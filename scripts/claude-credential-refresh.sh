#!/bin/bash
# claude-credential-refresh.sh
# Re-extract Claude OAuth token from macOS Keychain and write it atomically
# to ~/.claude/.credentials.json so the bind-mounted paperclip-server container
# can use the fresh token. Run on a 15-minute schedule via launchd.
#
# Why: Mac Claude Code CLI rotates the OAuth token in Keychain every ~30 min,
# but the file at ~/.claude/.credentials.json is just a snapshot — it goes
# stale and the container's claude CLI starts returning 401. This script
# keeps the file fresh.
#
# Install:
#   chmod +x ~/Documents/Paperclip/koenig-ai-org/scripts/claude-credential-refresh.sh
#   cp ~/Documents/Paperclip/koenig-ai-org/scripts/tech.kspl.claude-credential-refresh.plist \
#     ~/Library/LaunchAgents/
#   launchctl load ~/Library/LaunchAgents/tech.kspl.claude-credential-refresh.plist
#
# Verify:
#   tail -f ~/.claude/credential-refresh.log
#   stat -f "%Sm %z bytes" ~/.claude/.credentials.json   # should update every 15 min
#
# Manual run:
#   ~/Documents/Paperclip/koenig-ai-org/scripts/claude-credential-refresh.sh

set -euo pipefail

CREDS_FILE="${HOME}/.claude/.credentials.json"
TMP_FILE="${CREDS_FILE}.tmp"
LOG_FILE="${HOME}/.claude/credential-refresh.log"

# Try the standard Keychain entry name first
if security find-generic-password -s "Claude Code-credentials" -w > "$TMP_FILE" 2>/dev/null; then
    mv "$TMP_FILE" "$CREDS_FILE"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ok: refreshed from Keychain ($(stat -f%z "$CREDS_FILE") bytes)" >> "$LOG_FILE"
else
    rm -f "$TMP_FILE"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERR: Keychain extraction failed (entry 'Claude Code-credentials' not found or perms denied)" >> "$LOG_FILE"
    exit 1
fi
