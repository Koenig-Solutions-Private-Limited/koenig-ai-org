---
ticket: KOEA-2521
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
revision: 2
triggered_by_approval: 7f8e9537-7b30-4daf-a1b7-f97e430358cd
preflight: "status=in_progress assigned_to_planner=true root_ticket_sibling_check=n/a acceptance_spec=pass basebranch_verified=true approval=7f8e9537-7b30-4daf-a1b7-f97e430358cd"
---

# Plan: Stop publish-action watchdog false alerts

## Goal
Classify KOEA-2521 with evidence, then stop the publish-action watchdog from filing critical "silent >10min" incidents when `scripts/publish-action.sh` is completing normally but has not recently published an artifact. Current evidence says the launchd publish-action job recovered and is healthy (`publish-action complete.` at 2026-05-14 14:45:08 UTC), while the watchdog alert path remains faulty because it keys liveness off older `published` lines. Success is observable when the watchdog uses the latest `publish-action complete.` log line as liveness, dedupes active incidents by a stable key, and still alerts when the completion marker is genuinely stale or missing.

## Context
- Files to read first: `scripts/publish-action.sh:26-27`, `scripts/publish-action.sh:282-345`, `scripts/publish-action.sh:390-498`, `packages/db/watchdog_run_safe.mjs:31-47`, `packages/db/watchdog_run_safe.mjs:145-149`, `packages/db/watchdog_run.mjs:34-56`, `watchdog/watchdog.mjs:1-21`, `infra/launchd/com.koenig.publish-action.plist:7-20`, `infra/launchd/com.koenig.watchdog.plist:8-22`, `companies/learnova-academy/agents/watchdog-bot/SOUL.md:19-36`, `/paperclip/logs/publish-action.log`.
- Relevant prior work: KOEA-2713 planned the same failure mode but Executor blocked it because it referenced non-existent `scripts/watchdog/` and `scripts/tests/` paths. KOEA-2724 separately covers publish-action issue-list pagination; do not merge that scope into this fix. KOEA-2521's original stale tick was 2026-05-14T07:16:01Z; newer duplicate tickets KOEA-2733/2738 and KOEA-3047/3048/3049 show the detector kept alerting even after the job recovered.
- Current signal check: `/paperclip/logs/publish-action.log` shows successful `publish-action complete.` markers at 2026-05-14 14:24:17, 14:29:30, and 14:45:08 UTC. Active/backlog watchdog incidents still exist for older `last tick` values, so classify KOEA-2521 as a recovered/phantom publish-action outage plus an active Watchdog Bot parser/dedupe defect.
- Constraints: do not run live `scripts/publish-action.sh`, do not dispatch `learnovaBeast`, do not print secrets from `.env.koenig`, and preserve unrelated dirty work in the repo. Use `origin/master`; `origin/main` is absent.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Put a tested health probe in the existing `watchdog/` directory and make the actual publish-action alert scripts consume it. The helper should parse the newest `publish-action complete.` marker from `/paperclip/logs/publish-action.log`, emit machine-readable health JSON, and provide one stable dedupe key. Then update `packages/db/watchdog_run_safe.mjs` and the legacy `packages/db/watchdog_run.mjs` so they stop using `TICK|published` and stop deduping by timestamped title. Next owner/action is Executor for the parser/dedupe fix; Watchdog Bot should be restarted or inspected only if the helper reports non-OK after the patch; Chief Engineering may separately cancel duplicate recovered alerts after the fix lands.

**Rejected**: Reuse the KOEA-2713 plan verbatim because its paths do not exist in this checkout. **Rejected**: Patch only `watchdog/watchdog.mjs` because that daemon monitors agent loops/costs and is not the publish-action alert creator. **Rejected**: Raise the stale threshold because the bug is selecting the wrong liveness marker, not an overly aggressive timeout.

## Steps (Executor follows in order)
1. Add `watchdog/publish-action-health.mjs` with an exported function and CLI mode. Default to `/paperclip/logs/publish-action.log`, accept `PUBLISH_ACTION_LOG` and `PUBLISH_ACTION_STALE_MINUTES`, parse the newest `[YYYY-MM-DD HH:MM:SS] publish-action complete.` line, and emit JSON fields `state`, `last_success_at`, `age_minutes`, `dedupe_key`, and `evidence_line`.
2. Update `packages/db/watchdog_run_safe.mjs` to call the helper for publish-action health. When non-OK, create at most one active incident with stable title prefix/key such as `[WATCHDOG] publish-action.sh silent >10min`, include `last_success_at` and `evidence_line` in the description, and do not create another incident if an active backlog/todo/in_progress/blocked issue with the same key already exists.
3. Apply the same parser/dedupe change to `packages/db/watchdog_run.mjs` if it is still present, or delete/retire it only if Executor verifies it is unused by runtime configuration. Do not edit `watchdog/watchdog.mjs` unless verification proves the launchd daemon is the source of the publish-action alert.
4. Add `watchdog/publish-action-health.test.mjs` using temporary fixture logs. Cover healthy completion after an old `published` line, genuinely stale completion, missing log, malformed timestamps, and stable dedupe output.
5. Update `companies/learnova-academy/agents/watchdog-bot/SOUL.md` to require the helper for publish-action liveness and explicitly forbid `grep -E 'TICK|published'` as the health source.
6. Add a short retrospective note under `vault/retrospectives/watchdog-bot/2026-05-14-publish-action-false-positive.md` documenting that `published` events are not liveness and `publish-action complete.` is the canonical heartbeat marker.
7. After verification, comment on KOEA-2521 with the current log health result, explicitly state `launchd job healthy/recovered` or `needs Watchdog Bot action`, and mention KOEA-2713 as superseded pathing context; do not bulk-close duplicate watchdog tickets unless Chief Engineering explicitly scopes cleanup.

## Verification (QA Verifier checks these)
- [ ] `node --check watchdog/publish-action-health.mjs packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs watchdog/publish-action-health.test.mjs` passes.
- [ ] `node watchdog/publish-action-health.test.mjs` passes and proves an old `published` line followed by a newer `publish-action complete.` reports `state=ok`.
- [ ] `PUBLISH_ACTION_LOG=/paperclip/logs/publish-action.log node watchdog/publish-action-health.mjs` reports `state=ok` when the latest completion is within the configured threshold, without running `scripts/publish-action.sh`.
- [ ] Minimal log check `tail -n 80 /paperclip/logs/publish-action.log | rg "publish-action complete\\." | tail -1` shows a fresh completion marker before classifying the launchd job healthy.
- [ ] `rg -n "TICK\\|published|publish-action complete|publish-action-health" packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs watchdog companies/learnova-academy/agents/watchdog-bot/SOUL.md` shows no active `TICK|published` health source and shows the helper wired in.
- [ ] Simulating two stale health results with different `last_success_at` values produces one active watchdog incident key rather than timestamp-specific duplicates.

## Risk
- A helper can miss real failures if `publish-action.sh` logs completion before later work fails. Mitigation: keep `publish-action complete.` at the end of the script as the success boundary and treat missing or malformed completion evidence as non-OK.

## Out of scope
- Running the live publish-action job, dispatching or modifying `learnovaBeast`, fixing the KOEA-2724 pagination gap, broad Watchdog Bot permission changes from KOEA-2522, and cleaning up the historical duplicate watchdog backlog.
