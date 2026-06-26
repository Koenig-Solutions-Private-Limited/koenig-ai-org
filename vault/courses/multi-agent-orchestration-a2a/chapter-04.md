---
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8543
course: multi-agent-orchestration-a2a
chapter_num: 4
chapter_title: "Modeling Roles and Capabilities — The Specialized Agent (2026)"
slug: multi-agent-orchestration-a2a-chapter-04
description: "Specialized agents are the atomic unit of a trustworthy A2A network. This chapter applies recursive task decomposition to draw precise role boundaries, designs a capability advertisement with explicit constraints and cost-per-task, and implements a specialist that knows how to say no — and why that refusal is what keeps the network healthy."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 45
reading_time_min: 12
last_updated: 2026-06-15
chapter_primary_query: "how to design specialized agents with capability boundaries and rejection logic in A2A protocol"
first_60_words_answer: "Apply Recursive Task Decomposition to derive narrow role boundaries, then publish explicit constraints and cost-per-task in the Agent Card's skills block. Enforce those boundaries in code by rejecting any task not in ACCEPTED_SKILL_IDS with a structured error that names accepted skills and where to route the rejected one. Role boundaries make the A2A trust model work."
prerequisites_chapters: [2]
learning_objectives:
  - Apply Recursive Task Decomposition to define agent role boundaries with single, unambiguous output contracts
  - Design a Capability Advertisement (Agent Card skills block) that includes explicit constraints and cost-per-task metadata
  - Implement a specialist agent that returns a structured rejection for tasks outside its declared capability scope
  - Explain how Role Contamination erodes the network's trust model and causes system-wide failures in A2A deployments
positions:
  - id: mcp-as-interoperability-moat
    engagement: defends
tags: [A2A, multi-agent, orchestration, role-design, capability-advertisement, specialist-agents, rejection-logic]
status: g0-passed
sources:
  - https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/ # retrieved 2026-06-15
  - https://github.com/a2aproject/A2A/releases/tag/v1.0.0 # retrieved 2026-06-15
  - https://a2a-protocol.org/latest/specification/ # retrieved 2026-06-15
  - https://github.com/a2aproject/A2A # retrieved 2026-06-15
  - https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade # retrieved 2026-06-15
  - https://a2a-protocol.org/latest/topics/agent-discovery/ # retrieved 2026-06-15
faq:
  - question: "What is Recursive Task Decomposition?"
    answer: "Recursive Task Decomposition is a technique for deriving agent role boundaries from a top-level goal. You break the goal into independently completable sub-tasks, then break each sub-task recursively until every leaf meets two criteria: it can be completed without invoking another agent's domain, and it can be described with a single unambiguous output contract. Each leaf becomes a candidate specialist role. The process is recursive, not iterative — you continue subdividing until both criteria are satisfied at every leaf, not just at the first level of decomposition. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "What is Role Contamination, and why is it dangerous?"
    answer: "Role Contamination occurs when a specialist agent begins accepting tasks outside its declared AgentCard scope — typically through a one-off code path added with good intentions. The immediate symptom is invisible: the task succeeds. The latent damage is that the agent now owns two failure domains. When the borrowed scope causes a failure, the error traces back to an agent whose AgentCard says nothing about that task type, making root-cause analysis nearly impossible. At scale — with 150+ organizations integrating on the A2A standard — a single contaminated agent breaks the trust model for every orchestrator that relied on its original capability advertisement. ([Google A2A Announcement, Apr 2025](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/))"
  - question: "Why does a Capability Advertisement need cost-per-task metadata?"
    answer: "Cost transparency lets orchestrators make delegation decisions that go beyond raw capability matching. When two agents can fulfill the same task, an orchestrator with cost metadata can prefer the cheaper option, choose a cached result, or abort a workflow before it exceeds budget. Without cost metadata, the orchestrator must call first and reconcile costs after — which is the same anti-pattern as building an API without rate-limit headers. The cost_per_call_usd field is not in the A2A specification's mandatory schema; it is a production convention that emerges from real multi-agent deployments with real budget constraints. ([A2A GitHub v1.0.0 Release](https://github.com/a2aproject/A2A/releases/tag/v1.0.0))"
---

# Modeling Roles and Capabilities — The Specialized Agent (2026)

> **Chapter 4 of 10 · 45 min (prose ~12 min + 20 min hands-on exercise)**

---

## The Role Boundary Problem

A generalist agent that can "do everything" is an anti-pattern in A2A networks for the same reason a monolith fails in distributed systems: its failure domain is unbounded. When a generalist fails, nothing can replace it because nothing else shares its complete skill set. When a specialist fails, another agent of the same type can absorb its work immediately — the replacement lookup is a single capability query.

The subtler problem is coordination cost. Every agent in an A2A network evaluates incoming tasks against its declared scope. A generalist must map every incoming task class against every capability it possesses. That evaluation is expensive, non-deterministic, and fundamentally at odds with the purpose of the A2A AgentCard. A specialist evaluates tasks against a narrow declared scope. Its answer is binary and deterministic: in scope, or out.

