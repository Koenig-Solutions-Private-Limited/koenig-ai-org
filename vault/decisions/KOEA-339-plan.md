---
ticket: KOEA-339
planner: planner
date: 2026-05-02
estimated_complexity: small
estimated_token_cost: $0.30
files_touched:
  - learnovaBeast/learnova-academy/src/lib/wikilinks.ts (NEW)
  - learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx
  - learnovaBeast/learnova-academy/src/app/learn/[slug]/page.tsx
tags: [planning, refactor, seo, koea-43-followup]
---

# Plan: Unify wikilink parsing across blog and learn renderers (KOEA-43 follow-up)

## Goal

Extract a shared `resolveWikilink(target, label?)` helper to `learnova-academy/src/lib/wikilinks.ts`, and replace the two divergent inline regex branches in `blog/[slug]/page.tsx` and `learn/[slug]/page.tsx` with calls to it. This fixes two real silent bugs that the KOEA-43 hotfix didn't catch and removes the duplication that caused the divergence.

## Context

KOEA-43 PR #5 (commit `c12d5b3`) fixed the `/blog/blog/` double-prefix wikilink in `blog/[slug]/page.tsx`. While reviewing the surrounding code, the engineering trio E2E test surfaced that **the same wikilink syntax is parsed by a second, divergent `inline()` function in `learn/[slug]/page.tsx`**, and the two implementations disagree on edge cases.

Concrete current behavior (verified against `koea-43/fix-seo-internal-links` branch):

| Wikilink form               | `blog/[slug]/page.tsx`                  | `learn/[slug]/page.tsx`              |
| --------------------------- | --------------------------------------- | ------------------------------------ |
| `[[course/x]]`              | `<Link href="/learn/x">` ✅              | `<Link href="/learn/x">` ✅          |
| `[[blog/x]]`                | `<Link href="/blog/x">` ✅              | renders as **plain text** 🐛         |
| `[[glossary/embeddings]]`   | `<Link href="/blog/glossary/...">` 🐛   | `<GlossaryPopover>` ✅               |
| `[[course-slug/chapter]]`   | `<Link href="/blog/course-slug/...">` 🐛| `<Link href="/learn/.../#ch-...">` ✅|
| `[[blog/x\|Display]]`        | label respected ✅                       | label respected ✅                   |

The two 🐛 rows in the blog renderer are 404s; the `[[blog/x]]` text fallback in the learn renderer means cross-references from a course chapter to a blog post silently lose their links. Neither failure is caught by `tsc --noEmit`. KOEA-43's acceptance criterion ("no 404s on any internal link") was approved without crawl evidence — this refactor closes that gap by centralising the resolver.

- Files to read first:
  - `learnova-academy/src/app/blog/[slug]/page.tsx:240-285` — wikilink branch (post-KOEA-43)
  - `learnova-academy/src/app/learn/[slug]/page.tsx:1251-1291` — wikilink branch with `GlossaryPopover` dispatch
  - `learnova-academy/src/components/GlossaryPopover.tsx` — used only by the learn renderer today
- Constraints: zero behaviour change for cases that already work; no new runtime deps; no test runner exists in the project, so verification is `tsc --noEmit` + visual smoke on dev server; KOEA-43 PR #5 is still queued for merge — branch this work off `main` after PR #5 lands so we don't churn the same files twice.

## Approach (chosen)

Add `learnova-academy/src/lib/wikilinks.ts` exporting a pure `resolveWikilink(target, label?)` that returns a discriminated union: `{ kind: "course-index" | "course-chapter" | "blog" | "glossary" | "unknown", … }`. Both page renderers parse the regex once, call `resolveWikilink()`, and dispatch on `kind` to choose between `<Link>`, `<GlossaryPopover>`, or plain text. The helper is renderer-agnostic (no JSX), so it stays trivially testable later when a runner is wired in. The blog page gains correct `/learn/...`, `/glossary/...`, and `/learn/<course>#ch-<chapter>` resolution; the learn page gains the missing `/blog/...` link path.

## Approaches rejected

- **Just patch each `inline()` independently to fix its own bugs.** Rejected: leaves two parsers in lockstep that drift again on the next change. The whole point of the trio E2E test is to exercise an honest refactor, not another targeted fix.
- **Extract to a shared `<Wikilink>` React component.** Rejected: the learn renderer needs `GlossaryPopover` (uses client-side popover state) while the blog renderer doesn't import it. Forcing a single component would either pull `GlossaryPopover` into every blog page bundle or branch on context anyway. A pure resolver + per-page renderer keeps blast radius small and bundles unchanged.
- **Move to a real markdown library (`react-markdown` + `remark-wiki-link`).** Rejected: out of scope — the existing `inline()` parsers handle several non-wikilink concerns (footnotes, code, RunPromptCell shortcodes) that would require non-trivial migration. Note as future work, do not bake in.

