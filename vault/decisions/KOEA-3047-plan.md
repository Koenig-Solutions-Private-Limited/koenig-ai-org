---
ticket: KOEA-3047
source_ticket: KOEA-3080
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: "$0.24"
base_branch: master
basebranch_verified: true
---

# Plan: Make publish-action freshness deterministic

## Goal
Make the watchdog treat a completed publish-action run as fresh evidence, independent of whether that run actually published an artifact. Success means the scheduler owner is explicit, the tracked and active publish-action scripts no longer drift silently, and watchdog-created stale tickets are based on the latest successful `publish-action complete.` or legacy tick marker.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:31-47`, `packages/db/watchdog_run.mjs:37-54`, `scripts/publish-action.sh:21-26`, `scripts/publish-action.sh:282-341`, `/paperclip/scripts/publish-action.sh:53-87`, `/paperclip/logs/publish-action.log`, `infra/launchd/com.koenig.publish-action.plist:7-20`, `scripts/load-launchd-agents.sh:22-28`.
- Relevant prior work: `vault/decisions/KOEA-2029-plan.md`, `vault/decisions/KOEA-2213-plan.md`, `vault/decisions/KOEA-2724-plan.md`, and `vault/decisions/KOEA-3057-plan.md`.
- Constraints: do not print tokens from `.env.koenig`; do not run a live publish-action invocation unless dry-run or mutation guards are added first; preserve `origin/master` as the verified Koenig base branch; keep Publish Verifier as downstream G5 verification, not the scheduler for this script.
- Pre-flight: KOEA-3080 status is `in_progress`, assignee is Planner, chain depth is 2 via KOEA-3047, active sibling count is 0, body has four concrete planner requirements, and `git ls-remote --heads origin master` returned `refs/heads/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Keep publish-action as the scheduler-owned poller and make freshness parsing + runtime synchronization explicit. Executor should patch both watchdog scripts so the freshness check reads the latest terminal success marker (`publish-action complete.` and the legacy `publish-action V2 tick complete`) instead of looking only for `TICK|published`, then reconcile `scripts/publish-action.sh` with `/paperclip/scripts/publish-action.sh` so the tracked source and active runtime copy match or have an explicit documented deployment step.

**Rejected**: Move scheduling to Publish Verifier heartbeat, because Publish Verifier is a downstream G5 checker and would blur deployment with verification. **Rejected**: Only raise the stale threshold above 30 minutes, because that hides false positives without fixing the parser or owner drift. **Rejected**: Patch only `/paperclip/scripts/publish-action.sh`, because the next deploy from tracked source can reintroduce drift.

## Steps (Executor follows in order)
1. Update `packages/db/watchdog_run_safe.mjs` and `packages/db/watchdog_run.mjs` publish-action freshness logic to select the latest log line matching `publish-action complete.` or `publish-action V2 tick complete`, parse its timestamp, and include the matched line in the Watchdog Health summary.
2. Add a narrow fixture or inline test script under `packages/db` or `scripts/tests` that feeds sample log tails containing no publish events, a `publish-action complete.` line, and a legacy `publish-action V2 tick complete` line; assert stale detection is false for recent completion and true for old/no marker.
3. Reconcile `scripts/publish-action.sh` and `/paperclip/scripts/publish-action.sh`: preserve the current active runtime behavior, bring the tracked copy and active copy to the same content after review, and keep executable mode on both.
4. Update `infra/launchd/com.koenig.publish-action.plist` comments or adjacent docs/runbook text so the operational owner is explicit: launchd/host scheduler should run publish-action directly on a 60s cadence where used; container/runtime deployments must run the same `/paperclip/scripts/publish-action.sh` copy and log to `/paperclip/logs/publish-action.log`.
5. Add a lightweight drift verification command to the handoff docs or script comments, such as `shasum -a 256 scripts/publish-action.sh /paperclip/scripts/publish-action.sh`, and state that mismatch is an operational failure unless a deliberate deploy window is in progress.
6. Leave KOEA-3057 marker-compliance classifier work out of this change unless it is already merged; this ticket should not redesign blocked-comment marker auditing.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/publish-action.sh` and `bash -n /paperclip/scripts/publish-action.sh` pass.
- [ ] The new freshness fixture proves recent `publish-action complete.` and legacy `publish-action V2 tick complete` log lines are accepted as fresh without requiring an artifact publish.
- [ ] `shasum -a 256 scripts/publish-action.sh /paperclip/scripts/publish-action.sh` shows matching hashes after Executor syncs the runtime copy.
- [ ] `tail -n 80 /paperclip/logs/publish-action.log` shows the most recent successful completion marker, and the watchdog summary reports that marker as OK rather than filing a new stale publish-action issue.
- [ ] No command in verification dispatches GitHub Actions, pushes `koenig-ai-org`, or patches live Paperclip issue publish metadata unless the Executor first adds and enables an explicit dry-run/mutation guard.

## Risk
- Runtime drift could recur because `/paperclip/scripts/publish-action.sh` is outside normal git tracking. Mitigation: make the tracked script the source of truth, require hash comparison during verification, and document that runtime deployment is part of the fix.

## Out of scope
- Rewriting publish-action in TypeScript or Python, changing learnovaBeast workflows, changing G4/G5 publish-state semantics, bulk-closing historical watchdog tickets, or implementing the broader marker-compliance classifier from KOEA-3057.
