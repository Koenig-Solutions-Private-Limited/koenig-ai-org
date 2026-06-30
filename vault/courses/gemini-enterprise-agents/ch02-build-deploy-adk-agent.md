---
chapter_num: 2
chapter: 2
title: "Build One ADK Agent and Deploy It with a Real Lifecycle"
course_slug: gemini-enterprise-agents
chapter_slug: ch02-build-deploy-adk-agent
prerequisites_chapters:
  - ch01-map-the-platform
duration_min: 55
reading_time_min: 55
status: draft
author: "Koenig AI Academy"
content_type: course-chapter
vendor_tag: google
learning_objectives:
  - "Create a minimal ADK agent with a typed domain tool and a testable instruction"
  - "Run the agent locally and inspect events, state changes, and tool calls in the ADK developer UI"
  - "Deploy the same agent to Vertex AI Agent Engine and invoke it through the remote client path"
  - "Describe the deployment lifecycle: package, create, query, update, delete, and rollback"
  - "Distinguish ephemeral local state from managed session state in Vertex AI Agent Engine Sessions"
key_concepts:
  - "ADK Agent"
  - "typed domain tools"
  - "adk web (developer UI)"
  - "event history"
  - "AdkApp"
  - "Vertex AI Agent Engine"
  - "deployment package"
  - "remote agent"
  - "query / streamQuery"
  - "session state"
  - "managed sessions"
sources:
  - url: https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/adk
    title: "ADK — Gemini Enterprise Agent Platform"
  - url: https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview
    title: "Vertex AI Agent Engine overview"
  - url: https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview
    title: "Agent Engine Sessions overview"
  - url: https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy
    title: "Deploy an agent to Agent Engine"
hands_on_exercise: "Build a Policy Intake agent that classifies employee policy questions and calls a mock policy lookup tool. Run it locally, deploy it to Agent Engine, create a session, invoke it twice, and record which lifecycle events were local-only versus managed by Agent Engine."
---

# Build One ADK Agent and Deploy It with a Real Lifecycle

In Chapter 1, you drew the map. Now you build on it. This chapter follows one agent — a Policy Intake assistant — from a single Python file all the way to a production deployment on Vertex AI Agent Engine. Every lifecycle stage is explicit: write the tool, define the agent, run it in the developer UI, package it, create a remote deployment, create a session, query it, update it, and know how to roll it back.

By the end, you will have deployed a real agent and felt the concrete difference between ephemeral in-process state and Agent Engine's managed sessions. That difference defines the production boundary.

## Writing a Typed Domain Tool

ADK agents are only as useful as their tools. A tool is a plain Python function. What makes it production-quality is explicit parameter types, a descriptive docstring, and a return type the agent can reason about. The model reads the signature to understand when and how to call the function — a weak signature means unreliable invocation.

```python
# policy_tools.py
import json

POLICY_DB = {
    "pto": "Employees accrue 1.5 days PTO per month. Unused PTO rolls over up to 30 days.",
    "expense": "Expenses over $75 require manager approval. Submit receipts within 30 days.",
    "remote": "Employees may work remotely up to 3 days per week with team-lead agreement.",
}

def policy_lookup(category: str) -> dict[str, str]:
    """Return the policy text for a given category.

    Args:
        category: One of 'pto', 'expense', or 'remote'.

    Returns:
        dict with keys 'category' and 'text', or 'error' if category is unknown.
    """
    category = category.lower().strip()
    if category in POLICY_DB:
        return {"category": category, "text": POLICY_DB[category]}
    known = ", ".join(POLICY_DB.keys())
    return {"error": f"Unknown category '{category}'. Known categories: {known}"}
```

Three details matter here. First, the parameter type is `str` — not `Any`, not `dict`. ADK surfaces type annotations to the model's function-calling layer; broad types produce imprecise calls. Second, the docstring describes the expected value range for `category`. Third, the return type is always a `dict`: the agent gets structured output it can reason about rather than an untyped string it must parse.

## Building the ADK Agent

With the tool defined, constructing the agent is straightforward:

