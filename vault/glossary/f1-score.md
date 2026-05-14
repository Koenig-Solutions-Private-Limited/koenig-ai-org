---
term: "F1 Score"
definition: "A metric that combines precision and recall into a single harmonic mean, commonly used when false positives and false negatives both matter."
seo_description: "F1 score: a harmonic mean of precision and recall used when both false positives and false negatives matter."
category: "Evaluation concepts"
related_terms: [precision, recall, confusion-matrix, classifier, agent-evaluation]
---

F1 score is useful when accuracy hides class imbalance. For example, a system that says every document is safe may look accurate if unsafe documents are rare, but its recall for unsafe cases is zero.

Because F1 compresses two error types into one number, teams should still inspect precision and recall separately. A high-F1 system may be unacceptable if one kind of error carries much higher user, legal, or operational cost.
