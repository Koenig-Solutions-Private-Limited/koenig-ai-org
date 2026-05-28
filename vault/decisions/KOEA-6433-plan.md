---
ticket: KOEA-6433
planner: planner
date: 2026-05-28
estimated_complexity: small
estimated_token_cost: $0.32
base_branch: origin/master
preflight:
  status_ok: true
  sibling_count: 4
  chain_alert_resolved: ed9e6aed-def5-4bc5-b6f6-d44576009028
  acceptance_criteria_ok: true
  basebranch_verified: true
---

# Plan: Exclude routine executions from long-active productivity reviews

## Goal
Prevent productive routine execution issues from repeatedly spawning productivity-review tickets only because they stay active longer than the 6h `long_active_duration` threshold. Success means routine-origin issues still participate in productivity review for no-comment streak and high-churn signals, while non-routine long-active issues continue to create manager review tickets.

## Context
- Files to read first: `server/src/services/productivity-review.ts:373-388`, `server/src/services/productivity-review.ts:648-659`, `server/src/services/productivity-review.ts:676-699`, `server/src/__tests__/productivity-review-service.test.ts:50-110`, `server/src/__tests__/productivity-review-service.test.ts:201-221`, `packages/db/src/schema/issues.ts:44-89`, `server/src/services/routines.ts:938-948`
- Relevant prior work: [KOEA-6308](/KOEA/issues/KOEA-6308) and [KOEA-6332](/KOEA/issues/KOEA-6332) are false-positive productivity reviews filed against healthy routine execution issues; [KOEA-6432](/KOEA/issues/KOEA-6432) remains the long-term routine terminal-status/status-flip fix and should not block this short-term guard.
- Constraints: use the verified base branch `origin/master`; do not change schema or shared contracts; keep the change company-scoped through existing `companyId` query predicates; do not suppress unrelated productivity-review triggers for routines.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Gate the `longActive` boolean in `collectEvidence()` with the persisted routine marker: `sourceIssue.originKind !== "routine_execution"`. The exact predicate should be `const longActive = sourceIssue.originKind !== "routine_execution" && elapsedMs !== null && elapsedMs >= thresholds.longActiveMs;`. This is the smallest safe change because evidence collection already decides which trigger applies, and leaving candidates in the reconciler preserves routine reviews for `no_comment_streak` and `high_churn`.

**Rejected**: Exclude `originKind = "routine_execution"` in the candidate SQL because that would suppress all productivity-review triggers for routines. Rejected: raise routine-specific long-active thresholds because it still creates periodic routine review noise later and adds configuration surface. Rejected: wait for [KOEA-6432](/KOEA/issues/KOEA-6432) because that is the durable terminal-status fix, while this ticket is explicitly the short-term false-positive guard.

## Steps (Executor follows in order)
1. Branch from `origin/master`, then re-read `server/src/services/productivity-review.ts:373-388` and `server/src/__tests__/productivity-review-service.test.ts:50-110` before editing.
2. In `server/src/services/productivity-review.ts`, add a small local routine-origin predicate near the trigger booleans in `collectEvidence()` and change only `longActive` to require `sourceIssue.originKind !== "routine_execution"`.
3. Do not change the reconciler candidate query at `server/src/services/productivity-review.ts:648-659`; routines must remain candidates for other triggers.
4. In `server/src/__tests__/productivity-review-service.test.ts`, add a regression test using `seedAssignedIssue({ originKind: "routine_execution", status: "in_progress", startedAt: now - 7h })` and assert `reconcileProductivityReviews()` creates zero productivity reviews.
5. Add or extend a non-routine control assertion proving the existing manual long-active case still creates one `long_active_duration` review.
6. Add a narrow preservation test for routine executions with `DEFAULT_PRODUCTIVITY_REVIEW_NO_COMMENT_STREAK_RUNS` issue-linked runs and no run-created comments, asserting a productivity review is still created with primary trigger `no_comment_streak`.
7. Run `pnpm test:run -- productivity-review-service` and report the result; no browser, build, migration, or repo-wide typecheck is required for this scoped server-only change unless the implementation unexpectedly touches shared contracts.

## Verification (QA Verifier checks these)
- [ ] A `routine_execution` source issue active for more than the long-active threshold does not create an `issue_productivity_review` ticket.
- [ ] A comparable non-routine `in_progress` source issue still creates a `long_active_duration` productivity-review ticket.
- [ ] A routine execution issue that trips `no_comment_streak` still creates a productivity-review ticket, proving the guard is limited to `long_active_duration`.
- [ ] `pnpm test:run -- productivity-review-service` passes, or the Executor reports the exact local environment blocker.

## Risk
- A future routine-origin spelling change would bypass the guard. Mitigation: the persisted marker is confirmed in `packages/db/src/schema/issues.ts` and `server/src/services/routines.ts`; rollback is a one-line revert of the `longActive` predicate if routine review coverage is unexpectedly reduced.

## Out of scope
- Closing or reclassifying existing false-positive review tickets, changing routine issue terminal-status behavior from [KOEA-6432](/KOEA/issues/KOEA-6432), adding schema/shared type migrations, changing review ownership, or changing thresholds for any non-routine issue.
