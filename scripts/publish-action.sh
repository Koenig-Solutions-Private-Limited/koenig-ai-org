#!/usr/bin/env bash
# publish-action.sh — closes the loop on the auto-publish pipeline (V3.0).
#
# Phase 1: Scans for publish_state=g4-approved → fires repository_dispatch to
#          the per-track GitHub Actions repo, sets publish_state=dispatching +
#          dispatched_at + dispatch_repo.
# Phase 2: Scans for publish_state=dispatching → polls GH Actions on the
#          per-issue dispatch_repo (metadata.dispatch_repo, fallback to the
#          organic repo for in-flight items dispatched before this change),
#          sets publish_state=published or dispatch_failed.
#
# Per-track dispatch contract (domain split, 2026-06-12):
#   COURSE slugs read vault/courses/<slug>/outline.md frontmatter `course_track`.
#     course_track == "career"  → Career Compass vertical:
#         dispatch repo Koenig-Solutions-Private-Limited/koenig-career-academy,
#         prod URL https://academy.koenig-solutions.com
#     course_track absent/other → organic academy (current defaults).
#   BLOG slugs read vault/blogs/<slug>/draft.md frontmatter `blog_track`.
#     blog_track == "career"    → Career Compass vertical (same as above).
#     blog_track absent/other   → organic academy (current defaults).
#   The chosen dispatch repo is persisted in issue metadata.dispatch_repo at
#   dispatch time so Phase 2 polls the correct repo even across script versions.
#
# Requires GH_PAT_DISPATCH (repo+workflow scopes on BOTH dispatch repos) in
# $ENV_FILE. Wired to launchd via com.koenig.publish-action.plist (every 60s).
# Logs to ~/.paperclip/logs/publish-action.log.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.koenig"
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"
CANONICAL_COMPANY_ID="2a77f89b-33f0-4133-a20c-77ddaac5e744"
# Organic academy (default track) — learnovaBeast → academy.kspl.tech.
GH_DISPATCH_REPO="Koenig-Solutions-Private-Limited/learnovaBeast"
PROD_URL="https://academy.kspl.tech"
# Career Compass vertical (course_track: career) — koenig-career-academy →
# academy.koenig-solutions.com. Domain split, 2026-06-12.
CAREER_GH_DISPATCH_REPO="Koenig-Solutions-Private-Limited/koenig-career-academy"
CAREER_PROD_URL="https://academy.koenig-solutions.com"
# Path to the koenig-career-academy scripts directory (KOEA-10929 validator gate).
# Override via env var when the workspace lives at a non-standard path.
CAREER_ACADEMY_SCRIPTS="${CAREER_ACADEMY_SCRIPTS:-/paperclip/instances/default/workspaces/koenig-career-academy/scripts}"
# IndexNow (organic academy only) — key is public/non-secret, served at keyLocation.
INDEXNOW_HOST="academy.kspl.tech"
INDEXNOW_KEY="e295e26297adb46e2256b70ef90df085"
INDEXNOW_KEY_LOCATION="https://academy.kspl.tech/e295e26297adb46e2256b70ef90df085.txt"
INDEXNOW_API_URL="https://api.indexnow.org/indexnow"
LOG_DIR="${PAPERCLIP_LOG_DIR:-${HOME}/.paperclip/logs}"
SKIPPED_SENTINEL="$LOG_DIR/publish-action.skipped"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/publish-action.log"
cd "$REPO_ROOT"

# Resolve the track for a slug. Course slugs map to vault/courses/<slug>/outline.md
# (frontmatter `course_track: career`); blog slugs map to vault/blogs/<slug>/draft.md
# (frontmatter `blog_track: career`). Either "career" routes to Career Compass.
# Unmatched slugs fall through to the organic track.
# Echoes the track name: "career" or "organic".
track_for_slug() {
  local slug="${1:-}"
  local outline="$REPO_ROOT/vault/courses/$slug/outline.md"
  if [[ -n "$slug" && -f "$outline" ]]; then
    local track
    track="$(awk -F: '/^course_track:/{gsub(/[ \t"'"'"']/,"",$2); print $2; exit}' "$outline")"
    if [[ "$track" == "career" ]]; then
      echo "career"
      return 0
    fi
  fi
  local draft="$REPO_ROOT/vault/blogs/$slug/draft.md"
  if [[ -n "$slug" && -f "$draft" ]]; then
    local blog_track
    blog_track="$(awk -F: '/^blog_track:/{gsub(/[ \t"'"'"']/,"",$2); print $2; exit}' "$draft")"
    if [[ "$blog_track" == "career" ]]; then
      echo "career"
      return 0
    fi
  fi
  echo "organic"
}

