#!/usr/bin/env bash
# cleanup-stale-publish-states.sh — classify and repair stale publish_state metadata.
#
# Default: dry-run (prints proposed PATCHes only).
# Use --apply to issue PATCH requests against the Paperclip API.
#
# Cohort A: publish tickets with slug + matching vault/blogs/<slug>/draft.md
#   - live URL (HTTP 200) → publish_state=published + slug-specific published_url
#   - 404 → leave at g4-approved (publish-action will dispatch)
# Cohort B: upstream/mis-classified tickets (no slug or no vault draft)
#   - clear metadata.publish_state

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.koenig"
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"
PROD_URL="https://academy.kspl.tech"
APPLY=0

if [[ "${1:-}" == "--apply" ]]; then
  APPLY=1
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--apply]" >&2
  exit 1
fi

env_value() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" && -f "$ENV_FILE" ]]; then
    value="$(grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- || true)"
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
  fi
  printf '%s' "$value"
}

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

PAPERCLIP_URL="$(env_value PAPERCLIP_API_URL)"
if [[ -z "$PAPERCLIP_URL" ]]; then
  PAPERCLIP_URL="$(env_value PAPERCLIP_URL)"
fi
PAPERCLIP_URL="${PAPERCLIP_URL:-http://localhost:3100}"

COMPANY_ID="$(env_value PAPERCLIP_COMPANY_ID)"
if [[ -z "$COMPANY_ID" ]]; then
  COMPANY_ID="$(env_value COMPANY_ID)"
fi
if [[ -z "$COMPANY_ID" ]]; then
  echo "ERROR: PAPERCLIP_COMPANY_ID/COMPANY_ID missing" >&2
  exit 1
fi

AUTH_TOKEN="$(env_value PAPERCLIP_BOARD_TOKEN)"
if [[ -z "$AUTH_TOKEN" ]]; then
  AUTH_TOKEN="$(env_value PAPERCLIP_API_KEY)"
fi
if [[ -z "$AUTH_TOKEN" ]]; then
  echo "ERROR: PAPERCLIP_BOARD_TOKEN/PAPERCLIP_API_KEY missing" >&2
  exit 1
fi

ISSUES_JSON="$(mktemp)"
trap 'rm -f "$ISSUES_JSON"' EXIT

fetch_all_issues() {
  local aggregate_tmp page_tmp normalized_tmp
  local offset=0
  local page_size=1000
  local page_count=0
  local total_fetched=0

  aggregate_tmp="$(mktemp)"
  echo "[]" > "$aggregate_tmp"

  while true; do
    page_tmp="$(mktemp)"
    normalized_tmp="$(mktemp)"
    if ! curl -sf -H "Authorization: Bearer $AUTH_TOKEN" \
      "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues?limit=${page_size}&offset=${offset}" \
      -o "$page_tmp"; then
      rm -f "$aggregate_tmp" "$page_tmp" "$normalized_tmp"
      echo "ERROR: failed to fetch issues from Paperclip API (offset=$offset)" >&2
      return 1
    fi

    if ! python3 - "$page_tmp" > "$normalized_tmp" 2>/dev/null <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)
items = data.get("items", data) if isinstance(data, dict) else data
if not isinstance(items, list):
    raise ValueError("issue list payload must be an array or object with items[]")
print(json.dumps(items))
PY
    then
      rm -f "$aggregate_tmp" "$page_tmp" "$normalized_tmp"
      echo "ERROR: invalid issue response payload (offset=$offset)" >&2
      return 1
    fi

    if ! python3 - "$aggregate_tmp" "$normalized_tmp" > "$ISSUES_JSON" 2>/dev/null <<'PY'
import json
import sys

aggregate_path, page_path = sys.argv[1], sys.argv[2]
with open(aggregate_path, "r", encoding="utf-8") as fh:
    aggregate = json.load(fh)
with open(page_path, "r", encoding="utf-8") as fh:
    page = json.load(fh)
if not isinstance(aggregate, list) or not isinstance(page, list):
    raise ValueError("normalized payload is not an array")
