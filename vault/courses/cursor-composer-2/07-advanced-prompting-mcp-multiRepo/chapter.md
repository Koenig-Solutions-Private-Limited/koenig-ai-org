---
chapter_num: 7
course_slug: cursor-composer-2
title: "Advanced Prompting, MCP & Multi-Repo Workflows"
status: g3-passed
duration_min: 60
vendor_tag: Cursor
learning_objectives:
  - "Apply Prompt Contracts (.cursorrules / AGENTS.md) to make Composer sessions deterministic and team-consistent"
  - "Configure MCP servers in Cursor to wire external tools into agent context during Composer sessions"
  - "Manage context saturation in large and multi-repo codebases using workspace structuring and session hygiene"
  - "Route tasks between Composer 2 and frontier models based on cost-per-task reasoning, not cost-per-token instinct"
sources:
  - url: "https://cursor.com/blog/composer-2"
    title: "Cursor Composer 2 — Official Blog"
  - url: "https://venturebeat.com/technology/cursors-new-coding-model-composer-2-is-here-it-beats-claude-opus-4-6-but//"
    title: "Cursor's Composer 2: 86% cost reduction — VentureBeat"
  - url: "https://www.reddit.com/r/cursor/comments/1ryb2jt/has_anyone_actually_tested_composer_2_vs_claude/"
    title: "Community routing: Composer 2 vs frontier models — Reddit r/cursor"
  - url: "https://www.reddit.com/r/cursor/comments/1t9gzd1/tips_for_using_composer_2_new_to_cursor/"
    title: "Tips for using Cursor Composer 2 — Reddit r/cursor"
  - url: "https://news.ycombinator.com/item?id=46955895"
    title: "Prompt Contracts framing — Hacker News"
  - url: "https://www.nxcode.io/resources/news/openai-codex-vs-cursor-vs-claude-code-ai-coding-tools-2026"
    title: "Codex vs Cursor vs Claude Code 2026 — nxcode.io"
owns:
  - "MCP tool integration with Cursor Composer — wiring external tools into the agent context"
  - "Multi-repo workflows: cross-repo context, workspace coordination"
  - "Prompt engineering patterns specific to Cursor Composer 2"
  - "Cost discipline: token budgets, model routing, avoiding runaway Composer sessions"
defers_to:
  - "Background Agents for parallel cross-repo task dispatch → ch4"
  - "Bugbot automated PR review on agent-generated code → ch6"
  - ".cursorrules and AGENTS.md syntax and initial setup → ch2"
quiz_topics:
  - "Prompt Contracts: what they are and why instruction files persist across sessions"
  - "MCP tool integration: conceptual model and why Codex CLI docs don't transfer"
  - "Multi-repo context management: IDE harness advantage and saturation handling"
  - "Cost discipline: model routing heuristics and session hygiene practices"
notebooklm_source_focus:
  - "cursor.com/blog/composer-2 — context harness and IDE advantage"
  - "VentureBeat Composer 2 coverage — cost reduction and routing implications"
  - "Reddit community routing threads — practitioner model selection patterns"
  - "Hacker News Prompt Contracts — persistent instruction file framing"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "What is the core recommendation of the 'Prompt Contracts' pattern for Cursor workflows?"
    options:
      - "Paste the same system prompt at the top of every new Composer window"
      - "Store durable instructions in version-controlled files like .cursorrules or AGENTS.md"
      - "Use CI environment variables to inject context for every build-time agent run"
      - "Pin the conversation to one model to preserve session context across restarts"
    correct_idx: 1
    explanation: "Prompt Contracts treat instruction files like .cursorrules and AGENTS.md as durable control surfaces that outlive individual sessions. The whole team inherits the same rules through version control, eliminating per-session copy-paste."
    section_anchor: prompt-engineering-patterns-for-cursor-composer
  - question: "Why is Codex CLI MCP documentation an unreliable guide for configuring Cursor MCP servers?"
    options:
      - "Codex CLI does not support MCP; Cursor was first to implement the protocol"
      - "MCP in Codex CLI and Cursor are separate runtimes with different config interfaces"
      - "MCP server support is unavailable on Cursor's standard subscription plan"
      - "Cursor uses a proprietary MCP fork that breaks compatibility with standard servers"
    correct_idx: 1
    explanation: "The course dossier flags this explicitly: Codex CLI MCP and Cursor MCP are different runtimes. Using Codex CLI documentation for Cursor MCP setup produces broken configuration. Always use current Cursor documentation for Cursor-specific config."
    section_anchor: mcp-tool-integration
  - question: "What is Cursor's primary competitive advantage over terminal-based agents on large, complex codebases?"
    options:
      - "Cursor runs code in a sandbox that prevents accidental modifications to production files"
      - "Cursor's IDE harness provides indexed project context the model can reason across directly"
      - "Cursor automatically distributes large repos across parallel Background Agent instances"
      - "Cursor's headless CLI mode enables multi-repo checkout within a single agent session"
    correct_idx: 1
    explanation: "Per cursor.com/blog/composer-2, Cursor's indexed project context is the competitive moat. The harness exposes repository structure to the model so it reasons across the codebase without the user copying code snippets into the prompt manually."
    section_anchor: multi-repo-workflows-and-context-management
  - question: "According to community routing practice, when should you escalate from Composer 2 to a frontier model like Claude Opus or GPT-5?"
    options:
      - "When total session token count exceeds five thousand tokens during a single task"
      - "For architectural decisions requiring deep multi-file reasoning beyond routine refactors"
      - "Whenever the Auto routing selector chooses a model other than Composer 2 automatically"
      - "After three consecutive Composer 2 sessions to reset the context saturation baseline"
    correct_idx: 1
    explanation: "Community consensus from Reddit routing threads: Composer 2 wins on iteration speed and cost for scaffolding, refactors, and test generation. Frontier models (Claude Opus, GPT-5) remain stronger for architectural decisions requiring deep multi-file reasoning."
    section_anchor: cost-discipline-model-routing-and-session-hygiene
