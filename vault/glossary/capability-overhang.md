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
