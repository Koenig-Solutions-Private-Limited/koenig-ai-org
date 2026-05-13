---
chapter: 5
chapter_path: vault/courses/mcp-from-first-principles-to-production/05-gateways-audit-logs.md
chapter_slug: 05-gateways-audit-logs
course_slug: mcp-from-first-principles-to-production
assets_generated:
  - slides.pptx
  - audio.mp3
tool: openai-tts
tool_fallback_reason: "notebooklm-py not installed; open-notebook server not running; used OpenAI TTS (tts-1/alloy) directly"
slide_count: 15
audio_lufs: "not normalized (ffmpeg unavailable in this environment)"
produced_at: "2026-05-13T00:00:00Z"
status: awaiting-qa
---

# Ch05 Production Meta

## Assets

| Asset | Notes |
|-------|-------|
| `slides.pptx` | 15 slides — title, learning objectives, key concepts, 10 content sections, CTA |
| `audio.mp3` | ~9-10 min, OpenAI tts-1 / alloy voice, chapter key sections narrated |

## Slide outline (15 slides)

1. Title — "Gateways, audit logs, and shipping to a 1,000-user team" (Chapter 5)
2. What You'll Learn (4 learning objectives)
3. Key Concepts (8 concepts: MCP gateway topology, .well-known server discovery, RBAC scopes, structured audit logging, rate limiting, horizontal scaling, rolling deployments)
4. Key facts
5. The contrarian premise: gateways on day one, not day 100
6. Gateway topology: what goes where
7. Configuring mcp-gateway
8. RBAC: scopes, tools, and the least-privilege rule
9. Structured audit logging for SOC 2
10. Rate limiting: protecting your servers and your budget
11. The five production failure modes
12. Horizontal scaling and zero-downtime deployments
13. Hands-on exercise: gateway + RBAC + audit logs end-to-end
14. What's next
15. Try it next (CTA → Chapter 6)

## QA checklist

- [ ] Slides open in PowerPoint/LibreOffice without errors
- [ ] Slide 1 title matches chapter title exactly ✅ (verified)
- [ ] Slide 15 (last) is "Try it next" CTA ✅ (verified)
- [ ] No placeholder/lorem ipsum copy
- [ ] Audio plays in standard MP3 player
- [ ] Audio covers: intro, learning objectives, key section summaries

## Notes

- Slide count 15 meets ≥3 per 1000 words requirement (4287 words → need ≥13)
- Audio generated via OpenAI TTS (tts-1, alloy voice) from chapter key sections — queued for notebooklm-py re-run for dual-narrator Studio quality
- ffmpeg not available → no -16 LUFS normalization; queue for normalization when ffmpeg is available