This chapter shows you how to draw role boundaries systematically through decomposition, advertise them precisely in the A2A Agent Card, enforce them programmatically in your dispatch logic, and understand what happens to the entire network when those boundaries erode.

---

## Recursive Task Decomposition

Role boundaries don't emerge from intuition. They emerge from systematic decomposition of a goal into the smallest coherent units of work that can complete independently.

**Recursive Task Decomposition** works in three steps:

1. Start with the top-level goal ("produce a quarterly investment report").
2. Ask: "What are the distinct, independently completable sub-tasks?" List them. For each, recurse.
3. Stop when a candidate unit of work satisfies both exit conditions: (a) it can complete without invoking another agent's domain, and (b) it can be described with a single, unambiguous output contract.

Each leaf of this decomposition tree is a candidate **role**. The agent responsible for that role owns exactly the competencies needed to fulfill it — no more.

For the quarterly investment report, a clean decomposition looks like this:

```
InvestmentReportGoal
├── MarketDataRole        → fetch price history, compute technical metrics
│   └── outputs: TimeSeries[], MetricSummary
├── SentimentAnalystRole  → retrieve news, classify sentiment per ticker
│   └── outputs: SentimentReport
└── FinancialWriterRole   → synthesize data + sentiment into a formatted PDF
    └── inputs: TimeSeries[], MetricSummary, SentimentReport
    └── outputs: PDF blob
```

The recursion terminates here: each leaf completes its task without invoking another leaf's domain. The Writer depends on the other two agents' *outputs* but does not perform their *work*. That distinction is the boundary.

<KnowledgeCheck
  question="When does Recursive Task Decomposition tell you to stop subdividing a task?"
  answers={[
    "When you have exactly three subtasks at any level of the tree",
    "When each unit can complete independently and has a single unambiguous output contract",
    "When each candidate agent uses a different model provider or inference backend",
    "When you run out of skills to assign in the AGNTCY registry"
  ]}
  correct={1}
/>

---

## The Capability Advertisement

An agent's **Capability Advertisement** is its Agent Card, published at `/.well-known/agent.json`. This document is the formal contract between your specialist and every orchestrator that might hire it. The wire format of the AgentCard — including the `name`, `url`, and `capabilities` envelope — was established in [[multi-agent-orchestration-a2a/chapter-02|Chapter 2: A2A Protocol Architecture]]. The A2A specification defines the required envelope; the quality of your system depends on how precisely you fill in the `skills` block. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))

A minimal skills entry looks like this:

```json
{
  "skills": [
    {
      "id": "market-data-fetch",
      "name": "Historical Market Data Retrieval",
      "description": "Fetches daily OHLCV price data and computes technical indicators for a given ticker and date range.",
      "tags": ["finance", "market-data", "time-series"],
      "examples": ["fetch AAPL 2025-01-01 to 2025-12-31 with RSI and MACD"]
    }
  ]
}
```

That entry is readable, but it leaves every orchestrator guessing about the agent's actual limits. For production A2A deployments, your advertisement must add explicit **constraints** and **cost metadata**:

```json
{
  "skills": [
    {
      "id": "market-data-fetch",
      "name": "Historical Market Data Retrieval",
      "description": "Fetches daily OHLCV price data and computes RSI, MACD, and Bollinger Bands for up to 5 tickers per call over a maximum 2-year window.",
      "constraints": {
        "max_tickers_per_call": 5,
        "max_date_range_days": 730,
        "supported_exchanges": ["NYSE", "NASDAQ", "LSE"],
        "output_format": "application/json",
        "cost_per_call_usd": 0.004
      },
      "input_schema": { "$ref": "#/components/schemas/MarketDataRequest" },
      "output_schema": { "$ref": "#/components/schemas/MarketDataResponse" }
    }
  ]
}
```

The `cost_per_call_usd` field is not prescribed by the A2A specification's mandatory schema — it is a production convention. But it is not optional in real deployments. Orchestrators with cost visibility can choose between two equally capable specialists based on price, prefer a cached result, or halt a workflow before it overshoots its budget allocation. Cost transparency is a form of coordination infrastructure.

