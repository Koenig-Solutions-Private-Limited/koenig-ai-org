---
ticket: KOE-97
parent: KOE-96
stage: 1-audit
planner: planner
date: 2026-04-30
estimated_complexity: medium
status: ready-for-chief-engineering-review
---

# KOE-97 — Mobile Responsiveness Comprehensive Audit (Stage 1)

## Goal

Produce a complete, page-by-page mobile-responsiveness audit of academy.kspl.tech across 10 routes and 5 viewports, identifying every rendering defect that survives the V3-mobile patch (KOE-65). Each finding is a concrete, incremental CSS / JSX patch — no framework swaps, no layout rewrites.

## Baseline (state of code at time of audit)

- Repo: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`
- Branch: `academy/redesign-v1`
- V3-mobile patch is **uncommitted in the working copy** (CSS comment `LOCKED 2026-04-30`); not yet on `origin/main`. All findings below are measured against `academy.css` with the V3-mobile block applied (lines 314-402).
- Page components on the same branch.
- This audit assumes the parent KOE-96 ticket will land Bugs 1-4 (TopBar nav `!important`, catalog grid, TutorSheetWrapper, home meta-row wrap) — those are **Fix 1-4 below, restated for completeness** but are already drafted in `vault/decisions/KOE-96-plan.md`. **Fix 5-13 are net-new** and address why Vardaan still rates the experience "not up to the mark."

## Viewport-to-page rendering matrix

Legend: ✅ renders OK · ⚠ minor issue · ❌ broken/unusable · — fix lands in fix N

| Page | 320 SE | 390 14 | 414 Plus | 768 iPad-P | 1024 iPad-L |
|------|:--:|:--:|:--:|:--:|:--:|
| `/` | ❌ Fix 4, 11 | ⚠ Fix 11 | ⚠ Fix 11 | ⚠ Fix 7, 9 | ✅ |
| `/blog` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/blog/[slug]` | ❌ Fix 3, 6, 13 | ❌ Fix 3, 6, 13 | ❌ Fix 3, 6, 13 | ⚠ Fix 7, 9 | ✅ |
| `/learn/[slug]` | ❌ Fix 3, 5, 12, 13 | ❌ Fix 3, 5, 12, 13 | ❌ Fix 3, 5, 12, 13 | ❌ Fix 3, 5, 7, 9 | ⚠ |
| `/glossary` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/glossary/[slug]` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/capabilities` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/capabilities/[vendor]` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/capabilities/[vendor]/[feature]` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/authors` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/authors/[slug]` | ✅ | ✅ | ✅ | ⚠ Fix 9 | ✅ |
| `/catalog` | ❌ Fix 2 | ❌ Fix 2 | ❌ Fix 2 | ⚠ Fix 9 | ✅ |
| `/tutor` | ❌ Fix 8 | ❌ Fix 8 | ❌ Fix 8 | ❌ Fix 7, 8 | ⚠ |

Plus accessibility regressions affecting all pages: Fix 10 (skip-link target).

---

## Fixes restated from KOE-96 (Bugs 1-4) — already in `vault/decisions/KOE-96-plan.md`

### Fix 1 — TopBar `<nav>` inline `display: flex` defeats CSS hide

- **File:** `learnova-academy/src/app/academy.css:398`; component: `learnova-academy/src/components/_shared/chrome.tsx:145`
- **Problem:** `<nav>` still visible at ≤720px; overflows topbar.
- **Root cause:** Element-class selector loses to inline `style={{ display: "flex" }}`.
- **Proposed fix:**
  ```css
  /* academy.css line 398 — before */
  .topbar nav { display: none; }
  /* after */
  .topbar nav { display: none !important; }
  ```
- **Acceptance:** At 375px, no `<nav>` visible inside `.topbar`; topbar fits without horizontal scroll.

### Fix 2 — Catalog grid never collapses on mobile

- **File:** `learnova-academy/src/app/catalog/page.tsx:88`; CSS in `academy.css` `@media (max-width: 720px)` block.
- **Problem:** 3-col course grid stays at 320–414px → ~1100px content overflows viewport.
- **Root cause:** V3 selector `main > section [style*="grid-template-columns: repeat(3, 1fr)"]` requires a `<section>` ancestor; catalog grid is a direct `<div>` child of `<main>`.
- **Proposed fix:**
  - In `catalog/page.tsx:88`, add `className="catalog-grid"` to the grid `<div>`.
  - In `academy.css` add inside the existing `@media (max-width: 720px)` block:
    ```css
    .catalog-grid { grid-template-columns: 1fr !important; }
    ```
