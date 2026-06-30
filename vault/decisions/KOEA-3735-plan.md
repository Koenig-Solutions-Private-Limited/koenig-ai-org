---
ticket: KOEA-3735
planner: planner
date: 2026-06-27
estimated_complexity: small
estimated_token_cost: $0.25
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: a549361d-26b8-4aa0-833f-df67e6652f21
revision: 2
triggered_by_comment: 09967663-ef86-44c2-9beb-7cc2c121c445
---

# Plan: Restore claude-tool-use-from-zero ch02 slide public mirror

## Goal
Make `https://academy.kspl.tech/courses/claude-tool-use-from-zero/ch02-slides.pptx` return the slide deck that already exists in the vault. Success is observable as HTTP 200 for the public PPTX URL, with byte count matching the vault artifact, while keeping the fix scoped to the Academy public mirror/sync-vault path.

## Context
- Files to read first: `learnova-academy/scripts/sync-vault.mjs:35-184`, `learnova-academy/src/lib/courses.ts:300-443`, `learnova-academy/public/.gitignore:1-4`, `learnova-academy/next.config.ts:143-154`, `vault/courses/claude-tool-use-from-zero/02-understanding-mcp/chapter-meta.json`
- Relevant prior work: KOEA-3735 parent ticket; KOEA-7556/KOEA-8337 comments in `next.config.ts` explain why `public/courses` is generated at build time and excluded from function tracing.
- Constraints: do not commit `learnova-academy/public/courses/**`; keep the work on `learnovaBeast` `academy/redesign-v1`; keep sidecar-covered audio/video suppression intact to avoid Vercel bundle bloat; downstream KOEA-7943/7944/7945/7946 must wait for plan approval.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Fix the `sync-vault.mjs` sidecar skip so flat chapter PPTX decks remain publishable. `chapter-meta.json` for chapter 02 makes `sync-vault.mjs` add both `02-understanding-mcp` and `ch02` to `sidecarPrefixes`; the current `coveredBySidecar()` then skips root-level `ch02-slides.pptx`, even though KOEA-3735 requires the same-origin public URL. Executor should make a narrow mirror-rule change: keep suppressing large sidecar-covered media such as `.mp3`, but allow lightweight root-level flat slide decks like `chNN-slides.pptx` and `chNN-slides-v2.pptx` to copy into `public/courses/<slug>/`.

**Rejected**: Deploy-only backfill - plan review found `sync-vault.mjs` can skip the file on a clean build, so deploy alone may reproduce the 404. **Rejected**: Remove or edit `chapter-meta.json` - sidecars are the R2-canonical path for other assets and should remain. **Rejected**: Commit the PPTX into `public/courses` - `learnova-academy/public/.gitignore` explicitly excludes generated course media to avoid repository bloat.

## Steps (Executor follows in order)
1. In `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`, work from `academy/redesign-v1` and inspect `learnova-academy/scripts/sync-vault.mjs` around `sidecarPrefixes` and `coveredBySidecar()`.
2. Edit only `learnova-academy/scripts/sync-vault.mjs` so sidecar-covered root flat PPTX slide decks matching `chNN-slides*.pptx` are not skipped, while sidecar-covered `.mp3` and other large duplicate media remain skipped.
3. Add or update the smallest relevant verifier in `learnova-academy/scripts/` if existing tests do not cover this: it should simulate/read a sidecar-covered `ch02` case and assert `ch02-slides.pptx` is eligible for the mirror while `ch02-audio.mp3` remains suppressed.
4. From `learnova-academy/`, remove any stale local target `public/courses/claude-tool-use-from-zero/ch02-slides.pptx`, then run `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault node ./scripts/sync-vault.mjs`.
5. Verify the generated mirror matches the vault source with `wc -c` and `shasum -a 256` for both `public/courses/claude-tool-use-from-zero/ch02-slides.pptx` and `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-tool-use-from-zero/ch02-slides.pptx`.
6. Run the targeted verifier from step 3 plus the existing cheap Academy test path that includes sync-vault media guards, for example `pnpm test` from `learnova-academy/` if dependency state permits.
7. Open the implementation PR against `academy/redesign-v1`; after merge/deploy, verify production with `curl -I -L https://academy.kspl.tech/courses/claude-tool-use-from-zero/ch02-slides.pptx` and confirm HTTP 200 plus `content-length` near `37302`.

## Verification (QA Verifier checks these)
- [ ] `curl -I -L https://academy.kspl.tech/courses/claude-tool-use-from-zero/ch02-slides.pptx` returns HTTP 200, not `/404`.
- [ ] Clean local mirror regeneration after deleting the target recreates `learnova-academy/public/courses/claude-tool-use-from-zero/ch02-slides.pptx` with the same hash as the vault artifact.
- [ ] The targeted verifier proves sidecar-covered PPTX decks mirror while sidecar-covered audio remains suppressed.

## Risk
- Loosening sidecar suppression too broadly could reintroduce the large `public/courses` bundle problem; mitigate by allowing only root flat PPTX slide decks and explicitly testing that audio remains suppressed.

## Out of scope
- Reworking course asset URL generation, adding a new asset CDN, changing R2 chapter metadata, uploading assets to R2, or committing generated media binaries.
