---
ticket: KOEA-709
parent_ticket: KOEA-709
planner_ticket: KOEA-716
planner: planner
date: 2026-05-05
estimated_complexity: small (~25 LOC across 3 files)
estimated_token_cost: $0.30
files_touched:
  - learnova-academy/src/lib/vault.ts
  - learnova-academy/src/app/blog/[slug]/page.tsx
target_branch: academy/redesign-v1
target_repo: learnovaBeast
tags: [planning, seo, blog, wikilinks, koea-709]
---

# Plan: KOEA-709 — Fix FAQPage JSON-LD emission + wikilink resolver blog-prefix bug

## Goal

Two independent surface bugs on the public Academy blog, fixed in a single PR because they share one file (`blog/[slug]/page.tsx`):

1. **FAQPage JSON-LD never reaches the page.** All 13 publishable blog posts already carry a YAML `faq:` list in frontmatter (added in commit `f70f46b7`, KOEA-431), but the renderer drops it on the floor — the type `BlogPost` has no `faq` field, `readBlogFile()` doesn't pass it through, and the page never calls `faqPageLd()`. The schema-org `FAQPage` block is missing on every blog post → no rich-result eligibility.
2. **`[[blog/<slug>]]` wikilinks render as broken `/learn/blog#ch-<slug>` URLs.** The blog `inline()` function has named-prefix branches for `glossary/` and `course/`, then a slash-catch-all that assumes "first segment is a course slug, rest is a chapter anchor." Any other namespace — `blog/`, future `tag/`, etc. — falls through into that catch-all and produces a dead link.

After the fix: every g0+ blog post emits a third JSON-LD block (FAQPage) alongside BlogPosting + BreadcrumbList; `[[blog/foo]]` resolves to `/blog/foo`.

## Context

### Files to read first

- `learnova-academy/src/lib/vault.ts:21-40` — `BlogPost` interface (no `faq` field today)
- `learnova-academy/src/lib/vault.ts:48-114` — `readBlogFile()`; gray-matter already parses YAML `faq:` into `data.faq` as `{question, answer}[]`, the result is just never read
- `learnova-academy/src/lib/seo.ts:146-149` — local `interface FaqItem { question; answer }` (NOT exported; structural typing is fine)
- `learnova-academy/src/lib/seo.ts:213-223` — `faqPageLd(items: FaqItem[])` already exists and is exported; identical shape used by learn pages today
- `learnova-academy/src/app/blog/[slug]/page.tsx:16` — current SEO imports (`jsonLdScript, blogPostingLd, breadcrumbLd`)
- `learnova-academy/src/app/blog/[slug]/page.tsx:78-103` — JSON-LD `<script>` block, where the new entry is spread in
- `learnova-academy/src/app/blog/[slug]/page.tsx:498-624` — `inline()` function; bug at the catch-all on line 597
- `learnova-academy/src/app/learn/[slug]/page.tsx:1251-1291` — reference pattern: named prefix checks (`glossary/`, `course/`) with a single course-chapter fallback. Mirror this in blog context.

### Cross-cutting facts