# Echo the GitHub dispatch repo for a track.
dispatch_repo_for_track() {
  if [[ "${1:-}" == "career" ]]; then
    echo "$CAREER_GH_DISPATCH_REPO"
  else
    echo "$GH_DISPATCH_REPO"
  fi
}

# Echo the production base URL for a track.
prod_url_for_track() {
  if [[ "${1:-}" == "career" ]]; then
    echo "$CAREER_PROD_URL"
  else
    echo "$PROD_URL"
  fi
}

# Build the published URL for a slug, track-aware. Only the base (domain) varies
# by track; the path shape is unchanged from V3.0 (/blog/<slug>, or the track
# home page for an empty slug).
published_url_for_slug() {
  local slug="${1:-}"
  local track="${2:-organic}"
  local base
  base="$(prod_url_for_track "$track")"
  if [[ -n "$slug" ]]; then
    echo "$base/blog/$slug"
  else
    echo "$base"
  fi
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

indexnow_should_submit_url() {
  local url="${1:-}"
  [[ "$url" == "https://academy.kspl.tech" || "$url" == https://academy.kspl.tech/* ]]
}

submit_indexnow_url() {
  local url="${1:-}"
  local curl_bin="${INDEXNOW_CURL_BIN:-curl}"
  local payload_file response_file http_code body_excerpt

  if [[ -z "$url" ]]; then
    log "WARN: IndexNow skip — empty URL"
    return 0
  fi
  if [[ "$url" == "https://academy.koenig-solutions.com" || "$url" == https://academy.koenig-solutions.com/* ]]; then
    log "IndexNow skip: career URL ($url) — Career Compass uses separate host/key"
    return 0
  fi
  if ! indexnow_should_submit_url "$url"; then
    log "IndexNow skip: non-organic URL ($url)"
    return 0
  fi

  payload_file="$(mktemp)"
  response_file="$(mktemp)"
  INDEXNOW_URL="$url" python3 -c '
import json, os
print(json.dumps({
    "host": "academy.kspl.tech",
    "key": "e295e26297adb46e2256b70ef90df085",
    "keyLocation": "https://academy.kspl.tech/e295e26297adb46e2256b70ef90df085.txt",
    "urlList": [os.environ["INDEXNOW_URL"]],
}))
' > "$payload_file"

  http_code="$("$curl_bin" -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$INDEXNOW_API_URL" \
    -H "Content-Type: application/json" \
    --data-binary @"$payload_file" \
    --retry 2 --retry-delay 2 --connect-timeout 10 --max-time 30 \
    2>/dev/null || echo "000")"

  body_excerpt="$(head -c 200 "$response_file" | tr '\n' ' ')"
  case "$http_code" in
    200|202)
      log "IndexNow: accepted HTTP $http_code for $url${body_excerpt:+ — $body_excerpt}"
      ;;
    *)
      log "WARN: IndexNow submission failed HTTP $http_code for $url${body_excerpt:+ — $body_excerpt}"
      ;;
  esac

  rm -f "$payload_file" "$response_file"
  return 0
}

run_indexnow_self_test() {
  local mock_dir payload_capture http_code_file call_count_file output
  mock_dir="$(mktemp -d)"
  payload_capture="${mock_dir}/payload.json"
  http_code_file="${mock_dir}/http_code"
  call_count_file="${mock_dir}/call_count"
  echo "0" > "$call_count_file"

  cat > "${mock_dir}/curl" <<'MOCKCURL'
#!/usr/bin/env bash
set -euo pipefail
count_file="${MOCK_INDEXNOW_CALL_COUNT_FILE:?}"
payload_file="${MOCK_INDEXNOW_PAYLOAD_FILE:?}"
http_file="${MOCK_INDEXNOW_HTTP_CODE_FILE:?}"
count="$(cat "$count_file")"
echo $((count + 1)) > "$count_file"
data=""
out_file=""
args=("$@")
i=0
while [ "$i" -lt "${#args[@]}" ]; do
  case "${args[$i]}" in
    -o)
      out_file="${args[$((i + 1))]}"
      i=$((i + 2))
      ;;
    -d|--data|--data-raw)
      data="${args[$((i + 1))]}"
      i=$((i + 2))
      ;;
    --data-binary)
      arg="${args[$((i + 1))]}"
      if [[ "$arg" == @* ]]; then
        data="$(cat "${arg#@}")"
      else
        data="$arg"
      fi
      i=$((i + 2))
      ;;
    *)
      i=$((i + 1))
      ;;
  esac
