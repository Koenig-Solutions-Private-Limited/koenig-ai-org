#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$ROOT/scripts/hooks/commit-msg-blog-seo.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

run_case() {
  local name="$1"
  local expect_fail="$2"
  local draft_body="$3"
  local slug="test-slug-$$-$RANDOM"
  local case_dir="$TMP/case-$RANDOM"

  mkdir -p "$case_dir/vault/blogs/$slug"
  printf '%s\n' "$draft_body" > "$case_dir/vault/blogs/$slug/draft.md"

  (
    cd "$case_dir"
    git init -q
    git config user.email test@example.com
    git config user.name test
    git add "vault/blogs/$slug/draft.md"
    if [[ "$expect_fail" == "yes" ]]; then
      if "$HOOK" /dev/null 2>"$TMP/err"; then
        echo "FAIL $name: expected rejection" >&2
        exit 1
      fi
      echo "PASS $name (rejected): $(tr '\n' ' ' < "$TMP/err")"
    else
      if ! "$HOOK" /dev/null 2>"$TMP/err"; then
        echo "FAIL $name: expected acceptance: $(cat "$TMP/err")" >&2
        exit 1
      fi
      echo "PASS $name (accepted)"
    fi
  )
}

GOOD_DESC="Learn how Anthropic MCP connectors wire Resolume and Blender into agent workflows with cited benchmarks and production guardrails for creative teams."

run_case "rule-1-missing" yes $'---\nstatus: g0-passed\ntitle: Test\n---\n\nBody'
run_case "rule-2-named-fixture" yes $'---\nstatus: g0-passed\nseo_description: Updated Resolume and Blender descriptions for accuracy\ntitle: Test\n---\n\nBody'
run_case "rule-3-accept-good" no $'---\nstatus: g0-passed\nseo_description: '"$GOOD_DESC"$'\ntitle: Test\n---\n\nBody'

echo "All commit-msg-blog-seo smoke tests passed."
