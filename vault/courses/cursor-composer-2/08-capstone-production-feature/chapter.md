---
chapter_num: 8
course_slug: cursor-composer-2
title: "Capstone: Build a Production Feature End-to-End with Cursor Composer 2"
description: "Apply .cursorrules, Background Agents, Bugbot, and MCP together in a single 60-minute capstone exercise — webhook handler or data ingestion pipeline — and write the AI-first process document that makes the workflow reproducible."
status: g0-passed
duration_min: 65
vendor_tag: cursor
last_updated: 2026-06-12
tags:
  - cursor-composer-2
  - capstone
  - ai-first-engineering
  - production-workflow
  - background-agents
positions: []  # capstone synthesis chapter; no STANCES.md position applies — synthesizes tool usage from prior chapters without advocating a specific competitive stance
learning_objectives:
  - "Combine .cursorrules, Background Agents, Bugbot, and MCP in a single production feature workflow"
  - "Decide when to stay in Composer versus spawn a Background Agent during feature delivery"
  - "Write an AI-first engineering process document capturing decisions, prompts, and outcomes"
  - "Complete a 60-minute self-contained capstone exercise: webhook handler or data ingestion pipeline"
sources:
  - url: "https://cursor.com/blog/composer-2"
    title: "Composer 2 — Cursor Blog"
    retrieved: "2026-06-11"
  - url: "https://www.reddit.com/r/cursor/comments/1t9gzd1/tips_for_using_composer_2_new_to_cursor/"
    title: "Tips for using Composer 2 — r/cursor"
    retrieved: "2026-06-11"
  - url: "https://news.ycombinator.com/item?id=46955895"
    title: "Prompt Contracts framing — Hacker News"
    retrieved: "2026-06-11"
  - url: "https://render.com/blog/ai-coding-agents-benchmark/"
    title: "AI Coding Agents Benchmark — Render"
    retrieved: "2026-06-11"
  - url: "https://www.reddit.com/r/LocalLLaMA/comments/1t8t6tl/qwen3635ba3b_on_rtx_3090_113_ts_but_context/"
    title: "Context saturation in large-context model sessions — r/LocalLLaMA"
    retrieved: "2026-06-11"
  - url: "https://cursor.com/bugbot"
    title: "Bugbot — Cursor"
    retrieved: "2026-06-11"
faq:
  - question: "When should I spawn a Background Agent instead of staying in Composer during the capstone?"
    answer: "Spawn a Background Agent when the task is fully independent of the current feature slice — for example, scaffolding a test suite in parallel with the handler logic. Background Agents run on isolated branches and complete concurrently; Composer is single-threaded and serializes work that could run in parallel. The routing table in the Routing Decisions section provides the full decision map. [2][3]"
  - question: "What does Bugbot Autofix do with an agent-generated PR?"
    answer: "Bugbot scans the PR, identifies issues, and surfaces targeted inline fixes directly in your Cursor editor or via a Background Agent for you to review and apply. The developer applies the fixes — Bugbot does not auto-commit to the PR branch. Full configuration and behavior are covered in ch6. [6]"
  - question: "What belongs in an AI-first engineering process document?"
    answer: "A minimal process document captures five observable layers: the feature spec, the prompt contracts used (.cursorrules version and any session-level prompts), the routing log (Composer vs Background Agents vs Bugbot decisions), the override log (where you manually corrected tool output), and the outcome summary. It does not capture model internals — only engineer decisions and tool verdicts. [4]"
owns:
  - "Full production feature E2E implementation workflow"
  - "AI-first engineering documentation and process capture"
  - "Cross-chapter pattern synthesis: .cursorrules + Background Agents + Bugbot + MCP"
  - "Capstone hands-on exercise: webhook handler or data ingestion pipeline (60 min)"
defers_to:
  - ".cursorrules + AGENTS.md setup mechanics → ch2"
  - "Background Agents deep-dive → ch4"
  - "Bugbot configuration and PR review setup → ch6"
  - "MCP server wiring + multi-repo workflow → ch7"
