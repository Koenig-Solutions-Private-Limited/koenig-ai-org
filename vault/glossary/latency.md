---
term: "Latency"
definition: "The elapsed time between a user or system request and the response becoming available."
seo_description: "Latency: the elapsed time between a request and the response becoming available."
category: "Infrastructure"
related_terms: [inference, caching, prompt-caching, speculative-decoding, rate-limiting]
related_courses: [gemini-enterprise-agents]
---

Latency shapes how an AI product feels. A five-second answer may be acceptable for a research report, but painful for autocomplete, support chat, or interactive coding.

AI latency comes from several layers: network travel, [[retrieval]], tool calls, queueing, model prefill, token generation, and post-processing. Improving it often requires changing the whole workflow, not just choosing a faster model.

**Three latency metrics** describe different aspects of the user experience. Time-to-first-token (TTFT) is the delay from request submission to receiving the first output token — this controls how long the interface appears frozen. Time-per-output-token (TPOT) governs how fast the stream flows after it starts. End-to-end latency is the total time until the full response is available, which matters for non-streaming applications that must wait for completion before acting.

**Why TTFT matters for streaming UX.** Most production AI interfaces stream tokens as they are generated. A 4-second TTFT followed by fast streaming feels better than a 1-second TTFT followed by slow streaming, because users interpret the streaming start as a signal that the system is working. Optimizations that reduce TTFT — such as [[prompt-caching]] for long prompts, routing requests to the nearest serving region, and reducing retrieval round trips — directly improve perceived responsiveness.

**Latency in [[agent-loop]] workflows.** Agent workflows multiply latency because each iteration involves at least one model call plus any tool calls. A loop with three model calls and two tool calls (each 200ms) plus two retrieval steps (each 300ms) accumulates to several seconds before the first user-visible output. Mitigation strategies include: issuing parallel tool calls when tool results are independent, prefetching common [[retrieval]] results, using a faster (smaller) model for intermediate steps that do not require full capability, and caching [[inference]] outputs for identical sub-requests.

**[[prompt-caching]] and [[speculative-decoding]].** Prompt caching reduces prefill cost for long, stable prompt prefixes by reusing cached key-value attention tensors across requests. This cuts both cost and TTFT for requests that share a large system prompt or document context. Speculative decoding reduces decode [[latency]] by using a smaller draft model to propose tokens that the large model then verifies in parallel, achieving speedup when draft proposals are frequently correct.

**Measuring reliability: P95 and P99.** Average latency hides tail behavior. A system with 200ms average latency but 4s P99 latency will visibly stall one in a hundred requests — enough to be noticeable in interactive products. Production [[observability]] should track P50, P95, and P99 latency separately, and alert on P99 degradation rather than just average. See [[gemini-enterprise-agents]] for latency observability patterns in enterprise agent deployments.

## Related Terms

- [[glossary/inference|Inference]] — the process of running a trained model forward to generate output
- [[glossary/caching|Caching]] — storing computed results for reuse to reduce latency and cost on repeated inputs
- [[glossary/prompt-caching|Prompt Caching]] — the mechanism that reuses cached key-value state for repeated long prefixes
- [[glossary/speculative-decoding|Speculative Decoding]] — the technique of generating draft tokens with a small model and verifying with a large one
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
