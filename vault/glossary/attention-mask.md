---
term: "Attention Mask"
definition: "A binary or float tensor applied during transformer self-attention that marks which input positions the model should attend to and which should be ignored—primarily used to prevent padding tokens from influencing learned representations."
seo_description: "Attention mask: the tensor mechanism that tells a transformer which input positions to process and which to ignore during self-attention computation."
category: "LLM concepts"
related_terms: [transformer, attention-mechanism, context-length, tokenization, kv-cache]
related_courses: [picking-a-frontier-model-2026-q2]
---

The **attention mask** controls which tokens participate in the [[attention-mechanism|self-attention]] computation. During training, sequences in a batch are padded to the same length with special tokens. Without masking, those padding positions would produce gradients that corrupt the model's representations. The mask assigns value 1 to real tokens and 0 to padding, and during softmax computation, masked positions receive a very large negative value that reduces their weight to effectively zero.

There are two kinds of masks used in practice. A **padding mask** handles variable-length batches by masking out padding tokens at the end of shorter sequences. A **causal mask** (also called a look-ahead mask or autoregressive mask) prevents each position from attending to future positions, ensuring that the model can only condition its prediction for token `t` on tokens at positions `< t`. The causal mask is what makes decoder-only transformer models like GPT and Claude generate tokens left-to-right rather than in arbitrary order.

For practitioners working with model APIs, attention masks are rarely set explicitly—they are handled by the tokenizer and model automatically. But they become relevant in a few important scenarios: [[prompt-caching]] implementations must ensure cached prefix tokens are correctly distinguished from new tokens; custom training loops must apply the correct mask to compute loss only over real tokens; and [[context-length]] optimization techniques like sliding windows require custom masking strategies to handle how context is split across chunks. A common misconception is that the attention mask determines what the model *can't remember*—it only controls the computation during a single forward pass, not which information persists across turns. See [[picking-a-frontier-model-2026-q2]] for how context-length design and masking strategy affect model selection for long-document applications.

## Related Terms

- [[glossary/transformer|Transformer]] — the neural architecture underlying virtually all modern LLMs
- [[glossary/attention-mechanism|Attention Mechanism]] — the core transformer operation that weights token relationships to compute representations
- [[glossary/context-length|Context Length]] — the maximum number of tokens the model can process in a single call
- [[glossary/tokenization|Tokenization]] — related concept that intersects with this term in agent workflows
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