done
printf '%s' "$data" > "$payload_file"
if [[ -n "$out_file" ]]; then
  printf '' > "$out_file"
fi
cat "$http_file"
MOCKCURL
  chmod +x "${mock_dir}/curl"

  export MOCK_INDEXNOW_PAYLOAD_FILE="$payload_capture"
  export MOCK_INDEXNOW_HTTP_CODE_FILE="$http_code_file"
  export MOCK_INDEXNOW_CALL_COUNT_FILE="$call_count_file"
  export INDEXNOW_CURL_BIN="${mock_dir}/curl"

  assert_payload() {
    local expected_url="$1"
    python3 - "$payload_capture" "$expected_url" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    payload = json.load(fh)
expected_url = sys.argv[2]
required = {
    "host": "academy.kspl.tech",
    "key": "e295e26297adb46e2256b70ef90df085",
    "keyLocation": "https://academy.kspl.tech/e295e26297adb46e2256b70ef90df085.txt",
}
for key, value in required.items():
    if payload.get(key) != value:
        raise SystemExit(f"payload mismatch for {key}: {payload.get(key)!r}")
url_list = payload.get("urlList")
if not isinstance(url_list, list) or len(url_list) != 1 or url_list[0] != expected_url:
    raise SystemExit(f"unexpected urlList: {url_list!r}")
PY
  }

  echo "200" > "$http_code_file"
  : > "$payload_capture"
  echo "0" > "$call_count_file"
  output="$(submit_indexnow_url "https://academy.kspl.tech/blog/self-test-slug" 2>&1)"
  [[ "$output" == *"IndexNow: accepted HTTP 200"* ]] || {
    echo "indexnow self-test failed: expected HTTP 200 acceptance" >&2
    echo "$output" >&2
    return 1
  }
  assert_payload "https://academy.kspl.tech/blog/self-test-slug"

  echo "202" > "$http_code_file"
  : > "$payload_capture"
  echo "0" > "$call_count_file"
  output="$(submit_indexnow_url "https://academy.kspl.tech/blog/self-test-slug" 2>&1)"
  [[ "$output" == *"IndexNow: accepted HTTP 202"* ]] || {
    echo "indexnow self-test failed: expected HTTP 202 acceptance" >&2
    echo "$output" >&2
    return 1
  }

  echo "400" > "$http_code_file"
  : > "$payload_capture"
  echo "0" > "$call_count_file"
  output="$(submit_indexnow_url "https://academy.kspl.tech/blog/self-test-slug" 2>&1)"
  [[ "$output" == *"WARN: IndexNow submission failed HTTP 400"* ]] || {
    echo "indexnow self-test failed: expected HTTP 400 warning" >&2
    echo "$output" >&2
    return 1
  }

  echo "0" > "$call_count_file"
  output="$(submit_indexnow_url "https://academy.koenig-solutions.com/blog/career-slug" 2>&1)"
  [[ "$(cat "$call_count_file")" == "0" ]] || {
    echo "indexnow self-test failed: career URL should not call IndexNow" >&2
    return 1
  }
  [[ "$output" == *"IndexNow skip: career URL"* ]] || {
    echo "indexnow self-test failed: expected career URL skip log" >&2
    echo "$output" >&2
    return 1
  }

  rm -rf "$mock_dir"
  echo "indexnow self-test ok"
  return 0
}

