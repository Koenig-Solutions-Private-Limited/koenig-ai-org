#!/bin/zsh
# Generic NotebookLM chapter-asset batch (course-gen v3 producer tool).
# Usage: notebooklm-batch-chapters.sh <course-slug> <NN-chslug> [<NN-chslug> ...]
#   (max 3 chapters per run — single Google account etiquette)
# For each chapter: per-chapter notebook (chapter md + outline + dossier +
# frontmatter source URLs), async kickoff of the full artifact set, 60s poll,
# download, easy→hard quiz serialization, then upload-chapter-assets.mjs.
set -u
export PATH="$HOME/.local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COURSE="$1"; shift
CHAPTERS=("$@")
[ ${#CHAPTERS[@]} -gt 3 ] && { echo "max 3 chapters per run"; exit 1; }
# Guard against the unquoted-$VAR word-split bug: a single arg holding several
# chapter names (contains whitespace) would create merged dirs/R2 keys.
for CH in "${CHAPTERS[@]}"; do
  case "$CH" in *[[:space:]]*)
    echo "ERROR: chapter arg '$CH' contains whitespace — pass each chapter as its own argument"; exit 1;;
  esac
  [ -f "$ROOT/vault/courses/$COURSE/$CH.md" ] || { echo "ERROR: no such chapter file: vault/courses/$COURSE/$CH.md"; exit 1; }
done
WORK="/tmp/nlm-batch-$COURSE-$$"
LOG="$WORK/batch.log"
mkdir -p "$WORK"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; echo "[$(date '+%H:%M:%S')] $*"; }
VAULT="$ROOT/vault/courses/$COURSE"
AUDIENCE=$(grep -m1 '^target_audience:' "$VAULT/outline.md" | sed 's/^target_audience: *//; s/^"//; s/"$//' | head -c 200)

typeset -A NB
for CH in "${CHAPTERS[@]}"; do
  mkdir -p "$WORK/$CH"
  TITLE=$(grep -m1 '^title:' "$VAULT/$CH.md" | sed 's/^title: *//; s/^"//; s/"$//')
  J=$(notebooklm create "$COURSE — $CH" --json 2>>"$LOG")
  ID=$(echo "$J" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('id') or d.get('notebook_id') or d.get('notebook',{}).get('id') or '')" 2>/dev/null)
  [ -z "$ID" ] && { log "FATAL $CH notebook create"; continue; }
  NB[$CH]=$ID
  log "$CH notebook $ID"
  notebooklm source add "$VAULT/$CH.md" --title "$TITLE" -n "$ID" >> "$LOG" 2>&1
  notebooklm source add "$VAULT/outline.md" --title "Course outline" -n "$ID" >> "$LOG" 2>&1
  DOSSIER="$ROOT/vault/research/courses/$COURSE/$CH.md"
  [ -f "$DOSSIER" ] && notebooklm source add "$DOSSIER" --title "Research dossier" -n "$ID" >> "$LOG" 2>&1
  # frontmatter source URLs (up to 6) — NotebookLM grounds only in uploads
  python3 -c "
import sys, re
s = open(sys.argv[1]).read()
m = re.search(r'^sources:\n((?:\s*-\s*.*\n)+)', s, re.M)
if m:
    for line in m.group(1).strip().split('\n'):
        u = line.strip().lstrip('- ').strip().strip('\"')
        if u.startswith('http'): print(u)
