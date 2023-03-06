using Azure;
using Azure.Search.Documents.Models;
using System.Collections.ObjectModel;

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
            // retrive documents matching query request
            Collection<T> collection = new();
            await foreach (var document in searchResults.GetResultsAsync())
            {
                collection.Add(document.Document);
            }

            Documents = collection;
        }
    }
}
