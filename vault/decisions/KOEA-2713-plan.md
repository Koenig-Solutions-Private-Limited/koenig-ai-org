---
ticket: KOEA-2713
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.42
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true active_siblings=0 acceptance_spec=pass"
---

# Plan: Fix stale publish-action watchdog false positives

## Goal
Watchdog Bot should alert only when `publish-action.sh` has not completed recently, not when the most recent publish event is old. Success is observable when the detector treats `publish-action complete.` as the heartbeat, suppresses duplicates across title-format variants, and still files a high-priority alert if the completion marker is genuinely older than 10 minutes.

## Context
- Files to read first: `scripts/publish-action.sh:26-27`, `scripts/publish-action.sh:282-345`, `scripts/publish-action.sh:390-498`, `/paperclip/logs/publish-action.log`, `companies/learnova-academy/agents/watchdog-bot/SOUL.md:21-36`, `vault/retrospectives/watchdog-bot/2026-05-14-05-07.md:1-12`, `vault/retrospectives/watchdog-bot/2026-05-14-05-33.md:1-12`, `vault/retrospectives/watchdog-bot/2026-05-14-08-37.md:1-12`.
- Relevant prior work: KOEA-2710 and KOEA-2712 were both created by Watchdog Bot from run `8a9f0e2a-b2c7-43f7-a03f-c844178e91f5`; the run log shows the detector command `tail -n 200 /paperclip/logs/publish-action.log | grep -E 'TICK|published' | tail -1`. Runtime evidence in `/paperclip/logs/publish-action.log` shows later successful completions at `2026-05-14 13:02:51`, `13:07:55`, `13:12:55`, and `13:17:56` UTC.
- Constraints: do not run live `scripts/publish-action.sh`, do not push `koenig-ai-org`, do not dispatch `learnovaBeast`, do not print secrets, and keep the fix limited to Watchdog Bot/publish-action health detection. `origin/master` is the verified base branch; `origin/main` is absent.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Extract the publish-action health probe into a repo script and make Watchdog Bot call it. Add `scripts/watchdog/publish-action-health.sh` that reads the log path, uses the newest `publish-action complete.` line as the primary success marker, falls back only to explicit error/missing-log states, returns machine-readable JSON, and normalizes duplicate keys around a stable alert kind rather than a timestamped title. This keeps the operational rule testable and prevents future prompt-generated command drift.

**Rejected**: Patch only the inline Watchdog Bot prompt because the faulty command was generated inside the run and can regress on the next heartbeat; change `publish-action.sh` to emit `TICK` because completions are already present and the detector should consume existing evidence; raise the threshold because the issue is stale cursor selection, not a too-low outage threshold.

## Steps (Executor follows in order)
1. Add `scripts/watchdog/publish-action-health.sh` to parse `/paperclip/logs/publish-action.log` by default, accept `PUBLISH_ACTION_LOG` and `PUBLISH_ACTION_STALE_MINUTES`, select the newest `publish-action complete.` timestamp, compute age in minutes, and emit JSON fields `state`, `last_success_at`, `age_minutes`, `dedupe_key`, and `evidence_line`.
2. Add `scripts/tests/publish-action-health-smoke.sh` with fixture logs covering healthy completion after an old published line, genuinely stale completion, missing log, malformed timestamps, and duplicate title normalization. The healthy fixture must include the KOEA-2710 pattern: `12:19:07 ... published` followed by `13:12:55 publish-action complete.`.
3. Update Watchdog Bot’s checked-in operating instructions in `companies/learnova-academy/agents/watchdog-bot/SOUL.md` to require the helper for publish-action health, forbid `grep -E 'TICK|published'` as the health source, and state that duplicate suppression must key on `publish-action-silent` plus status, not the timestamped issue title.
4. If Watchdog Bot has a persisted routine/body for KOEA-2709 in Paperclip state, update that routine prompt or issue description to call `scripts/watchdog/publish-action-health.sh` before creating publish-action alerts; keep the script as source of truth and do not inline the parsing rule again.
5. In the alert creation path used by Watchdog Bot, change cooldown detection to search active issues by metadata or a stable title prefix/dedupe key before creating a new incident, and normalize descriptions to include the helper’s `last_success_at` and `evidence_line`.
6. Add a short note to `vault/retrospectives/watchdog-bot/<current-date>-publish-action-false-positive.md` documenting the false-positive cause and the new health-probe rule so future watchdog heartbeats read it during the mandatory vault-first check.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/watchdog/publish-action-health.sh scripts/tests/publish-action-health-smoke.sh` passes.
- [ ] `bash scripts/tests/publish-action-health-smoke.sh` passes and proves the KOEA-2710 fixture is `state=ok` because the later `publish-action complete.` line wins over the older `published` line.
- [ ] With `PUBLISH_ACTION_LOG=/paperclip/logs/publish-action.log scripts/watchdog/publish-action-health.sh`, the current log reports `state=ok` when the latest completion is within the configured threshold; this must not run `scripts/publish-action.sh`.
- [ ] `rg -n "TICK\\|published|publish-action-health|publish-action complete" companies/learnova-academy/agents/watchdog-bot scripts/watchdog scripts/tests` shows Watchdog Bot no longer uses `TICK|published` for health and references the helper instead.
- [ ] Creating or simulating two stale results with `last_success_at` formatted with and without `UTC` produces the same dedupe key and only one active watchdog incident.

## Risk
- The helper could miss a real outage if `publish-action.sh` logs `publish-action complete.` before silently failing later work. Mitigation: keep the completion marker at the end of `scripts/publish-action.sh` as the success boundary, treat missing or malformed logs as non-OK, and preserve evidence lines in any alert.

## Out of scope
- Running live `publish-action.sh`, dispatching or changing `learnovaBeast`, modifying GitHub Actions publish semantics, changing G4/G5 publish-state behavior, rewriting the whole Watchdog Bot heartbeat, or cancelling historical watchdog tickets beyond the already handled KOEA-2710/KOEA-2712 cleanup.
