---
date: 2026-06-05
author: blog-author
ticket: KOEA-7359
vendor_tag: anthropic
content_type: article
status: draft-for-review
title: "Claude Code Subagent: When to Spawn vs Inline (2026 Guide)"
meta_description: "The spawn vs inline decision comes down to context budget, not task size. Use this 7-signal matrix to protect your parent agent's reasoning quality in 2026."
reading_time_min: 8-10
primary_query: "claude code subagent when to spawn vs inline"
contrarian_angle: "Most developers spawn subagents for parallelism and speed — the real value is protecting the parent agent's reasoning quality by shielding the main context window from exploration waste"
positions:
  - id: stance:cli-first-workflows-for-production-teams
    engagement: defends
first_60_words_answer: "Spawn a Claude Code subagent when the task would flood your main context window with intermediate tokens you won't need again: search results, file trees, test logs. Stay inline when the task is short, files are already in context, or you need rapid back-and-forth. The decision boundary is context budget — not task complexity, not parallelism."
sources:
  - https://code.claude.com/docs/en/sub-agents
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
  - https://platform.claude.com/cookbook/tool-use-automatic-context-compaction
  - https://hyperdev.matsuoka.com/p/how-claude-code-got-better-by-protecting
  - https://arxiv.org/html/2604.14228v1
  - https://www.finout.io/blog/claude-code-pricing-2026
  - https://shipyard.build/blog/claude-code-subagents-guide
faq:
  - question: "When should I spawn a Claude Code subagent instead of continuing inline?"
    answer: "Spawn a subagent when a side task would flood your main conversation with tokens you won't reference again — search results, test logs, file trees. The subagent burns whatever tokens it needs exploring, then returns a 1–2k summary. Stay inline for tasks under 20 lines, files already open in context, or anything needing rapid back-and-forth."
  - question: "How does subagent context isolation protect the parent agent?"
    answer: "Each non-fork subagent starts with a fresh, isolated context window. It only receives the delegation message Claude composes — not the parent's full conversation history. The parent's reasoning window stays clean. When the subagent finishes, only its final summary flows back, not the intermediate tokens consumed during exploration."
  - question: "What is the difference between a subagent fork and a regular subagent in Claude Code?"
    answer: "A fork subagent inherits the parent's full conversation context — useful when the worker needs complete awareness of what happened before. A non-fork (default) subagent starts fresh with only a delegation message. Use forks sparingly: they negate the context isolation benefit and should be limited to cases where complete session history is genuinely required."
  - question: "What causes subagent fan-out cost explosions in Claude Code?"
    answer: "Unattended subagent chains or uncapped parallel spawns. Finout documented $8,000–$47,000 incidents from uncontrolled fan-out. The fix: set CLAUDE.md parallelism caps (max 4 concurrent on Pro), prefer explicit delegation over dynamic spawning for production workflows, and never leave multi-agent sessions unattended overnight."
original_data: true
last_updated: 2026-06-05
hero_image:
  url: /img/blogs/claude-code-subagent-context-window/hero.png
  alt: "Diagram of Claude Code parent agent with lean 75% context window delegating to three isolated subagents, each with fresh empty context"
whats_new:
  - "The 75% auto-compact threshold leaves 50k tokens of reasoning buffer — subagents protect that margin by absorbing exploration waste"
learning_objectives:
  - "Apply the spawn vs inline decision matrix based on context budget impact, not task size"
  - "Distinguish fork from non-fork subagent modes and choose correctly for each delegation"
  - "Configure CLAUDE.md parallelism caps to prevent $10K+ subagent fan-out cost incidents"
schema:
  - Article
  - FAQPage
---

# Claude Code Subagent: When to Spawn vs Inline in 2026

Spawn a Claude Code subagent when a side task would flood your main context window with tokens you won't need again: search results, file trees, test logs, debug traces. Stay inline when the task is short, files are already in context, or you need rapid back-and-forth. The decision boundary is **context budget** — not task complexity, not parallelism, not task importance.

Most teams get this backwards. They reach for subagents when tasks are "big" or when they want speed through parallel execution. Both are secondary benefits. The primary reason to spawn is to prevent **exploration waste** — the tens of thousands of intermediate tokens that accumulate during file traversal, web search, and debugging — from degrading the parent agent's reasoning margin. Speed is a side effect. Context protection is the point.

