---
term: "Context Injection"
definition: "The practice of dynamically inserting retrieved memories, tool results, or external data into an LLM's context window at inference time to provide information beyond what is encoded in the model's weights."
seo_description: "Context injection: dynamically inserting retrieved data, memories, or tool results into an LLM's context window at inference time."
category: "Agentic AI concepts"
related_terms: [working-memory, agent-memory, rag, grounding, system-prompt, few-shot-prompting]
---

Context injection is the mechanism by which external information becomes available to a running LLM. Rather than fine-tuning the model to know a fact, the scaffolding retrieves the fact and inserts it as text in the prompt. This enables dynamic, up-to-date knowledge without any weight updates.

Injection happens at multiple points in an agent's turn: the system prompt may inject user preferences and agent SOUL; the user turn may inject retrieved memory snippets; tool result blocks inject execution outputs. The order and formatting of injected content affects how well the model uses it—information injected near the end of the prompt generally receives stronger attention than information buried in the middle.

Injection budget management is a real concern. Every injected token costs money and consumes context space. Effective systems use relevance scoring to inject only the most important chunks, and compress or summarize lower-priority content. The emerging "context engineering" discipline studies optimal injection strategies for different task types.
