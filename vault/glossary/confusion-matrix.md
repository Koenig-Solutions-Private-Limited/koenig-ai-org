---
term: "Confusion Matrix"
definition: "A table that compares predicted labels against true labels, showing counts of true positives, false positives, true negatives, and false negatives."
seo_description: "Confusion matrix: a table comparing predicted labels with true labels to show true positives, false positives, true negatives, and false negatives."
category: "Evaluation concepts"
related_terms: [precision, recall, f1-score, agent-evaluation, classifier]
related_courses: [picking-a-frontier-model-2026-q2]
---

A confusion matrix is a grid that breaks a [[classifier]]'s predictions into four cells: true positives (TP), where the model correctly predicted the positive class; false positives (FP), where the model predicted positive but the true label was negative; false negatives (FN), where the model missed a positive case; and true negatives (TN), where the model correctly predicted the negative class. Reading the matrix reveals not just how often the system is wrong but what kind of wrong it is.

**Why accuracy alone misleads.** Consider a content moderation system where 99% of requests are safe. A classifier that always predicts "safe" achieves 99% accuracy while having zero ability to catch anything harmful. The confusion matrix exposes this immediately: the FN cell shows every missed harmful case, and the TP cell is zero. Accuracy hides this because it weights all cells equally regardless of class frequency.

**Deriving [[precision]] and [[recall]].** Precision is TP / (TP + FP) — of all positive predictions, how many were correct. Recall is TP / (TP + FN) — of all true positives, how many were caught. [[f1-score]] is the harmonic mean of the two. These metrics connect directly to the confusion matrix and expose the precision-recall tradeoff: lowering the decision threshold increases recall (fewer misses) at the cost of more false alarms, and vice versa.

**Threshold tuning.** The matrix is threshold-dependent. Most classifiers output a probability score; the binary label is determined by a threshold (default 0.5). Plotting the confusion matrix at multiple thresholds — or equivalently, reading the ROC curve — lets teams choose a threshold based on the business cost of each error type. A medical diagnosis system may accept many FPs to avoid a single FN; a spam filter may accept FNs to avoid FPs that delete legitimate email.

**Multi-class extension.** For classifiers with N output labels, the matrix is N×N. Each row represents the true label; each column represents the predicted label. Off-diagonal cells are misclassifications. Common multi-class applications in AI systems include intent classification (routing queries to the right agent), topic labelling, and language identification.

**AI product applications.** Confusion matrices are essential when evaluating [[agent-evaluation]] components — routing agents, safety filters, extraction models, and [[classifier]] layers that gate what reaches a more expensive downstream model. See [[picking-a-frontier-model-2026-q2]] for how evaluation tools like this feed into model selection decisions.

## Related Terms

- [[glossary/precision|Precision]] — the fraction of positive predictions that are actually correct
- [[glossary/recall|Recall]] — the fraction of true positives that the model successfully identifies
- [[glossary/f1-score|F1 Score]] — the harmonic mean of precision and recall used to evaluate information-extraction quality
- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
