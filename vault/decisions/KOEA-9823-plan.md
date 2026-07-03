---
ticket: KOEA-9823
planner: planner
date: 2026-07-01
estimated_complexity: medium
estimated_token_cost: $0.55
source_planner_issue: KOEA-9836
authorized_by_approval: ced144c8-349c-4095-b573-e0ecef8aecc6
base_branch: academy/redesign-v1
vault_branch: master
basebranch_verified: true
---

# Plan: Sonnet 5 Academy Claude API audit

## Goal
Make Academy learner-facing Claude examples safe for Claude Sonnet 5 migration without touching unrelated portals or deploying Convex. Success means current code does not silently change tutor behavior when `TUTOR_MODEL=claude-sonnet-5`, and Content can update every discovered course/glossary reference without re-running the engineering audit.

Official Anthropic evidence used: [What's new in Claude Sonnet 5](https://platform.claude.com/docs/en/about-claude/models/whats-new-sonnet-5) says adaptive thinking is on by default, non-default `temperature` / `top_p` / `top_k` return 400, manual `thinking: {type: "enabled", budget_tokens: N}` returns 400, and the new tokenizer produces about 30% more tokens for the same text. The same page says `thinking: {type: "disabled"}` is the Sonnet 5 opt-out for thinking-off workloads and Sonnet 5 keeps `$3/$15` standard pricing after introductory pricing.

Same-day minimal engineering patch is needed before Chief Content updates prose: update the Academy Nova tutor route so a Sonnet 5 env switch stays behaviorally stable by sending `thinking: {type: "disabled"}` only when the configured model is `claude-sonnet-5`. No sampling params or old thinking syntax are currently present in the route.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/api/tutor/route.ts:1`, `vault/courses/claude-agent-sdk-zero-to-production/outline.md:32`, `vault/courses/claude-agent-sdk-zero-to-production/07-build-channel-scoped-agents-for-multi-user-teams.md:117`, `vault/courses/production-agents-claude-agent-sdk-mcp-connector/06-cross-cli-context-persistence/chapter.md:168`, `vault/courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark.md:227`, `vault/glossary/greedy-decoding.md:1`, `vault/glossary/sampling-parameters.md:1`, `vault/glossary/temperature.md:1`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/scripts/sync-vault.mjs:112`
- Relevant prior work: KOEA-9821 daily community scan; KOEA-9823 escalation; Chief Engineering comment on KOEA-9836 at 2026-07-01T01:32:10Z authorizing the depth-3 planner chain.
- Constraints: do not deploy Convex; do not touch student/sales/admin/tc portals; preserve unrelated dirty files in `learnovaBeast` (`src/data/glossary-index.json`, `tsconfig.json`, `learnova-tc/package-lock.json`, `.pnpm-store/`, `public/slides/`); use Academy branch `academy/redesign-v1`; vault branch `master`.

## Search Evidence
Exact commands run:

```bash
git -C /Users/vardaankoenig/Documents/Paperclip/learnovaBeast ls-remote --heads origin academy/redesign-v1 | wc -l
git -C /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org ls-remote --heads origin master | wc -l
rg -n --glob '*.{md,mdx,ts,tsx,js,jsx,json,py,ipynb}' 'temperature|top_p|top_k' /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-agent-sdk-zero-to-production /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/production-agents-claude-agent-sdk-mcp-connector /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-tool-use-from-zero /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/public/courses
rg -n --glob '*.{md,mdx,ts,tsx,js,jsx,json,py,ipynb}' 'thinking|budget_tokens|output_config|effort' /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-agent-sdk-zero-to-production /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/production-agents-claude-agent-sdk-mcp-connector /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-tool-use-from-zero /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/public/courses
rg -n --glob '*.{md,mdx,ts,tsx,js,jsx,json,py,ipynb}' 'count_tokens|token count|tokenizer|cost|pricing|\$3|\$15|max_tokens' /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-agent-sdk-zero-to-production /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/production-agents-claude-agent-sdk-mcp-connector /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-tool-use-from-zero /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/public/courses
rg -n --glob '*.{md,mdx,ts,tsx,js,jsx,json,py}' 'model="claude-sonnet|model: "claude-sonnet|model="claude-opus|model: "claude-opus|model=' /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-tool-use-from-zero /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/production-agents-claude-agent-sdk-mcp-connector /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/claude-agent-sdk-zero-to-production /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/public/courses
```

Key results:

- Branch checks returned `1` for both `academy/redesign-v1` and `master`.
- `learnova-academy/src/app/api/tutor/route.ts:116-121` posts `model`, `max_tokens`, `system`, `messages`, and `stream` to Anthropic. It has no `temperature`, `top_p`, `top_k`, or old `thinking` field.
- `vault/courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark.md:231-236` has a real Anthropic SDK example with `temperature=0`.
- `vault/glossary/greedy-decoding.md`, `vault/glossary/sampling-parameters.md`, and `vault/glossary/temperature.md` recommend or explain temperature/top-p/top-k without a Claude Sonnet 5 caveat.
- `learnova-academy/package.json` runs `scripts/sync-vault.mjs` before dev/build, and `scripts/sync-vault.mjs:112-145` regenerates `learnova-academy/src/data/glossary-index.json` from `vault/glossary/*.md`; glossary edits must target the vault source files, not the generated JSON.
- `vault/courses/claude-opus-47-from-zero/01-what-opus-47-changes-and-costs/chapter.md:223-225` already teaches removal of sampling params and old thinking budgets, but it is Opus 4.7-specific and should not be used as the only Sonnet 5 wording.
- `vault/courses/claude-tool-use-from-zero` has 20 `RunPromptCell` examples pinned to `claude-sonnet-4-6`, including chapters 01, 02, 03, 04, 05, 06, 07, 08, 09, and 10.
- `vault/courses/production-agents-claude-agent-sdk-mcp-connector` has Messages/Agent SDK examples pinned to `claude-sonnet-4-5`, `claude-sonnet-4-6`, and `claude-opus-4-7`.
- `vault/courses/claude-agent-sdk-zero-to-production/outline.md:42`, `:107`, `:129`, and `:151` mention model tier/cost/caching/circuit-breaker learning objectives, while `07-build-channel-scoped-agents-for-multi-user-teams.md:123` teaches `ResultMessage.total_cost_usd`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Small engineering guard plus content migration plan. Executor should patch only the Academy tutor API to preserve thinking-off behavior under Sonnet 5, then update source course Markdown/content data through a separate content handoff. This addresses the only live code behavior risk found while keeping the broad learner-facing wording changes owned by Content.

**Rejected**: Global replace all `claude-sonnet-4-6` snippets with `claude-sonnet-5` because it would change course exercises without local verification and risks making stable MCP lessons about the model launch instead of tool-use fundamentals. **Rejected**: Do nothing in engineering and treat it as content-only because `TUTOR_MODEL=claude-sonnet-5` would enable adaptive thinking by default in Nova and may truncate responses under `max_tokens: 700`. **Rejected**: Build a new model abstraction/config layer because one route is affected and the ticket calls for a same-day audit, not a platform refactor.

## Steps (Executor follows in order)
1. Patch `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/api/tutor/route.ts` so the JSON body adds `thinking: { type: "disabled" }` only when `MODEL === "claude-sonnet-5"` or starts with `claude-sonnet-5`; keep sampling params absent and preserve streaming.
2. Add or update the narrow tutor route test if one exists; otherwise run a targeted static check by evaluating the request-body helper or by adding a tiny extracted helper only if needed to test without hitting Anthropic.
3. Update `vault/courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark.md` so the benchmark code does not instruct Claude Sonnet 5 users to pass `temperature=0`; use a model-conditional note or default-parameter omission for Sonnet 5.
4. Update source glossary files `vault/glossary/greedy-decoding.md`, `vault/glossary/sampling-parameters.md`, and `vault/glossary/temperature.md` with a Sonnet 5 caveat: some Claude models reject non-default sampling params and require prompt/schema/eval controls instead. Do not hand-edit generated `learnova-academy/src/data/glossary-index.json`; regenerate or compare it through `node ./scripts/sync-vault.mjs` from `learnova-academy`.
5. Update `vault/courses/claude-agent-sdk-zero-to-production/outline.md`, `toc.json`, and `07-build-channel-scoped-agents-for-multi-user-teams.md` with Sonnet 5 migration notes for tokenizer/cost rebasing and adaptive-thinking default, without expanding the unfinished course scope.
6. Update affected Claude course snippets in `vault/courses/claude-tool-use-from-zero` and `vault/courses/production-agents-claude-agent-sdk-mcp-connector` to either keep pinned older model IDs with an explicit “pinned for exercise reproducibility” note or migrate to Sonnet 5 with no sampling params and an explicit thinking posture.
7. Preserve unrelated dirty files and verify only the touched surfaces; do not deploy Convex or touch non-Academy portals.

## Content Handoff (No Re-Audit Needed)
| Affected file path | Course/chapter | Snippet/API pattern found | Required Engineering change | Required Content wording/cost update | Verification evidence needed |
|---|---|---|---|---|---|
| `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/api/tutor/route.ts:116` | Nova tutor API | Live Messages API request; no sampling params; no thinking field; `max_tokens: 700` | Add Sonnet 5-only `thinking: {type: "disabled"}` unless tutor intentionally wants adaptive thinking | Explain Nova uses thinking-off tutor mode for concise grounded answers; no cost prose needed unless model default changes | Unit/static check showing request body for `claude-sonnet-5` includes disabled thinking and for 4.x does not |
| `vault/courses/claude-agent-sdk-zero-to-production/outline.md:42`, `:107`, `:129`, `:151` | Claude Agent SDK zero-to-production outline | Model tier/cost/caching/circuit-breaker learning objectives | None in code | Add Sonnet 5 migration note: re-count tokens, sampling params rejected, old manual thinking removed, adaptive thinking default can affect max-token budgets | `rg -n 'Sonnet 5|tokenizer|temperature|budget_tokens|adaptive thinking' vault/courses/claude-agent-sdk-zero-to-production` |
| `vault/courses/claude-agent-sdk-zero-to-production/07-build-channel-scoped-agents-for-multi-user-teams.md:123`, `:187`, `:203` | Chapter 7 channel-scoped agents | Cost tracking via `ResultMessage.total_cost_usd`; text-only thinking/decision turns | None in code | Add note that Sonnet 5 tokenizer raises equivalent prompt token counts and adaptive thinking can create more text-only decision events unless explicitly disabled or handled | Chapter text mentions Sonnet 5 tokenizer and adaptive-thinking default near cost/audit sections |
| `vault/courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark.md:231-236`, `:253-262`, `:301` | Frontier model tool-use determinism | Anthropic SDK benchmark sets `temperature=0`; RunPromptCells use `claude-sonnet-4-6` | None unless benchmark is executable in app | Change code/comment so Sonnet 5 runs omit `temperature`; keep determinism lesson but say “temperature=0 is not portable to Sonnet 5” | `rg -n 'temperature=0|claude-sonnet-5|sampling' vault/courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark.md` |
| `vault/glossary/greedy-decoding.md`, `vault/glossary/sampling-parameters.md`, `vault/glossary/temperature.md` | Academy glossary: greedy decoding, sampling parameters, temperature | Generic learner-facing advice says temperature/top-p/top-k are normal knobs | No API code change; generated `learnova-academy/src/data/glossary-index.json` must come from `node ./scripts/sync-vault.mjs`, not manual edits | Add caveat that Claude Sonnet 5 rejects non-default sampling params; for Sonnet 5 use prompt/schema/eval controls and omit params | `rg -n 'Sonnet 5|non-default sampling|temperature=0' vault/glossary/{greedy-decoding,sampling-parameters,temperature}.md` and, after sync, `rg -n 'Sonnet 5|non-default sampling|temperature=0' learnova-academy/src/data/glossary-index.json` |
| `vault/courses/claude-tool-use-from-zero/*.md` matching `model="claude-sonnet-4-6"` | Claude Tool Use chapters 01-10 | 20 RunPromptCell examples pinned to Sonnet 4.6 | None in app code unless RunPromptCell runtime maps model IDs | Add a short course-wide note: examples are pinned to 4.6 for reproducibility; if using Sonnet 5, omit sampling params and account for adaptive thinking/tokenizer changes | `rg -n 'model="claude-sonnet-4-6"' vault/courses/claude-tool-use-from-zero` plus one visible note in outline or chapter 01 |
| `vault/courses/production-agents-claude-agent-sdk-mcp-connector/04-files-api-code-execution.md:136`, `:162`, `:208`, `:292` | Production Agents chapter 4 | Messages API examples with `claude-sonnet-4-5` and `max_tokens`; cost section says repeated file refs bill input tokens | None | Add Sonnet 5 note: file-token costs must be re-counted because tokenizer is about 30% higher for same text; revisit max_tokens if migrating examples | `rg -n 'Sonnet 5|tokenizer|max_tokens|file content' vault/courses/production-agents-claude-agent-sdk-mcp-connector/04-files-api-code-execution.md` |
| `vault/courses/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability.md:312`, `:398` | Production Agents chapter 5 | RunPromptCell examples with `claude-sonnet-4-6`; cost controls chapter | None | Add Sonnet 5 cost-control note where circuit breakers are taught: thresholds must be rebaselined after tokenizer change | `rg -n 'Sonnet 5|tokenizer|circuit' vault/courses/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability.md` |
| `vault/courses/production-agents-claude-agent-sdk-mcp-connector/06-cross-cli-context-persistence/chapter.md:193-199` | Production Agents chapter 6 | Agent SDK query uses Opus 4.7 dated ID and `max_tokens: 8096` | None | Content may leave Opus 4.7 example, but add note that Sonnet 5 equivalent should revisit `max_tokens` because thinking plus text share the hard output limit | `rg -n 'max_tokens|Sonnet 5|thinking' vault/courses/production-agents-claude-agent-sdk-mcp-connector/06-cross-cli-context-persistence/chapter.md` |
| `vault/courses/claude-opus-47-from-zero/01-what-opus-47-changes-and-costs/chapter.md:223-225` | Opus 4.7 migration course | Already teaches sampling param removal and old `budget_tokens` removal | None | Add cross-link or sidebar only if Content wants: Sonnet 5 shares these breakages but differs because adaptive thinking is on by default and can be disabled | `rg -n 'Sonnet 5|budget_tokens|temperature' vault/courses/claude-opus-47-from-zero/01-what-opus-47-changes-and-costs/chapter.md` |

## Verification (QA Verifier checks these)
- [ ] With `TUTOR_MODEL=claude-sonnet-5`, the tutor request body includes `thinking: {type: "disabled"}` and contains no `temperature`, `top_p`, `top_k`, or `thinking: {type: "enabled"}`.
- [ ] With the default 4.x tutor model, the tutor request body is unchanged except for any tested helper structure; no unsupported `thinking` field is sent to older model IDs.
- [ ] `rg -n 'temperature=0|temperature: 0|top_p|top_k|budget_tokens|type: "enabled"' vault/courses learnova-academy/src learnova-academy/public/courses` returns only intentional explanatory mentions with Sonnet 5 caveats, not runnable Sonnet 5 request examples.
- [ ] `rg -n 'Sonnet 5|claude-sonnet-5|tokenizer|adaptive thinking'` on the affected course/glossary files shows coverage for sampling params, old thinking syntax, thinking-default behavior, and tokenizer/cost rebasing.
- [ ] `rg -n 'Sonnet 5|non-default sampling|temperature=0' vault/glossary/{greedy-decoding,sampling-parameters,temperature}.md` shows the glossary source updates, then from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` either run `node ./scripts/sync-vault.mjs` or explicitly compare after sync and confirm `src/data/glossary-index.json` reflects those source changes.
- [ ] Targeted Academy check passes from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`: use the smallest relevant test/lint command available; do not run Convex deploy.

## Risk
- The highest risk is mixing engineering and content ownership in one patch. Mitigation: Executor should land the tutor route safety change first, then leave the no-reaudit table for Chief Content/CEO to drive prose updates or split content implementation if it exceeds one PR.

## Out of scope
- No Convex deploy, no model benchmark rerun, no changes to student/sales/admin/tc portals, no generated PDF/audio/slide regeneration, and no blanket migration of all older pinned model examples to Sonnet 5.