if [[ "${1:-}" == "--self-test-indexnow" ]]; then
  run_indexnow_self_test
  exit $?
fi

mark_dispatch_skipped() {
  local phase="$1"
  log "WARN: skipping $phase — fix .env.koenig (GH_PAT_DISPATCH missing)"
  mkdir -p "$(dirname "$SKIPPED_SENTINEL")"
  printf '%s phase=%s reason=GH_PAT_DISPATCH_missing\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$phase" > "$SKIPPED_SENTINEL"
}

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

fetch_all_issues() {
  if [ -n "${GUARD_ISSUE_CACHE:-}" ] && [ -s "$GUARD_ISSUE_CACHE" ]; then
    return 0
  fi

  GUARD_ISSUE_CACHE="$LOG_DIR/.issue-cache.$$.json"
  if [ -z "${PAPERCLIP_AUTH_TOKEN:-}" ]; then
    GUARD_API_ERROR=1
    log "guard:no-auth → block (PAPERCLIP_BOARD_TOKEN/PAPERCLIP_API_KEY missing)"
    return 1
  fi

  local aggregate_tmp page_tmp normalized_tmp
  local offset=0
  local page_size=1000

  aggregate_tmp="$(mktemp)"
  echo "[]" > "$aggregate_tmp"

  while true; do
    page_tmp="$(mktemp)"
    normalized_tmp="$(mktemp)"
    if ! curl -sf "${AUTH_HEADER[@]}" \
      "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues?limit=${page_size}&offset=${offset}" \
      -o "$page_tmp"; then
      rm -f "$aggregate_tmp" "$page_tmp" "$normalized_tmp"
      GUARD_API_ERROR=1
      log "guard:api-error"
      return 1
    fi

    if ! python3 - "$page_tmp" > "$normalized_tmp" 2>/dev/null <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)
items = data.get("items", data) if isinstance(data, dict) else data
if not isinstance(items, list):
    raise ValueError("issue list payload must be an array or object with items[]")
print(json.dumps(items))
PY
    then
      rm -f "$aggregate_tmp" "$page_tmp" "$normalized_tmp"
      GUARD_API_ERROR=1
      log "guard:api-error invalid issue response payload"
      return 1
    fi

    if ! python3 - "$aggregate_tmp" "$normalized_tmp" > "$GUARD_ISSUE_CACHE" 2>/dev/null <<'PY'
import json
import sys

aggregate_path, page_path = sys.argv[1], sys.argv[2]
with open(aggregate_path, "r", encoding="utf-8") as fh:
    aggregate = json.load(fh)
with open(page_path, "r", encoding="utf-8") as fh:
    page = json.load(fh)
if not isinstance(aggregate, list) or not isinstance(page, list):
    raise ValueError("normalized payload is not an array")
aggregate.extend(page)
print(json.dumps(aggregate))
PY
    then
      rm -f "$aggregate_tmp" "$page_tmp" "$normalized_tmp" "$GUARD_ISSUE_CACHE"
      GUARD_API_ERROR=1
      log "guard:api-error failed to merge issue pages"
      return 1
    fi

    mv "$GUARD_ISSUE_CACHE" "$aggregate_tmp"
    local page_count
    page_count="$(python3 - "$normalized_tmp" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)
print(len(data))
PY
)"
    rm -f "$page_tmp" "$normalized_tmp"
    if [ "$page_count" -lt "$page_size" ]; then
      break
    fi
    offset=$((offset + page_size))
  done

  mv "$aggregate_tmp" "$GUARD_ISSUE_CACHE"
  log "issue-list: fetched $((offset + page_count)) issues (paginated, page_size=$page_size)"

  return 0
}

