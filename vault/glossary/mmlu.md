---
term: "MMLU"
definition: "Massive Multitask Language Understanding, a broad benchmark that tests model performance across many academic and professional multiple-choice subjects."
seo_description: "MMLU: a broad benchmark that tests model performance across many academic and professional multiple-choice subjects."
category: "Evaluation concepts"
related_terms: [benchmark-suite, evals, reasoning-model, agent-evaluation, classifier]
---

MMLU (Massive Multitask Language Understanding) is a multiple-choice benchmark spanning 57 subjects from elementary mathematics and US history to professional law, medicine, and computer science. With over 14,000 questions, it tests breadth of knowledge more than any other single benchmark in common use. The evaluation metric is accuracy: the fraction of 4-way multiple-choice questions answered correctly, reported per subject and as an overall aggregate.

**Why it became the standard general-capability benchmark.** Before MMLU, most language benchmarks tested narrow capabilities: reading comprehension on a single domain, commonsense reasoning on curated sentence pairs, or arithmetic on synthetic problems. MMLU's breadth meant that a model could not score well by overfitting to one type of task. A high MMLU score is a credible signal that the model has absorbed a wide range of human knowledge in a usable form.

**MMLU-Pro.** The original benchmark has been partially saturated by frontier models, prompting the creation of MMLU-Pro, which increases question difficulty and requires more reasoning steps rather than direct knowledge recall. It is more aligned with how [[reasoning-model]] architectures are evaluated in 2025-2026.

**The saturation problem.** As of mid-2026, frontier models achieve very high accuracy on the original MMLU — differences between leading models are often within noise. This means MMLU no longer reliably differentiates the top tier. It remains useful for comparing a new model against historical baselines or screening smaller/cheaper models, but it does not discriminate well at the frontier.

**What MMLU does not test.** MMLU's multiple-choice format has significant blind spots. It does not evaluate generation quality, instruction-following, structured output formatting, [[tool-use]], multi-turn reasoning, or latency. A model can score near-perfectly on MMLU and still produce poor JSON outputs, ignore formatting constraints, or fail at agentic tasks. It says nothing about cost per token, which often drives production model selection more than capability at the margin.

**Common mistake.** Using MMLU as a proxy for production readiness is the most frequent misuse of this benchmark. High MMLU accuracy does not predict whether a model will follow a complex [[system-prompt]], produce valid structured data, or behave reliably in an [[agent-loop]] under tool-call pressure. Task-specific [[evals]] on representative inputs remain the correct instrument. See [[benchmark-suite]], [[humaneval]], [[swe-bench]], and [[picking-a-frontier-model-2026-q2]] for a more complete evaluation framework.

## Related Terms

- [[glossary/benchmark-suite|Benchmark Suite]] — a collection of standardised tasks used to compare model capabilities across dimensions
- [[glossary/evals|Evals]] — the structured evaluation framework that measures model quality against defined criteria
- [[glossary/reasoning-model|Reasoning Model]] — a model trained or prompted to perform multi-step deliberate reasoning before answering
- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
