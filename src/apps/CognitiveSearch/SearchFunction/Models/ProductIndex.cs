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
    public class ProductIndex
    {
        [JsonPropertyName("id")]
        public string Id { get; set; }
    }
}
