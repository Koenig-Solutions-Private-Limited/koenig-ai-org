---
ticket: KOEA-7098
planner: planner
date: 2026-07-16
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Ask Nova inline CTA after blog and chapter sections

## Goal
Add a repeated, lightweight "Ask Nova about this section" affordance in Academy long-form content. Success means blog posts and course chapter bodies show an accessible inline CTA after each H2 section start and after Quick Takeaways blocks where appropriate, and clicking it opens the existing on-page/global Nova rail with a contextual prefilled prompt.

## Context
- Files to read first: `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:327-366`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:378-418`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:753-790`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:825-867`, `learnova-academy/src/components/CourseChapterContent.tsx:392-468`, `learnova-academy/src/components/CourseChapterContent.tsx:580-599`, `learnova-academy/src/components/_shared/tutor-open.ts:1-9`, `learnova-academy/src/lib/track.ts:15-22`, `learnova-academy/src/app/academy.css:685-716`
- Relevant prior work: existing `TutorRail` listens for `OPEN_TUTOR_WITH_MESSAGE_EVENT`; existing `AskNovaSelectionMenu` already opens Nova from selected text; existing `track()` helper is no-op-safe when PostHog is absent.
- Constraints: Do not touch non-Academy portals. Target branch `academy/redesign-v1` exists on origin. The ticket-specified `learnovaBeast-fe-agent` path was not present during planning; current code was read from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` at fetched `academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a client-only `AskNovaSectionCta` component that builds a non-PII contextual prompt from page type, title, section heading, and optional section text snippet, calls `track("ask_nova_section_cta_click", ...)`, then uses the existing `openTutorWithMessage(prompt)` event that `TutorRail` already handles. Inject it from the existing Markdown block loops immediately after rendered H2 blocks and Quick Takeaways blocks, with spacing rules in `academy.css` so it reads as an inline learning affordance rather than a marketing card.

**Rejected**: Put CTA logic directly inside each renderer — duplicates client/event/analytics logic across three server components. Add CTAs from raw markdown preprocessing — harder to keep React keys, heading IDs, Takeaways detection, and infographic injection stable. Only add CTAs to the floating Nova nudge — does not satisfy per-section discoverability.

## Steps (Executor follows in order)
1. Create `learnova-academy/src/components/_shared/AskNovaSectionCta.tsx` as a `"use client"` component accepting `surface`, `pageTitle`, `sectionTitle`, optional `sectionId`, optional `sectionText`, and optional `courseSlug`/`contentSlug`; ensure the button has `type="button"`, `aria-label`, minimum 44px tap target, and keyboard-visible focus.
2. In `AskNovaSectionCta`, construct prompts such as `I'm reading "<pageTitle>". Explain the section "<sectionTitle>" in simpler terms and give me one practical example.`; if `sectionText` is present, append a short excerpt, call `track("ask_nova_section_cta_click", { surface, section_id, content_slug, course_slug })`, then call `openTutorWithMessage(prompt)` to open the existing page/global Nova rail.
3. Update `learnova-academy/src/app/(site)/blog/[slug]/page.tsx` so `BlogBody` tracks the latest H2 title/id while iterating `splitMarkdownBlocks`, and pushes `<AskNovaSectionCta surface="blog" ...>` after each rendered H2 and after each `Takeaways` render, without changing existing inline image insertion or heading ID generation.
4. Update `learnova-academy/src/app/(site)/learn/[slug]/page.tsx` so the long course page `ChapterBody` injects `<AskNovaSectionCta surface="course_chapter" ...>` after H2 blocks and Takeaways blocks while preserving first-H2 infographic placement and namespaced heading IDs.
5. Update `learnova-academy/src/components/CourseChapterContent.tsx` with the same injection behavior for standalone `/learn/[slug]/[chapterSlug]` pages, preserving existing `CourseChapterSection` navigation and rendered heading IDs.
6. Add `.ask-nova-section-cta` styles to `learnova-academy/src/app/academy.css`: compact inline layout, 44px minimum button height on mobile and desktop, visible focus, no nested card styling, and responsive wrapping that cannot overlap prose or quick-takeaway content.
7. Keep analytics limited to the existing `track()` helper; do not edit `AnalyticsClient` unless Executor discovers the event fallback cannot be observed, in which case document deferral to KOEA-7092 instead of widening scope.

## Verification (QA Verifier checks these)
- [ ] On a blog detail page, every rendered H2 section has an inline Ask Nova CTA after the heading and Quick Takeaways blocks have one immediately after the aside, without duplicate CTAs in related/next/reference sections.
- [ ] On both `/learn/[slug]` long course pages and `/learn/[slug]/[chapterSlug]` standalone chapter pages, H2 sections and Quick Takeaways blocks show the CTA while existing infographic insertion after the first H2 still works.
- [ ] Clicking the CTA opens the on-page/global Nova rail with a prefilled prompt naming the page and section.
- [ ] Mobile viewport inspection confirms the CTA button tap target is at least 44px high, focus state is visible, and text wraps without overlap.
- [ ] Analytics is no-op-safe: with PostHog/Umami absent the click does not throw; with PostHog present `ask_nova_section_cta_click` fires without message text or section excerpt.

## Risk
- Duplicate or noisy CTAs could make long articles feel cluttered. Mitigate by keeping the component visually compact, injecting only for H2 and Takeaways blocks, and excluding footer/related sections because they are rendered outside the Markdown block loops.

## Out of scope
- Changing Nova's model, `/api/tutor` behavior, answer grounding, or broader KOEA-7092 analytics instrumentation.
- Adding CTAs to H3/subsections, glossary pages, skill pages, or non-Academy portals.
- Reworking the missing `learnovaBeast-fe-agent` worktree; Executor should use the active issue workspace or a clean checkout of `academy/redesign-v1`.
