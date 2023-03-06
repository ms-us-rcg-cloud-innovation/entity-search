using ChangeFeedIndexerFunction;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        services.AddOptions();
        services.AddSingleton(sp => new FeedIndexerOptions { BatchSize = double.Parse(context.Configuration["FEEDINDEXER_BATCH_SIZE"]) });
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
