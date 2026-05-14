---
title: KOE-96 — Mobile Responsiveness Comprehensive Fix Plan (Stage 2 Approved)
ticket: KOE-96
stage: plan-approved
status: executor-briefed
authored-by: chief-engineering (stage 1 by chief-eng + planner, merged in stage 2)
date: 2026-04-30
plan-review: ✅ approved by chief-engineering
---

# KOE-96 Mobile Responsiveness — Approved Executor Brief (13 Fixes)

## Baseline

- Repo: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`
- Branch: `academy/redesign-v1` → PR target: `academy/main`
- V3-mobile patch (KOE-65) is in the working copy (`academy.css` lines 314-402). All fixes below are measured against that baseline.

## Fix 1 — TopBar `<nav>` inline style defeats CSS hide

**File:** `src/app/academy.css:399`  
**Viewports:** ≤720px

`.topbar nav { display: none; }` loses to inline `style={{ display: "flex" }}` (CSS specificity). Nav stays visible and overflows topbar horizontally.

```css
/* BEFORE */
.topbar nav { display: none; }
/* AFTER */
.topbar nav { display: none !important; }
```

## Fix 2 — Catalog 3-col grid never collapses

**Files:** `src/app/catalog/page.tsx:88`, `src/app/academy.css` (max-width 720 block)  
**Viewports:** ≤720px

V3 selector `main > section [style*="grid-template-columns: repeat(3, 1fr)"]` requires a `<section>` ancestor. Catalog grid is `main > div` — never matches.

```jsx
// catalog/page.tsx:88 — add className
<div className="catalog-grid" style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 16 }}>
```
```css
/* academy.css — inside @media (max-width: 720px) block */
.catalog-grid { grid-template-columns: 1fr !important; }
```

## Fix 3 — TutorRail bottom sheet stuck (no expand mechanism)

**Files:** `src/components/_shared/tutor.tsx:41-93`, `src/app/learn/[slug]/page.tsx:191`, `src/app/blog/[slug]/page.tsx:133`  
**Viewports:** ≤768px

`.lesson-tutor.expanded` CSS class exists but nothing toggles it. Tutor is permanently inaccessible on mobile.

Add `TutorSheetWrapper` "use client" component in `tutor.tsx`:
```tsx
export function TutorSheetWrapper({ chapter }: { chapter: string }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <div
      className={`lesson-tutor${expanded ? " expanded" : ""}`}
      onClick={() => !expanded && setExpanded(true)}
      style={{ cursor: expanded ? "default" : "pointer" }}
      aria-label={expanded ? undefined : "Open Nova tutor"}
    >
      <TutorRail
        chapter={chapter}
        onExpand={() => setExpanded(true)}
        onCollapse={() => setExpanded(false)}
      />
    </div>
  );
}
```
Add `onExpand`/`onCollapse` props to `TutorRailProps`. Wire the header collapse button to `onCollapse`. Replace bare `<div className="lesson-tutor">` in both lesson and blog pages with `<TutorSheetWrapper chapter={...} />`.

## Fix 4 — Home meta-info row overflows at 320px

**File:** `src/app/page.tsx:65`  
**Viewports:** 320px

```jsx
// BEFORE
<div style={{ display: "flex", gap: 20, marginTop: 36, fontSize: 13, color: "var(--ink-muted)" }}>
// AFTER
<div style={{ display: "flex", flexWrap: "wrap", rowGap: 8, columnGap: 20, marginTop: 36, fontSize: 13, color: "var(--ink-muted)" }}>
```

## Fix 5 — Lesson chapter navigation inaccessible on mobile

**File:** `src/app/learn/[slug]/page.tsx:149`, `src/app/academy.css` (max-width 768 block)  
**Viewports:** ≤768px

Left rail hidden on mobile — no way to switch chapters. Add zero-JS `<details>` chapter selector above H1:

```jsx
// In lesson-main inner div, before the back-link row (around line 149)
<details className="lesson-chapter-mobile" style={{ display: "none", marginBottom: 16 }}>
  <summary style={{ padding: "10px 12px", border: "1px solid var(--rule)", borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: "pointer" }}>
    Chapter {currentCh.idx} of {course.chapters} · {currentCh.title}
  </summary>
  <nav style={{ marginTop: 8, padding: 8, border: "1px solid var(--rule)", borderRadius: 8 }}>
    {lesson.chapters.map((ch) => (
      <a key={ch.idx} href={`#chapter-${ch.idx}`} style={{ display: "block", padding: "8px 10px", fontSize: 13, color: "var(--ink)", textDecoration: "none" }}>
        {ch.idx}. {ch.title}
      </a>
    ))}
  </nav>
