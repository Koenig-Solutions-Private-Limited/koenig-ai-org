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
---

# Plan: Fix Ask Nova `/tutor` 503 handling and fake demo fallback

## Goal
Make the standalone `/tutor` page use the real Nova tutor backend instead of silently appending hardcoded `(demo)` replies. Success means a submitted `/tutor` question either streams a real `/api/tutor` answer or shows a visible unavailable/error state; it must never present a fake answer as if Nova responded.

## Context
- Files to read first: `src/app/tutor/page.tsx:38-57`, `src/app/tutor/page.tsx:95-209`, `src/app/api/tutor/route.ts:59-132`, `src/components/_shared/tutor.tsx:63-127`, `src/components/_shared/tutor.tsx:159-180`, `src/app/learn/[slug]/client-shell.tsx:27-33`, `src/app/blog/[slug]/client-shell.tsx:30-36`, `src/app/llms-full.txt/route.ts:14-100`.
- Relevant prior work: the course/blog Nova widget already posts to `/api/tutor` with `{slug, type, title, body, history, message}` and streams NDJSON deltas. The standalone `/tutor` page currently does not share that path; it uses a client-only `setTimeout()` stub and returns text beginning with `(demo)`.
- Current root cause: the fix primarily belongs in the standalone `/tutor` route/page, not in Convex. The API route legitimately returns `503` when `ANTHROPIC_API_KEY` is missing, and `TutorRail` already surfaces non-OK responses as message text. The standalone page bypasses this contract entirely, so users can see fake demo replies even when the backend is unavailable.
- Constraints: the requested `~/Documents/Paperclip/learnovaBeast-fe-agent/` worktree was not present during planning; Executor should create or lock it before editing. Base all work on `academy/redesign-v1`. Do not mutate the dirty `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` checkout used for read-only planning.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Wire `/tutor` to the same `/api/tutor` streaming contract used by the course/blog Nova widget, with explicit unavailable states. Convert the standalone tutor page from a fake client-only demo into a real client/server page pair: the server side prepares a general academy grounding body from existing publishable course/blog corpus helpers, and the client side sends the same payload shape to `/api/tutor`, consumes NDJSON deltas, and renders 503/502/429 errors visibly.

**Rejected**: Only configure `ANTHROPIC_API_KEY`; that may be necessary in deployment, but it does not remove the fake `(demo)` fallback in source. **Rejected**: Build a new Convex/vector retrieval path now; the existing working widget proves `/api/tutor` is the current backend contract, and adding retrieval is larger than this incident fix.

## Steps (Executor follows in order)
1. Prepare or create `~/Documents/Paperclip/learnovaBeast-fe-agent/` on `academy/redesign-v1`, verify `git status --short` is clean, and perform all implementation in `learnova-academy/`.
2. In `src/app/tutor/page.tsx`, remove the hardcoded `SEED` demo conversation and `setTimeout()` fake reply path; split the interactive UI into a client component if needed so the route can gather server-side grounding data.
3. Add a small server-side helper or inline builder for `/tutor` that creates a bounded "Koenig AI Academy" grounding body from existing `listPublishableCourses()` / `listPublishableBlogs()` data, reusing the same source of truth as `src/app/llms-full.txt/route.ts` without duplicating the whole corpus.
4. In the new `/tutor` client flow, POST to `/api/tutor` with the same request shape used by `TutorRail`: `slug`, `type`, `title`, `body`, `history`, and `message`. If the API type needs a broader standalone context, extend `src/app/api/tutor/route.ts` deliberately to accept `type: "site"` and update the system prompt wording.
5. Implement visible unavailable/error UI in `/tutor`: show the server's JSON error for `503`, `502`, and `429`, keep the user's message in history, stop the pending state, and do not synthesize an assistant answer. Remove all `(demo)` copy from the route.
6. Keep the course/blog `TutorRail` behavior intact. If duplication grows while wiring `/tutor`, extract only the fetch/NDJSON parsing into a tiny shared client helper; do not redesign the floating widget UI in this ticket.
7. Update local documentation or inline comments only where needed to clarify that `/tutor` depends on `ANTHROPIC_API_KEY` and should fail visibly when the key is absent.

## Verification (QA Verifier checks these)
- [ ] From `learnova-academy/`, run `pnpm typecheck`.
- [ ] With `ANTHROPIC_API_KEY` absent, run the app locally and `curl -i -X POST http://localhost:3010/api/tutor -H 'content-type: application/json' --data '{"slug":"site","type":"site","title":"Koenig AI Academy","body":"Academy overview","history":[],"message":"ping"}'`; verify a JSON `503` is returned and `/tutor` displays a visible unavailable/error message, not a `(demo)` answer.
- [ ] With a valid `ANTHROPIC_API_KEY` in the local environment or staging, submit a question on `/tutor`; verify Network shows `POST /api/tutor` returning `200` with streamed NDJSON and the UI displays the real streamed answer.
- [ ] Browser walkthrough `/tutor`: send from the text box and suggestion buttons, verify pending/disabled states clear correctly, and confirm no rendered text contains `(demo)` or fake Convex/vector-index language.
- [ ] Regression walkthrough on a course page such as `/learn/mcp-from-first-principles-to-production`: open the bottom-right Nova widget, ask a grounded question, and verify it still streams/cites normally.

## Risk
- Risk: a broad academy grounding body could make `/tutor` requests large or slow. Mitigation: bound the body to concise course/blog summaries first, cap the text before sending, and leave full retrieval/vector search out of scope for a separate task.

## Out of scope
- Building Convex vector search or persistent chat history.
- Redesigning the `/tutor` page layout beyond the states required to remove fake answers.
- Production deployment or secret management beyond identifying that `ANTHROPIC_API_KEY` is required.
