---
term: "Precision"
definition: "An evaluation metric that measures how many positive predictions were actually correct."
seo_description: "Precision: an evaluation metric that measures how many positive predictions were actually correct."
category: "Evaluation concepts"
related_terms: [recall, f1-score, confusion-matrix, classifier, agent-evaluation]
related_courses: [picking-a-frontier-model-2026-q2]
---

Precision answers: when the system says yes, how often is it right? It is especially important when false positives are expensive, such as incorrectly flagging safe content, routing a ticket to the wrong expert, or blocking a legitimate action.

Precision usually trades off against [[recall]]. Raising a classifier threshold can reduce false positives and improve precision, but it may also miss more true positives.

**Formal definition.** Precision = TP / (TP + FP), where TP is true positives (correct positive predictions) and FP is false positives (predictions the model called positive that were actually negative). Read in plain terms: of all the times the system said "yes", how many of those were actually "yes"?

**When precision is the primary metric.** Choose precision as your headline metric when false alarms carry significant cost. In fraud detection, each false positive triggers a time-consuming human review; a low-precision system burns reviewer capacity on legitimate transactions. In content safety systems for enterprise workflows, falsely blocking a legitimate action erodes user trust rapidly. In legal or compliance document review, a false positive sent to a lawyer for review has real monetary cost per instance.

**Precision@k for retrieval.** In [[rag]] and [[retrieval]] systems, precision@k asks: of the top k documents returned, how many are actually relevant? This is distinct from classification precision but follows the same logic — it penalizes the system for surfacing irrelevant material in prime positions. High precision@k means users can trust the top results; low precision@k means the top of the list is noisy.

**Precision vs. accuracy.** Accuracy counts all correct predictions (TP + TN) divided by all predictions. In imbalanced datasets where one class dominates, accuracy is misleading — a model that always predicts the majority class can be highly accurate while having zero precision on the minority class. Precision focuses only on the positive-class predictions, making it meaningful regardless of class imbalance.

**The optimization trap.** A classifier that only fires when it is nearly certain will achieve very high precision. But its [[recall]] will be near zero — it misses most true positives. This maximizes precision at the cost of usefulness. [[f1-score]] captures this tradeoff, and the full precision-[[recall]] curve shows how the two metrics shift as the decision threshold changes. Examining the [[confusion-matrix]] alongside aggregate metrics is essential for understanding where a system is actually failing.

Threshold calibration should be driven by your specific cost function, not by convention. See [[evals]] for how to build test sets that surface precision failures, and [[picking-a-frontier-model-2026-q2]] for how precision requirements shape model selection.

## Related Terms

- [[glossary/recall|Recall]] — the fraction of true positives that the model successfully identifies
- [[glossary/f1-score|F1 Score]] — the harmonic mean of precision and recall used to evaluate information-extraction quality
- [[glossary/confusion-matrix|Confusion Matrix]] — the matrix that tabulates true/false positive and negative counts for a classifier
- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
