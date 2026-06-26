---
ticket: KOEA-2319
planner: planner
agent: planner
date: 2026-05-14
type: decision
tags:
  - decision
estimated_complexity: small
estimated_token_cost: $0.52
base_branch: academy/redesign-v1
basebranch_verified: true
revision: 2
reviewer_block_comment: 86f14240-623b-4e5a-9dde-ea543748c963
chain_alert_approval: d571bfab-94fc-491d-b7b1-74ebd558bd97
---

# Plan: Fix recursive course media mirroring

## Goal
`learnova-academy/scripts/sync-vault.mjs` should mirror every supported course media file from the vault into `learnova-academy/public/courses/<slug>/`, including media inside nested chapter directories. Success is observable when flat media keeps its current public path and nested media such as `mcp-from-first-principles-to-production/01-why-mcp-exists/ch01-audio-v2.mp3` exists under the same relative path in `public/courses/`.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/scripts/sync-vault.mjs:102-171`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts:91-149`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json:5-13`.
- Current code state: `mirrorCourseMedia()` has a partial one-level nested branch, but it flattens nested files into `<slug>/chNN-*`, only scans chapter directories matching `/^\d+-/`, and logs `file` in a catch block where `file` is undefined.
- Relevant prior work: KOEA-2319 parent describes recurring `vault_sync_lag` escalations from nested media 404s; dispatch reserved `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` on `academy/redesign-v1`; plan review comment `86f14240-623b-4e5a-9dde-ea543748c963` requested this revision because the prior vault plan disagreed with the issue plan on `src/lib/courses.ts` scope.
- Constraints: stay inside `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`; base branch is `academy/redesign-v1` and was verified on origin; do not delete existing untracked `.pnpm-store/`, `.claude/`, or `learnova-academy/public/slides/`; do not commit generated mirrored media.
- PR branch policy: Executor should branch from `academy/redesign-v1`, keep the diff limited to `learnova-academy`, and fill the repository PR template. The PR body should call out that this preserves relative nested media paths and keeps flat legacy media compatible.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Replace the partial one-level copy logic inside `mirrorCourseMedia()` with a small recursive media collector that walks each course directory, skips dot entries, filters only `MEDIA_EXTS`, and copies each file to `public/courses/<slug>/<relative-path-from-courseDir>`. This keeps flat layouts unchanged, preserves nested chapter paths exactly, fixes the undefined warning variable, and confines the implementation to the build-time sync script.

**Rejected**: Keep flattening nested chapter media into `chNN-*` names, because that conflicts with KOEA-2319's relative-path requirement and can hide missing nested static files. Rejected: change `src/lib/courses.ts::chapterAssetUrls()` in this ticket, because the current chapter sidecar/R2 URL behavior is a separate product surface and the plan-review gate requires the canonical plan to keep it out of scope.

## Steps (Executor follows in order)
1. In `learnova-academy/scripts/sync-vault.mjs`, update the `node:path` import to include helpers needed for relative-path mirroring, such as `relative`, `dirname`, and `extname`.
2. Replace the `itemsToCopy` construction inside `mirrorCourseMedia()` with a recursive helper that walks all descendant directories under `courseDir`, ignores dot-prefixed entries, and collects only files whose lowercase extension is in `MEDIA_EXTS`.
3. In the copy loop, compute `relPath = relative(courseDir, src)` and copy to `join(PUBLIC_COURSES, slug, relPath)`, creating `dirname(dst)` instead of only the course root directory.
4. Preserve the existing stale-copy optimization based on destination mtime and size, and change the warning message to reference `src` or `relPath` instead of the undefined `file`.
5. Run a narrow fixture verification with a temporary `KOENIG_VAULT_ROOT` containing one flat course and one nested course; check that flat output lands at `public/courses/<flat-slug>/<file>` and nested output lands at `public/courses/<nested-slug>/<chapter-dir>/<file>`.
6. Run the real-vault smoke check with `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault node ./scripts/sync-vault.mjs` from `learnova-academy`, then confirm the MCP nested files and `picking-a-frontier-model-2026-q2` flat files exist under `public/courses/`.
7. Before PR handoff, run `pnpm lint` from `learnova-academy`; leave generated `public/courses` outputs and `.env.local` unstaged unless the repo already tracks a touched file.

## Verification (QA Verifier checks these)
- [ ] Temporary fixture run proves `.mp3`, `.pptx`, `.pdf`, `.m4a`, and `.wav` files are copied recursively while unsupported files are ignored.
- [ ] Real-vault smoke run creates `public/courses/mcp-from-first-principles-to-production/01-why-mcp-exists/ch01-audio-v2.mp3` and `public/courses/mcp-from-first-principles-to-production/01-why-mcp-exists/ch01-slides-v2.pptx`.
- [ ] Real-vault smoke run still preserves flat outputs such as `public/courses/picking-a-frontier-model-2026-q2/ch01-audio.mp3` and `public/courses/picking-a-frontier-model-2026-q2/ch01-slides.pptx`.
- [ ] `pnpm lint` passes in `learnova-academy`.

## Risk
- Existing stale flattened public files may remain locally after the new recursive mirror runs. Mitigation: do not add cleanup in this ticket; verify the required nested paths exist and leave broader generated-asset cleanup to a separate ticket if needed.

## Out of scope
- Changing `src/lib/courses.ts` chapter URL selection, R2 `chapter-meta.json` behavior, or frontend course rendering.
- Deleting existing generated or untracked media directories.
- Changing the vault clone/auth flow in `ensureClone()`.

## Acceptance criteria
- Nested course media is mirrored recursively with relative paths preserved under `public/courses/<courseSlug>/`.
- Flat legacy media still mirrors and serves from `public/courses/<courseSlug>/`.
- All supported `MEDIA_EXTS` are included: `.mp3`, `.pptx`, `.pdf`, `.m4a`, `.wav`.
- Unsupported files, dotfiles, and non-course folders are ignored.
- Verification covers both flat and nested layouts.
- Executor opens the implementation PR from `academy/redesign-v1` and fills the repository PR template.

## Executor handoff
Use `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` on base branch `academy/redesign-v1`. Pre-flight telemetry: status_verified=true, assignee_verified=true, sibling_chain_ok=true, spec_verified=true, basebranch_verified=true.
