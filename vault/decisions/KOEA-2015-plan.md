---
ticket: KOEA-2015
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.25
base_branch: origin/academy/redesign-v1
implementation_branch: koea-2015/faq-jsonld
basebranch_verified: true
planner_issue: KOEA-2023
---

# Plan: FAQPage JSON-LD for FAQ blog frontmatter

## Goal
Make any publishable academy blog with `faq:` frontmatter emit schema.org `FAQPage` JSON-LD alongside the existing `BlogPosting` and `BreadcrumbList` data. Success is observable on `/blog/2026-04-30-gpt-5-5-in-codex`: local build output contains a JSON-LD object with `"@type":"FAQPage"` and `mainEntity` questions matching the vault frontmatter, without touching non-academy portals or deploying Convex.

## Context
- Files to read first: `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015/learnova-academy/src/lib/vault.ts:21-120`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015/learnova-academy/src/lib/seo.ts:146-223`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015/learnova-academy/src/app/blog/[slug]/page.tsx:16-103`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/blogs/2026-04-30-gpt-5-5-in-codex/draft.md:56-62`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/_audit/g5/2026-04-30-gpt-5-5-in-codex-20260514.md:42-54`.
- Relevant prior work: G5 audit `vault/_audit/g5/2026-04-30-gpt-5-5-in-codex-20260514.md` reports live JSON-LD types `BlogPosting`, `BreadcrumbList`, and `ListItem`, but no `FAQPage`, even though the source draft has three FAQ entries.
- Constraints: use worktree `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015`; target `origin/academy/redesign-v1`; implementation branch `koea-2015/faq-jsonld`; do not deploy Convex; do not touch `learnova-student`, `learnova-sales`, `learnova-admin`, or `learnova-tc`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Preserve the existing academy structured-data pipeline and add a focused regression verification. In the current checkout, `vault.ts` already carries `faq` into `BlogPost`, `seo.ts` already has `faqPageLd`, and `blog/[slug]/page.tsx` already appends `faqPageLd(post.faq)` when FAQ frontmatter exists. Executor should first confirm that production hook is present, avoid duplicating it, then add a small build-output verifier under `learnova-academy/scripts/` plus an npm script so the PR proves the target blog's generated HTML contains `FAQPage`.
**Rejected**: Inline FAQ JSON-LD directly in `blog/[slug]/page.tsx` - duplicates `faqPageLd` and weakens shared SEO helpers; move FAQ data out of blog frontmatter - changes content contract outside the G5 failure; broad SEO refactor across course/blog pages - too much blast radius for a single L3 red.

## Steps (Executor follows in order)
1. Confirm branch state in `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015`: stay on `koea-2015/faq-jsonld`, verify `git ls-remote --heads origin academy/redesign-v1` returns a row, and keep changes inside `learnova-academy/`.
2. Inspect `learnova-academy/src/app/blog/[slug]/page.tsx`. If the `faqPageLd` import and `...(post.faq?.length ? [faqPageLd(post.faq)] : [])` entry are missing in Executor's checkout, add them inside the existing `jsonLdScript([...])`; if they are present, leave this production hook unchanged.
3. Inspect `learnova-academy/src/lib/vault.ts` and `learnova-academy/src/lib/seo.ts`. Keep `BlogPost.faq`, `faq: Array.isArray(data.faq) ? data.faq : undefined`, and `faqPageLd` aligned; only adjust types if needed for the verifier, not for a broader schema redesign.
4. Add `learnova-academy/scripts/verify-blog-faq-jsonld.mjs` that reads the built HTML for a slug argument, parses all `<script type="application/ld+json">` blocks, flattens array payloads, and fails unless one object has `"@type" === "FAQPage"` with non-empty `mainEntity`.
5. Add a package script in `learnova-academy/package.json`, for example `"verify:faq-jsonld": "node ./scripts/verify-blog-faq-jsonld.mjs"`, without adding new dependencies.
6. Run the smallest verification from `learnova-academy`: `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault npm run build && npm run verify:faq-jsonld -- 2026-04-30-gpt-5-5-in-codex`. If build output path differs under Next 16, update the verifier to discover the slug HTML under `.next/server/app/blog/`.
7. Open the draft PR against `academy/redesign-v1` and report whether the production FAQ hook was newly added or already present on the base branch; do not deploy Convex or touch other portals.

## Verification (QA Verifier checks these)
- [ ] Local build command succeeds with `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault npm run build`.
- [ ] `npm run verify:faq-jsonld -- 2026-04-30-gpt-5-5-in-codex` finds `FAQPage` with at least one `mainEntity` question in the generated blog HTML.
- [ ] Changed files are limited to `learnova-academy/src/app/blog/[slug]/page.tsx` if the hook was missing, `learnova-academy/scripts/verify-blog-faq-jsonld.mjs`, and `learnova-academy/package.json`.

## Risk
- The current base branch appears to already contain the FAQ JSON-LD hook, so the live red may be stale deployment or Vercel vault-sync state rather than missing source code. Mitigation: require the build-output verifier and have Executor explicitly report whether source code changed or the PR is regression/deploy-trigger only.

## Out of scope
- No Convex deployment, no changes to student/sales/admin/tc portals, no changes to blog content frontmatter, and no broad structured-data refactor beyond the FAQ blog path.