" "$VAULT/$CH.md" | head -6 > "$WORK/$CH.urls"
  while read -r URL; do
    [ -n "$URL" ] && notebooklm source add "$URL" -n "$ID" >> "$LOG" 2>&1
  done < "$WORK/$CH.urls"
  sleep 6
  INSTR="Audience: $AUDIENCE Focus on this chapter: $TITLE. Practical, example-driven. Prioritize the research dossier for facts, benchmark numbers, and comparison tables; cite specific figures rather than vague claims."
  notebooklm generate slide-deck "$INSTR Follow the chapter's section structure. Include the comparison tables and slide-worthy benchmarks from the research dossier as dedicated slides, and render the visual-framework descriptions as diagrams. End with a practice/next-steps slide." -n "$ID" >> "$LOG" 2>&1; sleep 3
  notebooklm generate audio "Deep dive. $INSTR Use the dossier's audience scenario as the running example through the conversation." --format deep-dive -n "$ID" >> "$LOG" 2>&1; sleep 3
  notebooklm generate video "Explainer. $INSTR Build around the visual frameworks described in the dossier." -n "$ID" >> "$LOG" 2>&1; sleep 3
  notebooklm generate quiz "Simple comprehension check. $INSTR" --difficulty easy --quantity standard -n "$ID" >> "$LOG" 2>&1; sleep 3
  notebooklm generate flashcards "Key terms. $INSTR" -n "$ID" >> "$LOG" 2>&1; sleep 3
  notebooklm generate report --format study-guide --append "$INSTR" -n "$ID" >> "$LOG" 2>&1; sleep 3
  notebooklm generate infographic "$INSTR" -n "$ID" >> "$LOG" 2>&1; sleep 3
  notebooklm generate mind-map -n "$ID" >> "$LOG" 2>&1; sleep 3
  log "$CH: 8 generations kicked"
done

typeset -A EASY HARDK
for CH in "${CHAPTERS[@]}"; do EASY[$CH]=0; HARDK[$CH]=0; done

dl() { local CH=$1 T=$2 F=$3; shift 3
  [ -s "$F" ] && return 0
  notebooklm download "$T" "$F" -n "${NB[$CH]}" "$@" >> "$LOG" 2>&1 && log "$CH: got $T"
}

for i in $(seq 1 70); do
  sleep 60
  ALL=1
  for CH in "${CHAPTERS[@]}"; do
    [ -z "${NB[$CH]:-}" ] && continue
    notebooklm artifact list -n "${NB[$CH]}" --json 2>/dev/null | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for a in d.get('artifacts',[]): print(a['type_id'], a['status_id'])" > "$WORK/$CH.state"
    P=$(awk '$2==1||$2==2' "$WORK/$CH.state" | wc -l | tr -d ' ')
    log "poll#$i $CH: pending=$P"
    [ "$P" != "0" ] && ALL=0
    while read -r T S; do
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
          if [ "${EASY[$CH]}" = "0" ]; then
            notebooklm download quiz "$WORK/$CH/quiz-easy.json" -n "${NB[$CH]}" --format json >> "$LOG" 2>&1 && { EASY[$CH]=1; log "$CH: got quiz-easy"; }
          elif [ "${HARDK[$CH]}" = "1" ] && [ ! -s "$WORK/$CH/quiz-hard.json" ]; then
            notebooklm download quiz "$WORK/$CH/quiz-hard.json" -n "${NB[$CH]}" --format json >> "$LOG" 2>&1 && log "$CH: got quiz-hard"
          fi ;;
      esac
    done < "$WORK/$CH.state"
    if [ "${EASY[$CH]}" = "1" ] && [ "${HARDK[$CH]}" = "0" ]; then
      notebooklm generate quiz "Challenging applied questions. Chapter: $CH" --difficulty hard --quantity standard -n "${NB[$CH]}" >> "$LOG" 2>&1
      HARDK[$CH]=1; log "$CH: kicked quiz-hard"; ALL=0
    fi
    { [ "${HARDK[$CH]}" = "0" ] || [ ! -s "$WORK/$CH/quiz-hard.json" ]; } && ALL=0
  done
  [ "$ALL" = "1" ] && break
done

# Upload everything that arrived (video best-effort) + write sidecars
for CH in "${CHAPTERS[@]}"; do
  TITLE=$(grep -m1 '^title:' "$VAULT/$CH.md" | sed 's/^title: *//; s/^"//; s/"$//')
  node "$ROOT/scripts/upload-chapter-assets.mjs" --course "$COURSE" --chapter "$CH" \
    --dir "$WORK/$CH" --notebook "${NB[$CH]:-}" --title "$TITLE" >> "$LOG" 2>&1 && log "$CH: uploaded + sidecar"
done
log "BATCH DONE: ${CHAPTERS[*]}"
