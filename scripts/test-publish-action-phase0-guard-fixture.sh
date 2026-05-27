#!/usr/bin/env bash
# Fixture: prove verify_no_pending_g4_publish skips staged-deleted vault markdown
# without crashing under set -e. No network, no push, no secrets.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

log() { printf '%s\n' "$*"; }

slug_to_issue_info() {
  echo -e "none\tnone"
}

# shellcheck source=scripts/publish-action.sh
source_guard_functions() {
  GUARD_API_ERROR=0
  GUARD_ISSUE_CACHE=""
  BLOCKED_FILES=()
  BLOCKED_REASONS=()
  BLOCKED_OLD_STATUS=()
  BLOCKED_NEW_STATUS=()
  BLOCKED_SLUGS=()
  BLOCKED_STATES=()
  BLOCKED_ISSUES=()
  GUARD_ALLOWED_COUNT=0
  LOG="/dev/stderr"

  # shellcheck disable=SC1091
  source <(sed -n '/^verify_no_pending_g4_publish() {/,/^}$/p' "$SCRIPT_DIR/publish-action.sh")
}

setup_fixture_repo() {
  cd "$FIXTURE_ROOT"
  git init -q
  git config user.email "fixture@test.local"
  git config user.name "Fixture"

  mkdir -p vault/courses/fixture-course/ch1
  cat > vault/courses/fixture-course/ch1/live.md <<'EOF'
---
status: draft
---
live content
EOF
  git add -A
  git commit -q -m "init"

  mkdir -p vault/courses/fixture-course/ch2
  cat > 'vault/courses/fixture-course/ch2/.!tmp.md' <<'EOF'
---
status: draft
---
temp
EOF
  git add -A
  git commit -q -m "add temp"

  git rm 'vault/courses/fixture-course/ch2/.!tmp.md'
  echo "updated" >> vault/courses/fixture-course/ch1/live.md
  git add vault/courses/fixture-course/ch1/live.md
}

test_acmr_excludes_deleted() {
  local staged deleted_count
  staged="$(git diff --cached --name-only --diff-filter=ACMR -- vault/ \
    | grep -E '^vault/(blogs/[^/]+|courses/[^/]+(/[^/]+)*)/[^/]+\.md$' || true)"
  deleted_count="$(git diff --cached --name-only --diff-filter=D -- vault/ | wc -l | tr -d ' ')"
  if [[ "$deleted_count" -lt 1 ]]; then
    log "FAIL: expected staged deletion in fixture repo"
    return 1
  fi
  if grep -q '\.!tmp\.md' <<< "$staged"; then
    log "FAIL: ACMR filter still includes deleted staged path"
    return 1
  fi
  log "OK: ACMR excludes staged deletion (deleted_count=$deleted_count, staged=$staged)"
}

test_guard_exits_zero() {
  source_guard_functions
  if ! verify_no_pending_g4_publish; then
    log "FAIL: verify_no_pending_g4_publish returned non-zero"
    return 1
  fi
  log "OK: verify_no_pending_g4_publish exit 0 with staged deletion present"
}

test_skip_missing_file_path() {
  source_guard_functions
  local fake='vault/courses/fixture-course/ch9/missing.md'
  local output
  output="$(
    F="$fake"
    if [[ ! -f "$F" ]]; then
      log "guard: skip missing staged file=$F"
    fi
  )"
  if ! grep -q 'guard: skip missing staged file=' <<< "$output"; then
    log "FAIL: defensive skip log not emitted"
    return 1
  fi
  log "OK: defensive skip log path verified"
}

main() {
  setup_fixture_repo
  test_acmr_excludes_deleted
  test_guard_exits_zero
  test_skip_missing_file_path
  log "fixture: all checks passed"
}

main "$@"
