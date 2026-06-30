#!/usr/bin/env bash
set -euo pipefail

COMPANY_ID="${PAPERCLIP_COMPANY_ID:-2a77f89b-33f0-4133-a20c-77ddaac5e744}"
API_URL="${PAPERCLIP_API_URL:-http://localhost:3100}"
API_KEY="${PAPERCLIP_API_KEY:-}"
RUN_ID="${PAPERCLIP_RUN_ID:-}"
CHIEF_ENGINEERING_ID="b90788a0-d3de-42da-8e77-7dc8f7c01fd3"
DATABASE_URL="${DATABASE_URL:-}"
MODE="dry-run"
if [[ "${1:-}" == "--create-issues" ]]; then
  MODE="create-issues"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SQL_FILE="$ROOT_DIR/scripts/watchdog/check5-failure-spikes.sql"
SQL_TEXT="$(cat "$SQL_FILE" | sed "s/\$1/'$COMPANY_ID'/g")"

run_sql_tsv() {
  local sql="$1"
  if command -v psql >/dev/null 2>&1 && [[ -n "$DATABASE_URL" ]]; then
    PGPASSWORD="" psql "$DATABASE_URL" -t -A -F $'\t' -c "$sql"
    return
  fi
  if command -v docker >/dev/null 2>&1; then
    docker exec paperclip-db psql -U paperclip -d paperclip -t -A -F $'\t' -c "$sql"
    return
  fi
  echo "Neither psql+DATABASE_URL nor docker is available" >&2
  return 1
}

ROWS="$(run_sql_tsv "$SQL_TEXT")"

if [[ "$MODE" == "dry-run" ]]; then
  printf "adapter_type\tsignature\tfail_count\ttop_run_ids\n"
  if [[ -n "$ROWS" ]]; then
    printf "%s\n" "$ROWS"
  fi
  exit 0
fi

[[ -n "$API_KEY" ]] || { echo "PAPERCLIP_API_KEY is required for --create-issues"; exit 1; }

while IFS=$'\t' read -r adapter signature fail_count top_run_ids; do
  [[ -z "${adapter:-}" ]] && continue

  title="[WATCHDOG] Failure spike: ${adapter} hitting \"${signature}\" — ${fail_count} fails in 1h. Owner: Chief Engineering."
  title_sql=${title//\'/\'\'}
  exists="$(run_sql_tsv "SELECT 1 FROM issues WHERE company_id='${COMPANY_ID}' AND title='${title_sql}' AND created_at > NOW() - INTERVAL '4 hours' LIMIT 1;")"
  if [[ "$exists" == "1" ]]; then
    echo "cooldown: $title"
    continue
  fi

  description=$(cat <<DESC
Adapter failure spike detected in the last hour.

- adapter_type: ${adapter}
- signature: ${signature}
- failures: ${fail_count}
- top run IDs: ${top_run_ids}

Known patterns to inspect: Process lost, 401 Invalid authentication, configured model unavailable.
DESC
)

  payload=$(jq -n \
    --arg title "$title" \
    --arg description "$description" \
    --arg assignee "$CHIEF_ENGINEERING_ID" \
    '{title:$title,description:$description,status:"todo",priority:"critical",assigneeAgentId:$assignee,billingCode:"watchdog-alert"}')

  curl -sS -X POST "${API_URL}/api/companies/${COMPANY_ID}/issues" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -H "X-Paperclip-Run-Id: ${RUN_ID}" \
    --data-binary "$payload" >/dev/null
  echo "created: $title"
done <<< "$ROWS"
