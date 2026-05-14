---
ticket: KOEA-1833
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.36
base_branch: academy/redesign-v1
basebranch_verified: true
preflight_note: "Chief Engineering comment b75970bd superseded planner_chain_alert dafbfbb5 and authorized the KOEA-1833 -> KOEA-1836 chain."
---

# Plan: Unblock KOEA-1815 G2 lint and browser verification

## Goal
Unblock KOEA-1815 by removing the live Learnova Academy lint failure and giving QA a concrete, authenticated browser walkthrough path. Success means G2 can rerun without using a lint `qa_scope_exception`, without depending on unavailable `browser-use`, and without requiring Paperclip-core code changes.

## Context
- Files to read first: `learnova-academy/src/components/GlossaryPopover.tsx:31-54`, `learnova-academy/package.json:5-12`, `learnova-academy/README.md:3-18`, `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md:11-39`, `scripts/screenshot.cjs:1-84`, `doc/DEPLOYMENT-MODES.md:27-55`.
- Relevant prior work: KOEA-1815 G2 comments `9114b033`, `b2909ca0`, and `266a3c8d` identify the same three blockers; runtime/env approval `50e50e49-27fd-4a7b-a82d-2c4d0a5623fc` remains pending; Chief Engineering comment `b75970bd-3bf5-484e-adc3-44d82fb3fd5b` authorizes this chain to continue.
- Constraints: Do not modify code in this planner ticket. Learnova implementation should target `academy/redesign-v1`, verified to exist on origin. Academy is anonymous-by-default, so the authenticated-board walkthrough belongs to Paperclip, not Learnova Academy. No Paperclip-core code change is planned.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Fix the lint defect and use existing browser fallback. Executor should change `GlossaryPopover` so cached glossary data is used without synchronous `setState` inside `useEffect`, then verify with `pnpm test`, `pnpm typecheck`, and `pnpm lint`. QA should use the existing Playwright/Chromium walkthrough skill for Academy UI checks because this runtime already has Playwright and `/usr/bin/chromium`, and should use `scripts/screenshot.cjs` for an authenticated Paperclip board smoke screenshot because it injects the stored board token from `~/.paperclip/auth.json`.

**Rejected**: Request a `qa_scope_exception` for the lint failure — this masks a small real React lint issue and QA already said the existing instability alert is not a scope exception; install or require `browser-use` before G2 — slower and unnecessary because the repo already documents Playwright as the Docker replacement; change Paperclip auth/core to create a new walkthrough path — too broad for this unblock and not needed for the current private authenticated instance.

## Steps (Executor follows in order)
1. In `learnovaBeast/learnova-academy/src/components/GlossaryPopover.tsx`, replace the synchronous cached-data `setData(cached)` effect path with a render-safe derived value or lazy initializer pattern, preserving fetch-on-open behavior and the `cache` map.
2. In the same component, keep the failed-fetch behavior as a null cache entry so missing glossary terms still fall back to a plain link and do not refetch on every hover.
3. Run `cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && pnpm test && pnpm typecheck && pnpm lint`; address only failures caused by the executor change.
4. Start the Academy app via the existing project command or managed workspace service, then run a Playwright script based on `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md` against `http://localhost:3010/learn/mcp-from-first-principles-to-production#ch-1` to confirm the page loads and the `[[glossary/mcp]]` link can reveal a Glossary tooltip.
5. From `koenig-ai-org`, verify the authenticated Paperclip board path with `node scripts/screenshot.cjs /KOEA/dashboard /tmp/koea-dashboard-auth.png --width 1280 --height 800 --wait 2000`; if `~/.paperclip/auth.json` is missing, block on Chief Engineering/operator to provide a board-authenticated browser session rather than changing app code.
6. Record in the handoff that no Paperclip-core code changes and no new board approvals are required; if QA still mandates `browser-use` despite the documented Playwright replacement, update pending runtime/env approval `50e50e49-27fd-4a7b-a82d-2c4d0a5623fc` instead of filing a duplicate approval.

## Verification (QA Verifier checks these)
- [ ] `cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && pnpm test && pnpm typecheck && pnpm lint` exits 0; warnings are acceptable only if ESLint exits 0.
- [ ] Playwright/Chromium walkthrough exits 0 for `/learn/mcp-from-first-principles-to-production#ch-1`, including a visible glossary tooltip after hover/focus on the MCP glossary link.
- [ ] Authenticated Paperclip board screenshot command exits 0 and produces `/tmp/koea-dashboard-auth.png` for `/KOEA/dashboard`.
- [ ] KOEA-1815 G2 rerun comment states exact commands used and confirms whether any remaining blocker is adapter recovery evidence rather than lint/browser environment.

## Risk
- The cache refactor could accidentally refetch glossary entries or hide a valid cached tooltip. Mitigate by checking one known glossary term (`mcp`) through the browser walkthrough and preserving `cache.set(slug, null)` for failed lookups.

## Out of scope
- Installing `browser-use`, changing QA Verifier policy, changing Paperclip authentication, or modifying Hermes/content-agent adapter code.

## Telemetry
- status_checked=true
- basebranch_verified=true
- chain_override_comment=b75970bd-3bf5-484e-adc3-44d82fb3fd5b
