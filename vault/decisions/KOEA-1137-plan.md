---
title: KOEA-1137 plan — stale Academy publish states blocking G5
date: 2026-05-12
author: planner
ticket: KOEA-1137
parent: KOEA-1137
planner_ticket: KOEA-1139
tags: [plan, publish-action, publish-verifier, g5, academy, koea-1137]
status: ready-for-review
revision: r2
revision_note: "2026-05-26 plan-audit request resolved: published_url is mandatory slug URL scope"
---

# Plan: unblock G5 by fixing the publish pipeline + classifying 6 stale candidates

## Problem statement (from KOEA-1137)

Publish Verifier poll (KOEA-1131) reports **zero issues** with
`metadata.publish_state=published`, so G5 has no target to verify, yet six
issues remain "upstream stale" at `g4-approved` or `ready`:

| Key       | publish_state | Title                                                      |
|-----------|---------------|------------------------------------------------------------|
| KOEA-353  | g4-approved   | Publish blog: GPT-5.5 in Codex (slug=`2026-04-30-gpt-5-5-in-codex`) |
| KOEA-352  | g4-approved   | Publish blog: Anthropic creative connectors (slug=`2026-04-30-anthropic-creative-connectors`) |
| KOEA-368  | ready         | Blog G3: opus-4-7-long-running-coding-benchmark (no slug)  |
| KOEA-369  | ready         | Blog G3: gpt-5-5-in-codex (no slug)                        |
| KOEA-64   | ready         | G0 review: GPT-5.5 in Codex blog (no slug)                 |
| KOEA-344  | ready         | Course delta: open-vs-closed LLM framing (no slug)         |

KOEA-1137 asks us to: (1) inspect the publish path, (2) explain the absence of
published states, (3) classify each candidate, (4) name the smallest
implementation + verification path.

## Investigation summary

### Publish pipeline as designed (`scripts/publish-action.sh`)

- **Cadence**: launchd plist `infra/launchd/com.koenig.publish-action.plist`,
  `StartInterval=60`, runs `scripts/publish-action.sh`.
- **Phase 1**: lists issues where `status=done` AND
  `metadata.publish_state=g4-approved`, fires GitHub `repository_dispatch`
  (`event_type=publish-ready`, `client_payload={issue_id,slug}`) at
  `Koenig-Solutions-Private-Limited/learnovaBeast`, then PATCHes
  `metadata.publish_state=dispatching` + `dispatched_at`.
- **Phase 2**: for `publish_state=dispatching`, polls
  `/repos/.../actions/runs?event=repository_dispatch`, matches by
  `display_title == "publish-{issue_id}"` and `created_at >= dispatched_at`,
  then PATCHes either:
  - `success` → `publish_state=published`,
    `published_url=https://academy.kspl.tech/blog/<slug>`,
    `published_at=<now>`, and POSTs to the publish-verifier heartbeat to trigger G5.
  - `failure|cancelled|timed_out|action_required|startup_failure` →
    `publish_state=dispatch_failed` + `dispatch_failure_reason`.
- **Auth deps**: requires `GH_PAT_DISPATCH` in `.env.koenig` (repo+workflow scopes
  on learnovaBeast). The script logs and skips both phases if it is missing.

### Why `publish_state=published` count is 0

Cross-checked against the running Paperclip instance and the host filesystem:

1. **The launchd job is not loaded.**
   - `~/Library/LaunchAgents/com.koenig.publish-action.plist` does not exist.
   - `launchctl list | grep publish` returns nothing.
   - `~/.paperclip/logs/publish-action.log` does not exist — the script has
     never logged a single run. `load-launchd-agents.sh` lists `publish-action`
     in its `PLISTS` array but was never executed.

2. **`GH_PAT_DISPATCH` is missing from `.env.koenig`.**
   `.env.koenig` currently contains only `PAPERCLIP_BOARD_TOKEN` and
   `PAPERCLIP_API_KEY`. Even if the launchd job were running, Phase 1/2 would
   log `SKIPPED — GH_PAT_DISPATCH not set` and exit early.

3. **`publish-action.sh` does not authenticate to the Paperclip API.**
   `/api/companies/$COMPANY_ID/issues` now returns HTTP 401 without a Bearer
   token. The script's `curl -s` calls have no `Authorization: Bearer ...`
   header, so when the job *does* run it will get an empty list and PATCH
   nothing. This was likely a regression from the Docker migration that
   tightened API auth (see memory: docker-migration-state 2026-04-30).

