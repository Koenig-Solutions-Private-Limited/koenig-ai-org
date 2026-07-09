---
term: "Cross-Entropy"
definition: "The information-theoretic loss function used to train language models, measuring the average number of bits needed to encode the true next token under the model's predicted distribution—minimizing it is equivalent to maximizing likelihood."
seo_description: "Cross-entropy: the training loss for LLMs that measures divergence between predicted and true token distributions, minimized to maximize likelihood."
category: "LLM concepts"
related_terms: [perplexity, pre-training, softmax, logprobs, scaling-laws]
---

Cross-entropy loss H(p, q) = -Σ p(x) log q(x), where p is the true distribution (one-hot over the correct token) and q is the model's predicted distribution. For language modeling, this simplifies to -log q(correct_token). Minimizing cross-entropy is equivalent to maximizing the log-likelihood of the training data, which is equivalent to minimizing KL divergence from the data distribution.

The relationship between cross-entropy and perplexity is: PPL = exp(cross-entropy). So a cross-entropy of 2.3 nats (log base e) corresponds to a perplexity of e^2.3 ≈ 10. This makes cross-entropy and perplexity interchangeable as training progress metrics.

Cross-entropy has known limitations as a standalone training objective for LLMs: it treats all tokens equally, even though predicting "the" is much easier than predicting a rare technical term. Weighted cross-entropy variants up-weight important tokens, and recent work uses reward signals to move beyond pure likelihood maximization toward outcome-based objectives (RLHF, DPO).

## Related Terms

- [[glossary/perplexity|Perplexity]] — the exponentiated average negative log-likelihood used to measure how well a model predicts text
- [[glossary/pre-training|Pre-training]] — the large-scale unsupervised training run that teaches the model language and world knowledge
- [[glossary/softmax|Softmax]] — the normalisation function that converts raw logits into probability distributions
- [[glossary/logprobs|Logprobs]] — the log-probabilities of candidate tokens returned alongside the model's chosen token
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