## Why Context Budget Is the Decision Axis

Claude Code's official documentation names this explicitly: use a subagent "when a side task would flood your main conversation with search results, logs, or file contents you won't reference again."[^1] The subagent does that work in its own isolated context window and "returns only the summary."

The mechanism: each non-fork subagent starts fresh. It does not see your conversation history, previously invoked skills, or files the parent has already read. Claude composes a delegation message — a compact task brief — and the subagent works from there.[^1] After burning whatever tokens it needs exploring (potentially 50k–100k), it returns 1,000–2,000 tokens of findings. The parent gains the insight without paying for the exploration.

Anthropic's multi-agent research team documented this pattern at production scale: "each subagent might explore extensively, using tens of thousands of tokens or more, but returns only a condensed, distilled summary of its work (often 1,000–2,000 tokens)."[^2] The result: parent context grows proportional to tasks completed, not to exploration depth per task.

This math matters more than ever because Claude Code now triggers automatic compaction at approximately **75% context usage**, down from the historical 90%+ threshold.[^5] At 90%, a 200k-token session leaves only 20k tokens free before compaction fires. At 75%, there are 50k tokens of working memory — enough for the model to plan across multiple alternatives and hold quality through long sessions. Subagents don't just offload work; they directly protect the parent's reasoning margin by keeping the main context lean. (See [[blog/2026-05-31-claude-prompt-caching-roi-2026]] for the related economics of cache hits and context reuse.)

## The Spawn vs Inline Decision Matrix

The table below synthesizes decision signals from Claude Code's official documentation,[^1][^2][^3] the arXiv architecture analysis,[^6] and production engineering reports.[^7][^8]

| Signal | Spawn subagent | Stay inline |
|--------|---------------|-------------|
| Expected exploration token volume | High — 10k+ intermediate tokens | Low — task completes in <5k tokens |
| Target files already in parent context | No | Yes |
| Result-to-exploration ratio | Small summary (1–2k) vs large journey | Result ≈ exploration size |
| Back-and-forth feedback needed | No | Yes |
| Tasks are mutually independent | Yes | No — sequential with shared state |
| Domain boundary is clean | Yes — single directory or service | No — cross-cutting concerns |
| Change scope | Single domain, isolated module | Multi-file with shared context |

![Spawn vs inline decision flow: high exploration tokens + files not in context → spawn subagent with isolated context; low exploration tokens or files already open → stay inline for speed](/img/blogs/claude-code-subagent-context-window/decision-flow.png)

**Counterintuitive case**: a 3-line bug fix in a file already open in your conversation is a strong **inline** candidate — even if you could frame it as a "task for an agent." Spawning a subagent that must re-read the file from disk wastes a delegation round-trip with no context benefit. Conversely, "which of these five libraries handles streaming JSON?" is a strong **spawn** candidate even though the final answer is one sentence — because the documentation traversal journey is wasteful in the parent context.[^8]

A one-line heuristic from a top-voted HN comment: "The ideal sub-agent is one that can take a simple question, use up massive amounts of tokens answering it, and then return a simple answer, dropping all those intermediate tokens as unnecessary."

## Fork vs Non-Fork: The Hidden Branching Choice

The Claude Code documentation describes two subagent modes without much fanfare: **non-fork** (default) and **fork**.[^1]

**Non-fork**: fresh isolated context. The subagent only receives the delegation message. Maximum context isolation. This is right for the vast majority of delegation.

**Fork**: inherits the parent's full conversation. The subagent sees everything the parent has seen. Use when the worker genuinely needs awareness of the full session — for example, a code review subagent that needs to understand the refactoring rationale that developed over 40 prior messages.

The practical danger: teams default to forks because it feels "safer" to give the subagent more context. But this eliminates the core benefit. A forked subagent exploring a large codebase burns the parent's context budget just as effectively as inline work. The exploration tokens accumulate in a context the parent already paid for.

Practical heuristic: if you could write a clean, self-contained delegation brief without referencing session history, use non-fork. If your natural brief starts with "given everything we've discussed," consider a fork — but first ask whether a well-written delegation message could replace that dependency.

For a worked example of fork vs non-fork in a real multi-agent CLI workflow, see [[blog/2026-05-30-multi-agent-cli-workflow-harness-2026]].

## When Spawning Backfires: Three Anti-Patterns

