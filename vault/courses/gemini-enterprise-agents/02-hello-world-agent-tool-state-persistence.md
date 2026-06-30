---
chapter_num: 2
title: "Hello World: Agent + 1 Tool + State Persistence"
course_slug: gemini-enterprise-agent-platform-hands-on-tour
prerequisites_chapters: [1]
duration_min: 55
reading_time_min: 55
date: 2026-04-30
status: g3-passed
last_updated: 2026-06-14
author: Koenig AI Academy
agent_drafted_by: course-author
content_type: course-chapter
ticket: KOE-33
vendor_tag: google
learning_objectives:
  - "Install google-adk and run an agent locally in under 10 minutes"
  - "Define a Python function as a tool and attach it to an agent"
  - "Explain the difference between in-session state and long-term Memory Bank"
  - "Persist a conversation across process restarts using Agent Sessions"
sources:
  - https://adk.dev/
  - https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform
  - https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/agent-development-kit/overview
  - https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/sessions
  - https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/memory
---

# Hello World: Agent + 1 Tool + State Persistence

ADK (Agent Development Kit), released as part of Google's Gemini Enterprise Agent Platform on 23 April 2026, is a Python library that lets builders run a working agent with tool use and state persistence in under 10 lines of configuration code. By the end of this chapter you will have a local ADK agent that tracks expenses, remembers them across sessions, and summarises your spending history — without managing any database yourself. It is deliberately simple. The goal is to see exactly which lines of code map to which platform concepts before you layer in complexity.

## Key facts

1. ADK installs as a single pip package: `google-adk`
2. Tools are plain Python functions — no decorator magic required in most patterns
3. Session state is scoped to a conversation; [[glossary/memory-bank|Memory Bank]] is scoped to a user across all conversations
4. Local development uses `InMemorySessionService`; production uses `VertexAiSessionService` with a config swap
5. Agent Runtime (cloud deployment) requires no code changes — only a `deployment.yaml`
6. The ADK web UI (`adk web`) lets you test agents interactively in a browser without writing a test harness
7. Cold starts on Agent Runtime are sub-second for pre-warmed instances [1]

---

## Prerequisites

Before continuing, confirm:

```bash
python --version  # 3.10 or later
gcloud auth application-default login  # required for Vertex AI calls
gcloud config set project YOUR_PROJECT_ID
```

You also need a Gemini API key or a GCP project with Vertex AI enabled. The examples below use `gemini-flash-latest` because it is the fastest and cheapest Gemini model for development — swap to `gemini-pro-latest` for production reasoning tasks.

---

## Step 1: Install ADK

```bash
pip install google-adk
```

That is the entire install. ADK is a pure-Python library with no system dependencies. Verify:

```bash
python -c "import google.adk; print(google.adk.__version__)"
```

You should see a version string beginning with `1.` (the current release is in the 1.3x series). If you see an import error, check that your Python environment matches the `python` binary you ran above.

<Callout type="info">
**Venv is strongly recommended.** ADK pulls in `google-cloud-aiplatform` and other Google Cloud libraries; isolate it to prevent version conflicts. Run `python -m venv .venv && source .venv/bin/activate` before installing.
</Callout>

---

## Step 2: Define your first tool

In ADK, a **tool** is a Python function. The function's docstring is the tool description — the model reads it to decide when to call the function. Type annotations are the parameter schema.

```takeaways
- ADK infers the tool schema from the Python function's type annotations and docstring at runtime — no decorator or separate JSON schema file is required.
- The docstring quality directly controls when the model calls a tool; "Use this tool when..." phrasing is the trigger phrase that shapes model behavior.
- Tools must return strings or JSON-serialisable values because the model reads the return value as tool output; structured data should be returned as JSON strings for complex results.
```

Create `budget_tracker/tools.py`:

```python
from datetime import date
from typing import Optional

# In-process store for demo purposes; replace with a database in production.
_expenses: list[dict] = []


def log_expense(amount: float, category: str, note: Optional[str] = None) -> str:
    """Record a new expense.

    Use this tool when the user says they spent money on something.
    
    Args:
        amount: The amount spent, in USD.
        category: Expense category, e.g. 'food', 'transport', 'software'.
        note: Optional description of what was purchased.
    
    Returns:
        Confirmation string with the logged entry.
    """
    entry = {
        "date": date.today().isoformat(),
        "amount": amount,
        "category": category,
        "note": note or "",
    }
    _expenses.append(entry)
    return f"Logged: ${amount:.2f} on {category} ({note or 'no note'})"


def get_expense_summary() -> str:
    """Return a summary of all logged expenses grouped by category.

    Use this tool when the user asks how much they have spent or wants a summary.

    Returns:
        A formatted summary of total spending per category.
    """
    if not _expenses:
        return "No expenses logged yet."
    
    totals: dict[str, float] = {}
    for exp in _expenses:
        totals[exp["category"]] = totals.get(exp["category"], 0.0) + exp["amount"]
    
    lines = [f"  {cat}: ${total:.2f}" for cat, total in sorted(totals.items())]
    grand_total = sum(totals.values())
    lines.append(f"  Total: ${grand_total:.2f}")
    return "Expense summary:\n" + "\n".join(lines)
```

