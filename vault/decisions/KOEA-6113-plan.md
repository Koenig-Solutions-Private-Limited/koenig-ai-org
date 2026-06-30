---
ticket: KOEA-6113
planner: planner
planner_issue: KOEA-6149
date: 2026-05-28
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true active_siblings=0 acceptance_spec=pass basebranch_verified=true"
---

# Plan: Fix publish-action liveness parser false positive

## Goal
Stop Watchdog Bot from filing `publish-action.sh silent >10min` incidents when publish-action completed normally but did not publish a content item. Success is observable when the watchdog treats the final `publish-action complete.` log line as the success tick, while still alerting when no recent completion evidence exists.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:31-47`, `packages/db/watchdog_run.mjs:34-56`, `packages/db/tmp-watchdog-heartbeat.mjs:38-49`, `scripts/publish-action.sh:498`, `infra/launchd/com.koenig.publish-action.plist:7-27`, `/paperclip/logs/publish-action.log`.
- Relevant prior work: `vault/decisions/KOEA-5157-plan.md` planned the same parser fix on 2026-05-26, but the current code still derives liveness from `/TICK|published/` in both watchdog runners. KOEA-6113 reproduced the false positive on 2026-05-28: the log had healthy completions at 03:00:20 UTC, 03:05:22 UTC, and later 03:10:26 UTC, while the watchdog reported `last tick: none`.
- Constraints: Executor must not run live `scripts/publish-action.sh`, reload launchd, dispatch `learnovaBeast`, change publish-action ownership, print secrets, or run git push from `koenig-ai-org`. Keep the code change scoped to watchdog liveness parsing and focused verification.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small reusable publish-action health parser under `packages/db/`, then wire both `watchdog_run_safe.mjs` and `watchdog_run.mjs` to use `publish-action complete.` as the canonical success tick. The parser should scan the recent log tail, extract the latest timestamped completion line, return structured evidence (`lastSuccessAt`, `evidenceLine`, `isStale`), and support a standalone fixture test so this false positive cannot return unnoticed.

**Rejected**: Inline a broader regex in both runner files because it would be fast but leaves duplicated parsing and no direct test target. **Rejected**: Count any Phase 0/1/2 progress line as a success tick because partial progress can precede a later failure; the final completion line is the reliable end-of-run marker. **Rejected**: Modify `scripts/publish-action.sh` or scheduler ownership because the active log already emits a correct terminal success line, so the defect is in watchdog parsing.

## Steps (Executor follows in order)
1. Add `packages/db/publish_action_health.mjs` exporting `parsePublishActionHealth(logText, now, staleMinutes = 10)` and `readPublishActionHealth({ logPath, now, staleMinutes })`.
2. Implement the parser to scan the last 200 log lines for timestamped `publish-action complete.` lines, parse `[YYYY-MM-DD HH:MM:SS]` as UTC, return the latest completion evidence, and mark missing or malformed completion evidence as stale.
3. Replace the `/TICK|published/` liveness block in `packages/db/watchdog_run_safe.mjs:31-47` with the parser result; keep the alert title shape, set `lastTick` to `lastSuccessAt ?? "none"`, and include the evidence line in the alert description when available.
4. Mirror the same parser call in `packages/db/watchdog_run.mjs:34-56`; only leave it untouched if Executor verifies from runtime config that it is dead, and document that verification in the PR body.
5. Add `packages/db/publish_action_health.test.mjs` with fixtures for: healthy no-op completion, stale completion, old `published` before newer completion, missing completion, and malformed timestamp.
6. Run focused verification and comment the result on KOEA-6149, including the parser result for `/paperclip/logs/publish-action.log` without executing publish-action.

## Verification (QA Verifier checks these)
- [ ] `node --check packages/db/publish_action_health.mjs packages/db/publish_action_health.test.mjs packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs` passes.
- [ ] `node packages/db/publish_action_health.test.mjs` passes and includes a fixture where the old `/TICK|published/` filter would return no tick while the new parser finds `publish-action complete.`.
- [ ] A read-only parser probe against `/paperclip/logs/publish-action.log` reports the latest real completion line as fresh, without running `scripts/publish-action.sh`.
- [ ] `rg -n "TICK\\|published|publish_action_health|publish-action complete" packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs packages/db` shows both watchdog runners no longer use `/TICK|published/` as the liveness source.

## Risk
- If `publish-action.sh` ever logs `publish-action complete.` before later failure-prone work, the watchdog would miss that later failure. Mitigation: keep the completion line as the final success marker and do not count intermediate Phase lines as healthy ticks.

## Out of scope
- Running or reloading launchd jobs, executing publish-action, dispatching or verifying `learnovaBeast`, changing G4/G5 publish-state semantics, cleaning up historical duplicate watchdog issues, changing Watchdog Bot permissions, or broad watchdog dedupe refactors.
