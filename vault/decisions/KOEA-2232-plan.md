---
ticket: KOEA-2232
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.24
base_branch: academy/redesign-v1
basebranch_verified: true
triggered_by_approval: f4e526ca-b738-442e-bf0d-aa06e6852c73
---

# Plan: Stop the academy sitemap from advertising dead course URLs

## Goal
Success means `https://academy.kspl.tech/sitemap.xml` no longer advertises course URLs that the Academy app cannot serve. The fix should keep sitemap course URL generation aligned with the same vault-backed course source used by `/learn/[slug]`, without touching student, sales, admin, or tc portals.

## Context
- Files to read first: `learnova-academy/src/app/sitemap.ts:1-66`, `learnova-academy/src/app/learn/[slug]/page.tsx:42-86`, `learnova-academy/src/lib/courses.ts:10-71`, `learnova-academy/src/lib/courses.ts:233-265`, `learnova-academy/src/lib/fixtures.ts:104-281`.
- Live failure context checked 2026-05-14: the live sitemap lists 12 `/learn/` URLs; 11 return HTTP 404. The dead URLs are `/learn/gpt-voice-realtime-handbook`, `/learn/gemini-2m-context-deep-dive`, `/learn/mcp-from-first-principles`, `/learn/prompt-engineering-without-tears`, `/learn/building-evals-101`, `/learn/rag-in-2026-still-worth-it`, `/learn/agents-from-prompt-to-production`, `/learn/fine-tuning-when-and-when-not`, `/learn/shipping-safe-llm-features`, `/learn/embeddings-the-quiet-workhorse`, and `/learn/your-first-prompt-in-five-minutes`.
- Source evidence: `sitemap.ts` currently maps course routes from fixture `courses`, while `/learn/[slug]` serves only slugs that `getCourse(slug)` can read from `koenig-ai-org/vault/courses/<slug>/outline.md`. Current local fixture data has 12 course slugs, 10 of which have no vault outline; the deployed sitemap also has one stale older MCP slug, which confirms generated sitemap artifacts can lag source changes until redeployed.
- Relevant prior work: KOEA-2232 dispatch comment notes the shared `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` worktree is locked by KOEA-1776 and implementation must use a clean/dedicated academy worktree lock.
- Constraints: route implementation to `learnovaBeast` branch `academy/redesign-v1`; verify the branch exists before work starts; create/use a dedicated clean academy worktree with `.claude/agent-lock`; do not deploy Convex from any portal except `learnova-tc`; do not edit other portals.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Replace sitemap course URL generation with the vault-backed course reader already used by Academy course pages. In `learnova-academy/src/app/sitemap.ts`, import `listAllCourses` from `@/lib/courses` and build `courseRoutes` from `listAllCourses().map((c) => /learn/${c.slug})`. This keeps sitemap URLs and `generateStaticParams()` on the same source of truth, so every advertised course URL has an outline-backed route and `getCourse(slug)` can render it.

**Rejected**: Keep fixture slugs and add redirects for the 11 dead URLs - this preserves fake/stale fixture inventory and creates SEO debt. **Rejected**: use `listPublishableCourses()` only - this removes dead URLs but changes sitemap policy by hiding routable in-production course pages already listed from `/learn`; use a separate SEO policy ticket if the business wants only G0+ courses indexed.

## Steps (Executor follows in order)
1. Create or reuse a clean dedicated worktree for `learnovaBeast` on `academy/redesign-v1`, add a `.claude/agent-lock` for KOEA-2235, and avoid the shared locked tree unless Chief Engineering confirms KOEA-1776 released it.
2. In `learnova-academy/src/app/sitemap.ts`, remove the `courses` fixture import and import `listAllCourses` from `@/lib/courses`.
3. Change `courseRoutes` to map `listAllCourses()` instead of fixture `courses`; keep the existing `/learn/${c.slug}` URL shape, `lastModified`, `changeFrequency`, and priority.
4. Run a local sitemap assertion after the edit: compute sitemap course URLs and confirm none of the 11 live-dead slugs appear unless a matching vault outline now exists.
5. Run `cd learnova-academy && pnpm typecheck` and `cd learnova-academy && pnpm build`; use `node node_modules/next/dist/bin/next build` only if the package script hangs in this runtime.
6. Open a draft PR against `academy/redesign-v1` with the PR template, noting that the fix is Academy-only and does not touch Convex or other portals.

## Verification (QA Verifier checks these)
- [ ] Local/generated sitemap course URLs come from `listAllCourses()` and do not include the 11 known live-dead URLs listed above, unless a corresponding `vault/courses/<slug>/outline.md` was added before verification.
- [ ] After the preview or deployed build, each of the 11 previously-dead URLs is either absent from `/sitemap.xml` or returns HTTP 200/valid redirect; no listed `/learn/` sitemap URL returns 404.
- [ ] `cd learnova-academy && pnpm typecheck` passes.
- [ ] `cd learnova-academy && pnpm build` passes and regenerates `/sitemap.xml` from the fixed source.

## Risk
- SEO/canonical risk: switching the sitemap to vault-backed slugs may add routable draft or blocked course pages that are intentionally visible under `/learn` but not fully approved. Mitigation: this plan preserves current route visibility and only removes dead URLs; if indexing policy should be G0+ only, file a separate CEO-scoped SEO policy ticket before changing sitemap semantics.
- Stale artifact risk: Vercel currently serves a sitemap generated at `2026-05-14T07:12:37.180Z`, so source changes will not affect live SEO until the Academy branch is rebuilt and deployed. Mitigation: QA must verify the preview/deployed sitemap, not just source code.

## Out of scope
- Editing course content, adding redirects for fake fixture courses, changing `/learn` catalog behavior, changing canonical metadata, touching other Learnova portals, or deploying Convex.
