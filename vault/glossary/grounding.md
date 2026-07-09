---
term: "Grounding"
definition: "The process of anchoring an LLM's outputs to verifiable, external information sources—such as retrieved documents, database queries, or tool results—to reduce hallucination and improve factual accuracy."
seo_description: "Grounding: anchoring LLM outputs to external, verifiable information sources to reduce hallucination and improve factual accuracy."
category: "Agentic AI concepts"
related_terms: [rag, hallucination, tool-use, research-agent, factual-accuracy, faithfulness]
---

Ungrounded LLMs rely entirely on knowledge encoded in their weights during training, which can be stale, incomplete, or confidently wrong. Grounding addresses this by providing a retrieval or execution mechanism: the model's claims are supported by freshly retrieved documents, live API responses, or code execution results.

The two dominant grounding patterns are RAG (retrieval-augmented generation) for knowledge grounding and tool use for action grounding. In RAG, retrieved chunks are injected into context and the model is instructed to cite them. In tool-use grounding, the model runs a calculation or queries a database instead of recalling a fact from weights.

Grounding does not eliminate hallucination—models can still misquote sources or fail to retrieve the right document—but it dramatically reduces the rate of confident factual errors. Citation-based grounding (requiring the model to quote the exact sentence supporting each claim) provides the strongest guarantee and enables automated faithfulness verification.

## Related Terms

- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[glossary/hallucination|Hallucination]] — the failure mode where a model generates confident but factually incorrect output
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/research-agent|Research Agent]] — an agent that autonomously searches and synthesizes information from external sources
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
