using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using SearchFunction.Models;
using SearchFunction.Services;
using System.Net;

namespace SearchFunction.Functions
{
    public class ProductSearch
    {
        private readonly SearchService<ProductIndex> _searchService;
        private readonly CosmosService<Product> _cosmosService;
        private readonly ILogger _logger;

        public ProductSearch(ILoggerFactory loggerFactory, SearchService<ProductIndex> searchService, CosmosService<Product> cosmosService)
        {
            _searchService = searchService;
            _cosmosService = cosmosService;
            _logger = loggerFactory.CreateLogger<ProductSearch>();
        }

        [Function(nameof(ProductSearch))]
        public async Task<HttpResponseData> RunAsync(
            [HttpTrigger(AuthorizationLevel.Function
                , "post"
                , Route = "product-search")] HttpRequestData req)
        {
            var response = req.CreateResponse();

            var queryRequest = await req.ReadFromJsonAsync<QueryRequest>();

            if (!queryRequest.IsValid(out var validationErrors, validateAllProperties: true))
            {
                response.StatusCode = HttpStatusCode.BadRequest;
                await response.WriteAsJsonAsync(validationErrors);

                return response;
            }

            var queryResults = await _searchService.SearchAsync(queryRequest);

            var docs = await _cosmosService.GetDocumentsByPointReadAsync(queryResults.Documents.Select(x => x.Id).ToList());

            await response.WriteAsJsonAsync(new
            {
                SearchResults = queryResults,
                DbResults = new
                {
                    Count = docs.Count(),
                    docs
                }
            });

            return response;
        }
    }
}