4. **`COMPANY_ID` is hardcoded and may be wrong post-Docker.**
   `publish-action.sh` line 18 pins
   `COMPANY_ID=1ce472ae-c3fe-47cb-ae1c-99cd79a43b8d`, but the live agent
   environment is `PAPERCLIP_COMPANY_ID=2a77f89b-33f0-4133-a20c-77ddaac5e744`
   (where KOEA-352 / KOEA-353 actually live, verified by API query). Hardcoding
   the wrong company yields an empty page even with auth.

5. **No fallback path.** There is no manual "advance to published" or "clear
   stale publish_state" tool, so once items get stuck in `g4-approved`/`ready`
   they accumulate.

The net effect: g4-approved tickets sit forever, no dispatches happen, no
`dispatching` rows exist, no `published` rows exist, G5 starves.

### Vault content check

- `vault/blogs/2026-04-30-gpt-5-5-in-codex/draft.md` exists with
  `ticket: KOE-52`, `vendor_tag: openai`. Slug matches KOEA-353.
- `vault/blogs/2026-04-30-anthropic-creative-connectors/draft.md` exists with
  `ticket: KOEA-24`, `vendor_tag: anthropic`. Slug matches KOEA-352.

So both publish tickets have real source material in the vault — they are not
phantoms.

### Live URL check (deferred — not yet confirmed by me)

Before the implementation tickets are filed, the engineering executor must
probe whether either slug is already deployed:

```bash
curl -sI -o /dev/null -w "%{http_code}\n" \
  https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex
curl -sI -o /dev/null -w "%{http_code}\n" \
  https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors
```

The result branches the remediation (see classification below). Network egress
from the agent container is unreliable in this run, so this probe is captured
as the first executor step rather than as a planner finding.

## Classification of the 6 stale candidates

The candidates split cleanly into two cohorts: **publish tickets** (real
deploy targets with a slug and matching vault content) and **upstream review
tickets** (review/authoring tickets that should never have inherited a
`publish_state` field). Verifier behaviour is documented in
`companies/learnova-academy/skills/verify-publish/SKILL.md` — the
"Pre-flight gate" requires `publish_state=published` AND a live URL, so
upstream-mislabelled tickets actively poison the G5 queue.

### Cohort A — legitimate publish tickets (advance or dispatch)

| Key      | Slug                                          | Treatment                                    |
|----------|-----------------------------------------------|----------------------------------------------|
| KOEA-353 | 2026-04-30-gpt-5-5-in-codex                   | Live? → advance to `published`. 404? → dispatch. |
| KOEA-352 | 2026-04-30-anthropic-creative-connectors      | Live? → advance to `published`. 404? → dispatch. |

Treatment detail:
- If `curl -sI .../blog/<slug>` returns 200 → manually PATCH:
  `metadata.publish_state=published`,
  `metadata.published_url=https://academy.kspl.tech/blog/<slug>`,
  `metadata.published_at=<now>`. Then POST the publish-verifier heartbeat
  (`/api/agents/<publish-verifier-id>/heartbeat/invoke` with
  `context.issue_id=<id>`) so G5 picks it up immediately.
- If 404 → leave at `g4-approved`. After the publish-action fixes land,
  the next launchd tick will dispatch it via `repository_dispatch` and Phase 2
  will flip it to `published`. No manual mutation needed.

### Cohort B — upstream / mis-classified tickets (clear publish_state)

| Key      | True role                  | Treatment                                            |
|----------|----------------------------|------------------------------------------------------|
| KOEA-368 | Blog G3 review             | Clear `metadata.publish_state` (set to null). Reopen if review work is outstanding; close as `done` (no publish_state) if it was already actioned via a separate publish ticket (e.g. a future KOEA-3xx Publish blog ticket for `opus-4-7-long-running-coding-benchmark`). |
| KOEA-369 | Blog G3 review             | Same. The matching publish ticket for this slug is **KOEA-353** — KOEA-369 should not duplicate that lane. |
| KOEA-64  | G0 review                  | Clear `metadata.publish_state`. G0 review work belongs to chief-content's queue, not publisher's. |
| KOEA-344 | Course-delta authoring     | Clear `metadata.publish_state`. Course deltas publish via a different workflow (course-author → G3 → G4 human) and do not flow through `publish-action.sh` blog-dispatch at all. |

Rationale: every Cohort B ticket has `slug=None`, `published_url=None`, and a
title that names a *review or authoring* step. They were almost certainly
flagged with `publish_state=ready` by an earlier metadata-bootstrapping pass
that over-applied the field. Leaving them as-is keeps tripping KOEA-1131 false
positives and (per the verify-publish SKILL pre-flight gate) keeps surfacing
phantom G5 SKIPs.

