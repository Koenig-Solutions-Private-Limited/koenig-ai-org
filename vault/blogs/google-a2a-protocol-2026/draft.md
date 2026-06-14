---
title: "Use Google A2A for cross-agent delegation, not as an MCP replacement (2026)"
description: "Google A2A matters in 2026 because it standardizes durable task state, auth interruptions, and artifact exchange across agents, while MCP still handles tools and context inside each agent."
slug: 2026-05-13-google-a2a-protocol
date: 2026-05-13
author: vardaan-koenig
agent_drafted_by: blog-author
ticket: KOEA-3050
vendor_tag: google
content_type: article
status: awaiting-g0
reading_time_min: 14
primary_query: "google a2a protocol explained"
contrarian_angle: "A2A is not winning by replacing MCP; it is winning by standardizing the state, auth, and resume layer that cross-agent systems kept rebuilding badly."
first_60_words_answer: "Google's Agent2Agent (A2A) Protocol is an open standard for delegating work between independent agents over a shared task interface. A2A v1.0.0, released March 2026, added task listing, modern OAuth flows, and multi-tenant transport — making it production infrastructure. It complements MCP rather than replacing it: A2A handles cross-agent delegation while MCP handles tools and context inside a single agent."
tags: [google, a2a, agent-protocols, mcp, agntcy, gemini, multi-agent]
positions:
  - id: mcp-as-interoperability-moat
    engagement: extends
seo_description: "Google A2A v1.0 standardizes cross-agent task delegation, OAuth interruptions, and artifact exchange. 2026 guide to using A2A alongside MCP in production."
sources:
  - https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/
  - https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade
  - https://a2a-protocol.org/latest/specification/
  - https://github.com/a2aproject/A2A/releases/tag/v1.0.0
  - https://github.com/a2aproject/a2a-python
  - https://a2a-protocol.org/latest/tutorials/python/6-interact-with-server/
  - https://a2a-protocol.org/latest/topics/streaming-and-async/
  - https://a2a-protocol.org/latest/roadmap/
  - https://agntcy.org/
  - https://a2a-protocol.org/latest/partners/
  - https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform
  - https://cloud.google.com/blog/products/ai-machine-learning/the-new-gemini-enterprise-one-platform-for-agent-development
  - https://cloud.google.com/blog/products/ai-machine-learning/partner-built-agents-available-in-gemini-enterprise
whats_new:
  - "A2A became production infrastructure in 2026 because v1.0 finally standardized task state, auth interrupts, and multi-tenant transport details."
learning_objectives:
  - "Explain where A2A fits relative to MCP in a multi-agent architecture."
  - "Identify the v1.0 protocol changes that made A2A materially more usable in production."
  - "Recognize when A2A is enough and when a broader coordination fabric like AGNTCY is the better fit."
faq:
  - question: "Is A2A a replacement for MCP?"
    answer: "No. [MCP](https://modelcontextprotocol.io/) standardizes tool and context access inside a single agent's world — tools, resources, prompts, and context channels. [A2A](https://a2a-protocol.org/latest/specification/) standardizes delegation between independent agents over a shared task interface, allowing each remote agent to maintain its own permissions and internal execution chain without exposing its internals to the orchestrator."
  - question: "Why did A2A matter more in 2026 than at launch?"
    answer: "Because [v1.0.0](https://github.com/a2aproject/A2A/releases/tag/v1.0.0), released March 12, 2026, added the boring but essential production pieces: transport separation from application protocol, `tasks/list` with filtering and pagination, modern OAuth flows (Device Code and PKCE), and native gRPC multi-tenancy. Those changes make a protocol look like infrastructure rather than a demo — which is why adoption accelerated in 2026."
  - question: "Can Claude, OpenAI, and Gemini agents speak A2A if they expose compatible endpoints?"
    answer: "Yes. [A2A](https://a2a-protocol.org/latest/specification/) is vendor-neutral at the protocol layer: the client resolves an Agent Card at `/.well-known/agent-card.json`, sends tasks to the declared interface, and iterates over task state or artifact updates — regardless of whether Claude, OpenAI, or Gemini powers the endpoint. The [official Python SDK](https://github.com/a2aproject/a2a-python) implements spec 1.0 with backward compatibility for 0.3 across JSON-RPC, HTTP+JSON/REST, and gRPC."
  - question: "Where does AGNTCY fit?"
    answer: "[AGNTCY](https://agntcy.org/) sits above raw delegation and aims at a fuller internet-of-agents stack — adding discovery through OASF, cryptographically verifiable identity, SLIM messaging, and observability layers that [A2A](https://a2a-protocol.org/latest/specification/) leaves to the implementer. If A2A handles delegating a task to one known agent, AGNTCY is the layer for finding which agent to delegate to, routing across organizational boundaries, and tracking accountability across vendors."
