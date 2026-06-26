---
term: "Chunking"
definition: "The process of splitting source content into smaller passages for embedding, retrieval, summarization, or context-window management."
seo_description: "Chunking: splitting source content into smaller passages for embedding, retrieval, summarization, or context-window management."
category: "LLM concepts"
related_terms: [rag, embedding, vector-database, retrieval, context-window]
---

Chunking is a core design choice in retrieval-augmented generation. Small chunks can retrieve precise facts but may lose surrounding context. Large chunks preserve context but can dilute relevance and consume too much prompt budget.

Common strategies include fixed-token chunks, heading-based chunks, semantic chunks, and overlapping windows. Good chunking follows the structure of the source material: code, contracts, transcripts, and tutorials usually need different boundaries.