slug_to_issue_info() {
  local slug="$1"
  fetch_all_issues || {
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
    if not isinstance(item, dict):
        continue
    metadata = item.get("metadata")
    if not isinstance(metadata, dict):
        metadata = {}
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

  if [ -z "${PAPERCLIP_AUTH_TOKEN:-}" ]; then
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
    "${AUTH_HEADER[@]}" \
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
  staged="$(git diff --cached --name-only --diff-filter=ACMR -- vault/ \
    | grep -E '^vault/(blogs/[^/]+|courses/[^/]+(/[^/]+)*)/[^/]+\.md$' || true)"
  [ -z "$staged" ] && return 0

  while IFS= read -r F; do
    local OLD NEW SLUG ISSUE_INFO ISSUE STATE
    if [[ ! -f "$F" ]]; then
      log "guard: skip missing staged file=$F"
      continue
    fi
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

PAPERCLIP_URL="$(env_value PAPERCLIP_API_URL)"
if [[ -z "$PAPERCLIP_URL" ]]; then
  PAPERCLIP_URL="$(env_value PAPERCLIP_URL)"
fi
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"

COMPANY_ID="$(env_value PAPERCLIP_COMPANY_ID)"
if [[ -z "$COMPANY_ID" ]]; then
  COMPANY_ID="$(env_value COMPANY_ID)"
fi
if [[ -z "$COMPANY_ID" ]]; then
  log "ERROR: PAPERCLIP_COMPANY_ID/COMPANY_ID missing in environment/$ENV_FILE. Skipping publish-action run."
  exit 0
fi

PAPERCLIP_AUTH_TOKEN="$(env_value PAPERCLIP_BOARD_TOKEN)"
if [[ -z "$PAPERCLIP_AUTH_TOKEN" ]]; then
  PAPERCLIP_AUTH_TOKEN="$(env_value PAPERCLIP_API_KEY)"
fi
if [[ -z "$PAPERCLIP_AUTH_TOKEN" ]]; then
  log "ERROR: PAPERCLIP_BOARD_TOKEN/PAPERCLIP_API_KEY missing in environment/$ENV_FILE. Skipping publish-action run."
  exit 0
fi
AUTH_HEADER=(-H "Authorization: Bearer $PAPERCLIP_AUTH_TOKEN")

GH_PAT_DISPATCH="$(env_value GH_PAT_DISPATCH)"
if [[ -z "$GH_PAT_DISPATCH" ]]; then
  GH_PAT_DISPATCH="$(grep -m1 -E "^(GH_TOKEN_BOT|GH_TOKEN)=" "$ENV_FILE" | cut -d= -f2- || true)"
fi
if [[ -z "$GH_PAT_DISPATCH" ]]; then
  log "WARN: GH_PAT_DISPATCH missing in $ENV_FILE — Phase 1 and Phase 2 will be skipped."
fi
rm -f "$SKIPPED_SENTINEL"

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

if ! fetch_all_issues; then
  G4_ISSUES_JSON="[]"
else
  G4_ISSUES_JSON="$(python3 - "$GUARD_ISSUE_CACHE" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    items = json.load(fh)
# 2026-06-11 KOEA-6012: defensive — earlier shape AttributeError ('list' object
# has no attribute 'get') was caused by a page-shape edge case where some items
# come through as bare lists rather than dicts. Skip those safely instead of
# crashing Phase 1.
result = []
skipped = 0
for i in items:
    if not isinstance(i, dict):
        skipped += 1
        continue
    md = i.get('metadata')
    # 2026-06-11 KOEA-6012 fix #2: metadata is sometimes a list (or null or
    # primitive) instead of a dict — the `or {}` previously did not normalize
    # truthy non-empty lists. Force-coerce to {} when not a dict so .get()
    # never raises.
    if not isinstance(md, dict):
        md = {}
    if i.get('status') == 'done' and md.get('publish_state') == 'g4-approved':
        result.append({'id': i['id'], 'slug': md.get('slug', i['id'])})
if skipped:
    sys.stderr.write(f"phase1-scan: skipped {skipped} non-dict items\n")
print(json.dumps(result))
PY
)"
fi

if [[ -z "$G4_ISSUES_JSON" ]] || [[ "$G4_ISSUES_JSON" == "[]" ]]; then
  log "Phase 1: no g4-approved issues found."
elif [[ -z "$GH_PAT_DISPATCH" ]]; then
  mark_dispatch_skipped "phase1"
else
  while IFS=$'\t' read -r ISSUE_ID SLUG; do
    TRACK="$(track_for_slug "$SLUG")"
    DISPATCH_REPO="$(dispatch_repo_for_track "$TRACK")"
    # Career-track: run the chapter validator before dispatch (KOEA-10929).
    # Fails closed: if the validator is missing or fails, skip dispatch and leave
    # publish_state=g4-approved so the next run retries once content is fixed.
    if [[ "$TRACK" == "career" ]]; then
      CAREER_VALIDATOR="$CAREER_ACADEMY_SCRIPTS/validate-course-chapters.mjs"
      if [[ ! -f "$CAREER_VALIDATOR" ]]; then
        log "Phase 1: career validator not found at $CAREER_VALIDATOR — skipping Career dispatch (fail closed)"
        continue
      fi
      log "Phase 1: running career validator for slug=$SLUG"
      if ! KOENIG_VAULT_ROOT="$REPO_ROOT/vault" \
           node "$CAREER_VALIDATOR" --slug "$SLUG" >> "$LOG" 2>&1; then
        log "Phase 1: career validator FAILED for slug=$SLUG — skipping dispatch (g4-approved unchanged)"
        continue
      fi
      log "Phase 1: career validator PASSED for slug=$SLUG"
    fi
    log "Phase 1: dispatching publish-ready for issue=$ISSUE_ID slug=$SLUG track=$TRACK repo=$DISPATCH_REPO"
    DISPATCH_HTTP="$(curl -s -o /dev/null -w "%{http_code}" -X POST \
      "https://api.github.com/repos/$DISPATCH_REPO/dispatches" \
      -H "Authorization: Bearer $GH_PAT_DISPATCH" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -d "$(ISSUE_ID="$ISSUE_ID" SLUG="$SLUG" python3 -c 'import json,os;print(json.dumps({"event_type":"publish-ready","client_payload":{"issue_id":os.environ["ISSUE_ID"],"slug":os.environ["SLUG"]}}))')")"
    if [[ "$DISPATCH_HTTP" == "204" ]]; then
      DISPATCHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      log "Phase 1: dispatch accepted (204) for $ISSUE_ID — setting dispatching at $DISPATCHED_AT (repo=$DISPATCH_REPO)"
      curl -sX PATCH "${AUTH_HEADER[@]}" "$PAPERCLIP_URL/api/issues/$ISSUE_ID" \
        -H "Content-Type: application/json" \
        -d "$(SLUG="$SLUG" DISPATCHED_AT="$DISPATCHED_AT" DISPATCH_REPO="$DISPATCH_REPO" python3 -c 'import json,os;print(json.dumps({"metadata":{"publish_state":"dispatching","dispatched_at":os.environ["DISPATCHED_AT"],"dispatch_repo":os.environ["DISPATCH_REPO"],"slug":os.environ["SLUG"]}}))')" \
        -o /dev/null
    else
      log "Phase 1: dispatch FAILED (HTTP $DISPATCH_HTTP) for $ISSUE_ID (repo=$DISPATCH_REPO)"
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

