---
term: "Alignment Tax"
definition: "The reduction in raw task performance that results from applying alignment techniques (RLHF, Constitutional AI, safety training) to an LLM, reflecting the tradeoff between safety/helpfulness and peak capability."
seo_description: "Alignment tax: the performance reduction caused by applying safety and alignment training to an LLM, trading peak capability for safer behavior."
category: "LLM concepts"
related_terms: [rlhf, constitutional-ai, helpfulness-harmlessness-honesty, alignment, refusal, capability-overhang]
---

The alignment tax is the empirical observation that aligning a model to be safe, helpful, and harmless often reduces its performance on certain capability benchmarks. Early RLHF papers documented measurable decreases in mathematical reasoning and code quality after reinforcement learning from human feedback. Overly conservative refusals—a model declining tasks it could safely perform—represent a different facet of the same tradeoff.

The magnitude of the alignment tax varies by technique and implementation quality. Well-implemented Constitutional AI and DPO-based alignment can be nearly tax-free on most benchmarks while maintaining safety properties, because alignment sharpens instruction following rather than merely suppressing outputs. Poorly calibrated alignment amplifies refusals and produces verbose, hedge-heavy responses that users find less useful.

Anthropic's research suggests the alignment tax is not fundamental: a model can be both highly capable and well-aligned. The tax is a symptom of imperfect training, not an inherent tradeoff. Models like Claude Sonnet 4.6 demonstrate that high scores on capability benchmarks (MMLU, HumanEval) coexist with strong safety evaluations—though eliminating the tax entirely remains an open research problem.

## Related Terms

- [[glossary/rlhf|Reinforcement Learning from Human Feedback (RLHF)]] — the training technique that uses human preference comparisons to steer model behaviour
- [[glossary/constitutional-ai|Constitutional AI]] — Anthropic's training technique where the model critiques itself against a set of principles
- [[glossary/capability-overhang|Capability Overhang]] — the phenomenon where latent capabilities emerge suddenly as model scale crosses a threshold
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
