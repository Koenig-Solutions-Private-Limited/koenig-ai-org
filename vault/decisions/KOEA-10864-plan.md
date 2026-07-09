---
ticket: KOEA-10864
planner: planner
date: 2026-07-09
estimated_complexity: small
estimated_token_cost: $0.24
base_repo: Koenig-Solutions-Private-Limited/learnovaBeast
base_branch: academy/redesign-v1
basebranch_verified: true
triggered_by_approval: 7f51480f-0eef-4f9c-bec4-b17af803bfea
---

# Plan: Create Koenig AI Academy author page

## Goal
Create a real `/authors/koenig-ai-academy` profile page so the 110 publishable blog drafts that use `author: koenig-ai-academy` resolve to a non-stub author URL. Success means the author appears on `/authors`, in `/sitemap.xml`, in author-page Organization JSON-LD, and as the `BlogPosting.author` reference for those posts.

## Context
- Files to read first: `learnova-academy/src/lib/authors.ts:26-130`, `learnova-academy/src/app/(site)/authors/[slug]/page.tsx:18-132`, `learnova-academy/src/app/(site)/authors/page.tsx:26-101`, `learnova-academy/src/app/sitemap.ts:37-42`, `learnova-academy/src/lib/seo.ts:178-196`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:101-210`.
- Relevant prior work: KOEA-7017 standardized blog frontmatter onto real author slugs; current vault scan found 110 `draft.md` files with `author: koenig-ai-academy` and 11 with `author: vardaan-koenig`.
- Constraints: implement in `~/Documents/Paperclip/learnovaBeast-fe-agent/learnova-academy` and run preview on port 3001; base branch `academy/redesign-v1` exists; do not run Convex deploy except from learnova-tc; local planner read used `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` because the named `learnovaBeast-fe-agent` worktree was not present.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add `koenig-ai-academy` as an `Organization` in the existing author registry and make blog bylines link to the resolved author profile. The dynamic author route, author index, sitemap, and `BlogPosting` JSON-LD already consume `listAuthors()`, `getAuthor()`, and `authorRef()`, so a registry entry creates `/authors/koenig-ai-academy` without a bespoke route while keeping structured data and internal discovery in one place.

**Rejected**: Add a hardcoded `src/app/(site)/authors/koenig-ai-academy/page.tsx` page - it duplicates the existing dynamic author route and would still require separate sitemap/index/schema wiring. **Rejected**: Rewrite the 110 blog frontmatter entries to `editorial-team` - that reverses KOEA-7017's slug standardization and weakens the requested author URL. **Rejected**: Model the academy as `Person` - the slug and required name represent an editorial organization, and Organization JSON-LD is the cleaner match.

## Steps (Executor follows in order)
1. Start a clean branch from `origin/academy/redesign-v1` in `~/Documents/Paperclip/learnovaBeast-fe-agent/learnova-academy`; leave unrelated local edits in other worktrees alone.
2. Add a `"koenig-ai-academy"` `Organization` record to `src/lib/authors.ts` with display name `Koenig AI Academy`, a concise AI-powered editorial-team bio, `worksFor: "Koenig Solutions Pvt Ltd"`, relevant `knowsAbout`, Koenig/company `sameAs` links, and a `headshotPath`.
3. Ensure `ROLE_LABELS` and `formatRoleLabel()` still render `Koenig AI Academy` for the slug and that missing/unknown slugs continue to fall back to `editorial-team`.
4. Update `src/app/(site)/blog/[slug]/page.tsx` so the visible author portion of the byline links to `/authors/${author.slug}` while preserving reviewer and date text; keep the existing safe role-label behavior rather than exposing personal/internal reviewer IDs.
5. Add or update a narrow verification script/test, if the repo has an existing lightweight pattern available, to assert `getAuthor("koenig-ai-academy")` returns the new Organization, `listAuthors()` includes the slug, and `blogPostingLd({ author: "koenig-ai-academy", ... }).author.url` points at `/authors/koenig-ai-academy`.
6. Run targeted verification from `learnova-academy`: `pnpm typecheck`, the new/updated targeted check if added, and a production build with `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm build`.
7. Start the local preview on port 3001 and inspect `/authors`, `/authors/koenig-ai-academy`, one blog authored by `koenig-ai-academy`, and `/sitemap.xml`; do not run `convex deploy`.

## Verification (QA Verifier checks these)
- [ ] `/authors/koenig-ai-academy` returns 200, shows `Koenig AI Academy`, includes a brief AI-powered editorial-team bio, and lists posts authored by the slug.
- [ ] The page emits Organization JSON-LD with `name: "Koenig AI Academy"` and `url: "https://academy.kspl.tech/authors/koenig-ai-academy"`.
- [ ] A blog with `author: koenig-ai-academy` emits `BlogPosting.author` as an Organization named `Koenig AI Academy` with the same author URL.
- [ ] `/authors` and `/sitemap.xml` include `/authors/koenig-ai-academy`.
- [ ] The visible blog byline links the author label to `/authors/koenig-ai-academy` without exposing unsafe reviewer identifiers.
- [ ] `pnpm typecheck` and `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm build` pass in `learnova-academy`.

## Risk
- Changing byline rendering can accidentally expose internal reviewer slugs or alter existing visual spacing. Mitigation: keep `formatRoleLabel()` for visible labels, only link the resolved author label, and verify one `koenig-ai-academy` blog plus one `vardaan-koenig` blog in the preview.

## Out of scope
- Rewriting existing blog frontmatter, creating new individual human author profiles, changing Convex data, or deploying from this worktree.
