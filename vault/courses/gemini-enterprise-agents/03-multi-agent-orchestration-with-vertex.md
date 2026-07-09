---
chapter_num: 3
title: "Multi-Agent Orchestration with Vertex"
course_slug: gemini-enterprise-agents
prerequisites_chapters: [1, 2]
duration_min: 60
reading_time_min: 60
date: 2026-04-30
status: g3-passed
last_updated: 2026-06-14
author: Koenig AI Academy
agent_drafted_by: course-author
content_type: course-chapter
ticket: KOE-33
vendor_tag: google
learning_objectives:
  - "Explain the difference between deterministic and generative orchestration patterns in GEAP"
  - "Wire a supervisor agent that delegates to two specialist sub-agents"
  - "Use Agent Registry to discover and call a registered agent by name"
  - "Read an Agent Observability trace to debug a failed agent handoff"
sources:
  - https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform
  - https://adk.dev/
  - https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/multi-agent
  - https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/agent-registry
  - https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/observability
quiz:
  - question: "You are building a data enrichment pipeline where step B must always run after step A regardless of what A returns. Which ADK orchestration pattern fits?"
    options:
      - "Generative — use transfer_to_agent and let the model decide the routing order"
      - "Deterministic — use SequentialAgent to hardcode the fixed step-by-step routing"
      - "Either pattern produces identical cost and reliability for a fixed-order pipeline"
      - "Neither — GEAP workflow agents cannot enforce strict sequential execution order"
    correct_idx: 1
    explanation: "When routing is fixed and predictable, deterministic orchestration via SequentialAgent is the right choice. It gives predictable costs, easier testing, and eliminates any risk of the model skipping or reordering steps."
    section_anchor: two-orchestration-patterns-one-choice-to-make
  - question: "The Planner calls transfer_to_agent('retriever', question). In a production Vertex deployment, where does ADK resolve the 'retriever' name?"
    options:
      - "It imports the retriever module directly from the running Python process path"
      - "It queries Agent Registry, resolving the name to a registered agent definition"
      - "It looks for a class named RetrieverAgent declared in the same source file"
      - "It sends an HTTP request to a hardcoded localhost endpoint for local resolution"
    correct_idx: 1
    explanation: "In production on Vertex AI, ADK resolves agent names through Agent Registry — a centralised catalogue of approved agents. Locally, ADK resolves names via the sub_agents declaration within the same session."
    section_anchor: step-4-register-agents-in-agent-registry
  - question: "A trace shows the Planner calling transfer_to_agent three times before receiving any response from the Retriever. What is the most likely cause?"
    options:
      - "The Planner instruction lacks a wait-for-result rule, so multiple delegations fire before any response arrives"
      - "The Retriever is rate-limited by Agent Registry, causing the Planner to retry each call automatically"
      - "Agent Registry is temporarily unavailable, causing the Planner to retry resolution for each sub-question"
      - "The gemini-pro-latest model fires all tool calls as a single batch rather than processing them sequentially"
    correct_idx: 0
    explanation: "Without an explicit rule to wait for each result before the next transfer, a generative orchestrator issues multiple transfer_to_agent calls before processing any responses. Fix by adding 'wait for the result before the next transfer' to the Planner's instruction."
    section_anchor: step-5-reading-an-observability-trace
  - question: "Why is Agent Gateway recommended alongside Agent Registry for production multi-agent systems?"
    options:
      - "Agent Gateway improves model response quality on every sub-agent call made at runtime"
      - "Registry controls discovery but not execution; Gateway enforces IAM access policies on callers"
      - "Agent Gateway is a prerequisite for Memory Bank profiles to be stored and retrieved"
      - "Agent Gateway reduces cold-start latency by pre-routing and caching sub-agent requests"
    correct_idx: 1
    explanation: "Agent Registry controls which agents are discoverable by name. Agent Gateway enforces which caller identities are allowed to invoke them. Both are needed: Registry for governance and Gateway for enforcement."
    section_anchor: step-4-register-agents-in-agent-registry
