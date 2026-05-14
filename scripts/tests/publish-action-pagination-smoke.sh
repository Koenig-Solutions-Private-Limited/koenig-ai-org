#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/publish-action.sh"

run_case() {
  local mode="$1"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  mkdir -p "$tmp/repo" "$tmp/logs" "$tmp/fakebin"

  cat > "$tmp/repo/.env.koenig" <<'ENV'
PAPERCLIP_API_KEY=test-api-key
PAPERCLIP_BOARD_TOKEN=test-board-token
ENV

  cat > "$tmp/fakebin/git" <<'GIT'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "branch" && "${2:-}" == "--show-current" ]]; then
  echo "master"
  exit 0
fi
if [[ "$1" == "status" ]]; then
  exit 0
fi
if [[ "$1" == "diff" ]]; then
  exit 0
fi
exit 0
GIT
  chmod +x "$tmp/fakebin/git"

  cat > "$tmp/fakebin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
mode="${FAKE_CURL_MODE:-success}"
record_file="${FAKE_CURL_RECORD_FILE:-}"

out_file=""
url=""
args=("$@")
idx=0
while [[ $idx -lt ${#args[@]} ]]; do
  arg="${args[$idx]}"
  case "$arg" in
    -o)
      idx=$((idx + 1))
      out_file="${args[$idx]}"
      ;;
    -*)
      ;;
    *)
      url="$arg"
      ;;
  esac
  idx=$((idx + 1))
done

if [[ -n "$record_file" && -n "$url" ]]; then
  echo "$url" >> "$record_file"
fi

if [[ "$url" == *"/api/companies/"*"/issues?"* ]]; then
  payload='[]'
  if [[ "$url" == *"offset=0"* ]]; then
    payload="$(python3 - <<'PY'
import json
items=[{"id":f"i{i}","status":"done","metadata":{"slug":f"s{i}","publish_state":"none"}} for i in range(1000)]
print(json.dumps(items))
PY
)"
  elif [[ "$url" == *"offset=1000"* ]]; then
    if [[ "$mode" == "invalid_json" ]]; then
      payload='{bad json'
    else
      payload="$(python3 - <<'PY'
import json
items=[{"id":f"i{1000+i}","status":"done","metadata":{"slug":f"s{1000+i}","publish_state":"none"}} for i in range(998)]
items.append({"id":"koea-late-g4","status":"done","metadata":{"slug":"late-g4","publish_state":"g4-approved"}})
items.append({"id":"koea-late-dispatch","status":"done","metadata":{"slug":"late-dispatch","publish_state":"dispatching","dispatched_at":"2026-05-14T00:00:00Z"}})
print(json.dumps(items))
PY
)"
    fi
  elif [[ "$url" == *"offset=2000"* ]]; then
    payload='[{"id":"i2000","status":"done","metadata":{"slug":"s2000","publish_state":"none"}}]'
  fi

  if [[ -n "$out_file" ]]; then
    printf '%s' "$payload" > "$out_file"
  else
    printf '%s' "$payload"
  fi
  exit 0
fi

if [[ "$url" == *"api.github.com/repos/"*"/dispatches"* ]]; then
  echo "unexpected github dispatch call" >&2
  exit 1
fi

if [[ "$url" == *"api.github.com/repos/"*"/actions/runs"* ]]; then
  echo "unexpected github runs poll" >&2
  exit 1
fi

if [[ -n "$out_file" ]]; then
  printf '[]' > "$out_file"
else
  printf '[]'
fi
CURL
  chmod +x "$tmp/fakebin/curl"

  local script_copy
  script_copy="$tmp/publish-action-under-test.sh"
  cp "$SCRIPT_SRC" "$script_copy"
  sed -i "s|^REPO_ROOT=.*$|REPO_ROOT=\"$tmp/repo\"|" "$script_copy"
  sed -i "s|^ENV_FILE=.*$|ENV_FILE=\"$tmp/repo/.env.koenig\"|" "$script_copy"
  sed -i "s|^LOG_DIR=.*$|LOG_DIR=\"$tmp/logs\"|" "$script_copy"
  chmod +x "$script_copy"

  local record
  record="$tmp/curl-urls.log"
  : > "$record"

  PATH="$tmp/fakebin:$PATH" FAKE_CURL_MODE="$mode" FAKE_CURL_RECORD_FILE="$record" bash "$script_copy" >/dev/null

  local log
  log="$tmp/logs/publish-action.log"
  [[ -s "$log" ]]

  if [[ "$mode" == "success" ]]; then
    grep -q "Phase 1: SKIPPED" "$log"
    grep -q "Phase 2: SKIPPED" "$log"
    grep -q "offset=1000" "$record"
    grep -q "offset=2000" "$record"
  else
    grep -q "guard:api-error invalid issue response payload" "$log"
    grep -q "Phase 1: no g4-approved issues found." "$log"
    grep -q "Phase 2: no dispatching issues found." "$log"
  fi
}

run_case success
run_case invalid_json

echo "publish-action pagination smoke test: PASS"
