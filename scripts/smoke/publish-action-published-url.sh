#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[publish-action-published-url] $*"
}

fail() {
  echo "[publish-action-published-url] ERROR: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PUBLISH_ACTION="$REPO_ROOT/scripts/publish-action.sh"

[[ -f "$PUBLISH_ACTION" ]] || fail "missing publish-action script: $PUBLISH_ACTION"

log "running production published_url self-test via publish-action.sh"
output="$(bash "$PUBLISH_ACTION" --self-test-published-url)"
echo "$output"
[[ "$output" == *"published_url self-test ok"* ]] || fail "self-test did not report success"

log "smoke check passed"
