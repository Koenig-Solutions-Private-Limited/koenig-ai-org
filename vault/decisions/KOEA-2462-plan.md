---
ticket: KOEA-2462
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.32
base_branch: academy/redesign-v1
basebranch_verified: true
triggered_by_approval: 365ea2fc-2d45-4c03-a1e1-65328aa175b2
revision: 2
revised_at: 2026-05-14T14:54:00Z
---

# Plan: Make course slide/audio URLs match published files

## Goal
Course chapter audio and slide URLs should never point at same-origin `/courses/*` files that are missing from `learnova-academy/public/courses/` after the vault sync step. Success means the course reader resolves assets from either the existing R2-backed `chapter-meta.json` layout or local vault media layouts, the sync script publishes every local file shape it can emit, and a validation command fails the build/publish path when emitted course asset URLs cannot be served.

## Context
- Files to read first: `learnova-academy/src/lib/courses.ts:91-149`, `learnova-academy/scripts/sync-vault.mjs:68-113`, `learnova-academy/src/app/learn/[slug]/page.tsx:450-460`, `learnova-academy/src/app/learn/[slug]/page.tsx:811-819`, `learnova-academy/package.json:4-12`
- Relevant prior work: the prior claimed `Fix in PR ''` maps to LearnovaBeast PR #46, `https://github.com/Koenig-Solutions-Private-Limited/learnovaBeast/pull/46`, merged to `academy/redesign-v1` at merge commit `94b4957e` with KOEA-2462 commit `281524ef`. That PR updates `chapterAssetUrls` to handle flat and nested vault layouts. Current `origin/academy/redesign-v1` also has `sync-vault.mjs` flattening nested media into `public/courses/<slug>/chNN-*`.
- Constraints: no explicit acceptance criteria were captured; Chief approval `365ea2fc-2d45-4c03-a1e1-65328aa175b2` authorized proceeding from the current description. Keep this scoped to `learnovaBeast/learnova-academy` asset resolution and validation. Base branch verified with `git ls-remote --heads origin academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Treat PR #46 as the baseline implementation and avoid duplicating it. Executor should first fetch `origin/academy/redesign-v1` and confirm PR #46's `chapterAssetUrls` change plus the current `sync-vault.mjs` nested-media flattening are present. If they are present, implement only the missing validation/smoke-check path and attach PR #46 as the concrete prior fix; if the executor workspace is stale, update it from `origin/academy/redesign-v1` before adding validation.

**Rejected**: R2-only migration for every course asset - it requires moving existing vault binaries and upload credentials outside this ticket. Resolver-only change - it could emit nested `/courses/*` URLs that `sync-vault.mjs` still does not publish. Sync-only change - it would not fix missing asset discovery for nested local media when no `chapter-meta.json` exists.

## Steps (Executor follows in order)
1. Fetch `learnovaBeast` refs and confirm PR #46 is on `origin/academy/redesign-v1`: `git fetch origin academy/redesign-v1` then `git merge-base --is-ancestor 281524ef origin/academy/redesign-v1`.
2. Inspect `origin/academy/redesign-v1:learnova-academy/src/lib/courses.ts` and `origin/academy/redesign-v1:learnova-academy/scripts/sync-vault.mjs`; if the flat+nested resolver or nested-media flattening is missing in the working branch, update the branch from `origin/academy/redesign-v1` before proceeding.
3. Add `learnova-academy/scripts/verify-course-assets.mjs` that loads publishable courses, inspects rendered `audio_url` and `slides_url`, verifies every relative `/courses/*` URL has a corresponding file in `public/`, and optionally HEAD-checks absolute `http(s)` URLs when `VERIFY_REMOTE_COURSE_ASSETS=1`.
4. Update `learnova-academy/package.json` so the build path runs `sync-vault.mjs` and the local-file validation before `next build`; expose a named script such as `course-assets:check` for QA/publish verification.
5. Add focused fixture coverage inside the verifier script or a minimal colocated test harness for flat and nested layouts, using temporary directories so it does not depend on the developer vault contents.
6. In the final handoff, cite PR #46 and state whether the executor implemented only validation or also had to refresh/cherry-pick the already-merged asset resolver changes.

## Verification (QA Verifier checks these)
- [ ] `cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && node ./scripts/sync-vault.mjs && node ./scripts/verify-course-assets.mjs` exits 0 and reports no missing relative course assets.
- [ ] The MCP course chapter 1 resolves either absolute R2 URLs from `chapter-meta.json` or local nested URLs that exist under `public/courses/mcp-from-first-principles-to-production/01-why-mcp-exists/`.
- [ ] The Claude tool-use course chapter 8 still resolves `/courses/claude-tool-use-from-zero/ch08-slides.pptx`, and that file exists after sync.
- [ ] `cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && pnpm build` reaches Next build after the asset validation step.

## Risk
- Validation may fail on existing partially-produced courses that have metadata pointing to not-yet-uploaded R2 assets. Mitigation: default the build validation to deterministic local `/courses/*` file checks, and gate remote HEAD checks behind `VERIFY_REMOTE_COURSE_ASSETS=1` for publish QA.

## Out of scope
- Re-uploading or migrating all course media to R2.
- Changing the course page media UI beyond consuming the corrected URLs.
- Editing vault course content or generated audio/slide binaries.
