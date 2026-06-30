#!/usr/bin/env bash
# Koenig AI Academy — secret sync.
#
# Reads .env.koenig (gitignored), creates each secret in Paperclip's encrypted
# store, and binds each to the agents that declared the env var as a secret.
#
# Usage:
#   1. Edit .env.koenig (copy from .env.koenig.example if missing)
#   2. ./scripts/sync-secrets.sh
#
# Requires: bash, python3, curl. Paperclip server must be running at $PAPERCLIP_URL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.koenig"
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"
KOENIG_DEFAULT_COMPANY_ID="2a77f89b-33f0-4133-a20c-77ddaac5e744"
COMPANY_ID="${COMPANY_ID:-${KOENIG_COMPANY_ID:-$KOENIG_DEFAULT_COMPANY_ID}}"
AUTH_TOKEN="${PAPERCLIP_API_KEY:-${PAPERCLIP_BOARD_TOKEN:-}}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Copy from .env.koenig.example and fill in values." >&2
  exit 1
fi

extra_args=(--verify-ceo-bindings)
if [[ -n "$AUTH_TOKEN" ]]; then
  extra_args+=(--auth-token "$AUTH_TOKEN")
fi

python3 "$SCRIPT_DIR/sync_secrets.py" \
  --env-file "$ENV_FILE" \
  --paperclip-url "$PAPERCLIP_URL" \
  --company-id "$COMPANY_ID" \
  "${extra_args[@]}"
