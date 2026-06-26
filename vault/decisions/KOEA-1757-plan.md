---
ticket: KOEA-1757
plan_issue: KOEA-1768
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.36
approval_override: 21cc38f8-6e3a-4ffd-8b84-fba7e89ff4ee
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Serve vault blog slides and render download links

## Goal
Make vault-resident blog slide decks available as stable static URLs and visible from their corresponding blog pages. Success is observable when any `vault/blogs/<slug>/slides.pptx` is mirrored to `/slides/<slug>.pptx`, the blog page renders a visible download link only when the file exists, and the KOEA-1537 slide verifier passes for `2026-04-30-gpt-5-5-in-codex`.

## Context
- Files to read first: `learnova-academy/scripts/sync-vault.mjs:1-38`, `learnova-academy/scripts/sync-vault.mjs:102-176`, `learnova-academy/src/lib/vault.ts:21-41`, `learnova-academy/src/lib/vault.ts:55-122`, `learnova-academy/src/app/blog/[slug]/page.tsx:67-258`, `learnova-academy/src/lib/courses.ts:91-149`, `learnova-academy/src/app/learn/[slug]/page.tsx:570-686`.
- Relevant prior work: KOEA-1393 removed speculative slide URL probing from the verifier; current verification should only expect links for confirmed vault assets. Commit `8a71437` already mirrors course media from the vault into `public/courses`, which is the closest implementation pattern.
- Current evidence: `vault/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx` exists, but `learnova-academy/public/slides` is absent; live `https://academy.kspl.tech/slides/2026-04-30-gpt-5-5-in-codex.pptx` returns HTTP 404 and the live blog HTML contains no `/slides/` or `.pptx` link.
- Constraints: implementation branch is `academy/redesign-v1`; keep the fix inside `learnovaBeast/learnova-academy`; do not deploy Convex; do not touch other portals; preserve existing course slide behavior.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add an explicit blog-slide asset path through the existing build-time vault pipeline. Extend `sync-vault.mjs` with a `mirrorBlogSlides()` step that copies each `vault/blogs/<slug>/slides.pptx` to `learnova-academy/public/slides/<slug>.pptx`; extend `BlogPost`/`readBlogFile()` to expose `slides_url` only when the vault file exists; and render a compact visible download CTA in `app/blog/[slug]/page.tsx` when `post.slides_url` is present. This fixes both the static 404 and the missing template link using the same confirmed-file semantics as KOEA-1393.

**Rejected**: Generate `/slides/<slug>.pptx` with a Next route handler because binary streaming from the vault would depend on build/runtime filesystem access that static deployment should not require. Hard-code frontmatter `slides_url` values because it would make every blog asset a manual content-maintenance task and reintroduce stale/dead links. Move blog slides into the course `/courses/<slug>/...` convention because blog decks are post-level assets, and changing URL shape would not satisfy the accepted `/slides/<slug>.pptx` contract.

## Steps (Executor follows in order)
1. In `learnova-academy/scripts/sync-vault.mjs`, add `PUBLIC_SLIDES = join(PROJECT_ROOT, "public", "slides")` and a `mirrorBlogSlides()` function that scans `join(VAULT_ROOT, "blogs")`, skips dotfiles/non-directories, and copies only an existing `slides.pptx` to `${PUBLIC_SLIDES}/${slug}.pptx` with the same mtime/size no-op guard used by `mirrorCourseMedia()`.
2. Call `mirrorBlogSlides()` after `mirrorCourseMedia()` and before `exportVaultLastCommitDate()`, and fix the existing course-copy warning at `sync-vault.mjs:167` to reference `src` or `dstName` instead of the undefined `file` identifier if touched in the same block.
3. In `learnova-academy/src/lib/vault.ts`, add a small `fileExists()` helper, add `slides_url?: string` to `BlogPost`, and set it to `/slides/${slug}.pptx` only when `vault/blogs/<slug>/slides.pptx` exists.
4. In `learnova-academy/src/app/blog/[slug]/page.tsx`, render a visible slide download link near the article metadata or learning-objectives block when `post.slides_url` exists, using existing `I.cards`/chip/button styling and `download` so posts without slides remain unchanged.
5. Run `pnpm --dir learnova-academy typecheck` and `pnpm --dir learnova-academy build`; confirm the prebuild output reports mirrored blog slide files and that `learnova-academy/public/slides/2026-04-30-gpt-5-5-in-codex.pptx` exists after build.
6. Start or use a local Academy preview and verify `GET /slides/2026-04-30-gpt-5-5-in-codex.pptx` returns 200 and `/blog/2026-04-30-gpt-5-5-in-codex` contains a visible link to `/slides/2026-04-30-gpt-5-5-in-codex.pptx`.

## Verification (QA Verifier checks these)
- [ ] `pnpm --dir learnova-academy typecheck` passes.
- [ ] `pnpm --dir learnova-academy build` passes and logs blog slide mirroring without requiring Convex.
- [ ] Local preview or deployed preview returns HTTP 200 for `/slides/2026-04-30-gpt-5-5-in-codex.pptx`.
- [ ] `/blog/2026-04-30-gpt-5-5-in-codex` visibly links to `/slides/2026-04-30-gpt-5-5-in-codex.pptx`, while a blog without `slides.pptx` does not render a dead slide link.
- [ ] KOEA-1537 re-verify, or a fresh G5 verifier ticket, passes GREEN for the slides check.

## Risk
- `public/slides` can retain stale files if a vault blog deck is removed after a previous build. Mitigate by making the verifier authoritative for confirmed vault assets and, if stale removals become a real issue, follow up with a separate cleanup step that prunes only files managed by the blog-slide mirror.

## Out of scope
- This plan does not modify other Learnova portals, deploy Convex, change course slide rendering, upload assets to R2, add audio/podcast behavior, or alter verifier rules beyond relying on confirmed vault-resident `slides.pptx` files.
