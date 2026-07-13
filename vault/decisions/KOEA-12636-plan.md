---
ticket: KOEA-12636
parent: KOEA-7021
planner: planner
date: 2026-07-13
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
basebranch_verified: true
repo: koenig-ai-org
---

# Plan: G0 validator — reject blogs with stub /authors/<slug> pages

## Goal

Every blog draft that reaches G0 must have a substantive author page in the vault
(`vault/authors/<slug>/index.md`). The G0 reviewer will BLOCK if the file is missing,
under 100 words, or lacks required frontmatter. This closes the gap noted in
EDITORIAL.md §Author-slug where the policy mandated non-stub author pages but no
automated check enforced it.

## Context

- G0 skill: `companies/learnova-academy/skills/content-review/SKILL.md:85`
  — currently mentions "Author resolves to a Person/Org in authors.ts" as a Structure
  sub-check, but it is informal and does not read a file.
- Author TS registry: `learnovaBeast/learnova-academy/src/lib/authors.ts`
  — 2 registered slugs: `vardaan-koenig` (Person) and `editorial-team` (Organization).
- Blog frontmatter: most drafts use `author: koenig-ai-academy`; some use
  `author: vardaan-koenig`. `koenig-ai-academy` is NOT in authors.ts — falls back to
  editorial-team via getAuthor().
- EDITORIAL.md line 27 already declares the policy: "The /authors/<slug> page must exist
  on the site (not a stub)." No vault author files exist today.
- Vault has no `vault/authors/` directory yet.
- Files to read first: `companies/learnova-academy/skills/content-review/SKILL.md`,
  `learnovaBeast/learnova-academy/src/lib/authors.ts` (already read for this plan).

## Approach

**Chosen: Vault-side author markdown files + G0 SKILL.md addition**

Add a new step to SKILL.md that reads `vault/authors/<slug>/index.md` for the blog's
`author:` frontmatter value and blocks on missing/thin content. Pre-populate files for
the two canonical slugs (`vardaan-koenig`, `koenig-ai-academy`) so existing drafts
immediately pass.

**Rejected: Check authors.ts directly** — cross-repo reads inside G0 content review are
brittle (path changes break silently); the SOUL.md expects G0 to work vault-native.

**Rejected: Live-URL probe (`https://academy.kspl.tech/authors/<slug>`)** — network
dependency in G0 is slow and fails on local/CI runs; stub pages on live site aren't
detected before they publish.

## Required author page frontmatter schema

```yaml
---
slug: <slug>           # e.g. vardaan-koenig
display_name: <string> # e.g. "Vardaan Koenig"
type: Person | Organization
short_bio: <string>    # ≤ 40 words — used in byline tooltips
works_for: <string>    # e.g. "Koenig Solutions Pvt Ltd"
knows_about:
  - <topic>
  - <topic>
sameAs:
  - <URL>              # at least one social/web URL required
---
```

Body must be ≥ 100 prose words (count excludes frontmatter and YAML fences).

## Steps (Executor follows in order)

1. Create directory `vault/authors/` (mkdir, add `.gitkeep` or first file).

2. Create `vault/authors/vardaan-koenig/index.md` with full frontmatter + ≥100-word bio
   body. Source content from `learnovaBeast/learnova-academy/src/lib/authors.ts`
   (`vardaan-koenig` entry — bio, shortBio, knowsAbout, sameAs fields).

3. Create `vault/authors/koenig-ai-academy/index.md` with full frontmatter + ≥100-word
   bio body. Use editorial-team content from authors.ts as the base; slug must be
   `koenig-ai-academy` (not `editorial-team`) since that is the canonical slug used in
   most blog frontmatter.

4. Update `companies/learnova-academy/skills/content-review/SKILL.md`:
   a. Insert **"### 2a. Author page check"** between step 2 and step 3:

   ```markdown
   ### 2a. Author page check

   After reading the draft, extract the `author:` field from its YAML frontmatter.

   1. Read `vault/authors/<author-slug>/index.md`.
   2. If the file is missing → BLOCK with `AUTHOR_PAGE` category.
   3. Parse frontmatter. If any required field is absent
      (`slug`, `display_name`, `type`, `short_bio`, `works_for`, `sameAs`) → BLOCK.
   4. Count prose words in the body (exclude frontmatter block). If < 100 → BLOCK.

   Skip this check only when `author:` is absent from frontmatter entirely — that will
   be caught by the Structure dimension (step 5) as a missing-frontmatter blocker.
   ```

   b. Add `AUTHOR_PAGE` to the G0 BLOCK template (the `❌ G0 BLOCK` section):

   ```
   AUTHOR_PAGE (<n> blockers)
   - `vault/authors/<slug>/index.md` missing — create the author page before re-submitting.
   - OR: bio body is <N> words (minimum 100). Expand the bio.
   - OR: required frontmatter field `<field>` absent.
   ```

5. Update the Structure dimension check (step 5 in SKILL.md, line 85) — remove the
   informal "Author resolves to a Person or Organization in src/lib/authors.ts" item
   and replace it with a reference to the new step 2a:

   ```markdown
   - [ ] Author page exists and is not a stub — verified in step 2a above
   ```

6. Commit all changes to master with message:
   `[KOEA-7021] Add G0 author-page validator + vault/authors stub files`

## Verification (QA Verifier checks these)

- [ ] `vault/authors/vardaan-koenig/index.md` exists, body ≥ 100 words, all required
      frontmatter fields present.
- [ ] `vault/authors/koenig-ai-academy/index.md` exists, body ≥ 100 words, all required
      frontmatter fields present.
- [ ] SKILL.md step 2a is present and correctly named.
- [ ] SKILL.md G0 BLOCK template includes `AUTHOR_PAGE` category.
- [ ] Structure dimension (step 5) references step 2a instead of authors.ts.
- [ ] `git log --oneline -1` on master shows the commit.

## Risk

- **Most blog drafts use `author: koenig-ai-academy`**: step 3 creates that file so
  existing drafts continue to pass. Risk is low once step 3 is done before the validator
  goes live in SKILL.md.
- **Mitigation**: Executor does steps 1–3 before step 4 to avoid a window where existing
  drafts would be blocked.

## Out of scope

- Updating `learnovaBeast/src/lib/authors.ts` to add `koenig-ai-academy` (separate
  learnovaBeast ticket; authors.ts and vault/authors/ are independent sources for now).
- Creating `/authors/koenig-ai-academy` live page in learnovaBeast.
- Retroactive G0 re-review of already-g0-passed blogs.
- Checking reviewer byline (`agent_drafted_by`) — only `author:` is validated.
