using Microsoft.Azure.Cosmos;
using SearchFunction.Clients;
using System.Collections.ObjectModel;

namespace SearchFunction.Services
{
    public class CosmosService<T>
        where T : class
    {
        private readonly CosmosServiceClient _client;

        public CosmosService(CosmosServiceClient serviceClient)
        {
            _client = serviceClient;
        }

        // this method is used to get documents by point read from Cosmos DB
        // because point reads are faster and cost fewer RUs
        public async Task<IEnumerable<T>> GetDocumentsByPointReadAsync(IEnumerable<string> ids)
        {
            Collection<Task<ItemResponse<T>>> queries = new();
            foreach (var id in ids)
            {
                queries.Add(_client.Container.ReadItemAsync<T>(id, new PartitionKey(id.ToString())));
            }

            var response = await Task.WhenAll(queries);

            return response.Select(x => x.Resource).ToList(); ;
        }
    }
}
