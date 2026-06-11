---
ticket: KOEA-6994
planner: planner
date: 2026-06-11
estimated_complexity: small
estimated_token_cost: $0.20
base_branch: master
---

# Plan: Require commit SHA and vault path in blog revision handoffs

## Goal
Every Blog Author revision handoff that wakes Content Reviewer includes a deterministic review target: the exact commit SHA on `origin/master`, the canonical `vault/blogs/<slug>/draft.md` path, and a short list of changed areas. Content Reviewer should be able to verify the submitted revision with `git show <sha> -- <path>` instead of searching vault history or repeating stale-heartbeat work.

## Context
- Files to read first: `companies/learnova-academy/agents/blog-author/AGENTS.md:127-153`, `companies/learnova-academy/skills/blog-write/SKILL.md:165-183`, `companies/learnova-academy/agents/blog-author/SOUL.md:47-53`, `companies/learnova-academy/agents/content-reviewer/AGENTS.md:63-79`, `companies/learnova-academy/skills/content-review/SKILL.md:93-134`, `server/src/routes/issues.ts:2490-2650`, `server/src/routes/issues.ts:3398-3658`.
- Relevant prior work: KOEA-6947 observed duplicate Content Reviewer wakes caused by missing deterministic revision pointers. Adjacent KOEA-6993 handles master-path freshness before reviewer wake; this plan only defines the handoff contract and verification fields.
- Constraints: Non-engineering content agents must not run `git add`, `git commit`, or `git push`; publish-action owns vault sync to `master`. `origin/master` exists and was verified with `git ls-remote --heads origin master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Update the Blog Author source instructions, Blog Author SOUL, and `blog-write` skill to require a revision-complete handoff template before re-routing to Content Reviewer, then mirror the same source change into the runtime managed Blog Author instructions bundle or block on operator sync if agent-auth cannot update it. Add a small Content Reviewer instruction check that treats missing `Commit SHA` or `Vault path` on a revision re-review as an author handoff defect, so the reviewer does not burn a heartbeat searching history.

**Rejected**: Add a server-side validator for all comments mentioning Content Reviewer because the issue/comment routes already preserve wake comments and dedupe wakeups, while a generic validator would risk blocking non-blog review traffic. **Rejected**: Make Content Reviewer infer the SHA by searching git history because that preserves the waste KOEA-6994 is meant to remove. **Rejected**: Edit only source files without runtime bundle sync because current agents read managed bundles under `/paperclip/instances/.../agents/<id>/instructions`, so source-only changes may not affect the next revision heartbeat.

## Steps (Executor follows in order)
1. Create a branch/worktree from `origin/master`, e.g. `git fetch origin && git worktree add /tmp/koea-6994-handoff origin/master && cd /tmp/koea-6994-handoff && git switch -c koea-6994/revision-handoff-template`.
2. Edit `companies/learnova-academy/skills/blog-write/SKILL.md` Step 6 so blog handoff comments, especially re-review handoffs after G0 BLOCK, must include:
   `Revision complete:`, `- Commit SHA: <40-char sha>`, `- Vault path: vault/blogs/<slug>/draft.md`, and `- Changes:` with bullets, plus the existing word/source/funnel fields.
3. Edit `companies/learnova-academy/agents/blog-author/AGENTS.md` reporting format and execution contract to require the same template before `Status: awaiting-g0 -> @content-reviewer`; add the exact verification command authors use after publish-action sync: `git -C /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org pull origin master --rebase=false && git -C /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org log -n 1 --format=%H -- vault/blogs/<slug>/draft.md`.
4. Edit `companies/learnova-academy/agents/blog-author/SOUL.md` collaboration guidance with Content Reviewer so revision responses must name the exact canonical path and commit SHA, and must stand down or block per KOEA-6993 if the revision has not reached master yet.
5. Edit `companies/learnova-academy/agents/content-reviewer/AGENTS.md` or `companies/learnova-academy/skills/content-review/SKILL.md` to add a re-review precheck: if a revision wake lacks the `Commit SHA` or `Vault path`, return it to Blog Author as a handoff defect instead of searching history.
6. Sync runtime instructions: compare the updated source with `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/de11bfa2-e63c-462a-8b4b-56c0e5b345a3/instructions/AGENTS.md` and update the managed bundle via the agents instructions-bundle API if permitted. If the API returns 403, leave source committed and block with `unblock_owner=operator` and `unblock_action=sync Blog Author managed instructions bundle from companies/learnova-academy/agents/blog-author/AGENTS.md`.
7. Commit only the source instruction/skill changes; do not stage or alter unrelated vault content. Open the implementation PR against `master` and mention KOEA-6993 compatibility in the PR body.

## Verification (QA Verifier checks these)
- [ ] `rg -n "Revision complete|Commit SHA|Vault path" companies/learnova-academy/agents/blog-author/AGENTS.md companies/learnova-academy/skills/blog-write/SKILL.md companies/learnova-academy/agents/blog-author/SOUL.md companies/learnova-academy/agents/content-reviewer/AGENTS.md companies/learnova-academy/skills/content-review/SKILL.md` shows the required template and reviewer precheck.
- [ ] The runtime Blog Author bundle returned by `GET /api/agents/de11bfa2-e63c-462a-8b4b-56c0e5b345a3/instructions-bundle/file?path=AGENTS.md` contains `Commit SHA` and `Vault path`, or the implementation issue is blocked with the exact operator sync action above.
- [ ] A dry-run handoff comment using `vault/blogs/example-slug/draft.md` and a fake 40-character SHA matches the required template and gives Content Reviewer enough data to run `git show <sha> -- vault/blogs/example-slug/draft.md`.

## Risk
- Agents may include the latest commit touching the draft path even when publish-action has not yet synced the intended revision. Mitigation: require the author to pull canonical master first, inspect the path-specific diff or `git show --stat`, and defer to KOEA-6993's freshness gate when the expected content is not present.

## Out of scope
- Changing server comment/wakeup behavior, changing publish-action sync timing, teaching Content Reviewer to search git history as a fallback, or altering non-blog Course Author handoffs.

## Preflight
- status_checked=true
- sibling_count=0
- acceptance_spec_checked=true
- basebranch_verified=true
