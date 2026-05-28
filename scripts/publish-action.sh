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
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"
COMPANY_ID="${COMPANY_ID:-${KOENIG_COMPANY_ID:-2a77f89b-33f0-4133-a20c-77ddaac5e744}}"
GH_DISPATCH_REPO="Koenig-Solutions-Private-Limited/learnovaBeast"
PROD_URL="https://academy.kspl.tech"
LOG_DIR="${LOG_DIR:-/paperclip/logs}"
mkdir -p "$LOG_DIR"
LOG="${LOG:-$LOG_DIR/publish-action.log}"
DISPATCH_LEDGER_DIR="$LOG_DIR/.dispatch-ledger"
mkdir -p "$DISPATCH_LEDGER_DIR"
cd "$REPO_ROOT"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

CURRENT_PHASE="startup"
TERMINAL_REASON=""
REGISTERED_TEMP_FILES=()
RUNNING_AS_SCRIPT=0
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  RUNNING_AS_SCRIPT=1
fi

register_temp_file() {
  REGISTERED_TEMP_FILES+=("$1")
}

cleanup_registered_files() {
  local path
  for path in "${REGISTERED_TEMP_FILES[@]:-}"; do
    [ -n "$path" ] && rm -f "$path"
  done
}

terminal_log_and_cleanup() {
  local exit_code="$?"
  cleanup_registered_files
  if [ "$exit_code" -eq 0 ] && [ "${TERMINAL_REASON:-}" = "complete" ]; then
    log "publish-action complete."
    return 0
  fi

  if [ "$exit_code" -eq 0 ]; then
    log "publish-action terminal: exited phase=${CURRENT_PHASE:-unknown} reason=${TERMINAL_REASON:-early-exit} cleanup=done"
    return 0
  fi

  log "publish-action terminal: failed phase=${CURRENT_PHASE:-unknown} exit_code=$exit_code reason=${TERMINAL_REASON:-unhandled-error} cleanup=done"
  return "$exit_code"
}

if [ "$RUNNING_AS_SCRIPT" = "1" ]; then
  trap terminal_log_and_cleanup EXIT
fi

tg_alert() {
  local msg="$1"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=⚠️ publish-action: ${msg}" \
      > /dev/null 2>&1 || true
  fi
}

sanitize_guard_reason() {
  local input_file="$1"
  python3 - "$input_file" <<'PY'
import re
import sys

path = sys.argv[1]
try:
    raw = open(path, "rb").read(4096)
except Exception:
    raw = b""

text = raw.decode("utf-8", errors="replace")
text = "".join(ch if ch == "\n" or ch == "\t" or ord(ch) >= 32 else " " for ch in text)
text = re.sub(r"(?i)(bearer\s+)[^\s\"']+", r"\1[REDACTED]", text)
text = re.sub(r"(?i)((?:token|api[_-]?key|password|secret)[\"'\s:=]+)[^\"'\s,}]+", r"\1[REDACTED]", text)
text = re.sub(r"\s+", " ", text).strip()
print((text or "empty-response")[:240])
PY
}

paperclip_auth_args() {
  if [ -n "${PAPERCLIP_API_KEY:-}" ]; then
    printf '%s\n' "-H" "Authorization: Bearer ${PAPERCLIP_API_KEY}"
  fi
}

curl_failure_status() {
  local status="${1:-}"
  if [ -z "$status" ] || [ "$status" = "000" ]; then
    echo "curl-failed"
  else
    echo "$status"
  fi
}

paperclip_curl_json() {
  local method="$1"
  local endpoint="$2"
  local output_file="$3"
  local data_file="${4:-}"
  local error_file status reason
  error_file="$(mktemp)"
  register_temp_file "$error_file"

  local auth_args=()
  if [ -n "${PAPERCLIP_API_KEY:-}" ]; then
    auth_args=(-H "Authorization: Bearer ${PAPERCLIP_API_KEY}")
  fi

  local curl_args=(-sS --connect-timeout 10 --max-time 30 -X "$method" "$PAPERCLIP_URL$endpoint")
  curl_args+=("${auth_args[@]}" -H "Accept: application/json")
  if [ -n "$data_file" ]; then
    curl_args+=(-H "Content-Type: application/json" --data @"$data_file")
  fi

  if ! status="$(curl "${curl_args[@]}" -o "$output_file" -w "%{http_code}" 2>"$error_file")"; then
    status="$(curl_failure_status "$status")"
    reason="$(sanitize_guard_reason "$error_file")"
    log "paperclip:api-error phase=${CURRENT_PHASE:-unknown} endpoint=$endpoint http_status=$status reason=$reason"
    return 1
  fi

  if [[ ! "$status" =~ ^2 ]]; then
    reason="$(sanitize_guard_reason "$output_file")"
    log "paperclip:api-error phase=${CURRENT_PHASE:-unknown} endpoint=$endpoint http_status=$status reason=$reason"
    return 1
  fi

  return 0
}

