---
chapter_num: 10
course_slug: claude-tool-use-from-zero
title: "Claude Code Dynamic Workflows: Fan-Out, Checkpoint, and Verify (2026)"
status: draft-for-review
author: course-author
ticket: KOEA-6934
learning_objectives:
  - "Explain how Claude Code dynamic workflows differ from static single-prompt tool chains"
  - "Design a fan-out pattern that distributes work across parallel sub-agents"
  - "Implement checkpoint-based progress tracking that survives partial failures"
  - "Verify sub-agent results programmatically before incorporating them into a final response"
  - "Identify the five conditions under which dynamic workflows cost more than they save"
prerequisites_chapters:
  - 1
  - 2
  - 3
  - 5
  - 6
duration_min: 65
level: Builder
vendor_tag: anthropic
sources:
  - https://www.reddit.com/r/ClaudeAI/comments/1tq9ofy/introducing_dynamic_workflows_in_claude_code/
  - https://www.reddit.com/r/ClaudeAI/comments/1tq9vqf/claude_code_credits_rebooted_after_coding_for/
  - https://docs.anthropic.com/en/docs/claude-code/sdk
  - https://docs.anthropic.com/en/docs/claude-code/settings
  - https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan
  - https://docs.anthropic.com/en/docs/about-claude/models/overview
tags:
  - course/claude-tool-use-from-zero
  - claude-code
  - dynamic-workflows
  - multi-agent
  - fan-out
  - orchestration
positions:
  - stance_id: cli-first-workflows-for-production-teams
    mode: defends
chapter_primary_query: "claude code dynamic workflows fan-out multi-agent orchestration"
first_60_words_answer: "Claude Code dynamic workflows let a single orchestrator Claude instance write and execute orchestration scripts that fan work out to tens or hundreds of parallel sub-agents, checkpoint progress between stages, and verify results before handing anything back. This replaces sequential single-prompt chains with genuine parallelism and adds structured recovery points that survive partial failures."
faq:
  - question: "What is a dynamic workflow in Claude Code?"
    answer: "A dynamic workflow is an orchestration pattern where Claude Code writes a script that spins up multiple sub-agent instances, assigns work to them in parallel, checkpoints results at defined stages, and verifies outputs before incorporating them — as opposed to sending a single prompt and waiting for one reply."
  - question: "How many sub-agents can Claude Code fan out to?"
    answer: "The community reports practical fan-outs of tens to hundreds of sub-agents depending on quota tier. Claude Max users have higher weekly limits than Pro; the practical ceiling is token budget and weekly usage limit, not a hard API cap."
  - question: "When should I NOT use Claude Code dynamic workflows?"
    answer: "Avoid dynamic workflows for single-task jobs that fit in one prompt, latency-sensitive operations where orchestration startup time matters, operations that need human approval at an undetermined mid-flight point, jobs where sequential dependency chains prevent meaningful parallelism, and scripts where token spend is not justified by the time savings."
inline_assets:
  - type: diagram
    path: ./img/ch10-dynamic-workflow-architecture.svg
    alt: "Architecture diagram showing orchestrator Claude spawning three parallel sub-agents (analysis, transformation, verification), each writing results to a shared checkpoint store before the orchestrator reads and verifies"
last_updated: 2026-05-31
---

# Claude Code Dynamic Workflows: Fan-Out, Checkpoint, and Verify (2026)

Claude Code dynamic workflows turn a single orchestrator instance into a parallel execution engine: Claude writes and runs an orchestration script that fans work out to tens or hundreds of sub-agents, checkpoints progress between stages, and verifies sub-agent results before handing anything back. This is not a cosmetic upgrade to the prompt interface — it is a different execution model that changes how you think about cost, correctness, and control.

This chapter teaches you to design fan-out patterns, implement durable checkpoints, and build result-verification logic that earns trust. It also teaches you when the overhead is not worth it.

## Prerequisites check

Before continuing, confirm that you:

