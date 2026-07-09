---
date: 2026-06-05
title: "What to Put in Your CLAUDE.md File in 2026: The Hierarchy Most Guides Miss"
author: koenig-ai-academy
description: "Your CLAUDE.md should be a 4-layer hierarchy of pointers, not a dumping ground. Here's exactly what belongs in each layer (and what should live in .claude/rules/ or CLAUDE.local.md instead)."
seo_description: "Your CLAUDE.md should be a 4-layer hierarchy of pointers, not a dumping ground. What belongs in each layer and what goes in .claude/rules/ instead."
ticket: KOEA-7350
vendor_tag: anthropic
content_type: article
status: g3-passed
reading_time_min: 8-12
primary_query: "what to put in CLAUDE.md Claude Code 2026"
contrarian_angle: "The highest-performing CLAUDE.md files are mostly empty pointers — teams that pile in every convention they want Claude to remember get worse output than teams who use the four-layer hierarchy and put content in the right layer"
first_60_words_answer: "Your CLAUDE.md should contain project purpose and tech stack (2-4 sentences), exact build/test/lint commands, explicitly off-limits file paths, and @-pointers to detailed documentation — not inline style guides, linting rules, or personal preferences. Keep it under 200 lines. Everything else belongs in .claude/rules/ for scoped guidelines, hooks for deterministic actions, CLAUDE.local.md for personal preferences, or sub-docs pointed to by @-imports."
original_data: true
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: defends
last_updated: 2026-06-05
hero_image:
  url: /img/blogs/2026-06-05-what-goes-in-claude-md-file/hero.png
  alt: "Annotated diagram showing four-layer CLAUDE.md hierarchy from managed policy at top through user, project, and subdirectory layers, with content type examples at each layer"
faq:
  - question: "What should go in a CLAUDE.md file?"
    answer: "A CLAUDE.md file should contain: (1) project purpose and tech stack in 2-4 sentences, (2) exact build, test, and lint commands, (3) explicitly off-limits file paths, (4) @-pointers to detailed documentation files, and optionally (5) compaction behavior instructions. It should NOT contain linting rules (use hooks), personal preferences (use CLAUDE.local.md), or task-specific context (use .claude/rules/). Target under 200 lines; 80 lines is achievable for most projects after moving scoped rules to .claude/rules/ sub-files."
  - question: "How long should a CLAUDE.md file be?"
    answer: "Anthropic's official best practices recommend under 200 lines. Files over 300–500 lines degrade performance: Claude samples rather than reads, signal dilutes in noise, and contradictory rules produce inconsistent behavior. The 80-line target is achievable for most projects after one compression session that moves scoped rules to .claude/rules/ sub-files and detailed conventions to @-linked docs. See docs.anthropic.com/en/docs/claude-code/memory for the full loading hierarchy."
  - question: "What is the difference between CLAUDE.md and CLAUDE.local.md?"
    answer: "CLAUDE.md is checked into git and shared with the entire team — it contains project-wide conventions, architecture decisions, and shared workflows. CLAUDE.local.md is auto-gitignored and stores personal preferences that shouldn't affect teammates: verbosity level, preferred explanation depth, or session shortcuts. Claude Code loads both files at session start, giving each developer a shared project context plus their own personal layer on top."
  - question: "What is .claude/rules/ for in Claude Code?"
    answer: "The .claude/rules/ directory holds scoped instruction files that load conditionally based on file path globs defined in YAML frontmatter. A rule file with paths: ['src/api/**.ts'] activates only when Claude touches API files. This is the correct location for language-specific conventions, security reminders for particular modules, or testing patterns — context that is specific enough that loading it globally would waste tokens on unrelated tasks."
  - question: "Should I use /init to generate my CLAUDE.md?"
    answer: "The /init command generates a reasonable starting draft by scanning your project structure and stack. Most experienced practitioners use it as a base and prune aggressively — the generated output often documents what Claude already knows (framework conventions) rather than the project-specific decisions that actually prevent mistakes. Hand-craft the final file after pruning. Do not keep generated content you cannot justify line by line."
whats_new:
  - "CLAUDE.md's highest-performing pattern is 80% pointers and 20% content — not the 500-line instruction dump most teams write"
learning_objectives:
  - "Know which five categories of content belong in a root CLAUDE.md"
  - "Redirect linting rules, personal preferences, and scoped guidelines to the correct layer"
  - "Apply the orchestrator pattern to keep root files under 100 lines as projects scale"
