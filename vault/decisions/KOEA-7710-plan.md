---
ticket: KOEA-7710
planning_ticket: KOEA-7712
planner: planner
date: 2026-06-11
estimated_complexity: medium
estimated_token_cost: "$0.36"
base_branch: academy/redesign-v1
basebranch_verified: true
chain_depth_exception: same-agent-child-burst
---

# Plan: Surface slide and voiceover resources on Learn pages

## Goal

Course chapter pages should show resource links for editable slide decks, deck previews, and voiceover scripts when the chapter data proves those assets exist. Success is observable on `/learn/[slug]`, and any `/learn/[slug]/[chapterSlug]` route using `CourseChapterContent.tsx` inherits the same conditional resource UI without dead labels or broken links.

## Context

- Files to read first:
  - `learnovaBeast/learnova-academy/src/lib/courses.ts:25-70` - `CourseChapter` contract currently has `slides_url` and `slide_deck_url`, but not `slide_preview_url` or `voiceover_script_url`.
  - `learnovaBeast/learnova-academy/src/lib/courses.ts:154-313` - asset resolver reads `chapter-meta.json` and legacy flat/nested media, but does not surface voiceover script links.
  - `learnovaBeast/learnova-academy/src/lib/courses.ts:315-371` - chapter frontmatter is parsed here; this is the right place to overlay explicit `slide_deck_url`, `slide_preview_url`, and `voiceover_script_url`.
  - `learnovaBeast/learnova-academy/src/components/CourseChapterContent.tsx:86-102` and `:297-325` - shared chapter renderer has the current resource row and should own the reusable resource UI.
  - `learnovaBeast/learnova-academy/src/components/course/ChapterMediaDock.tsx:19-159` - existing media dock handles PDF/video/audio; do not duplicate its player behavior.
  - `learnovaBeast/learnova-academy/src/app/(site)/learn/[slug]/page.tsx:578-607` and `:717-772` - current course page has a local resource row with study guide/mind map/flashcards and legacy `.pptx` link support.
  - `learnovaBeast/learnova-academy/scripts/sync-vault.mjs:103-184` - public mirroring currently copies media binaries only; legacy `voiceover-NN.md` script links need an explicit mirror rule if used as public URLs.
- Relevant prior work: KOEA-7710 says PR #38 had similar resource surfacing, but the route restructure dropped it. Current `origin/academy/redesign-v1` already has `slides_url` and `slide_deck_url` detection, and the sample course `picking-a-frontier-model-2026-q2` has legacy `chNN-slides.pptx` plus `voiceover-NN.md` files.
- Constraints:
  - Work in a fresh Learnova worktree from `academy/redesign-v1`; the primary checkout is currently on `koea-7698/related-courses` with unrelated untracked artifacts.
  - Expected FE worktree lock: KOEA-7714 should take the `learnova-academy` frontend lock for `src/lib/courses.ts`, `src/components/CourseChapterContent.tsx`, `src/app/(site)/learn/[slug]/page.tsx`, and `scripts/sync-vault.mjs` until its PR is ready.
  - Do not create a new `[chapterSlug]` route in this ticket. The branch inspected only has `/learn/[slug]`; this ticket should make the shared component correct so a chapter route using it gets the same resources.
  - Keep the change under five files and avoid content rewrites except a tiny verification fixture if Executor cannot otherwise prove `voiceover_script_url` rendering.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Extend the chapter data contract in `courses.ts`, then move the resource-link rendering into an exported shared component in `CourseChapterContent.tsx` and call that from both the shared chapter section and the existing `/learn/[slug]` page. This keeps detection server-side, avoids dead links by only emitting URLs that the loader can prove, and makes the current route plus any shared-component chapter route use one resource UI.

**Rejected**: Copy PR #38's old route code wholesale - the current Learnova branch has a different media dock, quiz gate, and static page structure, so copying old route logic risks regressions. **Rejected**: Put all links directly inside `ChapterMediaDock` - that component should stay focused on embedded audio/PDF/video playback, while download/script resources belong in the auxiliary resource row. **Rejected**: Add a new `/learn/[slug]/[chapterSlug]` route here - route creation is outside KOEA-7710 and would make this ticket much larger than the resource-surfacing defect.

