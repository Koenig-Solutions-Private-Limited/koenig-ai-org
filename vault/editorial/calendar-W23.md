---
week: 2026-W23
draft_at: 2026-06-01
publish_window: 2026-06-01 to 2026-06-07
phase3_gate_active: true
---

# Editorial Calendar — W23

> **Phase 3 SEO/GEO gates ACTIVE from this week.** All new blogs published after 2026-06-01 require:
> - FAQ frontmatter ≥3 entries
> - `first_60_words_answer` field
> - Non-empty `positions` block
> - Content Reviewer (G0) enforces at gate; EiC monitors 50% compliance aggregate monthly.
> - `original_data: true` on ≥4 blogs/month (June target: 4).

## Picks (2)

1. **KOEA-6937** — [Why local model benchmarks lie: what agent trace evaluation reveals](KOEA/issues/KOEA-6937)
   - Researcher: Researcher · Community → Blog Author → G0 → G3 → G4
   - Angle: Local model leaderboards measure isolated generation quality; production agent trace evaluation reveals failure modes that static benchmarks miss entirely.
   - Phase 3 note: Must include `original_data: true` (build a comparison of eval harness outputs vs. leaderboard rankings as the data point). G0 to enforce FAQ ≥3 + positions.
   - Status: `in_progress` (Researcher + Blog Author both active; G0 blocker revision KOEA-6986 in_progress)

2. **KOEA-6938** — [The agent control surface developers actually want: rollback, hooks, readable artifacts](KOEA/issues/KOEA-6938)
   - Researcher: Researcher · Community → Blog Author → G0 → G3 → G4
   - Angle: MEDIUM signal (3 HN threads on audit rewrites, rollback tooling, delegation > memory). Developers want operational control primitives, not model capability improvements.
   - Phase 3 note: FAQ ≥3 required. `positions` block — check STANCES.md for any agent-tooling stance. G0 to enforce.
   - Status: `done` (commission complete); Blog Author revising G0 blockers via KOEA-6985

## W23 original_data tracker (June target: ≥4/month)

| Blog | original_data | Status |
|---|---|---|
| KOEA-6937 agent benchmarks | ✅ (benchmark comparison data) | in_progress — G0 revision |
| KOEA-6938 agent control surface | ❌ analysis only | G0 revision in_progress |
| KOEA-6987 Claude prompt caching ROI | ✅ (real API benchmark runs) | todo — needs Researcher assignment |
| KOEA-6988 MCP server adoption 2026 | ✅ (GitHub/npm data pull) | todo — needs Researcher assignment |
| KOEA-6989 multi-agent orchestration real cost | ✅ (API benchmark runs) | todo — needs Researcher assignment |

**Gap:** KOEA-6987/6988/6989 commissioned 2026-05-31. CEO escalation (KOEA-6700 comment `80fb65ac`) requests Researcher assignment. With KOEA-6937 that gives 4 original_data candidates for June — meeting the ≥4/month target if all ship.

## Cross-blog narrative arc this week

Theme: **Agent operational maturity**. The two picks address the gap between model capability (what benchmarks claim) and operational reality (what developers actually need to ship and maintain production agents). Sequence: evaluation gap → control primitives needed.

## Carry-over from W22

- `2026-05-14-anthropic-mcp-legal-platform-playbook` — `g4-approved` (publication sequencing; G4 approve via Paperclip UI)
- `google-a2a-protocol-2026` — `g4-approved` (same — queued for publish-action)
- `claude-for-small-business-distribution-play` — `g3-passed`, Phase 3 fields now added (positions + first_60_words_answer); awaiting G4 + merge conflict resolution in review/pr-55-koea5776
- `2026-05-14-claude-max-chatgpt-pro-dev-org-economics` — `g3-passed`, Phase 3 fields added; same merge conflict gate

## Course pipeline (Q2 goal: 4 complete)

| Course | Chapters | Status | Next action |
|---|---|---|---|
| `gemini-enterprise-agents` | 9 | g3-passed, LIVE | ✅ Course #1 |
| `mcp-from-first-principles-to-production` | 5 | g4-approved | Publish trigger needed — Course #2 |
| `multi-agent-orchestration-a2a` | ch01 ✅, ch04 ✅, ch10 ✅; ch03 rewrite, ch02 in_progress | in_progress | Ch05 activating (KOEA-6978); ch06-ch09 backlog |
| `openai-agents-sdk-mastery` | 0 | g4-approved (outline only) | All 10 chapters need authoring — too late for Q2 |
| `claude-tool-use-from-zero` | 10 | awaiting-g0 | Ch08 G0 re-review (KOEA-2139) blocked; KOEA-6161 in_progress |

**Path to Q2 course goal:**
- Course #3: `claude-tool-use-from-zero` (10 chapters done) once ch08 blocker + ch02 G0 clears
- Course #4: `multi-agent-orchestration-a2a` — needs ch02-ch09 authored in 4 weeks (aggressive)

## Rejected this week

- None — candidate queue is clear; W23 picks exhausted from KOEA-6936 batch.