sources:
  - https://docs.anthropic.com/en/docs/claude-code/memory
  - https://www.anthropic.com/engineering/claude-code-best-practices
  - https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
  - https://www.humanlayer.dev/blog/writing-a-good-claude-md
  - https://www.builder.io/blog/claude-md-guide
  - https://www.buildcamp.io/guides/the-ultimate-guide-to-claudemd
  - https://www.digitalapplied.com/blog/claude-code-anti-patterns-team-adoption-failure-modes-2026
  - https://news.ycombinator.com/item?id=46098838
  - https://dometrain.com/blog/creating-the-perfect-claudemd-for-claude-code
schema:
  - BlogPosting
  - FAQPage
---

# What to Put in Your CLAUDE.md File in 2026: The Hierarchy Most Guides Miss

Your CLAUDE.md should contain project purpose and tech stack (2-4 sentences), exact build/test/lint commands, explicitly off-limits file paths, and @-pointers to detailed documentation — not inline style guides, linting rules, or personal preferences. Keep it under 200 lines. Everything else belongs in `.claude/rules/` for scoped guidelines, hooks for deterministic actions, `CLAUDE.local.md` for personal preferences, or sub-docs pointed to by @-imports.

The most common advice about CLAUDE.md is "add your conventions so Claude remembers them." That framing produces 500-line files that degrade rather than improve performance. Claude doesn't read monolithic memory files like a human reads a spec — it loads and samples. Past roughly 300 lines, signal dilutes into noise, the model starts quietly skipping sections, and teams believe their context is comprehensive when the agent is already pattern-matching around it. [Digital Applied, 2026](https://www.digitalapplied.com/blog/claude-code-anti-patterns-team-adoption-failure-modes-2026) The highest-leverage CLAUDE.md files are mostly pointers, not content. The hierarchy is what most teams miss entirely.

![Annotated diagram showing the four-layer CLAUDE.md hierarchy: managed policy at organization level, user-level for cross-project preferences, project-level for team-shared conventions, and subdirectory-level for module-specific rules](/img/blogs/2026-06-05-what-goes-in-claude-md-file/hierarchy-diagram.png)

---

## The Four-Layer Hierarchy You're Probably Using Wrong

