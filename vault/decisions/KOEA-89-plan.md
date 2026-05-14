---
ticket: KOEA-89
planner: planner
date: 2026-04-30
estimated_complexity: medium
estimated_token_cost: $0.30
---

# Plan: GitHub-trigger publish path (V3-7)

## Goal

Replace the 5-min launchd polling publish loop with a GitHub Actions-backed pipeline that fires within ≤60s of G4 approval. The Mac host stays as a thin dispatcher; the actual vercel build/deploy moves into GitHub Actions for a portable CI/CD audit trail. Average publish lag target: ~90s (poll wait + GH Actions run time).

## Context

- Files to read first: `scripts/publish-action.sh`, `infra/launchd/com.koenig.publish-action.plist`
- Relevant prior work: V2.6 publish pipeline (current), KOEA-54 parent ticket
- Constraints: launchd stays enabled until GH Actions validated; plist disabled (not deleted) for 2-week safety net; G5 must still fire post-publish

## Approach (1 chosen, alternatives rejected)

**Chosen: Option B — keep launchd polling (60s), delegate build/deploy to GH Actions**

Paperclip's webhook API is inbound-only (`POST /api/routine-triggers/public/{publicId}/fire` fires a Paperclip routine from outside). No native outbound webhook capability on `issue.updated` events exists. Option A (Paperclip outbound webhook → GH dispatch) is not available without upstream Paperclip platform changes.

Reducing `StartInterval` 300s → 60s approaches the ≤90s acceptance criterion: avg ~30s poll wait + ~60s GH Actions run ≈ 90s.

`publish-action.sh` gains a two-phase loop:
- Phase 1: `g4-approved` → GH dispatch API → mark `dispatching` + `dispatched_at`
- Phase 2: `dispatching` → query GH Actions runs API (filter by `run-name` + `created_at`) → mark `published` or `dispatch_failed`; wake G5 on success

GH Actions `publish.yml`: `repository_dispatch` trigger, checkouts learnovaBeast + koenig-ai-org vault, runs vercel build + deploy. No Paperclip callback needed — Phase 2 handles confirmation from local Mac.

**Rejected:**
- Option A (Paperclip outbound webhook): not available in current Paperclip API
- Full local deploy only: no audit trail; Mac host is build bottleneck

## Steps (Executor follows in order)

1. Create GitHub PAT `GH_PAT_DISPATCH` (scopes: `repo`, `workflow`) and add to Mac `.env.koenig`
2. Add GH Actions repo secrets: `VERCEL_TOKEN` and `KOENIG_VAULT_REPO_TOKEN` (read-only on `koenig-ai-org`)
3. Create `learnovaBeast/.github/workflows/publish.yml` — `repository_dispatch` trigger, `run-name` includes `issue_id`, dual-checkout, vercel build + deploy
4. Refactor `scripts/publish-action.sh` — Phase 1 dispatch + Phase 2 confirmation; remove local vercel code
5. Update `infra/launchd/com.koenig.publish-action.plist` — `StartInterval` 300 → 60; reload plist
6. Run full acceptance test (see Verification below)
7. After 2-week validation: add `<key>Disabled</key><true/>` to plist (safety net)

## Verification (QA Verifier checks these)

- [ ] PATCH test issue to `publish_state=g4-approved` → GH dispatch run appears in learnovaBeast Actions within 60s
- [ ] GH Actions run completes with `conclusion=success`; issue `publish_state` flips to `published` within next poll
- [ ] `published_url` + `published_at` set on issue metadata; `academy.kspl.tech/blog/<slug>` serves new content
- [ ] publish-verifier G5 fires after `published` state is set

## Risk

- `koenig-ai-org` is private; `KOENIG_VAULT_REPO_TOKEN` must be a long-lived machine account token or deploy key. Token expiry → silent GH build failures. Mitigation: monitor `dispatch_failed` state.
- Concurrent dispatches: `run-name` in workflow must include `issue_id` to prevent Phase 2 cross-issue false-positives.

## Out of Scope

- Modifying G4 agent to call GitHub dispatch directly
- Paperclip outbound webhook infrastructure (upstream platform change)
- `meeting-follower` AGENTS.md update re: V3-7 public meeting page links
- Next.js on-demand revalidation fast-path
