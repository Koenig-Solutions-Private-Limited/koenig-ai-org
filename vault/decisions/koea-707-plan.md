---
ticket: KOEA-707
plan_ticket: KOEA-710
exec_ticket: KOEA-712
planner: planner
date: 2026-05-05
estimated_complexity: small
estimated_token_cost: $0.30
branch: academy/redesign-v1
---

# Plan: Homepage LCP 4.8s → <2.5s + favicon 404 fix

## Goal

Bring `https://academy.kspl.tech/` Lighthouse performance score to ≥0.90 with LCP <2.5s, and eliminate the `favicon.ico` 404 console error on every page load. Wins come primarily from deferring non-critical client JS (the Cmd+K palette + tutor module) so the homepage hero paints before the tutor bundle hydrates.

## Context

- **Repo**: `learnovaBeast/learnova-academy/` (Next.js 16.0.8, React 19.2.1, Tailwind 4, App Router).
- **Files to read first**:
  - `src/app/layout.tsx:1-101` — root layout, mounts `SitePalette` (Cmd+K palette) + `BottomNav` globally.
  - `src/components/_shared/SitePalette.tsx:1-13` — thin wrapper that imports `CommandPalette` from `tutor.tsx`.
  - `src/components/_shared/tutor.tsx:1-30` — 801-line `"use client"` module containing `TutorRail`, `CommandPalette`, `usePalette`. **This is the unused-JS hotspot** — homepage doesn't need tutor chat or vault search until ⌘K is pressed.
  - `src/components/_shared/chrome.tsx:1-30` — `TopBar` + `BottomNav` (`"use client"`, used on every page).
  - `src/app/page.tsx:1-210` — homepage, mostly server components plus `<Script id="ld-home" strategy="beforeInteractive">` for JSON-LD.
  - `src/app/academy.css:1-80` — design tokens + `@import "tailwindcss"`. This is the `537bae671c8edd1c.css` chunk.
  - `next.config.ts:1-19` — currently only configures `images.remotePatterns`; no perf knobs.
  - `package.json:14-40` — no `browserslist` field → SWC ships legacy polyfills.
  - `public/` — only contains `courses/`; **no `favicon.ico`, `icon.svg`, or any app icon.**
- **Constraint**: Branch `academy/redesign-v1`, ≤4 files changed, ≤200 LOC. Budget $0.50 for Executor.
- **Prior work**: None for this perf pass. Layout was last touched to add `SitePalette` (wired Cmd+K sitewide) — that wiring is what regressed home LCP because tutor.tsx now ships with every page.

## Approach (1 chosen, alternatives rejected)

**Chosen: Lazy-load SitePalette + add icon files in `src/app/` + set `browserslist` to Baseline 2024.**

Use `next/dynamic` with `ssr: false` to defer the `SitePalette` (and transitively the `CommandPalette` + `tutor.tsx` module) so the bundle is split off from the home critical path and only loads after first paint or on ⌘K press. Add an `icon.svg` (and a fallback `icon.png` plus `apple-icon.png`) directly in `src/app/` — Next.js App Router auto-detects these and emits the correct `<link>` tags + serves `/favicon.ico` with no need for files in `public/`. Add a `browserslist` field to `package.json` targeting Baseline 2024 so SWC drops legacy polyfills (≈14 KB saving).

**Rejected**:
- *Move tutor logic to a separate route layout* — bigger blast radius (touches every `/learn` and `/blog` page); same JS still loads when those routes are first visited. Lazy-loading via `next/dynamic` achieves the same goal in one line.
- *Inline critical CSS via experimental `optimizeCss`* — Next 16 already inlines what it can; the `537bae671c8edd1c.css` render-blocking chunk shrinks naturally once tutor JS no longer pulls in tutor-only Tailwind utilities, and `optimizeCss` requires `critters` + risk of FOUC. Skip until a follow-up if perf score still misses 0.90.
- *Drop a literal `favicon.ico` into `public/`* — works, but App Router's `icon.{ico,svg,png}` convention in `src/app/` is the idiomatic Next 16 path, gives both light/dark SVG and apple-touch-icon, and matches the rest of the layout's metadata wiring.

