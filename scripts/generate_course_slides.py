#!/usr/bin/env python3
"""Generate course chapter slides.pptx from chapter markdown files.

G0-compliant:
- Brand: #18181b dark bg / #ffffff white text / #a1a1aa zinc-400 accent / #3b82f6 blue
- Attribution footer "academy.kspl.tech | Koenig AI Academy" on every slide
- CTA slide ("Try it next →") is always LAST
- 3-5 bullets per body slide
"""
import sys
import re
from pathlib import Path

sys.path.insert(0, '/tmp/pptx_deps')

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
ACCENT = RGBColor(0xA1, 0xA1, 0xAA)
BLUE   = RGBColor(0x3B, 0x82, 0xF6)
YELLOW = RGBColor(0xFA, 0xCC, 0x15)

ATTRIBUTION = "academy.kspl.tech | Koenig AI Academy"

SKIP_H2 = {
    "references", "further reading", "related content",
    "what's next", "knowledge check", "knowledge checks",
    "notes", "acknowledgements",
}


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
                fm[k.strip()] = v.strip().strip('"')
    return fm, body


def clean_line(line: str) -> str:
    line = re.sub(r'\*\*(.+?)\*\*', r'\1', line)
    line = re.sub(r'\*(.+?)\*', r'\1', line)
    line = re.sub(r'`([^`]+)`', r'\1', line)
    line = re.sub(r'\[\[\d+\]\]\([^\)]+\)', '', line)
    line = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', line)
    line = re.sub(r'\[\[([^\]|]+)\|([^\]]+)\]\]', r'\2', line)
    line = re.sub(r'\[\[([^\]]+)\]\]', '', line)
    line = re.sub(r'<[^>]+>', '', line)
    line = re.sub(r'^\s*[-*+]\s+', '', line)
    line = re.sub(r'^\s*\d+\.\s+', '', line)
    line = re.sub(r'\s{2,}', ' ', line)
    line = re.sub(r'\[\d+\]', '', line)  # strip reference footnotes like [1]
    return line.strip()


def _keep(s: str) -> bool:
    return (bool(s) and len(s) > 20
            and not s.startswith("|")
            and not s.startswith("```")
            and not s.startswith("![")
            and not s.startswith("<Run")
            and not s.startswith("<Knowledge")
            and not s.startswith("<Callout"))


def extract_sections(body: str) -> list[tuple[str, list[str]]]:
    """Return (slide_title, [bullet, ...]) pairs from H2 sections."""
    sections = []
    current_h2 = None
    current_h3 = None
    h3_titles = []
    preamble_bullets = []
    current_bullets = []

    def _flush_h2():
        nonlocal current_h2, current_h3, h3_titles, preamble_bullets, current_bullets
        if current_h2 is None:
            return
        if current_h2.lower() in SKIP_H2:
            current_h2 = None
            h3_titles = []
            preamble_bullets = []
            current_bullets = []
            current_h3 = None
            return

        # Build bullet list from preamble + H3 titles
        bullets = []
        bullets.extend(preamble_bullets[:3])
        for t in h3_titles[:5]:
            short = re.sub(r'^\d+\.\s+', '', t).split(':')[0].strip()
            if len(short) > 10:
                bullets.append(short[:100])

        # Fall back to current_bullets if both above are empty
        if not bullets:
            bullets = current_bullets[:5]

        # Ensure at least 3 bullets by repeating/padding when needed
        if 1 <= len(bullets) < 3:
            # Pad with elaboration bullets from h3 titles or current_bullets
            extra = [b for b in current_bullets if b not in bullets]
            bullets += extra
            bullets = bullets[:5]
        if bullets:
            sections.append((current_h2, bullets[:5]))

        current_h2 = None
        h3_titles = []
        preamble_bullets = []
        current_bullets = []
        current_h3 = None

    for raw in body.splitlines():
        if raw.startswith("## "):
            _flush_h2()
            current_h2 = raw[3:].strip()
        elif raw.startswith("### ") and current_h2 is not None:
            current_h3 = raw[4:].strip()
            h3_titles.append(current_h3)
        elif not raw.startswith("#") and current_h2 is not None:
            c = clean_line(raw)
            if _keep(c):
                if current_h3 is None:
                    preamble_bullets.append(c[:120])
                else:
                    current_bullets.append(c[:120])
    _flush_h2()

    return sections


def _set_bg(slide):
    fill = slide.background.fill
    fill.solid()
    fill.fore_color.rgb = DARK


def _add_text(slide, text, left, top, width, height,
              size, bold=False, color=WHITE,
              align=PP_ALIGN.LEFT, italic=False):
    tb = slide.shapes.add_textbox(left, top, width, height)
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color


def _add_rule(slide, top=Inches(1.55)):
    rect = slide.shapes.add_shape(1, Inches(0.8), top, Inches(11.7), Inches(0.04))
    rect.fill.solid()
    rect.fill.fore_color.rgb = ACCENT
    rect.line.fill.background()


def _add_footer(slide):
    _add_text(slide, ATTRIBUTION,
              Inches(0.8), Inches(6.9), Inches(11.7), Inches(0.4),
              size=10, color=ACCENT)