Not every delegation improves outcomes. These three patterns reliably destroy context efficiency rather than protect it.

**1. The coordination tax.** Spawning a subagent for a task that requires real-time back-and-forth with the parent. If the subagent needs clarifying questions mid-exploration, each round-trip (delegation → question → response → clarification → response) burns more context than staying inline would have. The tell: you find yourself reading the subagent's partial output and replying "actually, focus on X, not Y." That back-and-forth should have been inline.

**2. Forking shared mutable state.** Spawning multiple concurrent subagents that write to the same files. Without explicit coordination, concurrent agents produce conflicts — `git merge` divergence, overwritten stubs, duplicate test fixtures. The resolution cost exceeds the parallelism savings. If two subagents touch the same file tree, serialize them or use explicit handoff: first agent writes, second agent reads its output as the delegation brief.[^3]

**3. Spawning for trivial commands.** Using a subagent to run a single `git status`, `ls`, or one-file read. The delegation overhead — context serialization, isolation setup, response marshaling — costs roughly 10× more tokens than the command output itself. Claude Code's official guidance is explicit: "only use subagents for tasks that benefit from isolation."[^1] Reserve spawning for tasks where exploration will consume 10k+ tokens.

A fast heuristic that catches all three: before spawning, ask "would this task generate outputs I never need to reference again?" If yes, spawn. If the outputs are live inputs to the current reasoning chain, stay inline.

## Context Compaction and the 75% Rule

Claude Code runs a five-stage compaction pipeline before every model call: budget reduction, snip, microcompact, context collapse, and auto-compact.[^6] Auto-compact is the final stage — it performs semantic compression, replacing raw history with a structured summary.

The 75% threshold was identified in GitHub issue discussions and confirmed independently by community profiling. One VS Code extension report noted it "auto-compacts at ~25% remaining context (75% usage), reserving ~20% for the compaction process itself."[^5] This leaves a 50k-token reasoning buffer at all times in a 200k session — enough to plan, evaluate alternatives, and produce quality output without hitting the degraded-reasoning zone.

On Opus 4.7's 1M token context window, the same proportional logic applies at larger scale. One failure mode documented in production: on long Opus 1M sessions, auto-compact was observed firing at 76k tokens — consuming 92% of available context in the compaction process itself.[^7] The fix isn't to avoid large contexts; it's to use subagents on exploration legs so the parent's context never accumulates enough intermediate tokens to trigger cascading compaction.

Anthropic's context engineering guide is explicit: when context limits approach, agents should "spawn fresh subagents with clean contexts while maintaining continuity through careful handoffs" rather than relying solely on compaction to survive long sessions.[^3] The handoff pattern: summarize completed work phases into CLAUDE.md or auto-memory, then delegate forward-looking tasks to fresh subagents. See [[blog/2026-06-04-claude-code-opus-4-7-production-guide]] for how this maps to Opus 4.7 effort tiers and task budgets.

## Production Patterns: Delegation and Cost Control

**Dynamic spawning** works best for research and competitive analysis. Instead of specifying a fixed agent count, describe the scope:

```bash
# In a Claude Code session
"Research these five competitor SDKs. Use however many subagents you need."
```

Claude reads the scope, spawns accordingly — five agents for five independent targets, fewer if documentation overlaps — and returns five summaries to the parent.[^8] The exploration tokens never touch the parent.

**Parallelism caps are not optional in production.** Subagent fan-out incidents have been documented at $8,000–$47,000 when unattended multi-agent chains run overnight.[^7] Add hard caps to your CLAUDE.md:

```markdown
## Subagent limits
- Maximum concurrent subagents: 4 (Pro plan), 2 (API pay-as-you-go)
- Never leave multi-agent sessions unattended for >30 minutes
- Use explicit delegation prompts, not open-ended "use as many as needed" in production
```

**Effort-tier matching**: subagents don't need the parent's full reasoning depth. An orchestrator running at `xhigh` for planning can dispatch subagents at `high` for execution and `medium` for documentation lookups. Claude Code defaults Opus 4.7 to `xhigh` on planning phases because quality compounds downstream — but that same overhead on a subagent doing a grep-and-summarize task is waste.[^6]

