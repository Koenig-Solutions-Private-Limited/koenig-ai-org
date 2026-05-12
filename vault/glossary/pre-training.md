---
term: "Pre-training"
definition: "The initial large-scale training phase of a language model in which it learns to predict the next token (or masked tokens) over a massive text corpus, establishing general language understanding before any task-specific fine-tuning."
seo_description: "Pre-training: the large-scale phase where an LLM learns language from a massive text corpus before task-specific fine-tuning begins."
category: "LLM concepts"
related_terms: [instruction-tuning, fine-tuning, scaling-laws, transformer, tokenization, in-context-learning]
---

Pre-training is the most computationally expensive phase of LLM development, consuming tens of thousands of GPU-hours and petabytes of training data. The objective is self-supervised: the model predicts the next token (causal language modeling) or reconstructs masked tokens (masked language modeling, used in BERT). No human-labeled data is required; the supervision signal comes from the data itself.

The resulting pre-trained model has broad language capabilities—it can complete sentences, continue code, summarize text—but is not aligned to follow instructions or behave safely. This is the "base model" stage. GPT-4 base, Claude base (before RLHF), and Llama 3 base are examples of pre-trained-only models, generally not deployed directly to users.

Pre-training quality depends on dataset curation (deduplication, quality filtering, domain mix), compute budget, and architecture. Chinchilla scaling laws (Hoffmann et al., 2022) established that training longer on more data with a smaller model often outperforms training shorter with a larger model for the same compute budget, reshaping how frontier labs allocate their training runs.
