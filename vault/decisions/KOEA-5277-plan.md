---
ticket: KOEA-5277
planner_issue: KOEA-5321
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Add OG fallback and lesson structured-data coverage

## Goal
Reduce the SEO/GEO scan gaps from KOEA-5248 by ensuring hub, glossary, and lesson/course pages always expose a deterministic `og:image`. Add structured-data coverage for procedural lesson sections and real embedded video content without inventing schema where the source content does not support it.

Success is observable in rendered metadata and JSON-LD: `/learn`, glossary entry pages, and course/lesson pages emit an OG image, procedural lesson chapters emit valid `HowTo`, and chapters with explicit video/embed data emit valid `VideoObject`.

## Context
- Files to read first: `src/lib/seo.ts:64-130`, `src/lib/seo.ts:231-338`, `src/lib/courses.ts:21-46`, `src/lib/courses.ts:175-203`, `src/app/learn/[slug]/page.tsx:50-75`, `src/app/learn/[slug]/page.tsx:107-155`, `src/app/learn/[slug]/page.tsx:423-528`, `src/app/learn/page.tsx:15-27`, `src/app/glossary/[slug]/page.tsx:22-36`, `src/app/api/og/route.tsx:8-108`.
- Relevant prior work: KOEA-5248 scan found missing `og:image` on 150/187 scanned URLs, concentrated on hub/glossary pages, and no `HowTo` or `VideoObject` schema on scanned sitemap URLs.
- Constraints: Do not implement from the dirty working tree blindly. The actual checkout is `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`, branch `academy/redesign-v1`, currently `ahead 2, behind 27` with modified `package.json`, `src/app/blog/[slug]/page.tsx`, `src/app/blog/page.tsx`, `src/app/learn/[slug]/page.tsx`, `src/app/page.tsx`, `src/lib/seo.ts`, plus untracked `public/slides/` and `scripts/check-meta-descriptions.mjs`. Executor must verify ownership or block for repo-state resolution before editing.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Central SEO helpers with route-level wiring. Add reusable helpers in `src/lib/seo.ts` for deterministic OG fallback, `HowTo`, and `VideoObject`, then wire only the route classes that need this ticket: `/learn` hub metadata, glossary entry metadata, and course/lesson JSON-LD in `src/app/learn/[slug]/page.tsx`. Extend `src/lib/courses.ts` only enough to expose explicit video/embed metadata from chapter frontmatter or recognized markdown embeds; do not treat audio, PDFs, or slide decks as videos.

**Rejected**: Route-local metadata duplication — would fix the scan but spread fallback image logic across pages; Scan-only/documentation-only — would not reduce the production OG/schema gaps; Content-only VideoObject frontmatter changes — would not create runtime schema coverage and would still miss embedded markdown videos.

## Steps (Executor follows in order)
1. Verify repo state in `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`: confirm branch or feature branch is based on `origin/academy/redesign-v1`, inspect `.claude/agent-lock` if present, and stop if existing dirty changes are not owned by this KOEA-5277 chain.
2. Add SEO helpers in `src/lib/seo.ts`: `defaultOgImage(alt?: string)`, `howToLd(...)`, `videoObjectLd(...)`, and small predicates/builders that return `null` when a chapter lacks enough source evidence.
3. Update hub/glossary metadata: in `src/app/learn/page.tsx`, add `openGraph.images` and `twitter` using the fallback helper; in `src/app/glossary/[slug]/page.tsx`, add the same fallback image to `openGraph` and `twitter` while preserving existing canonical URL/title/description.
4. Extend `src/lib/courses.ts` to surface optional chapter video evidence from frontmatter (`video_url`, `video_embed_url`, thumbnail/upload date/duration if present) and recognized markdown iframe/video embeds; keep all fields optional.
5. Update `src/app/learn/[slug]/page.tsx` to append conditional `HowTo` JSON-LD for procedural chapters and conditional `VideoObject` JSON-LD for chapters with explicit video evidence, alongside existing Course, LearningResource, Breadcrumb, and FAQ JSON-LD.
6. Verify route-class acceptance with targeted checks: build or render representative `/learn`, `/glossary/<slug>`, and `/learn/<slug>` pages, then inspect HTML for `og:image`, `HowTo`, and `VideoObject` only where expected.
7. Document route-class coverage in the PR body or issue handoff: hub (`/learn`) fallback OG, glossary entry fallback OG, course/lesson fallback OG plus Course/LearningResource/FAQ/Breadcrumb/conditional HowTo/conditional VideoObject.

## Verification (QA Verifier checks these)
- [ ] `git status --short --branch` shows Executor did not overwrite unrelated dirty changes; if a feature branch is used, it targets `academy/redesign-v1`.
- [ ] `pnpm typecheck` passes in `learnova-academy`.
- [ ] `pnpm build` passes; `postbuild` meta-description check still passes.
- [ ] Rendered `/learn` HTML includes an `og:image` pointing at the deterministic fallback `/api/og`.
- [ ] Rendered glossary entry HTML includes `og:image` and `twitter:image` fallback metadata.
- [ ] Rendered representative course page includes existing Course/LearningResource/FAQ/Breadcrumb JSON-LD plus at least one `HowTo` for a procedural chapter with ordered steps or hands-on exercise content.
- [ ] Rendered representative course page emits `VideoObject` only when the chapter has explicit video URL/embed evidence; pages with audio/PDF/slides only do not emit false `VideoObject`.

## Risk
- The current dirty/behind worktree may contain unrelated SEO edits already in progress. Mitigation: Executor must inspect ownership before editing and block for Chief Engineering repo-state direction if the dirty files are not part of KOEA-5277.

## Out of scope
- Do not create page-specific OG artwork; this plan uses the existing deterministic `/api/og` fallback.
- Do not add schema to blog pages unless a verification scan proves the blog route class is part of KOEA-5277's missing set.
- Do not label audio narration, slide decks, PDFs, or study guides as `VideoObject`.

## Acceptance Mapping
- hub/glossary templates emit `og:image`: steps 2-3 and verification checks 4-5.
- schema coverage documented by route class: step 7.
- HowTo on procedural lessons: steps 2 and 5, verification check 6.
- VideoObject where embedded video/lesson content exists: steps 2, 4, and 5, verification check 7.
- follow-up scan shows reduced OG/schema gaps: step 6 plus PR/issue coverage evidence.

## Pre-flight Footer
- status_checked=true
- sibling_chain_checked=true
- chain_alert_resolved_by_chief=true
- acceptance_checked=true
- basebranch_verified=true
