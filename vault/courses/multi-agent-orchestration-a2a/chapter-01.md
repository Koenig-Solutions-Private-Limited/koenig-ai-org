---
date: 2026-05-30
author: content-author
ticket: KOEA-6774
course: multi-agent-orchestration-a2a
chapter: 1
chapter_title: "The Multi-Agent Mandate — Why A2A?"
vendor_tag: google
content_type: article
level: Advanced
duration_min: 40
reading_time_min: 10
learning_objectives:
  - Define the Agent Silo problem and explain how it produces vendor lock-in and capability fragmentation
  - Distinguish Capability Discovery from Tool Selection and explain why the difference matters at scale
  - Identify the four core pillars of the A2A protocol — Identity, Discovery, Communication, Negotiation
  - Compare A2A to traditional API-based integration and name the Intent Gap failure mode
status: awaiting-g0
sources:
  - https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/
  - https://a2a-protocol.org/latest/specification/
  - https://a2a-protocol.org/latest/
  - https://github.com/a2aproject/A2A
  - https://agntcy.org/
  - https://docs.agntcy.org/
  - https://google.github.io/adk-docs/
  - https://lfaidata.foundation/projects/agntcy/
---

<!-- 
DURATION MATH DECISION (pre-authoring action):
  Ch1–9 durations sum = 40+45+50+45+55+50+45+55+40 = 425 min
  Ch10 capstone = 120 min
  Actual total = 545 min
  Outline frontmatter declared 480 min — INCORRECT.
  Decision: Updated outline frontmatter to 545 min (accurate total).
  Rationale: Trimming chapter durations to hit 480 would require removing ~65 min of content 
  across 9 chapters, degrading depth at an Advanced level. The 545 min number is honest; 
  learners should know the actual commitment.
-->

# Why Your Best Agents Can't Talk to Each Other — and How A2A Fixes That

> **Chapter 1 of 10 · 40 min (prose ~10 min + 20 min hands-on exercise)**

---

## The Problem No Framework Solves

You've built a production agent. It searches the web, writes code, sends emails, queries databases. It's impressive — until someone asks it to hand off a piece of work to a specialized agent running in a different team's infrastructure, built on a different model, deployed on a different cloud.

That handoff doesn't exist. You're inside an **Agent Silo**.

An Agent Silo is an agent that cannot delegate to, discover, or receive work from agents outside its own framework. Build on LangChain and your agent speaks LangChain. Your partner builds on AutoGen and their agent speaks AutoGen. Neither speaks the other. The practical fallout:

- **Vendor lock-in**: Every capability you need must live inside your chosen framework's ecosystem.
- **Capability fragmentation**: The best document-processing agent might live on a different platform than your best reasoning agent. Without interoperability, you can't compose them.
- **Duplication tax**: Teams rebuild capabilities from scratch rather than reuse specialized agents across organizational boundaries.

Google named this crisis in their April 2025 A2A announcement: enterprises deploy agents across disconnected systems, and the result is fragmented, duplicated, and ultimately brittle AI infrastructure. ([developers.googleblog.com](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)) By 2026, 150+ organizations — including Microsoft, Salesforce, ServiceNow, and SAP — have co-signed the same diagnosis by adopting the A2A standard.

This chapter makes the case for why the solution requires a *protocol*, not another framework.

---

## Capability Discovery vs. Tool Selection: Why the Difference Matters

Most architects who hit the Agent Silo problem reach for the nearest available solution: **Tool Selection**. They write a wrapper function, define it as a tool in their agent's toolset, and hard-code the downstream agent's endpoint. It works for one agent-pair. It does not scale to a network.

**Tool Selection** asks: "Which specific tool do I call?"  
**Capability Discovery** asks: "What kind of outcome do I need, and which agent can produce it?"

The distinction is architectural. Tool Selection produces a *topology* — a fixed graph of which agents call which tools at build time. Capability Discovery produces a *protocol* — a dynamic conversation in which agents find each other and agree on terms at runtime.

An analogy: a phone book entry is Tool Selection (you know the number, you dial it). DNS is Capability Discovery (you know the hostname; the network resolves it to whoever currently answers that name).

