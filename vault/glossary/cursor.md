---
term: "Cursor"
definition: "An AI-native code editor that integrates model assistance into repository navigation, code generation, chat, and iterative software changes."
seo_description: "Cursor: an AI-native code editor that integrates model assistance into repository navigation, code generation, chat, and software changes."
category: "Products"
related_terms: [coder-agent, code-generation, tool-use, prompt-engineering, definition-of-done]
related_courses: [claude-tool-use-from-zero]
---

Cursor is a code editor built around deep model integration rather than treating AI as an optional plug-in. Where a standard editor with a copilot add-on offers inline completions on the current line, Cursor exposes the full repository context to the model: file tree, open tabs, referenced symbols, and multi-file diffs. The model's assistance is woven into navigation, explanation, refactoring, and multi-file edit proposals rather than limited to autocomplete.

**What makes it different.** GitHub Copilot operates primarily in inline suggestion mode — the model predicts the next token or block as you type. Cursor adds a conversational chat layer that can read and modify files across the repo, propose multi-file diffs, and explain why a change was made. Its agent mode can execute tasks autonomously: write a function, run the tests, read the error output, revise the code, and repeat until the suite passes. This loop mirrors a [[coder-agent]] architecture but is embedded directly in the developer's working environment.

**Context window management.** Cursor selects which files and symbols to include in each model call based on relevance signals: open tabs, recent edits, and explicit mentions via `@file` syntax. This matters because [[context-window]] budget is finite. Poor context selection leads to the model hallucinating APIs that do not exist in the actual codebase. Being intentional about which files are included — and excluding large irrelevant files — improves generation quality.

**Rules files as a [[system-prompt]].** Cursor supports a `.cursorrules` file (or per-project rules in newer versions) that acts as a persistent [[system-prompt]] for the AI layer: architectural conventions, banned patterns, style preferences, and project-specific context. Teams that invest in a well-maintained rules file get more consistent output than those relying on ad-hoc chat instructions.

**Model choice.** Cursor is model-agnostic: it can run Claude, GPT-4, or other frontier models as the backend. The right choice depends on task type — reasoning-heavy refactoring benefits from stronger models; fast autocomplete works well with smaller ones. See [[claude-tool-use-from-zero]] for a foundation in how [[tool-use]] and function calling work, which underpins Cursor's file-editing and terminal-execution capabilities.

**Common misconception.** Cursor does not remove the need to understand the code. Developers who treat its output as correct without reading it accumulate subtle bugs that are harder to diagnose than if they had written the code manually. The productivity gain is real, but it is a multiplier on engineering judgement, not a substitute for it. A clear [[definition-of-done]] — tests pass, types check, behaviour matches spec — is still the developer's responsibility to define and verify.

## Related Terms

- [[glossary/coder-agent|Coder Agent]] — a specialized agent that writes, tests, and debugs code autonomously
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/prompt-engineering|Prompt Engineering]] — the practice of crafting inputs to elicit reliable, high-quality model outputs
- [[glossary/definition-of-done|Definition of Done]] — the explicit completion criteria that tell the agent when to stop and report
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
