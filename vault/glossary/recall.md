---
term: "Recall"
definition: "An evaluation metric that measures how many actual positive cases the system successfully found."
seo_description: "Recall: an evaluation metric that measures how many actual positive cases a system successfully found."
category: "Evaluation concepts"
related_terms: [precision, f1-score, confusion-matrix, classifier, retrieval]
---

Recall measures how completely a system surfaces what it should. Formally, recall = TP / (TP + FN): the number of true positives divided by all actual positives (true positives plus false negatives). A recall of 0.95 means the system found 95% of the relevant items and missed only 5%.

**What high recall means operationally.** A high-recall system generates few missed detections. This is the right priority whenever the cost of a miss is high: a content-safety classifier that misses harmful outputs, a medical screening tool that misses a positive diagnosis, a security incident detector that overlooks an attack, or a [[retrieval]] pipeline that fails to surface the document that would have answered the user's question. In each case the downstream harm of silence outweighs the friction of a false alarm.

**Recall in RAG pipelines.** In [[retrieval]]-augmented generation, recall asks: of all the documents in the corpus that were relevant to the query, how many did the retrieval step actually return? Low retrieval recall means the [[llm]] is asked to answer from an incomplete evidence set, which is a primary driver of [[hallucination]].

**The precision-recall tradeoff.** Maximising recall is not always correct. Lowering a classification threshold to catch more positives also increases false positives, adding noise for downstream steps, human reviewers, or users. A spam filter with perfect recall flags legitimate email; a document retriever with perfect recall floods the context window with irrelevant passages that dilute the signal. The [[f1-score]] is the harmonic mean of [[precision]] and recall, useful when both errors carry cost. [[confusion-matrix]] analysis breaks down all four outcome types and is the standard first step when debugging threshold choices.

**Recall vs. coverage.** Recall is a proportion of the true positives that exist; coverage is a broader term in retrieval systems that often refers to the fraction of possible queries that can be answered at all given the indexed corpus. Coverage is a corpus-design concern; recall is a retrieval-quality concern.

**Common misconception.** Higher recall is not unconditionally better. In high-volume production pipelines, unnecessary false positives impose real costs: operator review time, model inference on junk inputs, latency, or user trust erosion. Production systems tune thresholds based on downstream workflow: high recall for triage stages, higher [[precision]] at irreversible decision points. Task-specific [[evals]] tied to real business outcomes are the correct instrument for setting that threshold. See [[picking-a-frontier-model-2026-q2]] for how recall trade-offs factor into model selection decisions.

## Related Terms

- [[glossary/precision|Precision]] — the fraction of positive predictions that are actually correct
- [[glossary/f1-score|F1 Score]] — the harmonic mean of precision and recall used to evaluate information-extraction quality
- [[glossary/confusion-matrix|Confusion Matrix]] — the matrix that tabulates true/false positive and negative counts for a classifier
- [[glossary/retrieval|Retrieval]] — the query-time lookup that pulls relevant chunks from an external store
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