1. Can run a basic Claude tool-use script from Chapter 1 without errors.
2. Understand the MCP protocol from Chapters 2 and 3 — sub-agents often expose tools via MCP.
3. Have working structured logging from Chapter 5, because orchestrator-level debugging without logs is impractical.
4. Understand authorization gates from Chapter 6 — parallel agents amplify every authorization weakness.

If the Chapter 5 logging setup is not in place, you will not be able to tell which sub-agent produced a bad result. Fix that first.

## Static chains vs. dynamic workflows

The tool-use pattern you learned in Chapters 1 through 9 is a **static chain**: one Claude instance, one conversation thread, tools called one at a time, results incorporated sequentially.

```
User prompt → Claude decides → Tool A → Claude decides → Tool B → Final answer
```

A static chain is correct for most tasks. Claude reads the last tool result before calling the next tool, so it can adapt. The price is latency: each tool call is a synchronous round trip through the model, and you can only run one at a time.

```takeaways
- A static chain is sequential and adaptive but limited to one tool call at a time, making it slow for large-batch workloads.
- Dynamic workflows replace the sequential conversation loop with an orchestration script that spawns multiple sub-agents in parallel.
- Wall-clock time compresses with dynamic workflows, but token spend multiplies — each sub-agent is a full Claude invocation.
```

**Dynamic workflows** break that constraint. The orchestrator Claude instance does not call tools sequentially from inside a conversation loop. Instead, it writes an **orchestration script** — executable code that the host environment runs — and that script spawns multiple [[sub-agent]] instances in parallel.[^1]

```
Orchestrator → generates script
Script → spawns Agent A, Agent B, Agent C in parallel
Agents A, B, C run concurrently → write results to checkpoint store
Script → reads checkpoint store → verifies results → assembles final output
```

The practical effect: a codebase analysis that would take 20 sequential tool calls can instead fan out to 20 sub-agents reading 20 files simultaneously. Wall-clock time compresses, but token spend multiplies.

## The orchestrator model

The orchestrator is a Claude Code instance configured to produce and run multi-agent scripts rather than to answer a single user query. Anthropic's Claude Code SDK supports this pattern via the `--output-format` and subprocess orchestration APIs.[^3]

The orchestrator is responsible for four things:

1. **Decomposing** the task into parallel units of work.
2. **Spawning** sub-agents with scoped context (not the full conversation history).
3. **Checkpointing** each sub-agent's output to a persistent store.
4. **Verifying** that the checkpoint store is complete and correct before proceeding.

```takeaways
- Sub-agents receive only the context the orchestrator explicitly provides — they do not share memory with each other or with the orchestrator's conversation thread.
- Sub-agent isolation prevents one agent's error state from contaminating another's result, but also means dense sequential dependencies cannot be parallelized.
- The orchestrator's four responsibilities (decompose, spawn, checkpoint, verify) must all be present; missing one makes the others harder to operate.
```

Sub-agents are isolated. They receive only the context the orchestrator hands them — a slice of the task, any tools they need, and output format instructions. They do not share memory with each other or with the orchestrator's conversation thread.

This isolation is a feature, not a limitation. It prevents one sub-agent's error state from contaminating another's result. The downside: if your task has dense sequential dependencies (the output of step 3 is required input to step 4), dynamic workflows do not help and may hurt.

## Fan-out patterns

There are two structurally different fan-out shapes.

```takeaways
- Homogeneous fan-out applies the same task structure to different inputs; results are structurally identical and easy to aggregate.
- Heterogeneous fan-out assigns genuinely independent analysis dimensions to different sub-agents; results must be merged by the orchestrator.
- Use sequential chaining inside the orchestrator for steps with dense dependencies — forcing them into a heterogeneous fan-out adds complexity without parallelism benefit.
```

### Homogeneous fan-out

All sub-agents receive the same task structure applied to different inputs. Example: analyze 50 code files for security issues. Each sub-agent gets one file. Results are structurally identical.

