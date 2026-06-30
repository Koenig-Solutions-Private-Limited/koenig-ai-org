#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER="$ROOT_DIR/scripts/g4-notify.sh"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "ASSERT FAILED: missing '$needle'" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "ASSERT FAILED: found forbidden '$needle'" >&2
    exit 1
  fi
}

validate_json() {
  local payload="$1"
  python3 -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$payload" >/dev/null
}

run_helper() {
  "$HELPER" \
    --issue "KOEA-5102" \
    --approval-id "e33050ef-299f-4553-917d-eebbc8f36e7c" \
    --title "G4 approval smoke" \
    --preview-url "https://preview.example.test/item" \
    --vault-path "vault/courses/demo/ch1.md" \
    --gates "G0,G2,G3" "$@"
}

unset RESEND_API_KEY
unset SLACK_WEBHOOK_URL
DRY_RUN_OUTPUT="$(run_helper --dry-run)"
validate_json "$DRY_RUN_OUTPUT"
assert_contains "$DRY_RUN_OUTPUT" '"resendEmail": "skipped_dry_run"'
assert_contains "$DRY_RUN_OUTPUT" '"slack": "skipped_dry_run"'

MISSING_OUTPUT="$(run_helper --allow-chat-unavailable)"
validate_json "$MISSING_OUTPUT"
assert_contains "$MISSING_OUTPUT" '"resendEmail": "unavailable_missing_resend_api_key"'
assert_contains "$MISSING_OUTPUT" '"slack": "unavailable_allowed"'

set +e
FAIL_STDERR="$(run_helper 2>&1 >/dev/null)"
FAIL_CODE=$?
set -e
if [[ "$FAIL_CODE" -eq 0 ]]; then
  echo "ASSERT FAILED: expected non-zero without --allow-chat-unavailable" >&2
  exit 1
fi
assert_contains "$FAIL_STDERR" "Chat route unavailable"

COMBINED_OUTPUT="$DRY_RUN_OUTPUT
$MISSING_OUTPUT
$FAIL_STDERR"

assert_not_contains "$COMBINED_OUTPUT" "sk-"
assert_not_contains "$COMBINED_OUTPUT" "pcp_"
assert_not_contains "$COMBINED_OUTPUT" "ghp_"
assert_not_contains "$COMBINED_OUTPUT" "Bearer "
assert_not_contains "$COMBINED_OUTPUT" "hooks.slack.com"
assert_not_contains "$COMBINED_OUTPUT" "vardaan97@gmail.com"
assert_not_contains "$COMBINED_OUTPUT" "http://localhost:3100/api/approvals/"

printf 'g4-notify smoke: pass\n'
