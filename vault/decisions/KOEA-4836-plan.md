---
ticket: KOEA-4869
parent_issue: KOEA-4836
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: academy/redesign-v1
chain_alert_resolved: ae3db41e-1929-45ef-a5ee-ce8c24456d37
---

# Plan: Restore and harden the ch02 slide public mirror

## Goal
Restore the `claude-tool-use-from-zero` chapter 02 slide deck in the Learnova Academy public course mirror and prevent the same sync path from damaging Paperclip task vault workspaces. Success is observable as matching size and SHA-256 between the vault source deck and `learnova-academy/public/courses/claude-tool-use-from-zero/ch02-slides.pptx`, plus a tracked reliability fix if `sync-vault.mjs` is touched.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/scripts/sync-vault.mjs:1-210`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts:90-175`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/public/.gitignore:1-4`
- Source deck: `/paperclip/tmp/koea1551/koenig-ai-org/vault/courses/claude-tool-use-from-zero/ch02-slides.pptx`, restored from canonical `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-tool-use-from-zero/ch02-slides.pptx`; expected size `36728` bytes and SHA-256 `b8dc33b55546d938dba28ddbdeee2ebb8a33d1eda1ec433adf018a9c11403749`
- Target mirror: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/public/courses/claude-tool-use-from-zero/ch02-slides.pptx`; currently present with matching size and SHA-256, but `public/courses/` is intentionally ignored
- Relevant prior work: KOEA-4820 recovery found the source artifact; KOEA-2371 is the source slides issue; planner chain alert `ae3db41e-1929-45ef-a5ee-ce8c24456d37` was resolved as an authorized sequential gate chain
- Constraints: `learnovaBeast` is dirty and ahead/behind `origin/academy/redesign-v1`; Executor must preserve unrelated changes, acquire/observe `.claude/agent-lock`, and must not force-add ignored `public/courses/` binaries unless Chief Engineering explicitly overrides the ignore policy

## Approach (1 chosen, alternatives rejected)
**Chosen**: Verify or restore the generated mirror, then harden `sync-vault.mjs` only for the reliability issue found during planning. The mirror file is generated build output, so Executor should ensure it exists locally and verify the checksum, while committing only a small tracked script fix that prevents `KOENIG_VAULT_ROOT=/paperclip/tmp/.../koenig-ai-org/vault` from causing the script to attempt `rm -rf` on a Paperclip task workspace. Keep Vercel's `/tmp/koenig-vault` fresh-clone behavior intact.

**Rejected**: Force-add `learnova-academy/public/courses/.../ch02-slides.pptx` despite `.gitignore` because the repo explicitly avoids committing course media binaries; commit a one-off copied deck into another public directory because `courses.ts` resolves legacy slides from `/courses/<slug>/chNN-slides.pptx`; rewrite the course asset resolver because the current resolver already checks `ch02-slides.pptx`.

## Steps (Executor follows in order)
1. In `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`, acquire or wait for `.claude/agent-lock`, fetch `origin`, create a branch from `academy/redesign-v1`, and record the pre-existing dirty files before changing anything.
2. Verify the source and target with `stat -c '%n %s bytes'` and `shasum -a 256`; if the target is missing or mismatched, copy the source deck to `learnova-academy/public/courses/claude-tool-use-from-zero/ch02-slides.pptx` for the local generated mirror but do not stage that ignored file.
3. Patch `learnova-academy/scripts/sync-vault.mjs` so the protected-root guard covers Paperclip task vault checkouts such as `/paperclip/tmp/*/koenig-ai-org/vault`, while preserving removable clone behavior for `/tmp/koenig-vault/vault` on Vercel.
4. While editing `sync-vault.mjs`, fix the copy failure warning to reference an in-scope value such as `src` or `dstName` instead of the undefined `file` identifier.
5. Run the smallest verification: `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault node ./scripts/sync-vault.mjs`, then repeat `stat` and `shasum` for source and target and confirm `git status --short --ignored -- learnova-academy/public/courses/claude-tool-use-from-zero/ch02-slides.pptx` still reports it as ignored generated output.
6. Commit only tracked changes, open a draft PR against `academy/redesign-v1` using `.github/PULL_REQUEST_TEMPLATE.md`, and include the checksum evidence plus the note that the mirror binary is intentionally not committed.

## Verification (QA Verifier checks these)
- [ ] `learnova-academy/public/courses/claude-tool-use-from-zero/ch02-slides.pptx` exists and is `36728` bytes.
- [ ] Source and target SHA-256 are both `b8dc33b55546d938dba28ddbdeee2ebb8a33d1eda1ec433adf018a9c11403749`.
- [ ] Running `sync-vault.mjs` with the canonical local vault root does not delete or reclone a protected workspace and leaves the ch02 mirror available.
- [ ] The PR contains only tracked script changes and does not force-add `learnova-academy/public/courses/`.

## Risk
- The sync guard could accidentally disable Vercel's intended fresh clone. Mitigation: keep the new protected pattern scoped to Paperclip workspace paths and explicitly verify `/tmp/koenig-vault/vault` is still outside the protected set.

## Out of scope
- Reworking the full course asset pipeline, moving slides to R2, changing chapter metadata, or committing all public course media binaries.

Preflight: status=pass; sibling_chain=authorized_by_ae3db41e-1929-45ef-a5ee-ce8c24456d37; acceptance_spec=pass; basebranch_verified=true.
