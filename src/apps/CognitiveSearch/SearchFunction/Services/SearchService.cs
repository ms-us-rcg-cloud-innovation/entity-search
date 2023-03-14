using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using SearchFunction.Models;

namespace SearchFunction.Services
{
    /// <summary>
    /// Service class for passing queryes to Azure search
    /// </summary>
    /// <typeparam name="T">Document type being searched</typeparam>
    public class SearchService<T>
        where T : class
    {
        // Injected configs. as defined in program.cs
        private readonly SearchClient _searchClient;
        private readonly SearchOptions _searchOptions;

        public SearchService(SearchClient searchClient, SearchOptions searchOptions)
        {
            _searchClient = searchClient;
            _searchOptions = searchOptions;            
        }

        /// <summary>
        /// Execute document search using query request parameters
        /// </summary>
        /// <param name="query">Search query and filters as defined in input request</param>
        /// <returns>QueryResult for specified type T</returns>
        public async Task<QueryResult<T>> SearchAsync(QueryRequest query)
        {
            if (!string.IsNullOrEmpty(query.FilterOptions?.Trim()))
            {
                _searchOptions.Filter = query.FilterOptions;
            }
            
            SearchResults<T> results = await _searchClient.SearchAsync<T>(query.SearchParameter, _searchOptions);
            
            var queryResults = new QueryResult<T>(results);

            // await until content is ready for returning
            await queryResults.CompleteAsync();

            return queryResults;
        }
    }
}

