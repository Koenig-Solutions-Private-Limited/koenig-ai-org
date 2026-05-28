#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$(git -C "$ROOT" rev-parse --git-path hooks)"
SOURCE="$ROOT/scripts/hooks/commit-msg-blog-seo.sh"
TARGET="$HOOKS_DIR/commit-msg"

mkdir -p "$HOOKS_DIR"
chmod +x "$SOURCE"

if [[ -f "$TARGET" && ! -L "$TARGET" ]]; then
  echo "Refusing to overwrite existing non-symlink hook: $TARGET" >&2
  exit 1
fi

ln -sf "$SOURCE" "$TARGET"
echo "Installed commit-msg hook → $TARGET"
