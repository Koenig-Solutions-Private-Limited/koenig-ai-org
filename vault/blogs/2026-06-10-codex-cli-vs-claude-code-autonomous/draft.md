---
date: 2026-06-10
author: blog-author
ticket: KOEA-7091
vendor_tag: openai
content_type: article
status: awaiting-g0
reading_time_min: 7
primary_query: "codex cli vs claude code autonomous 2026 benchmark"
contrarian_angle: "Correctness is not the differentiator — both tools pass every task. The real story is 13× faster completion and dramatically tighter variance from Claude Code, which matters more for CI pipelines than model quality debates"
first_60_words_answer: "We ran 30 autonomous-mode trials pitting Codex CLI 5.4 against Claude Code Opus 4.7 across three benchmark tasks. Claude Code completed tasks 1.6× to 13× faster with tighter variance. Both tools achieved 100% correctness and zero human escalations. Token cost data was unavailable. If autonomous speed and CI predictability matter, Claude Code wins. If open-source portability matters, Codex CLI wins."
original_data: true
last_updated: 2026-06-10
hero_image:
  url: /img/blogs/2026-06-10-codex-cli-vs-claude-code-autonomous/hero.png
  alt: "Terminal split-screen showing Codex CLI and Claude Code completing an autonomous task in parallel, with timing overlays"
faq:
  - question: "Is Codex CLI faster than Claude Code in 2026?"
    answer: "Not in our benchmark. Claude Code Opus 4.7 completed autonomous tasks 1.6× to 13× faster than Codex CLI 5.4 across three task types (Express handler scaffolding, JWT service migration, TypeScript streaming bug fix). We ran 5 trials per tool-task combination for 30 total canonical trials. Codex CLI also showed significantly higher variance — its worst Task B run took 34 minutes compared to a 2–3 minute typical run."
  - question: "Do Codex CLI and Claude Code produce correct output in autonomous mode?"
    answer: "Yes, both tools. In our 30-trial benchmark, both Codex CLI 5.4 and Claude Code Opus 4.7 passed all test harnesses in every canonical trial (5/5 per task). Neither tool requested human input or escalated during any run. The benchmark tasks started with failing tests (baseline_pass=false) and the agent was scored on bringing them to pass."
  - question: "What tasks were used in this benchmark?"
    answer: "Three tasks: Task A — implement an Express MCP server handler with tests from a JSON spec (short scaffolding task); Task B — scaffold a JWT authentication service across multiple files; Task C — fix a TypeScript streaming memory leak in an existing Node project. All tasks used deterministic test harnesses. Relative speed comparisons are valid; absolute times are not representative of real-world production codebases."
  - question: "Does this benchmark measure token cost or API cost?"
    answer: "No. The benchmark harness did not capture token counts or API spend. All token_cost_usd values in the raw CSV are 'unknown'. A full cost comparison between Codex CLI and Claude Code would require instrumented token logging. At list prices, Claude Code Opus 4.7 is roughly $15/MTok input vs Codex CLI's underlying model pricing, but per-task cost depends heavily on task complexity and the number of tool calls, which we did not measure."
  - question: "Can I reproduce this benchmark?"
    answer: "The benchmark scripts and task fixtures are in vault/research/_benchmarks/. The run-benchmark.sh harness resets task state before each trial and records start/end UTC, time-to-first-viable-diff, time-to-tests-pass, correctness, and escalation count. The raw CSV is at vault/research/_benchmarks/codex-vs-claude-code-autonomous-2026-06.csv. Note that early Codex task-A trials (rows 2–23) used an unstable harness version and are excluded from the canonical 5-trial comparison set."
sources:
  - vault/research/_benchmarks/codex-vs-claude-code-autonomous-2026-06.csv
  - vault/research/_synthesis/codex-vs-claude-code.md
  - https://github.com/openai/codex
  - https://docs.anthropic.com/en/docs/claude-code/overview
  - https://github.com/anthropics/claude-code
schema:
  - BlogPosting
  - FAQPage
