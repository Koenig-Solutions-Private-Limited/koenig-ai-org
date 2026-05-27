---
ticket: KOEA-5250
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.48
base_branch: master
basebranch_verified: true
planner_chain_alert_approval: 3d11dd30-d2da-468a-b0b9-09d23e64c478
type: decision
agent: planner
tags:
  - decision
  - paperclip/watchdog
  - paperclip/routines
---

# Plan: Fix stale-blocked watchdog nudges for hourly dispatch

## Goal
Stop Watchdog from nudging `hourly-worker-dispatch` routine issues that are no longer currently blocked or have recent movement after resume/reopen recovery. Success means the stale-blocked detector revalidates current issue state immediately before reporting or commenting, excludes superseded routine dispatch issues from the nudge queue, and provides a dry-run cleanup path for historical blocked dispatch leftovers without touching unrelated issues.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:82-87`, `packages/db/watchdog_run_safe.mjs:145-149`, `packages/db/watchdog_run.mjs:79-82`, `packages/db/tmp-watchdog-heartbeat.mjs:108-119`, `server/src/services/issues.ts:1011-1362`, `server/src/services/heartbeat.ts:3955-4137`, `packages/db/src/schema/issues.ts:44-93`.
- Relevant prior work: KOEA-5112 created the stale-blocked sweep that later nudged KOEA-3978/KOEA-3993; KOEA-5236 covers the narrower current-status false positive for KOEA-3978; KOEA-4136 planned routine coalescing for stale recovery leftovers; KOEA-4875/KOEA-5155 planned Watchdog cross-assignee comment permissions.
- Constraints: keep all SQL company-scoped; do not mutate historical issues during tests; do not change `server/` route permissions, Drizzle schema, or routine definitions in this ticket. The source patch does not require CEO/board sign-off before Executor because it stays in Watchdog operational scripts, but any live cleanup apply run must be explicitly approved by Chief Engineering or board after dry-run output.

## Approach (1 chosen, alternatives rejected)
**Chosen**: add a shared stale-blocked classifier and wire both Watchdog runners through it. Extract the stale-blocked SQL and filtering into `packages/db/watchdog_stale_blocked.mjs`, revalidate each candidate's current status and latest movement before comment/report creation, classify superseded `originKind='routine_execution'` `hourly-worker-dispatch` issues as cleanup candidates instead of nudge targets, and expose a dry-run cleanup report with an opt-in apply mode for cancelling only clearly superseded blocked dispatch issues.

**Rejected**: patch only the SQL `status='blocked'` predicate - it already exists and does not fix stale snapshots, deferred KOEA-5112-style samples, comments after `updated_at`, or superseded routine instances. **Rejected**: skip every `routine_execution` issue - too broad; non-hourly routine blockers may still need stale triage. **Rejected**: server/core recovery changes - KOEA-5250 is a Watchdog false-positive/cleanup problem and can be fixed without API, schema, or liveness-state changes.

## Steps (Executor follows in order)
1. Add `packages/db/watchdog_stale_blocked.mjs` with pure helpers plus SQL builders: `listStaleBlockedNudgeCandidates(sql, { companyId, now, staleDays, limit })`, `listSupersededHourlyDispatchCleanupCandidates(sql, ...)`, and `formatStaleBlockedDigest(rows)`. Candidate criteria must require current `issues.status='blocked'`, `hidden_at is null`, latest movement older than 7 days, and no newer same-company `hourly-worker-dispatch` routine issue with the same `origin_id` + `origin_fingerprint`.
2. In `packages/db/watchdog_run_safe.mjs:82-87`, replace the raw stale-blocked query with `listStaleBlockedNudgeCandidates`; include candidate `id`, `identifier`, `title`, `assignee_agent_id`, `updated_at`, and `last_movement_at` in the digest so later manual nudges cannot rely on stale title-only samples.
3. In `packages/db/watchdog_run.mjs:79-82`, replace the raw stale-blocked query and per-issue comment loop with the same helper; before each comment, re-fetch or re-query that one issue through the helper by id so a target that moved to `in_progress`, `todo`, `done`, or has fresh movement is skipped.
4. Add cleanup support in the helper but keep it dry-run by default: identify blocked `originKind='routine_execution'` issues whose title starts `hourly-worker-dispatch`, are older than 7 days, have no active checkout/execution lock, and are superseded by a newer same `origin_id` + `origin_fingerprint` routine issue in `todo`, `in_progress`, `in_review`, or `done`. If `WATCHDOG_STALE_BLOCKED_CLEANUP_APPLY=1`, PATCH only those candidates to `cancelled` with a comment naming the newer superseding identifier; otherwise write a Watchdog Health dry-run summary.
5. Add `packages/db/watchdog_stale_blocked.test.mjs` with Node `assert` fixtures for: a KOEA-3978-style issue currently `in_progress` is excluded, a KOEA-3993-style dispatch issue with recent comment/movement is excluded, a genuinely blocked manual issue is included, a blocked hourly dispatch superseded by a newer same-fingerprint routine issue is cleanup-only, and cleanup apply payloads never include non-hourly or non-routine issues.
6. Inspect `packages/db/tmp-watchdog-heartbeat.mjs:108-119`; if Executor confirms it is only an untracked scratch copy, do not edit it. If it is referenced by local launchd/runtime config, mirror the helper call there and document that in the PR body.
7. In the PR handoff, call out overlap with KOEA-5236: if KOEA-5236 lands first, rebase and keep only the missing latest-movement and cleanup pieces; do not duplicate the same status-freshness guard.

## Verification (QA Verifier checks these)
- [ ] `node --check packages/db/watchdog_stale_blocked.mjs packages/db/watchdog_stale_blocked.test.mjs packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs`
- [ ] `node packages/db/watchdog_stale_blocked.test.mjs`
- [ ] Dry-run against the local Paperclip DB shows KOEA-3978/KOEA-3993-style non-blocked or recently moved dispatch issues are absent from stale-blocked nudge candidates, while cleanup candidates are reported separately and not cancelled without `WATCHDOG_STALE_BLOCKED_CLEANUP_APPLY=1`.
- [ ] With apply disabled, Watchdog Health summary includes `stale-blocked cleanup dry-run=<N>` and no issue status changes occur.

## Risk
- Risk: filtering out superseded hourly dispatch issues could hide a genuinely blocked current dispatch. Mitigation: only classify as cleanup when a newer same-company routine issue with the same `origin_id` and `origin_fingerprint` exists and the old candidate has no active checkout/execution lock; otherwise leave it in normal stale-blocked triage.

## Out of scope
- Changing Paperclip core issue routes, Drizzle schema, permissions, or routine scheduling semantics.
- Running live cleanup during implementation or tests.
- Resolving KOEA-5236, KOEA-5340, or the broader Watchdog cross-assignee comment permission work except for avoiding duplicate edits if those land first.

## Pre-flight Footer
status_ok=true; assignee_ok=true; sibling_count=4; sibling_alert_approved=3d11dd30-d2da-468a-b0b9-09d23e64c478; acceptance_ok=true; basebranch_verified=true; base_branch=master; plan_mode=true
