---
ticket: KOEA-1776
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.24
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Publish blog slide decks from vault to the academy site

## Goal

Fix the live GPT-5.5 Codex blog so it visibly links `/slides/2026-04-30-gpt-5-5-in-codex.pptx` and the static slide URL returns non-404 after deploy. Success is observable on the academy portal only: the blog page renders a slide-deck download affordance and the `.pptx` is served from `learnova-academy/public/slides/`.

Root cause category: **missing static asset copy plus missing checked-in page/template link rendering**. The source vault has `vault/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx`, but `learnova-academy/scripts/sync-vault.mjs` only mirrors course media to `public/courses/`, `learnova-academy/src/lib/vault.ts` exposes no blog `slides_url`, and the checked-in blog page source renders no slide-deck link.

## Context

- Files to read first: `learnova-academy/scripts/sync-vault.mjs:18-38`, `learnova-academy/scripts/sync-vault.mjs:102-176`, `learnova-academy/src/lib/vault.ts:21-41`, `learnova-academy/src/lib/vault.ts:102-122`, `learnova-academy/src/app/blog/[slug]/page.tsx:245-265`, `learnova-academy/src/app/blog/[slug]/page.tsx:736-805`.
- Relevant prior work: `vault/_audit/g5/2026-04-30-gpt-5-5-in-codex-20260513.md` records L3 RED: page lacks `/slides/2026-04-30-gpt-5-5-in-codex.pptx` and that URL returns 404; `vault/decisions/KOEA-1393-plan.md` documented the earlier verifier-only workaround before this ticket requested the actual production feature.
- Constraints: implement only in `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` on `academy/redesign-v1`; do not edit `learnova-admin`, `learnova-sales`, `learnova-student`, or `learnova-tc`; do not edit vault content unless a missing source asset is proven; expected QA port is `3001`.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Derive blog slide availability from `vault/blogs/<slug>/slides.pptx`, mirror those decks into `public/slides/<slug>.pptx` during `sync-vault.mjs`, and render a download link from the blog template when `post.slides_url` exists. This keeps the vault as source of truth, matches Next's normal static-file serving, and fixes both acceptance surfaces with three focused academy files.

**Rejected**: Add hardcoded frontmatter metadata to only the GPT-5.5 draft — fixes one link but leaves the asset URL 404 and creates per-post drift. **Rejected**: copy a single `.pptx` directly into `public/slides/` without changing the sync script — passes locally once but fails the next Vercel vault sync or for the other blog decks already present in `vault/blogs/*/slides.pptx`.

## Steps (Executor follows in order)

1. In `learnovaBeast`, create an implementation branch from verified base `academy/redesign-v1`; leave existing unrelated untracked `.pnpm-store/` alone.
2. Edit `learnova-academy/scripts/sync-vault.mjs`: add `PUBLIC_SLIDES = join(PROJECT_ROOT, "public", "slides")`, add a `mirrorBlogSlides()` function that scans `VAULT_ROOT/blogs`, requires both `draft.md` and `slides.pptx`, and copies each deck to `public/slides/<blog-slug>.pptx` using the same mtime/size skip behavior as course media. Call it after `mirrorCourseMedia()`.
3. Edit `learnova-academy/src/lib/vault.ts`: import `existsSync` or equivalent, add `slides_url?: string` to `BlogPost`, detect `vault/blogs/<slug>/slides.pptx` inside `readBlogFile`, and set `slides_url: "/slides/<slug>.pptx"` only when the source deck exists.
4. Edit `learnova-academy/src/app/blog/[slug]/page.tsx`: render a small post-footer resource section after `<References post={post} />` when `post.slides_url` exists, linking to `post.slides_url` with `download` text such as `Download slide deck`. Keep this in the academy blog template only.
5. Run the sync script against the authoritative local vault and confirm `learnova-academy/public/slides/2026-04-30-gpt-5-5-in-codex.pptx` exists and is non-empty.
6. Run the smallest build verification that proves static output: `pnpm typecheck` and `pnpm build` from `learnova-academy`.
7. Start the built academy app on port `3001` and verify both surfaces: the blog HTML contains `/slides/2026-04-30-gpt-5-5-in-codex.pptx`, and `curl -I http://localhost:3001/slides/2026-04-30-gpt-5-5-in-codex.pptx` returns non-404.

## Verification (QA Verifier checks these)

- [ ] `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault node scripts/sync-vault.mjs` creates `public/slides/2026-04-30-gpt-5-5-in-codex.pptx` with size > 0.
- [ ] `pnpm typecheck` and `pnpm build` pass in `learnova-academy`.
- [ ] Local server on port `3001`: `curl -sS http://localhost:3001/blog/2026-04-30-gpt-5-5-in-codex | rg '/slides/2026-04-30-gpt-5-5-in-codex\\.pptx'` finds the link.
- [ ] Local server on port `3001`: `curl -sI http://localhost:3001/slides/2026-04-30-gpt-5-5-in-codex.pptx` returns HTTP `200` or `304`, not `404`.

## Risk

- Publishing every vault blog `slides.pptx` that belongs to a rendered blog could expose a deck whose content is not intended for the public page yet. Mitigation: only derive links from the same blog directories the site already considers publishable, and if Executor finds an unapproved deck policy conflict, narrow `mirrorBlogSlides()` to statuses already accepted by `PUBLISHABLE_STATES` rather than copying arbitrary files.

## Out of scope

- Building an embedded Office viewer or full slide-preview UX.
- Regenerating, editing, or reviewing any `.pptx` deck.
- Changing the publish verifier rules or any non-academy Learnova portal.

## Pre-flight

- status_ok=true; assignee_ok=true; acceptance_criteria_ok=true; active_sibling_count=2; basebranch_verified=true; plan_only=true
