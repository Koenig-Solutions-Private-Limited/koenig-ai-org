---
ticket: KOEA-9841
planner: planner
date: 2026-07-01
estimated_complexity: small
estimated_token_cost: $0.28
koenig_ai_org_base_branch: master
learnova_base_branch: academy/redesign-v1
basebranch_verified: true
plan_revision: 2
review_context: KOEA-9858 G_plan REQUEST CHANGES on 2026-07-01
---

# Plan: Repair Career Compass reconciler S3 client runtime resolution

## Goal
Restore the Career Compass reconciler so `scripts/career-reconcile.sh` can load `scripts/career-reconcile.mjs` past the `@aws-sdk/client-s3` import. Success means the dependency boundary is repaired in the `learnovaBeast/learnova-academy` Node package context, with no R2 or Paperclip mutations during verification.

## Context
- Files to read first: `scripts/career-reconcile.mjs:33-42`, `scripts/career-reconcile.sh:1-6`, `learnova-academy/package.json:19-21`, `learnova-academy/pnpm-lock.yaml:9-13`, `learnova-academy/pnpm-lock.yaml:127-129`
- Relevant prior work: KOEA-9840 escalated three `career-toc-reconciler` failures before R2 processing; KOEA-9858 requested this revision because current `academy/redesign-v1` already declares `@aws-sdk/client-s3` as `^3.1064.0`
- Constraints: keep repair narrow; do not run the reconciler against production R2/Paperclip during verification; do not downgrade or churn `learnova-academy/package.json` / `pnpm-lock.yaml` when they already declare the dependency

## Approach (1 chosen, alternatives rejected)
**Chosen**: Runtime install refresh plus non-mutating load check. Executor first verifies the live `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` manifest, lockfile, and resolver state. If the manifest and lockfile already declare `@aws-sdk/client-s3@3.1064.0` but Node cannot resolve it, the narrow repair is `pnpm install --frozen-lockfile` in that `learnova-academy` package context or the equivalent scheduler checkout install refresh. Then add a `CAREER_RECONCILE_LOAD_CHECK=1` early-exit guard immediately after the S3 require in `scripts/career-reconcile.mjs` so verification proves the import loads without reading `.env.koenig` or mutating R2/Paperclip.

**Rejected**: Add `@aws-sdk/client-s3` to package files unconditionally - stale against current source and risks unnecessary lockfile churn. Rejected: move the reconciler to a new local package or vendor AWS SDK in `koenig-ai-org` - broader dependency redesign than the incident requires.

## Steps (Executor follows in order)
1. Verify source state on `learnovaBeast` `academy/redesign-v1`: confirm `learnova-academy/package.json` and `learnova-academy/pnpm-lock.yaml` already declare `@aws-sdk/client-s3` at `^3.1064.0` / `3.1064.0`; do not edit these files if confirmed.
2. Verify the live runtime resolver from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json` with `node -e 'const {createRequire}=require("node:module"); console.log(createRequire("/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json").resolve("@aws-sdk/client-s3"))'`.
3. If Step 2 fails while Step 1 is already satisfied, run `pnpm install --frozen-lockfile` from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`, then repeat the resolver check; record this as an environment/runtime install action, not a source dependency change.
4. In `koenig-ai-org/scripts/career-reconcile.mjs`, add a `CAREER_RECONCILE_LOAD_CHECK=1` guard immediately after `require("@aws-sdk/client-s3")` that prints a concise success line and exits `0` before `loadEnv()`, token lookup, S3 client construction, or any Paperclip/R2 calls.
5. Run `CAREER_RECONCILE_LOAD_CHECK=1 scripts/career-reconcile.sh` from the `koenig-ai-org` repo and capture the exact success output; if it still fails, include the exact import/resolver error and stop.
6. Comment on KOEA-9840 with exactly what changed: either no package files changed plus the `pnpm install --frozen-lockfile` runtime action, or the specific unexpected source file delta; include the exact load-check command and output.

## Verification (QA Verifier checks these)
- [ ] `learnova-academy/package.json` and `learnova-academy/pnpm-lock.yaml` are unchanged when they already contain `@aws-sdk/client-s3@3.1064.0`.
- [ ] The live `createRequire("/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json").resolve("@aws-sdk/client-s3")` command resolves to a `learnova-academy/node_modules/.pnpm/@aws-sdk+client-s3@3.1064.0/...` path after any install refresh.
- [ ] `CAREER_RECONCILE_LOAD_CHECK=1 scripts/career-reconcile.sh` exits `0` and prints the load-check success line without requiring `.env.koenig`, R2 credentials, or a Paperclip board token.
- [ ] KOEA-9840 has a handoff comment naming repo/files or environment action plus the exact verification result.

## Risk
- The scheduler may run from a different checkout than `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`; mitigate by recording the exact resolver path and, if it differs, applying the same frozen install refresh in the scheduler's package context before claiming repair.

## Out of scope
- No Convex deploy, portal UI change, Career Compass domain change, AWS SDK version downgrade, or broad package manager migration.
