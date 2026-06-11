---
course_slug: cursor-composer-2
chapter_num: 4
title: "Background Agents: Hand Off a Task, Keep Coding"
description: "Learn how Cursor Background Agents extend your IDE with async task execution — from in-IDE parallel worktree agents to cloud-hosted Ubuntu VMs that produce pull requests while you code, plus the limitations that keep them off the CI path."
chapter_primary_query: "What are Cursor Background Agents, how do they differ from Composer and headless CLI tools, and when should I use them?"
first_60_words_answer: "Background Agents let you hand off a coding task to Cursor's async runtime — a cloud-hosted Ubuntu VM or an in-IDE background thread — and keep working while it runs. Unlike Composer's synchronous diff-review loop, a Background Agent clones your repo, executes the task, and returns a pull request or diff for your review. Two modes, two trade-offs — one clear decision framework."
learning_objectives:
  - "Distinguish the two Background Agent modes — in-IDE Agents Window tasks and Cloud Background Agents — and explain when each applies"
  - "Configure a Background Agent environment using .cursor/environment.json and .cursor/worktrees.json for isolated parallel execution"
  - "Apply Chapter 3's routing rubric to determine when Background Agents extend the IDE path versus when headless CLI tools are required"
  - "Evaluate the credit, connectivity, and scope limitations of Background Agents and design tasks that stay within those constraints"
faq:
  - question: "Do Background Agents require Cursor to be open on my machine?"
    answer: "It depends on the mode. In-IDE Background Agents (running in the Agents Window) require the Cursor application to be running on your machine. Cloud Background Agents run in a sandboxed Ubuntu VM on Cursor's AWS infrastructure and can produce PRs while your laptop is closed — you trigger them by tagging @cursor on a GitHub issue or a Slack message (source: deployhq.com/guides/cursor, retrieved 2026-06-11)."
  - question: "What is the difference between Background Agents and Composer Agent Mode?"
    answer: "Composer Agent Mode is synchronous — it presents diffs after each step and waits for your review before continuing. Background Agents are asynchronous — they run independently in a background thread or cloud VM, complete the full task, and return a diff or pull request when done. Background Agents trade real-time review granularity for uninterrupted developer flow (source: stevekinney.com/courses/ai-development/cursor-background-agents, retrieved 2026-06-11)."
  - question: "Can I use Background Agents in CI/CD pipelines as a replacement for Codex CLI or Claude Code?"
    answer: "No. Background Agents are tied to Cursor's platform: in-IDE agents require the IDE to be running; Cloud Background Agents run on Cursor's infrastructure and are triggered through Cursor's own interfaces (GitHub @cursor tags, Slack). They cannot be invoked from a generic CI runner or composed into arbitrary pipeline scripts. For CI and unattended pipeline automation, use Codex CLI or Claude Code as covered in Chapter 3 (source: neura.market/directories/cursor/blog/devto-3487552, retrieved 2026-06-11)."
  - question: "What subscription tier is required for Background Agents?"
    answer: "Background Agents (both in-IDE and Cloud) require a Cursor Pro subscription or above. Free plan users have access to limited agent features but not long-running or cloud-hosted Background Agent tasks. Always verify the current tier limits at cursor.com/pricing, as the feature is actively evolving (source: cursor.com/pricing, retrieved 2026-06-11)."
sources:
  - https://www.deployhq.com/guides/cursor
  - https://stevekinney.com/courses/ai-development/cursor-background-agents
  - https://www.neura.market/directories/cursor/blog/devto-3487552
  - https://www.digitalapplied.com/blog/cursor-3-agents-window-complete-guide
  - https://cursor.com/changelog/04-24-26
  - https://cursor.com/docs/configuration/worktrees
  - https://forum.cursor.com/t/cursor-2-5-async-subagents/152125
  - https://cursor.com/blog/self-hosted-cloud-agents
  - https://cursor.com/security
tags:
  - cursor
  - background-agents
  - async-agents
  - worktrees
  - agents-window
  - cloud-agents
  - cursor-composer-2
duration_min: 45
read_time_min: 18
last_updated: 2026-06-11
status: awaiting-g0
author: content-author
ticket: KOEA-7739
whats_new: "Chapter introduces Cursor Background Agents in both in-IDE (Agents Window) and Cloud modes, the .cursor/environment.json + worktrees.json configuration pattern, and the routing position of Background Agents relative to the Chapter 3 IDE vs CLI decision tree."
prerequisites_chapters: [1, 2, 3]
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: defends
---

# Background Agents: Hand Off a Task, Keep Coding

