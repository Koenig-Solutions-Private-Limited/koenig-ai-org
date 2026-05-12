---
term: "Reasoning Model"
definition: "A reasoning model is an LLM specifically fine-tuned or trained to prioritize extended, multi-step chain-of-thought processing over immediate response generation."
seo_description: "Reasoning models explained: LLMs designed for complex multi-step reasoning."
category: "model-architecture"
related_terms: [chain-of-thought, inference-time-compute, agentic-loop]
related_courses: [picking-a-frontier-model-2026-q2]
---

Reasoning models (like Anthropic's Opus with thinking or OpenAI's o-series) do not just predict the next token. They perform a 'thinking' or 'reasoning' step, often involving multiple internal drafts or verification loops before producing the final response. This shift significantly reduces hallucination rates for complex tasks like multi-file coding or multi-agent orchestration.
