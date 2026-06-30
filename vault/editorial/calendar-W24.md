---
week: 2026-W24
draft_at: 2026-06-08
publish_window: 2026-06-08 to 2026-06-14
phase3_gate_active: true
---

# Editorial Calendar — W24

> Phase 3 SEO/GEO gates remain ACTIVE. All new blogs require:
> - FAQ ≥3 entries + `first_60_words_answer` + non-empty `positions` block
> - `original_data: true` counting toward June ≥4/month gate

## June original_data status check

| Blog | original_data | Pipeline state |
|---|---|---|
| KOEA-6937 local-model-benchmarks | ✅ | g3-passed → G4 pending |
| KOEA-6990 Claude prompt caching ROI | ✅ | awaiting-g0 (PR #80 pending merge) |
| KOEA-6991 MCP server adoption 2026 | ✅ | awaiting-g0 (PR #80 pending merge) |
| KOEA-6992 multi-agent orchestration cost | ✅ | awaiting-g0 (PR #80 pending merge) |
| W24 pick #1 | TBD | commission needed |
| W24 pick #2 | TBD | commission needed |

**June target:** ≥4 published with `original_data: true`. Current pipeline has 4 candidates in review — goal met if all clear G0/G3/G4 in June. W24 picks are bonus coverage.

## W24 Picks (2 commissions)

### Pick 1 — Gemini 2.5 Flash vs. Claude Sonnet 4.6: real developer workload benchmarks

**Angle:** Both models are in the same price tier and both get recommended for "agentic coding." Developers need actual numbers across the workloads they run (code generation, RAG retrieval, multi-turn reasoning, tool use latency), not synthetic benchmarks. We run the comparison ourselves.

**Original data:** Run ≥5 real workloads via both APIs, measure token counts, latency (p50/p95), and output quality scores. Report actuals.

**Phase 3 note:** `original_data: true` required. FAQ ≥3. Positions block: engage `gemini-vs-claude` stance if one exists in STANCES.md.

**Target slug:** `2026-06-xx-gemini-flash-vs-claude-sonnet-developer-benchmarks`

**Commission issue:** to be created → Researcher

---

### Pick 2 — Agent memory in production: in-context vs. RAG vs. external store (latency and cost data)

**Angle:** The "where to store agent memory" question has a cost and latency answer that most tutorials skip. We measure the three patterns (in-context window, RAG retrieval, external KV store) against each other with real numbers for a 20k-token agent state.

**Original data:** Benchmark memory read latency (p50/p95) and per-session cost across the three approaches using Claude Sonnet 4.6 + vector store + Redis. Report actuals.

**Phase 3 note:** `original_data: true`. FAQ ≥3. `positions:` block — check STANCES.md for any memory-architecture stance.

**Target slug:** `2026-06-xx-agent-memory-architecture-latency-cost-benchmarks`

**Commission issue:** to be created → Researcher

---

## Carry-over from W23

| Blog | Status | Next action |
|---|---|---|
| local-model-benchmarks | g3-passed | G4 board approval pending (PR #81 must merge first) |
| agent-control-surface | awaiting-g0 (blocked) | KOEA-6943 stuck-blocked — CEO clearing |
| claude-prompt-caching-roi | awaiting-g0 | G0 review KOEA-6997 (todo, pending PR #80 merge) |
| mcp-server-adoption-2026 | awaiting-g0 | G0 review KOEA-6998 (todo, pending PR #80 merge) |
| multi-agent-orchestration-cost | awaiting-g0 (blocked) | KOEA-6992 stuck G0 block — PR #80 resolves |
| claude-for-small-business | g3-passed | G4 approval pending Vardaan (`fa25131c`) |
| claude-max-economics | g3-passed | G4 approval pending Vardaan (`09cc759a`) |

## Course pipeline (Q2 goal: 4 complete)

| Course | Status | Next action |
|---|---|---|
| `gemini-enterprise-agents` | ✅ LIVE | Course #1 complete |
| `mcp-from-first-principles-to-production` | g4-approved | Publish trigger needed — Course #2 |
| `claude-tool-use-from-zero` | awaiting-g0 | KOEA-6161 ch02 G0 in_progress; KOEA-6984 blocked on it |
| `multi-agent-orchestration-a2a` | ch01/04/10 done; ch02/03/05/06 in-flight | ch06 (KOEA-6979) activating |

## W24 action items for CEO

1. Commission KOEA-W24-P1 (Gemini Flash vs. Sonnet benchmarks) → Researcher
2. Commission KOEA-W24-P2 (agent memory benchmarks) → Researcher
3. Merge PR #80 + PR #81 (all unblock contingent on these)
4. Unblock KOEA-6943 (null blockedByIssueIds but stuck blocked)
5. Activate KOEA-6979 ch06 → Course Author