paperclip_patch_issue_metadata() {
  local issue_id="$1"
  local metadata_json="$2"
  local payload_file response_file
  payload_file="$(mktemp)"
  response_file="$(mktemp)"
  register_temp_file "$payload_file"
  register_temp_file "$response_file"

  if ! python3 - "$metadata_json" > "$payload_file" <<'PY'
import json
import sys

metadata = json.loads(sys.argv[1])
print(json.dumps({"metadata": metadata}))
PY
  then
    log "paperclip:metadata-payload-failed phase=${CURRENT_PHASE:-unknown} issue=$issue_id"
    return 1
  fi

  paperclip_curl_json PATCH "/api/issues/$issue_id" "$response_file" "$payload_file"
}

github_curl_json() {
  local method="$1"
  local url="$2"
  local output_file="$3"
  local data_file="${4:-}"
  local expected_status="${5:-2xx}"
  local error_file status reason
  error_file="$(mktemp)"
  register_temp_file "$error_file"

  local curl_args=(-sS --connect-timeout 10 --max-time 30 -X "$method" "$url")
  curl_args+=(-H "Authorization: Bearer $GH_PAT_DISPATCH")
  curl_args+=(-H "Accept: application/vnd.github+json")
  curl_args+=(-H "X-GitHub-Api-Version: 2022-11-28")
  if [ -n "$data_file" ]; then
    curl_args+=(-H "Content-Type: application/json" --data @"$data_file")
  fi

  if ! status="$(curl "${curl_args[@]}" -o "$output_file" -w "%{http_code}" 2>"$error_file")"; then
    status="$(curl_failure_status "$status")"
    reason="$(sanitize_guard_reason "$error_file")"
    log "github:api-error phase=${CURRENT_PHASE:-unknown} url=$url http_status=$status reason=$reason"
    return 1
  fi

  if [ "$expected_status" = "204" ]; then
    if [ "$status" = "204" ]; then
      return 0
    fi
  elif [[ "$status" =~ ^2 ]]; then
    return 0
  fi

  reason="$(sanitize_guard_reason "$output_file")"
  log "github:api-error phase=${CURRENT_PHASE:-unknown} url=$url http_status=$status reason=$reason"
  return 1
}

json_parse_or_empty() {
  local phase="$1"
  local input_file="$2"
  local python_file="$3"
  local fallback="${4:-[]}"
  local output_file error_file
  output_file="$(mktemp)"
  error_file="$(mktemp)"
  register_temp_file "$output_file"
  register_temp_file "$error_file"

  if python3 "$python_file" "$input_file" > "$output_file" 2>"$error_file"; then
    cat "$output_file"
    return 0
  fi

  log "phase=$phase json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  printf '%s\n' "$fallback"
  return 0
}

json_parse_status_or_unknown() {
  local phase="$1"
  local python_file="$2"
  shift 2
  local output_file error_file
  output_file="$(mktemp)"
  error_file="$(mktemp)"
  register_temp_file "$output_file"
  register_temp_file "$error_file"

  if python3 "$python_file" "$@" > "$output_file" 2>"$error_file"; then
    cat "$output_file"
    return 0
  fi

  log "phase=$phase json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  echo "unknown_parse_error"
  return 0
}

dispatch_ledger_path() {
  local issue_id="$1"
  local safe_issue
  safe_issue="$(printf '%s' "$issue_id" | tr -c 'A-Za-z0-9_.-' '_')"
  echo "$DISPATCH_LEDGER_DIR/$safe_issue.json"
}

