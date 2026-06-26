---
ticket: KOEA-5490
planning_ticket: KOEA-5496
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.34
base_branch: master
basebranch_verified: true
revision: 2
revised_at: 2026-05-27T06:12:00Z
---

# Plan: Watchdog cross-issue comment permission fix

## Goal
Restore Watchdog Bot's ability to post company-scoped operational nudges on issues it observes but does not own. Success means a same-company agent with an explicit comment-only grant can `POST /api/issues/{id}/comments` on another assigned issue without gaining broader mutation powers, while cross-company agent keys still get rejected.

## Context
- Files to read first: `server/src/routes/issues.ts:601-636`, `server/src/routes/issues.ts:3361-3425`, `packages/shared/src/constants.ts:504-514`, `ui/src/pages/CompanyAccess.tsx:30-38`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:382-499`, `scripts/slide-fake-done-auditor.py:132-142`, `scripts/koenig-cron-driver.py:175-179`.
- Relevant prior work: KOEA-5490 parent evidence says Watchdog detected 65 required marker-compliance/stale-ticket nudges but received HTTP 403 from `POST /api/issues/{id}/comments`; KOEA-5497 review comment `4a93dd8a-a76e-4936-a2a9-f4986f6dc67c` rejected implementation drift into triage backlog routing.
- Constraints: no implementation until plan-review passes and Chief Engineering dispatches Executor; this touches Paperclip core permission behavior, so keep the grant company-scoped, auditable, and comment-only. Base branch verified with `git ls-remote --heads origin master`.
- Current drift to remove before implementing: local diff adds `isTriageRoutingAgent()`, a backlog assignee-change bypass, and a triage routing test. Those changes are unrelated to KOEA-5490 and must not ship under this ticket.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add an explicit comment-only permission grant, for example `issues:comment_any`, and route only plain issue-comment creation through it. Keep `assertCompanyAccess(req, issue.companyId)` as the company boundary, add a helper such as `hasAnyIssueCommentGrant(actorAgentId, companyId)`, and in the POST comment route allow non-assignee agents with that grant to add a comment without passing the broader `assertAgentIssueMutationAllowed` path. Preserve existing resume/reopen/interrupt gates so this grant cannot move blocked/done work to `todo`, interrupt runs, change assignees, upload attachments, edit documents, update issues, or manage active checkouts.

**Rejected**: Reuse `tasks:manage_active_checkouts` for Watchdog, because that existing grant intentionally allows broad intervention in active work and would over-authorize a monitoring bot. **Rejected**: Treat `tasks:assign` or `agents:create` as implicit comment-any permission, because Watchdog happens to have those grants today but many other agents may also have them for delegation and should not automatically gain cross-issue comment authority.

## Steps (Executor follows in order)
1. Remove any KOEA-5490 branch/worktree drift that adds triage backlog-routing behavior: delete `isTriageRoutingAgent()`, the backlog assignee-change bypass in `PATCH /issues/:id`, and the triage routing test fixture/case. This ticket is only about cross-issue comments.
2. Add a new permission key such as `issues:comment_any` to `packages/shared/src/constants.ts` and add its human-readable label in `ui/src/pages/CompanyAccess.tsx`; no database migration should be needed because `principal_permission_grants.permission_key` is text and shared validators derive from `PERMISSION_KEYS`.
3. In `server/src/routes/issues.ts`, add a small helper near `hasActiveCheckoutManagementOverride()` that calls `access.hasPermission(companyId, "agent", actorAgentId, "issues:comment_any")` after `assertCompanyAccess` has established the route issue's company boundary.
4. Refactor only `router.post("/issues/:id/comments")` so agent callers pass if they either satisfy existing `assertAgentIssueMutationAllowed()` or have `issues:comment_any`; keep `PATCH /issues/:id`, document routes, work-product routes, attachment routes, and checkout/assignment paths on the existing ownership/checkout checks.
5. In the comment route, ensure `issues:comment_any` permits only inert comments: reject or fall back to existing owner/manager checks when `resume`, `reopen`, or `interrupt` is requested, and keep board-only interrupt behavior unchanged.
6. Add focused route tests in `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts`: grant allows peer agent POST comments on another assigned todo/in-progress issue; the same grant still rejects patch/document/work-product/attachment mutation and assignee changes; no grant still 403/409s as today; cross-company actor still 403s via `assertCompanyAccess`.
7. After code review approval, have Chief Engineering or an authorized operator grant `issues:comment_any` to Watchdog Bot (`55ec4a3a-7c32-4436-a231-e0accd51a548`) through the existing company access grant path; do not bake this company-specific grant into route logic.

## Verification (QA Verifier checks these)
- [ ] `PAPERCLIP_HOME=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/.paperclip pnpm exec vitest run server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` passes and includes the comment-only grant cases.
- [ ] A same-company agent with `issues:comment_any` can `POST /api/issues/{id}/comments` on another assigned issue and the activity row remains `issue.comment_added`.
- [ ] The same agent cannot `PATCH /api/issues/{id}`, change assignees, update issue documents/work products, upload/delete attachments, set `resume: true`, set `reopen: true`, or set `interrupt: true` on another agent's issue using only this grant.
- [ ] An agent key from a different company still receives 403 before comment insertion.
- [ ] `git diff -- server/src/routes/issues.ts server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` contains no triage backlog-routing bypasses.
- [ ] Watchdog Bot has an active `issues:comment_any` grant after deployment before the live watchdog lane is considered fixed.

## Risk
- A new permission key fixes the authorization model but not the live bot until the grant is assigned. Mitigation: make grant assignment an explicit post-review deployment step and verify the Watchdog Bot's principal grants before closing KOEA-5490.

## Out of scope
- Do not grant Watchdog broad active-checkout management, cross-company access, document/work-product mutation, attachment mutation, or run interruption authority.
- Do not rewrite watchdog scripts beyond optional follow-up cleanup of `can_comment()` heuristics after the server authorization is fixed.
- Do not start implementation until plan-review passes and Chief Engineering dispatches Executor.

## Pre-flight
- ticket_status_checked=true
- assignee_verified=true
- chain_depth_authorized=true
- sibling_count=1
- acceptance_spec_checked=true
- basebranch_verified=true
- review_feedback_addressed=KOEA-5497:4a93dd8a-a76e-4936-a2a9-f4986f6dc67c
