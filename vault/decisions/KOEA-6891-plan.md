---
ticket: KOEA-6891
planner: planner
date: 2026-05-31
estimated_complexity: small
estimated_token_cost: $0.30
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: 4d3eaa16-1966-47b2-ac93-a3a422a30b91
---

# Plan: Add glossary DefinedTerm and DefinedTermSet JSON-LD

## Goal
Every Koenig AI Academy glossary term page should server-render valid `DefinedTerm` JSON-LD from the existing vault-backed glossary data, and the glossary index should server-render a `DefinedTermSet` containing the generated terms. Success is observable in built HTML/source for `/glossary/<slug>` and `/glossary`, with generated glossary routes still returning 200.

## Context
- Files to read first: `learnova-academy/src/lib/glossary.ts:12-105`, `learnova-academy/src/app/(site)/glossary/[slug]/page.tsx:18-58`, `learnova-academy/src/app/(site)/glossary/page.tsx:19-35`, `learnova-academy/src/lib/seo.ts:484-486`, `learnova-academy/scripts/sync-vault.mjs:23-32`
- Relevant prior work: `f07fb83e` `[KOEA-6004] Academy technical SEO foundation`; `53dd351a` prior V3 foundation adding glossary/course pages. Current `origin/academy/redesign-v1` already contains `definedTermLd`, `definedTermSetLd`, and glossary page `<script type="application/ld+json">` calls, so Executor should verify/harden the existing implementation rather than duplicate it.
- Constraints: Work in the learnovaBeast FE worktree on `academy/redesign-v1`; never target `main` directly. Do not deploy Convex unless a new finding proves it is necessary, and never operate outside `learnova-tc` for Convex work. Use the vault/build data source; do not manually edit per-term pages.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Verify and harden the existing vault-backed JSON-LD path. Keep the schema generators in `src/lib/glossary.ts`, keep page-level server rendering in the glossary index and term routes, and add only minimal guards/tests if source inspection or build output shows missing `name`, `definition`, `slug`, JSON escaping, or route-generation gaps.
**Rejected**: Add static JSON-LD into each glossary markdown file — violates the no manual per-term edit constraint and would drift as the glossary grows. **Rejected**: Build a new Convex-backed glossary schema source — unnecessary because glossary pages already read vault markdown at build time through `listGlossary()` / `getGlossaryEntry()`, and the ticket does not require a data migration.

## Steps (Executor follows in order)
1. Sync the FE worktree to the latest `origin/academy/redesign-v1` in `learnovaBeast`, preserving unrelated local changes by using a fresh worktree if the current checkout is dirty.
2. Inspect `learnova-academy/src/lib/glossary.ts` and confirm `readGlossaryFile()` excludes entries without `term` or `definition`, derives `slug` from the markdown filename, defaults optional arrays (`related_terms`, `related_courses`, `sameAs`) to `[]`, and returns `definedTermLd()` / `definedTermSetLd()` objects with absolute `https://academy.kspl.tech/glossary...` URLs.
3. Inspect `learnova-academy/src/app/(site)/glossary/[slug]/page.tsx` and ensure each static term page imports `definedTermLd`, uses `getGlossaryEntry(slug)`, calls `notFound()` for missing entries, and emits a server-rendered JSON-LD `<script>` containing the `DefinedTerm` plus existing breadcrumb schema.
4. Inspect `learnova-academy/src/app/(site)/glossary/page.tsx` and ensure the index page uses `listGlossary()` once for both the visible list and `definedTermSetLd(entries)`, so no separate manual term list can drift.
5. If any JSON-LD script uses raw `JSON.stringify` directly, replace it with `jsonLdScript()` from `learnova-academy/src/lib/seo.ts` so `<` is escaped as `\u003c`; otherwise leave the existing serializer unchanged.
6. If verification shows empty or malformed glossary entries reaching JSON-LD, add the smallest normalization in `readGlossaryFile()` to trim `term`, `definition`, and `slug`, filter blank `sameAs` values, and keep invalid entries out of `listGlossary()` / `generateStaticParams()`.
7. Do not touch Convex, admin/student apps, or glossary markdown content unless a failing build proves the Academy build source cannot read the vault.

## Verification (QA Verifier checks these)
- [ ] From `learnova-academy`, run `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm typecheck`.
- [ ] From `learnova-academy`, run `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm build`; do not use bare `npx vite build`.
- [ ] After build, inspect `.next/server/app/glossary.html` and confirm it contains `DefinedTermSet`, `hasDefinedTerm`, and at least one generated glossary slug URL.
- [ ] After build, inspect one generated term artifact such as `.next/server/app/glossary/rag.html` or `.next/server/app/glossary/transformer.html` and confirm it contains `DefinedTerm`, `inDefinedTermSet`, escaped JSON-LD, and the same canonical URL as the route.
- [ ] Run a local production server if needed and check `curl -I http://localhost:3010/glossary` plus one term URL such as `/glossary/rag` return HTTP 200.

## Risk
- JSON-LD validity depends on vault frontmatter quality and safe serialization. Mitigate by relying on `jsonLdScript()`, filtering missing `term` / `definition`, and verifying built HTML for both index and term pages before handoff.

## Out of scope
- Expanding the glossary from the current vault count, editing individual glossary definitions, changing unrelated SEO schema types, deploying Convex, or changing non-Academy apps.