Background Agents let you hand off a coding task to Cursor's async runtime — a cloud-hosted Ubuntu VM or an in-IDE background thread — and keep working while it runs. Unlike Composer's synchronous diff-review loop, a Background Agent clones your repo, executes the task, and returns a pull request or diff for your review. Two modes, two trade-offs — one clear decision framework.

If you have ever started a long Composer session — test suite generation across 30 files, a full-codebase rename, an async debug trace — only to find yourself alternating between "Accept" clicks and actual work, you have felt the problem Background Agents solve. Composer is a synchronous conversation. You are always in the loop, which is powerful for nuanced tasks and inefficient for mechanical ones.

Background Agents break that loop. You describe the task, hand it off, and come back to a diff — or a pull request — when it is done. This chapter covers both agent modes, how to configure them, and exactly where their usefulness ends.

---

## 4.1 Two Modes, One Feature Name

The term "Background Agents" in Cursor covers two distinct execution models introduced at different points in the product's history. Conflating them leads to misconfigured setups and mismatched expectations.

### Mode 1: In-IDE Background Agents (Agents Window)

Cursor 3, released April 2, 2026, introduced the **Agents Window** — a standalone interface for running multiple agents in parallel, each isolated in its own git worktree. [1] When you launch an agent from the Agents Window, it runs asynchronously in a background thread within the Cursor application. You can:

- Keep coding in the main editor while the agent works
- Monitor agent progress in the Agents Window status pane
- Review the diff when the agent signals completion
- Run multiple agents simultaneously on isolated branches — no mid-task merge conflicts

The Cursor 3.2 changelog (April 24, 2026) added `/multitask`, which lets the Agents Window spawn async *sub*agents automatically for large tasks. A parent agent breaks the work into chunks and assigns each chunk to a subagent that runs in parallel. [2]

**Key constraint:** The Cursor application must be running on your machine. Close Cursor, kill the in-IDE agents.

### Mode 2: Cloud Background Agents

Cloud Background Agents run in an isolated virtual machine on Cursor's AWS infrastructure, with a clean filesystem, scoped network access, and its own ephemeral checkout of your repository. [3] They were introduced in 2025 and received a major expansion on February 24, 2026: each Cloud Background Agent gained a full graphical development environment, a real browser, and the ability to interact with UI elements and record video demos of completed work. [4]

You trigger Cloud Background Agents by:
- Tagging `@cursor` on a GitHub issue
- Sending a `@Cursor` message in a connected Slack channel

The agent reads the issue or message, clones your repo, works the task, and opens a pull request — without your laptop needing to be open. [5]

**Key constraint:** These agents are tied to Cursor's platform and triggered through Cursor's own interfaces. They cannot be invoked from a generic CI runner or wired into an arbitrary pipeline script.

### Mode comparison

| | In-IDE (Agents Window) | Cloud Background Agent |
|---|---|---|
| Where it runs | Cursor process on your machine | AWS Ubuntu VM |
| IDE required? | Yes — Cursor must be open | No — laptop can be closed |
| Triggered by | Agents Window UI, `/multitask` | GitHub `@cursor` tag, Slack |
| Output | Diff in IDE | Pull request on GitHub |
| Isolation | Git worktree per agent | Isolated VM + cloned repo |
| Best for | Parallel tasks during active work | Long tasks while laptop is closed |

---

## 4.2 Setup and Configuration

### Subscription requirement

Both Background Agent modes require a **Cursor Pro** subscription or above. Verify current tier limits at cursor.com/pricing — the feature is actively evolving and tier thresholds shift between releases. [4]

### environment.json — configuring the Cloud agent environment

The Cloud Background Agent reads `.cursor/environment.json` at your repository root to understand how to bootstrap the project inside its Ubuntu VM. A minimal example for a Node.js project:

```json
{
  "setup": [
    "npm install",
    "npm run build"
  ],
  "startCommand": "npm run dev"
}
```

The agent executes every command in the `setup` array in order before tackling the actual task, so it has a working build environment from the start. For complex initialization, you can reference a `setup.sh` script instead of inlining commands. [5]

<RunPromptCell
  title="Draft your environment.json for a Next.js + Prisma project"
  prompt={`You are reviewing a .cursor/environment.json setup for a Next.js + TypeScript project. The project uses pnpm, has a Prisma schema that needs to be generated, and a .env.local file that should be copied from .env.example before the dev server starts.

Produce the minimal environment.json that will let a Cloud Background Agent reach a working build state before starting a task. Include: pnpm install, prisma generate, the .env.local copy, and the dev server start command. Return a valid JSON object only — no prose.`}
  expectedOutput={`{
  "setup": [
    "pnpm install",
    "cp .env.example .env.local",
    "pnpm exec prisma generate"
  ],
  "startCommand": "pnpm run dev"
}`}
  notes="Verify the generated JSON against your actual project's setup steps — model output is a starting point. The agent executes every setup command in order; a failing step aborts the run before the task begins."
