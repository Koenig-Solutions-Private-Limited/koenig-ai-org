---
course: multi-agent-orchestration-a2a
chapter_num: 4
chapter_title: "Modeling Roles and Capabilities — The Specialized Agent (2026)"
author: course-author
ticket: KOEA-6977
date: 2026-05-31
status: draft-for-review
level: Advanced
duration_min: 45
reading_time_min: 12
prerequisites_chapters:
  - 2
learning_objectives:
  - Apply Recursive Task Decomposition to identify where one agent ends and the next begins, producing a role boundary definition for each specialist
  - Design a Capability Advertisement that encodes constraints, cost-per-task estimates, and latency SLOs alongside the standard A2A skills schema
  - Implement a Specialist agent in Python that validates every incoming task against its declared scope and returns a TaskRejectedError for out-of-scope requests
  - Explain the Role Contamination failure mode — how a specialist that "also" accepts adjacent tasks eventually fails at everything, system-wide
positions:
  - id: stance:open-standards-over-vendor-lock-in
    engagement: defends
  - id: stance:specialized-agents-over-generalists
    engagement: defends
chapter_primary_query: "how to model agent roles and capabilities in A2A protocol specialist agent"
first_60_words_answer: "In A2A, a specialist agent's role is defined by its skills array — the capability advertisement — combined with active scope enforcement in code. To model roles correctly: decompose the task graph recursively until each leaf node does exactly one thing; then encode that one thing as a Skill with explicit constraints and cost estimates; and reject all other tasks with a TaskRejectedError."
faq:
  - question: "What is Recursive Task Decomposition in multi-agent systems?"
    answer: "Recursive Task Decomposition is the process of breaking a complex goal into sub-tasks, then breaking each sub-task into further sub-tasks, until each leaf node is narrow enough that a single-purpose agent can handle it without needing context from other domains. The decomposition boundary becomes the agent's role boundary."
  - question: "What is a Capability Advertisement in A2A and what should it include?"
    answer: "A Capability Advertisement is the skills array in an A2A AgentCard. Each Skill entry declares the agent's unique task type (id, name, description), accepted input and output modes (text, file, data, image), and discovery tags. Extended best practice adds a constraints object (file size limits, language requirements, schema version) and cost-per-task and p95-latency estimates so orchestrators can make informed hiring decisions."
  - question: "How does scope enforcement work in an A2A specialist agent?"
    answer: "Before processing any task, the specialist validates the incoming sendMessage payload against its declared capability scope: checking the requested skill ID, input modes, and any schema constraints. If the task doesn't match, the agent immediately returns a TaskRejectedError with a message explaining the mismatch. This is implemented at the middleware layer before the LLM is ever called, keeping rejection cheap."
  - question: "What is Role Contamination in A2A networks?"
    answer: "Role Contamination happens when a specialist agent begins accepting tasks outside its declared scope — initially as a 'favor' to unblock a workflow, gradually as a permanent informal expansion. The agent's internal context window becomes polluted with cross-domain knowledge, its reasoning quality drops on both the original task AND the new tasks, and the system loses the clean boundaries that made it debuggable. It is the most common cause of unexplained quality degradation in production A2A networks."
  - question: "How do you price tasks in a Capability Advertisement?"
    answer: "Add a metadata.economics object to each Skill in the AgentCard with three fields: cost_usd_estimate (expected LLM + tool cost per invocation), latency_p95_ms (95th-percentile completion time in milliseconds), and throughput_rps (maximum concurrent requests the agent can handle). These allow orchestrators to build cost models before hiring — choosing the cheapest sufficient agent rather than defaulting to the most capable one."
inline_assets:
  - type: diagram
    path: ./img/ch04-recursive-decomposition.png
    alt: "Recursive Task Decomposition tree: root node 'Produce investment research report' branches into three intermediate nodes: 'Gather market data', 'Analyze sentiment', and 'Write final report'. Each intermediate node branches further — 'Gather market data' into 'Query historical prices' and 'Fetch SEC filings'; 'Analyze sentiment' into 'Scrape news headlines' and 'Score sentiment'; 'Write final report' into 'Synthesize findings' and 'Format PDF'. Leaf nodes are each labeled as a single specialized agent role."
  - type: diagram
    path: ./img/ch04-scope-enforcement-flow.png
    alt: "A2A scope enforcement middleware flow: incoming sendMessage JSON-RPC request arrives; middleware layer checks skill ID against declared skills list (mismatch → TaskRejectedError returned immediately); checks inputModes against acceptedInputModes (mismatch → TaskRejectedError); validates constraints object (file size, language, schema version — violation → TaskRejectedError); all checks pass → task forwarded to LLM core. Three rejection paths exit before the LLM is ever invoked."
