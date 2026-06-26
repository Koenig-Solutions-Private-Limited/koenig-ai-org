---
ticket: KOEA-8594
planner_issue: KOEA-8595
planner: planner
date: 2026-06-15
estimated_complexity: small
estimated_token_cost: $0.34
base_branch: master
basebranch_verified: true
resolved_chain_alert: e3769442-7996-4930-ad84-879dee1e3d67
---

# Plan: Add IndexNow POST to publish-action Phase 2

## Goal
Every successful organic academy publish should notify IndexNow with the exact `academy.kspl.tech` URL that `publish-action.sh` has just marked live. Success is observable in `~/.paperclip/logs/publish-action.log`, a mocked smoke test, and the unchanged Paperclip publish metadata/G5 handoff path.

## Context
- Files to read first: `scripts/publish-action.sh:31-96`, `scripts/publish-action.sh:599-746`, `scripts/press-publish-ping.mjs:13-49`, `scripts/smoke/publish-action-published-url.sh:15-22`, `README.koenig.md:160-181`, `companies/learnova-academy/ARCHITECTURE.md:463-530`.
- Relevant prior work: KOEA-8593 verified the ownership key file is already live at `https://academy.kspl.tech/e295e26297adb46e2256b70ef90df085.txt`; one-shot bulk submission of 281 sitemap URLs already happened on 2026-06-15; `scripts/press-publish-ping.mjs` is an existing IndexNow pattern for the separate Career Compass domain; PR #118 / commit `e989f6409` added the organic-vs-career dispatch split.
- Constraints: keep this in `koenig-ai-org` on verified `origin/master`; do not touch learnovaBeast for the key file; do not run live publish dispatch while verifying; do not introduce secrets; skip `academy.koenig-solutions.com` URLs because Career Compass has its own host/key path; check `.claude`/worktree lock state before editing `scripts/publish-action.sh`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Hook IndexNow into the existing Phase 2 `success)` branch immediately after `publish_state=published` is patched and before the G5 publish-verifier invoke. At that point `publish-action.sh` already knows `TRACK` and `PUBLISHED_URL`, so the implementation can submit exactly one newly-live organic URL, skip career URLs, and keep IndexNow failure non-fatal to the publish state machine.

**Rejected**: Submit in Phase 1 after `repository_dispatch` because the URL may not be live yet. **Rejected**: Daily full-sitemap cron because KOEA-8593 asked for recurring publish-triggered pings and the 281-URL one-shot was already handled manually. **Rejected**: Put this in learnovaBeast because the current durable publish ownership is the koenig-ai-org `publish-action.sh` daemon.

## Steps (Executor follows in order)
1. In a clean topic branch from verified `origin/master`, inspect `git status --short scripts/publish-action.sh README.koenig.md companies/learnova-academy/ARCHITECTURE.md scripts/smoke` and check for relevant `.claude` lock files before editing; do not proceed if another active lock owns `scripts/publish-action.sh`.
2. Add IndexNow constants and helpers near `scripts/publish-action.sh:31-96`: `INDEXNOW_HOST=academy.kspl.tech`, `INDEXNOW_KEY=e295e26297adb46e2256b70ef90df085`, `INDEXNOW_KEY_LOCATION=https://academy.kspl.tech/e295e26297adb46e2256b70ef90df085.txt`, `indexnow_should_submit_url`, and `submit_indexnow_url`.
3. Implement `submit_indexnow_url` with a JSON payload exactly shaped as `{"host":"academy.kspl.tech","key":"e295e26297adb46e2256b70ef90df085","keyLocation":"https://academy.kspl.tech/e295e26297adb46e2256b70ef90df085.txt","urlList":["<published-url>"]}`. Use structured JSON generation, `curl` POST to `https://api.indexnow.org/indexnow` with `Content-Type: application/json`, `--retry 2 --retry-delay 2 --connect-timeout 10 --max-time 30`, accept HTTP `200` or `202`, log status/body excerpt, and treat all failures as `WARN` without changing `publish_state` or blocking G5.
4. Call `submit_indexnow_url "$PUBLISHED_URL"` inside the Phase 2 `success)` branch after the Paperclip metadata PATCH. The helper must no-op for non-`https://academy.kspl.tech/` URLs and log an explicit skip for career-track URLs.
5. Add a real non-mutating verification path: either `--self-test-indexnow` in `scripts/publish-action.sh` plus `scripts/smoke/publish-action-indexnow.sh`, or an equivalent smoke that invokes the helper with a mocked curl binary. The smoke must assert the exact payload, `200` and `202` success handling, non-2xx warning behavior, career URL skip behavior, and no Phase 0 git sync / GitHub dispatch / Paperclip PATCH.
6. Update the runbook docs in `README.koenig.md` Operations basics, and optionally the G5 section in `companies/learnova-academy/ARCHITECTURE.md`, to state that Phase 2 now sends a non-secret IndexNow POST for organic `academy.kspl.tech` publishes and logs success/failure in `publish-action.log`.
7. Open the implementation PR with only `scripts/publish-action.sh`, the new smoke script, and the doc update(s). Include the lock check result, the mocked payload excerpt, and note that the key is public/non-secret and already hosted live.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/publish-action.sh scripts/smoke/publish-action-indexnow.sh` passes.
- [ ] `bash scripts/smoke/publish-action-indexnow.sh` passes without real network calls, git commit/push, GitHub dispatch, or Paperclip mutations.
- [ ] The mocked request payload contains exactly `host`, `key`, `keyLocation`, and a one-item `urlList` for an organic `https://academy.kspl.tech/...` URL.
- [ ] Mocked HTTP `200` and `202` are logged as accepted; mocked `400`/`500` or curl failure logs `WARN` and exits the helper non-fatally.
- [ ] A mocked `https://academy.koenig-solutions.com/...` URL is skipped and does not call IndexNow.
- [ ] Docs mention the log location and non-secret key handling.

## Risk
- IndexNow outages or 4xx responses could otherwise wedge the publish pipeline. Mitigation: make the POST best-effort, retry only transiently, log the sanitized response, and never change `publish_state=published` or the G5 invoke based on IndexNow failure.

## Out of scope
- Regenerating or moving the ownership key file, repeating the 281-URL bulk submit, adding a full-sitemap cron, changing `published_url_for_slug` path semantics, changing Career Compass IndexNow behavior, changing GitHub dispatch workflows, or doing any live publish from this planning ticket.

## Pre-flight
- status_verified=true
- planner_chain_alert_resolved=e3769442-7996-4930-ad84-879dee1e3d67
- acceptance_spec=description_has_concrete_scope_and_done_when
- basebranch_verified=true origin/master
- basebranch_verified_learnovaBeast=true origin/academy/redesign-v1
