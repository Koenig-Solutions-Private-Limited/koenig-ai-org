#!/bin/bash
# Wrapper for launchd — starts slide-fake-done-auditor loop
# Sources .env.koenig so PAPERCLIP_API_KEY stays out of the plist.

set -e

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$REPO/.env.koenig"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

export PAPERCLIP_HOST="${PAPERCLIP_HOST:-http://localhost:3100}"
export KOENIG_COMPANY_ID="${KOENIG_COMPANY_ID:-2a77f89b-33f0-4133-a20c-77ddaac5e744}"

# Fallback when launchd doesn't propagate HOME.
HOME_DIR="${HOME:-/Users/vardaankoenig}"

NODE="$HOME_DIR/.nvm/versions/node/v24.14.1/bin/node"
if [ ! -x "$NODE" ]; then
  if command -v node >/dev/null 2>&1; then
    NODE="$(command -v node)"
  else
    echo "[start-slide-auditor-daemon] ERROR: cannot locate node binary (HOME=$HOME_DIR PATH=$PATH)" >&2
    exit 1
  fi
fi

# Run auditor every 10 minutes
echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Starting slide-fake-done-auditor loop..."
while true; do
  "$NODE" "$REPO/watchdog/slide-fake-done-auditor.mjs" 2>&1 | tee -a "$REPO/watchdog/slide-auditor.log"
  sleep 600  # 10 minutes
done
