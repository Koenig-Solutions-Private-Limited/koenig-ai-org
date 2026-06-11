---
ticket: KOEA-7075
planning_issue: KOEA-7674
planner: planner
date: 2026-06-10
estimated_complexity: medium
estimated_token_cost: "$0.24"
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Inline NotebookLM slides inside chapter prose

## Goal
Ship a build-time and render-time path that turns each NotebookLM `slide-deck.pdf` page into a public R2 PNG and interleaves those images into `/learn/[slug]` chapter prose at H2 section boundaries. Success means the full-deck PDF remains available in the chapter media dock, while individual slides appear as lazy-loaded, captioned, click-to-zoom figures in the chapter body.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/learn/[slug]/page.tsx:578-629`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/learn/[slug]/page.tsx:784-846`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts:25-70`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts:154-218`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/upload-chapter-assets.mjs:52-131`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/notebooklm-batch-chapters.sh:83-112`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/course/ChapterMediaDock.tsx:80-111`.
- Relevant prior work: current course-gen v3 sidecars already expose `assets.slide_deck_url` and `asset_metadata.slide_deck_pdf.page_count`, for example `vault/courses/mcp-from-first-principles-to-production/01-why-mcp-exists/chapter-meta.json`.
- Constraints: keep this inside `learnova-academy` and the Koenig asset pipeline; do not touch admin/student/TC portals or Convex. The Slide + Audio Producer owns NotebookLM reruns, PDF artifact availability, and caption/topic QA; engineering owns the script, sidecar reader, and frontend renderer. Current `openai-realtime-api-voice-agents-end-to-end` has only `outline.md` and is `g0-blocked`, so that course needs a content-lane prerequisite before slide migration can be completed.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Extend the existing `chapter-meta.json` sidecar contract with a top-level `slides` array, and have the existing upload script derive it from `slide-deck.pdf` after NotebookLM download. This keeps all chapter media in one manifest, lets `src/lib/courses.ts` merge slide metadata into `CourseChapter`, and lets `ChapterBody` inject slides while preserving the current `ChapterMediaDock` PDF table-of-contents affordance.

**Rejected**: Client-side PDF.js extraction, because it would push 15-20 MB PDFs and page rendering onto learners and hurt Lighthouse; separate `slides.json` manifests, because it duplicates the sidecar lifecycle and gives the frontend two sources of truth; replacing the full PDF dock with inline slides, because the ticket asks to maintain the full-deck embed as the table of contents.

## Steps (Executor follows in order)
1. Update `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/upload-chapter-assets.mjs` so when `slide-deck.pdf` exists it runs `pdfinfo`/`pdftoppm` or `pdftocairo` locally, writes `slides/slide-01.png` style files, uploads them to R2 under `courses/<course>/<chapter>/slides/`, records `asset_metadata.slide_images`, and writes `slides` into `chapter-meta.json`.
2. Use this sidecar shape:
   ```json
   {
     "slides": [
       {
         "page": 1,
         "image_url": "https://.../courses/<course>/<chapter>/slides/slide-01.png",
         "caption": "Section or slide topic",
         "section_heading": "Nearest H2 heading",
         "width": 1600,
         "height": 900
       }
     ]
   }
   ```
   Caption mapping should default to chapter H2 headings distributed in reading order; Slide + Audio Producer may correct `caption` and `section_heading` manually from the NotebookLM PDF outline before publish.
3. Extend `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts` with a `ChapterSlide` type, `CourseChapter.slides?: ChapterSlide[]`, sidecar parsing, basic validation, and compatibility with chapters that have no slide images.
4. Update `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/learn/[slug]/page.tsx` so `ChapterSection` passes `ch.slides` into `ChapterBody`, and `ChapterBody` injects a slide figure after matching H2 blocks without disturbing the existing infographic-after-first-H2 behavior.
5. Add a small client component in `learnova-academy/src/components/course/` for click-to-zoom slide figures, reusing the `ChapterAssetModal` pattern if practical; images must use native lazy loading, dimensions/aspect-ratio from metadata, `decoding="async"`, useful alt text, and direct R2 image URLs rather than `/api/asset`.
6. Add focused styling in `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/academy.css` for inline slide figures, mobile width, modal image containment, print behavior, and no layout shift.
7. Migration: run the producer/upload path for `mcp-from-first-principles-to-production` first and verify 5 chapters, then `gemini-enterprise-agents`, then `production-agents-claude-agent-sdk-mcp-connector` including legacy chapter 1, and defer `openai-realtime-api-voice-agents-end-to-end` until content chapters and PDFs exist or Chief Engineering supplies the intended replacement slug.

## Verification (QA Verifier checks these)
- [ ] `vault/courses/mcp-from-first-principles-to-production/*/chapter-meta.json` contains `slides` entries with public PNG URLs, page numbers, captions, dimensions, and existing `assets.slide_deck_url` preserved.
- [ ] `/learn/mcp-from-first-principles-to-production` renders inline slide figures after H2 sections, keeps the top PDF deck dock, and opens a clicked slide in a modal on desktop and mobile.
- [ ] Browser network inspection shows slide PNGs are lazy-loaded and the full PDF iframe still waits for explicit user action.
- [ ] `cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && pnpm typecheck && pnpm test && pnpm build` passes.
- [ ] Production smoke on `https://academy.kspl.tech/learn/mcp-from-first-principles-to-production` confirms no Lighthouse performance regression from eager PDF or image loading.

## Risk
- Poppler tools may be absent in the producer/runtime environment; mitigate by making the script fail with a clear `pdftoppm/pdfinfo missing` message and documenting the install requirement for the Slide + Audio Producer container before migration.

## Out of scope
- Rewriting NotebookLM generation prompts, replacing the existing PDF deck UI, generating missing OpenAI Realtime chapters, or changing non-academy portals.
