---
ticket: KOEA-7207
planning_issue: KOEA-7244
planner: planner
date: 2026-06-02
estimated_complexity: small
estimated_token_cost: $0.32
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Fix blog OG ImageResponse zero-byte output

## Goal
`/api/og?type=blog` and `/api/og?type=blog&title=Hello&accent=blue` should return normal `image/png` bodies instead of an empty response / render failure. Blog pages that lack frontmatter hero images should again use blog-specific OG cards in metadata, in-page heroes, and listing cards.

## Context
- Files to read first: `learnova-academy/src/app/api/og/route.tsx:35-135`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:47-73`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:133-150`, `learnova-academy/src/app/(site)/blog/page.tsx:23-33`, `learnova-academy/src/lib/seo.ts:36-42`
- Relevant prior work: V7 SEO/GEO Phase 1 added query-aware `/api/og`; current workaround avoids `type=blog` by using `?slug=...` or `?title=...` blog fallbacks.
- Constraints: target `learnovaBeast` branch `academy/redesign-v1`; Academy/public website only; no Convex deploy; do not disturb unrelated current worktree changes.
- Reproduction: with `learnova-academy` dev server on port 3010, default and title variants returned valid PNGs (`72733` and `52622` bytes). Blog variants failed with `Invalid value for CSS property "display"... Received: "inline-flex"` from the kicker element in `ImageResponse`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Keep the existing OG card structure and replace the kicker element's unsupported `display: "inline-flex"` with an `ImageResponse`-supported display value, then restore blog-specific fallback URLs through a small `blogOgImagePath(title)` helper parallel to `courseOgImagePath()`. This is the smallest fix: it addresses the actual renderer failure and keeps blog URL construction consistent across metadata, in-page hero image, and blog listing cards.

**Rejected**: Remove the blog kicker or force `type=default` for blog pages — hides the bug and fails the requested `type=blog` restoration. **Rejected**: Rewrite the OG card rendering/layout — unnecessary for a one-property ImageResponse incompatibility and increases regression risk across course/glossary/hub cards.

## Steps (Executor follows in order)
1. Checkout/update `learnovaBeast` on `academy/redesign-v1` and confirm the working tree before editing, preserving any unrelated user changes.
2. Edit `learnova-academy/src/app/api/og/route.tsx` so the kicker label uses an `ImageResponse`-supported display value such as `display: "flex"` while preserving the current alignment, padding, color, and typography.
3. Add `blogOgImagePath(title: string): string` in `learnova-academy/src/lib/seo.ts` using `URLSearchParams({ type: "blog", title, accent: "blue" })`, mirroring the existing course OG helper style.
4. Update `learnova-academy/src/app/(site)/blog/[slug]/page.tsx` to import/use `blogOgImagePath(post.title)` for the fallback `heroUrl`, in-page fallback image `src`, and JSON-LD `imageUrl` fallback where appropriate.
5. Update `learnova-academy/src/app/(site)/blog/page.tsx` to use `blogOgImagePath(post.title)` for listing card fallback heroes instead of `?slug=...`.
6. Keep explicit `post.hero_image?.url` precedence unchanged everywhere and leave non-blog OG consumers untouched.

## Verification (QA Verifier checks these)
- [ ] `cd learnova-academy && pnpm dev`, then `curl -sS -o /tmp/og-blog.png -w '%{http_code} %{size_download} %{content_type}\n' 'http://localhost:3010/api/og?type=blog&title=Hello&accent=blue'` returns `200`, `image/png`, and roughly `50000-100000` bytes.
- [ ] While the dev server is running, `curl -sS -o /tmp/og-course.png -w '%{http_code} %{size_download} %{content_type}\n' 'http://localhost:3010/api/og?type=course&title=Hello'` also returns a non-empty PNG, proving the shared kicker path is not regressed.
- [ ] Server logs contain no `failed to pipe response` or `Invalid value for CSS property "display"` after the OG curls.
- [ ] `curl -sS 'http://localhost:3010/blog/2026-05-13-claude-skills-vs-mcp' | rg '/api/og\\?type=blog'` finds the restored blog-specific fallback URL in rendered metadata/page HTML.
- [ ] `cd learnova-academy && pnpm typecheck` passes.

## Risk
- Changing the kicker display affects every typed OG card, not only blog. Mitigation: smoke-test at least blog and course typed URLs, plus default/title variants if time allows.

## Out of scope
- Redesigning the OG image, adding a full OG test harness, deploying Convex, or changing non-Academy portals.