- `inline()` is a **module-local** function in `blog/[slug]/page.tsx` — `git grep` confirms zero callers outside this file. No risk of leaking the wikilink change to other pages.
- Line numbers above are against `origin/academy/redesign-v1` (the Executor's working branch). The `<Script>`-vs-`<script>` divergence on `koea-40/json-ld-schema-sitewide` is unrelated; do not rebase onto it.
- 13 vault blog files already declare `faq:` (verified via `grep -l "^faq:" vault/blogs/*/draft.md`). No content authoring is required; this is purely a renderer change.
- gray-matter parses the frontmatter YAML list directly to `{question: string; answer: string}[]` — no coercion needed.

## Approach (chosen)

**One PR, two commits**, both touching the blog renderer plus one shared `vault.ts` change.

Rejected alternatives:

- **Split into two PRs (one per bug).** Both fixes touch `blog/[slug]/page.tsx`; splitting forces a rebase and doubles the review-cycle cost for two trivial diffs. The bugs are unrelated logically but fully colocated physically.
- **Drop the slash-catch-all entirely (render unknown `[[ns/slug]]` as plain text).** Tempting for safety, but the existing fallback (`/learn/<first>#ch-<rest>`) is genuine load-bearing behavior for blog→course chapter cross-links and at least one currently-published post may rely on it. Not in scope to audit — keep the fallback, add a `blog/` named branch in front of it.
- **Export `FaqItem` from `seo.ts` and reuse in `BlogPost`.** Marginal cleanup; not needed (structural typing matches), and out of scope for a bug-fix ticket.

## Steps (Executor follows in order)

### Fix 1 — FAQPage JSON-LD (3 touch-points)

1. **`learnova-academy/src/lib/vault.ts:21-40`** — extend `BlogPost` with an optional `faq`:

   ```ts
   export interface BlogPost {
     // ...existing fields...
     references?: BlogReference[];
     faq?: { question: string; answer: string }[];   // ← new
     reviewer?: string;
     // ...
   }
   ```

2. **`learnova-academy/src/lib/vault.ts:95-114`** — pass `data.faq` through in the returned object. Insert one line in the return literal, near `references`:

   ```ts
   return {
     // ...
     references,
     faq: data.faq,           // ← new (no normalization; shape is already {question, answer}[])
     reviewer: data.reviewer,
     // ...
   };
   ```

3. **`learnova-academy/src/app/blog/[slug]/page.tsx:16`** — add `faqPageLd` to the existing import:

   ```ts
   import { jsonLdScript, blogPostingLd, breadcrumbLd, faqPageLd } from "@/lib/seo";
   ```

4. **`learnova-academy/src/app/blog/[slug]/page.tsx:81-101`** — conditionally append `faqPageLd(post.faq)` to the array passed to `jsonLdScript([...])`. Use spread + ternary so the array stays a single expression:

   ```tsx
   __html: jsonLdScript([
     blogPostingLd({ /* unchanged */ }),
     breadcrumbLd([ /* unchanged */ ]),
     ...(post.faq?.length ? [faqPageLd(post.faq)] : []),
   ]),
   ```

   No new `<script>` element — keep one consolidated JSON-LD block, matching the learn-page convention.

### Fix 2 — `[[blog/<slug>]]` wikilinks (1 touch-point)

5. **`learnova-academy/src/app/blog/[slug]/page.tsx:597`** — insert a `target.startsWith("blog/")` branch immediately **before** the existing `else if (target.includes("/"))` catch-all. Keep the catch-all as the course-chapter fallback (intentional behavior preserved).

   ```tsx
   } else if (target.startsWith("blog/")) {
     const blogSlug = target.replace("blog/", "");
     const display = label ?? blogSlug;
     parts.push(
       <Link
         key={key++}
         href={`/blog/${blogSlug}`}
         style={{ color: "var(--cyan-600)", textDecoration: "underline" }}
       >
         {display}
       </Link>,
     );
   } else if (target.includes("/")) {
     // ...existing course-chapter fallback unchanged...
   }
   ```

   - Pipe label syntax (`[[blog/foo|read this]]`) is supported by the existing capture group `m[2]`; reuse `label`.
   - **Do NOT** route through `slugify(target)` — `blog/<slug>` is already canonical (the no-slash `else` branch on line 608 uses `slugify` for human-readable wikitext like `[[Some Blog Title]]`, which is a different code path).
   - `[[glossary/<term>]]` continues to hit its dedicated branch at line 574 (verified by branch ordering — Executor must keep the `blog/` branch **after** `glossary/` and `course/`, **before** the slash catch-all).

## Verification (QA Verifier checks these)

Manual smoke + grep, no full test suite needed for a 25-LOC renderer change.

- [ ] **JSON-LD present.** `curl -s https://academy.kspl.tech/blog/cloudflare-agents-week-2026-explained | grep -A2 '"@type":"FAQPage"'` returns the FAQPage block on a deployed preview. Locally: `pnpm --filter learnova-academy build && pnpm --filter learnova-academy start`, then view-source on any of the 13 blog URLs and confirm three JSON-LD blocks.
- [ ] **Schema validator clean.** Paste rendered HTML into https://validator.schema.org/ — FAQPage parses with N `Question`/`Answer` pairs matching the YAML.
- [ ] **All 13 blogs covered.** `for f in vault/blogs/*/draft.md; do grep -l "^faq:" "$f"; done | wc -l` returns 13, and each rendered page has the FAQPage block.
- [ ] **Wikilink fix.** Add a temporary `[[blog/cloudflare-agents-week-2026-explained]]` to any draft.md, build, view-source: link href is `/blog/cloudflare-agents-week-2026-explained`, not `/learn/blog#ch-cloudflare-agents-week-2026-explained`. Revert the temp edit before commit.
- [ ] **Glossary popover untouched.** `[[glossary/agentic-loop]]` in any blog body still renders `GlossaryPopover` (visual hover popover, not a Link).
- [ ] **Course-chapter fallback preserved.** `[[claude-tool-use-from-zero/chapter-1]]` in a blog body still resolves to `/learn/claude-tool-use-from-zero#ch-chapter-1`.
- [ ] **No type errors.** `pnpm --filter learnova-academy typecheck` (or `tsc --noEmit`) is clean.

## Risk

- **Risk:** A blog already in the wild uses `[[blog/something]]` in body text expecting the (broken) catch-all → `/learn/blog#ch-something` URL — and someone has linked to that broken URL externally.
  **Mitigation:** Searching `vault/blogs/*/draft.md` for `[[blog/` is part of Executor's pre-flight; if any are found, the new behavior fixes them (which is the goal). External inbound links to `/learn/blog#…` aren't a thing because that path 404s today (`/learn/blog` is not a course slug).
- **Risk:** gray-matter on a malformed `faq:` list crashes the build.
  **Mitigation:** All 13 existing files were lint-checked when KOEA-431 landed. New `faq?: …[]` is optional; absent or empty arrays are silently skipped by the spread guard `post.faq?.length`. No try/catch needed.
- **Risk:** TypeScript rejects passing `BlogPost.faq` (anonymous shape) into `faqPageLd` (typed `FaqItem[]`).
  **Mitigation:** Structural typing — TS accepts `{question; answer}[]` and `FaqItem[]` as equivalent. Verified by reading both definitions; no `as` cast required. If for any reason TS complains, simplest escape is to export `FaqItem` from `seo.ts` and reuse — but Executor should not preemptively do this.

## Out of scope

- Building a runtime Schema.org validator into the build pipeline (separate ticket if desired).
- Auto-generating FAQ entries for blogs that don't have `faq:` frontmatter (out of scope; KOEA-431 already authored them by hand for the 13 currently-published posts).
- Changing the learn-page wikilink handler — already correct; reference-only.
- Refactoring the blog `inline()` function to share code with learn `inline()` — the two are intentionally divergent (blog has footnote-anchor differences). Refactor would be a separate KOEA ticket.
- Migrating `<script>` JSON-LD to next/script — that decision is owned by KOEA-40 (`koea-40/json-ld-schema-sitewide`); this PR must not touch the script tag.

## Estimate for Executor

- LOC: ~25 (5 in `vault.ts`, 1 import + 1 spread + ~12 wikilink branch in `page.tsx`)
- Files: 2
- Token budget: ~$0.40 for Executor (read 4 files, 2 surgical edits, build + typecheck verify)
- Wall-clock: <30 min including local build verification

## Handoff

- Executor target branch: new branch off `academy/redesign-v1` in `learnovaBeast/`, e.g. `koea-709/blog-faq-jsonld-and-wikilinks`
- PR base: `academy/redesign-v1`
- PR title: `KOEA-709: emit FAQPage JSON-LD on blog posts + fix [[blog/<slug>]] wikilink resolver`
- Status flip on KOEA-716 → `ready-to-execute`, assign to executor
