---
ticket: KOEA-1030
planner: planner
date: 2026-05-11
estimated_complexity: small
estimated_token_cost: $0.40
files_touched:
  - learnovaBeast/learnova-academy/src/app/sitemap.ts
  - learnovaBeast/learnova-academy/src/app/llms.txt/route.ts
  - learnovaBeast/learnova-academy/src/app/llms-full.txt/route.ts
---

# Plan: Academy sitemap course 404s — make SEO surfaces vault-truth

## Goal
Stop emitting course URLs the site cannot serve. The sitemap, `llms.txt`, and `llms-full.txt` must list only courses that actually render at `/learn/<slug>`. After the fix, every course URL in `sitemap.xml` returns HTTP 200, restoring crawler trust and ending the W19 SEO finding (`11 of 12 sitemap course URLs return 404`).

## Context

### Symptom (W19 audit, `vault/marketing/seo/W19-2026.md`)
- Live `sitemap.xml` lists 12 course URLs.
- 11 return 404. Only `/learn/mcp-from-first-principles-to-production` returns 200.
- `llms.txt` advertises 1 live course but still imports the same 12-item fixture list, so its links collapse to phantoms.

### Root cause (single source-of-truth mismatch)
The site has two course catalogs that disagree:

1. **Static fixture catalog** — `learnovaBeast/learnova-academy/src/lib/fixtures.ts` lines 95–279. A hand-maintained 12-entry array authored from the v3 design fixtures. Drives the UI brochure cards on `/`, `/catalog`, and `/tutor`.
2. **Vault-backed catalog** — `learnovaBeast/learnova-academy/src/lib/courses.ts`. Reads `vault/courses/<slug>/outline.md` at build time. Drives `/learn/[slug]/page.tsx` via `generateStaticParams()` and `getCourse(slug)`.

Three SEO surfaces incorrectly read from catalog #1:

| File | Line | Imports |
| --- | --- | --- |
| `src/app/sitemap.ts` | 2 | `import { courses } from "@/lib/fixtures"` |
| `src/app/llms.txt/route.ts` | 5 | `import { courses } from "@/lib/fixtures"` |
| `src/app/llms-full.txt/route.ts` | 4 | `import { courses, lesson, vendors } from "@/lib/fixtures"` |

But the only courses the `/learn/[slug]` route can actually render are those backed by `vault/courses/<slug>/outline.md`. As of 2026-05-11 the vault holds 6 course directories — one has no `outline.md` so it isn't even listed — and only one has reached `g0-passed`:

| Vault slug | `outline.md` status |
| --- | --- |
| `claude-opus-47-from-zero` | `outline-draft-for-review` |
| `claude-tool-use-from-zero` | (no `outline.md` — chapter file only, not listed by `listCourseSlugs()`) |
| `gemini-enterprise-agents` | `outline-revised-for-g0` |
| `mcp-from-first-principles-to-production` | `g0-passed` (publishable) |
| `picking-a-frontier-model-2026-q2` | `outline-draft-for-review` |
| `production-agents-claude-agent-sdk-mcp-connector` | `outline-draft-for-review` |

Note the fixture slug `mcp-from-first-principles` (no `-to-production`) is itself stale — it doesn't match the vault slug, which is why even the "matching" course only renders under the longer URL.

`PUBLISHABLE_COURSE_STATES` in `src/lib/courses.ts:67-71` already encodes the publishing gate: `g0-passed`, `g3-passed`, `published`. `listPublishableCourses()` (line 259) is the existing helper that returns exactly the set we want to expose to crawlers.

### Why "publish the 11 missing courses" is not the answer
The 11 missing courses are not written. They are still in `outline-draft-for-review` or do not exist as vault folders at all (`gpt-voice-realtime-handbook`, `prompt-engineering-without-tears`, `building-evals-101`, `rag-in-2026-still-worth-it`, `agents-from-prompt-to-production`, `fine-tuning-when-and-when-not`, `shipping-safe-llm-features`, `embeddings-the-quiet-workhorse`, `your-first-prompt-in-five-minutes`, `gemini-2m-context-deep-dive`). Authoring 11 courses is a content-pipeline job worth tens of agent-days and gated by Content Author + Reviewer + G3/G4 approvals. The SEO bug is about advertising what isn't there — fix that today; let content roll in normally and add URLs as each course passes `g0-passed`.

### Out-of-scope sister bug to flag (NOT fixed here)
`src/app/page.tsx`, `src/app/catalog/*`, and `src/components/_shared/{chrome,tutor,content}.tsx` still iterate the fixture catalog for brochure cards, so a user clicking `/catalog` → "Prompt engineering without tears" lands on a 404. That is a separate UI/UX ticket (cards should either be hidden, badged "Coming soon" with a non-link, or also driven by `listPublishableCourses()`). Note in plan, do not touch in this PR.

