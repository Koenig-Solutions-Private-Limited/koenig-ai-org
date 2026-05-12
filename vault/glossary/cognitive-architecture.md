---
term: "Cognitive Architecture"
definition: "The high-level design of an AI system's information-processing components—perception, memory, reasoning, planning, and action—and the connections between them, analogous to human cognitive psychology frameworks like SOAR and ACT-R."
seo_description: "Cognitive architecture: the design of an AI system's memory, reasoning, planning, and action components and their interconnections."
category: "Agentic AI concepts"
related_terms: [agent-scaffolding, world-model, agent-memory, planning-agent, working-memory, episodic-memory]
---

Cognitive architecture research applies to AI agents the question that occupied cognitive psychologists for decades: what is the minimal set of functional components needed to produce intelligent, flexible behavior? Classic architectures like SOAR (Laird et al.) and ACT-R (Anderson) proposed symbolic structures; modern LLM-based architectures are largely emergent but increasingly informed by these frameworks.

A typical LLM-based cognitive architecture includes: a perception layer (parsing inputs, including image and audio modalities), a working memory (current context window), a long-term memory (external vector store or file system), a reasoning engine (the LLM itself), a planning module (explicit task decomposition), and an action layer (tool calls and output generation).

The key insight from cognitive architecture research is that no single component is sufficient—intelligence emerges from the interaction between them. Agents that fail in complex tasks often have a bottleneck in one layer: insufficient working memory capacity, poor long-term memory retrieval, or no explicit planning before acting.