<Callout type="hot">
  The [A2A v1.0.0 release](https://github.com/a2aproject/A2A/releases/tag/v1.0.0) introduced the Agentspace marketplace where published agent skills are indexed and discoverable across organizations. Agents with richer, constraint-explicit advertisements surface first in capability queries — because the indexer can answer a filtered search ("find a finance agent that handles LSE tickers and costs under $0.01/call") without calling the agent first. A vague skills block is invisible to filtered discovery. The registry and discovery mechanics that power Agentspace are covered in [[multi-agent-orchestration-a2a/chapter-03|Chapter 3: AGNTCY & Global Discovery]].
</Callout>

---

## Implementing the Specialist: Rejection Logic

A specialist without rejection logic is not a specialist — it is a generalist with a dishonest AgentCard. If your agent silently accepts tasks outside its declared scope, every orchestrator that relies on your capability advertisement will fail in ways that are difficult to trace.

The implementation is straightforward. The discipline is non-negotiable:

```python
from typing import Any
from dataclasses import dataclass

ACCEPTED_SKILL_IDS = {"market-data-fetch"}

@dataclass
class A2ATask:
    task_id: str
    skill_id: str
    params: dict[str, Any]

def dispatch(task: A2ATask) -> dict:
    if task.skill_id not in ACCEPTED_SKILL_IDS:
        return {
            "jsonrpc": "2.0",
            "id": task.task_id,
            "error": {
                "code": -32601,
                "message": f"Skill '{task.skill_id}' is outside this agent's capability scope.",
                "data": {
                    "accepted_skills": list(ACCEPTED_SKILL_IDS),
                    "suggested_action": (
                        "Query your AGNTCY registry for an agent "
                        f"with skill '{task.skill_id}' declared in its AgentCard."
                    ),
                }
            }
        }
    return handle_market_data(task.params)
```

The structured `data` payload in the error response is deliberate. It tells the orchestrator exactly what skills this agent accepts and where to look for an agent that handles the rejected one. A good rejection response closes the routing loop; a silent failure or a generic error forces the orchestrator to guess — or worse, to retry.

<KnowledgeCheck
  question="What makes a specialist's rejection response operationally useful rather than just an error signal?"
  answers={[
    "Returning HTTP 418 (I'm a Teapot) to trigger the orchestrator's standard retry-with-backoff logic",
    "Including accepted_skills and a suggested_action so the orchestrator can reroute without guessing",
    "Logging the rejection to a centralized ledger before returning an empty JSON body",
    "Returning HTTP 200 with a null result to avoid breaking orchestrator state machines"
  ]}
  correct={1}
/>

---

## Role Contamination

**Role Contamination** is what happens when a specialist begins accepting tasks outside its declared scope — almost always through a well-intentioned "just this once" code path. A developer adds a branch to handle a task type that was "close enough." The AgentCard is not updated. The task succeeds. Nobody notices.

The damage is latent. The contaminated agent now owns two failure domains: its own and the borrowed one. When the borrowed scope causes a failure, the error traces back to an agent whose AgentCard says nothing about that task type. Debugging becomes a guessing game. At scale — with 150+ organizations integrating on the same [A2A standard](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) — a single contaminated agent breaks the capability trust model for every orchestrator that relied on its original advertisement. Discovery becomes unreliable. The entire benefit of the protocol erodes.

The antidote is treating `ACCEPTED_SKILL_IDS` as an immutable runtime constant. Capability expansion is a **deployment-time decision**, not a runtime decision. Adding a new skill requires an AgentCard update, a code change, a test, and a new deployment — not a one-liner in the dispatch function. If those steps feel expensive for a small change, that feeling is correct. Role boundaries are expensive to draw and cheap to maintain. Contamination is cheap to introduce and expensive to remediate.

---

## Hands-On Exercise: Refactor a Generalist into a Researcher Specialist

**Time estimate:** 20 minutes

You have a generalist agent with five declared skills in its AgentCard:

```json
{
  "skills": [
    { "id": "web-search",   "name": "Web Search" },
    { "id": "pdf-read",     "name": "PDF Reader" },
    { "id": "sql-query",    "name": "SQL Query" },
    { "id": "email-send",   "name": "Email Sender" },
    { "id": "report-write", "name": "Report Writer" }
  ]
}
```

**Step 1 — Apply decomposition.** Using the Recursive Task Decomposition technique from this chapter, identify which skills belong exclusively to a "Researcher" specialist. The Researcher's role: find and retrieve information from public web and internal data sources; return structured summaries. It does not produce final deliverables and does not send communications.

**Step 2 — Write the capability advertisement.** Draft a complete `skills` block for the Researcher's Agent Card. For each in-scope skill, include:
- A `description` that specifies the output format and any key restrictions
- A `constraints` block with at least: `max_query_length`, `output_format`, and `supported_sources`
- A `cost_per_call_usd` estimate

**Step 3 — Implement rejection logic.** Write the `dispatch()` function for the Researcher agent. It must:
- Accept only the skills identified in Step 1
- Return a structured error for any out-of-scope skill, with `accepted_skills` and `suggested_action`

**Success criteria:**
- Calling `dispatch` with `skill_id="report-write"` returns a structured error that names the correct agent type to route to
- The Researcher's AgentCard contains no skills from the Writer or Communicator roles
- Each in-scope skill entry has a non-empty `constraints` block and a `cost_per_call_usd` value

---

## What's Next

You now have a specialist that knows what it can do, advertises it precisely, and refuses everything else. The next challenge is giving that specialist the tools it needs to do its job — without hard-coding tool access into its own runtime.

[[multi-agent-orchestration-a2a/chapter-05|Chapter 5: Tool-Sharing & Resource Injection with MCP]] shows how an orchestrator injects external data sources into a specialist via MCP, and how two agents from different vendors share tool execution without sharing code or credentials.

---

*Sources: [Google A2A Announcement, Apr 2025](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) · [A2A GitHub v1.0.0 Release](https://github.com/a2aproject/A2A/releases/tag/v1.0.0) · [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [A2A GitHub Repository](https://github.com/a2aproject/A2A)*
