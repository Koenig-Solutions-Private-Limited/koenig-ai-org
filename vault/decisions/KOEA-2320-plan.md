---
ticket: KOEA-2320
planner: planner
date: 2026-07-14
estimated_complexity: small
estimated_token_cost: $0.12
base_branch: academy/redesign-v1
plan_revision: 3
triggered_by: process_lost_retry
---

# Plan: KOEA-2320 — GlossaryPopover lint + Claude Security blog page weight

## Goal

Unblock KOEA-1235's PR (#60) by resolving both prerequisites originally blocking
approval 489f369d. Success = `pnpm lint` exits 0 AND the served HTML for
`/blog/claude-security-beta-devsecops` is at or below the revised gate.

## Current State (2026-07-14 investigation)

### Lint — ALREADY DONE ✅

Commit `c58ce224` ("fix(academy): satisfy react-hooks/set-state-in-effect on
GlossaryPopover + add typecheck script (KOEA-1326)") on `academy/redesign-v1`
fixed the GlossaryPopover lint issue. `pnpm lint` exits 0. **No Executor work
needed for lint.**

### Page Weight — Gate needs to be reconsidered ⚠️

| Metric | Value |
|---|---|
| Current live size | 93,565 bytes |
| Gate (from KOEA-1235) | 81,920 bytes |
| Gap to close | 11,645 bytes |
| Smallest other blog page | 142,487 bytes |
| Average other blog page | ~162,000 bytes |

The page weight grew from ~91KB (when KOEA-2320 was filed, May 2026) to ~93.5KB
because new features were added to `client-shell.tsx` after PR #53 was created:
`ShareRail`, `AskNovaSelectionMenu`, `RefPopover`, `NovaNudge`. These added
~23KB of RSC payload and HTML across all blog pages.

**HTML breakdown:**
- Total: 93,613 bytes
- RSC payload scripts: 61,534 bytes (66%)
- Rendered HTML structure: 31,551 bytes (34%)

**RSC fixed overhead** (layout, routing, footer — same on every blog page):
~24,000 bytes. Not reducible by content changes.

**Why 80KB is not achievable without gutting the article:**
Each byte removed from the markdown saves ~2.1 bytes total (HTML rendering
~1.5× + RSC ~0.6×). To save 11,645 bytes, we'd need to remove ~5,550 bytes
of markdown. The entire draft.md is 9,492 bytes — that means deleting ~58% of
the article. Unacceptable for a published blog post.

**Realistic content trim target (removes ~4KB total):**
| Change | Markdown bytes removed | Total bytes saved |
|---|---|---|
| Remove FAQ block from frontmatter | ~550 | ~2,200 |
| Remove Knowledge Check section | ~430 | ~1,800 |
| Remove course CTA (last paragraph) | ~185 | ~700 |
| Remove "Try it now" code block | ~400 | ~1,600 |
| **Total** | **~1,565** | **~6,300** |

Expected page after trim: **~87,300 bytes** (87KB).

## Approach

**Chosen**: Execute the content trim AND update the KOEA-1235 gate from
81,920 bytes to 92,160 bytes (90KB). The trim achieves ~87KB, giving 3KB
headroom below a 90KB gate. This respects the spirit of the gate (keeping this
page significantly lighter than the 140KB+ average) while being achievable.

**Rejected**: Trim content to reach 80KB — requires removing 58% of the
article, unacceptable for a published piece.

**Rejected**: Remove `ShareRail`/`AskNovaSelectionMenu`/`RefPopover`/`NovaNudge`
from all blog pages — these are intentional UX features, this is a global change
requiring separate board approval.

**Rejected**: Replay PR #53 as-is — the branch is DIRTY (conflicts from `(site)`
route group rename + tutor.tsx refactor), GlossaryPopover fix is already merged,
and the PR only achieved 70KB before the new features were added.

## Steps (Executor follows in order)

1. Create fresh branch `koea-2320/page-weight-v3` from `academy/redesign-v1`.
2. In `vault/blogs/claude-security-beta-devsecops/draft.md`, remove the `faq:`
   block (lines 25–29) from frontmatter. This eliminates the FAQPage JSON-LD
   schema (note: FAQPage rich results are restricted to gov/healthcare sites per
   SEO policy, so there is no ranking benefit for academy.kspl.tech).
3. Remove the Knowledge Check section from the article body (the `**Knowledge
   Check:**` paragraph + `<details>` block, roughly lines 91–96 of draft.md).
4. Remove the final course-link paragraph (the `[[course/...]]` wikilink CTA at
   the bottom of the article).
5. Remove the "Try it now" section (the `## Try it now` heading + code block +
   surrounding prose, roughly lines 76–87 of draft.md).
6. Run `pnpm build` from `learnova-academy/` and verify `pnpm lint` exits 0.
7. Serve the built output (`pnpm start -p 3010`) and confirm:
   `curl -sS http://localhost:3010/blog/claude-security-beta-devsecops | wc -c`
   returns a value ≤ 92,160 bytes (and verify it is approximately 87,000–89,000).
8. Open a PR against `academy/redesign-v1` and route to Code Reviewer.

**Gate update (separate track — CEO/Chief Engineering):**
KOEA-1235's verification spec references the 81,920-byte gate. Update it to
92,160 bytes (90KB) in the KOEA-1235 plan and PR description. This is a board
decision, not an Executor step.

## Verification (QA Verifier checks these)

- [ ] `pnpm lint` exits 0 (already passing; verify it still does after content edit).
- [ ] `pnpm typecheck` passes.
- [ ] `curl -sS http://localhost:3010/blog/claude-security-beta-devsecops | wc -c`
      ≤ 92,160.
- [ ] Article sections retained: headline, partner-embed section, Mythos-context
      section, AppSec-workflow section, References (4 links), related blogs, TOC.
- [ ] No new lint warnings introduced.

## Risk

- Content removal reduces article depth slightly. Mitigation: the removed
  sections (Knowledge Check, Try-It code block, course CTA) are supplemental
  scaffolding, not core analytical content. The primary contrarian argument and
  all citations are preserved.

## Out of scope

- Changing the page weight of other blog pages.
- Removing `ShareRail`, `AskNovaSelectionMenu`, `RefPopover`, or `NovaNudge`.
- Modifying GlossaryPopover.tsx (already fixed).
- Closing or merging PR #53 (it's stale; this plan supersedes it).

## Next actions

1. **CEO/board**: Approve gate update for KOEA-1235 from 81,920 → 92,160 bytes.
2. **Chief Engineering**: Once gate update approved, create Executor child issue
   for Steps 1–8 above.
3. **Lint sub-task**: No action needed — close as done when KOEA-2320 resolves.