## Approach (chosen)
**Vault-truth for SEO surfaces.** Change the three SEO files to import `listPublishableCourses()` from `@/lib/courses` and emit one URL per publishable vault course. The UI brochure pages keep using the fixture catalog (unchanged). One conceptual edit per file; ~30 LOC total.

This is correct because:
- The `/learn/[slug]` route already resolves from the vault, so vault-backed surfaces will match what the server actually serves — no more sitemap/route divergence by construction.
- `listPublishableCourses()` already exists and filters to `g0-passed` ∪ `g3-passed` ∪ `published`, which is exactly the SEO-visible set.
- It scales: new courses appear in `sitemap.xml` and `llms*.txt` automatically the day their outline flips to `g0-passed`. No second-edit risk.
- It is reversible by one-file revert (see Rollback).

## Approaches rejected
- **Publish the 11 missing courses.** Out-of-scope (multi-week content pipeline) and orthogonal — the SEO surfaces would still need to be vault-driven afterward.
- **Hand-curate the sitemap to the single known-good slug.** Solves W19 but rots immediately when the next course passes `g0-passed`; reintroduces the exact divergence we're paying off now.
- **Update `fixtures.ts` to match the vault.** Doesn't address the architectural mismatch — `fixtures.ts` exists for UI demo cards, including aspirational `learners: 38420` numbers and design metadata (`cover: "teal"`). It is not meant to be authoritative content state; conflating it with vault state would reintroduce drift the next time the UI and vault diverge.

## Steps

1. `src/app/sitemap.ts` — replace `import { courses } from "@/lib/fixtures"` with `import { listPublishableCourses } from "@/lib/courses"`. In the `courseRoutes` builder (currently lines 23–28) iterate `listPublishableCourses()` instead of `courses`; use the publishable course's own `slug` field.

2. `src/app/llms.txt/route.ts` — replace `import { courses } from "@/lib/fixtures"` with `import { listPublishableCourses } from "@/lib/courses"`. In the courses loop (lines 39–43), iterate `listPublishableCourses()`; each line should read `- [<title>](https://academy.kspl.tech/learn/<slug>): <one-line tagline> (<level>, <total_duration_min> min, <vendor_tag>)`. Pull title/level/vendor/duration from the vault course; derive a tagline from `learning_outcomes[0]` (falling back to `target_audience`, then a short generic line) since vault courses do not currently carry a marketing `tagline` field.

3. `src/app/llms-full.txt/route.ts` — replace the fixtures import with `listPublishableCourses()` plus the existing `vendors` import (still used for vendor display name; OK to keep importing `vendors` from `fixtures` since it is shared chrome metadata, or inline the names — pick one in PR review). Rewrite the courses loop (lines 29–100) to iterate publishable vault courses, emitting `title`, URL, vendor, level, duration, chapter count from the vault data. Delete the hard-coded `claude-tool-use-from-zero` special case (lines 47–66) — that course no longer has an outline and the chapter list is stale fixture data.

4. Local rebuild + sitemap snapshot. Run `pnpm --filter learnova-academy build` (or `pnpm dev` in the academy package on port 3010, then visit `/sitemap.xml`, `/llms.txt`, `/llms-full.txt`). Confirm course URL count equals the count of `g0-passed`+`g3-passed`+`published` outlines (today: 1).

5. Twelve-URL status probe (executable: see Verification). Confirm every emitted course URL returns 200 against the local dev server and that the 11 previously-listed phantom slugs are no longer in the sitemap.

6. Open PR titled `KOEA-1030: vault-truth for sitemap / llms.txt / llms-full.txt`. Body links to W19 audit and lists the publishable-course count before/after. Self-review: confirm no UI files were touched.

## Verification (Code Reviewer + QA checks)

Run these from `learnovaBeast/learnova-academy` against a local build at `http://localhost:3010` (or substitute the preview URL):

