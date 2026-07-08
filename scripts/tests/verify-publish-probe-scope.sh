#!/usr/bin/env bash
set -euo pipefail

# Offline fixture for KOEA-1717: if live HTML has no /slides/<slug>.pptx link,
# verifier logic must skip slides probing even when a vault slides.pptx exists.

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

slug="2026-04-30-gpt-5-5-in-codex"
url="https://academy.kspl.tech/blog/${slug}"
slide_path="/slides/${slug}.pptx"
slide_url="https://academy.kspl.tech${slide_path}"

mkdir -p "$tmpdir/vault/blogs/$slug"
: > "$tmpdir/vault/blogs/$slug/slides.pptx"

cat > "$tmpdir/live.html" <<HTML
<html>
  <body>
    <h1>Blog post</h1>
    <a href="/courses/sample-course">Course link only</a>
  </body>
</html>
HTML

curl_log="$tmpdir/curl.log"

curl() {
  echo "$*" >> "$curl_log"
  if [[ "$*" == "-s $url" ]]; then
    cat "$tmpdir/live.html"
    return 0
  fi
  if [[ "$*" == *"$slide_url"* ]]; then
    echo "unexpected slides probe" >&2
    return 99
  fi
  return 0
}

run_slides_check() {
  local html slide_path_local
  html="$(curl -s "$url")"
  slide_path_local="$(printf '%s' "$url" | sed -E 's#https?://[^/]+/(blog|courses)/([^/?#]+).*#/slides/\2.pptx#')"

  if printf '%s' "$html" | rg -q "$slide_path_local"; then
    local status
    status="$(curl -sI -o /dev/null -w "%{http_code}" "https://academy.kspl.tech$slide_path_local")"
    echo "slides_link=present path=$slide_path_local status=$status"
  else
    echo "slides_link=absent path=$slide_path_local status=n/a (skip)"
  fi
}

out="$(run_slides_check)"

if [[ "$out" != "slides_link=absent path=$slide_path status=n/a (skip)" ]]; then
  echo "unexpected output: $out" >&2
  exit 1
fi

if rg -q "$slide_url" "$curl_log"; then
  echo "failed: speculative slides URL was probed" >&2
  cat "$curl_log" >&2
  exit 1
fi

echo "PASS: no speculative slides probe when live link is absent"
