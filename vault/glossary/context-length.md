---
term: "Context Length"
definition: "The maximum number of tokens an LLM can process in a single forward pass—both input and output combined—determining the amount of text the model can read and reason over at once."
seo_description: "Context length: the maximum tokens an LLM can process in one pass, setting the limit on how much text the model can read and reason over."
category: "LLM concepts"
related_terms: [context-window, kv-cache, working-memory, attention-mechanism, positional-encoding, prompt-caching]
---

Context length is a fundamental architectural property of transformer-based LLMs. Early models (GPT-2, BERT) had context lengths of 512–1024 tokens. The frontier as of 2026 spans from 128K tokens (Claude Sonnet 4.6, GPT-5 standard) to over 1M tokens (Gemini 2.5 Pro, Claude Opus 4.7). This expansion has been driven by architectural improvements (rotary embeddings, sliding window attention) and engineering advances (FlashAttention, memory-efficient KV caching).

Long context enables qualitatively new tasks: reasoning over an entire codebase, summarizing a book, analyzing hundreds of documents simultaneously. However, attention quality degrades for content in the middle of very long contexts ("lost in the middle" problem), and costs scale with context length. Prompt caching mitigates cost for stable prefixes.

Effective context length—how well the model actually uses information near the limit—is often shorter than the advertised maximum. Models tested on the RULER benchmark and needle-in-a-haystack tasks show degraded retrieval accuracy for items near the context midpoint. Architectural improvements continue to close the gap between claimed and effective context length.
