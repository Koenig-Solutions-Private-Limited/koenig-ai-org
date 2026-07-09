#!/bin/bash
# Roster truth sync (board-directed 2026-07-09).
# Dumps the LIVE agent roster (DB = source of truth for runtime config) into
# companies/learnova-academy/ROSTER.live.md so the repo always reflects reality.
# Run modes:
#   ./scripts/roster-snapshot.sh          # regenerate the snapshot
#   ./scripts/roster-snapshot.sh --check  # exit 1 + diff if repo snapshot is stale
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO_ROOT/companies/learnova-academy/ROSTER.live.md"
TMP="$(mktemp)"

{
  echo "# Live agent roster (generated — do not hand-edit)"
  echo
  echo "Regenerate: \`./scripts/roster-snapshot.sh\`. Verify: \`./scripts/roster-snapshot.sh --check\`."
  echo "The DB is the runtime source of truth; this file makes it reviewable in git."
  echo
  echo "| Agent | Status | Adapter | Model | Reports to | Heartbeat |"
  echo "|---|---|---|---|---|---|"
  docker exec paperclip-db psql -U paperclip -d paperclip -Atc "
    SELECT '| ' || a.name || ' | ' || a.status || ' | ' || a.adapter_type || ' | ' ||
           coalesce(a.adapter_config->>'model','-') || ' | ' ||
           coalesce((SELECT b.name FROM agents b WHERE b.id=a.reports_to),'-') || ' | ' ||
           coalesce(a.runtime_config->'heartbeat'->>'schedule',
                    CASE WHEN (a.runtime_config->'heartbeat'->>'enabled')='true' THEN 'enabled' ELSE '-' END) || ' |'
    FROM agents a ORDER BY a.name;"
} > "$TMP"

if [ "${1:-}" = "--check" ]; then
  if diff -q "$OUT" "$TMP" >/dev/null 2>&1; then
    echo "roster snapshot: in sync"; rm -f "$TMP"; exit 0
  else
    echo "roster snapshot: STALE — run ./scripts/roster-snapshot.sh and commit"; diff "$OUT" "$TMP" || true
    rm -f "$TMP"; exit 1
  fi
fi
mv "$TMP" "$OUT"
echo "wrote $OUT"
