---
ticket: KOEA-6958
planner: planner
date: 2026-05-31
estimated_complexity: medium
estimated_token_cost: $0.34
base_branch: academy/redesign-v1
approval: f3cd0492-eb3d-42dc-bb8e-ef2543a042c1
---

# Plan: Add blog share rail, related posts, and safe bylines

## Goal
Every `/blog/[slug]` article should expose a visible share surface, a generated related-posts section with three real internal links, and a role-only byline that never renders user IDs, email addresses, or raw reviewer identifiers. Success is observable on the Cloudflare Agents sample post and on any other vault-backed blog post without editing individual markdown bodies.

## Context
- Files to read first: `learnova-academy/src/app/blog/[slug]/page.tsx:66-267`, `learnova-academy/src/app/blog/[slug]/client-shell.tsx:17-39`, `learnova-academy/src/lib/vault.ts:21-153`, `learnova-academy/src/lib/authors.ts:84-123`, `learnova-academy/src/app/academy.css:428-481`
- Relevant prior work: approval `f3cd0492-eb3d-42dc-bb8e-ef2543a042c1` clarified acceptance for share destinations, related-post matching, and sanitized byline behavior.
- Constraints: target `learnovaBeast` branch `academy/redesign-v1`; keep blog body server-rendered; do not rely on embeddings or runtime network calls during static generation; avoid exposing raw `author` / `reviewer` frontmatter values in HTML.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add small reusable helpers and UI at the existing blog boundaries. Extend `BlogPost` parsing in `src/lib/vault.ts` to include `tags` and export a deterministic `getRelatedBlogs(post, limit)` scorer based on tag overlap, then vendor/content fallback. Add role-label sanitization in `src/lib/authors.ts` or a nearby helper and use it in `page.tsx` for the visible byline. Mount a `ShareRail` from `client-shell.tsx` so copy-link uses the browser clipboard while the article body remains server-rendered.
**Rejected**: Per-post markdown widgets — does not guarantee every blog post gets share/related UI and leaves stale manual `## Related from the academy` sections in control; embedding-distance matching — higher complexity and requires build-time model/index infrastructure not present in the repo.

## Steps (Executor follows in order)
1. Update `learnova-academy/src/lib/vault.ts` to add `tags: string[]` to `BlogPost`, parse frontmatter `tags`, and export `getRelatedBlogs(post: BlogPost, limit = 3)` that excludes the current slug, scores tag overlap first, then `vendor_tag`, then `content_type`, and returns three publishable posts with positive relatedness.
2. Add a safe byline formatter in `learnova-academy/src/lib/authors.ts` (or a small adjacent helper if imports are cleaner) that converts known role slugs like `blog-author`, `content-reviewer`, and `editorial-team` to display roles, rejects emails/UUID-like/user-id-like strings, and never returns raw unknown identifiers.
3. Modify `learnova-academy/src/app/blog/[slug]/page.tsx` to compute `relatedPosts = getRelatedBlogs(post, 3)`, replace the visible byline with role-only text such as `Blog Author · Reviewed by Content Reviewer · May 28, 2026`, and render an automatic `Related from the academy` section after `References` with three linked post titles plus vendor/read-time metadata.
4. Update `learnova-academy/src/app/blog/[slug]/client-shell.tsx` to render a `ShareRail` client component using the current canonical blog URL and title, with buttons/links for X, LinkedIn, Reddit, Hacker News, and copy-link.
5. Add minimal responsive styles in `learnova-academy/src/app/academy.css` for the share rail and related-post widget so desktop uses a floating rail that does not collide with TOC/Nova, while mobile collapses to a compact horizontal row.
6. Remove or suppress duplicated manual related headings only if the server-rendered body currently repeats the auto-widget on the Cloudflare sample; keep the markdown source unchanged unless duplication is visible.

## Verification (QA Verifier checks these)
- [ ] On `/blog/2026-05-28-cloudflare-agents-workers-production-architecture`, the page shows share controls for X, LinkedIn, Reddit, Hacker News, and copy-link without breaking the existing TOC or Nova controls.
- [ ] The same page renders an automatic `Related from the academy` widget with exactly three internal `/blog/...` links chosen by overlapping tags or vendor/content fallback.
- [ ] The visible byline uses role labels only and contains no `@`, UUID, raw `blog-author`, raw `content-reviewer`, or email-like text.
- [ ] `cd learnova-academy && pnpm typecheck` passes.

## Risk
- The related-post scorer may return fewer than three posts if the publishable vault has sparse tags. Mitigation: after tag scoring, fill remaining slots from same `vendor_tag` / `content_type` matches and only fall back to newest publishable posts if necessary, while preserving internal links.

## Out of scope
- No embedding index, analytics tracking, social share count API, or per-post content rewrite beyond suppressing visible duplicate related sections if the auto-widget makes them redundant.

Pre-flight: status_ok=true; sibling_count=1; acceptance_approval=f3cd0492-eb3d-42dc-bb8e-ef2543a042c1; basebranch_verified=true; vault_pull=passed
