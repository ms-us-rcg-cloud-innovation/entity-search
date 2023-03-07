using Azure.Search.Documents.Indexes;
using System.Text.Json.Serialization;

namespace SearchFunction.Models
{
    public class Product
    {
        [JsonPropertyName("id")]
        [SearchableField(IsKey = true)]
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
        public string StandardCost { get; set; }

        [SimpleField(IsFilterable = true)]
        public string ListPrice { get; set; }

        [SimpleField(IsFilterable = true)]
        public string SubCategoryId { get; set; }
    }
}
