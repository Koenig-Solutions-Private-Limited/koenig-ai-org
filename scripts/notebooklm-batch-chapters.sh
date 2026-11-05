#!/usr/bin/env bash
# Generic NotebookLM chapter-asset batch (course-gen v3 producer tool).
# Usage: notebooklm-batch-chapters.sh [--no-upload] <course-slug> <NN-chslug> [<NN-chslug> ...]
#   (max 3 chapters per run — single Google account etiquette)
# For each chapter: per-chapter notebook (chapter md + outline + dossier +
# frontmatter source URLs), async kickoff of the full artifact set, 60s poll,
# download, easy→hard quiz serialization, then upload-chapter-assets.mjs.
#
# Portable: runs on bash 3.2 (stock macOS), bash 4/5 (Linux, Paperclip box) and
# Git Bash/WSL. Per-chapter state lives in files under $WORK/<chapter>/ instead
# of associative arrays (bash 3.2 has none — `typeset -A` fails there and the
# chapter names were then evaluated as arithmetic, crashing the run after the
# first notebook had already been created).
#
#   --no-upload   generate + download only; skip R2 upload and the vault
#                 sidecar. Use for local testing. Files stay in $WORK.
#   NLM_POLL_MAX  max 60s polls (default 70 ≈ 70 min)
#
# Exit codes: 0 all chapters complete (or uploaded), 1 usage/setup error,
# 2 one or more chapters missing artifacts or failed to upload.
set -u
export PATH="/paperclip/.local/venvs/notebooklm/bin:/paperclip/bin:/paperclip/.local/bin:$HOME/.local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

