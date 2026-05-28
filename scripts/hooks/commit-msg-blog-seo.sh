#!/usr/bin/env bash
# Reject commits that advance blog drafts without a valid seo_description.
# Installed via scripts/install-hooks.sh → .git/hooks/commit-msg
set -euo pipefail

COMMIT_MSG_FILE="${1:?commit-msg file required}"
ROOT="$(git rev-parse --show-toplevel)"

COMMIT_MSG_REGEX='^\s*(rev\s*[0-9]+:|updated?\b|fixed?\b|standardized\b|bumped\b|refactored\b|chore\b|wip\b|added?\b|removed\b|merged?\b)'

check_seo_description() {
  local value="$1"
  local path="$2"
  local status="$3"

  if [[ -z "${value// /}" ]]; then
    echo "error: ${path} status=${status} seo_description fails rule 1: missing or empty; G0 requires this (see content-review SKILL)." >&2
    return 1
  fi

  local len=${#value}
  if (( len < 80 )); then
    echo "error: ${path} status=${status} seo_description fails rule 2: length=${len} < 80; G0 requires this (see content-review SKILL)." >&2
    return 1
  fi
  if (( len > 160 )); then
    echo "error: ${path} status=${status} seo_description fails rule 3: length=${len} > 160; G0 requires this (see content-review SKILL)." >&2
    return 1
  fi
  if echo "$value" | grep -qiE "$COMMIT_MSG_REGEX"; then
    echo "error: ${path} status=${status} seo_description fails rule 4: commit-message opener detected; G0 requires this (see content-review SKILL)." >&2
    return 1
  fi
}

parse_frontmatter_field() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    BEGIN { in_fm=0; found=0 }
    NR==1 && $0 ~ /^---$/ { in_fm=1; next }
    in_fm && $0 ~ /^---$/ { exit }
    in_fm && $0 ~ ("^" field ":[[:space:]]*") {
      sub("^" field ":[[:space:]]*", "", $0)
      gsub(/^"/, "", $0)
      gsub(/"$/, "", $0)
      print $0
      found=1
      exit
    }
    END { if (!found) print "" }
  ' "$file"
}

failures=0

while IFS= read -r -d '' path; do
  [[ "$path" == vault/blogs/*/draft.md ]] || continue
  full="$ROOT/$path"
  [[ -f "$full" ]] || continue

  status="$(parse_frontmatter_field "$full" status)"
  case "$status" in
    g0-passed|g3-passed|published) ;;
    *) continue ;;
  esac

  seo_description="$(parse_frontmatter_field "$full" seo_description)"
  if ! check_seo_description "$seo_description" "$path" "$status"; then
    failures=1
  fi
done < <(git diff --cached --name-only -z -- 'vault/blogs/*/draft.md')

exit "$failures"
