---
ticket: KOEA-2335
source_ticket: KOEA-2321
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
---

# Plan: Fix slide auditor artifact discovery and recovery handoff

## Goal
The slide fake-done auditor should stop treating real `.pptx` artifacts in active Paperclip workspaces as missing, and it should stop attempting unsupported peer-agent issue mutations. Success means the auditor can find recovered slide files under both `koenig-ai-org-*` and `learnovaBeast-*` workspaces, creates at most one recovery handoff per affected slide ticket, and routes any status/metadata repair through the source issue owner or Chief Engineering instead of relying on `docker exec` or forbidden PATCH calls.

## Context
- Files to read first: `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md:94-253`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/server/src/routes/issues.ts:563-624`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:390-450`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/watchdog/watchdog.mjs:1-340`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/doc/execution-semantics.md:291-299`.
- Relevant prior work: [KOEA-2321](/KOEA/issues/KOEA-2321) captured the false-positive recovery case for [KOEA-2263](/KOEA/issues/KOEA-2263); [KOEA-2334](/KOEA/issues/KOEA-2334) restored KOEA-2263 and verified artifacts at `/paperclip/instances/default/workspaces/koenig-ai-org-KOEA-2288/vault/courses/claude-tool-use-from-zero/ch06-slides.pptx` and `/paperclip/instances/default/workspaces/learnovaBeast-koea-2145/learnova-academy/public/courses/claude-tool-use-from-zero/ch06-slides.pptx`.
- Constraints: do not edit Paperclip core permission policy for this ticket; Watchdog Bot currently reports to Chief Engineering and has `canCreateAgents=false`, so peer mutations correctly return `403 Agent cannot mutate another agent's issue`; `docker exec paperclip-db psql` is not available in this runtime; `origin/master` exists and is the verified base for any repo changes.
- Pre-flight: status_verified=true, assignee_verified=true, sibling_count=0, spec_verified=true, basebranch_verified=true.

## Approach (1 chosen, alternatives rejected)
**Chosen**: patch the auditor contract in Watchdog Bot instructions to use broad workspace discovery plus owner-routed recovery handoffs. Replace the hardcoded four-path search with deterministic globs over `/paperclip/instances/default/workspaces/koenig-ai-org-*/vault/courses/<slug>` and `/paperclip/instances/default/workspaces/learnovaBeast-*/learnova-academy/public/courses/<slug>`, while preserving the current canonical paths first for predictable results. Change both missing-artifact and recovered-artifact actions from direct source-issue mutation to an idempotent recovery/action issue assigned to the source ticket assignee when possible, otherwise Chief Engineering, with exact artifact paths and requested status/metadata changes.

**Rejected**: grant Watchdog Bot broad `canCreateAgents` or add a new core permission for direct cross-agent mutation, because the existing route guard is intentionally least-privilege and this ticket can be fixed through supported workflow. **Rejected**: only append KOEA-2288 and learnovaBeast-koea-2145 to the current static list, because the next slide ticket will likely use another worktree and repeat the failure. **Rejected**: build a centralized artifact index now, because no such index exists in the current code path and it is broader than the immediate auditor recovery defect.

## Steps (Executor follows in order)
1. Update the active Watchdog Bot instruction file at `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md`, replacing Check 6 Step 2 and the V7 Phase L patch with one canonical artifact search contract that checks explicit canonical locations first, then dynamically searches matching `koenig-ai-org-*` and `learnovaBeast-*` workspaces for `${CHNUM}-slides*.pptx` above 1000 bytes.
2. In the same instruction section, update candidate selection so `done` tickets without `fake_done_audited=true` are audited for missing artifacts, and previously blocked/reverted tickets with `fake_done_audited=true` may enter the recovery path only when a matching artifact is found.
3. Replace all direct DB/PATCH repair instructions for source slide tickets with a supported handoff: create or update one idempotent Paperclip recovery issue titled `[Recovery] Restore <identifier> after slide artifact found` or `[Recovery] Verify missing slide artifact for <identifier>`, linked to the source issue, assigned to the source assignee when resolvable and otherwise Chief Engineering.
4. Define the recovery issue body template with the source issue id/identifier/title/status, discovered artifact paths or searched paths, exact requested mutation for the owner to perform, and a note that Watchdog Bot must not mutate another agent's issue directly.
5. Add idempotency rules to the instructions: before creating a recovery issue, query related/open issues or search by the deterministic recovery title; if one exists in `todo`, `in_progress`, `in_review`, or `blocked`, comment with any new artifact path instead of creating another issue.
6. Mirror the durable operator contract in the repo by adding a short Watchdog Bot operations note under `companies/learnova-academy/agents/watchdog-bot/AGENTS.md` if Chief Engineering wants repo-seeded agent instructions, or under `docs/runbook.md` if the active Paperclip instance file remains the only source of truth; do not touch `server/` unless Chief Engineering explicitly approves a core permission change.
7. Leave `watchdog/watchdog.mjs` unchanged unless Executor confirms the slide auditor has been moved into that daemon; current repo inspection found no slide auditor code there.

## Verification (QA Verifier checks these)
- [ ] `rg -n "koenig-ai-org-\\*|learnovaBeast-\\*|Restore <identifier>|Verify missing slide artifact|must not mutate another agent" /paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md` shows the new dynamic search and owner-routed handoff rules.
- [ ] A dry-run `find` for `claude-tool-use-from-zero/ch06` finds both known recovered files under `koenig-ai-org-KOEA-2288` and `learnovaBeast-koea-2145`.
- [ ] Creating or updating a recovery issue uses supported `POST /api/companies/{companyId}/issues` or `POST /api/issues/{id}/comments`; no auditor instruction tells Watchdog Bot to `PATCH /api/issues/<source>` or run `docker exec paperclip-db psql` for source issue repair.
- [ ] Re-running the idempotency search for KOEA-2263 would find the existing recovery work and would not create a second active recovery issue.

## Risk
- A workflow-only fix means the source slide ticket is repaired by an owner handoff, not instantly by Watchdog Bot. Mitigation: make recovery issues high priority, assign them to the source owner or Chief Engineering, include exact PATCH instructions, and keep the route guard intact unless a separate board-approved permission design is opened.

## Out of scope
- Adding Paperclip core mutation privileges, changing `server/src/routes/issues.ts`, building a centralized artifact index, rewriting `watchdog/watchdog.mjs`, changing Slide+Audio Producer generation logic, or modifying unrelated slide/course artifacts.

## Executor handoff
Use `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org` on base branch `master`; it was verified with `git ls-remote --heads origin master` on 2026-05-14. Keep the implementation focused on Watchdog Bot auditor instructions and the smallest repo mirror/runbook note needed for durability.