AGNTCY — the open multi-agent infrastructure project originally developed by Cisco, now hosted by the Linux Foundation alongside 65+ participating organizations ([LF AI & Data](https://lfaidata.foundation/projects/agntcy/)) — is built on this principle. Its Open Agent Schema Framework (OASF) lets any agent describe its capabilities in a machine-readable format, enabling other agents to find it by *what it can do*, not by a hard-coded endpoint. ([docs.agntcy.org](https://docs.agntcy.org/)) When an agent publishes an OASF-compliant schema, it becomes searchable across organizational boundaries. That's the Internet of Agents model.

<KnowledgeCheck
  question="What is the key architectural difference between Tool Selection and Capability Discovery?"
  answers={[
    "Tool Selection uses JSON-RPC; Capability Discovery uses REST",
    "Tool Selection hard-codes endpoints at build time; Capability Discovery finds agents by capability at runtime",
    "Capability Discovery is slower but more cryptographically secure",
    "Tool Selection only works within a single framework"
  ]}
  correct={1}
/>

---

## The Intent Gap: Why Traditional APIs Fail Agents

Traditional API integration assumes both sides agree in advance on *what to request*. Call `POST /api/summarize` with a document, receive a summary. The contract is in the path, the method, and the schema.

Replace the API consumer with an agent. The agent doesn't want to call `POST /api/summarize`. The agent wants to **achieve an outcome**: "I need the key facts from this 40-page report, ranked by relevance to Q3 procurement costs, flagging any line items over $50k."

That outcome cannot be expressed in a REST endpoint path. The gap between what an agent *intends* and what a traditional API *accepts* is the **Intent Gap**.

The Intent Gap produces failures that are difficult to debug:

1. The agent calls the nearest API that seems relevant.
2. The API returns a result that technically satisfies its contract.
3. The result doesn't advance the agent's actual goal.
4. No error is raised. The downstream workflow continues on a wrong assumption.

A2A closes this gap with **intent-first messaging**. Instead of calling an endpoint, an agent sends a `Task` — a structured object containing the desired outcome, context, and constraints. The receiving agent's `AgentCard` declares what task types it can fulfill. The sending agent queries that card *before* delegating. Mismatches are caught at negotiation time, not after silent failure. ([A2A specification v1.0.0](https://a2a-protocol.org/latest/specification/))

<Callout type="hot">
  A2A v1.0.0 shipped March 2026 and is now natively integrated into Google ADK, Cloud Run, and GKE. ([Google ADK Documentation](https://google.github.io/adk-docs/)) The Agentspace marketplace already lists 200+ A2A-compliant agents. The Intent Gap isn't a theoretical concern — organizations at Salesforce, ServiceNow, and Microsoft are paying the operational tax of traditional API integration with agents today.
</Callout>

---

## The Four Pillars of A2A

Every design decision in the A2A specification flows from four foundational pillars. Understanding these pillars tells you not just *what* A2A does, but *why* every wire-level choice was made. ([a2a-protocol.org/latest/specification](https://a2a-protocol.org/latest/specification/))

### Pillar 1: Identity

Agents declare who they are through the **AgentCard** — a JSON document published at `/.well-known/agent.json`. The card contains:

- Provider and service metadata
- Declared capabilities (streaming support, push notifications, extended card access)
- Security schemes: OAuth2, API Key, mTLS, OpenID Connect, mutual TLS
- Skills — the specific task categories the agent will accept

Identity is load-bearing, not ceremonial. An agent that cannot prove its identity cannot be trusted. An agent that cannot describe its capabilities cannot be discovered usefully. The `AgentCard` is both a passport and a service contract.

### Pillar 2: Discovery

Because every A2A-compliant agent publishes a standardized `AgentCard` at a predictable path, any client can probe an endpoint and understand its capabilities without out-of-band documentation. At the registry layer — implemented by AGNTCY's OASF or Google's Agentspace marketplace — agents become searchable by fuzzy capability query, not just by known URL.

This is the architectural shift from phone book to DNS: you don't need to know Agent B exists before you need it.

### Pillar 3: Communication

A2A communication is built on **JSON-RPC 2.0 over HTTP**, with Server-Sent Events for streaming and optional gRPC transport. ([github.com/a2aproject/A2A](https://github.com/a2aproject/A2A)) The core methods:

| Method | Purpose |
|---|---|
| `sendMessage` | Initiate a task or get a direct response |
| `sendStreamingMessage` | Real-time streaming updates during task execution |
| `getTask` | Retrieve current task state by ID |
| `cancelTask` | Request graceful cancellation |
| `subscribeToTask` | Establish an update stream for a running task |

Tasks carry a `contextId` that survives agent handoffs, enabling multi-agent workflows to maintain shared state across organizational and framework boundaries. A task's lifecycle follows a deterministic state machine: `SUBMITTED → WORKING → COMPLETED` (or `FAILED`, `CANCELED`, `INPUT_REQUIRED`, `AUTH_REQUIRED`, `REJECTED`).

Messages contain a `role` (`ROLE_USER` or `ROLE_AGENT`) and a `parts` array. Each Part is exactly one of: text, raw binary, URL, or structured JSON data. The protocol is multi-modal by design — text, files, images, and tool outputs all flow through the same envelope.

### Pillar 4: Negotiation

Before a task is delegated, the protocol negotiates two things explicitly:

- **Protocol version**: Clients send `A2A-Version: 1.0` in headers. Servers reject unsupported versions with a typed `VersionNotSupportedError`. Empty version headers default to `0.3` for backward compatibility.
- **Extensions**: Clients advertise extension URIs via `A2A-Extensions`. Servers declare supported extensions in their AgentCard.

This means an A2A network evolves without flag-day upgrades. Older agents refuse tasks that require extensions they don't support. Newer agents negotiate down gracefully. The handshake is explicit — no silent capability mismatch.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt={`You are an A2A client agent. Write a minimal JSON-RPC 2.0 sendMessage payload to delegate this task to a specialist agent: "Summarize the Q3 procurement section of the attached report and flag any line items over $50k." 

Include: jsonrpc version, method name, params with a message object containing role (ROLE_USER), a parts array with one text Part holding the task description, a contextId (use a UUID placeholder), and a messageId.`}
  expectedOutput='{"jsonrpc":"2.0","method":"sendMessage","params":{"message":{"role":"ROLE_USER","messageId":"<uuid>","contextId":"<uuid>","parts":[{"text":"Summarize the Q3 procurement section of the attached report and flag any line items over $50k."}]}}}'
/>

---

## Frameworks Are Apps; A2A Is the Network

Here is the misconception that costs teams months of re-architecture: **multi-agent does not mean AutoGen or CrewAI**.

AutoGen, CrewAI, LangGraph — these are *orchestration frameworks*. They're excellent at defining how agents within their ecosystem collaborate. They were never designed to be interoperability protocols.

The distinction:

- A **framework** defines the rules for agents that have already opted into that framework.
- A **protocol** defines how agents that know nothing about each other can still collaborate.

TCP/IP didn't replace application software. It made application software from different vendors interoperable over a common network. A2A occupies exactly the same layer for agents. A CrewAI orchestrator can dispatch tasks to a LangGraph specialist via A2A. A Paperclip agent can hire a Vertex AI agent via A2A. The frameworks run on top; A2A is the network beneath them.

This is the "Internet of Agents" thesis. AGNTCY states it directly: its goal is open infrastructure for "discovery, identity, messaging, and observability among AI agents from different vendors and frameworks." ([agntcy.org](https://agntcy.org/)) A2A handles message-passing; AGNTCY handles the network-layer infrastructure. Together they form the stack beneath every framework.

<KnowledgeCheck
  question="Which statement correctly describes the relationship between A2A and orchestration frameworks like CrewAI?"
  answers={[
    "A2A replaces orchestration frameworks for cross-framework use cases",
    "Orchestration frameworks replace A2A when operating at enterprise scale",
    "A2A is the protocol layer that lets agents from different frameworks interoperate; frameworks orchestrate agents within their own ecosystem",
    "A2A and CrewAI solve the same problem at different abstraction levels and are mutually exclusive"
  ]}
  correct={2}
/>

---

## Hands-On Exercise: Decompose a Monolith

**Time estimate:** 20 minutes

You have a single "Swiss Army Knife" agent with these 10 tools:

```python
tools = [
    search_web,       # Tavily / Perplexity API
    read_document,    # PDF + HTML parser
    write_report,     # Markdown + PDF formatter
    send_email,       # SMTP sender
    query_database,   # SQL executor
    run_python,       # Code interpreter
    scrape_website,   # Playwright
    transcribe_audio, # Whisper API
    generate_image,   # Image generation API
    translate_text,   # DeepL API
]
```

**Step 1 — Decompose.** Group these 10 tools into exactly 3 Specialist Agent personas. Name each persona, assign its tools, and justify each grouping in one sentence.

**Step 2 — Write the SLAs.** For each agent-pair that would interact, write a 3-line Service Level Agreement:

```
Agent [A] → Agent [B]
Task type: <what A asks B to produce>
Output contract: <what B commits to returning, including format>
Failure protocol: <what A does if B fails or exceeds timeout>
```

**Step 3 — Close the Intent Gap.** Pick one inter-agent handoff from your SLAs. Write the JSON-RPC 2.0 `sendMessage` payload that would trigger it under A2A — including the task description as a text Part and a placeholder `contextId`.

This decomposition is the mental model you'll use throughout the course. When you can describe the contracts between specialists, you're ready to implement those contracts at the wire level in Chapter 2.

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| Agent Silo | An agent that cannot delegate to or receive work from agents outside its own framework |
| Intent Gap | The mismatch between an agent's desired outcome and what a traditional API endpoint accepts |
| Tool Selection | Hard-coding which endpoint to call for a specific function — fixed topology |
| Capability Discovery | Finding agents by *what they can do* at runtime via a registry or protocol |
| A2A | Open protocol (Linux Foundation) implementing Identity, Discovery, Communication, and Negotiation |
| AgentCard | JSON manifest at `/.well-known/agent.json` declaring an agent's capabilities, skills, and auth schemes |
| AGNTCY | Internet of Agents infrastructure providing OASF schemas, registry, and identity for cross-vendor agents |

---

## What's Next

[[multi-agent-orchestration-a2a/chapter-02|Chapter 2: A2A Protocol Architecture — The Message Flow]] puts the four pillars to work at the wire level. You'll implement a raw JSON-RPC Handshake and Negotiation sequence, trace every state transition in the A2A task lifecycle, and understand why JSON-RPC 2.0 outperforms REST for intent-based agent communication.

The theory ends here. In Chapter 2, you write the wire.

---

*Sources: [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [Google A2A Announcement, Apr 2025](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [AGNTCY Internet of Agents](https://agntcy.org/) · [AGNTCY Documentation](https://docs.agntcy.org/) · [Google ADK Documentation](https://google.github.io/adk-docs/) · [LF AI & Data — AGNTCY Project](https://lfaidata.foundation/projects/agntcy/)*
