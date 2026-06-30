---
course_slug: production-agents-claude-agent-sdk-mcp-connector
chapter_num: 2
chapter_slug: managed-agents-when-to-use
title: "Managed Agents beta — when to use it, when to roll your own"
description: "Choose when to use Claude Managed Agents versus the local Agent SDK by comparing hosting, session lifecycle, streaming, and cost controls."
tags: [managed-agents, agent-hosting, cloud-agents]
faq:
  - q: "What are Claude Managed Agents?"
    a: "They are Anthropic-hosted agent sessions that run in managed cloud environments and communicate through REST and streaming events."
  - q: "When should I prefer the Agent SDK?"
    a: "Prefer the Agent SDK when you need local control, simple per-request execution, or infrastructure you already operate."
  - q: "What event tells my app the session is done?"
    a: "The session.status_idle event is the key signal that a Managed Agents task has reached an idle state."
status: g3-passed
last_updated: 2026-06-14
author: vardaan-koenig
agent_drafted_by: course-author
date: 2026-04-30
duration_min: 45
prerequisites_chapters: [1]
learning_objectives:
  - "Describe the four core Managed Agents concepts: Agent, Environment, Session, Events"
  - "Create an agent, environment, and session via the REST API"
  - "Stream SSE events and correctly detect session.status_idle"
  - "Apply the decision rule: Managed Agents vs Agent SDK for five scenario types"
key_concepts:
  [managed-agents, agent-environment-session, sse-streaming, runtime-pricing, beta-header, status-idle]
hands_on_exercise: "Ship a Managed Agents session that runs a multi-step data analysis task and streams all tool-use events to your terminal"
sources:
  - https://platform.claude.com/docs/en/managed-agents/overview
  - https://platform.claude.com/docs/en/managed-agents/quickstart
  - https://claude.com/blog/agent-capabilities-api
  - https://platform.claude.com/docs/en/api/beta-headers
  - https://code.claude.com/docs/en/agent-sdk/overview
  - https://modelcontextprotocol.io/docs/getting-started/intro
---

# Managed Agents beta — when to use it, when to roll your own

Claude Managed Agents is Anthropic's hosted REST API for running Claude as an autonomous agent in a sandboxed cloud environment — launched in public beta on April 8, 2026, requiring the `managed-agents-2026-04-01` beta header. Where the [[course/production-agents-claude-agent-sdk-mcp-connector/01-sdk-rename-what-changed|Agent SDK]] runs the agent loop in your own process, Managed Agents runs it in Anthropic's infrastructure: you send user messages, you stream results back. Anthropic handles the container, tool execution, and session persistence [1]. Verify current pricing in the official quickstart before launch [2].

## Key facts

1. All API requests require the `managed-agents-2026-04-01` beta header [1].
2. Pricing: Managed Agents runtime plus standard Claude token costs; verify current rates before launch [2].
3. Rate limits: 300 RPM for create endpoints (agents, sessions, environments); 600 RPM for read endpoints [1].
4. `agent_toolset_20260401` enables Bash, file ops, web search, and MCP; outcomes and multiagent are research preview requiring separate access [1].

## The four core concepts

**Agent** — saved configuration (model, system prompt, tools). Create once, reuse by `agent.id`. Think Docker image: build once, run many sessions from it.

**Environment** — cloud container template: packages, network rules. `cloud` config with `unrestricted` or `restricted` networking.

**Session** — one running agent+environment instance per task. Not reused; start a new one when the task is done.

**Events** — SSE stream: you send `user.message`; agent emits `agent.message`, `agent.tool_use`, then `session.status_idle` when done.

```takeaways
- Managed Agents uses four primitives: Agent (saved config), Environment (sandbox template), Session (running instance per task), and Events (SSE message stream).
- Sessions are not reused — one session equals one task; when the task is done, start a new session for the next task.
- Agent and Environment IDs are stable and should be created once and reused; only the Session is created per-task to avoid hitting the 300 create-requests-per-minute rate limit.
```

## Creating your first agent

Install the Anthropic SDK (Managed Agents uses the standard client, not the Agent SDK):

```bash
pip install anthropic  # Python
npm install @anthropic-ai/sdk  # TypeScript
```

Create an agent once — save the returned `agent.id`:

```python
from anthropic import Anthropic

client = Anthropic()  # reads ANTHROPIC_API_KEY from env

agent = client.beta.agents.create(
    name="Data Analyst",
    model="claude-opus-4-7",
    system="You are a data analyst. When given a dataset, summarize it with statistics and key insights.",
    tools=[
        {"type": "agent_toolset_20260401"},  # enables Bash, file ops, web search
    ],
)

print(f"Agent ID: {agent.id}")  # save this
print(f"Agent version: {agent.version}")
```

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const agent = await client.beta.agents.create({
  name: "Data Analyst",
  model: "claude-opus-4-7",
  system: "You are a data analyst. When given a dataset, summarize it with statistics and key insights.",
  tools: [{ type: "agent_toolset_20260401" }],
});

