---
ticket: KOEA-2739
planner: planner
planner_issue: KOEA-3015
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Restore claude-tool-use-from-zero chapter 03 audio public mirror

## Goal
Restore the generated public audio path for `claude-tool-use-from-zero` chapter 03 so `/courses/claude-tool-use-from-zero/ch03-audio.mp3` is present after the Academy vault sync. Success is observable by a fresh sync/build producing the file from `vault/courses/claude-tool-use-from-zero/ch03-audio.mp3`, while existing course media paths remain unchanged.

## Context
- Files to read first: `learnova-academy/scripts/sync-vault.mjs:23-39`, `learnova-academy/scripts/sync-vault.mjs:103-172`, `learnova-academy/src/lib/courses.ts:91-150`, `learnova-academy/package.json:5-13`, `learnova-academy/public/.gitignore:1-4`, `vault/courses/claude-tool-use-from-zero/03-building-your-first-mcp-server-meta.md:1-13`
- Relevant prior work: `learnovaBeast` commit `8a71437a` added nested media mirroring; `koenig-ai-org` commit `2de20f0a1` added `vault/courses/claude-tool-use-from-zero/ch03-audio.mp3`; parent issue comment `c4a3b5db` created this Planner child because the parent is blocked on a plan.
- Constraints: do not commit `learnova-academy/public/courses/*` because it is generated and ignored; use `origin/academy/redesign-v1` for Academy code; no Convex deploy is needed; use an isolated worktree if the shared FE checkout is locked.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Treat the missing chapter 03 file as stale generated mirror/deploy state, then add the smallest guard that proves the sync keeps flat vault audio assets mirrored. Planner verified the vault source exists and is tracked, `sync-vault.mjs` already copies flat `.mp3` files into `public/courses/<slug>/`, `courses.ts` already resolves `ch03-audio.mp3`, and a current local generated mirror contains a size-matching chapter 03 MP3. Executor should reproduce from a clean generated mirror, fix only if the reproduction fails, and otherwise ship a targeted regression check or operational redeploy note rather than committing generated binaries.
**Rejected**: Commit `public/courses/claude-tool-use-from-zero/ch03-audio.mp3` - rejected because `public/courses/` is intentionally gitignored and regenerated. **Rejected**: Change course rendering to hard-code an audio URL - rejected because `courses.ts` already resolves the canonical flat asset name and hard-coding would bypass the sync contract.

## Steps (Executor follows in order)
1. Create or use an isolated `learnovaBeast` worktree on `origin/academy/redesign-v1`; in `learnova-academy`, remove only the generated folder `public/courses/claude-tool-use-from-zero` to prove the mirror can be recreated.
2. Run `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault node ./scripts/sync-vault.mjs` from `learnova-academy`, then verify `public/courses/claude-tool-use-from-zero/ch03-audio.mp3` exists and has the same byte size as the vault source.
3. If step 2 fails, patch `learnova-academy/scripts/sync-vault.mjs` in the file discovery/copy block so flat course media files named `chNN-audio.mp3` are always copied to `public/courses/<slug>/`; keep the existing nested-layout behavior intact.
4. Add a focused regression check in `learnova-academy` for the sync contract, preferably a small script or test that runs sync against the local vault and asserts chapter 03 audio plus at least one adjacent existing asset are present with matching sizes.
5. Confirm `learnova-academy/src/lib/courses.ts` still reports chapter 03 `audio_url` as `/courses/claude-tool-use-from-zero/ch03-audio.mp3`; only patch it if the sync succeeds but the URL is still absent.
6. Do not commit generated files under `learnova-academy/public/courses/`; if no source-code fix is needed, document that the restore path is rerunning the sync/build or redeploying Academy after the vault commit that added the MP3.

## Verification (QA Verifier checks these)
- [ ] From a clean generated mirror, `node ./scripts/sync-vault.mjs` recreates `learnova-academy/public/courses/claude-tool-use-from-zero/ch03-audio.mp3`.
- [ ] `stat -c '%s'` reports the same byte size for the public mirror file and `vault/courses/claude-tool-use-from-zero/ch03-audio.mp3`.
- [ ] Existing course assets such as `ch01-audio.mp3`, `ch02-audio.mp3`, and `ch06-slides.pptx` are still present after sync.
- [ ] A build-time or local route check confirms chapter 03 renders an audio URL of `/courses/claude-tool-use-from-zero/ch03-audio.mp3`.

## Risk
- The public mirror may be present locally but still absent in the deployed site if Vercel has not rebuilt against the vault commit containing `ch03-audio.mp3`; mitigate by recording the vault commit used by sync and triggering a fresh Academy build after the fix or verification.

## Out of scope
- Producing new audio, changing Convex data, committing generated public media binaries, or refactoring the course asset model beyond the chapter 03 restore path.

Pre-flight: status=passed; chain_depth=2; active_siblings=0; acceptance_criteria=passed; basebranch_verified=true.
