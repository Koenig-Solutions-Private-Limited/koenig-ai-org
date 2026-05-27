#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_UNDER_TEST="$ROOT/scripts/publish-action.sh"
TMPROOT="$(mktemp -d)"
SERVER_PID=""
export HOME="$TMPROOT/home"
mkdir -p "$HOME"

cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMPROOT"
}
trap cleanup EXIT

FUNCTIONS_FILE="$TMPROOT/publish-action-functions.sh"
sed '/^if \[\[ ! -f "\$ENV_FILE" \]\]; then/,$d' "$SCRIPT_UNDER_TEST" > "$FUNCTIONS_FILE"
# shellcheck source=/dev/null
source "$FUNCTIONS_FILE"

STATE_FILE="$TMPROOT/state"
PORT_FILE="$TMPROOT/port"
python3 - "$STATE_FILE" "$PORT_FILE" <<'PY' &
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import sys

state_file, port_file = sys.argv[1], sys.argv[2]

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        with open(state_file, "r", encoding="utf-8") as fh:
            state = fh.read().strip()
        if state == "500":
            self.send_response(500)
            self.end_headers()
            return
        payload = {
            "items": [
                {
                    "id": "issue-id-1",
                    "identifier": "KOEA-TEST",
                    "metadata": {
                        "slug": "fixture-slug",
                        "publish_state": state,
                    },
                }
            ]
        }
        body = json.dumps(payload).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

server = HTTPServer(("127.0.0.1", 0), Handler)
with open(port_file, "w", encoding="utf-8") as fh:
    fh.write(str(server.server_port))
server.serve_forever()
PY
SERVER_PID="$!"

for _ in $(seq 1 50); do
  [ -s "$PORT_FILE" ] && break
  sleep 0.1
done
[ -s "$PORT_FILE" ]

PORT="$(cat "$PORT_FILE")"
export PAPERCLIP_URL="http://127.0.0.1:$PORT"
export COMPANY_ID="company-test"
export PAPERCLIP_API_KEY="test-token"
LOG_DIR="$TMPROOT/logs"
LOG="$LOG_DIR/publish-action.log"
mkdir -p "$LOG_DIR"

setup_repo() {
  local repo="$1"
  rm -rf "$repo"
  mkdir -p "$repo/vault/blogs/fixture-slug"
  (
    cd "$repo"
    git init -q
    git config user.email test@example.com
    git config user.name "Test User"
    cat > vault/blogs/fixture-slug/draft.md <<'MD'
---
status: g0-passed
---

Body.
MD
    git add vault/blogs/fixture-slug/draft.md
    git commit -q -m "seed fixture"
    cat > vault/blogs/fixture-slug/draft.md <<'MD'
---
status: published
---

Body.
MD
    git add vault/blogs/fixture-slug/draft.md
  )
}

setup_new_file_repo() {
  local repo="$1"
  rm -rf "$repo"
  mkdir -p "$repo/vault/blogs/fixture-slug"
  (
    cd "$repo"
    git init -q
    git config user.email test@example.com
    git config user.name "Test User"
    git commit --allow-empty -q -m "seed empty repo"
    cat > vault/blogs/fixture-slug/draft.md <<'MD'
---
status: published
---

Body.
MD
    git add vault/blogs/fixture-slug/draft.md
  )
}

run_case() {
  local state="$1"
  local expected="$2"
  local repo="$TMPROOT/repo-$state"
  echo "$state" > "$STATE_FILE"
  setup_repo "$repo"
  (
    cd "$repo"
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
    verify_no_pending_g4_publish
    actual="${#BLOCKED_FILES[@]}"
    if [ "$actual" != "$expected" ]; then
      echo "state=$state expected blocked=$expected actual=$actual" >&2
      exit 1
    fi
  )
}

run_new_file_case() {
  local repo="$TMPROOT/repo-new-file"
  echo "g3-passed" > "$STATE_FILE"
  setup_new_file_repo "$repo"
  (
    cd "$repo"
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
    verify_no_pending_g4_publish
    actual="${#BLOCKED_FILES[@]}"
    if [ "$actual" != "1" ]; then
      echo "new-file expected blocked=1 actual=$actual" >&2
      exit 1
    fi
  )
}

run_case "g3-passed" "1"
run_case "g4-approved" "0"
run_case "500" "1"
run_new_file_case

echo "publish-action guard tests passed"
