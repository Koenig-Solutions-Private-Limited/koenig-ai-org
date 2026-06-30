---
chapter_num: 2
course_slug: gemini-enterprise-agents
title: "Build one ADK agent and deploy it with a real lifecycle"
status: g3-passed
last_updated: 2026-06-12
duration_min: 55
vendor_tag: google
learning_objectives:
  - "Create a minimal ADK agent with a typed domain tool and a testable instruction"
  - "Run the agent locally and inspect events, state changes, and tool calls in the ADK developer UI"
  - "Deploy the same agent to Vertex AI Agent Engine and invoke it through the remote client path"
  - "Describe the deployment lifecycle: package, create, query, update, delete, and rollback"
  - "Distinguish ephemeral local state from managed session state in Vertex AI Agent Engine Sessions"
sources:
  - url: "https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/adk"
    title: "ADK on Gemini Enterprise Agent Platform"
    retrieved: "2026-06-12"
  - url: "https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale"
    title: "Scale agents on Gemini Enterprise Agent Platform"
    retrieved: "2026-06-12"
  - url: "https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview"
    title: "Vertex AI Agent Engine overview"
    retrieved: "2026-06-12"
  - url: "https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy"
    title: "Deploy agents to Vertex AI Agent Engine"
    retrieved: "2026-06-12"
  - url: "https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview"
    title: "Agent Engine Sessions overview"
    retrieved: "2026-06-12"
  - url: "https://google.github.io/adk-docs/get-started/about/"
    title: "ADK: About the Agent Development Kit"
    retrieved: "2026-06-12"
owns:
  - "ADK Agent creation with typed domain tools and instruction strings"
  - "local run and ADK developer UI event inspection"
  - "AdkApp deployment package"
  - "Vertex AI Agent Engine create/query/update/delete/rollback lifecycle"
  - "ephemeral local state vs managed session state in Agent Engine Sessions"
defers_to:
  - "ADK workflow agents (SequentialAgent, ParallelAgent, LoopAgent) → ch3"
  - "A2A Agent Card and cross-agent task lifecycle → ch4"
  - "enterprise data grounding and RAG → ch5"
  - "agent identity, IAM, and policy gates → ch6"
  - "tracing, callbacks, and evaluation gates → ch7"
quiz_topics:
  - "ADK Agent constructor arguments (name, model, tools, instruction)"
  - "local run vs remote run event visibility"
  - "Agent Engine deployment lifecycle steps"
  - "managed session state vs in-process ephemeral state"
  - "AdkApp as the deployment wrapper"
word_budget: { min: 2500, max: 3000 }
quiz:
  - question: "Which ADK `Agent` constructor argument encodes behavioral policy — what the agent must and must not do?"
    options:
      - "The `tools` list, which enumerates callable functions the model may invoke"
      - "The `instruction` string, which defines the agent's behavior and constraints"
      - "The `model` parameter, which selects the underlying reasoning engine"
      - "The `name` field, which scopes the agent's session namespace"
    correct_idx: 1
    explanation: "The `instruction` string is where behavioral policy lives — it tells the model how to reason, what to output, and what to refuse. The `tools` list controls which functions are available but does not express behavioral constraints."
    section_anchor: "creating-a-minimal-adk-agent"
  - question: "When you run `adk web` locally, which of the following is NOT visible in the developer UI?"
    options:
      - "The sequence of model call events for a single turn"
      - "Tool input arguments and their return values"
      - "Vertex AI Agent Engine session IDs assigned after deployment"
      - "Intermediate state changes written to the in-process session"
    correct_idx: 2
    explanation: "Agent Engine session IDs are assigned only after deployment. The local developer UI shows model events, tool calls, and in-process state, but has no concept of managed Agent Engine sessions."
    section_anchor: "running-locally-and-reading-events"
  - question: "What is the correct order for the Vertex AI Agent Engine deployment lifecycle?"
    options:
      - "Package → create → query → update → delete (rollback via re-create from prior version)"
      - "Create → package → deploy → query → rollback"
      - "Build → push → provision → invoke → monitor"
      - "Init → validate → stage → promote → retire"
    correct_idx: 0
    explanation: "The canonical lifecycle is: package the app into a wheel, create a remote agent resource, query it to invoke, update when logic changes, delete to retire. Rollback is achieved by re-creating from a prior wheel artifact."
    section_anchor: "deploying-to-vertex-ai-agent-engine"
  - question: "A teammate stores conversation context in an ADK agent's Python dict that lives inside the running process. What is the production risk?"
    options:
      - "In-process dicts are encrypted at rest, introducing read latency compared to managed sessions"
      - "In-process state is ephemeral — it is lost when the container restarts or scales to zero"
      - "ADK agents do not support dict-style storage; only proto-serialized state is allowed"
      - "Agent Engine charges per-write for in-process mutations, making them expensive"
    correct_idx: 1
    explanation: "In-process state lives only as long as the running process. A container restart, new deployment, or scale-to-zero event wipes it. Agent Engine's managed Sessions API persists state independently of the agent process."
    section_anchor: "sessions-and-state-local-versus-managed"
  - question: "Which Python object wraps your ADK root agent so that `vertexai.agent_engines.create()` can accept it as a deployment artifact?"
    options:
      - "`RemoteAgent`, which exposes a gRPC endpoint for the Engine to invoke"
      - "`AdkApp`, which wraps the root agent and optional session configuration"
      - "`AgentCard`, which publishes a discovery document for the Engine's routing table"
      - "`VertexAISession`, which binds the agent to a project and location before deployment"
    correct_idx: 1
    explanation: "`AdkApp` is the deployment wrapper in the ADK–Agent Engine integration. It accepts the root agent and optional session service, and is passed as the `agent_engine` argument to `vertexai.agent_engines.create()`."
    section_anchor: "packaging-for-deployment"
