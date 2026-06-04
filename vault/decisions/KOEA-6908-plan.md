---
ticket: KOEA-6908
planner: planner
date: 2026-05-31
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
plan_issue: KOEA-6910
---

# Plan: Restore `/courses/<slug>` course landing pages

## Goal
Academy course landing pages must resolve at `/courses/<slug>` for every `vault/courses/<slug>/outline.md` course instead of returning 404. Success means at least five real `/courses/*` URLs return HTTP 200 with course content, sitemap course entries use the same `/courses/*` structure, and existing `/learn/*` links do not become hard 404s during the migration.

## Context
- Files to read first: `src/app/learn/[slug]/page.tsx:45-89`, `src/app/learn/[slug]/page.tsx:107-143`, `src/lib/courses.ts:268-353`, `src/app/sitemap.ts:21-26`, `src/lib/seo.ts:64-110`, `src/lib/seo.ts:299-313`, `src/app/llms.txt/route.ts:46-51`
- Relevant prior work: current production check on 2026-05-31 shows `/courses/ai-agent-security-for-developers`, `/courses/claude-opus-47-from-zero`, `/courses/claude-mcp-mastery`, `/courses/production-agents-claude-agent-sdk-mcp-connector`, and `/courses/cursor-composer-2` all return 404; the same slugs under `/learn/*` return 200. Production sitemap currently lists `/learn/<slug>` course URLs.
- Constraints: work only in the learnovaBeast Academy frontend worktree; target `academy/redesign-v1` or a task branch based on it; do not merge `main`; do not deploy Convex from any portal except `learnova-tc`; keep one ticket per worktree and create/use `.claude/agent-lock` if running locally with shared checkout discipline.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add `/courses/[slug]` as the public course route and align course canonical/discovery URLs to `/courses`. Reuse the existing `/learn/[slug]` page implementation instead of duplicating the 1,300-line renderer, then update the hardcoded course self URLs in the page, schema helpers, sitemap, and LLM discovery surface so crawlers see `/courses/*` as the canonical course structure while `/learn/*` remains backward-compatible.

**Rejected**: Redirect `/courses/:slug` to `/learn/:slug` only — this does not satisfy the P0 symptom because the canonical course URL remains `/learn/*` and `/courses/*` does not itself serve content. **Rejected**: Duplicate `src/app/learn/[slug]/page.tsx` into `src/app/courses/[slug]/page.tsx` — faster initially, but it creates two large renderers that will drift. **Rejected**: Rename `/learn/[slug]` to `/courses/[slug]` and remove `/learn` — too risky for existing internal links and any indexed `/learn/*` URLs.

## Steps (Executor follows in order)
1. Create a task branch from verified `origin/academy/redesign-v1` in the learnovaBeast frontend worktree; do not use `main`, and keep the worktree locked to KOEA-6912 while implementing.
2. Add `src/app/courses/[slug]/page.tsx` as a thin route module that re-exports `dynamic`, `generateStaticParams`, `generateMetadata`, and the default page from `src/app/learn/[slug]/page.tsx`.
3. Update `src/app/learn/[slug]/page.tsx` so course canonical URLs, Open Graph URLs, breadcrumb URLs, and course-to-course wikilinks point to `/courses/${slug}`; keep non-course navigation such as catalog browsing pointed at `/catalog`.
4. Update `src/lib/seo.ts` so `courseLd` and `learningResourceLd` emit `/courses/${slug}` URLs and course prerequisites use `/courses/${slug}`.
5. Update `src/app/sitemap.ts` so `listDiscoverableCourses()` produces `https://academy.kspl.tech/courses/${slug}` entries.
6. Update `src/app/llms.txt/route.ts` course links to `https://academy.kspl.tech/courses/${slug}` so the lightweight LLM discovery file matches sitemap and canonical course URLs.
7. Run the targeted verification below, then open/update the draft PR with command output, five checked slugs, and any remaining `/learn/*` compatibility notes.

## Verification (QA Verifier checks these)
- [ ] `npm run typecheck` passes in the learnovaBeast Academy frontend worktree.
- [ ] `KOENIG_VAULT_ROOT=/tmp/master-sync/vault npm run build` passes and includes generated static pages for `/courses/[slug]`.
- [ ] With the built app running, these URLs return HTTP 200 and visible course title/chapter content: `/courses/ai-agent-security-for-developers`, `/courses/claude-opus-47-from-zero`, `/courses/claude-mcp-mastery`, `/courses/production-agents-claude-agent-sdk-mcp-connector`, `/courses/cursor-composer-2`.
- [ ] `/sitemap.xml` contains `/courses/<slug>` course entries and does not contain `/learn/<slug>` course entries.
- [ ] `/llms.txt` course entries use `/courses/<slug>`.
- [ ] A representative legacy URL such as `/learn/claude-mcp-mastery` still does not hard 404; it may render with canonical `/courses/claude-mcp-mastery` or redirect if Executor chooses an equivalent backward-compatible implementation.

## Risk
- Static media already lives under `public/courses/<slug>/...`; adding `src/app/courses/[slug]` could accidentally interfere with asset paths if implemented as a catch-all route. Mitigation: use exactly `src/app/courses/[slug]/page.tsx`, not `[[...slug]]` or `[...slug]`, and verify an existing asset URL such as `/courses/claude-tool-use-from-zero/ch01-slides.pptx` still returns 200.

## Out of scope
- Full migration of every internal navigation link from `/learn/*` to `/courses/*`; this plan only changes canonical/discovery surfaces needed to stop `/courses/<slug>` 404s and restore crawlable course URLs. Broader link cleanup can be a separate SEO polish ticket after the P0 route is fixed.
