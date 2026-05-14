---
ticket: KOEA-1717
planner_ticket: KOEA-1718
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.48
base_branch: master
basebranch_verified: true
chain_alert_approval_id: 5c438d6b-5110-4a33-b118-f1bc51c0d646
underspec_approval_id: ec301b5a-e8c7-46c8-b1fb-77027789c4f2
---

# Plan: Fix Publish Verifier compliance and slides-probe drift

## Goal
Stop Publish Verifier from emitting speculative `/slides/<slug>.pptx` failures when the live page has no visible slides link, while keeping the Section 0 probe-scope rule authoritative. Success is observable when a verifier run against a blog with a vault `slides.pptx` but no live slides link records the slides check as skipped/not applicable and does not probe or report `/slides/<slug>.pptx`.

## Context
- Files to read first: `companies/learnova-academy/skills/verify-publish/SKILL.md:25-33`, `companies/learnova-academy/skills/verify-publish/SKILL.md:155-178`, `companies/learnova-academy/agents/publish-verifier/AGENTS.md:111-128`, `companies/learnova-academy/.paperclip.yaml:386-395`, `companies/learnova-academy/ARCHITECTURE.md:276-281`.
- Relevant prior work: KOEA-1393 / PR #21 added the Section 0 hard probe-scope rule; later commit `566f3230 chore(skill): add blog slides check` reintroduced a vault-file-triggered slides probe as check 11; KOEA-1716 is the separate academy slide asset/link implementation track and is out of scope here.
- Constraints: keep work in `koenig-ai-org`; do not change `learnovaBeast`, publish slide decks, or implement `/slides/` serving; preserve G_code and G2 review gates; base branch verified as `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Make Publish Verifier's slides check visible-link-gated and reconcile the verifier runtime configuration. Replace the current source-vault-triggered check 11 with a rule that first inspects fetched live HTML for an explicit `/slides/${slug}.pptx` link; if no link exists, skip the slides check and do not probe any guessed URL. In the same implementation, update the stale verifier docs/config comments and patch the live Paperclip agent config back to the stricter declared runtime (`claude_local`, `claude-haiku-4-5`) because the API currently reports `publish-verifier` as `codex_local` with empty config despite the repo YAML declaring Haiku.

**Rejected**: model-only change, because the current skill still contains a deterministic-looking but wrong vault-file trigger; full standalone checklist runner, because that is larger than needed for this recurrence; academy slide serving, because KOEA-1717 explicitly says not to plan asset/link implementation.

## Steps (Executor follows in order)
1. Branch from `origin/master` in `koenig-ai-org` as `koea-1717/publish-verifier-compliance-model`; do not touch `learnovaBeast` or generated vault media.
2. Edit `companies/learnova-academy/skills/verify-publish/SKILL.md`: keep Section 0, but change it to say slides validation may only act on explicit live HTML links, then replace check 11 so it fetches `$URL` first, searches for `/slides/${slug}.pptx`, skips with an `n/a` result if absent, and only then curls the linked asset.
3. Update `companies/learnova-academy/agents/publish-verifier/AGENTS.md` so the check count and live-runtime note match the repo policy: no stale DeepSeek/OpenCode migration note, no “run all 10” drift, and an explicit “do not use Grok/OpenCode for G5 verifier” comment if useful.
4. Add or update a narrow deterministic verification fixture, preferably `scripts/tests/verify-publish-probe-scope.sh`, that stubs live HTML without a slides link while a vault `slides.pptx` exists and proves the checker does not call or report `/slides/<slug>.pptx`; keep it offline and temp-dir based.
5. Reconcile live Paperclip state for agent `publish-verifier` (`ea443734-e060-4f5a-bcc8-9dc8c0ded526`) after review approval by PATCHing adapter config to `adapterType=claude_local`, `adapterConfig.model=claude-haiku-4-5`, `cwd=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org`, preserving any unrelated runtime settings.
6. Open the PR against `master` with the standard template; note both approvals (`5c438d6b-5110-4a33-b118-f1bc51c0d646`, `ec301b5a-e8c7-46c8-b1fb-77027789c4f2`) and that KOEA-1716 remains the separate slide-serving track.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/tests/verify-publish-probe-scope.sh` and `bash scripts/tests/verify-publish-probe-scope.sh` pass if the fixture script is added.
- [ ] `rg -n "Probe-scope rule|slides.*skip|/slides/\\$\\{slug\\}\\.pptx|Grok|DeepSeek|codex_local" companies/learnova-academy/skills/verify-publish/SKILL.md companies/learnova-academy/agents/publish-verifier/AGENTS.md companies/learnova-academy/.paperclip.yaml` shows the visible-link gating and no stale runtime contradiction.
- [ ] A dry-run/focused verifier fixture where `vault/blogs/<slug>/slides.pptx` exists but fetched HTML lacks `/slides/<slug>.pptx` does not emit a BLOCK and does not run `curl` against `https://academy.kspl.tech/slides/<slug>.pptx`.
- [ ] `GET /api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents` shows `publish-verifier` on `claude_local` with model `claude-haiku-4-5` after the approved live config reconciliation.

## Risk
- Runtime agent config may drift again from repo YAML. Mitigation: update the repo docs/comments and require the post-approval API readback as part of verification so the PR and live state converge before the ticket closes.

## Out of scope
- No `learnovaBeast` changes, no `/slides/` route or static asset implementation, no G5 re-verification for the GPT-5.5 Codex slides signal, no publishing of `.pptx` files, and no broader rewrite of the G5 verifier into a full service.

Telemetry: basebranch_verified=true; planner_chain_override=approval-5c438d6b-5110-4a33-b118-f1bc51c0d646; underspec_override=approval-ec301b5a-e8c7-46c8-b1fb-77027789c4f2