```bash
# 1. Build succeeds and emits a sitemap.
pnpm --filter learnova-academy build
pnpm --filter learnova-academy start &  # serves the built output
SLEEP=4 && sleep $SLEEP

# 2. Sitemap lists exactly the publishable vault courses.
curl -s http://localhost:3010/sitemap.xml \
  | grep -oE 'https://academy\.kspl\.tech/learn/[a-z0-9-]+' \
  | sort -u > /tmp/sitemap_courses.txt
wc -l /tmp/sitemap_courses.txt   # expect: 1 today; grows as outlines reach g0-passed

# 3. The 12-course status probe (the same set W19 audited).
for slug in \
  claude-tool-use-from-zero \
  gpt-voice-realtime-handbook \
  gemini-2m-context-deep-dive \
  mcp-from-first-principles-to-production \
  prompt-engineering-without-tears \
  building-evals-101 \
  rag-in-2026-still-worth-it \
  agents-from-prompt-to-production \
  fine-tuning-when-and-when-not \
  shipping-safe-llm-features \
  embeddings-the-quiet-workhorse \
  your-first-prompt-in-five-minutes; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3010/learn/$slug")
  in_sitemap=$(grep -c "/learn/$slug\b" /tmp/sitemap_courses.txt || true)
  printf "%-50s HTTP %s | in_sitemap=%s\n" "$slug" "$code" "$in_sitemap"
done
# Expect: mcp-from-first-principles-to-production → HTTP 200 | in_sitemap=1
# Expect: every other slug → HTTP 404 | in_sitemap=0  (NOT 200 / in_sitemap=1)

# 4. llms.txt + llms-full.txt agree with the sitemap.
curl -s http://localhost:3010/llms.txt | grep -oE '/learn/[a-z0-9-]+' | sort -u
curl -s http://localhost:3010/llms-full.txt | grep -oE '/learn/[a-z0-9-]+' | sort -u
# Expect both lists to equal /tmp/sitemap_courses.txt content.

# 5. Production smoke (after deploy).
curl -sI https://academy.kspl.tech/learn/mcp-from-first-principles-to-production | head -1
# Expect: HTTP/2 200
```

Verification checklist:
- [ ] `sitemap.xml` course URL count = count of vault outlines with status ∈ {`g0-passed`,`g3-passed`,`published`}.
- [ ] Every course URL in `sitemap.xml` returns 200 on the running build.
- [ ] None of the 11 W19 phantom slugs appear in `sitemap.xml`, `llms.txt`, or `llms-full.txt`.
- [ ] `llms.txt` and `llms-full.txt` URL lists equal the sitemap URL list (set equality).
- [ ] `pnpm --filter learnova-academy build` exits 0; no type errors from the import swap.
- [ ] UI snapshots: `/catalog`, `/`, `/tutor` still show their full brochure cards (fixture catalog untouched).

## Worktree choice
Use a fresh worktree on a new branch, **not** the current `koea-862/bwrap-docker-fix` branch which is dedicated to the Docker fix. Recommended branch name: `koea-1030/sitemap-vault-source-of-truth`. Repo: `learnovaBeast`. Executor should branch from `master` (academy production branch) and open the PR against `master`.

`koenig-ai-org` is not touched — this plan document is the only change here.

## Rollback risk
**Very low.** Three single-file imports + small loop rewrites. No data, schema, or config migration. No build-pipeline change. Crawler harm is asymmetric in our favor:
- Pre-fix state: 11 phantom URLs in `sitemap.xml`. Worst case for SEO.
- Post-fix state: 1 URL (today). Worst case for SEO: temporarily smaller crawl frontier, which is strictly better than advertising 404s.
- Rollback: `git revert` of the PR puts the 11 phantoms back. No state loss.

Edge cases to keep an eye on during review:
- If `KOENIG_VAULT_ROOT` is unset in the Vercel build environment, `lib/courses.ts` falls back to a hard-coded Mac path (`src/lib/courses.ts:11`). The build will silently emit zero course URLs in CI/Vercel. **Pre-merge check**: confirm `KOENIG_VAULT_ROOT` is set in the academy Vercel project, or that the build step copies `vault/courses` into the build context. If neither, file a follow-up before merging (do not bake a default sitemap as a workaround).
- `force-static` on `/learn/[slug]/page.tsx` means courses promoted to `g0-passed` only appear after the next deploy — same behavior as today, called out so QA does not expect hot updates.

## Out of scope
- Authoring the 11 missing courses. Separate content tickets per slug.
- Fixing fixture-driven brochure cards on `/`, `/catalog`, `/tutor` that link to phantom `/learn/<slug>` URLs — file a follow-up ticket `KOEA-1030-followup: brochure cards link to 404 courses`.
- `/favicon.ico` 404 (W19 issue) — owned by [[KOEA-707]] / [[KOEA-717]].
- Short-slug redirects for blog posts (W19 issue) — owned by [[KOEA-426]].
- GSC OAuth (W19 unblock) — owned by [[KOEA-708]] / [[KOEA-1022]].
- Homepage / course-page LCP work (W19 WARN) — owned by [[KOEA-707]].
- Any change to `PUBLISHABLE_COURSE_STATES` in `src/lib/courses.ts:67-71`.
- Any change to `fixtures.ts` — UI brochure cards keep using it for now.
