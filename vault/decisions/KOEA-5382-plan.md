---
ticket: KOEA-5382
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
planned_by_issue: KOEA-5410
---

# Plan: Root-cause Cursor adapter failure cascade

## Goal
Stop Cursor-lane heartbeats from silently falling into the generic process adapter, and fix the Cursor invocation shape so headless runs receive a prompt and bypass the workspace trust prompt. Success is observable as clear adapter selection, no `Process adapter missing command` for Cursor/Cursor-legacy runs, and a focused test suite proving command args, prompt transport, and trust flags.

## Context
- Files to read first: `server/src/adapters/registry.ts:157-172`, `server/src/adapters/registry.ts:445-447`, `server/src/adapters/registry.ts:552-557`, `server/src/services/heartbeat.ts:5564-5583`, `server/src/adapters/process/execute.ts:14-17`, `packages/adapters/cursor-local/src/server/execute.ts:202-204`, `packages/adapters/cursor-local/src/server/execute.ts:419-424`, `packages/adapters/cursor-local/src/server/execute.ts:476-483`, `packages/adapters/cursor-local/src/server/execute.ts:526-532`, `packages/adapters/cursor-local/src/server/test.ts:188-193`, `packages/adapters/cursor-local/src/shared/trust.ts:1-8`, `packages/adapters/cursor-local/src/index.ts:49-83`, `server/src/services/environment-execution-target.ts:35-45`
- Relevant prior work: KOEA-5382 parent incident; KOEA-5383/KOEA-5384 mitigation comments; KOEA-5405/KOEA-5409 operational adapter repair; failed run evidence `fc462ce6-31c6-451d-8dcc-2d08330048b9`, `3d6ec4cf-afbd-4214-9cbb-87deea228022`, and `6e9fdbb5-3e70-4362-b718-df86cc0bffe7`.
- Constraints: planning only in KOEA-5410; implementation changes Paperclip core adapter code and should land through a normal PR/review. Current production branch for this repo is effectively `master` in this fork; `git ls-remote --heads origin master` returned a matching ref. `main` is not present on this fork remote.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a narrow runtime compatibility layer for legacy `cursor_local`, fail closed on unknown adapter types during heartbeat execution, and correct Cursor headless invocation to pass the prompt as the final positional argv. Keep the canonical adapter type as `cursor`, because the V1 spec and current UI/server contracts use `cursor`, but normalize legacy `cursor_local` wherever runtime adapter lookup and remote/sandbox environment support need to recognize it. In the Cursor adapter, keep the default command as `agent`; local CLI help shows both `agent -p ... [prompt...]` and top-level `cursor -p ... [prompt...]` support print-mode options, while `cursor agent --help` exposes only a prompt subcommand and is not the right command form for Paperclip’s generated args.
**Rejected**: Operational config-only repair; it already restored some agents, but it leaves the silent fallback and stdin prompt bug in place. **Rejected**: Rename the canonical adapter to `cursor_local`; that would churn shared constants, UI labels, docs, and existing `cursor` agents for no functional gain. **Rejected**: Configure Cursor as the generic process adapter with hand-written args; that loses Cursor session parsing, skills sync, billing metadata, local JWT injection, and adapter-specific tests.

## Steps (Executor follows in order)
1. Update `server/src/adapters/registry.ts` so runtime lookup normalizes `cursor_local` to the registered `cursor` adapter, and add/adjust tests in `server/src/__tests__/adapter-registry.test.ts` proving `requireServerAdapter("cursor_local")` and `findActiveServerAdapter("cursor_local")` resolve to the Cursor adapter without adding a duplicate adapter to list outputs.
2. Update heartbeat invocation in `server/src/services/heartbeat.ts` to use `requireServerAdapter(agent.adapterType)` instead of the process fallback path, so truly unknown adapter types fail with `Unknown adapter type: <type>` instead of `Process adapter missing command`; cover this with the smallest existing heartbeat test or adapter-registry test seam available.
3. Update `server/src/services/environment-execution-target.ts` or a shared server helper so `cursor_local` is treated as Cursor for SSH/sandbox execution support checks; keep the public shared `AGENT_ADAPTER_TYPES` canonical list unchanged unless a failing test proves server validation needs the alias.
4. Change `packages/adapters/cursor-local/src/server/execute.ts` so `runAttempt()` appends the rendered prompt as the final positional argument and no longer depends on stdin for the prompt. Keep `stdin` unset or empty for Cursor, and update invocation metadata/tests to show the prompt is in argv while `meta.prompt` remains available for audit.
5. Keep the trust behavior explicit: continue auto-adding a supported trust/force bypass when no user-provided `--trust`, `--yolo`, `-f`, or `--trust=...` arg exists; update `commandNotes` wording if needed so it matches the actual flag behavior. Add tests for default auto-bypass and `-f`/`--trust` preventing duplicate bypass injection.
6. Update Cursor adapter docs/tests (`packages/adapters/cursor-local/src/index.ts`, `packages/adapters/cursor-local/src/server/test.ts`, `server/src/__tests__/cursor-local-execute.test.ts`) to state the supported command form is `agent` by default or top-level `cursor`, not `cursor agent`, and that print-mode prompts are positional.
7. Do a targeted verification run: `pnpm --filter @paperclipai/adapter-cursor-local test`, `pnpm --filter @paperclipai/server test -- cursor-local adapter-registry`, and a local no-model smoke of `agent --help`, `cursor --help`, and `cursor agent --help` captured in the PR notes.

## Verification (QA Verifier checks these)
- [ ] A synthetic agent with `adapterType: "cursor_local"` resolves through the Cursor adapter and records `adapter.invoke.payload.adapterType` as `cursor`, not `process`.
- [ ] A synthetic unknown adapter type fails with a clear `Unknown adapter type` error and never reaches `server/src/adapters/process/execute.ts`.
- [ ] Cursor execute tests show args include `-p`, `--output-format stream-json`, `--workspace <cwd>`, a trust/force bypass, and the prompt as the final positional argument.
- [ ] A Cursor config with `extraArgs: ["-f"]` or `["--trust"]` does not receive a duplicate auto-bypass flag.

## Risk
- Long Paperclip prompts may approach OS argv limits once moved from stdin to a positional argument. Mitigation: keep the change focused, add a clear guard or failure message if the rendered prompt exceeds a conservative argv threshold, and document that a future Cursor prompt-file/stdin feature can replace this once the CLI supports it.

## Out of scope
- Reworking agent configuration ownership, changing the public canonical adapter type away from `cursor`, or replacing the Cursor adapter with the process adapter.
