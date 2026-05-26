---
ticket: KOEA-5142
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: academy/redesign-v1
basebranch_verified: true
chain_depth_exception_approval: 3d93213c-42b7-460d-9791-a7d50472ac79
---

# Plan: Fix Cartesia blog canonical slug route

## Goal
Make the Cartesia Sonic 3 blog live at the expected canonical URL `https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning`. Success means the dated frontmatter slug renders the article, emits parseable blog JSON-LD, and appears in sitemap, RSS, and llms discovery outputs after deploy.

## Context
- Files to read first: `learnova-academy/src/lib/vault.ts:55-152`, `learnova-academy/src/app/blog/[slug]/page.tsx:31-70`, `learnova-academy/src/app/sitemap.ts:30-35`, `learnova-academy/src/app/rss.xml/route.ts:30-48`, `learnova-academy/src/app/llms-full.txt/route.ts:76-88`, `vault/blogs/cartesia-sonic-3-voice-cloning/draft.md:1-35`, `vault/_audit/g5/2026-05-14-cartesia-sonic-3-voice-cloning-20260526.md:1-28`.
- Relevant prior work: live evidence shows the article already renders at `/blog/cartesia-sonic-3-voice-cloning`, while the frontmatter declares `slug: 2026-05-14-cartesia-sonic-3-voice-cloning`; `origin/academy/redesign-v1` exists at `33ddab8282e2ac89593bf367c9e77a83bb6feb76`.
- Constraints: plan mode only for KOEA-5143; Executor should work in `learnovaBeast` from a clean branch/worktree based on `origin/academy/redesign-v1` because the current checkout is dirty and behind; do not touch Convex or merge directly to main; no direct production publish outside the publish-action chain.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Treat blog frontmatter `slug` as the public canonical slug and keep the vault directory name as an internal storage key. Update the Academy vault reader so `listPublishableBlogs()` returns `BlogPost.slug` from frontmatter when present and `getBlog()` resolves by canonical public slug, causing the blog route, index links, metadata, sitemap, RSS, and llms routes to share the dated canonical URL through their existing `post.slug` usage.

**Rejected**: Rename `vault/blogs/cartesia-sonic-3-voice-cloning/` to the dated slug because it fixes only this item and leaves six known frontmatter/directory mismatches. **Rejected**: Change Publish Verifier to expect directory slugs because the content frontmatter already declares the intended canonical route and SEO discovery should follow that source of truth. **Rejected**: Debug Vercel deploy lag or publish-action dispatch first because live discovery already contains the article under the undated directory slug, proving the deploy picked up the content.

## Steps (Executor follows in order)
1. Prepare a clean `learnovaBeast` branch from `origin/academy/redesign-v1`, preserving the existing dirty checkout; confirm `git status --short` before editing and keep changes inside `learnova-academy/`.
2. Update `learnova-academy/src/lib/vault.ts` so `readBlogFile(directorySlug)` returns the public slug from `data.slug ?? directorySlug` and retains enough internal directory context to read files without exposing the directory as the route contract.
3. Replace `getBlog(slug)` in `learnova-academy/src/lib/vault.ts` with a canonical lookup over publishable posts, so `getBlog("2026-05-14-cartesia-sonic-3-voice-cloning")` resolves the file in `vault/blogs/cartesia-sonic-3-voice-cloning/draft.md`.
4. Recheck `learnova-academy/src/app/blog/[slug]/page.tsx`, `blog/page.tsx`, `sitemap.ts`, `rss.xml/route.ts`, `llms.txt/route.ts`, and `llms-full.txt/route.ts`; only adjust them if the vault reader change exposes a stale directory-slug assumption.
5. Add a narrow regression check if the repo has a suitable test harness; otherwise add a tiny script-level assertion in the PR notes showing all mismatched vault directories now produce frontmatter-slug URLs.
6. Run `cd learnova-academy && KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm typecheck` and `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm build`.
7. Start the built Academy app locally and verify the dated Cartesia URL, JSON-LD, sitemap, RSS, and llms outputs before opening a draft PR against `academy/redesign-v1`; after merge/deploy, hand KOEA-5127 back to Publish Verifier for G5 recheck.

## Verification (QA Verifier checks these)
- [ ] `curl -sI http://localhost:3010/blog/2026-05-14-cartesia-sonic-3-voice-cloning | head -1` returns `HTTP/1.1 200` or `HTTP/2 200`.
- [ ] `curl -s http://localhost:3010/blog/2026-05-14-cartesia-sonic-3-voice-cloning | rg 'Choose the Cartesia Sonic 3 cloning path|application/ld\\+json'` finds both the article title and JSON-LD script.
- [ ] `curl -s http://localhost:3010/sitemap.xml | rg 'https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning'` finds the dated slug.
- [ ] `curl -s http://localhost:3010/rss.xml | rg 'https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning'` finds the dated slug.
- [ ] `curl -s http://localhost:3010/llms-full.txt | rg 'https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning'` finds the dated slug.

## Risk
- Changing the canonical slug source can move existing undated blog URLs to dated URLs; mitigate by checking all directory/frontmatter mismatches and, if SEO continuity is required, adding explicit redirects in the same PR or routing that follow-up as a separate SEO task.

## Out of scope
- Do not rewrite publish-action, alter `publish_state` semantics, deploy to production manually, touch Convex, or edit the Cartesia article content beyond route/discovery behavior.
