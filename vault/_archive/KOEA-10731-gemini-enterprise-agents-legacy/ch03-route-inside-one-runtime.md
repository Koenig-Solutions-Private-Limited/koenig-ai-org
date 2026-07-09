---
chapter_num: 3
course_slug: gemini-enterprise-agents
title: "Route inside one runtime with deterministic and LLM-mediated patterns"
status: draft
duration_min: 55
vendor_tag: google
learning_objectives:
  - "Implement deterministic routing with ADK workflow agents: SequentialAgent, ParallelAgent, and LoopAgent"
  - "Implement LLM-mediated routing where a coordinator chooses a specialist sub-agent based on request content"
  - "Pass data between sub-agents through shared invocation context and explicit session state rather than hidden prompt coupling"
  - "Add loop limits, route budgets, and fail-loud behavior for routing errors"
  - "Read ADK events to prove which sub-agent ran and why"
sources:
  - url: "https://google.github.io/adk-docs/agents/multi-agents/"
    title: "ADK Multi-agents documentation"
  - url: "https://google.github.io/adk-docs/agents/workflow-agents/sequential-agents/"
    title: "ADK Workflow Agents: Sequential Agents"
  - url: "https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/adk"
    title: "Agent Development Kit (ADK) — Gemini Enterprise Agent Platform"
  - url: "https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview"
    title: "Vertex AI Agent Engine Sessions"
owns:
  - "deterministic routing with ADK workflow agents (SequentialAgent, ParallelAgent, LoopAgent)"
  - "LLM-mediated routing via coordinator + specialist sub-agents"
  - "invocation context and session state for sub-agent data passing"
  - "loop limits, route budgets, and fail-loud routing errors"
  - "ADK event inspection to audit route decisions"
defers_to:
  - "A2A cross-agent routing → ch4"
  - "permission-scoped enterprise data retrieval per specialist → ch5"
  - "agent identity and IAM policy gates → ch6"
  - "trace spans and evaluation gates → ch7"
quiz_topics:
  - "SequentialAgent vs ParallelAgent vs LoopAgent — when to choose each"
  - "invocation context state vs session state — which primitive for which scope"
  - "loop guard via max_iterations"
  - "fail-loud vs silent-fail on unmatched routes"
  - "ADK AgentStartEvent and AgentEndEvent for route auditing"
