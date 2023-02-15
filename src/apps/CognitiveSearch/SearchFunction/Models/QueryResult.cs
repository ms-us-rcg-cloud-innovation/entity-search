using Azure.Search.Documents.Models;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SearchFunction.Models
{
    public class QueryResult<T>
    {       
        private readonly Task _ready;

        public QueryResult(SearchResults<T> searchResults) 
        {
            _ready = ProcessResultsAsync(searchResults);
        }

        public async Task CompleteAsync() => await _ready;

        public int Count => Documents?.Count() ?? 0;

        public IEnumerable<T> Documents { get; set; }

        private async Task ProcessResultsAsync(SearchResults<T> searchResults)
        {
            Collection<T> collection = new();
            await foreach(var document in searchResults.GetResultsAsync())
            {
                collection.Add(document.Document);
            }

            Documents = collection;
        }
    }
}