**Subagent transcripts as audit trail**: subagent transcripts persist independently at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`. Main conversation compaction does not affect them.[^1] For teams with [[glossary/audit-trail]] requirements, this is a structurally important guarantee — the subagent's full exploration is logged even when the parent's [[glossary/context-compaction]] collapses prior turns.

## Compaction vs Spawn: The Architecture Choice

The last non-obvious decision: when should you compact the parent vs spawn a fresh subagent?

**Compact** when: the session must continue with awareness of prior work, but intermediate tool outputs are no longer needed. Compaction preserves narrative continuity at lower token cost. The Anthropic Cookbook recommends setting the `context_token_threshold` between 50k–100k for multi-phase workflows with natural checkpoints.[^4]

**Spawn a new subagent** when: the next task is genuinely independent of session history. You want clean reasoning from a blank slate, not compressed reasoning from a summary. The subagent starts fresh, avoids compaction artifacts, and returns only what the parent needs.

The test: if you'd naturally start a new terminal session for the task, spawn a subagent. If you'd continue the same session and want to clean up token bloat, compact. Most long-horizon sessions need both: compact periodically to maintain parent continuity, spawn for exploration-heavy side tasks throughout.

---

**KnowledgeCheck**: Your parent session is at 60% context usage. You need to (A) search SDK documentation for an unfamiliar API and (B) write three integration tests using what you find. What's the optimal approach?

*Answer*: Spawn one non-fork subagent for (A) — documentation traversal is high-exploration, low-return-size, and doesn't need session history. Run (B) inline after the summary returns — the files are in context, the scope is bounded, and you need to iterate quickly on test failures. Spawning a second subagent for the tests adds round-trip latency with no context benefit since the test files are already present.

---

For hands-on practice with Claude Code's agentic patterns — CLAUDE.md configuration, effort-tier matching, multi-agent orchestration, and context recovery — see [[course/claude-code-production-workflows]].

---

**About the author**: The Koenig AI Academy editorial team tests AI coding tools on real production workloads and publishes for engineers who build with LLMs for a living. We run every pattern described here against actual Claude Code sessions before publishing. The Academy's [Claude Code Production Workflows course](https://academy.kspl.tech/courses/claude-code-production-workflows) covers multi-agent orchestration, effort-tier matching, and context engineering in depth — with hands-on labs you can run from your terminal.

---

<!-- schema.org Article JSON-LD — injected into <head> by the blog template -->
```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Claude Code Subagent: When to Spawn vs Inline in 2026",
  "description": "The spawn vs inline decision comes down to context budget, not task size. Use this 7-signal matrix to protect your parent agent's reasoning quality in 2026.",
  "author": {
    "@type": "Organization",
    "name": "Koenig AI Academy",
    "url": "https://academy.kspl.tech"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Koenig AI Academy",
    "logo": {
      "@type": "ImageObject",
      "url": "https://academy.kspl.tech/logo.png"
    }
  },
  "datePublished": "2026-06-05",
  "dateModified": "2026-06-05",
  "image": "https://academy.kspl.tech/img/blogs/claude-code-subagent-context-window/hero.png",
  "url": "https://academy.kspl.tech/blog/claude-code-subagent-context-window-strategy",
  "keywords": ["claude code", "subagent", "context window", "ai coding agents", "multi-agent", "context engineering"]
}
```

---

[^1]: Claude Code official documentation — [Create custom subagents](https://code.claude.com/docs/en/sub-agents), retrieved 2026-06-05
[^2]: Anthropic Engineering — [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system), retrieved 2026-06-05
[^3]: Anthropic Engineering — [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), retrieved 2026-06-05
[^4]: Anthropic Claude Cookbook — [Automatic context compaction](https://platform.claude.com/cookbook/tool-use-automatic-context-compaction), retrieved 2026-06-05
[^5]: Hyperdev — [How Claude Code Got Better by Protecting More Context](https://hyperdev.matsuoka.com/p/how-claude-code-got-better-by-protecting), retrieved 2026-06-05
[^6]: arXiv — [Dive into Claude Code: The Design Space of Today's and Future AI Coding Agents](https://arxiv.org/html/2604.14228v1), retrieved 2026-06-05
[^7]: Finout — [Claude Code Pricing 2026: Complete Plans & Cost Guide](https://www.finout.io/blog/claude-code-pricing-2026), retrieved 2026-06-05
[^8]: Shipyard — [Claude Code Subagents Quickstart](https://shipyard.build/blog/claude-code-subagents-guide), retrieved 2026-06-05
