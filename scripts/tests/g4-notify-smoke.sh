#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
SCRIPT="$ROOT_DIR/scripts/g4-notify.sh"

TMP_OUTPUT=$(mktemp)
trap 'rm -f "$TMP_OUTPUT"' EXIT

unset RESEND_API_KEY || true
unset SLACK_WEBHOOK_URL || true

"$SCRIPT" \
  --issue KOEA-4997 \
  --approval-id 88461ffc-4cf7-48ec-836d-f21734d579a6 \
  --title "CEO G4 delivery smoke" \
  --preview-url "https://example.invalid/preview" \
  --vault-path "vault/decisions/KOEA-4997-plan.md" \
  --gates "G0,G_code,G2,G3" \
  --dry-run > "$TMP_OUTPUT"

jq -e . "$TMP_OUTPUT" >/dev/null

jq -e '.email.status == "missing_secret"' "$TMP_OUTPUT" >/dev/null
jq -e '.slack.status == "missing_secret"' "$TMP_OUTPUT" >/dev/null
jq -e '.mode.dryRun == true' "$TMP_OUTPUT" >/dev/null
jq -e '.mode.validateResend == false' "$TMP_OUTPUT" >/dev/null

if rg -n 'Bearer|https://hooks.slack|\bre_[A-Za-z0-9]+' "$TMP_OUTPUT" >/dev/null; then
  echo "secret-like token found in output" >&2
  exit 1
fi

if rg -n '"PATCH"|/api/issues|/api/approvals|/api/companies/.*/issues' "$TMP_OUTPUT" >/dev/null; then
  echo "unexpected Paperclip mutation reference found in output" >&2
  exit 1
fi

echo "g4-notify smoke: PASS"