hero_image:
  url: auto:flux
  alt: "Diagram showing A2A protocol handling cross-agent task delegation while MCP manages tools and context within each agent, with task state lifecycle overlay"
references:
  - n: 1
    title: "Announcing the Agent2Agent Protocol (A2A)"
    url: https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/
    retrieved: 2026-05-13
  - n: 2
    title: "Agent2Agent protocol (A2A) is getting an upgrade"
    url: https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade
    retrieved: 2026-05-13
  - n: 3
    title: "Agent2Agent (A2A) Protocol Specification"
    url: https://a2a-protocol.org/latest/specification/
    retrieved: 2026-05-13
  - n: 4
    title: "Release v1.0.0 · a2aproject/A2A"
    url: https://github.com/a2aproject/A2A/releases/tag/v1.0.0
    retrieved: 2026-05-13
  - n: 5
    title: "Official Python SDK for the Agent2Agent (A2A) Protocol"
    url: https://github.com/a2aproject/a2a-python
    retrieved: 2026-05-13
  - n: 6
    title: "Interacting with the Server - A2A Protocol"
    url: https://a2a-protocol.org/latest/tutorials/python/6-interact-with-server/
    retrieved: 2026-05-13
  - n: 7
    title: "Streaming & Asynchronous Operations - A2A Protocol"
    url: https://a2a-protocol.org/latest/topics/streaming-and-async/
    retrieved: 2026-05-13
  - n: 8
    title: "A2A protocol roadmap"
    url: https://a2a-protocol.org/latest/roadmap/
    retrieved: 2026-05-13
  - n: 9
    title: "AGNTCY.org"
    url: https://agntcy.org/
    retrieved: 2026-05-13
  - n: 10
    title: "Partners - A2A Protocol"
    url: https://a2a-protocol.org/latest/partners/
    retrieved: 2026-05-13
  - n: 11
    title: "Introducing Gemini Enterprise Agent Platform"
    url: https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform
    retrieved: 2026-05-13
  - n: 12
    title: "The new Gemini Enterprise: one platform for agent development"
    url: https://cloud.google.com/blog/products/ai-machine-learning/the-new-gemini-enterprise-one-platform-for-agent-development
    retrieved: 2026-05-13
  - n: 13
    title: "Partner-built agents available in Gemini Enterprise"
    url: https://cloud.google.com/blog/products/ai-machine-learning/partner-built-agents-available-in-gemini-enterprise
    retrieved: 2026-05-13
---

# Use Google A2A when another agent should own the work, not when you just need a tool

Google's Agent2Agent Protocol is an open agent interoperability standard introduced by Google in April 2025 for delegating work between independent agents over a shared task interface. By March 2026, A2A had reached v1.0.0 with standardized task listing, modern OAuth flows, and multi-tenant transport support, which is why it now looks more like production infrastructure than a launch-week demo [1][4].

## Key facts

1. Google introduced A2A on April 9, 2025 as a protocol for agent-to-agent interoperability rather than as a replacement for tool protocols such as MCP [1].
2. A2A v1.0.0 shipped on March 12, 2026 with transport separation, `tasks/list`, PKCE and Device Code OAuth flows, and gRPC multi-tenancy support [4].
3. The spec requires an Agent Card at `/.well-known/agent-card.json` and centers interaction on tasks, messages, artifacts, and resumable task state [3].
4. Google's August 1, 2025 upgrade positioned A2A for enterprise use with gRPC support, signed cards, and an ecosystem of more than 150 organizations [2].
5. Gemini Enterprise Agent Platform embedded A2A into Google's broader agent runtime and marketplace story in April 2026 [11][12][13].

The part most teams still miss is where A2A became genuinely useful. The launch story in 2025 was interoperability. The real 2026 story is control plane maturity. Once A2A shipped v1.0.0 with transport separation, `tasks/list`, modern OAuth patterns including PKCE and Device Code, and stronger multi-tenant support, it stopped looking like a clever demo protocol and started looking like infrastructure you could put in front of enterprise workflows [4]. That is the reason to care now.