```python
import subprocess, json, pathlib, concurrent.futures

def analyze_file(file_path: str) -> dict:
    result = subprocess.run(
        ["claude", "-p",
         f"Analyze this Python file for security issues. Return JSON: {{issues: [...], severity: 'low'|'medium'|'high'}}",
         "--input-file", file_path,
         "--output-format", "json"],
        capture_output=True, text=True, timeout=120
    )
    return {"file": file_path, "result": json.loads(result.stdout)}

files = list(pathlib.Path("src/").glob("**/*.py"))

with concurrent.futures.ThreadPoolExecutor(max_workers=20) as pool:
    futures = {pool.submit(analyze_file, str(f)): f for f in files}
    results = [f.result() for f in concurrent.futures.as_completed(futures)]
```

The orchestrator script launches 20 parallel `claude -p` processes (the practical thread limit for a Max account without hitting rate ceilings). Each sub-agent returns structured JSON. The orchestrator collects and checkpoints all results before doing anything else.

### Heterogeneous fan-out

Sub-agents receive different tasks that produce inputs for a downstream aggregation step. Example: one sub-agent audits for security, another for performance, a third for test coverage. Results are structurally different and must be merged by the orchestrator.

```python
AGENTS = {
    "security":  "Audit for OWASP Top 10 issues. Return {findings: [...]}",
    "perf":      "Identify hot paths and O(n²) loops. Return {findings: [...]}",
    "coverage":  "List untested public functions. Return {findings: [...]}",
}

def run_agent(role: str, prompt: str, target: str) -> dict:
    result = subprocess.run(
        ["claude", "-p", prompt,
         "--input-file", target,
         "--output-format", "json"],
        capture_output=True, text=True, timeout=180
    )
    return {"role": role, "result": json.loads(result.stdout)}

with concurrent.futures.ThreadPoolExecutor() as pool:
    futures = [
        pool.submit(run_agent, role, prompt, "src/payments.py")
        for role, prompt in AGENTS.items()
    ]
    specialist_results = [f.result() for f in concurrent.futures.as_completed(futures)]
```

Heterogeneous fan-out is useful when the analysis dimensions are genuinely independent — security review has nothing to say about test coverage. When they are not independent (e.g., you need the security result to scope the performance review), use sequential chaining inside the orchestrator script, not a heterogeneous fan-out.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I want to audit a Python monorepo with 80 files. Some files need security analysis, some need performance review, and some need both. Design a fan-out orchestration strategy. Consider: how do I route files to the right agents? What shape should the checkpoint store take? How do I avoid running redundant agents?"
  expectedOutput={`Fan-out strategy for a mixed-audit monorepo:

1. **Classification pass (single agent, sequential)**
   Run one fast classification agent first: read file names + top-level imports, return a JSON map of {file_path: ["security", "perf"]} tags. Cost: ~1 agent × 80 short reads. Time: ~30s.

2. **Parallel audit agents (fan-out)**
   From the classification map, build two lists: security_files, perf_files. Files needing both appear in both lists. Spawn two independent thread pools: one for security agents, one for perf agents. Max 20 workers each. Each agent receives one file and its assigned role.

3. **Checkpoint store shape**
   {
     "run_id": "audit-2026-05-31-a1b2",
     "files": {
       "src/payments.py": {
         "security": { "status": "done", "findings": [...] },
         "perf":     { "status": "done", "findings": [...] }
       },
       "src/models.py": {
         "security": { "status": "done", "findings": [...] },
         "perf":     { "status": "pending" }
       }
     }
   }

4. **Deduplication**
   Track each (file, role) pair. If the run crashes and you resume, skip pairs where status == "done". This is idempotent fan-out.`}
/>

## Token budget math

Dynamic workflows multiply token spend. Every sub-agent is a full Claude invocation. A homogeneous fan-out of 50 sub-agents costs 50× the tokens of running one.

```takeaways
- Token spend scales linearly with sub-agent count: a 50-agent fan-out costs 50× a single invocation, and Claude Code plan weekly limits apply to the total.
- Log `input_tokens` and `output_tokens` from every sub-agent and aggregate them in the checkpoint store to create a cost record per orchestration run.
- Measure token spend on a small pilot run before scheduling a recurring large fan-out; cost accumulation is invisible without explicit tracking.
```

Rule of thumb for estimating cost before you build:

