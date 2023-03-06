using System.ComponentModel.DataAnnotations;
using System.Runtime.Serialization;

namespace SearchFunction.Models
{
    public class QueryRequest
    {
        [MinLength(0)]
        [MaxLength(512)]
        public string SearchParameter { get; set; }

        [MinLength(0)]
        [MaxLength(512)]
        public string FilterOptions { get; set; }
    }
}
