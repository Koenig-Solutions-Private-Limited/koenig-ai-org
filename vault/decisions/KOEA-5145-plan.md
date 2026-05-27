---
ticket: KOEA-5145
planner: planner
planner_issue: KOEA-5209
date: 2026-05-27
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
basebranch_verified: true
chain_alert_approval: 646916dd-9b07-4561-a7d0-60da98750fce
preflight: "status=in_progress assigned_to_planner=true chain_depth=3 authorized_by_chief=true active_siblings=2 acceptance_spec=pass basebranch_verified=true"
---

# Plan: Fix approval-backlog watchdog duplicate alerts

## Goal
Prevent Watchdog Bot from filing a second open approval-backlog alert for the same condition while preserving the live pending-approval count. Success is observable when the watchdog still counts only `approvals.status = pending`, but skips creating a new `[WATCHDOG] Approval backlog exceeded 10 pending. Operator may want to triage.` issue if any same-title issue is already active, even when the older issue is more than 4 hours old.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:17-22`, `packages/db/watchdog_run_safe.mjs:49-58`, `packages/db/watchdog_run.mjs:14-21`, `packages/db/watchdog_run.mjs:58-62`, `packages/db/vitest.config.ts:1-6`, `packages/db/package.json:31-39`.
- Relevant prior work: KOEA-5110 was created at 2026-05-26T17:53:14Z with `Current pending approvals: 36`, and Chief Engineering reconstructed that 36 approvals were pending at that creation time. The CEO's later 2026-05-26T18:04Z observation of 2 pending approvals happened after board hygiene decisions at 17:53-17:58Z, so the count mismatch is a stale/race observation after cleanup, not a count-query defect. KOEA-5081 was an older same-title approval-backlog alert created at 2026-05-26T13:53:00Z and still open when KOEA-5110 was filed, proving the duplicate-open-alert defect.
- Constraints: plan-only child KOEA-5209 must not implement. Preserve board approval semantics and do not approve, reject, cancel, or mutate approvals. Keep the fix company-scoped through existing API/SQL paths. `origin/master` is the verified base branch for this repo; `origin/main` does not exist.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a narrow reusable active-issue dedupe helper for watchdog issue creation, then use it only for the stable approval-backlog alert in both `watchdog_run_safe.mjs` and `watchdog_run.mjs`. The helper should treat `todo`, `in_progress`, `in_review`, and `blocked` same-title issues as active duplicates regardless of age, while leaving the existing 4-hour freshness behavior available for timestamped or count-specific watchdog incidents.

**Rejected**: Change the pending approval SQL because both runner variants already query `approvals where company_id = CID and status = 'pending'`, and KOEA-5110's 36 count was accurate at creation time. **Rejected**: Globally remove the 4-hour freshness window from all watchdog alerts because some titles include volatile counts, timestamps, or failure signatures and need separate dedupe decisions. **Rejected**: Close or retitle historical KOEA-5081/KOEA-5110 alerts in this implementation because cleanup is operator triage, not the watchdog code fix.

## Steps (Executor follows in order)
1. Add `packages/db/watchdog_issue_dedupe.mjs` exporting `ACTIVE_WATCHDOG_ISSUE_STATUSES`, `findActiveIssueByTitle(issues, title)`, and optionally `findFreshIssueByTitle(issues, title, now, cooldownMs)` so both runner scripts share the same active/open definition.
2. Add `packages/db/watchdog_issue_dedupe.test.mjs` with plain Node `assert` coverage for same-title `blocked` issues older than 4 hours, terminal `done`/`cancelled` issues, hidden issues, and fresh-window compatibility.
3. Update `packages/db/watchdog_run_safe.mjs:17-22` so `ensureIssue` can choose active-title dedupe for stable incidents without changing the default fresh-title behavior used by other watchdog categories.
4. Update `packages/db/watchdog_run_safe.mjs:55-58` so the approval-backlog path calls `ensureIssue` with active-title dedupe and still uses the existing `select count(*)::int ... status='pending'` query unchanged.
5. Update `packages/db/watchdog_run.mjs:58-62` with the same active-title dedupe behavior for the approval-backlog path, reusing the helper instead of maintaining a divergent inline check.
6. Run focused verification and include KOEA-5081/KOEA-5110 evidence in the handoff: no duplicate should be created when a same-title `blocked` issue is older than 4 hours, but a new alert can still be created when only terminal same-title issues exist.

## Verification (QA Verifier checks these)
- [ ] `node packages/db/watchdog_issue_dedupe.test.mjs` passes and covers an older-than-4-hours same-title `blocked` approval-backlog issue as a duplicate.
- [ ] `node --check packages/db/watchdog_issue_dedupe.mjs packages/db/watchdog_issue_dedupe.test.mjs packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs` passes.
- [ ] `rg -n "Approval backlog exceeded 10 pending|status='pending'|pending_total|pendingTotal" packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs packages/db/watchdog_issue_dedupe.mjs` shows the pending-count SQL is still status-pending-only and both backlog alert paths use active-title dedupe.
- [ ] Manual fixture or unit evidence confirms KOEA-5081-style active same-title issue suppresses KOEA-5110-style duplicate creation after the 4-hour freshness window expires.

## Risk
- A stale open backlog issue could suppress a new alert after the queue drops below threshold and later exceeds it again. Mitigation: the alert is intentionally operator-owned while active; Watchdog should only create a fresh backlog issue after the prior same-title alert is terminal (`done` or `cancelled`).

## Out of scope
- Changing approval lifecycle semantics, changing the pending approval count query, resolving or mutating existing board approvals, cleaning up historical KOEA-5081/KOEA-5110 tickets, broad watchdog incident dedupe for publish-action/marker/stale-blocked/failure-spike alerts, or refactoring the watchdog runner architecture.
