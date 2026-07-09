---
term: "F1 Score"
definition: "A metric that combines precision and recall into a single harmonic mean, commonly used when false positives and false negatives both matter."
seo_description: "F1 score: a harmonic mean of precision and recall used when both false positives and false negatives matter."
category: "Evaluation concepts"
related_terms: [precision, recall, confusion-matrix, classifier, agent-evaluation]
related_courses: [picking-a-frontier-model-2026-q2]
---

F1 score is useful when accuracy hides class imbalance. For example, a system that says every document is safe may look accurate if unsafe documents are rare, but its [[recall]] for unsafe cases is zero.

Because F1 compresses two error types into one number, teams should still inspect [[precision]] and [[recall]] separately. A high-F1 system may be unacceptable if one kind of error carries much higher user, legal, or operational cost.

**The formula** is F1 = 2 × P × R / (P + R), where P is [[precision]] and R is [[recall]]. This is the harmonic mean of the two values. The harmonic mean penalizes imbalance more severely than the arithmetic mean: a system with perfect precision but zero recall scores F1 = 0, not 0.5. This is by design — a system that never fires avoids false positives but provides no value, and F1 should reflect that.

**F-beta variants** let teams weight the two error types differently. F-beta = (1 + β²) × P × R / (β² × P + R). Setting β > 1 increases the weight on [[recall]], useful for safety or fraud detection where missing a true positive is more costly than a false alarm. Setting β < 1 increases the weight on [[precision]], useful for content recommendation or legal document review where false positives waste expert time.

**Multi-class settings** introduce three aggregation strategies. Macro F1 computes F1 per class and averages them equally, giving equal weight to rare and common classes. Micro F1 aggregates counts across all classes before computing, making it dominated by the most frequent class. Weighted F1 averages per-class F1 scores weighted by class frequency, balancing between the two.

**Practical AI use cases** where F1 is the right primary metric include content moderation (both passing unsafe content and blocking safe content are costly), intent detection (missing an intent and misfiring both degrade user experience), and information extraction (false extractions and missed extractions equally harm downstream tasks).

**Where F1 still misleads.** In highly imbalanced datasets, even a low recall on the rare class can be masked by strong performance on the majority class. Always inspect the per-class [[confusion-matrix]] alongside F1, and consider whether the imbalance in your production data matches your [[evals]] data. See [[picking-a-frontier-model-2026-q2]] for how these metrics factor into model selection decisions in real deployments.

## Related Terms

- [[glossary/precision|Precision]] — the fraction of positive predictions that are actually correct
- [[glossary/recall|Recall]] — the fraction of true positives that the model successfully identifies
- [[glossary/confusion-matrix|Confusion Matrix]] — the matrix that tabulates true/false positive and negative counts for a classifier
- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