quiz_topics:
  - "How to apply .cursorrules constraints during a live Capstone Composer session"
  - "Decision points: when to spawn Background Agents vs stay in Composer"
  - "What Bugbot Autofix does with agent-generated PRs"
  - "Managing multi-repo context saturation in a single Composer session"
  - "Core elements of an AI-first engineering process document"
notebooklm_source_focus:
  - "cursor.com production workflow and Composer 2 docs"
  - "End-to-end AI engineering patterns — webhook handler and data pipeline examples"
  - "AI-first development process documentation templates"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "During a Composer session, the model generates handler functions using a naming convention your team abandoned six months ago. Which file should have encoded the current conventions before the session started?"
    options:
      - ".gitignore — determines which files are excluded from version control, not AI behavior"
      - ".cursorrules — the per-session AI control surface Cursor reads at session start"
      - "package.json — defines project dependencies and build scripts, not AI constraints"
      - "README.md — plain human-readable documentation with no AI instruction semantics"
    correct_idx: 1
    explanation: ".cursorrules is read at session start and acts as the durable control surface for AI behavior in Cursor. Stale rules produce stale output — the fix is updating .cursorrules before the session, not mid-session patches. Setup mechanics are covered in ch2."
    section_anchor: the-four-tools-in-one-session
  - question: "You need to scaffold five independent microservice stubs in parallel. What is the correct routing decision?"
    options:
      - "Open five Composer tabs and coordinate them manually by copy-pasting between results"
      - "Spawn one Background Agent per stub so each runs concurrently on its own branch"
      - "Ask Bugbot to generate the stubs automatically from the open PR description"
      - "Configure an MCP template server and skip Composer for this scaffolding task"
    correct_idx: 1
    explanation: "Background Agents run concurrently, each on an isolated branch — exactly the right tool for parallel independent tasks. Composer is single-threaded by design and would serialize work that can safely run in parallel. Background Agent mechanics are covered in ch4."
    section_anchor: routing-decisions-a-decision-map
  - question: "Bugbot Autofix triggers on an agent-generated PR. What does it do next?"
    options:
      - "Bugbot closes the PR and reopens a replacement with a cleaned commit history"
      - "Bugbot posts a comment listing issues and waits for human approval of each fix"
      - "Bugbot surfaces inline fixes in your editor or via Background Agent for you to apply"
      - "Bugbot rolls back the branch to the most recent green CI commit automatically"
    correct_idx: 2
    explanation: "Bugbot reviews the PR, identifies issues, and surfaces targeted inline fixes directly in your Cursor editor or via a Background Agent for you to apply — significantly reducing manual review burden on agent-generated code [6]. Full configuration and behavior are covered in [[06-bugbot-pr-review|ch6]]."
    section_anchor: routing-decisions-a-decision-map
  - question: "Your Composer session pulls context from two repos and three MCP servers. Response quality drops. What is the first intervention?"
    options:
      - "Upgrade your Cursor subscription to a higher tier for an expanded context window"
      - "Pin only the files active for this feature slice and drop the background repo context"
      - "Switch to Composer 2 Fast to trade output quality for additional context headroom"
      - "Restart the Cursor IDE to force the context index to completely rebuild"
    correct_idx: 1
    explanation: "Context saturation degrades quality when too many repos and MCP servers compete for attention. The fix is surgical scoping: pin only in-scope files and drop what the current feature slice does not need. Cursor's indexed project context makes this precise narrowing possible."
    section_anchor: managing-context-saturation
  - question: "Which element does NOT belong in an AI-first engineering process document?"
    options:
      - "Prompt contracts used for each major Composer or Background Agent invocation"
      - "A decision log noting when Background Agents were spawned versus Composer kept"
      - "The model's raw internal chain-of-thought tokens captured from each session"
      - "Bugbot Autofix verdicts and any manual overrides the engineer applied afterward"
    correct_idx: 2
    explanation: "A model's internal chain-of-thought is not exposed or capturable by engineers. An AI-first process document records observable artifacts: prompts used, routing decisions, tool verdicts, and engineer overrides — not model internals."
    section_anchor: writing-the-ai-first-process-document
