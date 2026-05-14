---
ticket: KOEA-1960
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.32
base_branch: master
basebranch_verified: true
chain_depth_override_approval: fab55842-ad4e-498e-a3ed-eefd9a4f23dc
---

# Plan: Stop vault frontmatter status reversion

## Goal
Make vault blog frontmatter status changes durable so `g3-passed`, `g4-approved`, and `ready-to-publish` style publish-chain states are not overwritten by a background sync job. Success is observable when the KOEA-1944 draft can be flipped away from `g0-blocked`, remain stable across a publish-action tick, and still be read correctly by the academy build without publishing unrelated content.

## Context
- Files to read first: `/paperclip/scripts/publish-action.sh:282-340`, `scripts/publish-action.sh:15-193`, `infra/launchd/com.koenig.publish-action.plist:7-27`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/vault.ts:43-72`, `companies/learnova-academy/agents/content-reviewer/AGENTS.md:33-38`, `companies/learnova-academy/skills/g3-alignment/SKILL.md:37-69`.
- Relevant prior work: `f75201a9` set the target draft to `draft-for-review`; `8b0d9d95` changed only `status: draft-for-review` to `status: g0-blocked` and was authored by `Koenig Publish Action <publish-action@kspl.tech>`; `3608b465` / `e07e3667` are the Phase 0 publish-action guard/silent-exit hardening commits to inspect before editing.
- Constraints: no Convex deploy, no direct merge to a protected branch, no unrelated Learnova portal edits, no live publish dispatch during reproduction, and no broad vault rewrites.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Disable publish-action's vault git-sync side effect and keep publish-action focused on Paperclip metadata -> repository_dispatch -> verification. The root evidence points to Phase 0 in the active runtime copy: it stages all dirty `vault/` files and commits/pushes them as `auto: vault-sync`; its guard only blocks transitions to `published`, so a stale local `g0-blocked` status can be committed over a later approval status. The durable fix is to remove or default-disable Phase 0 in the source-controlled script and ensure the active runtime copy/launch path uses that source, then handle any future vault sync with a separate, explicit owner.

**Rejected**: Patch `learnova-academy/src/lib/vault.ts` to tolerate `g0-blocked` because that reader does not write frontmatter and would risk publishing blocked content; broaden the Phase 0 guard to allow more publish states because the cron would still be a broad, stale-state committer; manually flip the draft again because the same cron can reintroduce drift.

## Steps (Executor follows in order)
1. Confirm the active writer before editing: compare `scripts/publish-action.sh` with `/paperclip/scripts/publish-action.sh`, inspect `/paperclip/logs/publish-action.log` around `2026-05-14 04:18-04:23`, and verify `git diff f75201a9 8b0d9d95 -- vault/blogs/2026-05-14-claude-max-chatgpt-pro-economics-dev-orgs/draft.md` is a status-only downgrade.
2. Edit the repo-owned `scripts/publish-action.sh` so it has no default Phase 0 vault sync path: remove `git add -A vault/`, `git commit`, and `git push` behavior, or place it behind an explicit default-off variable such as `PUBLISH_ACTION_ENABLE_VAULT_SYNC=1` with a log line when disabled.
3. Update the runtime install path so the running job cannot keep using the stale `/paperclip/scripts/publish-action.sh` copy: either make launchd call the repo script from `infra/launchd/com.koenig.publish-action.plist` consistently or add a repo script that overwrites the runtime copy from source before loading. Do not hand-edit only `/paperclip/scripts/publish-action.sh` as the durable fix.
4. Add a narrow regression check under `scripts/tests/` or an equivalent shell check that fails if publish-action contains unconditional `git add -A vault`, `git commit`, or `git push origin` in the default path.
5. Safe reproduction: use a temporary clone or copied fixture, not the live vault, with a draft whose status changes from `draft-for-review` or `g3-passed` to `g0-blocked`; run the publish-action entrypoint with dispatch disabled and confirm no vault commit is created by default.
6. Restore the target draft only after the sync fix is in place: set `vault/blogs/2026-05-14-claude-max-chatgpt-pro-economics-dev-orgs/draft.md` to the correct upstream gate status from the parent thread, then wait through one publish-action tick and confirm `git log -1 -- <draft>` does not show an automatic downgrade.
7. Handoff with evidence: include the before/after grep for vault-sync commands, the safe reproduction result, the publish-action log line showing Phase 0 disabled or absent, and the final frontmatter status read by `learnovaBeast/learnova-academy/src/lib/vault.ts`.

## Verification (QA Verifier checks these)
- [ ] `rg "git add -A vault|git commit|git push origin" scripts/publish-action.sh /paperclip/scripts/publish-action.sh` shows no unconditional default-path vault commit/push behavior.
- [ ] A temp-clone reproduction can modify a vault draft status and run publish-action with dispatch disabled without creating an `auto: vault-sync` commit.
- [ ] The KOEA-1944 draft status remains stable across at least one publish-action tick, and academy `listPublishableBlogs()` includes it only when its status is publishable and excludes it when explicitly `g0-blocked`.

## Risk
- Removing Phase 0 may stop the current automatic vault-to-master sync relied on by non-engineering agents. Mitigation: preserve the dispatch phases, document the temporary sync gap in the PR, and if vault sync is still required, create a separate follow-up with a state-machine-aware sync owner instead of keeping it inside publish-action.

## Out of scope
- Publishing KOEA-1944, changing Learnova portal rendering, deploying Convex, rewriting content-review/G3 policy, or bulk-normalizing other vault draft statuses.
