---
ticket: KOEA-7874
planning_issue: KOEA-7875
planner: planner
date: 2026-06-12
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
---

# Plan: Add claude_local long-invoke heartbeat output

## Goal
`claude_local` should produce a lightweight keep-alive log line during long-running `adapter.invoke` calls so healthy but quiet Claude runs do not trigger silent-run watchdog recovery. Success is observable as periodic stdout log activity at least every 15 minutes while an attempt is still running, without changing watchdog thresholds or blocking the Claude subprocess.

## Context
- Files to read first: `packages/adapters/claude-local/src/server/execute.ts:536`, `packages/adapters/claude-local/src/server/execute.ts:562`, `server/src/services/heartbeat.ts:5446`, `packages/adapter-utils/src/server-utils.ts:1458`, `server/src/__tests__/claude-local-execute.test.ts:21`
- Relevant prior work: [KOEA-7874](/KOEA/issues/KOEA-7874) was filed from silent-run false positives [KOEA-7859](/KOEA/issues/KOEA-7859) and [KOEA-7869](/KOEA/issues/KOEA-7869), while preserving real-hang detection from the [KOEA-7855](/KOEA/issues/KOEA-7855) / [KOEA-7856](/KOEA/issues/KOEA-7856) auth-hang cluster.
- Constraints: plan-only ticket; implementation should stay scoped to `claude_local`; no watchdog threshold change; no schema/API/UI changes; `origin/master` verified as the base branch for this checkout.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small invoke-heartbeat timer inside `packages/adapters/claude-local/src/server/execute.ts` around each `runAdapterExecutionTargetProcess(...)` attempt. The timer should call the adapter `onLog("stdout", JSON.stringify({ event: "heartbeat", ts: new Date().toISOString(), adapter: "claude_local" }) + "\n")` every 10 minutes while the process promise is unresolved, chain/catch async log writes so it never blocks the subprocess, and clear the interval in `finally`. Because `server/src/services/heartbeat.ts` already updates `heartbeat_runs.last_output_at` from any `onLog` chunk, this refreshes watchdog liveness through the existing output path without contaminating `proc.stdout` or Claude stream parsing.

**Rejected**: Change `scanSilentActiveRuns` thresholds or special-case `claude_local` in watchdog logic - this would weaken real-hang detection. **Rejected**: Write heartbeat JSON directly to the child process stdout buffer or parse Claude transcript progress - direct child output risks interfering with `parseClaudeStreamJson`, and transcript-aware progress is more complex than needed for this fix.

## Steps (Executor follows in order)
1. Update `packages/adapters/claude-local/src/server/execute.ts` to define `CLAUDE_INVOKE_HEARTBEAT_INTERVAL_MS = 10 * 60 * 1000` and a focused helper that starts a `setInterval`, emits one JSON heartbeat line through `onLog("stdout", ...)`, serializes/catches async log writes, and returns a cleanup function.
2. Wrap the `runAdapterExecutionTargetProcess(...)` await in `runAttempt` with that helper so every fresh, resumed, auth-retry, and missing-session fallback attempt emits periodic keep-alives until the attempt resolves.
3. Keep the heartbeat line synthetic via `onLog` only; do not append it to `proc.stdout`, do not alter `parseClaudeStreamJson`, and do not change `server/src/services/heartbeat.ts`.
4. Add focused coverage in `server/src/__tests__/claude-local-execute.test.ts` using fake timers and a fake Claude command that sleeps long enough to trigger the timer, then succeeds with normal stream-json output.
5. In the new test, assert that `onLog` receives a stdout line whose parsed JSON has `event: "heartbeat"` and `adapter: "claude_local"`, and that the normal adapter result still succeeds with the expected session/result.
6. Add a cleanup assertion by advancing timers after `execute(...)` resolves and confirming no further heartbeat lines are emitted.
7. Run targeted verification first, then typecheck the touched package/server boundary if the test passes.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run server/src/__tests__/claude-local-execute.test.ts` passes.
- [ ] `pnpm --filter @paperclipai/adapter-claude-local typecheck` passes.
- [ ] The new test proves a heartbeat line is emitted while the fake Claude process is still running and no heartbeat is emitted after cleanup.
- [ ] No changes are made to watchdog thresholds or `lastOutputAt` semantics; liveness is refreshed through the existing `onLog` path.

## Risk
- Synthetic stdout heartbeat lines may appear in run transcripts as generic stdout. Mitigation: keep the line compact, machine-readable, and adapter-tagged, and do not feed it into `proc.stdout` or Claude result parsing.

## Out of scope
- Changing watchdog recovery thresholds, adding UI transcript rendering for heartbeat lines, parsing Claude transcript progress, or changing non-Claude adapters.

## Pre-flight
- status_ok=true
- sibling_guard_passed=true
- acceptance_ok=true
- basebranch_verified=true
