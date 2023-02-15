using Microsoft.Azure.Cosmos;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SearchFunction.Services
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
