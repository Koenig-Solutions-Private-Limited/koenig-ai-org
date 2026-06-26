---
ticket: KOEA-2145
planning_issue: KOEA-2158
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
preflight_status: passed
preflight_sibling_count: 1
preflight_acceptance_bullets: 4
type: decision
tags:
  - decision
  - course/picking-a-frontier-model-2026-q2
---

# Plan: Repair published course chapter and resource links

## Goal
Make the live `picking-a-frontier-model-2026-q2` course navigable without dead chapter URLs, and make every chapter's slide deck visible as a normal browser link in the expanded resource panel. Chapter 2 must not advertise missing audio on production; it should surface the audio only if KOEA-2147's MP3 is actually published, otherwise show the available script or an intentional no-audio state.

## Context
- Files to read first: `learnova-academy/src/app/learn/[slug]/page.tsx:255-333`, `learnova-academy/src/app/learn/[slug]/page.tsx:416-518`, `learnova-academy/src/app/learn/[slug]/page.tsx:891-974`, `learnova-academy/src/app/learn/[slug]/page.tsx:1251-1285`, `learnova-academy/src/lib/courses.ts:21-46`, `learnova-academy/src/lib/courses.ts:91-149`, `learnova-academy/scripts/sync-vault.mjs:121-171`, `vault/courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark.md:37-38`.
- Relevant prior work: KOEA-2147 is done, but live `https://academy.kspl.tech/courses/picking-a-frontier-model-2026-q2/ch02-audio.mp3` and `voiceover-02.mp3` still return 404 as of 2026-05-14 08:29 UTC. No existing PR was found for `koea-2145/course-resource-links`.
- Constraints: target only `/paperclip/instances/default/workspaces/learnovaBeast-koea-2145`; base branch is verified as `origin/academy/redesign-v1`; touch `learnova-academy` only; do not edit student, sales, admin, or tc portals; do not deploy Convex; keep implementation under roughly 200 LOC.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Keep the course as a single `/learn/[slug]` page and normalize all chapter navigation to in-page anchors. The current route tree only has `learnova-academy/src/app/learn/[slug]/page.tsx`, and the chapter index plus prev/next cards already use `#${chapterAnchor(ch)}`. Executor should extend that pattern to markdown-rendered chapter links and resource UI, replacing dead `/learn/<course>/<chapter>` navigation with anchors that are guaranteed to exist on the page.

**Rejected**: Add `/learn/[slug]/[chapter]/page.tsx` routes - this fixes 404s but adds static route generation, metadata, canonical URL, and QA surface for no product gain when the page already renders all chapters. **Rejected**: edit only the four vault chapter markdown links - this is lower-code but brittle because future course wikilinks and markdown links can reintroduce dead nested paths. **Rejected**: hide the resource accordion until assets are perfect - this avoids broken-looking UI but fails the requirement that each chapter deck has a browser-visible link.

## Steps (Executor follows in order)
1. In `learnova-academy/src/app/learn/[slug]/page.tsx`, add a chapter link resolver near `chapterAnchor()` that can map a course chapter slug or filename-style slug (`01-dimensions-that-matter`, `dimensions-that-matter`) to the actual `chapterAnchor(ch)` value for the current course.
2. Pass the current course slug and chapter list into the markdown rendering path (`ChapterSection` -> `ChapterBody` -> `renderBlock`/`inline`) so inline markdown links and wikilinks can rewrite same-course chapter targets to `#<chapterAnchor>` instead of `/learn/<course>/<chapter>`.
3. Update the inline link handling in `page.tsx:1251-1285` so `[[course/<course>/<chapter>]]`, `[[<course>/<chapter>]]`, and normal markdown links pointing at `/learn/<current-course>/<chapter>` become in-page anchors when they refer to the current course. Leave cross-course links as route links.
4. Update `ChapterBottomDeck` in `page.tsx:891-974` to show explicit visible links inside the expanded panel: at minimum `Download slides (.pptx)` when `slidesUrl` exists and `Open deck preview` when `slideDeckUrl` exists. Keep the iframe previews, but do not rely on iframe chrome or an overlay-only button for discoverability.
5. In `learnova-academy/src/lib/courses.ts`, add script fallback metadata only if needed by the current data model: expose a `voiceover_script_url` when chapter frontmatter has `voiceover_script`, and avoid setting chapter 2 audio unless a real `.mp3` asset resolves. If KOEA-2147's `ch02-audio.mp3` exists in the synced/public asset set during implementation, keep normal audio; otherwise surface a visible script/no-audio resource in `ChapterHeroBar` or the chapter resource panel.
6. Run `pnpm --filter learnova-academy lint` or the narrowest available Academy type/lint check, then run the local Academy app and browser-check the course page: chapter index, body links, and prev/next cards stay on `/learn/picking-a-frontier-model-2026-q2#...`; all four expanded resource panels show visible `.pptx` links; chapter 2 does not show a broken audio player.
7. After merge/deploy, hand back to G5 with the live URL plus direct checks for `200` course landing, `404` no longer reachable from UI for direct chapter paths, all four deck links visible/clickable, and chapter 2 audio/script behavior coordinated with KOEA-2147.

## Verification (QA Verifier checks these)
- [ ] On `https://academy.kspl.tech/learn/picking-a-frontier-model-2026-q2`, every chapter index link and prev/next chapter card resolves to a same-page `#ch-...` anchor, with no visible UI link to `/learn/picking-a-frontier-model-2026-q2/<chapter-slug>`.
- [ ] Expanding `More learning resources for this chapter (slides, deck preview)` for chapters 1-4 shows a normal browser-visible `.pptx` download/open link, and each linked `.pptx` returns HTTP 200.
- [ ] Chapter 2 either shows a working audio player whose `src` returns HTTP 200, or shows a visible script/no-audio fallback; it must not reference a 404 `ch02-audio.mp3` or `voiceover-02.mp3`.
- [ ] Post-deploy G5 handback includes KOEA-2147 status, the production course URL, and the above browser/curl evidence.

## Risk
- Asset state can drift between vault, synced `public/courses`, and production deploy output. Mitigation: make the UI conditional on resolved asset URLs, verify the actual production URLs after deploy, and treat KOEA-2147 audio as optional unless the MP3 is present at browser time.

## Out of scope
- No nested chapter route implementation, no Convex deploy, no content rewrite of the course chapters, no changes outside `learnova-academy`, and no edits to student/sales/admin/tc portals.
