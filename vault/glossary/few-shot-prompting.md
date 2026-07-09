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

## Related Terms

- [[glossary/prompt-engineering|Prompt Engineering]] — the practice of crafting inputs to elicit reliable, high-quality model outputs
- [[glossary/in-context-learning|In-Context Learning]] — the ability to adapt to a task using only examples in the prompt, without weight updates
- [[glossary/chain-of-thought|Chain of Thought]] — the prompting technique that asks the model to reason step-by-step before answering
- [[glossary/system-prompt|System Prompt]] — the top-level instruction block prepended to every conversation turn
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
