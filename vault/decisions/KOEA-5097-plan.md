---
ticket: KOEA-5097
planner_ticket: KOEA-5786
planner: planner
date: 2026-05-27
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: "koenig-ai-org origin/master; learnovaBeast origin/academy/redesign-v1 + origin/main verified"
triggered_by_approval: cbe18eeb-74a9-45a8-8833-8048245de7f9
---

# Plan: recover KOEA-5097 publish QA blockers

## Goal

Unblock KOEA-1321 by resolving the three remaining KOEA-5097 blockers without inventing course content or bypassing gates. Success means the secure-coding route expectation is explicitly aligned to the current vault state, a fresh KOEA-256 `repository_dispatch` run succeeds after the OOM workflow fix, and G2 can run the required browser-use gate instead of falling back to Playwright.

## Context

- Files to read first: `learnovaBeast/learnova-academy/src/app/learn/[slug]/page.tsx:42`, `learnovaBeast/learnova-academy/src/lib/courses.ts:209`, `learnovaBeast/.github/workflows/publish.yml:45`, `scripts/publish-action.sh:343`, `scripts/publish-action.sh:428`, `companies/learnova-academy/agents/qa-verifier/AGENTS.md:26`, `companies/learnova-academy/skills/qa-verify-task/SKILL.md:47`.
- Relevant prior work: learnovaBeast PR #27 fixed typecheck/lint blockers; PR #28 promoted the publish OOM workflow fix to `main`; KOEA-1326 final comment says V7/V8 passed for a non-secure-coding dispatch.
- Current state: `origin/main` workflow already has `NODE_OPTIONS: --max-old-space-size=6144`; `vault/courses/secure-coding/outline.md` is absent; `vault/courses/secure-coding-with-claude/draft.md` exists but is not a route-generating course outline.
- Constraints: do not create placeholder content routes; do not publish manually from koenig-ai-org runtime; preserve the dirty local worktree by using clean temporary worktrees; route Executor -> G_code -> G2 after this plan.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Contract alignment plus dispatch replay. Executor should make a small koenig-ai-org instruction/skill PR that teaches QA to put `/paperclip/.local/bin` on `PATH` before invoking `browser-use`, and to derive course route checks from real `vault/courses/<slug>/outline.md` files instead of stale issue metadata. Separately, Executor should trigger one fresh learnovaBeast `repository_dispatch` for KOEA-256's issue id and collect run evidence; no learnova app code change is planned unless the route existence check contradicts the current vault state.

**Rejected**: Create `/learn/secure-coding` as an alias or placeholder route, because the app generates routes from `outline.md` and no such course exists. Rejected: rerun G2 without updating the QA contract, because it will repeat the same `/learn/secure-coding` and browser-use blockers. Rejected: add browser-use as a learnova dependency, because the failure is QA runtime `PATH`, not academy app code.

## Steps (Executor follows in order)

1. Create a clean koenig-ai-org worktree from `origin/master`, branch `koea-5097/qa-contract-runtime`; do not reuse the dirty primary worktree.
2. Edit `companies/learnova-academy/agents/qa-verifier/AGENTS.md` and `companies/learnova-academy/skills/qa-verify-task/SKILL.md` only: add the browser-use preflight `export PATH=/paperclip/.local/bin:$PATH && browser-use --help`, and state that `/learn/<slug>` checks require `vault/courses/<slug>/outline.md`; if absent, QA records route expectation aligned/out-of-scope instead of blocking on that slug.
3. Verify and open a koenig-ai-org PR to `master`; evidence must include `git diff --name-only origin/master...HEAD` with exactly those two files and `PATH=/paperclip/.local/bin:$PATH browser-use --help` returning usage text.
4. In a clean learnovaBeast worktree, verify no route-code change is needed: `test ! -f ../koenig-ai-org/vault/courses/secure-coding/outline.md`, `test -f ../koenig-ai-org/vault/courses/secure-coding-with-claude/draft.md`, and `gh workflow view publish.yml -R Koenig-Solutions-Private-Limited/learnovaBeast --ref main --yaml | grep -n "NODE_OPTIONS: --max-old-space-size=6144"`.
5. Trigger the required KOEA-256 dispatch through GitHub Actions, not local Vercel: `gh api repos/Koenig-Solutions-Private-Limited/learnovaBeast/dispatches --method POST -f event_type=publish-ready -f client_payload[issue_id]=781ec769-d5e1-4239-b376-e465a49bdb14 -f client_payload[slug]=secure-coding`, then watch the resulting `publish-781ec769-d5e1-4239-b376-e465a49bdb14` run to `conclusion=success`.
6. Comment on KOEA-5097 with the PR URL, route-contract evidence, dispatch run URL, and browser-use preflight output; move the implementation through G_code, then G2 must rerun with browser-use and the corrected route contract before KOEA-1321 is unblocked.

## Verification (QA Verifier checks these)

- [ ] koenig-ai-org PR changes exactly `companies/learnova-academy/agents/qa-verifier/AGENTS.md` and `companies/learnova-academy/skills/qa-verify-task/SKILL.md`.
- [ ] `PATH=/paperclip/.local/bin:$PATH browser-use --help` succeeds in the QA runtime and G2 uses browser-use, not Playwright fallback.
- [ ] `vault/courses/secure-coding/outline.md` is absent, so `/learn/secure-coding` is not a valid route expectation for this recovery; the aligned contract is recorded on KOEA-5097/KOEA-1321.
- [ ] `gh workflow view publish.yml --ref main` shows `NODE_OPTIONS: --max-old-space-size=6144` under Deploy.
- [ ] A fresh post-plan run named `publish-781ec769-d5e1-4239-b376-e465a49bdb14` completes with `conclusion=success`.
- [ ] G_code approves the koenig-ai-org PR before G2 reruns KOEA-1321.

## Risk

- The direct `repository_dispatch` can publish the whole current academy site, not just KOEA-256. Mitigation: use the existing GitHub workflow only, make no content mutations in this plan, and require G2 to smoke Home, Catalog, one untouched lesson, and the dispatch run logs.

## Out of scope

- Authoring, renaming, or promoting a real secure-coding course outline; changing KOEA-256 metadata by direct database mutation; changing learnovaBeast route code; changing the publish-action state machine; G5 publish verification.