```
Total tokens ≈ (n_subagents × avg_context_per_agent) + orchestrator_tokens
```

For a code analysis run with 50 agents, each receiving a 2,000-token file plus a 500-token prompt:

```
50 × 2,500 = 125,000 input tokens
50 × 1,000 = 50,000 output tokens (estimated)
Orchestrator: ~5,000 tokens
Total: ~180,000 tokens
```

At Sonnet 4.6 pricing (as of 2026), this is a fraction of a dollar — but with Claude Code plans that enforce **weekly [[token]] limits**, burning 180,000 tokens on one orchestration run can noticeably dent your weekly quota.[^5]

Community posts from May 2026 consistently flag this: users who turned on dynamic workflows for large fan-outs saw their weekly credit reset events become meaningful rather than routine.[^2] The problem is not the per-run cost but the **invisibility** — if you do not log total tokens per orchestration run, you will not see the accumulation until the quota wall hits.

**Mitigation:** log `input_tokens` and `output_tokens` from every sub-agent's response. Aggregate them at orchestrator level. Write the total to your checkpoint store. You then have a cost record per run that persists across failures.

```python
def run_agent_with_cost_tracking(role: str, prompt: str, file: str) -> dict:
    result = subprocess.run(
        ["claude", "-p", prompt,
         "--input-file", file,
         "--output-format", "json",
         "--verbose"],   # prints usage to stderr
        capture_output=True, text=True, timeout=180
    )
    payload = json.loads(result.stdout)
    # claude --verbose emits usage JSON on stderr
    try:
        usage = json.loads(result.stderr.splitlines()[-1])
    except Exception:
        usage = {}
    return {
        "role": role,
        "file": file,
        "result": payload,
        "tokens_in": usage.get("input_tokens", 0),
        "tokens_out": usage.get("output_tokens", 0),
    }
```

<Callout type="warning">
Weekly Claude Code plan limits apply per-account, not per-script. A dynamic workflow that fans out to 100 sub-agents burns plan quota as if a human ran 100 manual Claude Code tasks. On Pro, that can exhaust a week's allowance in a few runs. On Max, limits are higher but still finite. Before you schedule a recurring orchestration job, measure its token cost on one real run and multiply by run frequency.
</Callout>

## Checkpoint patterns

A **[[checkpoint]]** is a durable write of an intermediate result that the orchestration script can read on restart. Without checkpoints, a partial failure means re-running all sub-agents from scratch — wasting quota and time.

The minimal checkpoint pattern:

```python
import json, pathlib, hashlib, time

CHECKPOINT_DIR = pathlib.Path(".checkpoints")
CHECKPOINT_DIR.mkdir(exist_ok=True)

def checkpoint_key(run_id: str, file: str, role: str) -> str:
    content = f"{run_id}:{file}:{role}"
    return hashlib.sha256(content.encode()).hexdigest()[:16]

def write_checkpoint(run_id: str, file: str, role: str, result: dict):
    key = checkpoint_key(run_id, file, role)
    path = CHECKPOINT_DIR / f"{key}.json"
    path.write_text(json.dumps({
        "run_id": run_id, "file": file, "role": role,
        "ts": time.time(), "result": result
    }))

def read_checkpoint(run_id: str, file: str, role: str) -> dict | None:
    key = checkpoint_key(run_id, file, role)
    path = CHECKPOINT_DIR / f"{key}.json"
    if path.exists():
        return json.loads(path.read_text())
    return None

def run_agent_checkpointed(run_id: str, role: str, prompt: str, file: str) -> dict:
    cached = read_checkpoint(run_id, file, role)
    if cached:
        return cached["result"]           # skip sub-agent if already done
    result = run_agent_with_cost_tracking(role, prompt, file)
    write_checkpoint(run_id, file, role, result)
    return result
```

With this pattern, you can kill the orchestration script mid-run, fix a broken agent prompt, and restart. Only the incomplete (file, role) pairs re-run. Completed pairs read from disk in milliseconds.

### Checkpoint granularity

