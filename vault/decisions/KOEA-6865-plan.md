---
ticket: KOEA-6865
planner: planner
date: 2026-06-03
estimated_complexity: medium
estimated_token_cost: "$0.42"
base_branch: academy/redesign-v1
basebranch_verified: true
approved_chain_alert: d5f23da0-d1c2-4894-8e46-de017448ba11
---

# Plan: Add HowTo JSON-LD to the Cloudflare course landing page

## Goal
Academy course landing pages should expose course-level `howto_steps` from vault frontmatter as schema.org `HowTo` JSON-LD when the field is present. Success means the Cloudflare course renders a `HowTo` object with seven `HowToStep` entries, while the page `<title>`, rendered `<h1>`, and `/llms.txt` entry all use the 2026 course title from `outline.md`.

## Context
- Files to read first: `learnova-academy/src/lib/courses.ts:95-112`, `learnova-academy/src/lib/courses.ts:314-358`, `learnova-academy/src/lib/seo.ts:371-410`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:58-83`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:123-205`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:247-258`, `learnova-academy/src/app/(site)/courses/[slug]/page.tsx:1-7`, `learnova-academy/src/app/llms.txt/route.ts:20-55`, `vault/courses/cloudflare-agents-platform-workers-to-production/outline.md:1-49`.
- Relevant prior work: blog HowTo parsing already exists in `learnova-academy/src/lib/vault.ts:49-55` and `learnova-academy/src/lib/vault.ts:220-245`; blog pages already emit `howToLd()` in `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:112-128`.
- Constraints: use a feature branch off verified `origin/academy/redesign-v1` in `learnovaBeast`; do not deploy Convex; do not merge to main; preserve unrelated local work in the shared Academy checkout before resetting or use a fresh worktree.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Extend the existing course data contract in `src/lib/courses.ts`, then wire that typed field into the existing `howToLd()` helper from `src/lib/seo.ts`. This keeps frontmatter parsing centralized, reuses the established JSON-LD generator used by blogs, and lets `/courses/[slug]` inherit the same behavior through its re-export of `/learn/[slug]`.

**Rejected**: Parse `outline.md` again inside the page component — duplicates vault IO and bypasses the `Course` contract; add Cloudflare-specific special casing in the page — solves one course but leaves no reusable course-level HowTo support; create a second course-only HowTo helper — duplicates `howToLd()` and risks schema drift.

## Steps (Executor follows in order)
1. In `learnovaBeast`, preserve the current dirty feature-branch work (`koea-7247/...`) or use a fresh worktree, then create the implementation branch from `origin/academy/redesign-v1`.
2. Update `learnova-academy/src/lib/courses.ts` to add a `CourseHowToStep` or equivalent type and optional `howto_steps?: { name: string; text: string; url?: string }[]` on `Course`; normalize `data.howto_steps` in `readCourseOutline()` by accepting only array items with non-empty string `name` and `text`, preserving optional string `url`.
3. In `learnova-academy/src/app/(site)/learn/[slug]/page.tsx`, import `howToLd` and append it to the existing `jsonLdScript([...])` array only when `course.howto_steps?.length`; pass `name: course.title`, `description`, `url: https://academy.kspl.tech/courses/${course.slug}`, `totalTimeMinutes: course.total_duration_min`, and `steps: course.howto_steps.map(...)`.
4. Normalize each HowTo step URL to an absolute course URL before calling `howToLd`: for `#chapter...`, emit `https://academy.kspl.tech/courses/${course.slug}${step.url}`; for absolute URLs, preserve as-is; for missing URLs, omit the field.
5. Verify the 2026 title path rather than changing it unless evidence shows drift: `generateMetadata()` currently uses `course.title` for `<title>`, the hero `<h1>` renders `course.title`, and `/llms.txt` uses `c.title`; if any runtime check fails, fix the smallest broken link in that path.
6. Add focused verification coverage using the existing Academy scripts style: either a small `node --experimental-strip-types` verifier under `learnova-academy/scripts/` or a direct scripted check that imports the route/data helpers and asserts the Cloudflare page JSON-LD contains one `HowTo` with seven `HowToStep` objects and that `/llms.txt` contains `Cloudflare Agents Platform: From Workers to Production — 2026 Tutorial`.
7. Open the PR using `.github/PULL_REQUEST_TEMPLATE.md`, noting no Convex deployment, the `academy/redesign-v1` base branch, the HowTo data contract, focused verification commands, and rollback as removal of the course `howto_steps` wiring.

## Verification (QA Verifier checks these)
- [ ] `cd learnova-academy && KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault npm run typecheck`
- [ ] `cd learnova-academy && KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault npm run build` or, if Vite/Next build hangs on the shared machine, run the exact targeted verifier from Step 6 and report the build limitation.
- [ ] Render or inspect `/courses/cloudflare-agents-platform-workers-to-production` and confirm its `application/ld+json` includes `@type: "HowTo"` with seven `HowToStep` entries whose names match `outline.md`.
- [ ] Confirm the rendered page title and `<h1>` include `Cloudflare Agents Platform: From Workers to Production — 2026 Tutorial`.
- [ ] Confirm `/llms.txt` contains a course entry for `cloudflare-agents-platform-workers-to-production` using the same 2026 title.

## Risk
- The Cloudflare outline is currently `outline-draft-for-review`, but `listDiscoverableCourses()` includes all outlines for static rendering and `/llms.txt`. Mitigation: do not change course visibility rules in this ticket; only attach HowTo schema when `howto_steps` is present and valid.

## Out of scope
- Do not change the Cloudflare course content, status, chapter files, sitemap visibility, blog HowTo parsing, Convex data, or production deployment configuration.