---

# Advanced Prompting, MCP & Multi-Repo Workflows

By Chapter 7, you have a full Cursor Composer 2 stack running: models selected, project rules applied, background agents dispatched, and [[cursor-composer-2/06-bugbot-pr-review]] reviewing every PR. This chapter covers the last mile — prompting patterns that make Composer sessions deterministic, MCP servers that extend Cursor's tool reach beyond the IDE, multi-repo context strategies, and the cost hygiene that keeps AI spend under control at team scale.

---

## Prompt Engineering Patterns for Cursor Composer

The most durable Cursor prompting practice in the practitioner community is the [Prompt Contracts framing](https://news.ycombinator.com/item?id=46955895): treat instruction files as persistent, version-controlled documents that define what the agent should always do, never do, and verify before acting. Where one-shot system prompts die when a session closes, `.cursorrules` and `AGENTS.md` files survive across sessions and teammates.

A minimal Prompt Contract for a Cursor project does three things:

1. **States project invariants.** Language version, framework, test runner, linting rules. The agent stops asking and starts asserting.
2. **Lists prohibited patterns.** No `eval()`, no hardcoded API keys, no `TODO` comments in shipped code. Every prohibition that Bugbot won't catch must live here.
3. **Defines the verification step.** "Before proposing a change, confirm the test suite passes." This converts Cursor's generation into a test-driven loop rather than a suggestion stream.

The community evidence is consistent: teams using `.cursorrules` with explicit prohibitions report fewer hallucinated dependencies and fewer off-base refactors from [community practice threads](https://www.reddit.com/r/cursor/comments/1t9gzd1/tips_for_using_composer_2_new_to_cursor/). The pattern generalises across instruction file formats — `.cursorrules`, `AGENTS.md`, `CLAUDE.md` — the runtime changes, the principle does not.

<KnowledgeCheck question="What is the core recommendation of the 'Prompt Contracts' pattern for Cursor workflows?" options={["Paste the same system prompt at the top of every new Composer window", "Store durable instructions in version-controlled files like .cursorrules or AGENTS.md", "Use CI environment variables to inject context for every build-time agent run", "Pin the conversation to one model to preserve session context across restarts"]} correctIdx={1} explanation="Prompt Contracts treat instruction files as durable control surfaces that outlive individual sessions. The whole team inherits the same rules through version control, eliminating per-session copy-paste." />

---

## MCP Tool Integration

MCP (Model Context Protocol) is the standard interface for wiring external tools — databases, APIs, search indexes, internal services — directly into an AI agent's context. When Cursor loads an MCP server, the agent can call those tools mid-session: query your dev database schema, fetch a Jira ticket, read a Confluence page, or call an internal API without leaving the IDE.

The mental model is simple: MCP servers are sidecars to the agent runtime. The agent sees a tool manifest; you see the result inline in the Composer panel. Three patterns are most useful in practice:

- **Database schema MCP.** A read-only connection to your dev DB schema. Cursor answers "what columns does `orders` have?" without you opening a separate DB client or copy-pasting schema dumps into context.
- **Documentation search.** An MCP server over your internal Confluence or Notion workspace. One `@search internal-docs "auth flow"` pulls the current architecture doc into Composer context, keeping the agent grounded in actual specs.
- **Issue tracker integration.** A Jira or Linear MCP lets the agent read the ticket, see acceptance criteria, and generate code targeting the stated spec — eliminating the tab-switching tax.

<Callout type="warning">
MCP configuration syntax and server compatibility evolve with each Cursor release. The patterns above describe the design intent; verify specific config against current Cursor docs at cursor.com/docs before deploying to your team. Do not use Codex CLI MCP documentation as a template for Cursor — they are separate runtimes with different config surfaces and separate tool manifests.
</Callout>

<KnowledgeCheck question="Why is Codex CLI MCP documentation an unreliable guide for configuring Cursor MCP servers?" options={["Codex CLI does not support MCP; Cursor was first to implement the protocol", "MCP in Codex CLI and Cursor are separate runtimes with different config interfaces", "MCP server support is unavailable on Cursor's standard subscription plan", "Cursor uses a proprietary MCP fork that breaks compatibility with standard servers"]} correctIdx={1} explanation="Codex CLI MCP and Cursor MCP are different runtimes. Using Codex CLI documentation for Cursor MCP setup produces broken configuration. Always use current Cursor documentation for Cursor-specific MCP config." />

---

## Multi-Repo Workflows and Context Management

Cursor's IDE harness — the indexed project context that makes it stronger than terminal-native agents on complex codebases — is scoped to the currently open workspace. Per [cursor.com/blog/composer-2](https://cursor.com/blog/composer-2), this indexed context is the competitive moat. For single-repo work, that's a pure advantage. For multi-repo workflows (backend service + frontend + shared library), it's a constraint to work with, not fight.

The practical approach:

1. **Workspace per context unit.** Open the services that interact as a multi-root workspace. Cursor indexes all roots; the agent reasons across them within one session, covering cross-service API calls and shared type definitions.
2. **Respect the saturation ceiling.** Long sessions on very large codebases hit context limits — community evidence is consistent on this pattern. When Composer starts producing off-base suggestions, the problem is usually a saturated context, not a model failure. End the session, summarise decisions in a note or commit message, start fresh with that summary as seed context.
3. **Cross-repo contracts go in instruction files.** If your frontend depends on a specific API contract from the backend, document that contract in `.cursorrules` or a dedicated `CONTEXT.md`. Don't rely on the agent inferring cross-repo invariants from implicit patterns at runtime.

A 2026 comparison of AI coding tools by [nxcode.io](https://www.nxcode.io/resources/news/openai-codex-vs-cursor-vs-claude-code-ai-coding-tools-2026) confirms this pattern: IDE-harness tools outperform terminal-native CLI agents on large NX monorepos precisely because they expose indexed project context without manual copying. The advantage narrows on smaller repos; it widens as the dependency graph grows.

For genuine parallel cross-repo task dispatch — spinning one agent per repo to develop features independently — see Background Agents in [[cursor-composer-2/04-background-agents]].

---

## Cost Discipline: Model Routing and Session Hygiene

Composer 2 is approximately 86% cheaper per token than prior Cursor generations, which [VentureBeat's Composer 2 coverage](https://venturebeat.com/technology/cursors-new-coding-model-composer-2-is-here-it-beats-claude-opus-4-6-but//) noted changes iteration habits at the team level — more total sessions for the same monthly budget. The risk that follows: lower unit cost encourages longer, wider sessions, which compounds token spend and accelerates context saturation.

The [community routing pattern](https://www.reddit.com/r/cursor/comments/1ryb2jt/has_anyone_actually_tested_composer_2_vs_claude/) that consistently holds: use Composer 2 for rapid iteration (scaffolding, refactors, test generation) and switch to frontier models like Claude Opus or GPT-5 for architectural decisions that require deep multi-file reasoning. The key distinction: **cost-per-task is not the same as cost-per-token**. A 10× cheaper model that needs three attempts at a complex architecture task costs 30% of one frontier-model attempt only if you scope tasks correctly.

Practical session hygiene:

- **One session per coherent task.** When the task changes, start a new session. Stale context bleeds into new tasks and inflates token consumption.
- **Use `/clear` proactively.** Accumulated chat history costs tokens on every subsequent message. Clear it when switching tasks, not after the session feels sluggish.
- **Pin Composer 2 explicitly for repeatable work.** Auto routing is convenient but opaque. For automation-adjacent tasks (test generation, migration scripts), pin the model so monthly cost is predictable.
- **Read your usage dashboard weekly.** Cursor's dashboard breaks down consumption per model. A single runaway frontier-model refactor session can cost as much as a full week of standard Composer 2 use — visibility catches this before month-end.

---

## Hands-on Exercise: Build a Three-Layer Prompt Contract

**Objective:** Create a `.cursorrules` file encoding the three-layer Prompt Contract for an existing project, then verify Composer 2 respects each layer.

**Steps:**

1. Open an active project in Cursor.
2. Create `.cursorrules` at the repo root with three explicit sections: `## Project Invariants`, `## Prohibited Patterns`, `## Verification Step`.
3. Add 3–5 rules per section specific to your stack — language version, test runner, banned anti-patterns, and the command to run tests before proposing changes.
4. Open a new Composer session. Prompt: "Add email validation to the user registration handler."
5. Deliberately prompt against one rule: "Add a TODO comment here for the edge cases." Observe whether Composer 2 complies or invokes the prohibition.
6. If it complies with the violation, tighten the prohibition wording and retry until it holds.

**Success criteria:** Composer 2 correctly applies at least two project invariants without being reminded in the prompt. The prohibition test either prevents the violation or surfaces it so you can tighten the rule.

---

Chapter 8 brings everything together into a full production feature built end-to-end with the Cursor Composer 2 stack. See [[cursor-composer-2/08-capstone-production-feature]].
