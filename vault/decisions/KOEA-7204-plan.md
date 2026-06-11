---
ticket: KOEA-7204
planner: planner
date: 2026-06-03
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: academy/redesign-v1
basebranch_verified: true
approval_context: 35a0a75c-ab4e-473b-bcb9-352130700d55
---

# Plan: Split Academy course chapters into route pages

## Goal
Reduce the Academy course page from one giant all-chapters document into a course overview plus individual chapter routes. Success means `/learn/claude-tool-use-from-zero` is a short chapter index, each `/learn/<course>/<chapter>` page renders only one chapter, progress survives reloads in localStorage, and mobile learners can move chapter-to-chapter without returning to the top-level course page.

## Context
- Files to read first: `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:93-124`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:306-383`, `learnova-academy/src/components/CourseChapterContent.tsx:15-23`, `learnova-academy/src/components/CourseChapterContent.tsx:324-386`, `learnova-academy/src/lib/course-progress.ts:7-15`, `learnova-academy/src/components/CourseResumeBanner.tsx:18-44`, `learnova-academy/src/components/ChapterNavCard.tsx:19-59`.
- Relevant prior work: PR #29 / `origin/koea-1243/course-chapter-routes` proved the basic route pattern with `src/app/learn/[slug]/[chapter]/page.tsx`, but it also moved/deleted broad app structure. Its first review found a blocking citation regression: chapter `[^N]` links rendered without reference targets. KOEA-6959 later implemented the same idea directly, then was cancelled as superseded by KOEA-7204.
- Constraints: work only in `learnovaBeast/learnova-academy`; base from `origin/academy/redesign-v1`; wait for the active FE `.claude/agent-lock` before implementation; no Convex deploy; do not touch student, sales, admin, or TC portals; open a draft PR against `academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Reimplement the route split cleanly from current `academy/redesign-v1`. Keep the existing `(site)` App Router structure and current media/reference rendering, replace the live course page's inline `course.chapters.map(...)` with an overview/index, and add a new `[chapter]` route that reuses a current shared chapter renderer. Extend the existing `course-progress-<slug>` localStorage object instead of inventing a second progress store.

**Rejected**: Cherry-pick PR #29 wholesale — it is stale, relocates many routes outside `(site)`, deletes current scripts/components, and predates later audio/PDF/alt-text/SEO fixes; Client-only pagination inside the single page — it would not fix the 73,492px document height, LCP, or direct chapter URLs; Anchor-only tweaks — prev/next anchors already exist and are the UX failure this ticket replaces.

## Steps (Executor follows in order)
1. Create a clean implementation branch from `origin/academy/redesign-v1` after the FE lock clears; do not reuse the dirty local worktree state or the stale PR branch except as reference.
2. Update `src/components/CourseChapterContent.tsx` to be the shared chapter renderer: preserve current `ChapterPlayer`, resource row, `ChapterBody`, references footer, infographic alt handling, and `[^N]` reference targets; export `chapterPath(courseSlug, ch)` and render prev/next targets as `/learn/${courseSlug}/${chapter.slug}`.
3. Update `src/app/(site)/learn/[slug]/page.tsx` so it renders only the hero, learning outcomes, course progress/resume block, and chapter list linking to `chapterPath(...)`; remove the inline all-chapter render loop and pass only overview/course-outline grounding to Nova.
4. Add `src/app/(site)/learn/[slug]/[chapter]/page.tsx` with `generateStaticParams()` over course + chapter slugs, chapter metadata/canonical URL, breadcrumb JSON-LD, `TopBar`, `ChapterProgressBar`, one `CourseChapterSection`, and Nova grounding from only that chapter body.
5. Extend `src/lib/course-progress.ts` to keep the existing key `course-progress-${slug}` with `completedChapterNums` plus `lastPosition: { chapterNum, chapterSlug, scrollY, updatedAt }`; keep writing the legacy `academy-course-progress` percent map for cards that still read it.
6. Update the course progress UI path in `CourseProgressSection`/related client code so the overview list links to route URLs, the resume CTA uses `lastPosition.chapterSlug`, completion checkboxes still toggle `completedChapterNums`, and the active chapter page records last position on load/scroll before unload.
7. Add mobile pagination handling on the chapter route: keep the server-rendered `ChapterNavCard` as the accessible baseline, and add client-side swipe/keyboard route changes only on chapter pages with a conservative horizontal-swipe threshold so vertical reading scroll is not hijacked.

## Verification (QA Verifier checks these)
- [ ] Desktop: `/learn/claude-tool-use-from-zero` renders as an overview/chapter index under 3,000px document height and does not include all chapter bodies, audio players, or PDF iframes inline.
- [ ] Desktop: one chapter URL such as `/learn/claude-tool-use-from-zero/<chapter-slug>` renders a single chapter under 12,000px document height with media, citations, references, and prev/next route links intact.
- [ ] Progress: marking a chapter complete updates `localStorage["course-progress-claude-tool-use-from-zero"].completedChapterNums`, scrolling/visiting records `lastPosition`, and the overview resume CTA returns to the recorded chapter.
- [ ] Mobile viewport: chapter pages have no horizontal overflow, prev/next controls fit, and left/right swipe pagination changes to adjacent chapter routes without interrupting vertical scroll.
- [ ] Commands: `cd learnova-academy && pnpm typecheck`; `cd learnova-academy && pnpm lint`; `cd learnova-academy && pnpm build` or document any unrelated vault-content blocker exactly.

## Risk
- The highest risk is losing current chapter rendering behavior while extracting it from the live page. Mitigation: extract from current `origin/academy/redesign-v1`, explicitly verify `[^N]` reference targets and media rows on a chapter page, and do not copy PR #29's older `_shared/chapter-render.tsx` wholesale.

## Out of scope
- No Convex progress persistence, authentication, enrollment model, deployment, sitemap/llms discovery expansion, or portal work outside `learnova-academy`.
