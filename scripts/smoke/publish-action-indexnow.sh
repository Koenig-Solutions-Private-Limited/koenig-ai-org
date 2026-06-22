#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[publish-action-indexnow] $*"
}

fail() {
  echo "[publish-action-indexnow] ERROR: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PUBLISH_ACTION="$REPO_ROOT/scripts/publish-action.sh"

[[ -f "$PUBLISH_ACTION" ]] || fail "missing publish-action script: $PUBLISH_ACTION"

log "running IndexNow self-test via publish-action.sh (mocked curl, no network/git/Paperclip)"
output="$(bash "$PUBLISH_ACTION" --self-test-indexnow)"
echo "$output"
[[ "$output" == *"indexnow self-test ok"* ]] || fail "self-test did not report success"

log "smoke check passed"