Write checkpoints **per unit of work** (per file, per document, per API call), not per stage. A coarser checkpoint — "stage 2 is done" — forces a full stage re-run on failure. A finer checkpoint — "file X, role Y is done" — lets you resume at the exact failure point.

The cost of fine-grained checkpoints is small JSON files and slightly more I/O. The cost of coarse checkpoints is duplicated sub-agent invocations. Fine-grained is almost always the right choice.

## Verification before handoff

A checkpoint stores what a sub-agent said. A **[[verification]]** step decides whether to trust it.

Without verification, a silent sub-agent failure — malformed JSON, hallucinated schema field, empty output, timeout — propagates into the final result. The orchestrator assembles garbage and the downstream consumer sees it.

Verification should happen before the orchestrator commits to using a checkpoint result in the final assembly.

```python
from typing import TypedDict

class SecurityFinding(TypedDict):
    file: str
    line: int
    severity: str
    description: str

def verify_security_result(result: dict) -> tuple[bool, str]:
    """Returns (is_valid, reason). Reason is empty string on success."""
    if "findings" not in result:
        return False, "missing 'findings' key"
    if not isinstance(result["findings"], list):
        return False, "'findings' must be a list"
    for i, f in enumerate(result["findings"]):
        if not isinstance(f.get("severity"), str):
            return False, f"finding[{i}] missing string 'severity'"
        if f["severity"] not in ("low", "medium", "high", "critical"):
            return False, f"finding[{i}] has invalid severity: {f['severity']}"
    return True, ""

def assemble_final_report(run_id: str, files: list[str]) -> dict:
    verified, rejected = [], []
    for file in files:
        cp = read_checkpoint(run_id, file, "security")
        if cp is None:
            rejected.append({"file": file, "reason": "no checkpoint"})
            continue
        ok, reason = verify_security_result(cp["result"])
        if ok:
            verified.append({"file": file, "findings": cp["result"]["findings"]})
        else:
            rejected.append({"file": file, "reason": reason})

    if rejected:
        # surface failures explicitly rather than silently omitting them
        print(f"WARNING: {len(rejected)} files rejected during verification:")
        for r in rejected:
            print(f"  {r['file']}: {r['reason']}")

    return {"verified": verified, "rejected": rejected, "run_id": run_id}
```

The orchestrator should expose the `rejected` list to the caller. Silent omission is the worst outcome — the downstream system thinks all 80 files were analyzed when 5 were silently dropped.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="An orchestration script fanned out to 20 sub-agents. Two returned empty output (timeout), one returned valid JSON with an unexpected extra field 'confidence_score' not in the agreed schema, and one returned a Python traceback instead of JSON. How should the verification layer handle each case? What should the orchestrator report?"
  expectedOutput={`Handle each case explicitly:

**Empty output (2 agents — timeouts)**
Mark these as status: "failed", reason: "empty output / timeout". Do NOT silently drop them. Log which files were skipped. Depending on tolerance: either re-queue these specific files with a longer timeout, or surface them in the final report as "unanalyzed".

**Extra schema field ('confidence_score')**
This is a schema evolution case, not a failure. If the field is not required by your contract, accept the result and strip or preserve the extra field based on policy. Do not reject valid outputs for forward-compatible additions. Log the unexpected field for schema tracking.

**Python traceback instead of JSON**
This is a hard failure. The sub-agent crashed before producing output. Mark status: "failed", reason: "agent error — non-JSON output". Log the traceback for debugging. Do not attempt to parse it as a finding.

**Orchestrator report**
Always include a summary:
{
  "total_files": 20,
  "verified": 17,
  "failed": {
    "timeout": 2,
    "agent_error": 1
  },
  "warnings": {
    "schema_drift": 1
  }
}

Never present 17/20 as "complete". The 3 failures are load-bearing gaps in coverage.`}
/>

## Rollback patterns

Not all dynamic workflows are read-only. Some fan-out to sub-agents that write to databases, call APIs, or modify files. When a verification step fails after some sub-agents have already committed writes, you need rollback.

The simplest rollback pattern is **two-phase execution**:

1. **Propose phase** — sub-agents generate proposed changes, write them to the checkpoint store as diffs or new-state blobs. No actual writes to production systems.
2. **Commit phase** — the orchestrator runs verification on all proposals. If all verify, it applies them. If any fail, it discards the entire set and surfaces the failures.

```python
def execute_two_phase(run_id: str, tasks: list[dict]) -> dict:
    # Phase 1: propose
    proposals = {}
    for task in tasks:
        proposal = run_propose_agent(run_id, task)   # writes to checkpoint, not to DB
        ok, reason = verify_proposal(proposal)
        if not ok:
            return {"status": "aborted", "reason": reason, "task": task}
        proposals[task["id"]] = proposal

    # Phase 2: commit (only reached if all proposals verified)
    committed = []
    for task_id, proposal in proposals.items():
        apply_proposal(task_id, proposal)             # actual write
        committed.append(task_id)

    return {"status": "committed", "count": len(committed)}
```

If you cannot implement two-phase (e.g., external API calls have no transactional rollback), design the fan-out so that each sub-agent is **idempotent**: running it twice has the same effect as running it once. Idempotency is the poor-person's rollback when real rollback is unavailable.

<KnowledgeCheck
  questions={[
    {
      question: "You fan out 50 sub-agents for a document analysis job. After 35 complete, the orchestration script crashes. You fix a bug in the sub-agent prompt. What should the checkpoint pattern allow you to do?",
      answers: [
        "Re-run all 50 sub-agents with the new prompt",
        "Skip the 35 completed agents and run only the remaining 15",
        "Invalidate all checkpoints because the prompt changed",
        "Run the orchestrator once more and let it decide automatically"
      ],
      correctIndex: 1,
      explanation: "Checkpoints store (file, role, run_id) → result. Since you fixed a bug in the prompt, the correct decision depends on whether the 35 completed results are still valid. If the bug affected their output, you should invalidate and re-run. If only the 15 remaining would have been affected, skip the 35. The key is that the checkpoint architecture gives you the choice — without it, you have no choice but to re-run all 50."
    }
  ]}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Describe a fan-out workflow from your own domain. Identify: the unit of parallelism (what does each sub-agent receive?), the checkpoint key structure, one verification check, and one case where you would reject the entire run rather than just flag a single failure."
    }
  ]}
/>

## When NOT to use dynamic workflows

Dynamic workflows are not the default for tool use. They are a specialized pattern that adds complexity, cost, and operational overhead. Use them only when the task justifies it.

**Do not use dynamic workflows when:**

1. **The task fits in one prompt.** If Claude can produce the correct result in a single turn with one or two tool calls, fan-out adds nothing except tokens and latency.

2. **Sequential dependencies prevent meaningful parallelism.** If step 3 depends on step 2's output, you cannot run them in parallel. Sequential chaining inside one Claude instance is simpler.

3. **You need human approval at an undetermined mid-flight point.** Dynamic workflows are designed for machine-to-machine completion. If a human must review and approve at a step that only becomes identifiable during execution, an interactive agent loop is the right tool, not an orchestration script.

4. **Latency matters more than throughput.** Spawning sub-agents has overhead: process startup, context injection, output parsing, checkpoint I/O. For a task with five small sequential steps, that overhead is more than the parallelism saves.

5. **The token cost is not justified.** If your job takes 10 minutes sequentially and 2 minutes with 50 sub-agents, but the sequential path costs 5,000 tokens and the fan-out costs 250,000 tokens, you are spending 50× to save 8 minutes. That trade-off only makes sense at scale or when wall-clock time has a direct dollar value to you.

<Callout type="info">
The community's reaction to dynamic workflows has been instructive: the users who benefit most are those running batch jobs (code review, document processing, data extraction) where the input is large, the parallelism is natural, and the cost-per-run is predictable. Users who add dynamic workflows to interactive pipelines or small tasks consistently report that the overhead outweighs the benefit.
</Callout>

## Practical fan-out limits by plan tier

As of June 2026, the practical fan-out ceiling is determined by weekly token limits, not a hard API concurrency cap.[^2][^5]

