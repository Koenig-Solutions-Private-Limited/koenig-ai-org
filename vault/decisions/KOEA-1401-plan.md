---
title: KOEA-1401 plan — publish-action vault-sync pending-G4 guard
date: 2026-05-13
author: planner
ticket: KOEA-1401
parent: KOEA-1401
planner_ticket: KOEA-1402
revision_ticket: KOEA-1433
tags: [plan, publish-action, vault-sync, g4-guard, koea-1401]
status: ready-for-review
revision: 2
estimated_complexity: medium
estimated_token_cost: ~$0.40
---

# Plan: guard publish-action Phase 0 against pending-G4 `status: published` flips

## Revision 2 (2026-05-13) — script-topology correction

**Why this revision exists** (KOEA-1433): Revision 1 said to wire the guard
into `scripts/publish-action.sh` Phase 0 between `git add -A vault/` and
`git commit`. Executor (KOEA-1404) correctly observed that the repo's
`scripts/publish-action.sh` has **no Phase 0** — it is V3.0 (commits
`ee1dc85e`, `e33a0cb9`, `df1d4216`, `f413a028`) with only Phase 1+2 dispatch
and poll. Plan deviation was real.

**Substantive cause**: there are **two publish-action scripts** with
divergent lineages:

| Path | Version | Lines | Source | What it does |
|------|---------|-------|--------|--------------|
| `scripts/publish-action.sh` (repo) | V3.0 | 264 | git-tracked; latest fix `df1d4216` | Phase 1 g4-approved→dispatch, Phase 2 dispatch→poll. **No Phase 0.** |
| `/paperclip/scripts/publish-action.sh` (container) | V2 | 212 | **NOT** in any git repo; mtime 2026-05-12 16:38 UTC | Phase 0 vault-sync (lines 101–146), Phase 1 dispatch (148–206); no Phase 2 polling. **This is the script producing the `auto: vault-sync` commits** authored by `Koenig Publish Action <publish-action@kspl.tech>` (e.g. `83f85605`, `1eb0a7e0`). |

The repo launchd plist (`infra/launchd/com.koenig.publish-action.plist`
line 11) points at the repo's V3.0 script, but the **deployed launchd job
on the host runs the V2 container script** (otherwise the bot commits would
have died when V3.0 dropped Phase 0). Repo and runtime are out of sync.

**Revised approach**: instead of editing a container-internal file that is
not git-tracked (no audit trail, no PR), **port the V2 Phase 0 vault-sync
block into the repo's `scripts/publish-action.sh` (V3.0) as the new source
of truth, add the pending-G4 guard inline, then sync the deployed copy**.
Net result: the guard ships, the V2/V3.0 divergence is reconciled, and the
next deploy cycle picks up the repo script. This is a deliberate widening
of scope (≈80–120 extra LOC ported) but the original plan cannot be
executed safely without it.

The detection strategy, decision matrix, default-closed policy, watchdog
issue contract, tests, and verification checks from Revision 1 are
**unchanged** and remain authoritative below. Only the file-target,
hook-point, and a new "port Phase 0 + sync deployed copy" step are revised.

---

## Goal

`scripts/publish-action.sh` Phase 0 vault-sync **must refuse to commit** any
vault frontmatter transition to `status: published` unless the matching
Paperclip issue carries `metadata.publish_state ∈ {g4-approved, dispatching,
published}`. On refusal, leave the offending files staged-but-uncommitted,
emit structured evidence to `publish-action.log`, fire a Telegram alert, and
file a `pending-g4-bypass` watchdog issue so the operator can intervene.
Authorised G4 dispatches (current `g4-approved → published` flow) must
continue to work unchanged. The repo's `scripts/publish-action.sh` becomes
the single source of truth (replacing the un-tracked container V2 copy).

## Context — why we are adding this

### Current Phase 0 flow — actually lives in `/paperclip/scripts/publish-action.sh` (V2, lines 101–146)

Verbatim from the deployed V2 script — the block we are porting into the
repo:

```bash
# ── Phase 0: vault git-sync ──────────────────────────────────────────────────

CURRENT_BRANCH="$(git branch --show-current)"
log "Phase 0: vault-sync starting on branch=$CURRENT_BRANCH"

git config user.email "publish-action@kspl.tech"
git config user.name  "Koenig Publish Action"

VAULT_DIRTY="$(git status --porcelain vault/ 2>&1 | grep -vE '^.. vault/\.obsidian/|\.DS_Store|__pycache__|\.pyc$' || true)"

if [ -z "$VAULT_DIRTY" ]; then
  log "Phase 0: no vault changes — skipping commit"
else
  CHANGE_COUNT=$(echo "$VAULT_DIRTY" | wc -l | tr -d ' ')
  log "Phase 0: $CHANGE_COUNT vault file changes detected"
  git add -A vault/
  git reset HEAD vault/.obsidian/workspace.json 2>/dev/null || true
  git checkout -- vault/.obsidian/workspace.json 2>/dev/null || true
  CHANGED_DIRS="$(git status --porcelain vault/ 2>&1 | awk '{print $2}' | xargs -I{} dirname {} | sort -u | head -10 | tr '\n' ' ')"
  COMMIT_MSG="auto: vault-sync $(date -u +%Y-%m-%dT%H:%M:%SZ)

Files: $CHANGE_COUNT
Dirs: $CHANGED_DIRS

Auto-committed by publish-action.sh V2.
Co-Authored-By: Paperclip-Agents <agents@kspl.tech>"
  if git commit -m "$COMMIT_MSG" 2>&1 | tee -a "$LOG"; then
    log "Phase 0: commit succeeded; pushing origin/$CURRENT_BRANCH"
    if git push origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG"; then
      log "Phase 0: push succeeded ✓"
    else
      log "Phase 0: PUSH FAILED"
      tg_alert "git push origin $CURRENT_BRANCH failed; check $LOG"
    fi
  else
    log "Phase 0: nothing to commit (likely all changes were excluded)"
  fi
fi
```

Also depends on the V2 `tg_alert()` helper (lines 88–97):

```bash
tg_alert() {
  local msg="$1"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=⚠️ publish-action: ${msg}" \
      > /dev/null 2>&1 || true
  fi
}
```

The script **never inspects the contents** of the staged diff. Anything
left dirty on disk by an upstream agent is laundered through the bot
identity `Koenig Publish Action <publish-action@kspl.tech>`.

### The incident this plan addresses (from KOEA-1392 / KOEA-1401)

- 2026-05-13T03:09:47Z — CEO G3 sweep updated six blogs from
  `status: g0-passed` to `status: g3-passed` and filed
  `request_board_approval 5c2e9971-3a35-4a50-b0e3-738797072b50`.
- Between 03:09:47Z and 03:10:18Z, *something* (not publish-action) rewrote
  the same six blogs from `g3-passed` → `published` on disk.
- 2026-05-13T03:10:18Z — publish-action V2 tick. Phase 0 saw 16 dirty vault
  files, `git add -A`-ed all of them, committed `83f85605` and pushed.
  Phase 1 on the same tick logged `no g4-approved issues found`. The board
  approval was still `pending`.
- Net effect: six drafts hit `master` with `status: published` while the G4
  gate had never closed. `git show 83f85605 -- vault/blogs/<slug>/draft.md`
  shows clean one-line `-status: g3-passed / +status: published` deltas.

Phase 1 already gates GitHub dispatch on `metadata.publish_state=g4-approved`
(lines 158–206). The bypass is **not** in dispatch — it is in Phase 0
laundering a `status: published` frontmatter change without checking whether
G4 ever closed.

### Why this matters

- `master` is what learnovaBeast / Vercel deploy from. A premature `published`
  in vault means the Academy frontend would render the post (or 404 in a way
  that fakes deploy-gap signals — see the existing
  `publish-verifier-false-positive` memory).
- Publish Verifier (G5) trusts `publish_state=published` as its target. A
  status flip with no matching `publish_state` mutation creates a permanent
  drift between the vault and the issue board.
- The bot identity on the commit obscures the real writer. Any future audit
  has to dig through reflogs to find the actor.

## Detection strategy — staged-diff-based frontmatter parse

The guard runs **after `git add` and before `git commit`** so it sees exactly
what is about to land. Two-step check per candidate file:

### Step A — enumerate `published` transitions

For every staged file matching `vault/blogs/*/draft.md` or
`vault/courses/**/*.md`:

```bash
# Old frontmatter (from index HEAD, if file existed)
OLD_STATUS=$(git show "HEAD:$F" 2>/dev/null \
  | awk '/^---$/{c++; next} c==1 && /^status:/{print $2; exit}')
# New frontmatter (from worktree/index)
NEW_STATUS=$(awk '/^---$/{c++; next} c==1 && /^status:/{print $2; exit}' "$F")
```

A file is a **transition candidate** iff `NEW_STATUS == "published"` AND
`OLD_STATUS != "published"`.

Edge cases the guard must handle:

- **New file** (no `HEAD:$F`): `OLD_STATUS = ""`. Still a candidate if
  `NEW_STATUS = published`. Same gate applies — you cannot land a brand-new
  published file without G4.
- **No frontmatter** (e.g. a raw markdown change with no `---` block): skip.
- **Status absent or unparseable**: skip (logged as `status:unknown`, not a
  candidate — we want this guard to under-detect rather than block clean
  edits).
- **`vault/blogs/<slug>/` other files** (e.g. `references.md`,
  `og-image.png`): not checked. Only `draft.md` (and the equivalent course
  chapter file) carries status.

### Step B — slug → issue lookup

The slug is the **last path segment of the parent directory**:
`vault/blogs/<SLUG>/draft.md`. For each candidate, look up the issue:

```bash
ISSUE_JSON=$(curl -sf "${AUTH_HEADER[@]}" \
  "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues?limit=2000")
# Filter in python: items where metadata.slug == SLUG
```

Decision matrix:

| Issue match            | `metadata.publish_state`                        | Verdict |
|------------------------|-------------------------------------------------|---------|
| Found                  | `g4-approved` / `dispatching` / `published`     | **ALLOW** |
| Found                  | `g3-passed` / `g0-passed` / `ready` / `null` / anything else | **BLOCK** |
| Not found (no `metadata.slug == SLUG`) | n/a                            | **BLOCK** |

Both `dispatching` and `published` already trail G4. Phase 2 (not yet wired)
will move `dispatching → published` after a successful learnovaBeast run, so
both are legitimate post-gate states.

If `curl` fails or the API is down, the guard **defaults to BLOCK** and logs
`guard:api-error`. Quiet success during an outage is what masked the
two-week pipeline gap in KOEA-1137; we will not repeat that.

## Approval / state source of truth

**Paperclip issue `metadata.publish_state`** on the issue whose
`metadata.slug` equals the vault slug. Same primitive Phase 1 already trusts
on lines 160–169 of the current script. Keeping the source-of-truth field
identical means: one place to revoke, one place to audit, one place that can
drift.

Rejected alternatives:

- **Board interaction state** (e.g. interaction
  `5c2e9971-3a35-4a50-b0e3-738797072b50`). Cleaner conceptually, but there is
  no current API to list interactions filtered by referenced slug, and the
  G3 sweep PATCH that flips an issue to `g4-approved` *is* the durable
  artefact of an accepted board approval. Reading both fields is double-book
  keeping.
- **Trust the original `ticket:` frontmatter field** (e.g. `KOE-35`). Those
  early authoring tickets exist but do not carry `publish_state` (verified
  via `/api/issues/KOE-35` → 404 against the current company). Wrong key.
- **A separate ledger file in vault**. Adds a new file the agents must keep
  in sync; multiplies the failure modes the guard is trying to eliminate.

## Approach (1 chosen, alternatives rejected)

**Chosen — inline bash guard in Phase 0**, between `git add -A vault/` and
`git commit`. A single function `verify_no_pending_g4_publish` that:

1. Lists staged files (`git diff --cached --name-only -- vault/`).
2. Runs Steps A+B for each candidate.
3. If any candidate BLOCKs, calls `git reset HEAD <files>` to unstage them
   (leaving the rest of the dirty vault commit clean), logs structured
   evidence, fires Telegram, files a watchdog issue, and **continues the
   commit for the remaining authorised files**.

Why this shape:

- Keeps the existing two-phase script structure intact (no rewrite to Node /
  TypeScript — the existing
  [KOEA-1137 out-of-scope item](./KOEA-1137-plan.md#out-of-scope) defers
  that).
- Partial commit is *safer* than abort-everything: legitimate vault-sync
  output (research notes, decisions, retrospectives) still lands; only the
  suspicious `published` flips are quarantined.
- The guard is testable in isolation by staging a fixture vault file.

Rejected alternatives:

- **Block the entire commit on any violation.** Simpler logic, but punishes
  unrelated authors whose changes happen to ride the same heartbeat. With
  ~16-file vault-sync ticks this becomes a foot-gun.
- **Pre-commit git hook on the host.** publish-action runs *inside* the
  Docker container (`docker exec paperclip-server bash …`), and the hook
  would need to live on the host repo, not the container's working copy.
  Worse: agent-mode commits from inside containers would bypass the hook
  entirely. Wrong layer.
- **A separate Python lint script invoked from publish-action.** Adds a
  process boundary and a Python dependency. The bash inline version uses
  `awk` + `python3 -c` (already used in the script) and stays self-contained.

## Steps (Executor follows in order — REVISED)

The repo's `scripts/publish-action.sh` (V3.0) currently has Phase 1+2 only.
Steps 1–3 port the V2 Phase 0 vault-sync block from
`/paperclip/scripts/publish-action.sh` lines 88–146 into the repo and add
the guard inline. Step 4 syncs the deployed container copy. Steps 5–8 are
the watchdog issue path, env doc, tests, and verification (unchanged from
Revision 1 in intent; only the file target moves).

1. **Port Phase 0 helpers into `scripts/publish-action.sh`** (the repo
   script). Insert after `log() { ... }` on line 25, before the existing
   ENV_FILE check on line 27:
   - Copy the `tg_alert()` helper verbatim from V2 lines 88–97.
   - Add a new `verify_no_pending_g4_publish()` function (signature below in
     step 3).
   - Add a new `fetch_issues_by_slug` helper that does **one**
     `curl -sf -H "Authorization: Bearer ${PAPERCLIP_API_KEY:-}"
     "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues?limit=2000"` per
     heartbeat and writes the JSON to
     `$LOG_DIR/.issue-cache.$$.json` (PID-scoped so concurrent ticks do not
     collide). HTTP failure or empty body sets a global
     `GUARD_API_ERROR=1` so the guard returns BLOCK for every candidate.

2. **Port the Phase 0 vault-sync block** into
   `scripts/publish-action.sh`. Insert after the existing
   `GH_PAT_DISPATCH` warning on line 35, **before** the
   `# ── Phase 1: g4-approved → repository_dispatch ───` divider on line 37.
   Copy the V2 Phase 0 block (V2 lines 101–146) verbatim with **one
   modification**: between `git checkout -- vault/.obsidian/workspace.json`
   and the `CHANGED_DIRS=...` line, insert a call to
   `verify_no_pending_g4_publish` and the per-file unstage loop (step 3).

3. **`verify_no_pending_g4_publish()` body**. Sketch (Executor expands
   into runnable bash):

   ```bash
   verify_no_pending_g4_publish() {
     # Returns 0 always; populates global BLOCKED_FILES=() and BLOCKED_REASONS=()
     BLOCKED_FILES=(); BLOCKED_REASONS=()
     local staged
     staged="$(git diff --cached --name-only -- vault/ \
       | grep -E '^vault/(blogs/[^/]+|courses/[^/]+(/[^/]+)*)/[^/]+\.md$' || true)"
     [ -z "$staged" ] && return 0
     while IFS= read -r F; do
       local OLD NEW SLUG STATE
       OLD="$(git show "HEAD:$F" 2>/dev/null \
         | awk '/^---$/{c++; next} c==1 && /^status:/{print $2; exit}')"
       NEW="$(awk '/^---$/{c++; next} c==1 && /^status:/{print $2; exit}' "$F")"
       [ "$NEW" = "published" ] || continue
       [ "$OLD" = "published" ] && continue
       SLUG="$(dirname "$F" | awk -F/ '{print $NF}')"
       if [ "${GUARD_API_ERROR:-0}" = "1" ]; then
         BLOCKED_FILES+=("$F"); BLOCKED_REASONS+=("api-error slug=$SLUG"); continue
       fi
       STATE="$(slug_to_publish_state "$SLUG")"
       case "$STATE" in
         g4-approved|dispatching|published) : ;;  # ALLOW
         *) BLOCKED_FILES+=("$F"); BLOCKED_REASONS+=("slug=$SLUG state=${STATE:-none}") ;;
       esac
     done <<< "$staged"
     return 0
   }
   ```

   Wire it into Phase 0 right after `git checkout -- vault/.obsidian/workspace.json`:

   ```bash
   verify_no_pending_g4_publish
   if [ "${#BLOCKED_FILES[@]}" -gt 0 ]; then
     for i in "${!BLOCKED_FILES[@]}"; do
       F="${BLOCKED_FILES[$i]}"; R="${BLOCKED_REASONS[$i]}"
       log "guard: BLOCK file=$F $R"
       git reset HEAD -- "$F" >/dev/null 2>&1 || true
     done
     log "Phase 0 guard: ${#BLOCKED_FILES[@]} blocked; commit will exclude them"
     # step 5 below: file watchdog issue + tg_alert
   fi
   ```

   Note: `CHANGED_DIRS` must be recomputed **after** the unstage loop so
   the commit message reflects what actually lands (Rollout risk #5).

4. **Sync deployed container copy**. Two paths (Executor chooses based on
   container access):
   - **Preferred**: from the host, run
     `docker cp scripts/publish-action.sh paperclip-server:/paperclip/scripts/publish-action.sh`
     and `docker exec paperclip-server chmod +x /paperclip/scripts/publish-action.sh`.
   - **Fallback** (if container is bind-mounting the repo): confirm via
     `docker inspect paperclip-server | jq '.[0].Mounts'`; if
     `/paperclip/scripts` is bind-mounted from the repo, the cp is a no-op
     and only `chmod` is needed.

   Then verify the deployed copy matches the repo:
   `docker exec paperclip-server md5sum /paperclip/scripts/publish-action.sh`
   vs `md5sum scripts/publish-action.sh` on the host. Both must match
   before closing the ticket.

5. **Watchdog issue on block**. If `${#BLOCKED_FILES[@]} > 0` after step 3:
   fire one consolidated `tg_alert` and `POST
   /api/companies/$COMPANY_ID/issues` (auth via `PAPERCLIP_API_KEY`
   `Authorization: Bearer` header, same primitive the new
   `fetch_issues_by_slug` uses) with payload:

   ```json
   {
     "title": "[Watchdog] publish-action Phase 0 blocked pending-G4 status flips",
     "description": "<file list, slug, current publish_state, expected>",
     "priority": "high",
     "metadata": {
       "watchdog_kind": "pending-g4-bypass",
       "blocked_files": ["vault/blogs/<slug>/draft.md", ...],
       "parent_incident": "KOEA-1401"
     }
   }
   ```

   Idempotency: hash the sorted `blocked_files` list, dedupe via a sentinel
   file `$LOG_DIR/.guard-issue-<hash>.created` so a stuck dirty workspace
   does not spawn an issue every minute.

6. **`.env.example` doc-only update**. Add a stanza describing
   `PAPERCLIP_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` as
   guard-relevant. No `.env.koenig` changes — guard uses tokens already
   carried for the existing dispatch path (KOEA-1137). If
   `PAPERCLIP_API_KEY` is empty AND the unauthenticated GET fails, the
   guard logs `guard:no-auth → block` and refuses everything (matches the
   "default closed" policy).

7. **Tests**. Add `scripts/tests/publish-action-guard.bats` (or a bare
   `bash -e` script if bats is not on the container). Fixture: create a
   temp git repo, seed `vault/blogs/fixture-slug/draft.md` with
   `status: g0-passed`, stage a flip to `status: published`, stub
   `PAPERCLIP_URL` to a local `python3 -m http.server` returning a canned
   issue JSON. Run with `publish_state=g3-passed` (expect block) and
   `publish_state=g4-approved` (expect allow). Also a third fixture: stub
   server returns HTTP 500 → expect block (api-error path).

8. **Live smoke**. After the host launchd plist is reloaded
   (`launchctl unload && launchctl load infra/launchd/com.koenig.publish-action.plist`),
   confirm one tick runs cleanly against today's dirty vault state and
   produces zero false-positives. Then leave the job running.

## Logging / evidence shape

Each violation produces three log lines so grep-based audit stays easy:

```
[2026-05-13 03:10:18] guard: BLOCK file=vault/blogs/<slug>/draft.md old=g0-passed new=published
[2026-05-13 03:10:18] guard:   slug=<slug> issue=<KOEA-XXX or none> publish_state=<state or null>
[2026-05-13 03:10:18] guard:   action=unstaged; commit will exclude this file
```

Plus, on commit completion, a summary tally:

```
[2026-05-13 03:10:18] Phase 0 guard: 6 blocked, 10 allowed, watchdog=KOEA-1XXX
```

The Telegram alert reuses `tg_alert` with the form
`⚠️ publish-action: 6 vault files blocked at pending-G4 gate. See
publish-action.log and KOEA-1XXX.`

## Watchdog alert / issue path

- **Inline alert**: Telegram via existing `tg_alert` (only fires when
  `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` are set; existing behaviour).
- **Durable artefact**: a Paperclip issue
  (`metadata.watchdog_kind=pending-g4-bypass`) so the operator queue surfaces
  it and so future audits can grep for the kind. Assignee defaults to
  unassigned — Chief Engineering / CEO routing happens via the standard
  triage lane.
- **Out of scope**: extending `watchdog/watchdog.mjs` itself. The guard
  detects + files; watchdog only needs to keep doing what it does. If we
  later want a `pending-g4-bypass` rule in watchdog.mjs (e.g. "auto-escalate
  if N within an hour"), file separately.

## Smallest verification (also rolls up to Plan-Reviewer)

1. **Repo/runtime parity**:
   `md5sum scripts/publish-action.sh` on the host equals
   `docker exec paperclip-server md5sum /paperclip/scripts/publish-action.sh`.
   Mandatory — confirms the V2/V3.0 divergence is reconciled.
2. **Unit-ish**: `bash scripts/tests/publish-action-guard.bats`
   (or the bare-bash equivalent) — expects 1 block, 1 allow, 1 api-error
   block, 0 panics.
3. **Live tick smoke**: stage a temp edit on
   `vault/blogs/fixture-koea-1401/draft.md` (a new throwaway file) flipping
   to `status: published` without a corresponding Paperclip issue. Run
   `docker exec paperclip-server bash /paperclip/scripts/publish-action.sh`
   once. Expect: file is unstaged, log shows `guard: BLOCK`, no commit
   contains the file, watchdog issue gets created once.
4. **Existing G4 flow unbroken**: pick one issue with
   `metadata.publish_state=g4-approved` already (or set one manually), edit
   its draft to `status: published`, run publish-action. Expect: commit
   contains the file, Phase 1 dispatch fires, no false block.
5. **API-down default**: stop the Paperclip server, run publish-action.
   Expect: any candidate file is blocked, log shows `guard:api-error`, the
   rest of the vault commit proceeds.

`KOEA-1401` closes when steps 1 + 2 + 3 + 4 + 5 all pass and `master`
shows the test commits with the expected file inclusions/exclusions.

## Rollout risks

1. **False positives during the cleanup of historical drift.** Today's vault
   already contains files at `status: published` whose matching issues do
   not carry `g4-approved` (legacy state from before KOEA-1137 landed).
   *Mitigation*: the guard only triggers on **transitions** — old → new in
   the *staged* diff. A file that is already `published` in `HEAD` and stays
   `published` in the worktree is never a candidate. We are not retroactive.
2. **Slug-derivation false negatives.** A draft moved out of the
   `vault/blogs/<slug>/draft.md` convention (e.g. a course chapter at
   `vault/courses/<course>/<chapter>.md`) gets a different slug shape. Phase
   1's dispatcher uses the same slug primitive, so anything Phase 1 can
   dispatch the guard can also gate. New layouts must update both, in
   lockstep — call out in the PR description.
3. **API rate / latency.** One `GET /issues?limit=2000` per minute is
   negligible against the existing Paperclip server, but if the company
   crosses ~10k issues this needs server-side filtering (`?metadata.slug=…`)
   or a server-side index. *Mitigation*: the issue-cache file inside one
   heartbeat already deduplicates; revisit when total issues > 5k.
4. **Watchdog issue spam.** Without the per-hash sentinel, a stuck dirty
   workspace would file a new issue every minute. *Mitigation*: hash-based
   dedupe sentinel under `$LOG_DIR/.guard-issue-<hash>.created`, cleaned
   when the underlying files come unstuck (executor decides clean cadence —
   nightly cron acceptable).
5. **Concurrent legitimate publishes within the same tick.** If two slugs
   land in one heartbeat and only one is `g4-approved`, the guard allows
   the approved one and blocks the other — the commit message Top-Level Dirs
   header will be slightly misleading. *Mitigation*: rebuild
   `CHANGED_DIRS` from the post-reset staged-files set, not the pre-reset
   one. Minor cosmetic fix; not a correctness issue.

## Plan-Reviewer checklist

- [ ] Guard only triggers on transitions to `status: published` (not on
      files that are already published or that flip between non-published
      states).
- [ ] Default-closed under API failure / missing token (`guard:api-error` →
      block).
- [ ] `g4-approved` AND `dispatching` AND `published` all map to ALLOW —
      Phase 2 (currently dormant) and Phase 1 mid-flight tickets must not
      false-block.
- [ ] Partial commit semantics: blocked files are `git reset HEAD`-unstaged,
      everything else commits.
- [ ] Watchdog issue is idempotent per blocked-file-set hash (no per-minute
      spam).
- [ ] Verification fixture lives under `scripts/tests/` and runs against a
      stubbed Paperclip endpoint, not the live API.
- [ ] No change to `.env.koenig` required (tokens already in place from
      KOEA-1137); `.env.example` describes what the guard reads, not what
      it writes.
- [ ] Log shape is grep-friendly and includes `slug`, `issue`,
      `publish_state` on every BLOCK line.
- [ ] Phase 1 dispatch behaviour is byte-identical with this change applied
      against a known-good `g4-approved` ticket.

## Out of scope

- Rewriting `publish-action.sh` to TypeScript / Node.
- Adding a `pending-g4-bypass` rule to `watchdog/watchdog.mjs` itself.
- Identifying or fixing **which** upstream agent is writing
  `status: published` into draft frontmatter without a matching board
  approval (that is the real upstream bug; this guard is defence-in-depth).
  Open as a follow-up once the guard catches the next instance and the
  evidence trail is captured in the watchdog issue.
- Retroactive cleanup of vault files already on `master` at
  `status: published` without an authorised G4 trail. Separate
  reconciliation ticket.
- Course-delta publish flow (different pipeline; see KOEA-12 note in memory).

## Suggested subtask split (for KOEA-1401 implementation, after plan-audit)

1. **KOEA-1401a** — eng: port V2 Phase 0 vault-sync block + `tg_alert`
   helper + `fetch_issues_by_slug` into the repo's
   `scripts/publish-action.sh` (steps 1–2 above). Single PR, no behaviour
   change vs the deployed V2 until step 4 lands.
2. **KOEA-1401b** — eng: add `verify_no_pending_g4_publish` + partial-reset
   wiring inside the ported Phase 0 (step 3). Depends on 1401a.
3. **KOEA-1401c** — eng: add watchdog-issue path with hash dedupe (step 5).
   Depends on 1401b.
4. **KOEA-1401d** — eng: sync deployed container copy via `docker cp` +
   md5sum parity check (step 4 in the body). Depends on 1401c.
5. **KOEA-1401e** — eng: add `scripts/tests/publish-action-guard.bats`
   (step 7). Can run in parallel with 1401b–1401d.
6. **KOEA-1401f** — verify: run the five-step smallest verification on the
   running container; attach `publish-action.log` excerpts, repo/runtime
   md5sum parity output, and the blocked-file watchdog issue id to the
   closing comment.

1401a → 1401b → 1401c is the strict serial chain. 1401d is the deploy gate.
1401e is parallel-safe with the others. 1401f gates closure.

## Open questions for plan-audit

1. Should the guard also gate vault **deletions** of a `status: published`
   file (i.e. someone trying to retract a published post via `rm`)? My
   recommendation is **no for this ticket** — retraction is a different
   workflow with different approvers; file separately if we want it.
2. Course chapter files (`vault/courses/<course>/<chapter>.md`) — do any
   carry `status: published` today? Quick grep:
   `vault/courses/production-agents-claude-agent-sdk-mcp-connector/01-…md`
   and siblings show `status: …` lines. If they do, the guard should cover
   them — or we explicitly scope to `vault/blogs/` for this ticket and file
   a follow-up. Recommendation: cover both from day one; the slug primitive
   is the directory containing the file.
3. Should we **also** require `status: done` on the matching issue (not just
   `publish_state ∈ {g4-approved, …}`)? Today Phase 1's filter is
   `publish_state == 'g4-approved'` alone, so adding `status: done` would
   tighten beyond current behaviour. Recommendation: **no**, mirror Phase 1
   exactly; otherwise the guard and the dispatcher disagree.
