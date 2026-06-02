---
date: 2026-05-30
author: blog-author
ticket: KOEA-6873
vendor_tag: community
content_type: article
status: g0-ready
reading_time_min: 6-8
primary_query: "codex claude cursor gemini cli handoff workflow"
contrarian_angle: "The workflow harness is the moat — the community already named the four primitives that separate a winner from a pretty chat box: plan mode, rollback coupling, approval switching, and message injection."
first_60_words_answer: "To hand off context between Codex CLI, Claude Code, Cursor, and Gemini CLI in 2026, you need a file-based workflow harness — not a model switch. Shared markdown memory files, per-agent inbox/outbox folders, and a typed message protocol let all four CLIs read the same project state without rebuilding context from scratch on every switch."
positions:
  - id: stance:tools-codex-cli-default-headless
    engagement: extends
  - id: stance:tools-cursor-composer-ide-only
    engagement: refines
faq:
  - question: "How do I hand off context from Claude Code to Codex CLI without losing project state?"
    answer: "Use a shared markdown memory file (e.g., project_facts.md) that both CLIs read at session start. OACP (pip install oacp-cli) formalizes this with typed inbox/outbox messages and a shared memory directory at $OACP_HOME/projects/<name>/memory/. You commit the memory file to git and each CLI loads it via its own context-file mechanism — CLAUDE.md for Claude Code, --context-file for Codex — so context persists across switches without any daemon or server."
  - question: "What are the four primitives a multi-CLI workflow harness must provide?"
    answer: "Plan mode (read-only exploration before destructive writes), rollback coupling (checkpoint files linked to git SHAs so any agent can revert), approval-mode switching (requiring sign-off before execution), and message injection (structured task context passed to any CLI session via file or stdin). HN commenters on Codex in May 2026 explicitly named all four as the blockers preventing full CLI switching — none are a model quality issue."
  - question: "Is OACP production-ready for multi-agent handoffs in 2026?"
    answer: "OACP v0.3.1 (Apache 2.0, pip install oacp-cli) supports four runtimes — Claude, Codex, Gemini, and custom — with 12 typed message types and zero servers required. As of May 2026 it is community-verified via HN and Reddit, with async inbox/outbox messaging and optional git-backed memory sync across machines. For production use you will want to add your own token-budget guardrails; OACP does not enforce spend limits natively."
original_data: false
last_updated: 2026-05-30
hero_image:
  url: /img/blogs/2026-05-30-multi-agent-cli-workflow-harness-2026/hero.png
  alt: "Diagram showing Codex CLI, Claude Code, Cursor, and Gemini CLI exchanging task context through shared inbox/outbox directories in a file-based workflow harness"
sources:
  - https://www.reddit.com/r/codex/comments/1tq0p2e/looking_for_one_local_app_to_use_multiple_ai/
  - https://oacp.dev/
  - https://github.com/kiloloop/oacp
  - https://github.com/mrdanielcasper/coretex
  - https://news.ycombinator.com/item?id=48283108
  - https://news.ycombinator.com/item?id=48293253
  - https://news.ycombinator.com/item?id=47075089
  - https://news.ycombinator.com/item?id=47211136
  - https://medium.com/@jacklandrin/skills-cli-guide-using-npx-skills-to-supercharge-your-ai-agents-38ddf3f0a826
whats_new:
  - "A file-based workflow harness — not a faster model — is what makes multi-CLI handoffs work without context loss in 2026."
learning_objectives:
  - "Name the four primitives a multi-CLI harness must provide: plan mode, rollback coupling, approval switching, and message injection."
  - "Configure a shared markdown memory layer readable by Codex, Claude Code, Cursor, and Gemini without a server or daemon."
  - "Use OACP's typed inbox/outbox protocol to pass structured task handoffs between agent runtimes."
description: "Sharing context between Codex, Claude Code, Cursor, and Gemini CLI in 2026 needs a file-based workflow harness — not a model switch. Here's how to build one."
---

# The workflow harness is the moat: cross-CLI context persistence with Codex, Claude Code, Cursor, and Gemini in 2026

To hand off context between [Codex CLI](/blog/2026-05-17-codex-cli-vs-cursor-composer-2), [Claude Code](/blog/cursor-3-2-vs-claude-code-workflow), Cursor, and Gemini CLI in 2026, you need a **file-based workflow harness** — not a model switch. Shared markdown memory files, per-agent inbox/outbox folders, and a typed message protocol let all four CLIs read the same project state without rebuilding context from scratch on every switch. The harness, not the model, is what keeps work continuous.

