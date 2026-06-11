---
course_slug: cursor-composer-2
chapter_num: 5
title: "/multitask and Parallel Agents: Running a Fleet"
description: "Master Cursor 3.2's /multitask command to spawn async subagent fleets — covering the parent-child coordination model, task decomposition patterns, workflow_state.md tracking, worktree housekeeping, and the budget signals that tell you when to stop."
chapter_primary_query: "How do I use Cursor's /multitask command to run parallel agents, and what kinds of tasks benefit from multi-agent parallelisation?"
first_60_words_answer: "/multitask tells Cursor to break your request into independent chunks and hand each chunk to an async subagent running in its own worktree branch — instead of queuing tasks one after another. The result is a fleet of background workers tackling separate parts of a large project simultaneously, each reporting back to the parent agent that assembled the final work plan."
learning_objectives:
  - "Invoke /multitask correctly and describe what the Agents Window does when it receives the command"
  - "Apply the parent-child agent model to decompose a real task into parallelisable subagent chunks"
  - "Distinguish task types that benefit from parallelisation from those with ordering or shared-state conflicts"
  - "Use the Cursor credit dashboard to monitor and abort a multi-agent run that is over-consuming"
faq:
  - question: "What does /multitask do, and when was it introduced?"
    answer: "/multitask is a Cursor Composer command introduced in Cursor 3.2 (April 24, 2026). When invoked, Cursor spawns async subagents to parallelise your request instead of adding tasks to a queue — each subagent runs in an isolated git worktree branch and handles one independent chunk of the overall work (source: cursor.com/changelog/04-24-26, retrieved 2026-06-11)."
  - question: "How does /multitask differ from manually launching two Background Agents side by side?"
    answer: "/multitask automates the coordination: the parent agent decomposes work into chunks, creates the subagents, names the branches, and monitors progress via workflow_state.md. Manual parallel agents (Chapter 4's Agents Window) require you to define each task, name each branch, and track progress yourself. /multitask is the systematic, scalable version of the same pattern (source: digitalapplied.com/blog/cursor-3-agents-window-complete-guide, retrieved 2026-06-11)."
  - question: "How does Cursor prevent parallel subagents from overwriting each other's files?"
    answer: "Each subagent runs in its own git worktree — a separate working directory backed by the same repository object store but on a distinct branch. Changes written by subagent A are invisible to subagent B until you explicitly merge them. Cursor defaults to a maximum of 25 worktrees per machine and runs automatic cleanup every 6 hours (source: cursor.com/docs/configuration/worktrees, retrieved 2026-06-11)."
  - question: "How much does a /multitask run cost?"
    answer: "Credit costs scale roughly linearly with the number of subagents. Community data from Cursor's Background Agents preview puts a typical PR-scoped task at around $4–6 in usage-based credits (source: stevekinney.com/courses/ai-development/cursor-background-agents, retrieved 2026-06-11). These figures are indicative — check cursor.com/pricing and your credit dashboard before planning large fleets, as pricing is actively evolving."
sources:
  - https://cursor.com/changelog/04-24-26
  - https://stevekinney.com/courses/ai-development/cursor-background-agents
  - https://www.digitalapplied.com/blog/cursor-3-agents-window-complete-guide
  - https://cursor.com/docs/configuration/worktrees
  - https://cursor.com/changelog/04-02-26
  - https://www.deployhq.com/guides/cursor
tags:
  - cursor
  - multitask
  - parallel-agents
  - background-agents
  - worktrees
  - agents-window
  - cursor-composer-2
duration_min: 45
read_time_min: 10
last_updated: 2026-06-11
status: g0-passed
author: content-author
ticket: KOEA-7796
whats_new: "Chapter introduces /multitask (Cursor 3.2) and the parent-child async subagent model, covering task decomposition patterns, workflow_state.md coordination, worktree housekeeping at scale, credit budget awareness, and the conditions under which /multitask should not be used."
prerequisites_chapters: [1, 2, 3, 4]
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: defends
---

# /multitask and Parallel Agents: Running a Fleet

`/multitask` tells Cursor to break your request into independent chunks and hand each chunk to an async subagent running in its own worktree branch — instead of queuing tasks one after another. The result is a fleet of background workers tackling separate parts of a large project simultaneously, each reporting back to the parent agent that assembled the final work plan.

Introduced in Cursor 3.2 (April 24, 2026) [1], `/multitask` is the systematic version of the parallel-agent pattern you first encountered in [[cursor-composer-2/04-background-agents]]'s Agents Window — a hub for running many agents in parallel across local, worktree, cloud, and remote SSH environments (Cursor 3.0, April 2, 2026 [5]) — except now the coordination happens automatically. You describe the work at a high level; the parent agent handles decomposition, branch naming, and progress tracking.

