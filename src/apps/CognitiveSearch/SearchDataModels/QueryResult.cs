using Azure;
using Azure.Search.Documents.Models;
using System.Collections.ObjectModel;

namespace SearchFunction.Models
{
    public class QueryResult<T>
    {
        private readonly Task _ready;

        public int PageSize { get; }

        public QueryResult(int pageSize, string continuationToken)
        {
            PageSize = pageSize;
            ContinuationToken = continuationToken;          
        }
    
        public int Count => Documents?.Count ?? 0;

        public string ContinuationToken { get; set; }

        public List<T> Documents { get; } = new();

        public async Task ProcessResultsAsync(SearchResults<T> searchResults)
        {
            await foreach(var doc in searchResults.GetResultsAsync())
            {
                Documents.Add(doc.Document);
            }
        }
    }
}
