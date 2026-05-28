#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
SERVER_LOG="$TMP_DIR/server.log"
LOG_DIR="$TMP_DIR/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/publish-action.log"

cleanup() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

sed '/^if \[\[ ! -f "\$ENV_FILE" \]\]/,$d' "$ROOT/scripts/publish-action.sh" > "$TMP_DIR/guard-functions.sh"

REQUEST_LOG="$TMP_DIR/requests.log"

cat > "$TMP_DIR/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        return

    def do_GET(self):
        with open(sys.argv[2], "a", encoding="utf-8") as fh:
            fh.write(f"GET {self.path}\n")
        if self.path == "/paperclip-401":
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b'{"error":"unauthorized","token":"should-not-leak"}')
            return
        self.send_response(500)
        self.end_headers()
        self.wfile.write(b'{"error":"upstream failed","api_key":"should-not-leak"}')

    def do_POST(self):
        with open(sys.argv[2], "a", encoding="utf-8") as fh:
            fh.write(f"POST {self.path}\n")
        self.send_response(500)
        self.end_headers()
        self.wfile.write(b'{"error":"create failed","token":"should-not-leak"}')

    def do_PATCH(self):
        with open(sys.argv[2], "a", encoding="utf-8") as fh:
            fh.write(f"PATCH {self.path}\n")
        self.send_response(500)
        self.end_headers()
        self.wfile.write(b'{"error":"patch failed","secret":"should-not-leak"}')


server = HTTPServer(("127.0.0.1", 0), Handler)
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    fh.write(str(server.server_port))
server.serve_forever()
PY

python3 "$TMP_DIR/server.py" "$TMP_DIR/port" "$REQUEST_LOG" > "$SERVER_LOG" 2>&1 &
SERVER_PID="$!"
for _ in 1 2 3 4 5; do
  [ -s "$TMP_DIR/port" ] && break
  sleep 0.1
done
PORT="$(cat "$TMP_DIR/port")"

export LOG_DIR LOG
export PAPERCLIP_URL="http://127.0.0.1:$PORT"
export COMPANY_ID="company-fixture"
export PAPERCLIP_API_KEY="fixture-token"

# shellcheck source=/dev/null
source "$TMP_DIR/guard-functions.sh"
LOG_DIR="$TMP_DIR/logs"
LOG="$LOG_DIR/publish-action.log"

fetch_issues_by_slug || true

BLOCKED_FILES=("vault/blogs/fixture-slug/draft.md")
BLOCKED_SLUGS=("fixture-slug")
BLOCKED_ISSUES=("api-error")
BLOCKED_STATES=("api-error")
BLOCKED_OLD_STATUS=("g0-passed")
BLOCKED_NEW_STATUS=("published")
create_guard_watchdog_issue || true

grep -Eq 'guard:api-error endpoint=/api/companies/company-fixture/issues\?limit=2000 http_status=500 reason=' "$LOG"
grep -Eq 'guard:watchdog-issue-create-failed endpoint=/api/companies/company-fixture/issues http_status=500 reason=' "$LOG"
! grep -Eq 'fixture-token|should-not-leak' "$LOG"
grep -q 'all staged vault changes excluded; continuing without commit' "$ROOT/scripts/publish-action.sh"
grep -q 'publish-action complete' "$ROOT/scripts/publish-action.sh"

PAPERCLIP_RESPONSE="$TMP_DIR/paperclip-response.json"
paperclip_curl_json GET "/paperclip-401" "$PAPERCLIP_RESPONSE" || true
grep -Eq 'paperclip:api-error .*endpoint=/paperclip-401 http_status=401 reason=' "$LOG"
! grep -Eq 'fixture-token|should-not-leak' "$LOG"

BAD_RUNS="$TMP_DIR/bad-runs.json"
printf '{not-json\n' > "$BAD_RUNS"
RUN_STATUS="$(phase2_run_status "$BAD_RUNS" "issue-fixture" "2026-05-14T00:00:00Z")"
[ "$RUN_STATUS" = "unknown_parse_error" ]
grep -Eq 'phase=2 json-parse-failed reason=' "$LOG"

DISPATCH_LEDGER_DIR="$TMP_DIR/dispatch-ledger"
mkdir -p "$DISPATCH_LEDGER_DIR"
write_dispatch_ledger "issue-fixture" "slug-fixture" "2026-05-14T00:00:00Z"
LEDGER_PATH="$(dispatch_ledger_path "issue-fixture")"
[ -s "$LEDGER_PATH" ]
retry_dispatch_ledger "$LEDGER_PATH" || true
[ -s "$LEDGER_PATH" ]
retry_dispatch_ledger "$LEDGER_PATH" || true
[ -s "$LEDGER_PATH" ]
grep -q 'Phase 1: dispatch ledger metadata retry pending issue=issue-fixture' "$LOG"
grep -q 'PATCH /api/issues/issue-fixture' "$REQUEST_LOG"
PATCH_COUNT="$(grep -c 'PATCH /api/issues/issue-fixture' "$REQUEST_LOG")"
[ "$PATCH_COUNT" = "2" ]
! grep -q 'POST /repos/' "$REQUEST_LOG"
! grep -Eq 'fixture-token|should-not-leak' "$LOG"

CURRENT_PHASE="fixture"
TERMINAL_REASON=""
terminal_log_and_cleanup
grep -q 'publish-action terminal: exited phase=fixture reason=early-exit cleanup=done' "$LOG"

echo "publish-action guard logging fixture passed"
