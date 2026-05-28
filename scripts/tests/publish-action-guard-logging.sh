#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
LOG_DIR="$TMP_DIR/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/publish-action.log"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

sed '/^if \[\[ ! -f "\$ENV_FILE" \]\]/,$d' "$ROOT/scripts/publish-action.sh" \
  | sed '/^cd "\$REPO_ROOT"$/d' > "$TMP_DIR/guard-functions.sh"

mkdir -p "$TMP_DIR/fixture-repo"
export REPO_ROOT="$TMP_DIR/fixture-repo"

setup_fixture_repo() {
  local repo="$TMP_DIR/fixture-repo"
  local bare="$TMP_DIR/origin.git"
  mkdir -p "$repo/vault/blogs/test-slug"
  git init -b master "$bare" --bare >/dev/null
  git -C "$repo" init -b master >/dev/null
  git -C "$repo" config user.email "fixture@test.local"
  git -C "$repo" config user.name "Fixture"
  cat > "$repo/vault/blogs/test-slug/draft.md" <<'MD'
---
status: g4-approved
---
body
MD
  git -C "$repo" add vault/blogs/test-slug/draft.md
  git -C "$repo" commit -m "fixture" >/dev/null
  git -C "$repo" branch feature/fixture >/dev/null
  git -C "$repo" remote add origin "$bare"
  git -C "$repo" push -u origin master >/dev/null
  echo "$repo"
}

export LOG_DIR LOG
export PUBLISH_CANONICAL_REMOTE="origin"
export PUBLISH_CANONICAL_BRANCH="master"
export PAPERCLIP_URL="http://127.0.0.1:9"
export COMPANY_ID="company-fixture"
export PAPERCLIP_API_KEY="fixture-token"
export PAPERCLIP_BOARD_TOKEN="fixture-board-token"

# shellcheck source=/dev/null
source "$TMP_DIR/guard-functions.sh"
LOG="$LOG_DIR/publish-action.log"

REPO_ROOT="$(setup_fixture_repo)"
export REPO_ROOT
cd "$REPO_ROOT"

PHASE0_SYNC_OK=1
git checkout feature/fixture >/dev/null 2>&1
if on_canonical_branch; then
  echo "expected branch-mismatch guard failure" >&2
  exit 1
fi
grep -q 'origin-master-guard: BLOCK reason=branch-mismatch' "$LOG"

git checkout master >/dev/null 2>&1
PHASE0_SYNC_OK=1
on_canonical_branch

ARTIFACT="$(resolve_artifact_path "test-slug" "" || true)"
[ "$ARTIFACT" = "vault/blogs/test-slug/draft.md" ]

if resolve_artifact_path "" "" >/dev/null 2>&1; then
  echo "expected missing-artifact-path failure" >&2
  exit 1
fi

git fetch origin master >/dev/null 2>&1
if ! artifact_on_origin_master_matches "vault/blogs/test-slug/draft.md"; then
  echo "expected matching artifact on origin/master" >&2
  exit 1
fi

printf 'local-only-change\n' >> vault/blogs/test-slug/draft.md
if artifact_on_origin_master_matches "vault/blogs/test-slug/draft.md"; then
  echo "expected blob-mismatch guard failure" >&2
  exit 1
fi
grep -q 'origin-master-guard: BLOCK reason=blob-mismatch' "$LOG"

git checkout -- vault/blogs/test-slug/draft.md
PHASE0_SYNC_OK=1
finalize_phase0_sync
[ "$PHASE0_SYNC_OK" = "1" ]

printf 'dirty\n' > tracked-dirty.txt
git add tracked-dirty.txt
PHASE0_SYNC_OK=1
if finalize_phase0_sync; then
  echo "expected dirty-worktree guard failure" >&2
  exit 1
fi
[ "$PHASE0_SYNC_OK" = "0" ]
grep -q 'origin-master-guard: BLOCK reason=dirty-worktree' "$LOG"
git reset HEAD tracked-dirty.txt >/dev/null
rm -f tracked-dirty.txt

ISSUE_TMP="$TMP_DIR/issue.json"
PAYLOAD_TMP="$TMP_DIR/payload.json"
printf '{"id":"issue-fixture","metadata":{"slug":"keep-slug","publish_state":"g4-approved","extra":"stay"}}' > "$ISSUE_TMP"

curl() {
  local arg output_file="" data_file="" target_issue=0
  local args=("$@")
  local i=0
  while [ $i -lt ${#args[@]} ]; do
    arg="${args[$i]}"
    case "$arg" in
      --data@*)
        data_file="${arg#--data@}"
        ;;
      --data)
        i=$((i + 1))
        data_file="${args[$i]#@}"
        ;;
      -o)
        i=$((i + 1))
        output_file="${args[$i]}"
        ;;
      "$PAPERCLIP_URL/api/issues/issue-fixture")
        target_issue=1
        ;;
    esac
    i=$((i + 1))
  done

  if [ -n "$data_file" ]; then
    cp "$data_file" "$PAYLOAD_TMP"
    return 0
  fi
  if [ "$target_issue" = "1" ] && [ -n "$output_file" ] && [ "$output_file" != "/dev/null" ]; then
    cp "$ISSUE_TMP" "$output_file"
    return 0
  fi
  if [ "$target_issue" = "1" ] && [ -n "$output_file" ] && [ "$output_file" = "/dev/null" ]; then
    return 0
  fi
  command curl "$@"
}
export -f curl

patch_issue_metadata_merge "issue-fixture" '{"publish_state":"dispatching","dispatched_at":"2026-05-28T00:00:00Z"}'
python3 - "$PAYLOAD_TMP" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
metadata = payload["metadata"]
assert metadata["slug"] == "keep-slug", metadata
assert metadata["extra"] == "stay", metadata
assert metadata["publish_state"] == "dispatching", metadata
assert metadata["dispatched_at"] == "2026-05-28T00:00:00Z", metadata
PY

grep -q 'Phase 1: SKIPPED — Phase 0 origin/master sync guard failed' "$ROOT/scripts/publish-action.sh"
grep -q 'Phase 2: SKIPPED — Phase 0 origin/master sync guard failed' "$ROOT/scripts/publish-action.sh"
grep -q 'origin-master-guard: BLOCK issue=' "$ROOT/scripts/publish-action.sh"
grep -q 'publish-action complete' "$ROOT/scripts/publish-action.sh"

echo "publish-action guard logging fixture passed"
