#!/usr/bin/env python3
"""Generate audio.mp3 for course chapters using OpenAI TTS.

Extracts key content from the chapter (title intro + objectives + key facts +
section lead paragraphs) to produce an 8-12 min narration audio track.

Usage: generate_course_audio.py <chapter.md> <out_dir>
"""
import os
import sys
sys.path.insert(0, '/tmp/openai_deps')  # fallback install path
import re
import tempfile
from pathlib import Path

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

try:
    from openai import OpenAI
except ImportError:
    print("openai package not found. Run: pip3 install openai --target /tmp/openai_deps")
    sys.exit(1)

HAS_FFMPEG = os.system("which ffmpeg > /dev/null 2>&1") == 0


MAX_NARRATION_WORDS = 1400  # ~9-10 min at 150 wpm
VOICE_NARRATOR = "alloy"    # primary narrator


def parse_frontmatter(text: str):
    if not text.startswith("---"):
        return {}, text
    end = text.find("---", 3)
    if end == -1:
        return {}, text
    fm_raw = text[3:end]
    body = text[end + 3:].strip()
    if HAS_YAML:
        try:
            fm = yaml.safe_load(fm_raw) or {}
        except Exception:
            fm = {}
    else:
        fm = {}
        for line in fm_raw.splitlines():
            if ":" in line:
                k, _, v = line.partition(":")
                fm[k.strip()] = v.strip()
    return fm, body


def clean_for_speech(text: str) -> str:
    """Strip markdown syntax for clean TTS narration."""
    text = re.sub(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]', r'\1', text)
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    text = re.sub(r'\*(.+?)\*', r'\1', text)
    text = re.sub(r'`([^`]+)`', r'\1', text)
    text = re.sub(r'^#+\s+', '', text, flags=re.MULTILINE)
    text = re.sub(r'\[\^\d+\]', '', text)
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'^\s*[-*+]\s+', '', text, flags=re.MULTILINE)
    text = re.sub(r'^\s*\d+\.\s+', '', text, flags=re.MULTILINE)
    text = re.sub(r'\|[^\n]+\|', '', text)  # table rows
    text = re.sub(r'```[\s\S]*?```', '', text)  # code blocks
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()


def extract_narration(body: str, objectives: list, title: str) -> str:
    """Build a narration script from the chapter content."""
    parts = []
    word_count = 0

    def add(segment: str):
        nonlocal word_count
        cleaned = clean_for_speech(segment).strip()
        if not cleaned:
            return
        words = len(cleaned.split())
        if word_count + words > MAX_NARRATION_WORDS:
            # Take only what fits
            remaining = MAX_NARRATION_WORDS - word_count
            if remaining > 20:
                trimmed = " ".join(cleaned.split()[:remaining])
                parts.append(trimmed)
                word_count += remaining
            return
        parts.append(cleaned)
        word_count += words

    # Intro
    add(f"Welcome to Chapter: {title}.")

    if objectives:
        obj_text = "In this chapter, you will: " + "; ".join(
            str(o).strip().rstrip('"').lstrip('"') for o in objectives[:4]
        ) + "."
        add(obj_text)

    # Parse sections
    sections = []
    current_title = None
    paras: list[str] = []
    in_code = False

    for raw in body.splitlines():
        if raw.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if raw.startswith("## "):
            if current_title is not None:
                sections.append((current_title, "\n".join(paras)))
            current_title = raw[3:].strip()
            paras = []
        elif raw.startswith("### "):
            paras.append(raw[4:].strip())
        elif current_title is not None and raw.strip():
            paras.append(raw.strip())

    if current_title is not None:
        sections.append((current_title, "\n".join(paras)))

    skip = {"references cited", "references", "further reading", "acknowledgements"}

    for sec_title, sec_body in sections:
        if sec_title.lower() in skip:
            continue
        if word_count >= MAX_NARRATION_WORDS:
            break
        add(f"\n{sec_title}.\n")
        # Add first two substantive paragraphs of this section
        sec_paras = [p.strip() for p in sec_body.split("\n\n") if p.strip() and len(p.strip()) > 40]
        for para in sec_paras[:2]:
            if word_count >= MAX_NARRATION_WORDS:
                break
            add(para)

    # Closing
    add("\nThat concludes this chapter. Complete the hands-on exercise, then move on to the next chapter at academy.kspl.tech.")

    return "\n\n".join(parts)


