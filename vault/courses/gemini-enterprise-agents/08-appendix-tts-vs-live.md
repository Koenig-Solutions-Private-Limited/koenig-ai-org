---
course_slug: gemini-enterprise-agents
chapter_num: 8
chapter_slug: appendix-tts-vs-live
title: "Appendix: Gemini Flash TTS vs. Gemini Live API"
status: draft-for-review
author: course-author
duration_min: 10
learning_objectives:
  - "Distinguish between scripted audio generation (Flash TTS) and interactive speech agents (Live API)"
  - "Identify the correct Google audio surface for your agent's UX requirements"
---

# Appendix: Gemini Flash TTS vs. Gemini Live API

As of May 2026, Google provides two primary surfaces for audio-capable agents. While both involve "Gemini talking," they are architecturally distinct and optimized for different user experiences. Choosing the wrong one can lead to significantly higher latency or a lack of vocal control.

## Comparison at a Glance

| Dimension | Gemini 3.1 Flash TTS | Gemini Live API |
|---|---|---|
| **Primary UX** | Scripted, exact text-to-audio | Interactive, low-latency conversation |
| **Input Type** | Text only (SSML-like expressive tags) | Multimodal (Audio, Video, Text) |
| **Output Type** | High-fidelity audio file / stream | Real-time audio stream |
| **Vocal Control** | Exact (via style tags like `[whisper]`) | Generative (natural prosody) |
| **Latency** | Medium (batch or stream generation) | Ultra-low (optimized for turn-taking) |
| **Best For** | Narrated courses, podcasts, exact recitation | Voice assistants, roleplay, real-time support |

## When to use Gemini 3.1 Flash TTS

Use **Flash TTS** when your agent's response is already "final" and you need precise control over how it is read. Flash TTS is the modern successor to traditional Text-to-Speech engines, offering natural-sounding voices with the ability to inject emotion and style via tags.

**Use cases:**
- **Automated Narration**: Converting course text (like this one) into an audio version.
- **Scripted Dialogue**: Creating multi-speaker podcasts or briefings where the script is generated first by a Pro-class model.
- **Brand Consistency**: Ensuring a specific vocal style and pace that remains identical across sessions.

## When to use Gemini Live API

Use the **Live API** when you are building an agent that the user *talks to* in real-time. The Live API is a multimodal-to-multimodal pipe that minimizes the "processing" gap between a user finishing their sentence and the agent starting theirs.

**Use cases:**
- **Voice Concierge**: A real-time assistant that helps users navigate a physical space or app via voice.
- **Language Tutor**: An agent that corrects a user's pronunciation and engages in back-and-forth dialogue.
- **Real-time multimodal**: Agents that need to "see" a webcam feed while talking to the user.

## Strategic Recommendation

Do not try to build an interactive voice agent using a sequence of:
`User Audio → Speech-to-Text → LLM Reasoning → Flash TTS → User Audio`

This "cascaded" approach will always have a higher latency floor (typically 2–4 seconds) than the **Live API**, which handles the audio-to-audio path natively. Only use **Flash TTS** for the scripted, non-interactive portions of your agent's experience.
