---
ticket: KOEA-2724
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.34
base_branch: master
basebranch_verified: true
planned_against_branch: master
planned_against_sha: 43324233846d63fcea9bd08e02da145d1ea8c7eb
preflight: "status=in_progress assigned_to_planner=true active_siblings=0 acceptance_spec=pass chain_alert_cooldown=1eef225c-6b39-43c2-8713-a516dc68bf56"
---

# Plan: Fix publish-action issue-list pagination gap

## Goal
`scripts/publish-action.sh` must see every relevant Paperclip issue even when the company has more than the API's current 1000-row list cap. Success means Phase 0 slug checks, Phase 1 `g4-approved` dispatch discovery, and Phase 2 `dispatching` polling all consume a complete paginated issue snapshot without running the live publish action during implementation verification.

## Context
- Files to read first: `scripts/publish-action.sh:49-79`, `scripts/publish-action.sh:343-404`, `server/src/routes/issues.ts:920-980`, `server/src/services/issues.ts:2084-2219`, `server/src/__tests__/issues-service.test.ts:32-37`.
- Relevant prior work: KOEA-2723 was created as an operational carrier because KOEA-1430 was older than the visible 1000-row broad issue list despite `metadata.publish_state="g4-approved"`. Existing server code already accepts `offset` and clamps `limit` to `ISSUE_LIST_MAX_LIMIT=1000`.
- Constraints: do not run live `scripts/publish-action.sh`, do not push `koenig-ai-org`, do not dispatch `learnovaBeast`, do not expose secrets, and keep the fix scoped to issue discovery for publish-action. `origin/master` is verified; `origin/main` is absent in this repo.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a paginated issue-fetch helper inside `scripts/publish-action.sh` and route all three broad issue reads through it. The helper should request pages with `limit=1000&offset=N`, append returned arrays until a page has fewer than 1000 items, normalize both bare-array and `{items:[...]}` responses, and write one complete JSON array cache for Phase 0 slug lookup. Phase 1 and Phase 2 should read from the same helper instead of making their current single-page `limit=2000` calls.

**Rejected**: Add a new server metadata filter first, because it touches API contract and shared validation surface when the existing `offset` contract already solves this incident. **Rejected**: Raise `ISSUE_LIST_MAX_LIMIT`, because larger single responses just move the failure threshold and can make routine issue-list calls heavier. **Rejected**: Query KOEA-1430 or known slugs directly, because publish-action must handle future approved artifacts without manual carrier issues.

## Steps (Executor follows in order)
1. In `scripts/publish-action.sh`, replace `fetch_issues_by_slug` with a general `fetch_all_issues` helper that creates the existing `GUARD_ISSUE_CACHE`, loops over `offset` in 1000-row pages, passes the auth header when `PAPERCLIP_API_KEY` is set, fails closed on curl/JSON errors, and stores one complete JSON array.
2. Update `slug_to_issue_info` to call `fetch_all_issues` and keep its existing output contract: `issue<TAB>publish_state`, `none<TAB>none`, or `api-error<TAB>api-error`.
3. Update Phase 1 and Phase 2 in `scripts/publish-action.sh` to consume the cached complete issue array from `fetch_all_issues` instead of each running a fresh `curl ... issues?limit=2000`.
4. Add a lightweight shell smoke test under `scripts/tests/` that stubs `curl` to return two full 1000-item pages plus a final short page, then verifies that a late-page `g4-approved` issue and a late-page `dispatching` issue are present in the helper output without calling GitHub or PATCH routes.
5. Add one failure fixture to the same smoke test where page 2 returns invalid JSON or curl fails; assert the helper reports failure and the script path treats it as no unsafe dispatch, preserving the current fail-closed guard behavior.
6. Run `bash -n scripts/publish-action.sh scripts/tests/<new-smoke-test>.sh` and the new smoke test. Do not run live `scripts/publish-action.sh`.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/publish-action.sh scripts/tests/<new-smoke-test>.sh` passes.
- [ ] The new smoke test proves pagination continues past 1000 rows and finds candidates that only appear on page 2 or later.
- [ ] `rg -n "issues\\?limit=2000" scripts/publish-action.sh` returns no active issue-list fetches.
- [ ] `rg -n "offset=" scripts/publish-action.sh` shows the paginated Paperclip issue-list helper is used by Phase 0, Phase 1, and Phase 2.
- [ ] No verification step runs live publish-action, calls GitHub repository_dispatch, pushes `koenig-ai-org`, or patches real Paperclip issue metadata.

## Risk
- Shell-level pagination can silently regress if test fixtures only exercise the happy path. Mitigation: include both multi-page success and malformed-page failure fixtures, keep JSON normalization in one helper, and ensure Phase 1/2 do not bypass that helper.

## Out of scope
- Adding new Paperclip API filters, changing the server-side issue-list limit, repairing already-published metadata, running the live launchd job, dispatching Learnova builds, or changing G4/G5 publish semantics beyond making existing issue discovery complete.