UPLOAD=1
if [ "${1:-}" = "--no-upload" ]; then UPLOAD=0; shift; fi
[ $# -lt 2 ] && { echo "usage: $0 [--no-upload] <course-slug> <NN-chslug> [<NN-chslug> ...]"; exit 1; }
COURSE="$1"; shift
CHAPTERS=("$@")
[ ${#CHAPTERS[@]} -gt 3 ] && { echo "max 3 chapters per run"; exit 1; }
POLL_MAX="${NLM_POLL_MAX:-70}"

command -v notebooklm >/dev/null || { echo "ERROR: notebooklm CLI not on PATH (pip install 'notebooklm-py[browser]')"; exit 1; }
command -v python3 >/dev/null || { echo "ERROR: python3 not on PATH"; exit 1; }

# Guard against the unquoted-$VAR word-split bug: a single arg holding several
# chapter names (contains whitespace) would create merged dirs/R2 keys.
for CH in "${CHAPTERS[@]}"; do
  case "$CH" in *[[:space:]]*)
    echo "ERROR: chapter arg '$CH' contains whitespace — pass each chapter as its own argument"; exit 1;;
  esac
  [ -f "$ROOT/vault/courses/$COURSE/$CH/chapter.md" ] || [ -f "$ROOT/vault/courses/$COURSE/$CH.md" ] || { echo "ERROR: no chapter file found at vault/courses/$COURSE/$CH/chapter.md or vault/courses/$COURSE/$CH.md"; exit 1; }
done

# Fail before creating any notebook if auth is broken (expired cookies are the
# most common failure on headless boxes).
notebooklm auth check --test >/dev/null 2>&1 || { echo "ERROR: NotebookLM auth check failed — run 'notebooklm login' (or refresh NOTEBOOKLM_AUTH_JSON)"; exit 1; }

WORK="${TMPDIR:-/tmp}"; WORK="${WORK%/}/nlm-batch-$COURSE-$$"
LOG="$WORK/batch.log"
mkdir -p "$WORK"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; echo "[$(date '+%H:%M:%S')] $*"; }
VAULT="$ROOT/vault/courses/$COURSE"
AUDIENCE=$(grep -m1 '^target_audience:' "$VAULT/outline.md" | sed 's/^target_audience: *//; s/^"//; s/"$//' | head -c 200)
log "work dir: $WORK (upload=$UPLOAD)"

# Per-chapter state helpers (files, not associative arrays).
st_get() { [ -f "$WORK/$1/.$2" ] && cat "$WORK/$1/.$2" || echo "${3:-}"; }
st_set() { printf '%s' "$3" > "$WORK/$1/.$2"; }
chapter_md() { if [ -f "$VAULT/$1/chapter.md" ]; then echo "$VAULT/$1/chapter.md"; else echo "$VAULT/$1.md"; fi; }
json_field() { python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for k in sys.argv[1:]:
    v=d
    for p in k.split('.'):
        v=v.get(p) if isinstance(v,dict) else None
    if v: print(v); break" "$@"; }

for CH in "${CHAPTERS[@]}"; do
  mkdir -p "$WORK/$CH"
  CH_MD=$(chapter_md "$CH")
  TITLE=$(grep -m1 '^title:' "$CH_MD" | sed 's/^title: *//; s/^"//; s/"$//')
  ID=$(notebooklm create "$COURSE — $CH" --json 2>>"$LOG" | json_field id notebook_id notebook.id)
  [ -z "$ID" ] && { log "FATAL $CH notebook create (see $LOG)"; continue; }
  st_set "$CH" notebook "$ID"
  log "$CH notebook $ID"

  add_source() { # <notebook> <path-or-url> [title]
    local SID
    if [ -n "${3:-}" ]; then
      SID=$(notebooklm source add "$2" --title "$3" -n "$1" --json 2>>"$LOG" | json_field id source_id source.id)
    else
      SID=$(notebooklm source add "$2" -n "$1" --json 2>>"$LOG" | json_field id source_id source.id)
    fi
    [ -n "$SID" ] && echo "$SID" >> "$WORK/$CH/.sources" || log "$CH: WARN source add failed: $2"
  }
  # Upload sanitized copies: internal frontmatter (ticket ids, pipeline status,
  # author agent, SEO targeting) otherwise leaks into learner-facing artifacts —
  # e.g. study guides printed "Ticket: KOEA-2461" in their header.
  clean_copy() { # <src.md> <dest.md>
    python3 - "$1" "$2" <<'PY'
import re, sys
src, dest = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
DROP = re.compile(r"^(ticket|tickets|issue|issue_id|status|author|reviewer\w*|positions|content_type|"
                  r"chapter_primary_query|vendor_tag|course_slug|chapter_slug|slug|paperclip\w*|"
                  r"g\d\w*|gate\w*|\w*_ticket)$")
m = re.match(r"^---\n(.*?)\n---\n?", text, re.S)
if m:
    kept, skip = [], False
    for line in m.group(1).split("\n"):
        key = re.match(r"^([A-Za-z0-9_]+):", line)
        if key:
            skip = bool(DROP.match(key.group(1)))
        if not skip:
            kept.append(line)
    text = "---\n" + "\n".join(kept) + "\n---\n" + text[m.end():]
open(dest, "w", encoding="utf-8").write(text)
PY
  }
  mkdir -p "$WORK/$CH/src"
  clean_copy "$CH_MD" "$WORK/$CH/src/chapter.md"
  clean_copy "$VAULT/outline.md" "$WORK/$CH/src/outline.md"
  add_source "$ID" "$WORK/$CH/src/chapter.md" "$TITLE"
  add_source "$ID" "$WORK/$CH/src/outline.md" "Course outline"
  DOSSIER="$ROOT/vault/research/courses/$COURSE/$CH.md"
  if [ -f "$DOSSIER" ]; then
    clean_copy "$DOSSIER" "$WORK/$CH/src/dossier.md"
    add_source "$ID" "$WORK/$CH/src/dossier.md" "Research dossier"
  fi
  # frontmatter source URLs (up to 6) — NotebookLM grounds only in uploads
  python3 -c "
import sys, re
s = open(sys.argv[1]).read()
m = re.search(r'^sources:\n((?:\s*-\s*.*\n)+)', s, re.M)
if m:
    for line in m.group(1).strip().split('\n'):
        u = line.strip().lstrip('- ').strip().strip('\"')
        if u.startswith('http'): print(u)
" "$CH_MD" | head -6 > "$WORK/$CH.urls"
  while read -r URL; do
    [ -n "$URL" ] && add_source "$ID" "$URL"
  done < "$WORK/$CH.urls"
  # Wait for every source to finish processing (replaces a blind `sleep 6`;
  # generating before sources are ready yields thin or ungrounded artifacts).
  READY=0; TOTAL=0
  while read -r SID; do
    TOTAL=$((TOTAL+1))
    notebooklm source wait "$SID" -n "$ID" --timeout 180 >> "$LOG" 2>&1 && READY=$((READY+1))
  done < "$WORK/$CH/.sources"
  log "$CH: sources ready $READY/$TOTAL"
  [ "$READY" = "0" ] && { log "FATAL $CH: no usable sources"; st_set "$CH" notebook ""; continue; }

  INSTR="Audience: $AUDIENCE Focus on this chapter: $TITLE. Practical, example-driven. Prioritize the research dossier for facts, benchmark numbers, and comparison tables; cite specific figures rather than vague claims."
  gen() { # <label> <generate args...> — logs failures instead of hiding them
    local L=$1 R="--retry 2"; shift
    [ "$L" = "mind-map" ] && R=""   # mind-map has no --retry flag
    # shellcheck disable=SC2086
    if notebooklm generate "$@" -n "$ID" $R >> "$LOG" 2>&1; then :; else log "$CH: WARN generate $L refused (quota/rate limit?) — see log"; fi
    sleep 3
  }
  gen slide-deck slide-deck "$INSTR Follow the chapter's section structure. Include the comparison tables and slide-worthy benchmarks from the research dossier as dedicated slides, and render the visual-framework descriptions as diagrams. End with a practice/next-steps slide."
  gen audio audio "Deep dive. $INSTR Use the dossier's audience scenario as the running example through the conversation." --format deep-dive
  gen video video "Explainer. $INSTR Build around the visual frameworks described in the dossier."
  gen quiz-easy quiz "Simple comprehension check. $INSTR" --difficulty easy --quantity standard
  gen flashcards flashcards "Key terms. $INSTR"
  gen report report --format study-guide --append "$INSTR"
  gen infographic infographic "$INSTR"
  gen mind-map mind-map
  log "$CH: 8 generations kicked"
done

dl() { local CH=$1 T=$2 F=$3; shift 3
  [ -s "$F" ] && return 0
  notebooklm download "$T" "$F" -n "$(st_get "$CH" notebook)" "$@" >> "$LOG" 2>&1 && log "$CH: got $T"
}

# Artifact status ids (notebooklm-py ArtifactStatus): 1 pending, 2 processing,
# 3 completed, 4 failed, 6 pending_review, 7 scheduled ("Generate later" when
# over quota). 1/2/6/7 all mean "not done yet"; 4 gets one in-place retry.
for i in $(seq 1 "$POLL_MAX"); do
  sleep 60
  ALL=1
  for CH in "${CHAPTERS[@]}"; do
    NBID=$(st_get "$CH" notebook)
    [ -z "$NBID" ] && continue
    notebooklm artifact list -n "$NBID" --json 2>/dev/null | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for a in d.get('artifacts',[]): print(a['type_id'], a['status_id'], a['id'])" > "$WORK/$CH.state"
    # An empty artifact list is a transient API hiccup, NOT completion —
    # treating it as done strands slides/audio/video mid-generation.
    if [ ! -s "$WORK/$CH.state" ]; then
      log "poll#$i $CH: empty artifact list (transient) — still pending"
      ALL=0; continue
    fi
    P=$(awk '$2==1||$2==2||$2==6||$2==7' "$WORK/$CH.state" | wc -l | tr -d ' ')
    log "poll#$i $CH: pending=$P"
    [ "$P" != "0" ] && ALL=0
    while read -r T S AID; do
      if [ "$S" = "4" ]; then
        if [ ! -f "$WORK/$CH/.retried-$AID" ]; then
          touch "$WORK/$CH/.retried-$AID"
          notebooklm artifact retry "$AID" -n "$NBID" >> "$LOG" 2>&1 && log "$CH: $T failed — retrying" || log "$CH: $T failed — retry refused"
          ALL=0
        fi
        continue
      fi
      [ "$S" != "3" ] && continue
      case "$T" in
        audio) dl "$CH" audio "$WORK/$CH/audio.mp3" ;;
        slide-deck|slide_deck) dl "$CH" slide-deck "$WORK/$CH/slide-deck.pdf" ;;
        video) dl "$CH" video "$WORK/$CH/video.mp4" ;;
        flashcard|flashcards) dl "$CH" flashcards "$WORK/$CH/flashcards.json" --format json ;;
        infographic) dl "$CH" infographic "$WORK/$CH/infographic.png" ;;
        mind-map|mind_map) dl "$CH" mind-map "$WORK/$CH/mind-map.json" ;;
        report) dl "$CH" report "$WORK/$CH/study-guide.md" ;;
        quiz)
          if [ "$(st_get "$CH" easy 0)" = "0" ]; then
            notebooklm download quiz "$WORK/$CH/quiz-easy.json" -n "$NBID" --format json >> "$LOG" 2>&1 && { st_set "$CH" easy 1; log "$CH: got quiz-easy"; }
          elif [ "$(st_get "$CH" hard 0)" = "1" ] && [ ! -s "$WORK/$CH/quiz-hard.json" ]; then
            notebooklm download quiz "$WORK/$CH/quiz-hard.json" -n "$NBID" --format json >> "$LOG" 2>&1 && log "$CH: got quiz-hard"
          fi ;;
      esac
    done < "$WORK/$CH.state"
    if [ "$(st_get "$CH" easy 0)" = "1" ] && [ "$(st_get "$CH" hard 0)" = "0" ]; then
      notebooklm generate quiz "Challenging applied questions. Chapter: $CH" --difficulty hard --quantity standard -n "$NBID" --retry 2 >> "$LOG" 2>&1
      st_set "$CH" hard 1; log "$CH: kicked quiz-hard"; ALL=0
    fi
    { [ "$(st_get "$CH" hard 0)" = "0" ] || [ ! -s "$WORK/$CH/quiz-hard.json" ]; } && ALL=0
  done
  [ "$ALL" = "1" ] && break