last_updated: 2026-05-31
sources:
  - https://a2a-protocol.org/latest/specification/
  - https://a2a-protocol.org/latest/topics/agent-discovery/
  - https://github.com/a2aproject/A2A
  - https://docs.agntcy.org/oasf/open-agentic-schema-framework/
  - https://modelcontextprotocol.io/introduction
  - https://agntcy.org/
---

# Modeling Roles and Capabilities — The Specialized Agent (2026)

> **Chapter 4 of 10 · 45 min (prose ~12 min + 25 min hands-on exercise)**

---

In A2A, a specialist agent's role is defined by its `skills` array — the capability advertisement — combined with active scope enforcement in code. To model roles correctly: decompose the task graph recursively until each leaf node does exactly one thing; then encode that one thing as a Skill with explicit constraints and cost estimates; and reject all other tasks with a `TaskRejectedError`. An agent that accepts everything is a wrapper around an LLM, not a specialist.

Chapter 3 showed you how agents find each other through AGNTCY registries and AgentCard discovery. This chapter answers the harder question: once found, what *exactly* should an agent agree to do — and what should it refuse? The answer isn't philosophical. It's encoded in your AgentCard and enforced in your middleware.

---

## The Contrarian Opening: "Do Everything" Is an Architecture Bug

The most common first-iteration agent design is the Swiss Army Knife: one agent, 50 tools, a 4,000-token system prompt, and the instruction to "figure it out." This works in demos. It fails in production for three compounding reasons.

**First: Prompt entropy.** The more domains you pack into a system prompt, the more the model must context-switch mid-reasoning. A prompt that covers both "analyze financial risk" and "draft legal summaries" and "translate technical specs to plain English" forces the model to hold three different cognitive frames simultaneously. The result is reasoning that is mediocre at all three rather than excellent at one.

**Second: Undebuggable failures.** When a Swiss Army Knife agent produces wrong output, you cannot tell which "tool" failed. Did the legal summary fail because the risk analysis was wrong and the summarizer trusted it? Or because the translation step introduced drift? You can't isolate the cause. You rerun the entire system with different prompts and hope.

**Third: Cost opacity.** If one agent does everything, you can't measure which tasks are cheap and which are expensive. You can't optimize. You can't price. You can't decide when to substitute a cheaper model for a cheaper sub-task. The bill just goes up.

The A2A protocol was designed for a fundamentally different architecture: **many narrow specialists, each excellent at one thing, collaborating through a standard protocol**. This chapter teaches you how to design those specialists — starting from task decomposition and ending with a working scope-enforcement implementation.

---

## Step 1: Recursive Task Decomposition

Before you write a single line of A2A code, you need to answer: what are the leaf-node tasks in this system? Recursive Task Decomposition is the method.

Start with the system's top-level goal. Ask: "Can a single agent, with a single coherent skill and a reasonable context window, complete this entire goal in one invocation?" If yes, it's already a leaf. If no, split it into 2–4 sub-goals. Repeat.

**Example: Investment Research Report**

```
Goal: Produce an investment research report on Company X

├─ Sub-goal A: Gather structured data
│    ├─ Leaf 1: Query historical stock prices (Market Data Agent)
│    └─ Leaf 2: Fetch SEC 10-K filings and parse financials (Filings Agent)
│
├─ Sub-goal B: Analyze qualitative signals
│    ├─ Leaf 3: Scrape recent news headlines (News Fetcher Agent)
│    └─ Leaf 4: Score sentiment per headline (Sentiment Analyst Agent)
│
└─ Sub-goal C: Synthesize and format
     ├─ Leaf 5: Merge structured data + sentiment into findings (Synthesis Agent)
     └─ Leaf 6: Format findings as a PDF report (Writer Agent)
```

Each leaf node becomes one specialist agent. The boundary test at each split is:

1. **Single-domain knowledge**: does completing this leaf require expertise in only one domain? The Filings Agent knows SEC schema; it does not need to understand sentiment scoring.
2. **Bounded output contract**: does this leaf produce exactly one artifact type with a predictable schema? The Sentiment Analyst outputs `{score: float, category: string}` per headline. Not "here's what I found."
3. **Independent replaceability**: if this leaf's model is swapped, does that change anything downstream? If yes, the contract is too loose — tighten the output schema.

When your decomposition satisfies all three criteria at every leaf, you have your agent roster.

<Callout type="hot">
  The A2A specification's Skill model directly encodes the leaf-node contract from your decomposition. The `id`, `description`, `inputModes`, and `outputModes` fields in a Skill are not documentation — they are the machine-readable boundary definition that registries, orchestrators, and other agents use to decide whether your agent is the right hire for a task.
</Callout>

---

## Step 2: Designing the Capability Advertisement

With your leaf-node roles defined, you now encode each one as an A2A Capability Advertisement. The base structure from Chapter 2 covers the essentials. For production specialist agents, you need three additional layers.

### Layer 1: The Core Skill (what you already know)

```json
{
  "id": "earnings-sentiment-scorer",
  "name": "Earnings Call Sentiment Scorer",
  "description": "Analyzes earnings call transcript text and returns a JSON array of sentiment findings. Each finding includes: the quoted passage (string), a sentiment score (-1.0 to 1.0 float), a category (positive|negative|neutral), and a topic tag (guidance|revenue|margins|headcount|outlook). Input must be plain text. Output is a JSON DataPart.",
  "inputModes": ["text"],
  "outputModes": ["data"],
  "tags": ["finance", "sentiment", "NLP", "earnings", "structured-output"]
}
```

The description is a job description, not a function signature. It describes the input format, the output schema, and the domain — everything an orchestrator needs to decide whether to hire this agent.

### Layer 2: Constraints (what the Skill doesn't handle)

Constraints define the negative space — the explicit list of inputs the agent will reject. Without explicit constraints, orchestrators will send you out-of-scope tasks and be surprised when you reject them.

Add a `metadata.constraints` object to the AgentCard:

```json
{
  "metadata": {
    "constraints": {
      "max_transcript_length_chars": 150000,
      "accepted_languages": ["en"],
      "min_a2a_version": "1.0",
      "required_schema_version": "earnings-v2",
      "no_audio_input": true,
      "no_real_time_data": true
    }
  }
}
```

Every constraint must be enforceable at the middleware layer before the LLM is invoked. If you can't check it in code, don't list it — listing an unenforceable constraint creates false confidence.

### Layer 3: Economics (what the Skill costs and how fast it responds)

This is the layer most teams skip and later regret. Add cost and latency estimates to each Skill so orchestrators can build cost models:

```json
{
  "metadata": {
    "economics": {
      "cost_usd_estimate": 0.035,
      "latency_p95_ms": 4200,
      "throughput_rps": 8
    }
  }
}
```

| Field | Description |
|---|---|
| `cost_usd_estimate` | Expected LLM + tool cost per single invocation at median input size. Not a hard cap — a planning signal. |
| `latency_p95_ms` | 95th-percentile task completion time. Orchestrators use this to set `getTask` polling intervals and timeout thresholds. |
| `throughput_rps` | Maximum concurrent requests. Orchestrators can use this to implement backpressure rather than queuing unbounded tasks. |

Without economics in the capability advertisement, your orchestrator is flying blind: it doesn't know whether to hire the cheap-but-slow agent or the fast-but-expensive one. It can't optimize multi-leg workflows for cost vs. latency. It can't warn users when a workflow will exceed budget.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt={`You are designing the Capability Advertisement for a specialist A2A agent called the "SEC Filings Parser."

This agent's role (as defined by Recursive Task Decomposition): parse SEC 10-K and 10-Q filings in XBRL or plain text format and extract a structured JSON object containing: company_name (string), fiscal_period (string), revenue_usd (float), net_income_usd (float), operating_cash_flow_usd (float), total_debt_usd (float), and key_risk_factors (array of strings, max 5).