---

## Step 3: Wire the agent

```takeaways
- The `instruction` field in the Agent constructor is the system prompt and acts as the most important variable controlling agent behavior — it should be version-controlled and tested like production code.
- Explicit per-tool rules in the instruction (when to call, what not to do) reduce wrong-tool invocations and hallucinated data significantly compared with a vague persona prompt.
- The `Agent` constructor requires only `name`, `model`, `description`, `instruction`, and `tools` to produce a deployable agent with automatic multi-step tool use.
```

Create `budget_tracker/agent.py`:

```python
import os
from google.adk import Agent
from budget_tracker.tools import log_expense, get_expense_summary

# Use a stable model ID or environment variable in production.
# Preview model IDs like 'gemini-3.1-pro-preview' are volatile.
MODEL_ID = os.getenv("AGENT_MODEL_ID", "gemini-flash-latest")

budget_agent = Agent(
    name="budget_tracker",
    model=MODEL_ID,
    description="A personal budget tracker that logs and summarises expenses.",
    instruction="""You are a friendly budget tracker. 

When the user mentions spending money, call log_expense with the amount, 
category, and any note they provide. Always confirm what you logged.

When the user asks about their spending, call get_expense_summary and 
present the results clearly.

Keep responses short. Do not invent expenses the user did not mention.""",
    tools=[log_expense, get_expense_summary],
)
```

<Callout type="warning">
**Instruction quality is your most important variable.** A poorly written instruction produces an agent that calls the wrong tool, invents data, or returns walls of text. Treat the instruction like production code: version it, test it, refine it when you see failures.
</Callout>

---

## Step 4: Run locally with the ADK web UI

ADK ships with a built-in development server that gives you a browser-based chat interface:

```bash
adk web budget_tracker/
```

Open `http://localhost:8000`. You should see a chat interface with your `budget_tracker` agent. Try:

- "I spent $12.50 on lunch"
- "I paid $45 for a software subscription"
- "How much have I spent?"

<RunPromptCell
  model="gemini-flash-latest"
  tools={["log_expense", "get_expense_summary"]}
  prompt="I spent $12.50 on lunch and $4 on coffee this morning. How much have I spent on food today?"
  expectedOutput={`I'll log both of those for you.

[tool_call: log_expense]
{"amount": 12.50, "category": "food", "note": "lunch"}
→ "Logged: $12.50 on food (lunch)"

[tool_call: log_expense]
{"amount": 4.00, "category": "food", "note": "coffee"}
→ "Logged: $4.00 on food (coffee)"

[tool_call: get_expense_summary]
→ "Expense summary:\n  food: $16.50\n  Total: $16.50"

You've spent **$16.50 on food** so far today — $12.50 on lunch and $4.00 on coffee.`}
/>

The agent correctly identifies two separate expenses from one message, calls `log_expense` twice, then calls `get_expense_summary` to answer the question. This multi-step tool use happens automatically — you did not write any routing logic.

<KnowledgeCheck
  questions={[
    {
      question: "Where does ADK read the tool description that the model uses to decide when to call a function?",
      answers: [
        "A separate JSON schema file you provide",
        "The function's docstring",
        "A `description` parameter in the Agent constructor",
        "A metadata decorator applied to the function"
      ],
      correct: 1,
      explanation: "ADK infers the tool description from the function's docstring. The quality of your docstring directly affects when and how accurately the model decides to invoke the tool."
    }
  ]}
/>

---

## Step 5: Add session state

Right now, expenses vanish when the process restarts. The `_expenses` list is in memory. Real agents need state that survives restarts. GEAP offers two layers: **Session state** (within a conversation) and **Memory Bank** (across all conversations for a user).

```takeaways
- ADK injects a `Session` object into tool functions automatically when the parameter is typed as `Session` — no manual wiring is required by the caller.
- `session.state` is a dictionary that ADK persists through the conversation and restores if the same session ID is resumed after a process restart.
- Switching from local `InMemorySessionService` to production `VertexAiSessionService` requires only a one-line constructor swap; all tool code and the Session API remain unchanged.
```

