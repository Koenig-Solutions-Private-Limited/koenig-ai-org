---
term: "Capability Overhang"
definition: "A situation where an AI model possesses underlying capabilities that are not apparent in standard evaluations, which may be unlocked by better prompting, fine-tuning, or scaffolding—creating a gap between measured and achievable performance."
seo_description: "Capability overhang: hidden LLM capabilities not visible in standard evals, potentially unlocked by better prompting, fine-tuning, or scaffolding."
category: "LLM concepts"
related_terms: [emergent-abilities, scaling-laws, alignment-tax, in-context-learning, fine-tuning, benchmark]
---

Capability overhang describes the gap between what a model can do under optimal conditions and what standard benchmarks measure. A model trained on a broad task distribution may have latent skills that only surface with the right prompt format, few-shot examples, or scaffolding. Jailbreaking research demonstrates an extreme case: safety-trained behaviors can be bypassed, suggesting the underlying capability was always present.

The concept has safety implications: if a model's capabilities significantly exceed its measured performance, alignment efforts based on measured behavior may underestimate the model's true risk profile. A model that appears incapable of harmful synthesis in standard evaluations might be capable under adversarial prompting.

Capability overhang also has positive implications: systematic prompt engineering and task-specific fine-tuning can unlock substantial performance improvements without retraining. Chain-of-thought prompting unlocked mathematical reasoning that appeared absent in earlier evaluations. Extended thinking in Claude Sonnet 4.7 suggests significant performance improvements available from additional inference compute on models whose base capabilities were previously saturated.

## Related Terms

- [[glossary/emergent-abilities|Emergent Abilities]] — capabilities that appear in large models but are absent in smaller ones at the same task
- [[glossary/scaling-laws|Scaling Laws]] — the empirical relationships between model size, compute, data, and performance
- [[glossary/alignment-tax|Alignment Tax]] — the performance reduction that can result from applying safety and alignment training
- [[glossary/in-context-learning|In-Context Learning]] — the ability to adapt to a task using only examples in the prompt, without weight updates
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
