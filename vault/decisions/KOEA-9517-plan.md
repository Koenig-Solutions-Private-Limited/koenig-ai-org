---
ticket: KOEA-9517
planner: planner
date: 2026-06-27
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: master
basebranch_verified: true
triggered_by_approval: cf054b72-9035-4ed0-9dc2-9ca7f1e1c7d6
---

# Plan: Permanent GSC token fix for daily Search Console reporting

## Goal
Make the GSC daily daemon stop depending on a weekly-expiring installed-app refresh token. Success means the operator provisions one durable Google credential path, Executor wires `gsc-daily.py` to use it without committing secrets, and the report command exits 0, writes the daily vault report, and remains valid beyond 8 days without manual re-auth.

## Context
- Files to read first: `/paperclip/.claude/scripts/gsc-daily.py:7-24`, `/paperclip/.claude/scripts/gsc-daily.py:34-115`, `/paperclip/.claude/skills/seo/scripts/google_auth.py:64-148`, `/paperclip/.claude/skills/seo/scripts/google_auth.py:288-331`, `/paperclip/.claude/skills/seo/scripts/gsc_query.py:41-50`, `vault/marketing/seo/gsc-daily-2026-06-10.md:1-44`
- Relevant prior work: KOEA-7345 is the blocked GSC credential provisioning branch; KOEA-9517 records `invalid_grant: Token has been expired or revoked` on 2026-06-27; chain-depth approval `cf054b72-9035-4ed0-9dc2-9ca7f1e1c7d6` authorizes this plan as legitimate parallel work.
- Constraints: do not write secrets to git or vault; keep the fix in the BE/ops runtime path unless inspection proves a repo patch is required; `origin/master` exists for `koenig-ai-org`; `learnovaBeast` production base `academy/redesign-v1` exists; do not touch `learnova-student`, `learnova-sales`, or `learnova-admin`; if Convex deployment is unexpectedly required, only run it from `learnova-tc` after explicit human confirmation.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Service-account daemon credential. The current script loads `/paperclip/.secrets/gsc-client.json` as an installed OAuth client and refreshes `/paperclip/.secrets/gsc-token.json` in place, which matches the weekly `invalid_grant` failure pattern. The SEO helper stack already supports service accounts through `GOOGLE_APPLICATION_CREDENTIALS` or `~/.config/claude-seo/google-api.json`; Executor should reuse that loader or the same service-account pattern in `gsc-daily.py`, then write the markdown report from the fetched GSC data.

**Rejected**: Publish OAuth consent screen to In production and re-auth once - acceptable fallback if the operator cannot grant a service account, but it keeps an interactive user-token dependency for a daemon; keep manual weekly re-auth - rejected because it fails the >8 day durability requirement.

## Steps (Executor follows in order)
1. Confirm the operator-selected path before editing: primary is service account, requiring a Google Cloud service-account JSON stored outside git plus that `client_email` added in Search Console for `https://academy.kspl.tech/` as Full or Restricted; fallback is OAuth consent screen set to In production plus one fresh re-auth.
2. In the BE/ops runtime workspace, inspect only redacted credential metadata for `/paperclip/.secrets/gsc-client.json`, `/paperclip/.secrets/gsc-token.json`, any service-account JSON path, and `~/.config/claude-seo/google-api.json`; never print or copy token, private-key, auth-code, or client-secret values.
3. Update `/paperclip/.claude/scripts/gsc-daily.py` to build the Search Console service from the durable credential path: prefer importing/reusing `/paperclip/.claude/skills/seo/scripts/google_auth.py` service-account/OAuth fallback behavior, or implement equivalent local logic if import-path coupling is unsafe.
4. Add or preserve report writing so the command creates `vault/marketing/gsc/<YYYY-MM-DD>.md` with the same core sections currently represented in `vault/marketing/seo/gsc-daily-2026-06-10.md`; if the existing SEO folder remains canonical, write a compatibility copy or symlink only after confirming with Chief Marketing/SEO.
5. Run `python3 /paperclip/.claude/scripts/gsc-daily.py` and fix only credential/report-writer defects needed for it to exit 0; if Google returns 403, stop and ask the operator to add the chosen principal to the Search Console property rather than changing application code.
6. For the fallback OAuth path only, have the operator publish the OAuth consent screen to In production, re-auth once, then rerun the same command and record the new token file metadata without exposing token contents.
7. Hand off with verification notes, including the exact credential mode used, the created report path, and a scheduled follow-up check after 2026-07-05 to prove the credential survived more than 8 days without re-auth.

## Verification (QA Verifier checks these)
- [ ] `python3 /paperclip/.claude/scripts/gsc-daily.py` exits 0 without `invalid_grant`.
- [ ] A daily report exists at `vault/marketing/gsc/<YYYY-MM-DD>.md` for the run date and includes data windows, Search Analytics page/query sections, sitemap data, and URL inspection results or explicit per-URL errors.
- [ ] Redacted credential inspection shows the active path is either a service account configured through `GOOGLE_APPLICATION_CREDENTIALS` or `~/.config/claude-seo/google-api.json`, or an OAuth app that the operator confirms is In production.
- [ ] A delayed check after 2026-07-05 reruns the command successfully without another manual re-auth.

## Risk
- Google Search Console permissions remain operator-owned; if the service account is not added to the `https://academy.kspl.tech/` property, Executor will see 403s even with correct code. Mitigation: stop on 403, report the exact principal/property mismatch, and do not rotate credentials repeatedly.

## Out of scope
- Learnova portal edits, student/sales/admin changes, SEO strategy changes, GA4 provisioning, IndexNow work, and Convex deployment unless Chief Engineering opens or confirms a separate implementation ticket.