/>

### worktrees.json — configuring in-IDE parallel agents

For in-IDE agents in the Agents Window, isolation is provided by git worktrees. Cursor creates a separate worktree (and branch) per agent to prevent file-level conflicts. Configure per-worktree setup in `.cursor/worktrees.json`: [6]

```json
{
  "setup-worktree": [
    "npm install",
    "cp $ROOT_WORKTREE_PATH/.env.local .env.local"
  ]
}
```

The `$ROOT_WORKTREE_PATH` variable resolves to the main project root, letting you copy non-tracked assets (`.env.local`, generated configs) into each isolated branch without hardcoding absolute paths. Steve Kinney's 2026 guide recommends maintaining a `workflow_state.md` file in the project root that agents read for task-coordination context during parallel runs. [5]

> <Callout type="info">
> For a deeper look at MCP connectors that Background Agents can use to interact with external services (databases, APIs, issue trackers), see the Academy course [[mcp-from-first-principles-to-production|MCP from First Principles to Production]]. Cloud Background Agents support MCP-enabled tool use within their Ubuntu VM environment.
> </Callout>

---

## KnowledgeCheck 1: Modes and Use Cases

**Question 1 (MCQ):** You need to generate unit tests for 40 TypeScript files while you continue working on a new feature. Your laptop will stay open throughout. Which mode is the right fit?

- A) Composer Agent Mode — because you want to review each test file as it is written
- B) In-IDE Background Agents (Agents Window) — because the task is mechanical and you want to keep coding without managing the synchronous review loop
- C) Cloud Background Agent via GitHub `@cursor` — because it runs off-machine and handles large tasks
- D) Codex CLI in `full-auto` mode — because Cursor cannot run test generation asynchronously

*Correct answer: B — in-IDE Background Agents via the Agents Window run asynchronously in a separate worktree while you work in the main editor. Composer (A) puts you in a synchronous 40-file diff loop. Cloud agents (C) are valid architecture but unnecessary overhead when your laptop is already open and active. Codex CLI (D) is correct for headless work but bypasses Cursor's worktree isolation and in-IDE review flow.*

**Question 2 (free-form):** A teammate says: "I'll use a Cloud Background Agent to run our nightly code-quality audit — it can fire at 2am without anyone touching Cursor." Explain in 2 sentences why this will not work.

*Model answer: Cloud Background Agents are triggered through Cursor's own interfaces — GitHub `@cursor` tags or Slack messages — not by arbitrary cron jobs or external scheduler scripts. For a scheduled unattended job, the correct tool is Codex CLI or Claude Code invoked via a cron scheduler or CI runner, as covered in Chapter 3.*

---

## 4.3 Where Background Agents Shine

Background Agents, in both modes, are designed for tasks you do not want to babysit. The pattern: hand off, keep working, review when done. [5]

### High-value use cases

**Test generation at scale.** Asking Composer to generate tests for a large codebase puts you in a diff loop for hundreds of turns. A Background Agent handles the full task — "generate Vitest tests for every `.ts` file under `/lib` that lacks a matching `.test.ts`" — and runs it to completion. You review a consolidated diff, not a turn-by-turn conversation.

**Large-scale refactoring.** Renames, interface migrations, and file-structure changes spanning dozens of files are strong candidates. In the Agents Window with worktrees, the agent works on an isolated branch, so half-finished refactors never land on your active development branch mid-flight.

**Debugging with browser verification.** As of February 2026, Cloud Background Agents have a full browser and can spin up a dev server to verify visual correctness. [4] An agent can write a fix, start the server, navigate to the affected page, and screenshot the result — all before it opens the PR for your review.

**GitHub issue → pull request.** The Cloud Background Agent's most high-leverage use case: tag `@cursor` on a well-described GitHub issue and the agent reads it, writes the fix, and opens a PR. This works best for scoped, well-documented bugs — a Sentry trace plus a clear reproduction case gives the agent the signal it needs without interactive clarification. [5]

For deeper patterns on building agents that use tools effectively, the Academy course [[claude-tool-use-from-zero|Claude Tool Use from Zero]] covers tool-calling architecture that maps directly to how Background Agents reason about multi-step tasks.

### What to avoid handing to a Background Agent

**Ambiguous tasks.** Background Agents cannot ask clarifying questions mid-run the way Composer can. Vague prompts produce vague diffs — or stuck agents burning credits.