## Steps (Executor follows in order)

1. In `learnovaBeast`, branch off latest `main` (after PR #5 lands) as `koea-339/wikilink-helper`. If PR #5 has not merged yet, branch off `koea-43/fix-seo-internal-links` and rebase onto `main` once PR #5 is in.
2. Create `learnova-academy/src/lib/wikilinks.ts` exporting:
   - `type WikilinkResolution = { kind: "course-index"; href: string; label: string } | { kind: "course-chapter"; href: string; label: string; courseSlug: string; chapter: string } | { kind: "blog"; href: string; label: string } | { kind: "glossary"; term: string; label: string } | { kind: "unknown"; label: string }`
   - `function resolveWikilink(target: string, label?: string): WikilinkResolution` — splits `target` on `/`, dispatches on the first segment (`course`, `blog`, `glossary`) and on the 2-segment-without-prefix course/chapter form, computes `href` for the link kinds, and falls back to `{ kind: "unknown", label: label ?? target }`.
3. In `learnova-academy/src/app/blog/[slug]/page.tsx`, replace the wikilink branch (current ~lines 252–267) with: `const m = remaining.match(/^\[\[([^|\]]+)(?:\|([^\]]+))?\]\]/); if (m) { const r = resolveWikilink(m[1].trim(), m[2]?.trim()); ... }`. Render: `course-index`/`course-chapter`/`blog`/`glossary` → `<Link>` (use `/glossary/<term>` for the glossary kind here — the popover stays learn-page-only); `unknown` → plain text label. Keep the existing `var(--teal-600)` styling.
4. In `learnova-academy/src/app/learn/[slug]/page.tsx`, replace the wikilink branch (current ~lines 1261–1291) with the same `resolveWikilink()` call. Render: `glossary` → `<GlossaryPopover>` (preserve existing behaviour); `course-index`/`course-chapter`/`blog` → `<Link>` with the existing `var(--cyan-600)` styling; `unknown` → plain text label. Drop the now-dead inline branching.
5. Run `pnpm --filter learnova-academy tsc --noEmit` and `pnpm --filter learnova-academy lint`. Fix any types/lint surfaced by the new helper signature.
6. Run `pnpm --filter learnova-academy dev`, smoke-check the four pages below in a browser (golden path + each fixed bug). Capture a one-line note per page for the PR description.
7. Open PR `koea-339/wikilink-helper` → `main` titled `refactor(seo): unify wikilink resolver across blog + learn renderers [KOEA-339]`. Body: list the 4 forms × 2 contexts table (above) with before/after, link this plan, and tag for `@code-reviewer` (cursor + composer-2 standard).

## Verification (Code Reviewer + smoke)

- [ ] `pnpm --filter learnova-academy tsc --noEmit` exits clean.
- [ ] `pnpm --filter learnova-academy lint` exits clean (no new warnings).
- [ ] Smoke on `/blog/2026-04-30-anthropic-creative-connectors`: any `[[course/<slug>]]` resolves to `/learn/<slug>`; the blog post that previously hit `/blog/blog/...` (now fixed in PR #5) still renders correctly via the new helper; a `[[glossary/<term>]]` link points to `/glossary/<term>` (not `/blog/glossary/<term>`).
- [ ] Smoke on `/learn/claude-tool-use-from-zero` (or any course page that references `[[blog/<slug>]]` in chapter body): the wikilink renders as a clickable `<Link>` to `/blog/<slug>`, not as plain text.
- [ ] `[[glossary/embeddings]]` inside the learn page still renders the `<GlossaryPopover>` (no regression).
- [ ] Bundle size: no measurable change to `/blog/[slug]` or `/learn/[slug]` route bundles (helper is a few hundred bytes, tree-shakable).

## Risk

The `inline()` parser regex order matters — wikilinks `[[…]]` must match before the markdown link rule `[…](…)` because `[[` is a valid prefix of `[`. Both files already order the rules correctly today; the executor must preserve that ordering when shrinking the wikilink branch. Mitigation: keep the `inline()` rule order untouched and only replace the body of the existing wikilink `if (m)` block.

## Out of scope

- Replacing the bespoke `inline()` parsers with `react-markdown` / `remark-wiki-link` — note as future ticket if Chief Engineering wants to file it.
- Adding a unit-test runner to the academy package (no Vitest/Jest is wired today).
- A `wget --spider` build-time link crawler to satisfy KOEA-43's original "no 404s" criterion — file as a separate ticket if desired; not blocked by this refactor.
- Changing the visual styling of wikilinks (colors, underline, weight) — preserved exactly.
