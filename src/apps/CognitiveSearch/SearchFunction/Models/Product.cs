using Azure.Search.Documents.Indexes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

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
        
        public double StandardCost { get; set; }
    
        public double ListPrice { get; set; }
        
        public string SubCategoryId { get; set; }
    }
}