**Tasks requiring sensitive credentials at runtime.** The cloud environment has access to your repo but should not hold production secrets. Keep secret values in GitHub Secrets and reference them via environment variables rather than putting them in `environment.json`.

**Real-time collaborative tasks.** If a task needs rapid back-and-forth — "does this API shape look right? What about this alternative?" — keep it in Composer where the synchronous loop is the point.

---

## 4.4 Limitations — What Background Agents Cannot Do

<Callout type="warn">
Background Agents are not a replacement for headless CLI tools in CI pipelines. Review these constraints before routing a task to a Background Agent.
</Callout>

**1. IDE dependency for in-IDE agents.** In-IDE Background Agents require the Cursor application to be running. They are an IDE productivity feature, not a scheduling system. [1]

**2. Platform lock-in for Cloud agents.** Cloud Background Agents run on Cursor's AWS infrastructure and are triggered through Cursor's native interfaces (GitHub `@cursor`, Slack). You cannot invoke them from a GitHub Actions step, a cron job, or any other external pipeline orchestrator. [4]

**3. Credit and compute cost.** Both modes consume Cursor's compute credits. Long-running agents on complex tasks accumulate significant spend. The Cursor dashboard shows agent run history and credit consumption — check it when running frequent background tasks against large codebases. [4]

**4. Internet required.** Background Agents and Cloud Agents communicate with Anysphere's cloud infrastructure. Corporate proxies and firewalls may require whitelisting of Cursor's backend domains — check `cursor.com/security` for the current allowlist. [8]

**5. No general unattended scheduling.** You cannot schedule a Background Agent to run at 2am without someone creating the trigger (a GitHub issue, a Slack message, or an open Agents Window session). For time-triggered automation, the routing from [[cursor-composer-2/03-cursor-cli-headless|Chapter 3]] still applies: use Codex CLI or Claude Code.

---

## 4.5 Connecting to the Chapter 3 Routing Rubric

[[cursor-composer-2/03-cursor-cli-headless|Chapter 3]] established a three-question routing rubric: Is there a human at a keyboard? Does the task need MCP/external services? Headless or interactive?

Background Agents slot into that rubric as an **extension of the IDE path**, not a replacement for the CLI path:

```
Task: "Is there a human present with a GUI (or Cursor open)?"
├── YES
│   ├── Task is short + synchronous → Composer Agent Mode
│   ├── Task is long + mechanical + OK to review later
│   │   → Background Agent (Agents Window)
│   └── Task needs external services (MCP) → Claude Code
└── NO (headless / CI / scheduled)
    ├── Trigger available via GitHub issue + @cursor?
    │   → Cloud Background Agent (platform-bound; not a generic CI substitute)
    └── General headless automation → Codex CLI or Claude Code (Ch3)
```

The updated rule: **Background Agents extend the IDE path for long or parallel async tasks. They do not replace headless CLI tools for CI pipelines and scheduled automation.**

---

## KnowledgeCheck 2: Routing with Background Agents

**Question 1 (MCQ):** Which of the following tasks is the best fit for a Cursor Cloud Background Agent?

- A) A GitHub Actions job that auto-generates a changelog from commit messages on every merge to main
- B) A well-described GitHub issue: "Login button returns 500 when email contains a + character" tagged with `@cursor`
- C) An SSH session on a remote GPU server running a Python training-script refactor
- D) A nightly cron job that checks for TypeScript files over 400 lines

*Correct answer: B — a scoped, well-described GitHub issue is exactly the trigger and task type Cloud Background Agents are designed for. A (GitHub Actions) requires a headless CLI tool — Cursor cannot be invoked by a CI runner. C (SSH/remote server) has no Cursor application context. D (cron job) has no Cursor trigger mechanism.*

**Question 2 (MCQ):** A developer runs a Background Agent in the Agents Window to refactor a large module. Midway through their own work session, their laptop battery dies and Cursor closes. What happens to the in-IDE Background Agent?

- A) The agent continues running in Cursor's cloud infrastructure automatically
- B) The agent saves its progress locally and resumes when Cursor restarts
- C) The agent stops — in-IDE Background Agents are bound to the running Cursor process
- D) The agent completes its task and commits the result to the branch automatically

*Correct answer: C — in-IDE Background Agents run within the Cursor application process. When Cursor closes, they stop. For tasks that must survive a closed laptop, use Cloud Background Agents (triggered via GitHub `@cursor` or Slack), which run on Cursor's remote infrastructure independently of your machine.*

---

## 4.6 Hands-On Exercise: Your First In-IDE Background Agent Run

**Objective:** Run an in-IDE Background Agent for a test-generation task on your own project. Verify task isolation, completion, and the diff review flow.

