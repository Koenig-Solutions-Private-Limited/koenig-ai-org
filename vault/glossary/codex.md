---
term: "Codex"
definition: "OpenAI's coding-oriented agent and model line used for reading repositories, editing code, running checks, and collaborating on software tasks."
seo_description: "Codex: OpenAI's coding-oriented agent and model line for repository work, code edits, checks, and software collaboration."
category: "Products"
related_terms: [coder-agent, code-generation, tool-use, agent-harness, definition-of-done]
related_courses: [production-agents-claude-agent-sdk-mcp-connector]
---

Codex is OpenAI's line of coding-oriented models and agents. The original Codex models were GPT-class systems fine-tuned on large code corpora, powering GitHub Copilot's inline suggestions from 2021 onward. The more recent Codex agent product is a distinct, more autonomous system: it runs asynchronously, reads repository context, edits files across multiple locations, executes terminal commands, and reports results back through a GitHub integration.

**From copilot to agent.** In-editor copilot tools like GitHub Copilot suggest the next line or block as the developer types. A coding agent like Codex operates at a higher level of autonomy: it takes a task description, inspects the relevant codebase state, plans edits across multiple files, runs tests or linters to validate its changes, and produces a diff for review. The difference is scope and initiative, not just the model underneath.

**Evaluation on [[swe-bench]].** SWE-bench tests whether a model can resolve real GitHub issues in open-source repositories by reading the issue description, navigating the codebase, writing a patch, and passing the repo's tests. Performance on [[swe-bench]] is the standard published metric for coding agents. It measures genuine task completion rather than code generation fluency, which makes it a better proxy for production usefulness.

**Role in multi-agent systems.** A standalone coding agent handles one task per invocation. In larger orchestrations, Codex or equivalent [[coder-agent]] instances are sub-agents that receive tightly scoped work items from an orchestrator — "add this endpoint," "fix this failing test" — rather than open-ended briefs. The orchestrator handles decomposition, sequencing, and review routing. [[tool-use]] provides the file-editing, terminal, and search capabilities the agent needs within each task. See [[production-agents-claude-agent-sdk-mcp-connector]] for patterns on wiring coding sub-agents into a broader pipeline.

**Why [[definition-of-done]] matters.** Autonomous code changes are only trustworthy when the agent knows unambiguously what success looks like. A clear [[definition-of-done]] — "all existing tests pass, the new endpoint returns 200 for the sample payload, no lint errors" — lets the agent self-verify before handing off. Without it, the agent may produce code that compiles but does not satisfy the actual requirement.

**Common misconception.** Coding agents do not replace code review. They accelerate first-draft production and can handle repetitive changes reliably, but the diff must still be read by a developer who understands the system's constraints, security requirements, and intended behaviour.

## Related Terms

- [[glossary/coder-agent|Coder Agent]] — a specialized agent that writes, tests, and debugs code autonomously
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/agent-harness|Agent harness]] — the software framework that runs the agent loop with tools and stopping criteria
- [[glossary/definition-of-done|Definition of Done]] — the explicit completion criteria that tell the agent when to stop and report
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
