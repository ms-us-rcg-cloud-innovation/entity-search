using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SearchFunction.Models
{
    internal class QueryRequest
    {
        [Required]
        [MinLength(1)]
        public string SearchParameter { get; set; }

        public string FilterOptions { get; set; }
    }
}
