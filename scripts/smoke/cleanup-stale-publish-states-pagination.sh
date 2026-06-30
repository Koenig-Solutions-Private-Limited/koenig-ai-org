#!/usr/bin/env bash
# Smoke test: cleanup-stale-publish-states.sh paginates past the 1000-row API cap.
set -euo pipefail

log() {
  echo "[cleanup-stale-pagination] $*"
}

fail() {
  echo "[cleanup-stale-pagination] ERROR: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLEANUP_SCRIPT="$REPO_ROOT/scripts/cleanup-stale-publish-states.sh"
STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

[[ -f "$CLEANUP_SCRIPT" ]] || fail "missing cleanup script: $CLEANUP_SCRIPT"

bash -n "$CLEANUP_SCRIPT" || fail "bash -n failed for cleanup script"

if rg -n 'issues\?limit=2000' "$CLEANUP_SCRIPT" >/dev/null 2>&1; then
  fail "cleanup script still uses single-page limit=2000 fetch"
fi

if ! rg -n 'offset=' "$CLEANUP_SCRIPT" >/dev/null 2>&1; then
  fail "cleanup script missing offset= pagination"
fi

python3 - "$STUB_DIR" <<'PY'
import json
from pathlib import Path

stub_dir = Path(__import__("sys").argv[1])

def make_issue(identifier: str, publish_state: str) -> dict:
    return {
        "id": f"id-{identifier}",
        "identifier": identifier,
        "metadata": {"publish_state": publish_state, "slug": None},
    }

page1 = [{"id": f"page1-{i}", "identifier": f"KOEA-{i}", "metadata": {}} for i in range(1000)]
page2 = [make_issue("KOEA-LATE-STALE", "ready")]
(stub_dir / "page-0.json").write_text(json.dumps({"items": page1}), encoding="utf-8")
(stub_dir / "page-1000.json").write_text(json.dumps({"items": page2}), encoding="utf-8")
PY

cat >"$STUB_DIR/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
url=""
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      out="$2"
      shift 2
      ;;
    *)
      if [[ "$1" == http* ]]; then
        url="$1"
      fi
      shift
      ;;
  esac
done

stub_dir="${CLEANUP_PAGINATION_STUB_DIR:?}"
offset="${url##*offset=}"
if [[ "$offset" == "$url" ]]; then
  offset="0"
fi

case "$offset" in
  0)
    cp "$stub_dir/page-0.json" "$out"
    ;;
  1000)
    cp "$stub_dir/page-1000.json" "$out"
    ;;
  *)
    echo "[]" >"$out"
    ;;
esac
CURL
chmod +x "$STUB_DIR/curl"

export CLEANUP_PAGINATION_STUB_DIR="$STUB_DIR"
export PATH="$STUB_DIR:$PATH"
export PAPERCLIP_API_URL="http://paperclip.test"
export PAPERCLIP_COMPANY_ID="company-test"
export PAPERCLIP_API_KEY="token-test"

output="$(bash "$CLEANUP_SCRIPT" 2>&1)"
echo "$output"

[[ "$output" == *"issue-list: fetched 1001 issues (paginated, page_size=1000)"* ]] \
  || fail "pagination log missing expected fetched count"
[[ "$output" == *"Found 1 stale publish_state candidates"* ]] \
  || fail "late-page stale candidate not discovered"
[[ "$output" == *"KOEA-LATE-STALE"* ]] \
  || fail "late-page identifier missing from dry-run output"
[[ "$output" == *"Dry run only"* ]] \
  || fail "dry-run default semantics changed"

log "smoke check passed"
