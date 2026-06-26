---
ticket: KOEA-5817
planning_ticket: KOEA-5820
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: master
basebranch_verified: true
approval_authorization: 6f518b47-f2fa-415a-9736-9590fc1650f1
---

# Plan: Guard deferred comment wakes from reopening reconciled done issues

## Goal
Stop `deferred_comment_wake` promotion from reopening a completed issue when the deferred comment has already been superseded by the assignee's closure or reconciliation comment. Success means stale/self-reconciliation comment wakes may still be delivered as context when appropriate, but they no longer mutate `done` or `cancelled` issues back to `todo` or `in_progress` unless there is a still-current external or explicit resume/reopen signal.

## Context
- Files to read first: `server/src/services/heartbeat.ts:6159-6208`, `server/src/services/heartbeat.ts:6880-6938`, `server/src/services/heartbeat.ts:1495-1614`, `server/src/routes/issues.ts:185-201`, `server/src/routes/issues.ts:2572-2604`, `server/src/__tests__/heartbeat-comment-wake-batching.test.ts:603-987`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:812-868`, `packages/db/src/schema/issue_comments.ts:7-35`.
- Relevant prior work: KOEA-5391 activity and comments show repeated `issue.updated` system events with `details.source=deferred_comment_wake` and `reopenedFrom=done` after human reconciliation comments were followed by assignee closure comments.
- Constraints: no production code in this plan stage; keep the patch inside Paperclip core heartbeat behavior; do not change public API contracts or database schema; preserve explicit human resume/reopen behavior.
- Governance: this implementation touches Paperclip core server code and tests, not vault/course content. Chief Engineering approved the chain alert `6f518b47-f2fa-415a-9736-9590fc1650f1`; `origin/master` was verified as the actual base branch because `origin/main` is absent in this checkout.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a promotion-time freshness guard in `server/src/services/heartbeat.ts`. Before setting `shouldReopenDeferredCommentWake`, load the deferred wake comment rows and the latest issue comment. Reopen only when the deferred wake is still externally actionable: either the latest relevant comment is one of the deferred user comments, or the wake reason is an explicit `issue_reopened_via_comment` / resume signal that has not been superseded by a later assignee-authored comment. If the latest comment after the deferred comment is by the assignee or by the same run that closes/reconciles the issue, promote without reopening and without logging `source=deferred_comment_wake`.
**Rejected**: Change comment route reopen semantics only, because KOEA-5391 is caused during deferred wake promotion after the comment route has already created the wake. **Rejected**: Suppress all deferred comment promotions for closed issues, because legitimate human comments made during an active run still need to wake the assignee after the run finishes.

## Steps (Executor follows in order)
1. Inspect `server/src/services/heartbeat.ts` around deferred promotion and add a small helper near `extractWakeCommentIds` that decides whether deferred comment ids remain reopen-worthy for the current issue status, assignee, requester, and latest comment.
2. In the deferred promotion transaction, query `issue_comments` for the deferred ids plus the latest comment on the issue before computing `shouldReopenDeferredCommentWake`.
3. Replace the current boolean at `server/src/services/heartbeat.ts:6163-6169` with the helper result, preserving existing reopen behavior for current human comments and explicit resume/reopen wakes.
4. Ensure suppressed stale wakes do not set `promotedContextSeed.reopenedFrom`, do not call `issuesSvc.update(... status: "todo")`, and do not create the `issue.updated` activity with `source: "deferred_comment_wake"`.
5. Add a regression test to `server/src/__tests__/heartbeat-comment-wake-batching.test.ts` that reproduces KOEA-5391: user deferred comment, later assignee closure/reconciliation comment, issue set `done`, deferred promotion occurs, final issue remains `done`.
6. Keep the existing test for active-run human follow-up reopening after close, updating expectations only if the helper needs a clearer fixture boundary.
7. Run targeted verification, then leave broader typecheck/build to PR handoff if targeted checks pass.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run server/src/__tests__/heartbeat-comment-wake-batching.test.ts -t "does not reopen"` passes, including the new KOEA-5391 regression.
- [ ] `pnpm exec vitest run server/src/__tests__/heartbeat-comment-wake-batching.test.ts -t "promotes deferred comment wakes after the active run closes the issue"` still passes.
- [ ] Manual or test inspection confirms no `issue.updated` activity with `details.source="deferred_comment_wake"` is written when the assignee closure comment supersedes the deferred user comment.

## Risk
- Freshness rules could accidentally suppress a legitimate user follow-up if ordered comments are ambiguous. Mitigation: base the guard on stored `issue_comments.created_at` and authorship, and retain the existing reopen path when the newest relevant comment is still user-authored or explicitly marked resume/reopen.

## Out of scope
- This plan does not redesign deferred wake coalescing, change comment route semantics, add schema fields, or alter agent instruction text.
