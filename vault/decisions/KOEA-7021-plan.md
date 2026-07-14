---
ticket: KOEA-7021
planner: planner
date: 2026-07-14
estimated_complexity: S
estimated_token_cost: $0.15
base_branch: master
---

# Plan

## Goal

Add a G0-stage author-page validator that blocks blog PRs whose `author:` frontmatter slug has no corresponding `vault/authors/<slug>.md` file, or whose author file is missing any of the 5 required E-E-A-T fields (jobTitle, bio, knowsAbout, worksFor, sameAs). Create at least 2 complete vault author pages to unblock KOEA-7017.

## Context

**Files to read first:**
- `companies/learnova-academy/skills/content-review/SKILL.md` — G0 reviewer skill; new sub-check inserts into Step 5 (Structure dimension)
- `learnovaBeast/learnova-academy/src/lib/authors.ts` — TypeScript registry; author slugs valid there are `vardaan-koenig`, `editorial-team`; blogs also use `koenig-ai-academy` (111 occurrences, falls back to `editorial-team` in the app)
- `vault/people/vardaan-aggarwal.md` — source data for vardaan-koenig author page

**Prior work / constraints:**
- No `vault/authors/` directory exists; must create it
- The app's `/authors/[slug]` route reads from `authors.ts`, NOT vault markdown — these are separate concerns; vault pages are the agent-readable E-E-A-T source
- The G0 Structure dimension already checks author resolves to `src/lib/authors.ts` — new check is additive (vault page presence + completeness)
- `koenig-ai-academy` is the slug used by 111 existing blogs; it is NOT in `AUTHORS` in `authors.ts` (falls back to `editorial-team`); vault author page uses the literal frontmatter slug, so file is `vault/authors/koenig-ai-academy.md`
- Acceptance criteria require ≥2 author pages → create `koenig-ai-academy` + `vardaan-koenig` (covers 122 of 123 live blogs)

## Approach

**Chosen: Additive sub-check in Structure dimension + vault author files**

Add one new bullet to the Structure dimension checklist in `content-review/SKILL.md` with its own BLOCK message template. Create `vault/authors/` with 3 author pages (koenig-ai-academy, vardaan-koenig, editorial-team). No new skill file needed — the check is concise enough to inline.

**Rejected alternatives:**

| Alternative | Why rejected |
|---|---|
| Standalone bash validator script | G0 is an LLM agent following SKILL.md; it doesn't shell out. Adds tool complexity with no benefit. |
| New 6th dimension ("Author integrity") | Author-page presence is a structural/completeness signal, not a separate editorial dimension. Inlining keeps the 5-dimension rubric clean. |
| Only update SKILL.md, no vault pages | Fails AC4 (≥2 author pages required) and leaves KOEA-7017 blocked. |

## Steps

1. **Create** `vault/authors/_index.md` — directory index with schema note and field spec (prevents agents from guessing the format)
2. **Create** `vault/authors/koenig-ai-academy.md` — Organization author page; all 5 fields (jobTitle=n/a for org, so use "description" field instead per schema note); aligns with `editorial-team` in `authors.ts`; covers 111 blogs
3. **Create** `vault/authors/vardaan-koenig.md` — Person author page; all 5 fields sourced from `vault/people/vardaan-aggarwal.md` + `authors.ts` data; covers 11 blogs
4. **Create** `vault/authors/editorial-team.md` — Organization author page; all 5 fields; covers 1 blog + future fallback slug
5. **Edit** `companies/learnova-academy/skills/content-review/SKILL.md` — insert author-page sub-check into Step 5 (Structure dimension) checklist, immediately after the existing `authors.ts` check bullet; add BLOCK example format for missing-file and missing-field cases
6. **Commit** all 5 files to master with message `[KOEA-7021] feat: G0 author-page validator + 3 vault author pages`

## Verification

Observable checks for QA (G2):

1. **Pass scenario:** Blog with `author: koenig-ai-academy` → `vault/authors/koenig-ai-academy.md` present with all 5 fields → G0 passes this sub-check without BLOCK comment for author-page
2. **Block scenario (file absent):** Blog with `author: some-new-person` → `vault/authors/some-new-person.md` does not exist → G0 BLOCK comment includes `AUTHOR PAGE MISSING: vault/authors/some-new-person.md not found. Create author page before publishing.`
3. **Block scenario (fields incomplete):** `vault/authors/some-author.md` exists but `knowsAbout:` is empty array → G0 BLOCK comment lists `missing fields: knowsAbout`
4. **File check:** `ls vault/authors/` returns `_index.md`, `koenig-ai-academy.md`, `vardaan-koenig.md`, `editorial-team.md`
5. **Field check:** Each author file has all 5 fields non-empty: `grep -E "^jobTitle:|^bio:|^knowsAbout:|^worksFor:|^sameAs:" vault/authors/koenig-ai-academy.md | wc -l` returns 5

## Risk

- **Slug mismatch:** `koenig-ai-academy` is not in `authors.ts` `AUTHORS` — the validator uses the raw frontmatter slug for vault lookup, which is correct. Executor must not canonicalize to `editorial-team` slug for the vault file name.
- **Organization jobTitle:** Organizations don't have a `jobTitle` per se; the validator spec lists jobTitle as mandatory for all types. Executor should use the org's editorial role description (e.g. "AI Editorial Team, Koenig Solutions") for the koenig-ai-academy page so the field is non-empty and meaningful for AI citation signals.
- **Scope creep:** DO NOT update `authors.ts` to add `koenig-ai-academy` as a named entry. That's a separate ticket (KOEA-7017 scope). This ticket's change is vault + skill only.

## Out of scope

- Adding `koenig-ai-academy` as a named entry in `learnovaBeast/src/lib/authors.ts` (KOEA-7017)
- Retroactively running the validator against all 111 existing blogs (not a blocker — only new/revised drafts go through G0)
- Author headshotPath or image assets (KOEA-7017 Phase 2)
- Updating `/authors` listing page in the app (app-side, KOEA-7017)