## Use A2A for delegated ownership and keep MCP for tools

A2A is for agent peers. MCP is for tools, data, and context. If your orchestrator needs a finance agent, a compliance agent, and a research agent to each do work with their own permissions and internal logic, the clean design is to let those agents expose A2A endpoints and keep their private tools behind MCP or whatever internal adapter they already trust [1][3].

That architectural line matters because tool reach-through is where multi-agent systems get ugly fast. Once an orchestrator starts grabbing every downstream tool directly, you lose local policy boundaries, permission scoping, and ownership over retries or approvals. The A2A spec instead assumes opaque execution: the remote agent advertises capabilities through an Agent Card, accepts a task, updates status, and returns artifacts without exposing the internal chain that got there [3].

Google's launch post made this explicit by positioning A2A as complementary to Anthropic's Model Context Protocol. That was not diplomatic wording. It was a design constraint. A2A handles collaboration between agents that may not share runtime, memory, or vendor stack. MCP handles the inside of one agent's world: tools, resources, prompts, and context channels [1]. In practice, that means a useful stack often looks like this:

- An orchestrator calls a remote research agent over A2A.
- The research agent uses MCP internally to access search, files, and citation databases.
- The orchestrator receives only the task state and artifact outputs it needs.

That is why [[mcp-2026-roadmap-explained]] and A2A are best understood together. They solve adjacent problems, not the same one.

The point is not elegance. It is blast-radius control. When a remote agent hits `AUTH_REQUIRED` or `INPUT_REQUIRED`, the task model can pause and resume cleanly instead of collapsing into ad hoc error handling [3]. That is a production property, not a philosophical one.

## Treat 2026 as A2A's production year, not its announcement year

A2A became interesting in April 2025. It became credible in 2026. The launch announcement introduced the core design, said the protocol would be open, and framed it around long-running tasks, capability discovery, and modality-agnostic interaction over HTTP, SSE, and JSON-RPC [1]. Useful. Still early.

The first meaningful stabilization signal came in Google's August 1, 2025 upgrade post. Google said A2A v0.3 was pushing toward enterprise stability, added gRPC support, added signed security cards, improved Python SDK support, and said the ecosystem had grown to more than 150 organizations [2]. Protocols usually fail from lack of operational detail and partner gravity, not lack of cleverness.

Then v1.0.0 landed on March 12, 2026 under the Linux Foundation-hosted `a2aproject` repository. The release notes are worth reading because the most important changes are exactly the boring ones teams usually postpone until the second rewrite: the application protocol was separated from transport mappings, `tasks/list` gained filtering and pagination, OAuth removed implicit and password grants in favor of Device Code and PKCE, and gRPC gained native multi-tenancy support via additional request scope data [4]. Those are the fingerprints of a protocol leaving adolescence.

The roadmap page, last updated March 10, 2026, reinforces the same story. Near-term work is no longer "prove the idea exists." It is validation, compatibility kits, SDK breadth across five languages, and community best practices [8]. That is what mature infrastructure projects talk about when they expect real deployments.

Google's surrounding platform story also changed in spring 2026. The Gemini Enterprise Agent Platform announcement on April 23, 2026 positioned A2A inside a larger runtime, registry, gateway, identity, and governance system for enterprise agents [12]. The related Gemini Enterprise platform post the same day described an agent development platform that uses open protocols like A2A and MCP alongside runtime, observability, and centralized governance, without making the stronger claim that the post itself labels those protocols "complementary" [12]. That same day, Google announced partner-built agents from the marketplace landing directly inside Gemini Enterprise, with Adobe, Salesforce, ServiceNow, Workday, and others showing up in the agent gallery and procurement flow [13].

That sequence is the real milestone. Protocol launch. Stability upgrade. v1 release. Platform embedding. Partner channel. If you are deciding whether A2A is "real," that timeline is the answer.

Partner breadth is another hard signal. The A2A partner directory now spans cloud providers, enterprise SaaS, observability vendors, telecoms, and security companies, including Microsoft, SAP, Adobe, Atlassian, Salesforce, ServiceNow, Workday, Cisco, Datadog, and many others [10]. That does not guarantee long-term dominance. It does make custom one-off agent APIs look less attractive in enterprise buying cycles.

## Model long-running work as task state, not chat turns