</details>
```
```css
/* academy.css — inside @media (max-width: 768px) */
.lesson-chapter-mobile { display: block !important; }
```

Where `currentCh = lesson.chapters.find((c) => c.current) ?? lesson.chapters[0]`.

## Fix 6 — Blog sidebar content (Sources, Learning Objectives) lost on mobile

**File:** `src/app/blog/[slug]/page.tsx` (after BlogBody, around line 130), `src/app/academy.css`  
**Viewports:** ≤768px

Left sidebar hidden, no fallback. Mobile readers lose access to sources. Add mobile-only footer block inside `<article className="lesson-main">`:

```jsx
<footer className="blog-mobile-meta" style={{ display: "none", marginTop: 40, padding: "20px 0", borderTop: "1px solid var(--rule)" }}>
  <div className="eyebrow" style={{ marginBottom: 8 }}>What you&apos;ll learn</div>
  <ul style={{ paddingLeft: 16, margin: "0 0 24px", fontSize: 14, color: "var(--ink-soft)", lineHeight: 1.6 }}>
    {post.learning_objectives.map((lo, i) => <li key={i} style={{ marginBottom: 6 }}>{lo}</li>)}
  </ul>
  {post.sources.length > 0 && (
    <>
      <div className="eyebrow" style={{ marginBottom: 8 }}>Sources</div>
      {post.sources.map((src, i) => (
        <a key={i} href={src} target="_blank" rel="noreferrer" style={{ fontSize: 12, color: "var(--cyan-600)", display: "block", marginBottom: 6, wordBreak: "break-all" }}>
          {new URL(src).hostname}
        </a>
      ))}
    </>
  )}
</footer>
```
```css
/* academy.css — inside @media (max-width: 768px) */
.blog-mobile-meta { display: block !important; }
```

## Fix 7 — Breakpoint mismatch 720 → 768 (typography/padding)

**File:** `src/app/academy.css:352`  
**Viewports:** 721–768px (hybrid layout bug)

`.lesson-grid` collapses at 768 but typography/padding only at 720. Devices at 721–768px get 1-col layout with desktop-scale H1/padding.

```css
/* academy.css line 352 — BEFORE */
@media (max-width: 720px) {
/* AFTER */
@media (max-width: 768px) {
```

This single change fixes the breakpoint mismatch AND subsumes Fix 9 (TopBar at 768px).

## Fix 8 — /tutor page broken on mobile (height stays fixed)

**Files:** `src/app/tutor/page.tsx:62`, `src/app/academy.css`  
**Viewports:** ≤768px

`height: calc(100vh - 56px)` stays on `<main>` when grid collapses to 1 column — conversation area shrinks to ~1/3 viewport, composer is covered.

```jsx
// tutor/page.tsx:62 — add className
<main className="tutor-shell" style={{ display: "grid", gridTemplateColumns: "240px 1fr 240px", gap: 0, height: "calc(100vh - 56px)" }}>
```
```css
/* academy.css — inside @media (max-width: 768px) block */
main.tutor-shell {
  grid-template-columns: 1fr !important;
  height: auto !important;
  min-height: calc(100vh - 56px);
}
main.tutor-shell > aside:first-of-type,
main.tutor-shell > aside:last-of-type {
  display: none;
}
```

(History + suggestions sidebars hidden on mobile — acceptable for V1. Tracked for future hamburger menu.)

## Fix 9 — TopBar overflow at 768px

**SUBSUMED BY FIX 7.** When the media query moves to 768px, the existing topbar collapse rules (nav hide, search shrink, chip hide) apply at 768px automatically. No separate action needed.

## Fix 10 — Skip-to-content target missing on all pages

**Files:** 13 page files + 2 layout files (see list below)  
**Viewports:** All

`layout.tsx:64` has `<a href="#main">` but no element has `id="main"`. Skip link does nothing.

Add `id="main"` to:
- `<main>` in: `page.tsx:42`, `blog/page.tsx:46`, `catalog/page.tsx:62`, `tutor/page.tsx:62`, `glossary/page.tsx:37`, `glossary/[slug]/page.tsx:60`, `capabilities/page.tsx:45`, `capabilities/[vendor]/page.tsx:59`, `capabilities/[vendor]/[feature]/page.tsx:75`, `authors/page.tsx:41`, `authors/[slug]/page.tsx:62`
- `<article>` in: `learn/[slug]/page.tsx:148`, `blog/[slug]/page.tsx:104`

## Fix 11 — Logo wordmark squeezes search bar at 320px

**File:** `src/app/academy.css` (CSS-only, no JSX edits)  
**Viewports:** ≤480px

Wordmark "Koenig AI Academy" (~140px) leaves only ~60–70px for search bar at 320px.

```css
/* academy.css — nested inside @media (max-width: 768px) or as separate block */
@media (max-width: 480px) {
  .topbar a[href="/"] > span { display: none; }
}
```

## Fix 12 — Lesson action rows lack flex-wrap

**Files:** `src/app/learn/[slug]/page.tsx:150`, `:175`, `src/components/_shared/content.tsx:141`  
**Viewports:** 320px

Three flex rows without `flexWrap: "wrap"` — back-link row, mark-complete CTA, RunPromptCell toolbar.

```jsx
// learn/[slug]/page.tsx:150 — back-link row
<div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20, flexWrap: "wrap", rowGap: 8 }}>