```python
# agent.py
from google.adk.agents import Agent
from policy_tools import policy_lookup

agent = Agent(
    name="policy_intake_agent",
    model="gemini-2.0-flash",
    instruction=(
        "You are an HR Policy Intake specialist. "
        "When an employee asks about a company policy, "
        "use the policy_lookup tool to retrieve the current policy text, "
        "then answer clearly and cite the retrieved text. "
        "If the category is unclear, ask the employee to clarify before calling the tool."
    ),
    tools=[policy_lookup],
)
```

The four constructor parameters carry distinct responsibilities:

- **`name`**: A stable identifier used in traces, session history, and Agent Engine resource names. Use a lowercase, hyphen-separated name — it appears in deployment paths.
- **`model`**: The model ID that processes each turn. `gemini-2.0-flash` is a solid default for tool-using agents. Avoid `latest` aliases in production; pin the ID so model updates are deliberate, not accidental.
- **`instruction`**: The system-level prompt. It sets the agent's persona, tells it when to use each tool, and defines how it should handle edge cases. Short and specific beats long and vague. The instruction in this example does three things: names the role, states when to call the tool, and handles the ambiguous-category case.
- **`tools`**: A list of callables. ADK reflects each function's signature and docstring into the model's tool schema automatically.

> **Warning: Model ID pinning is a production invariant.** When you write `gemini-2.0-flash-001` instead of `gemini-2.0-flash`, you opt into explicit version control. When Google deprecates a model ID, your agent fails loudly — a predictable, debuggable failure you can plan for. An unpinned alias fails silently when Google upgrades the endpoint beneath it. Chapter 8 covers the deprecation watch runbook in detail.

## Running Locally: The ADK Developer UI

ADK ships a local development server that renders a chat interface and a real-time event inspector. To launch it, organize your project as a package and point `adk web` at the directory:

```
policy-intake/
├── __init__.py
├── agent.py         # agent = Agent(...)
└── policy_tools.py
```

```bash
pip install google-cloud-aiplatform[adk]
adk web policy-intake/
```

The server starts on `http://localhost:8000`. Open it in a browser. On the left you get a chat panel where you type messages to the agent. On the right — and this is where local development pays back — you get a live event stream that shows every step:

- **`model_call`**: the prompt the model received and the raw response
- **`tool_call`**: the function name, the arguments, and the function's return value
- **`state_change`**: any update to session state keys the agent set explicitly
- **`model_response`**: the agent's final text back to the user

Type "What is our PTO policy?" and watch the event panel. You should see: a `model_call` as the model decides to invoke `policy_lookup`, a `tool_call` with `category: "pto"` and the returned policy text, then another `model_call` as the model synthesizes the answer. Each event has a timestamp and a session ID — the same session ID persists across the whole conversation until you reset it.

The developer UI is diagnostic infrastructure, not a demo surface. Use it to confirm tool invocation order, check that argument values match your intent, and spot instruction-following gaps before they reach production.

> **Info: The event stream is the ground truth.** When the agent produces a wrong answer, the event stream tells you whether the model failed to call the tool (instruction gap), called it with wrong arguments (type or docstring gap), or received correct output but synthesized it badly (instruction gap in a different place). Debugging from event stream to fix is faster than debugging from final answer alone.

## Packaging for Deployment: AdkApp

Local `adk web` runs the agent in your process with no external session management. To move to production, you need two things: an `AdkApp` wrapper that Agent Engine can invoke, and a requirements list that pins your dependencies.

```python
# app.py
from google.adk.app import AdkApp
from policy_intake.agent import agent

app = AdkApp(agent=agent)
```

`AdkApp` is a thin wrapper that translates Agent Engine's invocation protocol — HTTP request/response over the managed runtime — into ADK's internal session and event machinery. You export `app`, not `agent`, when you deploy.

The requirements list matters because Agent Engine runs your code in a managed container. Every package you import must be declared:

```python
requirements = [
    "google-cloud-aiplatform[adk,reasoningengine]>=1.90.0",
    "google-cloud-secret-manager>=2.22.0",  # if your tools access secrets
]
```

Pin versions. An unpinned requirements list means deployment is not reproducible: the Agent Engine package resolver might pull a different version tomorrow and break your tool invocations.

## Deploying to Vertex AI Agent Engine

With the `AdkApp` and requirements ready, deployment is a single SDK call:

```python
import vertexai
from vertexai.preview import reasoning_engines

vertexai.init(project="my-gcp-project", location="us-central1")

remote_agent = reasoning_engines.ReasoningEngine.create(
    reasoning_engines.AdkApp(agent=agent),
    requirements=requirements,
    display_name="policy-intake-v1",
)

print(remote_agent.resource_name)
# projects/123456/locations/us-central1/reasoningEngines/7890123
```

`ReasoningEngine.create()` packages your code, uploads it to Agent Engine, provisions a managed runtime, and returns a resource object. The `resource_name` is the stable identifier — save it. You need it for queries, updates, and rollbacks.

The call is synchronous from the SDK's perspective but runs a multi-minute provisioning operation server-side. Expect one to five minutes on first create; updates are faster because Agent Engine has a warm baseline.

Once provisioned, create a session and query:

```python
# Create a persistent session
session = remote_agent.create_session(user_id="employee-ada-lovelace")
session_id = session["id"]

# First query
response = remote_agent.query(
    user_id="employee-ada-lovelace",
    session_id=session_id,
    message="What is our work-from-home policy?",
)
print(response["output"])

# Second query — history is preserved in the managed session
response2 = remote_agent.query(
    user_id="employee-ada-lovelace",
    session_id=session_id,
    message="And how does that compare to our PTO policy?",
)
print(response2["output"])
```

The second query uses the same `session_id`. Agent Engine retrieves the event history from managed storage and provides it to the model as context. The agent can see the first question and answer. This is managed session state — it persists across restarts, across SDK reconnections, and across your laptop closing.

For streaming responses — useful for long answers or tool chains with multiple steps — substitute `streamQuery`:

```python
for chunk in remote_agent.stream_query(
    user_id="employee-ada-lovelace",
    session_id=session_id,
    message="Summarize all three policy areas.",
):
    print(chunk["output"], end="", flush=True)
```

## The Full Deployment Lifecycle

Agent Engine deployments follow a six-stage lifecycle. Every stage has a corresponding SDK operation:

| Stage | Operation | When to use |
|---|---|---|
| **Package** | Construct `AdkApp(agent=)` with requirements | Before every deployment or update |
| **Create** | `ReasoningEngine.create()` | Initial deployment |
| **Query** | `remote_agent.query()` / `stream_query()` | Live invocation |
| **Update** | `remote_agent.update(requirements=..., display_name=...)` | Code changes, model pin updates, instruction revisions |
| **Delete** | `remote_agent.delete()` | Decommissioning a deployment (irreversible) |
| **Rollback** | Re-instantiate a previous resource by its resource name | Recovering from a bad update |

Update preserves the resource name but creates a new runtime container. The operation is synchronous to the SDK call but asynchronous server-side — poll `remote_agent.get()` to check `state` until it returns `ACTIVE`.

Rollback in Agent Engine means returning to a prior working resource name. Keep resource names in version control or a deployment manifest — you cannot roll back to a state that no longer exists as a resource. A minimal rollback pattern:

```python
# deployment_manifest.py
DEPLOYMENTS = {
    "v1": "projects/123456/locations/us-central1/reasoningEngines/7890123",
    "v2": "projects/123456/locations/us-central1/reasoningEngines/7890456",  # current
}

# To roll back to v1:
from vertexai.preview import reasoning_engines
stable = reasoning_engines.ReasoningEngine(DEPLOYMENTS["v1"])
# Route production traffic to 'stable'
```

> **Warning: Delete is irreversible.** `remote_agent.delete()` removes the Agent Engine resource and its associated session history permanently. Never delete until you have confirmed the replacement is healthy and you have exported any session history you need for audit. The safest pattern is to update the routing path to the new resource and leave the old one in place until the post-deployment smoke test passes.

## Session State: Ephemeral vs. Managed

This is the production boundary that trips most teams. Local ADK runs and Agent Engine sessions feel similar from the outside — both maintain conversation history. They differ in one fundamental way: **durability**.

| Property | Local `adk web` / `adk run` | Vertex AI Agent Engine Sessions |
|---|---|---|
| Storage | In-memory (Python process heap) | Google Cloud managed storage |
| Durability | Process lifetime only | Survives restarts, SDK reconnects, client crashes |
| Session ID | Generated per run | Stable UUID, queryable by `get_session()` |
| Multi-client | No — single process | Yes — multiple clients can attach to same session |
| Event history | Visible in developer UI | Queryable via `get_session()` and `list_events()` |
| State changes | Local dict mutations | Persisted, addressable by key |