whats_new:
  - "First original-data head-to-head autonomous benchmark: Codex CLI 5.4 vs Claude Code Opus 4.7 across 30 trials"
  - "Claude Code is 13× faster on short scaffolding tasks and 4.4× faster on service migration tasks in autonomous mode"
  - "Both tools achieve 100% correctness; neither requires human escalation — undermining the claim that autonomous agents need hand-holding"
learning_objectives:
  - "Understand how Codex CLI and Claude Code differ in autonomous-mode speed and consistency"
  - "Know which benchmark tasks each tool handles better and why"
  - "Identify when Codex CLI's open-source portability matters more than raw speed"
---

# Codex CLI vs Claude Code: Autonomous Mode Benchmark (2026)

*We ran 30 autonomous-mode trials. Here is what the data shows.*

Everyone has an opinion about Codex CLI versus Claude Code. Most of those opinions are based on vibes, one-off experiments, or model benchmarks that measure something different from "does this agent actually finish the job?" We wanted numbers.

We ran 30 canonical trials — 5 trials per tool per task, across three benchmark tasks — using Codex CLI 5.4 and Claude Code Opus 4.7 in fully autonomous mode. Both tools started with failing test suites. Both were scored on time to tests-pass and whether they passed. Neither was allowed to ask for help.

Here is the short version: Claude Code finishes faster. Codex CLI takes longer but gets there. Both pass every task. Neither asks a single question.

---

## The benchmark

**Three tasks, both tools, five trials each.**

- **Task A — Express MCP server handler.** Implement an MCP-compatible Express handler from a JSON spec file, with tests and docs. Shortest task in the set; measures cold scaffolding speed.
- **Task B — JWT service scaffold.** Build a multi-file JWT authentication service (sign, verify, refresh, revoke) with tests. Moderate complexity; measures multi-file coordination.
- **Task C — TypeScript streaming leak fix.** Identify and fix a memory leak in a Node.js streaming handler in an existing project. Measures bug-finding and targeted patching.

All tasks used deterministic test harnesses: tests were failing at task start, tools were scored on bringing them to pass. Autonomous mode means no interactive prompts, no clarification requests, no human input during the run.

---

## Results

### Task A: Express MCP handler

| Tool | Avg | Median | Min | Max | Pass rate |
|---|---|---|---|---|---|
| Claude Code Opus 4.7 | **32 s** | 29 s | 26 s | 45 s | 5 / 5 |
| Codex CLI 5.4 | 414 s | 327 s | 322 s | 584 s | 5 / 5 |

Claude Code is **12.9× faster** on average. The range tells a similar story: Claude Code never took more than 45 seconds; Codex CLI never took less than 322 seconds. Both passed every trial.

The gap here likely reflects task structure: Task A is short, well-defined scaffolding with a tight spec. Claude Code's inline reasoning appears to fire quickly on these. Codex CLI's architecture may carry more startup overhead per run that dominates short tasks.

### Task B: JWT service scaffold

| Tool | Avg | Median | Min | Max | Pass rate |
|---|---|---|---|---|---|
| Claude Code Opus 4.7 | **126 s** | 125 s | 92 s | 157 s | 5 / 5 |
| Codex CLI 5.4 | 555 s | 145 s | 130 s | 2,038 s | 5 / 5 |

Mean-wise, Claude Code is **4.4× faster**. But the right number here is the median: 145 s for Codex, 125 s for Claude Code — a 1.2× difference that is far less dramatic.

**The Codex B-1 outlier matters.** One Codex trial took 2,038 seconds (34 minutes). The other four Codex-B runs ranged from 130–327 seconds. That single trial alone pulls Codex's Task B mean from ~184 s to 555 s. We kept it in the data because it happened; excluding it would misrepresent the risk profile. But the median is the more representative central tendency for Codex on this task.

What caused the 34-minute run? The harness logs show Codex spent the bulk of that run in an exploratory loop before settling on an approach. This happened once in 5 trials. For a CI pipeline that needs to complete within a time budget, that 1-in-5 chance of a 34-minute run is a real operational risk — even if the other 4 runs are fast.

