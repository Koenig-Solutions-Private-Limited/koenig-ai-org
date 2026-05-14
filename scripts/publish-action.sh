#!/usr/bin/env bash
# publish-action.sh — closes the loop on the auto-publish pipeline (V3.0).
#
# Phase 1: Scans for publish_state=g4-approved → fires repository_dispatch to
#          learnovaBeast GitHub Actions, sets publish_state=dispatching + dispatched_at.
# Phase 2: Scans for publish_state=dispatching → polls GH Actions for matching run,
#          sets publish_state=published or dispatch_failed.
#
# Requires GH_PAT_DISPATCH (repo+workflow scopes on learnovaBeast) in $ENV_FILE.
# Wired to launchd via com.koenig.publish-action.plist (every 60s).
# Logs to ~/.paperclip/logs/publish-action.log.

set -euo pipefail

REPO_ROOT="/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org"
ENV_FILE="$REPO_ROOT/.env.koenig"
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"
COMPANY_ID="${COMPANY_ID:-${KOENIG_COMPANY_ID:-2a77f89b-33f0-4133-a20c-77ddaac5e744}}"
GH_DISPATCH_REPO="Koenig-Solutions-Private-Limited/learnovaBeast"
PROD_URL="https://academy.kspl.tech"
LOG_DIR="/paperclip/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/publish-action.log"
cd "$REPO_ROOT"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

tg_alert() {
  local msg="$1"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=⚠️ publish-action: ${msg}" \
      > /dev/null 2>&1 || true
  fi
}

GUARD_API_ERROR=0
GUARD_ISSUE_CACHE=""
BLOCKED_FILES=()
BLOCKED_REASONS=()
BLOCKED_OLD_STATUS=()
BLOCKED_NEW_STATUS=()
BLOCKED_SLUGS=()
BLOCKED_STATES=()
BLOCKED_ISSUES=()
GUARD_ALLOWED_COUNT=0

fetch_issues_by_slug() {
  if [ -n "${GUARD_ISSUE_CACHE:-}" ] && [ -s "$GUARD_ISSUE_CACHE" ]; then
    return 0
  fi

  GUARD_ISSUE_CACHE="$LOG_DIR/.issue-cache.$$.json"
  local auth_args=()
  if [ -n "${PAPERCLIP_API_KEY:-}" ]; then
    auth_args=(-H "Authorization: Bearer ${PAPERCLIP_API_KEY}")
  fi

  if ! curl -sf "${auth_args[@]}" \
    "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues?limit=2000" \
    -o "$GUARD_ISSUE_CACHE"; then
    GUARD_API_ERROR=1
    if [ -z "${PAPERCLIP_API_KEY:-}" ]; then
      log "guard:no-auth → block"
    else
      log "guard:api-error"
    fi
    return 1
  fi

  if [ ! -s "$GUARD_ISSUE_CACHE" ]; then
    GUARD_API_ERROR=1
    log "guard:api-error empty issue response"
    return 1
  fi

  return 0
}

slug_to_issue_info() {
  local slug="$1"
  fetch_issues_by_slug || {
    echo -e "api-error\tapi-error"
    return 0
  }

  python3 - "$GUARD_ISSUE_CACHE" "$slug" <<'PY'
import json
import sys

path, slug = sys.argv[1], sys.argv[2]
try:
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    print("api-error\tapi-error")
    sys.exit(0)

items = data.get("items", data) if isinstance(data, dict) else data
if not isinstance(items, list):
    print("none\tnone")
    sys.exit(0)

for item in items:
    metadata = item.get("metadata") or {}
    if metadata.get("slug") == slug:
        issue = item.get("identifier") or item.get("issueIdentifier") or item.get("id") or "unknown"
        state = metadata.get("publish_state") or "null"
        print(f"{issue}\t{state}")
        break
else:
    print("none\tnone")
PY
}

slug_to_publish_state() {
  slug_to_issue_info "$1" | awk -F '\t' '{print $2}'
}

