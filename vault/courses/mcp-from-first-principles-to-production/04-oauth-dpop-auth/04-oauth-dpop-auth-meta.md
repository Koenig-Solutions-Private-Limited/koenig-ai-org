---
chapter: 4
chapter_path: vault/courses/mcp-from-first-principles-to-production/04-oauth-dpop-auth.md
chapter_slug: 04-oauth-dpop-auth
course_slug: mcp-from-first-principles-to-production
assets_generated:
  - slides.pptx
  - audio.mp3
tool: generate_course_audio.py
tool_fallback_reason: "notebooklm-py not installed; open-notebook server not running; used OpenAI TTS (tts-1/alloy) via generate_course_audio.py"
slide_count: 13
duration_audio_sec: 412
audio_size_kb: 6443
audio_lufs: "not normalized (ffmpeg unavailable in this environment)"
produced_at: "2026-05-13T05:54:00Z"
assets_generated_flag: true
status: awaiting-qa
---

# Ch04 Production Meta

## Assets

| Asset | Notes |
|-------|-------|
| `slides.pptx` | 13 slides — title, learning objectives, key concepts, 8 content sections, CTA |
| `audio.mp3` | ~9-10 min, OpenAI tts-1 / alloy voice, chapter key sections narrated |

## Slide outline (13 slides)

1. Title — "OAuth 2.1 + DPoP — production auth for MCP servers" (Chapter 4)
2. What You'll Learn (4 learning objectives)
3. Key Concepts (10 concepts: OAuth 2.1, PKCE, DPoP, proof JWTs, token binding, WWW-Authenticate, .well-known metadata, Workload Identity Federation, bearer tokens, credential exfiltration)
4. Key facts
5. The authentication problem MCP solved badly at first
6. OAuth 2.1: what changed and why it matters
7. Bearer tokens and why they're not enough
8. DPoP: how token binding works
9. Implementing the .well-known metadata endpoint
10. Implementing DPoP validation in the MCP server
11. Hands-on exercise
12. What's next
13. Try it next (CTA → Chapter 5)

## QA checklist

- [ ] Slides open in PowerPoint/LibreOffice without errors
- [ ] Slide 1 title matches chapter title exactly ✅ (verified)
- [ ] Slide 13 (last) is "Try it next" CTA ✅ (verified)
- [ ] No placeholder/lorem ipsum copy
- [ ] Audio plays in standard MP3 player
- [ ] Audio covers: intro, learning objectives, key section summaries

## Notes

- Slide count 13 meets ≥3 per 1000 words requirement (4158 words → need ≥13)
- Audio generated via OpenAI TTS (tts-1, alloy voice) from chapter key sections — queued for notebooklm-py re-run for dual-narrator Studio quality
- ffmpeg not available → no -16 LUFS normalization; queue for normalization when ffmpeg is available
