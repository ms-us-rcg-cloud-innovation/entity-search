using ChangeFeedIndexerFunction.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using SearchFunction.Models;

namespace ChangeFeedIndexerFunction.Functions
{
    public class ChangeFeedIndexer
    {
        private readonly ILogger _logger;
        private readonly IndexService _indexService;

        public ChangeFeedIndexer(ILoggerFactory loggerFactory, IndexService indexService)
        {
            _logger = loggerFactory.CreateLogger<ChangeFeedIndexer>();
            _indexService = indexService;
        }

        [Function(nameof(ChangeFeedIndexer))]
        public async Task RunAsync(
            [CosmosDBTrigger(
                databaseName:"%COSMOSDB_DATABASE_NAME%",
                containerName: "%COSMOSDB_CONTAINER_NAME%",
                Connection = "COSMOSDB_CONNECTION_STRING",
                LeaseContainerName = "%COSMOSDB_LEASE_CONTAINER_NAME%",
                CreateLeaseContainerIfNotExists = true
            )] IReadOnlyList<Product> products,
            FunctionContext functionContext)
        {
            if (products?.Any() == true)
            {
                var results = await _indexService.IndexDocumentsAsync(products);

                _logger.LogInformation("Indexed documents | {results}", results);
            }
        }
    }
}