**Time-box:** 35 minutes.

**Prerequisites:** Cursor Pro subscription; a project with at least 5 source files lacking test coverage.

**Steps:**

1. **Open the Agents Window** — use the sidebar icon or `Cmd/Ctrl+Shift+A`. If you do not see it, update to Cursor 3 or above (released April 2, 2026).

2. **Create `.cursor/worktrees.json`** in your project root if it does not exist:

   ```json
   {
     "setup-worktree": [
       "npm install"
     ]
   }
   ```

   Adjust the setup command for your package manager (`pnpm install`, `yarn`, etc.).

3. **Start a new agent in the Agents Window** using a scoped, concrete prompt:

   ```
   Find all .ts files under /src that do not have a corresponding .test.ts 
   file in the same directory. For each one, generate a Vitest test file 
   with at least 3 test cases: the happy path, an edge case, and an error 
   case. Follow the test conventions in .cursorrules. Stop after 10 files.
   ```

4. **Return to your main editor and work on something else** for 5–10 minutes. This is the core of the exercise — confirm you can work while the agent runs without managing a synchronous loop.

5. **Check the Agents Window status.** When the agent signals completion, open the diff viewer. Review:
   - Are the generated test files in the correct directories?
   - Do the test names follow your project's `.cursorrules` conventions?
   - Do the files compile? Run `tsc --noEmit` to verify.

6. **Accept or reject the diff.** The agent's work lives on an isolated branch in a worktree — your main branch is untouched until you explicitly merge. Accept the tests you are happy with; reject or edit any that need correction.

**Success criteria:**
- Agent completed without requiring you to manage a turn-by-turn Composer conversation
- Generated test files follow `.cursorrules` conventions
- No TypeScript compilation errors
- You merged the accepted tests into your working branch

---

## 4.7 Quick Takeaways

```
:::quick-takeaways
- Background Agents come in two modes: in-IDE (Agents Window, requires Cursor open) and Cloud (AWS Ubuntu VM, can run with laptop closed).
- Cloud Background Agents are triggered by GitHub @cursor tags or Slack messages — not by CI runners or cron jobs.
- Configure the Cloud agent environment in .cursor/environment.json; configure in-IDE worktree isolation in .cursor/worktrees.json.
- Best use cases: test generation at scale, large-scope refactoring, GitHub issue → PR, browser-verified bug fixes.
- They are NOT a CI pipeline replacement — platform-bound, no generic CLI trigger, no unattended scheduling without a Cursor-native trigger.
- Updated routing rule: Background Agents extend the IDE path for async tasks; Codex CLI and Claude Code own the CI and scheduled automation path.
- Subscription: Cursor Pro or above required. Monitor credit consumption in the Cursor dashboard.
:::
```

---

## What's Next

This chapter completed the Background Agents picture — where they fit in the IDE, where they hand off to the cloud, and where their boundaries end. You now have the full routing framework: Composer for synchronous pair programming, Background Agents for async IDE tasks, and Codex CLI or Claude Code for headless pipelines.

**[[cursor-composer-2/05-multitask-parallel-agents|Chapter 5]]** builds on the parallel execution introduced here, covering Cursor 3.2's `/multitask` command and the patterns for coordinating multi-agent runs across worktrees at scale. If running two agents in parallel is useful, `/multitask` makes running ten systematic.

---

## References

1. Digital Applied. "Cursor 3: Agents Window, Cloud Agents, and What Changed." digitalapplied.com/blog/cursor-3-agents-window-complete-guide. Retrieved 2026-06-11.
2. Cursor Changelog. "3.2 Multitask, Worktrees, and Multi-root Workspaces." cursor.com/changelog/04-24-26. Retrieved 2026-06-11.
3. Cursor Blog. "Run cloud agents in your own infrastructure." cursor.com/blog/self-hosted-cloud-agents. Retrieved 2026-06-11.
4. Neura Market. "Cursor 3 Review: Background Agents and the Agent-First IDE." neura.market/directories/cursor/blog/devto-3487552. Retrieved 2026-06-11.
5. Steve Kinney. "Using Cursor Background Agents for Asynchronous Coding." stevekinney.com/courses/ai-development/cursor-background-agents. Retrieved 2026-06-11.
6. Cursor Documentation. "Worktrees." cursor.com/docs/configuration/worktrees. Retrieved 2026-06-11.
7. DeployHQ. "Cursor 2026: Composer, Agent Mode, MCP & Background Agent." deployhq.com/guides/cursor. Retrieved 2026-06-11.
8. Cursor Security. "Security." cursor.com/security. Retrieved 2026-06-11.