Let's start with Session state. Modify `agent.py`:

```python
from google.adk import Agent
from google.adk.sessions import InMemorySessionService, Session
from budget_tracker.tools import log_expense, get_expense_summary

session_service = InMemorySessionService()

budget_agent = Agent(
    name="budget_tracker",
    model="gemini-flash-latest",
    description="A personal budget tracker that logs and summarises expenses.",
    instruction="""...""",  # same as before
    tools=[log_expense, get_expense_summary],
    session_service=session_service,
)
```

Now update your tools to read and write session state instead of the module-level list:

```python
# budget_tracker/tools.py  (session-aware version)
from datetime import date
from typing import Optional
from google.adk.sessions import Session


def log_expense(
    amount: float,
    category: str,
    session: Session,
    note: Optional[str] = None,
) -> str:
    """Record a new expense in the current session.

    Use this tool when the user says they spent money on something.

    Args:
        amount: The amount spent, in USD.
        category: Expense category, e.g. 'food', 'transport', 'software'.
        session: The current session (injected automatically by ADK).
        note: Optional description of what was purchased.
    
    Returns:
        Confirmation string with the logged entry.
    """
    expenses = session.state.get("expenses", [])
    entry = {
        "date": date.today().isoformat(),
        "amount": amount,
        "category": category,
        "note": note or "",
    }
    expenses.append(entry)
    session.state["expenses"] = expenses
    return f"Logged: ${amount:.2f} on {category} ({note or 'no note'})"


def get_expense_summary(session: Session) -> str:
    """Return a summary of all logged expenses grouped by category.

    Use this tool when the user asks how much they have spent.

    Args:
        session: The current session (injected automatically by ADK).
    
    Returns:
        A formatted summary of total spending per category.
    """
    expenses = session.state.get("expenses", [])
    if not expenses:
        return "No expenses logged yet."
    
    totals: dict[str, float] = {}
    for exp in expenses:
        totals[exp["category"]] = totals.get(exp["category"], 0.0) + exp["amount"]
    
    lines = [f"  {cat}: ${total:.2f}" for cat, total in sorted(totals.items())]
    grand_total = sum(totals.values())
    lines.append(f"  Total: ${grand_total:.2f}")
    return "Expense summary:\n" + "\n".join(lines)
```

---

## Step 6: Understanding Session vs Memory Bank

The distinction between these two concepts is the most important architectural choice in this chapter:

```takeaways
- Session state is scoped to one conversation and holds raw data you write explicitly; Memory Bank is scoped to a user across all conversations and holds distilled "Memory Profiles" the platform generates automatically.
- Memory Bank profiles are created by running a model over completed sessions to extract relevant facts, enabling agents to recall user preferences and history at low latency without loading full conversation transcripts.
- Memory Bank requires deploying to Vertex AI with `VertexAiSessionService` and is not available with `InMemorySessionService` used in local development.
```

| | **Session state** | **Memory Bank** |
|---|---|---|
| **Scope** | One conversation | All conversations for a user |
| **Duration** | Until session expires (configurable) | Long-term (days to indefinite) |
| **Content** | Raw conversation + structured state dict | Distilled "Memory Profiles" |
| **Latency** | Sub-millisecond (local dict) | Low-latency retrieval (indexed) |
| **Who creates it** | You (via `session.state` writes) | The platform (via model distillation) |
| **Who reads it** | Your tools, explicitly | The agent's instruction context, automatically |

**Session state** holds what matters in the current conversation — a cart, a form, the user's task context — and you write to it explicitly. **Memory Bank** holds what should survive across conversations — preferences, past decisions — and the platform populates it automatically by distilling completed sessions. For the budget tracker: session state holds expenses logged this session; a Memory Bank profile would capture "user consistently overspends on food."

<Callout type="info">
**Memory Bank is not available in `InMemorySessionService`.** It requires deploying to Vertex AI with a `VertexAiSessionService`. For local development, simulate long-term memory by loading a state file at session start. We show the production wiring in the capstone.
</Callout>

---

## Step 7: Switching to production sessions

When you are ready to deploy, swap `InMemorySessionService` for `VertexAiSessionService`:

```python
from google.adk.sessions import VertexAiSessionService

session_service = VertexAiSessionService(
    project="your-gcp-project",
    location="us-central1",
    agent_engine_id="your-agent-engine-id",  # from Agent Runtime
)
```

