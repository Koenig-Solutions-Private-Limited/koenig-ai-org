---
ticket: KOEA-5482
planner: planner
date: 2026-05-27
estimated_complexity: small
estimated_token_cost: $0.25
base_branch: master
basebranch_verified: true
---

# Plan: Fix publish-action blog published URLs

## Goal
Stop `scripts/publish-action.sh` from recording the Academy homepage as `metadata.published_url` for successful blog publishes. Success means a dispatching blog issue with `metadata.slug=2026-05-14-anthropic-mcp-legal-platform-playbook` is marked published with `https://academy.kspl.tech/blog/2026-05-14-anthropic-mcp-legal-platform-playbook`, while issues without a blog slug keep the current homepage fallback.

## Context
- Files to read first: `scripts/publish-action.sh:15-24`, `scripts/publish-action.sh:390-498`, `vault/_audit/g5/2026-05-14-anthropic-mcp-legal-platform-playbook-20260527.md:1-27`, `vault/marketing/publish-verify/2026-05-27-2026-05-14-anthropic-mcp-legal-platform-playbook.md:1-10`
- Relevant prior work: KOEA-5476 repaired KOEA-1391 directly and confirmed the systemic source: Phase 2 currently writes `PROD_URL=https://academy.kspl.tech` into `metadata.published_url`. `vault/decisions/KOEA-1137-plan.md` already established that blog publish metadata must store `https://academy.kspl.tech/blog/<slug>` for G5 to probe the canonical artifact URL directly.
- Constraints: Plan mode only. Keep the fix in `scripts/publish-action.sh` plus one narrow smoke check if needed. Do not run live publish-action, dispatch GitHub Actions, push the vault, change Learnova code, or modify Paperclip core packages. Verified code base branch: `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Preserve `metadata.slug` through Phase 2 and derive a blog artifact URL before the publish metadata PATCH. Add a small shell helper such as `published_url_for_slug()` that returns `$PROD_URL/blog/$slug` only when `slug` is non-empty and `vault/blogs/$slug/draft.md` exists; otherwise it returns `$PROD_URL`. Extend the Phase 2 dispatching issue query to include `slug`, pass it through the loop, log the derived URL, and patch `metadata.published_url` with that derived value.

**Rejected**: Always write `$PROD_URL/blog/$slug` whenever `metadata.slug` exists, because some non-blog publish states may carry slugs and the ticket explicitly says to preserve non-blog behavior. **Rejected**: Change the Learnova GitHub Action to return the published route, because this regression is in Paperclip metadata derivation and does not require touching the deployment repo. **Rejected**: Repair only KOEA-1391 metadata again, because KOEA-5476 already did that and this ticket is for the systemic publish-action source.

## Steps (Executor follows in order)
1. Edit `scripts/publish-action.sh` near the config block to add a pure `published_url_for_slug()` helper that accepts a slug and returns `$PROD_URL/blog/$slug` only when `vault/blogs/$slug/draft.md` exists, falling back to `$PROD_URL` for blank or non-blog slugs.
2. Update the Phase 2 `DISPATCHING_JSON` builder in `scripts/publish-action.sh:394-404` to include `slug: md.get('slug', '')` alongside `id` and `dispatched_at`.
3. Update the Phase 2 loop in `scripts/publish-action.sh:426-493` to read `ISSUE_ID`, `DISPATCHED_AT`, and `SLUG`, compute `PUBLISHED_URL="$(published_url_for_slug "$SLUG")"`, and use that variable in both the success log and metadata PATCH.
4. Add a narrow smoke check, preferably `scripts/smoke/publish-action-published-url.sh`, that exercises the helper or an explicit self-test mode without running live publish-action network, git, dispatch, or Paperclip mutation paths.
5. In the smoke check, cover the known blog slug `2026-05-14-anthropic-mcp-legal-platform-playbook` and assert the derived URL is `https://academy.kspl.tech/blog/2026-05-14-anthropic-mcp-legal-platform-playbook`.
6. In the same smoke check, cover a blank/non-blog slug and assert the fallback remains `https://academy.kspl.tech`, proving non-blog behavior is preserved.
7. Run `bash -n scripts/publish-action.sh scripts/smoke/publish-action-published-url.sh`, the new smoke check, and `git diff --check`.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/publish-action.sh scripts/smoke/publish-action-published-url.sh` passes.
- [ ] `bash scripts/smoke/publish-action-published-url.sh` passes without calling GitHub, Paperclip mutation endpoints, `git push`, or the live publish-action run path.
- [ ] The known slug `2026-05-14-anthropic-mcp-legal-platform-playbook` derives exactly `https://academy.kspl.tech/blog/2026-05-14-anthropic-mcp-legal-platform-playbook`.
- [ ] A blank or non-blog slug still derives `https://academy.kspl.tech`.
- [ ] Source inspection shows Phase 2 no longer writes `published_url` directly from `$PROD_URL` for blog artifacts.

## Risk
- The smoke check could accidentally test duplicated helper logic instead of the production helper. Mitigate by adding a sourceable/self-test path in `scripts/publish-action.sh` or by invoking the production helper directly before the script reaches env loading or network work.

## Out of scope
- Changing Learnova deployment workflows, changing G4/G5 publish-state semantics, rerunning Publish Verifier, modifying KOEA-1391 metadata again, broad publish-action auth/pagination refactors, Paperclip core changes, live launchd reloads, GitHub dispatches, and vault pushes.
