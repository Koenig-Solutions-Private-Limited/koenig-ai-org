#!/usr/bin/env python3
"""Generate slides.pptx for course chapters using python-pptx.

Brand: #18181b dark bg / #ffffff white text / #a1a1aa zinc-400 accent
Format: title + objectives + concepts + content sections (≥3/1000 words) + CTA
"""
import sys
sys.path.insert(0, '/tmp/pptx_deps')

import re
from pathlib import Path
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

DARK   = RGBColor(0x18, 0x18, 0x1B)
WHITE  = RGBColor(0xFF, 0xFF, 0xFF)
ACCENT = RGBColor(0xA1, 0xA1, 0xAA)  # zinc-400
GREEN  = RGBColor(0x22, 0xC5, 0x5E)  # emerald-500

ATTRIBUTION = "academy.kspl.tech | Koenig AI Academy"

SKIP_SECTIONS = {
    "references cited", "references", "further reading",
    "related content", "notes", "acknowledgements",
    "what's next", "hands-on exercise",
}

# JSX/MDX component tags to skip entirely (content belongs in speaker notes)
JSX_TAGS = {'KnowledgeCheck', 'Callout', 'Quiz', 'Warning', 'Info', 'Note', 'Tip'}


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


def clean_line(line: str) -> str:
    line = re.sub(r'\*\*(.+?)\*\*', r'\1', line)
    line = re.sub(r'\*(.+?)\*', r'\1', line)
    line = re.sub(r'`([^`]+)`', r'\1', line)
    line = re.sub(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]', r'\1', line)  # wikilinks
    line = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', line)
    line = re.sub(r'<[^>]+>', '', line)
    line = re.sub(r'^\s*[-*+]\s+', '', line)
    line = re.sub(r'^\s*\d+\.\s+', '', line)
    line = re.sub(r'\[\^\d+\]', '', line)  # footnote refs
    line = line.strip()
    return line


def _get_paragraphs(lines: list[str]) -> list[str]:
    """Group content lines into prose paragraphs (skip headings/tables/images)."""
    paragraphs = []
    current: list[str] = []
    for raw in lines:
        stripped = raw.strip()
        if not stripped:
            if current:
                paragraphs.append(' '.join(current))
                current = []
        elif not raw.startswith('#') and not stripped.startswith('|') and not stripped.startswith('!['):
            cleaned = clean_line(stripped)
            if cleaned:
                current.append(cleaned)
    if current:
        paragraphs.append(' '.join(current))
    return paragraphs


MAX_BULLET_CHARS = 200


def _truncate_bullet(text: str) -> str:
    """Truncate at word boundary to MAX_BULLET_CHARS, appending ellipsis."""
    if len(text) <= MAX_BULLET_CHARS:
        return text
    snippet = text[:MAX_BULLET_CHARS - 1]
    last_sp = snippet.rfind(' ')
    return (snippet[:last_sp] + '…') if last_sp > MAX_BULLET_CHARS // 2 else snippet + '…'


def _extract_bullets(lines: list[str]) -> list[str]:
    """Extract 3-5 slide bullets, preferring headings/lists over prose sentences."""
    # For sections that are structured as multiple named subsections (≥3 H3 headings,
    # e.g. "The four pillars"), return only the H3 titles so every subsection appears
    # on the slide instead of being crowded out by sub-bullets from the first one.
    h3_heads = []
    for raw in lines:
        if raw.startswith('### '):
            sub = clean_line(raw[4:].strip())
            if sub and len(sub) > 3:
                h3_heads.append(sub)
    if len(h3_heads) >= 3:
        return h3_heads[:5]

    structured: list[str] = []
    for raw in lines:
        if raw.startswith('### '):
            sub = clean_line(raw[4:].strip())
            if sub and len(sub) > 3:
                structured.append(_truncate_bullet(sub))
        elif re.match(r'^\s*[-*+]\s+', raw) or re.match(r'^\s*\d+\.\s+', raw):
            cleaned = clean_line(raw)
            if cleaned and len(cleaned) > 5:
                structured.append(_truncate_bullet(cleaned))
        if len(structured) >= 5:
            break

    if len(structured) >= 3:
        return structured[:5]

    # Fallback: extract sentences from prose paragraphs
    bullets = list(structured)
    for para in _get_paragraphs(lines):
        for sent in re.split(r'(?<=\.)\s+', para):
            if len(bullets) >= 5:
                break
            sent = sent.strip()
            # Skip very short fragments and intro-style fragments ending with ':'
            if len(sent) <= 20 or sent.endswith(':'):
                continue
            sent = _truncate_bullet(sent)
            if sent not in bullets:
                bullets.append(sent)

    return bullets[:5]


