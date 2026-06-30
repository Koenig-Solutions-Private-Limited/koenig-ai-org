---
ticket: KOEA-5155
planner: planner
planner_ticket: KOEA-5249
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
preflight: status=todo; sibling_chain_alert=9c1b1ea5-a4e0-43a4-9b12-a8aa990182cc approved; acceptance=deliverable-concrete
---

# Plan: Fix Watchdog cross-issue comment auth gap

## Goal
Watchdog Bot can post escalation-marker nudges as same-company issue comments on issues it does not own without receiving `403 Agent cannot mutate another agent's issue`. Success is narrowly comment-only: assignment, status, documents, attachments, active checkout ownership, explicit resume/reopen, interrupt behavior, and cross-company boundaries remain unchanged.

## Context
- Files to read first: `server/src/routes/issues.ts:601-669`, `server/src/routes/issues.ts:3361-3495`, `server/src/services/issues.ts:3189-3265`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:379-499`, `packages/shared/src/constants.ts:504-514`, `ui/src/pages/CompanyAccess.tsx:30-39`, `packages/db/watchdog_run_safe.mjs:49-87`.
- Relevant prior work: `vault/decisions/KOEA-4875-plan.md`, which diagnosed the same cross-assignee comment gap and chose a narrow permissioned comment path.
- Constraints: keep company access checks in `assertCompanyAccess`; do not use board credentials for Watchdog; do not weaken active checkout mutation ownership; no schema migration should be needed because `principal_permission_grants.permission_key` is text; verified base branch is `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a narrow agent grant for cross-assignee issue comments and wire it only into `POST /api/issues/:id/comments`. Refactor the existing agent issue mutation guard so a same-company agent with the new permission can create a plain observer comment on another assigned issue, while the same grant cannot patch issues, upload/delete attachments, update documents, interrupt active runs, or request resume/reopen. This is the smallest compliant fix because it reuses the existing comment route's author attribution, wake/reference sync, activity logging, and company boundary enforcement.

**Rejected**: Give Watchdog a board API key - too broad and bypasses the agent permission model; create a dedicated Watchdog comment endpoint - duplicates existing comment route behavior and adds unnecessary API surface.

## Steps (Executor follows in order)
1. Add `issue.comments:create_cross_assignee` to `PERMISSION_KEYS` in `packages/shared/src/constants.ts` and add a label such as `Comment on assigned tasks` in `ui/src/pages/CompanyAccess.tsx`.
2. Refactor `assertAgentIssueMutationAllowed` in `server/src/routes/issues.ts` to accept an option for comment-only cross-assignee observer writes; keep current behavior as the default for all existing mutation callers.
3. In `POST /api/issues/:id/comments`, reject observer-grant use when `resume`, `reopen`, or `interrupt` is present, then call the refactored guard with the comment-only option before `svc.addComment`.
4. Extend `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` with positive coverage for a granted peer agent posting a plain comment to another same-company assignee's issue and negative coverage proving the same grant cannot patch, update documents/attachments, interrupt, resume/reopen, or comment cross-company.
5. Update `packages/db/watchdog_run_safe.mjs` so approval backlog, marker compliance, stale blocked, and Watchdog Health paths try direct issue comments with duplicate/cooldown checks, then fall back to the existing issue-creation alert path when the comment write is rejected.
6. In the Executor handoff or PR body, note that no additional CEO/board authorization is required before implementation, but after deployment an operator must grant `issue.comments:create_cross_assignee` only to Watchdog Bot before direct nudges can succeed.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run --project @paperclipai/server server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts --pool=forks --poolOptions.forks.isolate=true` passes.
- [ ] A Watchdog-agent API request with `issue.comments:create_cross_assignee` can `POST /api/issues/:id/comments` on another same-company assignee's issue, and the stored row has Watchdog Bot as `authorAgentId`.
- [ ] The same Watchdog-agent API key still receives the existing `403` or `409` behavior for issue PATCH, document/attachment mutation, interrupt, resume/reopen, and any other company's issue.

## Risk
- A route-level permission could accidentally become broad mutation authority. Mitigate by making the grant usable only inside the comment POST route, explicitly rejecting `resume`/`reopen`/`interrupt`, and adding negative tests around every non-comment mutation already covered by the ownership suite.

## Out of scope
- This plan does not redesign Watchdog scheduling, add enterprise RBAC, migrate existing grants, auto-grant permissions to Watchdog Bot, or change active-run watchdog decision authorization.