- **Acceptance:** At 375px, exactly one course card per row; no horizontal scroll.

### Fix 3 — TutorRail bottom sheet has no expand mechanism

- **Files:** `learnova-academy/src/components/_shared/tutor.tsx:41-93`; `learnova-academy/src/app/learn/[slug]/page.tsx:191`; `learnova-academy/src/app/blog/[slug]/page.tsx:133-135`
- **Problem:** On mobile (≤768px) `.lesson-tutor` is fixed at `height: 56px; overflow: hidden`. The `.expanded` class is never added — the tutor is permanently inaccessible on mobile.
- **Root cause:** No client-side toggle. The `<button>` at `tutor.tsx:85-92` has no `onClick`. The wrapper `<div className="lesson-tutor">` in both pages is a server component with no state.
- **Proposed fix:** Add a `TutorSheetWrapper` client component that owns `expanded` state, applies `.expanded` class, and forwards `onExpand`/`onCollapse` props into `TutorRail`. Replace the bare `<div className="lesson-tutor">` in both lesson and blog pages with `<TutorSheetWrapper chapter={...} />`. Tap-anywhere on the 56px header expands; the existing collapse button collapses.
- **Acceptance:** At 375px on `/learn/<slug>` and `/blog/<slug>`, tapping the bottom 56px sheet expands it to 75vh; the collapse button restores 56px; both transitions animate smoothly.

### Fix 4 — Home meta row overflows on small phones

- **File:** `learnova-academy/src/app/page.tsx:65`
- **Problem:** Three `<span>`s (Anonymous-by-default · Run real prompts · Always-on tutor) on a single flex row; total ~430px → overflows 320px viewport.
- **Root cause:** Missing `flexWrap`.
- **Proposed fix:**
  ```jsx
  // before
  <div style={{ display: "flex", gap: 20, marginTop: 36, fontSize: 13, color: "var(--ink-muted)" }}>
  // after
  <div style={{ display: "flex", flexWrap: "wrap", rowGap: 8, columnGap: 20, marginTop: 36, fontSize: 13, color: "var(--ink-muted)" }}>
  ```
- **Acceptance:** At 320px, items wrap to multiple rows; no horizontal scroll.

---

## Fixes net-new in this Stage-1 audit

### Fix 5 — Lesson page chapter navigation inaccessible on mobile

