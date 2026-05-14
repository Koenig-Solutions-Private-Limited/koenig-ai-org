---
term: "Recall"
definition: "An evaluation metric that measures how many actual positive cases the system successfully found."
seo_description: "Recall: an evaluation metric that measures how many actual positive cases a system successfully found."
category: "Evaluation concepts"
related_terms: [precision, f1-score, confusion-matrix, classifier, retrieval]
---

Recall answers: of all the things the system should have found, how many did it catch? It is important when misses are costly, such as failing to detect unsafe content, missing a relevant document, or overlooking a critical incident.

High recall can come with more false positives. Many production systems tune thresholds based on the downstream workflow: high recall for triage, higher precision for irreversible actions.
