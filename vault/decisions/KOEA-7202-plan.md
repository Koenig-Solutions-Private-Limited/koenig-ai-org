---
ticket: KOEA-7202
planner: planner
date: 2026-06-02
estimated_complexity: medium
estimated_token_cost: $0.32
base_branch: academy/redesign-v1
basebranch_verified: true
plan_issue: KOEA-7210
---

# Plan: Add home page imagery and stronger visual hierarchy

## Goal
Make the Koenig AI Academy home page feel visually credible on first load by adding real image elements to the hero, vendor strip, course-of-the-day card, This Week in AI cards, and footer brand area. Success is observable on `/`: at least 6 descriptive `<img>` elements render above 1000px scroll, mobile layout does not overlap, and the change stays scoped to the FE worktree with no Convex deploys or other portal changes.

## Context
- Files to read first: `learnova-academy/src/app/(site)/page.tsx:84-216`, `learnova-academy/src/components/_shared/content.tsx:400-635`, `learnova-academy/src/components/_shared/chrome.tsx:243-271`, `learnova-academy/src/components/_shared/footer.tsx:12-149`, `learnova-academy/src/app/academy.css:356-415`, `learnova-academy/package.json:5-16`
- Relevant prior work: parent issue KOEA-7202 audit found 0 `<img>` elements on `/`; Chief Engineering dispatched KOEA-7210 for Planner and KOEA-7211 for plan review.
- Constraints: FE worktree only under `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`; base branch `academy/redesign-v1` verified on origin; no Convex deploys; no changes to other portals. Local status includes unrelated untracked `.qa-koea-5152/`, which Executor should leave untouched.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small local asset system and use actual image tags in the existing home page surfaces. Create brand/vendor/hero assets under `learnova-academy/public/img/academy/`, add a typed vendor image mapping near the existing vendor data or shared chrome helper, then update the home page and shared card/footer components to render images with stable dimensions, descriptive alt text, eager loading only for the above-fold hero, and lazy loading for below-fold/supporting imagery.

**Rejected**: Use only CSS backgrounds and inline SVG marks; this preserves the current visual style but fails the explicit `<img>` acceptance check. **Rejected**: Pull remote vendor logos/photos at runtime; this adds network/privacy/performance variability and makes Lighthouse harder to keep stable. **Rejected**: Rewrite the landing page into a new marketing layout; the ticket asks for imagery and hierarchy, not a wholesale redesign.

## Steps (Executor follows in order)
1. Add local assets under `learnova-academy/public/img/academy/`: one optimized hero illustration/image around 600x400, grayscale vendor logos for Anthropic/OpenAI/Google AI/Cloudflare/Cursor, and a Koenig footer brand mark; keep file names stable and lowercase.
2. Update `learnova-academy/src/components/_shared/chrome.tsx` or a new small shared helper to expose vendor logo image metadata while preserving `VendorMark` for places that still need text glyph marks.
3. Update `learnova-academy/src/app/(site)/page.tsx` hero section to keep the current text/actions but add the hero image in the right column, move course-of-the-day below/alongside it without overlap, and add a "Covering" vendor logo row directly below the hero.
4. Update `learnova-academy/src/components/_shared/content.tsx` so `CourseCard` uses a real image element for `course.thumbnail` when present and `NewsCard` renders the vendor logo image next to the vendor name; preserve existing links, progress UI, and fallback gradients.
5. Update `learnova-academy/src/components/_shared/footer.tsx` to replace the inline SVG K tile with the local Koenig brand mark image while keeping the same link, wordmark, and footer layout.
6. Add or adjust focused CSS in `learnova-academy/src/app/academy.css` for `.academy-hero`, image/logo sizing, responsive stacking, contrast, and no text/image overlap; avoid large global resets beyond these home-page/shared classes.
7. Verify in `learnova-academy`: run `pnpm lint`, `pnpm typecheck`, `pnpm build`, then run the local app and perform DOM/mobile checks for image count, alt text, responsive layout, and Lighthouse performance.

## Verification (QA Verifier checks these)
- [ ] On `/` at desktop width, `document.querySelectorAll('img').length >= 6` before scrolling past 1000px, and every image has non-empty descriptive `alt`.
- [ ] Mobile viewport around 390px wide shows the hero, vendor strip, course-of-the-day, This Week in AI cards, and footer without text/image overlap or horizontal scrolling.
- [ ] `pnpm lint`, `pnpm typecheck`, and `pnpm build` pass in `learnova-academy`; Lighthouse performance does not regress materially, with the hero sized eagerly and below-fold/supporting images lazy-loaded or small enough to avoid LCP damage.

## Risk
- Adding image assets can hurt LCP if they are too large or unsized. Mitigate by committing optimized local SVG/WebP/PNG assets, setting explicit width/height or aspect-ratio, eager-loading only the hero image, and keeping vendor/footer logos small.

## Out of scope
- No Convex deploys, no catalog/lesson/blog redesign, no external logo-fetch service, no changes outside `learnova-academy`, and no broad homepage copy rewrite beyond labels needed for the new visual sections.
