---
ticket: KOEA-2423
planner_ticket: KOEA-2426
planner: planner
agent: planner
date: 2026-05-14
type: decision
tags:
  - decision
  - plan
  - learnovaBeast
estimated_complexity: large
estimated_token_cost: "$0.72"
repo: Koenig-Solutions-Private-Limited/learnovaBeast
base_branch: academy/redesign-v1
basebranch_verified: true
triggering_approval: 5963662a-d7e8-4825-a11d-4ffd8f12acb4
---

# Plan: Rework the open learnovaBeast PR stack before CEO G3

## Goal

Get the open `learnovaBeast` PR stack into a mergeable, reviewable state against `academy/redesign-v1`. Success means every open PR is either rebased and ready for Code Reviewer/QA, explicitly superseded and closed, or assigned a narrow Executor fix with clear dependency order.

This plan reconciles the parent title's "9 PRs" with the current live inventory: there are 14 open PRs (#4, #5, #6, #15, #16, #17, #18, #19, #21, #23, #27, #29, #34, #38).

## Context

- Files to read first:
  - `learnova-academy/next.config.ts:5-32` for redirects and `optimizeCss`.
  - `learnova-academy/package.json:5-41` for lint/typecheck/build scripts and `critters`.
  - `learnova-academy/src/app/layout.tsx:31-100` for global metadata and root `<head>`/body placement.
  - `learnova-academy/src/app/blog/[slug]/page.tsx:35-104` for blog metadata and JSON-LD emission.
  - `learnova-academy/src/app/learn/[slug]/page.tsx:24-140` for course metadata, JSON-LD, and the chapter renderer collision.
  - `learnova-academy/src/app/llms.txt/route.ts:10-28` and `learnova-academy/src/app/llms-full.txt/route.ts:9-14` for the llms route dynamic/static decision.
  - `learnova-academy/src/lib/seo.ts:161-321` for FAQ, schema, and JSON-LD helpers.
  - `learnova-academy/src/lib/vault.ts:21-141` for blog frontmatter, FAQ, and slide URL support.
  - `learnova-academy/src/lib/courses.ts:21-149` for course resource URL handling.
  - `learnova-academy/src/components/GlossaryPopover.tsx:24-53` for the #27/#34 overlap.
- Relevant prior work:
  - PRs: #4, #5, #6, #15, #16, #17, #18, #19, #21, #23, #27, #29, #34, #38.
  - Prior comments: #4 has V7 Phase N "do not merge as-is"; #23 needs a human decision and should not merge autonomously; #27 has G_code approval but is dirty; #29 has G_code request changes; #34 has request changes for procedural/out-of-scope CSS/binary handling; #38 has G_code approval but Vercel failed.
  - Chain-alert approval `5963662a-d7e8-4825-a11d-4ffd8f12acb4` explicitly allowed planning despite KOEA-2423 child fanout.