A2A matters most when the work is interruptible, resumable, and artifact-heavy. The spec centers interaction on tasks, messages, and artifacts rather than on a single request-response turn. That is why the protocol can represent `TASK_STATE_WORKING`, `TASK_STATE_INPUT_REQUIRED`, `TASK_STATE_AUTH_REQUIRED`, `TASK_STATE_COMPLETED`, and other lifecycle states directly instead of forcing every agent framework to reinvent them in application logic [3].

This is where the protocol is sharper than most vendor demos. A lot of agent products still behave like chat with nicer nouns. A2A does not. Its task object assumes that real work may last minutes, hours, or days, and that the client may poll, stream updates, or rely on push notifications depending on the situation [3][7].

The official async guidance makes the contract even clearer. If a client can keep an active connection open, it can use SSE streaming and receive `TaskStatusUpdateEvent` and `TaskArtifactUpdateEvent` objects in real time. If the task is too long-running for that, or the client is mobile or serverless, the server can send push notifications to a webhook and the client can call `GetTask` to retrieve the latest full state [7]. That may sound routine, but it is exactly the state machine most teams end up inventing by hand once the first approval flow or credential prompt arrives.

The v1.0 changes improved this layer in practical ways. The protocol removed some earlier structural awkwardness, formalized `SubscribeToTask`, standardized error handling via `google.rpc.Status`, simplified IDs, removed the `/v1` URL prefix, and clarified how the Agent Card advertises interfaces and versions [4]. If you have ever had to keep a long-running orchestration system alive across dropped sockets, retries, approval pauses, and credential interruptions, those changes are not cosmetic.

This is also why the official Python SDK matters. The `a2a-python` project now implements A2A spec 1.0 with backward compatibility for 0.3 across JSON-RPC, HTTP+JSON/REST, and gRPC. That means the client is talking to one task model even if the transport changes underneath it [5]. The tutorial client resolves the Agent Card from `/.well-known/agent-card.json`, builds a client, sends a message, and then iterates over task or stream chunks rather than assuming one terminal response [6].

Once you see A2A as a task protocol instead of a chat wrapper, the design starts to click. It is building the boring middle layer between orchestration logic and remote execution. That is where most multi-agent systems get brittle.

## Wire Claude, OpenAI, and Gemini through the same A2A contract

The cleanest proof that A2A is useful is that the client code barely cares which model vendor sits behind the endpoint. It cares about the Agent Card, the supported interface, the task lifecycle, and the output artifact. If a Claude-backed research agent, an OpenAI-backed coding agent, and a Gemini-backed planning agent each expose an A2A-compatible surface, the orchestration code gets much flatter [1][3][5].

The first step is publishing the Agent Card. A2A v1.0 Agent Cards advertise supported interfaces, protocol binding, protocol version, skills, and capabilities such as streaming or push notifications [3]. A minimal Gemini-backed planner can expose that card through a standard HTTP route:

```python
from fastapi import FastAPI
from google.protobuf.json_format import MessageToDict
from a2a.types import (
    AgentCard,
    AgentCapabilities,
    AgentInterface,
    AgentProvider,
    AgentSkill,
)

app = FastAPI()

agent_card = AgentCard(
    name="gemini-planner",
    description="Plans multi-agent workflows and returns task graphs.",
    provider=AgentProvider(
        organization="Google Cloud",
        url="https://cloud.google.com",
    ),
    version="1.0.0",
    capabilities=AgentCapabilities(
        streaming=True,
        push_notifications=True,
    ),
    supported_interfaces=[
        AgentInterface(
            url="https://gemini.example.invalid",
            protocol_binding="JSON_RPC",
            protocol_version="1.0",
        )
    ],
    skills=[
        AgentSkill(
            id="plan",
            name="plan",
            description="Turn a business goal into an ordered task graph.",
        )
    ],
)

@app.get("/.well-known/agent-card.json")
async def public_agent_card():
    return MessageToDict(agent_card, preserving_proto_field_name=False)
```

Expected output:

```json
{
  "name": "gemini-planner",
  "capabilities": {
    "streaming": true,
    "pushNotifications": true
  },
  "supportedInterfaces": [
    {
      "url": "https://gemini.example.invalid",
      "protocolBinding": "JSON_RPC",
      "protocolVersion": "1.0"
    }
  ]
}
```

That is registration in the only sense that matters for interoperable clients: capability discovery through a stable, machine-readable card [3].

