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

        // This function is triggered when a change is published to the
        // cosmos change feed for the given container we're monitoring.
        // To configure a change feed you need the monitored container and a
        // lease container as described here: 
        // https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/change-feed-functions
        [Function(nameof(ChangeFeedIndexer))]
        public async Task RunAsync(
            [CosmosDBTrigger(
                // Configured Environment Variabels. Variables 
                // wrapped in % % are expanded during execution time.
                // Connection string is looked up by the provided Key 
                // and does not expect to be wrapped in % %
                databaseName:"%COSMOSDB_DATABASE_NAME%",
                containerName: "%COSMOSDB_CONTAINER_NAME%",
                Connection = "COSMOSDB_CONNECTION_STRING",
                LeaseContainerName = "%COSMOSDB_LEASE_CONTAINER_NAME%",
                CreateLeaseContainerIfNotExists = true // lease container for chaged feed
            )] IReadOnlyList<Product> products)
        {
            if (products?.Count > 0)
            {
                IndexDocumentsBatch<Product> batch = new();
                foreach (var doc in products)
                {
                    // Add each document to the indexing action collection with 
                    // Merge or Upload setting. This guarantees if a document with
                    // the defined index ID exists it's udpated, otherwise it's a 
                    // new document index is inserted.
                    var indexDocAction = new IndexDocumentsAction<Product>(IndexActionType.MergeOrUpload, doc);
                    batch.Actions.Add(indexDocAction);
                }

                // Take the index batch and pass to the SDK for further index processing
                var indexResult = await _searchClient.IndexDocumentsAsync(batch);
            }
        }
    }
}