- Constraints:
  - Target `academy/redesign-v1`; never target `main` for implementation PRs.
  - Use isolated per-PR worktrees. Do not reuse the shared cwd or the reserved FE worktree for rebases.
  - Do not modify portals other than `learnova-academy` unless CEO signs off.
  - Close superseded PRs only after posting a short comment pointing to this plan.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Triage-collapse, then rebase in dependency order. Executor should first close the two PRs that are not valid implementation vehicles (#4 and #23), then work the remaining PRs in stack order: independent gate fix (#27), JSON-LD/SEO foundation (#21 -> #5 -> #6), main-targeted SEO tangle (#16 -> #15/#17/#19 -> #18), course route/resource stack (#29 -> #38), and blog slides (#34). This keeps each PR's historical review context while preventing a mega-branch from hiding regressions.

**Rejected**: Merge by PR number, because it would merge stale `main`-targeted branches before the production base is clean. One replacement mega-PR, because it would erase useful prior review comments and make SEO/course/media regressions harder to isolate. Reopen all cancelled executor children immediately, because KOEA-2430 is already the plan-review gate and execution should wait for that gate to pass.

## PR classification

| PR | Current base | Classification | Exact target base | Executor action |
|---|---|---|---|---|
| #4 KOEA-40 broad JSON-LD | `main` | superseded/close | none | Close after comment. It shares head with #21 but includes 34 files and out-of-scope academy surface work; do not merge. |
| #5 KOEA-41/43 SEO foundation | `koea-40/json-ld-schema-sitewide` | keep/rebase | `koea-40/json-ld-schema-sitewide` after #21 is fixed on `academy/redesign-v1` | Rebase, fix commit-author/Vercel identity artifact, keep only SEO/meta/internal-link scope. |
| #6 KOEA-42 og:image capability pages | `koea-43/fix-seo-internal-links` | needs Executor fix | `koea-43/fix-seo-internal-links` after #5 | Rebase, address prior G_code request changes, verify capability pages and Vercel. |
| #15 KOEA-431 FAQ JSON-LD | `main` | needs Executor fix | `ci/publish-pnpm-setup` (#16) | Rebase on #16, dedupe the redirect block already owned by #16, keep only FAQ/vault deltas not already on `academy/redesign-v1`. |
| #16 KOEA-426 redirects + llms live | `main` | keep/rebase | `academy/redesign-v1` | Make #16 the sole owner of `next.config.ts` redirect work and llms route dynamic/static decision; rebase first. |
| #17 KOEA-432 meta descriptions | `main` | needs Executor fix | `ci/publish-pnpm-setup` (#16) | Rebase after #16; resolve `authors.ts` against merged author work and avoid overwriting current page metadata. |
| #18 KOEA-433 OG/Twitter meta | `koea-431/faq-json-ld` | needs Executor fix | `koea-431/faq-json-ld` after #15 is rebased | Keep as stacked on #15; dedupe with #17 metadata where both touch the same pages. |
| #19 KOEA-434 llms-full 72 pages | `main` | needs Executor fix | `ci/publish-pnpm-setup` (#16) | Rebase after #16; either push the missing 72-entry fixture source or drop the 72-entry claim and keep only verifiable llms output. |
| #21 KOEA-40 JSON-LD to head | `academy/redesign-v1` | needs Executor fix | `academy/redesign-v1` | Do not keep the current `next/script beforeInteractive` page-level approach unless `view-source` proves it. Prefer restoring raw JSON-LD scripts or moving emission to root-safe placement, then close #4. |
| #23 KOEA-719 critters/optimizeCss | `main` | superseded/close | none | Close. Current `academy/redesign-v1` already has `critters` and `optimizeCss`; the open PR is a draft main-tracking dump. |
| #27 KOEA-1326 lint/typecheck gates | `academy/redesign-v1` | merge-ready after rebase | `academy/redesign-v1` | Rebase, resolve `package.json`/`GlossaryPopover.tsx`, run lint/typecheck, then send to review. |
| #29 KOEA-1243 course chapter routes | `academy/redesign-v1` | needs Executor fix | `academy/redesign-v1` | Rebase and undraft; keep the `_shared/chapter-render` extraction; sequence before #38. |
| #34 KOEA-1851 blog slides + LCP | `academy/redesign-v1` | needs Executor fix | `academy/redesign-v1` after #27 if #27 merges first | Drop the out-of-scope `academy.css` hunk, choose generated `mirrorBlogSlides()` over committed `public/slides/*.pptx`, and re-review. |
| #38 KOEA-2302 course resource links | `academy/redesign-v1` | needs Executor fix | `koea-1243/course-chapter-routes` after #29 | Fix the `inline()`/context caller build failure and port link/resource rewriting into the shared renderer introduced by #29. |

## Dependency order and duplicate overlaps

1. Independent first: #27 can land before the SEO/course stacks once rebased. #34 also touches `GlossaryPopover.tsx`, so rebase #34 after #27 if #27 lands first.
2. JSON-LD foundation: #21 is the narrow KOEA-40 vehicle; #4 is the stale broad duplicate and should close. #5 then stacks on #21; #6 stacks on #5.
3. SEO tangle: #16 owns `next.config.ts` redirects and `llms*.txt` route mode. #15, #17, and #19 should rebase on #16. #18 remains stacked on #15. Duplicate areas are `next.config.ts`, `llms.txt`, `llms-full.txt`, `authors.ts`, `blog/[slug]/page.tsx`, and metadata blocks across index/detail pages.
4. Course routes/resources: #29 changes `learn/[slug]/page.tsx` by extracting chapter rendering and adding `/learn/[slug]/[chapter]`; #38 changes the same route for course resource links. Rebase #38 after #29 and move resource-link fixes into the extracted renderer.
5. Media/blog slides: #34 overlaps #27 on `GlossaryPopover.tsx` and overlaps current `vault.ts` frontmatter normalization. It should not commit both static `public/slides/*.pptx` binaries and the `mirrorBlogSlides()` generator.

## Steps (Executor follows in order)

1. Create isolated worktrees from the PR head branches with a consistent pattern, for example `git fetch origin pull/<n>/head:koea-2423/pr-<n>` then `git worktree add /tmp/learnova-pr-<n> koea-2423/pr-<n>`. Before each PR push, verify `git status --short` is clean except intended edits.
2. Close #4 and #23 with comments referencing this plan; #4 is superseded by the #21 path and #23 is a draft `main` tracking PR whose useful changes are already on `academy/redesign-v1`.
3. Rebase and verify #27 against `origin/academy/redesign-v1`; resolve only `learnova-academy/package.json` and `learnova-academy/src/components/GlossaryPopover.tsx`; run `pnpm --dir learnova-academy lint` and `pnpm --dir learnova-academy typecheck`.
4. Repair the JSON-LD/SEO foundation in order: #21, #5, #6. For #21, prove JSON-LD appears in `view-source:` or revert to raw page `<script type="application/ld+json">`; for #5/#6, fix Vercel author identity and prior G_code comments before re-review.
5. Untangle #16/#15/#17/#18/#19 in the SEO stack. Rebase #16 to `academy/redesign-v1`; rebase #15/#17/#19 to #16; rebase #18 to #15; remove duplicate redirect/metadata hunks and resolve #19's missing 72-entry source claim.
6. Rework course and media PRs: rebase/undraft #29, then rebase #38 onto #29 and fix the `inline()` context call; rebase #34 after #27, drop the out-of-scope CSS hunk, and keep only one slide-delivery mechanism.
7. For each surviving PR, push only its branch, request Code Reviewer, and leave PR comments listing verification commands and exact preview URLs. If any PR still touches >5 files after dedupe, split it before review instead of widening scope.

## Executor command skeleton

```sh
cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
git ls-remote --heads origin academy/redesign-v1
git fetch origin academy/redesign-v1

# Per PR:
git fetch origin pull/<PR>/head:koea-2423/pr-<PR>
git worktree add /tmp/learnova-pr-<PR> koea-2423/pr-<PR>
cd /tmp/learnova-pr-<PR>
git rebase origin/academy/redesign-v1
pnpm --dir learnova-academy lint
pnpm --dir learnova-academy typecheck
pnpm --dir learnova-academy build
git push --force-with-lease origin HEAD:<original-head-branch>
```

For stacked branches, replace the rebase target with the exact target base from the PR classification table. Do not force-push `academy/redesign-v1` directly.

## Verification (QA Verifier checks these)

- [ ] Every open PR is accounted for: #4/#23 closed, all survivors target either `academy/redesign-v1` or the planned stack branch whose root targets `academy/redesign-v1`.
- [ ] #27, #21, #5, #6, #16, #15, #17, #18, #19, #29, #34, and #38 each have fresh Vercel previews or an explicit closed/superseded comment.
- [ ] `pnpm --dir learnova-academy lint`, `pnpm --dir learnova-academy typecheck`, and `pnpm --dir learnova-academy build` pass on every surviving branch before review.
- [ ] JSON-LD is visible in `view-source:` for representative home, blog detail, course detail, glossary detail, and author pages.
- [ ] `/llms.txt`, `/llms-full.txt`, `/learn/<course>`, `/learn/<course>/<chapter>`, blog slide links, and course resource links do not 404 in the preview chosen for QA.
- [ ] Code Reviewer confirms no PR retains unrelated portal changes outside `learnova-academy`.

## Risk

- The main risk is rebase drift across overlapping SEO and course files. Mitigation: keep the stack order above, close stale broad PRs first, and require each survivor to list changed files and verification evidence before Code Reviewer spends another pass.

## Out of scope

- This plan does not promote anything to `main`.
- This plan does not decide whether `main` should track `academy/redesign-v1`; #23 explicitly needs separate CEO/Chief decision if that is desired.
- This plan does not modify code, push branches, or close PRs from the Planner heartbeat.
- This plan does not touch non-academy portals.

## Telemetry

- preflight_status=pass
- chain_alert_approval=5963662a-d7e8-4825-a11d-4ffd8f12acb4
- basebranch_verified=true
- live_open_pr_count=14
- plan_revision=1
