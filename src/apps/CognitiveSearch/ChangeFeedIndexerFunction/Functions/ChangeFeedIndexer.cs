using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using SearchFunction.Models;

namespace ChangeFeedIndexerFunction.Functions
{
    public class ChangeFeedIndexer
    {
        private readonly ILogger _logger;
        private readonly SearchClient _searchClient;

        public ChangeFeedIndexer(ILoggerFactory loggerFactory, SearchClient searchClient)
        {
            _logger = loggerFactory.CreateLogger<ChangeFeedIndexer>();
            _searchClient = searchClient;
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
            if (products?.Count > 0)
            {
                IndexDocumentsBatch<Product> batch = new();
                foreach (var doc in products)
                {
                    var indexDocAction = new IndexDocumentsAction<Product>(IndexActionType.MergeOrUpload, doc);
                    batch.Actions.Add(indexDocAction);
                }

                var indexResult = await _searchClient.IndexDocumentsAsync(batch);
            }
        }
    }
}
