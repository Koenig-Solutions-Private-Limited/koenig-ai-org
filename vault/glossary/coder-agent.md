---
term: "Coder Agent"
definition: "An AI agent specialized in writing, editing, testing, and debugging code by combining an LLM with file-system access, shell execution, and version-control tools in a persistent software development environment."
seo_description: "Coder agent: an AI agent that writes, edits, and tests code using file-system and shell access in a persistent development environment."
category: "Agentic AI concepts"
related_terms: [autonomous-agent, agent-scaffolding, tool-use, codex, devin, swe-agent, aider]
---

Coder agents are the most mature class of autonomous agents as of 2026. They operate on a repository, run tests, read error messages, edit files, and iterate until the test suite passes or a definition-of-done is satisfied. The underlying LLMs are typically trained or fine-tuned on code: DeepSeek V4 Pro, Claude Sonnet 4.6, and GPT-5 lead on coding benchmarks.

The scaffolding around the model is as important as the model itself. Coder agents need accurate file-tree navigation, diff-aware editing (to avoid rewriting entire files), sandboxed code execution, and a way to record and revert changes. Tools like Aider, OpenHands, and Claude Code implement these scaffolds with varying tradeoffs between safety and autonomy.

Key unsolved problems include handling very large codebases that exceed the context window, maintaining architectural coherence across many edits, and knowing when to ask a human rather than guessing at intent.
