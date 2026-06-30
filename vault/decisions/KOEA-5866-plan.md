---
ticket: KOEA-5866
planning_issue: KOEA-5916
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: "$0.34"
base_branch: master
basebranch_verified: true
---

# Plan: Fix routine execution uniqueness collision on comment resumes

## Goal
Prevent `issues_open_routine_execution_uq` from surfacing as `adapter_failed` when a comment-triggered resume or queued promotion tries to bind a routine execution issue while another same routine/fingerprint execution is already active. Success means duplicate same-origin routine work is coalesced, deferred, skipped, or cancelled with an explicit lifecycle reason before adapter execution starts, and the original successful agent turn is not rewritten as failed by a later lock collision.

## Context
- Files to read first: `packages/db/src/schema/issues.ts:31-91`, `server/src/services/routines.ts:663-715`, `server/src/services/routines.ts:905-1008`, `server/src/services/heartbeat.ts:3830-3924`, `server/src/services/heartbeat.ts:6105-6335`, `server/src/services/issues.ts:3060-3155`
- Relevant prior work: [KOEA-5866](/KOEA/issues/KOEA-5866) investigation comments; failed heartbeat run `80358a0c-f599-4192-8df1-fb24aa45ff8f` on [KOEA-5842](/KOEA/issues/KOEA-5842)
- Constraints: implementation is Paperclip core and requires board/CEO authorization after plan review; keep changes to heartbeat/routine execution semantics only; do not change the partial unique index unless the guard cannot be made correct.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a shared heartbeat-side routine execution bind guard. The root cause is the lazy-lock transition that sets `issues.executionRunId` after a run is queued or promoted: `claimQueuedRun()` stamps `executionRunId` once the queued run becomes `running`, and `releaseIssueExecutionAndPromote()` stamps it for deferred wakes. Those updates can hit the partial unique index when another open `routine_execution` row with the same `companyId`, `originId`, and `originFingerprint` already has a live `executionRunId`. The existing `dispatchRoutineRun()` handler does not cover this because it only wraps `issueSvc.create()`, while the duplicate-key exception is raised later during heartbeat binding. Implement one helper that locks the target issue, detects a same routine/fingerprint live execution before stamping, stamps atomically when safe, and converts conflicts into explicit run/wakeup cancellation or coalescing metadata instead of throwing raw `23505`.

**Rejected**: Broaden `issues_open_routine_execution_uq` to include idle rows. Reason: the current service test intentionally permits fresh execution issues when previous routine issues are open but idle, and changing the index would turn backlog cleanup into a blocking migration.

**Rejected**: Fix only `dispatchRoutineRun()` by checking for more existing issues. Reason: comment resumes and deferred promotions can be queued independently of routine dispatch, so the failing transition would remain uncovered.

## Steps (Executor follows in order)
1. Add a helper in `server/src/services/heartbeat.ts` near `claimQueuedRun()` that, inside a transaction, loads the target issue, recognizes `originKind === "routine_execution"`, checks for another open, unhidden same `originId`/`originFingerprint` issue with a live queued/running/scheduled-retry execution path, and either stamps `executionRunId` or returns a structured conflict.
2. Replace the direct `issues.executionRunId` update in `claimQueuedRun()` with the helper and move the heartbeat-run `queued -> running` claim plus issue bind into one atomic path; when the helper reports a routine conflict, mark the queued run cancelled or coalesced with a stable `errorCode` such as `routine_execution_already_active`, update the wakeup request, append a lifecycle event naming the active issue/run, and return `null` before adapter execution.
3. Use the same helper in `releaseIssueExecutionAndPromote()` before promoted deferred wakes stamp `executionRunId`; if a same routine/fingerprint execution is active, leave the deferred wake in a non-running terminal state with the same structured event instead of promoting it into a run that can trip `23505`.
4. Keep the existing `dispatchRoutineRun()` create-conflict catch, but route any shared conflict formatting through the new helper utilities where practical so routine dispatch, queued claims, and promotions report the same active issue/run details.
5. Add embedded-Postgres coverage in `server/src/__tests__/routines-service.test.ts` or a focused heartbeat test file for: a scheduled routine execution becoming active while a comment-triggered resume for an older same-fingerprint routine issue is queued; the queued resume is cancelled/coalesced without `adapter_failed` and the active execution remains live.
6. Add a regression for deferred promotion: a deferred comment wake for a routine issue is promoted only when no same routine/fingerprint execution is active; otherwise it gets the structured routine-conflict terminal state and does not throw `23505`.
7. Add a data-stance note to the implementation PR: no emergency repair is needed for rows already covered by the partial unique index; optional cleanup of open idle same-origin/fingerprint routine issues with `execution_run_id is null` is separate backlog work.

## Verification (QA Verifier checks these)
- [ ] `pnpm test -- --run server/src/__tests__/routines-service.test.ts` or the new focused heartbeat test file passes against embedded Postgres and exercises the real partial unique index.
- [ ] A synthetic queued comment resume for a routine issue with another active same routine/fingerprint issue exits with the structured routine-conflict status/event, not `adapter_failed` or raw `23505`.
- [ ] A successful original routine agent run remains `succeeded`/live and its issue state is not overwritten to failed because a later same-origin queued resume was cancelled or coalesced.

## Risk
- The main risk is dropping a human comment-triggered resume instead of preserving it. Mitigate by recording the target issue id, active issue id, active run id, wake reason, and comment id in the cancelled/coalesced run event so follow-up handling is visible and can be promoted to a richer deferred-by-routine-fingerprint queue later if product wants that behavior.

## Out of scope
- Cleaning up historical open idle routine execution issues where `execution_run_id is null`.
- Changing the `issues_open_routine_execution_uq` index definition or routine concurrency policy semantics.
- Reposting to [KOEA-5842](/KOEA/issues/KOEA-5842) while it is checked out by another agent.
