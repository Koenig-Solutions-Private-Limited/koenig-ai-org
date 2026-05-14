---
ticket: KOEA-2230
incident: KOEA-2213
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.30
base_branch: master
basebranch_verified: true
revision: 1
---

# Plan: fix publish-action Phase 0 deleted-file guard crash

## Goal
Restore the active `publish-action` scheduler loop so staged deleted vault markdown paths no longer crash Phase 0 before Phase 1/2 can run. Success means the guard ignores or safely skips deleted staged files, logs its decision, preserves the current no-secret/no-push operational constraints for agent verification, and leaves a clear path to keep the tracked repo script and deployed script from drifting again.

## Context
- Files to read first: `/paperclip/scripts/publish-action.sh:199-264`, `/paperclip/scripts/publish-action.sh:282-340`, `scripts/publish-action.sh:13-193`, `/paperclip/logs/publish-action.log` recent tail, KOEA-2213 latest comment.
- Relevant prior work: KOEA-2213 triage found the active log at `/paperclip/logs/publish-action.log` and identified crashes after `Phase 0: N vault file changes detected`; `bash -n /paperclip/scripts/publish-action.sh` and `bash -n scripts/publish-action.sh` already pass.
- Constraints: `origin/master` is the verified base branch; do not push `koenig-ai-org` from the agent runtime; do not print or expose `PAPERCLIP_API_KEY`, `PAPERCLIP_BOARD_TOKEN`, `GH_PAT_DISPATCH`, or Telegram tokens; do not clean unrelated dirty vault files; keep the fix scoped to publish-action guard behavior and deployment sync.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Patch the Phase 0 guard at the source of the crash by making `verify_no_pending_g4_publish` enumerate only staged added/copied/modified/renamed vault markdown paths and by adding a defensive file-exists check before reading the working-tree path. Then safely sync the validated active script back into the tracked source, because the tracked `scripts/publish-action.sh` currently lacks the deployed Phase 0 code and cannot receive the guard fix directly without first reconciling that drift. Executor should create timestamped backups before changing `/paperclip/scripts/publish-action.sh`, validate both copies, and only then replace the deployed script; verification must not invoke a real push.

**Rejected**: Only add `[[ -f "$F" ]]` around the `awk` call, because deleted paths would stop crashing but the guard would still enumerate files it should never inspect. **Rejected**: Only change `git diff --cached --diff-filter=ACMR`, because a second existence check is cheap protection against race conditions between staging and guard execution. **Rejected**: Patch only `/paperclip/scripts/publish-action.sh`, because the next tracked-script deployment could reintroduce the crash or lose the existing Phase 0 hardening.

## Steps (Executor follows in order)
1. In `/paperclip/scripts/publish-action.sh`, update `verify_no_pending_g4_publish` so the `staged` command is `git diff --cached --name-only --diff-filter=ACMR -- vault/ | grep -E ... || true`, preserving the existing vault blog/course regex.
2. In the same function, before computing `NEW`, add a defensive readable-file check for `"$F"`; if absent, log a concise `guard: skip missing staged file=$F` line and `continue` without adding a block or calling `awk`.
3. Re-run `bash -n /paperclip/scripts/publish-action.sh`, then copy the fixed deployed script into `scripts/publish-action.sh` only after making timestamped backups of both paths; preserve executable mode and do not copy any env file or secret material.
4. Create a small fixture verification script or one-off documented shell fixture that initializes a temporary git repo, stages a deleted `vault/courses/.../.!tmp.md` path plus one normal markdown change, and proves the guard path exits 0 without reading the deleted file. Stub or disable network, commit, and push paths; do not run the live script in a way that can push.
5. Run `bash -n scripts/publish-action.sh` and `bash -n /paperclip/scripts/publish-action.sh`, then compare the two script hashes so the tracked and active deployed copies match after the fix.
6. If a manual one-shot is safe, run it only with push disabled by the fixture/stub mechanism and confirm logs progress past Phase 0 into Phase 1/2 or `publish-action complete`; otherwise state that live one-shot was skipped because the current script has no dry-run mode and pushing is forbidden.
7. Leave KOEA-2213/KOEA-2230 implementation notes with changed paths, backup paths, syntax/fixture results, script hash comparison, and current `git status --short` so unrelated dirty vault files remain visibly separate.

## Verification (QA Verifier checks these)
- [ ] Deleted staged vault markdown fixture exits 0 and logs a skip instead of failing under `set -e`.
- [ ] `bash -n scripts/publish-action.sh` passes.
- [ ] `bash -n /paperclip/scripts/publish-action.sh` passes.
- [ ] `shasum -a 256 scripts/publish-action.sh /paperclip/scripts/publish-action.sh` shows matching script contents after Executor sync.
- [ ] No command in the report pushes `koenig-ai-org`, prints secrets, or mutates unrelated vault files.

## Risk
- Risk: syncing the tracked script from the active deployed script may accidentally preserve host-specific paths such as `REPO_ROOT="/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org"` in repo source. Mitigation: Executor must call this out in the implementation report; for this outage fix, preserving the deployed script exactly is safer than reconstructing Phase 0 from the stale tracked file. A follow-up can parameterize paths after the scheduler is healthy.

## Out of scope
- Reworking publish-state semantics, changing learnovaBeast workflows, rotating tokens, solving existing non-fast-forward push failures, cleaning unrelated staged/deleted vault content, or adding a full dry-run architecture beyond the minimal fixture needed to prove this crash fix.

## Pre-flight
- status_verified=true
- active_sibling_count=0
- chain_depth=2
- acceptance_spec=5_planner_deliverable_bullets_in_issue_description
- basebranch_verified=true origin/master