notebooklm_source_focus:
  - "ADK multi-agent and workflow-agent documentation"
  - "Vertex AI Agent Engine session and invocation-context primitives"
  - "ADK event stream: AgentStartEvent, AgentEndEvent"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Three validation steps must run in fixed order before the final response. Which ADK agent type fits this pattern?"
    options:
      - "ParallelAgent, because each validation step is independent of the others"
      - "SequentialAgent, because steps execute in declaration order and each blocks the next"
      - "LoopAgent, because the steps repeat until all three pass a quality check"
      - "A coordinator LlmAgent that calls each step as a separate tool function"
    correct_idx: 1
    explanation: "SequentialAgent runs sub-agents in the order you declare them, blocking on each until it completes. That is the right primitive for ordered pipelines. ParallelAgent runs them concurrently; LoopAgent repeats a step; a coordinator LLM adds unnecessary latency and non-determinism for a fixed-order pipeline."
    section_anchor: "deterministic-routing-sequentialagent-parallelagent-and-loopagent"
  - question: "A sub-agent computes a classification that a downstream sub-agent must read in the same runner.run() call. Where should the classification be stored?"
    options:
      - "A module-level Python variable so every agent can import it at any time"
      - "The invocation context state dict, keyed by a well-known name"
      - "Vertex AI Agent Engine Sessions, because that is where agent state belongs"
      - "A temporary file written to /tmp before the next sub-agent starts"
    correct_idx: 1
    explanation: "Invocation context state is the correct primitive for intra-invocation data sharing. Module-level variables break under concurrent or multi-process deployment; Agent Engine Sessions are for cross-turn persistence; disk I/O adds latency and coupling."
    section_anchor: "passing-state-between-sub-agents"
  - question: "A LoopAgent has no explicit exit condition coded in the sub-agent. What is the safest guard against runaway execution?"
    options:
      - "Set a short model timeout so the inference call fails before the loop completes too many times"
      - "Rely on the LLM to decide when enough iterations have passed and to stop producing output"
      - "Set max_iterations on the LoopAgent and raise a typed error when the limit is hit"
      - "Wrap the LoopAgent in a broad try/except that swallows all exceptions and returns empty"
    correct_idx: 2
    explanation: "max_iterations is the ADK-native guard. Silencing exceptions hides failures and looks like a successful empty answer in logs. Relying on the LLM to self-terminate is non-deterministic and unauditable."
    section_anchor: "loop-limits-route-budgets-and-fail-loud-behavior"
  - question: "You suspect the coordinator routed an ambiguous request to the wrong specialist. Which mechanism gives you a deterministic audit record of which specialist actually ran?"
    options:
      - "Check the session history for the user-visible final answer and infer the route from wording"
      - "Inspect the ADK event stream for AgentStartEvent and AgentEndEvent on each specialist"
      - "Re-run the coordinator with a higher temperature and see if the choice changes"
      - "Query Agent Engine Sessions for the last logged tool call in the conversation"
    correct_idx: 1
    explanation: "AgentStartEvent and AgentEndEvent are emitted per sub-agent invocation in the ADK event stream. They are independent of the model's final answer and give you a deterministic audit record."
    section_anchor: "reading-adk-events-to-prove-which-sub-agent-ran"
---

## Routing inside one runtime means sub-agents, not services

"Multi-agent routing" means two different things in this course, and collapsing them causes bad production designs:

1. **In-process sub-agent routing** — one ADK agent orchestrates others within the same runtime, sharing the same invocation context. This is what this chapter teaches.
2. **Cross-service A2A routing** — a client agent dispatches a Task to a separately deployed agent over the A2A protocol, with a distinct lifecycle model. That is Chapter 4.