## Implementation changes needed

Smallest viable patchset (do **not** implement in this ticket — file the
subtasks under KOEA-1137 once this plan is plan-audited):

### 1. `scripts/publish-action.sh` — four concrete edits

a. **Add auth to every Paperclip API call.** Source `PAPERCLIP_BOARD_TOKEN`
   (or `PAPERCLIP_API_KEY`) from `.env.koenig` and pass it on each `curl`:

   ```bash
   PAPERCLIP_BOARD_TOKEN="$(grep '^PAPERCLIP_BOARD_TOKEN=' "$ENV_FILE" | cut -d= -f2-)"
   AUTH_HEADER=(-H "Authorization: Bearer $PAPERCLIP_BOARD_TOKEN")
   # then: curl -s "${AUTH_HEADER[@]}" "$PAPERCLIP_URL/api/..."
   ```

   Bail with a loud log line if the token is missing — quiet failure is what
   masked this for two weeks.

b. **De-hardcode `COMPANY_ID`.** Replace
   `COMPANY_ID="${COMPANY_ID:-1ce472ae-...}"` with
   `COMPANY_ID="$(grep '^COMPANY_ID=' "$ENV_FILE" | cut -d= -f2-)"` and
   require it to be set, or read from `PAPERCLIP_COMPANY_ID` if exported.
   Document the canonical value (`2a77f89b-33f0-4133-a20c-77ddaac5e744`) in
   `.env.example`.

c. **Surface skipped runs.** When `GH_PAT_DISPATCH` is missing, log a single
   `WARN: skipping — fix .env.koenig` line **and** also write a sentinel file
   under `~/.paperclip/logs/publish-action.skipped` so the watchdog can alert.

d. **Set slug-specific published URLs.** In Phase 2 success handling, write
   `metadata.published_url=https://academy.kspl.tech/blog/<slug>` using the
   issue slug that Phase 1 already dispatches. This is mandatory implementation
   scope, not a reviewer choice: G5's pre-flight probe should be able to `curl`
   the stored URL directly without deriving a blog path from separate metadata.

No structural rewrite is needed — the two-phase polling design is sound; only
the auth/config/url plumbing is broken.

### 2. `.env.koenig`

Add (locally, do not commit values):

```
GH_PAT_DISPATCH=<PAT with repo + workflow scopes on Koenig-Solutions-Private-Limited/learnovaBeast>
COMPANY_ID=2a77f89b-33f0-4133-a20c-77ddaac5e744
# PAPERCLIP_BOARD_TOKEN already present
```

Document additions in `.env.example` with placeholder values.

### 3. Install / activate the launchd job

```
./scripts/load-launchd-agents.sh publish-action
```

Confirm via `launchctl list | grep publish-action` and tail
`~/.paperclip/logs/publish-action.log`.

### 4. One-shot metadata cleanup script

Add `scripts/cleanup-stale-publish-states.sh` (idempotent, dry-run-default)
that walks all issues with `publish_state` set, splits into Cohort A / Cohort
B by presence of `metadata.slug` + matching `vault/blogs/<slug>/draft.md`, and
prints proposed PATCHes. `--apply` actually issues them. Run once to clean the
6 candidates; keep it on shelf for future regressions.

### 5. learnovaBeast workflow assertion (read-only check)

The Phase 2 poll matches GH Actions runs by `display_title == "publish-{issue_id}"`.
Confirm `Koenig-Solutions-Private-Limited/learnovaBeast/.github/workflows/<X>.yml`
has `on: repository_dispatch: types: [publish-ready]` and that the
workflow's `name` (or first job `name`) renders the run title as
`publish-<issue_id>`. If it doesn't, Phase 2 will always log `not_found` and
KOEA-353/352 will stick at `dispatching` forever. **No edit yet** — confirm
first, file a follow-up if mismatched. (The fe-agent worktree is the
designated read path:
`~/Documents/Paperclip/learnovaBeast-fe-agent/.github/workflows/`.)

## Convex / portal constraints

Per CLAUDE.md + KOEA-1137 acceptance:

- **Deploy code only from `learnova-tc`** (the toolchain repo). All
  Convex/Vercel publish wiring is centralised there; the `learnovaBeast`
  repo's GitHub Actions workflow is its public entry point.
- **Do not modify unrelated portals.** Avoid touching
  `learnova-careers`, `learnova-blog-internal`, or any sibling product
  portals when patching the publish workflow.
