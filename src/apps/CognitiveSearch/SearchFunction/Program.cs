using Grpc.Net.Client.Configuration;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SearchFunction.Models;
using SearchFunction.Services;
using System.Text.Json;


var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        services.AddScoped<SearchService<ProductIndex>>();
        services.AddScoped<CosmosService<Product>>();
        services.AddSingleton<CosmosServiceClient>(options =>
        {
            var connectionString = context.Configuration["COSMOS_CONNECTION"];
            var databaseName = context.Configuration["COSMOS_DATABASE"];
            var containerName = context.Configuration["COSMOS_CONTAINER"];
            var partitionKey = context.Configuration["COSMOS_CONTAINER_PARTITIONKEY"];

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
    })
    .Build();

host.Run();