---

## 5.1 How /multitask Works

Type `/multitask` followed by a high-level description into Cursor Composer. The Agents Window responds immediately: instead of adding your request to the active agent's queue, Cursor spawns a set of async subagents and assigns each a slice of the work. [1]

Each subagent:

1. Receives its isolated task description from the parent agent
2. Runs in its own git worktree on a separate branch — no shared working directory
3. Executes independently and writes changes without awareness of other subagents
4. Signals completion back to the Agents Window status pane when done

If messages are already queued when you type `/multitask`, Cursor breaks the queue into parallel subagents and starts them simultaneously rather than processing them one by one. [1] The parent assembles a diff set — one branch diff per subagent — for your review when all subagents complete.

---

## 5.2 The Parent-Child Agent Model

Every `/multitask` run has a two-level structure:

- **Parent agent** — reads your prompt, decomposes it into N independent chunks, creates one subagent per chunk, monitors progress via `workflow_state.md`
- **Subagents** — each owns exactly one chunk, executes in its own worktree branch, writes results without cross-subagent awareness

The parent never merges output directly — that is your job. When all subagents signal done, you review each branch diff in the Agents Window and decide which to accept, discard, or merge. Cursor supports running multiple background agents in parallel on independent tasks simultaneously, which is what makes this two-level structure practical at scale. [2][6]

This builds directly on the Background Agents architecture from Chapter 4: each subagent is isolated in a worktree exactly as a manually-launched Background Agent is. The `/multitask` innovation is the automated parent layer that eliminates manual task-splitting and branch-setup overhead.

---

## 5.3 Task Decomposition: What Parallelises Well

The quality of a `/multitask` run depends on how cleanly the work divides. The test is simple: if you can describe each chunk as "do X in files {A}" without referencing any other chunk, it parallelises well. If chunk 2's description begins with "after chunk 1 finishes", it does not. [3]

**Good candidates:**
- Adding tests to independent service modules (auth, billing, notifications — each assigned to its own subagent)
- Generating documentation or type annotations for separate packages
- Linting or formatting passes across disjoint directories
- Independent bug fixes on non-overlapping feature branches

**Do not parallelise:**
- Tasks with sequential dependencies (run migration → then update models)
- Tasks where both subagents must modify the same config file (`package.json`, `pyproject.toml`)
- Rename or move operations affecting a shared import graph
- Any task requiring real-time review at each step — use Composer's synchronous loop instead

<KnowledgeCheck
  question="Which of these tasks is the best candidate for /multitask?"
  options={[
    "Rename a shared utility function used across 40 files",
    "Add unit tests to three independent service modules",
    "Run a database migration then update ORM models",
    "Refactor a shared config object used by every service"
  ]}
  correct={1}
  explanation="Independent service modules with no shared state are the ideal /multitask target — each subagent works on its module without affecting others. Renaming a shared function touches an overlapping import graph. Migrations require sequential ordering. A shared config object causes write conflicts across subagents."
/>

---

## 5.4 workflow_state.md Coordination

When a `/multitask` run is active, the parent agent writes a `workflow_state.md` file that acts as the coordination contract between parent and subagents. It typically tracks: [2]

- A task checklist with current status for each subagent (`pending` | `in-progress` | `done` | `blocked`)
- The branch name each subagent is working on
- Any blocking notes or dependencies surfaced mid-run

You can open `workflow_state.md` at any point to monitor the fleet without leaving the editor. It updates in near-real time as subagents complete their chunks. Note that parallel agents remain IDE-bound — this is distinct from the headless pipeline path in [[cursor-composer-2/03-cursor-cli-headless]]. `workflow_state.md` is an in-IDE coordination artifact, not a CI signal file. For persisting task context across sessions, pair it with the `AGENTS.md` conventions from [[cursor-composer-2/02-project-discipline-layer]].

<Callout type="info">
`workflow_state.md` is authored by the parent agent, not written by Cursor's runtime. If you abort a /multitask run mid-flight, the file may be left in a partial state. Delete or reset it before retrying the run.
</Callout>

---

## 5.5 Worktree Housekeeping at Scale

Running five to ten parallel subagents creates five to ten worktree directories and branches. Without naming discipline, your repo accumulates orphaned branches like `cursor-task-1`, `cursor-task-1a`, and `cursor-task-1-retry`.

Recommended naming convention:
- Prefix all subagent branches with `mt/` — e.g., `mt/add-tests-auth`, `mt/add-tests-billing`
- After merging or discarding a result, remove its worktree: `git worktree remove .cursor/worktrees/<branch>`
- After any `/multitask` session, run `git worktree list` to identify and prune stale entries

