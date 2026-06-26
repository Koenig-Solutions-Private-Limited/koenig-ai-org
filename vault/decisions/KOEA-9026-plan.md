---
ticket: KOEA-9026
planner: planner
date: 2026-06-22
estimated_complexity: medium
estimated_token_cost: $0.45
repo: Koenig-Solutions-Private-Limited/koenig-career-academy
base_branch: main
basebranch_verified: true
---

# Plan: Fix Career Compass CV analyze/email/lifecycle failures

## Goal
Career Compass CV analysis should either persist a report and navigate the user to a working `/career/r/{token}` page, or stop with a clear recoverable error before claiming success. The executor should also identify whether the `email.failed` and `lifecycle.failed` events are code defects or Resend/cron configuration blockers, then patch the smallest safe code path or report the exact external config needed.

## Context
- Files to read first: `src/app/api/career/analyze/route.ts:200-441`, `src/lib/career/store.ts:63-83`, `src/lib/r2.ts:22-88`, `src/app/api/career/subscribe/route.ts:36-79`, `src/app/api/career/check-requests/route.ts:12-110`, `src/app/api/career/lifecycle/route.ts:99-303`, `src/components/career/CareerWizard.tsx:113-181`
- Relevant prior work: KOEA-9018 verified R2/log provenance: retained CV objects under `career/cv/{token}.{ext}`, reports under `career/r/{token}/report.json`, logs under `career/log/YYYY-MM-DD/*.json`; rolling window ending `2026-06-22T11:25:41.942Z` showed 2 retained PDF uploads, 0 reports, 2 `analyze.failed`, 10 `email.failed`, and 10 `lifecycle.failed`. Recent repo PRs #1, #3, and #5 were SEO/content surface changes and did not touch these routes.
- Constraints: scope is only `Koenig-Solutions-Private-Limited/koenig-career-academy` and `academy.koenig-solutions.com`; do not use `academy.kspl.tech` data. Work from `main` (verified by `git ls-remote --heads ... main`, SHA `2d9a223ace1973cd98378aabdb70e0c06d4602f2`). If production R2/Vercel/Resend credentials are unavailable, document the exact missing secret/right instead of fabricating verification.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Fix the explicit failure boundary in the analyzer first, then verify email/lifecycle from logged error detail. The source shows `saveReport(report)` can return `false` while `/api/career/analyze` still emits `{done:true, url, persisted:false}` and `CareerWizard` redirects on any `done` URL, which can produce a user-facing report link with no report behind it. Treat report persistence failure as a real `analyze.failed` at a new persistence stage or equivalent recoverable error, and use R2 event log details to decide whether Resend failures are code-level sender/default issues or external configuration.

**Rejected**: Add broad retry queues around every R2 and Resend write — too large for the VIP repair and can duplicate emails without a durable idempotency design. **Rejected**: Change analytics/PostHog instrumentation first — KOEA-9018 already showed PostHog would undercount failed uploads and this ticket is about operational failure. **Rejected**: Guess the Resend fix from source alone — the logs already record `email.failed` details, so executor should confirm whether the blocker is sender-domain verification, API key, cron auth, or another Resend response.

## Steps (Executor follows in order)
1. Create a work branch from the verified target branch: clone or update `Koenig-Solutions-Private-Limited/koenig-career-academy`, checkout `main`, then branch `fix/KOEA-9026-career-failures`; do not touch `koenig-ai-org` except for reporting.
2. Inspect production Career Compass evidence only: read R2 `career/log/2026-06-17/*.json` plus current `career/log/YYYY-MM-DD/*.json` entries for `analyze.failed`, `email.failed`, and `lifecycle.failed`; if unavailable, stop and report the missing `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_R2_ACCESS_KEY_ID`, `CLOUDFLARE_R2_SECRET_ACCESS_KEY`, bucket access, or Vercel log access needed.
3. Patch `src/app/api/career/analyze/route.ts` so report persistence is a hard success boundary: set an explicit persistence stage before `saveReport(report)`, and if `saveReport` returns `false`, log `analyze.failed` with token/stage/error and emit a clear retryable error instead of `{done:true}`. Keep CV file upload best-effort unless logs prove CV upload itself is the root cause.
4. Patch only the email route(s) implicated by the R2 log details. If failures show Resend sender/API configuration, prefer documenting the exact Vercel env or Resend domain blocker; if source defaults are causing the failure, update the affected Career Compass route(s) such as `src/app/api/career/subscribe/route.ts`, `src/app/api/career/check-requests/route.ts`, and/or `src/app/api/career/lifecycle/route.ts` to use a verified sender default or shared helper without expanding beyond Career Compass.
5. If lifecycle marker writes fail after a successful send, make `src/app/api/career/lifecycle/route.ts` log a distinct failure event with token/stage and avoid claiming plain `"sent"` without marker status; this prevents silent repeated lifecycle sends.
6. Add the smallest local verification available in this repo: run `pnpm install` if needed, then `pnpm typecheck` and `pnpm test`; for behavior, run a local or preview `/api/career/analyze` smoke with a pasted CV/job when `ANTHROPIC_API_KEY` and R2 env are available, or document that live smoke is blocked by the exact missing credential.
7. Report back on KOEA-9026 with changed repo paths, branch/PR URL, the analyzed log error details, verification commands/results, and any unresolved operator credential/config action.

## Verification (QA Verifier checks these)
- [ ] A CV analysis that reaches model completion no longer returns `{done:true}` unless `career/r/{token}/report.json` is actually persisted, or it emits a user-visible recoverable error before redirect.
- [ ] The two rolling-window `analyze.failed` events have a named stage/error from Career Compass logs, and the fix addresses that stage or documents the exact external blocker.
- [ ] `email.failed` and `lifecycle.failed` are either reduced by a code fix in the implicated routes or tied to a precise Resend/Vercel config blocker with the needed secret/right named.
- [ ] `pnpm typecheck` and `pnpm test` pass in `koenig-career-academy`, or any skipped smoke is justified by missing production credentials.

## Risk
- A failed report persistence after expensive model calls can still frustrate users; mitigation is to make the failure explicit and retryable now, and leave durable retry/outbox design out of this hotfix unless Chief Engineering opens a separate reliability ticket.

## Out of scope
- No academy.kspl.tech metrics, no PostHog/GSC/GA4 restoration, no analytics funnel redesign, no broad email marketing/lifecycle rewrite, and no changes outside `Koenig-Solutions-Private-Limited/koenig-career-academy`.
