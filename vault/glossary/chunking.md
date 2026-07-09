---
term: "Chunking"
definition: "The process of splitting source content into smaller passages for embedding, retrieval, summarization, or context-window management."
seo_description: "Chunking: splitting source content into smaller passages for embedding, retrieval, summarization, or context-window management."
category: "LLM concepts"
related_terms: [rag, embedding, vector-database, retrieval, context-window]
related_courses: [claude-tool-use-from-zero]
---

Chunking is the first major design decision in any [[rag]] pipeline. An [[embedding]] model encodes each chunk as a single fixed-dimension vector. That vector must summarise the chunk well enough that a similarity search can match it against the query vector. Too large a chunk and the vector becomes a blurry average of too many topics, making retrieval imprecise. Too small a chunk and the vector captures a precise fragment but loses the surrounding context the model needs to reason from.

**Chunk size selection.** For precise fact retrieval — "What is the refund window for product X?" — chunks of 50–200 tokens work well. The narrow scope keeps the vector specific. For reasoning tasks that require synthesising across several sentences — "Summarise the key risks in this contract section" — 300–800 tokens preserves enough context for the model to work from. There is no universal optimal size; the right answer depends on document type, query distribution, and model [[context-window]] budget.

**Overlap windows.** A sentence split exactly at a chunk boundary loses context on both sides. Overlapping adjacent chunks by 15–20% — repeating the last few sentences of one chunk at the start of the next — reduces this boundary loss. The tradeoff is slightly larger [[vector-database]] storage and more tokens injected into the [[context-window]] per retrieved passage.

**Document-aware chunking.** Markdown headings, HTML section tags, and PDF paragraph boundaries carry semantic meaning. Splitting at these natural boundaries produces chunks that are more cohesive than fixed-token splits. For code, function or class boundaries are the natural unit. For contracts, clause boundaries are. Generic fixed-token chunking ignores structure and often cuts across ideas mid-sentence.

**Parent-child chunking.** A hybrid approach stores two levels: small child chunks (50–100 tokens) for high-precision [[retrieval]], and larger parent chunks (400–800 tokens) that get returned to the model once a child chunk matches. The child's specificity gets the right passage; the parent's breadth gives the model the context it needs.

**Impact on reranking.** After initial vector search, a [[reranking]] model re-scores the top candidates against the full query. Poor chunking — chunks that split mid-argument or bundle unrelated topics — degrades reranker quality because no reranker can recover context that was never in the chunk. See [[claude-tool-use-from-zero]] for a practical walkthrough of building retrieval pipelines where chunk strategy directly affects answer quality.

## Related Terms

- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[glossary/embedding|Embedding]] — dense vector representations that power semantic similarity search
- [[glossary/vector-database|Vector Database]] — the indexed store that enables fast semantic similarity search for retrieval
- [[glossary/retrieval|Retrieval]] — the query-time lookup that pulls relevant chunks from an external store
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
