---
ticket: KOEA-5279
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
---

# Plan: Stop completed issues from drifting back to in_progress after comment wakes

## Goal
Completed or cancelled issues must not be reopened or checked out by ordinary follow-up comments, deferred comment wake promotion, or wake reconciliation. Success means KOEA-5203-style closure comments remain communicative unless the request includes explicit resume intent, and legitimate board/operator status changes and company-scoped checkout semantics still work.

## Context
- Files to read first: `server/src/routes/issues.ts:185-204`, `server/src/routes/issues.ts:1948-1998`, `server/src/routes/issues.ts:3361-3417`, `server/src/services/heartbeat.ts:3997-4049`, `server/src/services/heartbeat.ts:6115-6277`, `server/src/services/issues.ts:3037-3186`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:344-481`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:767-917`, `server/src/__tests__/heartbeat-comment-wake-batching.test.ts:730-782`, `server/src/__tests__/heartbeat-stale-queue-invalidation.test.ts:299-346`.
- Relevant prior work: KOEA-5279 parent comment `a0f5339a-4439-43cd-8ee7-78d4d9f0fe4b`; chain alert resolution comment `e93c8cad-df14-4425-8f58-b7916b6058ed`.
- Repro evidence: KOEA-5279 cites KOEA-5203 closure/comment sequence `93261bdf-5d36-4584-b35c-1eb0ff0fcd1d`, `6592e9b6-2d14-4d45-bb29-007e9c76f964`, `c7c149e0-493e-42b5-8e0a-c8d917face62`, `044ba218-b457-4318-85ae-dd48a562e6f4`.
- Constraints: no schema migration expected; preserve single-assignee checkout and company access checks; base branch verified on `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Guard terminal issue revival at both the comment API and wake promotion boundaries. Treat `resume: true` as the required machine-readable intent for done/cancelled follow-up execution, stop implicit closed-issue reopen from plain comments, and cancel or leave terminal queued/deferred comment wakes inert when that resume marker is absent. This fixes both direct comment updates and delayed wake reconciliation without changing the checkout contract for normal `todo`/`blocked` work.

**Rejected**: Checkout-only guard; it would stop some direct done -> in_progress writes but would still allow deferred wake promotion to change `done` to `todo` and generate noisy runs. **Rejected**: Remove all comment wakeups for closed issues; that is broader than needed and risks breaking explicit operator resume and mention/review visibility flows.

## Steps (Executor follows in order)
1. Update `server/src/routes/issues.ts` so `shouldImplicitlyMoveCommentedIssueToTodo` no longer reopens `done` or `cancelled` issues from plain comments; keep blocked-issue behavior only if unresolved blocker checks still pass.
2. Update both PATCH `/api/issues/:id` and POST `/api/issues/:id/comments` paths in `server/src/routes/issues.ts` so terminal issue status moves to `todo` only for explicit `resume: true` or deliberate non-comment status updates; reject `resume: true` on `cancelled` as today.
3. Update `server/src/services/heartbeat.ts` queued-run staleness so terminal issue runs with comment IDs are cancelled/skipped unless `resumeIntent` or `followUpRequested` is present.
4. Update `server/src/services/heartbeat.ts` deferred wake promotion so `shouldReopenDeferredCommentWake` requires resume intent, not just `requestedByActorType === "user"` or `issue_reopened_via_comment`; terminal deferred wakes without resume should not mutate issue status.
5. Adjust `server/src/__tests__/issue-comment-reopen-routes.test.ts` by replacing old implicit closed-issue reopen expectations with inert plain-comment cases plus explicit `resume: true` cases for the same-agent/allowed actor paths.
6. Adjust `server/src/__tests__/heartbeat-comment-wake-batching.test.ts` so the KOEA-5203-shaped deferred comment wake leaves the issue `done` and does not clear `completedAt` without resume; add or update one explicit-resume deferred wake case if coverage is not already present.
7. Run targeted verification and keep rollback simple: revert the route/heartbeat changes and restore the old tests if a downstream gate proves an intentional comment-resume flow was missed.

## Verification (QA Verifier checks these)
- [ ] `pnpm vitest run server/src/__tests__/issue-comment-reopen-routes.test.ts`
- [ ] `pnpm vitest run server/src/__tests__/heartbeat-comment-wake-batching.test.ts server/src/__tests__/heartbeat-stale-queue-invalidation.test.ts`
- [ ] Manual API repro: set a test issue to `done`, post an agent or board comment without `resume`, confirm status remains `done` and `completedAt` stays non-null; repeat with `resume: true` and confirm the allowed path moves to `todo` and queues a resume-marked wake.

## Risk
- Existing operator workflows may rely on plain board comments reopening completed work. Mitigation: keep explicit status updates and `resume: true` available, and surface the changed contract in tests and activity payload assertions.

## Rollback
Revert the changes in `server/src/routes/issues.ts`, `server/src/services/heartbeat.ts`, and the three targeted test files. No database rollback is required because this plan does not add schema or migrations.

## Out of scope
- UI affordances for adding `resume: true` from the board comment form.
- Broader recovery/watchdog policy changes for stranded issues unrelated to terminal comment wakes.

## Pre-flight
- `status_gate=pass`
- `chain_alert_resolved=e93c8cad-df14-4425-8f58-b7916b6058ed`
- `basebranch_verified=true`
