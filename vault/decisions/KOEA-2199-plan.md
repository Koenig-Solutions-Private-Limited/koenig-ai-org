---
ticket: KOEA-2199
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.25
base_branch: academy/redesign-v1
basebranch_verified: true
unblocked_by_comment: a7f0958d-25bb-4977-9b7c-f089e3ea896a
---

# Plan: fix Academy blog 404 for Anthropic legal MCP post

## Goal
Make `https://academy.kspl.tech/blog/2026-05-14-anthropic-legal-mcp-vs-openai-fde-enterprise-wedge` render the vault article instead of the generic 404 shell. Success means the same post is also discoverable through sitemap/RSS/llms outputs, with canonical metadata and article JSON-LD present.

## Context
- Files to read first: `learnova-academy/src/lib/vault.ts:21-148`, `learnova-academy/src/app/blog/[slug]/page.tsx:31-101`, `learnova-academy/src/app/sitemap.ts:30-35`, `learnova-academy/src/app/rss.xml/route.ts:30-51`, `learnova-academy/src/app/llms.txt/route.ts:28-63`, `vault/blogs/anthropic-legal-mcp-vs-openai-fde-enterprise-wedge/draft.md:1-44`, `vault/_audit/g5/2026-05-14-anthropic-legal-mcp-vs-openai-fde-enterprise-wedge-20260514.md:1-72`.
- Relevant prior work: G5 evidence reports live 404, missing canonical, zero JSON-LD blocks, and missing sitemap/RSS/llms discovery for the slug. Local source draft exists with `status: g4-approved`.
- Constraints: implementation target is `learnovaBeast/learnova-academy` on `academy/redesign-v1`; do not deploy Convex; do not sweep unrelated dirty vault changes into this fix; verify the vault draft is present on `koenig-ai-org` `origin/master` before claiming the live route is fixed.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Fix the shared Academy vault reader so the publish pipeline's approved state is actually publishable. `getBlog()` and `listPublishableBlogs()` are the common gate for `/blog/[slug]`, `generateStaticParams()`, sitemap, RSS, and llms routes; adding `g4-approved` to the accepted status model fixes the 404 and all discovery surfaces through one narrow contract change. While in that file, normalize FAQ frontmatter from both `{q, a}` and `{question, answer}` into the existing `faqPageLd()` shape so the article's FAQ JSON-LD is valid once the page renders.
**Rejected**: Change this one draft's vault status to `published` only, because it masks the mismatch between Paperclip's `g4-approved` publish state and Academy's reader. **Rejected**: Hardcode a fallback for this slug in `/blog/[slug]`, because it would not fix sitemap/RSS/llms and would create one-off routing debt. **Rejected**: Start by changing Vercel/vault sync branch defaults, because the local file still fails the Academy reader even when present.

## Steps (Executor follows in order)
1. In `learnovaBeast/learnova-academy/src/lib/vault.ts`, extend the `BlogPost.status` type and `PUBLISHABLE_STATES` to include `awaiting-g0` and `g4-approved`, matching the existing comment that only explicit rejects should be hidden.
2. In the same file, normalize `data.faq` entries so drafts using `q`/`a` frontmatter become `{ question, answer }`, while preserving existing `{ question, answer }` support.
3. Update `learnovaBeast/learnova-academy/README.md` vault-reader documentation so the publishable states list includes the current pipeline states, especially `g4-approved`.
4. Run a local content check against the real vault root, confirming `getBlog("2026-05-14-anthropic-legal-mcp-vs-openai-fde-enterprise-wedge")` returns a post and `listPublishableBlogs()` includes the slug.
5. Run `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm --dir learnova-academy typecheck` and `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm --dir learnova-academy build`.
6. Verify the source draft is on the deployed vault ref with `git -C /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org log origin/master --oneline -- vault/blogs/anthropic-legal-mcp-vs-openai-fde-enterprise-wedge/draft.md`; if it is still absent, block as repo-state/publish-chain rather than pushing unrelated vault changes.
7. After Academy deploy/rebuild, verify the live route returns HTTP 200 and contains title keywords, a canonical for the slug, `BlogPosting` JSON-LD, and the slug in `/sitemap.xml`, `/rss.xml`, and `/llms-full.txt`.

## Verification (QA Verifier checks these)
- [ ] `curl -sS -I -L https://academy.kspl.tech/blog/2026-05-14-anthropic-legal-mcp-vs-openai-fde-enterprise-wedge` returns HTTP 200, not 404.
- [ ] Live HTML contains `Choose Connectors or Engineers`, `rel="canonical"` for the exact slug, and `application/ld+json` with `BlogPosting`.
- [ ] Live `/sitemap.xml`, `/rss.xml`, and `/llms-full.txt` contain `2026-05-14-anthropic-legal-mcp-vs-openai-fde-enterprise-wedge`.
- [ ] `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm --dir learnova-academy typecheck` passes.
- [ ] `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm --dir learnova-academy build` passes.

## Risk
- Risk: the Academy code fix can pass locally while live stays 404 if the vault draft is not present on the ref Vercel clones. Mitigation: make the origin-master vault check explicit and block on publish-chain state instead of committing or pushing unrelated dirty vault files.

## Out of scope
- Reworking the whole publish-action/vault-sync pipeline.
- Deploying Convex or changing non-Academy portals.
- Publishing unrelated vault changes currently present in the local `koenig-ai-org` worktree.
