---
name: slide-audio-produce
description: >
  Slide+Audio Producer's primary skill — drive notebooklm-py (primary, paid
  NotebookLM account) or open-notebook (fallback, self-hosted) to generate
  slide deck + audio overview + mind-map + flashcards + briefing PDF for a
  G0-passed course chapter. Use when ticket lands assigned to
  @slide-audio-producer.
---

# Slide-Audio Produce

You orchestrate NotebookLM. You don't generate creative content.

## Scope

- One G0-passed course chapter → slides.pdf + audio.mp3 + mindmap.png + flashcards.json + briefing.pdf
- notebooklm-py PRIMARY (Vardaan's paid quota); open-notebook FALLBACK (self-hosted, audio + chat only)
- Hand off to @qa-verifier for spot-check

## Inputs

- Paperclip ticket with `status: ready-to-produce`
- G0-passed chapter markdown at `vault/courses/<slug>/<chapter>.md`
- (For Core courses with ≥4 chapters) prior chapters in same course for context

## Workflow

### 1. Read chapter markdown + frontmatter

Verify `status: g0-passed` in frontmatter. If not, abort + comment.

### 2. Try notebooklm-py (primary)

```bash
notebooklm-py create-notebook \
  --source vault/courses/<slug>/<chapter>.md \
  --source vault/courses/<slug>/outline.md \
  --source vault/courses/<slug>/<prior-chapter>.md \
  --output-dir vault/courses/<slug>/<chapter>-assets/

notebooklm-py generate audio --notebook <id> --format dual-narrator --length 9-12min
notebooklm-py generate slides --notebook <id> --format pdf --slides 10-16
notebooklm-py generate mindmap --notebook <id> --format png
notebooklm-py generate flashcards --notebook <id> --count <KnowledgeCheck-count>
notebooklm-py generate briefing --notebook <id> --format pdf
```

If any call fails with `GENERATION_FAILED` (rate limit) → retry once; if 2 failures, fall through to Tier 2.

### 3. Fallback ladder (Tier 2 → Tier 3)

**Tier 2 — open-notebook** (self-hosted, audio + chat only; requires Docker service on `:5055`):

```bash
# Health check first
curl -fsS http://127.0.0.1:5055/health

# Boot if down:
docker compose -f observability/open-notebook/docker-compose.yml up -d

curl -X POST http://127.0.0.1:5055/api/podcasts/generate \
  -H "Authorization: Bearer $OPEN_NOTEBOOK_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"episode_profile": "solo_expert", "episode_name": "<chapter>", "content": "<chapter markdown body>"}'

# Poll job, then download:
# GET /api/podcasts/jobs/{job_id}
# GET /api/podcasts/episodes/{episode_id}/audio
```

**Tier 3 — OpenAI TTS script** (when open-notebook is down or lacks podcast support):

```bash
python3 scripts/generate_course_audio.py \
  vault/courses/<slug>/<chapter>.md \
  vault/courses/<slug>/<chapter>-assets \
  --output-name audio.mp3
```

Requires `OPENAI_API_KEY` in env (see `.env.koenig.example`). No ElevenLabs.

In any fallback run, ship audio only. Comment on ticket: "fallback used; slides/mindmap/flashcards skipped — queued for re-run when notebooklm-py is healthy."

### 4. Inspect outputs (NEVER skip)

- Slides: open the PDF; verify ≥3 slides per 1000 source words; first slide titled correctly; final slide has CTA
- Audio: load MP3; verify duration in target range; sample-check first 5 sec for coherence
- Mindmap: open PNG at full size; verify readable
- Flashcards: validate JSON schema (`vault/_schemas/flashcards.schema.json`)

If any output fails inspection → DON'T ship; retry once; if still fails, escalate.

### 5. Normalize audio loudness

```bash
ffmpeg -i <chapter>-assets/audio.mp3 \
       -af loudnorm=I=-16:LRA=11:tp=-1.5 \
       -ar 44100 -ac 2 \
       <chapter>-assets/audio-normalized.mp3
mv <chapter>-assets/audio-normalized.mp3 <chapter>-assets/audio.mp3
```

### 6. Write sidecar metadata

`<chapter>-meta.md`:

```yaml
---
chapter_path: vault/courses/<slug>/<chapter>.md
assets_generated:
  - slides.pdf
  - audio.mp3
  - mindmap.png
  - flashcards.json
  - briefing.pdf
tool: notebooklm-py | open-notebook | openai-tts
tool_fallback_reason: "notebooklm-py rate-limited after 2 attempts; open-notebook :5055 unreachable"
duration_audio_sec: 583
audio_lufs: -16
slide_count: 14
mindmap_node_count: 6
flashcard_count: 4
produced_at: 2026-04-30T15:42:00Z
notes: "Fallback audio only — Studio assets (slides/mindmap/flashcards/briefing) skipped; queue notebooklm-py re-run when healthy"
---
```

**Fallback metadata example** (open-notebook Tier 2):

```yaml
tool: open-notebook
tool_fallback_reason: "notebooklm-py GENERATION_FAILED x2"
duration_audio_sec: 579
audio_lufs: -16
notes: "Studio assets skipped in fallback run"
```

**Fallback metadata example** (OpenAI TTS Tier 3):

```yaml
tool: openai-tts
tool_fallback_reason: "open-notebook health check failed on 127.0.0.1:5055"
duration_audio_sec: 540
audio_lufs: -16
notes: "Studio assets skipped; shorter single-voice narration vs dual-narrator NotebookLM"
```

### 7. Hand off

```
status: awaiting-qa
assignee: @qa-verifier
asset_dir: vault/courses/<slug>/<chapter>-assets/
```

Comment:
```
✅ Assets ready · vault/courses/<slug>/<chapter>-assets/
- slides.pdf — 14 slides, 1.2 MB (notebooklm-py)
- audio.mp3 — 9:42, 11 MB, -16 LUFS
- mindmap.png — 1080p, 6 concept nodes
- flashcards.json — 4 cards (matches 4 KnowledgeChecks)
- briefing.pdf — 8 pages
- Status: awaiting-qa → @qa-verifier
```

## Output

5 asset files + sidecar meta + Paperclip ticket flip.

## Notes

- Don't generate content from scratch.
- Don't use ElevenLabs.
- Always inspect outputs — never trust the tool's "success" signal alone.
- Always normalize audio loudness.
- 2 notebooklm-py failures → health-check open-notebook → else Tier-3 `generate_course_audio.py`.
- Per-task cap $1.

## Escalation

- Both tools fail → ping chief-content; ask whether to ship without slides/audio or wait
- Audio output corrupted → retry once; if still fails, escalate
- Slides reference content not in source chapter (notebooklm hallucinated) → switch tool, retry; if persists, ping chief-content
