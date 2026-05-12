---
term: "Reflection Agent"
definition: "An AI agent that critiques its own prior outputs, identifies errors or gaps, and generates improved responses by iterating over self-evaluation feedback before producing a final answer."
seo_description: "Reflection agent: an AI agent that self-critiques its outputs and iteratively improves them before delivering a final answer."
category: "Agentic AI concepts"
related_terms: [self-consistency, chain-of-thought, agent-evaluation, agent-loop, planning-agent]
---

Reflection agents implement a generate-critique-refine loop. After producing an initial response or plan, the agent (or a separate critic model) evaluates it against explicit criteria—correctness, completeness, style, safety—then writes a critique. The original agent uses this critique as additional context to produce a revised response.

Studies on models like GPT-4 and Claude Sonnet 4.6 show that one or two reflection rounds significantly reduce factual errors and logical inconsistencies. Diminishing returns set in quickly, so production systems cap reflection at two or three iterations to control latency and cost.

Reflection can be self-reflection (same model) or cross-reflection (separate judge model). Cross-reflection with a stronger judge—for example using Opus 4.7 to critique a Sonnet 4.6 draft—tends to surface more diverse failure modes but roughly doubles inference cost per iteration.
