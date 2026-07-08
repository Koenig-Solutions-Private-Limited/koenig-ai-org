#!/usr/bin/env bash
set -euo pipefail

violations=0
live_count=0
generic_re='^(image|picture|photo|diagram|figure|graphic)\.?$'

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

is_generic() {
  local value
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$value" =~ $generic_re ]]
}

report() {
  printf '%s:%s: %s\n' "$1" "$2" "$3"
  violations=$((violations + 1))
}

check_frontmatter() {
  local file="$1"
  local in_fm=0 line_no=0 section="" hero_url=0 hero_alt="" hero_line=0
  local inline_url=0 inline_alt="" inline_line=0

  flush_hero() {
    if (( hero_url )) && [[ -z "$(trim "$hero_alt")" ]]; then
      report "$file" "$hero_line" "hero_image has url but missing/empty alt"
    fi
  }

  flush_inline() {
    if (( inline_url )) && [[ -z "$(trim "$inline_alt")" ]]; then
      report "$file" "$inline_line" "inline_images entry has url but missing/empty alt"
    fi
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    if [[ "$line_no" -eq 1 && "$line" == "---" ]]; then
      in_fm=1
      continue
    fi
    if (( in_fm )) && [[ "$line" == "---" ]]; then
      flush_hero
      flush_inline
      break
    fi
    (( in_fm )) || continue

    if [[ "$line" =~ ^[A-Za-z_]+: ]]; then
      if [[ "$section" == "hero" && ! "$line" =~ ^hero_image: ]]; then flush_hero; fi
      if [[ "$section" == "inline" && ! "$line" =~ ^inline_images: ]]; then flush_inline; fi
      [[ "$line" =~ ^hero_image: ]] || [[ "$line" =~ ^inline_images: ]] || section=""
    fi

    if [[ "$line" =~ ^hero_image:[[:space:]]*$ ]]; then
      section="hero"; hero_url=0; hero_alt=""; hero_line=$line_no; continue
    fi
    if [[ "$line" =~ ^hero_image:[[:space:]]*(auto:flux|$) ]]; then
      section=""; continue
    fi
    if [[ "$line" =~ ^inline_images:[[:space:]]*$ ]]; then
      section="inline"; inline_url=0; inline_alt=""; inline_line=$line_no; continue
    fi

    if [[ "$section" == "hero" ]]; then
      if [[ "$line" =~ ^[[:space:]]+url:[[:space:]]*(.+)$ ]]; then hero_url=1; hero_line=$line_no; fi
      if [[ "$line" =~ ^[[:space:]]+alt:[[:space:]]*(.*)$ ]]; then
        hero_alt="${BASH_REMATCH[1]}"
        if is_generic "$(trim "$hero_alt")"; then report "$file" "$line_no" "hero_image alt is generic"; fi
      fi
    elif [[ "$section" == "inline" ]]; then
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
        flush_inline
        inline_url=0; inline_alt=""; inline_line=$line_no
      fi
      if [[ "$line" =~ url:[[:space:]]*(.+)$ ]]; then inline_url=1; inline_line=$line_no; fi
      if [[ "$line" =~ alt:[[:space:]]*(.*)$ ]]; then
        inline_alt="${BASH_REMATCH[1]}"
        if is_generic "$(trim "$inline_alt")"; then report "$file" "$line_no" "inline_images alt is generic"; fi
      fi
    fi
  done < "$file"
}

check_body() {
  local file="$1"
  local in_body=0 fence_count=0 line_no=0 prev_line="" alt lower
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    if [[ "$line" == "---" ]]; then
      fence_count=$((fence_count + 1))
      if (( fence_count == 2 )); then in_body=1; fi
      prev_line="$line"
      continue
    fi
    (( in_body )) || { prev_line="$line"; continue; }

    if [[ "$line" =~ !\[\]\( ]] && [[ ! "$line" =~ decorative:[[:space:]]*true ]] && [[ ! "$prev_line" =~ \<\!--[[:space:]]*decorative[[:space:]]*--\> ]]; then
      report "$file" "$line_no" "markdown image has empty alt"
    fi
    if [[ "$line" =~ !\[([^]]*)\]\( ]]; then
      alt="$(trim "${BASH_REMATCH[1]}")"
      if [[ -n "$alt" ]] && is_generic "$alt"; then report "$file" "$line_no" "markdown image alt is generic"; fi
    fi
    if [[ "$line" =~ \<img ]]; then
      lower="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"
      if [[ ! "$lower" =~ [[:space:]]alt= ]]; then
        report "$file" "$line_no" "img tag lacks alt attribute"
      elif [[ "$lower" =~ alt=[\"\'][[:space:]]*[\"\'] ]] && [[ ! "$line" =~ decorative:[[:space:]]*true ]] && [[ ! "$prev_line" =~ \<\!--[[:space:]]*decorative[[:space:]]*--\> ]]; then
        report "$file" "$line_no" "img tag has empty alt without decorative opt-in"
      elif [[ "$lower" =~ alt=[\"\']([^\"\']*)[\"\'] ]]; then
        alt="$(trim "${BASH_REMATCH[1]}")"
        if [[ -n "$alt" ]] && is_generic "$alt"; then report "$file" "$line_no" "img alt is generic"; fi
      fi
    fi
    prev_line="$line"
  done < "$file"
}

for file in vault/blogs/*/draft.md; do
  status="$(awk -F': *' 'NR==1 && $0!="---"{exit} /^status:/ {print $2; exit} /^---$/ && NR>1{exit}' "$file")"
  case "$status" in
    g0-passed|g3-passed|published)
      live_count=$((live_count + 1))
      check_frontmatter "$file"
      check_body "$file"
      ;;
  esac
done

if (( violations )); then
  printf 'FAIL: %s live blogs, %s violations\n' "$live_count" "$violations"
  exit 1
fi

printf 'OK: %s live blogs, 0 violations\n' "$live_count"