---

# Multi-Agent Orchestration with Vertex

GEAP's agent-to-agent orchestration, available since GA on 23 April 2026, lets a coordinator delegate to specialist sub-agents — turning a fragile 20-tool monolith into a testable, independently-deployable network. A customer-support agent covering account management, billing, and technical support accumulates enough tools and instruction length to produce correlated hallucinations. The answer is **decomposition**: specialist agents with a coordinator.

The tools and session patterns from [[gemini-enterprise-agents/02-hello-world-agent-tool-state-persistence|Chapter 2]] are the foundation: this chapter adds a coordinator layer — a two-agent research pipeline where a Planner decomposes questions and a Retriever answers each one, wired through Agent Registry and traced with Agent Observability.

## Key facts

1. GEAP supports two orchestration patterns: **deterministic** (you define routing logic in code) and **generative** (the orchestrator model decides routing at runtime)
2. Sub-agents are ADK Agent instances — same class, different instruction and tools
3. `transfer_to_agent(agent_name)` is the built-in ADK mechanism for generative handoff; the orchestrator calls it as a tool
4. Agent Registry is a GCP-managed catalogue; agents discover sub-agents by name via the Registry API, not by Python import
5. Agent Anomaly Detection flags unusual reasoning patterns — including infinite handoff loops — without you writing watchdog code [1]
6. ADK's `SequentialAgent` and `ParallelAgent` are the code primitives for deterministic orchestration
7. Observability traces are available in the GCP console under GEAP > Observability within seconds of a completed invocation

---

## Two orchestration patterns, one choice to make

Before writing code, you need to decide which pattern fits your use case. The choice has downstream consequences for debugging, cost, and reliability. (If you need a refresher on the platform itself, see [[gemini-enterprise-agents/01-what-gemini-enterprise-agent-platform-is-and-isnt|Chapter 1: GEAP platform overview]].)

```takeaways
- Deterministic orchestration (via `SequentialAgent` or `ParallelAgent`) hardcodes the routing logic in code and gives predictable costs; generative orchestration lets the model decide routing at runtime, which is more flexible but produces non-deterministic costs.
- Use generative orchestration when routing decisions depend on user input content you cannot enumerate at design time; use deterministic orchestration for ETL-style pipelines where step order never changes.
- In a multi-agent system, using the most expensive model for every agent is an anti-pattern — the Supervisor/Planner warrants Gemini Pro, while Worker/Specialist agents running well-defined tasks can use Flash or Flash-Lite at roughly 13× lower cost.
```

### Deterministic orchestration

You write the routing logic. Sub-agent A always runs first, then sub-agent B gets A's output. Or: A and B run in parallel; their outputs are merged by a deterministic merge function.

ADK provides `SequentialAgent` and `ParallelAgent` for this:

```python
from google.adk.agents import SequentialAgent, ParallelAgent

# Sequential: planner output → retriever
pipeline = SequentialAgent(
    name="research_pipeline",
    agents=[planner_agent, retriever_agent],
)

# Parallel: both agents run simultaneously, results merged
parallel_lookup = ParallelAgent(
    name="parallel_lookup",
    agents=[weather_agent, news_agent],
)
```

**When to use**: Fixed routing with predictable costs — ETL pipelines, data enrichment, report generation. **Tradeoff**: Brittle under variable inputs; a rigid sequential pipeline invokes sub-agents even when they're not needed.

### Generative orchestration

The orchestrator is an Agent with a `transfer_to_agent` tool; the model decides at runtime which sub-agent to invoke, whether to invoke multiple, and in what order.

**When to use**: When routing depends on user input content you cannot enumerate at design time — support triage, intent routing, dynamic workflows. **Tradeoff**: Non-deterministic costs, harder to test exhaustively; a weak orchestrator instruction increases jailbreak risk.

