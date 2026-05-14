#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_SCRIPT="$ROOT_DIR/scripts/publish-action.sh"
RUNTIME_SCRIPT="/paperclip/scripts/publish-action.sh"

if [[ ! -f "$REPO_SCRIPT" ]]; then
  echo "missing repo script: $REPO_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$RUNTIME_SCRIPT" ]]; then
  echo "missing runtime script: $RUNTIME_SCRIPT" >&2
  exit 1
fi

for target in "$REPO_SCRIPT" "$RUNTIME_SCRIPT"; do
  if rg -n 'git add -A vault/|git commit -m|git push origin' "$target" >/dev/null; then
    echo "forbidden default-path vault sync command found in $target" >&2
    rg -n 'git add -A vault/|git commit -m|git push origin' "$target" >&2
    exit 1
  fi

  if ! rg -n 'vault-sync disabled: publish-action will not stage, commit, or push vault content\.' "$target" >/dev/null; then
    echo "expected vault-sync disabled log line missing in $target" >&2
    exit 1
  fi
done

echo "PASS: publish-action default path does not stage/commit/push vault content."
