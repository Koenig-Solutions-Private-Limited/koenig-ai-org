---
ticket: KOEA-2015
planner: planner
date: 2026-05-26
estimated_complexity: small
estimated_token_cost: $0.30
base_branch: origin/academy/redesign-v1
implementation_branch: koea-2015/faq-jsonld
basebranch_verified: true
planner_issue: KOEA-5015
revises_plan_issue: KOEA-2023
shared_fix_for: KOEA-2045
---

# Plan: FAQPage JSON-LD preserves FAQ frontmatter content

## Goal
Make any publishable academy blog with `faq:` frontmatter emit schema.org `FAQPage` JSON-LD alongside the existing `BlogPosting` and `BreadcrumbList` data. Success is observable on both `/blog/2026-04-30-gpt-5-5-in-codex` and `/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive`: generated and live JSON-LD contains `FAQPage.mainEntity` with `Question.name` and `Answer.text` matching the vault frontmatter, without touching non-academy portals or deploying Convex.

## Context
- Files to read first: `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015/learnova-academy/src/lib/vault.ts:21-120`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015/learnova-academy/src/lib/seo.ts:146-223`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015/learnova-academy/src/app/blog/[slug]/page.tsx:16-103`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/blogs/2026-04-30-gpt-5-5-in-codex/draft.md:56-62`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/blogs/2026-05-13-cloudflare-agents-week-2026-build-deep-dive/draft.md:22-28`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/_audit/g5/2026-05-13-cloudflare-agents-week-2026-build-deep-dive-20260514.md:51-77`.
- Relevant prior work: KOEA-2024 requested a plan revision after KOEA-2045 added the KOEA-1748 live-blog regression. The GPT-5.5 draft uses `faq[].question` / `faq[].answer`; the Cloudflare draft uses `faq[].q` / `faq[].a`. Current live KOEA-1748 JSON-LD now includes `FAQPage`, but each `Question` lacks `name` and each `Answer` lacks `text`, so KOEA-2045 is not complete.
- Constraints: use worktree `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015`; target `origin/academy/redesign-v1` verified 2026-05-26; implementation branch `koea-2015/faq-jsonld`; keep scope constrained to `learnova-academy`; route KOEA-1748-specific live verification through KOEA-2050 after shared G_code KOEA-2026 passes; do not deploy Convex; do not touch `learnova-student`, `learnova-sales`, `learnova-admin`, or `learnova-tc`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Normalize blog FAQ frontmatter at the vault boundary, then strengthen the regression verifier to compare generated JSON-LD against the source Q&A content for both affected slugs. `blog/[slug]/page.tsx` already appends `faqPageLd(post.faq)` and `seo.ts` already renders the correct schema shape when it receives `{ question, answer }`, so the smallest durable fix is to make `vault.ts` accept both `question`/`answer` and `q`/`a` frontmatter forms and expose one normalized `BlogPost.faq` contract.
**Rejected**: Tolerate `q`/`a` inside `faqPageLd` - leaks vault parsing concerns into SEO helpers; rewrite the Cloudflare draft frontmatter to `question`/`answer` - fixes one article but leaves the content contract ambiguous; inline special-case JSON-LD in `blog/[slug]/page.tsx` - duplicates the existing helper and increases page-level blast radius.

## Steps (Executor follows in order)
1. Confirm branch state in `/paperclip/instances/default/workspaces/learnovaBeast-koea-2015`: work from `origin/academy/redesign-v1` on implementation branch `koea-2015/faq-jsonld`, account for any existing workspace dirt before editing, and keep changes inside `learnova-academy/`.
2. Update `learnova-academy/src/lib/vault.ts` to normalize `data.faq` into `{ question, answer }[]` by accepting either `question`/`answer` or `q`/`a`, trimming strings, and dropping invalid or incomplete entries. Keep `BlogPost.faq` as the normalized contract.
3. Inspect `learnova-academy/src/lib/seo.ts` and `learnova-academy/src/app/blog/[slug]/page.tsx`. Preserve the existing `faqPageLd` output shape and page hook; only adjust them if required to avoid emitting an empty `FAQPage` when normalization returns no valid entries.
4. Add or update `learnova-academy/scripts/verify-blog-faq-jsonld.mjs` so it accepts one or more slug arguments, reads each source vault draft, normalizes FAQ entries with the same accepted key forms, parses built `<script type="application/ld+json">` payloads, and fails unless `BlogPosting`, `BreadcrumbList`, and `FAQPage` are present and every generated `Question.name` / `Answer.text` matches the source Q&A content.
5. Add a package script in `learnova-academy/package.json`, for example `"verify:faq-jsonld": "node ./scripts/verify-blog-faq-jsonld.mjs"`, without adding new dependencies.
6. Run the smallest verification from `learnova-academy`: `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault npm run build && npm run verify:faq-jsonld -- 2026-04-30-gpt-5-5-in-codex 2026-05-13-cloudflare-agents-week-2026-build-deep-dive`. If Next's output path differs, update the verifier to discover slug HTML under `.next/server/app/blog/`.
7. Open or update the draft PR against `academy/redesign-v1`, report that KOEA-1748-specific live validation is delegated to KOEA-2050 after KOEA-2026 shared G_code passes, and do not deploy Convex or touch other portals.

## Verification (QA Verifier checks these)
- [ ] Local build command succeeds with `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault npm run build`.
- [ ] `npm run verify:faq-jsonld -- 2026-04-30-gpt-5-5-in-codex 2026-05-13-cloudflare-agents-week-2026-build-deep-dive` finds parseable `BlogPosting`, `BreadcrumbList`, and `FAQPage` JSON-LD for both generated blog pages, with `FAQPage.mainEntity` preserving source `Question.name` and `Answer.text`.
- [ ] After the PR is deployed, KOEA-2050 confirms the live URL `https://academy.kspl.tech/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive` emits parseable `BlogPosting`, `BreadcrumbList`, and content-bearing `FAQPage` JSON-LD.
- [ ] Changed files are limited to `learnova-academy/src/lib/vault.ts`, `learnova-academy/src/lib/seo.ts` only if empty FAQ suppression is needed, `learnova-academy/src/app/blog/[slug]/page.tsx` only if the hook is missing, `learnova-academy/scripts/verify-blog-faq-jsonld.mjs`, and `learnova-academy/package.json`.

## Risk
- There are two FAQ frontmatter shapes in live vault content, so future articles could introduce more variants. Mitigation: support only the two observed shapes in `vault.ts`, fail the verifier on incomplete entries, and leave broader content-schema validation to a separate ticket.

## Out of scope
- No Convex deployment, no changes to student/sales/admin/tc portals, no live deployment by Executor, no manual rewrite of blog content frontmatter, and no broad structured-data refactor beyond the academy blog FAQ path.