<Callout type="hot">
**Model Routing: Pro vs. Flash.** In a multi-agent system, using the most expensive model for every agent is a common anti-pattern. GEAP allows per-agent model selection:
1. **Supervisor/Planner**: Always use **Gemini 3.1 Pro**. The orchestration reasoning required to decompose tasks and synthesize results is significantly higher than task execution. Pro's ARC-AGI-2 reasoning leap reduces "looping" and hallucinated handoffs.
2. **Worker/Specialist**: Use **Gemini 3.1 Flash or Flash-Lite** for high-volume, well-defined tasks (e.g., data extraction, sentiment analysis, simple lookup). If your evaluation pipeline shows Flash-Lite can handle the task, you drop your per-agent cost by 13×.
</Callout>

---

## Building the sub-agent: Retriever

```takeaways
- A sub-agent is a standard ADK `Agent` instance with its own instruction, tools, and model — the same class used for any agent, just scoped to a specialist task.
- The Retriever's instruction should constrain it to only return what it found without adding interpretation, keeping the specialization boundary clean between retrieval and synthesis.
- In production, the `search_knowledge_base` tool replaces the canned demo responses with a vector database or search API call, while the agent wiring and instruction remain unchanged.
```

Create `research_pipeline/retriever.py`:

```python
from google.adk import Agent


def search_knowledge_base(query: str) -> str:
    """Search the internal knowledge base for information relevant to a query.

    Use this tool when you have a specific factual question to answer.

    Args:
        query: The specific question to answer.

    Returns:
        A string containing the most relevant information found, or a
        'no results' message if nothing was found.
    """
    # In production, this calls a vector database, RAG pipeline, or search API.
    # For demo purposes, we return canned responses.
    knowledge = {
        "gemini enterprise agent platform ga date": "GEAP reached general availability on 23 April 2026.",
        "geap memory bank purpose": "Memory Bank stores long-term cross-session context as distilled Memory Profiles, enabling agents to recall user preferences and history across conversations.",
        "adk install command": "Install the Agent Development Kit with: pip install google-adk",
        "agent registry purpose": "Agent Registry is a centralized catalogue of approved tools, agents, and capabilities. Agents discover sub-agents by name via Registry rather than hardcoded imports.",
    }
    # Simple keyword match for demo; real implementation uses semantic search.
    query_lower = query.lower()
    for key, value in knowledge.items():
        if any(word in query_lower for word in key.split()):
            return value
    return f"No results found for: {query}"


retriever_agent = Agent(
    name="retriever",
    model="gemini-flash-latest",
    description="A specialist agent that answers specific factual questions by searching the knowledge base.",
    instruction="""You are a precise factual retriever. 

When given a question, call search_knowledge_base with the question text.
Return only what you found — do not add interpretation or speculation.
If the search returns no results, say so clearly.""",
    tools=[search_knowledge_base],
)
```

---

## Building the orchestrator: Planner

The Planner does two things: it decomposes a complex question into sub-questions, and it hands each sub-question to the Retriever using `transfer_to_agent`.

```takeaways
- `transfer_to_agent` is a built-in ADK tool that routes a message to a named sub-agent and returns that sub-agent's response into the orchestrator's context automatically.
- Declaring `sub_agents=["retriever"]` in the orchestrator serves as both a security boundary and a documentation aid that Agent Registry uses to build the graph of agent dependencies.
- Without an explicit "wait for result before the next transfer" rule in the Planner instruction, a generative orchestrator can fire multiple delegations simultaneously before receiving any responses.
```

Create `research_pipeline/planner.py`:

```python
from google.adk import Agent
from google.adk.tools import transfer_to_agent


planner_agent = Agent(
    name="planner",
    model="gemini-pro-latest",  # use a stronger model for orchestration reasoning
    description="An orchestrator that decomposes research questions and coordinates specialist agents.",
    instruction="""You are a research coordinator. Your job:

1. DECOMPOSE: When given a complex question, break it into 2-4 specific sub-questions.
2. DELEGATE: For each sub-question, transfer to the 'retriever' agent to get the answer.
3. SYNTHESISE: After all sub-questions are answered, compile a clear, complete response.

Rules:
- Always decompose before delegating. Never answer factual questions yourself.
- Transfer one sub-question at a time; wait for the result before the next transfer.
- If the original question is already specific enough (one fact to look up), skip decomposition and delegate directly.
- Your final response must cite which sub-questions were answered.""",
    tools=[transfer_to_agent],
    # Register sub-agents that this orchestrator can delegate to.
    # ADK resolves these by name at runtime; they do not need to be imported.
    sub_agents=["retriever"],
)
```

`transfer_to_agent` is a built-in ADK tool: the Planner calls it with the agent name and message; ADK routes to the Retriever and returns its response into the Planner's context.

<Callout type="info">
**Why `sub_agents` matters**: Declaring `sub_agents=["retriever"]` tells ADK which agents this orchestrator can delegate to — a security boundary and documentation aid that Agent Registry uses to build the dependency graph.
</Callout>

---

## Step 3: Wire the pipeline

Create `research_pipeline/agent.py`:

```python
from research_pipeline.planner import planner_agent
from research_pipeline.retriever import retriever_agent
from google.adk.sessions import InMemorySessionService

session_service = InMemorySessionService()

# The entry point is the planner. ADK will start here and let it delegate to retriever.
root_agent = planner_agent
```

Run it:

```bash
adk web research_pipeline/
```

<RunPromptCell
  model="gemini-pro-latest"
  tools={["transfer_to_agent", "search_knowledge_base"]}
  prompt="Tell me about Gemini Enterprise Agent Platform: when it launched, how to install it, and what Memory Bank does."
  expectedOutput={`I'll break this into three specific questions.

**Sub-question 1**: When did GEAP launch?
[transfer_to_agent: retriever]
→ "GEAP reached general availability on 23 April 2026."

**Sub-question 2**: How do I install the ADK?
[transfer_to_agent: retriever]
→ "Install the Agent Development Kit with: pip install google-adk"

**Sub-question 3**: What does Memory Bank do?
[transfer_to_agent: retriever]
→ "Memory Bank stores long-term cross-session context as distilled Memory Profiles, enabling agents to recall user preferences and history across conversations."

---

Here's what I found:

**Gemini Enterprise Agent Platform** launched on **23 April 2026** (GA). 

To get started, install the ADK: \`pip install google-adk\`

**Memory Bank** provides long-term cross-session memory — instead of rebuilding context from raw conversation history, it stores distilled "Memory Profiles" so agents can recall what they need at low latency.`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "The Planner agent calls transfer_to_agent('retriever', question). Where does ADK look to find the retriever agent at runtime?",
      answers: [
        "It imports the retriever module directly from the Python path",
        "It queries Agent Registry, resolving 'retriever' to a registered agent definition",
        "It looks for a class named RetrieverAgent in the same file",
        "It sends an HTTP request to a hardcoded localhost endpoint"
      ],
      correct: 1,
      explanation: "In production on Vertex, ADK resolves agent names through Agent Registry — a centralized catalogue of approved agents. Locally, ADK uses the sub_agents declaration to resolve names within the same session."
    },
    {
      question: "You are building a data enrichment pipeline where step B always runs after step A, regardless of what A returns. Which orchestration pattern is more appropriate?",
      answers: [
        "Generative — use transfer_to_agent and let the model decide",
        "Deterministic — use SequentialAgent to define the fixed routing",
        "Either — they produce identical results for this case",
        "Neither — GEAP does not support data pipelines"
      ],
      correct: 1,
      explanation: "When routing is fixed and predictable, deterministic orchestration (SequentialAgent) is the right choice. It gives predictable costs, easier testing, and no risk of the model skipping or reordering steps."
    }
  ]}
