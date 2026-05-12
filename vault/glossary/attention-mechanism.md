---
term: "Attention Mechanism"
definition: "A neural network component that computes a weighted sum of value vectors based on query-key similarity scores, allowing the model to selectively focus on relevant parts of its input regardless of positional distance."
seo_description: "Attention mechanism: the neural network component that lets LLMs selectively focus on relevant input positions by computing query-key similarity scores."
category: "LLM concepts"
related_terms: [transformer, multi-head-attention, kv-cache, positional-encoding, context-length]
---

Attention was introduced in Bahdanau et al. (2015) for sequence-to-sequence models and generalized to the self-attention variant in the "Attention Is All You Need" paper (Vaswani et al., 2017) that defined the Transformer architecture. For each position in the sequence, attention computes a query vector, compares it against key vectors at all positions, converts similarity scores to weights via softmax, and outputs a weighted sum of value vectors.

Self-attention allows each token to directly attend to every other token, capturing long-range dependencies without the recurrence bottleneck of RNNs. The computational cost is O(n²) in sequence length, which is the primary constraint on context window size for standard attention. Variants like FlashAttention optimize memory access patterns to make this quadratic scaling tractable for sequences up to 200K+ tokens.

Sparse attention (Longformer, BigBird) and linear attention approximations reduce the quadratic bottleneck for extremely long contexts but typically sacrifice some quality. Rotary Positional Embeddings (RoPE) and ALiBi extend effective attention distance beyond training lengths, enabling the long-context capabilities seen in Claude 3.7+ and Gemini 2.5.