def extract_sections(body: str):
    """Return list of (h2_title, [bullet_str, ...]) skipping boilerplate sections."""
    sections = []
    current_title: str | None = None
    raw_lines: list[str] = []
    in_code_block = False
    in_jsx_block = False
    jsx_tag: str | None = None

    def flush() -> None:
        if current_title is None:
            return
        if current_title.lower() not in SKIP_SECTIONS:
            bullets = _extract_bullets(raw_lines)
            if bullets:
                sections.append((current_title, bullets))

    for raw_line in body.splitlines():
        stripped = raw_line.strip()

        # JSX/MDX component blocks — skip entirely (KnowledgeCheck, Callout, etc.)
        if not in_jsx_block:
            m = re.match(r'^<(\w+)', stripped)
            if m and m.group(1) in JSX_TAGS:
                in_jsx_block = True
                jsx_tag = m.group(1)
                if stripped.endswith('/>'):  # self-closing on same line
                    in_jsx_block = False
                continue
        else:
            closing_tag = rf'^</{re.escape(jsx_tag)}\b' if jsx_tag else r'^</\w+'
            if stripped == '/>' or stripped.endswith('/>') or re.match(closing_tag, stripped):
                in_jsx_block = False
            continue

        if raw_line.startswith('```'):
            in_code_block = not in_code_block
            continue
        if in_code_block:
            continue

        if raw_line.startswith('## '):
            flush()
            current_title = raw_line[3:].strip()
            raw_lines = []
        elif current_title is not None:
            raw_lines.append(raw_line)

    flush()
    return sections


def _add_text(slide, text, left, top, width, height,
              size, bold=False, color=WHITE, align=PP_ALIGN.LEFT):
    tb = slide.shapes.add_textbox(left, top, width, height)
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color


def _add_bullets(slide, items, left, top, width, height, size=16):
    tb = slide.shapes.add_textbox(left, top, width, height)
    tf = tb.text_frame
    tf.word_wrap = True
    first = True
    for item in items:
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        run = p.add_run()
        run.text = f"  • {item}"
        run.font.size = Pt(size)
        run.font.color.rgb = WHITE


def _set_bg(slide):
    bg = slide.background
    fill = bg.fill
    fill.solid()
    fill.fore_color.rgb = DARK


def _add_footer(slide):
    _add_text(slide, ATTRIBUTION,
              Inches(0.8), Inches(6.85), Inches(11.7), Inches(0.4),
              size=10, color=ACCENT)


def _add_rule(slide, top=Inches(1.55)):
    rect = slide.shapes.add_shape(
        1, Inches(0.8), top, Inches(11.7), Inches(0.04)
    )
    rect.fill.solid()
    rect.fill.fore_color.rgb = ACCENT
    rect.line.fill.background()