if ! fetch_all_issues; then
  DISPATCHING_JSON="[]"
else
  DISPATCHING_JSON="$(python3 - "$GUARD_ISSUE_CACHE" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    items = json.load(fh)
result = []
for i in items:
    if not isinstance(i, dict):
        continue
    md = i.get('metadata')
    if not isinstance(md, dict):
        md = {}
    if md.get('publish_state') == 'dispatching':
        # dispatch_repo persisted by Phase 1 (domain split, 2026-06-12). Items
        # dispatched before this change lack it — leave blank; the shell falls
        # back to the organic dispatch repo so in-flight publishes still poll.
        result.append({
            'id': i['id'],
            'dispatched_at': md.get('dispatched_at', ''),
            'slug': md.get('slug', ''),
            'dispatch_repo': md.get('dispatch_repo', ''),
        })
print(json.dumps(result))
PY
)"
fi

if [[ -z "$DISPATCHING_JSON" ]] || [[ "$DISPATCHING_JSON" == "[]" ]]; then
  log "Phase 2: no dispatching issues found."
elif [[ -z "$GH_PAT_DISPATCH" ]]; then
  mark_dispatch_skipped "phase2"
else
  # GH Actions runs are fetched per dispatch repo, cached for this poll so that
  # a mixed batch (organic + career) hits each repo's API at most once.
  GH_RUNS_DIR="$(mktemp -d)"
  fetch_runs_for_repo() {
    local repo="$1"
    local cache="$GH_RUNS_DIR/$(printf '%s' "$repo" | tr '/' '_').json"
    if [[ ! -s "$cache" ]]; then
      curl -s \
        "https://api.github.com/repos/$repo/actions/runs?event=repository_dispatch&per_page=20" \
        -H "Authorization: Bearer $GH_PAT_DISPATCH" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" > "$cache"
    fi
    echo "$cache"
  }

  PV_AGENT_ID="$(curl -s "${AUTH_HEADER[@]}" "$PAPERCLIP_URL/api/companies/$COMPANY_ID/agents" | python3 -c "
