---
term: "Distillation"
definition: "A training or optimization technique where a smaller or cheaper model learns to approximate the behavior of a larger or more capable teacher model."
seo_description: "Distillation: training a smaller or cheaper model to approximate the behavior of a larger, more capable teacher model."
category: "Infrastructure"
related_terms: [fine-tuning, supervised-fine-tuning, inference, latency, scaling-laws]
related_courses: [picking-a-frontier-model-2026-q2]
---

Distillation is a training technique in which a large, capable teacher model generates outputs that a smaller student model is then trained to reproduce. The student does not learn directly from raw human-labelled data; it learns from the teacher's behaviour, which carries richer signal than a binary correct/incorrect label.

**How it works.** In response distillation, the teacher is run over a set of prompts and generates full completions — or, in reasoning-oriented variants, chain-of-thought traces with intermediate steps. The student is then fine-tuned on these completions. The teacher's probability distribution over tokens (soft labels) is often used directly rather than just the top-1 prediction, because the distribution encodes the teacher's uncertainty and secondary plausible answers. This extra signal is why distillation tends to outperform training the small model from scratch on the same inputs using only human labels.

**Response vs. feature distillation.** Response distillation trains the student on the teacher's outputs. Feature distillation, more common in computer vision, trains the student to match the teacher's intermediate layer activations as well. In large language model settings, response distillation is more practical because intermediate activations are expensive to store and architecture-dependent.

**[[latency]] and cost improvements.** A distilled student model running at inference time consumes fewer FLOPs per token, fits on smaller hardware, and responds faster. For high-throughput production workloads where [[inference]] cost dominates, this is a significant lever. The student's [[latency]] advantage is structural — it has fewer parameters — rather than depending on quantisation or other post-training compression.

**Limitations.** A student cannot surpass the teacher on the distilled task. It approximates, never exceeds. The student also generalises less broadly: it has learned to mimic the teacher on the training distribution, not to reason independently. When inputs fall outside that distribution, the student degrades faster than the teacher.

**Difference from [[fine-tuning]].** [[supervised-fine-tuning]] trains a model on curated human-labelled examples. Distillation trains on teacher-generated examples. The two can be combined: a [[fine-tuning]] run on human labels followed by distillation on teacher outputs often produces the best small-model results. In practice, the teacher for distillation is often the same frontier model that you want to deploy cheaply — see [[picking-a-frontier-model-2026-q2]] for how capability tiers and [[scaling-laws]] inform the teacher/student split decision.

**Production pattern.** Deploy the student for common, well-covered cases. Route hard cases — low confidence, out-of-distribution inputs, high-stakes decisions — to the teacher. This tiered architecture captures most of the cost savings while preserving quality where it matters.

## Related Terms

- [[glossary/fine-tuning|Fine-tuning]] — the weight-update process that adapts a pre-trained base model for downstream tasks
- [[glossary/supervised-fine-tuning|Supervised Fine-Tuning]] — the weight-update process that adapts a pre-trained model to a target task using labeled data
- [[glossary/inference|Inference]] — the process of running a trained model forward to generate output
- [[glossary/latency|Latency]] — the elapsed time from request submission to first token or full response received
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
