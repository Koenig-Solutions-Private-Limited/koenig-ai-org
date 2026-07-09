---
term: "Speech-to-Text"
definition: "An AI capability that transcribes spoken audio into written text, using end-to-end neural models trained on large audio-text paired datasets to handle diverse accents, languages, and audio conditions."
seo_description: "Speech-to-text: AI transcription of spoken audio to written text using neural models trained on diverse audio-language pairs."
category: "LLM concepts"
related_terms: [multimodal, text-to-speech, transformer]
---

Modern speech-to-text (STT, also called automatic speech recognition or ASR) is dominated by transformer-based models. OpenAI Whisper (2022) demonstrated that training on 680,000 hours of weakly supervised internet audio produced a model that generalizes broadly across languages, accents, and audio quality. Whisper remains the dominant open-source STT model in 2026.

Faster alternatives include faster-whisper (CTranslate2-optimized), Deepgram Nova, and AssemblyAI Universal-2, which achieve near-Whisper accuracy with 10× lower latency. Streaming STT models (e.g., Parakeet from NVIDIA) transcribe audio in real time with chunk-level output, enabling live captioning and interactive voice agents.

Speaker diarization (who said what) and keyword spotting extend basic STT for meeting transcription and voice command applications. Multimodal LLMs increasingly handle STT natively: Gemini 2.5 and GPT-5 can take raw audio as input and perform transcription, translation, and reasoning in a single forward pass without a separate STT step.

## Related Terms

- [[glossary/multimodal|Multimodal]] — the ability to process and generate content across text, images, audio, and other modalities
- [[glossary/text-to-speech|Text-to-Speech]] — the task of synthesizing natural-sounding audio from written text
- [[glossary/transformer|Transformer]] — the neural architecture underlying virtually all modern LLMs
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
