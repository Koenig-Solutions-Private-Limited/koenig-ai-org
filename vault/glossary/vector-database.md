---
term: "Vector Database"
definition: "A database or index optimized for storing embeddings and searching for nearby vectors that represent semantically similar items."
seo_description: "Vector database: a database or index for storing embeddings and searching nearby vectors that represent semantically similar items."
category: "Infrastructure"
related_terms: [embedding, rag, retrieval, reranking, chunking]
---

A vector database stores high-dimensional embedding vectors alongside metadata and source references. At query time, it finds items whose vectors are close to the query vector, which often correspond to semantically similar text, images, or records.

Vector databases are commonly used in RAG, memory systems, semantic search, deduplication, and recommendation. Production designs still need permission filtering, freshness rules, metadata constraints, and evaluation of retrieval quality.
