---
term: "Reranking"
definition: "A retrieval step that reorders initially retrieved results using a more precise scoring model or rule before passing context to the next stage."
seo_description: "Reranking: reordering initially retrieved results with a more precise scoring model before passing context to the next stage."
category: "LLM concepts"
related_terms: [rag, retrieval, embedding, vector-database, chunking]
---

Reranking improves retrieval quality by separating candidate generation from final selection. A fast vector or keyword search finds a broad set of possible matches; a reranker then scores those candidates more carefully against the query.

This is useful when the first-stage retriever returns semantically related but not actually useful passages. The cost is extra latency and compute, so reranking should be measured against downstream answer quality, not used automatically.
