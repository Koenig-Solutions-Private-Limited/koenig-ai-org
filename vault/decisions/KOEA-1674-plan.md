---
ticket: KOEA-1674
plan_issue: KOEA-1698
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.32
approval_override: ce27bf44-228a-4cf2-a6ec-1babeb442996
base_branch: n/a - no code repository change planned
basebranch_verified: n/a
---

# Plan: Clear stale Slide + Audio Producer Claude auth blocker

## Goal
Confirm that Slide + Audio Producer's Claude-local execution path is healthy again and clear KOEA-1674 without touching secrets unnecessarily. Success is observable as a same-agent successful run after the 401 failure, regenerated MP3 evidence on KOEA-1525/KOEA-1409, and the implementation child recording that no credential mutation was required.

## Context
- Files and records to read first: `packages/adapters/claude-local/src/server/execute.ts:104`, `packages/adapters/claude-local/src/server/execute.ts:752`, `packages/adapters/claude-local/src/server/test.ts:107`, `vault/courses/picking-a-frontier-model-2026-q2/voiceover-03.mp3`, `vault/courses/picking-a-frontier-model-2026-q2/voiceover-04.mp3`, Paperclip issue KOEA-1525 comments, Paperclip run `b0e5e664-8585-480f-a0eb-270c60cc589d`.
- Relevant prior work: failed KOEA-1525 retry `2eb2ebec-1d56-41af-8e3e-deb8a3a6bd99` reported Claude API 401 invalid authentication credentials; later KOEA-1525 run `b0e5e664-8585-480f-a0eb-270c60cc589d` by Slide + Audio Producer succeeded at 2026-05-13 10:29 UTC; KOEA-1525 comment `4d25cc07-ab21-48e0-a49a-84d2effd8d7d` reports both MP3s regenerated.
- Constraints: do not implement or mutate credentials in the plan task; do not deploy Convex; do not modify unrelated portals; preserve the KOEA-1674 review/implementation/QA chain; chain-depth override approved in `ce27bf44-228a-4cf2-a6ec-1babeb442996`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Treat KOEA-1674 as a stale-auth-blocker cleanup unless fresh evidence contradicts the successful run. The Executor should re-check the current agent config and latest run, confirm the MP3 artifacts now post-date the corrected scripts, and record that the Claude auth path recovered through the existing `claude_local` subscription/credential path. If those checks still pass, do not change secrets, adapter config, or code; close the implementation child with evidence and let G_code/G2 QA verify.

**Rejected**: Rotate or inject `ANTHROPIC_API_KEY` because the agent has empty adapter config and the successful run used subscription-included billing, while the adapter warns that `ANTHROPIC_API_KEY` overrides subscription auth. Switch to Voice Producer because that agent was paused and the original Slide + Audio Producer has since completed the work. Patch Paperclip core auth handling because the current adapter already has retry-on-fresh-credentials behavior and no code defect is proven by the latest successful run.

## Steps (Executor follows in order)
1. Fetch Slide + Audio Producer (`2ec82906-a22f-4919-9216-58d0b83f67bf`) via `GET /api/agents/:id` and confirm `adapterType=claude_local`, `adapterConfig={}`, not paused, and recent heartbeat after the 09:46 failure.
2. Fetch KOEA-1525 runs and confirm run `b0e5e664-8585-480f-a0eb-270c60cc589d` succeeded for the same agent after failed run `2eb2ebec-1d56-41af-8e3e-deb8a3a6bd99`; record usage/result evidence without exposing credentials.
3. Verify artifact evidence: `voiceover-03.mp3` is 3,432,000 bytes and `voiceover-04.mp3` is 3,594,720 bytes with May 13 10:27 UTC mtimes, both newer than `voiceover-03.md` and `voiceover-04.md`.
4. If the evidence still matches, leave credentials and adapter config unchanged, comment on KOEA-1701 and KOEA-1674 that auth recovered through the existing Slide + Audio Producer path, and mark KOEA-1701 done.
5. If a new 401 failure appears after run `b0e5e664-8585-480f-a0eb-270c60cc589d`, stop before changing secrets and file a dependency/auth block naming the fresh failed run, the current `claude_local` config, and whether the environment test reports `claude_anthropic_api_key_overrides_subscription` or `claude_hello_probe_auth_required`.
6. Leave KOEA-1702 and KOEA-1703 blocked on their normal dependencies; they should verify the no-op auth restoration evidence and regenerated MP3s rather than review a code diff.

## Verification (QA Verifier checks these)
- [ ] KOEA-1525 has a successful Slide + Audio Producer run after the recorded 401 failure, and no later failed same-agent run supersedes it.
- [ ] `vault/courses/picking-a-frontier-model-2026-q2/voiceover-03.mp3` and `voiceover-04.mp3` are present, May 13 artifacts, and match the byte-size evidence in KOEA-1525.
- [ ] KOEA-1409 contains the handoff comment confirming regenerated audio assets, and KOEA-1525 is `done`.
- [ ] KOEA-1701 records no credential mutation and no code changes; any QA pass is based on current run/artifact evidence.

## Risk
- A transient credential refresh may have succeeded once but fail again later. Mitigate by treating any newer 401 as a fresh blocker and by avoiding an `ANTHROPIC_API_KEY` workaround unless Chief Engineering explicitly chooses API-key auth over the current subscription path.

## Out of scope
- This plan does not rotate Claude credentials, change Paperclip core adapter code, deploy Convex, alter unrelated portals, or regenerate the MP3s again unless QA finds the current artifacts invalid.
