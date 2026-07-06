#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER="$ROOT_DIR/scripts/g4-notify.sh"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "ASSERT FAILED: missing '$needle'" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "ASSERT FAILED: found forbidden '$needle'" >&2
    exit 1
  fi
}

validate_json() {
  local payload="$1"
  python3 -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$payload" >/dev/null
}

run_helper() {
  "$HELPER" \
    --issue "KOEA-5102" \
    --approval-id "e33050ef-299f-4553-917d-eebbc8f36e7c" \
    --title "G4 approval smoke" \
    --preview-url "https://preview.example.test/item" \
    --vault-path "vault/courses/demo/ch1.md" \
    --gates "G0,G2,G3" "$@"
}

# ── Mock webhook script ──────────────────────────────────────────────────────
# Write the Python mock server to a temp file so it can be run without heredoc
# stdin issues (bash $() subshells wait for background jobs started via heredoc).
MOCK_SCRIPT="$(mktemp /tmp/mock_wh_XXXXXX.py)"
cat > "$MOCK_SCRIPT" <<'PY'
from http.server import HTTPServer, BaseHTTPRequestHandler
import sys

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'ok')
    def log_message(self, *a): pass

srv = HTTPServer(('127.0.0.1', 0), Handler)
with open(sys.argv[1], 'w') as f:
    f.write(str(srv.server_address[1]))
for _ in range(3):
    srv.handle_request()
PY

SLACK_PORT_FILE="$(mktemp)"
TEAMS_PORT_FILE="$(mktemp)"
MOCK_PIDS=()

cleanup() {
  for pid in "${MOCK_PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  rm -f "$MOCK_SCRIPT" "$SLACK_PORT_FILE" "$TEAMS_PORT_FILE"
}
trap cleanup EXIT

wait_for_port_file() {
  local port_file="$1"
  for _ in {1..40}; do
    [[ -s "$port_file" ]] && return 0
    sleep 0.1
  done
  echo "ERROR: mock server port file never populated: $port_file" >&2
  return 1
}

# ── Case 1: dry run ──────────────────────────────────────────────────────────
unset RESEND_API_KEY
unset SLACK_WEBHOOK_URL
unset TEAMS_WEBHOOK_URL
DRY_RUN_OUTPUT="$(run_helper --dry-run)"
validate_json "$DRY_RUN_OUTPUT"
assert_contains "$DRY_RUN_OUTPUT" '"resendEmail": "skipped_dry_run"'
assert_contains "$DRY_RUN_OUTPUT" '"slack": "skipped_dry_run"'
assert_contains "$DRY_RUN_OUTPUT" '"teams": "skipped_dry_run"'

# ── Case 2: no chat routes, explicitly allowed ───────────────────────────────
MISSING_OUTPUT="$(run_helper --allow-chat-unavailable)"
validate_json "$MISSING_OUTPUT"
assert_contains "$MISSING_OUTPUT" '"resendEmail": "unavailable_missing_resend_api_key"'
assert_contains "$MISSING_OUTPUT" '"slack": "unavailable_missing_slack_webhook_url"'
assert_contains "$MISSING_OUTPUT" '"teams": "unavailable_missing_teams_webhook_url"'

# ── Case 3: no chat routes, no flag → must fail ──────────────────────────────
set +e
FAIL_STDERR="$(run_helper 2>&1 >/dev/null)"
FAIL_CODE=$?
set -e
if [[ "$FAIL_CODE" -eq 0 ]]; then
  echo "ASSERT FAILED: expected non-zero without --allow-chat-unavailable" >&2
  exit 1
fi
assert_contains "$FAIL_STDERR" "Chat route unavailable"

# ── Case 4: Slack mock webhook → delivered ───────────────────────────────────
# Start server directly (not inside $()) to avoid bash subshell-waits-for-bg-jobs hang.
> "$SLACK_PORT_FILE"
python3 "$MOCK_SCRIPT" "$SLACK_PORT_FILE" &
MOCK_PIDS+=($!)
wait_for_port_file "$SLACK_PORT_FILE"
SLACK_MOCK_PORT="$(cat "$SLACK_PORT_FILE")"
SLACK_OUTPUT="$(SLACK_WEBHOOK_URL="http://127.0.0.1:${SLACK_MOCK_PORT}/" run_helper)"
validate_json "$SLACK_OUTPUT"
assert_contains "$SLACK_OUTPUT" '"slack": "delivered"'
assert_contains "$SLACK_OUTPUT" '"teams": "skipped_slack_delivered"'

# ── Case 5: Teams mock webhook (Slack unset) → delivered ────────────────────
> "$TEAMS_PORT_FILE"
python3 "$MOCK_SCRIPT" "$TEAMS_PORT_FILE" &
MOCK_PIDS+=($!)
wait_for_port_file "$TEAMS_PORT_FILE"
TEAMS_MOCK_PORT="$(cat "$TEAMS_PORT_FILE")"
TEAMS_OUTPUT="$(unset SLACK_WEBHOOK_URL; TEAMS_WEBHOOK_URL="http://127.0.0.1:${TEAMS_MOCK_PORT}/" run_helper)"
validate_json "$TEAMS_OUTPUT"
assert_contains "$TEAMS_OUTPUT" '"slack": "unavailable_missing_slack_webhook_url"'
assert_contains "$TEAMS_OUTPUT" '"teams": "delivered"'

# ── Secret redaction across all output ───────────────────────────────────────
COMBINED_OUTPUT="$DRY_RUN_OUTPUT
$MISSING_OUTPUT
$FAIL_STDERR
$SLACK_OUTPUT
$TEAMS_OUTPUT"

assert_not_contains "$COMBINED_OUTPUT" "sk-"
assert_not_contains "$COMBINED_OUTPUT" "pcp_"
assert_not_contains "$COMBINED_OUTPUT" "ghp_"
assert_not_contains "$COMBINED_OUTPUT" "Bearer "
assert_not_contains "$COMBINED_OUTPUT" "hooks.slack.com"
assert_not_contains "$COMBINED_OUTPUT" "webhook.office.com"
assert_not_contains "$COMBINED_OUTPUT" "office365.com"
assert_not_contains "$COMBINED_OUTPUT" "vardaan97@gmail.com"
assert_not_contains "$COMBINED_OUTPUT" "http://localhost:3100/api/approvals/"

printf 'g4-notify smoke: pass\n'
