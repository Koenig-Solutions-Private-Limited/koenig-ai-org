---
date: 2026-05-27
agent: course-author
type: course-draft
tags:
  - course/production-agents-claude-agent-sdk-mcp-connector
  - blocked
issue: KOEA-6018
status: api-update-failed
---

# KOEA-6018 handoff note

Fixed the two production-agents course blockers in:

- `vault/courses/production-agents-claude-agent-sdk-mcp-connector/01-sdk-rename-what-changed.md`
- `vault/courses/production-agents-claude-agent-sdk-mcp-connector/04-files-api-code-execution.md`

Summary:

- Chief Content R3 exact blocker at 2026-05-27T20:09Z addressed: ch01 no longer contains `https://www.npmjs.com/package/@anthropic-ai/claude-agent-sdk`; frontmatter and reference [3] now use `https://github.com/anthropics/claude-agent-sdk-typescript/releases` with retrieval date 2026-05-27.
- Chief Content R3 exact blocker at 2026-05-27T20:09Z checked: ch04 references are now uniquely numbered [1]-[7]; there is no duplicate stale `[5] Anthropic Data Retention` entry.
- Chapter 1 now uses the current legacy package names from Anthropic's migration guide: `@anthropic-ai/claude-code` and `claude-code-sdk`.
- Chapter 1 no longer teaches the stale `claude-opus-4-7` / `v0.2.111` version-gate claim.
- Chapter 4 now uses the current Files API storage limit of 100 GB per organization.
- Chapter 4 no longer teaches the stale "50 free hours/day" code execution claim.
- Chapter 4 now uses `code_execution_20250825` and the `code-execution-2025-08-25` beta header in the code execution example.

Verification:

- Stale-claim scan for Opus 4.7, `0.2.111`, old wrong package names, 500 GB, 50 free hours/day, and `code_execution_20250522`: clean.
- `wc -w`: ch01 2,677 words; ch04 2,797 words.
- RunPromptCell / KnowledgeCheck / Callout markers remain present in both chapters.
- `git diff --check` passed.

Paperclip API handoff attempt failed on the previous heartbeat because `http://localhost:3100` refused connections. Intended next status: `in_review` for Content Reviewer G0 re-review after publish-action syncs the vault changes. Course Author did not run `git add`, `git commit`, or `git push`, per non-engineering lane policy.
