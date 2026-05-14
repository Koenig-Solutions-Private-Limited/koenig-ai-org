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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.koenig"
CANONICAL_COMPANY_ID="2a77f89b-33f0-4133-a20c-77ddaac5e744"
GH_DISPATCH_REPO="Koenig-Solutions-Private-Limited/learnovaBeast"
PROD_URL="https://academy.kspl.tech"
LOG_DIR="$HOME/.paperclip/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/publish-action.log"
PUBLISH_ACTION_DRY_RUN="${PUBLISH_ACTION_DRY_RUN:-0}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

env_value() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" && -f "$ENV_FILE" ]]; then
    value="$(grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- || true)"
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
  fi
  printf '%s' "$value"
}

sanitize_response() {
  python3 -c '
import re, sys
import os
text = sys.stdin.read()[:500]
for secret in (os.environ.get("PAPERCLIP_BOARD_TOKEN"), os.environ.get("GH_PAT_DISPATCH")):
    if secret:
        text = text.replace(secret, "[REDACTED]")
text = re.sub(r"Bearer\s+[A-Za-z0-9._~+/=-]+", "Bearer [REDACTED]", text)
text = re.sub(r"(?i)(token|api[_-]?key|authorization|secret)[\"'"'"']?\s*[:=]\s*[\"'"'"']?[^\"'"'"'\s,}]+", r"\1=[REDACTED]", text)
print(text.replace("\n", " ")[:240])
'
}

paperclip_request() {
  local method="$1"
  local endpoint="$2"
  local body="${3:-}"
  local tmp
  local http
  tmp="$(mktemp)"
  if [[ "$method" != "GET" && "$PUBLISH_ACTION_DRY_RUN" == "1" ]]; then
    log "DRY-RUN would $method Paperclip $endpoint"
    rm -f "$tmp"
    return 0
  fi

  if [[ "$method" == "GET" ]]; then
    http="$(curl -sS -o "$tmp" -w "%{http_code}" \
      "$PAPERCLIP_URL$endpoint" \
      -H "Authorization: Bearer $PAPERCLIP_BOARD_TOKEN")"
  else
    http="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" \
      "$PAPERCLIP_URL$endpoint" \
      -H "Authorization: Bearer $PAPERCLIP_BOARD_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$body")"
  fi

  if [[ "$http" =~ ^2 ]]; then
    cat "$tmp"
    rm -f "$tmp"
    return 0
  fi

  local summary
  summary="$(sanitize_response < "$tmp")"
  log "Paperclip API FAILED method=$method endpoint=$endpoint status=$http reason=$summary"
  rm -f "$tmp"
  return 1
}

paperclip_get() { paperclip_request GET "$1"; }
paperclip_patch() { paperclip_request PATCH "$1" "$2"; }
paperclip_post() { paperclip_request POST "$1" "$2"; }

if [[ ! -f "$ENV_FILE" ]]; then
  log "WARN: $ENV_FILE not found. Continuing with process environment only."
fi

PAPERCLIP_URL="$(env_value PAPERCLIP_API_URL)"
if [[ -z "$PAPERCLIP_URL" ]]; then
  PAPERCLIP_URL="$(env_value PAPERCLIP_URL)"
fi
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"
COMPANY_ID="$(env_value PAPERCLIP_COMPANY_ID)"
if [[ -z "$COMPANY_ID" ]]; then
  COMPANY_ID="$(env_value COMPANY_ID)"
fi
COMPANY_ID="${COMPANY_ID:-}"
PAPERCLIP_BOARD_TOKEN="$(env_value PAPERCLIP_BOARD_TOKEN)"
GH_PAT_DISPATCH="$(env_value GH_PAT_DISPATCH)"
export PAPERCLIP_BOARD_TOKEN GH_PAT_DISPATCH

if [[ "$COMPANY_ID" != "$CANONICAL_COMPANY_ID" ]]; then
  log "ERROR: PAPERCLIP_COMPANY_ID/COMPANY_ID must be canonical Koenig company id. Skipping publish-action run."
  exit 0
fi

if [[ -z "$PAPERCLIP_BOARD_TOKEN" ]]; then
  log "ERROR: PAPERCLIP_BOARD_TOKEN missing. Skipping publish-action run before any mutation-capable phase."
  exit 0
fi
log "Paperclip config OK: url=$PAPERCLIP_URL company_id=$COMPANY_ID board_token=present dry_run=$PUBLISH_ACTION_DRY_RUN"

