---
ticket: KOEA-8314
planner: planner
date: 2026-06-14
estimated_complexity: small
estimated_token_cost: $0.32
base_branch: main
basebranch_verified: true
chain_alert_resolution: "Existing planner_chain_alert b42a5af4-2e63-437c-b8f1-13b092d79fee for root KOEA-2045 was resolved by Chief Engineering as an authorized gated chain."
---

# Plan: Promote the FAQPage JSON-LD fix to production without the redesign merge

## Goal
Restore `FAQPage` JSON-LD on the production Academy blog page for KOEA-1748 by preparing a clean PR from `main` that contains only the minimal FAQ ingestion and schema-emission fix. Success is a reviewed, mergeable PR into `main`, not a direct merge by Chief Engineering or Planner.

## Context
- Files to read first: `learnova-academy/src/lib/vault.ts:21-39`, `learnova-academy/src/lib/vault.ts:55-122`, `learnova-academy/src/app/blog/[slug]/page.tsx:16-22`, `learnova-academy/src/app/blog/[slug]/page.tsx:77-101`, `learnova-academy/src/lib/seo.ts:213-223`, `learnova-academy/package.json:5-13`.
- Relevant prior work: PR #137 (`koea-7937/restore-faqpage-jsonld` -> `academy/redesign-v1`) merged 2026-06-14 and changed only `learnova-academy/src/lib/vault.ts` plus two verifier scripts; PR #138 (`academy/redesign-v1` -> `main`) is closed with `mergeStateStatus=DIRTY`, Vercel failure, and a diff too large for GitHub's 20,000-line PR diff limit.
- Conflict finding: `git merge-tree --write-tree --name-only origin/main origin/academy/redesign-v1` reports conflicts across `.github/workflows/publish.yml`, `next.config.ts`, `package.json`, `pnpm-lock.yaml`, `scripts/sync-vault.mjs`, `src/app/api/og/route.tsx`, old/new app route moves, shared components, `courses.ts`, and `vault.ts`.
- Constraints: do not merge directly to `main`; do not deploy Convex; do not repair the full `academy/redesign-v1` promotion in this ticket; do not bring unrelated portal/redesign changes into the production PR.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Create a clean promotion branch from `origin/main` and manually port the minimal FAQ behavior. `main` already has `faqPageLd()` in `learnova-academy/src/lib/seo.ts`, but its blog route never appends `faqPageLd(post.faq)`, and its vault reader passes raw `data.faq` through without normalizing the KOEA-1748 draft's `q` / `a` shorthand. Executor should port those two production-specific changes, then add main-compatible verifier scripts.

**Rejected**: Repair PR #138 / merge all of `academy/redesign-v1` into `main` because the conflict surface is broad and unrelated to the production FAQPage hotfix; blind cherry-pick of PR #137 because the first commit edits `normalizeBlogFaq()`, which exists on `academy/redesign-v1` but not on `main`; edit vault content from `q` / `a` to `question` / `answer` because it hides the app ingestion bug and bypasses the desired production code fix.

## Steps (Executor follows in order)
1. Prepare a clean worktree from `main`:
   ```sh
   cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
   git fetch origin main academy/redesign-v1 --prune
   git switch -c koea-8314-faqpage-main origin/main
   ```
2. Edit `learnova-academy/src/lib/vault.ts` to add a small `normalizeBlogFaq(value: unknown)` helper near the reference normalization code; it must accept `question` / `answer` and `q` / `a`, trim both fields, drop incomplete pairs, and keep returning `{ question, answer }[] | undefined`. Replace `faq: Array.isArray(data.faq) ? data.faq : undefined` with `faq: normalizeBlogFaq(data.faq)`.
3. Edit `learnova-academy/src/app/blog/[slug]/page.tsx` so the SEO import includes `faqPageLd`, then append `...(post.faq?.length ? [faqPageLd(post.faq)] : [])` to the existing `jsonLdScript([blogPostingLd(...), breadcrumbLd(...)])` array. Do not port `HowTo`, redesign route moves, hero/image changes, or other `academy/redesign-v1` blog renderer changes.
4. Add main-compatible verifier scripts under `learnova-academy/scripts/`: one check for `getBlog("2026-05-13-cloudflare-agents-week-2026-build-deep-dive").faq.length === 3` with exact Q&A text, and one check that prerendered HTML or source composition includes `BlogPosting`, `BreadcrumbList`, `FAQPage`, and `FAQPage.mainEntity.length === 3`. Do not require `HowTo` on `main`.
5. Run targeted verification from `learnova-academy`:
   ```sh
   node --experimental-strip-types ./scripts/verify-blog-faq-normalize.mjs
   node --experimental-strip-types ./scripts/verify-blog-faq-jsonld.mjs
   pnpm run typecheck
   ```
   If a build is needed for the HTML path, run `pnpm build`; report any unrelated pre-existing build blocker separately instead of broadening the fix.
6. Open a PR from `koea-8314-faqpage-main` to `main` using the repo PR template if present. The PR body must call out PR #137 as source context, PR #138 as deliberately avoided, the no-direct-main-merge boundary, and the production recheck path: after Vercel deploys `main`, fetch `https://academy.kspl.tech/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive` and parse JSON-LD for `FAQPage.mainEntity.length === 3`.

## Verification (QA Verifier checks these)
- [ ] PR diff is limited to `learnova-academy/src/lib/vault.ts`, `learnova-academy/src/app/blog/[slug]/page.tsx`, and focused FAQ verifier scripts.
- [ ] Targeted verifier scripts pass on the `main`-based branch and show the KOEA-1748 blog has exactly 3 normalized FAQ entries.
- [ ] Local or prerendered JSON-LD for `/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive` includes `BlogPosting`, `BreadcrumbList`, and `FAQPage` with `mainEntity.length === 3`.
- [ ] The PR into `main` is reviewed and green enough for the agreed hotfix boundary before any production merge; after deploy, the live URL is rechecked for the same JSON-LD result.

## Risk
- Risk: main and academy have diverged enough that blindly reusing PR #137's verifier may assert `HowTo` or other redesign-only behavior. Mitigation: keep the verifier scoped to the production `main` contract: blog FAQ normalization plus `FAQPage` emission only.

## Out of scope
- Full `academy/redesign-v1` promotion, PR #138 resurrection, Vercel/Convex configuration changes, lockfile churn unrelated to the focused scripts, course renderer fixes, or any unrelated portal/redesign conflict resolution.
