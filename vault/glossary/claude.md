---
term: "Claude"
definition: "Anthropic's family of frontier AI assistants and models, commonly used for writing, reasoning, coding, tool use, and agent workflows."
seo_description: "Claude: Anthropic's family of AI assistants and models for writing, reasoning, coding, tool use, and agent workflows."
category: "Products"
related_terms: [anthropic-agent-sdk, claude-agent-sdk, tool-use, reasoning-model, coder-agent]
related_courses: [claude-tool-use-from-zero, production-agents-claude-agent-sdk-mcp-connector]
---

Claude is Anthropic's family of AI models, spanning three tiers designed to cover different points on the capability-cost-latency curve. Haiku is the fastest and cheapest, suited for high-volume classification, extraction, and routing tasks where latency is critical. Sonnet balances capability and cost, making it the default choice for most production workflows. Opus is the most capable tier, reserved for demanding reasoning, complex multi-step tasks, and quality-sensitive generation where cost is secondary.

**Design priorities.** Claude is trained with [[constitutional-ai]], a technique in which the model evaluates and revises its own outputs against a set of principles before finalising a response. This produces a model that tends toward caution, honesty about uncertainty, and refusal of clearly harmful requests — properties that are distinct from raw benchmark performance. The practical consequence is that Claude will sometimes decline or hedge when less-aligned models would comply. For enterprise deployments, this is usually an asset.

**Tool use.** Claude supports structured [[tool-use]] via function calling: the model emits a structured JSON object naming a tool and its arguments, the harness executes the call, and the result is returned to Claude as a tool message. This is the foundation of agent loops where Claude plans actions, receives feedback, and iterates. See [[claude-tool-use-from-zero]] for a ground-up walkthrough.

**Context window and prompt caching.** Claude's context windows are large — up to 200k tokens on current models — enabling long-document analysis and multi-turn agent memory. [[prompt-caching]] is supported natively: when a long system prompt or document prefix is reused across requests, the cached key-value state is served without re-running the full prompt through the model, cutting latency and cost substantially for agent workloads.

**The Claude Agent SDK.** For multi-agent orchestration, Anthropic provides a [[claude-agent-sdk]] that wraps the raw API with patterns for spawning sub-agents, managing tool permissions, and maintaining conversation state across turns. See [[production-agents-claude-agent-sdk-mcp-connector]] for production deployment patterns.

**Common misconception.** The largest Claude model is not always the right choice. Many production workloads run well on Haiku or Sonnet at a fraction of the cost, and [[reasoning-model]] overhead is only justified when the task genuinely requires deep multi-step inference.

## Related Terms

- [[glossary/anthropic-agent-sdk|Anthropic Agent SDK]] — the broader Anthropic toolkit for evaluation, prompt management, and deployment
- [[glossary/claude-agent-sdk|Claude Agent SDK]] — Anthropic's SDK that wraps the API with agent loop, tool, and multi-turn patterns
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/reasoning-model|Reasoning Model]] — a model trained or prompted to perform multi-step deliberate reasoning before answering
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