## Steps (Executor follows in order)

1. **`learnovaBeast/learnova-academy/src/components/_shared/SitePalette.tsx`** — keep this file as-is (it's the `"use client"` boundary), but switch its `CommandPalette` import to a local `next/dynamic`-wrapped value with `ssr: false` so the tutor chunk is split. Example shape: replace `import { CommandPalette, usePalette } from "./tutor";` with `import { usePalette } from "./tutor";` and `const CommandPalette = dynamic(() => import("./tutor").then(m => m.CommandPalette), { ssr: false });`. Keep `usePalette` as a synchronous import (it's a tiny hook, not the chat surface).
2. **`learnovaBeast/learnova-academy/src/app/icon.svg`** — add a new SVG icon (≈2 KB) using the Koenig teal `#0d8a6b` brand color. A simple "K" mark or the existing logo glyph from `chrome.tsx` lifted out as standalone SVG is fine. Next 16 will auto-emit `<link rel="icon" type="image/svg+xml" href="/icon.svg?...">`.
3. **`learnovaBeast/learnova-academy/src/app/apple-icon.png`** — add a 180×180 PNG fallback for Safari/iOS. Render from the same SVG via any local tool (`sharp`, `rsvg-convert`, or even an online converter run locally). This also makes `/favicon.ico` resolve since Next derives it from the icon graph.
4. **`learnovaBeast/learnova-academy/package.json`** — add a top-level `"browserslist"` entry: `["chrome >= 109", "edge >= 109", "firefox >= 115", "safari >= 16"]` (rough Baseline 2024). This signals SWC to drop ES2020+ polyfills from the client bundle.
5. **Verify locally** — run `pnpm --filter learnova-academy build` and confirm: (a) the home `/` route's First Load JS shrinks (compare against `next build` summary before/after), (b) no `favicon.ico` 404 in dev server console at `pnpm --filter learnova-academy dev`, (c) the Cmd+K palette still opens (lazy-load works).

## Verification (QA Verifier checks these on KOEA-714)

- [ ] Lighthouse performance score on `/` ≥ 0.90 (mobile, throttled, single run from same vantage as KOEA-706).
- [ ] LCP on `/` < 2.5s.
- [ ] Browser devtools Network tab shows no 404 for `/favicon.ico` on any of `/`, `/catalog`, `/blog`, `/learn/<slug>`.
- [ ] Cmd+K (or `/` keyboard shortcut) still opens the command palette on `/` after lazy-load is in place.
- [ ] Tutor FAB on `/learn/<any-published-slug>` still functions (smoke check that the dynamic import path didn't break the non-palette tutor surfaces).

## Risk

- **Hydration/race risk on `next/dynamic({ ssr: false })`**: if a user mashes ⌘K within the first ~200 ms of page load, the palette may not yet be loaded. Mitigation: `usePalette` queues `open=true`; once the dynamic chunk resolves, `<CommandPalette open={open} />` renders. No data loss, just a one-frame delay. Acceptable for a power-user shortcut.

## Out of scope

- Inlining critical CSS via `experimental.optimizeCss` — file a follow-up ticket if score still misses 0.90 after this pass.
- Refactoring `tutor.tsx` itself (e.g., splitting `TutorRail` from `CommandPalette` into separate files) — possible win, but >200 LOC blast radius. Keep as future cleanup.
- Image optimization on `/courses/*` thumbnails — not on the homepage critical path per the audit.
- Convex / `/api/tutor` latency tuning — orthogonal to LCP.

## Handoff

Plan complete. Mark KOEA-710 `done`; KOEA-712 (Executor) auto-unblocks. Executor should branch off `academy/redesign-v1`, follow steps 1–4 above, and report bundle-size delta in the PR description.
