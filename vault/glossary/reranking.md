---
term: "Reranking"
definition: "A retrieval step that reorders initially retrieved results using a more precise scoring model or rule before passing context to the next stage."
seo_description: "Reranking: reordering initially retrieved results with a more precise scoring model before passing context to the next stage."
category: "LLM concepts"
related_terms: [rag, retrieval, embedding, vector-database, chunking]
---

Reranking is the second stage in a two-stage [[retrieval]] pipeline. The first stage — typically a fast vector or keyword search — casts a wide net and returns a large candidate set, often the top 50–100 results from a [[vector-database]]. The reranker then scores those candidates more carefully against the query and returns the top 3–10 for inclusion in the prompt. The result is better [[rag]] quality at a controlled cost.

**Why first-stage retrieval alone is insufficient.** [[Embedding]]-based similarity search uses a bi-encoder: each document and query are independently encoded into dense vectors, and similarity is approximated by their geometric distance. This is fast and scalable, but the encodings are computed independently, so the model never directly compares a specific query to a specific passage. This approximation misses important relevance signals, especially for long-tail queries, documents with domain-specific terminology, or complex multi-part questions where word overlap is low but conceptual alignment is high.

**Cross-encoder architecture.** A reranker uses a cross-encoder: the query and each candidate passage are concatenated and processed jointly by a transformer. Because the model can attend across both sequences, it captures interaction signals that bi-encoders miss. The trade-off is that cross-encoding cannot be precomputed — it must run at query time for every candidate.

**Latency budget.** Reranking adds roughly 100–500 ms depending on the number of candidates and the reranker model size. This is acceptable for asynchronous or batch workloads and often tolerable for interactive chat if the first-stage result count is kept small. Popular options include Cohere Rerank, BGE Reranker, and Jina Reranker; several providers expose hosted APIs that keep the reranker out of your inference path.

**When reranking matters most.** The gap between first-stage and reranked quality is largest for domain-specific corpora, technical documentation, and queries that use different vocabulary from the indexed documents. For simple factual lookups against well-curated short documents, the benefit may not justify the added latency.

**Common mistake.** Teams often add reranking because it is described as best practice, then measure only intermediate ranking metrics rather than end-answer quality. Reranking is only valuable if it causes the [[llm]] to produce better outputs. Evaluate end-to-end with [[evals]] before committing to the extra hop. See [[claude-tool-use-from-zero]] for practical patterns integrating reranking into agent tool-call pipelines.

## Related Terms

- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[glossary/retrieval|Retrieval]] — the query-time lookup that pulls relevant chunks from an external store
- [[glossary/embedding|Embedding]] — dense vector representations that power semantic similarity search
- [[glossary/vector-database|Vector Database]] — the indexed store that enables fast semantic similarity search for retrieval
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
