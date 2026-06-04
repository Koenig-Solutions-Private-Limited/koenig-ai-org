#!/usr/bin/env bash
# Verify paperclip-chromium-debug CDP sidecar is reachable and returns a
# connectable webSocketDebuggerUrl (not ws://0.0.0.0 — that breaks browser-use).
set -euo pipefail

CDP_HOST="${CHROMIUM_DEBUG_HOST:-paperclip-chromium-debug}"
CDP_PORT="${CHROMIUM_DEBUG_PORT:-3000}"
CDP_TOKEN="${CHROMIUM_DEBUG_TOKEN:-koenig-cdp-token-2026}"
BASE_URL="http://${CDP_HOST}:${CDP_PORT}"

json="$(curl -fsS "${BASE_URL}/json/version?token=${CDP_TOKEN}")"
ws_url="$(printf '%s' "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("webSocketDebuggerUrl",""))')"

if [[ -z "$ws_url" ]]; then
  echo "FAIL: /json/version returned no webSocketDebuggerUrl" >&2
  exit 1
fi

if [[ "$ws_url" == *"0.0.0.0"* ]]; then
  echo "FAIL: webSocketDebuggerUrl advertises 0.0.0.0 (browser-use cannot connect): $ws_url" >&2
  echo "Fix: set EXTERNAL=http://${CDP_HOST}:${CDP_PORT} on paperclip-chromium-debug and recreate the container." >&2
  exit 1
fi

echo "OK: chromium-debug CDP healthy"
echo "  webSocketDebuggerUrl=$ws_url"