- **File:** `learnova-academy/src/app/learn/[slug]/page.tsx:90-145` (left rail rendering chapter list); CSS rule `learnova-academy/src/app/academy.css:319` (`.lesson-nav { display: none }` at ≤768px).
- **Problem:** On `/learn/[slug]` at ≤768px, the entire chapter sidebar (chapter list + skill graph) is hidden via `display: none`. The lesson body only renders the *current* chapter's variant component (`InteractiveVariant` / `PdfVariant` / `VideoVariant`). **Mobile users have no way to switch chapters or see lesson progress.**
- **Root cause:** V3-mobile hid the rail and provided no inline replacement. The chapter anchors (`href="#chapter-${ch.idx}"`) point to in-page sections, but no chapter sections are actually rendered in the variants — the anchors land nowhere.
- **Proposed fix:** Add a mobile-only collapsible chapter selector at the top of the lesson body (above the H1). Use a native `<details>` element so it's zero-JS:
  ```jsx
  // learn/[slug]/page.tsx — inside the inner <div> at line 149, before the back-to-catalog row
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
  And in `academy.css` inside the existing `@media (max-width: 768px)` block:
  ```css
  .lesson-chapter-mobile { display: block !important; }
  ```
- **Acceptance:** At 375px on `/learn/<slug>`, a "Chapter N of M · <title>" disclosure appears above the H1; tapping it expands a list of all chapters that scroll the page on tap. At 1024px+, the disclosure is hidden and the existing left rail shows.

### Fix 6 — Blog post sidebar (Sources, Learning Objectives) hidden on mobile

- **File:** `learnova-academy/src/app/blog/[slug]/page.tsx:70-102` (the `<aside className="lesson-nav">` block); CSS rule `academy.css:319`.
- **Problem:** On `/blog/[slug]` at ≤768px, the sidebar containing **Sources** (citation links — critical for AI-search trust) and **Learning Objectives** is hidden via `.lesson-nav { display: none }`. There is no inline replacement below the article. Mobile readers lose access to the sources every blog post is supposed to cite.
- **Root cause:** Sidebar content is nowhere else in the DOM; hide-only behaviour, not move-and-show.
- **Proposed fix:** Render a mobile-only "Sources & objectives" footer block at the bottom of the article body. Add inside `<article className="lesson-main">` after the `<BlogBody>` (around line 130):
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
  And in `academy.css` inside `@media (max-width: 768px)`:
  ```css
  .blog-mobile-meta { display: block !important; }
  ```
- **Acceptance:** At 375px on `/blog/<slug>`, scrolling past the article body reveals the learning objectives and sources list. At 1024px the same content remains in the left rail; the footer is hidden.

### Fix 7 — Breakpoint mismatch between layout collapse (768) and typography/padding (720)

- **File:** `learnova-academy/src/app/academy.css` lines 314 (`@media (max-width: 768px)`) vs 352 (`@media (max-width: 720px)`).
- **Problem:** Devices in the 721–768px window (uncommon Android tablets, some split-screen modes, the iPad-portrait keyboard-up state) hit the `.lesson-grid` 1-col collapse rule but **not** the heading downsizes, prose font scale-down, padding compress, or topbar collapse. Result: a 1-column layout with desktop-scale H1 (56px), desktop padding (32px×28px), and the full topbar nav — visually awkward.
- **Root cause:** Two breakpoints chosen at different times. The grid rule and the typography rule must align.
- **Proposed fix:** Unify on **768px**. Change the second media block opener:
  ```css
  /* academy.css line 352 — before */
  @media (max-width: 720px) {
  /* after */
  @media (max-width: 768px) {
  ```
  This subsumes the existing `.lesson-grid` block (lines 314-335). Keep both `@media` blocks because some rules (multi-col grid → 1-col) are appropriate at 768 too. Verify no rule that should *only* fire below 720 needs the tighter breakpoint — none do (all rules in the 720 block are safe at 768).
- **Acceptance:** At a synthetic 750px width, the topbar nav is hidden, prose is 16px, and main padding is 20px×16px. At 769px, the desktop layout fully restores.

### Fix 8 — `/tutor` page broken on mobile (3-col layout collapses but height collapses too)

- **File:** `learnova-academy/src/app/tutor/page.tsx:62`
- **Problem:** `<main>` uses `gridTemplateColumns: "240px 1fr 240px"` plus `height: calc(100vh - 56px)`. The V3 fix at ≤720px collapses to single column, but the **fixed height stays**, so all three sections (History sidebar, Conversation, "Things you've learned" sidebar) try to fit in `100vh - 56px` while stacked vertically. The conversation area shrinks to ~1/3 of viewport and the bottom sidebar covers the composer; chat is unusable.
  Also at 768px (iPad portrait), the 3-col stays (V3 only collapses at ≤720) leaving ~288px for the chat column — too narrow for usable conversation.
- **Root cause:** `height: calc(100vh - 56px)` was designed for a 3-col flex; it doesn't relax when the grid stacks. And the `/tutor` collapse breakpoint (720) is wrong for iPad portrait (768).
- **Proposed fix:**
  - Move the `/tutor` collapse breakpoint to 768 (subsumed by Fix 7 if applied).
  - Add a class `tutor-shell` to the `<main>` element and add CSS:
    ```css
    @media (max-width: 768px) {
      main.tutor-shell {
        grid-template-columns: 1fr !important;
        height: auto !important;
        min-height: calc(100vh - 56px);
      }
      main.tutor-shell > aside:first-of-type,            /* History */
      main.tutor-shell > aside:last-of-type {            /* Things you've learned */
        display: none;
      }
    }
    ```
    Add `className="tutor-shell"` to the `<main>` element in `tutor/page.tsx:62`.
  - Tradeoff noted: history + suggestions sidebars are hidden on mobile (acceptable for V1; can be exposed via a hamburger in a follow-up). Conversation gets the full viewport.
- **Acceptance:** At 375px and 768px, `/tutor` shows only the conversation column with the composer pinned to the bottom; the page scrolls; suggestions chips and existing seed turns render in order. At 1024px, the 3-col layout is unchanged.

### Fix 9 — Topbar overflows at 768 (iPad portrait)

- **File:** `learnova-academy/src/app/academy.css` topbar block (lines 305-312); collapse rules in `@media (max-width: 720px)` (lines 397-402).
- **Problem:** At 768px the topbar still renders Logo (~160px) + 16gap + nav 4×~60 (240) + 16gap + spacer + 16gap + 280px search button + 16gap + DarkToggle (32) + 16gap + Anonymous chip (~80) ≈ 856px > 768. Items wrap or overflow. (`overflow: hidden` on `.topbar` clips the chip in `chrome.tsx`.)
- **Root cause:** Topbar collapse only triggers at ≤720. At 768 the full layout is still requested.
- **Proposed fix:** Subsumed by Fix 7 (move topbar collapse to 768). If Fix 7 is *not* taken, add a stand-alone block:
  ```css
  @media (max-width: 768px) {
    .topbar { padding: 0 12px; gap: 8px; overflow: hidden; }
    .topbar nav { display: none !important; }
    .topbar > button.input { width: auto !important; flex: 1; min-width: 0; }
    .topbar > button.input .kbd { display: none; }
    .topbar .chip { display: none; }
  }
  ```
- **Acceptance:** At 768px wide, the topbar fits on a single line with Logo + search button + DarkToggle visible; nav, kbd, chip hidden.

### Fix 10 — Skip-to-content link target missing

- **Files:** `learnova-academy/src/app/layout.tsx:64` declares `<a href="#main">`; the `<main>` element across all pages (e.g., `page.tsx:42`, `blog/page.tsx:46`, `catalog/page.tsx:62`, `tutor/page.tsx:62`, `glossary/page.tsx:37`, `capabilities/page.tsx:45`, `authors/page.tsx:41`, plus `<article className="lesson-main">` on lesson + blog post) **has no `id="main"`** anywhere. Skip link does nothing — a keyboard/AT user lands on... nothing.
- **Root cause:** Inconsistency between layout and per-page main elements.
- **Proposed fix:**
  - For `<main>`-rooted pages, add `id="main"` to the `<main>` element. Pages: `page.tsx:42`, `blog/page.tsx:46`, `catalog/page.tsx:62`, `tutor/page.tsx:62`, `glossary/page.tsx:37`, `glossary/[slug]/page.tsx:60`, `capabilities/page.tsx:45`, `capabilities/[vendor]/page.tsx:59`, `capabilities/[vendor]/[feature]/page.tsx:75`, `authors/page.tsx:41`, `authors/[slug]/page.tsx:62`.
  - For `<article className="lesson-main">`-rooted pages, add `id="main"` to the `<article>`. Pages: `learn/[slug]/page.tsx:148`, `blog/[slug]/page.tsx:104`.
- **Acceptance:** Tab to focus the skip-link in any page; Enter; focus jumps to the main content. Verified with VoiceOver rotor.

### Fix 11 — Logo wordmark squeezes search bar at 320px

- **File:** `learnova-academy/src/components/_shared/chrome.tsx:114-121` (Logo wordmark span); CSS in `academy.css`.
- **Problem:** At 320px, after Fix 1 hides the nav, the topbar lays out: Logo svg (26) + 8 + Logo wordmark "Koenig AI Academy" (~140) + 8 + spacer (flex 1) + 8 + search-button (flex 1, min ~120) + 8 + DarkToggle (32) = the wordmark eats half the topbar, search bar gets ~60–70px and can't show its placeholder.
- **Root cause:** Logo always renders the wordmark; no responsive collapse.
- **Proposed fix:** Hide the wordmark at ≤480px via CSS (preserves SSR — keeps the markup server-rendered, just visually hidden). Add inside the `@media (max-width: 768px)` block in `academy.css`:
  ```css
  @media (max-width: 480px) {
    .topbar a[href="/"] > span { display: none; }
  }
  ```
  Targeting the wordmark span via the structural selector keeps the logo svg visible; no JSX edit needed.
- **Acceptance:** At 320px, only the K-square logo + search-bar + theme toggle appear in the topbar; placeholder text reads "Search lessons, ask Nova…" without truncation. At 481px+, the wordmark returns.

### Fix 12 — Lesson page action rows lack flex-wrap on small phones

- **File:** `learnova-academy/src/app/learn/[slug]/page.tsx:150-158` (back-to-catalog row), `:175-186` (mark-complete CTA row); `learnova-academy/src/components/_shared/content.tsx:141-190` (`RunPromptCell` toolbar).
- **Problem:**
  - `learn/[slug]/page.tsx:150` — back link + spacer + 2 chips (`12 min read`) on a flex row with no wrap; at 320px the chips push past the right edge.
  - `learn/[slug]/page.tsx:175` — "Mark this chapter as understood" title block + button on flex row; at 320px the title wraps inside its column but the button is pushed off-screen.
  - `content.tsx:141` (RunPromptCell toolbar) — Run / Copy / Save-to-vault buttons + token counter on flex row, no wrap; at 320px the counter overflows.
- **Root cause:** Missing `flexWrap: "wrap"` on three flex rows.
- **Proposed fix:** Three small JSX edits, each adds `flexWrap: "wrap"` (and where needed `rowGap: 8` to preserve spacing):
  ```jsx
  // learn/[slug]/page.tsx:150
  <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20, flexWrap: "wrap", rowGap: 8 }}>

  // learn/[slug]/page.tsx:175
  <div style={{ marginTop: 56, padding: 20, borderRadius: 12, background: "var(--surface-2)", display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap", rowGap: 12 }}>

  // content.tsx:141
  <div style={{ display: "flex", gap: 6, padding: "6px 10px", borderTop: "1px solid var(--rule)", background: "var(--surface-2)", flexWrap: "wrap", rowGap: 6 }}>
  ```
- **Acceptance:** At 320px on `/learn/<slug>`, no horizontal scroll inside any of the three rows; controls wrap to a second line cleanly.

### Fix 13 — Blog post header chips overflow at 320px

- **File:** `learnova-academy/src/app/blog/[slug]/page.tsx:106-117`
- **Problem:** Header row is `← Home · spacer · clock chip · vendor-tag chip` on flex with no wrap. Vendor tags can be long ("Anthropic Claude Skills"). At 320px the right-side chips overflow.
- **Root cause:** Missing `flexWrap`.
- **Proposed fix:**
  ```jsx
  // blog/[slug]/page.tsx:106 — before
  <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
  // after
  <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20, flexWrap: "wrap", rowGap: 8 }}>
  ```
- **Acceptance:** At 320px on `/blog/<slug>`, the chips wrap below the back link rather than overflowing.

---

## Out of scope (flagged for separate tickets — do NOT bundle into KOE-96)

- **Forced dark-mode wrapper on `/tutor`** (`tutor/page.tsx:60` `<div className="dark">`) overrides user preference. Bug, but not mobile-specific. → propose KOE-99 to remove the forced class and let `DarkToggle` rule.
- **Mobile chapter navigation drawer** (richer than Fix 5's `<details>` disclosure — e.g., a slide-in left drawer triggered by a hamburger) — explicitly out of scope: incremental patches only per the ticket's "no full layout rewrite" rule.
- **TutorRail expand-to-fullscreen on tap of a message** — out of scope.
- **TopBar mobile hamburger menu** to restore Catalog/Blog/Tutor nav links on phones — out of scope; flag as KOE-100 candidate. (Without it, mobile users navigate via the home page or the search button.)
- **Lighthouse / Web Vitals optimization** — out of scope.

## Verification (QA Verifier checks these after Executor lands)

For each fix, on a deployed preview, check the listed viewports in Chrome DevTools device toolbar:

- [ ] **Fix 1**: 375px, `/`, `<nav>` not visible inside `.topbar` (Inspect → computed `display: none`).
- [ ] **Fix 2**: 375px, `/catalog`, exactly 1 course card per row; document.scrollWidth ≤ 375.
- [ ] **Fix 3**: 375px, `/learn/<slug>`, tap the bottom 56px sheet; height transitions to 75vh; collapse button restores 56px. Same on `/blog/<slug>`.
- [ ] **Fix 4**: 320px, `/`, the meta-info row wraps to 2+ lines; document.scrollWidth ≤ 320.
- [ ] **Fix 5**: 375px, `/learn/<slug>`, "Chapter N of M" disclosure visible above H1; tap to expand reveals all chapters; anchor links scroll within page.
- [ ] **Fix 6**: 375px, `/blog/<slug>`, scrolling past article body reveals "What you'll learn" + "Sources" footer.
- [ ] **Fix 7**: 750px (synthetic), `/`, prose is 16px, main padding 20×16, topbar nav hidden. 769px restores desktop.
- [ ] **Fix 8**: 375px, `/tutor`, conversation occupies full viewport; composer pinned at bottom; sidebars hidden. 768px same. 1024px shows all 3 columns.
- [ ] **Fix 9**: 768px, `/`, topbar fits on one line; nav hidden, kbd hidden, anonymous chip hidden, only Logo + search + DarkToggle visible.
- [ ] **Fix 10**: any page, Tab key focuses skip-link; Enter; focus moves to `<main id="main">` content.
- [ ] **Fix 11**: 320px, `/`, only K-square logo visible (no "Koenig AI Academy" wordmark); search placeholder readable.
- [ ] **Fix 12**: 320px, `/learn/<slug>`, none of the three flex rows (back-link, mark-complete, RunPromptCell toolbar) overflow horizontally.
- [ ] **Fix 13**: 320px, `/blog/<slug>`, header chips wrap below back link; no overflow.

Global regression check — at 1024px+, all pages render identical to current desktop. Run `pnpm --filter learnova-academy build && pnpm --filter learnova-academy start` and spot-check Home + Lesson + Blog post.

## Risk

- **Risk:** Fix 7 (breakpoint unification 720 → 768) could regress edge styling at the 721–768 window where some rules were intentionally desktop. Mitigation: I read every rule in the 720 block — all are mobile-correct at 768. The change is monotonic (more-mobile applies to more devices, never less).
- **Risk:** Fix 5/6 disclose-on-mobile blocks add server-rendered DOM to every lesson/blog page. Page weight ~150 bytes per chapter — negligible.
- **Risk:** Fix 8 hides /tutor sidebars on mobile; loses functionality (history, suggestions). Acceptable for V1 since the chat is the primary surface; out-of-scope hamburger ticket should restore them.

## Files Executor will touch

| File | Fixes |
|------|-------|
| `learnova-academy/src/app/academy.css` | 1, 2, 5, 6, 7, 8, 9, 11 |
| `learnova-academy/src/app/page.tsx` | 4 |
| `learnova-academy/src/app/catalog/page.tsx` | 2, 10 |
| `learnova-academy/src/app/blog/page.tsx` | 10 |
| `learnova-academy/src/app/blog/[slug]/page.tsx` | 3, 6, 10, 13 |
| `learnova-academy/src/app/learn/[slug]/page.tsx` | 3, 5, 10, 12 |
| `learnova-academy/src/app/glossary/page.tsx` | 10 |
| `learnova-academy/src/app/glossary/[slug]/page.tsx` | 10 |
| `learnova-academy/src/app/capabilities/page.tsx` | 10 |
| `learnova-academy/src/app/capabilities/[vendor]/page.tsx` | 10 |
| `learnova-academy/src/app/capabilities/[vendor]/[feature]/page.tsx` | 10 |
| `learnova-academy/src/app/authors/page.tsx` | 10 |
| `learnova-academy/src/app/authors/[slug]/page.tsx` | 10 |
| `learnova-academy/src/app/tutor/page.tsx` | 8, 10 |
| `learnova-academy/src/components/_shared/chrome.tsx` | (none — Fix 11 is CSS-only) |
| `learnova-academy/src/components/_shared/tutor.tsx` | 3 |
| `learnova-academy/src/components/_shared/content.tsx` | 12 |

**Net delta**: ~120 LOC across 17 files. Mostly CSS additions + tiny JSX `flexWrap`/`id` additions. Two new client-side wrappers (`TutorSheetWrapper`, `<details>` chapter disclosure). No new dependencies.

## Branch & PR

Branch from `academy/main` (per parent KOE-96 plan):
```
git checkout -b koe-96/mobile-comprehensive-stage2
```
Single PR titled `[KOE-96] fix(academy): mobile comprehensive pass — 13 fixes` linking back to this audit at `vault/decisions/KOE-97-plan.md`.

## Handoff

Stage-1 is complete. Chief Engineering should review this audit, decide if any fixes are out-of-scope for the immediate KOE-96 round, and dispatch Stage-2 (Executor) with the approved subset.
