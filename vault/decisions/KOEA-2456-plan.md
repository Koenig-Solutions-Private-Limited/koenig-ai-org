---
ticket: KOEA-2456
planner: planner
agent: planner
date: 2026-05-14
type: decision
tags:
  - decision
estimated_complexity: small
estimated_token_cost: "$0.35"
repo: learnovaBeast
worktree: /paperclip/instances/default/workspaces/learnovaBeast-koea-2456
base_branch: academy/redesign-v1
basebranch_verified: true
feature_branch: koea-2456/capabilities-soft404
approval_context: planner_chain_alert e5effc13-f52f-4b25-899d-1c1cd5eb7f12 resolved by Chief Engineering
---

# Plan: Remove dead capabilities URLs from the academy sitemap

## Goal
Stop advertising `/capabilities` URLs that do not have public pages in the learnova-academy site. Success means `/sitemap.xml` contains no `/capabilities` entries, `/capabilities` and nested capability URLs return HTTP 404, and no student, sales, admin, or TC portal files are touched.

## Context
- Files to read first: `learnova-academy/src/app/sitemap.ts:1-66`, `learnova-academy/src/lib/capabilities.ts:1-233`, `learnova-academy/README.md:34-45`, `learnova-academy/src/app/not-found.tsx:1-80`.
- Relevant prior work: live sitemap currently lists `/capabilities`, 5 vendor pages, and 10 capability pages; current live `/capabilities` returns HTTP 404 with the not-found body, but sitemap still advertises the dead IA.
- Constraints: learnova-academy only; do not modify student/sales/admin/tc portals; do not deploy Convex; base branch verified with `git ls-remote --heads origin academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Remove the capabilities sitemap surface until real pages exist. In `learnova-academy/src/app/sitemap.ts`, remove the `@/lib/capabilities` import, remove `/capabilities` from `staticRoutes`, remove the vendor/capability route generation blocks, and return only the already-rendered static/course/blog/author/glossary routes. Keep `src/lib/capabilities.ts` and vault capability notes untouched because they may support a future feature, but they must not create crawlable URLs without pages.

**Rejected**: Implement full `/capabilities` pages now - this would require new index/vendor/detail routes, content presentation, metadata, schema, and fact-checking, which is broader than a soft-404 sitemap fix. **Rejected**: Redirect `/capabilities` to `/catalog` or `/glossary` - that hides the dead IA but creates misleading URLs and does not remove the sitemap quality problem. **Rejected**: Delete capability vault data or `src/lib/capabilities.ts` - unnecessary data loss for this ticket.

## Steps (Executor follows in order)
1. In `/paperclip/instances/default/workspaces/learnovaBeast-koea-2456`, confirm the worktree is on `koea-2456/capabilities-soft404` based on `origin/academy/redesign-v1`; ignore `.claude/agent-lock` unless it blocks git operations.
2. Edit `learnova-academy/src/app/sitemap.ts` to remove `listCapabilities`/`listVendors`, the `/capabilities` static route, the `vendorRoutes` block, the `capabilityRoutes` block, and those arrays from the returned sitemap.
3. Do not add public capability pages in this ticket. Only if local preview still returns HTTP 200 for `/capabilities` after step 2, add the minimum explicit `learnova-academy/src/app/capabilities/page.tsx` that calls `notFound()`; otherwise leave routing unchanged.
4. Run `pnpm --dir learnova-academy typecheck`.
5. Run a local preview/dev server for learnova-academy and verify `curl -sS http://localhost:<port>/sitemap.xml | rg '/capabilities'` returns no matches.
6. Verify `curl -sSI http://localhost:<port>/capabilities`, `/capabilities/anthropic`, and `/capabilities/openai/realtime-api` all report HTTP 404.
7. Commit and open a draft PR into `academy/redesign-v1` using `.github/PULL_REQUEST_TEMPLATE.md`; include the verification output and note that no non-academy portals or Convex deploys were touched.

## Verification (QA Verifier checks these)
- [ ] `sitemap.xml` contains zero `/capabilities` URLs on the PR preview or local preview.
- [ ] `/capabilities`, `/capabilities/anthropic`, and `/capabilities/openai/realtime-api` return HTTP 404, not HTTP 200 with a 404 body.
- [ ] The diff is limited to learnova-academy sitemap/routing files and does not touch student, sales, admin, or TC portals.

## Risk
- The unused capabilities library may look like dead code after removing sitemap imports. Mitigation: leave it in place intentionally and mention in the PR that the data layer is preserved for a future real capabilities feature.

## Out of scope
- Building the public capabilities index, vendor pages, or capability detail pages.
- Fact-checking or rewriting capability markdown content.
- Changing robots, llms.txt, course/blog sitemap behavior, or any portal outside learnova-academy.

## Pre-flight Footer
- status_check: passed
- sibling_chain_check: resolved by Chief Engineering comment on 2026-05-14
- acceptance_spec_check: passed; body contains concrete required output, scope, evidence, and handoff
- basebranch_verified: true