Write the complete A2A AgentCard JSON for this agent. Include:
1. name, description, url (use a placeholder), version, protocolVersion
2. capabilities: streaming: true, pushNotifications: false
3. skills: one Skill entry with id, name, description, inputModes (text and file), outputModes (data), and 5 tags
4. metadata.constraints: max file size 10MB, accepted formats ["xbrl", "text/plain"], max_fiscal_periods_per_call: 4, accepted_languages: ["en"]
5. metadata.economics: cost_usd_estimate: 0.018, latency_p95_ms: 3500, throughput_rps: 12
6. defaultInputModes: ["text", "file"]
7. defaultOutputModes: ["data"]
8. securitySchemes: use oauth2 clientCredentials pointing to "https://auth.example.internal/token" with scope "a2a:tasks:write"

Format as clean, properly indented JSON.`}
  expectedOutput={`{
  "name": "SEC Filings Parser",
  "description": "Parses SEC 10-K and 10-Q filings in XBRL or plain text and extracts structured financial data.",
  "url": "https://sec-filings-parser.internal/a2a",
  "version": "1.0.0",
  "protocolVersion": "1.0",
  "capabilities": {
    "streaming": true,
    "pushNotifications": false
  },
  "skills": [
    {
      "id": "sec-filing-extraction",
      "name": "SEC Filing Financial Extractor",
      "description": "Parses SEC 10-K and 10-Q filings (XBRL or plain text) and returns a structured JSON object with company_name, fiscal_period, revenue_usd, net_income_usd, operating_cash_flow_usd, total_debt_usd, and key_risk_factors (max 5 items).",
      "inputModes": ["text", "file"],
      "outputModes": ["data"],
      "tags": ["finance", "SEC", "XBRL", "10-K", "structured-output"]
    }
  ],
  "metadata": {
    "constraints": {
      "max_file_size_mb": 10,
      "accepted_formats": ["xbrl", "text/plain"],
      "max_fiscal_periods_per_call": 4,
      "accepted_languages": ["en"]
    },
    "economics": {
      "cost_usd_estimate": 0.018,
      "latency_p95_ms": 3500,
      "throughput_rps": 12
    }
  },
  "defaultInputModes": ["text", "file"],
  "defaultOutputModes": ["data"],
  "securitySchemes": {
    "oauth2": {
      "type": "oauth2",
      "flows": {
        "clientCredentials": {
          "tokenUrl": "https://auth.example.internal/token",
          "scopes": {
            "a2a:tasks:write": "Submit tasks to this agent"
          }
        }
      }
    }
  },
  "security": [{"oauth2": ["a2a:tasks:write"]}]
}`}
/>

---

## Step 3: Scope Enforcement — The Agent That Says No

Declaring a narrow capability in your AgentCard is necessary but not sufficient. Without runtime enforcement, your specialist becomes a soft-limit generalist: any orchestrator that sends an out-of-scope task will quietly get a degraded result instead of a clear error.

Scope enforcement means validating every incoming task **before the LLM is invoked**. This is your middleware layer.

### Why Before the LLM?

If you let the LLM decide whether a task is in-scope, two bad things happen:

1. **Cost**: you spend tokens on a task you were never going to complete correctly.
2. **False compliance**: LLMs are trained to be helpful. A sentiment analysis agent asked to "just summarize this contract too" will often try — and produce a mediocre, expensive, un-auditable result that the orchestrator mistakes for a valid output.

Pre-LLM rejection is cheap, deterministic, and auditable.

### Implementation: Scope Middleware in Python

```python
from dataclasses import dataclass
from typing import Any
import json


@dataclass
class TaskRejectedError(Exception):
    code: int
    message: str
    data: dict[str, Any]

    def to_jsonrpc_error(self) -> dict:
        return {
            "code": self.code,
            "message": self.message,
            "data": self.data
        }


DECLARED_SKILL_IDS = {"earnings-sentiment-scorer"}
ACCEPTED_INPUT_MODES = {"text"}
MAX_TRANSCRIPT_LENGTH = 150_000
ACCEPTED_LANGUAGES = {"en"}


