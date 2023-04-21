using System.Text.Json.Serialization;

namespace SearchFunction.Models
{
    public class ProductIndex
    {
        [JsonPropertyName("id")]
        public string Id { get; set; }
    }
}
