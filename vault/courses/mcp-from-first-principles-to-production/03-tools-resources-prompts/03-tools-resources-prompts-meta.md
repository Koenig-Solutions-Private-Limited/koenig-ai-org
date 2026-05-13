---
chapter: 3
chapter_path: vault/courses/mcp-from-first-principles-to-production/03-tools-resources-prompts.md
chapter_slug: 03-tools-resources-prompts
course_slug: mcp-from-first-principles-to-production
assets_generated:
  - slides.pptx
  - audio.mp3
tool: generate_course_audio.py
tool_fallback_reason: "notebooklm-py not installed; open-notebook server not running; used OpenAI TTS (tts-1/alloy) via generate_course_audio.py"
slide_count: 12
duration_audio_sec: 701
audio_size_kb: 10957
audio_lufs: "not normalized (ffmpeg unavailable in this environment)"
produced_at: "2026-05-13T05:53:00Z"
assets_generated_flag: true
status: awaiting-qa
---

# Ch03 Production Meta

## Assets

| Asset | Notes |
|-------|-------|
| `slides.pptx` | 12 slides — title, learning objectives, key concepts, 7 content sections, CTA |
| `audio.mp3` | ~9-10 min, OpenAI tts-1 / alloy voice, chapter key sections narrated |

## Slide outline (12 slides)

1. Title — "Tools, Resources, Prompts — the three primitives and the decision rule" (Chapter 3)
2. What You'll Learn (4 learning objectives)
3. Key Concepts (9 concepts: Tools, Resources, Prompts, URI templating, inputSchema, resource subscriptions, control flow ownership, side effects, semantic classification)
4. Key facts
5. The mistake almost every developer makes
6. Tools — what the model executes
7. Resources — what the model reads
8. Prompts — what the user selects
9. The decision rule
10. Hands-on exercise: classify and implement a GitHub integration
11. What's next
12. Try it next (CTA → Chapter 4)

## QA checklist

- [ ] Slides open in PowerPoint/LibreOffice without errors
- [ ] Slide 1 title matches chapter title exactly ✅ (verified)
- [ ] Slide 12 (last) is "Try it next" CTA ✅ (verified)
- [ ] No placeholder/lorem ipsum copy
- [ ] Audio plays in standard MP3 player
- [ ] Audio covers: intro, learning objectives, key section summaries

## Notes

- Slide count 12 meets ≥3 per 1000 words requirement (3844 words → need ≥12)
- Audio generated via OpenAI TTS (tts-1, alloy voice) from chapter key sections — queued for notebooklm-py re-run for dual-narrator Studio quality
- ffmpeg not available → no -16 LUFS normalization; queue for normalization when ffmpeg is available
