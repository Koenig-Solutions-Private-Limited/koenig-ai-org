---
ticket: KOEA-7206
planner: planner
date: 2026-06-02
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
artifact_issue: KOEA-7239
---

# Plan: Author avatars, Person schema, and author pages

## Goal
Make every Learnova Academy blog expose a visible, trust-building author identity: avatar, linked byline, author profile page, and Person/Organization JSON-LD. Success is observable in prerendered blog HTML, `/authors/<slug>` pages, sitemap output, and Rich Results-compatible `BlogPosting.author` data. No Convex deploy is expected because current blog author data is static vault frontmatter parsed by `src/lib/vault.ts`.

## Context
- Files to read first:
  - `src/lib/authors.ts:9-178` — current author source of truth, author JSON-LD helpers, byline formatter.
  - `src/lib/seo.ts:168-197` — `blogPostingLd` currently embeds `authorRef(author)` but omits author image/jobTitle.
  - `src/app/(site)/blog/[slug]/page.tsx:76-172` — blog detail page gets `author`, emits JSON-LD, and renders a plain-text byline.
  - `src/app/(site)/authors/[slug]/page.tsx:18-130` — profile routes already exist and list posts, but no visible headshot.
  - `src/app/(site)/authors/page.tsx:15-55` — authors index already exists; treat as enhancement, not a new route.
  - `src/app/academy.css:527-532` — blog meta/title/byline styling lives here.
  - `src/app/sitemap.ts:12-53` — `/authors` and `/authors/<slug>` are already in sitemap.
- Relevant prior work: existing V3/V7 SEO work added static author registry, author routes, sitemap entries, `BlogPosting`, `FAQPage`, `HowTo`, and image-alt verification. No prior PR comments were present on KOEA-7206/KOEA-7239.
- Constraints: implementation should use a dedicated or explicitly locked Learnova worktree rooted at `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` from `origin/academy/redesign-v1` (verified remote head `d09d4fb6c3f904552b5f068f5932bebf0e6ef6d5`). The currently visible worktree is on unrelated branch `koea-7247/homepage-imagery-visual-hierarchy` with untracked `.qa-koea-5152/`, `learnova-academy/public/img/products/`, and `learnova-academy/public/slides/`; Executor must not overwrite those without an explicit workspace lock/branch switch decision. Do not modify Convex or deploy Convex unless discovery finds a real runtime data dependency, which current code does not show.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Enhance the existing static author registry. Add explicit avatar fields and alias coverage in `src/lib/authors.ts`, store required avatar assets under `public/img/authors/`, render a linked avatar byline on blog pages, and reuse the same registry in author pages and JSON-LD. This keeps author identity in one static source of truth that already feeds blog pages, author routes, RSS, sitemap, and schema helpers.

**Rejected**: Build a new CMS/Convex-backed author model — unnecessary because `src/lib/vault.ts` already reads static frontmatter and no runtime author query exists; risky because it would require data deployment outside the ticket. Rejected: create a separate author-component system plus new route layer — the routes already exist, so this would duplicate rather than improve the current surface. Rejected: rely on `/api/og?author=...` for avatars — the OG route does not implement an author mode and profile/headshot schema should use stable image URLs.

## Steps (Executor follows in order)
1. Update `src/lib/authors.ts` so the registry is the source of truth for display name, profile slug, avatar image path, avatar alt text, canonical author aliases, and schema fields. Add alias mappings for current vault slugs (`blog-author`, `koenig-ai`, `koenig-academy`, `koenig-ai-academy`, `editorial-team`) and handle the parent-ticket `vardaan-aggarwal` slug without breaking existing `/authors/vardaan-koenig` URLs.
2. Add avatar assets in `public/img/authors/`: a real/approved Vardaan avatar and Koenig brand-mark avatars for agent/editorial identities. Use deterministic filenames matching registry paths; do not use external hotlinked images for schema `image`.
3. Update `src/lib/seo.ts` `authorRef()` usage/output so `blogPostingLd` emits a complete schema.org author object with `@type`, `name`, `url`, `image`, and Person-specific fields when available. Keep Organization fallback valid for agent/editorial authors.
4. Update `src/app/(site)/blog/[slug]/page.tsx` to render a 40-48px circular avatar next to a linked author display name/profile URL, reviewed-by label, and date. Keep `formatBlogByline` or replace it with structured byline helpers from `authors.ts`; do not expose raw internal slugs or UUID-like identifiers.
5. Update `src/app/(site)/authors/[slug]/page.tsx` and `src/app/(site)/authors/page.tsx` to show the same avatar image, preserve existing post lists/metadata, and support any alias route with either `notFound()` for unknown slugs or a safe canonical redirect if Executor chooses one.
6. Add or adjust CSS in `src/app/academy.css` for `.blog-byline`, avatar sizing, link states, and responsive wrapping. Keep source changes scoped to the five source files above plus avatar assets unless a compile error proves another file must change.
7. Verify with static build output: `pnpm lint`, `pnpm build`, `node scripts/verify-blog-listing-alt.mjs`, and a targeted rendered-HTML/schema check that `.next/server/app/blog/*.html` contains author avatar `<img alt=...>`, links to `/authors/...`, and `BlogPosting.author.image`.

## Verification (QA Verifier checks these)
- [ ] `/blog/<published-slug>` prerendered HTML shows a 40-48px author avatar, linked author name/profile URL, reviewer label, and date without raw internal slugs.
- [ ] `BlogPosting` JSON-LD for a Vardaan-authored post emits `author.@type = "Person"` with `name`, `url`, and stable `image`; agent/editorial posts emit a valid Organization or approved fallback author.
- [ ] `/authors/vardaan-koenig` and the parent-ticket slug `/authors/vardaan-aggarwal` behavior is intentional and documented by the implementation: either both resolve safely or one redirects canonically.
- [ ] `/authors` and `/authors/<slug>` pages include avatars and remain present in `sitemap.xml`.
- [ ] `pnpm lint`, `pnpm build`, and `node scripts/verify-blog-listing-alt.mjs` pass from `learnova-academy`.

## Risk
- The parent ticket names `vardaan-aggarwal` while current code and live author URLs use `vardaan-koenig`; naive renaming could break existing posts and sitemap URLs. Mitigation: add alias handling and keep one canonical profile slug unless Chief Engineering explicitly authorizes a public URL migration.

## Out of scope
- No Convex schema/data migration or deploy.
- No wholesale blog frontmatter rewrite across the vault.
- No redesign of the blog index beyond optional avatar display if Executor can fit it without adding more source files.
- No external author CMS or identity provider integration.

## Plan-Reviewer Handoff Checklist
- [ ] Code Reviewer G_plan confirms the static-registry approach satisfies KOEA-7206 without Convex.
- [ ] Code Reviewer checks the slug mismatch mitigation for `vardaan-aggarwal` vs `vardaan-koenig`.
- [ ] Code Reviewer verifies the implementation surface stays bounded to five source files plus avatar assets.
- [ ] After G_plan approval, hand to Executor; after implementation, route through Code Reviewer G_code, then QA Verifier G2.
