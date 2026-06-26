---
ticket: KOEA-1716
planner_ticket: KOEA-1726
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.34
base_branch: academy/redesign-v1
basebranch_verified: true
chain_depth_override_comment: c0782651-9c37-4fba-be66-b3deeb91dc4e
chain_depth_alert_approval_id: 7a6a18a6-d9bb-40c6-b984-5ce4227288aa
---

# Plan: Restore GPT-5.5 Codex blog slide deck on live academy

## Goal
Restore the static slide deck contract for the published blog `2026-04-30-gpt-5-5-in-codex`. Success is observable when `https://academy.kspl.tech/slides/2026-04-30-gpt-5-5-in-codex.pptx` returns 200 after deploy and the live blog page contains a download link to `/slides/2026-04-30-gpt-5-5-in-codex.pptx`.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/scripts/sync-vault.mjs:34-38`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/scripts/sync-vault.mjs:102-175`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/vault.ts:21-40`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/vault.ts:55-122`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:11-15`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:147-258`.
- Root cause: `sync-vault.mjs` mirrors media only from `vault/courses/*` into `public/courses/`; it never copies `vault/blogs/<slug>/slides.pptx` into any public directory. `src/lib/vault.ts` also returns blog markdown/frontmatter only, with no derived slide URL, and `src/app/blog/[slug]/page.tsx` has no conditional link surface. The vault source exists locally at `vault/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx` and 13 blog slide decks exist in total.
- Relevant prior work: `vault/decisions/KOEA-1514-plan.md` treated an earlier slides probe as a verifier false positive; later `vault/decisions/KOEA-1563-plan.md` records Chief Engineering's feature-ship mandate for `/slides/<slug>.pptx`. KOEA-1514 and KOEA-1563 are relevant context but are not blockers for KOEA-1716 because Chief Engineering comment `c0782651-9c37-4fba-be66-b3deeb91dc4e` explicitly instructs this Planner to proceed and keep the implementation scoped to `learnovaBeast/learnova-academy`.
- Constraints: work only in `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` on `academy/redesign-v1`; do not touch Convex, `learnova-tc`, `learnova-admin`, `learnova-sales`, `learnova-student`, verifier skills, or vault content; do not commit generated PPTX binaries unless Chief Engineering explicitly asks.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a build-time blog slide mirror plus a derived blog slide URL and a static download link. This follows the existing course-media pattern: `prebuild` and `predev` already run `scripts/sync-vault.mjs`, so copying `vault/blogs/<slug>/slides.pptx` to `public/slides/<slug>.pptx` makes the asset available without any runtime vault dependency. `src/lib/vault.ts` should expose `slides_url?: string` when the vault file exists, and the blog page should render a small download link when `post.slides_url` is present.

**Rejected**: Dynamic Next route handler reading from the vault at request time, because blog pages are force-static and the site should not depend on the private vault filesystem at runtime. Frontmatter `slides_url`, because it adds authoring burden and still would not serve the bytes. Cross-portal or Convex changes, because the failure is fully explained by static asset sync and blog rendering in the academy site.

## Steps (Executor follows in order)
1. Create a dedicated branch/worktree from `origin/academy/redesign-v1` for `learnovaBeast/learnova-academy`; preserve the existing untracked `../.pnpm-store/` and do not include it in commits.
2. Extend `scripts/sync-vault.mjs` with `PUBLIC_SLIDES = join(PROJECT_ROOT, "public", "slides")` and a `mirrorBlogSlides()` function modelled on `mirrorCourseMedia()`: iterate `join(VAULT_ROOT, "blogs")`, skip dotfiles and non-directories, copy exact `slides.pptx` files to `public/slides/<slug>.pptx`, and keep the existing mtime+size idempotency behavior.
3. Call `mirrorBlogSlides()` after `mirrorCourseMedia()` and before `exportVaultLastCommitDate()`; log `[sync-vault] mirrored N blog slide deck(s) to public/slides/`.
4. Update `src/lib/vault.ts` so `BlogPost` has optional `slides_url?: string`; in `readBlogFile(slug)`, `statSync(join(VAULT_ROOT, "blogs", slug, "slides.pptx"))` in a try/catch and return `/slides/${slug}.pptx` only when the source file exists.
5. Update `src/app/blog/[slug]/page.tsx` to render a visible download link when `post.slides_url` exists, ideally after `<References post={post} />` and before `</article>`, using the existing `I.cards` icon and `href={post.slides_url}` with `download`. Do not embed Office Online or iframe slides on blog pages.
6. Verify locally from `learnova-academy`: run `rm -rf public/slides && node ./scripts/sync-vault.mjs`, confirm `public/slides/2026-04-30-gpt-5-5-in-codex.pptx` exists and has the same byte count as the vault source, then run `pnpm exec tsc --noEmit` and `pnpm build`.
7. Open the PR against `academy/redesign-v1` with verification output, then after Vercel deploy verify the live asset and page link with `curl -sI https://academy.kspl.tech/slides/2026-04-30-gpt-5-5-in-codex.pptx | head -1` and `curl -s https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex | grep -F '/slides/2026-04-30-gpt-5-5-in-codex.pptx'`.

## Verification (QA Verifier checks these)
- [ ] `node ./scripts/sync-vault.mjs` creates `public/slides/2026-04-30-gpt-5-5-in-codex.pptx`; `wc -c` matches the vault source byte count (`37240` at plan time).
- [ ] `pnpm exec tsc --noEmit` and `pnpm build` pass from `learnova-academy`.
- [ ] Built/local HTML for `/blog/2026-04-30-gpt-5-5-in-codex` contains `/slides/2026-04-30-gpt-5-5-in-codex.pptx`.
- [ ] After deploy, `https://academy.kspl.tech/slides/2026-04-30-gpt-5-5-in-codex.pptx` returns HTTP 200 and the live blog page links that exact URL path.

## Risk
- Mirroring all blog slide decks increases build output size because 13 `slides.pptx` files currently exist. Mitigate by copying only exact `slides.pptx` files, not every media extension under `vault/blogs`, and by leaving generated files out of git so rollback is a code revert of the mirror and link logic.

## Out of scope
- No Convex deploy, no other portal changes, no verifier-skill changes, no sitemap changes unless Chief Engineering separately requests discovery of binary slide URLs, no new slide generation, and no content/frontmatter edits.

Telemetry: basebranch_verified=true; planner_chain_override=chief-engineering-comment-c0782651-9c37-4fba-be66-b3deeb91dc4e