Claude Code loads CLAUDE.md from a precedence hierarchy, not just your project root. [Anthropic — How Claude Remembers Your Project](https://docs.anthropic.com/en/docs/claude-code/memory) Understanding the layers changes what you put where:

| Layer | Location | Scope | Shared via |
|-------|----------|-------|-----------|
| **Managed policy** | `/etc/claude-code/CLAUDE.md` (Linux) | Organization-wide | IT/DevOps deployment |
| **User** | `~/.claude/CLAUDE.md` | All your projects | Personal only |
| **Project** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | This repo | Git |
| **Subdirectory** | `./src/api/CLAUDE.md` | That directory only | Git |

Most guides treat the project layer as the only layer and ignore the rest. The right design:

- **Managed layer** → security policies, compliance reminders, org-wide coding standards deployed by IT
- **User layer** → your personal cross-project preferences (verbosity level, preferred explanations, shortcuts)
- **Project layer** → project-specific architecture decisions and build commands, shared with the team via git
- **Subdirectory layer** → module-specific conventions loaded only when Claude touches that directory

The subdirectory layer is the most underused. If you're writing 400 lines in your root CLAUDE.md to cover all your packages, you've picked the wrong layer. Move package-specific rules to `packages/api/CLAUDE.md` and `packages/web/CLAUDE.md`. The [context window](/glossary/context-window) stays clean and scoped to whatever Claude is actually touching. [Medium — Complete Guide to CLAUDE.md](https://medium.com/@bijit211987/the-complete-guide-to-claude-md-memory-rules-loading-and-cross-tool-compression-97cc12ed037b)

---

## What Belongs in a Root CLAUDE.md

After pruning, a production CLAUDE.md should have five categories of content and nothing else:

**1. Project WHY and WHAT (2–4 sentences)**

The model can read your code, but it cannot infer your product's strategic constraints. Why does this service exist? What are the non-obvious architectural decisions that govern every change?

```markdown
# Project Overview
Multi-tenant SaaS billing service for Acme Corp. Handles Stripe webhooks,
usage-based metering, and invoice generation for 3,000 enterprise customers.
All billing mutations must be idempotent — see @docs/idempotency.md for the pattern.
```

**2. Exact build, test, and lint commands**

Don't make Claude guess. Wrong commands waste tool-call rounds and sometimes break things.

```markdown
# Commands
- Build: `pnpm build`
- Test: `pnpm test` (unit) | `pnpm test:integration` (needs Docker)
- Lint: `pnpm lint`
- Type check: `pnpm tsc --noEmit`
```

**3. Explicitly off-limits paths**

Claude Code's `--worktree` flag isolates changes to a branch, but the model also needs to know which files are human-only:

```markdown
# Off-Limits Files
- NEVER modify: `prisma/migrations/` (hand-authored; use migration tooling)
- NEVER modify: `.env*` files
- NEVER modify: `infra/terraform/` without explicit instruction
```

**4. @-pointers to detailed docs**

This is the most important pattern and the one most files get wrong. Anthropic's [best practices guide](https://www.anthropic.com/engineering/claude-code-best-practices) is explicit: include the project overview inline, but for detailed conventions, use `@-pointers` to let Claude fetch them just-in-time. Anthropic's own [context engineering research](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) describes the principle: "CLAUDE.md files are naively dropped into context up front, while primitives like glob and grep allow Claude to navigate its environment and retrieve files just-in-time, effectively bypassing the issues of stale indexing." The pointer tells Claude where to go when it needs the information; don't duplicate content upfront.

```markdown
# Reference Docs
- Authentication flow: @docs/auth-flow.md
- API conventions: @docs/api-design.md
- Error handling patterns: @docs/error-handling.md
- Database schema: @prisma/schema.prisma
```

**5. Compaction behavior instructions (optional but high-value)**

When Claude Code hits context limits, it compacts the conversation. You can specify what to preserve:

```markdown
# Compaction
When compacting: always preserve the full list of files modified, open TODO items,
and any test commands run with their outcomes.
```

---

## What Doesn't Belong (and Where It Should Go)

Wrong content in CLAUDE.md doesn't just waste lines — it competes with correct content for attention. [HumanLayer — Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)

**Linting rules → hooks**

"Always run ESLint before committing" is the canonical example of an instruction that belongs in a hook, not CLAUDE.md. CLAUDE.md instructions are advisory — the model can and sometimes does skip them. Hooks are deterministic: they run on every trigger with zero exceptions. [Anthropic best practices](https://www.anthropic.com/engineering/claude-code-best-practices) If it must happen every time, wire a hook. If it's a preference, CLAUDE.md is fine.

**Scoped guidelines → `.claude/rules/`**

Rules that only apply to specific file types belong in `.claude/rules/` with path-scoped frontmatter, not in the root file:

```markdown
---
paths:
  - "src/api/**.ts"
---
# API Handler Conventions
- Validate request bodies with Zod schemas
- Return HTTP 422 for validation failures, not 400
- Log all auth failures with structuredLog('auth.failure', ...)
```

This rule loads only when Claude touches an API file. A developer working in the React frontend never sees it. Scoping at this level also makes rules easier to maintain — the team owns security conventions for `src/api/` without those conventions polluting the experience in `src/components/`. [Dometrain — Creating the Perfect CLAUDE.md](https://dometrain.com/blog/creating-the-perfect-claudemd-for-claude-code)

**Personal preferences → `CLAUDE.local.md`**

Your preference for verbose explanations, or your habit of requesting diffs before accepting edits, doesn't belong in the shared project file. Claude Code auto-gitignores `CLAUDE.local.md`, making it the correct location for personal preferences that would be noise for teammates. [Builder.io — How to Write a Good CLAUDE.md](https://www.builder.io/blog/claude-md-guide)

---

## The Orchestrator Pattern: Pointers Beat Content at Scale

The teams reporting the best results at scale use what practitioners call the orchestrator pattern: the root file is almost entirely pointers, and actual content lives in linked sub-docs. [BuildCamp — The Ultimate Guide to CLAUDE.md](https://www.buildcamp.io/guides/the-ultimate-guide-to-claudemd)

The `@`-import syntax makes this concrete:

```markdown
# Project Context
@README.md

# Development Guide
@docs/development.md

# Architecture Decisions
@docs/adr/0001-database-choice.md
@docs/adr/0012-auth-strategy.md
```

Claude reads the linked files when it needs them, not upfront. This keeps the context window clean for the actual task rather than loading every convention into memory at session start. A BuildCamp analysis of high-performing configurations found that orchestrator-style files "consistently outperform the monolithic version, even at identical total line counts" — the model handles small linked context far better than large blocks of inline text.

The linked structure also stays accurate longer. A doc file with a heading like `@docs/api-design.md` is maintained by whoever owns API conventions. The root CLAUDE.md just points to it. When conventions change, you update the doc, not the CLAUDE.md. Monolithic files decay fast because no one owns cleanup.

---

## Where to Configure What: A Decision Matrix

This table synthesizes across all five Claude Code configuration surfaces. No single official doc consolidates this view:

| Configuration type | Best location | Advisory vs deterministic | Shared with team |
|---|---|---|---|
| Project overview, purpose, non-obvious constraints | Root `CLAUDE.md` | Advisory | Yes (git) |
| Build/test/lint commands | Root `CLAUDE.md` | Advisory | Yes (git) |
| Off-limits paths | Root `CLAUDE.md` | Advisory | Yes (git) |
| Pointers to documentation | Root `CLAUDE.md` (`@`-imports) | Advisory | Yes (git) |
| Language-specific conventions | `.claude/rules/<rule>.md` with `paths:` | Advisory | Yes (git) |
| Security rules for a specific module | `.claude/rules/security.md` with `paths:` | Advisory | Yes (git) |
| Pre/post-edit actions (lint, format, test) | `.claude/settings.json` hooks | **Deterministic** | Yes (git) |
| Blocks on sensitive paths | `.claude/settings.json` hooks | **Deterministic** | Yes (git) |
| Personal verbosity/explanation preferences | `CLAUDE.local.md` | Advisory | No (gitignored) |
| Personal session shortcuts | `CLAUDE.local.md` | Advisory | No (gitignored) |
| Org-wide security/compliance standards | `/etc/claude-code/CLAUDE.md` (managed) | Advisory | All users in org |
| Cross-project personal preferences | `~/.claude/CLAUDE.md` | Advisory | No |

The key column is advisory vs deterministic. CLAUDE.md is advisory — it informs Claude's behavior but doesn't guarantee it. If a rule must always run, it belongs in a hook. Piling enforcement rules into CLAUDE.md and then complaining that "Claude ignored my instructions" is the most common failure mode on community threads. [HN thread 46098838](https://news.ycombinator.com/item?id=46098838)

---

## Runnable Example: A Minimal but Complete CLAUDE.md

```markdown
# Acme Billing Service

TypeScript/Node.js billing microservice for enterprise SaaS. Handles Stripe webhooks,
usage-based metering, and invoice generation. All billing mutations must be idempotent.

## Commands
- Build: `pnpm build`
- Test (unit): `pnpm test`
- Test (integration): `pnpm test:integration` (requires Docker)
- Lint: `pnpm lint`
- Type check: `pnpm tsc --noEmit`

## Off-Limits
- Never modify `prisma/migrations/` directly — use migration tooling
- Never modify `.env*` files

## Reference Docs
- Authentication: @docs/auth-flow.md
- Error handling: @docs/error-handling.md
- Billing mutations: @docs/idempotency.md

## Compaction
Preserve: all modified file paths, open TODOs, last test run results.
```

**22 lines.** Covers all five categories. Linting runs via a hook in `.claude/settings.json`. API conventions live in `.claude/rules/api.md` scoped to `src/api/**.ts`. Personal preferences are in `CLAUDE.local.md`. The root file is a stable pointer map that rarely changes and is easy for the whole team to maintain.

---

## Knowledge Check

Which location is correct for a rule that should only apply when Claude modifies TypeScript files in `src/api/`?

A) Root `CLAUDE.md`  
B) `~/.claude/CLAUDE.md`  
C) `.claude/rules/api.md` with `paths: ["src/api/**.ts"]` frontmatter  
D) `.claude/settings.json` hooks

*Correct answer: C. Path-scoped rules in `.claude/rules/` load conditionally based on the files Claude is touching, keeping context clean for unrelated work.*

---

A well-structured CLAUDE.md is the foundation — but it's one layer of a full [Claude Code](/blog/ai-tool-deep-dive-claude-code) harness that also covers subagents, [MCP](/glossary/model-context-protocol) server wiring, and worktree isolation. If you're evaluating whether to build a multi-agent pipeline or choosing between tools for your team, the [AI coding agents buyers guide](/blog/ai-coding-agents-production-2026-buyers-guide) gives the full decision matrix. For the model-specific setup for Opus 4.7 — including effort levels, task budgets, and the Detailed Plan Pattern — the [Opus 4.7 production guide](/blog/2026-06-04-claude-code-opus-4-7-production-guide) covers the specifics.

Ready to build a production-grade Claude Code setup end to end? **[[course/claude-code-production-workflows]]** covers CLAUDE.md architecture, hook design, `.claude/rules/` scoping, subagent orchestration, and MCP server wiring across structured hands-on modules.
