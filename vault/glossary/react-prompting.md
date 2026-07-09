---
term: "ReAct Prompting"
definition: "A prompting framework that interleaves Reasoning (Thought) and Acting (Action/Observation) steps, guiding an agent to think before each tool call and incorporate the observation into subsequent reasoning."
seo_description: "ReAct prompting: a framework that interleaves reasoning thoughts and tool actions, grounding LLM reasoning in real-world observations."
category: "Agentic AI concepts"
related_terms: [chain-of-thought, agent-loop, tool-use, few-shot-prompting, planning-agent]
---

ReAct (Yao et al., 2022) formalizes the think-act-observe loop as a structured prompt format. Each step has three components: a Thought (the model's reasoning about what to do next), an Action (a tool call), and an Observation (the tool result injected back). This explicit structure dramatically reduces hallucination compared to asking models to answer complex questions without tool access.

The format is largely baked into modern agent SDKs. Claude's tool-use API naturally produces a reasoning step before each tool call. The explicit thought field is particularly valuable for auditing: reviewers can see whether the model's stated rationale matches the action taken.

ReAct falls short when tasks require deep forward planning before acting—situations where chain-of-thought planning (Reflexion, Tree of Thoughts) outperforms the purely reactive approach. Hybrid architectures combine an upfront planning pass with ReAct-style execution.

## Related Terms

- [[glossary/chain-of-thought|Chain of Thought]] — the prompting technique that asks the model to reason step-by-step before answering
- [[glossary/agent-loop|Agent Loop]] — the iterative perceive-act-observe cycle the harness executes
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/few-shot-prompting|Few-Shot Prompting]] — the technique of including worked examples in the prompt to steer model behaviour
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
