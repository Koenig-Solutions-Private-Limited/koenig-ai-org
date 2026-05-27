---
ticket: KOEA-5278
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: master
approval: a03551a3-fea4-49bc-9303-8a9a326fade3
---

# Plan: Fix deferred comment wake status drift

## Goal
Stop deferred comment wake promotion from reviving intentionally terminal or blocked recovery issues unless the wake represents explicit reopen intent from the owner or board. Success means KOEA-5161-style human reconciliation comments can be recorded without repeatedly returning a done/blocked issue to active execution, while legitimate explicit resume/reopen comments still wake the assignee.

## Context
- Files to read first: `server/src/services/heartbeat.ts:6123-6210`, `server/src/routes/issues.ts:189-200`, `server/src/routes/issues.ts:1932-2605`, `server/src/routes/issues.ts:3361-3581`, `server/src/__tests__/heartbeat-comment-wake-batching.test.ts:603-789`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:767-868`
- Relevant prior work: existing route tests distinguish generic same-agent comments from explicit `resume: true`; existing heartbeat batching tests cover deferred user comment promotion after an active run finishes.
- Constraints: keep the patch minimal and company-scoped; do not change generic comment creation semantics; do not block normal explicit `resume: true` / `reopen: true` route behavior; base branch `origin/master` verified on 2026-05-27.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Gate deferred promotion reopen on explicit reopen metadata and exclude blocked issues. Update `server/src/services/heartbeat.ts` where deferred wakeups are promoted so it only converts a closed issue to `todo` when the deferred context already carries `wakeReason: "issue_reopened_via_comment"` plus explicit `resumeIntent` or `reopenedFrom` metadata from the route. Leave generic `issue_commented` deferred wakes as comment-only follow-up context. Also ensure blocked issues stay blocked in this path; blocked issues should only move through the normal comment route when first-class blockers allow it and explicit intent is present.

**Rejected**: Remove deferred comment wake promotion entirely - would drop legitimate follow-up comments queued during an active run. **Rejected**: Change `POST /issues/:id/comments` and `PATCH /issues/:id` implicit reopen behavior broadly - higher regression risk because those routes already encode explicit and user-authored reopen policy. **Rejected**: Add a migration/backfill that mutates historical statuses automatically - the safe first step is audit visibility; operators should reconcile historical drift manually.

## Steps (Executor follows in order)
1. Update `server/src/services/heartbeat.ts` around `shouldReopenDeferredCommentWake` so deferred promotion reopens only when `deferredWakeReason === "issue_reopened_via_comment"` and the deferred context/payload proves explicit intent (`resumeIntent`, `followUpRequested`, or `reopenedFrom`), and never for plain `issue_commented` wakes.
2. Preserve deferred wake delivery for inert comments: promoted runs should still receive comment IDs/message context, but the issue status must remain `done`, `cancelled`, or `blocked` unless the explicit reopen gate passes.
3. Add/adjust tests in `server/src/__tests__/heartbeat-comment-wake-batching.test.ts` for: terminal generic user deferred comment stays closed; `resume: true` deferred reopen still works; blocked issue deferred comment stays blocked; agent-authored deferred comment stays inert.
4. Add/adjust route-level tests in `server/src/__tests__/issue-comment-reopen-routes.test.ts` only if needed to lock the explicit route metadata that heartbeat now depends on (`wakeReason`, `resumeIntent`, `followUpRequested`, `reopenedFrom`).
5. Add an audit query to the PR notes or a small docs/comment artifact for operators:
   ```sql
   SELECT
     al.created_at,
     al.entity_id AS issue_id,
     i.identifier,
     i.status AS current_status,
     al.details->>'reopenedFrom' AS reopened_from,
     al.run_id
   FROM activity_log al
   JOIN issues i ON i.id::text = al.entity_id
   WHERE al.action = 'issue.updated'
     AND al.details->>'source' = 'deferred_comment_wake'
     AND al.details->>'reopened' = 'true'
     AND al.details->>'reopenedFrom' IN ('done', 'blocked')
     AND al.created_at >= now() - interval '14 days'
   ORDER BY al.created_at DESC;
   ```
6. Run targeted verification: `pnpm vitest run server/src/__tests__/heartbeat-comment-wake-batching.test.ts server/src/__tests__/issue-comment-reopen-routes.test.ts`.

## Verification (QA Verifier checks these)
- [ ] A deferred plain user comment queued during an active run does not change a `done` issue back to `todo`/`in_progress`.
- [ ] A deferred explicit resume/reopen comment still reopens and wakes the assignee with `issue_reopened_via_comment`.
- [ ] A blocked issue remains blocked through deferred comment promotion unless it is reopened through the normal explicit route path with blocker readiness satisfied.
- [ ] Agent-authored comments, including same-agent comments, do not reopen terminal issues without explicit allowed resume intent.
- [ ] Audit query returns KOEA-5161-style drift events for recent `source=deferred_comment_wake` reopen activity.

## Risk
- Tightening deferred reopen detection could suppress a legitimate follow-up wake if a route fails to include explicit intent metadata. Mitigation: route-level tests should assert the metadata contract, and heartbeat tests should cover both inert and explicit paths.

## Out of scope
- No automatic historical status repair for KOEA-5161 or similar issues.
- No redesign of comment UX labels or implicit user reopen policy outside deferred wake promotion.
- No changes to non-comment heartbeat wake scheduling.

## Pre-flight
- status_verified=true
- assigned_to_planner=true
- chain_alert_approval=a03551a3-fea4-49bc-9303-8a9a326fade3
- basebranch_verified=true