/>

---

## Step 4: Register agents in Agent Registry

In local development, agent resolution is handled in-process. In production on Vertex, register agents so the platform manages discovery, versioning, and access control.

Register the retriever via ADK CLI (requires a deployed Agent Runtime):

```bash
adk agents register retriever \
  --engine-id=YOUR_ENGINE_ID \
  --project=YOUR_PROJECT \
  --location=us-central1 \
  --description="Answers factual questions via knowledge base search"
```

After registration, any agent in the same project can call `transfer_to_agent("retriever", ...)` and ADK resolves it through Registry — no hardcoded endpoints. The Registry owner controls which agents are discoverable and which are retired.

<Callout type="warning">
**Registry is not import control.** Agent Registry controls discovery, not execution security. A rogue agent that knows a sub-agent's name directly can still call it if it has the right IAM permissions. For true isolation, combine Registry with Agent Gateway policies that restrict which caller identities can invoke which agents.
</Callout>

---

## Step 5: Reading an Observability trace

When the Planner hands off to the Retriever and the Retriever returns the wrong answer, how do you debug it? The Agent Observability console shows the full execution trace.

```takeaways
- Each node in the observability trace is clickable in the GCP console, letting you inspect the exact input and output of every model call and tool call in a multi-agent chain.
- Query transformation is the most common source of sub-agent failures: the orchestrator rephrases a sub-question before handing it off, and the rephrased query fails to match knowledge base entries.
- Agent Anomaly Detection flags infinite delegation loops — where two agents keep calling each other — automatically within 2-3 hops without requiring custom watchdog code.
```

A trace for a multi-agent call looks like this:

```
Trace: user-request-7f3a
├─ [0.000s] planner: received user message
│    input: "Tell me about GEAP..."
├─ [0.312s] planner: model reasoning
│    thinking: "Decompose into 3 sub-questions..."
├─ [0.891s] planner: tool_call transfer_to_agent
│    args: {agent_name: "retriever", message: "When did GEAP launch?"}
│    ├─ [0.892s] retriever: received delegation
│    ├─ [0.904s] retriever: tool_call search_knowledge_base
│    │    args: {query: "gemini enterprise agent platform ga date"}
│    │    result: "GEAP reached general availability on 23 April 2026."
│    └─ [0.967s] retriever: returned result
├─ [1.201s] planner: received sub-answer
│    content: "GEAP reached GA on 23 April 2026."
├─ [1.203s] planner: tool_call transfer_to_agent (sub-question 2)
│    ...
└─ [2.891s] planner: final response assembled
```

Each node is clickable in the GCP console — inspect exact inputs and outputs of every model call and tool call. When a handoff fails, click the `search_knowledge_base` node to see what query it received.

**Common failure patterns**:
1. **Query transformation**: The Planner rephrases a sub-question before handoff; the rephrased query doesn't match the knowledge base. Fix: instruct the Planner to pass questions verbatim.
2. **Infinite delegation**: The Retriever calls `transfer_to_agent` back to the Planner due to a loose instruction. Agent Anomaly Detection flags this within 2–3 hops.
3. **Silent tool failure**: A tool returns an empty string; the model treats it as a valid result and continues. Always return explicit "no results" messages.

