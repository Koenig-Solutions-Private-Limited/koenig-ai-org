---
term: "Vector Database"
definition: "A database or index optimized for storing embeddings and searching for nearby vectors that represent semantically similar items."
seo_description: "Vector database: a database or index for storing embeddings and searching nearby vectors that represent semantically similar items."
category: "Infrastructure"
related_terms: [embedding, rag, retrieval, reranking, chunking]
---

A vector database stores high-dimensional numeric vectors — [[embedding]] representations of text, images, audio, or structured records — and enables fast approximate nearest-neighbor (ANN) search over them. At query time, the system encodes the query into a vector and retrieves the stored vectors that are geometrically closest, which typically corresponds to semantic similarity in the original data.

**How ANN search works.** Exact nearest-neighbor search over millions of high-dimensional vectors is computationally prohibitive. Vector databases use approximate algorithms: HNSW (Hierarchical Navigable Small World graphs) builds a multilayer proximity graph for fast traversal; IVF (Inverted File Index) partitions the space into clusters and searches only the most relevant clusters. Both trade a small amount of recall for large speed gains.

**Distance metrics.** The choice of metric matters. Cosine similarity measures the angle between vectors, making it robust to differences in vector magnitude — useful for text [[embedding]] models that produce unnormalized outputs. Dot product rewards both direction and magnitude, often preferred when the embedding model is trained with dot-product objectives. Euclidean distance is less common in NLP contexts but used in some image embedding applications.

**Popular options.** Pinecone and Weaviate are fully managed cloud services. Qdrant is open-source and self-hostable with strong filtering performance. pgvector brings ANN search to PostgreSQL, keeping vector search inside an existing relational database. Chroma is lightweight and suited for local development and prototyping.

**Metadata filtering.** ANN search alone is rarely sufficient in production. Most queries also require filtering by category, date range, user ID, permission scope, or document type. Vector databases support pre-filter (filter first, then search the narrowed set) or post-filter (search all vectors, then filter results) strategies. Pre-filter is safer for correctness but can reduce recall if the filtered set is small.

**Hybrid search.** Combining vector similarity with keyword (BM25) scoring often outperforms either alone, particularly for queries with rare or domain-specific terms that embedding models may under-represent.

**Confidentiality and data residency.** [[Embedding]] vectors of private documents are sensitive: they encode semantic content that can be partially recovered. [[Confidentiality]] controls and [[data-residency]] requirements that apply to source documents apply equally to their embeddings. Managed vector databases that store data in external regions may not satisfy compliance requirements without explicit configuration.

**Common misconception.** A vector database does not solve [[rag]] quality on its own. Quality depends on how documents are split ([[chunking]]), which embedding model is used, whether [[reranking]] is applied, and how retrieved passages are assembled into the prompt. The vector database is the storage and search layer; the quality levers are upstream and downstream of it. See [[claude-tool-use-from-zero]] for end-to-end retrieval pipeline patterns.

## Related Terms

- [[glossary/embedding|Embedding]] — dense vector representations that power semantic similarity search
- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[glossary/retrieval|Retrieval]] — the query-time lookup that pulls relevant chunks from an external store
- [[glossary/reranking|Reranking]] — the scoring step that re-orders retrieved candidates by relevance before injection
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