- **Do not run any Convex deploy from this fix.** This ticket is about
  Paperclip-side metadata + dispatcher plumbing, not Academy frontend
  shipping. If the executor finds a Convex/Vercel auth gap during step 1's
  live-URL probe, route to chief-engineering as a separate KOEA-xxx ticket
  rather than fixing in-band here.

## Smallest verification path

1. **Pre-verify live state** (read-only):
   ```bash
   for SLUG in 2026-04-30-gpt-5-5-in-codex 2026-04-30-anthropic-creative-connectors; do
     curl -sI -o /dev/null -w "%{http_code} $SLUG\n" \
       "https://academy.kspl.tech/blog/$SLUG"
   done
   ```
2. **Patch script + env** (changes 1+2 above).
3. **Manual one-shot**: `bash scripts/publish-action.sh` and inspect
   `~/.paperclip/logs/publish-action.log` for one full Phase 1+2 cycle.
4. **Backfill / clean**: run `scripts/cleanup-stale-publish-states.sh --apply`.
   Expected diffs:
   - Cohort A (KOEA-353, KOEA-352): either now `published` (live-URL path) or
     `dispatching` then `published` after one launchd tick.
   - Cohort B (KOEA-368, KOEA-369, KOEA-64, KOEA-344): `publish_state` cleared.
5. **Activate launchd**: `./scripts/load-launchd-agents.sh publish-action`.
6. **Re-poll**: re-run KOEA-1131 (Publish Verifier poll). Expected:
   - ≥1 issue with `publish_state=published` (so G5 has a target).
   - 0 issues with `publish_state in (g4-approved, ready)` for the stale six.
7. **End-to-end gate**: G5 (publish-verifier) auto-fires for KOEA-353/352;
   look for `✅ G5 PUBLISH VERIFIED` or a structured BLOCK on each.

Acceptance is met when steps 6+7 hold; KOEA-1137 closes when KOEA-1131's next
poll shows green.

## Out of scope

- Refactoring `publish-action.sh` to a typed Node script (deferred — file
  separately if the bash version regresses again).
- Adding course-delta auto-publish — different workflow, separate ticket.
- Any change to `learnova-careers` or other portals.
- Touching G0 / G3 / G4 routing logic itself — verifier pre-flight gate
  already handles `publish_state != published` correctly; the bug is that
  Cohort B never should have carried `publish_state` to begin with.

## Suggested subtask split (for KOEA-1137 implementation)

Create as children of KOEA-1137 after plan-audit:

1. **KOEA-1137a** — eng: patch `scripts/publish-action.sh` (auth header,
   de-hardcoded company id, loud skip logging, slug-specific `published_url`)
   + update `.env.example`.
2. **KOEA-1137b** — host (Vardaan): add `GH_PAT_DISPATCH` and `COMPANY_ID`
   to `.env.koenig`; run `load-launchd-agents.sh publish-action`. Depends on
   KOEA-1137a.
3. **KOEA-1137c** — eng: add `scripts/cleanup-stale-publish-states.sh`
   (dry-run + `--apply`) and run it once. Depends on KOEA-1137b (so dispatched
   tickets aren't clobbered mid-flight).
4. **KOEA-1137d** — eng: read-only audit of learnovaBeast
   `repository_dispatch` workflow; confirm run display_title matches
   `publish-<issue_id>`. File a follow-up if not.
5. **KOEA-1137e** — verify: re-run KOEA-1131; confirm green; close KOEA-1137.

Each is small enough for a single executor heartbeat. KOEA-1137a and
KOEA-1137d are independent and can run in parallel.

## Plan-audit notes

Resolved per KOEA-1141 feedback on 2026-05-26: `published_url` must carry the
slug path. The executor must change Phase 2 to store
`https://academy.kspl.tech/blog/<slug>` on successful dispatch or manual
advance; bare `https://academy.kspl.tech` is not acceptable because G5 needs a
directly probeable URL.

Remaining questions:

1. Is the canonical company UUID `2a77f89b-33f0-4133-a20c-77ddaac5e744`
   universal across local + Docker instances, or per-environment? If the
   latter, the script must read it from `$PAPERCLIP_COMPANY_ID` at runtime
   rather than `.env.koenig`.
2. Are there any other vault slugs already deployed but missing the
   matching Paperclip publish ticket? A full inventory pass
   (`vault/blogs/*` vs Paperclip `publish_state` table) would tell us
   whether the six candidates are the entire backlog or a sample.