def make_title_slide(prs, title: str, chapter_num: int, course_slug: str, date_str: str):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(slide)
    badge = f"Chapter {chapter_num}"
    _add_text(slide, badge,
              Inches(1.0), Inches(1.4), Inches(11.3), Inches(0.5),
              size=14, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_text(slide, title,
              Inches(1.0), Inches(1.9), Inches(11.3), Inches(2.8),
              size=32, bold=True, align=PP_ALIGN.CENTER)
    _add_text(slide, ATTRIBUTION,
              Inches(1.0), Inches(4.9), Inches(11.3), Inches(0.5),
              size=14, color=ACCENT, align=PP_ALIGN.CENTER)
    if date_str:
        _add_text(slide, str(date_str),
                  Inches(1.0), Inches(5.5), Inches(11.3), Inches(0.4),
                  size=13, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_footer(slide)


def make_objectives_slide(prs, objectives: list[str]):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(slide)
    _add_text(slide, "What You'll Learn",
              Inches(0.8), Inches(0.45), Inches(11.7), Inches(1.0),
              size=28, bold=True)
    _add_rule(slide)
    top = Inches(1.75)
    for obj in objectives[:5]:
        cleaned = obj.strip().rstrip('"').lstrip('"')
        _add_text(slide, f"  • {cleaned}",
                  Inches(0.8), top, Inches(11.7), Inches(1.0),
                  size=15, color=WHITE)
        top += Inches(1.0)
    _add_footer(slide)


def make_concepts_slide(prs, concepts: list):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(slide)
    _add_text(slide, "Key Concepts",
              Inches(0.8), Inches(0.45), Inches(11.7), Inches(1.0),
              size=28, bold=True)
    _add_rule(slide)
    items = [str(c) for c in concepts[:8]]
    col1 = items[:4]
    col2 = items[4:]
    top = Inches(1.8)
    for item in col1:
        _add_text(slide, f"  • {item}",
                  Inches(0.8), top, Inches(5.5), Inches(0.8),
                  size=16, color=WHITE)
        top += Inches(0.9)
    top = Inches(1.8)
    for item in col2:
        _add_text(slide, f"  • {item}",
                  Inches(6.6), top, Inches(5.9), Inches(0.8),
                  size=16, color=WHITE)
        top += Inches(0.9)
    _add_footer(slide)


def make_content_slide(prs, section_title: str, bullets: list[str]):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(slide)
    _add_text(slide, section_title,
              Inches(0.8), Inches(0.45), Inches(11.7), Inches(1.1),
              size=26, bold=True)
    _add_rule(slide)
    top = Inches(1.75)
    for bullet in bullets[:4]:
        _add_text(slide, f"  {bullet}",
                  Inches(0.8), top, Inches(11.7), Inches(1.05),
                  size=16, color=WHITE)
        top += Inches(1.15)
    _add_footer(slide)


def make_cta_slide(prs, chapter_num: int, next_chapter_num: int):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(slide)
    _add_text(slide, "Try it next",
              Inches(1.0), Inches(1.8), Inches(11.3), Inches(0.9),
              size=36, bold=True, align=PP_ALIGN.CENTER)
    _add_rule(slide, top=Inches(2.75))
    _add_text(slide, f"Complete the hands-on exercise in this chapter.",
              Inches(1.0), Inches(2.95), Inches(11.3), Inches(0.7),
              size=18, color=WHITE, align=PP_ALIGN.CENTER)
    _add_text(slide, f"Then continue to Chapter {next_chapter_num} →",
              Inches(1.0), Inches(3.75), Inches(11.3), Inches(0.7),
              size=20, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_text(slide, "academy.kspl.tech",
              Inches(1.0), Inches(5.0), Inches(11.3), Inches(0.7),
              size=22, bold=True, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_footer(slide)


def generate(draft_path: Path, out_dir: Path) -> Path:
    text = draft_path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)

    title = fm.get("title", "").strip('"') or draft_path.stem.replace("-", " ").title()
    chapter_num = int(fm.get("chapter_num", 1))
    date_str = str(fm.get("date", ""))
    objectives = fm.get("learning_objectives", []) or []
    concepts = fm.get("key_concepts", []) or []
    course_slug = fm.get("course_slug", "")

    sections = extract_sections(body)

    prs = Presentation()
    prs.slide_width  = Inches(13.333)
    prs.slide_height = Inches(7.5)

    make_title_slide(prs, title, chapter_num, course_slug, date_str)

    # Reserve content slots for objectives/concepts so total stays 5-7 slides
    max_content = 5
    if objectives:
        make_objectives_slide(prs, objectives)
        max_content -= 1
    if concepts:
        make_concepts_slide(prs, concepts)
        max_content -= 1

    content_count = 0
    for sec_title, bullets in sections:
        if content_count >= max_content:
            break
        make_content_slide(prs, sec_title, bullets)
        content_count += 1

    make_cta_slide(prs, chapter_num, chapter_num + 1)

    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"ch{chapter_num:02d}-slides.pptx"
    prs.save(str(out))
    return out


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: generate_course_slides.py <chapter.md> <out_dir>")
        sys.exit(1)

    ok = []
    fail = []
    args = sys.argv[1:]
    # Accept pairs: <chapter.md> <out_dir> or batch via --batch
    if len(args) % 2 != 0:
        print("Error: provide pairs of <chapter.md> <out_dir>")
        sys.exit(1)

    pairs = [(Path(args[i]), Path(args[i+1])) for i in range(0, len(args), 2)]
    for draft_path, out_dir in pairs:
        if not draft_path.exists():
            print(f"SKIP (not found): {draft_path}")
            fail.append(str(draft_path))
            continue
        try:
            out = generate(draft_path, out_dir)
            slide_count = len(Presentation(str(out)).slides)
            size_kb = out.stat().st_size // 1024
            print(f"OK  {out}  ({slide_count} slides, {size_kb} KB)")
            ok.append(str(out))
        except Exception as e:
            import traceback
            print(f"FAIL {draft_path}: {e}")
            traceback.print_exc()
            fail.append(str(draft_path))

    print(f"\nDone: {len(ok)} OK, {len(fail)} failed")
