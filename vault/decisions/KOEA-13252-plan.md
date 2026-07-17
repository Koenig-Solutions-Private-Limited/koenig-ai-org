---
ticket: KOEA-13252
planner: planner
date: 2026-07-16
estimated_complexity: medium
estimated_token_cost: "$0.25"
---

# Plan

## Goal
Prevent scheduled `skip_if_active` routines from starving forever behind a stale routine execution issue that has no live checkout/execution run, while preserving the intended behavior that a genuinely live run suppresses overlapping scheduled dispatches. This plan was produced by [KOEA-13253](/KOEA/issues/KOEA-13253).

## Context
- Files to read first: `server/src/services/routines.ts:620-745`, `server/src/services/routines.ts:880-1095`, `server/src/services/routines.ts:1660-1760`, `server/src/__tests__/routines-service.test.ts:503-565`, `packages/db/src/schema/issues.ts:80-91`, `packages/db/src/schema/routines.ts:30-111`, `doc/GOAL.md`, `doc/PRODUCT.md`, `doc/SPEC-implementation.md`, `doc/DEVELOPING.md`, `doc/DATABASE.md`.
- Prior work: [KOEA-13252](/KOEA/issues/KOEA-13252) shows six routines from 2026-07-14 through 2026-07-16 stuck behind one open routine issue with `checkoutRunId`/`executionRunId` null. Manual cancellation of those stale issues let routines resume, so the durable fix should happen at the routine dispatch gate.
- Current code: `dispatchRoutineRun` calls `findOpenExecutionIssue` for all non-`always_enqueue` policies. That helper treats any open routine execution issue as active, even when `findLiveExecutionIssue` would return null. The skipped run then records `linkedIssueId` and `coalescedIntoRunId` against the stale issue and updates routine touched state, masking the missed real execution.
- Constraints: this touches Paperclip core server behavior, so Chief Engineering should request the required core-package approval before Executor starts. Base branch `origin/master` exists. No schema migration should be needed because the necessary issue run-lock and status fields already exist.

## Approach
**Chosen**: Add a stale-issue branch inside routine dispatch for scheduled `skip_if_active` runs. When an open routine execution issue exists but no live execution issue exists, and the issue has no active checkout/execution lock, automatically cancel that stale issue with an audit comment/activity, then allow the scheduled dispatch to create the new routine execution issue. This directly fixes the starvation path and keeps live `skip_if_active` behavior intact.

**Rejected alternative 1**: Change `skip_if_active` to ignore open non-live issues without closing them. This would resume schedules but leave stale routine issues open and preserve the recovery-loop noise that caused the incident.

**Rejected alternative 2**: Fix only stranded-assigned-issue recovery. That is useful follow-up work, but it does not protect routine dispatch from future stale routine issues or guarantee the next cron tick creates a fresh execution.

**Rejected alternative 3**: Add only an alert after missed ticks. Alerts reduce silence but still require human cleanup; the parent issue already proves manual cleanup is the fragile part.

## Steps
1. In `server/src/services/routines.ts`, add a small helper near `findLiveExecutionIssue`/`findOpenExecutionIssue` that identifies a stale routine execution issue: open routine issue, same routine/fingerprint, no live heartbeat run, and no active `checkoutRunId`/`executionRunId`.
2. In `dispatchRoutineRun`, split the non-`always_enqueue` path so `skip_if_active` checks for a live issue first; if live, keep the existing `skipped` result and manual-run inbox touch behavior.
3. In the same dispatch path, when a scheduled `skip_if_active` run finds only a stale open issue, cancel that stale issue inside the existing transaction before issue creation, with a concise comment such as `Auto-cancelled stale routine execution so the next scheduled run can proceed`; preserve company scoping and actor as system/routine scheduler.
4. Keep `coalescedIntoRunId` only for real coalesce/skip into a live issue. The stale-cancel-and-create path should produce an `issue_created` run linked to the new issue, not a skipped run linked to the stale issue.
5. Add focused regression coverage in `server/src/__tests__/routines-service.test.ts`: seed a `skip_if_active` scheduled routine with a stale open issue whose run locks are null, call `tickScheduledTriggers`, and assert the old issue is cancelled, a new issue is created, the run status is `issue_created`, and trigger `nextRunAt` remains non-null/future.
6. Extend or preserve the existing active-run test so a `skip_if_active` routine with a live heartbeat run still returns `skipped`, links to the active issue, and does not cancel it.
7. Update no UI or shared API types unless Executor discovers a compile-time contract break; document in the PR that this is a server-side behavior fix with no migration.

## Verification
- `pnpm test:run server/src/__tests__/routines-service.test.ts`
- `pnpm -r typecheck` if the routines service helper changes exported/shared types or issue-service signatures; otherwise report that targeted Vitest covered the change.
- QA should verify the regression behavior from test evidence: stale `skip_if_active` scheduled routine issues are auto-cancelled and replaced by a fresh execution issue, while live active executions still skip overlap.
- QA should inspect the PR diff for no schema migration, no UI copy churn, and no behavior change to `always_enqueue`.

## Risk
- Auto-cancelling an open issue is a strong action. Limit it to scheduled `skip_if_active` routine execution issues with no live run/lock, and write an audit comment so the board can see why it happened.
- A stale issue might contain useful human context. The cancellation comment should link the new execution issue when available or clearly state that the scheduler is creating the replacement run.
- Race conditions are possible around scheduler ticks. Keep the change inside the existing routine transaction and preserve the routine row lock.

## Out of scope
- Reworking stranded-assigned-issue recovery, adding missed-tick alerting, changing `coalesce_if_active`, changing `always_enqueue`, adding routine policy configuration UI, database migrations, or manually cancelling current production issues.
