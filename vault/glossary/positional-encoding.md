---
term: "Positional Encoding"
definition: "A mechanism that injects information about the position of each token in a sequence into a transformer model, compensating for the permutation-invariance of self-attention and enabling the model to understand word order."
seo_description: "Positional encoding: the mechanism that injects token position information into transformers, enabling word-order awareness in self-attention."
category: "LLM concepts"
related_terms: [transformer, attention-mechanism, context-length, multi-head-attention, embedding]
---

Pure self-attention is permutation-equivariant: shuffling the input tokens produces the same attention patterns, just rearranged. To distinguish "dog bites man" from "man bites dog," the model needs positional information. Original transformers used sinusoidal positional encodings added to token embeddings; these were later replaced by learned absolute positional embeddings.

Rotary Positional Embeddings (RoPE, Su et al., 2021) encode position by rotating the query and key vectors in attention, making the dot product naturally dependent on relative position. RoPE enables efficient extrapolation to longer sequences than seen during training and is used by Llama 3, Mistral, and most recent open-source models. ALiBi (Attention with Linear Biases) takes a different approach, adding a linear position bias to attention logits.

Context length extension techniques (YaRN, LongRoPE) scale RoPE to longer contexts by adjusting the rotation frequencies. These techniques allowed Claude 3.7, Llama 3 Long, and similar models to extend from 8K–32K training context to 128K+ deployment context with minimal fine-tuning.

## Related Terms

- [[glossary/transformer|Transformer]] — the neural architecture underlying virtually all modern LLMs
- [[glossary/attention-mechanism|Attention Mechanism]] — the core transformer operation that weights token relationships to compute representations
- [[glossary/context-length|Context Length]] — the maximum number of tokens the model can process in a single call
- [[glossary/multi-head-attention|Multi-Head Attention]] — the parallel attention computation that lets transformers attend to different representation subspaces
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