In local development, if you restart the `adk web` server, all conversation history is gone. A user picking up a policy question the next morning finds a blank slate. In Agent Engine, that history lives in managed storage. The user can resume mid-conversation, and your agent has the prior tool calls and answers as context.

This difference also affects debugging in production. When a remote session produces an unexpected answer, you call `remote_agent.get_session(session_id=session_id)` and inspect the full event history — every tool call, every model response, every state mutation. That is the audit trail that Chapter 7 builds on.

The local developer UI event panel and the remote session event history are showing you the same data structure: a sequence of typed events. The local version is ephemeral and diagnostic. The managed version is durable and auditable. Build your mental model around that distinction: the developer UI is for building and debugging; Agent Engine sessions are for operating.

## Hands-On Exercise: Policy Intake Agent

Build, deploy, and observe the Policy Intake agent described in this chapter.

**Part 1: Local run**

1. Create the `policy-intake/` package structure with `agent.py` and `policy_tools.py` as shown above.
2. Run `adk web policy-intake/` and open the developer UI.
3. Send three messages: one asking about PTO, one about expenses, and one with an ambiguous category ("What's our policy on flexible scheduling?").
4. In the event panel, record: for each message, did the agent call `policy_lookup`? What `category` argument was passed? What was the return value?

**Part 2: Deploy to Agent Engine**

5. Create `app.py` with the `AdkApp` wrapper and requirements list.
6. Run `ReasoningEngine.create()` and record the `resource_name`.
7. Create a session with a stable `user_id`.
8. Query the remote agent twice with the same `session_id`: first ask about PTO, then ask a follow-up that requires knowing the previous answer ("How many days is the max rollover?").
9. Confirm the second answer uses the first turn's context.

**Success criteria:**
- Part 1: All three local queries produce tool call events visible in the UI; the ambiguous query prompts for clarification rather than guessing.
- Part 2: Both remote queries succeed; the second response correctly references policy content from the first turn; the session ID is stable between calls.
- Lifecycle audit: You can identify which events in Part 1 were ephemeral (disappeared on restart) and which in Part 2 were durable (accessible via `get_session()` after the queries).

**What to record in your notes:**
- The `resource_name` from deployment
- Session ID used for both queries
- One event from local UI that does NOT appear in the remote session (a diagnostic event specific to local dev mode)
- The tool call argument from the ambiguous-category test and what the agent returned

---

## Chapter Summary and Key Takeaways

- An ADK agent has four required properties: `name`, `model`, `instruction`, and `tools`. Tools are plain typed Python functions; the docstring and type annotations are part of the interface — the model reads them to decide how and when to call the tool.
- The ADK developer UI (`adk web`) shows a real-time event stream: `model_call`, `tool_call`, `state_change`, and `model_response`. Use event-stream inspection rather than final-answer inspection when debugging.
- Deployment to Vertex AI Agent Engine requires packaging the agent in an `AdkApp` wrapper and calling `ReasoningEngine.create()` with a pinned requirements list. The `resource_name` is your rollback target — save it.
- The deployment lifecycle is: package → create → query → update → (rollback if needed) → delete. Delete is irreversible; keep prior resource names until the replacement is verified healthy.
- Ephemeral local state (in-memory, dies on process restart) versus managed Agent Engine sessions (durable, multi-client, auditable via `get_session()`) is the production boundary. Production agents run on Agent Engine so that session history persists and is queryable.
- Pin model IDs to explicit version strings, never to `latest` aliases, so model updates are a deliberate choice with a test cycle, not an accidental change.

Next: Chapter 3 extends the Policy Intake agent into a multi-agent helpdesk router, adding deterministic and LLM-mediated routing patterns — [[ch03-routing-inside-one-runtime]].

---

## Quiz

**Question 1**

You define an ADK tool with this signature: `def get_data(params: dict) -> str`. After deploying, the agent calls the tool inconsistently — sometimes passing all required keys, sometimes only a subset. What is the most likely root cause?

