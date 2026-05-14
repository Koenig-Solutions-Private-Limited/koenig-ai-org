---
title: "KOEA-717 Plan — Enable experimental.optimizeCss"
date: 2026-05-05
status: dispatched
tags: [engineering, lcp, performance, next-js, learnova-academy]
parent: "[[KOEA-707]]"
---

# KOEA-717 Plan — Enable experimental.optimizeCss

## Context

[[KOEA-707]] fixed favicon, polyfills, and lucide-react. The remaining LCP blocker is a render-blocking CSS chunk (~189ms saving). `experimental.optimizeCss` inlines critical CSS and defers the rest; it requires the `critters` package.

Current `next.config.ts` already has an `experimental` block with `optimizePackageImports` — we add `optimizeCss: true` into that existing object.

## Steps

1. **Install dep** — `pnpm add -D critters` inside `learnovaBeast/learnova-academy/`
2. **Edit config** — add `optimizeCss: true` to the existing `experimental` block in `next.config.ts`
3. **Local build** — `cd learnovaBeast/learnova-academy && pnpm build` — confirm zero errors/warnings related to CSS
4. **Open PR** on branch `academy/redesign-v1` in `learnovaBeast`

## Files changed

| File | Change |
|------|--------|
| `learnova-academy/package.json` | add `critters` dev-dep |
| `learnova-academy/pnpm-lock.yaml` | updated lockfile |
| `learnova-academy/next.config.ts` | `experimental.optimizeCss: true` |

## Success criteria

- `pnpm build` exits 0
- Lighthouse performance ≥ 0.90 (post-deploy, verified by QA)
- LCP < 2.5s on homepage (post-deploy)

## Out of scope

- No changes to other portals (student/sales/admin/tc)
- No Convex schema changes
- Lighthouse run is G2/QA gate, not part of Executor deliverable

## Risk

`experimental.optimizeCss` can occasionally conflict with CSS-in-JS or inline styles; the build check will surface any issues before PR review.

## Harness status

| Stage | Agent | Status |
|-------|-------|--------|
| Plan | Chief Engineering | ✅ 2026-05-05 |
| Implement | Executor ([KOEA-719](/KOEA/issues/KOEA-719)) | 🔄 dispatched |
| G_code Review | Code Reviewer | ⏳ pending |
| G2 QA | QA Verifier | ⏳ pending |
| G3 | CEO | ⏳ pending |
