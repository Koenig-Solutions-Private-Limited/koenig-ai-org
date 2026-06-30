---
ticket: KOEA-6886
planner: planner
date: 2026-06-10
estimated_complexity: small
estimated_token_cost: $0.35
approval: ca3b666c-8d42-4965-ab71-80d91f49cf4e
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Add missing blog index og:image metadata

## Goal
Make `/blog` emit the same deterministic OpenGraph image metadata contract already used by the academy homepage. Success is SSR HTML for `/blog` containing `og:image`, `og:image:width`, `og:image:height`, and `og:image:alt`, while the existing blog index `og:title`, `og:description`, `og:url`, and `og:type` values remain unchanged.

## Context
- Files to read first: `learnova-academy/src/app/(site)/blog/page.tsx:11-22`, `learnova-academy/src/app/(site)/page.tsx:23-42`, `learnova-academy/src/lib/seo.ts:10-24`, `learnova-academy/src/app/layout.tsx:36-59`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:48-77`.
- Relevant prior work: KOEA-6886 says PR #70 fixed homepage `og:image` but missed `/blog`; `origin/academy/redesign-v1` currently includes `db1e0b27` (#119) and prior SEO commit `f07fb83e` ([KOEA-6004]).
- Constraints: target `learnovaBeast/learnova-academy` on `origin/academy/redesign-v1`; local checkout may be on another branch, so Executor should branch from the verified production branch. Do not redesign the blog index, change `/api/og`, add image assets, or modify existing OG title/description/url/type strings.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Reuse the existing `defaultOgImage()` helper in the blog index metadata. Import `defaultOgImage` from `@/lib/seo`, define `const ogImage = defaultOgImage()` near the existing metadata, and add `images: [ogImage]` inside `metadata.openGraph` in `learnova-academy/src/app/(site)/blog/page.tsx`. This matches the homepage implementation and gives Next.js the descriptor it needs to render `og:image`, width, height, and alt tags.

**Rejected**: Inline a duplicate image descriptor in `blog/page.tsx` - it would work but duplicates the homepage/default contract. **Rejected**: Move the image descriptor to root layout only - root metadata is already present and did not make `/blog` emit the required route-level `og:image`. **Rejected**: Build dynamic blog-index images from the first post hero - larger scope and unnecessary for the acceptance criteria.

## Steps (Executor follows in order)
1. Create a working branch from `origin/academy/redesign-v1` in `learnovaBeast`; do not reuse the current dirty `academy/career-compass` checkout state.
2. Edit `learnova-academy/src/app/(site)/blog/page.tsx` to import `defaultOgImage` alongside `jsonLdScript` and `blogIndexLd` from `@/lib/seo`.
3. Add `const ogImage = defaultOgImage();` above `export const metadata`, following the homepage pattern in `src/app/(site)/page.tsx`.
4. Add only `images: [ogImage]` to `metadata.openGraph`; leave existing `title`, `description`, `url`, and `type` unchanged.
5. Run `cd learnova-academy && pnpm typecheck`.
6. Run the SSR metadata checks below against a production build or local preview and paste the matching lines into the issue comment.

## Verification (QA Verifier checks these)
- [ ] `cd learnova-academy && pnpm typecheck` passes.
- [ ] SSR HTML for `/blog` contains the required image tags:

```sh
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:image"'
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:image:width" content="1200"'
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:image:height" content="630"'
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:image:alt" content="Koenig AI Academy'
```

- [ ] Existing blog OG tags remain unchanged:

```sh
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:title" content="AI blog . Koenig AI Academy"'
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:description" content="Same-day commentary on what AI vendors shipped today\\."'
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:url" content="https://academy\\.kspl\\.tech/blog"'
curl -sL http://localhost:3010/blog | tr '>' '>\n' | rg 'property="og:type" content="website"'
```

- [ ] After deploy, live SSR verification also passes:

```sh
curl -sL https://academy.kspl.tech/blog | tr '>' '>\n' | rg 'property="og:image"'
curl -sL https://academy.kspl.tech/blog | tr '>' '>\n' | rg 'property="og:image:width" content="1200"'
curl -sL https://academy.kspl.tech/blog | tr '>' '>\n' | rg 'property="og:image:height" content="630"'
curl -sL https://academy.kspl.tech/blog | tr '>' '>\n' | rg 'property="og:image:alt" content="Koenig AI Academy'
```

## Risk
- Next metadata merging can be sensitive to route nesting. Mitigation: verify against rendered SSR HTML rather than trusting TypeScript or metadata object inspection.

## Out of scope
- No changes to blog cards, blog post metadata, `/api/og`, homepage metadata, catalog metadata, JSON-LD, sitemap, or social image design.
