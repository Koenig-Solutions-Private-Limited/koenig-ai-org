#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: g4-notify.sh --issue ID --approval-id ID --title TITLE --preview-url URL --vault-path PATH --gates GATES [options]

Required:
  --issue ID
  --approval-id ID
  --title TITLE
  --preview-url URL
  --vault-path PATH
  --gates GATES

Options:
  --dry-run
  --validate-resend
  --allow-chat-unavailable
USAGE
}

json_escape() {
  local s=${1//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

ISSUE=""
APPROVAL_ID=""
TITLE=""
PREVIEW_URL=""
VAULT_PATH=""
GATES=""
DRY_RUN=0
VALIDATE_RESEND=0
ALLOW_CHAT_UNAVAILABLE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)
      ISSUE=${2:-}
      shift 2
      ;;
    --approval-id)
      APPROVAL_ID=${2:-}
      shift 2
      ;;
    --title)
      TITLE=${2:-}
      shift 2
      ;;
    --preview-url)
      PREVIEW_URL=${2:-}
      shift 2
      ;;
    --vault-path)
      VAULT_PATH=${2:-}
      shift 2
      ;;
    --gates)
      GATES=${2:-}
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --validate-resend)
      VALIDATE_RESEND=1
      shift
      ;;
    --allow-chat-unavailable)
      ALLOW_CHAT_UNAVAILABLE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for required in ISSUE APPROVAL_ID TITLE PREVIEW_URL VAULT_PATH GATES; do
  if [[ -z "${!required}" ]]; then
    echo "Missing required argument: --${required,,}" >&2
    usage >&2
    exit 2
  fi
done

EMAIL_STATUS=""
EMAIL_DETAIL=""
SLACK_STATUS=""
SLACK_DETAIL=""

if [[ -z "${RESEND_API_KEY:-}" ]]; then
  EMAIL_STATUS="missing_secret"
  EMAIL_DETAIL="RESEND_API_KEY is not set"
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ "$VALIDATE_RESEND" -eq 1 ]]; then
      EMAIL_STATUS="dry_run_validation_skipped"
      EMAIL_DETAIL="Dry run skipped live Resend validation"
    else
      EMAIL_STATUS="dry_run_not_sent"
      EMAIL_DETAIL="Dry run skipped live email send"
    fi
  else
    if [[ "$VALIDATE_RESEND" -eq 1 ]]; then
      http_code=$(curl -sS -o /tmp/g4_notify_resend_validate.json -w '%{http_code}' \
        -H "Authorization: Bearer ${RESEND_API_KEY}" \
        -H 'Content-Type: application/json' \
        https://api.resend.com/domains || true)
      if [[ "$http_code" == "200" ]]; then
        EMAIL_STATUS="validated"
        EMAIL_DETAIL="Resend API key accepted"
      elif [[ "$http_code" == "401" ]]; then
        EMAIL_STATUS="unauthorized"
        EMAIL_DETAIL="Resend API key rejected"
      else
        EMAIL_STATUS="error"
        EMAIL_DETAIL="Resend validation failed with HTTP ${http_code}"
      fi
      rm -f /tmp/g4_notify_resend_validate.json
    else
      email_payload=$(cat <<JSON
{"from":"g4-notify@koenig.local","to":["ceo-review@koenig.local"],"subject":"TEST ONLY - no publish: ${TITLE}","text":"Issue: ${ISSUE}\nApproval: ${APPROVAL_ID}\nPreview: ${PREVIEW_URL}\nVault: ${VAULT_PATH}\nGates: ${GATES}\n"}
JSON
)
      http_code=$(curl -sS -o /tmp/g4_notify_resend_send.json -w '%{http_code}' \
        -X POST \
        -H "Authorization: Bearer ${RESEND_API_KEY}" \
        -H 'Content-Type: application/json' \
        -d "$email_payload" \
        https://api.resend.com/emails || true)
      if [[ "$http_code" == "200" ]]; then
        EMAIL_STATUS="sent"
        EMAIL_DETAIL="Resend email accepted"
      elif [[ "$http_code" == "401" ]]; then
        EMAIL_STATUS="unauthorized"
        EMAIL_DETAIL="Resend API key rejected"
      else
        EMAIL_STATUS="error"
        EMAIL_DETAIL="Resend send failed with HTTP ${http_code}"
      fi
      rm -f /tmp/g4_notify_resend_send.json
    fi
  fi
fi

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  if [[ "$ALLOW_CHAT_UNAVAILABLE" -eq 1 ]]; then
    SLACK_STATUS="intentionally_unavailable"
    SLACK_DETAIL="SLACK_WEBHOOK_URL not set; explicitly allowed"
  else
    SLACK_STATUS="missing_secret"
    SLACK_DETAIL="SLACK_WEBHOOK_URL is not set"
  fi
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    SLACK_STATUS="dry_run_not_sent"
    SLACK_DETAIL="Dry run skipped live Slack send"
  else
    slack_payload=$(cat <<JSON
{"text":"TEST ONLY - no publish\\nIssue: ${ISSUE}\\nApproval: ${APPROVAL_ID}\\nTitle: ${TITLE}\\nPreview: ${PREVIEW_URL}\\nVault: ${VAULT_PATH}\\nGates: ${GATES}"}
JSON
)
    http_code=$(curl -sS -o /tmp/g4_notify_slack_send.json -w '%{http_code}' \
      -X POST \
      -H 'Content-Type: application/json' \
      -d "$slack_payload" \
      "$SLACK_WEBHOOK_URL" || true)
    if [[ "$http_code" == "200" ]]; then
      SLACK_STATUS="sent"
      SLACK_DETAIL="Slack webhook accepted"
    else
      SLACK_STATUS="error"
      SLACK_DETAIL="Slack send failed with HTTP ${http_code}"
    fi
    rm -f /tmp/g4_notify_slack_send.json
  fi
fi

printf '{\n'
printf '  "issue": "%s",\n' "$(json_escape "$ISSUE")"
printf '  "approvalId": "%s",\n' "$(json_escape "$APPROVAL_ID")"
printf '  "mode": {"dryRun": %s, "validateResend": %s, "allowChatUnavailable": %s},\n' \
  "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)" \
  "$([[ "$VALIDATE_RESEND" -eq 1 ]] && echo true || echo false)" \
  "$([[ "$ALLOW_CHAT_UNAVAILABLE" -eq 1 ]] && echo true || echo false)"
printf '  "email": {"status": "%s", "detail": "%s"},\n' \
  "$(json_escape "$EMAIL_STATUS")" "$(json_escape "$EMAIL_DETAIL")"
printf '  "slack": {"status": "%s", "detail": "%s"}\n' \
  "$(json_escape "$SLACK_STATUS")" "$(json_escape "$SLACK_DETAIL")"
printf '}\n'
