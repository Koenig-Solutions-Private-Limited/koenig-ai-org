---
term: "In-Context Learning"
definition: "The ability of a language model to adapt its behavior to new tasks by reading examples or instructions in its context window, without any gradient updates to its weights."
seo_description: "In-context learning: an LLM's ability to perform new tasks by reading examples in its context window, without any weight updates."
category: "LLM concepts"
related_terms: [few-shot-prompting, prompt-engineering, emergent-abilities, fine-tuning, chain-of-thought]
---

In-context learning (ICL) is one of the most surprising emergent capabilities of large language models. A model that has never been explicitly trained on a task can perform it reliably if given a few examples in the prompt. The mechanism is not fully understood: hypotheses include ICL as implicit Bayesian inference, gradient descent in activation space, or retrieval from training data.

ICL quality scales with model size and the quality of the examples provided. Larger models extract more signal from fewer examples and are more robust to noisy or imperfect examples. The choice of example format, order, and coverage of the input space all affect ICL performance non-trivially.

ICL has a fundamental limitation: the context window sets a hard ceiling on the number of examples, and performance generally plateaus before that ceiling. For tasks requiring hundreds or thousands of examples to master, supervised fine-tuning is more effective. The practical choice between ICL and fine-tuning depends on task difficulty, data availability, latency requirements, and inference cost.

## Related Terms

- [[glossary/few-shot-prompting|Few-Shot Prompting]] — the technique of including worked examples in the prompt to steer model behaviour
- [[glossary/prompt-engineering|Prompt Engineering]] — the practice of crafting inputs to elicit reliable, high-quality model outputs
- [[glossary/emergent-abilities|Emergent Abilities]] — capabilities that appear in large models but are absent in smaller ones at the same task
- [[glossary/fine-tuning|Fine-tuning]] — the weight-update process that adapts a pre-trained base model for downstream tasks
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
