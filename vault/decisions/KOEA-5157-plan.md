---
ticket: KOEA-5157
planner: planner
planner_issue: KOEA-5177
date: 2026-05-26
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true chain_depth=2 active_siblings=0 acceptance_spec=pass basebranch_verified=true"
---

# Plan: Fix publish-action watchdog false-positive tick detection

## Goal
Stop Watchdog Bot from filing critical `publish-action.sh silent >10min` issues when the publish-action loop is completing normally but has no recent `published` event. Success is observable when the watchdog accepts the latest `publish-action complete.` line as a success tick, still alerts on genuinely stale or missing completion evidence, and reports the 2026-05-26 18:44:25 and 19:32:44 completions as fresh relative to KOEA-5157's creation window.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:31-47`, `packages/db/watchdog_run_safe.mjs:145-149`, `packages/db/watchdog_run.mjs:34-56`, `scripts/publish-action.sh:282-345`, `scripts/publish-action.sh:390-498`, `infra/launchd/com.koenig.publish-action.plist:7-27`, `/paperclip/logs/publish-action.log`.
- Relevant prior work: `vault/decisions/KOEA-2521-plan.md` identified the same `TICK|published` liveness bug on 2026-05-14, but the current code still has that filter in both watchdog scripts. KOEA-5157 proves the defect is still live: the issue was created at 2026-05-26T18:45:56Z, while the publish-action log had `publish-action complete.` at 2026-05-26 18:44:25 and again at 19:32:44.
- Constraints: plan-only child KOEA-5177 must not implement. Executor is authorized to touch `koenig-ai-org/packages/db/watchdog_run_safe.mjs`, `packages/db/watchdog_run.mjs`, and a narrowly scoped watchdog parser test/helper file in this repo. Do not run live `scripts/publish-action.sh`, do not dispatch `learnovaBeast`, do not print secrets, and preserve unrelated dirty vault/worktree state.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small reusable publish-action log parser near the watchdog scripts, then wire both active and legacy watchdog runners to use `publish-action complete.` as the canonical success tick. The parser should scan the recent log tail, ignore old `published`-only events for liveness, return structured evidence (`lastSuccessAt`, `evidenceLine`, `isStale`), and be covered by fixture tests that reproduce the current false positive before proving the fixed detection.

**Rejected**: Patch the two scripts with an inline regex only because it would be fast but leaves the parser untestable and risks drift between safe and legacy runners. **Rejected**: Treat Phase 0/Phase 1/Phase 2 progress lines as success ticks because partial progress can happen before a later failure; the final `publish-action complete.` line is the actual end-of-run success marker. **Rejected**: fold the `scripts/koenig-cron-driver.py` `Operation not permitted` scheduler drift into this fix because KOEA-5157's timing proves the immediate alert was parser-driven; cron-driver health needs a separate ticket if Chief Engineering wants it pursued.

## Steps (Executor follows in order)
1. Add a tiny parser module under `packages/db/`, for example `packages/db/publish_action_health.mjs`, exporting `parsePublishActionHealth(logText, now, staleMinutes = 10)` and `readPublishActionHealth({ logPath, now, staleMinutes })`.
2. Implement the parser so it scans the last 200 log lines for timestamped lines ending in or containing `publish-action complete.`, converts `[YYYY-MM-DD HH:MM:SS]` to UTC, returns `lastSuccessAt`, `evidenceLine`, and `isStale`, and treats missing/malformed completion evidence as stale with `lastSuccessAt: null`.
3. Update `packages/db/watchdog_run_safe.mjs:31-47` to use the parser instead of `.filter(l => /TICK|published/.test(l))`; keep the existing alert title shape but make `lastTick` use the parser's `lastSuccessAt ?? "none"` and include the evidence line in the alert description.
4. Mirror the same parser call in `packages/db/watchdog_run.mjs:34-56` unless Executor verifies from launchd/runtime config that the file is dead; if dead, leave a comment in the PR body rather than deleting it.
5. Add a focused standalone Node test, for example `packages/db/publish_action_health.test.mjs`, covering: current failure fixture with only `publish-action complete.` lines, stale completion, old `published` before newer completion, missing log text, and malformed timestamp handling.
6. Run focused verification and comment on KOEA-5157 with the parser result for `/paperclip/logs/publish-action.log`, explicitly stating that the publish-action loop was healthy at the alert time and cron-driver permission errors are separate follow-up scope.

## Verification (QA Verifier checks these)
- [ ] A fixture containing the 2026-05-26 18:44:25 and 19:32:44 `publish-action complete.` lines reports the later completion as `lastSuccessAt`, while the old `/TICK|published/` filter reproduces `none`.
- [ ] `node --check packages/db/publish_action_health.mjs packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs packages/db/publish_action_health.test.mjs` passes.
- [ ] `node packages/db/publish_action_health.test.mjs` passes.
- [ ] `PUBLISH_ACTION_LOG=/paperclip/logs/publish-action.log node packages/db/publish_action_health.mjs` or an equivalent one-liner reports a real `publish-action complete.` evidence line without running `scripts/publish-action.sh`.
- [ ] `rg -n "TICK\\|published|publish-action complete|publish_action_health" packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs packages/db` shows no active `TICK|published` liveness source.

## Risk
- If `publish-action.sh` ever logs `publish-action complete.` before later failure work, the watchdog would miss that failure. Mitigation: keep the completion line as the final line of `scripts/publish-action.sh` and make the parser accept only that final success marker, not intermediate Phase lines.

## Out of scope
- Fixing `scripts/koenig-cron-driver.py` launchd/cron `Operation not permitted` errors, running or reloading launchd jobs, dispatching publish workflows, changing G4/G5 publish-state semantics, cleaning up historical duplicate watchdog tickets, or broad Watchdog Bot dedupe/permission refactors.
