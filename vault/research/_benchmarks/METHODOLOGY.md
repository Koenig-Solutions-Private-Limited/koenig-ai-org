---
title: Benchmark Methodology — Codex CLI vs Claude Code Opus 4.7
koea: KOEA-7091
author: Chief Research (08faf10d)
date: 2026-06-03
status: infrastructure-complete, trials-pending-human-execution
---

# Benchmark: Codex CLI vs Claude Code Opus 4.7 — Autonomous Mode

## Research question

Which tool — Codex CLI or Claude Code Opus 4.7 — solves real-world coding tasks faster and more reliably in fully autonomous mode (no human confirmations)?

## Tool versions

| Tool | CLI version | Model |
|------|-------------|-------|
| Codex CLI | 0.128.0 (`codex-cli` npm package) | o4-mini (default) |
| Claude Code | 2.1.126 (`claude` CLI) | claude-opus-4-7 (`--model claude-opus-4-7`) |

Note: KOEA-7091 issue text references "Codex CLI 5.4" — this refers to the model version (codex-o4 / o4-mini), not the npm package. The npm package version is 0.128.0. Recorded in CSV `notes` field as `tool_version=codex-cli-0.128.0`.

## Tasks

Three purpose-built tasks with planted bugs or blank scaffolds. Each has a deterministic correctness criterion (`npm test` all-pass).

### Task A — Express handler refactor (`task-a-express-handler`)
**Difficulty**: Easy (1 of 5 tests failing)
**Bug**: `app.listen()` called at module load time, causing EADDRINUSE in tests. Fix: guard with `if (require.main === module)`.
**Baseline**: 1 failed, 4 passed
**Prompt file**: `prompts/task-a-express-handler.txt`

### Task B — JWT auth scaffold (`task-b-jwt-scaffold`)
**Difficulty**: Hard (0 of 9 tests passing — full implementation required)
**Task**: Implement 5 auth endpoints (register, login, refresh, logout, /me) using bcrypt + JWT + httpOnly cookies from in-memory store.
**Baseline**: 9 failed, 0 passed
**Prompt file**: `prompts/task-b-jwt-scaffold.txt`

### Task C — EventEmitter listener leak (`task-c-streaming-leak`)
**Difficulty**: Medium (1 of 2 tests failing)
**Bug**: `dataSource.on('data', handler)` added per client connect, never removed on disconnect. Fix: add `dataSource.removeListener('data', handler)` in the `req.on('close', ...)` callback.
**Baseline**: 1 failed, 1 passed
**Prompt file**: `prompts/task-c-streaming-leak.txt`

## Protocol

1. **Reset**: `git checkout HEAD -- tasks/<task-name>` before every trial.
2. **Baseline verify**: `npm test` — must show failing tests before tool runs. If baseline is already passing, trial is invalid (abort, re-check git state).
3. **Execute**: Run tool with prompt from `prompts/<task-name>.txt`. Autonomous mode — no human input.
   - Codex: `codex --approval-policy never -q "$PROMPT"`
   - Claude: `claude --model claude-opus-4-7 --allowedTools "Edit,Read,Bash" -p "$PROMPT"`
4. **Timeout**: 1800 seconds (30 min) per trial.
5. **Measure correctness**: `npm test` after tool exits — all-pass = `correctness_pass=true`.
6. **Reset again**: `git checkout HEAD -- tasks/<task-name>` to clean for next trial.

## Metrics

| Column | Description |
|--------|-------------|
| `tool` | `codex` or `claude` |
| `task` | task directory name |
| `trial` | trial number (1–N) |
| `start_utc` | ISO-8601 start timestamp |
| `end_utc` | ISO-8601 end timestamp |
| `time_to_first_viable_diff_s` | elapsed seconds from start to tool exit |
| `time_to_tests_pass_s` | same as above when `correctness_pass=true`, else empty |
| `token_cost_usd` | `unknown` (not captured automatically; fill from provider dashboard) |
| `correctness_pass` | `true` if `npm test` all-pass after tool exits |
| `human_escalations` | always `0` in autonomous mode |
| `notes` | git hash, baseline state, tool version |

## Design choices

- **Autonomous mode only**: Both tools run with all confirmations disabled. This measures raw capability without prompt-engineering overhead.
- **No DB required**: Task A mocks pg; Task B uses in-memory Map; Task C uses EventEmitter. Trials run without external services.
- **Deterministic correctness**: `npm test` all-pass is binary — no partial scoring. Eliminates observer bias.
- **5 trials per combination**: Enough to detect consistency gaps without excessive runtime cost (est. 2–4h total machine time).

## Execution

Run from `vault/research/_benchmarks/`:

```bash
# Full run (5 trials × 2 tools × 3 tasks = 30 trials, ~4–6h)
./run-benchmark.sh

# Pilot: 2 trials, Codex only, task-c only (fastest to validate pipeline)
./run-benchmark.sh --trials 2 --tools codex --tasks task-c-streaming-leak

# Single trial, manual
./run-trial.sh claude tasks/task-b-jwt-scaffold 1 >> codex-vs-claude-code-autonomous-2026-06.csv
```

## Infrastructure status (2026-06-03)

| Component | Status |
|-----------|--------|
| Task A codebase + baseline | verified (1 fail, 4 pass) |
| Task B codebase + baseline | verified (9 fail, 0 pass) |
| Task C codebase + baseline | verified (1 fail, 1 pass) |
| `run-trial.sh` | complete |
| `run-benchmark.sh` | complete |
| Per-task prompt files | complete |
| Codex CLI | installed (0.128.0) |
| Claude Code CLI | installed (2.1.126) |
| CSV with headers | ready |
| **Actual trial data** | **PENDING — human execution required** |

## Why human execution is required

Claude Code trials cannot be run by the Chief Research agent (Claude Code itself) within a Paperclip heartbeat:
1. **Model mismatch**: Chief Research runs on `claude-sonnet-4-6`; the benchmark requires `claude-opus-4-7`. Nested `claude -p` from within an active session inherits the outer model.
2. **Heartbeat timeout**: Each trial takes up to 30 minutes. 30 trials × 30 min = 15h of execution — orders of magnitude beyond a heartbeat window.
3. **Self-referential measurement**: Benchmarking Claude Code from within Claude Code introduces confounds (shared context, resource contention).

**To execute**: Run `./run-benchmark.sh` from a fresh terminal (not inside a Claude Code session), with both CLIs authenticated and `PORT` env unset (or set to an unused value) to avoid EADDRINUSE in Task A.
