---
ticket: KOEA-2245
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: "$0.45"
base_branch: master
basebranch_verified: true
preflight_approval: c80aa239-2938-415e-bb80-a5de5c5558d7
---

# Plan: Audit Paperclip's Claude billing path before June 15 credits

## Goal
Produce a read-only audit report that proves which Claude execution paths Paperclip actually uses today: Claude Agent SDK, Claude Code CLI / `claude --print`, direct Anthropic API, Bedrock, or subscription-backed `claude_local`. Success is an evidence-backed `vault/decisions/KOEA-2245-audit.md` with billing impact, cap-risk hypotheses, and any follow-up config/docs/code tickets needed, without making production code changes in this chain.

## Context
- Files to read first: `vault/research/_daily/2026-05-14.md:35-49`, `vault/research/_daily/2026-05-14.md:80-82`, `packages/adapters/claude-local/src/server/execute.ts:91-106`, `packages/adapters/claude-local/src/server/execute.ts:493-565`, `packages/adapters/claude-local/src/server/execute.ts:726-743`, `packages/adapters/claude-local/src/server/test.ts:99-139`, `packages/adapters/claude-local/src/server/quota.ts:212-245`, `packages/adapters/claude-local/src/server/quota.ts:387-425`, `server/src/services/heartbeat.ts:1017-1044`, `server/src/services/heartbeat.ts:4591-4629`, `server/src/services/costs.ts:12-13`, `server/src/adapters/registry.ts:120-136`.
- Relevant prior work: KOEA-2245 source brief says this is an internal billing audit before June 15 credits; KOEA-2245 comments created this chain and explicitly set no-code-change boundaries. Approval `c80aa239-2938-415e-bb80-a5de5c5558d7` authorized proceeding despite chain fanout.
- Constraints: no production code changes; no secrets or raw OAuth tokens in vault; use `master` as the verified repository base branch because `origin/main` is absent and `origin/master` exists; deadline is 2026-05-22 EOD IST.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Evidence-first billing-path trace. Executor should start with dependency/import searches to rule in or rule out Claude Agent SDK usage, then trace the actual `claude_local` invocation, auth-mode detection, quota polling, and cost-ledger normalization from adapter result to `cost_events`. This keeps the audit grounded in current code and gives Reviewer exact claims to validate.
**Rejected**: Vendor-doc-first writeup - too likely to overfit June 15 announcement language before proving Paperclip's actual path. Runtime probing with live Claude calls - may burn subscription/API quota and is unnecessary unless static evidence is ambiguous. Immediate implementation fixes - explicitly out of scope until the audit identifies a concrete defect.

## Steps (Executor follows in order)
1. Re-read KOEA-2245, KOEA-2250, KOEA-2245 comments, and `vault/research/_daily/2026-05-14.md`; capture the source claim that Agent SDK monthly credits are a June 15 billing/cap risk and not course content.
2. Run read-only searches from repo root: `rg -n 'claude-agent-sdk|claude-code-sdk|@anthropic-ai/sdk|@anthropic-ai/claude|claude --print|ANTHROPIC_API_KEY|CLAUDE_CODE_USE_BEDROCK|anthropic-oauth|billingType|subscription_included|subscription_overage|metered_api' package.json pnpm-lock.yaml server packages ui scripts vault -g '!**/node_modules/**' -g '!**/dist/**'`; record whether production code imports Agent SDK or instead shells out to Claude Code CLI.
3. Trace `claude_local` execution in `packages/adapters/claude-local/src/server/execute.ts`: default command `claude`, `--print - --output-format stream-json --verbose`, stdin prompt, model/effort args, `ANTHROPIC_API_KEY`/Bedrock/subscription billing classification, usage/cost parsing, biller, and `billingType` returned to Paperclip.
4. Trace auth and cap detection in `packages/adapters/claude-local/src/server/test.ts`, `packages/adapters/claude-local/src/server/quota.ts`, and `packages/adapters/claude-local/src/server/parse.ts`; specifically answer whether subscription mode depends on local `claude login`, whether `ANTHROPIC_API_KEY` bypasses subscription credits, and how extra-usage/weekly/session-cap failures are classified.
5. Trace cost accounting from adapter result through `server/src/services/heartbeat.ts`, `server/src/services/costs.ts`, `packages/db/src/schema/cost_events.ts`, and `ui/src/lib/utils.ts`; check for mismatches between adapter-returned `"subscription"`/`"api"` and ledger-facing `subscription_included`/`metered_api`, and note whether subscription runs are costed at zero even when Claude reports `total_cost_usd`.
6. Write `vault/decisions/KOEA-2245-audit.md` with sections: conclusion, evidence table, current execution paths, billing-impact questions, cap-risk hypotheses, source requirements, recommended follow-up tickets, and no-code-change confirmation. Include only file paths, line references, commands, and summarized findings; do not include secrets, tokens, raw `.credentials.json`, or live usage values.
7. Hand off to Code Reviewer on KOEA-2256 by marking KOEA-2255 done with a concise comment linking `vault/decisions/KOEA-2245-audit.md` and listing the strongest claims Reviewer should verify.

## Verification (QA Verifier checks these)
- [ ] Audit report states whether Paperclip production code imports Claude Agent SDK packages or uses Claude Code CLI / `claude --print`, with command output and file references.
- [ ] Audit report maps each detected billing path to `billingType`, `biller`, quota source, and ledger cost behavior.
- [ ] Audit report identifies June 15 cap risks and open billing-impact questions without proposing or making code changes.
- [ ] Audit report includes enough evidence for Code Reviewer to reproduce the searches and validate line-referenced claims.

## Risk
- The main risk is conflating Anthropic's Agent SDK credit announcement with Claude Code CLI subscription behavior. Mitigation: Executor must separate "vendor announcement applicability" from "Paperclip path evidence" and clearly label any inference that is not directly proven by current code or cited source material.

## Out of scope
- No code, config, docs, dependency, or adapter behavior changes.
- No live Claude usage probing unless static evidence is insufficient and Chief Engineering explicitly approves the quota spend.
- No course/content updates from this ticket.
