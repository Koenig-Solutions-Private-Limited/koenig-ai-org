---
ticket: KOEA-8335
parent_ticket: KOEA-8314
root_ticket: KOEA-2045
planner: planner
date: 2026-06-14
type: decision
tags:
  - decision
  - koea-8314
estimated_complexity: small
estimated_token_cost: $0.47
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_cooldown: b42a5af4-2e63-437c-b8f1-13b092d79fee
---

# Plan: Restore live FAQPage by fixing the Vercel deploy blocker

## Goal
The live Cloudflare Agents Week blog should emit parseable `FAQPage` JSON-LD with 3 `Question` entries while preserving the existing `BlogPosting`, `BreadcrumbList`, and redesign `HowTo` schemas. Success is observable on `https://academy.kspl.tech/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive`, not only in source or a PR preview.

## Context
- Files to read first: `learnova-academy/next.config.ts:1-22`, `learnova-academy/scripts/sync-vault.mjs:35-40`, `learnova-academy/scripts/sync-vault.mjs:108-180`, `learnova-academy/src/lib/courses.ts:94-153`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:106-150`, `learnova-academy/src/lib/vault.ts:114-141`, `learnova-academy/scripts/verify-blog-faq-jsonld.mjs:1-91`.
- Relevant prior work: PR #139 merged to `main` at `313b16f0`, but its Vercel context failed. `academy/redesign-v1` is the production checkout in `.github/workflows/publish.yml:16-20` and already has FAQ normalization + blog JSON-LD wiring at `44999795`.
- Live evidence from 2026-06-14: live page returns HTTP 200 with `x-vercel-cache: HIT`, `age: 152872`, and JSON-LD types `BlogPosting`, `BreadcrumbList`, and `HowTo`, but no `FAQPage`.
- Vercel failure evidence: `npx vercel inspect dpl_ELR2M1RZXKAtCiDjod7EsQkRNbFi --logs` reports `llms-full.txt.rsc` is 351.68 MB, over the 300 MB function limit, because `learnova-academy/public/courses` is traced into serverless functions at roughly 364 MB.
- Constraints: keep Convex and vault content untouched; preserve legacy `/courses/<slug>/...` media URLs; do not merge the broader redesign into `main`; production branch verified with `git ls-remote --heads origin academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Exclude mirrored course media from serverless function tracing on `academy/redesign-v1`. Add a narrow Next config trace exclusion for `./public/courses/**/*` so Vercel can still upload course media as static public assets, but does not pack the 300+ MB directory into route function bundles such as `llms-full.txt.rsc`. Then redeploy the already-correct production branch and verify the live JSON-LD.

**Rejected**: rerun Vercel without code changes - the same 300 MB function limit should fail again; remove/disable `mirrorCourseMedia()` - likely breaks older course audio/slides that still rely on `/courses/<slug>/...`; move all legacy media to R2 now - correct long-term direction but too broad for this critical FAQPage recovery.

## Steps (Executor follows in order)
1. Branch from `origin/academy/redesign-v1` for the repair PR; do not start from `main`, because `.github/workflows/publish.yml` deploys `academy/redesign-v1`.
2. Update `learnova-academy/next.config.ts` with `outputFileTracingExcludes` for `./public/courses/**/*`; if the route glob requires explicit keys, cover `/*`, `/blog/[slug]`, `/learn`, `/learn/[slug]`, `/catalog`, `/llms.txt`, and `/llms-full.txt`.
3. Run `cd learnova-academy && node --experimental-strip-types ./scripts/verify-blog-faq-normalize.mjs` to confirm the vault FAQ shorthand still normalizes to 3 entries.
4. Run `cd learnova-academy && node --experimental-strip-types ./scripts/verify-blog-faq-jsonld.mjs` before and after build; after `pnpm build` it should validate prerendered HTML with `BlogPosting`, `BreadcrumbList`, `HowTo`, and `FAQPage`.
5. Run `cd learnova-academy && npx vercel build --prod` or the repository's production deploy workflow path and confirm the previous `Max serverless function size was exceeded` error is gone.
6. Open the PR against `academy/redesign-v1`, get G_code review, merge after approval, then trigger the existing publish-ready deployment path rather than hand-editing Vercel production state.
7. Recheck live with a JSON-LD parser command and require `FAQPage.mainEntity.length === 3`; also verify `HowTo`, `BlogPosting`, and `BreadcrumbList` remain present.

## Verification (QA Verifier checks these)
- [ ] Vercel build/deploy no longer fails with `llms-full.txt.rsc` over 300 MB.
- [ ] `verify-blog-faq-normalize.mjs` passes on the target branch.
- [ ] `verify-blog-faq-jsonld.mjs` passes against prerendered HTML after build.
- [ ] Live `https://academy.kspl.tech/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive` JSON-LD includes `FAQPage` with exactly 3 `Question` entries.
- [ ] Live JSON-LD still includes `BlogPosting`, `BreadcrumbList`, and `HowTo`.

## Risk
- Trace exclusion globs may be too broad or too narrow for Next 16. Mitigation: inspect `.next/required-server-files.json` and Vercel build output after the change; if `public/courses` still appears in function traces, add explicit route keys for every oversized route listed in the Vercel log.

## Out of scope
- Reworking all legacy course media to R2/chapter-meta sidecars.
- Changing the already-merged PR #139 FAQPage implementation on `main`.
- Changing Convex, vault blog content, or SEO schema beyond the deploy-size repair needed to publish the existing FAQPage code.
