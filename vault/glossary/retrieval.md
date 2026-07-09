---
term: "Retrieval"
definition: "The process of finding relevant external information, documents, memories, or records to use in a model or agent workflow."
seo_description: "Retrieval: finding relevant external information, documents, memories, or records for a model or agent workflow."
category: "LLM concepts"
related_terms: [rag, embedding, vector-database, reranking, chunking]
---

Retrieval gives an AI system access to information that does not live in the model's weights. Before generating a response or choosing an action, the system queries an external source — a document index, a database, a codebase, an agent memory store, or a live API — and injects the returned content into the prompt. The quality of what gets retrieved largely determines the quality of what gets generated.

**Retrieval types.** Semantic retrieval uses [[embedding]] vectors to find documents that are conceptually similar to the query regardless of exact wording. Keyword search (BM25) finds documents that share surface-level tokens with the query. Hybrid search combines both signals and typically outperforms either alone. Structured queries retrieve from relational databases or knowledge graphs using SQL or SPARQL. API retrieval fetches live data such as calendar entries, CRM records, or pricing tables. The right method depends on the content type and query distribution.

**The RAG pipeline.** [[Rag]] (retrieval-augmented generation) is the dominant pattern for grounding [[llm]] outputs in external knowledge: retrieve the relevant passages, insert them into the [[context-window]], then generate. [[Chunking]] controls how source documents are split before indexing. [[Reranking]] re-scores the candidate set before injection to improve signal quality. The model never needs to memorise facts that can be retrieved on demand.

**Retrieval and hallucination.** When retrieval fails — returning stale, irrelevant, or missing context — the model is forced to generate from priors alone, which is a primary cause of [[hallucination]]. A capable model with bad retrieval looks unreliable; a weaker model with excellent retrieval often outperforms it on knowledge-intensive tasks.

**Retrieval quality metrics.** Precision measures how many of the retrieved items were actually relevant. Recall measures how many of the truly relevant items were retrieved. Both matter: low precision floods the context with noise; low recall leaves the model without the evidence it needs.

**Retrieval vs. grounding.** Retrieval is the mechanical step of fetching context. [[Grounding]] is the broader practice of ensuring that model responses are tied to verifiable sources. Retrieval is the primary mechanism for achieving grounding, but grounding also includes citation generation, source attribution, and confidence calibration.

**Agent memory as retrieval.** Agent memory stores are a form of retrieval: the agent queries past events, learned facts, or user preferences at the start of a session, exactly as it would query a document index. See [[claude-tool-use-from-zero]] for worked patterns.

## Related Terms

- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[glossary/embedding|Embedding]] — dense vector representations that power semantic similarity search
- [[glossary/vector-database|Vector Database]] — the indexed store that enables fast semantic similarity search for retrieval
- [[glossary/reranking|Reranking]] — the scoring step that re-orders retrieved candidates by relevance before injection
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
