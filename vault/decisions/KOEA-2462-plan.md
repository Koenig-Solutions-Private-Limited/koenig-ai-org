---
ticket: KOEA-2462
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.32
base_branch: academy/redesign-v1
basebranch_verified: true
triggered_by_approval: 365ea2fc-2d45-4c03-a1e1-65328aa175b2
---

# Plan: Make course slide/audio URLs match published files

## Goal
Course chapter audio and slide URLs should never point at same-origin `/courses/*` files that are missing from `learnova-academy/public/courses/` after the vault sync step. Success means the course reader resolves assets from either the existing R2-backed `chapter-meta.json` layout or local vault media layouts, the sync script publishes every local file shape it can emit, and a validation command fails the build/publish path when emitted course asset URLs cannot be served.

## Context
- Files to read first: `learnova-academy/src/lib/courses.ts:91-149`, `learnova-academy/scripts/sync-vault.mjs:68-113`, `learnova-academy/src/app/learn/[slug]/page.tsx:450-460`, `learnova-academy/src/app/learn/[slug]/page.tsx:811-819`, `learnova-academy/package.json:4-12`
- Relevant prior work: ticket comment says `chapterAssetUrls` should mirror `sync-vault.mjs`, but current code only falls back to flat vault media after `chapter-meta.json`; `sync-vault.mjs` only copies flat course-root media.
- Constraints: no explicit acceptance criteria were captured; Chief approval `365ea2fc-2d45-4c03-a1e1-65328aa175b2` authorized proceeding from the current description. Keep this scoped to `learnovaBeast/learnova-academy` asset resolution and validation. Base branch verified with `git ls-remote --heads origin academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a shared layout contract between resolver, vault sync, and validation. Keep R2 `chapter-meta.json` URLs as the preferred source, then support local flat and nested chapter media by emitting only URLs that the sync script will copy into `public/courses/<course>/<relative-file>`. Add a small validation script and package script so the same-origin URL/file invariant is checked before publish, with optional remote HEAD checks for absolute R2 URLs when explicitly enabled.

**Rejected**: R2-only migration for every course asset - it requires moving existing vault binaries and upload credentials outside this ticket. Resolver-only change - it could emit nested `/courses/*` URLs that `sync-vault.mjs` still does not publish. Sync-only change - it would not fix missing asset discovery for nested local media when no `chapter-meta.json` exists.

## Steps (Executor follows in order)
1. Update `learnova-academy/src/lib/courses.ts` to resolve chapter assets in this order: valid `chapter-meta.json` asset URLs, flat course-root candidates, then nested `<chapterPrefix>/<candidate>` candidates.
2. Keep returned local URLs path-stable as `/courses/${courseSlug}/${relativePath}` where `relativePath` is either `ch01-slides.pptx` or `01-why-mcp-exists/ch01-slides-v2.pptx`; URI-encode path segments if needed, but do not encode `/`.
3. Update `learnova-academy/scripts/sync-vault.mjs` so `mirrorCourseMedia()` copies media from both the course root and one-level chapter subdirectories into `public/courses/<courseSlug>/...`, preserving nested relative paths.
4. Add `learnova-academy/scripts/verify-course-assets.mjs` that loads publishable courses, inspects `audio_url` and `slides_url`, verifies every relative `/courses/*` URL has a corresponding file in `public/`, and optionally HEAD-checks absolute `http(s)` URLs when `VERIFY_REMOTE_COURSE_ASSETS=1`.
5. Update `learnova-academy/package.json` so the build path runs `sync-vault.mjs` and the local-file validation before `next build`; expose a named script such as `course-assets:check` for QA/publish verification.
6. Add focused fixture coverage inside the verifier script or a minimal colocated test harness for flat and nested layouts, using temporary directories so it does not depend on the developer vault contents.

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
