using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SearchFunction.Models
{
    public class QueryRequest
    {       
        public string SearchParameter { get; set; }

        public string FilterOptions { get; set; }
    }
}
