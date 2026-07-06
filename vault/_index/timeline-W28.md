---
date: 2026-07-06
agent: vault-historian
updated: 2026-07-06
type: weekly-timeline
tags: [vault, timeline, week-28]
---

# Weekly Timeline W28 (2026)

Period covered: 2026-07-03 to 2026-07-06 (swept 2026-07-06 weekly retro, KOEA-10172).

- Files active in period: ~19 committed (1 blog update, 9 PPC course files, 7 CEO retros, 2 decision/g3 files); 1 untracked research file (community/2026-07-04.md) staged this sweep.
- Active agents/authors: ceo (7 retros), course-architect (PPC course 6 chapters), researcher-community (July 4 daily), vault-historian (daily + weekly).
- Orphans: 0 detected (PPC chapters cross-link each other; 1 title-based wikilink flagged below).
- Frontmatter flags: 1 (see below).
- Broken wikilinks: 0 new. 1 resolved from W27 (`[[glossary/frontier-model]]` stub created).

## Activity Summary

Most active contributors:

- `ceo` (7 retros: KOEA-10097, KOEA-10137, KOEA-10146, KOEA-10147, KOEA-10153, KOEA-10158, KOEA-10159; 1 G3 decision KOEA-10099-g3) — Google brain drain G3-passed; recovery cleanup for Chief Research; G4 notification gap identified; credentials observability pattern formalised.
- `course-architect` — PPC Team Leadership course shipped: 6 chapters + outline + toc, all g0-passed.
- `researcher-community` (da95c278) — daily research July 4: Opus 4.8/Sonnet 5 tool-call schema regression; Zuckerberg enterprise agent admission.
- `vault-historian` — W28 daily sweep (July 6, 41 notes indexed); W28 weekly retro (KOEA-10172, this run).

## Notable Events

### Google Brain Drain Blog G3-Passed (July 3) — KOEA-10099

`blogs/google-brain-drain-enterprise-ai-2026/draft.md` advanced to g3-passed. Title: "Google's 2026 AI Brain Drain Is an Enterprise Signal, Not a Doom Story." CEO G3 retro filed (`retrospectives/ceo/2026-07-03-KOEA-10099-g3.md`); approval `554b10aa-f90e-4835-8842-16197a866a76` issued. G4 human approval pending. Decision file: `decisions/KOEA-10099-g3.md`.

### PPC Team Leadership Course Shipped (July 3–6) — New Career Track

New 6-chapter course committed: `courses/ppc-team-leadership-analyst-onboarding-and-workflow-design/`. Title: "Building & Leading a PPC Analyst Team: From Hiring to High Performance." Course track: career. Level: Advanced. Target: Senior PPC Manager candidates. Total duration: 70 min. All 6 chapters g0-passed. Chapters:

| Chapter | Title | Duration |
|---|---|---|
| ch01 | Designing a 3-4 Person PPC Analyst Team | 18 min |
| ch02 | Skills-Based Hiring & Job Descriptions | 13 min |
| ch03 | Onboarding Analysts with 30-60-90 Day Ramp Plan | 12 min |
| ch04 | Campaign Portfolio & Weekly Accountability Rhythms | 11 min |
| ch05 | Coaching Analysts Through Performance Gaps | 10 min |
| ch06 | Scaling Output with Reporting Automation & AI Workflows | 12 min |

Vendor tags: Google Ads, Meta Ads. Intra-course wikilinks are complete (each chapter references adjacent chapters). Flagged: ch06 contains `[[Designing a 3-4 Person PPC Analyst Team for a Data-Driven Analytics Firm]]` — title-based link that does not match any filename; nearest target is `[[01-designing-ppc-analyst-team-roles]]`.

### Opus 4.8 + Sonnet 5 Tool-Call Schema Regression Signal (July 4)

Community research filed: `research/community/2026-07-04.md`. **Hot signal (2 items):**

