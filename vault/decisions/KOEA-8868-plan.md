---
ticket: KOEA-8868
source_planning_ticket: KOEA-9321
planner: planner
date: 2026-06-29
estimated_complexity: small
estimated_token_cost: $0.24
base_branch: master
basebranch_verified: true
status: ready-to-execute
preflight: "vault_pull=clean status=in_progress assigned_to_planner=true active_siblings=0 chain_depth=2 spec_source=issue_required_plan_output basebranch_verified=true"
---

# Plan: Restore career reconciler Paperclip token discovery

## Goal
Make `scripts/career-reconcile.sh` run successfully in the current agent/runtime environment where Docker is unavailable and `PAPERCLIP_BOARD_TOKEN` is not injected into process env. Success means the reconciler can discover the existing board token from its already-loaded `.env.koenig` file, fail loudly without printing secrets when no token is available, and keep course-build issue creation behavior unchanged.

## Context
- Files to read first: `scripts/career-reconcile.sh:1-6`, `scripts/career-reconcile.mjs:50-81`, `scripts/career-reconcile.mjs:103-110`, `scripts/career-reconcile.mjs:171-176`
- Relevant prior work: KOEA-9321 preflight found the canonical synced source now lives in `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org`; `/app/.env.koenig` and the synced checkout expose `PAPERCLIP_BOARD_TOKEN` by key presence, but this runtime process has only `PAPERCLIP_API_KEY`.
- Constraints: do not print or hardcode secrets; do not modify Paperclip core packages; keep Chief Learning routine contract `run scripts/career-reconcile.sh`; base branch `origin/master` verified on 2026-06-29.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Make the reconciler use its existing `.env.koenig` load as the second Paperclip token source. Executor should change `paperclipToken()` in `scripts/career-reconcile.mjs` to check `process.env.PAPERCLIP_BOARD_TOKEN`, then `env.PAPERCLIP_BOARD_TOKEN`, then the existing Docker fallback. This is the smallest code-path fix because `loadEnv()` already parses `.env.koenig` before the token is required, R2 credentials already depend on that file, and it removes the runtime dependency on Docker without changing issue-creation semantics.

**Rejected**: Configure the routine/adapter to inject `PAPERCLIP_BOARD_TOKEN` - this would fix only the current scheduler environment and leave the script brittle in other local/routine invocations. **Rejected**: Use `PAPERCLIP_API_KEY` as a fallback - the current key is an agent runtime token with uncertain board-level scope for creating Course Architect issues, and using it could silently change auth semantics. **Rejected**: Require Docker fallback restoration - Docker is explicitly unavailable in the failing runtime.

## Steps (Executor follows in order)
1. Edit `scripts/career-reconcile.mjs` so `paperclipToken()` accepts the parsed `.env.koenig` map or otherwise reads it after `const env = loadEnv()`, preserving the existing process-env preference and Docker fallback.
2. Keep token values out of logs; if no token is found, retain the current generic `reconcile: no Paperclip board token reachable` failure or replace it only with a presence-only message.
3. Do not change `scripts/career-reconcile.sh` except if needed for a comment-only contract clarification; the wrapper already points to the `.mjs` implementation.
4. Add a focused regression check if the repo has a lightweight script-test pattern; otherwise add a small Node-only verification command in the PR notes that stubs `fetch`/S3 enough to prove token selection does not invoke Docker when `.env.koenig` contains the board token.
5. Run syntax and token-discovery verification without printing secrets.

## Verification (QA Verifier checks these)
- [ ] `node --check scripts/career-reconcile.mjs` passes.
- [ ] With `PAPERCLIP_BOARD_TOKEN` absent from process env and Docker absent, a focused token-discovery check proves `.env.koenig` key presence is enough to avoid `reconcile: no Paperclip board token reachable`, without printing the token.
- [ ] A no-secret negative check with a temporary env file lacking `PAPERCLIP_BOARD_TOKEN` still exits before Paperclip API calls with the generic missing-token failure.

## Risk
- The current implementation executes top-level R2/Paperclip work, so careless verification could create duplicate Course Architect issues. Mitigation: keep tests focused on token selection with stubs or temporary fixtures, and do not run the full reconciler against live R2/Paperclip as verification unless Chief Engineering explicitly authorizes it.

## Out of scope
- Changing routine scheduling, injecting adapter secrets, replacing the Docker fallback, using `PAPERCLIP_API_KEY` for board operations, or modifying Paperclip core authentication behavior.
