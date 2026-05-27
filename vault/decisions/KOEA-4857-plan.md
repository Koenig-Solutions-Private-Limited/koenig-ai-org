---
ticket: KOEA-4857
planner: planner
date: 2026-05-27
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
basebranch_verified: true
revision: 2
supersedes_plan_revision: 1
triggered_by_comment: 048dc245-532b-487f-bdd2-4fbdc208c9f8
plan_drift_block: e52e42bf-d6ad-4f88-9ceb-82599316579b
---

# Plan: Fix Watchdog publish-action tick false positive

## Goal
Stop Watchdog from filing `publish-action.sh silent >10min` when `publish-action.sh` has recently completed a healthy no-op run. Success is observable when the existing Watchdog health check can find a recent completion marker in `/paperclip/logs/publish-action.log`, while old or missing logs still remain stale.

## Context
- Files to read first: `scripts/publish-action.sh:21-27`, `scripts/publish-action.sh:282-290`, `scripts/publish-action.sh:390-498`, live Watchdog instructions at `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md:13-22`.
- Relevant prior work: [KOEA-4801](/KOEA/issues/KOEA-4801) proved the alert was false positive: the log had `publish-action complete.` at `2026-05-26 09:11:29 UTC`, but Watchdog only looked for `TICK|published`. Executor then found revision 1 drifted because `packages/db/watchdog_run*.mjs` were untracked local/generated files, not files on `origin/master`.
- Constraints: keep this in `koenig-ai-org`; do not touch learnovaBeast; do not merge `origin/koea-4849/fix-watchdog-publish-heartbeat`; target verified `origin/master` (`git ls-remote --heads origin master` returned `refs/heads/master`). This plan intentionally avoids untracked `packages/db/watchdog_run*.mjs`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Make the tracked producer log line compatible with the live Watchdog parser by changing the terminal success message in `scripts/publish-action.sh` from `publish-action complete.` to a success marker that still contains that phrase but also includes `TICK`, for example `TICK publish-action complete.`. This is the smallest executable fix on the tracked base: the existing Watchdog instruction keeps using `grep -E 'TICK|published'`, and healthy no-op runs become visible on the next launchd tick without loosening stale detection.

**Rejected**: Edit `packages/db/watchdog_run.mjs` / `packages/db/watchdog_run_safe.mjs`; those files are not on `origin/master`, so this repeats the plan drift. **Rejected**: Update only the live Watchdog `AGENTS.md`; that can fix the local instance, but it is not PR-reviewable and will drift from repo state. **Rejected**: Build a full shared parser library; too broad for a high-priority false positive.

## Steps (Executor follows in order)
1. Create or reuse a clean issue worktree from verified `origin/master` for [KOEA-4857](/KOEA/issues/KOEA-4857); before editing, confirm `git ls-files packages/db/watchdog_run.mjs packages/db/watchdog_run_safe.mjs` is empty so the old plan is not being followed.
2. Edit `scripts/publish-action.sh` line 498 so the final healthy completion log includes `TICK` and preserves the existing completion phrase, e.g. `log "TICK publish-action complete."`.
3. Add a narrow tracked smoke check at `scripts/smoke/publish-action-watchdog-parser.sh` that builds temporary log fixtures and exercises the current Watchdog extraction contract (`tail -n 200 ... | grep -E 'TICK|published' | tail -1`).
4. In that smoke check, assert a fresh `TICK publish-action complete.` line is detected and timestamp-parsed as healthy, and assert missing/no-marker and older-than-10-minute fixtures remain stale.
5. Run `bash scripts/smoke/publish-action-watchdog-parser.sh`, then `bash -n scripts/publish-action.sh scripts/smoke/publish-action-watchdog-parser.sh`, and `git diff --check`.
6. Open the implementation PR with only `scripts/publish-action.sh` and the smoke script changed; mention that the next real launchd run should write `TICK publish-action complete.` to `/paperclip/logs/publish-action.log`.

## Verification (QA Verifier checks these)
- [ ] `bash scripts/smoke/publish-action-watchdog-parser.sh` passes.
- [ ] `bash -n scripts/publish-action.sh scripts/smoke/publish-action-watchdog-parser.sh` passes.
- [ ] The smoke fixture with a recent `TICK publish-action complete.` is classified healthy.
- [ ] Missing/no-marker and older-than-10-minute fixtures are classified stale.
- [ ] PR diff excludes `packages/db/watchdog_run*.mjs`, vault/course/blog files, and learnovaBeast.

## Risk
- This fixes the tracked producer/consumer contract but does not rewrite the live Watchdog instruction to explicitly name `publish-action complete.`. Mitigation: preserve the current parser contract by adding `TICK` to the producer success line, then let Watchdog's existing `TICK|published` match continue to drive stale detection.

## Out of scope
- Refactoring Watchdog Bot into a tracked deterministic script, changing launchd cadence, or repairing unrelated publish-action git push failures seen in the log.
