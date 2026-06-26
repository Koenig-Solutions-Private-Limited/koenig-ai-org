---
chapter_path: vault/courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark.md
issue: KOE-62
produced_at: 2026-05-28T03:18:00Z
assets_generated:
  - ch02-slides.pptx
  - ch02-audio.mp3
tool: python-pptx (slides) / generate_course_audio.py
slide_count: 12
slide_file: vault/courses/picking-a-frontier-model-2026-q2/ch02-slides.pptx
audio_file: vault/courses/picking-a-frontier-model-2026-q2/ch02-audio.mp3
duration_audio_sec: 697
audio_bitrate_kbps: 108
audio_lufs: -16.23
status: g3-passed
g3_issue: KOEA-2169
g3_passed_at: 2026-05-26T12:12:00Z
g4_approval_id: 88461ffc-4cf7-48ec-836d-f21734d579a6
notes:
  - CEO G3 alignment passed after QA audio spot-check KOEA-2169 confirmed the
    MP3 artifact, metadata, voiceover source, and public mirror URL.
  - Chapter frontmatter says status:draft-for-review (not g0-passed) — dispatched
    by Paperclip issue KOE-62 as authoritative G0 signal; flagged for follow-up.
  - Voiceover script exists at voiceover-02.md (580s, 1450 words) and was used
    as the source for TTS synthesis.
  - notebooklm-py was not installed; open-notebook was not reachable on port
    5055; the committed generate_course_audio.py helper was absent, so the
    equivalent OpenAI TTS tier-3 path was run manually with tts-1/alloy.
  - KOEA-6148 regenerated ch02 audio from voiceover-02.md using
    scripts/generate_course_audio.py (OpenAI TTS fallback path), then
    normalized with ffmpeg loudnorm.
  - PPTX slide quality: 12 slides covering all DOD topics (10x3x5 design,
    results table, pipeline math, failure modes, GPT-5.5 strict schema finding,
    interpretation guide, hands-on exercise, Try-it-next CTA).
---