aggregate.extend(page)
print(json.dumps(aggregate))
PY
    then
      rm -f "$aggregate_tmp" "$page_tmp" "$normalized_tmp" "$ISSUES_JSON"
      echo "ERROR: failed to merge issue pages (offset=$offset)" >&2
      return 1
    fi

    mv "$ISSUES_JSON" "$aggregate_tmp"
    page_count="$(python3 - "$normalized_tmp" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)
print(len(data))
PY
)"
    rm -f "$page_tmp" "$normalized_tmp"
    total_fetched=$((offset + page_count))
    if [ "$page_count" -lt "$page_size" ]; then
      break
    fi
    offset=$((offset + page_size))
  done

  mv "$aggregate_tmp" "$ISSUES_JSON"
  echo "issue-list: fetched ${total_fetched} issues (paginated, page_size=${page_size})" >&2
}

if ! fetch_all_issues; then
  exit 1
fi

python3 - "$ISSUES_JSON" "$REPO_ROOT" "$PROD_URL" "$APPLY" "$PAPERCLIP_URL" "$AUTH_TOKEN" <<'PY'
import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

issues_path, repo_root, prod_url, apply_flag, api_url, auth_token = sys.argv[1:7]
apply = apply_flag == "1"
repo = Path(repo_root)

with open(issues_path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

items = data.get("items", data) if isinstance(data, dict) else data
if not isinstance(items, list):
    print("No issues returned.")
    sys.exit(0)

stale_states = {"g4-approved", "ready", "dispatching", "dispatch_failed"}
candidates = []
for item in items:
    md = item.get("metadata") or {}
    state = md.get("publish_state")
    if state not in stale_states:
        continue
    candidates.append(
        {
            "id": item["id"],
            "identifier": item.get("identifier") or item["id"],
            "publish_state": state,
            "slug": md.get("slug"),
        }
    )

def live_url_status(slug: str) -> int:
    url = f"{prod_url}/blog/{slug}"
    req = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status
    except Exception:
        return 0

def patch_issue(issue_id: str, metadata: dict) -> None:
    body = json.dumps({"metadata": metadata}).encode("utf-8")
    req = urllib.request.Request(
        f"{api_url.rstrip('/')}/api/issues/{issue_id}",
        data=body,
        method="PATCH",
        headers={
            "Authorization": f"Bearer {auth_token}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        if resp.status >= 300:
            raise RuntimeError(f"PATCH failed status={resp.status}")

cohort_a = []
cohort_b = []

for item in candidates:
    slug = item.get("slug")
    draft = repo / "vault" / "blogs" / slug / "draft.md" if slug else None
    if slug and draft and draft.is_file():
        cohort_a.append(item)
    else:
        cohort_b.append(item)

print(f"Found {len(candidates)} stale publish_state candidates")
print(f"Cohort A (publish tickets): {len(cohort_a)}")
print(f"Cohort B (clear publish_state): {len(cohort_b)}")
print()

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

for item in cohort_a:
    slug = item["slug"]
    published_url = f"{prod_url}/blog/{slug}"
    http = live_url_status(slug)
    if http == 200:
        patch = {
            "publish_state": "published",
            "published_url": published_url,
            "published_at": now,
            "slug": slug,
        }
        action = "PATCH published (live URL 200)"
    else:
        patch = {"publish_state": "g4-approved", "slug": slug}
        action = f"PATCH g4-approved (live URL {http or 'error'})"

    print(f"[A] {item['identifier']} slug={slug} state={item['publish_state']} -> {action}")
    print(f"    metadata={json.dumps(patch)}")
    if apply:
        patch_issue(item["id"], patch)
        print("    applied ✓")

for item in cohort_b:
    patch = {"publish_state": None}
    print(
        f"[B] {item['identifier']} slug={item.get('slug') or 'none'} "
        f"state={item['publish_state']} -> PATCH clear publish_state"
    )
    print(f"    metadata={json.dumps(patch)}")
    if apply:
        patch_issue(item["id"], patch)
        print("    applied ✓")

if not apply:
    print()
    print("Dry run only. Re-run with --apply to issue PATCH requests.")
PY
