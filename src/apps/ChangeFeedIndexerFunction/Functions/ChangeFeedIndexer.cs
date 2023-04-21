using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SearchFunction.Models;
using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;

namespace ChangeFeedIndexerFunction.Functions
{
    public class ChangeFeedIndexer
    {
        private readonly ILogger _logger;
        private readonly SearchClient _searchClient;
        private readonly SearchIndexingBufferedSenderOptions<Product> _bufferedSenderOptions;

        public ChangeFeedIndexer(ILoggerFactory loggerFactory, SearchClient searchClient, IOptions<SearchIndexingBufferedSenderOptions<Product>> bufferedSenderOptions)
        {
            _logger = loggerFactory.CreateLogger<ChangeFeedIndexer>();
            _searchClient = searchClient;
            _bufferedSenderOptions = bufferedSenderOptions.Value;
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
            )] IReadOnlyList<Product> products,
            CancellationToken cancellationToken)
        {
            // check if there are any documents to index
            if (products.Count() == 0)
            {
                _logger.LogInformation("No documents to index");
                return;
            }

            // create a new buffered sender for batch sending
            var batchSender = new SearchIndexingBufferedSender<Product>(_searchClient, _bufferedSenderOptions);
                        
            // prep documents batch for upload
            await batchSender.MergeOrUploadDocumentsAsync(products, cancellationToken);
            
            // flush buffer -- attempt index uploads
            await batchSender.FlushAsync(cancellationToken);
        }
    }
}
