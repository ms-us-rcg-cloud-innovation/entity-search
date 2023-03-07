using Azure.Search.Documents;
using ChangeFeedIndexerFunction;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SearchFunction.Models;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        services.AddOptions();
        services.Configure<SearchIndexingBufferedSenderOptions<Product>>(context.Configuration.GetSection("SearchIndexerOptions"));   
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