Cursor automates some of this. The machine-level setting `cursor.worktreeCleanupIntervalHours` (default: 6 hours) removes idle worktrees automatically, and `cursor.worktreeMaxCount` (default: 25) caps total worktrees per machine. [4] Cursor 3.2 also added one-click branch promotion — you can move any subagent branch into your local foreground from the Agents Window for a final review pass. [1]

---

## 5.6 Budget and Credit Awareness

Running N subagents in parallel costs roughly N× the credit consumption of a single agent run. Community data from the Background Agents preview puts a typical PR-scoped task in the $4–6 range of usage-based credits, based on Steve Kinney's course notes. [2] Scale linearly: a ten-subagent refactor session can cost $40–60 before you see a single diff.

Practical guardrails before launching a large fleet:
- Pilot with 2–3 subagents on a small representative task to establish a per-subagent cost baseline
- Check Settings → Credits before and after the pilot run
- If any subagent is stuck on `in-progress` for more than ten minutes, abort the run — stalled agents still consume credits

<Callout type="warn">
Do not treat the $4–6 figure as a fixed rate. Cursor's usage-based pricing is in active revision. Always check cursor.com/pricing and the live credit dashboard before budgeting a large fleet run.
</Callout>

---

## 5.7 When NOT to /multitask

`/multitask` is powerful enough to cause significant problems when misapplied:

1. **Ordered dependencies** — if step 2 requires step 1's output, parallelisation creates a race condition. Use Composer's synchronous loop.
2. **Shared mutable files** — two subagents editing `package.json` or any shared configuration produce conflicts the parent cannot auto-resolve.
3. **Real-time review gates** — if you need to approve each diff before the next step, `/multitask` removes that gate. Use Composer or sequential Background Agents.
4. **Unfamiliar codebases** — async fleet work makes it hard to catch mistakes in real time. Build your mental model with single Composer sessions first.
5. **Tight credit headroom** — a stall mid-run drains credits quickly. If near a monthly limit, run agents sequentially. [1]

<KnowledgeCheck
  question="Which condition makes /multitask unsafe for a documentation update across eight modules?"
  options={[
    "Both subagents need to write to the same shared schema file",
    "The task covers more than three separate modules total",
    "The developer has not tried Background Agents in this project",
    "Cursor is running on a laptop with limited available RAM"
  ]}
  correct={0}
  explanation="A shared schema file creates a write conflict — two subagents appending to the same file produce a merge collision the parent cannot auto-resolve. Module count, prior experience with Background Agents, and RAM availability do not affect /multitask safety; worktree isolation handles independent modules regardless of count."
/>

---

## Hands-on: Your First /multitask Run

<RunPromptCell
  title="Parallel docstring generation"
  timeBoxMin={15}
  successCriteria="The Agents Window shows at least two subagents running on separate branches, and workflow_state.md appears in the repo root with at least two task entries marked in-progress or done."
  prompt={`/multitask
Subagent 1: Add Google-style docstrings to every public function in src/auth/ — modify only files inside that directory.
Subagent 2: Add Google-style docstrings to every public function in src/billing/ — modify only files inside that directory.
Subagent 3: Add Google-style docstrings to every public function in src/notifications/ — modify only files inside that directory.`}
  expectedOutput="Three background agents appear in the Agents Window, each on an mt/-prefixed branch. workflow_state.md shows three tasks progressing independently. When all complete, review each branch diff and merge the ones you accept."
/>

---

## 5.8 What's Next

You now have the core multi-agent toolkit: Background Agents for async task delegation ([[cursor-composer-2/04-background-agents]]) and `/multitask` for automatic fleet coordination. For work that must step outside the IDE entirely — unattended pipelines, CI runners, remote scripts — Chapter 3's CLI path ([[cursor-composer-2/03-cursor-cli-headless]]) remains the right route; parallel agents are IDE-bound and require Cursor to be running.

The next chapter extends this toolkit to the review side: once a fleet of subagents has produced a set of diffs, you need a systematic approach to evaluate, integrate, and gate those changes through your CI pipeline without introducing regressions.

---

## Sources

[1] Cursor 3.2 Changelog, April 24, 2026 — https://cursor.com/changelog/04-24-26

[2] Steve Kinney, "Cursor Background Agents" — https://stevekinney.com/courses/ai-development/cursor-background-agents

[3] Digital Applied, "Cursor 3 Agents Window: Complete Guide" — https://www.digitalapplied.com/blog/cursor-3-agents-window-complete-guide

[4] Cursor Docs, "Worktrees Configuration" — https://cursor.com/docs/configuration/worktrees

[5] Cursor 3.0 Changelog, April 2, 2026 — https://cursor.com/changelog/04-02-26

[6] DeployHQ, "Cursor 2026: Composer, Agent Mode, MCP & Background Agent" — https://www.deployhq.com/guides/cursor

