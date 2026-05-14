---
ticket: KOEA-1953
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.45
base_branch: master
basebranch_verified: true
chain_alert_approval: 047618a0-11ee-4ebe-9eca-6c672bc2aea0
---

# Plan: Restore Researcher OpenAI execution path

## Goal
Restore the `daily-research - OpenAI` execution path so KOEA-1882 can run under Researcher OpenAI without selecting `x-ai/grok-4.1-fast` and without failing on Claude authentication. Success is observable as a passing Claude local environment probe, a KOEA-1882 resume/invoke that no longer fails before work starts, and `vault/research/openai/2026-05-14.md` being produced by the assigned researcher or clearly unblocked for that researcher to produce.

## Context
- Files to read first: `packages/adapters/claude-local/src/index.ts:4-30`, `packages/adapters/claude-local/src/server/execute.ts:310-355`, `packages/adapters/claude-local/src/server/execute.ts:536-555`, `packages/adapters/claude-local/src/server/test.ts:104-220`, `server/src/routes/agents.ts:969-997`, `server/src/routes/agents.ts:2078-2172`, `server/src/routes/agents.ts:2528-2558`, `server/src/services/heartbeat.ts:4860-5010`.
- Relevant prior work: KOEA-1882 run `0af8babe-b328-4007-aa5a-642e177d618e` failed with `--model x-ai/grok-4.1-fast`; KOEA-1892 run `03abed4b-c18b-449f-9a16-f9e468e3dff1` and KOEA-1908 run `d85170ce-30ce-4e9b-9bea-e85ca4f00d4c` failed with `Invalid authentication credentials`.
- Constraints: Preserve CEO-owned KOEA-1892 and KOEA-1908 blocker ownership; do not close or rewrite those blockers from Executor unless explicitly authorized. Prefer config/API repair over code changes. `origin/master` is the verified base branch; `origin/main` does not exist in this checkout.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Explicit agent config plus auth probe. Set Researcher OpenAI's `claude_local` adapter config to an allowed Claude model, preferably `claude-sonnet-4-6`, using the existing `PATCH /api/agents/:id` surface, then verify/repair host Claude auth using the existing adapter environment test and Claude login surfaces. This directly addresses the run evidence: bad model selection reached `commandArgs`, and the later CEO recovery path failed on credentials.

**Rejected**: Clear only the host Claude default - too indirect because KOEA-1882 already proved a bad `--model` can be passed into the run; switch Researcher OpenAI to a different adapter - larger blast radius and unnecessary unless Claude auth cannot be restored; patch `claude_local` code - no code defect is established because the adapter already supports explicit `model` and auth probes.

## Steps (Executor follows in order)
1. Confirm current state with `GET /api/agents/64ec286b-93d7-464b-8957-9e8fdc0509c2`, `GET /api/issues/2812b7c9-5fb0-4b66-a2eb-057174a8ddda`, and `GET /api/heartbeat-runs/0af8babe-b328-4007-aa5a-642e177d618e/events`; record that Researcher OpenAI is `claude_local` and the failed run passed `--model x-ai/grok-4.1-fast`.
2. Probe Claude local with `POST /api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/adapters/claude_local/test-environment` and body `{"adapterConfig":{"model":"claude-sonnet-4-6","cwd":"/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org"}}`.
3. If the probe reports auth failure or invalid credentials and Executor lacks board authority, file `POST /api/companies/{companyId}/approvals` with `type: "request_board_approval"` and `payload.subtype: "mutation_authorization_block"`, including issueId, summary, recommendedAction, risks, severity, cooldown_hours.
4. Patch Researcher OpenAI via `PATCH /api/agents/64ec286b-93d7-464b-8957-9e8fdc0509c2` with `{"adapterConfig":{"model":"claude-sonnet-4-6"},"replaceAdapterConfig":false}`; preserve any existing config keys returned by Step 1.
5. Re-run the Claude local environment test with Researcher OpenAI's effective adapter config and require `claude_hello_probe_passed` or equivalent non-auth, non-model success before waking KOEA-1882.
6. Resume or invoke KOEA-1882 using the issue/agent heartbeat path already used by Paperclip, then inspect the new run's adapter invocation event to verify it no longer includes `x-ai/grok-4.1-fast` and no longer fails before research work starts.
7. Coordinate blocker state: comment evidence on KOEA-1886, KOEA-1892, KOEA-1908, and KOEA-1953; mark only Executor-owned implementation work done. Leave CEO-owned blockers for CEO/operator or Chief Engineering to close after they accept the evidence.

## Verification (QA Verifier checks these)
- [ ] `GET /api/agents/64ec286b-93d7-464b-8957-9e8fdc0509c2` shows `adapterConfig.model == "claude-sonnet-4-6"` and keeps unrelated config keys intact.
- [ ] `POST /api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/adapters/claude_local/test-environment` with the Researcher OpenAI config returns no `claude_hello_probe_auth_required`, no invalid-credentials detail, and no model-unavailable detail.
- [ ] The next KOEA-1882 heartbeat run's `adapter.invoke.commandArgs` includes an allowed Claude model, does not include `x-ai/grok-4.1-fast`, and does not fail with `adapter_failed` before research starts.
- [ ] `vault/research/openai/2026-05-14.md` exists after Researcher OpenAI resumes, or KOEA-1882 has a fresh comment from Researcher OpenAI stating the path is live and the file is the immediate next write.

## Risk
- Host Claude credentials may be globally invalid, so model repair alone may not restore execution. Mitigation: make the auth probe a gate before waking KOEA-1882, and escalate through the `request_board_approval` envelope with `payload.subtype: "mutation_authorization_block"` if Executor cannot run the board-only login flow.

## Out of scope
- Manually writing the OpenAI daily research note as Planner or Executor.
- Closing CEO-owned KOEA-1892 or KOEA-1908 without CEO/operator confirmation.
- Refactoring `claude_local`, changing recovery semantics, or moving Researcher OpenAI to another adapter unless the explicit config and auth repair fail with new evidence.

Pre-flight: status_assignee=passed; chain_gate=approved:047618a0-11ee-4ebe-9eca-6c672bc2aea0; acceptance_criteria=passed; basebranch_verified=true (`origin/master`).