def validate_scope(message: dict) -> None:
    """
    Validates an incoming A2A sendMessage payload against declared scope.
    Raises TaskRejectedError if the task falls outside the agent's capability.
    Must be called before the LLM is ever invoked.
    """
    params = message.get("params", {})
    msg = params.get("message", {})

    # 1. Validate skill ID (if caller specified one in metadata)
    requested_skill = params.get("metadata", {}).get("skillId")
    if requested_skill and requested_skill not in DECLARED_SKILL_IDS:
        raise TaskRejectedError(
            code=-32001,
            message="Task rejected: requested skill is not offered by this agent.",
            data={
                "requested_skill": requested_skill,
                "offered_skills": list(DECLARED_SKILL_IDS),
                "resolution": "Query the AgentCard at /.well-known/agent.json for the correct skill ID."
            }
        )

    # 2. Validate input modes
    parts = msg.get("parts", [])
    received_modes = {part["kind"] for part in parts}
    unsupported = received_modes - ACCEPTED_INPUT_MODES
    if unsupported:
        raise TaskRejectedError(
            code=-32002,
            message=f"Task rejected: input mode(s) {unsupported} not accepted by this agent.",
            data={
                "received_modes": list(received_modes),
                "accepted_modes": list(ACCEPTED_INPUT_MODES),
                "resolution": "Send transcript as a text Part only. Audio and file inputs are not supported."
            }
        )

    # 3. Validate constraints: transcript length
    full_text = " ".join(
        part["text"] for part in parts if part.get("kind") == "text"
    )
    if len(full_text) > MAX_TRANSCRIPT_LENGTH:
        raise TaskRejectedError(
            code=-32003,
            message=f"Task rejected: transcript exceeds maximum length of {MAX_TRANSCRIPT_LENGTH:,} characters.",
            data={
                "received_length": len(full_text),
                "max_length": MAX_TRANSCRIPT_LENGTH,
                "resolution": "Split the transcript and send in multiple tasks, one quarter per call."
            }
        )


def handle_sendMessage(request_body: dict) -> dict:
    try:
        validate_scope(request_body)
    except TaskRejectedError as err:
        return {
            "jsonrpc": "2.0",
            "error": err.to_jsonrpc_error(),
            "id": request_body.get("id")
        }

    # Scope validated — safe to invoke LLM
    return invoke_llm_core(request_body)
```

### What the Rejection Response Looks Like

When `validate_scope` raises `TaskRejectedError`, the caller receives:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32001,
    "message": "Task rejected: requested skill is not offered by this agent.",
    "data": {
      "requested_skill": "contract-risk-analysis",
      "offered_skills": ["earnings-sentiment-scorer"],
      "resolution": "Query the AgentCard at /.well-known/agent.json for the correct skill ID."
    }
  },
  "id": "req-045"
}
```

The `resolution` field is essential: it tells the calling orchestrator exactly what to do next. A rejection without a resolution is an error message; a rejection with a resolution is a redirect. Orchestrators that parse the `resolution` field can automatically find the correct agent and retry — no human required.

<KnowledgeCheck
  question="A developer is building a Sentiment Analyst specialist agent. Which of the following rejection checks should be implemented BEFORE the LLM is invoked?"
  answers={[
    "Check whether the user's account has billing enabled",
    "Check whether the incoming task's requested skill ID matches the agent's declared skills, and whether the input mode (e.g. audio) is in the agent's acceptedInputModes",
    "Ask the LLM to decide if the task is relevant to its domain",
    "Check whether a similar task was completed successfully in the past 24 hours"
  ]}
  correct={1}
/>

<Callout type="warning">
  **Error codes in the -32000 to -32099 range are reserved for A2A application-level errors.** Use `-32001` through `-32010` for scope-enforcement rejections, allocating a distinct code per rejection type (skill mismatch, input mode mismatch, constraint violation, etc.). This lets orchestrators handle rejection subtypes programmatically without parsing the human-readable `message` field.
</Callout>

---

## Role Contamination: How Specialists Die

You've implemented scope enforcement. Your agent rejects out-of-scope tasks with clear errors. This is the correct design.

Now imagine production pressure: an orchestrator sends a task that's "almost" in scope. A developer on your team says "it's just this one time — let it through." They comment out the scope check for that task type. The workflow unblocks. No one reverts the change.

Three months later, your "Earnings Sentiment Analyst" is also doing contract risk analysis, news summarization, and ad-hoc SQL query interpretation. Nobody planned this. Each expansion made local sense at the time. But the cumulative effect is **Role Contamination** — and it is the most common cause of unexplained quality degradation in production A2A networks.

### Why Role Contamination Destroys Quality

The damage is not obvious until it compounds:

**1. Prompt entropy at scale.** Every capability you add to an agent's effective scope requires additional context in its system prompt (or implicit in its training/fine-tuning). By the time a specialist handles five "edge case" task types, its system prompt is 6,000 tokens of conflicting instructions. The model's attention is spread thin across five domains simultaneously.

