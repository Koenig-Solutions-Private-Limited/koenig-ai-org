#!/usr/bin/env python3
"""Generate a PDF slide deck for a course chapter from its markdown file.

Fallback slide generator (tier-3) when NotebookLM is unavailable.
Extracts structured content from chapter markdown and renders it as a
branded PDF in landscape widescreen format.

Usage:
    python3 scripts/generate_course_slides.py <chapter.md> <output_dir>

Output: <output_dir>/slide-deck.pdf
"""
import sys
import re
import os
from pathlib import Path

# Self-install reportlab if needed
try:
    from reportlab.pdfgen import canvas as pdfcanvas
    from reportlab.lib.pagesizes import landscape
    from reportlab.lib.units import inch
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'reportlab', '--quiet', '--target', '/tmp/rl_deps'])
    sys.path.insert(0, '/tmp/rl_deps')
    from reportlab.pdfgen import canvas as pdfcanvas
    from reportlab.lib.pagesizes import landscape
    from reportlab.lib.units import inch
    from reportlab.lib import colors

# ---- Brand colors (Koenig AI Academy) ----
BG_COLOR    = colors.HexColor('#18181b')    # dark zinc
TEXT_COLOR  = colors.HexColor('#ffffff')    # white
ACCENT_COLOR = colors.HexColor('#a1a1aa')  # zinc-400
HIGHLIGHT   = colors.HexColor('#6366f1')   # indigo-500

# Slide dimensions: 16:9 widescreen (similar to Google Slides default)
SLIDE_W = 10 * inch
SLIDE_H = 5.625 * inch

ATTRIBUTION = "academy.kspl.tech | Koenig AI Academy"


def parse_frontmatter(text: str):
    if not text.startswith('---'):
        return {}, text
    end = text.find('---', 3)
    if end == -1:
        return {}, text
    fm_raw = text[3:end]
    body = text[end + 3:].strip()
    fm = {}
    for line in fm_raw.splitlines():
        if ':' in line:
            k, _, v = line.partition(':')
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if v and not v.startswith('-'):
                fm[k] = v
    return fm, body


def clean_text(t: str) -> str:
    t = re.sub(r'\[\[(?:[^\]|]+\|)?([^\]]+)\]\]', r'\1', t)
    t = re.sub(r'\*\*(.+?)\*\*', r'\1', t)
    t = re.sub(r'\*(.+?)\*', r'\1', t)
    t = re.sub(r'`([^`]+)`', r'\1', t)
    t = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', t)
    t = re.sub(r'<[^>]+>', '', t)
    t = re.sub(r'^\s*[-*+]\s+', '', t)
    t = re.sub(r'^\s*\d+\.\s+', '', t)
    return t.strip()


def extract_yaml_list(text: str, key: str) -> list:
    """Extract a YAML list field from frontmatter by key name."""
    items = []
    in_field = False
    for line in text.splitlines():
        stripped = line.strip()
        if re.match(rf'^{key}:', stripped):
            in_field = True
            continue
        if in_field:
            if stripped.startswith('- '):
                item = stripped[2:].strip().strip('"')
                if item and not item.startswith('{') and not item.startswith('url:'):
                    items.append(item)
            elif stripped and not stripped.startswith(' ') and not stripped.startswith('\t'):
                in_field = False
    return items[:5]


def extract_learning_objectives(text: str) -> list:
    return extract_yaml_list(text, 'learning_objectives')


def extract_key_sentences(paragraph: str, max_len: int = 110) -> list:
    """Extract up to 2 concise key sentences from a paragraph."""
    # Split on sentence boundaries
    sentences = re.split(r'(?<=[.!?])\s+', paragraph)
    results = []
    for s in sentences:
        s = s.strip()
        if len(s) < 20 or len(s) > max_len:
            continue
        # Skip sentences that are just links or code-heavy
        if s.count('`') > 3 or s.count('http') > 0:
            continue
        results.append(s)
        if len(results) >= 2:
            break
    return results


