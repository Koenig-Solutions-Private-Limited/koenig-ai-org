#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/g4-notify.sh --issue <id> --approval-id <id> --title <text> \
  [--preview-url <url>] [--vault-path <path>] [--gates <text>] \
  [--dry-run] [--validate-resend] [--allow-chat-unavailable]
USAGE
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

ISSUE_ID=""
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
      ISSUE_ID="${2:-}"; shift 2 ;;
    --approval-id)
      APPROVAL_ID="${2:-}"; shift 2 ;;
    --title)
      TITLE="${2:-}"; shift 2 ;;
    --preview-url)
      PREVIEW_URL="${2:-}"; shift 2 ;;
    --vault-path)
      VAULT_PATH="${2:-}"; shift 2 ;;
    --gates)
      GATES="${2:-}"; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --validate-resend)
      VALIDATE_RESEND=1; shift ;;
    --allow-chat-unavailable)
      ALLOW_CHAT_UNAVAILABLE=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2 ;;
  esac
done

if [[ -z "$ISSUE_ID" || -z "$APPROVAL_ID" || -z "$TITLE" ]]; then
  echo "Missing required arguments" >&2
  usage
  exit 2
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  EMAIL_STATUS="skipped_dry_run"
  SLACK_STATUS="skipped_dry_run"
  TEAMS_STATUS="skipped_dry_run"
else
  EMAIL_STATUS="not_attempted"
  SLACK_STATUS="not_attempted"
  TEAMS_STATUS="not_attempted"

  # ── Email via Resend ────────────────────────────────────────────────────────
  if [[ -z "${RESEND_API_KEY:-}" ]]; then
    EMAIL_STATUS="unavailable_missing_resend_api_key"
  elif [[ "$VALIDATE_RESEND" -eq 1 ]]; then
    RESEND_HTTP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' \
      -H "Authorization: Bearer ${RESEND_API_KEY}" \
      https://api.resend.com/domains || true)"
    if [[ "$RESEND_HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
      EMAIL_STATUS="validated"
    else
      EMAIL_STATUS="validation_failed_http_${RESEND_HTTP_CODE:-000}"
    fi
  else
    EMAIL_STATUS="configured"
  fi

  # ── Slack webhook ───────────────────────────────────────────────────────────
  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    slack_payload=$(cat <<JSON
{"text":"G4 approval queued for ${ISSUE_ID} (${APPROVAL_ID}). Review in Paperclip UI."}
JSON
)
    SLACK_HTTP_CODE="$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' \
      -H 'Content-Type: application/json' \
      --data "$slack_payload" \
      "$SLACK_WEBHOOK_URL" 2>/dev/null || true)"
    if [[ "$SLACK_HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
      SLACK_STATUS="delivered"
    else
      SLACK_STATUS="delivery_failed_http_${SLACK_HTTP_CODE:-000}"
    fi
  else
    SLACK_STATUS="unavailable_missing_slack_webhook_url"
  fi

  # ── Teams webhook (fallback when Slack is not delivered) ────────────────────
  if [[ "$SLACK_STATUS" == "delivered" ]]; then
    TEAMS_STATUS="skipped_slack_delivered"
  elif [[ -n "${TEAMS_WEBHOOK_URL:-}" ]]; then
    teams_payload=$(cat <<JSON
{"text":"G4 approval queued for ${ISSUE_ID} (${APPROVAL_ID}). Review in Paperclip UI."}
JSON
)
    TEAMS_HTTP_CODE="$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' \
      -H 'Content-Type: application/json' \
      --data "$teams_payload" \
      "$TEAMS_WEBHOOK_URL" 2>/dev/null || true)"
    if [[ "$TEAMS_HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
      TEAMS_STATUS="delivered"
    else
      TEAMS_STATUS="delivery_failed_http_${TEAMS_HTTP_CODE:-000}"
    fi
  else
    TEAMS_STATUS="unavailable_missing_teams_webhook_url"
  fi
fi

# ── Chat availability gate ──────────────────────────────────────────────────
# Fail unless at least one chat route delivered, dry-run, or explicitly allowed.
if [[ "$DRY_RUN" -eq 0 && "$ALLOW_CHAT_UNAVAILABLE" -eq 0 ]]; then
  if [[ "$SLACK_STATUS" != "delivered" && "$TEAMS_STATUS" != "delivered" ]]; then
    echo "Chat route unavailable. Re-run with --allow-chat-unavailable if intentional." >&2
    exit 3
  fi
fi

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat <<JSON
{
  "issue": $(json_escape "$ISSUE_ID"),
  "approvalId": $(json_escape "$APPROVAL_ID"),
  "title": $(json_escape "$TITLE"),
  "previewUrl": $(json_escape "$PREVIEW_URL"),
  "vaultPath": $(json_escape "$VAULT_PATH"),
  "gates": $(json_escape "$GATES"),
  "channels": {
    "paperclipUi": "source_of_truth",
    "resendEmail": $(json_escape "$EMAIL_STATUS"),
    "slack": $(json_escape "$SLACK_STATUS"),
    "teams": $(json_escape "$TEAMS_STATUS")
  },
  "note": "notification_only_no_publish",
  "timestamp": $(json_escape "$TIMESTAMP")
}
JSON