write_dispatch_ledger() {
  local issue_id="$1"
  local slug="$2"
  local dispatched_at="$3"
  local ledger_path
  ledger_path="$(dispatch_ledger_path "$issue_id")"
  python3 - "$issue_id" "$slug" "$dispatched_at" > "$ledger_path" <<'PY'
import json
import sys

issue_id, slug, dispatched_at = sys.argv[1:4]
print(json.dumps({
    "issue_id": issue_id,
    "slug": slug,
    "dispatched_at": dispatched_at,
}))
PY
  log "Phase 1: dispatch ledger recorded issue=$issue_id path=$ledger_path"
}

retry_dispatch_ledger() {
  local ledger_path="$1"
  local issue_id dispatched_at metadata_json
  issue_id="$(python3 - "$ledger_path" <<'PY'
import json
import sys

try:
    data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
except Exception:
    data = {}
print(data.get("issue_id", ""))
PY
)"
  dispatched_at="$(python3 - "$ledger_path" <<'PY'
import json
import sys

try:
    data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
except Exception:
    data = {}
print(data.get("dispatched_at", ""))
PY
)"
  if [ -z "$issue_id" ] || [ -z "$dispatched_at" ]; then
    log "Phase 1: dispatch ledger unreadable path=$ledger_path"
    return 1
  fi

  metadata_json="$(python3 - "$dispatched_at" <<'PY'
import json
import sys

print(json.dumps({"publish_state": "dispatching", "dispatched_at": sys.argv[1]}))
PY
)"
  if paperclip_patch_issue_metadata "$issue_id" "$metadata_json"; then
    rm -f "$ledger_path"
    log "Phase 1: dispatch ledger metadata retry succeeded issue=$issue_id"
    return 0
  fi

  log "Phase 1: dispatch ledger metadata retry pending issue=$issue_id path=$ledger_path"
  return 1
}

