---
ticket: KOEA-1977
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.42
base_branch: origin/academy/redesign-v1
approved_chain_alert: ad7fd785-e68e-4a87-828f-a7fdeda5e3f0
basebranch_verified: true
---

# Plan: Repair academy published blog route 404

## Goal
Restore and verify the published KOEA-1748 artifact at `/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive`. Success means the live route returns HTTP 200 with the expected article title/body, canonical URL, `BlogPosting`, `BreadcrumbList`, and discovery entries in sitemap, RSS, `llms.txt`, and `llms-full.txt`.

Current observation on 2026-05-14T05:01Z: the live route now returns HTTP 200 and includes the title, canonical, `BlogPosting`, `BreadcrumbList`, sitemap entry, RSS entry, `llms.txt`, and `llms-full.txt`. Treat this as a possibly already-resolved propagation/build issue, not as permission to skip verification.

## Context
- Files to read first:
  - `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/blog/[slug]/page.tsx:31-70` for static params, metadata, and `notFound()` behavior.
  - `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/blog/[slug]/page.tsx:76-103` for `BlogPosting`, `BreadcrumbList`, and FAQ JSON-LD emission.
  - `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/lib/vault.ts:43-53` and `:125-152` for publishable status filtering, slug discovery, and `getBlog()`.
  - `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/scripts/sync-vault.mjs:27-32` and `:56-99` for Vercel vault clone root/ref/token behavior.
  - `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/sitemap.ts:30-35`, `src/app/rss.xml/route.ts:30-49`, `src/app/llms.txt/route.ts:28-63`, and `src/app/llms-full.txt/route.ts:14-93` for discovery surfaces.
  - `vault/blogs/2026-05-13-cloudflare-agents-week-2026-build-deep-dive/draft.md:1-61` for artifact frontmatter and title.
  - `vault/_audit/g5/2026-05-13-cloudflare-agents-week-2026-build-deep-dive-20260514.md:1-55` for the original RED evidence.
- Relevant prior work: `koenig-ai-org` now has `origin/master` commit `0a1f2b9b chore: bring Cloudflare Agents Week blog to master for publish pipeline`; `learnova-academy` `origin/academy/redesign-v1` includes `63fc2c3 fix(vault): widen PUBLISHABLE_STATES...` and `7a564c5 safety: guard sync-vault rm -rf + add typecheck script`.
- Constraints: use `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy`; do not use `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`; base the implementation branch from `origin/academy/redesign-v1`; no Convex deploy unless unavoidable, and if unavoidable only from `learnova-tc`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Evidence-driven verify-then-patch. The original failure can be explained by the artifact not being available to the Vercel build/ref at verification time, because the current live route and discovery surfaces are green after the vault commit reached `origin/master`. Executor should first prove the current academy branch plus vault content produce the route, then make no code change if live/local checks stay green; only patch the specific failing layer if a reproducible failure remains.

**Rejected**: Force a new catch-all/dynamic fallback route - unnecessary because `generateStaticParams()` already reads `listPublishableBlogs()` and the current route prerenders correctly; it would weaken static SEO guarantees. **Rejected**: Edit the blog markdown slug/frontmatter - the slug, title, and `status: published` are already correct, and changing content risks creating a second URL. **Rejected**: Convex deploy - the academy blog pipeline is static vault-to-Vercel and does not depend on Convex for this route.

## Steps (Executor follows in order)
1. Prepare the correct workspace: in `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy`, fetch, create a KOEA-1977 feature branch from `origin/academy/redesign-v1`, and leave `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` untouched.
2. Reconfirm content availability: verify `vault/blogs/2026-05-13-cloudflare-agents-week-2026-build-deep-dive/draft.md` has `slug`, `title`, and `status: published`, and verify `git -C /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org log origin/master --oneline -- vault/blogs/2026-05-13-cloudflare-agents-week-2026-build-deep-dive/` includes the artifact commit.
3. Reproduce the route-generation path locally from the academy workspace with the real vault root: run `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm build` and confirm the build/prerender output includes the target `/blog/...` route; if build output is not explicit enough, run `pnpm start` on an available port and curl the local route.
4. If local route generation fails, patch only the failing layer: `src/lib/vault.ts` for publishable filtering/slug lookup, `scripts/sync-vault.mjs` for Vercel clone/ref/token behavior, or `src/app/blog/[slug]/page.tsx` for `generateStaticParams()`, `generateMetadata()`, and `notFound()` handling.
5. If the route is 200 but metadata or JSON-LD is missing, patch `src/app/blog/[slug]/page.tsx` and/or `src/lib/seo.ts`; keep `BlogPosting`, `BreadcrumbList`, canonical, Open Graph, and Twitter metadata tied to the same `post.slug` from `getBlog(slug)`.
6. If the article route is green but discovery is missing, patch the specific discovery surface that omits `listPublishableBlogs()`: `src/app/sitemap.ts`, `src/app/rss.xml/route.ts`, `src/app/llms.txt/route.ts`, or `src/app/llms-full.txt/route.ts`.
7. Run the verification commands below, record whether code changed or the issue was already resolved by vault propagation, and hand off to G_code/G2 with no Convex deploy.

## Verification (QA Verifier checks these)
- [ ] `git -C /paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy ls-remote --heads origin academy/redesign-v1` returns a branch row before implementation starts.
- [ ] `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm build` passes from the academy workspace.
- [ ] `curl -sSI https://academy.kspl.tech/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive` returns `HTTP/2 200` and `x-matched-path` for the concrete blog slug, not `/blog/[slug]` 404 shell evidence.
- [ ] The live HTML title contains `Build Production AI Agents on Cloudflare: What Agents Week Actually Shipped`, includes canonical `/blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive`, and contains `BlogPosting` plus `BreadcrumbList`.
- [ ] `https://academy.kspl.tech/sitemap.xml`, `/rss.xml`, `/llms.txt`, and `/llms-full.txt` each contain the target slug or title.

## Risk
- Vercel may still serve stale prerendered output from a previous build in one region. Mitigation: compare `age`, `x-vercel-cache`, and `x-matched-path` headers across repeated checks; if stale 404 persists after a green build, trigger a normal Vercel redeploy of the academy project, not a Convex deploy.

## Out of scope
- Rewriting the markdown article, changing its slug, changing unrelated blog routing, or deploying Convex.
