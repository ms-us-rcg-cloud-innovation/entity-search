using Azure;
using Azure.Search.Documents.Models;
using System.Collections.ObjectModel;
using System.Data.Common;
using System.Text.Json.Serialization;

namespace SearchFunction.Models
{
    public record class QueryResult<T>(SearchResults<T> SearchResults, int PageIndex, int MaxPageSize, int TotalAvailablePages, int RemainingPages, long? Skip)
        where T : class
    {
        public int PageSize => Documents.Count;

        private readonly List<T> _documents = new();
        [JsonIgnore]
        public IReadOnlyList<T> Documents => _documents;

        public async Task ProcessResultsAsync()
        {            
            var results = SearchResults.GetResultsAsync();
            await foreach (var doc in results)
            {
                _documents.Add(doc.Document);
            }
        }
    }
}
