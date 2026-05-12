---
term: "System Prompt"
definition: "A privileged instruction block prepended to an LLM conversation that establishes the model's persona, capabilities, constraints, and task context before any user or assistant turns appear."
seo_description: "System prompt: a privileged instruction block that sets an LLM's persona, capabilities, and constraints before user conversation begins."
category: "Agentic AI concepts"
related_terms: [prompt-engineering, few-shot-prompting, agent-soul, prompt-caching, prompt-injection, context-window]
---

The system prompt is the operator's primary lever for shaping model behavior without fine-tuning. It appears at the top of the context window in a dedicated role (typically `"role": "system"` in the Messages API) and is processed before any user messages. Well-crafted system prompts specify: the model's role and persona, what it should and shouldn't do, output format requirements, and available tools.

In agentic systems, the system prompt is often dynamically assembled from modular components: a base SOUL defining the agent's identity, injected memory snippets, the current task context, and the tool schema. Prompt caching is particularly valuable for the stable portions of long system prompts, often achieving cache hit rates above 90% and cutting per-turn costs by 50–80%.

Prompt injection attacks attempt to override the system prompt through adversarial user input. Robust agent designs treat the system prompt as a trust boundary and validate all tool results before injecting them into context.