**2. Evaluation becomes impossible.** You cannot measure quality for an agent that does five things. You'd need five separate evaluation datasets, five sets of golden answers, five metrics. In practice, teams measure "did it complete?" not "was the output correct?" Contaminated agents that produce wrong output at low rates are invisible in production until a downstream decision is made on bad data.

**3. The Discovery Registry lies.** Your AgentCard still declares one skill: `earnings-sentiment-scorer`. But the agent now accepts five task types. Any registry or orchestrator that trusts the AgentCard will make incorrect hiring decisions. The gap between declared capability and actual behavior is the definition of an unreliable service.

**4. Cascading failures.** When the contaminated agent degrades (model update, increased load, ambiguous new task), it fails across all five task types at once. In a clean network, a failure in the Earnings Sentiment Agent is contained — the Orchestrator can hire a backup. In a contaminated network, the "Earnings Sentiment Agent" is also the only agent that does contract risk and SQL queries. Its failure propagates system-wide.

### The Discipline: Scope Is a Contract, Not a Guideline

Treat your agent's declared scope as a binding contract, enforced in code. The technical enforcement (the `validate_scope` middleware above) is the guard. But the organizational discipline matters equally:

- **No undeclared task types are accepted, ever.** If a new task type is valid, update the AgentCard, write new evaluation cases, and add a new scope check. Do not quietly extend the agent.
- **Scope expansions go through AgentCard versioning.** When a new skill is added, the AgentCard `version` field increments. Registries and orchestrators that cache AgentCards are notified.
- **Audit contamination quarterly.** Log every incoming task's skill ID. Compare the logged distribution against the declared `skills`. Any skill ID in the logs that's not in the AgentCard is a contamination event.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt={`You are auditing the task log of a specialist agent that declares only one skill in its AgentCard: skill id "earnings-sentiment-scorer". The agent was supposed to analyze only earnings call transcripts.

Here is a sample from the agent's task log (20 tasks, each showing the skill_id the orchestrator sent in the request metadata):

earnings-sentiment-scorer
earnings-sentiment-scorer
contract-risk-check
earnings-sentiment-scorer
news-headline-summarizer
earnings-sentiment-scorer
contract-risk-check
earnings-sentiment-scorer
sql-query-interpretation
earnings-sentiment-scorer
earnings-sentiment-scorer
contract-risk-check
earnings-sentiment-scorer
news-headline-summarizer
earnings-sentiment-scorer
earnings-sentiment-scorer
sql-query-interpretation
earnings-sentiment-scorer
contract-risk-check
earnings-sentiment-scorer

Analyze this log and produce:
1. A Role Contamination Report with: total tasks, in-scope count and percentage, out-of-scope count and percentage, a breakdown of out-of-scope skill IDs and their frequencies.
2. A severity assessment: is this mild contamination (<10% OOS), moderate (10-30% OOS), or severe (>30% OOS)?
3. Three concrete remediation steps, ordered by priority.`}
  expectedOutput={`## Role Contamination Audit Report
**Agent:** earnings-sentiment-scorer
**Log window:** 20 tasks

### Task distribution
| Skill ID | Count | % |
|---|---|---|
| earnings-sentiment-scorer (IN SCOPE) | 13 | 65% |
| contract-risk-check (OUT OF SCOPE) | 4 | 20% |
| news-headline-summarizer (OUT OF SCOPE) | 2 | 10% |
| sql-query-interpretation (OUT OF SCOPE) | 1 | 5% |

### Summary
- **In-scope tasks:** 13 / 20 (65%)
- **Out-of-scope tasks:** 7 / 20 (35%)

### Severity Assessment
**SEVERE** — 35% of tasks are out of scope, exceeding the 30% threshold. The agent is operating as a de facto generalist. Quality degradation on the primary skill (earnings-sentiment-scorer) is highly likely.

### Remediation (priority order)
1. **Immediate: Re-enable scope enforcement middleware.** Audit the codebase for commented-out or bypassed `validate_scope` checks. Restore strict rejection of contract-risk-check, news-headline-summarizer, and sql-query-interpretation task types.
2. **Short-term: Audit the orchestrators.** Identify which orchestrators sent the 7 out-of-scope tasks. Update their agent-selection logic to route these tasks to the correct specialists (or commission the missing specialists if they don't exist).
3. **Structural: Establish a scope-change governance process.** Any future capability expansion must include: AgentCard version bump, new evaluation dataset, peer review of the updated scope check. No silent extensions.`}
/>