def extract_sections(body: str) -> list:
    """Return list of (heading, [bullet_str]) from ## headings."""
    sections = []
    current_title = None
    bullets = []
    in_code = False
    in_jsx = False  # inside <KnowledgeCheck or <Callout block

    SKIP = {'references', 'further reading', 'knowledge check', 'quiz',
            'summary', 'notes', 'acknowledgements', 'hands-on exercise'}

    for line in body.splitlines():
        if line.startswith('```'):
            in_code = not in_code
            continue
        if in_code:
            continue

        # Skip JSX components like <KnowledgeCheck ... /> and <Callout ...>
        stripped = line.strip()
        if re.match(r'<(KnowledgeCheck|Callout)', stripped):
            if '/>' not in stripped:  # multi-line tag
                in_jsx = True
            continue
        if in_jsx:
            if '/>' in stripped or re.match(r'</(KnowledgeCheck|Callout)', stripped):
                in_jsx = False
            continue

        if line.startswith('## '):
            if current_title and bullets:
                sections.append((current_title, bullets[:4]))
            current_title = line[3:].strip()
            bullets = []
        elif line.startswith('### ') and current_title:
            sub = clean_text(line[4:])
            if sub and len(sub) > 8 and sub.lower() not in SKIP:
                bullets.append(sub)
        elif current_title:
            if (stripped.startswith('>') or stripped.startswith('|')
                    or stripped.startswith('![') or stripped.startswith('---')
                    or stripped.startswith('#')):
                continue
            cleaned = clean_text(stripped)
            if cleaned and 15 < len(cleaned) <= 120:
                bullets.append(cleaned)
            elif cleaned and len(cleaned) > 120:
                # Extract key sentences from longer paragraphs
                sentences = extract_key_sentences(cleaned)
                bullets.extend(sentences)

    if current_title and bullets:
        sections.append((current_title, bullets[:4]))

    return [
        (t, b) for t, b in sections
        if t.lower() not in SKIP and b
    ][:5]


def draw_background(c, w, h):
    c.setFillColor(BG_COLOR)
    c.rect(0, 0, w, h, fill=1, stroke=0)


def draw_footer(c, w, h):
    c.setFillColor(ACCENT_COLOR)
    c.setFont('Helvetica', 8)
    c.drawString(0.4 * inch, 0.25 * inch, ATTRIBUTION)


def draw_rule(c, y, w):
    c.setStrokeColor(ACCENT_COLOR)
    c.setLineWidth(0.5)
    c.line(0.4 * inch, y, w - 0.4 * inch, y)


def slide_title(c, w, h, title: str, subtitle: str = ''):
    draw_background(c, w, h)
    draw_footer(c, w, h)

    # Highlight bar at top
    c.setFillColor(HIGHLIGHT)
    c.rect(0, h - 0.08 * inch, w, 0.08 * inch, fill=1, stroke=0)

    # Chapter title
    c.setFillColor(TEXT_COLOR)
    c.setFont('Helvetica-Bold', 26)
    # Word-wrap the title
    words = title.split()
    lines = []
    current = ''
    for word in words:
        test = (current + ' ' + word).strip()
        if c.stringWidth(test, 'Helvetica-Bold', 26) < (w - 1.2 * inch):
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    y_start = h / 2 + len(lines) * 0.2 * inch
    for i, line in enumerate(lines):
        c.drawCentredString(w / 2, y_start - i * 0.45 * inch, line)

    if subtitle:
        c.setFillColor(ACCENT_COLOR)
        c.setFont('Helvetica', 12)
        c.drawCentredString(w / 2, y_start - len(lines) * 0.45 * inch - 0.3 * inch, subtitle)

    # Attribution line
    c.setFillColor(ACCENT_COLOR)
    c.setFont('Helvetica', 10)
    c.drawCentredString(w / 2, 0.5 * inch, ATTRIBUTION)


def slide_objectives(c, w, h, objectives: list):
    draw_background(c, w, h)
    draw_footer(c, w, h)

    c.setFillColor(TEXT_COLOR)
    c.setFont('Helvetica-Bold', 20)
    c.drawString(0.5 * inch, h - 0.7 * inch, 'Learning Objectives')
    draw_rule(c, h - 0.85 * inch, w)

    c.setFont('Helvetica', 13)
    y = h - 1.2 * inch
    for obj in objectives[:5]:
        # Wrap objective text
        words = obj.split()
        lines = []
        cur = '•  '
        for word in words:
            test = cur + word + ' '
            if c.stringWidth(test, 'Helvetica', 13) < (w - 1.0 * inch):
                cur = test
            else:
                lines.append(cur.rstrip())
                cur = '   ' + word + ' '
        lines.append(cur.rstrip())

        for i, line in enumerate(lines):
            if y < 0.6 * inch:
                break
            c.setFillColor(TEXT_COLOR if i == 0 else ACCENT_COLOR)
            c.drawString(0.5 * inch, y, line)
            y -= 0.28 * inch
        y -= 0.12 * inch


