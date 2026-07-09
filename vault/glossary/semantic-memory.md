---
term: "Semantic Memory"
definition: "A type of agent memory that stores general facts, domain knowledge, embeddings of documents, and distilled insights—without temporal binding—enabling knowledge-base-style retrieval for any task."
seo_description: "Semantic memory: an AI agent's store of general facts and knowledge embeddings, enabling knowledge-base retrieval for any task."
category: "Agentic AI concepts"
related_terms: [agent-memory, episodic-memory, working-memory, rag, embedding, vector-database]
---

Semantic memory corresponds roughly to a knowledge base or long-term fact store. Unlike episodic memory (what happened when), semantic memory holds timeless or slowly-changing facts: product documentation, domain ontologies, company policies, research findings. It is the primary target of RAG pipelines.

Implementation typically uses a vector database (Chroma, FAISS, Pinecone) that stores embeddings of text chunks. At query time, the agent embeds its query and retrieves the nearest neighbors, then re-ranks them. The resulting chunks are injected into the context window to ground the model's response.

Maintenance of semantic memory is an ongoing process: new documents must be ingested and indexed, stale documents updated or removed, and the embedding model periodically upgraded when a better model becomes available (which requires re-embedding the entire corpus). Tools like LlamaIndex and LangChain provide pipelines for this maintenance work.

## Related Terms

- [[glossary/agent-memory|Agent Memory]] — the persistence layer (working, episodic, semantic) that maintains agent continuity
- [[glossary/episodic-memory|Episodic Memory]] — the long-term store of past interactions retrieved to inform future decisions
- [[glossary/working-memory|Working Memory]] — the in-context short-term store for the current task's intermediate results
- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