An in-process handoff that fails is a bug in your orchestration logic. An A2A task that fails is a distributed systems problem with a completely different recovery path. Keep the mental models separate before you touch the keyboard. As [ADK's multi-agent documentation](https://google.github.io/adk-docs/agents/multi-agents/) explains, sub-agents live in the same agent graph and share the coordinator's invocation context — there is no network hop and no task state machine.

---

## Deterministic routing: SequentialAgent, ParallelAgent, and LoopAgent

ADK provides three workflow agent primitives that encode the route in Python, not in a model prompt. Use them when the routing logic is known at design time. The [ADK Sequential Agents documentation](https://google.github.io/adk-docs/agents/workflow-agents/sequential-agents/) covers each primitive's contract in detail; here is how to choose between them.

### SequentialAgent

`SequentialAgent` runs sub-agents in declaration order, blocking on each before advancing. Use it for ordered pipelines: validate first, classify second, answer third.

```python
from google.adk.agents import SequentialAgent, LlmAgent
from google.adk.tools import FunctionTool

def validate_employee_id(employee_id: str) -> dict:
    return {"valid": employee_id.startswith("EMP"), "employee_id": employee_id}

validator = LlmAgent(
    name="employee_validator",
    model="gemini-2.5-flash",
    instruction="Extract the employee_id from the request and call validate_employee_id.",
    tools=[FunctionTool(validate_employee_id)],
)

classifier = LlmAgent(
    name="request_classifier",
    model="gemini-2.5-flash",
    instruction=(
        "Given the validated employee context, classify the request as "
        "'hr', 'expense', or 'it'. Store the result in state['department']."
    ),
)

intake_pipeline = SequentialAgent(
    name="intake_pipeline",
    sub_agents=[validator, classifier],
)
```

`classifier` cannot start until `validator` completes. The invocation context (including any state the validator wrote) passes between them automatically.

### ParallelAgent

`ParallelAgent` runs sub-agents concurrently and waits for all to complete. Use it when steps are independent and latency matters more than ordering.

```python
from google.adk.agents import ParallelAgent

hr_context_fetcher = LlmAgent(
    name="hr_context_fetcher",
    model="gemini-2.5-flash",
    instruction="Fetch the relevant HR policy section and store it in state['hr_context'].",
)

expense_context_fetcher = LlmAgent(
    name="expense_context_fetcher",
    model="gemini-2.5-flash",
    instruction="Fetch the relevant expense policy and store it in state['expense_context'].",
)

context_loader = ParallelAgent(
    name="context_loader",
    sub_agents=[hr_context_fetcher, expense_context_fetcher],
)
```

Treat parallel sub-agents as isolated until both complete and their state is merged. Neither can safely read the other's writes mid-execution.

### LoopAgent

`LoopAgent` repeats a sub-agent until a condition is met or the iteration limit is reached.

```python
from google.adk.agents import LoopAgent

refiner = LlmAgent(
    name="answer_refiner",
    model="gemini-2.5-pro",
    instruction=(
        "Review the draft in state['draft']. If it is complete and compliant, "
        "set state['done'] = True. Otherwise improve state['draft'] and continue."
    ),
)

refinement_loop = LoopAgent(
    name="refinement_loop",
    sub_agents=[refiner],
    max_iterations=3,
)
```

<Callout type="warning">
**Always set `max_iterations`.** A `LoopAgent` with no cap will spin until a quota or timeout kills it. Set the limit, and raise a typed exception in your exit-condition tool when it is hit — an empty string looks like a successful empty answer in logs.
</Callout>

---

## LLM-mediated routing: coordinator plus specialists

Deterministic workflow agents cannot handle ambiguous intent. For those cases, a coordinator `LlmAgent` reads the request, picks a specialist, and delegates. This pattern is described in the [ADK multi-agent documentation](https://google.github.io/adk-docs/agents/multi-agents/) as the `LlmAgent`-as-orchestrator model.

```python
hr_specialist = LlmAgent(
    name="hr_specialist",
    model="gemini-2.5-flash",
    instruction=(
        "Answer HR policy questions: leave, benefits, performance reviews. "
        "For non-HR questions, respond exactly: ESCALATE"
    ),
)

expense_specialist = LlmAgent(
    name="expense_specialist",
    model="gemini-2.5-flash",
    instruction=(
        "Answer expense and reimbursement questions: receipts, per diem, approvals. "
        "For non-expense questions, respond exactly: ESCALATE"
    ),
)

it_specialist = LlmAgent(
    name="it_specialist",
    model="gemini-2.5-flash",
    instruction=(
        "Answer IT access questions: VPN, laptop provisioning, software access. "
        "For non-IT questions, respond exactly: ESCALATE"
    ),
)

helpdesk_coordinator = LlmAgent(
    name="helpdesk_coordinator",
    model="gemini-2.5-pro",
    instruction=(
        "Route internal helpdesk requests to exactly one specialist: "
        "hr_specialist, expense_specialist, or it_specialist. "
        "If the request matches none, respond: ESCALATE. Do not answer the question yourself."
    ),
    sub_agents=[hr_specialist, expense_specialist, it_specialist],
)
```

The coordinator uses the Pro model for reasoning; specialists use Flash for extraction and lookup. That gives you a cost-quality split per route without any additional infrastructure.

<KnowledgeCheck
  question="A coordinator LlmAgent receives a request it cannot classify into any specialist's domain. What is the correct behavior?"
  options={[
    "Pick the most likely specialist and let it handle the ambiguity itself",
    "Call all three specialists simultaneously and merge their answers",
    "Respond with an explicit escalation message and call no specialist",
    "Retry the classification with a larger, more capable model"
  ]}
  correctIdx={2}
  explanation="An unclassifiable request must produce an explicit escalation. Routing to the 'most likely' specialist hides misrouting; calling all three wastes tokens and can produce contradictory answers. Retrying silently masks the classification failure."
/>

---

## Passing state between sub-agents

Sub-agents in the same invocation share a **state dict** on the invocation context. Write results there explicitly — do not rely on prompt carry-through, which is invisible, untestable, and breaks on model updates.

```python
# In a sub-agent's tool function:
def store_department(tool_context, department: str) -> dict:
    tool_context.state["department"] = department
    return {"stored": True}

# In the next sub-agent's instruction:
# "Read state['department'] and route accordingly."
```

**Invocation context** is ephemeral — it lives for one `runner.run()` call. **Session state** via [Vertex AI Agent Engine Sessions](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview) persists across turns. Choose deliberately:

| Need | Correct primitive |
|------|-------------------|
| Data needed only by downstream sub-agents this call | Invocation context state dict |
| Data that the next user turn must see | Agent Engine Session |
| Data shared across multiple users | A separate data store (not session) |

<KnowledgeCheck
  question="A sub-agent computes a classification that a specialist must read two steps later in the same runner.run() call. Where should the classification be stored?"
  options={[
    "A module-level Python variable so all agents can import it at runtime",
    "The invocation context state dict, keyed by a well-known name agreed on in advance",
    "Vertex AI Agent Engine Sessions, because that is the canonical agent state store",
    "A temporary file on disk, deleted after the run completes"
  ]}
  correctIdx={1}
  explanation="Invocation context state is the correct primitive for intra-invocation data sharing. Module-level variables break under concurrent deployments; Agent Engine Sessions add cross-turn persistence you do not need here; disk I/O adds latency and coupling."
/>

---

## Loop limits, route budgets, and fail-loud behavior

Three guards keep routing safe once you deploy beyond a laptop:

**Loop limit** — `max_iterations` on every `LoopAgent`. When the limit is hit, raise a typed exception, not an empty return.

**Route budget** — cap the coordinator's output tokens. The coordinator decides the route; it does not write the answer. A `max_output_tokens` of 256–512 tokens is sufficient for a routing decision and prevents runaway token spend on coordinator retries.

```python
helpdesk_coordinator = LlmAgent(
    name="helpdesk_coordinator",
    model="gemini-2.5-pro",
    generate_content_config={"max_output_tokens": 512},
    instruction=COORDINATOR_INSTRUCTION,
    sub_agents=[hr_specialist, expense_specialist, it_specialist],
)
```

**Fail-loud** — when a route fails (no specialist matched, loop limit hit, specialist returned ESCALATE), raise a typed exception. Empty strings pass silently through monitoring and look like successful zero-length responses.

```python
class RoutingError(Exception):
    pass

def assert_routed(response: str, specialist_called: str | None) -> None:
    if not specialist_called or response.strip() == "ESCALATE":
        raise RoutingError(
            f"No specialist matched. Coordinator response: '{response[:80]}'"
        )
```

---

## Reading ADK events to prove which sub-agent ran

The ADK event stream emits `AgentStartEvent` and `AgentEndEvent` for every sub-agent invocation. Read these after the run to confirm routing without inspecting model internals or parsing answer text.

```python
import asyncio
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.events import AgentStartEvent

async def run_and_audit(query: str) -> list[str]:
    session_service = InMemorySessionService()
    runner = Runner(agent=helpdesk_coordinator, session_service=session_service)
    session = await session_service.create_session()

    events = []
    async for event in runner.run_async(
        user_id="user1",
        session_id=session.id,
        new_message=query,
    ):
        events.append(event)

    routed_to = [
        e.agent_name for e in events
        if isinstance(e, AgentStartEvent)
        and e.agent_name != "helpdesk_coordinator"
    ]
    print(f"Query: {query[:50]}")
    print(f"Routed to: {routed_to or ['ESCALATE — no specialist called']}")
    return routed_to
```

If `routed_to` is empty, the coordinator returned ESCALATE and called no specialist. If it contains two names, you have a double-route bug to fix. The event stream is ground truth; the final answer text is a consequence of it.

---

## Hands-on exercise: Three-agent internal helpdesk router

**Goal**: Extend the Policy Intake agent from Chapter 2 into a working three-specialist router. Verify routing accuracy for three known-domain requests and one unknown request.

### Step 1: Define the three specialists

```python
hr_specialist = LlmAgent(
    name="hr_specialist",
    model="gemini-2.5-flash",
    instruction=(
        "You answer HR policy questions: leave, benefits, performance reviews. "
        "For non-HR questions, respond exactly: ESCALATE"
    ),
)

expense_specialist = LlmAgent(
    name="expense_specialist",
    model="gemini-2.5-flash",
    instruction=(
        "You answer expense and reimbursement questions: receipts, per diem, approvals. "
        "For non-expense questions, respond exactly: ESCALATE"
    ),
)

it_specialist = LlmAgent(
    name="it_specialist",
    model="gemini-2.5-flash",
    instruction=(
        "You answer IT access questions: VPN, laptop provisioning, software access. "
        "For non-IT questions, respond exactly: ESCALATE"
    ),
)
```

### Step 2: Build the coordinator with a token budget

```python
COORDINATOR_INSTRUCTION = """
You are the internal helpdesk coordinator. Route each request to exactly one specialist.
- hr_specialist: leave, benefits, performance reviews
- expense_specialist: receipts, reimbursement, per diem, spending approvals
- it_specialist: VPN, laptop, software access, account provisioning

If the request matches none of the above, respond: ESCALATE
Do not answer the question yourself. Choose a specialist or escalate.
"""

helpdesk_coordinator = LlmAgent(
    name="helpdesk_coordinator",
    model="gemini-2.5-pro",
    generate_content_config={"max_output_tokens": 512},
    instruction=COORDINATOR_INSTRUCTION,
    sub_agents=[hr_specialist, expense_specialist, it_specialist],
)
```

### Step 3: Run four test cases and check routing via events

```python
TEST_CASES = [
    ("hr_specialist",      "How many sick days am I entitled to this year?"),
    ("expense_specialist", "Can I expense a client dinner for $340?"),
    ("it_specialist",      "I need VPN access set up for a contractor starting Monday."),
    ("ESCALATE",           "What is the cafeteria menu for Thursday?"),
]

async def verify_all():
    session_service = InMemorySessionService()
    runner = Runner(agent=helpdesk_coordinator, session_service=session_service)

    results = []
    for expected, query in TEST_CASES:
        session = await session_service.create_session()
        events = []
        async for event in runner.run_async(
            user_id="test", session_id=session.id, new_message=query
        ):
            events.append(event)

        routed = [
            e.agent_name for e in events
            if isinstance(e, AgentStartEvent)
            and e.agent_name != "helpdesk_coordinator"
        ]
        actual = routed[0] if routed else "ESCALATE"
        status = "PASS" if actual == expected else "FAIL"
        print(f"{status}  expected={expected:<22} got={actual}")
        results.append(status)

    print(f"\n{results.count('PASS')}/4 passed")

asyncio.run(verify_all())
```

**Success criteria**:
- All three domain queries route to the correct specialist (PASS for hr, expense, it).
- The cafeteria query routes to no specialist — `routed_to` is empty and `actual == "ESCALATE"`.
- No query triggers two `AgentStartEvent` entries (no double-routing).
- All four test runs complete without a Python exception.

If a domain query fails, inspect the full event list to see what the coordinator emitted before the specialist was called. The routing decision is in the coordinator's `ModelResponseEvent`, not in the final output text.

---

[[ch04-route-across-agents-with-a2a-task-lifecycle]] introduces A2A — a completely separate lifecycle model where agents are independently deployed services that communicate through a standardized protocol, not in-process sub-agents sharing an invocation context.