retry_pending_dispatch_ledgers() {
  local ledger_path
  shopt -s nullglob
  for ledger_path in "$DISPATCH_LEDGER_DIR"/*.json; do
    retry_dispatch_ledger "$ledger_path" || true
  done
  shopt -u nullglob
}

phase1_extract_g4_issues() {
  local input_file="$1"
  local output error_file
  error_file="$(mktemp)"
  register_temp_file "$error_file"
  if output="$(python3 - "$input_file" 2>"$error_file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    items = json.load(fh)
if isinstance(items, dict):
    items = items.get("items", [])
result = [
    {"id": i["id"], "slug": i.get("metadata", {}).get("slug", i["id"])}
    for i in items
    if i.get("status") == "done"
    and i.get("metadata", {}).get("publish_state") == "g4-approved"
]
print(json.dumps(result))
PY
)"; then
    printf '%s\n' "$output"
    return 0
  fi
  log "phase=1 json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  echo "[]"
}

phase1_issue_rows() {
  local input_json="$1"
  local error_file
  error_file="$(mktemp)"
  register_temp_file "$error_file"
  if printf '%s\n' "$input_json" | python3 -c '
import json, sys
items = json.load(sys.stdin)
for i in items:
    print(i["id"] + "\t" + i["slug"])
' 2>"$error_file"; then
    return 0
  fi
  log "phase=1 json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  return 0
}

phase2_extract_dispatching_issues() {
  local input_file="$1"
  local output error_file
  error_file="$(mktemp)"
  register_temp_file "$error_file"
  if output="$(python3 - "$input_file" 2>"$error_file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    items = json.load(fh)
if isinstance(items, dict):
    items = items.get("items", [])
result = [
    {"id": i["id"], "dispatched_at": i.get("metadata", {}).get("dispatched_at", "")}
    for i in items
    if i.get("metadata", {}).get("publish_state") == "dispatching"
]
print(json.dumps(result))
PY
)"; then
    printf '%s\n' "$output"
    return 0
  fi
  log "phase=2 json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  echo "[]"
}

phase2_issue_rows() {
  local input_json="$1"
  local error_file
  error_file="$(mktemp)"
  register_temp_file "$error_file"
  if printf '%s\n' "$input_json" | python3 -c '
import json, sys
items = json.load(sys.stdin)
for i in items:
    print(i["id"] + "\t" + i.get("dispatched_at", ""))
' 2>"$error_file"; then
    return 0
  fi
  log "phase=2 json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  return 0
}

phase2_publish_verifier_id() {
  local input_file="$1"
  local output error_file
  error_file="$(mktemp)"
  register_temp_file "$error_file"
  if output="$(python3 - "$input_file" 2>"$error_file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)
agents = data if isinstance(data, list) else data.get("items", [])
match = next((a["id"] for a in agents if a.get("urlKey") == "publish-verifier"), "")
print(match)
PY
)"; then
    printf '%s\n' "$output"
    return 0
  fi
  log "phase=2 json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  echo ""
}

phase2_run_status() {
  local runs_file="$1"
  local issue_id="$2"
  local dispatched_at="$3"
  local output error_file
  error_file="$(mktemp)"
  register_temp_file "$error_file"
  if output="$(python3 - "$runs_file" "$issue_id" "$dispatched_at" 2>"$error_file" <<'PY'
import json
import sys
from datetime import datetime

runs_file, issue_id, dispatched_at = sys.argv[1:4]
data = json.load(open(runs_file, "r", encoding="utf-8"))
if not dispatched_at:
    print("not_found")
    sys.exit(0)
try:
    boundary = datetime.fromisoformat(dispatched_at.replace("Z", "+00:00"))
except ValueError:
    print("not_found")
    sys.exit(0)
runs = data.get("workflow_runs", [])
match = None
for run in runs:
    run_name = run.get("display_title") or ""
    try:
        created_at = datetime.fromisoformat((run.get("created_at") or "").replace("Z", "+00:00"))
    except ValueError:
        continue
    if run_name == f"publish-{issue_id}" and created_at >= boundary:
        match = run
        break
if match:
    print(match.get("conclusion") or match.get("status", "pending"))
else:
    print("not_found")
PY
)"; then
    printf '%s\n' "$output"
    return 0
  fi
  log "phase=2 json-parse-failed reason=$(sanitize_guard_reason "$error_file")" >&2
  echo "unknown_parse_error"
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
  local endpoint="/api/companies/$COMPANY_ID/issues?limit=2000"
  local auth_args=()
  if [ -n "${PAPERCLIP_API_KEY:-}" ]; then
    auth_args=(-H "Authorization: Bearer ${PAPERCLIP_API_KEY}")
  fi

  local curl_err http_status reason
  curl_err="$(mktemp)"
  if ! http_status="$(curl -sS "${auth_args[@]}" \
    -o "$GUARD_ISSUE_CACHE" \
    -w "%{http_code}" \
    "$PAPERCLIP_URL$endpoint" 2>"$curl_err")"; then
    GUARD_API_ERROR=1
    reason="$(sanitize_guard_reason "$curl_err")"
    if [ -z "${PAPERCLIP_API_KEY:-}" ]; then
      log "guard:no-auth block endpoint=$endpoint http_status=curl-failed reason=$reason"
    fi
    log "guard:api-error endpoint=$endpoint http_status=curl-failed reason=$reason"
    rm -f "$curl_err"
    return 1
  fi
  rm -f "$curl_err"

  if [[ ! "$http_status" =~ ^2 ]]; then
    GUARD_API_ERROR=1
    reason="$(sanitize_guard_reason "$GUARD_ISSUE_CACHE")"
    log "guard:api-error endpoint=$endpoint http_status=$http_status reason=$reason"
    return 1
  fi

  if [ ! -s "$GUARD_ISSUE_CACHE" ]; then
    GUARD_API_ERROR=1
    log "guard:api-error endpoint=$endpoint http_status=$http_status reason=empty-response"
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

  local hash sentinel description_file payload_file response_file error_file issue_id
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
  error_file="$(mktemp)"

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

  local endpoint="/api/companies/$COMPANY_ID/issues"
  local http_status reason
  if http_status="$(curl -sS -X POST "$PAPERCLIP_URL$endpoint" \
    -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" \
    -H "Content-Type: application/json" \
    --data @"$payload_file" \
    -o "$response_file" \
    -w "%{http_code}" 2>"$error_file")" && [[ "$http_status" =~ ^2 ]]; then
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
    rm -f "$description_file" "$payload_file" "$response_file" "$error_file"
    echo "$issue_id"
    return 0
  fi

  if [ -s "$response_file" ]; then
    reason="$(sanitize_guard_reason "$response_file")"
  else
    reason="$(sanitize_guard_reason "$error_file")"
  fi
  if [ -z "${http_status:-}" ] || [ "$http_status" = "000" ]; then
    http_status="curl-failed"
  fi
  log "guard:watchdog-issue-create-failed endpoint=$endpoint http_status=$http_status reason=$reason"
  rm -f "$description_file" "$payload_file" "$response_file" "$error_file"
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

CURRENT_PHASE="phase0"
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
  if [ "$STAGED_COUNT" = "0" ]; then
    log "Phase 0 guard: all staged vault changes excluded; continuing without commit"
  elif git commit -m "$COMMIT_MSG" 2>&1 | tee -a "$LOG"; then
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

CURRENT_PHASE="phase1"
log "Phase 1: scanning for publish_state=g4-approved issues..."
retry_pending_dispatch_ledgers

G4_ISSUES_RESPONSE="$(mktemp)"
register_temp_file "$G4_ISSUES_RESPONSE"
if paperclip_curl_json GET "/api/companies/$COMPANY_ID/issues" "$G4_ISSUES_RESPONSE"; then
  G4_ISSUES_JSON="$(phase1_extract_g4_issues "$G4_ISSUES_RESPONSE")"
else
  G4_ISSUES_JSON="[]"
fi

if [[ -z "$G4_ISSUES_JSON" ]] || [[ "$G4_ISSUES_JSON" == "[]" ]]; then
  log "Phase 1: no g4-approved issues found."
elif [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "Phase 1: SKIPPED — GH_PAT_DISPATCH not set."
else
  while IFS=$'\t' read -r ISSUE_ID SLUG; do
    [ -n "$ISSUE_ID" ] || continue
    LEDGER_PATH="$(dispatch_ledger_path "$ISSUE_ID")"
    if [ -s "$LEDGER_PATH" ]; then
      log "Phase 1: dispatch ledger pending for issue=$ISSUE_ID path=$LEDGER_PATH; skipping duplicate repository_dispatch"
      retry_dispatch_ledger "$LEDGER_PATH" || true
      continue
    fi

    log "Phase 1: dispatching publish-ready for issue=$ISSUE_ID slug=$SLUG"
    DISPATCH_PAYLOAD="$(mktemp)"
    DISPATCH_RESPONSE="$(mktemp)"
    register_temp_file "$DISPATCH_PAYLOAD"
    register_temp_file "$DISPATCH_RESPONSE"
    python3 - "$ISSUE_ID" "$SLUG" > "$DISPATCH_PAYLOAD" <<'PY'
import json
import sys

issue_id, slug = sys.argv[1:3]
print(json.dumps({
    "event_type": "publish-ready",
    "client_payload": {"issue_id": issue_id, "slug": slug},
}))
PY
    if github_curl_json POST "https://api.github.com/repos/$GH_DISPATCH_REPO/dispatches" "$DISPATCH_RESPONSE" "$DISPATCH_PAYLOAD" 204; then
      DISPATCHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      log "Phase 1: dispatch accepted (204) for $ISSUE_ID — setting dispatching at $DISPATCHED_AT"
      write_dispatch_ledger "$ISSUE_ID" "$SLUG" "$DISPATCHED_AT"
      METADATA_JSON="$(python3 - "$DISPATCHED_AT" <<'PY'
import json
import sys

print(json.dumps({"publish_state": "dispatching", "dispatched_at": sys.argv[1]}))
PY
)"
      if paperclip_patch_issue_metadata "$ISSUE_ID" "$METADATA_JSON"; then
        rm -f "$LEDGER_PATH"
        log "Phase 1: metadata patch succeeded for $ISSUE_ID; dispatch ledger cleared"
      else
        log "Phase 1: metadata patch failed after dispatch for $ISSUE_ID; ledger retained path=$LEDGER_PATH"
      fi
    else
      log "Phase 1: dispatch FAILED for $ISSUE_ID"
    fi
  done < <(phase1_issue_rows "$G4_ISSUES_JSON")
fi

# ── Phase 2: dispatching → poll GH Actions → published / dispatch_failed ─────

CURRENT_PHASE="phase2"
log "Phase 2: scanning for publish_state=dispatching issues..."

DISPATCHING_RESPONSE="$(mktemp)"
register_temp_file "$DISPATCHING_RESPONSE"
if paperclip_curl_json GET "/api/companies/$COMPANY_ID/issues" "$DISPATCHING_RESPONSE"; then
  DISPATCHING_JSON="$(phase2_extract_dispatching_issues "$DISPATCHING_RESPONSE")"
else
  DISPATCHING_JSON="[]"
fi

if [[ -z "$DISPATCHING_JSON" ]] || [[ "$DISPATCHING_JSON" == "[]" ]]; then
  log "Phase 2: no dispatching issues found."
elif [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "Phase 2: SKIPPED — GH_PAT_DISPATCH not set."
else
  GH_RUNS_TMP="$(mktemp)"
  AGENTS_TMP="$(mktemp)"
  register_temp_file "$GH_RUNS_TMP"
  register_temp_file "$AGENTS_TMP"
  if ! github_curl_json GET "https://api.github.com/repos/$GH_DISPATCH_REPO/actions/runs?event=repository_dispatch&per_page=20" "$GH_RUNS_TMP"; then
    log "Phase 2: unable to fetch GH Actions runs; will re-check next poll"
    GH_RUNS_AVAILABLE=0
  else
    GH_RUNS_AVAILABLE=1
  fi

  if paperclip_curl_json GET "/api/companies/$COMPANY_ID/agents" "$AGENTS_TMP"; then
    PV_AGENT_ID="$(phase2_publish_verifier_id "$AGENTS_TMP")"
  else
    PV_AGENT_ID=""
  fi

  while IFS=$'\t' read -r ISSUE_ID DISPATCHED_AT; do
    [ -n "$ISSUE_ID" ] || continue
    log "Phase 2: checking GH Actions run for issue=$ISSUE_ID dispatched_at=${DISPATCHED_AT:-unknown}"
    if [ "$GH_RUNS_AVAILABLE" = "1" ]; then
      RUN_STATUS="$(phase2_run_status "$GH_RUNS_TMP" "$ISSUE_ID" "$DISPATCHED_AT")"
    else
      RUN_STATUS="not_found"
    fi
    log "Phase 2: run status for $ISSUE_ID = $RUN_STATUS"
    case "$RUN_STATUS" in
      success)
        log "Phase 2: marking $ISSUE_ID published url=$PROD_URL"
        PUBLISHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        METADATA_JSON="$(python3 - "$PROD_URL" "$PUBLISHED_AT" <<'PY'
import json
import sys

print(json.dumps({
    "publish_state": "published",
    "published_url": sys.argv[1],
    "published_at": sys.argv[2],
}))
PY
)"
        paperclip_patch_issue_metadata "$ISSUE_ID" "$METADATA_JSON" || true
        if [[ -n "$PV_AGENT_ID" ]]; then
          log "Phase 2: triggering publish-verifier (G5) for $ISSUE_ID"
          VERIFY_PAYLOAD="$(mktemp)"
          VERIFY_RESPONSE="$(mktemp)"
          register_temp_file "$VERIFY_PAYLOAD"
          register_temp_file "$VERIFY_RESPONSE"
          python3 - "$ISSUE_ID" > "$VERIFY_PAYLOAD" <<'PY'
import json
import sys

print(json.dumps({"context": {"issue_id": sys.argv[1]}}))
PY
          paperclip_curl_json POST "/api/agents/$PV_AGENT_ID/heartbeat/invoke" "$VERIFY_RESPONSE" "$VERIFY_PAYLOAD" || true
        fi
        ;;
      failure|cancelled|timed_out|action_required|startup_failure)
        log "Phase 2: marking $ISSUE_ID dispatch_failed (run_status=$RUN_STATUS)"
        METADATA_JSON="$(python3 - "$RUN_STATUS" <<'PY'
import json
import sys

print(json.dumps({
    "publish_state": "dispatch_failed",
    "dispatch_failure_reason": "GH Actions run status: " + sys.argv[1],
}))
PY
)"
        paperclip_patch_issue_metadata "$ISSUE_ID" "$METADATA_JSON" || true
        ;;
      not_found|in_progress|queued|waiting|pending)
        log "Phase 2: run not yet complete ($RUN_STATUS) for $ISSUE_ID — will re-check next poll"
        ;;
      unknown_parse_error)
        log "Phase 2: malformed GH Actions run data for $ISSUE_ID — skipping"
        ;;
      *)
        log "Phase 2: unknown run status '$RUN_STATUS' for $ISSUE_ID — skipping"
        ;;
    esac
  done < <(phase2_issue_rows "$DISPATCHING_JSON")
fi

TERMINAL_REASON="complete"

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
