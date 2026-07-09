---
term: "Emergent Abilities"
definition: "Capabilities that appear in large language models above a certain scale threshold and are not present in smaller models, seemingly arising discontinuously rather than improving gradually with model size."
seo_description: "Emergent abilities: LLM capabilities that appear abruptly above certain scale thresholds and are absent in smaller models."
category: "LLM concepts"
related_terms: [scaling-laws, in-context-learning, chain-of-thought, capability-overhang, pre-training]
---

Wei et al. (2022) documented a set of capabilities—multi-step arithmetic, analogical reasoning, chain-of-thought performance—that appeared to emerge sharply at specific scale thresholds. This contrasted with smooth scaling: instead of gradual improvement, models below the threshold performed near-random, while models above performed dramatically better.

Subsequent work (Schaeffer et al., 2023) argued that many apparent emergent abilities are artifacts of discontinuous evaluation metrics rather than discontinuous model improvements. When tasks are evaluated with granular metrics (partial credit, continuous scores), improvements are smooth. This debate remains active and has implications for forecasting: if emergence is real, future models could unexpectedly gain dangerous capabilities; if it is a measurement artifact, capability improvements are more predictable.

Regardless of the mechanistic debate, operationally useful emergent behaviors observed around 10–100B parameter scales include: reliable instruction following, multi-hop reasoning, code generation, and mathematical problem solving. These capabilities are the foundation of modern agentic systems.

## Related Terms

- [[glossary/scaling-laws|Scaling Laws]] — the empirical relationships between model size, compute, data, and performance
- [[glossary/in-context-learning|In-Context Learning]] — the ability to adapt to a task using only examples in the prompt, without weight updates
- [[glossary/chain-of-thought|Chain of Thought]] — the prompting technique that asks the model to reason step-by-step before answering
- [[glossary/capability-overhang|Capability Overhang]] — the phenomenon where latent capabilities emerge suddenly as model scale crosses a threshold
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
