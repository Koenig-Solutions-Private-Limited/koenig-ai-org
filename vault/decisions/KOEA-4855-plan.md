---
ticket: KOEA-4855
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: master
basebranch_verified: true
chain_authorization_comment: 1d365284-3248-4ca8-8f6f-345e308c8869
revision: 2
revision_reason: G_code requested guardrail, route-target, permission-key, cross-company, and operational-grant clarifications
---

# Plan: Watchdog cross-issue alert comments

## Goal
Watchdog Bot must be able to post stale-blocked, approval-age, and marker-compliance alert comments on non-owned same-company issues without getting `403 Agent cannot mutate another agent's issue`. Success is an explicit least-privilege route through Paperclip core that permits comments only, preserves company boundaries and the watchdog's existing 4h dedupe behavior, and avoids granting broader issue mutation powers.

This requires Paperclip core code changes. Executor may write core code only after KOEA-4884 plan review approves this plan; the production permission grant for Watchdog Bot should be applied separately by a board/Chief Engineering operator after code review and QA.

## Context
- Files to read first: `server/src/routes/issues.ts:601-650`, `server/src/routes/issues.ts:3361-3469`, `server/src/services/issues.ts:3505-3540`, `packages/shared/src/constants.ts:504-514`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:379-499`, `scripts/slide-fake-done-auditor.py:132-143`, `scripts/slide-fake-done-auditor.py:163-170`, `scripts/slide-fake-done-auditor.py:486-491`.
- Relevant prior work: KOEA-4855 observed `POST /api/issues/<target>/comments -> 403` when Watchdog Bot comments on another agent's issue; KOEA-4883 chain authorization comment `1d365284-3248-4ca8-8f6f-345e308c8869` says this Planner -> Review -> Implement -> G_code -> G2 sequence is expected.
- Constraints: company boundary must remain enforced by `assertCompanyAccess`; the new permission key is exactly `tasks:comment_cross_assignee_alerts`; `tasks:manage_active_checkouts` is too broad; the watchdog's local 4h cooldown in `scripts/slide-fake-done-auditor.py` must continue to suppress repeated alert comments.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a new explicit permission key, exactly `tasks:comment_cross_assignee_alerts`, and teach only the issue comment route to honor it for same-company agent-authored comments. The helper must require `req.actor.type === "agent"` and a non-null `req.actor.agentId` before permission lookup, then rely on the already-fetched `issue.companyId` after `assertCompanyAccess(req, issue.companyId)`. Keep all other issue mutations, document writes, attachments, deletes, status changes, and active-checkout management behind the existing ownership rules. This is the smallest core change that preserves existing comment creation, activity logging, reference syncing, and agent-authored comment semantics while giving Watchdog Bot an auditable grant.

**Rejected**: Grant Watchdog Bot `tasks:manage_active_checkouts` because it also permits broad mutations on other agents' active work; route Watchdog through plugin `issue.comments.create` because that host service bypasses the public REST ownership guard and would require turning an operational watchdog script into a plugin; use a board token/service account directly because it hides the agent identity and weakens audit attribution.

## Steps (Executor follows in order)
1. Add `tasks:comment_cross_assignee_alerts` to `PERMISSION_KEYS` in `packages/shared/src/constants.ts`, relying on the existing text-backed `principal_permission_grants.permission_key` column so no DB migration is needed.
2. In `server/src/routes/issues.ts`, add a comment-only helper that first checks `req.actor.type === "agent"` and `req.actor.agentId` is non-null, then calls `access.hasPermission(issue.companyId, "agent", req.actor.agentId, "tasks:comment_cross_assignee_alerts")`; do not allow board/user auth through this helper.
3. Change only `router.post("/issues/:id/comments", ...)` to allow the helper before calling the generic `assertAgentIssueMutationAllowed`; leave `PATCH /api/issues/:id`, `PUT /api/issues/:id/documents/:key`, delete, attachment, and work-product routes unchanged.
4. Preserve current comment behavior after authorization: call `svc.addComment`, sync issue references, log `issue.comment_added`, report run activity, and do not implicitly reopen because the author is an agent.
5. Extend `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts`: add one positive case for a granted peer agent using `POST /api/issues/:id/comments`; add exact negative cases for `PATCH /api/issues/:id` and `PUT /api/issues/:id/documents/:key`; preserve the existing non-granted peer comment `403`; add a cross-company deny case proving a grant does not bypass `assertCompanyAccess`.
6. Update `scripts/slide-fake-done-auditor.py` only if needed to remove the preflight `can_comment` skip for Watchdog-owned alert targets after the permission exists; keep `COOLDOWN_SECONDS = 60 * 60 * 4` and existing `comment:<issue>:<kind>` cooldown keys intact.
7. Document the operational follow-up in the Executor handoff comment and implementation ticket: board/Chief Engineering must verify a `tasks:comment_cross_assignee_alerts` principal grant exists for Watchdog Bot in company `2a77f89b-33f0-4133-a20c-77ddaac5e744` before rerunning KOEA-4852.

## Verification (QA Verifier checks these)
- [ ] `pnpm test:run -- server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` or the repo's nearest supported targeted Vitest command passes with the new authorization cases.
- [ ] A non-granted peer agent still receives `403 Agent cannot mutate another agent's issue` for `POST /api/issues/:id/comments` on another assignee's non-`in_progress` issue.
- [ ] A granted agent from another company cannot comment on or mutate the target issue; the existing company-access guard still returns the appropriate deny/not-found response before the comment-only permission can apply.
- [ ] A granted Watchdog Bot agent can post a comment to a non-owned same-company issue, and the response/activity record keeps `authorAgentId` as the watchdog agent.
- [ ] The same granted Watchdog Bot agent still cannot `PATCH /api/issues/:id` or `PUT /api/issues/:id/documents/:key` solely from this new permission.
- [ ] `scripts/slide-fake-done-auditor.py` still uses a 4h cooldown before repeat restore/verify alert comments.
- [ ] Before KOEA-4852 rerun, board/Chief Engineering verifies the Watchdog Bot principal grant for `tasks:comment_cross_assignee_alerts` exists in company `2a77f89b-33f0-4133-a20c-77ddaac5e744`.

## Risk
- A comment-only grant still changes issue `updatedAt`, which can affect recency and liveness views. Mitigation: keep the grant limited to Watchdog Bot, preserve the 4h cooldown, and do not use this permission for broad status or document mutation.

## Out of scope
- Replacing Watchdog Bot with a plugin, adding server-side alert dedupe tables, granting production permissions automatically, or changing broader issue ownership semantics outside `POST /api/issues/:id/comments`.
