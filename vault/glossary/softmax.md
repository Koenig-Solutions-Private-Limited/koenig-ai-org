---
term: "Softmax"
definition: "A mathematical function that converts a vector of raw scores (logits) into a probability distribution by exponentiating each score and normalizing by their sum, ensuring all outputs are positive and sum to 1."
seo_description: "Softmax: the function that converts LLM logits into a valid probability distribution by exponentiation and normalization."
category: "LLM concepts"
related_terms: [temperature, logprobs, cross-entropy, attention-mechanism, sampling-parameters]
---

Softmax(x_i) = exp(x_i) / Σ_j exp(x_j). In language model inference, the logit vector has dimension equal to the vocabulary size (typically 32K–200K tokens), and softmax converts it to a probability distribution from which the next token is sampled. Temperature scaling (dividing logits by T before softmax) controls distribution sharpness.

Numerically stable softmax implementations subtract the maximum logit before exponentiation to prevent overflow: softmax(x_i) = exp(x_i - max(x)) / Σ_j exp(x_j - max(x)). This is standard practice in all production ML frameworks.

In the attention mechanism, softmax normalizes the query-key dot products to produce attention weights that sum to 1 over the sequence positions. FlashAttention and other efficient attention implementations avoid materializing the full attention matrix, instead computing softmax in tiles to reduce memory usage—this is the key innovation enabling long-context models.
