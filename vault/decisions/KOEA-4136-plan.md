---
ticket: KOEA-4136
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: $0.55
base_branch: master
planner_chain_alert_approval: 70fa0ff5-3cc1-4b19-81c6-2047d87dc1b4
type: decision
agent: planner
tags:
  - decision
  - paperclip/recovery
---

# Plan: Stop stale-block recovery zombies

## Goal
Stop routine/watchdog cleanup work from reappearing after intentional cancellation, and stop scheduled routines from accumulating duplicate blocked execution issues. Success means intentionally cancelled stale-triage issues stay cancelled, routine polls coalesce into one actionable open issue per routine/fingerprint, and recovery still handles genuinely stranded assigned work.

## Context
- Files to read first: `server/src/services/recovery/service.ts:178-180`, `server/src/services/recovery/service.ts:374-415`, `server/src/services/recovery/service.ts:1352-1435`, `server/src/services/recovery/service.ts:1545-1805`, `server/src/services/recovery/service.ts:2328-2491`, `server/src/services/heartbeat.ts:6029-6414`, `server/src/services/routines.ts:653-717`, `server/src/services/routines.ts:903-965`, `packages/db/src/schema/issues.ts:85-93`, `server/src/__tests__/heartbeat-process-recovery.test.ts:1511-1544`, `server/src/__tests__/heartbeat-process-recovery.test.ts:1829-1976`, `server/src/__tests__/routines-service.test.ts:181-226`, `server/src/__tests__/routines-service.test.ts:322-384`.
- Root-cause hypothesis: the observed "reviver" is likely two mechanisms interacting. Stranded-work recovery and terminal-run recovery retry assigned `todo`/`in_progress` work through `enqueueStrandedIssueRecovery`, `ensureStrandedIssueRecoveryIssue`, and the immediate recovery path in `heartbeat.ts`; separately, routine dispatch only coalesces when an existing routine issue has a live execution run, while status changes to `blocked` clear `executionRunId`, so blocked routine executions stop matching both `findLiveExecutionIssue` and the partial unique index. That lets schedule ticks create new routine issues while stale blocked/cancelled cleanup output remains in the graph.
- Relevant prior work: KOEA-4136 parent diagnosis from V7 Phase N stale-block triage; approved planner chain alert `70fa0ff5-3cc1-4b19-81c6-2047d87dc1b4`.
- Constraints: keep all queries company-scoped; do not touch learnova portals; preserve genuine recovery for normal stranded issues; do not hard-delete issues; do not introduce a broad schema migration unless tests prove service-level coalescing is insufficient.

## Approach (1 chosen, alternatives rejected)
**Chosen**: combined recovery suppression plus routine coalescing. Add a narrow stale-triage suppression guard to the recovery service and immediate terminal-run recovery path, then change routine dispatch to coalesce against any open non-terminal routine execution with the same routine/fingerprint, not only one with a live `executionRunId`. This addresses both acceptance risks: cancelled stale-triage markers stay respected, and new duplicate routine/watchdog issues stop accumulating.

**Rejected**: guard only - it prevents some recovery paths but leaves `routines.ts` free to create new open duplicates after a blocked issue loses `executionRunId`; reaper only - it cleans symptoms after duplication and risks deleting useful audit history; upsert only - it reduces future routine duplicates but does not explicitly protect intentional stale-triage cancellations from recovery/liveness escalation paths.

## Steps (Executor follows in order)
1. In `server/src/services/recovery/service.ts`, add a helper near `isStrandedIssueRecoveryIssue` that detects intentionally suppressed stale-triage issues by company-scoped issue id/status plus existing evidence markers in recent issue comments or activity details: `V7 Phase N triage`, `stale-triage subagent`, `no_recover=true`, and `close_reason` values starting with those prefixes. Do not add an `issues.metadata` column in this ticket because the current schema has no such column.
2. In `server/src/services/recovery/service.ts`, call that helper before `ensureStrandedIssueRecoveryIssue`, before liveness escalation creation in `createIssueGraphLivenessEscalation`, and before retiring/relinking cancelled liveness recovery issues, so suppressed cancelled blockers do not spawn new `stranded_issue_recovery` or `harness_liveness_escalation` issues.
3. In `server/src/services/heartbeat.ts`, mirror the same suppression check before `releaseIssueExecutionAndPromote` queues immediate recovery for a terminal failed/cancelled run. If the issue is suppressed, release execution state only and do not reopen, retry, or block it.
4. In `server/src/services/routines.ts`, replace or extend `findLiveExecutionIssue` with a `findOpenExecutionIssue` path used by `dispatchRoutineRun`: for `coalesce_if_active` and `skip_if_active`, coalesce/skip when an existing `routine_execution` issue in the same company has the same `originId` and dispatch fingerprint and status in `backlog`, `todo`, `in_progress`, `in_review`, or `blocked`, regardless of live `executionRunId`. Keep `always_enqueue` behavior unchanged.
5. Add regression coverage in `server/src/__tests__/heartbeat-process-recovery.test.ts`: one test for a cancelled stale-triage marked issue proving `reconcileStrandedAssignedIssues` and immediate terminal-run recovery do not create a recovery issue, and one test for a blocked issue with a cancelled stale-triage blocker proving liveness reconciliation does not create an escalation.
6. Update `server/src/__tests__/routines-service.test.ts`: change the current "creates a fresh execution issue when the previous routine issue is open but idle" expectation to the new coalescing behavior, and add a blocked open routine issue case proving a later schedule tick links to the existing issue instead of creating another.
7. Runtime/dist handling: make source-only changes in the PR. `server/dist/services/recovery/service.js` is not tracked in this repo, so do not edit generated dist in source control. For the running Paperclip instance that currently executes `/app/server/dist/...`, coordinate a normal rebuild/restart after merge; only use a temporary dist hotfix if Chief Engineering explicitly authorizes it, and then reconcile it back to source.

## Verification (QA Verifier checks these)
- [ ] `pnpm vitest run server/src/__tests__/heartbeat-process-recovery.test.ts server/src/__tests__/routines-service.test.ts`
- [ ] `pnpm -r typecheck`
- [ ] Manual DB spot-check after deploy: for the target company, repeated routine ticks for publish-verifier/watchdog-style routines do not increase count of open `routine_execution` issues with the same `origin_id` and `origin_fingerprint`.
- [ ] Manual cancellation spot-check: a stale-triage marked cancelled issue remains `cancelled` after one heartbeat scheduler interval and no new recovery issue appears with that issue as `origin_id` or liveness leaf.

## Risk
- Risk: broad suppression could hide legitimate recovery for real cancelled blockers. Mitigation: match only explicit stale-triage/no-recover markers, keep normal `blocked_by_cancelled_issue` liveness behavior for unmarked cancelled blockers, and cover both marked and unmarked cases in tests.

## Out of scope
- Hard-deleting old zombie issues or building a new reaper.
- Changing routine definitions such as publish-verifier-poll, triage-30min, course-author-poll, content-reviewer-poll, slide-fake-done-auditor, or Watchdog Marker nudges.
- Adding a new issue metadata column or database-level uniqueness migration unless a follow-up ticket decides service-level coalescing is not enough.
- Modifying learnova portals.

## Pre-flight Footer
status_ok=true; sibling_count=4; sibling_alert_approved=70fa0ff5-3cc1-4b19-81c6-2047d87dc1b4; acceptance_ok=true; basebranch_verified=true; base_branch=master; dist_tracked=false
