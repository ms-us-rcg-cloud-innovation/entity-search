using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SearchFunction.Clients;
using SearchFunction.Models;
using SearchFunction.Services;


var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        services.AddScoped<SearchService<ProductIndex>>();
        services.AddScoped<CosmosService<Product>>();
        services.AddSingleton<CosmosServiceClient>(options =>
        {
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
            var endpoint = new Uri(context.Configuration["SEARCH_ENDPOINT"]);
            var indexName = context.Configuration["SEARCH_INDEX_NAME"];
            var key = new Azure.AzureKeyCredential(context.Configuration["SEARCH_CREDENTIAL_KEY"]);

            builder.AddSearchClient(endpoint, indexName, key);
        });
        services.AddScoped(sp =>
        {
            var options = new SearchOptions();
            options.IncludeTotalCount = true;
            options.QueryType = SearchQueryType.Full;
            options.SearchMode = SearchMode.Any;

            return options;
        });

    })
    .Build();

host.Run();