---

## The Four Tools in One Session

A real production feature doesn't live in a single tool. By chapter 8 you've built fluency with four distinct layers: the constraint surface (.cursorrules and AGENTS.md, [[02-project-discipline-layer|ch2]]), the parallel execution layer ([[04-background-agents|Background Agents, ch4]]), the automated code review gate ([[06-bugbot-pr-review|Bugbot, ch6]]), and the external data and context layer ([[07-advanced-prompting-mcp-multiRepo|MCP servers and multi-repo wiring, ch7]]). The capstone isn't about adding new tools — it's about sequencing the ones you have.

The mental model that makes sequencing work: **Cursor's IDE harness provides indexed project context as its core competitive moat**. Everything else — Background Agents, Bugbot, MCP — extends that harness outward. The constraint surface sets the rules before the session starts; the parallel execution layer handles work that can't share context; the review gate catches what agents miss; the MCP layer feeds the harness external truth.

<Callout type="info">
Before you open Composer for the capstone, verify your .cursorrules file encodes your target service's conventions: module boundaries, error handling patterns, logging format, and test file co-location. Cursor reads .cursorrules at session start — not mid-session. If the rules are stale, everything spawned downstream inherits the stale contract. Setup mechanics are in [[02-project-discipline-layer]].
</Callout>

<KnowledgeCheck
  question="You start a Composer session and notice the AI is generating handler functions with a naming convention your team abandoned six months ago. What was missing from your pre-session setup?"
  options={[
    "A fresh Git branch for the feature",
    "An updated .cursorrules file encoding current naming conventions",
    "An MCP server for the team's style guide",
    "A Background Agent to run the linter in parallel"
  ]}
  correctIdx={1}
  explanation=".cursorrules is read at session start and acts as the durable control surface for AI behavior. Stale rules produce stale output — the fix is updating .cursorrules before the session, not applying mid-session corrections."
/>

## Routing Decisions: A Decision Map

The costliest mistake in an AI-first workflow is using the wrong tool for the job. Composer is single-threaded and context-bound. Background Agents are concurrent and branch-isolated. Bugbot runs post-PR. MCP servers extend what Composer can reach but consume context budget. The right routing decision determines whether you wait 20 minutes for sequential work or get five results in parallel.

| Situation | Right tool |
|---|---|
| Scaffolding 3+ independent stubs in parallel | Background Agent per stub |
| Implementing a single feature slice with deep cross-file context | Composer session |
| Reviewing and fixing an agent-generated PR | Bugbot Autofix |
| Pulling live schema or API spec into Composer | MCP server |
| A multi-repo refactor where each repo is independent | Background Agent per repo |
| A multi-repo feature where repos share a domain model | Composer + pinned context from each repo |

