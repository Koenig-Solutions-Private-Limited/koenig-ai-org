---
ticket: KOEA-5275
planner: planner
agent: planner
date: 2026-05-27
type: decision
tags:
  - decision
  - engineering
estimated_complexity: medium
estimated_token_cost: "$0.34"
base_branch: academy/redesign-v1
basebranch_verified: true
authorized_by_approval: 0e8420cf-a22e-4704-b4c7-fdcf34fa2f09
---

# Plan: Remove dead sitemap URL and add sitemap health guard

## Goal
`https://academy.kspl.tech/sitemap.xml` must not advertise `https://academy.kspl.tech/blog/seven-cli-comparison` while that route returns 404. The Academy publish path and a daily scheduled guard should fail with clear output if any sitemap URL returns non-200, so crawler-surface regressions are caught before or shortly after deploy.

## Context
- Files to read first: `learnova-academy/src/app/sitemap.ts:1-54`, `learnova-academy/src/lib/vault.ts:44-54`, `learnova-academy/src/lib/vault.ts:78-179`, `learnova-academy/src/app/blog/[slug]/page.tsx:32-71`, `learnova-academy/package.json:5-13`, `.github/workflows/publish.yml:16-37`.
- Relevant prior work: KOEA-5248 found the crawler regression; KOEA-5275 requested this fix; planner-chain alert `0e8420cf-a22e-4704-b4c7-fdcf34fa2f09` authorized this normal Plan-Review -> Implement -> G_code -> G2 chain.
- Current evidence: `curl -o /dev/null -w '%{http_code}' https://academy.kspl.tech/blog/seven-cli-comparison` returned `404` during planning. A live sitemap grep for `seven-cli` returned no match during planning, so the removal may already be present in current content/build state; Executor should still preserve and verify that absence.
- Constraints: target only `learnova-academy` on `origin/academy/redesign-v1`; do not deploy Convex; do not modify `learnova-tc`, `learnova-admin`, `learnova-sales`, or `learnova-student`; local worktree was dirty and behind origin during planning, so Executor should create a clean implementation branch from freshly fetched `origin/academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a reusable sitemap health script and wire it into publish plus a daily workflow. Keep sitemap generation source-of-truth unchanged unless Executor finds the forbidden URL still emitted from the fresh branch/vault checkout; then make the smallest source fix that removes only `seven-cli-comparison`. The guard should parse sitemap `<loc>` entries, explicitly fail if the forbidden dead URL appears, fetch each listed URL, require HTTP 200, and print a concise failing-URL table for GitHub Actions logs.

**Rejected**: hardcode a permanent denylist in `src/app/sitemap.ts` - hides one symptom while RSS/llms surfaces can still drift; change blog route behavior to serve the dead URL - out of scope because the ticket asks to remove a stale sitemap URL, not resurrect content; run a broad site crawler in CI - more expensive and slower than validating the sitemap contract directly.

## Steps (Executor follows in order)
1. Create a clean branch from `origin/academy/redesign-v1` in the FE worktree, then confirm `learnova-academy/src/lib/vault.ts` does not treat `g4-approved` as publishable and `vault/blogs/seven-cli-comparison/draft.md` is not emitted by `listPublishableBlogs()` in the current build input.
2. Add `learnova-academy/scripts/check-sitemap-health.mjs` using Node 20 globals only: fetch a sitemap URL, parse `<loc>` values, fail if `https://academy.kspl.tech/blog/seven-cli-comparison` is present, request each listed URL with retries, and require final HTTP 200.
3. Add `sitemap:health` to `learnova-academy/package.json` so local, publish, and scheduled jobs can run the same command against `https://academy.kspl.tech/sitemap.xml` by default.
4. Update `.github/workflows/publish.yml` after the deploy step to run the health command against production with retry/backoff, so a publish that creates dead sitemap entries fails with the offending URLs in logs.
5. Add `.github/workflows/sitemap-health.yml` with a daily cron and manual dispatch that checks out `academy/redesign-v1`, installs the minimal Node/pnpm setup if needed, and runs `pnpm --filter learnova-academy sitemap:health`; the failed Actions run is the alert path.
6. If Step 1 shows the forbidden URL is still emitted on a clean branch, make the smallest source-of-truth fix in `learnova-academy/src/lib/vault.ts` or the synced vault input to exclude only that unpublished blog; do not broaden blog publishability rules.
7. Open a draft PR against `academy/redesign-v1` and include the exact command output showing the forbidden URL is absent and the sitemap health script passes.

## Verification (QA Verifier checks these)
- [ ] `curl -sS https://academy.kspl.tech/sitemap.xml | rg 'seven-cli-comparison|2026-05-14-seven-cli-comparison'` returns no matches after deploy.
- [ ] `curl -sS -o /dev/null -w '%{http_code}\n' https://academy.kspl.tech/blog/seven-cli-comparison` still returns `404`, proving the guard is not masking the dead page by serving stale content.
- [ ] `pnpm --filter learnova-academy sitemap:health` exits 0 and prints the checked URL count.
- [ ] Temporarily running the script against a fixture sitemap containing `https://academy.kspl.tech/blog/seven-cli-comparison` exits non-zero with that URL in the output.
- [ ] `pnpm --filter learnova-academy typecheck` passes.

## Risk
- Network checks can be flaky in GitHub Actions. Mitigation: implement bounded retries/backoff and print final status per failed URL, but still fail if the URL remains non-200 after retries.

## Out of scope
- Publishing or restoring the `seven-cli-comparison` blog page.
- Convex deploys or changes to non-Academy portals.
- Fixing unrelated sitemap course 404s unless the new guard exposes them; if it does, file or link a separate ticket rather than expanding this PR.