Everything else stays the same. Your tool code, your agent instruction, your tool definitions — unchanged. The `Session` object your tools receive has the same API. This is the portability promise of ADK: develop locally with in-memory services, deploy to Vertex with a one-line swap. For a broader introduction to the Vertex AI infrastructure GEAP builds on, see [[gemini-enterprise-agents/01-what-gemini-enterprise-agent-platform-is-and-isnt|the GEAP platform overview]].

<RunPromptCell
  model="gemini-flash-latest"
  tools={["log_expense", "get_expense_summary"]}
  prompt="I spent $85 on groceries yesterday. What's my total food spend this month?"
  expectedOutput={`[tool_call: log_expense]
{"amount": 85.00, "category": "food", "note": "groceries"}
→ "Logged: $85.00 on food (groceries)"

[tool_call: get_expense_summary]
→ "Expense summary:\n  food: $101.50\n  Total: $101.50"

I've logged your $85.00 grocery run. Your total food spend this month is **$101.50** — that's the $12.50 lunch, $4.00 coffee, and today's $85.00 groceries.`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Your budget tracker agent needs to remember a user's preferred currency (USD, EUR, GBP) across all future sessions. Which storage layer should you use?",
      answers: [
        "session.state, because it persists within a conversation",
        "Memory Bank, because it preserves information across all sessions for a user",
        "A module-level Python variable, because it is fastest",
        "Agent Registry, because preferences are a form of tool configuration"
      ],
      correct: 1,
      explanation: "Preferred currency is a user preference that should persist indefinitely across conversations. Memory Bank is designed for exactly this: cross-session, long-lived context. session.state would reset at the end of each conversation."
    },
    {
      question: "How does ADK inject the Session object into a tool function?",
      answers: [
        "You manually pass it when calling the tool",
        "The agent reads a global session variable",
        "ADK sees the Session type annotation in the function signature and injects it automatically",
        "You register the session with a decorator before the function definition"
      ],
      correct: 2,
      explanation: "ADK uses type annotation-based dependency injection. If your function declares a parameter typed as Session, ADK automatically injects the current session when calling the tool. No manual wiring required."
    },
    {
      question: "What is the only change required to move from local InMemorySessionService to production VertexAiSessionService?",
      answers: [
        "Rewrite all tool functions to use a different Session API",
        "Replace the session_service constructor — all other code stays unchanged",
        "Add a @production_tool decorator to each tool",
        "Change the agent model from gemini-flash-latest to gemini-pro-latest"
      ],
      correct: 1,
      explanation: "ADK is designed for environment parity. The Session API is identical between InMemorySessionService and VertexAiSessionService — swap the constructor, everything else works."
    }
  ]}
/>

---

## Hands-on exercise: Build the budget tracker

**Goal**: A working ADK agent with session state and (simulated) long-term memory.

**Steps**:
1. Create the project structure: `budget_tracker/__init__.py`, `budget_tracker/tools.py`, `budget_tracker/agent.py`
2. Implement `log_expense` and `get_expense_summary` with `Session` injection as shown above
3. Run `adk web budget_tracker/` and test three messages: log two expenses, then ask for a summary
4. Stop the process, restart it, and resume the same session ID via the web UI. Confirm your expenses are still there.
5. **Extension**: Add a third tool `clear_expenses(session: Session) -> str` that deletes all logged expenses. Test that calling it and restarting the session returns "No expenses logged yet."

**Success criteria**:
- Agent correctly logs expenses from natural language input (not JSON)
- Session summary matches what you logged
- Expenses survive a process restart when using the same session ID

---

## What's next

You now have a single-agent system with state. The next step is coordination: what happens when one agent is not enough? Chapter 3 introduces multi-agent orchestration — a supervisor agent that routes work to specialist sub-agents — and shows how Agent Registry makes those sub-agents discoverable.

See [[gemini-enterprise-agent-platform-hands-on-tour/03-multi-agent-orchestration-with-vertex]] to continue.

---

## References

[1] Google Cloud Blog. "Introducing Gemini Enterprise Agent Platform." 23 April 2026. — https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform · retrieved 2026-04-30

[2] Google Agent Development Kit. Official documentation and quickstart. — https://adk.dev/ · retrieved 2026-04-30

[3] Google Cloud. Vertex AI Agent Builder — ADK overview. — https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/agent-development-kit/overview · retrieved 2026-04-30

[4] Google Cloud. Agent Sessions documentation. — https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/sessions · retrieved 2026-04-30

[5] Google Cloud. Memory Bank guide. — https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/memory · retrieved 2026-04-30
