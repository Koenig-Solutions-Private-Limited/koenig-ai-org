#!/usr/bin/env bash
# Sync tracked publish-action.sh into the Paperclip runtime scripts directory.
#
# Container and legacy cron paths invoke /paperclip/scripts/publish-action.sh.
# This script keeps that copy aligned with scripts/publish-action.sh (source of truth).
#
# Usage:
#   ./scripts/sync-publish-action-runtime.sh
#
# Optional:
#   PUBLISH_ACTION_RUNTIME_DIR=/custom/path ./scripts/sync-publish-action-runtime.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$REPO_ROOT/scripts/publish-action.sh"
RUNTIME_DIR="${PUBLISH_ACTION_RUNTIME_DIR:-/paperclip/scripts}"
TARGET="$RUNTIME_DIR/publish-action.sh"

if [[ ! -f "$SOURCE" ]]; then
  echo "ERROR: missing source script: $SOURCE" >&2
  exit 1
fi

mkdir -p "$RUNTIME_DIR"
install -m 755 "$SOURCE" "$TARGET"

if command -v shasum >/dev/null 2>&1; then
  src_hash="$(shasum -a 256 "$SOURCE" | awk '{print $1}')"
  dst_hash="$(shasum -a 256 "$TARGET" | awk '{print $1}')"
  if [[ "$src_hash" != "$dst_hash" ]]; then
    echo "ERROR: runtime copy hash mismatch after install ($TARGET)" >&2
    exit 1
  fi
fi

echo "OK: synced publish-action runtime copy to $TARGET"
