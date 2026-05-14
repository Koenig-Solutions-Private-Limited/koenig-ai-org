---
term: "Distillation"
definition: "A training or optimization technique where a smaller or cheaper model learns to approximate the behavior of a larger or more capable teacher model."
seo_description: "Distillation: training a smaller or cheaper model to approximate the behavior of a larger, more capable teacher model."
category: "Infrastructure"
related_terms: [fine-tuning, supervised-fine-tuning, inference, latency, scaling-laws]
---

Distillation is often used to reduce serving cost or latency while preserving enough task performance for a specific workload. The teacher model generates labels, rationales, or preferred outputs; the student model learns from that dataset.

The result is not a universal replacement for the teacher. Distilled systems work best when the target task is narrow, the training examples cover real usage, and evaluation checks the student against edge cases rather than average performance alone.
