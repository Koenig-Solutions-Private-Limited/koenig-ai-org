---
ticket: KOEA-6729
agent: Executor
author: operator (Claude Code, V7 SEO/GEO)
date: 2026-05-29
phase: implementation
estimated_minutes: 30
priority: blocks-KOEA-5815-ranking
---

# KOEA-6729 plan — /tutor LCP 2.57s → <2.5s

## Goal

Shave 70ms+ off LCP on `https://academy.kspl.tech/tutor`. Currently 2.57s (per QA Verifier G2 BLOCK on KOEA-6710 at 08:18Z). Target <2.5s. **This is the SOLE blocker for the entire SEO PR #70 → KOEA-5815 ranking ticket chain.**

## Diagnosis

`learnova-academy/src/app/tutor/page.tsx`:
- `"use client"` at top — whole page is client-rendered → no SSR HTML for LCP element
- 4-turn `SEED` conversation array renders synchronously on first paint
- Uses Source Serif 4 + Inter + JetBrains Mono via next/font/google (3 font loads)
- `NovaAvatar` custom SVG renders per nova turn
- TopBar + 240px History sidebar + 240px right rail (3-column grid)

LCP element on /tutor is likely the first conversation card (`Three options, cheapest first:...`) — it's the largest text block above the fold.

## Procedure

### Phase A — preload primary font (3 min)

`learnova-academy/src/app/layout.tsx`:
```tsx
import { Inter, Source_Serif_4, JetBrains_Mono } from "next/font/google";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter", display: "swap", preload: true });
const sourceSerif = Source_Serif_4({ subsets: ["latin"], variable: "--font-source-serif-4", display: "swap", preload: true });
const jetbrainsMono = JetBrains_Mono({ subsets: ["latin"], variable: "--font-jetbrains-mono", display: "swap", preload: false });  // ← only used in code blocks, not /tutor
```

Setting `preload: false` on JetBrains Mono saves ~30–50ms on /tutor (not used on this page).

### Phase B — defer SEED rendering after first paint (10 min)

Add a minimal SSR shell at `/tutor` (server component) + isolate the interactive part:

Split `learnova-academy/src/app/tutor/page.tsx` into:
- `tutor/page.tsx` (server component) — renders chrome (TopBar + History sidebar + RightRail). Reserves space for the conversation card.
- `tutor/TutorConversation.tsx` (client component) — useState for `turns`, `draft`, `send`. Renders SEED after mount.

This pushes LCP to the chrome content (faster to render) instead of the conversation card.

Acceptable tradeoff: initial paint shows an empty conversation pane for ~50ms, then fills with SEED. Per `[stance:voice-answer-first]`, the answer-first approach is OK because the chrome already shows "Ask Nova".

### Phase C — trim SEED to 2 turns (2 min)

`learnova-academy/src/app/tutor/page.tsx` (or the new TutorConversation):
```tsx
const SEED: Turn[] = [
  { who: "user", text: "What's the cheapest way to add memory to a Claude agent?" },
  {
    who: "nova",
    text: "Three options, cheapest first: (1) Append-only conversation log in your DB...",
    cite: "From: courses/claude-tool-use-from-zero · Chapter 6",
  },
];
```

Smaller initial DOM = faster LCP.

### Phase D — verify locally + open PR (10 min)

```bash
cd /tmp/koea-6710-pr70-g2/learnova-academy  # the QA workspace
git checkout -b koea-6729/tutor-lcp-fix
# Apply patches above
pnpm typecheck
pnpm build
# Local Lighthouse:
npx @lhci/cli@latest autorun --collect.url="http://localhost:3010/tutor" --collect.numberOfRuns=3 --upload.target=temporary-public-storage
# Expect LCP ≤ 2.45s
git add . && git commit -m "perf(tutor): defer SEED rendering + preload only essential fonts (KOEA-6729)"
git push origin koea-6729/tutor-lcp-fix
gh pr create --title "[KOEA-6729] /tutor LCP fix (unblocks KOEA-6710 G2 → KOEA-5815)" --base academy/redesign-v1
```

### Phase E — auto-resume QA on KOEA-6710 (5 min)

Post a comment on KOEA-6710:
```
Fix shipped via KOEA-6729 PR #XXX. Re-run G2 after PR head SHA changes.
```

QA Verifier re-G2s. If LCP passes → KOEA-6710 done → cascade unblocks KOEA-6708/6004/5834/5815.

## Acceptance

- [ ] /tutor LCP < 2.5s on Lighthouse (3-run median, desktop preset)
- [ ] All other Core Web Vitals (CLS, INP) within current pass thresholds
- [ ] No visual regression vs current /tutor (TopBar + History + conversation panel all render)
- [ ] No accessibility regression (screen reader still sees "Ask Nova — your AI tutor" h1)
- [ ] PR opened + KOEA-6710 re-routed to QA

## Exit invariant

Executor exits `done` after PR opened. If a phase fails (e.g., split breaks types), exit `blocked` with unblock_owner=operator + specific blocker.

## Stance alignment

- `[stance:voice-answer-first]` defends — page chrome shows "Ask Nova" headline as first paint
- Page is the academy's flagship interactive entry — must be fast
