---
ticket: KOEA-6165
planner_task: KOEA-6172
planner: planner
agent: planner
date: 2026-05-28
type: decision
tags:
  - decision
  - engineering
estimated_complexity: medium
estimated_token_cost: $0.55
base_branch: origin/master
basebranch_verified: true
chain_authorization_comment: 23a6b9a1-ea09-4555-8de6-e0ee82e25d3d
chain_alert: 07687222-8adf-4474-9a06-afb2e3f94e2f
---

# Plan: Stop passive comment wakes from reopening done issues

## Goal
Done and cancelled issues must remain terminal when a passive comment wake is delivered after an active run has already completed the issue. Success is observable when KOEA-6129-style deferred comment wakes no longer move a `done` issue to `todo` or `in_progress`, `completedAt` stays populated, and explicit resume/reopen intent still works through the existing guarded paths.

## Context
- Files to read first: `server/src/services/heartbeat.ts:6159-6208`, `server/src/services/heartbeat.ts:1440-1465`, `server/src/services/heartbeat.ts:4749-4762`, `server/src/services/issues.ts:2900-2912`, `server/src/routes/issues.ts:190-200`, `server/src/routes/issues.ts:3363-3405`, `server/src/__tests__/heartbeat-comment-wake-batching.test.ts:603-780`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:812-870`.
- Root-cause hypothesis: `releaseIssueExecutionAndPromote` treats any deferred human comment wake on a `done` or `cancelled` issue as an implicit reopen, calls `issuesSvc.update(..., { status: "todo" })`, and `issuesSvc.update` clears `completedAt` for non-`done` statuses. The promoted run then sees `todo`, auto-checks out via `shouldAutoCheckoutIssueForWake`, and `issuesSvc.checkout` moves the issue to `in_progress`.
- Relevant prior work: existing tests already encode both sides of the policy: `heartbeat-comment-wake-batching.test.ts` currently expects passive deferred human comments to reopen, while `issue-comment-reopen-routes.test.ts` already keeps generic same-agent comments on closed issues inert and preserves explicit `resume: true`.
- Constraints: no learnova portal changes, no schema migration expected, preserve company scoping and existing explicit resume/reopen permission checks.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Make terminal reopen explicit-only. In direct issue comment/update routes, generic comments on `done` or `cancelled` issues should add communication but not change status; only explicit `resume: true` or `reopen: true` may revive work. In deferred wake promotion, only promote a closed issue wake when the deferred context carries explicit resume/reopen intent; otherwise mark that deferred wake request `skipped` with a clear reason and leave the issue terminal.

**Rejected**: Patch only `releaseIssueExecutionAndPromote` because direct human comments would still implicitly move terminal issues to `todo`, leaving another passive reopen path. **Rejected**: Disable auto-checkout for all `issue_commented` wakes because that would regress legitimate open `todo`/`blocked` follow-up workflows instead of fixing the terminal-state boundary.

## Steps (Executor follows in order)
1. Update `server/src/routes/issues.ts` so `shouldImplicitlyMoveCommentedIssueToTodo` no longer returns true for `done` or `cancelled`; keep any desired implicit behavior scoped to `blocked` issues with no unresolved first-class blockers.
2. Update `server/src/services/heartbeat.ts` around deferred wake promotion so `shouldReopenDeferredCommentWake` requires explicit intent, such as `wakeReason === "issue_reopened_via_comment"` or `resumeIntent/followUpRequested === true`, and never treats `requestedByActorType === "user"` alone as reopen intent.
3. In the same promotion loop, when the issue is terminal and the deferred wake lacks explicit reopen intent, mark that `agent_wakeup_requests` row `skipped` with `finishedAt`, `updatedAt`, and a reason like `terminal_issue_passive_comment_wake`; do not create a heartbeat run or mutate the issue.
4. Update `server/src/__tests__/heartbeat-comment-wake-batching.test.ts` so the passive deferred human comment case asserts the issue remains `done`, `completedAt` remains non-null, and the deferred wake is skipped or otherwise not promoted into a second execution run.
5. Add or update a positive regression in `server/src/__tests__/heartbeat-comment-wake-batching.test.ts` proving an explicit resume/reopen deferred context still reopens and promotes exactly once.
6. Update `server/src/__tests__/issue-comment-reopen-routes.test.ts` expectations for generic human comments on closed issues: no `svc.update`, no assignee wake, comment still persists; keep explicit `resume: true` and authorized `reopen: true` tests passing.
7. Run `pnpm test -- server/src/__tests__/heartbeat-comment-wake-batching.test.ts server/src/__tests__/issue-comment-reopen-routes.test.ts` first; if the repo test runner does not accept file filters, run the equivalent targeted Vitest command used elsewhere in this repo.

## Verification (QA Verifier checks these)
- [ ] A deferred `issue_commented` wake created by a human while an active run is running does not reopen the issue after that run marks it `done`; stored status stays `done` and `completedAt` stays non-null.
- [ ] A generic POST or PATCH comment on an assigned `done` issue persists the comment but does not call `svc.update({ status: "todo" })` and does not queue an assignee wake.
- [ ] Explicit `resume: true` or authorized `reopen: true` still reopens eligible `done` issues and queues the assignee with resume/reopen metadata.

## Risk
- Risk: suppressing passive deferred wakes may hide a legitimate human follow-up after an issue was completed. Mitigation: require the UI/API caller to send explicit `resume: true` or `reopen: true`, preserve the comment itself on the issue, and record skipped deferred wakes with a reason for audit visibility.

## Out of scope
- No database migration, no learnova content or deployment changes, no rewrite of the broader heartbeat scheduler, and no changes to dependency-blocked issue semantics beyond preserving blocked-issue guards.
