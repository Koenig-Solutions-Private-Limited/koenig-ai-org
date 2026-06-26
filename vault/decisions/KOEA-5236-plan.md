---
ticket: KOEA-5236
planner: planner
planner_issue: KOEA-5340
date: 2026-05-27
estimated_complexity: small
estimated_token_cost: $0.28
base_branch: master
basebranch_verified: true
chain_alert_approval: 69973490-4da1-42ee-bdd1-31b58aea844b
preflight: "status=in_progress assigned_to_planner=true chain_depth=3 authorized_by_chief=true acceptance_spec=concrete basebranch_verified=true"
---

# Plan: Guard stale-blocked watchdog nudges with fresh issue state

## Goal
Prevent Watchdog Bot from nudging issues that are no longer blocked by the time the stale-blocked alert is dispatched. Success is observable when a KOEA-3978-style issue that transitions from `blocked` to `in_progress` after the watchdog's initial scan is skipped, while genuinely current `blocked` issues older than seven days can still be surfaced.

## Context
- Files to read first: `packages/db/watchdog_run.mjs:18-21`, `packages/db/watchdog_run.mjs:79-82`, `packages/db/watchdog_run_safe.mjs:9-12`, `packages/db/watchdog_run_safe.mjs:82-87`, `packages/db/tmp-watchdog-heartbeat.mjs:108-119`, `packages/db/package.json:1-19`.
- Relevant prior work: KOEA-3978 comment `b57ede5f-2732-4e6d-ac2b-dd27b8c07437` says the blocked-ticket nudge came from KOEA-5112; later KOEA-3978 comments `2663e2b6-3c42-4239-84b4-6cc6b5139dcb` and `900fbf56-736d-4789-97b5-e34f0ff5ba94` confirm current state was `in_progress` with no blocker metadata and escalated this false positive through KOEA-5236. Chief Engineering dispatch comment `880e0814-72db-49cb-a06f-b420f35cc1b7` confirms KOEA-3978 had `status=in_progress`, no `blockedBy`, and `blockerAttention=none` before this plan chain.
- Constraints: do not implement from KOEA-5340; keep the fix in the watchdog runner path, preserve company scoping via `CID`, and do not broaden Watchdog Bot permissions. `origin/master` is the verified implementation base branch for this checkout.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small stale-blocked eligibility helper and revalidate every candidate's current persisted state immediately before dispatch in both watchdog runner variants. The guard should require the fresh row to still have `status === "blocked"`, `hidden_at is null`, and `updated_at < now() - interval '7 days'`; blocker metadata such as `blockedBy` or `blockerAttention` may be included in evidence when available, but should not be mandatory because legacy blocked issues can be valid without first-class blocker relations. This directly fixes the race between initial scan and comment/issue creation without changing schema or ownership rules.

**Rejected**: Only change the initial SQL query because both scripts already query `status='blocked'`, and KOEA-3978 proves the false positive can occur after scan but before dispatch. **Rejected**: Require `blockedBy.length > 0` or `blockerAttention.state !== "none"` for all stale-blocked nudges because that would silently drop legitimate legacy blocked issues that use status/comment-based unblock instructions. **Rejected**: Move the watchdog into core server recovery services because this ticket is a narrow automation guard, not a watchdog architecture refactor.

## Steps (Executor follows in order)
1. Add `packages/db/watchdog_stale_blocked_guard.mjs` exporting `isFreshStaleBlockedIssue(row, now)` and `filterFreshStaleBlockedRows(rows, now)`; require `status === "blocked"`, no hidden timestamp, and `updatedAt` or `updated_at` older than seven days.
2. Add `packages/db/watchdog_stale_blocked_guard.test.mjs` with Node `assert` coverage for current `blocked` rows, transitioned `in_progress`/`todo`/`done` rows, hidden rows, rows updated inside seven days, and legacy blocked rows with no blocker metadata.
3. Update `packages/db/watchdog_run.mjs:79-82` so the stale-blocked loop re-queries each candidate by `id` immediately before `recentSelf` and `apiPost`, maps the fresh SQL row through the helper, and skips dispatch when the fresh row no longer qualifies.
4. Update the Watchdog Health digest in `packages/db/watchdog_run.mjs:82` to count/sample only the fresh eligible rows after revalidation, so skipped transitioned issues do not appear in the summary.
5. Update `packages/db/watchdog_run_safe.mjs:82-87` so its aggregate `[WATCHDOG] Stale blocked tickets >7d (...)` issue is built from freshly revalidated eligible rows, not the stale initial scan result.
6. Mirror the same guard in `packages/db/tmp-watchdog-heartbeat.mjs:108-119` only if Executor confirms that file is still used by the KOEA-5112 deployment path; otherwise leave it untouched and explicitly note it as an obsolete scratch copy in the handoff.
7. Document in the Executor handoff that no DB schema or migration is required because the guard uses existing `issues.status`, `issues.hidden_at`, and `issues.updated_at` fields.

## Verification (QA Verifier checks these)
- [ ] `node packages/db/watchdog_stale_blocked_guard.test.mjs` passes and proves `in_progress`, `todo`, `done`, hidden, and recently updated candidates are skipped.
- [ ] `node --check packages/db/watchdog_stale_blocked_guard.mjs packages/db/watchdog_stale_blocked_guard.test.mjs packages/db/watchdog_run.mjs packages/db/watchdog_run_safe.mjs` passes.
- [ ] `rg -n "status='blocked'|Stale blocked tickets|this has been blocked >7 days|isFreshStaleBlockedIssue|filterFreshStaleBlockedRows" packages/db/watchdog_run.mjs packages/db/watchdog_run_safe.mjs packages/db/watchdog_stale_blocked_guard.mjs` shows both stale-blocked dispatch paths use fresh eligibility before posting.
- [ ] A manual fixture or unit-level simulation demonstrates a candidate selected as blocked but revalidated as `in_progress` before dispatch produces no per-issue nudge and is absent from the Watchdog Health stale-blocked sample.

## Risk
- Revalidating candidates one-by-one adds a small number of SQL reads to the watchdog heartbeat. Mitigation: the stale-blocked query already limits to 20 rows, so the overhead is bounded and preferable to noisy escalation against active issues.

## Out of scope
- Changing Watchdog Bot permissions, redesigning watchdog scheduling, mutating KOEA-3978 directly, requiring all blocked issues to use `blockedBy` relations, changing issue schema, or cleaning up historical KOEA-5112/KOEA-5236 comments.
