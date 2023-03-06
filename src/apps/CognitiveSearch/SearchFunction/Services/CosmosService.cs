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

        public async Task<IEnumerable<T>> GetDocumentsByQueryAsync(IEnumerable<string> ids)
        {
            var query = new QueryDefinition($"SELECT * FROM {_client.Container.Id} c WHERE ARRAY_CONTAINS(@ids, c.id)")
                                .WithParameter("@ids", ids);

            List<T> dbResponse = new();
            var feedIterator = _client.Container.GetItemQueryIterator<T>(query);

            while (feedIterator.HasMoreResults)
            {
                var response = await feedIterator.ReadNextAsync();
                dbResponse.AddRange(response.ToList());
            }

            return dbResponse;
        }
    }
}
