using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SearchFunction.Clients;
using SearchFunction.Models;
using SearchFunction.Services;


// Serverless search function that uses the Azure Search SDK 
// What is Azure Search? https://learn.microsoft.com/en-us/azure/search/search-what-is-azure-search
// Function consists of two integrations:
//    1. Azure Search integration to query data stored in Cosmos 
//    2. CosmosDB integration to retrieve document based on query results

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        services.AddScoped<SearchService<ProductIndex>>();
        services.AddScoped<CosmosService<Product>>();
        services.AddSingleton<QueryRequestValidationService>();
        services.AddSingleton<CosmosServiceClient>(options =>
        {
            // Configure CosmosClient for query results document retrieval
            var connectionString = context.Configuration["COSMOSDB_CONNECTION_STRING"];
            var databaseName = context.Configuration["COSMOSDB_DATABASE_NAME"];
            var containerName = context.Configuration["COSMOSDB_CONTAINER_NAME"];
            var partitionKey = context.Configuration["COSMOSDB_CONTAINER_PARTITIONKEY"];

            CosmosClient client = new(connectionString);
            Container container = client.GetContainer(databaseName, containerName);

            return new CosmosServiceClient(container, partitionKey);
        });
        services.AddAzureClients(builder =>
        {
            // Configure Azure SearchClient
            var endpoint = new Uri(context.Configuration["SEARCH_ENDPOINT"]);
            var indexName = context.Configuration["SEARCH_INDEX_NAME"];
            var key = new Azure.AzureKeyCredential(context.Configuration["SEARCH_CREDENTIAL_KEY"]);

            builder.AddSearchClient(endpoint, indexName, key);
        });

        // Configured the Search Client options to be passed to the 
        // SearchService. This is where you define query type and search mode.
        // SDK v11: https://learn.microsoft.com/en-us/azure/search/search-howto-dotnet-sdk
        // Query Types: 
        //   simple: https://learn.microsoft.com/en-us/azure/search/search-query-simple-examples
        //   full:   https://learn.microsoft.com/en-us/azure/search/search-query-lucene-examples
        //   semantic (not tested): https://learn.microsoft.com/en-us/azure/search/semantic-search-overview
        // SearchMode:
        //   referece: https://learn.microsoft.com/en-us/azure/search/search-query-simple-examples#example-1-full-text-search
        //   all: find matches based on all criteria - favors precision
        //   any: find matches based on any criteria - favors recall
        services.AddScoped(sp =>
        {
            var options = new SearchOptions();
            options.IncludeTotalCount = true;
            options.QueryType = SearchQueryType.Full;
            options.SearchMode = SearchMode.Any;
            options.Size = 2;
            
            return options;
        });

    })
    .Build();

host.Run();
