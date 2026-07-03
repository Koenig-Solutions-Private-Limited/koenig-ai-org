---
ticket: KOEA-1917
planning_issue: KOEA-9900
planner: planner
date: 2026-07-01
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
preflight:
  vault_pull: true
  status_checked: true
  sibling_count: 0
  basebranch_verified: true
---

# Plan: remove dead Academy course URLs from discovery surfaces

## Goal
Make Academy crawler and LLM discovery surfaces advertise only course URLs that resolve, either directly at the canonical `/courses/*` URL or through an intentional `/learn/*` redirect. Success means `sitemap.xml`, `/llms.txt`, and `/llms-full.txt` have explicit parity checks for current live course routes, while the full LLM corpus remains limited to publishable courses.

## Context
- Files to read first: `learnova-academy/src/lib/courses.ts:140-151`, `learnova-academy/src/lib/courses.ts:584-633`, `learnova-academy/src/app/sitemap.ts:1-64`, `learnova-academy/src/app/llms.txt/route.ts:1-94`, `learnova-academy/src/app/llms-full.txt/route.ts:1-101`, `learnova-academy/scripts/assert-discovery-surfaces.mjs:1-143`, `learnova-academy/next.config.ts:94-140`.
- Relevant prior work: the existing May plan in this file targeted a stale fixture-backed sitemap and a two-course publishable corpus; current `academy/redesign-v1` instead uses `listDiscoverableCourses()` for sitemap/`llms.txt`, `listPublishableCourses()` for `llms-full.txt`, and redirects `/learn/:slug` to `/courses/:slug`.
- Current live evidence on 2026-07-01: production `sitemap.xml` and `/llms.txt` list canonical `/courses/*` URLs; `/llms-full.txt` still emits course entry URLs as `/learn/*`, which currently resolve by intentional redirect for live publishable slugs.
- Constraints: use the FE worktree path requested by the ticket if present, otherwise create it before editing; branch base is `academy/redesign-v1`; do not change course statuses, course page rendering, schema/live markup, or the Career Compass redirect contract.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Normalize the remaining full-corpus course URLs to the canonical `/courses/*` route and extend the discovery assertion script so future regressions fail locally before deployment. This keeps source-of-truth behavior intact: sitemap and `llms.txt` continue to reflect renderable organic course pages, while `llms-full.txt` continues to dump only publishable course bodies.

**Rejected**: Filter sitemap/`llms.txt` down to `listPublishableCourses()` because that would remove renderable organic course pages from discovery without fixing a 404. **Rejected**: Keep code unchanged and close as stale because `llms-full.txt` still diverges from canonical URL shape and the current regression script does not check it. **Rejected**: Modify catalog, homepage, tutor links, JSON-LD, or route redirects because the ticket is crawler/LLM discovery scope only.

## Steps (Executor follows in order)
1. Prepare a clean Learnova FE workspace from `academy/redesign-v1`; if `~/Documents/Paperclip/learnovaBeast-fe-agent/` is still missing, create or request the standard worktree, and avoid the detached `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` checkout with unrelated untracked files.
2. Edit `learnova-academy/src/app/llms-full.txt/route.ts` so course entry lines emit `https://academy.kspl.tech/courses/${c.slug}` instead of `/learn/${c.slug}`; leave blog entries and corpus body dumping unchanged.
3. Edit `learnova-academy/scripts/assert-discovery-surfaces.mjs` to fetch `/llms-full.txt`, parse only course entry URL lines, and assert those slugs are present in the canonical course route form and resolve with HTTP 200 after redirects.
4. In the same script, replace stale partial slug coverage with checks derived from the actual URLs in `/sitemap.xml`, `/llms.txt`, and `/llms-full.txt`: every advertised course URL must resolve, and Career Compass slugs must remain absent from all three surfaces.
5. Keep `learnova-academy/src/lib/courses.ts`, `src/app/sitemap.ts`, `src/app/llms.txt/route.ts`, and `next.config.ts` behavior unchanged unless the new verification exposes a real route-parity bug.
6. Run the narrow checks from `learnova-academy`: `pnpm typecheck`, `pnpm build`, and `node scripts/assert-discovery-surfaces.mjs`.
7. Open a draft PR against `academy/redesign-v1` using the repo PR template, noting that production smoke must re-check sitemap, `/llms.txt`, and `/llms-full.txt` after deploy.

## Verification (QA Verifier checks these)
- [ ] `pnpm typecheck` and `pnpm build` pass in `learnova-academy`.
- [ ] `node scripts/assert-discovery-surfaces.mjs` passes and explicitly checks `/sitemap.xml`, `/llms.txt`, `/llms-full.txt`, `/catalog`, and advertised course URL resolution.
- [ ] Local `/llms-full.txt` course entry URLs use `https://academy.kspl.tech/courses/<slug>` and no longer emit `https://academy.kspl.tech/learn/<slug>` as the entry URL.
- [ ] Production smoke after deploy confirms every course URL advertised by `https://academy.kspl.tech/sitemap.xml`, `/llms.txt`, and `/llms-full.txt` returns 200 or an intentional redirect to a 200 page.

## Risk
- The assertion script may become flaky if it depends on hardcoded course counts while the vault changes. Mitigation: derive slugs from the generated surfaces where possible and keep only the Career Compass absence list as an explicit guardrail.

## Out of scope
- Publishing, drafting, deleting, or changing status for any `vault/courses/*` content.
- Changing course page UI, schema.org JSON-LD, catalog/home/tutor cards, or the `/learn/:slug -> /courses/:slug` redirect rule.
- Modifying Career Compass course redirects or any non-Academy portal.
