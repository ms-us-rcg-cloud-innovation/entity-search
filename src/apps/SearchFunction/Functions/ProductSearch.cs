using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using SearchFunction.Models;
using SearchFunction.Services;
using System.Net;
using System.ComponentModel.DataAnnotations;

namespace SearchFunction.Functions
{
    public class ProductSearch
    {
        private readonly SearchService<ProductIndex> _searchService;
        private readonly CosmosService<Product> _cosmosService;
        private readonly QueryRequestValidationService _queryRequestValidationService;
        private readonly ILogger _logger;

        public ProductSearch(ILoggerFactory loggerFactory
                           , SearchService<ProductIndex> searchService
                           , CosmosService<Product> cosmosService
                           , QueryRequestValidationService queryRequestValidationService)
        {
            _searchService = searchService;
            _cosmosService = cosmosService;
            _queryRequestValidationService = queryRequestValidationService;
            _logger = loggerFactory.CreateLogger<ProductSearch>();
        }

        // Azure function that is triggered when an HTTP request is received
        // the request is deserialized into a QueryRequest object and validated 
        // using the QueryRequestValidationService
        [Function(nameof(ProductSearch))]
        public async Task<HttpResponseData> RunAsync(
                       [HttpTrigger(AuthorizationLevel.Function
                           , "post"
                           , Route = "entity-search")] HttpRequestData req)
        {
            var response = req.CreateResponse();
            var queryRequest = await req.ReadFromJsonAsync<QueryRequest>();

            if (_queryRequestValidationService.Validate(queryRequest, out IList<ValidationResult> validationResults, true))
            {
                response.StatusCode = HttpStatusCode.BadRequest;
                await response.WriteAsJsonAsync(validationResults);
                return response;
            }

            QueryResult<ProductIndex> queryResults = await _searchService.SearchAsync(queryRequest);            
            IEnumerable<Product> docs = await _cosmosService.GetDocumentsByPointReadAsync(queryResults.Documents.Select(x => x.Id).ToList());  
            
            var results = new
            {
                SearchResults = queryResults,
                DatabaseResults = docs
            };

            await response.WriteAsJsonAsync(results);
            
            return response;
        }

    }
}
