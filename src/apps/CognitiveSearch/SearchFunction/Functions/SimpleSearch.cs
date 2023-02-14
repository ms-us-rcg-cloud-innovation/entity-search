using System.Collections.ObjectModel;
using System.Net;
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using SearchFunction.Models;

namespace SearchFunction.Functions
{
    public class SimpleSearch
    {
        private readonly SearchClient _searchClient;
        private readonly ILogger _logger;

        public SimpleSearch(ILoggerFactory loggerFactory, SearchClient searchClient)
        {
            _searchClient = searchClient;
            _logger = loggerFactory.CreateLogger<SimpleSearch>();
        }

        [Function("SimpleSearch")]
        public async Task<HttpResponseData> RunAsync(
            [HttpTrigger(AuthorizationLevel.Function
                , "post"
                , Route = "simple-search")] HttpRequestData req)
        {            
            var response = req.CreateResponse();

            var queryRequest = await req.ReadFromJsonAsync<QueryRequest>();

            if (!queryRequest.IsValid(out var validationErrors, validateAllProperties: true))
            {
                response.StatusCode = HttpStatusCode.BadRequest;
                await response.WriteAsJsonAsync(validationErrors);

                return response;
            }

            var metaResults = new
            {
                Details = await SearchProductsAsync(queryRequest),
                Docs = new Collection<SearchResult<Product>>()
            };
            await foreach(var r in metaResults.Details.GetResultsAsync())
            {
                metaResults.Docs.Add(r);
            }


            await response.WriteAsJsonAsync(metaResults);

            return response;
        }

        private async Task<SearchResults<Product>> SearchProductsAsync(QueryRequest query)
        {
            SearchOptions searchOptions = new()
            {
                SearchMode = SearchMode.All
            };

            if (!string.IsNullOrEmpty(query.FilterOptions?.Trim()))
            {
                searchOptions.Filter = query.FilterOptions;
            }

            searchOptions.IncludeTotalCount = true;
            
            searchOptions.QueryType = SearchQueryType.Full;
            var results = await _searchClient.SearchAsync<Product>(query.SearchParameter, searchOptions);

            return results;
        }
    }
}