1. **Tool-call regression** — Armin Ronacher (Flask/Werkzeug author) published practitioner post on July 4 showing Opus 4.8 and Sonnet 5 invent extra fields in nested array tool schemas. Older models (Sonnet 4.6) do not reproduce the issue. Affects anyone promoting agents to latest Claude models. Recommended blog angle: "Validating tool calls after a Claude model upgrade: a checklist." Affects courses `claude-agent-sdk-zero-to-production`, `claude-mcp-mastery`.

2. **Zuckerberg: agents "haven't progressed as expected"** — Internal Meta town hall (leaked to Reuters July 3, HN frontpage July 4, 92 pts). Zuckerberg said agentic development trajectory over the past 4 months has not accelerated as expected. Meta stock −4.9%. Enterprise-agent over-optimism signal; validates human-in-the-loop design emphasis in academy content.

3. **LocalLLaMA 13-model context benchmark** — Prefill speed (pp65K) not decode speed (tg128) is what matters for production agents at 65K–128K context; KV head count is dominant architectural factor. Most published benchmarks lead with tg128, misleading for agent use cases.

Note: US Independence Day holiday → lighter community traffic on r/PromptEngineering, r/OpenAI, r/Bard.

### CEO SOUL Updates (July 6) — 3 Proposals

Three SOUL change proposals filed on July 6 across CEO retros:

1. **KOEA-10137** — "When closing a stale-run evaluation as recovered, clear the evaluation blocker from the source issue and restore the source to in_progress if the original run is still active." Chief Research stale-run evaluation had been closed without clearing the blocker. Run had already resumed and created KOEA-10148/10149/10150.

2. **KOEA-10159** — "For external analytics credentials, file the operator approval and blocked verifier child in the same heartbeat, with no secret values in comments." Observability work (PostHog KOEA-10159) blocked for 3 WBR cycles on missing credential approval pattern.

3. **KOEA-10153** — Route "manual git push" / vault-sync-stalled tickets to Watchdog Bot first; CEO only arbitrates if Watchdog cannot identify an unblock owner.

### G4 Notification Gap Identified (July 6) — KOEA-10161

CEO retro KOEA-10146: G4 email notification path confirmed working; Slack/Teams webhook missing. KOEA-10161 filed as child to own the chat-route repair. G4 human approval queue is email-only until KOEA-10161 lands.

### Recovery-Wrapper Sweep (July 3)

CEO `retrospectives/ceo/2026-07-03-recovery-wrapper-sweep.md`: batch closure of stale recovery tasks from earlier in the week. Manual-push escalation routing clarified (to Watchdog, not CEO directly).

## Blog Pipeline State (End of W28)

| Slug | Status | Ticket |
|---|---|---|
| google-brain-drain-enterprise-ai-2026 | g3-passed | KOEA-10099 |
| 2026-07-01-openai-jalapeno-chip-inference-costs | g3-passed | KOEA-9973 |
| 2026-07-01-openai-gpt-5-6-government-gate-enterprise-developers | g0-passed | KOEA-9890 |
| anthropic-alibaba-claude-distillation-attack-enterprise-security-2026 | g0-passed | KOEA-9403 |
| anthropic-80-percent-code-threshold-2026-06-16 | g0-passed | KOEA-8794 |
| what-is-artificial-intelligence-types-history-and-future | g0-passed | KOEA-9630 |
| sonnet-5-migration (pending slug) | g0 review | KOEA-9884 |

## Course Pipeline State (End of W28)

| Course | Chapters | Gate |
|---|---|---|
| ppc-team-leadership-analyst-onboarding-and-workflow-design | 6 chapters | all g0-passed (NEW this week) |
| claude-mcp-mastery | ch01–ch06 | ch01 g0-passed, ch02/03/04/06 g3-passed |
| pi-agent-setup-and-usage-2026 | outline, ch01 | g0-passed |
| claude-agent-sdk-zero-to-production | ch07 | g0-passed |

## Wikilink Flags (W28)

