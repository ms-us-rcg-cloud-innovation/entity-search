using Azure.Search.Documents.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ChangeFeedIndexerFunction
{
    public static class IndexingExtensions
    {
        public static IndexDocumentsBatch<T> ToIndexDocumentUpsertBatch<T>(this IEnumerable<T> documents)
            where T : class           
        {
            IndexDocumentsBatch<T> batch = new();
            foreach(var doc in documents)
            {
                batch.Actions.Add(new IndexDocumentsAction<T>(IndexActionType.MergeOrUpload, doc));
            }

            return batch;
        }
    }
}
