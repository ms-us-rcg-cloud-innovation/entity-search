using System.Text.Json.Serialization;

namespace SearchFunction.Models
{
    public class Product
    {
        [JsonPropertyName("id")]
        public string Id { get; set; }

        public string ProductNumber { get; set; }

        public string ProductName { get; set; }

        public string ModelName { get; set; }

        public string MakeFlag { get; set; }

        public string StandardCost { get; set; }

        public string ListPrice { get; set; }

        public string SubCategoryId { get; set; }
    }
}
