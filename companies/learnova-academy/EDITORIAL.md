# Editorial Standard — Single Source of Truth

**Effective 2026-07-09. Approved by Vardaan (board). Supersedes ALL word-count and length rules in any agent's AGENTS.md, SOUL.md, or skill file. If another file contradicts this one, THIS file wins — and file a ticket to fix the other file.**

## Word counts (prose words only — strip frontmatter, code fences, and component tags before counting)

| Content type | Target | Hard floor | Hard ceiling |
|---|---|---|---|
| Blog (standard) | 1,200–2,000 | 1,000 | 2,400 |
| Blog with `news-flash: true` frontmatter | 500–900 | 400 | 1,200 |
| Course chapter (legacy tracks) | 1,200–2,500 | 1,000 | 3,000 |
| Course chapter (`course_track: career`) | per career-track rubric (max 1,200 prose words) | — | 1,200 |
| Glossary entry | 150–400 | 100 | 600 |

Reviewer rule: BLOCK only below the hard floor or above the hard ceiling. Inside floor–ceiling but outside target: PASS with a note, do not block.

## Why 1,200–2,000 for blogs
Long enough for topical depth and internal linking; short enough to stay answer-first, citation-dense, and cheap to produce. Depth of insight beats length. 1,500 words of repetition is worse than 1,200 words of dense, hard-to-find-elsewhere analysis.

## Everything else (unchanged, restated for one-stop reference)
- Answer-first: first 60 words literally answer the primary query.
- ≥3 inline source citations per blog; every stat needs a source with a `retrieved` date. **No uncited precise-sounding numbers** — a specific figure without a citation is a BLOCK.
- ≥2 RunPromptCell or KnowledgeCheck blocks per 1,000 words (blogs and chapters).
- Internal links to ≥2 related Academy pages.
- FAQ: ≥3 entries, each answer ≥40 words with ≥1 citation.
- No AI-tells ("In conclusion", "Furthermore", "Let's dive in", "delve", "moreover", "in today's fast-paced world").
- **Author slug (G0 BLOCK if missing or invalid):** every blog must have `author: <real-slug>` in frontmatter. Canonical slugs: `vardaan-koenig` (for content attributed to Vardaan) or `koenig-ai-academy` (for AI-authored/team content). Banned defaults: `editorial-team`, `blog-author`, `content-author`, `koenig-blog-author` — these yield Organization schema instead of Person schema and weaken AI citation signals. The `/authors/<slug>` page must exist on the site (not a stub). [KOEA-7017]

## Status vocabulary (contract with the frontend)
Authors hand off drafts as **`awaiting-g0`** — never `draft-for-review` (non-canonical; the frontend silently drops it). Full canonical set: `draft` → `awaiting-g0` → `g0-passed` / `g0-blocked` → `awaiting-qa` → `g2-passed` → `g3-passed` (LIVE from here) → `g4-approved` → `published`. Content file is always `draft.md` — never `index.md`.

## Publish governance (board decision 2026-07-09)
- Blogs auto-publish at **G3 PASS**. No per-blog G4 approval requests.
- Human G4 approval required ONLY for: new courses (first publish), pricing/commercial claims, legal/brand-sensitive topics, anything naming a partner or customer.
- A daily digest (Editor in Chief) reports everything that went live in the last 24h to the board with one-line summaries; the board can order an unpublish at any time.
