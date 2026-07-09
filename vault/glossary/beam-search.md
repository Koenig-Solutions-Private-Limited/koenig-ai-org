---
term: "Beam Search"
definition: "A deterministic decoding algorithm that maintains a fixed number of candidate sequences (beams) at each generation step, expanding the most probable partial sequences and pruning the rest to find a high-probability complete output."
seo_description: "Beam search: a deterministic LLM decoding algorithm that maintains multiple candidate sequences in parallel to find high-probability outputs."
category: "LLM concepts"
related_terms: [greedy-decoding, sampling-parameters, top-p, self-consistency, completion]
---

Beam search with beam width b keeps the b highest-probability partial sequences at each step. Greedy decoding is beam search with b=1. Wider beams find higher-probability sequences but at quadratic computational cost in beam width. For translation and summarization, beam widths of 4–10 are common.

Beam search fell out of favor for open-ended text generation because high-probability sequences under the model's distribution tend to be repetitive and generic. Sampling-based methods produce more diverse, interesting text at the cost of some coherence. However, beam search remains useful for constrained generation tasks (machine translation, code completion with exact syntax requirements) where maximizing probability is more appropriate than diversity.

For LLMs in the 10B+ parameter range, the difference between beam search and greedy decoding is small—the model's distribution is already well-calibrated enough that the top-1 token is usually correct. Most production inference systems for large models use greedy or simple temperature sampling for speed, reserving beam search for smaller specialized models.

## Related Terms

- [[glossary/greedy-decoding|Greedy Decoding]] — the simplest decoding strategy that always picks the highest-probability next token
- [[glossary/sampling-parameters|Sampling Parameters]] — the temperature, top-k, and top-p settings that control output randomness
- [[glossary/top-p|Top-p (Nucleus Sampling)]] — the nucleus sampling strategy that selects from the smallest set covering cumulative probability p
- [[glossary/self-consistency|Self-Consistency]] — the technique of sampling multiple reasoning paths and taking the majority answer
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