Community practice confirms that .cursorrules and AGENTS.md are most effective when treated as **prompt contracts** — durable, versioned, and reviewed like code ([HN Prompt Contracts](https://news.ycombinator.com/item?id=46955895)). For the capstone, your .cursorrules file is the contract that governs everything spawned downstream: Background Agents inherit it, Bugbot enforces it in review, and MCP servers serve data that should conform to it.

<KnowledgeCheck
  question="You need to add an authentication middleware to your Express app AND scaffold a matching integration test suite. These are fully independent tasks. What's the optimal tool split?"
  options={[
    "One Composer session for both, switching focus between the two tasks",
    "Two Background Agents — one per task — running concurrently on separate branches",
    "Bugbot to generate the middleware and Composer for the test suite",
    "One MCP server call to retrieve a boilerplate template covering both"
  ]}
  correctIdx={1}
  explanation="Independent tasks with no shared context are the exact use case for Background Agents. Each gets its own branch and runs concurrently, completing both in the time one would take in a linear Composer session."
/>

## Managing Context Saturation

Multi-tool sessions create a specific failure mode: **context saturation**. When a Composer session pulls from two repos, three MCP servers, and a long conversation history, quality degrades — the model starts averaging across contexts instead of reasoning precisely within your target scope. Large-context sessions reliably produce this pattern: the more unrelated material competes for attention, the less accurate the output becomes ([context saturation pattern](https://www.reddit.com/r/LocalLLaMA/comments/1t8t6tl/qwen3635ba3b_on_rtx_3090_113_ts_but_context/)).

The discipline: **pin only what the current slice needs**. If you're implementing a webhook handler, the analytics repo does not belong in context. If your MCP server exposes three schemas but only one is relevant, name it explicitly in your prompt and ask Composer to ignore the others. Cursor's indexed project context is a precision tool — treat it like a scope, not a dumping ground.

Watch for these saturation signals before quality collapses:

- Composer mixes idioms from files you didn't include in the active context
- Generated code references types or functions that don't exist in the pinned scope
- Response latency increases without any model or plan change

When you see these signals, close the session, reopen with a narrower context, and continue. The overhead of a clean restart is lower than the review cost of saturated output.

## Writing the AI-First Process Document

The capstone deliverable is not just working code — it's a **process document** that makes the workflow reproducible and auditable. An AI-first process document captures the observable layer of the session: what was prompted, what was routed where, what the tools produced, and what the engineer overrode.

A minimal document contains five sections:

1. **Feature spec** — what was being built and why, in two to three sentences
2. **Prompt contracts** — the .cursorrules version used, any session-level system prompts added
3. **Routing log** — which tasks went to Composer, which spawned Background Agents, which triggered Bugbot Autofix
4. **Override log** — where tool output was manually corrected and the reason for each override
5. **Outcome summary** — tests passing, PR merged, known deferred items and their owners

An AI-first process document does not capture the model's internal reasoning. That layer is not accessible. The value is in decisions and prompt contracts, not model internals — the same reason a commit message records intent, not the compiler's intermediate output.

[Cursor's benchmark advantage on setup speed and code quality in IDE-shaped tasks](https://render.com/blog/ai-coding-agents-benchmark/) depends on exactly this discipline: structured inputs — clear constraints, scoped context, defined routing — produce structured outputs. The process document is the evidence that the discipline held.

## Capstone Exercise: Webhook Handler or Data Ingestion Pipeline

**Choose one path and complete it within 60 minutes.**

**Option A — Stripe webhook handler (Express / Node)**

Build a `/webhooks/stripe` POST endpoint that:
- Validates the `Stripe-Signature` header using the Stripe SDK
- Routes `checkout.session.completed` events to an order-creation service function
- Returns `200` on verified success and `400` on signature failure
- Includes co-located integration tests covering both the success and failure paths

**Option B — CSV data ingestion pipeline (Python)**

Build a pipeline that:
- Reads a CSV from a configurable local path (via environment variable)
- Validates each row against a Pydantic schema with at least three required fields
- Writes valid rows to a SQLite database and logs invalid rows to stderr
- Includes unit tests for both the row validator and the database writer

**Required process for both options:**

1. Confirm your .cursorrules file encodes this service's conventions before opening Composer (ch2)
2. Open a Composer session scoped to the target service directory only
3. If you identify two or more independent subtasks (e.g., endpoint logic and test suite), spawn Background Agents instead of running them sequentially in Composer (ch4)
4. Open a PR — Bugbot Autofix should auto-review the agent-generated code (ch6)
5. If pulling an external schema or API spec into Composer, wire an MCP server for it (ch7)
6. Write a process document at `docs/ai-process/capstone.md` covering the five required sections

**Success criteria:**

- Feature code and tests are in a merged PR with all CI checks passing
- A Bugbot Autofix comment appears on the PR (or is manually annotated if Bugbot is unavailable in your environment)
- `docs/ai-process/capstone.md` is committed to the repo and covers all five process document sections
- No .cursorrules violations appear in the final merged code (run a manual diff against your rules file)

---

This is the final chapter of *Cursor Composer 2 — IDE-First AI Engineering*. The patterns you've practiced here — constraint surfaces, parallel agents, automated review gates, and multi-repo context discipline — are not Cursor-specific habits. They are the primitives of AI-first engineering that scale to any IDE-embedded workflow you encounter next.