---

## Cost Modeling in Practice: Making Economics Machine-Readable

The economics layer in your Capability Advertisement is most useful when the Orchestrator knows how to read and act on it. Here is a concrete pattern.

### The Orchestrator's Hiring Decision

Before hiring a specialist for a task, an Orchestrator that implements cost modeling does:

```python
def select_agent(capability_required: str, budget_usd: float, deadline_ms: int) -> str:
    """
    Selects the best available agent for a capability, given budget and deadline.
    Returns the selected agent's URL.
    """
    candidates = registry.query_capability(capability_required)

    affordable = [
        agent for agent in candidates
        if agent["metadata"]["economics"]["cost_usd_estimate"] <= budget_usd
    ]
    if not affordable:
        raise NoBudgetError(
            f"No agent for '{capability_required}' within budget ${budget_usd:.3f}. "
            f"Cheapest available: ${min(a['metadata']['economics']['cost_usd_estimate'] for a in candidates):.3f}"
        )

    fast_enough = [
        agent for agent in affordable
        if agent["metadata"]["economics"]["latency_p95_ms"] <= deadline_ms
    ]
    if not fast_enough:
        # Relax: pick the fastest affordable agent even if it misses the deadline
        fast_enough = sorted(affordable, key=lambda a: a["metadata"]["economics"]["latency_p95_ms"])

    # Among affordable + fast enough, pick the cheapest
    selected = min(fast_enough, key=lambda a: a["metadata"]["economics"]["cost_usd_estimate"])
    return selected["url"]
```

This is a five-line hiring algorithm that becomes possible only because your Capability Advertisement includes economics. Without `cost_usd_estimate` and `latency_p95_ms`, the Orchestrator defaults to the first available agent — usually the most expensive.

### Keeping Cost Estimates Accurate

Cost estimates in AgentCards become stale. Model API pricing changes. Task complexity drifts as the orchestrator's prompts evolve. Establish a quarterly update cadence:

1. **Instrument every invocation.** Log the actual cost (from the model API response's `usage` field) and wall-clock latency for every task.
2. **Compute rolling P95.** Use the last 30 days of invocations to update `latency_p95_ms`.
3. **Update the AgentCard.** Bump the `version` field and push the updated card to the registry. The registry propagates the update; orchestrators re-fetch during their next AgentCard cache TTL cycle.

<KnowledgeCheck
  question="An orchestrator finds three candidate agents for a 'financial-news-summarization' task. Agent A: cost $0.04, P95 latency 2,000ms. Agent B: cost $0.02, P95 latency 8,000ms. Agent C: cost $0.06, P95 latency 900ms. The budget is $0.03 and the deadline is 5,000ms. Which agent should the orchestrator hire, and why?"
  answers={[
    "Agent A — it's the fastest agent within budget",
    "Agent B — it's within budget ($0.02 < $0.03) and within deadline (8,000ms is close enough)",
    "Agent B — it's within budget ($0.02 < $0.03) and meets the deadline (8,000ms > 5,000ms, so it misses, but it's the only affordable option; orchestrator should relax the deadline or raise a NoBudgetError for the fast option)",
    "Agent C — it has the lowest latency"
  ]}
  correct={2}
/>

---

## Hands-On Exercise: Refactor a Generalist into a Researcher Specialist

**Time estimate:** 25 minutes

**Goal:** Take the generalist agent below and refactor it into a strict `Research Specialist` with a correct A2A Capability Advertisement and working scope enforcement.

### Starting Point: The Generalist

This Python pseudo-agent accepts any task and routes to the LLM without validation:

```python
# generalist_agent.py (DO NOT use in production)

SYSTEM_PROMPT = """
You are a general-purpose assistant. You can:
- Research companies using web search
- Analyze sentiment in text
- Summarize documents
- Write reports
- Answer coding questions
- Translate text
Do whatever the user asks.
"""

def handle_task(message: dict) -> dict:
    user_text = extract_text(message)
    response = llm.complete(system=SYSTEM_PROMPT, user=user_text)
    return build_response(response)
```

### Your Task

**Part 1 — Decompose the scope.** List the six task types this generalist "handles." Then identify which single task type should belong to a `Research Specialist`. Justify your boundary.

---

**Part 2 — Write the AgentCard.** Write a complete A2A AgentCard JSON for the `Research Specialist`. The agent's declared scope:

- It researches companies and industries using web search and structured data sources.
- It returns a JSON DataPart with: `company_name` (string), `research_summary` (string, 300-500 words), `data_sources` (array of URL strings, min 3), `key_metrics` (object: `revenue_usd`, `employee_count`, `founded_year`), and `confidence_score` (float, 0.0–1.0).
- It accepts text input only (the research query as plain text).
- It does NOT analyze sentiment, summarize arbitrary documents, write reports, answer coding questions, or translate text.
- Cost estimate: $0.045 per invocation. P95 latency: 7,500ms. Max throughput: 5 RPS.
- Constraint: queries must be in English; max query length 500 characters; accepts only company or industry research queries (no personal, political, or speculative topics).

---

**Part 3 — Implement `validate_scope`.** Write the Python `validate_scope` function for this Research Specialist. It must reject:

1. Any task whose `params.metadata.skillId` is not `company-research`.
2. Any text Part longer than 500 characters.
3. Any non-text Part (file, image, data).

For each rejection, include a `resolution` field in the error `data` that tells the orchestrator what to do instead.

---

**Part 4 — Write the refactored agent handler.** Write the `handle_sendMessage` function that calls `validate_scope` first, and only invokes the (mock) LLM if validation passes.

---

### Success Criteria

- Your AgentCard has exactly one Skill entry with id `company-research`.
- The Skill's `description` is a job description (not a function signature): it names the input format, output schema fields, and domain.
- `metadata.constraints` includes max query length, accepted languages, and topic restriction.
- `metadata.economics` includes all three fields: `cost_usd_estimate`, `latency_p95_ms`, `throughput_rps`.
- `validate_scope` raises `TaskRejectedError` for all three rejection cases.
- Each `TaskRejectedError` includes a `resolution` field.
- `handle_sendMessage` calls `validate_scope` before any LLM invocation.
- A task with `skillId: "report-writer"` is rejected with code `-32001` and the correct resolution.
- A text Part of 600 characters is rejected with code `-32003` and the correct resolution.
- A FilePart is rejected with code `-32002` and the correct resolution.
- A valid task with `skillId: "company-research"`, text under 500 characters, and no non-text parts passes through to the mock LLM handler.

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| Recursive Task Decomposition | Breaking a complex goal into sub-tasks recursively until each leaf node is handled by a single-purpose agent |
| Role Boundary | The explicit set of task types an agent accepts, encoded in its AgentCard skills and enforced in middleware |
| Capability Advertisement | The A2A AgentCard's `skills` array, extended with `constraints` and `economics` metadata for production use |
| Constraints | Explicit limits on what the agent accepts: file size, language, query length, topic domain |
| Economics | Cost-per-task estimate, P95 latency, and max throughput declared in the AgentCard for orchestrator cost modeling |
| Scope Enforcement | Pre-LLM validation middleware that rejects out-of-scope tasks with a `TaskRejectedError` before spending any tokens |
| TaskRejectedError | A2A error in the `-32001` to `-32010` range; includes a `resolution` field with the correct next action for the orchestrator |
| Role Contamination | The gradual expansion of a specialist agent's effective scope through informal exceptions, leading to quality degradation across all task types |
| Cost Modeling | The orchestrator-side algorithm that uses `economics` fields in AgentCards to select the cheapest sufficient agent for a task |

---

## What's Next

[[multi-agent-orchestration-a2a/chapter-05|Chapter 5: Tool-Sharing & Resource Injection with MCP]] builds on the role definitions you've just designed. You've defined what each specialist *can do* in isolation. In Chapter 5, you'll give your specialists shared tools through the Model Context Protocol — so the Research Specialist you just designed can expose its web-search tool to other agents via an MCP server, without duplicating the implementation.

You know how to say No. Chapter 5 shows you what to say Yes to — and how to share it.

---

*Sources: [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [A2A Agent Discovery & AgentCard](https://a2a-protocol.org/latest/topics/agent-discovery/) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [OASF Open Agentic Schema Framework](https://docs.agntcy.org/oasf/open-agentic-schema-framework/) · [Model Context Protocol](https://modelcontextprotocol.io/introduction) · [AGNTCY Internet of Agents](https://agntcy.org/)*
