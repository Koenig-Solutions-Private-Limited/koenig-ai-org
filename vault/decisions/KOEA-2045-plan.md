---
ticket: KOEA-2045
planner: planner
date: 2026-06-13
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
chain_alert_resolution: "Chief Engineering comment 9df1dc7f-7792-4c80-9f03-5d7e69ed4b62 authorized KOEA-7935 -> KOEA-7936 -> KOEA-7937 -> KOEA-7938 -> KOEA-2050"
---

# Plan: Restore FAQPage JSON-LD for the KOEA-1748 live blog

## Goal
Make the KOEA-1748 blog page emit `FAQPage` JSON-LD with exactly the 3 vault FAQ entries while preserving the existing `BlogPosting`, `BreadcrumbList`, and `HowTo` JSON-LD objects. Success is observable both in the local/prerendered Academy output and on the production URL after deployment.

## Context
- Files to read first: `learnova-academy/src/lib/vault.ts:114-132`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:106-150`, `learnova-academy/src/lib/seo.ts:267-277`, `vault/blogs/2026-05-13-cloudflare-agents-week-2026-build-deep-dive/draft.md:42-49`, `vault/_audit/g5/2026-05-13-cloudflare-agents-week-2026-build-deep-dive-20260514.md:42-63`.
- Relevant prior work: KOEA-1748 publish audit recorded L3 RED because the live page had `BlogPosting` and `BreadcrumbList` but no `FAQPage`; fresh live check on 2026-06-13 shows `BlogPosting`, `BreadcrumbList`, and `HowTo`, still no `FAQPage`.
- Constraints: plan-only ticket; implementation must target `learnovaBeast` branch `academy/redesign-v1` (verified present); do not modify the vault blog content to paper over the app bug; preserve existing HowTo behavior introduced after the original G5 audit.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Accept legacy `q` / `a` FAQ frontmatter aliases in the build-time vault reader. `BlogPage` already appends `faqPageLd(post.faq)` when `post.faq?.length`, and `faqPageLd` already emits valid `FAQPage.mainEntity`; the miss is that `normalizeBlogFaq()` only accepts `question` / `answer`, while the KOEA-1748 vault draft uses `q` / `a`. Widening normalization fixes all blogs using the observed shorthand without touching rendering, generated schema shape, or vault content.

**Rejected**: Rename this one vault draft from `q` / `a` to `question` / `answer` — it would clear one page but leave the ingestion bug for other published drafts; add FAQ schema directly in the blog template — duplicates logic that already belongs in `faqPageLd`; republish/redeploy only — live output proves the current deployed code path still drops the FAQ data.

## Steps (Executor follows in order)
1. Create the implementation branch from `academy/redesign-v1` in `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`.
2. Edit `learnova-academy/src/lib/vault.ts:114-132` so `normalizeBlogFaq()` accepts either `question` / `answer` or `q` / `a`, trims both fields, keeps rejecting incomplete pairs, and continues returning `{ question, answer }[] | undefined`.
3. Add or run a focused regression check for the KOEA-1748 draft that proves `getBlog("2026-05-13-cloudflare-agents-week-2026-build-deep-dive")?.faq?.length === 3` and that the normalized question/answer text matches the vault frontmatter.
4. Build or prerender the Academy app with the local vault available (`cd learnova-academy && pnpm build`, using the repo's `sync-vault` defaults) and inspect the generated blog HTML for JSON-LD types.
5. Verify the generated JSON-LD includes `BlogPosting`, `BreadcrumbList`, `HowTo`, and `FAQPage`, and that `FAQPage.mainEntity.length === 3`.
6. Open or update the implementation PR with the root cause, the exact verification commands, and the production recheck requirement after deploy.

## Verification (QA Verifier checks these)
- [ ] Local/prerendered blog HTML for `/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive` has parseable JSON-LD types including `BlogPosting`, `BreadcrumbList`, `HowTo`, and `FAQPage`.
- [ ] `FAQPage.mainEntity` contains exactly 3 `Question` entries matching the vault `faq` frontmatter Q&A pairs.
- [ ] After merge/deploy, `https://academy.kspl.tech/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive` returns HTTP 200 and live JSON-LD has the same four types with `FAQPage.mainEntity.length === 3`.

## Risk
- Risk: accepting `q` / `a` aliases could publish malformed FAQ schema if a draft has partial shorthand entries. Mitigation: keep the existing complete-pair filter and only normalize entries with non-empty question and answer text.

## Out of scope
- Rewriting existing vault frontmatter, changing visible FAQ rendering, altering `HowTo` schema behavior, or adding unrelated SEO schema coverage beyond restoring `FAQPage` for blog FAQ frontmatter.
