---
term: "Confusion Matrix"
definition: "A table that compares predicted labels against true labels, showing counts of true positives, false positives, true negatives, and false negatives."
seo_description: "Confusion matrix: a table comparing predicted labels with true labels to show true positives, false positives, true negatives, and false negatives."
category: "Evaluation concepts"
related_terms: [precision, recall, f1-score, agent-evaluation, classifier]
---

A confusion matrix makes classification errors visible. Instead of reducing a classifier to a single accuracy number, it shows which labels are being confused and whether the system is failing through false alarms or missed detections.

For AI product work, this matters when evaluating moderation, routing, extraction, intent detection, and safety filters. The operational cost of a false positive can be very different from the cost of a false negative, so the matrix helps teams tune thresholds and review queues.
