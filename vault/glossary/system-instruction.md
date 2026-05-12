---
term: "System Instruction"
definition: "System instructions (also called system prompt or meta-prompt) define the core behavioral constraints, goals, and persona of an AI model, set at the start of a session before any user input is processed."
seo_description: "System instructions explained: the behavioral framework for AI agents."
category: "prompt-engineering"
related_terms: [prompt, system-prompt, constitutional-ai]
related_courses: [gemini-enterprise-agents]
---

System instructions are the primary mechanism for aligning a model with its operational goals. They define what the agent *is*, what it *does*, and what its *boundaries* are. In robust agent design, system instructions are often treated as immutable configuration rather than dynamic prompt input, and they are typically the first tokens cached in a prompt-caching pipeline.
