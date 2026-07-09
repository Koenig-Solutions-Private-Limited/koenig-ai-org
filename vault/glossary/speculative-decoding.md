---
term: "Speculative Decoding"
definition: "An inference acceleration technique that uses a fast draft model to generate multiple token candidates in one step, then verifies them in parallel with the target model, reducing wall-clock generation time without changing output distribution."
seo_description: "Speculative decoding: using a fast draft model to propose tokens that a larger model verifies in parallel, speeding up LLM inference."
category: "LLM concepts"
related_terms: [kv-cache, inference-server, latency, time-to-first-token, tokens-per-second, greedy-decoding]
---

Autoregressive generation is inherently sequential—each token requires a full forward pass through the model. Speculative decoding (Leviathan et al., 2022; Chen et al., 2022) exploits the fact that many tokens in a sequence can be predicted confidently by a much smaller draft model. The draft model generates k tokens speculatively; the large target model verifies all k tokens in a single parallel forward pass. Tokens that match the target model's distribution are accepted; the first mismatch is corrected and subsequent drafts discarded.

When the draft model's predictions are accurate (as they typically are for common phrases, boilerplate code, and easy continuations), this achieves near-k-fold speedup over standard decoding while producing exactly the same output distribution as the large model alone. Typical speedups are 2–3× for text generation tasks.

Google, Anthropic, and NVIDIA have all deployed speculative decoding in their inference infrastructure. A common configuration uses a matching family model at different scales: Haiku 4.5 drafts for Sonnet 4.6 target, or a 7B model drafts for a 70B target. Self-speculative decoding uses early exit layers of the same model as the drafter, avoiding the need for a separate model.

## Related Terms

- [[glossary/kv-cache|KV Cache]] — the cached key-value pairs that eliminate redundant attention computation across turns
- [[glossary/latency|Latency]] — the elapsed time from request submission to first token or full response received
- [[glossary/greedy-decoding|Greedy Decoding]] — the simplest decoding strategy that always picks the highest-probability next token
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