if [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "WARN: GH_PAT_DISPATCH missing in environment/$ENV_FILE — Phase 1 and Phase 2 will be skipped."
fi

# ── Phase 1: g4-approved → repository_dispatch ───────────────────────────────

log "Phase 1: scanning for publish_state=g4-approved issues..."

G4_ISSUES_JSON="$(paperclip_get "/api/companies/$COMPANY_ID/issues" | python3 -c "
import json, sys
items = json.load(sys.stdin)
if isinstance(items, dict): items = items.get('items', [])
result = [
    {'id': i['id'], 'slug': i.get('metadata', {}).get('slug', i['id'])}
    for i in items
    if i.get('status') == 'done'
    and i.get('metadata', {}).get('publish_state') == 'g4-approved'
]
print(json.dumps(result))
")"

if [[ -z "$G4_ISSUES_JSON" ]] || [[ "$G4_ISSUES_JSON" == "[]" ]]; then
  log "Phase 1: no g4-approved issues found."
elif [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "Phase 1: SKIPPED — GH_PAT_DISPATCH not set."
else
  while IFS=$'\t' read -r ISSUE_ID SLUG; do
    log "Phase 1: dispatching publish-ready for issue=$ISSUE_ID slug=$SLUG"
    if [[ "$PUBLISH_ACTION_DRY_RUN" == "1" ]]; then
      log "DRY-RUN would dispatch publish-ready for issue=$ISSUE_ID slug=$SLUG"
      DISPATCH_HTTP="204"
    else
      DISPATCH_HTTP="$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        "https://api.github.com/repos/$GH_DISPATCH_REPO/dispatches" \
        -H "Authorization: Bearer $GH_PAT_DISPATCH" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -d "$(python3 -c "import json; print(json.dumps({'event_type':'publish-ready','client_payload':{'issue_id':'$ISSUE_ID','slug':'$SLUG'}}))")")"
    fi
    if [[ "$DISPATCH_HTTP" == "204" ]]; then
      DISPATCHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      log "Phase 1: dispatch accepted (204) for $ISSUE_ID — setting dispatching at $DISPATCHED_AT"
      paperclip_patch "/api/issues/$ISSUE_ID" \
        "$(python3 -c "import json; print(json.dumps({'metadata':{'publish_state':'dispatching','dispatched_at':'$DISPATCHED_AT'}}))")" \
        >/dev/null
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

DISPATCHING_JSON="$(paperclip_get "/api/companies/$COMPANY_ID/issues" | python3 -c "
import json, sys
items = json.load(sys.stdin)
if isinstance(items, dict): items = items.get('items', [])
result = [
    {'id': i['id'], 'dispatched_at': i.get('metadata', {}).get('dispatched_at', '')}
    for i in items
    if i.get('metadata', {}).get('publish_state') == 'dispatching'
]
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

  PV_AGENT_ID="$(paperclip_get "/api/companies/$COMPANY_ID/agents" | python3 -c "
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
    if run_name == 'publish-' + issue_id and created_at >= boundary:
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
        paperclip_patch "/api/issues/$ISSUE_ID" \
          "$(python3 -c "import json; print(json.dumps({'metadata':{'publish_state':'published','published_url':'$PROD_URL','published_at':'$(date -u +%Y-%m-%dT%H:%M:%SZ)'}}))")" \
          >/dev/null
        if [[ -n "$PV_AGENT_ID" ]]; then
          log "Phase 2: triggering publish-verifier (G5) for $ISSUE_ID"
          paperclip_post "/api/agents/$PV_AGENT_ID/heartbeat/invoke" \
            "$(python3 -c "import json; print(json.dumps({'context':{'issue_id':'$ISSUE_ID'}}))")" \
            >/dev/null
        fi
        ;;
      failure|cancelled|timed_out|action_required|startup_failure)
        log "Phase 2: marking $ISSUE_ID dispatch_failed (run_status=$RUN_STATUS)"
        paperclip_patch "/api/issues/$ISSUE_ID" \
          "$(python3 -c "import json; print(json.dumps({'metadata':{'publish_state':'dispatch_failed','dispatch_failure_reason':'GH Actions run status: $RUN_STATUS'}}))")" \
          >/dev/null
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
# ROLLBACK: PV_AGENT_ID="$(curl -s "$PAPERCLIP_URL/api/companies/$COMPANY_ID/agents" | python3 -c "
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
