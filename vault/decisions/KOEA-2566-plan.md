---
ticket: KOEA-2566
planning_issue: KOEA-2572
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: "$0.35"
repo: learnovaBeast/learnova-academy
base_branch: academy/redesign-v1
basebranch_verified: true
source_ref: origin/academy/redesign-v1@94b4957e5063cda0af04f52f0b23422200e61409
---

# Plan: Fix Ask Nova `/tutor` 503 handling and fake demo fallback

## Goal
Make the standalone `/tutor` page use the real Nova tutor backend instead of silently appending hardcoded `(demo)` replies. Success means a submitted `/tutor` question either streams a real `/api/tutor` answer or shows a visible unavailable/error state; it must never present a fake answer as if Nova responded.

## Context
- Files to read first: `src/app/tutor/page.tsx:38-57`, `src/app/tutor/page.tsx:95-209`, `src/app/api/tutor/route.ts:59-132`, `src/components/_shared/tutor.tsx:94-153`, `src/app/learn/[slug]/page.tsx:97-102`, `src/app/learn/[slug]/client-shell.tsx:21-31`, `src/app/blog/[slug]/client-shell.tsx:21-31`, `src/app/llms-full.txt/route.ts:14-100`.
- Relevant prior work: the course/blog Nova widget already posts to `/api/tutor` with `{slug, type, title, body, history, message}` and streams NDJSON deltas. Course pages build one concatenated grounding body from outline + chapters before mounting the widget. Blog pages let the widget derive body text from the rendered article.
- Current diagnosis: the fix primarily belongs in the standalone `/tutor` route/page and a tiny shared Nova client helper, not in Convex or a new backend. On `academy/redesign-v1`, `/tutor/page.tsx` still uses a local `SEED` transcript plus `setTimeout()` to append a fake `(demo)` answer. The API route already exists and returns `503` only when `ANTHROPIC_API_KEY` is absent; the working course-page widget proves `/api/tutor` is the current backend contract.
- Constraints: the requested checkout `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-fe-agent/learnova-academy` was still absent during planning. I read the current target branch from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` using `git show origin/academy/redesign-v1:<path>` without changing that worktree. Executor should implement from an unlocked checkout on `academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Wire `/tutor` to the same `/api/tutor` streaming contract used by the course/blog Nova widget, with an explicit unavailable state. Convert the standalone tutor route from a fake client-only demo into a server/client pair: the server page prepares a bounded "Koenig AI Academy" grounding body from existing publishable course/blog corpus helpers, and the client sends the same payload shape to `/api/tutor`, consumes NDJSON deltas, and renders 503/502/429 errors visibly.

**Rejected**: Only configure `ANTHROPIC_API_KEY` in production - that may be necessary, but it does not remove the fake `(demo)` fallback in source. **Rejected**: Build Convex/vector retrieval now - the existing working widget proves `/api/tutor` is the current backend contract, and retrieval is larger than this incident fix.

## Steps (Executor follows in order)
1. Prepare an unlocked `learnovaBeast/learnova-academy` checkout on `academy/redesign-v1`, verify `git status --short`, and keep changes scoped to the academy app.
2. In `src/app/tutor/page.tsx`, remove `SEED`, mock history labels, and the `setTimeout()` `(demo)` reply path; split the interactive conversation into a client component if needed so the page can load server-side grounding data.
3. Add a small server-side grounding builder for `/tutor` that reuses `listPublishableCourses()` and `listPublishableBlogs()` from the same sources as `src/app/llms-full.txt/route.ts`, but caps output to concise course/blog titles, summaries, outcomes, and chapter headings rather than dumping the full corpus.
4. In the `/tutor` client flow, POST to `/api/tutor` with `slug`, `type`, `title`, `body`, `history`, and `message`. Prefer `slug: "site"` and `title: "Koenig AI Academy"`; if TypeScript requires it, extend `src/app/api/tutor/route.ts` from `type: "blog" | "course"` to include `"site"` and adjust the system prompt wording.
5. Implement visible unavailable/error UI in `/tutor`: show the server JSON error for `503`, `502`, and `429`, keep the user's message in history, clear the pending state, and do not synthesize an assistant answer.
6. Keep the course/blog `TutorRail` behavior intact. If the `/tutor` wiring duplicates more than a few lines, extract only the fetch/NDJSON parsing into a small shared client helper under `src/components/_shared/` or `src/lib/`; do not redesign the floating widget UI.
7. Add only narrow comments or README notes if needed to clarify that Nova depends on `ANTHROPIC_API_KEY` and must fail visibly when that key or upstream Anthropic is unavailable.

## Verification (QA Verifier checks these)
- [ ] From `learnova-academy/`, run `pnpm typecheck`.
- [ ] With `ANTHROPIC_API_KEY` absent, run the app locally and `curl -i -X POST http://localhost:3010/api/tutor -H 'content-type: application/json' --data '{"slug":"site","type":"site","title":"Koenig AI Academy","body":"Academy overview","history":[],"message":"ping"}'`; verify JSON `503` is returned and `/tutor` displays a visible unavailable/error message, not a `(demo)` answer.
- [ ] With a valid `ANTHROPIC_API_KEY` in local env or staging, submit a question on `/tutor`; verify Network shows `POST /api/tutor` returning `200` with streamed NDJSON and the UI displays the real streamed answer.
- [ ] Browser walkthrough `/tutor`: send from the text box and suggestion buttons, verify pending/disabled states clear correctly, and confirm no rendered text contains `(demo)` or fake Convex/vector-index language.
- [ ] Regression walkthrough on a course page such as `/learn/mcp-from-first-principles-to-production`: open the bottom-right Nova widget, ask a grounded question, and verify it still streams and cites normally.

## Risk
- A broad academy grounding body could make `/tutor` requests large or slow. Mitigate by capping the generated body and using concise course/blog metadata first; leave full retrieval/vector search out of this ticket.
- If production truly lacks `ANTHROPIC_API_KEY`, the user-facing result after this fix will still be an unavailable state until the deployment secret is restored. That is acceptable for this ticket because the fake answer must be removed even when the backend is down.

## Out of scope
- Building Convex vector search, semantic retrieval, or persistent chat history.
- Redesigning the `/tutor` page layout beyond the states required to remove fake answers.
- Production deployment or secret management beyond identifying that `ANTHROPIC_API_KEY` is required.
