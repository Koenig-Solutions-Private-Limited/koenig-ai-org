---
ticket: KOEA-2463
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.20
repo: learnovaBeast
base_branch: academy/redesign-v1
---

# Plan: Canonicalize the course catalog at /catalog

## Goal
Eliminate duplicate course catalog index content by making `/catalog` the only canonical catalog listing URL. Success means bare `/learn` permanently redirects to `/catalog`, `/catalog` remains indexable with its self-referencing canonical/catalog structured data, all internal catalog-entry links point to `/catalog`, and existing course detail pages under `/learn/<slug>` still render.

## Context
- Files to read first: `learnova-academy/next.config.ts:7-28`, `learnova-academy/src/app/learn/page.tsx:15-76`, `learnova-academy/src/app/catalog/page.tsx:48-75`, `learnova-academy/src/app/not-found.tsx:10-22`, `learnova-academy/src/app/llms.txt/route.ts:33-44`, `learnova-academy/src/app/learn/[slug]/page.tsx:150-160`
- Relevant prior work: PR #45 (`https://github.com/Koenig-Solutions-Private-Limited/learnovaBeast/pull/45`) already contains a compatible implementation on `koea-website-qa/course-source-of-truth`; Executor may reuse that branch or reapply the scoped KOEA-2463 subset.
- Constraints: base branch `academy/redesign-v1` verified on origin; do not redirect or remove `/learn/[slug]` course detail routes; keep this ticket scoped to duplicate catalog index/canonical cleanup, not broader course publishability or sitemap issues from adjacent QA tickets.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Keep `/catalog` as the canonical catalog index and redirect only the bare `/learn` route. This matches the existing header nav and `/catalog` structured-data URL while preserving `/learn/<slug>` as the established course detail namespace.

**Rejected**: Make `/learn` canonical and redirect `/catalog` because it conflicts with current header navigation and the schema.org SearchAction/catalog target; keep both pages with one cross-canonical because users and crawlers would still encounter two live URLs for the same index.

## Steps (Executor follows in order)
1. Update `learnova-academy/next.config.ts` so `redirects()` always returns `{ source: "/learn", destination: "/catalog", permanent: true }` in addition to the existing legacy blog redirects, including the fallback path when the vault blog directory is unreadable.
2. Delete `learnova-academy/src/app/learn/page.tsx` so the duplicate static catalog index and `/learn` self-canonical cannot render.
3. Keep `learnova-academy/src/app/catalog/page.tsx` as the catalog index and leave its catalog JSON-LD URL at `https://academy.kspl.tech/catalog`.
4. Replace internal catalog-index references that point at bare `/learn`, especially `learnova-academy/src/app/not-found.tsx` and the Catalog page entry in `learnova-academy/src/app/llms.txt/route.ts`, with `/catalog`.
5. Audit for remaining bare `/learn` catalog links with `rg` and preserve intentional course-detail links such as `/learn/${slug}`, `/learn/[slug]` canonical metadata, breadcrumbs, and "All courses" links only if they are deliberately meant to navigate to the catalog after redirect.
6. Run the narrow verification from `learnova-academy`: `pnpm typecheck` and `pnpm build` using `node node_modules/next/dist/bin/next build` or the repo's non-hanging build command if needed.

## Verification (QA Verifier checks these)
- [ ] `GET /learn` returns a permanent redirect to `/catalog`.
- [ ] `GET /catalog` returns `200` and its canonical/catalog structured data names `https://academy.kspl.tech/catalog`, not `/learn`.
- [ ] At least one existing `/learn/<slug>` course detail page still returns `200` and does not redirect to `/catalog`.
- [ ] `rg 'href="/learn"|href: "/learn"|academy\\.kspl\\.tech/learn\\)' learnova-academy/src` shows no remaining bare catalog-index references, while dynamic `/learn/${slug}` course links remain.

## Risk
- A broad redirect pattern could accidentally catch `/learn/<slug>` and break all course pages; mitigate by using exact `source: "/learn"` and explicitly verifying a real slug route.

## Out of scope
- Changing course publishability rules, homepage course source-of-truth behavior, or sitemap `/capabilities` cleanup from adjacent PR #45 fixes.

## Pre-flight
- status_ok=true
- sibling_chain_ok=true
- acceptance_spec_ok=true (structured `acceptanceCriteria` is null, but issue body plus Chief Engineering dispatch state concrete success criteria)
- basebranch_verified=true