import json, sys
data = json.load(sys.stdin)
agents = data if isinstance(data, list) else data.get('items', [])
match = next((a['id'] for a in agents if a.get('urlKey') == 'publish-verifier'), '')
print(match)
")"

  while IFS=$'\t' read -r ISSUE_ID DISPATCHED_AT SLUG DISPATCH_REPO; do
    # Fallback to the organic repo for items dispatched before dispatch_repo
    # was persisted (domain split, 2026-06-12).
    if [[ -z "$DISPATCH_REPO" ]]; then
      DISPATCH_REPO="$GH_DISPATCH_REPO"
    fi
    if [[ "$DISPATCH_REPO" == "$CAREER_GH_DISPATCH_REPO" ]]; then
      TRACK="career"
    else
      TRACK="organic"
    fi
    PUBLISHED_URL="$(published_url_for_slug "$SLUG" "$TRACK")"
    GH_RUNS_TMP="$(fetch_runs_for_repo "$DISPATCH_REPO")"
    log "Phase 2: checking GH Actions run for issue=$ISSUE_ID dispatched_at=${DISPATCHED_AT:-unknown} slug=${SLUG:-none} repo=$DISPATCH_REPO published_url=$PUBLISHED_URL"
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
        log "Phase 2: marking $ISSUE_ID published url=$PUBLISHED_URL"
        curl -sX PATCH "${AUTH_HEADER[@]}" "$PAPERCLIP_URL/api/issues/$ISSUE_ID" \
          -H "Content-Type: application/json" \
          -d "$(python3 -c "import json; print(json.dumps({'metadata':{'publish_state':'published','published_url':'$PUBLISHED_URL','published_at':'$(date -u +%Y-%m-%dT%H:%M:%SZ)'}}))")" \
          -o /dev/null
        submit_indexnow_url "$PUBLISHED_URL"
        if [[ -n "$PV_AGENT_ID" ]]; then
          log "Phase 2: triggering publish-verifier (G5) for $ISSUE_ID"
          curl -sX POST "$PAPERCLIP_URL/api/agents/$PV_AGENT_ID/heartbeat/invoke" \
            "${AUTH_HEADER[@]}" \
            -H "Content-Type: application/json" \
            -d "$(python3 -c "import json; print(json.dumps({'context':{'issue_id':'$ISSUE_ID'}}))")" \
            -o /dev/null
        fi
        ;;
      failure|cancelled|timed_out|action_required|startup_failure)
        log "Phase 2: marking $ISSUE_ID dispatch_failed (run_status=$RUN_STATUS)"
        curl -sX PATCH "${AUTH_HEADER[@]}" "$PAPERCLIP_URL/api/issues/$ISSUE_ID" \
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
    print(i['id'] + '\t' + i.get('dispatched_at', '') + '\t' + i.get('slug', '') + '\t' + i.get('dispatch_repo', ''))
")

  rm -rf "$GH_RUNS_DIR"
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