| Plan | Practical max concurrent sub-agents | Notes |
|---|---|---|
| Claude Pro | 5–10 | Weekly credit resets quickly at high fan-out |
| Claude Max (×5) | 20–40 | Comfortable for mid-size batch jobs |
| Claude Max (×20) | 80–150 | Viable for large-scale orchestration |
| API (pay-as-you-go) | Rate-limit dependent | No weekly cap; cost is per-token |

These are community-reported heuristics, not Anthropic's official numbers.[^1] Your optimal concurrency depends on your specific prompts and context sizes. Always measure token spend on a small pilot run before committing to a large fan-out.

For the API route (non-plan, pay-as-you-go), weekly limits do not apply but per-minute rate limits do. Throttle sub-agent launch rates with exponential backoff if you see 429s.

## Summary of the dynamic workflow stack

A production dynamic workflow has five layers:

```
┌─────────────────────────────────────────────────────────┐
│ 1. Orchestrator   Decomposes task → spawns sub-agents   │
├─────────────────────────────────────────────────────────┤
│ 2. Sub-agents     Isolated Claude -p invocations        │
│                   Each receives scoped context + tools  │
├─────────────────────────────────────────────────────────┤
│ 3. Checkpoint store  JSON files per (run_id, unit, role)│
│                      Enables idempotent resume          │
├─────────────────────────────────────────────────────────┤
│ 4. Verification   Schema + value checks before assembly │
│                   Rejects or flags incomplete results   │
├─────────────────────────────────────────────────────────┤
│ 5. Cost tracking  input_tokens + output_tokens per agent│
│                   Aggregated per run in checkpoint store│
└─────────────────────────────────────────────────────────┘
```

Missing any layer makes the others harder to operate. Verification without checkpoints means you cannot recover from partial failures. Checkpoints without cost tracking means you cannot explain the quota bill.

## Try this yourself

**Hands-on exercise: build a checkpointed code reviewer**

Build an orchestration script that:

1. Accepts a directory path as input.
2. Lists all `.py` files in the directory.
3. Fans out to one `claude -p` sub-agent per file, asking each to return `{file, issues: [{line, severity, message}]}` as JSON.
4. Writes each result to a checkpoint store keyed by `(run_id, file_path)`.
5. Verifies each result (checks that `issues` is a list, each issue has `line` as int and `severity` in `["low","medium","high","critical"]`).
6. Prints a summary: total files, verified, rejected (with reasons), total input + output tokens.

**Success criteria:**
- Run the script on a 10-file sample directory. Kill it after 5 files complete. Restart it. Confirm that only the 5 incomplete files run again (not the already-complete 5).
- Manually corrupt one checkpoint file (remove the `issues` key). Confirm the script flags it as a verification failure, not a crash.
- Check the token totals in the summary against what you expect from your plan's usage dashboard.

**Stretch goal:** add a `--dry-run` flag that reads checkpoints and prints the summary without spawning any sub-agents.

## What's next

You have now covered the full tool-use stack from basic function calling (Chapter 1) through production connector patterns (Chapters 7–9) and orchestration (this chapter). The **Capstone Project** applies everything: build a production-ready MCP Agentic Connector that bridges a secure domain system to Claude, includes structured logs for every tool call, authorization per tool, a compliance audit trail, and optionally a dynamic workflow layer for batch operations.

---

[^1]: r/ClaudeAI thread on Claude Code dynamic workflows, 2026-05-29 — https://www.reddit.com/r/ClaudeAI/comments/1tq9ofy/introducing_dynamic_workflows_in_claude_code/
[^2]: r/ClaudeAI thread on Claude Code credits and weekly limits, 2026-05-29 — https://www.reddit.com/r/ClaudeAI/comments/1tq9vqf/claude_code_credits_rebooted_after_coding_for/
[^3]: Anthropic Claude Code SDK documentation — https://docs.anthropic.com/en/docs/claude-code/sdk
[^4]: Anthropic support: Claude Agent SDK with Claude plan — https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan
[^5]: Anthropic Claude Code settings documentation — https://docs.anthropic.com/en/docs/claude-code/settings
