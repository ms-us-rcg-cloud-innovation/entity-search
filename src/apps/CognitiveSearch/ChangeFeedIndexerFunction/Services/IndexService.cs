using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ChangeFeedIndexerFunction.Services
{
    public class IndexService
    {
        private readonly SearchClient _searchClient;

        public IndexService(SearchClient searchClient) 
        {
            _searchClient = searchClient;
        }

        public async Task<IndexDocumentsResult> IndexDocumentsAsync<T>(IEnumerable<T> documents)
            where T : class
        {
            var documentBatch = documents.ToIndexDocumentUpsertBatch();
            var indexResult = await _searchClient.IndexDocumentsAsync(documentBatch);

            return indexResult.Value;
        }
    }
}
