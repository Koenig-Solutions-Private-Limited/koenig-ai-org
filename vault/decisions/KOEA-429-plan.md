---
ticket: KOEA-429
planner: planner
date: 2026-05-03
estimated_complexity: small (~10 LOC changed)
estimated_token_cost: $0.20
files_touched:
  - scripts/wake-triage.sh
tags: [planning, scripts, eng-trio-e2e, koea-317, koea-429]
---

# Plan: KOEA-429 — replace hardcoded `/opt/homebrew/bin/python3.12` in `scripts/wake-triage.sh` with `jq`

## Goal

Make `scripts/wake-triage.sh` portable and consistent with the rest of the repo by removing the two hardcoded `/opt/homebrew/bin/python3.12` invocations and replacing them with `jq` — already available at `/usr/bin/jq` and the canonical JSON tool used elsewhere (e.g. `README.koenig.md:169`). After the change the script must keep its current behaviour exactly: resolve `triage`/`triage-agent` slug → id, count backlog items, skip the heartbeat invoke when backlog is zero, otherwise POST and append a single status line to `~/.paperclip/logs/triage.stdout.log`.

This is the **Engineering Trio E2E test refactor** (KOEA-317 sub-4): scope deliberately tiny so the Planner → Executor → Code Reviewer chain can be exercised without confounding the trio under a complex change.

## Context

- `scripts/wake-triage.sh` is fired every 30 minutes by `infra/launchd/com.koenig.triage.plist` (StartInterval=1800).
- Two heredocs invoke `/opt/homebrew/bin/python3.12` (lines 16-26 and 34-40) to parse JSON from the Paperclip API.
- That path is fragile: it pins a specific Python minor version (3.12) and assumes Apple-Silicon Homebrew. A `brew upgrade python` to 3.13 would silently break the cron; running on an Intel Mac (path is `/usr/local/bin/...`) would also break.
- The launchd plist already adds `/opt/homebrew/bin:/usr/bin:/bin` to PATH, so plain `jq` resolves at `/usr/bin/jq` (1.7, confirmed locally).
- `jq` is already the de-facto JSON tool in this repo: `README.koenig.md:169` shows the same agent-by-slug pattern in `jq` form.
- Other shell scripts in `scripts/` (`publish-action.sh`, `sync-secrets.sh`) use bare `python3 -c`, not the absolute path — so the brittleness is local to `wake-triage.sh`.

### Files to read first

- `scripts/wake-triage.sh:1-52` — the entire script; the two python heredocs are the only thing changing
- `infra/launchd/com.koenig.triage.plist` — caller; PATH env var is already correct, no changes needed there
- `README.koenig.md:169` — canonical `jq` recipe for `agents[] | select(.urlKey=="<slug>") | .id`

## Approach (chosen)

Replace each `/opt/homebrew/bin/python3.12 -c "<heredoc>"` with a single `jq` invocation that preserves the current Python semantics exactly:

- **List-or-envelope guard**: Python uses `data if isinstance(data, list) else data.get('items', [])`. The jq equivalent is `(if type == "array" then . else (.items // []) end)` — the `// []` fallback matches Python's default-empty when `.items` is absent.
- **Slug match**: Python iterates and breaks on first match for `triage` or `triage-agent`. The jq equivalent picks the first match: `map(select(.urlKey == "triage" or .urlKey == "triage-agent")) | .[0].id // ""`. The `// ""` keeps the empty-string fallback that the existing `[[ -z "$TRIAGE_ID" ]]` guard already handles.
- **Backlog count**: Python `sum(1 for i in items if i.get('status') == 'backlog')` becomes `map(select(.status == "backlog")) | length`.

Behaviour is unchanged. The diff is tight: the two `curl | python3.12 -c "..."` blocks shrink to one-line `curl | jq` pipes; everything else (env vars, log lines, exit-zero on no-triage, exit-zero on empty backlog, the final POST + log) stays byte-for-byte the same.

## Approaches rejected