A. The Agent Engine runtime is sampling a different model than specified in the constructor  
B. The parameter type `dict` is too broad; the model cannot infer the required keys from the signature alone  
C. The `query()` call is missing the session_id, so context is lost between invocations  
D. Streaming (`stream_query`) must be used for tools that return structured data  

**Answer: B**

Using `dict` as a parameter type removes the structured signal the model relies on to invoke the function correctly. Replace `dict` with a typed `TypedDict` or named individual parameters (`key1: str, key2: int`) and update the docstring to describe expected values. A broad type produces inconsistent invocations because the model has no schema to validate against.

---

**Question 2**

An engineer runs `adk web` locally, conducts a five-turn conversation, and closes the terminal. The next morning they restart `adk web` and ask the agent to "continue from yesterday." The agent responds as if it has no prior context. What explains this behavior and what is the correct fix?

A. The instruction was not set; add a `memory` parameter to the `Agent` constructor  
B. Local `adk web` sessions are ephemeral and stored in-process; session history is lost when the process exits. Deploy to Vertex AI Agent Engine and use managed sessions to persist history across restarts  
C. The `session_id` must be passed explicitly on each query; the developer was not passing it  
D. The ADK model (`gemini-2.0-flash`) has a context window limit that discards history after five turns  

**Answer: B**

This is the core ephemeral-vs-managed distinction. Local ADK keeps session state in the Python process heap. It is erased when the process exits. Vertex AI Agent Engine sessions are stored in managed Cloud storage, survive process restarts, and are queryable by session ID via `get_session()`. The fix is to deploy to Agent Engine and use a stable `session_id` tied to the user identity.

---

**Question 3**

You deploy an ADK agent to Agent Engine as `v1`. You update the tool logic and redeploy as `v2`. Shortly after, users report incorrect answers. How do you execute a rollback to `v1` and what must you have saved in advance?

A. Call `remote_agent.restore(version="v1")`; Agent Engine versions are automatic  
B. Re-instantiate the v1 resource using its saved `resource_name` and route traffic to it; you must have recorded the v1 `resource_name` before the update  
C. Delete the v2 resource; Agent Engine automatically activates the previous deployment  
D. Pass `rollback=True` to `remote_agent.update()` to revert to the prior container  

**Answer: B**

Agent Engine does not have a built-in rollback command. Rollback means re-pointing your application to a previous resource by its `resource_name`. You must have stored that name — in a deployment manifest, version control, or environment variable — before the update. `delete()` on v2 does not restore v1; it only removes the resource. Saving resource names for every deployment is a production discipline, not an optional convenience.

---

**Question 4**

In the ADK developer UI event panel, you notice there is no `tool_call` event after asking a question that clearly requires looking up a policy. The agent guesses an answer instead. Which part of the agent definition is most likely deficient?

A. The `model` parameter specifies a model that does not support tool use  
B. The `requirements` list in the deployment package is missing the tool library  
C. The `instruction` does not tell the agent when to use the tool, so the model skips it and generates from training data  
D. The `session_id` was not created before querying, causing the tool registry to be empty  

**Answer: C**

When an agent has access to a tool but does not call it, the most common cause is an insufficient instruction. The instruction must explicitly specify when the tool should be called (e.g., "always use `policy_lookup` before answering policy questions") — not just what the tool does. Without that directive, the model defaults to its training data. Session ID and requirements affect connectivity and runtime, not tool-calling behavior within a session.

---

**Question 5**

You have two deployments of the same Policy Intake agent running in Agent Engine. A session created against deployment A is being queried. Which statement accurately describes the session's relationship to deployment B?

A. Session history is shared between deployments by default; either deployment can continue the conversation  
B. Session history is scoped to the resource that created it; deployment B cannot access sessions created by deployment A without explicit session migration  
C. Session history is stored client-side in the SDK, so either deployment can read it if you pass the same `session_id`  
D. Sessions expire after 24 hours regardless of which deployment created them  

**Answer: B**

Agent Engine session history is scoped to the deployment resource that created it. A session created via deployment A is stored under that resource's namespace. Deployment B, even with identical code, cannot access it unless you implement explicit session migration. This is by design: it keeps per-deployment history clean and prevents accidental cross-deployment contamination. When rolling back to a previous resource, users may lose recent session turns created on the newer deployment — this should be documented in your rollback runbook.