console.log(`Agent ID: ${agent.id}`);
```

<Callout type="info">
The `agent_toolset_20260401` tool type is a bundle — it's not equivalent to listing individual tools. It enables everything Managed Agents supports including Bash, file I/O, web search/fetch, and MCP. If you need to restrict to specific tools, configure them individually rather than using the toolset bundle.
</Callout>

## Creating an environment

```python
environment = client.beta.environments.create(
    name="analyst-env",
    config={
        "type": "cloud",
        "networking": {"type": "unrestricted"},  # allows outbound web access
    },
)

print(f"Environment ID: {environment.id}")  # save this too
```

The environment is a one-time setup. Use `unrestricted` for most workloads; `restricted` blocks outbound access for sensitive data.

## Starting a session and streaming events

Open the stream, then immediately send the first user message:

```python
import asyncio
from anthropic import Anthropic

client = Anthropic()

# Create session (reuse agent_id and environment_id from above)
session = client.beta.sessions.create(
    agent=agent_id,
    environment_id=environment_id,
    title="Analyze Q1 sales data",
)

# Open SSE stream + send first message
with client.beta.sessions.events.stream(session.id) as stream:
    client.beta.sessions.events.send(
        session.id,
        events=[{
            "type": "user.message",
            "content": [{
                "type": "text",
                "text": "Here is some sales data as a Python list: [120, 340, 290, 410, 380]. Compute mean, median, and standard deviation. Show your work in Python code."
            }]
        }],
    )

    for event in stream:
        match event.type:
            case "agent.message":
                for block in event.content:
                    print(block.text, end="", flush=True)
            case "agent.tool_use":
                print(f"\n[Tool: {event.name}]", flush=True)
            case "session.status_idle":
                print("\n\n[Session complete]")
                break
```

```typescript
const session = await client.beta.sessions.create({
  agent: agentId,
  environment_id: environmentId,
  title: "Analyze Q1 sales data",
});

const stream = await client.beta.sessions.events.stream(session.id);

await client.beta.sessions.events.send(session.id, {
  events: [{
    type: "user.message",
    content: [{
      type: "text",
      text: "Sales data: [120, 340, 290, 410, 380]. Compute mean, median, std dev. Show Python code."
    }]
  }]
});

