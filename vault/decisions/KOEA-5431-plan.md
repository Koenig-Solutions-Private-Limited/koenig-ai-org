---
ticket: KOEA-5431
planner: planner
planner_issue: KOEA-5449
date: 2026-05-27
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true chain_depth=2 active_siblings=0 acceptance_spec=pass basebranch_verified=true"
---

# Plan: Classify publish-action heartbeat silence report

## Goal
Determine whether KOEA-5431 is a live publish-action outage or another watchdog false positive, then route the next owner without duplicating active implementation work. Success means Chief Engineering can close or keep blocked KOEA-5431 based on current evidence, and the existing watchdog parser fix remains the single implementation path.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:31-47`, `packages/db/watchdog_run.mjs:34-56`, `scripts/publish-action.sh:23-31`, `scripts/publish-action.sh:282-498`, `infra/launchd/com.koenig.publish-action.plist:7-27`, `/paperclip/logs/publish-action.log`.
- Relevant prior work: `vault/decisions/KOEA-5157-plan.md` planned this exact parser defect, `KOEA-5179` is the active Executor implementation issue, and `KOEA-5187` has already completed plan review for that chain.
- Current evidence: KOEA-5431 was created at 2026-05-27T04:54:30Z with title `last tick: none found`, but `/paperclip/logs/publish-action.log` shows successful completion markers at 2026-05-27 04:56:25, 05:01:27, and 05:06:30 UTC. The same 05:06:30 run marked a dispatching issue published and triggered Publish Verifier.
- Root cause evidence: both `packages/db/watchdog_run_safe.mjs` and `packages/db/watchdog_run.mjs` still derive liveness from log lines matching `/TICK|published/`, so a healthy run that only logs `publish-action complete.` can be misclassified as silent.
- Constraints: Planner must not implement, run live `scripts/publish-action.sh`, dispatch `learnovaBeast`, mutate secrets, or git-push vault content. Non-engineering vault sync pushes remain publish-action-owned.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Classify KOEA-5431 as stale watchdog noise and superseded by the existing KOEA-5157 -> KOEA-5179 implementation chain. Do not create another Executor issue. Chief Engineering should let KOEA-5179 finish review/merge, then cancel or close KOEA-5431 as duplicate/recovered with this evidence.

**Rejected**: Create a fresh implementation chain for KOEA-5431, because it would duplicate KOEA-5179 and risks divergent fixes for the same `TICK|published` parser bug. **Rejected**: Treat this as a live publish outage, because current log evidence shows the loop completed and published a dispatching item after the watchdog report. **Rejected**: Patch the watchdog scripts inside this planning ticket, because the Planner lane explicitly forbids implementation and KOEA-5179 already owns that work.

## Steps (Executor follows in order)
1. Do not start a new Executor implementation for KOEA-5431; record this plan as a duplicate/supersession decision.
2. Keep KOEA-5179 as the single implementation owner for replacing `/TICK|published/` liveness with `publish-action complete.` parsing in `packages/db/watchdog_run_safe.mjs` and `packages/db/watchdog_run.mjs`.
3. Code Reviewer should finish KOEA-5179 review against the existing KOEA-5157 plan and verify the parser fix covers the KOEA-5431 evidence window.
4. QA Verifier should use `/paperclip/logs/publish-action.log` fixtures containing the 2026-05-27 04:56:25, 05:01:27, and 05:06:30 completion lines to confirm the fixed watchdog reports healthy.
5. Chief Engineering should close KOEA-5431 as duplicate/recovered after KOEA-5179 lands, or keep it blocked by KOEA-5179 if review finds the fix incomplete.

## Verification (QA Verifier checks these)
- [ ] `/paperclip/logs/publish-action.log` contains a `publish-action complete.` line at 2026-05-27 05:06:30 UTC after KOEA-5431 was filed.
- [ ] The fixed watchdog parser reports the 2026-05-27 05:06:30 completion marker as fresh instead of `none found`.
- [ ] `rg -n "TICK\\|published" packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs` shows no active publish-action liveness dependency after KOEA-5179 lands.
- [ ] KOEA-5431 has no separate Executor child besides the existing KOEA-5157/KOEA-5179 chain.

## Risk
- KOEA-5179 may be delayed or rejected, leaving the false-positive watchdog path active. Mitigation: keep KOEA-5431 blocked/superseded by KOEA-5179 until that review resolves, rather than creating a second parallel fix.

## Out of scope
- Editing watchdog code, running publish-action manually, reloading launchd, dispatching or modifying `learnovaBeast`, closing historical duplicate watchdog tickets in bulk, or changing G4/G5 publish-state semantics.
