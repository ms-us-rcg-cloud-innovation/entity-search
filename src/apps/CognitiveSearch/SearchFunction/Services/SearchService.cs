using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using SearchFunction.Models;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SearchFunction.Services
{
    public class SearchService<T>
        where T : class
    {
        private readonly SearchClient _searchClient;

        public SearchService(SearchClient searchClient) 
        {
            _searchClient = searchClient;
        }

        public async Task<QueryResult<T>> SearchAsync(QueryRequest query)
        {
            SearchOptions searchOptions = new()
            {
                SearchMode = SearchMode.Any
            };

            if (!string.IsNullOrEmpty(query.FilterOptions?.Trim()))
            {
                searchOptions.Filter = query.FilterOptions;
            }

            searchOptions.IncludeTotalCount = true;

            searchOptions.QueryType = SearchQueryType.Full;
            SearchResults<T> results = await _searchClient.SearchAsync<T>(query.SearchParameter, searchOptions);

            var queryResults = new QueryResult<T>(results);

            // await until content is ready for returning
            await queryResults.CompleteAsync();

            return queryResults;
        }
    }
}