The second step is sending a real task to a remote agent. The official Python client flow is simple: resolve the card, create the client, construct a `SendMessageRequest`, and iterate over the response stream [5][6]. A Claude-backed research agent can look like this:

```python
import asyncio
import httpx
from a2a.client import A2ACardResolver, ClientConfig, create_client
from a2a.types import Message, Part, Role, SendMessageRequest

async def run() -> None:
    base_url = "https://claude-research.example.invalid"

    async with httpx.AsyncClient(timeout=30) as httpx_client:
        resolver = A2ACardResolver(httpx_client=httpx_client, base_url=base_url)
        card = await resolver.get_agent_card()
        client = await create_client(agent=card, client_config=ClientConfig(streaming=True))

        request = SendMessageRequest(
            message=Message(
                role=Role.ROLE_USER,
                parts=[Part(text="Find three primary sources on A2A security and summarize the risks.")],
            )
        )

        async for event in client.send_message(request):
            print(event)

asyncio.run(run())
```

Expected output:

```text
task { state: TASK_STATE_SUBMITTED ... }
status_update { state: TASK_STATE_WORKING ... }
artifact_update { artifact { name: "result" ... } }
status_update { state: TASK_STATE_COMPLETED }
```

That pattern is vendor-neutral. The only vendor-specific part is whatever sits behind `https://claude-research.example.invalid` [3][5][6].

The third step is handling async completion. A coding agent backed by OpenAI is a good fit for push notifications because codegen or refactor jobs may outlive a single open HTTP stream. The official async topic shows that the client can attach a `TaskPushNotificationConfig`, let the server notify a webhook on major state changes, and then call `GetTask` with the returned task ID to retrieve the full final state [7]. With the Python SDK types, the request shape looks like this:

```python
import asyncio
import httpx
from a2a.client import A2ACardResolver, ClientConfig, create_client
from a2a.types import (
    Message,
    Part,
    Role,
    SendMessageConfiguration,
    SendMessageRequest,
    TaskPushNotificationConfig,
)

async def run() -> None:
    base_url = "https://openai-code-agent.example.invalid"

    async with httpx.AsyncClient(timeout=30) as httpx_client:
        resolver = A2ACardResolver(httpx_client=httpx_client, base_url=base_url)
        card = await resolver.get_agent_card()
        client = await create_client(agent=card, client_config=ClientConfig(streaming=False))

        callback = TaskPushNotificationConfig(
            url="https://ops.example.invalid/a2a/callback",
            token="demo-shared-secret",
        )

        request = SendMessageRequest(
            message=Message(
                role=Role.ROLE_USER,
                parts=[Part(text="Refactor src/agent.py to separate retry policy from transport code.")],
            ),
            configuration=SendMessageConfiguration(
                task_push_notification_config=callback,
                history_length=20,
                return_immediately=True,
            ),
        )

        async for event in client.send_message(request):
            print(event)

asyncio.run(run())
```

Expected output:

```text
task { state: TASK_STATE_SUBMITTED ... }
# later: webhook receives TASK_STATE_WORKING / TASK_STATE_COMPLETED updates
```

A minimal local webhook receiver for that callback can be as simple as:

```bash
curl -X POST https://ops.example.invalid/a2a/callback \
  -H 'content-type: application/json' \
  -d '{"statusUpdate":{"taskId":"task-123","status":{"state":"TASK_STATE_COMPLETED"}}}'
```

Expected output:

```json
{"ok":true}
```

If you are building [[multi-agent-orchestration-a2a]], this is the payoff. The orchestrator code stops caring whether the remote agent runs Claude, GPT, Gemini, or something internal. It cares whether the endpoint keeps the A2A contract.

## Compare A2A, MCP, and AGNTCY by layer instead of by hype

A2A and AGNTCY only look like direct rivals if you flatten the stack. They are closer to different layer choices.

A2A is narrow by design. It standardizes agent discovery, task submission, task state, artifact exchange, streaming, and push notifications. That narrowness is why it can be practical [3][7]. You can adopt it without buying into a whole worldview.

MCP is narrower in a different direction. It standardizes how an agent connects to tools, resources, and prompts inside one agent boundary. That is why the clean comparison is not A2A versus MCP. It is A2A plus MCP versus the custom glue teams keep writing when they have multiple agents and multiple tool surfaces.

