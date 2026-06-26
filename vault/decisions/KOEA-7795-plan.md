---
ticket: KOEA-7795
plan_review_ticket: KOEA-7810
planner: planner
date: 2026-06-11
estimated_complexity: medium
estimated_token_cost: $0.20
base_branch: master
basebranch_verified: true
---

# Plan: Gate-review status-flip guards for PASS and BLOCK orphans

## Goal
Prevent gate-review verdicts from creating stranded review tickets for KOEA-7795. A PASS or APPROVE verdict must complete the issue in the same write, and a BLOCK verdict that moves an issue to `blocked` must preserve an owner or first-class blocker handoff.

## Context
- Files to read first: `server/src/routes/issues.ts:1924-2535`, `server/src/routes/issues.ts:3398-3657`, `server/src/services/issues.ts:3586-3622`, `packages/shared/src/validators/issue.ts:133-187`, `packages/db/src/schema/issues.ts:21-64`, `packages/db/src/schema/issue_comments.ts:7-19`, `server/src/__tests__/issue-update-comment-wakeup-routes.test.ts:188-260`
- Relevant prior work: parent implementation issue KOEA-7795; plan-review ticket KOEA-7810; CEO comment `c07e1579` expanded scope from PASS orphans to BLOCK orphans.
- Constraints: keep company access checks, assignment permission checks, execution-policy transitions, activity logging, and wakeups intact. `issue_comments` currently has no metadata column, so structured verdict detection applies to issue `metadata` writes, while comment verdict detection applies to comment body text.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small route-level gate verdict guard in `server/src/routes/issues.ts`. Define shared helper functions near the existing route utilities to detect `G_code`, `G0`, `G2`, and `G3` verdicts from `metadata.g_code/g0/g2/g3.verdict` and body text, then call the guard before `svc.update` or `svc.addComment` in both issue write routes.

**Rejected**: Move the guard into `issueService.update` only, because `POST /issues/:id/comments` can create PASS-orphan comments without calling `svc.update` unless reopening. **Rejected**: Add a sweeper/remediation job, because it would repair orphans after they are already observable instead of preventing new ones at the write boundary.

## Steps (Executor follows in order)
1. In `server/src/routes/issues.ts`, add verdict helper functions that normalize gate keys and verdict values from issue metadata and comment body text.
2. In the `PATCH /issues/:id` handler, after execution-policy transition and normalized assignee calculation but before `svc.update`, compute the effective next status, next assignee, and next `blockedByIssueIds`.
3. In that PATCH guard, reject PASS or APPROVE verdict writes unless the effective next status is `done`, returning `400` with error code `gate_verdict_requires_status_flip`.
4. In that PATCH guard, reject BLOCK verdict writes only when the effective next status is `blocked`, the effective assignee is empty, and the blocker handoff is empty, returning `400` with error code `gate_block_requires_owner_handoff`. If `blockedByIssueIds` is omitted, fetch existing blocker relations before evaluating this condition so retained blockers count as a valid handoff.
5. In the `POST /issues/:id/comments` handler, run the same verdict detection on `req.body.body` before any reopen/update side effect. Reject PASS or APPROVE comments because this route cannot set `status: done`, and apply the BLOCK owner/handoff check only when the current issue is already `blocked`.
6. Add targeted route tests in `server/src/__tests__/issue-update-comment-wakeup-routes.test.ts` for PATCH PASS rejection, PATCH PASS with `status: done` acceptance, PATCH BLOCK orphan rejection, PATCH BLOCK with omitted `blockedByIssueIds` but retained existing blockers acceptance, POST PASS rejection without reopen side effects, and a non-gate comment unaffected.
7. Hand off this KOEA-7795 implementation plan to Code Reviewer through KOEA-7810 for plan review before Executor starts implementation; after approval, Executor should implement on `origin/master`.

## Verification (QA Verifier checks these)
- [ ] `pnpm vitest run server/src/__tests__/issue-update-comment-wakeup-routes.test.ts` passes.
- [ ] PATCHing an issue with `comment: "G2 PASS"` or `metadata: { g2: { verdict: "APPROVE" } }` without `status: "done"` returns `400 gate_verdict_requires_status_flip`.
- [ ] PATCHing an issue with `comment: "G0 BLOCK"`, `status: "blocked"`, `assigneeAgentId: null`, and no submitted or existing blockers returns `400 gate_block_requires_owner_handoff`.
- [ ] POSTing `body: "G_code PASS"` to a blocked or closed issue returns `400 gate_verdict_requires_status_flip` and does not call the reopen/update path.
- [ ] Non-gate comments and non-gate issue updates keep existing behavior, activity logging, and wakeups.

## Risk
- A loose body regex could classify ordinary text as a gate verdict. Mitigation: require a recognized gate token (`G_code`, `G0`, `G2`, `G3`) and a nearby verdict token (`PASS`, `APPROVE`, `BLOCK`) rather than matching either word globally.

## Out of scope
- Backfilling or closing existing PASS/BLOCK orphan tickets.
- Adding metadata support to `issue_comments`.
- Changing execution-policy stage semantics or reviewer assignment rules beyond rejecting invalid gate-review writes.