def generate(draft_path: Path, out_dir: Path) -> Path:
    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

    text = draft_path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)

    title = fm.get("title", "").strip('"') or draft_path.stem.replace("-", " ").title()
    objectives = fm.get("learning_objectives", []) or []

    narration = extract_narration(body, objectives, title)
    word_count = len(narration.split())
    print(f"  Narration: {word_count} words (~{word_count // 150} min)")

    out_dir.mkdir(parents=True, exist_ok=True)

    # OpenAI TTS max input is 4096 chars per request; split if needed
    MAX_CHARS = 4000
    chunks = []
    current = ""
    for sentence in re.split(r'(?<=[.!?])\s+', narration):
        if len(current) + len(sentence) + 1 > MAX_CHARS:
            if current:
                chunks.append(current.strip())
            current = sentence
        else:
            current = (current + " " + sentence).strip()
    if current:
        chunks.append(current.strip())

    print(f"  Chunks: {len(chunks)}")

    tmp_files = []
    for i, chunk in enumerate(chunks):
        with client.audio.speech.with_streaming_response.create(
            model="tts-1",
            voice=VOICE_NARRATOR,
            input=chunk,
            response_format="mp3",
        ) as response:
            tmp = tempfile.NamedTemporaryFile(suffix=f"_chunk{i}.mp3", delete=False)
            for data in response.iter_bytes(chunk_size=4096):
                tmp.write(data)
            tmp.close()
            tmp_files.append(tmp.name)
        print(f"  Chunk {i+1}/{len(chunks)} done")

    # Concatenate chunks
    normalized_out = out_dir / "audio.mp3"

    if len(tmp_files) == 1:
        import shutil
        shutil.copy(tmp_files[0], str(normalized_out))
    elif HAS_FFMPEG:
        raw_out = out_dir / "audio-raw.mp3"
        concat_list = tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False)
        for f in tmp_files:
            concat_list.write(f"file '{f}'\n")
        concat_list.close()
        os.system(f"ffmpeg -y -f concat -safe 0 -i '{concat_list.name}' -c copy '{raw_out}' 2>/dev/null")
        os.unlink(concat_list.name)
        # Normalize loudness
        ret = os.system(
            f"ffmpeg -y -i '{raw_out}' "
            f"-af loudnorm=I=-16:LRA=11:tp=-1.5 "
            f"-ar 44100 -ac 2 -b:a 128k "
            f"'{normalized_out}' 2>/dev/null"
        )
        if ret == 0 and normalized_out.exists():
            raw_out.unlink(missing_ok=True)
        else:
            import shutil
            shutil.copy(str(raw_out), str(normalized_out))
            raw_out.unlink(missing_ok=True)
    else:
        # No ffmpeg: binary-concatenate MP3 chunks (good enough for TTS outputs)
        print("  ffmpeg not found — binary-concatenating chunks (no loudness normalization)")
        with open(str(normalized_out), 'wb') as fout:
            for chunk_file in tmp_files:
                with open(chunk_file, 'rb') as fin:
                    fout.write(fin.read())

    # Clean up temp files
    for f in tmp_files:
        try:
            os.unlink(f)
        except Exception:
            pass

    # Get duration (best-effort via ffprobe or mutagen)
    duration_sec = 0
    if HAS_FFMPEG:
        result = os.popen(
            f"ffprobe -v error -show_entries format=duration "
            f"-of default=noprint_wrappers=1:nokey=1 '{normalized_out}' 2>/dev/null"
        ).read().strip()
        if result:
            try:
                duration_sec = int(float(result))
            except ValueError:
                pass
    if duration_sec == 0:
        # Estimate from file size: tts-1 output ~128kbps
        size_bytes = normalized_out.stat().st_size
        duration_sec = int(size_bytes * 8 / 128000)

    size_kb = normalized_out.stat().st_size // 1024
    mins = duration_sec // 60
    secs = duration_sec % 60
    print(f"  Output: {normalized_out.name} — {mins}:{secs:02d}, {size_kb} KB")
    return normalized_out, duration_sec


if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv[1:]) % 2 != 0:
        print("Usage: generate_course_audio.py <chapter.md> <out_dir> [<chapter.md> <out_dir> ...]")
        sys.exit(1)

    args = sys.argv[1:]
    pairs = [(Path(args[i]), Path(args[i+1])) for i in range(0, len(args), 2)]

    ok = []
    fail = []
    for draft_path, out_dir in pairs:
        print(f"\n→ {draft_path.name}")
        if not draft_path.exists():
            print(f"  SKIP (not found)")
            fail.append(str(draft_path))
            continue
        try:
            out, dur = generate(draft_path, out_dir)
            ok.append((str(draft_path), dur))
        except Exception as e:
            import traceback
            print(f"  FAIL: {e}")
            traceback.print_exc()
            fail.append(str(draft_path))

    print(f"\nDone: {len(ok)} OK, {len(fail)} failed")
