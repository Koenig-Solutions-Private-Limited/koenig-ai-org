---
ticket: KOEA-4849
source_ticket: KOEA-4799
planner: planner
agent: planner
date: 2026-05-27
type: decision
tags:
  - decision
estimated_complexity: small
estimated_token_cost: "$0.18"
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true active_siblings=0 acceptance_spec=pass body_bullets=4 basebranch_verified=true"
---

# Plan: Count idle publish-action completions as watchdog heartbeat evidence

## Goal
Stop KOEA-4799-style false positives where publish-action is running successfully but the watchdog reports `last tick: none`. Success means the watchdog accepts the terminal `publish-action complete.` line as fresh heartbeat evidence, still alerts when the final success marker is stale or missing, and does not count partial runs healthy from early phase logs.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:31-47`, `packages/db/watchdog_run.mjs:34-56`, `packages/db/tmp-watchdog-heartbeat.mjs:38-62` if present in the executor workspace, `scripts/publish-action.sh:1-27`, `scripts/publish-action.sh:498`, `infra/launchd/com.koenig.publish-action.plist:7-14`, `/paperclip/logs/publish-action.log`.
- Relevant prior work: `vault/decisions/KOEA-2521-plan.md`, `vault/decisions/KOEA-3047-plan.md`, and `vault/decisions/KOEA-2713-plan.md` already diagnose this class of stale `TICK|published` parsing; this ticket narrows the fix to the current KOEA-4799 false positive.
- Constraints: `packages/db/watchdog_run_safe.mjs` and `packages/db/watchdog_run.mjs` are currently untracked in this checkout, so Executor must treat them as runtime/source-of-truth files and either add the corrected scripts to the branch or explicitly document any runtime-only deployment step. Do not run live publish dispatches, print `.env.koenig`, clean unrelated dirty files, or bulk-close historical watchdog tickets.
- Current evidence: KOEA-4799 was created with title `[WATCHDOG] publish-action.sh silent >10min — last tick: none`; `/paperclip/logs/publish-action.log` shows successful idle completions on 2026-05-27, including `09:47:35 publish-action complete.`. The publish-action launchd plist runs `scripts/publish-action.sh`, and the tracked script logs `publish-action complete.` only at the end.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Patch the watchdog publish-health parser, not publish-action. Executor should replace the `/TICK|published/` selector in the active watchdog runtime scripts with a helper or local function that selects the newest final success marker matching `publish-action complete.` or legacy `publish-action V2 tick complete`, parses its timestamp, and reports non-OK only when that final marker is missing, malformed, or older than the stale threshold. The alert path should keep the current critical issue behavior but use a stable active-issue dedupe key/title prefix so timestamp changes do not create duplicate incidents.

**Rejected**: Add a new `TICK` line to publish-action because the script already has a final success boundary and the parser should consume it. **Rejected**: Patch `watchdog/watchdog.mjs` because the launchd watchdog daemon monitors agent loops/costs and does not contain the KOEA-4799 publish-action incident title. **Rejected**: Raise the stale threshold because the false positive is caused by selecting the wrong log line, not by a too-short freshness window.

## Steps (Executor follows in order)
1. Confirm the runtime entrypoint by searching current scheduler/run configuration and the KOEA-4799 creator path; treat `packages/db/watchdog_run_safe.mjs` as primary and `packages/db/watchdog_run.mjs` as legacy fallback unless evidence proves otherwise.
2. Update `packages/db/watchdog_run_safe.mjs` so publish-action health scans the last log tail for final success markers, prefers the newest `publish-action complete.` or `publish-action V2 tick complete` line, stores `lastSuccessAt` plus `evidenceLine`, and leaves `publishStale=true` for missing or unparseable evidence.
3. Apply the same parser behavior to `packages/db/watchdog_run.mjs`; only touch `packages/db/tmp-watchdog-heartbeat.mjs` if step 1 shows it is still callable by a routine or harness command.
4. Change the publish-action incident dedupe in the touched watchdog script(s) to search active `backlog`, `todo`, `in_progress`, `in_review`, or `blocked` issues by stable title prefix such as `[WATCHDOG] publish-action.sh silent >10min`, while keeping `last_success_at` and `evidence_line` in the description/comment.
5. Add a small command-level fixture test near the watchdog script(s), or a documented `node -e` smoke command if the runtime files remain untracked, covering recent completion after old publish lines, stale completion, missing log, malformed timestamp, and duplicate stale outputs.
6. Run the narrow checks and hand off evidence on KOEA-4799/KOEA-4849: syntax check for touched `.mjs` files, the fixture/smoke test, and a read-only live log parse against `/paperclip/logs/publish-action.log` that reports OK without running `scripts/publish-action.sh`.

## Verification (QA Verifier checks these)
- [ ] `node --check packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs` passes, plus `packages/db/tmp-watchdog-heartbeat.mjs` if Executor modifies it.
- [ ] The new fixture or smoke command proves an older `published` line followed by a newer `[YYYY-MM-DD HH:MM:SS] publish-action complete.` reports healthy/fresh.
- [ ] A stale or missing final completion marker still reports failing and includes `last_success_at` and `evidence_line` where available.
- [ ] `tail -n 80 /paperclip/logs/publish-action.log` shows the newest `publish-action complete.` marker, and the updated parser reports OK without invoking publish-action.
- [ ] Running the stale-path simulation twice with different last-success timestamps resolves to one stable active watchdog incident key/title prefix, not timestamp-specific duplicates.

## Risk
- A real partial failure could be missed if publish-action logs `publish-action complete.` before later work fails. Mitigation: Executor must verify the completion log remains the terminal success line in `scripts/publish-action.sh` and must not count phase-start, phase-scan, `published`, or vault-sync lines as heartbeat evidence.

## Out of scope
- Running the live publish-action dispatcher, changing learnovaBeast workflows, changing G4/G5 publish-state semantics, redesigning Watchdog Bot permissions, syncing `/paperclip/scripts/publish-action.sh`, and closing historical duplicate watchdog tickets.
