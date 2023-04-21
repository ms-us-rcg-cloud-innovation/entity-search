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

        [Required]
        [Range(1, int.MaxValue)]
        public int PageIndex { get; set; }

        [Required]
        [Range(1, 100)]
        public int PageSize { get; set; }

        public string ContinuationToken { get; set; }
    }
}