def slide_content(c, w, h, section_title: str, bullets: list):
    draw_background(c, w, h)
    draw_footer(c, w, h)

    # Section title
    c.setFillColor(TEXT_COLOR)
    c.setFont('Helvetica-Bold', 22)
    c.drawString(0.5 * inch, h - 0.7 * inch, section_title)
    draw_rule(c, h - 0.85 * inch, w)

    c.setFont('Helvetica', 14)
    y = h - 1.25 * inch
    for bullet in bullets[:4]:
        # Bullet symbol
        c.setFillColor(HIGHLIGHT)
        c.setFont('Helvetica-Bold', 16)
        c.drawString(0.5 * inch, y, '▸')

        # Bullet text with wrapping
        c.setFillColor(TEXT_COLOR)
        c.setFont('Helvetica', 13)
        words = bullet.split()
        lines = []
        cur = ''
        for word in words:
            test = (cur + ' ' + word).strip()
            if c.stringWidth(test, 'Helvetica', 13) < (w - 1.2 * inch):
                cur = test
            else:
                if cur:
                    lines.append(cur)
                cur = word
        if cur:
            lines.append(cur)

        for i, line in enumerate(lines):
            if y < 0.6 * inch:
                break
            c.drawString(0.85 * inch, y, line)
            y -= 0.27 * inch
        y -= 0.18 * inch


def slide_cta(c, w, h, course_title: str):
    draw_background(c, w, h)

    # Gradient-like decorative block
    c.setFillColor(HIGHLIGHT)
    c.rect(0, 0, 0.06 * inch, h, fill=1, stroke=0)

    c.setFillColor(TEXT_COLOR)
    c.setFont('Helvetica-Bold', 28)
    c.drawCentredString(w / 2, h / 2 + 0.5 * inch, 'Continue Learning')

    c.setFillColor(ACCENT_COLOR)
    c.setFont('Helvetica', 16)
    c.drawCentredString(w / 2, h / 2, 'Full course available at:')

    c.setFillColor(HIGHLIGHT)
    c.setFont('Helvetica-Bold', 20)
    c.drawCentredString(w / 2, h / 2 - 0.45 * inch, 'academy.kspl.tech')

    c.setFillColor(ACCENT_COLOR)
    c.setFont('Helvetica', 10)
    c.drawCentredString(w / 2, 0.3 * inch, ATTRIBUTION)


def generate(chapter_md: Path, out_dir: Path) -> Path:
    text = chapter_md.read_text(encoding='utf-8')
    fm, body = parse_frontmatter(text)

    title = fm.get('title', chapter_md.stem.replace('-', ' ').title())
    chapter_num = fm.get('chapter_num', '')
    subtitle = f'Chapter {chapter_num}' if chapter_num else ''

    objectives = extract_learning_objectives(text)
    sections = extract_sections(body)

    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / 'slide-deck.pdf'

    w, h = SLIDE_W, SLIDE_H
    c = pdfcanvas.Canvas(str(out_path), pagesize=(w, h))
    c.setTitle(title)
    c.setAuthor('Koenig AI Academy')
    c.setSubject(f'Course chapter slide deck: {title}')

    # Slide 1: Title
    slide_title(c, w, h, title, subtitle)
    c.showPage()

    # Slide 2: Learning Objectives (if present)
    if objectives:
        slide_objectives(c, w, h, objectives)
        c.showPage()

    # Content slides (up to 5 sections)
    for sec_title, bullets in sections[:5]:
        slide_content(c, w, h, sec_title, bullets)
        c.showPage()

    # CTA slide
    slide_cta(c, w, h, title)
    c.showPage()

    c.save()
    return out_path


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: generate_course_slides.py <chapter.md> <output_dir>')
        sys.exit(1)

    chapter = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])

    if not chapter.exists():
        print(f'ERROR: {chapter} not found')
        sys.exit(1)

    out = generate(chapter, out_dir)
    size_kb = out.stat().st_size // 1024
    from reportlab.pdfgen import canvas as _c
    print(f'OK  {out}  ({size_kb} KB)')