AGNTCY is broader. Its own homepage describes an internet-of-agents stack with discovery through OASF, cryptographically verifiable identity, SLIM messaging, observability, and support for both A2A and MCP as interoperable protocols inside that broader fabric [9]. That is a different ambition. Cisco and the other formative members are not trying to define only the RPC contract between agents. They are aiming at the surrounding substrate for identity, networking, and monitoring across organizations [9].

That is why the right comparison sounds like this:

- Use MCP when one agent needs tools or data.
- Use A2A when one agent needs another agent to own the task.
- Look at AGNTCY when you need a broader inter-org fabric with discovery, identity, messaging, and observability as first-class concerns.

The A2A partner directory underlines that these worlds are already overlapping. Cisco appears in the A2A partner list while AGNTCY's own site explicitly advertises support for both A2A and MCP [9][10]. The market is converging on layered interoperability, not on one protocol swallowing everything.

So the contrarian take is simple: A2A's biggest advantage is not that it can become the entire internet of agents. Its biggest advantage is that it does not have to. It is useful precisely because it standardizes the awkward middle layer that most teams need right now: capability discovery, task lifecycle, auth interruptions, and artifact exchange across agent boundaries [1][3][4].

That also explains why Google's 2026 platform push matters. Gemini Enterprise Agent Platform, Agent Registry, Agent Gateway, identity, and marketplace distribution give A2A a deployment story inside a governed enterprise stack, while still keeping the on-wire protocol open and vendor-neutral [11][12][13]. That is a stronger adoption wedge than trying to replace every other standard in one move.

## KnowledgeCheck

Question: When would AGNTCY be a better fit than raw A2A alone?

A. When all you need is a single remote task call between two agents
B. When you need an inter-org coordination fabric with identity, messaging, discovery, and observability
C. When you want to connect one agent to a local filesystem tool
D. When you only need a better prompt template

Answer: B

If your team keeps building multi-agent systems as if they were just chat apps with more tabs, A2A will feel unnecessary. If your real problem is delegated ownership across vendors, credentials, and long-running work, A2A is one of the few 2026 protocols that actually targets that problem head-on. The useful next step is to map where [[multi-agent-orchestration-a2a]], [[mcp-2026-roadmap-explained]], and [[Gemini Enterprise Agent Platform]] fit in your stack, then build the smallest A2A path first: publish an Agent Card, send one task, handle one `AUTH_REQUIRED`, and only then decide whether you also need a broader fabric like AGNTCY. If you want the implementation patterns behind that progression, start with [[course/multi-agent-orchestration-a2a]].

## References

[1] Announcing the Agent2Agent Protocol (A2A) — https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/ · retrieved 2026-05-13
[2] Agent2Agent protocol (A2A) is getting an upgrade — https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade · retrieved 2026-05-13
[3] Agent2Agent (A2A) Protocol Specification — https://a2a-protocol.org/latest/specification/ · retrieved 2026-05-13
[4] Release v1.0.0 · a2aproject/A2A — https://github.com/a2aproject/A2A/releases/tag/v1.0.0 · retrieved 2026-05-13
[5] Official Python SDK for the Agent2Agent (A2A) Protocol — https://github.com/a2aproject/a2a-python · retrieved 2026-05-13
[6] Interacting with the Server - A2A Protocol — https://a2a-protocol.org/latest/tutorials/python/6-interact-with-server/ · retrieved 2026-05-13
[7] Streaming & Asynchronous Operations - A2A Protocol — https://a2a-protocol.org/latest/topics/streaming-and-async/ · retrieved 2026-05-13
[8] A2A protocol roadmap — https://a2a-protocol.org/latest/roadmap/ · retrieved 2026-05-13
[9] AGNTCY.org — https://agntcy.org/ · retrieved 2026-05-13
[10] Partners - A2A Protocol — https://a2a-protocol.org/latest/partners/ · retrieved 2026-05-13
[11] Introducing Gemini Enterprise Agent Platform — https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform · retrieved 2026-05-13
[12] The new Gemini Enterprise: one platform for agent development — https://cloud.google.com/blog/products/ai-machine-learning/the-new-gemini-enterprise-one-platform-for-agent-development · retrieved 2026-05-13
[13] Partner-built agents available in Gemini Enterprise — https://cloud.google.com/blog/products/ai-machine-learning/partner-built-agents-available-in-gemini-enterprise · retrieved 2026-05-13