<RunPromptCell
  model="gemini-pro-latest"
  tools={["transfer_to_agent", "search_knowledge_base"]}
  prompt="What is the Agent Registry and why does it matter for production multi-agent systems?"
  expectedOutput={`[transfer_to_agent: retriever]
message: "What is Agent Registry and what is its purpose?"

→ "Agent Registry is a centralized catalogue of approved tools, agents, and capabilities. Agents discover sub-agents by name via Registry rather than hardcoded imports."

**Agent Registry** is GEAP's centralized catalogue of agents and tools. In practice, it matters because it separates *discovery* from *implementation*: your Planner agent doesn't import the Retriever — it asks Registry for an agent named 'retriever'. 

This means:
- **Versioning**: Update the Retriever without touching the Planner's code
- **Governance**: The Registry owner controls which agents are visible to which callers
- **Auditability**: Registry logs show exactly which agents called which sub-agents`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "An Agent Observability trace shows the Planner calling transfer_to_agent three times in a row before the Retriever responds to the first call. What is the most likely cause?",
      answers: [
        "The Planner instruction is missing the 'wait for result' constraint, causing it to fire multiple delegations simultaneously",
        "The Retriever is rate-limited, causing the Planner to retry",
        "Agent Registry is down",
        "The gemini-pro-latest model does not support multi-step tool use"
      ],
      correct: 0,
      explanation: "Without an explicit instruction to wait for each result before the next transfer, a generative orchestrator can issue multiple transfer_to_agent calls before processing any results. Fix: add 'wait for the result before the next transfer' to the Planner's instruction."
    },
    {
      question: "Why is Agent Gateway recommended alongside Agent Registry in production multi-agent systems?",
      answers: [
        "Gateway improves model response quality for sub-agent calls",
        "Registry controls discovery but not execution security; Gateway enforces IAM-backed access policies",
        "Gateway is required for Memory Bank to function",
        "Gateway reduces cold-start latency for sub-agent invocations"
      ],
      correct: 1,
      explanation: "Agent Registry controls which agents are discoverable by name. Agent Gateway enforces which callers are actually allowed to invoke them. For production security, you need both: Registry for governance and Gateway for enforcement."
    }
  ]}
/>

---

## Hands-on exercise: Build the research pipeline

**Goal**: A two-agent system where the Planner decomposes questions and the Retriever answers them.

**Steps**:
1. Create the directory structure: `research_pipeline/__init__.py`, `research_pipeline/retriever.py`, `research_pipeline/planner.py`, `research_pipeline/agent.py`
2. Implement the Retriever with `search_knowledge_base` as shown. Add at least 3 additional knowledge base entries on a topic of your choice.
3. Implement the Planner with `transfer_to_agent` and the `sub_agents=["retriever"]` declaration.
4. Run `adk web research_pipeline/` and ask a question that requires at least 2 sub-questions to answer fully.
5. In the ADK web UI, click on the trace view and identify the exact point where the Planner transferred to the Retriever.
6. **Extension**: Add a third agent — a `Formatter` that takes the Planner's synthesis and formats it as a structured markdown report. Wire it as a deterministic last step using `SequentialAgent`.

**Success criteria**:
- Planner correctly decomposes a multi-part question (visible in the trace)
- Retriever is called once per sub-question (not once per user message)
- Synthesis addresses all sub-questions without hallucinating new facts
- Trace in the UI shows the delegation chain clearly

---

## What's next

You have now built a two-agent system on GEAP. Chapter 4 puts GEAP in honest comparison with Claude Agent SDK and Cloudflare Agents — covering state management, deployment topology, lock-in, and the workloads each platform wins.

See [[gemini-enterprise-agent-platform-hands-on-tour/04-comparing-to-claude-agent-sdk-and-cloudflare-agents]] to continue.

---

## References

[1] Google Cloud Blog. "Introducing Gemini Enterprise Agent Platform." 23 April 2026. — https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform · retrieved 2026-04-30

[2] Google Agent Development Kit. Agent-to-agent orchestration guide. — https://adk.dev/ · retrieved 2026-04-30

[3] Google Cloud. Multi-agent documentation. — https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/multi-agent · retrieved 2026-04-30

[4] Google Cloud. Agent Registry guide. — https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/agent-registry · retrieved 2026-04-30

[5] Google Cloud. Agent Observability documentation. — https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/observability · retrieved 2026-04-30
