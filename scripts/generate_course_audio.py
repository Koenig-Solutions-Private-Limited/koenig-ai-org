#!/usr/bin/env python3
"""Generate OpenAI TTS narration for course chapters.

Usage:
    python3 scripts/generate_course_audio.py <chapter.md> <out_dir>

Output:
    <out_dir>/audio.mp3

Tier-3 fallback when notebooklm-py and open-notebook are unavailable.
Requires OPENAI_API_KEY. Installs the OpenAI package into /tmp/openai_deps if
the runtime does not already provide it.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

OPENAI_DEPS = "/tmp/openai_deps"
WORDS_PER_MIN = 155
TARGET_MIN = 9
TARGET_WORDS = TARGET_MIN * WORDS_PER_MIN
CHUNK_CHARS = 3800


def fail(message: str, code: int = 1) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def ensure_openai() -> None:
    if OPENAI_DEPS not in sys.path:
        sys.path.insert(0, OPENAI_DEPS)
    try:
        import openai  # noqa: F401

        return
    except ImportError:
        subprocess.check_call(
            [
                sys.executable,
                "-m",
                "pip",
                "install",
                "openai",
                "--target",
                OPENAI_DEPS,
                "-q",
            ]
        )
        sys.path.insert(0, OPENAI_DEPS)


def parse_chapter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if text.startswith("---"):
        end = text.find("---", 3)
        if end != -1:
            text = text[end + 3 :]

    lines_out: list[str] = []
    in_code = False
    skip_sections = {"further reading", "references"}
    skip_current = False

    for line in text.splitlines():
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code or line.startswith("|"):
            continue
        if line.startswith("## "):
            heading = line[3:].strip().lower()
            skip_current = heading in skip_sections
        if skip_current:
            continue

        line = re.sub(r"\[\[([^\]]+)\]\]", r"\1", line)
        line = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", line)
        line = re.sub(r"\*\*(.+?)\*\*", r"\1", line)
        line = re.sub(r"\*(.+?)\*", r"\1", line)
        line = re.sub(r"`([^`]+)`", r"\1", line)
        line = re.sub(r"#+\s+", "", line)
        line = re.sub(r"^[-*+]\s+", "", line)
        line = re.sub(r"^\d+\.\s+", "", line)
        line = line.strip()
        if line and line != "---":
            lines_out.append(line)

    full_text = "\n".join(lines_out)
    words = full_text.split()
    if len(words) > TARGET_WORDS:
        full_text = " ".join(words[:TARGET_WORDS])

    return full_text


def chunk_text(text: str) -> list[str]:
    sentences = re.split(r"(?<=[.!?])\s+", text)
    chunks: list[str] = []
    current: list[str] = []
    current_len = 0
    for sentence in sentences:
        if current_len + len(sentence) + 1 > CHUNK_CHARS and current:
            chunks.append(" ".join(current))
            current = [sentence]
            current_len = len(sentence)
        else:
            current.append(sentence)
            current_len += len(sentence) + 1
    if current:
        chunks.append(" ".join(current))
    return [chunk for chunk in chunks if chunk.strip()]


def concatenate_mp3(parts: list[Path], out_path: Path, tmp_dir: Path) -> None:
    if len(parts) == 1:
        shutil.copy(parts[0], out_path)
        return

    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        fail("ffmpeg not found on PATH; cannot concatenate MP3 chunks safely")

    list_file = tmp_dir / "parts.txt"
    list_file.write_text("\n".join(f"file '{part}'" for part in parts), encoding="utf-8")
    subprocess.check_call(
        [
            ffmpeg,
            "-y",
            "-f",
            "concat",
            "-safe",
            "0",
            "-i",
            str(list_file),
            "-c",
            "copy",
            str(out_path),
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def generate_audio(chapter_path: Path, out_dir: Path) -> Path:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        fail("OPENAI_API_KEY not set")

    text = parse_chapter(chapter_path)
    if not text.strip():
        fail("no narration text extracted")

    ensure_openai()
    import openai

    client = openai.OpenAI(api_key=api_key)
    word_count = len(text.split())
    est_min = word_count / WORDS_PER_MIN
    print(f"Narration text: {word_count} words (~{est_min:.1f} min)")

    chunks = chunk_text(text)
    if not chunks:
        fail("no TTS chunks produced")
    print(f"Chunks: {len(chunks)}")

    out_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir = Path(tempfile.mkdtemp(prefix="course_tts_"))
    try:
        mp3_parts: list[Path] = []
        for index, chunk in enumerate(chunks):
            part_path = tmp_dir / f"part_{index:03d}.mp3"
            print(f"  TTS chunk {index + 1}/{len(chunks)} ({len(chunk)} chars)...")
            with client.audio.speech.with_streaming_response.create(
                model="tts-1",
                voice="alloy",
                input=chunk,
            ) as response:
                response.stream_to_file(str(part_path))
            if not part_path.exists() or part_path.stat().st_size == 0:
                fail(f"OpenAI TTS produced empty chunk: {part_path}")
            mp3_parts.append(part_path)

        out_path = out_dir / "audio.mp3"
        concatenate_mp3(mp3_parts, out_path, tmp_dir)
        if not out_path.exists() or out_path.stat().st_size == 0:
            fail(f"audio output missing or empty: {out_path}")

        size_kb = out_path.stat().st_size // 1024
        print(f"Output: {out_path} ({size_kb} KB)")
        return out_path
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("Usage: generate_course_audio.py <chapter.md> <out_dir>")
        return 2

    chapter = Path(argv[1])
    out_dir = Path(argv[2])
    if not chapter.exists():
        fail(f"{chapter} not found")
    if not chapter.is_file():
        fail(f"{chapter} is not a file")

    generate_audio(chapter, out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