done

# Report what arrived, then upload (video best-effort) + write sidecars.
EXPECTED="audio.mp3 slide-deck.pdf video.mp4 quiz-easy.json quiz-hard.json flashcards.json study-guide.md infographic.png mind-map.json"
RC=0
for CH in "${CHAPTERS[@]}"; do
  MISSING=""
  for F in $EXPECTED; do [ -s "$WORK/$CH/$F" ] || MISSING="$MISSING $F"; done
  if [ -z "$(st_get "$CH" notebook)" ]; then
    log "$CH: FAILED — no notebook"; RC=2; continue
  fi
  [ -n "$MISSING" ] && { log "$CH: MISSING:$MISSING"; RC=2; } || log "$CH: all 9 artifacts downloaded"
  if [ "$UPLOAD" = "1" ]; then
    TITLE=$(grep -m1 '^title:' "$(chapter_md "$CH")" | sed 's/^title: *//; s/^"//; s/"$//')
    if node "$ROOT/scripts/upload-chapter-assets.mjs" --course "$COURSE" --chapter "$CH" \
      --dir "$WORK/$CH" --notebook "$(st_get "$CH" notebook)" --title "$TITLE" >> "$LOG" 2>&1; then
      log "$CH: uploaded + sidecar"
    else
      log "$CH: UPLOAD FAILED (see $LOG)"; RC=2
    fi
  fi
done
log "BATCH DONE: ${CHAPTERS[*]} (exit $RC) — files in $WORK"
exit $RC
