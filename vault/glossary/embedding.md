---
term: "Embedding"
definition: "An embedding is a numerical vector representation of an input — typically text, but also images, audio, or code — that places semantically similar inputs near each other in a high-dimensional space, enabling semantic search, retrieval, classification, and clustering."
category: "AI architecture"
related_terms: [rag, vector-database, llm, transformer]
related_courses: []
sameAs:
  - https://en.wikipedia.org/wiki/Word_embedding
  - https://www.wikidata.org/wiki/Q18616576
---

Modern embeddings come from transformer encoder models or specialized embedding models. As of April 2026, common production embedding models include Google text-embedding-004 (768 dimensions, free tier on Vertex), Voyage-3 (1024 dim, paid), OpenAI text-embedding-3-large (3072 dim), and Cohere embed-v4. Open-weights options include BAAI bge-m3 and Jina embeddings v3.

Embedding dimensionality, model architecture, and training data dominate quality. Modern best-in-class embedding models train with contrastive losses on (query, positive document, hard negative) triples sourced from search query logs.

In RAG systems, embeddings are typically used with vector indexes (FAISS, pgvector, Pinecone, Weaviate, Convex vector index, Supabase pgvector) and a top-k semantic similarity query. Hybrid retrieval — combining dense embedding similarity with sparse BM25 — typically outperforms either alone on real-world workloads.

## Related Terms

- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[glossary/vector-database|Vector Database]] — the indexed store that enables fast semantic similarity search for retrieval
- [[glossary/llm|Large Language Model (LLM)]] — the large language model that generates responses and tool calls inside the loop
- [[glossary/transformer|Transformer]] — the neural architecture underlying virtually all modern LLMs
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