Most coverage of AI coding tools asks "which CLI should I use?" The harder question — the one a [r/codex thread asked in May 2026](https://www.reddit.com/r/codex/comments/1tq0p2e/looking_for_one_local_app_to_use_multiple_ai/) — is: "how do I use all of them from one workspace without losing the thread?" The community has already named what's missing: plan mode, rollback coupling, approval-mode switching, and message injection. These are the four moat primitives. Whoever ships the best harness around them wins — independent of which underlying model tops the next benchmark.

![Diagram showing Codex CLI, Claude Code, Cursor, and Gemini CLI exchanging task context through shared inbox/outbox directories in a file-based workflow harness](/img/blogs/2026-05-30-multi-agent-cli-workflow-harness-2026/hero.png)

## Why developers hit the CLI-switching wall

The pain is specific: you start a task in Codex CLI (fast headless execution, good for scripted ops), hit a design question that needs Claude Code's extended reasoning, then want Cursor Composer for a rapid in-editor refactor — but switching resets your context window. Every CLI session starts cold. You re-paste the problem statement. You re-explain the architecture. You lose the chain of decisions made in the previous session.

A [May 2026 Hacker News thread on Codex](https://news.ycombinator.com/item?id=47075089) put specifics on the friction: users who would switch to Codex full-time were held back by the absence of plan mode, the lack of rollback that tracks git commits, and no way to inject structured task context without re-typing it. [agentchattr](https://news.ycombinator.com/item?id=47211136) and `npx continues` emerged directly from this pain — both routing the same task across agents without losing the thread.

This is a harness problem. Not a model problem.

## The four moat primitives

[HN discussions on multi-agent CLI orchestration](https://news.ycombinator.com/item?id=48283108) converged on four specific gaps. Each maps to a concrete failure mode:

**Plan mode.** Read-only exploration before destructive writes. Claude Code has `/plan`, Codex has headless `--approve` flags, but there's no shared protocol for propagating a "planning" state across CLIs so each tool knows it's in advisory mode. Without this, any CLI in the chain can fire a write when it shouldn't.

**Rollback coupling.** Checkpoint files linked to git SHAs. If Gemini CLI produces a bad refactor, the harness should let Claude Code or Codex revert to the last known-good state without a manual `git reset`. This requires the harness to write a checkpoint manifest that every CLI can read and act on.

**Approval-mode switching.** Requiring explicit sign-off — from a human, an orchestrator, or another agent — before execution. Cursor Composer lives inside the IDE and has no programmatic approval gate; any harness spanning IDEs and terminals needs its own approval-state file that all CLIs respect.

**Message injection.** Structured task context passed to any CLI session via file or stdin. Without it, context travels by copy-paste. With it, the harness writes a `task_context.md` file that every CLI loads at startup — objective, constraints, last checkpoint, open decisions.

## OACP and CoreTex: community-validated harness patterns

Two open-source projects show what these primitives look like in practice.

[**OACP** (Open Agent Coordination Protocol, v0.3.1)](https://oacp.dev/) is a file-based, zero-daemon protocol that implements all four. It adds per-agent `inbox/` and `outbox/` directories under a shared workspace, typed YAML message files — 12 types including `task_request`, `review_feedback`, `handoff`, and `review_lgtm` — and a shared memory layer with `project_facts.md`, `decision_log.md`, `open_threads.md`, and `known_debt.md`. All four supported runtimes (Claude Code, Codex CLI, Gemini, custom) read the same memory directory at session start. Apache 2.0. [GitHub: kiloloop/oacp](https://github.com/kiloloop/oacp).

[**CoreTex**](https://github.com/mrdanielcasper/coretex) takes a biomimetic angle — the orchestrator process is the `Medulla`, short-term state lives in the `Hippocampus` — but underneath is a flat-file harness with YAML declarative agent configs, sandboxed code execution (opt-in only, not default), and first-class `CLAUDE.md` and `GEMINI.md` support so both runtimes pick up context from the same directory. Pre-alpha but the pattern is clear: multi-CLI context is a filesystem concern, not a model-API concern.

What validates both projects isn't their maturity — it's that the community built them independently to solve the same problem.

## A minimal operator workflow you can wire today

You don't need OACP or CoreTex to start. The underlying pattern is three files and a convention:

```
.harness/
  task.md          # Current task: objective, constraints, open questions
  decision_log.md  # Dated list of decisions made across sessions
  checkpoint.txt   # Last git SHA where state was known-good
```

Each CLI loads `task.md` as context at session start:

- **Claude Code:** add an `[[include:.harness/task.md]]` line to `CLAUDE.md`
- **Codex CLI:** pass `--context-file .harness/task.md`
- **Gemini CLI:** pass `--system-prompt-file .harness/task.md`
- **Cursor Composer:** add `.harness/task.md` to workspace context rules

When you switch CLIs, commit `decision_log.md` with what was decided, update `checkpoint.txt` with the current SHA, and open the next session with `task.md` unchanged. Context doesn't rebuild — it accumulates.

The [`npx skills` CLI](https://medium.com/@jacklandrin/skills-cli-guide-using-npx-skills-to-supercharge-your-ai-agents-38ddf3f0a826) extends this to reasoning procedures: it installs skill files into a shared `.agents/skills/` directory readable by Cursor, Claude Code, Codex, and Continue from a single install, so the reasoning conventions — not just task state — are portable across CLIs without re-configuration.

## Why Codex headless and Cursor IDE-only actually clarify the model

The stance on Codex CLI as the default headless execution node extends naturally into the harness model: Codex's programmatic, non-interactive mode makes it the natural **executor** in a pipeline. You dispatch a `task_request` via OACP, Codex picks it up from its inbox and runs it, writes output to its outbox. No human needed in the execution loop.

Cursor Composer's IDE-only nature, rather than being a limitation, defines the division of responsibility: Cursor owns the in-editor refactor loop where a human is present; the harness owns headless execution and context persistence. The failure mode is treating Cursor as a general-purpose background executor — it isn't designed for that. The [HN discussion on multi-agent harnesses](https://news.ycombinator.com/item?id=48293253) makes this explicit: the CLIs that thrive are the ones that stay in their lane and let the harness handle the handoffs.

## The winner will be the harness, not the model

Every six months a new benchmark reshuffles the model leaderboard. The r/codex thread, the OACP Show HN, and the CoreTex Discord all point to the same unsatisfied demand: developers don't want to pick one CLI — they want all of them cooperating without losing the thread.

The harness that solves plan mode, rollback coupling, approval switching, and message injection across Codex, Claude Code, Cursor, and Gemini will capture that workflow loyalty regardless of which provider's model wins the next eval. The community already named the four missing primitives. The first harness that ships all four — reliably, without a server — wins the workflow layer.

---

```runprompt
# Minimal three-file harness handoff test
# Prerequisites: claude CLI + codex CLI installed, project has git history

mkdir -p .harness

cat > .harness/task.md << 'EOF'
## Current task
Refactor auth middleware to use token-based sessions.

## Constraints
- Do not break existing cookie-based tests
- Maintain backward compat with v1 clients

## Last checkpoint
abc1234 — state before auth refactor
EOF

# Step 1: load into Claude Code for plan-mode review
claude --context-file .harness/task.md \
  "Review the task. Identify the three riskiest changes. Do not write any code."

# Expected output:
# 1. Session token storage backend selection
# 2. Existing cookie test isolation boundary
# 3. v1 client backward-compat header handling

# Step 2: commit context and hand off to Codex
git add .harness/task.md
git commit -m "harness: task context for auth refactor"
codex --context-file .harness/task.md \
  "Implement token storage backend only. Scope: src/auth/storage.ts."
```

---

**KnowledgeCheck:** A developer wants to switch from a Claude Code session to Codex CLI mid-task without losing context. Which of the four harness primitives is their workflow most likely missing?

a) Plan mode  
b) Message injection  
c) Rollback coupling  
d) Approval-mode switching

*Answer: b. Without message injection — a mechanism to pass structured task context from one session to the next via a shared file — the developer must re-type the objective and constraints when opening Codex. The other three primitives govern what happens during execution; message injection governs whether context survives the CLI switch at all.*

---

Cross-CLI context persistence at scale — with budget tracking, approval gates, and session checkpointing across production agent pipelines — is exactly what the [[course/production-agents-claude-agent-sdk-mcp-connector]] course covers.
