---
term: "Few-Shot Prompting"
definition: "A prompting technique in which a small number of input-output examples are included in the prompt to demonstrate the desired task format or reasoning pattern, enabling the model to generalize to new instances."
seo_description: "Few-shot prompting: including example input-output pairs in a prompt to teach an LLM the desired format or reasoning pattern."
category: "Agentic AI concepts"
related_terms: [prompt-engineering, in-context-learning, chain-of-thought, system-prompt, zero-shot]
---

Few-shot prompting exploits in-context learning: modern LLMs can infer a task's pattern from just a handful of examples without weight updates. Two to eight examples typically saturate the gains; adding more rarely helps and wastes context. Examples should be diverse, correctly labeled, and representative of the input distribution the model will encounter at test time.

The format of examples matters as much as their content. Chain-of-thought few-shot prompting (Wei et al., 2022) interleaves reasoning steps between input and output, dramatically improving performance on multi-step tasks like math and logic. This technique transfers well to tool-calling scenarios where the agent should reason before selecting a tool.

Few-shot prompting is less effective when the task requires knowledge not present in the model's training data—in such cases, retrieval-augmented generation or fine-tuning is a better fit. It also costs tokens, which is a non-trivial consideration in high-volume agentic systems with per-token pricing.
