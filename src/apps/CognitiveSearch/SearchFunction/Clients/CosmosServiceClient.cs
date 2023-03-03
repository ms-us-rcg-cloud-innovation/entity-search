using Microsoft.Azure.Cosmos;

namespace SearchFunction.Clients
{
    public class CosmosServiceClient
    {
        public CosmosServiceClient(Container container, string partitionKey)
        {
            Container = container;
            PartitionKey = partitionKey;
        }

        public Container Container { get; }

        public string PartitionKey { get; }
    }
}
