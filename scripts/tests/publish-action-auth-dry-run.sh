#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/scripts/publish-action.sh"
ENV_FILE="$ROOT/.env.koenig"
OLD_COMPANY_ID="1ce472ae-c3fe-47cb-ae1c-99cd79a43b8d"
CANONICAL_COMPANY_ID="2a77f89b-33f0-4133-a20c-77ddaac5e744"
SECRET_TOKEN="fixture-board-token-secret"
GH_TOKEN="fixture-gh-token-secret"
TMP="$(mktemp -d)"
BACKUP_ENV="$TMP/env.backup"
HAD_ENV=0

cleanup() {
  if [[ "$HAD_ENV" == "1" ]]; then
    cp "$BACKUP_ENV" "$ENV_FILE"
  else
    rm -f "$ENV_FILE"
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

if [[ -f "$ENV_FILE" ]]; then
  HAD_ENV=1
  cp "$ENV_FILE" "$BACKUP_ENV"
fi

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

write_curl_stub() {
  local mode="$1"
  mkdir -p "$TMP/bin"
  cat > "$TMP/bin/curl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "CALL $*" >> "$CURL_CALLS"

status="200"
body="{}"
case "${CURL_STUB_MODE:-ok}" in
  fail-paperclip)
    if printf '%s\n' "$*" | grep -q "/api/companies/"; then
      status="500"
      body='{"token":"fixture-board-token-secret","message":"bad token fixture-board-token-secret"}'
    fi
    ;;
  ok)
    if printf '%s\n' "$*" | grep -q "/api/companies/.*/issues"; then
      body='{"items":[{"id":"issue-g4","status":"done","metadata":{"publish_state":"g4-approved","slug":"ready-slug"}},{"id":"issue-dispatching","status":"done","metadata":{"publish_state":"dispatching","dispatched_at":"2026-05-14T00:00:00Z"}}]}'
    elif printf '%s\n' "$*" | grep -q "/api/companies/.*/agents"; then
      body='{"items":[{"id":"publish-verifier-id","urlKey":"publish-verifier"}]}'
    elif printf '%s\n' "$*" | grep -q "api.github.com/repos/.*/actions/runs"; then
      body='{"workflow_runs":[{"display_title":"publish-issue-dispatching","created_at":"2026-05-14T00:01:00Z","conclusion":"success"}]}'
    else
      status="204"
      body=""
    fi
    ;;
esac

out=""
writeout=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      out="$2"
      shift 2
      ;;
    -w)
      writeout="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n "$out" ]]; then
  printf '%s' "$body" > "$out"
else
  printf '%s' "$body"
fi

if [[ "$writeout" == "%{http_code}" ]]; then
  printf '%s' "$status"
fi
SH
  chmod +x "$TMP/bin/curl"
  export PATH="$TMP/bin:$PATH"
  export CURL_STUB_MODE="$mode"
  export CURL_CALLS="$TMP/curl-calls.log"
  : > "$CURL_CALLS"
}

write_env() {
  local include_board="${1:-yes}"
  {
    printf 'PAPERCLIP_API_URL=http://paperclip.fixture\n'
    printf 'PAPERCLIP_COMPANY_ID=%s\n' "$CANONICAL_COMPANY_ID"
    printf 'GH_PAT_DISPATCH=%s\n' "$GH_TOKEN"
    if [[ "$include_board" == "yes" ]]; then
      printf 'PAPERCLIP_BOARD_TOKEN=%s\n' "$SECRET_TOKEN"
    fi
  } > "$ENV_FILE"
}

grep -q "$OLD_COMPANY_ID" "$SCRIPT" && fail "old default company id still appears in publish-action.sh"

export HOME="$TMP/home"
mkdir -p "$HOME"
write_curl_stub ok
write_env no
PUBLISH_ACTION_DRY_RUN=1 bash "$SCRIPT" >/dev/null
grep -q "PAPERCLIP_BOARD_TOKEN missing" "$HOME/.paperclip/logs/publish-action.log" || fail "missing board token was not logged"
[[ ! -s "$CURL_CALLS" ]] || fail "curl was called despite missing board token"

rm -rf "$HOME"
export HOME="$TMP/home-dry-run"
mkdir -p "$HOME"
write_curl_stub ok
write_env yes
PUBLISH_ACTION_DRY_RUN=1 bash "$SCRIPT" >/dev/null
LOG="$HOME/.paperclip/logs/publish-action.log"
grep -q "Phase 1: scanning" "$LOG" || fail "Phase 1 did not run"
grep -q "Phase 2: scanning" "$LOG" || fail "Phase 2 did not run"
grep -q "DRY-RUN would dispatch publish-ready" "$LOG" || fail "repository_dispatch was not dry-run gated"
grep -q "DRY-RUN would PATCH Paperclip /api/issues/issue-g4" "$LOG" || fail "dispatching PATCH was not dry-run gated"
grep -q "DRY-RUN would PATCH Paperclip /api/issues/issue-dispatching" "$LOG" || fail "published PATCH was not dry-run gated"
grep -q "DRY-RUN would POST Paperclip /api/agents/publish-verifier-id/heartbeat/invoke" "$LOG" || fail "publish-verifier invoke was not dry-run gated"
grep -q "Authorization: Bearer $SECRET_TOKEN" "$CURL_CALLS" || fail "Paperclip Authorization header missing"
grep -q "$CANONICAL_COMPANY_ID" "$CURL_CALLS" || fail "canonical company id was not used"
! grep -q "$SECRET_TOKEN" "$LOG" || fail "board token leaked to publish-action log"
! grep -q "$GH_TOKEN" "$LOG" || fail "GitHub token leaked to publish-action log"

rm -rf "$HOME"
export HOME="$TMP/home-failure"
mkdir -p "$HOME"
write_curl_stub fail-paperclip
write_env yes
if PUBLISH_ACTION_DRY_RUN=1 bash "$SCRIPT" >/dev/null 2>&1; then
  fail "Paperclip failure did not fail the script"
fi
FAIL_LOG="$HOME/.paperclip/logs/publish-action.log"
grep -q "Paperclip API FAILED" "$FAIL_LOG" || fail "Paperclip failure was not logged"
grep -q "status=500" "$FAIL_LOG" || fail "HTTP status was not logged"
grep -q "token=\\[REDACTED\\]" "$FAIL_LOG" || fail "failure reason was not sanitized"
! grep -q "$SECRET_TOKEN" "$FAIL_LOG" || fail "secret token leaked in failure log"

echo "publish-action auth/dry-run fixture passed"