create_guard_watchdog_issue() {
  [ "${#BLOCKED_FILES[@]}" -gt 0 ] || return 0

  local hash sentinel description_file payload_file response_file issue_id
  hash="$(printf '%s\n' "${BLOCKED_FILES[@]}" | sort | shasum -a 256 | awk '{print $1}')"
  sentinel="$LOG_DIR/.guard-issue-${hash}.created"
  if [ -s "$sentinel" ]; then
    cat "$sentinel"
    return 0
  fi

  if [ -z "${PAPERCLIP_API_KEY:-}" ]; then
    log "guard:no-auth watchdog issue not created"
    return 1
  fi

  description_file="$(mktemp)"
  payload_file="$(mktemp)"
  response_file="$(mktemp)"

  {
    echo "publish-action Phase 0 blocked pending-G4 status flips."
    echo
    echo "Expected: matching Paperclip issue metadata.publish_state in g4-approved, dispatching, published."
    echo
    for i in "${!BLOCKED_FILES[@]}"; do
      echo "- file=${BLOCKED_FILES[$i]} slug=${BLOCKED_SLUGS[$i]} issue=${BLOCKED_ISSUES[$i]} publish_state=${BLOCKED_STATES[$i]} old=${BLOCKED_OLD_STATUS[$i]} new=${BLOCKED_NEW_STATUS[$i]}"
    done
  } > "$description_file"

  python3 - "$description_file" "${BLOCKED_FILES[@]}" > "$payload_file" <<'PY'
import json
import sys

description_path = sys.argv[1]
blocked_files = sys.argv[2:]
with open(description_path, "r", encoding="utf-8") as fh:
    description = fh.read()
payload = {
    "title": "[Watchdog] publish-action Phase 0 blocked pending-G4 status flips",
    "description": description,
    "priority": "high",
    "metadata": {
        "watchdog_kind": "pending-g4-bypass",
        "blocked_files": blocked_files,
        "parent_incident": "KOEA-1401",
    },
}
print(json.dumps(payload))
PY

  if curl -sf -X POST "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues" \
    -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" \
    -H "Content-Type: application/json" \
    --data @"$payload_file" > "$response_file"; then
    issue_id="$(python3 - "$response_file" <<'PY'
import json
import sys

try:
    data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
except Exception:
    print("created")
    sys.exit(0)
print(data.get("identifier") or data.get("id") or "created")
PY
)"
    echo "$issue_id" > "$sentinel"
    rm -f "$description_file" "$payload_file" "$response_file"
    echo "$issue_id"
    return 0
  fi

  rm -f "$description_file" "$payload_file" "$response_file"
  log "guard:watchdog-issue-create-failed"
  return 1
}

verify_no_pending_g4_publish() {
  BLOCKED_FILES=()
  BLOCKED_REASONS=()
  BLOCKED_OLD_STATUS=()
  BLOCKED_NEW_STATUS=()
  BLOCKED_SLUGS=()
  BLOCKED_STATES=()
  BLOCKED_ISSUES=()
  GUARD_ALLOWED_COUNT=0

  local staged
  staged="$(git diff --cached --name-only -- vault/ \
    | grep -E '^vault/(blogs/[^/]+|courses/[^/]+(/[^/]+)*)/[^/]+\.md$' || true)"
  [ -z "$staged" ] && return 0

  while IFS= read -r F; do
    local OLD NEW SLUG ISSUE_INFO ISSUE STATE
    OLD="$( (git show "HEAD:$F" 2>/dev/null || true) \
      | awk '/^---$/{c++; next} c==1 && /^status:/{print $2; exit}')"
    NEW="$(awk '/^---$/{c++; next} c==1 && /^status:/{print $2; exit}' "$F")"
    [ "$NEW" = "published" ] || continue
    [ "$OLD" = "published" ] && continue

    SLUG="$(dirname "$F" | awk -F/ '{print $NF}')"
    if [ "${GUARD_API_ERROR:-0}" = "1" ]; then
      BLOCKED_FILES+=("$F")
      BLOCKED_REASONS+=("api-error slug=$SLUG")
      BLOCKED_OLD_STATUS+=("${OLD:-unknown}")
      BLOCKED_NEW_STATUS+=("$NEW")
      BLOCKED_SLUGS+=("$SLUG")
      BLOCKED_STATES+=("api-error")
      BLOCKED_ISSUES+=("api-error")
      continue
    fi

    ISSUE_INFO="$(slug_to_issue_info "$SLUG")"
    ISSUE="$(echo "$ISSUE_INFO" | awk -F '\t' '{print $1}')"
    STATE="$(echo "$ISSUE_INFO" | awk -F '\t' '{print $2}')"
    if [ "$STATE" = "api-error" ]; then
      BLOCKED_FILES+=("$F")
      BLOCKED_REASONS+=("api-error slug=$SLUG")
      BLOCKED_OLD_STATUS+=("${OLD:-unknown}")
      BLOCKED_NEW_STATUS+=("$NEW")
      BLOCKED_SLUGS+=("$SLUG")
      BLOCKED_STATES+=("api-error")
      BLOCKED_ISSUES+=("${ISSUE:-api-error}")
      continue
    fi

    case "$STATE" in
      g4-approved|dispatching|published)
        GUARD_ALLOWED_COUNT=$((GUARD_ALLOWED_COUNT + 1))
        ;;
      *)
        BLOCKED_FILES+=("$F")
        BLOCKED_REASONS+=("slug=$SLUG state=${STATE:-none}")
        BLOCKED_OLD_STATUS+=("${OLD:-unknown}")
        BLOCKED_NEW_STATUS+=("$NEW")
        BLOCKED_SLUGS+=("$SLUG")
        BLOCKED_STATES+=("${STATE:-none}")
        BLOCKED_ISSUES+=("${ISSUE:-none}")
        ;;
    esac
  done <<< "$staged"

  return 0
}