chapter_primary_query: "How do you build and deploy an ADK agent to Vertex AI Agent Engine?"
first_60_words_answer: "Create an ADK Agent with a typed tool and instruction string, run it with `adk web` to verify the four-event trace, wrap it in AdkApp and build a Python wheel, then deploy with `vertexai.agent_engines.create()`. The full lifecycle is: package, create, query, update, delete. Rollback requires re-creating from a prior wheel. Managed session state persists across container restarts; in-process state does not."
positions: []
faq:
  - question: "What does AdkApp do and why is it needed for deployment?"
    answer: |
      AdkApp wraps your ADK root agent for deployment to Vertex AI Agent Engine.
      It translates the Agent Engine remote invocation protocol into ADK's internal
      event loop, so your agent code runs identically whether started by `adk web`
      locally or by an Agent Engine managed container. Pass it as the `agent_engine`
      argument to `vertexai.agent_engines.create()`. Without AdkApp, Agent Engine
      has no entry-point contract to fulfill when it starts your container.
      Source: [ADK on Gemini Enterprise Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/adk)
  - question: "How do you roll back an Agent Engine deployment?"
    answer: |
      Vertex AI Agent Engine has no native rollback command. Rollback is achieved
      by calling `vertexai.agent_engines.create()` with a prior wheel artifact
      from Cloud Storage, producing a new agent resource. Update your routing table
      or client to point at the new resource_name, then delete the broken version
      once traffic is confirmed stable. Keep versioned wheels in Cloud Storage for
      every deployment so the prior artifact is always retrievable without rebuilding.
      Source: [Deploy agents to Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy)
  - question: "What is the difference between local ADK session state and Agent Engine managed session state?"
    answer: |
      Local (in-process) state lives in Python objects inside the running agent process
      and is lost on any container restart, scale-to-zero event, or deployment update.
      Agent Engine managed session state is stored by the Sessions service independently
      of the agent process; session history persists across process restarts and is
      available as a full event audit trail for compliance purposes. Use
      `remote_agent.create_session()` and pass `session_id` on subsequent queries
      for managed persistence.
      Source: [Agent Engine Sessions overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview)
---

# Build one ADK agent and deploy it with a real lifecycle

## From Prototype to Production Pipeline

By the end of this chapter you will have a working Agent Engine deployment with a real session record and a lifecycle comparison table that maps every observable event to its runtime context. You will write an ADK agent, run it with `adk web` to verify the four-event trace, package it as a Python wheel, and push it to Vertex AI Agent Engine — exercising the full create, query, update, delete, and rollback lifecycle. [[ch01-map-the-platform]] established the platform topology; this chapter moves your cursor to the first production-deployable box on that map.

The reason to do all of this before routing is that every routing decision in later chapters touches agent lifecycle. If you do not know the difference between an in-process ADK sub-agent call and a remote Agent Engine invocation, the routing diagrams in later chapters will look like plumbing that connects identical boxes. They do not connect identical boxes. Local agents and deployed agents have different identity, different state guarantees, and different failure modes. A local agent run is useful for verifying that tool calls fire correctly. It is not a deployment, and it cannot serve production traffic. Building one properly deployed agent first gives you the concrete reference point for every routing and lifecycle comparison that follows.