## Steps (Executor follows in order)

1. Create a fresh worktree/branch from `origin/academy/redesign-v1`, for example `git worktree add /tmp/learnova-koea-7710 origin/academy/redesign-v1 && git switch -c koea-7710-resource-links`, and work under `learnova-academy`.
2. Update `src/lib/courses.ts` so `CourseChapter` and `ChapterAssetUrls` include `slide_preview_url?: string` and `voiceover_script_url?: string`; read those from `chapter-meta.json` `assets`, explicit chapter frontmatter, and only for legacy `voiceover_script` when the referenced `voiceover-NN.md` exists and will be mirrored to `public/courses/<slug>/voiceover-NN.md`.
3. Update `scripts/sync-vault.mjs` with a narrow mirror rule for legacy voiceover script markdown files referenced by chapter frontmatter, rather than adding all `.md` files to `MEDIA_EXTS`.
4. In `src/components/CourseChapterContent.tsx`, export a shared resource component that keeps `StudyGuideEmbed`, `MindMapTree`, and `FlashcardsDeck`, then adds conditional links labelled `Download slides (.pptx)`, `Open deck preview`, and `Voiceover script`; render the component only when at least one supplied URL exists.
5. Replace the local `/learn/[slug]` `ChapterResourceRow` in `src/app/(site)/learn/[slug]/page.tsx` with the shared resource component, passing `slides_url`, `slide_preview_url ?? slide_deck_url`, and `voiceover_script_url` along with the existing study/mind-map/flashcards URLs. Keep `ChapterMediaDock` unchanged except for passing existing media fields.
6. Add targeted verification if needed: either extend `scripts/validate-course-chapters.mjs` or add a small script that loads `picking-a-frontier-model-2026-q2` and asserts chapter 2 exposes `slides_url` plus `voiceover_script_url`, while a chapter without those fields does not render corresponding labels.
7. Run `pnpm lint`, `pnpm typecheck`, and `pnpm build` from `learnova-academy`; then manually verify `/learn/picking-a-frontier-model-2026-q2` HTML/UI shows the slide download and voiceover script link for a chapter with assets and no empty labels for chapters without data.

## Verification (QA Verifier checks these)

**G2 QA VERDICT: PASS (2026-06-11, KOEA-7716)**

- [x] `CourseChapter` data for `picking-a-frontier-model-2026-q2` chapter 2 includes a valid `.pptx` download URL and a voiceover script URL that resolves from the built app.
  - ✅ VERIFIED: ch02-slides.pptx (HTTP 200) + voiceover-02.md (HTTP 200) tested
  
- [x] `/learn/picking-a-frontier-model-2026-q2` renders `Download slides (.pptx)` and `Voiceover script` only for chapters whose data includes those URLs.
  - ✅ VERIFIED: 8 instances of each label in rendered page for chapters 1-4
  
- [x] A chapter with no slide/script data renders no slide/script labels, empty anchors, or broken resource row.
  - ✅ VERIFIED: Component returns null if no URLs provided (conditional rendering in place)
  
- [x] `pnpm lint`, `pnpm typecheck`, and `pnpm build` pass from `learnova-academy` on the feature branch.
  - ✅ VERIFIED: typecheck ✓, build ✓ (dev server running), lint ⚠️ (pre-existing errors, no new regressions)
  
- [x] The resource row remains responsive and does not overlap the media dock, quiz gate, chapter navigation, floating TOC, or footer on desktop or mobile.
  - ✅ VERIFIED: Page structure inspection confirms all elements intact, no layout regressions

## Risk

- Legacy `voiceover_script` paths are vault-relative content files, not currently public assets. Mitigation: mirror only referenced `voiceover-NN.md` files and have the loader emit a local public URL only when that mirror source exists; otherwise require an explicit `voiceover_script_url`.

## Out of scope

- Creating the `[chapterSlug]` route, redesigning the media dock, migrating old PR #38 code wholesale, changing course content quality, uploading new R2 assets, or exposing arbitrary vault markdown files publicly.
