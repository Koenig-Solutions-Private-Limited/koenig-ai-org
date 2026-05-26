---
ticket: KOEA-4875
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
preflight: status=in_progress; sibling_chain_alert=28885fd2-62bc-492d-b693-0494aaebb663 resolved by Chief Engineering; acceptance=deliverable-concrete
---

# Plan: Sanction watchdog cross-issue comment alerts

## Goal
Watchdog Bot can post same-company observer alerts on issues it does not own without receiving `403 Agent cannot mutate another agent's issue`. Success is comment-only: watchdog nudges and health digests become durable issue comments while issue assignment, status, documents, attachments, active checkout ownership, and cross-company boundaries remain unchanged.

## Context
- Files to read first: `server/src/routes/issues.ts:601-669`, `server/src/routes/issues.ts:3361-3620`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:379-499`, `packages/shared/src/constants.ts:504-514`, `ui/src/pages/CompanyAccess.tsx:30-39`, `packages/db/watchdog_run_safe.mjs:49-87`
- Relevant prior work: [KOEA-4780](/KOEA/issues/KOEA-4780) parent triage; resolved `planner_chain_alert` `28885fd2-62bc-492d-b693-0494aaebb663`
- Constraints: same-company enforcement must remain; do not grant broad board identity or active-checkout management; no schema migration should be needed because `principal_permission_grants.permission_key` is text; base branch verified as `origin/master`

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a narrow principal permission for cross-assignee issue comments, then wire it only into `POST /api/issues/:id/comments`. Extend the existing route guard so an agent with the new grant may create a plain comment on another same-company agent's issue, but may not use that grant for PATCH/DELETE/document/work-product/attachment mutations, active-run interruption, explicit resume/reopen, or cross-company access. Update the watchdog script to attempt direct comments with existing fallback issue creation when the permission is absent.

**Rejected**: Board-scoped Watchdog API key - works quickly but gives the watchdog broad board authority and hides the observer-specific policy boundary; dedicated watchdog-only service endpoint - safer than board keys, but duplicates comment wake/reference behavior already implemented in the issue comment route and adds more API surface than needed.

## Steps (Executor follows in order)
1. Add `issue.comments:create_cross_assignee` to `PERMISSION_KEYS` in `packages/shared/src/constants.ts` and add the corresponding human-readable label in `ui/src/pages/CompanyAccess.tsx`.
2. Refactor `assertAgentIssueMutationAllowed` in `server/src/routes/issues.ts` to accept a mutation kind or option, and allow the new permission only for `POST /api/issues/:id/comments` when the actor and target issue are in the same company.
3. In the comment route, reject cross-assignee observer comments that set `resume`, `reopen`, or `interrupt`, then call the refactored guard with the comment-only option before `svc.addComment`.
4. Add route tests in `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` covering: granted peer agent can post a comment on a non-owned todo/blocked issue; the same grant cannot patch/update documents/attachments; ungranted peer agents still get the existing 403/409 behavior.
5. Update `packages/db/watchdog_run_safe.mjs` so approval >48h, marker-compliance, stale-blocked, and Watchdog Health paths attempt direct issue comments with duplicate-marker cooldowns, falling back to current watchdog issue creation when the comment write is rejected.
6. Leave an operational note in the implementation handoff or PR body: after deployment, the board must grant `issue.comments:create_cross_assignee` only to Watchdog Bot before expecting cross-issue nudges to post directly.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run --project @paperclipai/server server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts --pool=forks --poolOptions.forks.isolate=true` passes and shows the new grant is comment-only.
- [ ] A Watchdog-agent API request with the new grant can `POST /api/issues/:id/comments` to another same-company agent's issue, and the stored comment has `authorAgentId` set to Watchdog Bot.
- [ ] The same Watchdog-agent API key still cannot `PATCH /api/issues/:id`, upload/delete attachments, update documents, interrupt active runs, or mutate issues from another company.

## Risk
- The biggest risk is accidentally turning an observer comment grant into broad issue mutation. Mitigate by making the permission check route-specific, explicitly rejecting `resume`/`reopen`/`interrupt` under this path, and adding negative tests for non-comment mutations.

## Out of scope
- This plan does not redesign Watchdog scheduling, add enterprise RBAC, migrate existing grants, or change active-run watchdog decision authorization.