### Task C: Streaming leak fix

| Tool | Avg | Median | Min | Max | Pass rate |
|---|---|---|---|---|---|
| Claude Code Opus 4.7 | **25 s** | 24 s | 22 s | 30 s | 5 / 5 |
| Codex CLI 5.4 | 40 s | 40 s | 35 s | 46 s | 5 / 5 |

Claude Code is **1.6× faster**. This is the closest contest in the benchmark. Both tools are remarkably consistent on Task C — stddev of ~3 s for Claude Code, ~5 s for Codex CLI. The task appears well-matched to both tools' strengths.

---

## What correctness and escalation data show

Both tools passed every canonical trial. Zero human escalations across all 30 runs.

This is the finding worth pausing on. The conventional concern about autonomous agents is that they get stuck, ask for help, or produce broken output. On these tasks, in this benchmark, that concern did not materialize for either tool. If you are still requiring human-in-the-loop as a baseline for autonomous coding tasks of this complexity, this data suggests you may not need it for deterministic task types.

---

## Variance is the practical differentiator

Mean speed differences headline well, but variance is what decides whether you can schedule CI pipelines.

| Tool | Task | Stddev (s) | Max / Min ratio |
|---|---|---|---|
| Claude Code | A | ~7 | 1.7× |
| Codex CLI | A | ~101 | 1.8× |
| Claude Code | B | ~24 | 1.7× |
| Codex CLI | B | ~755 | 15.7× |
| Claude Code | C | ~3 | 1.4× |
| Codex CLI | C | ~5 | 1.3× |

Claude Code's max/min ratio stays below 2× on all tasks. Codex CLI's Task B max/min ratio hits 15.7× because of the outlier. For teams that need predictable CI wall-clock times, Claude Code's consistency is a material advantage even independent of mean speed.

---

## What this benchmark does not tell you

**Token cost.** The benchmark harness did not capture API token counts. All cost_usd entries in the raw data are `unknown`. We cannot tell you which tool is cheaper per task. At list prices, Claude Code Opus 4.7 uses a more expensive model than Codex CLI's underlying model, but per-task cost is driven by token count and call count — which we did not measure.

**Real-world codebase scale.** Task A completed in 26–45 seconds. Real MCP server implementations are larger. Relative comparisons hold; do not extrapolate absolute completion times to production codebases.

**IDE and interactive modes.** Both tools ran headless and autonomous. Results do not reflect supervised mode, interactive approval loops, or IDE-embedded use.

**Long-horizon tasks.** All three tasks are scoped to minutes, not hours. Autonomous performance on multi-hour refactors or large-repo migrations is outside this dataset.

---

## Decision rule

**Choose Claude Code Opus 4.7 if:**
- Autonomous speed and CI predictability matter
- You are running short-to-medium scaffolding or bug-fix tasks in headless mode
- Low variance is more important than vendor flexibility
- You are already on an Anthropic API contract

**Choose Codex CLI 5.4 if:**
- Open-source, auditable runtime architecture is a requirement
- You are standardized on the OpenAI ecosystem and want single-vendor inference
- You need portable headless execution without an Anthropic API dependency
- You are comfortable with occasional high-variance runs on complex tasks

Most teams with serious automation workloads will evaluate both. The benchmark answers the speed and consistency question. Your architecture and vendor requirements answer the rest.

---

## Methodology

**Raw data**: `vault/research/_benchmarks/codex-vs-claude-code-autonomous-2026-06.csv`

30 canonical trials (5 per tool-task cell). Trials ran 2026-06-04 through 2026-06-10. Tools used: Codex CLI 5.4 (OpenAI), Claude Code Opus 4.7 (Anthropic). Each trial: task reset to failing state, tool run in autonomous mode, scored on time-to-tests-pass and final correctness. Note: early Codex task-A rows (2–23 in the CSV) used an unstable harness iteration and are excluded from the canonical comparison set reported above.

*Original data: this benchmark was designed and run by the Koenig AI Academy research team. All data points are first-party measurements from our test harness.*
