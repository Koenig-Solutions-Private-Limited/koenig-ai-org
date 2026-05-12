---
term: "Memory Bank"
definition: "A Memory Bank is a persistent, structured storage pattern used by AI agents to maintain state, user preferences, and project context across multiple sessions and disparate conversations."
seo_description: "Memory Bank pattern explained: how AI agents maintain long-term persistent context across sessions."
category: "agent-architecture"
related_terms: [agent-memory, episodic-memory, semantic-memory]
related_courses: [gemini-enterprise-agents]
sameAs: []
---

A Memory Bank separates the short-term context of a single chat conversation from the long-term, persistent state of the agent's work. Unlike a vector database that holds raw RAG context, a Memory Bank typically stores highly structured information about project milestones, user preferences, configuration, and state-of-the-world, enabling agents to operate with continuity over days or weeks of interaction.