def make_title_slide(prs, course_title: str, chapter_num: int, chapter_title: str):
    s = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(s)
    _add_text(s, course_title.upper(),
              Inches(0.8), Inches(1.1), Inches(11.7), Inches(0.6),
              size=13, bold=True, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_text(s, f"Chapter {chapter_num}",
              Inches(0.8), Inches(1.85), Inches(11.7), Inches(0.7),
              size=20, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_text(s, chapter_title,
              Inches(0.8), Inches(2.7), Inches(11.7), Inches(2.5),
              size=30, bold=True, align=PP_ALIGN.CENTER)
    _add_text(s, ATTRIBUTION,
              Inches(0.8), Inches(6.85), Inches(11.7), Inches(0.4),
              size=10, color=ACCENT, align=PP_ALIGN.CENTER)


def make_objectives_slide(prs, objectives: list[str]):
    s = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(s)
    _add_text(s, "What you'll be able to do",
              Inches(0.8), Inches(0.35), Inches(11.7), Inches(1.1),
              size=28, bold=True)
    _add_rule(s)
    top = Inches(1.75)
    for obj in objectives[:5]:
        _add_text(s, f"▸  {obj[:110]}",
                  Inches(0.8), top, Inches(11.7), Inches(1.0),
                  size=16, color=WHITE)
        top += Inches(0.95)
    _add_footer(s)


def make_content_slide(prs, title: str, bullets: list[str]):
    s = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(s)
    _add_text(s, title,
              Inches(0.8), Inches(0.35), Inches(11.7), Inches(1.1),
              size=26, bold=True)
    _add_rule(s)
    top = Inches(1.75)
    for b in bullets[:5]:
        _add_text(s, f"▸  {b}",
                  Inches(0.8), top, Inches(11.7), Inches(1.0),
                  size=16, color=WHITE)
        top += Inches(0.95)
    _add_footer(s)


def make_cta_slide(prs, next_chapter_num: int | None, next_chapter_title: str | None):
    s = prs.slides.add_slide(prs.slide_layouts[6])
    _set_bg(s)
    _add_text(s, "Try it next →",
              Inches(0.8), Inches(1.5), Inches(11.7), Inches(1.0),
              size=38, bold=True, align=PP_ALIGN.CENTER)
    if next_chapter_num and next_chapter_title:
        _add_text(s, f"Chapter {next_chapter_num}: {next_chapter_title}",
                  Inches(0.8), Inches(2.7), Inches(11.7), Inches(0.8),
                  size=22, bold=True, color=BLUE, align=PP_ALIGN.CENTER)
    _add_text(s, "Continue learning at:",
              Inches(0.8), Inches(4.0), Inches(11.7), Inches(0.6),
              size=16, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_text(s, "academy.kspl.tech",
              Inches(0.8), Inches(4.7), Inches(11.7), Inches(0.8),
              size=28, bold=True, color=ACCENT, align=PP_ALIGN.CENTER)
    _add_text(s, ATTRIBUTION,
              Inches(0.8), Inches(6.85), Inches(11.7), Inches(0.4),
              size=10, color=ACCENT, align=PP_ALIGN.CENTER)


def generate(chapter_md: Path, next_chapter_num=None, next_chapter_title=None,
             out_path: Path | None = None) -> Path:
    text = chapter_md.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)

    chapter_num = fm.get("chapter_num", 1)
    chapter_title = fm.get("title", chapter_md.stem.replace("-", " ").title())
    course_slug = fm.get("course_slug", "")
    course_display = course_slug.replace("-", " ").title()

    objectives = fm.get("learning_objectives") or []
    if isinstance(objectives, list):
        objectives = [str(o) for o in objectives]
    else:
        objectives = []

    sections = extract_sections(body)

    prs = Presentation()
    prs.slide_width  = Inches(13.333)
    prs.slide_height = Inches(7.5)

    make_title_slide(prs, course_display, chapter_num, chapter_title)

    if objectives:
        make_objectives_slide(prs, objectives)

    content_count = 0
    for title, bullets in sections:
        if content_count >= 8:
            break
        # Ensure minimum 3 bullets
        if len(bullets) < 3:
            continue
        make_content_slide(prs, title, bullets)
        content_count += 1

    # CTA is always last
    make_cta_slide(prs, next_chapter_num, next_chapter_title)

    if out_path is None:
        ch_num = str(chapter_num).zfill(2)
        out_path = chapter_md.parent / f"ch{ch_num}-slides.pptx"

    prs.save(str(out_path))
    return out_path


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: generate_course_slides.py <chapter.md> [--out slides.pptx]")
        sys.exit(1)

    args = sys.argv[1:]
    out_override = None
    if "--out" in args:
        idx = args.index("--out")
        out_override = Path(args[idx + 1])
        args = args[:idx] + args[idx + 2:]

    for arg in args:
        p = Path(arg)
        if not p.exists():
            print(f"SKIP (not found): {p}")
            continue
        out = generate(p, out_path=out_override)
        count = len(Presentation(str(out)).slides)
        print(f"OK  {out}  ({count} slides)")