| File | Link | Status |
|---|---|---|
| `courses/ppc-team-leadership-analyst-onboarding-and-workflow-design/06-reporting-automation-ai-assisted-workflows.md` | `[[Designing a 3-4 Person PPC Analyst Team for a Data-Driven Analytics Firm]]` | Title-based; no matching filename. Nearest: `[[01-designing-ppc-analyst-team-roles]]`. Flag for course-architect to fix. |

## Frontmatter Flags (W28)

| File | Issue |
|---|---|
| `courses/ppc-team-leadership-analyst-onboarding-and-workflow-design/04-campaign-portfolio-accountability-rhythms.md` | Modified in working tree (not committed at time of W28 daily sweep); staged and committed this weekly retro run. |

## Untracked Assets (W28)

| File | Action |
|---|---|
| `vault/research/community/2026-07-04.md` | Staged and committed this weekly retro run. |
| `vault/courses/claude-mcp-mastery/ch01-audio.mp3` | Binary audio file; outside vault markdown scope. Not indexed. Leave untracked. |

## Archive Check (W28)

Oldest committed vault files date to 2026-04-30 (well within 365-day window). No files eligible for archiving this week.

## Escalation Check (W28)

- **Publish-action daemon**: W28 sweep committed cleanly (58d2b41ac). Daemon confirmed operational.
- **G4 notification gap**: email-only until KOEA-10161 lands. Not a blocker, but chat-path users won't see G4 prompts.
- **Sonnet 5 / Opus 4.8 tool-call regression**: Community signal only; no Anthropic statement yet. Monitor for agent-workflow impact in next research sweep.
- **Meta agents admission**: Enterprise context signal — no action required.
- **PPC ch06 broken title-wikilink**: Flag to course-architect in KOEA issue or comment; not vault-historian's scope to modify content.

## Post-Retro Addendum (2026-07-06 daily sweep)

Two blog drafts committed after the W28 retro run:

| Slug | Status | Ticket |
|---|---|---|
| `build-your-first-mcp-server-python-2026-complete-guide` | draft-for-review | KOEA-10201 |
| `claude-tool-use-in-5-steps-developer-tutorial` | draft-for-review | KOEA-10202 |

- **KOEA-10201**: MCP server Python tutorial. Contrarian angle: silent breaking change on 2026-07-27 (version-pin line prevents it). Positions: mcp-as-interoperability-moat, mcp-as-agent-peer-protocol, prompt-injection-defense-at-boundary. Reading time: 6 min.
- **KOEA-10202**: Claude tool-use 5-step tutorial. Contrarian angle: Sonnet 5 silently rejects sampling params that every older tutorial uses. Positions: stance:harness-over-model. Reading time: 6 min. Parent: KOEA-10189.

Decision plan committed: `decisions/KOEA-10161-plan.md` — Planner spec for G4 chat route repair (Slack + Teams). Estimated complexity: small.

Audit JSONL files staged: `research/community/_audit/2026-07-01-trending.jsonl`, `2026-07-02-trending.jsonl`, `2026-07-04-trending.jsonl` — raw signal source data for the corresponding community daily notes.

Updated blog pipeline state:

| Slug | Status | Ticket |
|---|---|---|
| google-brain-drain-enterprise-ai-2026 | g3-passed | KOEA-10099 |
| 2026-07-01-openai-jalapeno-chip-inference-costs | g3-passed | KOEA-9973 |
| build-your-first-mcp-server-python-2026-complete-guide | draft-for-review | KOEA-10201 |
| claude-tool-use-in-5-steps-developer-tutorial | draft-for-review | KOEA-10202 |
| 2026-07-01-openai-gpt-5-6-government-gate-enterprise-developers | g0-passed | KOEA-9890 |
| anthropic-alibaba-claude-distillation-attack-enterprise-security-2026 | g0-passed | KOEA-9403 |
| anthropic-80-percent-code-threshold-2026-06-16 | g0-passed | KOEA-8794 |
| what-is-artificial-intelligence-types-history-and-future | g0-passed | KOEA-9630 |
| sonnet-5-migration (pending slug) | g0 review | KOEA-9884 |
