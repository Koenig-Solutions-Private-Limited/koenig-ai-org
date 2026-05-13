---
chapter: 2
chapter_path: vault/courses/mcp-from-first-principles-to-production/02-json-rpc-over-stdio.md
chapter_slug: 02-json-rpc-over-stdio
course_slug: mcp-from-first-principles-to-production
assets_generated:
  - slides.pptx
  - audio.mp3
tool: openai-tts
tool_fallback_reason: "notebooklm-py not installed; open-notebook server not running; used OpenAI TTS (tts-1/alloy) directly"
slide_count: 13
audio_lufs: "not normalized (ffmpeg unavailable in this environment)"
produced_at: "2026-05-13T00:00:00Z"
status: awaiting-qa
---

# Ch02 Production Meta

## Assets

| Asset | Notes |
|-------|-------|
| `slides.pptx` | 13 slides — title, learning objectives, key concepts, 9 content sections, CTA |
| `audio.mp3` | ~9-10 min, OpenAI tts-1 / alloy voice, chapter key sections narrated |

## Slide outline (13 slides)

1. Title — "JSON-RPC over stdio — the wire protocol explained" (Chapter 2)
2. What You'll Learn (4 learning objectives)
3. Key Concepts (7 concepts: JSON-RPC 2.0, newline-delimited framing, stdio transport, HTTP streaming transport, capability negotiation, notification vs request vs response, protocol version)
4. Why the wire format matters
5. JSON-RPC 2.0: the message envelope
6. The stdio transport: why a pipe beats a socket
7. The initialize handshake: step by step
8. Reading a real MCP exchange
9. HTTP Streaming transport: when stdio isn't enough
10. Hands-on exercise: a 60-line MCP server, no SDK
11. Error codes reference
12. What's next
13. Try it next (CTA → Chapter 3)

## QA checklist

- [ ] Slides open in PowerPoint/LibreOffice without errors
- [ ] Slide 1 title matches chapter title exactly ✅ (verified)
- [ ] Slide 13 (last) is "Try it next" CTA ✅ (verified)
- [ ] No placeholder/lorem ipsum copy
- [ ] Audio plays in standard MP3 player
- [ ] Audio covers: intro, learning objectives, key section summaries

## Notes

- Slide count 13 meets ≥3 per 1000 words requirement (3969 words → need ≥12)
- Audio generated via OpenAI TTS (tts-1, alloy voice) from chapter key sections — queued for notebooklm-py re-run for dual-narrator Studio quality
- ffmpeg not available in this environment → no -16 LUFS normalization; queue for normalization when ffmpeg is available