if [[ ! -f "$ENV_FILE" ]]; then
  log "ERROR: $ENV_FILE not found. Skipping publish-action run."
  exit 0
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

GH_PAT_DISPATCH="$(grep -m1 -E "^(GH_PAT_DISPATCH|GH_TOKEN_BOT|GH_TOKEN)=" "$ENV_FILE" | cut -d= -f2- || true)"
if [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "WARN: GH_PAT_DISPATCH missing in $ENV_FILE — Phase 1 and Phase 2 will be skipped."
fi

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

  verify_no_pending_g4_publish
  WATCHDOG_ISSUE=""
  if [ "${#BLOCKED_FILES[@]}" -gt 0 ]; then
    for i in "${!BLOCKED_FILES[@]}"; do
      F="${BLOCKED_FILES[$i]}"
      log "guard: BLOCK file=$F old=${BLOCKED_OLD_STATUS[$i]} new=${BLOCKED_NEW_STATUS[$i]}"
      log "guard:   slug=${BLOCKED_SLUGS[$i]} issue=${BLOCKED_ISSUES[$i]} publish_state=${BLOCKED_STATES[$i]}"
      log "guard:   action=unstaged; commit will exclude this file"
      git reset HEAD -- "$F" >/dev/null 2>&1 || true
    done
    WATCHDOG_ISSUE="$(create_guard_watchdog_issue || true)"
    tg_alert "${#BLOCKED_FILES[@]} vault files blocked at pending-G4 gate. See publish-action.log${WATCHDOG_ISSUE:+ and $WATCHDOG_ISSUE}."
    log "Phase 0 guard: ${#BLOCKED_FILES[@]} blocked, $GUARD_ALLOWED_COUNT allowed, watchdog=${WATCHDOG_ISSUE:-none}"
  fi

  STAGED_COUNT="$(git diff --cached --name-only -- vault/ | wc -l | tr -d ' ')"
  CHANGED_DIRS="$(git diff --cached --name-only -- vault/ | python3 -c "
import os
import sys
dirs = sorted({os.path.dirname(line.strip()) for line in sys.stdin if line.strip()})
print(' '.join(dirs[:10]))
")"
  COMMIT_MSG="auto: vault-sync $(date -u +%Y-%m-%dT%H:%M:%SZ)

Files: $STAGED_COUNT
Dirs: $CHANGED_DIRS

Auto-committed by publish-action.sh V3.0.
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

# ── Phase 1: g4-approved → repository_dispatch ───────────────────────────────

log "Phase 1: scanning for publish_state=g4-approved issues..."

G4_ISSUES_JSON="$(curl -s -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues?limit=2000" | python3 -c "
import json, sys
items = json.load(sys.stdin)
if isinstance(items, dict): items = items.get('items', [])
result = []
for i in items:
    md = i.get('metadata') or {}
    if i.get('status') == 'done' and md.get('publish_state') == 'g4-approved':
        result.append({'id': i['id'], 'slug': md.get('slug', i['id'])})
print(json.dumps(result))
")"

if [[ -z "$G4_ISSUES_JSON" ]] || [[ "$G4_ISSUES_JSON" == "[]" ]]; then
  log "Phase 1: no g4-approved issues found."
elif [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "Phase 1: SKIPPED — GH_PAT_DISPATCH not set."
else
  while IFS=$'\t' read -r ISSUE_ID SLUG; do
    log "Phase 1: dispatching publish-ready for issue=$ISSUE_ID slug=$SLUG"
    DISPATCH_HTTP="$(curl -s -o /dev/null -w "%{http_code}" -X POST \
      "https://api.github.com/repos/$GH_DISPATCH_REPO/dispatches" \
      -H "Authorization: Bearer $GH_PAT_DISPATCH" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -d "$(python3 -c "import json; print(json.dumps({'event_type':'publish-ready','client_payload':{'issue_id':'$ISSUE_ID','slug':'$SLUG'}}))")")"
    if [[ "$DISPATCH_HTTP" == "204" ]]; then
      DISPATCHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      log "Phase 1: dispatch accepted (204) for $ISSUE_ID — setting dispatching at $DISPATCHED_AT"
      curl -sX PATCH -H "Authorization: Bearer ${PAPERCLIP_BOARD_TOKEN}" "$PAPERCLIP_URL/api/issues/$ISSUE_ID" \
        -H "Content-Type: application/json" \
        -d "$(python3 -c "import json; print(json.dumps({'metadata':{'publish_state':'dispatching','dispatched_at':'$DISPATCHED_AT'}}))")" \
        -o /dev/null
    else
      log "Phase 1: dispatch FAILED (HTTP $DISPATCH_HTTP) for $ISSUE_ID"
    fi
  done < <(echo "$G4_ISSUES_JSON" | python3 -c "
import json, sys
items = json.load(sys.stdin)
for i in items:
    print(i['id'] + '\t' + i['slug'])
")
fi

# ── Phase 2: dispatching → poll GH Actions → published / dispatch_failed ─────

log "Phase 2: scanning for publish_state=dispatching issues..."

DISPATCHING_JSON="$(curl -s -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues?limit=2000" | python3 -c "
import json, sys
items = json.load(sys.stdin)
if isinstance(items, dict): items = items.get('items', [])
result = []
for i in items:
    md = i.get('metadata') or {}
    if md.get('publish_state') == 'dispatching':
        result.append({'id': i['id'], 'dispatched_at': md.get('dispatched_at', '')})
print(json.dumps(result))
")"

if [[ -z "$DISPATCHING_JSON" ]] || [[ "$DISPATCHING_JSON" == "[]" ]]; then
  log "Phase 2: no dispatching issues found."
elif [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "Phase 2: SKIPPED — GH_PAT_DISPATCH not set."
else
  GH_RUNS_TMP="$(mktemp)"
  curl -s \
    "https://api.github.com/repos/$GH_DISPATCH_REPO/actions/runs?event=repository_dispatch&per_page=20" \
    -H "Authorization: Bearer $GH_PAT_DISPATCH" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" > "$GH_RUNS_TMP"

  PV_AGENT_ID="$(curl -s -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" "$PAPERCLIP_URL/api/companies/$COMPANY_ID/agents" | python3 -c "
import json, sys
data = json.load(sys.stdin)
agents = data if isinstance(data, list) else data.get('items', [])
match = next((a['id'] for a in agents if a.get('urlKey') == 'publish-verifier'), '')
print(match)
")"

  while IFS=$'\t' read -r ISSUE_ID DISPATCHED_AT; do
    log "Phase 2: checking GH Actions run for issue=$ISSUE_ID dispatched_at=${DISPATCHED_AT:-unknown}"
    RUN_STATUS="$(python3 -c "
import json, sys
from datetime import datetime, timezone
data = json.load(open('$GH_RUNS_TMP'))
issue_id = '$ISSUE_ID'
dispatched_at = '$DISPATCHED_AT'
if not dispatched_at:
    print('not_found')
    sys.exit(0)
try:
    boundary = datetime.fromisoformat(dispatched_at.replace('Z', '+00:00'))
except ValueError:
    print('not_found')
    sys.exit(0)
runs = data.get('workflow_runs', [])
match = None
for r in runs:
    run_name = r.get('display_title') or ''
    try:
        created_at = datetime.fromisoformat((r.get('created_at') or '').replace('Z', '+00:00'))
    except ValueError:
        continue
    if run_name == f'publish-{issue_id}' and created_at >= boundary:
        match = r
        break
if match:
    print(match.get('conclusion') or match.get('status', 'pending'))
else:
    print('not_found')
")"
    log "Phase 2: run status for $ISSUE_ID = $RUN_STATUS"
    case "$RUN_STATUS" in
      success)
        log "Phase 2: marking $ISSUE_ID published url=$PROD_URL"
        curl -sX PATCH -H "Authorization: Bearer ${PAPERCLIP_BOARD_TOKEN}" "$PAPERCLIP_URL/api/issues/$ISSUE_ID" \
          -H "Content-Type: application/json" \
          -d "$(python3 -c "import json; print(json.dumps({'metadata':{'publish_state':'published','published_url':'$PROD_URL','published_at':'$(date -u +%Y-%m-%dT%H:%M:%SZ)'}}))")" \
          -o /dev/null
        if [[ -n "$PV_AGENT_ID" ]]; then
          log "Phase 2: triggering publish-verifier (G5) for $ISSUE_ID"
          curl -sX POST "$PAPERCLIP_URL/api/agents/$PV_AGENT_ID/heartbeat/invoke" \
            -H "Content-Type: application/json" \
            -d "$(python3 -c "import json; print(json.dumps({'context':{'issue_id':'$ISSUE_ID'}}))")" \
            -o /dev/null
        fi
        ;;
      failure|cancelled|timed_out|action_required|startup_failure)
        log "Phase 2: marking $ISSUE_ID dispatch_failed (run_status=$RUN_STATUS)"
        curl -sX PATCH -H "Authorization: Bearer ${PAPERCLIP_BOARD_TOKEN}" "$PAPERCLIP_URL/api/issues/$ISSUE_ID" \
          -H "Content-Type: application/json" \
          -d "$(python3 -c "import json; print(json.dumps({'metadata':{'publish_state':'dispatch_failed','dispatch_failure_reason':'GH Actions run status: $RUN_STATUS'}}))")" \
          -o /dev/null
        ;;
      not_found|in_progress|queued|waiting|pending)
        log "Phase 2: run not yet complete ($RUN_STATUS) for $ISSUE_ID — will re-check next poll"
        ;;
      *)
        log "Phase 2: unknown run status '$RUN_STATUS' for $ISSUE_ID — skipping"
        ;;
    esac
  done < <(echo "$DISPATCHING_JSON" | python3 -c "
import json, sys
items = json.load(sys.stdin)
for i in items:
    print(i['id'] + '\t' + i.get('dispatched_at', ''))
")

  rm -f "$GH_RUNS_TMP"
fi

log "publish-action complete."

# ROLLBACK: old local vercel build + deploy (pre-V3.0 / Option A architecture).
# Replaced by repository_dispatch to learnovaBeast GitHub Actions (Option B, KOEA-94).
# Keep for rollback reference — do NOT re-enable without removing Phase 1/2 above.
#
# ROLLBACK: ACADEMY="$REPO_ROOT/../learnovaBeast/learnova-academy"
# ROLLBACK: VERCEL_TOKEN="$(grep "^VERCEL_TOKEN=" "$ENV_FILE" | cut -d= -f2-)"
# ROLLBACK: if [[ -z "$VERCEL_TOKEN" ]]; then
# ROLLBACK:   log "ERROR: VERCEL_TOKEN missing in $ENV_FILE. Skipping."
# ROLLBACK:   exit 0
# ROLLBACK: fi
# ROLLBACK:
# ROLLBACK: log "Polling for ready-to-publish issues (status=done + metadata.publish_state in ready|g4-approved)..."
# ROLLBACK: APPROVED_IDS="$(curl -s "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues" | python3 -c "
# ROLLBACK: import json, sys
# ROLLBACK: items = json.load(sys.stdin)
# ROLLBACK: if isinstance(items, dict): items = items.get('items', [])
# ROLLBACK: ids = [
# ROLLBACK:     i['id'] for i in items
# ROLLBACK:     if i.get('status') == 'done'
# ROLLBACK:     and i.get('metadata', {}).get('publish_state') in ('ready', 'g4-approved')
# ROLLBACK: ]
# ROLLBACK: print(' '.join(ids))
# ROLLBACK: ")"
# ROLLBACK:
# ROLLBACK: if [[ -z "$APPROVED_IDS" ]]; then
# ROLLBACK:   log "No ready-to-publish issues. Exiting cleanly."
# ROLLBACK:   exit 0
# ROLLBACK: fi
# ROLLBACK: log "Found ready-to-publish issues: $APPROVED_IDS"
# ROLLBACK:
# ROLLBACK: log "Running vercel build + deploy --prebuilt --prod..."
# ROLLBACK: cd "$ACADEMY"
# ROLLBACK: KOENIG_VAULT_ROOT="$REPO_ROOT/vault" vercel build --prod --token "$VERCEL_TOKEN" >> "$LOG" 2>&1
# ROLLBACK:
# ROLLBACK: DEPLOY_OUTPUT="$(vercel deploy --prod --prebuilt --token "$VERCEL_TOKEN" --yes 2>&1)"
# ROLLBACK: echo "$DEPLOY_OUTPUT" >> "$LOG"
# ROLLBACK:
# ROLLBACK: PUBLISHED_URL="$(echo "$DEPLOY_OUTPUT" | python3 -c "
# ROLLBACK: import sys, re
# ROLLBACK: text = sys.stdin.read()
# ROLLBACK: m = re.search(r'\"url\":\\s*\"(https?://[^\"]+)\"', text)
# ROLLBACK: print(m.group(1) if m else '')
# ROLLBACK: ")"
# ROLLBACK:
# ROLLBACK: if [[ -z "$PUBLISHED_URL" ]]; then
# ROLLBACK:   log "ERROR: Could not parse published URL from deploy output. Aborting."
# ROLLBACK:   exit 1
# ROLLBACK: fi
# ROLLBACK: log "Deployed: $PUBLISHED_URL"
# ROLLBACK:
# ROLLBACK: PV_AGENT_ID="$(curl -s -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" "$PAPERCLIP_URL/api/companies/$COMPANY_ID/agents" | python3 -c "
# ROLLBACK: import json, sys
# ROLLBACK: data = json.load(sys.stdin)
# ROLLBACK: print(next(a['id'] for a in data if a['urlKey'] == 'publish-verifier'))
# ROLLBACK: ")"
# ROLLBACK:
# ROLLBACK: for ID in $APPROVED_IDS; do
# ROLLBACK:   log "Marking $ID publish_state=published + url=$PUBLISHED_URL (status stays done)"
# ROLLBACK:   curl -sX PATCH "$PAPERCLIP_URL/api/issues/$ID" \
# ROLLBACK:     -H "Content-Type: application/json" \
# ROLLBACK:     -d "$(python3 -c "import json; print(json.dumps({'metadata': {'publish_state': 'published', 'published_url': '$PUBLISHED_URL', 'published_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)'}}))")" \
# ROLLBACK:     -o /dev/null
# ROLLBACK:   log "Triggering publish-verifier (G5) for issue $ID"
# ROLLBACK:   curl -sX POST "$PAPERCLIP_URL/api/agents/$PV_AGENT_ID/heartbeat/invoke" \
# ROLLBACK:     -H "Content-Type: application/json" \
# ROLLBACK:     -d "$(python3 -c "import json; print(json.dumps({'context': {'issue_id': '$ID'}}))")" \
# ROLLBACK:     -o /dev/null
# ROLLBACK: done
# ROLLBACK:
# ROLLBACK: log "publish-action complete: deployed $PUBLISHED_URL, flipped $(echo $APPROVED_IDS | wc -w) issues, triggered G5"
