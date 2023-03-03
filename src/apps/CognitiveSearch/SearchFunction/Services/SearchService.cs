using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using SearchFunction.Models;

namespace SearchFunction.Services
{
    public class SearchService<T>
        where T : class
    {
        private readonly SearchClient _searchClient;
        private readonly SearchOptions _searchOptions;

        public SearchService(SearchClient searchClient, SearchOptions searchOptions)
        {
            _searchClient = searchClient;
            _searchOptions = searchOptions;            
        }

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

