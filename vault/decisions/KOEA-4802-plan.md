---
ticket: KOEA-4802
planner: planner
agent: planner
date: 2026-05-27
type: decision
tags:
  - decision
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
---

# Plan: Watchdog health comments can post cross-issue without broad mutation

## Goal
Fix the Watchdog health-comment path so the Watchdog agent can post required health nudges on same-company issues it does not own. Success means the current `403 Agent cannot mutate another agent's issue` case passes only for the allowed comment endpoint, while ordinary non-assignee agent mutations still fail.

## Context
- Files to read first: `server/src/routes/issues.ts:595-635`, `server/src/routes/issues.ts:3348-3357`, `packages/shared/src/constants.ts:504-514`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:358-454`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:483-510`, `scripts/mint-watchdog-token.sh:22-36`.
- Relevant prior work: KOEA-4844 planned this fix but the required vault document was missing; branch `koea-4885/watchdog-comment-alert-path` contains closely related commits `86053cff4`, `7bb564ca3`, and `b7e37c8d4` for a dedicated cross-assignee alert-comment permission and boundary tests.
- Constraints: preserve company scoping before any grant check, preserve agent API-key tenant boundaries, do not grant broad issue mutation rights, and keep the exception limited to POST `/api/issues/:id/comments`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a dedicated cross-assignee health-comment permission and check it only inside the POST issue-comment route after `assertCompanyAccess`. The route should bypass `assertAgentIssueMutationAllowed` only for agents with that same-company grant, then continue through the existing closed-workspace, blocker, resume, activity, and comment creation logic. This keeps the change small, auditable, and narrower than checkout or task mutation authority.

**Rejected**: Grant Watchdog `tasks:manage_active_checkouts`, because it would permit broader active-checkout intervention than health comments require; route Watchdog through board tokens or Watchdog-owned meta issues only, because that is an operational workaround and does not fix the cross-issue health-comment API contract.

## Steps (Executor follows in order)
1. Add a new `PermissionKey` in `packages/shared/src/constants.ts`, for example `tasks:comment_cross_assignee_health`, with no database migration because `principal_permission_grants.permission_key` is already data-driven.
2. In `server/src/routes/issues.ts`, add a helper near `assertAgentIssueMutationAllowed` that returns true only for agent actors with the new grant in `issue.companyId`.
3. Update POST `/api/issues/:id/comments` in `server/src/routes/issues.ts` so it calls `assertCompanyAccess(req, issue.companyId)` before the grant helper, then skips `assertAgentIssueMutationAllowed` only when the helper returns true.
4. Do not apply the new helper to PATCH `/api/issues/:id`, document writes, work products, attachments, checkout, status updates, or explicit `resume: true` behavior.
5. Extend `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` with positive coverage for a granted same-company peer agent posting a comment across assignees and negative coverage proving the same grant cannot patch, upsert documents, or cross company boundaries.
6. Keep existing non-assignee POST/PATCH comment rejection coverage in `server/src/__tests__/issue-comment-reopen-routes.test.ts`; add assertions there only if route behavior changes around closed or resume comments.
7. In the PR handoff, call out that the live Watchdog Bot still needs the new grant assigned by board/CEO tooling; do not hardcode the KOEA company id or Watchdog agent id into server code.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts server/src/__tests__/issue-comment-reopen-routes.test.ts` passes.
- [ ] A same-company agent with `tasks:comment_cross_assignee_health` can POST `/api/issues/:id/comments` on another agent's non-`in_progress` issue and `issueService.addComment` is called.
- [ ] The same granted agent still receives 403 for PATCH `/api/issues/:id`, issue documents, work products, attachments, and any cross-company comment attempt.
- [ ] An ungranted non-assignee agent still receives `403 Agent cannot mutate another agent's issue` for the current failing comment path.

## Risk
- Risk: a too-broad bypass could let Watchdog mutate or reopen work it does not own. Mitigation: put the bypass only in the POST comment route, after company access enforcement, and cover negative route tests for PATCH, documents, attachments, and cross-company access.

## Out of scope
- Building a general RBAC UI for every permission key, changing Watchdog daemon scheduling logic, using board tokens for routine health comments, or granting Watchdog broader task assignment, checkout, pause, or issue update authority.

## Pre-flight
- status_checked=true
- sibling_chain_checked=true
- acceptance_checked=true
- basebranch_verified=true (`origin/master`)
