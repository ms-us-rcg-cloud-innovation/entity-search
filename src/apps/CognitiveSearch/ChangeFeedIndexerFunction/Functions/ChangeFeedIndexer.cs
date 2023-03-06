using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
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
        private readonly FeedIndexerOptions _options;

        public ChangeFeedIndexer(ILoggerFactory loggerFactory, SearchClient searchClient, FeedIndexerOptions options)
        {
            _logger = loggerFactory.CreateLogger<ChangeFeedIndexer>();
            _searchClient = searchClient;
            _options = options; //arbitrary batch size
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
            if (products.Count() == 0)
            {
                _logger.LogInformation("No documents to index");
                return;
            }

            var productsArray = products.ToArray();
            // Batch input if it exceeds the configured size limit
            if (products.Count() > _options.BatchSize)
            { // batch process the input

                await IndexDocumentsInBatchesAsync(productsArray);
            }
            else
            {
                await IndexDocumentsAsync(productsArray);
            }
        }

        private async Task<Azure.Response<IndexDocumentsResult>[]> IndexDocumentsInBatchesAsync(ReadOnlyMemory<Product> products)
        {
            var batchCount = (int)Math.Ceiling(products.Length / _options.BatchSize);
            var indexJobs = new List<Task<Azure.Response<IndexDocumentsResult>>>();
            int batchLength = (int)_options.BatchSize - 1;

            for (int n = 0; n < batchCount; n++)
            {
                int start = n * (int)_options.BatchSize;
                ReadOnlyMemory<Product> docBatch;

                if (start + batchLength < products.Length)
                {// if slice is withint range of array length
                    docBatch = products.Slice(start, batchLength);
                }
                else
                {// if batch size pushes slice out of bounds
                    docBatch = products.Slice(start); // capture remainder
                   
                }

                indexJobs.Add(IndexDocumentsAsync(docBatch));
            }

            return await Task.WhenAll(indexJobs);
        } 

        private async Task<Azure.Response<IndexDocumentsResult>> IndexDocumentsAsync(ReadOnlyMemory<Product> products)
        {
            IndexDocumentsBatch<Product> batch = new();
            for(int n = 0; n < products.Length; n++)
            {
                Product doc = products.Span[n];

                // Add each document to the indexing action collection with 
                // Merge or Upload setting. This guarantees if a document with
                // the defined index ID exists it's udpated, otherwise it's a 
                // new document index is inserted.
                var indexDocAction = new IndexDocumentsAction<Product>(IndexActionType.MergeOrUpload, doc);
                batch.Actions.Add(indexDocAction);
            }
            return await _searchClient.IndexDocumentsAsync(batch);
        }
    }
}
