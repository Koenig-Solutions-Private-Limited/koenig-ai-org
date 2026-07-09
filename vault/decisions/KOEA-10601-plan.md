---
ticket: KOEA-10601
planner: planner
date: 2026-07-08
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
chain_alert_approval: 97e62092-392c-4f53-977d-04068d1f331e
---

# Plan: Restore Research Editor hermes_local CLI invocation

## Goal
Research Editor's `hermes_local` heartbeat should reach task execution for KOEA-10570 instead of failing at Hermes argument parsing. Success is observable when the smoke issue either marks itself done after posting a runtime comment, or blocks with a meaningful runtime/auth/model failure beyond CLI usage text.

## Context
- Files to read first: `packages/adapters/hermes-local/src/server/execute.ts:143`, `packages/adapters/hermes-local/src/server/execute.ts:378`, `packages/adapters/hermes-local/src/server/test-environment.ts:123`, `server/src/adapters/registry.ts:235`, `/paperclip/.paperclip/adapter-plugins.json:1`
- Relevant prior work: KOEA-10570 run `647ab3bf-1639-4d0e-8c4d-c7927814986d` failed before task execution with `adapter_failed: usage: hermes chat [-h] [-q QUERY] [--image IMAGE] [-m MODEL] [-t TOOLSETS]`; KOEA-10601 dispatch says expected config was `adapterType=hermes_local`, `provider=lmstudio`, `model=qwopus3.6-35b-a3b-v1-mtp`.
- Constraints: Plan authorized by resolved planner-chain approval `97e62092-392c-4f53-977d-04068d1f331e`; keep scope to operational adapter repair; do not create implementation subtasks; preserve KOEA-10604 plan-review gate.
- Root cause hypothesis: current Hermes CLI v0.11.0 accepts `hermes chat -q QUERY -m MODEL -t TOOLSETS -Q --source ...`, but its `--provider` enum does not include `lmstudio`. Local reproduction of `hermes chat -q ... -Q -m qwopus3.6-35b-a3b-v1-mtp --provider lmstudio --source paperclip` fails with the same usage header and `invalid choice: 'lmstudio'`. Running the same argument shape without `--provider lmstudio` reaches session startup. The adapter currently pushes any non-empty `config.provider` as `--provider` in `packages/adapters/hermes-local/src/server/execute.ts:382`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Normalize unsupported Hermes providers at the adapter boundary. In `execute.ts`, keep passing the prompt through `-q`, model through `-m`, and toolsets through `-t`, but only append `--provider` for values Hermes accepts. Treat `lmstudio` as a local/OpenAI-compatible backend hint that must not be passed to Hermes v0.11.0, and add a command note when it is suppressed. Also improve the stderr fallback to prefer the argparse `error:` line over the generic usage header, so future CLI-shape failures expose the exact bad flag.

**Rejected**: Change Research Editor config only by deleting `provider=lmstudio` — this unblocks one agent but leaves the adapter able to emit the same bad CLI for any future Hermes agent. **Rejected**: replace `hermes chat` with top-level `hermes -z` — that loses the session id and conflicts with the adapter design in `packages/adapters/hermes-local/DESIGN.md:13`. **Rejected**: broad externalization cleanup — the current plugin entry points at this package, and removing built-in Hermes imports is outside KOEA-10601.

## Steps (Executor follows in order)
1. Update `packages/adapters/hermes-local/src/server/execute.ts` to introduce a small allowed-provider set matching `hermes chat -h`; when `config.provider` is empty, `auto`, or unsupported such as `lmstudio`, do not append `--provider`, while still appending `-m <model>` and `-t <toolsets>` when present.
2. In the same file, change `firstMeaningfulStderrLine` to return a `hermes chat: error:` line before returning the usage header, preserving the current session-id filtering.
3. Add focused coverage in `packages/adapters/hermes-local/src/server/execute.test.ts` using a fake Hermes executable that records argv: assert `-q <prompt>`, `-m qwopus3.6-35b-a3b-v1-mtp`, and `-t <toolsets>` are present, and `--provider lmstudio` is absent.
4. Add a second test for a supported provider such as `openrouter` to assert `--provider openrouter` is still passed, so the fix does not remove legitimate provider overrides.
5. If Executor wants UI/operator feedback, add only a narrow warning in `packages/adapters/hermes-local/src/server/test-environment.ts` for unsupported configured providers; do not touch schema, routes, or the generic adapter manager.
6. After tests pass, temporarily re-enable the Research Editor smoke path only if needed: set Research Editor back to `hermes_local` with model `qwopus3.6-35b-a3b-v1-mtp`, omit `provider` or set it blank, and keep the current `opencode_local` config as the rollback target.
7. Rerun or re-dispatch KOEA-10570 and stop when Research Editor reaches task execution, or when the smoke issue blocks with a non-secret model/auth/runtime error that is no longer Hermes argparse usage.

## Verification (QA Verifier checks these)
- [ ] `pnpm -C packages/adapters/hermes-local test` passes, including the new argv tests.
- [ ] A local argument smoke equivalent to `hermes chat -q 'paperclip smoke' -Q -m qwopus3.6-35b-a3b-v1-mtp --source paperclip --max-turns 1 --yolo --accept-hooks` reaches session startup without usage text.
- [ ] KOEA-10570 no longer records `adapter_failed: usage: hermes chat ...`; it either reaches Research Editor task execution and is marked done, or blocks with a meaningful non-secret runtime/auth/model failure.

## Risk
- Suppressing `provider=lmstudio` may rely on Hermes auto-detection for the local backend. Mitigation: keep the smoke issue narrow and rollback Research Editor to the current `opencode_local` config if Hermes reaches model/backend failure rather than task execution.

## Out of scope
- Removing built-in Hermes imports from core, changing adapter plugin architecture, updating Hermes itself, or producing the 2026-07-07 daily brief.