- **Replace `/opt/homebrew/bin/python3.12` with bare `python3`.** Rejected: removes the version pin but leaves the embedded heredocs and their fragility (multi-line shell-escaping, breaks if PATH-resolved python doesn't have stdin-JSON helpers, etc). `jq` is one tool with one shape, used elsewhere in this repo for the same pattern. Doesn't justify the ugliness.
- **Rewrite `wake-triage.sh` as a Python script.** Rejected: scope creep. The plist already invokes a `.sh`, and rewriting would force changes to the launchd plist + log pipes for a refactor that is supposed to be tiny.
- **Extract a shared `paperclip-curl-jq` helper script.** Rejected: only 2 call sites, premature abstraction. If `publish-action.sh` is migrated off Python heredocs in a future ticket, that would be the time to factor.
- **Bring in a `paperclip` CLI subcommand.** Rejected: out of scope, and no such CLI exists for these endpoints today.

## Steps (Executor follows in order)

1. **Branch** off `master` as `koea-429/wake-triage-jq`. Confirm `git status -- scripts/wake-triage.sh` shows no pending modifications (the file should be clean — repo has unrelated dirty paths in `.claude/skills/` that must NOT be staged).

2. **Edit `scripts/wake-triage.sh`** — replace lines 15-26 (the comment + the python heredoc that resolves `TRIAGE_ID`) with:

   ```bash
   # Find triage-agent's id (handles both 'triage' and 'triage-agent' slugs)
   TRIAGE_ID="$(curl -s "$PAPERCLIP_URL/api/companies/$COMPANY_ID/agents" 2>/dev/null \
     | jq -r '(if type == "array" then . else (.items // []) end) | map(select(.urlKey == "triage" or .urlKey == "triage-agent")) | .[0].id // ""')"
   ```

3. **Edit `scripts/wake-triage.sh`** — replace the second python heredoc (lines 33-40, the `BACKLOG_COUNT` block) with:

   ```bash
   # Count backlog items — skip wake if zero
   BACKLOG_COUNT="$(curl -s "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues" 2>/dev/null \
     | jq '(if type == "array" then . else (.items // []) end) | map(select(.status == "backlog")) | length')"
   ```

4. **Do not change** any other line. The shebang, `set -euo pipefail`, env-var defaults, log-dir setup, `[[ -z "$TRIAGE_ID" ]]` guard, `[[ "$BACKLOG_COUNT" -eq 0 ]]` guard, the final `curl POST` invoke, and the trailing log line all stay verbatim.

5. **Syntax check**: `bash -n scripts/wake-triage.sh` must exit 0.

6. **Smoke-test against the live local Paperclip server** (assumes `pnpm dev` or the Docker container is running on `localhost:3100`):
   ```bash
   bash scripts/wake-triage.sh
   tail -1 ~/.paperclip/logs/triage.stdout.log
   ```
   Cross-check the backlog count against:
   ```bash
   curl -s http://localhost:3100/api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/issues \
     | jq '(if type == "array" then . else (.items // []) end) | map(select(.status == "backlog")) | length'
   ```
   Both numbers must agree. The log line should look like one of:
   - `... triage-agent not found in roster; skipping`
   - `... backlog empty; skipping triage wake (saves tokens)`
   - `... backlog=<N> triage_id=<uuid> woke: ...`

7. **Open PR** `koea-429/wake-triage-jq` → `master` titled `KOEA-429: replace hardcoded python3.12 in wake-triage.sh with jq`. Body must include:
   - One-line rationale (portability + version-pin removal).
   - Diff stats (expect: 2 files? no, 1 file; ~10 lines removed, ~4 lines added).
   - The smoke-test evidence from step 6 (the log line + the cross-check curl output).
   - A "no-op verification" line confirming `TRIAGE_ID` and `BACKLOG_COUNT` resolve to the same values they did pre-change (run the old python heredocs manually side-by-side if doubt).

8. **Hand off to Code Reviewer** by tagging the PR with `@code-reviewer` per KOEA-317 task-4 protocol, and dropping a comment on the KOEA-429 child-issue thread linking the PR.

## Verification (Code Reviewer audits these)

- [ ] `scripts/wake-triage.sh` no longer contains `/opt/homebrew/bin/python3.12` (or any absolute python path).
- [ ] Both call sites use `jq` from PATH (no `/usr/bin/jq` absolute path either — keep it lean).
- [ ] The `(if type == "array" then . else (.items // []) end)` envelope guard appears in both jq pipes (preserves Python's `isinstance / .get('items', [])` behaviour for the dict-envelope response shape).
- [ ] The slug filter is `(.urlKey == "triage" or .urlKey == "triage-agent")` — both slugs preserved.
- [ ] The first-match selector is `.[0].id // ""` — keeps empty-string fallback so the existing `[[ -z "$TRIAGE_ID" ]]` guard still triggers correctly.
- [ ] The backlog filter is `.status == "backlog"` and the result piped through `length` (no `-r` here, since `length` already prints a bare integer).
- [ ] Lines 1-14, 27-32, 41-52 of the original `wake-triage.sh` are byte-for-byte unchanged (defensive: keep the diff tight).
- [ ] `bash -n scripts/wake-triage.sh` is clean.
- [ ] PR body contains the smoke-test log-line evidence.
- [ ] No changes to `infra/launchd/com.koenig.triage.plist` (PATH already includes `/usr/bin`, no plist edit needed).

## Risk

- **jq quoting in the slug filter.** The double-quoted strings inside the jq program need to survive bash double-quoting too. The proposed form `'(if type == "array" then . else (.items // []) end) | map(select(.urlKey == "triage" or .urlKey == "triage-agent")) | .[0].id // ""'` uses single-quotes for the jq program so the inner `"..."` are literal — verified mentally; Executor must confirm with `bash -n` and a smoke-test before pushing. Mitigation: if shell-escaping is wrong, the jq error surfaces immediately (`jq: error: ... at <top-level>`) and the smoke-test catches it.
- **Status enum drift.** If Paperclip's issue-status enum has been renamed from `"backlog"` to something else (e.g. `"to_do"`), `BACKLOG_COUNT` would always be 0 — but that would be a pre-existing bug masked by the python version too, not introduced by this change. Mitigation: the smoke-test cross-check in step 6 catches it (compare raw count from the issues endpoint).
- **API envelope change.** If the `/api/companies/{id}/agents` endpoint started returning `{ data: [...] }` instead of `{ items: [...] }`, both the old python and new jq would fall back to `[]` and silently skip. Same risk as before; not regressed.
- **No regression in the unhappy paths.** The `set -euo pipefail` at the top means a transient `curl` failure now exits the script (was already the case under python). Unchanged behaviour.

## Out of scope

- Other shell scripts that use `python3 -c` heredocs (`scripts/publish-action.sh`, `scripts/sync-secrets.sh`). They use bare `python3` (not the homebrew absolute path), so they aren't broken by the same bug. Migrating them to `jq` is welcome but tracked separately.
- Rewriting `wake-triage.sh` as a Python script.
- Adding `jq` as an explicit dependency in `infra/launchd/...` setup docs — `jq` is already implicitly required by `README.koenig.md:169` and is preinstalled on macOS via developer tools / Homebrew.
- Changes to the launchd plist itself.
- Any change in semantics: triage wake cadence, backlog threshold, log format.

## Engineering Trio E2E test (KOEA-317 sub-4) scoring guidance

- **Planner phase**: judged on (a) picking a refactor that is genuinely small but represents a real bug, not a synthetic one; (b) preserving existing behaviour exactly via well-chosen jq filters that map 1:1 to the Python heredocs; (c) calling out the envelope-guard subtlety so Executor doesn't drop the `// []` fallback.
- **Executor phase**: judged on (a) tight diff (only the two python blocks change); (b) running the smoke-test cross-check before opening the PR; (c) no scope creep into other scripts.
- **Code Reviewer phase**: judged on (a) confirming all six jq-filter checkboxes above; (b) catching any shell-quoting slip; (c) verifying the smoke evidence in the PR body matches a real backlog count.

Report scores back to KOEA-317 with one line per phase.
