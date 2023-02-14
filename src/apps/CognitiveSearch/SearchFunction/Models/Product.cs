using Azure.Search.Documents.Indexes;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace SearchFunction.Models
{
    public class Product
    {
        [JsonPropertyName("id")]
        [SearchableField(IsFilterable = true)]
        public string Id { get; set; }

        [SearchableField(IsFilterable = true)]
        public string ProductNumber { get; set; }

        [SearchableField(IsFilterable = true)]
        public string ProductName { get; set; }

        [SearchableField(IsFilterable = true)]
        public string ModelName { get; set; }
        
        [SearchableField(IsFilterable = true)]
        public string MakeFlag { get; set; }

        [SimpleField(IsFilterable = true)]
        public double StandardCost { get; set; }

        [SimpleField(IsFilterable = true)]
        public double ListPrice { get; set; }

        [SimpleField(IsFilterable = true)]
        public string SubCategoryId { get; set; }

        [SimpleField]
        public string Rid { get; set; }
    }
}
