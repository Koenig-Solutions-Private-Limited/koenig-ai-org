---
ticket: KOEA-7099
planner: planner
agent: planner
date: 2026-06-02
type: decision
tags:
  - decision
  - planning
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: 19c3578e-0fbf-4570-9732-97ff7c0ec597
---

# Plan: Bottom-of-blog digest CTA and next-read card

## Goal
Add a stronger end-of-article action area to every Academy blog post. Success means `/blog/<slug>` still renders References and the existing related links, then shows a responsive two-column section with the existing digest opt-in on the left and one deterministic "next best read" card on the right.

## Context
- Files to read first: `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:75-185`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:629-650`, `learnova-academy/src/components/_shared/DigestOptIn.tsx:9-127`, `learnova-academy/src/lib/vault.ts:21-58`, `learnova-academy/src/lib/vault.ts:282-355`, `learnova-academy/src/app/academy.css:436-572`
- Relevant prior work: KOEA-7008 added `DigestOptIn`; KOEA-7134 chain alert approval `19c3578e-0fbf-4570-9732-97ff7c0ec597` authorized the KOEA-7099 sequential Plan -> Plan Review -> Implement -> G_code -> G2 split.
- Constraints: Implement only after KOEA-7129 provides a clean FE worktree. This Planner read `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`, which is currently dirty on `koea-6897/geo-schema-rendering`; Executor must work from a clean branch based on `origin/academy/redesign-v1`. Keep the PR scoped to `learnova-academy`; do not touch non-Academy portals or vault blog drafts.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Server-rendered blog postscript section. Add a deterministic `getNextBestBlog(post)` helper in `src/lib/vault.ts`, import `DigestOptIn` into `src/app/(site)/blog/[slug]/page.tsx`, and render a new `BlogPostscript` section immediately after `<RelatedFromAcademy posts={relatedPosts} />`. The section should stay server-rendered except for the existing `DigestOptIn` client island, use Next `<Image>` for the next-read card image, and add CSS classes in `academy.css` for the desktop two-column layout and mobile single-column stack.

**Rejected**: Reuse `getRelatedBlogs(post, 1)` as the next-read source - its tag-overlap scoring does not match the requested `vendor_tag > date > clicks` order. **Rejected**: Build a new digest form variant - it duplicates KOEA-7008 behavior and risks divergent subscribe/error handling. **Rejected**: Add analytics-backed click ranking now - there is no current blog click data source, so use an explicit placeholder/tie-break hook until analytics exists.

## Steps (Executor follows in order)
1. In `learnova-academy/src/lib/vault.ts`, add `getNextBestBlog(post: BlogPost): BlogPost | null` near `getRelatedBlogs`. It should exclude the current slug and sort candidates by same `vendor_tag` first, then newest `date`, then a placeholder click score function that currently returns `0`, then `slug` as a deterministic tie-breaker.
2. In `learnova-academy/src/app/(site)/blog/[slug]/page.tsx`, import `DigestOptIn` and `getNextBestBlog`, compute `const nextPost = getNextBestBlog(post)` beside `relatedPosts`, and render `<BlogPostscript nextPost={nextPost} />` after `RelatedFromAcademy`.
3. In the same page file, add `BlogPostscript`, `DigestCtaPanel`, `NextReadCard`, and a small teaser helper. The digest panel copy should include the requested headline `Don't miss tomorrow's AI brief`; the next-read card heading should be `Pick up where you left off`; the teaser should prefer `seo_description`, otherwise derive up to 80 words from the post body with markdown/control blocks stripped.
4. For next-read imagery, use `entry.hero_image?.url ?? \`/api/og?slug=${entry.slug}\`` with `blogHeroAlt(entry)`, `fill`, an aspect-ratio wrapper, non-priority loading, and a narrow `sizes` value such as `(max-width: 768px) 100vw, 430px`. Do not add new above-the-fold images or client-side fetching.
5. In `learnova-academy/src/app/academy.css`, add postscript styles near the existing blog footer styles: a centered breakout width up to about `960px`, desktop `grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr)`, mobile `1fr`, token-based borders/backgrounds, stable image aspect ratio, and static positioning on mobile. Keep text sizes smaller than the article title and ensure long titles wrap cleanly.
6. Keep `RelatedFromAcademy` intact. The new postscript is additive and must not alter References, related-link rendering, heading extraction/TOC behavior, JSON-LD, or blog publishability rules.
7. Open the implementation PR against `academy/redesign-v1` only after the clean worktree path/branch is available from KOEA-7129; mention in the PR that click ranking is intentionally a placeholder until a real analytics source is wired.

## Verification (QA Verifier checks these)
- [ ] On the clean FE branch from `origin/academy/redesign-v1`, run `pnpm --dir learnova-academy typecheck` and `pnpm --dir learnova-academy lint`.
- [ ] Run `pnpm --dir learnova-academy build`; if the build syncs vault content, confirm `KOENIG_VAULT_ROOT` resolves to the expected local or Vercel vault path.
- [ ] Browser-check one representative `/blog/<slug>` at desktop width: References, Related from the academy, then the new two-column postscript appear in that order; the digest form submits or errors with the existing `DigestOptIn` states.
- [ ] Browser-check the same page at mobile width: the postscript stacks to one column, image/title/CTA text do not overflow, and the footer digest form remains unaffected.
- [ ] Confirm the selected next-read candidate is not the current post and follows same `vendor_tag` first, then newest date, then placeholder click score. A simple temporary console/log assertion or unit-like script is acceptable if no test harness exists for `vault.ts`.
- [ ] Run a Lighthouse/perf sanity check on a representative blog page before/after. The new below-the-fold image must not be `priority`, must have a constrained `sizes`, and should not materially regress LCP or CLS.

## Risk
- The postscript widens beyond the existing `760px` article column, so careless CSS can cause horizontal overflow or cramped desktop cards. Mitigation: use a constrained breakout width with `max-width`, `calc(100vw - 48px)`, stable grid tracks, and a mobile media query.

## Out of scope
- Adding real analytics/click tracking, changing the sitewide footer digest widget, editing vault blog drafts, replacing `RelatedFromAcademy`, or modifying any non-Academy portal.

## Pre-flight
- basebranch_verified=true
- plan_mode=true
- codebase_read_current=true
- production_code_changed=false