By the time you complete the hands-on exercise, you will have run the same logical agent in two runtime modes and produced a table showing exactly which lifecycle events are local-only and which are owned by Agent Engine. That table will be a reference you reach for through the rest of the course.

## Creating a Minimal ADK Agent

An ADK agent is an instance of the `google.adk.agents.Agent` class ([ADK: About the Agent Development Kit](https://google.github.io/adk-docs/get-started/about/)). Its four construction concerns are a `name`, a `model`, a list of `tools`, and an `instruction` string. Each concern has a distinct job that no other concern can substitute for.

The **`name`** scopes the agent's identity in session records, trace spans, and Agent Engine logs. When you have multiple agents deployed to the same project, the name is how you distinguish which agent produced which event. Use a stable, environment-qualified name in production — `policy-intake-v1` rather than `agent` or `my_agent`.

The **`model`** selects the Gemini variant the agent reasons with. For chapter-level work, `gemini-2.0-flash` is a reasonable default: fast, cheap, and capable of reliable function calling. Model selection becomes a first-class architectural decision in the final chapter. For now, treat it as a configuration knob you will revisit once you understand routing costs.

The **`tools`** list enumerates typed Python functions the model is allowed to call. ADK extracts JSON schemas from Python type hints to tell the model exactly which argument values are valid. A function without type hints forces the model to infer the schema, which produces inconsistent argument formats in production — a class of bug that is difficult to reproduce deterministically and even harder to diagnose from logs.

The **`instruction`** string is where behavioral policy lives. It tells the model what to do, how to do it, and what to refuse. An instruction that only names the agent's purpose without specifying must-do and must-not-do constraints leaves the model free to take shortcuts — answering directly instead of calling a tool, or calling the wrong tool when none fits perfectly. Be explicit and negative: tell the model what it must not do as clearly as you tell it what it must.

Here is a minimal Policy Intake agent implementing all four concerns correctly:

```python
from google.adk.agents import Agent
from typing import Literal

def classify_policy_question(
    question: str,
    category: Literal["hr", "expense", "it", "unknown"]
) -> dict:
    """Classify an employee policy question into a routing category."""
    return {"category": category, "question": question}

policy_intake_agent = Agent(
    name="policy-intake-v1",
    model="gemini-2.0-flash",
    tools=[classify_policy_question],
    instruction="""You are a policy intake classifier for an enterprise helpdesk.

When an employee submits a policy question:
1. Determine whether it belongs to the hr, expense, it, or unknown category.
2. You MUST call classify_policy_question with the verbatim question text and your chosen category.
3. After the tool returns, respond with exactly: "Your question has been classified as [category] and routed to the appropriate team."

You must NOT answer the policy question directly. You must NOT skip the tool call. Your only function is classification and routing confirmation."""
)
```

The `Literal["hr", "expense", "it", "unknown"]` type on `category` is not decorative. ADK builds the tool's JSON schema from that annotation, and the model uses that schema to constrain its output. Without the `Literal`, the model can emit any string — and under load or with ambiguous input, it will. Type your tool arguments precisely.

The instruction uses explicit negative constraints: "must NOT answer directly," "must NOT skip the tool call." These constraints close the two shortcuts the model is most likely to take. In testing, you will verify that they hold. In production, the event trace is what proves they held.

<KnowledgeCheck question="Why does ADK use Python type hints on tool function arguments?" options={["To enforce runtime type-checking in Python before the function executes","To generate the JSON schema the model uses to construct structured function calls","To prevent functions from being registered if they have incorrect signatures","To reduce token usage by compressing the tool description in the prompt"]} correctIdx={1} explanation="ADK extracts the JSON schema for each tool from the function's Python type annotations. The model uses that schema to generate structured arguments when it decides to call the tool. Without precise annotations, the model must infer argument structure and will produce inconsistent or invalid calls."/>

Save the agent in a directory structure that `adk web` can discover:

```
policy_intake/
  __init__.py       # exports policy_intake_agent as `agent`
  agent.py          # contains the Agent definition above
  requirements.txt  # google-adk, vertexai
```

In `__init__.py`, export the root agent with the name the ADK discovery convention expects:

```python
from .agent import policy_intake_agent as agent
```

ADK looks for an attribute named `agent` at the package root. The name controls everything in the local discovery path; misname it and `adk web` silently shows an empty agent list.

## Running Locally and Reading Events

Install ADK and start the developer server from the parent directory of `policy_intake/`:

```bash
pip install google-adk
adk web .
```

Open the URL the CLI prints (default `http://localhost:8000`). Select `policy-intake-v1` from the agent selector. Send the question: "Can I expense a home-office monitor?"

The **Events** panel shows the full turn trace in sequence. For a healthy turn with a correctly behaving agent, you should see exactly four event types in order:

1. `model_request` — the prompt sent to Gemini, containing your instruction and the user's question
2. `function_call` — the tool invocation the model decided to make, with the argument values it chose
3. `function_response` — the dict your tool returned
4. `model_response` — the final reply the model generated after reading the tool response

This four-event pattern is the diagnostic signature of a correctly functioning single-tool agent. Every deviation from it is a bug. If `function_call` is absent, the model skipped the tool. If `function_response` contains an error, your tool threw an exception. If `model_response` arrives before `function_call`, the model ignored the instruction ordering constraint.

The **State** panel shows key-value pairs written to the in-process session during the turn. For a simple classification agent, session state will be sparse — mostly turn history buffered for multi-turn context. In later chapters, you will write explicit routing decisions into session state so downstream sub-agents can read them without re-running classification from scratch.

<KnowledgeCheck question="You send a test question to the local agent and the Events panel shows only model_request followed immediately by model_response with no function_call in between. What has gone wrong?" options={["The tool returned an error and the model fell back to a direct answer","The model skipped the tool call, violating the instruction constraint","The ADK developer UI is not rendering function_call events for this model version","The agent has no tools registered in its tools list"]} correctIdx={1} explanation="When no function_call event appears, the model skipped the tool. This is an instruction-following failure, not a tool error — a tool error would appear as a function_response with an error payload. Strengthen the instruction with explicit must-call language and re-test until function_call appears on every turn."/>

Run three test questions before moving to deployment:

- "Can I expense a home-office monitor?" → expect category: `expense`
- "How do I request parental leave?" → expect category: `hr`
- "I need admin access to the VPN gateway." → expect category: `it`

For each question, verify that `function_call` appears, that the `category` argument matches the expected value, and that the final response uses the exact phrasing from your instruction. If the model paraphrases the response rather than following the prescribed format, tighten the instruction. These three checks are your local regression baseline — any future changes to the instruction or tool must pass all three before you rebuild the deployment artifact.

## Packaging for Deployment

Vertex AI Agent Engine does not execute your Python module directly. It needs a deployable artifact — a Python wheel it can install into a managed container. The ADK integration provides the `AdkApp` class to bridge the local runtime to the managed runtime.

Add the wrapper to your package:

```python
# policy_intake/__init__.py
from google.adk.agents.vertex_ai_adk_app import AdkApp
from .agent import policy_intake_agent

agent = policy_intake_agent          # keeps adk web working
adk_app = AdkApp(agent=policy_intake_agent)
```

`AdkApp` wraps the root agent and optionally accepts a `session_service` argument for managed session configuration. When you pass `adk_app` to `vertexai.agent_engines.create()`, Agent Engine installs your wheel, starts a managed container, and routes all inbound invocations to the `AdkApp` handler. The handler translates Agent Engine's remote invocation protocol into ADK's internal event loop, so your agent code runs identically whether it was started by `adk web` or by an Agent Engine container.

Build the wheel:

```bash
pip install build
python -m build --wheel .
# produces dist/policy_intake-0.1.0-py3-none-any.whl
```

<Callout>
**Preview status and import path drift.** The `AdkApp` integration and Agent Engine billing model were both in preview as of the research window (billing launched January 28, 2026). Before deploying in a new environment, verify the current `AdkApp` import path in your installed version of `google-adk` — Google has moved it between minor releases. Pin your `google-adk` version in `requirements.txt`, confirm the import locally, then build and deploy. An unpinned version that drifts to a new minor release mid-project can silently break the `AdkApp` import and produce a confusing packaging error at deploy time.
</Callout>

[ADK on Gemini Enterprise Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/adk) describes ADK as "an open-source agent development framework that lets you build, debug, and deploy reliable AI agents at enterprise scale," with Python as the primary deployment language for Agent Engine integration. The open-source framing matters: you can inspect `AdkApp`'s source to understand exactly what it does to your agent before trusting it with production traffic.

## Deploying to Vertex AI Agent Engine

The [Vertex AI Agent Engine overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) describes it as the fully managed serverless compute environment for production ADK agents — the runtime that owns the agent's lifecycle from first deployment through retirement. [Scaling agents on the Gemini Enterprise Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale) frames it as the serverless compute layer with integrated session management, IAM-governed access, and observability hooks — the difference between an agent that runs on your laptop and one that runs as a governed service.

The deployment lifecycle has five explicit steps: package, create, query, update, and delete. Rollback is not a native single-command operation; it is achieved by creating a new agent resource from a prior package version. Understanding this distinction prevents a critical production mistake: assuming Agent Engine maintains a version history you can flip like a feature flag. It does not.

**Create.** Authenticate your default credentials and run the SDK:

```python
import vertexai
from vertexai import agent_engines
from policy_intake import adk_app

vertexai.init(project="your-project-id", location="us-central1")

remote_agent = agent_engines.create(
    agent_engine=adk_app,
    requirements=["google-adk==0.5.0", "vertexai>=1.70.0"],
    display_name="policy-intake-v1",
    description="Classifies HR, expense, and IT policy questions for routing.",
)

print(remote_agent.resource_name)
# projects/your-project-id/locations/us-central1/reasoningEngines/AGENT_ID
```

Save `resource_name`. It is the stable identifier you use for every subsequent lifecycle operation. Include the version string in `display_name` — `policy-intake-v1`, `policy-intake-v2` — so rollback targets are unambiguous when you are looking at a list of resources at 2 a.m. during an incident.

**Query.** The remote client path for synchronous invocation:

```python
remote_agent = agent_engines.get("projects/.../reasoningEngines/AGENT_ID")

response = remote_agent.query(
    input="Can I expense a home-office monitor?",
    user_id="employee-42"
)
print(response)
```

For production interactive applications, use `stream_query` instead of `query`. It returns a generator of events as they arrive, enabling incremental output to the user rather than a full-turn wait. The event structure in `stream_query` is the same four-event pattern you observed locally — model request, function call, function response, model response — but delivered over a streaming connection.

**Update.** When agent logic changes, build a new wheel and push the update:

```python
remote_agent.update(
    agent_engine=new_adk_app,
    requirements=["google-adk==0.5.1"],
)
```

Agent Engine replaces the running container with the new version. Queries in flight complete against the old container; new queries hit the updated version. There is no traffic-splitting built into a single resource — if you need a canary, create two resources and split traffic at the client layer.

**Delete.** Retire the agent resource when it is no longer needed:

```python
remote_agent.delete()
```

This removes the compute resource. Session records stored in Agent Engine Sessions persist separately and must be deleted independently if you need to purge them.

**Rollback.** Rollback in Agent Engine means re-running `agent_engines.create()` with a prior wheel artifact. Keep your wheel files versioned in Cloud Storage alongside each deployment so the previous artifact is always retrievable. After creating the rollback resource, update your routing table or client configuration to point to its `resource_name`. The retired resource can be deleted after traffic is confirmed stable on the rollback version. This procedure is slower than a flag flip, but it is explicit, auditable, and does not depend on any hidden Agent Engine rollback state. The [Deploy agents to Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy) reference documents the full parameter set for each lifecycle operation.

## Sessions and State: Local Versus Managed

The most consequential production mistake with ADK is treating local session state and Agent Engine managed session state as equivalent. They are not equivalent, and conflating them produces agents that appear to work in development and fail silently in production.

**Local (in-process) state** is whatever Python objects live inside the agent process during a run: the in-memory session dictionary, variables your tools write, conversation history buffered for context. This state is *ephemeral*. When the process stops for any reason — a container restart, a scale-to-zero event, a deployment update — all of it is gone. Local state is the right tool for verifying that tool calls fire correctly in a unit test. It is the wrong tool for any production scenario where a user's conversation needs to survive a network reconnection, a client refresh, or a server restart.

**Managed session state** is stored by the Agent Engine Sessions service, completely independently of any agent process. When you call `remote_agent.query(user_id=...)`, Agent Engine creates a session record tied to that user identity and persists the full event history — every model turn, every tool call, every tool response. On the next query with the same session ID, Agent Engine loads that history into the model's context window before invoking the agent. The agent resumes the conversation with full context even if the container handling the previous turn has been replaced and recycled.

```python
# First invocation — Agent Engine creates a session
session = remote_agent.create_session(user_id="employee-42")
response = remote_agent.query(
    input="Can I expense a home-office monitor?",
    session_id=session["id"],
    user_id="employee-42"
)

# Second invocation — Agent Engine loads and continues the session
response = remote_agent.query(
    input="What if I buy it refurbished — does that change the category?",
    session_id=session["id"],
    user_id="employee-42"
)
# The model's context now contains the first turn; the follow-up is coherent
```

The event history stored in a managed session is also the audit trail your compliance function will request. Each entry records which agent processed the request, which tool was called, what arguments were passed, and what the tool returned. For a policy classification agent, that record is evidence that every submitted question was routed through the classifier before being sent downstream — something you cannot reconstruct from ephemeral in-process logs after the fact.

The [Agent Engine Sessions overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview) documents the full sessions API, including session listing, querying, and deletion across user identities. The practical rule is simple: anything that needs to survive a process restart belongs in managed session state. Anything that is purely computational within a single turn can stay in-process. Multi-turn conversation context, user identity signals, and routing decisions that downstream agents will need to read: managed. Intermediate computation results used within a single function call: in-process. Turning this session record into evaluation gates and SLO dashboards is the subject of [[06-observability]].

## Hands-on: Build the Policy Intake Agent

**Goal.** Build a minimal Policy Intake agent, verify it locally with the developer UI, deploy it to Agent Engine, and produce a lifecycle comparison table documenting which events are local-only versus managed.

**Prerequisites.** GCP project with billing enabled; `gcloud auth application-default login` completed; Python 3.10+; `google-adk` and `vertexai` installed.

**Step 1 — Write the agent.** Create the `policy_intake/` package structure described above. Implement `classify_policy_question` with `Literal` typing on the `category` argument. Write the `instruction` with explicit must-do and must-not-do constraints. Export the agent as `agent` from `__init__.py`.

**Step 2 — Run locally and verify events.** Run `adk web .` from the parent directory. Send these three test questions and inspect the Events panel for each:
- "Can I expense a home-office monitor?" → expect `function_call` with category `expense`
- "How do I request parental leave?" → expect `function_call` with category `hr`
- "I need admin access to the VPN gateway." → expect `function_call` with category `it`

For any turn where `function_call` is absent or the category is wrong, revise the instruction and re-test until all three pass. Record the exact event sequence for a passing turn; you will compare it to the Agent Engine trace in step 5.

**Step 3 — Package the agent.** Add `AdkApp` to `__init__.py`. Run `python -m build --wheel .` and confirm the wheel file is produced in `dist/`.

**Step 4 — Deploy to Agent Engine.** Run `vertexai.init()` with your project and `us-central1`. Call `agent_engines.create()` with the wheel and pinned `requirements`. Save the `resource_name`.

**Step 5 — Invoke through the remote client.** Call `remote_agent.create_session(user_id="employee-42")`. Send the same three test questions from step 2 using `remote_agent.query()` with the session ID. Confirm that the responses match what you observed locally. Then send a fourth question that refers to the first turn — for example, "Was that last question classified correctly?" — and observe whether the model can reference the earlier turn.

**Step 6 — Fill in the lifecycle comparison table.**

| Event or state | Local run (`adk web`) | Agent Engine (`query`) |
|---|---|---|
| `model_request` visible | ✓ (developer UI) | ✓ (Agent Engine trace) |
| `function_call` visible | ✓ (developer UI) | ✓ (Agent Engine trace) |
| Session ID assigned by managed service | ✗ | ✓ |
| Session persists after process stop | ✗ | ✓ |
| Event history queryable after run | ✗ | ✓ |
| Identity governed by IAM | ✗ | ✓ |

Add any additional rows your testing surfaces. The goal is at least three rows where local and managed behavior differ.

**Step 7 — Delete the Agent Engine resource.** Call `remote_agent.delete()` when you are done to avoid ongoing charges. Managed session records from the test run remain in Agent Engine Sessions until deleted separately.

**Success criteria.** All three test questions produce a `function_call` event both locally and via the remote client. The fourth follow-up query returns a contextually aware response, confirming that managed session history is providing context. The lifecycle table has at least three populated rows with observable differences between the local and managed runtimes.

---

Chapter 1 gave you a platform map. This chapter gave you a deployed, session-backed agent on that map — one real lifecycle with evidence at every step. The next chapter takes this single deployed agent and extends it into a three-specialist routing system using deterministic and LLM-mediated patterns. [[ch03-route-inside-one-runtime-with-deterministic-and-llm-mediated-patterns]]
