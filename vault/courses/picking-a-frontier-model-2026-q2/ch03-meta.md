---
chapter_path: vault/courses/picking-a-frontier-model-2026-q2/03-long-context-behavior.md
assets_generated:
  - ch03-slides.pptx
  - voiceover-03.mp3
assets_blocked:
  - mindmap.png
  - flashcards.json
tool: python-pptx (slides) / macOS-say (audio fallback)
slide_count: 11
slide_file: vault/courses/picking-a-frontier-model-2026-q2/ch03-slides.pptx
duration_audio_sec: 166
audio_lufs: -16
audio_kbps: 50
audio_hz: 22050
audio_note: macOS TTS fallback (Nova voice). Short (2.8 min vs 8–12 min DOD target). Flagged for re-run when notebooklm-py or Cartesia/Kokoro is available.
produced_at: 2026-05-13T03:22:00Z
---

## Production notes

- `notebooklm-py` not installed in environment; not available in $PATH.
- Local open-notebook (port 5055) has no configured provider credentials — podcast fallback not viable.
- Slides built with **python-pptx** from chapter source content via `scripts/generate_blog_slides.py` pattern. All 11 slides derived from chapter markdown; no content invented.
- Audio (`voiceover-03.mp3`) produced by macOS `say` (builtin TTS, Nova voice preset) — same constraint as ch01 and ch02. Duration 165.96s (2.8 min), below the 8–12 min DOD target. See `voiceover-03-meta.json` for details.
- Chapter frontmatter says `status: draft-for-review` (not `g0-passed`) — dispatched by Paperclip issue (SLIDES BACKFILL) as authoritative production signal; flagged for follow-up with G0 reviewer.

## Asset inventory

| Asset | Status | Notes |
|---|---|---|
| `ch03-slides.pptx` | ✅ shipped | 11 slides; first slide: "PICKING A FRONTIER MODEL · 2026 Q2"; final slide: "Try it next →" |
| `voiceover-03.mp3` | ⚠️ partial | macOS TTS fallback; 2.8 min vs 8–12 min target; re-run needed |
| `mindmap.png` | ❌ blocked | 7 key concepts (≥5 threshold met); blocked — notebooklm-py unavailable |
| `flashcards.json` | ❌ blocked | 2 KnowledgeChecks present; blocked — same tool constraint |

## Inspection results

| Check | Result | Notes |
|---|---|---|
| Slide count ≥ 9 (3121 words ÷ 1000 × 3) | ✅ 11 slides | Meets ≥3/1000-word DOD |
| First slide titled correctly | ✅ | "PICKING A FRONTIER MODEL · 2026 Q2" |
| Final slide has CTA | ✅ | Slide 11: "Try it next →" |
| Content grounded in source | ✅ | All slide content derived from 03-long-context-behavior.md |
| Audio normalized | ✅ | −16 LUFS (voiceover-03-meta.json) |
| Placeholder copy in slides | ✅ None | No lorem ipsum or placeholder text detected |

## Blocked assets — unblock path

- **Mindmap + flashcards**: Require notebooklm-py (primary) or open-notebook with configured provider (Cartesia/OpenAI/Groq key).
- **Full audio overview**: Same dependency. Re-run this issue after Cartesia API key is restored in .env.
- **Escalation owner**: Chief Content — decide whether to ship ch03 slides-only or hold for audio re-run.