for await (const event of stream) {
  if (event.type === "agent.message") {
    for (const block of event.content) process.stdout.write(block.text);
  } else if (event.type === "agent.tool_use") {
    console.log(`\n[Tool: ${event.name}]`);
  } else if (event.type === "session.status_idle") {
    console.log("\n[Session complete]");
    break;
  }
}
```

<RunPromptCell
  model="claude-opus-4-7"
  prompt="You are running inside a Managed Agents session. The user has sent: 'Here is some sales data as a Python list: [120, 340, 290, 410, 380]. Compute mean, median, and standard deviation. Show your work in Python code.' Run the computation using the Bash tool."
  expectedOutput="Claude emits an agent.message with a plan, then an agent.tool_use event for Bash, then another agent.message with results like: mean=308.0, median=340.0, std_dev=109.3. The session then emits session.status_idle."
/>

```takeaways
- Open the SSE stream before sending the first `user.message` event; events arrive in real time, including `agent.tool_use` calls and `agent.message` responses.
- The `session.status_idle` event is the canonical signal that the agent has finished working; break the stream loop when you see it.
- Always close idle sessions explicitly with `client.beta.sessions.update(session.id, status="completed")` to avoid ongoing runtime cost exposure.
```

## Session lifecycle and cost

Managed Agents cost depends on session lifetime, not just active generation time. A session left idle after `session.status_idle` can accrue runtime exposure — verify current billing rules in the official quickstart [2]. Never use Managed Agents for polling loops; use the Agent SDK with a cron job instead. For cost circuit breakers and audit hooks that protect production sessions, see [[course/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability|Chapter 5]].

Always close idle sessions explicitly:

```python
client.beta.sessions.update(session.id, status="completed")
```

## Decision rule: Managed Agents vs Agent SDK

| Scenario | Use |
|---|---|
| Long-running task (>5 min), async, need cloud sandbox | **Managed Agents** |
| Agent needs to operate on files on your own server/filesystem | **Agent SDK** |
| You need custom in-process tool execution (Python functions) | **Agent SDK** |
| You're prototyping locally; no cloud infra budget yet | **Agent SDK** |
| You need to serve many concurrent agent sessions to end users | **Managed Agents** (they handle the infrastructure) |


<Callout type="hot">
Managed Agents is in public beta as of April 2026. The `managed-agents-2026-04-01` beta header is required on every request. Behaviors can be refined between releases. Two capabilities — outcomes and multiagent — are in research preview and require a separate access request at `claude.com/form/claude-managed-agents`. Do not build production features that depend on research-preview capabilities without direct Anthropic support.
</Callout>

```takeaways
- Use Managed Agents for long-running (>5 min), async tasks needing a cloud sandbox; use the Agent SDK for short, stateless, webhook-triggered, or locally-executed work.
- Runtime pricing has two components: Managed Agents runtime plus standard Claude token costs — verify current rates in the official quickstart before launch.
- The `managed-agents-2026-04-01` beta header is required on every request; outcomes and multiagent are in research preview and require a separate access request.
```

## Hands-on exercise

**Ship a Managed Agents session streaming a data analysis task to your terminal.**

1. Create agent: `model: "claude-opus-4-7"`, `tools: [{ type: "agent_toolset_20260401" }]`
2. Create environment: `type: "cloud"`, `networking: { type: "unrestricted" }`
3. Create session; send: "Fetch https://jsonplaceholder.typicode.com/todos (10 items), filter completed, print titles. Run it."
4. Print tool name per `agent.tool_use`, text per `agent.message`

**Verify**: At least one `[Tool: bash]` line, ending with `[Session complete]`. **Est. time**: 20 min

<KnowledgeCheck
  question="A team is building an AI coding assistant that responds to GitHub webhook events. Each request takes 15–30 seconds. The team is choosing between Managed Agents and Agent SDK. Which is more appropriate, and why?"
  options={[
    "Agent SDK — short, stateless, webhook-triggered tasks don't benefit from Managed Agents' hosted runtime, and per-invocation costs are lower",
    "Managed Agents — it scales automatically to handle concurrent GitHub events",
    "Managed Agents — it includes a built-in GitHub webhook listener",
    "Agent SDK — the Managed Agents beta header makes it unsuitable for production webhooks"
  ]}
  correctIdx={0}
  explanation="For 15–30 second tasks triggered by webhooks, the Agent SDK on a serverless function (Lambda, Cloud Run) is the right call. Managed Agents is designed for hosted agent sessions, so the architecture fit is weaker when every task is short, stateless, and easy to run in your own invocation. The beta header caveat is real but not the primary reason — lifecycle and operational ownership are."
/>

<KnowledgeCheck
  question="You've created a Managed Agents session and opened the SSE stream. What event type signals that the agent has finished working and your application should stop listening?"
  options={["self-check"]}
  correctIdx={0}
  explanation="Self-check: The event type is `session.status_idle`. When you see this event in your stream loop, break out of the loop and optionally close the session with `client.beta.sessions.update(session.id, status='completed')`. Not breaking the loop means your stream stays open and the session continues accruing runtime cost."
/>

## Rate limits

The 300 RPM create limit is shared across agent, environment, and session creates. **Pre-create agents and environments once** — only sessions are per-task:

```python
# Create once, store these IDs
AGENT_ID = "agt_01XxXxxXx"       # created once, reused forever
ENVIRONMENT_ID = "env_01YyYyyYy"  # created once, reused forever

# Create per-task
async def handle_user_request(task: str) -> str:
    session = client.beta.sessions.create(
        agent=AGENT_ID,           # reused
        environment_id=ENVIRONMENT_ID,  # reused
        title=task[:100],
    )
    # ... stream events
```


## What's next

[[course/production-agents-claude-agent-sdk-mcp-connector/03-mcp-connector-multi-server|Chapter 3]] covers MCP tool servers — three transport modes and the permission grants that make them work.

## References

[1] Claude Managed Agents Overview — https://platform.claude.com/docs/en/managed-agents/overview · retrieved 2026-04-30
[2] Claude Managed Agents Quickstart — https://platform.claude.com/docs/en/managed-agents/quickstart · retrieved 2026-04-30
[3] Agent Capabilities API announcement — https://claude.com/blog/agent-capabilities-api · retrieved 2026-04-30
[4] Managed Agents Beta Header Documentation — https://platform.claude.com/docs/en/api/beta-headers · retrieved 2026-05-14
[5] Claude Agent SDK Overview — https://code.claude.com/docs/en/agent-sdk/overview · retrieved 2026-04-30
[6] Model Context Protocol introduction — https://modelcontextprotocol.io/docs/getting-started/intro · retrieved 2026-05-14
