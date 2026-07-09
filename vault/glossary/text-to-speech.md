---
term: "Text-to-Speech"
definition: "A speech synthesis capability that converts written text into natural-sounding audio speech, using neural models trained on human speech recordings to generate expressive, voice-cloned, or custom-voiced audio."
seo_description: "Text-to-speech: converting written text to natural-sounding audio using neural synthesis models trained on human speech recordings."
category: "LLM concepts"
related_terms: [multimodal, speech-to-text, transformer]
---

Neural text-to-speech (TTS) models like Tacotron 2, FastSpeech, and their successors generate mel-spectrograms from phoneme sequences, then convert spectrograms to audio waveforms using vocoders (HiFi-GAN, WaveNet). Diffusion-based TTS models (Voicebox, VoiceBox 2) and flow matching approaches (Kokoro, Cartesia Sonic) produce state-of-the-art naturalness and emotion control.

Zero-shot voice cloning—reproducing a target voice from a short reference audio clip—has become reliable with models like XTTS, Parler-TTS, and Chatterbox (open-source). This capability powers personalized assistant voices, audiobook narration, and localization. Commercial ElevenLabs pioneered high-quality cloning; open-source alternatives now achieve comparable quality.

For AI agent pipelines, TTS enables voice interfaces without ElevenLabs dependency. Kokoro and OmniVoice provide MIT-licensed TTS with multiple voice styles suitable for production use. Latency is a key metric: streaming TTS models begin producing audio before completing synthesis, achieving first-byte latencies under 200ms.

## Related Terms

- [[glossary/multimodal|Multimodal]] — the ability to process and generate content across text, images, audio, and other modalities
- [[glossary/speech-to-text|Speech-to-Text]] — the task of converting spoken audio into written transcriptions
- [[glossary/transformer|Transformer]] — the neural architecture underlying virtually all modern LLMs
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
