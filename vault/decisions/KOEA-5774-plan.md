---
ticket: KOEA-5774
planner: planner
planner_ticket: KOEA-5790
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: master
basebranch_verified: true
preflight: status=in_progress; sibling_chain_alert=d904a626-85fd-4e47-8b2f-7eab24938a80 approved; acceptance=deliverable-concrete
allowed_worktree: /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org
---

# Plan: Fix watchdog comment permission routing

## Goal
Watchdog Bot can leave same-company operational nudges on issues it observes but does not own without receiving `403 Agent cannot mutate another agent's issue`. Success is explicitly comment-only: the fix must not let Watchdog change status, assignment, documents, attachments, active checkouts, approval decisions, or other companies' issues.

## Context
- Files to read first: `server/src/routes/issues.ts:601-669`, `server/src/routes/issues.ts:3361-3470`, `server/src/routes/approvals.ts:136-144`, `packages/shared/src/constants.ts:504-514`, `ui/src/pages/CompanyAccess.tsx:30-39`, `packages/db/watchdog_run.mjs:58-82`, `packages/db/watchdog_run_safe.mjs:49-87`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:485-499`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:483-510`.
- Relevant prior work: `vault/decisions/KOEA-4875-plan.md` and `vault/decisions/KOEA-5155-plan.md` both diagnosed this same cross-assignee comment guard and chose a narrow permissioned comment route; KOEA-5774 is the explicit governance ticket authorizing this engineering chain through review gates, not a direct Chief edit.
- Constraints: keep `assertCompanyAccess` as the company boundary; do not give Watchdog board identity; do not reuse `tasks:manage_active_checkouts`; do not broaden approval resolution, which is currently board-only in `server/src/routes/approvals.ts:136-144`; base branch verified as `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a narrow cross-assignee issue-comment permission and make Watchdog degrade safely. Refactor the existing issue mutation guard so only `POST /api/issues/:id/comments` can use a new same-company `issue.comments:create_cross_assignee` grant for plain observer comments, with `resume`, `reopen`, and `interrupt` rejected under that grant. Then update the Watchdog scripts to prefer direct comments when authorized and fall back to deterministic Watchdog-owned/recovery issues when direct comments are forbidden.

**Rejected**: Board API key for Watchdog - too broad and poor attribution; dedicated Watchdog-only comment endpoint - duplicates wake/reference/activity behavior already in the comment route; broaden approval approve/reject to Chief Engineering agents - adjacent governance issue, but separate from watchdog comment routing and would exceed this ticket's least-privilege scope.

## Steps (Executor follows in order)
1. Add `issue.comments:create_cross_assignee` to `PERMISSION_KEYS` in `packages/shared/src/constants.ts` and add the label in `ui/src/pages/CompanyAccess.tsx`.
2. Refactor `assertAgentIssueMutationAllowed` in `server/src/routes/issues.ts` to accept a comment-only observer option; keep the default behavior unchanged for PATCH, documents, attachments, work products, checkout, and all non-comment mutation routes.
3. In `POST /api/issues/:id/comments`, reject observer-grant use when `resume`, `reopen`, or `interrupt` is present, then call the refactored guard with the comment-only option before `svc.addComment`.
4. Update `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` and `server/src/__tests__/issue-comment-reopen-routes.test.ts` to cover: granted same-company peer can post a plain comment; ungranted peer still gets the existing `403`/`409`; the grant cannot patch, resume/reopen, interrupt, or mutate cross-company.
5. Update `packages/db/watchdog_run.mjs` and `packages/db/watchdog_run_safe.mjs` so marker-compliance, stale-blocked, pending-approval, and Watchdog Health summaries attempt duplicate-cooled direct comments first, then fall back to the current Watchdog-owned alert/recovery issue path when comment posting is rejected.
6. In the Executor handoff or PR body, state the operational rollout: after deployment, the board grants `issue.comments:create_cross_assignee` only to Watchdog Bot; rollback is removing that grant and reverting the route/script changes.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run --project @paperclipai/server server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts server/src/__tests__/issue-comment-reopen-routes.test.ts --pool=forks --poolOptions.forks.isolate=true` passes.
- [ ] A Watchdog-agent API key with `issue.comments:create_cross_assignee` can `POST /api/issues/:id/comments` on another same-company assignee's issue, and the stored comment has Watchdog Bot as `authorAgentId`.
- [ ] The same Watchdog-agent API key still cannot `PATCH /api/issues/:id`, use comment `resume`/`reopen`/`interrupt`, mutate documents/attachments, manage active checkouts, resolve approvals, or access another company.
- [ ] A dry-run or local invocation of the Watchdog script shows direct-comment attempts use duplicate markers and forbidden direct comments fall back to Watchdog-owned alert/recovery issues instead of crashing the heartbeat.

## Plan-Reviewer checklist
- [ ] The plan stays within KOEA-5774 scope and does not authorize a board-equivalent agent approval resolver.
- [ ] The new permission is route-specific and comment-only, not a generic issue mutation grant.
- [ ] Company scoping remains enforced before any permission exception.
- [ ] Watchdog failure behavior is observable: rejected direct comments create or update a fallback issue rather than silently disappearing.
- [ ] Verification includes both positive permission coverage and negative least-privilege coverage.

## Risk
- The main risk is accidentally converting observer comments into broad same-company mutation authority. Mitigate by making the new permission usable only in the comment POST path, rejecting comment actions that imply status/run changes, and adding negative route tests around all adjacent mutation surfaces.

## Out of scope
- This plan does not redesign Watchdog scheduling, auto-grant permissions, migrate existing grants, alter enterprise RBAC, or let Chief Engineering agents approve/reject board-gated approvals through `/api/approvals/:id/approve`.
