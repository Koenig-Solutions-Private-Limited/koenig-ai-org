---
ticket: KOEA-3676
source_planning_ticket: KOEA-5181
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: "$0.43"
base_branch: master
preflight: status_passed=true, active_siblings=4, chain_authorized_by=541ba688-2d4d-46af-8d99-210cae80984a, acceptance_criteria_passed=true, basebranch_verified=true
touches_paperclip_core: true
authorization: "CEO routing comment on KOEA-3676 at 2026-05-26T19:49:56.754Z: platform/automation bug; route to Chief Engineering."
---

# Plan: stop blocked issue status drift

## Goal
Prevent metadata-guarded blocked issues such as [KOEA-2829](/KOEA/issues/KOEA-2829) from being activated by generic heartbeat checkout or status-update paths while their unblock condition has not changed. Success is observable when repeated poll/heartbeat cycles leave KOEA-2829 `blocked`, every blocked activation attempt has actor/run attribution, and legitimate first-class blocker-resolution wakes still work.

## Context
- Files to read first: `server/src/services/issues.ts:2849`, `server/src/services/issues.ts:3037`, `server/src/routes/issues.ts:1932`, `server/src/routes/issues.ts:2744`, `server/src/services/heartbeat.ts:3791`, `server/src/routes/issues.ts:2477`, `server/src/services/activity-log.ts:53`, `server/src/__tests__/issue-dependency-wakeups-routes.test.ts:119`, `server/src/__tests__/issue-comment-reopen-routes.test.ts:726`.
- Relevant prior work: [KOEA-2829](/KOEA/issues/KOEA-2829) activity shows repeated manual re-locks from `in_progress` back to `blocked` with metadata containing `unblock_owner`, `unblock_action`, and later `status_drift_child_issue: KOEA-3676`; the CEO routing comment on KOEA-3676 explicitly authorizes Chief Engineering to fix this as a platform/automation bug.
- Constraints: Planner must not implement; target verified `origin/master`; keep the fix company-scoped and avoid changing learnovaBeast content/frontmatter in this platform ticket.
- Current likely mutation path: `POST /api/issues/:id/checkout` in `server/src/routes/issues.ts:2744` calls `issueService.checkout()` in `server/src/services/issues.ts:3037`; that service accepts caller-provided `expectedStatuses` and unconditionally sets `status: "in_progress"` at `server/src/services/issues.ts:3080` when `blocked` is included and no first-class blockers are unresolved. Adapter/tool defaults include `blocked` in checkout status lists, so an automation run can activate a metadata-blocked issue.
- Secondary path to guard: `PATCH /api/issues/:id` routes through `issueService.update()` in `server/src/services/issues.ts:2820`; it already blocks `in_progress` when first-class blockers are unresolved but has no guard for metadata-only blocked conditions such as `unblock_owner` / `unblock_action`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a core blocked-activation guard shared by checkout and update. Treat an issue as metadata-guarded when it is currently `blocked` and `metadata` contains `unblock_owner` and `unblock_action` (or equivalent existing drift marker such as `status_drift_child_issue`). For attempts to activate it to `in_progress`, require a qualifying unblock path: unresolved first-class blockers are resolved through the existing dependency readiness flow, the issue was explicitly moved to `todo`/resumed by a board or assigned agent with a durable comment, or the metadata guard fields have been cleared/changed by an explicit issue update. When the guard rejects, return a conflict/422 with structured details and log `issue.blocked_activation_blocked` including actor type/id, agent id, run id, source path, previous status, requested status, and guard metadata keys.

**Rejected**: Remove `blocked` from all adapter `expectedStatuses` defaults because legitimate dependency-resolution wakes currently rely on checking out blocked issues after first-class blockers clear. **Rejected**: Patch only KOEA-2829 or the content-review workflow because the drift is in Paperclip core activation semantics, not the frontmatter verifier. **Rejected**: Rely on heartbeat queued-run filtering because `claimQueuedRun()` only cancels runs for unresolved first-class blockers and cannot see metadata-only unblock conditions.

## Steps (Executor follows in order)
1. Add a small helper in `server/src/services/issues.ts` or a sibling service module to detect metadata-guarded blocked issues and produce structured guard details from `issue.metadata` keys (`unblock_owner`, `unblock_action`, `status_drift_child_issue`, current status, requested status).
2. In `issueService.checkout()` (`server/src/services/issues.ts:3037`), before the `.update(issues).set({ status: "in_progress" })` block, reject checkout when the current issue is metadata-guarded `blocked` and the checkout run is not tied to a qualifying unblock/resume context; preserve the existing unresolved first-class blocker check and stale-checkout adoption behavior.
3. In `issueService.update()` (`server/src/services/issues.ts:2820`), apply the same guard to direct `blocked -> in_progress` updates, while still allowing explicit `blocked -> todo` or metadata-clearing updates so a real frontmatter repair/reroute can unblock the issue deliberately.
4. In `server/src/routes/issues.ts`, wrap both the PATCH update path and checkout route so rejections carrying the guard code emit `logActivity()` with action `issue.blocked_activation_blocked`, actor/run attribution from `getActorInfo(req)`, and details showing the source (`issue.update` or `issue.checkout`) plus guard metadata; then rethrow/respond with the structured error.
5. Add focused tests: service-level checkout/update tests for metadata-guarded `blocked -> in_progress` rejection and allowed explicit unblock path, plus route-level tests that the audit activity contains actor id and `X-Paperclip-Run-Id`.
6. Add a regression test around dependency-resolution behavior, reusing `server/src/__tests__/issue-dependency-wakeups-routes.test.ts` or a narrow service fixture, proving an issue blocked only by first-class `blockedBy` relations can still be woken and activated once those blockers are done.
7. Run targeted verification first: the new issue-service/route tests plus existing dependency wakeup tests; then manually replay the KOEA-2829 shape by creating or updating a fixture issue with `metadata.unblock_owner`/`unblock_action` and confirming three checkout attempts leave status `blocked` and create three audit events.

## Verification (QA Verifier checks these)
- [ ] A KOEA-2829-shaped issue with `status: blocked` and metadata `unblock_owner` / `unblock_action` remains `blocked` after at least 3 checkout or heartbeat attempts with unchanged metadata.
- [ ] Each rejected activation attempt writes an `issue.blocked_activation_blocked` activity row with actor type/id, agent id when present, and run id from `X-Paperclip-Run-Id`.
- [ ] A direct generic `PATCH` attempting `blocked -> in_progress` on a metadata-guarded issue is rejected with structured guard details.
- [ ] Explicit unblock flow still works: metadata guard is cleared/changed with a durable comment or status moves to `todo`, and a subsequent legitimate checkout can move the issue to `in_progress`.
- [ ] First-class dependency flow still works: when all `blockedBy` blockers become `done`, `issue_blockers_resolved` wakes are still enqueued and the dependent can be resumed without the metadata guard blocking unrelated cases.

## Risk
- A guard that is too broad could strand legitimate blocked issues. Mitigation: scope it only to `blocked` issues with explicit metadata unblock fields/drift markers, keep `blocked -> todo` and metadata-clearing updates allowed, and include a regression test for first-class blocker resolution.

## Out of scope
- Editing the learnovaBeast vault artifact, repairing the missing blog frontmatter, changing Content Reviewer instructions, removing `blocked` from all adapter checkout defaults, or closing [KOEA-2829](/KOEA/issues/KOEA-2829) manually.