// learn/[slug]/page.tsx:175 — mark-complete row
<div style={{ marginTop: 56, padding: 20, borderRadius: 12, background: "var(--surface-2)", display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap", rowGap: 12 }}>

// content.tsx:141 — RunPromptCell toolbar
<div style={{ display: "flex", gap: 6, padding: "6px 10px", borderTop: "1px solid var(--rule)", background: "var(--surface-2)", flexWrap: "wrap", rowGap: 6 }}>
```

## Fix 13 — Blog post header chips overflow at 320px

**File:** `src/app/blog/[slug]/page.tsx:106`  
**Viewports:** 320px

```jsx
// BEFORE
<div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
// AFTER
<div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20, flexWrap: "wrap", rowGap: 8 }}>
```

---

## Files Executor will touch

| File | Fixes |
|------|-------|
| `src/app/academy.css` | 1, 2, 5, 6, 7, 8, 11 |
| `src/app/page.tsx` | 4, 10 |
| `src/app/catalog/page.tsx` | 2, 10 |
| `src/app/blog/page.tsx` | 10 |
| `src/app/blog/[slug]/page.tsx` | 3, 6, 10, 13 |
| `src/app/learn/[slug]/page.tsx` | 3, 5, 10, 12 |
| `src/app/glossary/page.tsx` | 10 |
| `src/app/glossary/[slug]/page.tsx` | 10 |
| `src/app/capabilities/page.tsx` | 10 |
| `src/app/capabilities/[vendor]/page.tsx` | 10 |
| `src/app/capabilities/[vendor]/[feature]/page.tsx` | 10 |
| `src/app/authors/page.tsx` | 10 |
| `src/app/authors/[slug]/page.tsx` | 10 |
| `src/app/tutor/page.tsx` | 8, 10 |
| `src/components/_shared/tutor.tsx` | 3 |
| `src/components/_shared/content.tsx` | 12 |

**Net delta:** ~120 LOC across 16 files. 2 new client components (`TutorSheetWrapper`, `<details>` chapter disclosure). No new deps.

---

## Branch + PR

```bash
git checkout -b koe-96/mobile-responsiveness-comprehensive
# implement all 13 fixes
git commit -m "fix(academy): comprehensive mobile responsiveness pass — 13 fixes [KOE-96]
Co-Authored-By: Paperclip <noreply@paperclip.ing>"
gh pr create \
  --base academy/main \
  --title "[KOE-96] fix(academy): comprehensive mobile responsiveness pass" \
  --body "Fixes all 13 mobile issues identified in Stage 1 audit (KOE-97). See vault/decisions/KOE-96-plan.md."
```

---

## Out of scope (do NOT include in this PR)

- Forced dark mode on `/tutor` (`<div className="dark">`) — separate ticket
- Mobile hamburger nav menu — future enhancement
- Fullscreen TutorRail — future enhancement
- Lighthouse / Web Vitals optimization

---

## QA Verifier checklist (from KOE-97 plan)

- [ ] Fix 1: 375px `/` — `<nav>` not visible inside `.topbar`
- [ ] Fix 2: 375px `/catalog` — 1 card/row; `document.scrollWidth ≤ 375`
- [ ] Fix 3: 375px `/learn/<slug>` + `/blog/<slug>` — bottom sheet expands to 75vh on tap
- [ ] Fix 4: 320px `/` — meta-info row wraps; no scroll
- [ ] Fix 5: 375px `/learn/<slug>` — chapter disclosure visible above H1
- [ ] Fix 6: 375px `/blog/<slug>` — Sources + objectives footer visible after article
- [ ] Fix 7: 750px synthetic — prose 16px, padding 20×16, nav hidden; 769px restores desktop
- [ ] Fix 8: 375px + 768px `/tutor` — conversation full-viewport; composer at bottom; 1024px shows 3 cols
- [ ] Fix 9: subsumed by Fix 7 ✅
- [ ] Fix 10: skip-link Tab+Enter lands on `<main id="main">`
- [ ] Fix 11: 320px `/` — only K-square logo, no wordmark; search placeholder readable
- [ ] Fix 12: 320px `/learn/<slug>` — 3 rows don't overflow
- [ ] Fix 13: 320px `/blog/<slug>` — header chips wrap; no overflow
- [ ] 1024px regression: all pages identical to current desktop
