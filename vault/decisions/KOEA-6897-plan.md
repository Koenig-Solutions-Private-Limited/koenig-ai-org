---
ticket: KOEA-6897
planning_ticket: KOEA-6916
planner: planner
agent: planner
date: 2026-06-01
type: decision
tags:
  - decision
estimated_complexity: small
estimated_token_cost: $0.30
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_resolved_by_approval: 05505298-fbf5-4439-9406-a3f7a1118806
---

# Plan: Render GEO Schema for Academy Pages

## Goal
Render valid structured data for Koenig AI Academy discovery surfaces without changing the content model or deploying Convex. Success means homepage source includes Organization and WebSite JSON-LD, every renderable blog post source includes BlogPosting JSON-LD and FAQPage JSON-LD when valid `faq` frontmatter exists, and `/llms.txt` starts with a timestamped descriptive header.

## Context
- Files to read first: `learnova-academy/CLAUDE.md:1-48`, `learnova-academy/package.json:1-24`, `learnova-academy/src/lib/vault.ts:21-58`, `learnova-academy/src/lib/vault.ts:150-188`, `learnova-academy/src/lib/seo.ts:65-99`, `learnova-academy/src/lib/seo.ts:168-197`, `learnova-academy/src/lib/seo.ts:266-276`, `learnova-academy/src/lib/seo.ts:484-487`, `learnova-academy/src/lib/authors.ts:82-121`, `learnova-academy/src/app/(site)/page.tsx:76-83`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:75-129`, `learnova-academy/src/app/llms.txt/route.ts:28-44`.
- Relevant prior work: current `src/lib/seo.ts` already has Organization, WebSite, BlogPosting, FAQPage, and JSON-LD serialization helpers; current blog template already emits BlogPosting, BreadcrumbList, optional FAQPage, and optional HowTo in one `application/ld+json` script.
- Constraints: work in the `learnovaBeast` Academy app only; base work from `academy/redesign-v1` and never `main`; preserve unrelated dirty files; do not deploy Convex unless a code read proves it is necessary, and then only from `learnova-tc`; keep schema output deterministic and escaped through `jsonLdScript`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Tighten the existing static-render path. Executor should keep using `src/lib/seo.ts` JSON-LD helpers and existing App Router `<script type="application/ld+json">` render points, then add the missing/null-safe data wiring: sanitize blog FAQ frontmatter before emitting FAQPage, pass `post.last_updated` as BlogPosting `dateModified`, confirm homepage Organization/WebSite stays in source, and prepend `/llms.txt` with generated timestamp plus concise site description.

**Rejected**: Add a new schema component abstraction — unnecessary because there is already one serializer and established per-route script pattern; generate schemas from Convex or runtime APIs — out of scope because Academy blogs and discovery surfaces are build-time vault/static data; emit one schema per separate script tag — noisier and inconsistent with the existing array-based `jsonLdScript` pattern.

## Steps (Executor follows in order)
1. Create or use a clean `learnovaBeast` execution worktree from `origin/academy/redesign-v1` for this ticket, for example `git fetch origin academy/redesign-v1` then a KOEA-6897 branch/worktree; do not base from or merge into `main`, and do not overwrite unrelated dirty files in the existing checkout.
2. In `learnova-academy/src/lib/vault.ts`, add a small normalizer for `faq` frontmatter that accepts only array entries with non-empty string `question` and `answer`, trims both fields, and returns `undefined` when no valid entries remain; keep the `BlogPost["faq"]` shape unchanged.
3. In `learnova-academy/src/lib/seo.ts`, leave `blogPostingLd`, `faqPageLd`, `organizationLd`, `websiteLd`, and `jsonLdScript` as the single schema surface unless TypeScript reveals a needed input type tweak; do not introduce fake ratings, search result counts, or unverified organization facts.
4. In `learnova-academy/src/app/(site)/blog/[slug]/page.tsx`, pass `dateModified: post.last_updated` into `blogPostingLd`, continue falling back to `date` inside the helper, and emit `faqPageLd(post.faq)` only after the normalized `faq` list is non-empty.
5. In `learnova-academy/src/app/(site)/page.tsx`, verify the existing Organization + WebSite script remains server-rendered before `<TopBar />`; only edit if implementation drift removed either schema.
6. In `learnova-academy/src/app/llms.txt/route.ts`, add header lines immediately after `# Koenig AI Academy` for `Updated: <YYYY-MM-DD>` and a short `Description:` sentence; derive the date at build/request time with an ISO date slice and keep the response plain text with the existing cache header.
7. Run targeted verification from `learnova-academy`: `pnpm typecheck`, `pnpm build`, and `pnpm verify:g2-seo`; then serve locally on port 3010 and source-check `/`, one FAQ-bearing blog such as `/blog/2026-05-31-multi-agent-orchestration-real-cost-2026`, and `/llms.txt`.

## Verification (QA Verifier checks these)
- [ ] `pnpm typecheck`, `pnpm build`, and `pnpm verify:g2-seo` pass from `learnova-academy`.
- [ ] Page source for `http://localhost:3010/` contains one `application/ld+json` block with both `"@type":"Organization"` and `"@type":"WebSite"`.
- [ ] Page source for a FAQ-bearing blog contains `"@type":"BlogPosting"`, `"datePublished"`, `"dateModified"`, `"author"`, `"publisher"`, and `"@type":"FAQPage"` with `Question`/`Answer` entities.
- [ ] `curl http://localhost:3010/llms.txt | sed -n '1,8p'` shows `# Koenig AI Academy`, an `Updated: YYYY-MM-DD` line, and a `Description:` line before the existing `## Pages` section.

## Risk
- Malformed vault frontmatter could previously pass through as invalid JSON-LD entities; mitigate by filtering to complete non-empty FAQ pairs before rendering and by leaving the public article body untouched.
- A dynamic timestamp in `/llms.txt` can vary between builds; mitigate by using date-only ISO format and keeping cache semantics unchanged.

## Out of scope
- No Convex schema/function changes, no Convex deployment, no author registry expansion, no generated ratings/reviews, no sitemap/RSS changes, and no redesign of the blog or homepage UI.

## Pre-flight Footer
- `koenig-ai-org` vault sync: `git pull origin master --rebase=false` passed on 2026-06-01.
- `learnovaBeast` base branch check: `git ls-remote --heads origin academy/redesign-v1` returned `84295a935a506b7290bdd237e24ca6098e48ca91`.
- Sibling chain note: KOEA-6916 has sequential pipeline siblings, but Chief Engineering resolved planner_chain_alert `05505298-fbf5-4439-9406-a3f7a1118806` and authorized proceeding.
- `basebranch_verified=true`
