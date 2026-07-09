---
term: "Active Learning"
definition: "A machine learning paradigm where the algorithm interactively queries a labeling oracle—usually a human—to annotate the most informative data points, dramatically reducing the labeling cost required to reach target performance."
seo_description: "Active learning: the ML technique where an algorithm selects its own most informative training examples, reducing labeling cost while improving model performance."
category: "LLM concepts"
related_terms: [supervised-fine-tuning, fine-tuning, evals, rlhf, instruction-tuning]
related_courses: [picking-a-frontier-model-2026-q2]
---

**Active learning** inverts the normal data-collection process. Instead of labeling a large random sample and training on all of it, an active learning system identifies which unlabeled examples would most improve the model if labeled, asks a human (or another model) to label only those, and updates iteratively. The practical payoff is large: studies routinely show that active learning can match the performance of full-dataset training using 10–30% of the labels, which matters when expert annotation is expensive or slow.

Three classic selection strategies drive most active learning systems. Uncertainty sampling picks examples the current model is least confident about. Diversity sampling picks examples from underrepresented regions of the input space. Query-by-committee runs multiple models and picks examples where they disagree. Modern systems often combine these signals, or use a learned acquisition function that predicts which examples will improve downstream performance the most. The right strategy depends on the task, the annotation cost, and whether the labeler is a human expert or a teacher model.

For large language models, active learning surfaces in [[rlhf]] and [[instruction-tuning]] pipelines: a reward model's weakest predictions identify which human comparisons to collect next, rather than collecting comparisons uniformly. It also appears in [[evals]]: instead of evaluating on a fixed benchmark, teams can iteratively discover which kinds of prompts reveal model weaknesses and add those to the test set. A common misconception is that active learning always requires a human in the loop—automated teacher models (data distillation, LLM labelers) qualify as the oracle in many modern pipelines, as long as the selected examples genuinely improve the student. See [[picking-a-frontier-model-2026-q2]] for how active evaluation design connects to model selection decisions.

## Related Terms

- [[glossary/supervised-fine-tuning|Supervised Fine-Tuning]] — the training stage active learning targets, selecting the highest-value examples to label before a full SFT run
- [[glossary/fine-tuning|Fine-tuning]] — the broader weight-update process active learning reduces the labeled-data cost of
- [[glossary/evals|Evals]] — the evaluation framework where active selection identifies which prompt types best reveal model weaknesses
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — covers active evaluation design for agent workflows where the labeling oracle is an LLM rather than a human
