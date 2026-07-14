---
course_slug: multi-agent-orchestration-a2a
slug: multi-agent-orchestration-a2a
title: "Multi-Agent Orchestration with A2A Protocol: Building the Internet of Agents"
status: g3-passed
author: course-author
level: Advanced
tags: [A2A, Multi-Agent, Orchestration, Protocol, MCP, AGNTCY, Distributed Systems]
target_audience: "Senior Engineers and Architects building agentic systems who need to move beyond single-agent monoliths to interoperable, multi-vendor agent networks."
prerequisites:
  - "Experience building and deploying at least one production-grade LLM agent"
  - "Strong proficiency in Python or TypeScript"
  - "Solid understanding of distributed systems (message queues, async patterns, JSON-RPC)"
  - "Familiarity with the Model Context Protocol (MCP) is a plus but not required"
learning_outcomes:
  - "Architect and deploy an interoperable multi-agent system using the A2A protocol"
  - "Integrate MCP servers for cross-agent tool sharing and resource injection"
  - "Implement global agent discovery and naming using AGNTCY (Internet of Agents) patterns"
  - "Design resilient, asynchronous agent workflows that handle state consistency across distributed networks"
  - "Secure agent-to-agent communication using DPoP-bound tokens and trust-based authorization"
total_duration_min: 480
chapter_count: 10
capstone_project_min: 120
draft_type: course_bundle
bundle_assembler: course-architect
source_chapters:
  - vault/courses/multi-agent-orchestration-a2a/chapter-01.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-02.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-03.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-04.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-05.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-06.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-07.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-08.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-09.md
  - vault/courses/multi-agent-orchestration-a2a/chapter-10.md
---

# Multi-Agent Orchestration with A2A Protocol

## Why this course

Most agent tutorials teach you how to build a single "Swiss Army Knife" agent. They give it 50 tools, a long system prompt, and hope for the best. This approach is the "Monolithic Agent" anti-pattern—it's brittle, expensive, and impossible to scale.

The future isn't one giant agent; it's a network of specialized agents that collaborate. But for agents to collaborate, they need a common language. That language is the **A2A (Agent-to-Agent) Protocol**.

This course is for the builders who realize that vendor-locked agent silos are a dead end. We move beyond the "hello world" of agentic chains and dive into the architecture of the **Internet of Agents**. We'll cover everything from the core protocol wire-format to global discovery with **AGNTCY**, tool-sharing with **MCP**, and the production realities of distributed tracing and secure message passing.

By the end, you won't just be chaining LLM calls—you'll be orchestrating a sovereign network of autonomous agents.

## Final Chapter Bundle

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-01.md -->

```yaml
date: 2026-05-30
author: content-author
ticket: KOEA-8038
course: multi-agent-orchestration-a2a
chapter: 1
chapter_title: "Why Your Best Agents Can't Talk to Each Other — and How A2A Fixes That"
slug: multi-agent-orchestration-a2a-chapter-01
description: "A2A (Agent-to-Agent) solves the Agent Silo problem — the architectural barrier preventing agents across vendors and frameworks from delegating work to each other. This chapter defines the Intent Gap failure mode, contrasts Capability Discovery with Tool Selection, and introduces the four protocol pillars: Identity, Discovery, Communication, and Negotiation."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 40
reading_time_min: 10
last_updated: 2026-06-12
chapter_primary_query: "how do AI agents communicate across different frameworks using the A2A protocol"
learning_objectives:
  - Define the Agent Silo problem and explain how it produces vendor lock-in and capability fragmentation
  - Distinguish Capability Discovery from Tool Selection and explain why the difference matters at scale
  - Identify the four core pillars of the A2A protocol — Identity, Discovery, Communication, Negotiation
  - Compare A2A to traditional API-based integration and name the Intent Gap failure mode
positions:
  - mcp-as-interoperability-moat
tags: [A2A, multi-agent, orchestration, protocol, agent-interoperability]
status: g0-passed
sources:
  - https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/ # retrieved 2026-06-12
  - https://a2a-protocol.org/latest/specification/ # retrieved 2026-06-12
  - https://a2a-protocol.org/latest/ # retrieved 2026-06-12
  - https://github.com/a2aproject/A2A # retrieved 2026-06-12
  - https://agntcy.org/ # retrieved 2026-06-12
  - https://docs.agntcy.org/ # retrieved 2026-06-12
  - https://google.github.io/adk-docs/ # retrieved 2026-06-12
  - https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year # retrieved 2026-06-12
  - https://cloud.google.com/blog/topics/partners/google-cloud-ai-agent-marketplace # retrieved 2026-06-12
faq:
  - question: "What is the Intent Gap?"
    answer: "The Intent Gap is the mismatch between what an AI agent intends to achieve and what a traditional REST API endpoint accepts. A REST call assumes both sides pre-agree on the contract — path, method, schema. An agent wants to express an outcome ('summarise this report and flag items over $50k'), but that outcome cannot be expressed in an endpoint path. A2A closes this gap with intent-first messaging: agents send a structured Task object containing the desired outcome, constraints, and context, and the receiving agent's AgentCard declares which task types it can fulfil before delegation occurs. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "How does A2A differ from MCP?"
    answer: "MCP (Model Context Protocol) connects an individual AI agent to tools — databases, APIs, file systems, and external data sources. A2A (Agent-to-Agent protocol) connects agents to other agents for task delegation across vendor and framework boundaries. In Google's reference architecture both protocols operate simultaneously: an orchestrator delegates work via A2A while each sub-agent uses MCP to access its own tools. MCP is the agent-to-tool layer; A2A is the agent-to-agent layer. They are explicitly designed to be complementary, not competing. ([A2A launch announcement, April 2025](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/))"
  - question: "What is an AgentCard?"
    answer: "An AgentCard is a JSON document published at the well-known path `/.well-known/agent.json` by every A2A-compliant agent. It serves as both a passport and a service contract: it declares the agent's provider metadata, supported capabilities (streaming, push notifications, extended card access), accepted security schemes (OAuth2, API Key, mTLS, OpenID Connect), and specific skill categories — the task types the agent will accept. Any A2A client can probe this endpoint before delegating a task, so capability mismatches are caught at negotiation time rather than after a silent downstream failure. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
```

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

Google named this crisis in their April 2025 A2A announcement: enterprises deploy agents across disconnected systems, and the result is fragmented, duplicated, and ultimately brittle AI infrastructure. ([developers.googleblog.com](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)) By April 2026, that founding coalition had grown to 150+ organizations — including AWS, Cisco, IBM, Microsoft, Salesforce, SAP, and ServiceNow — co-signing the same diagnosis by adopting the A2A standard. ([Linux Foundation, April 2026](https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year))

This chapter makes the case for why the solution requires a *protocol*, not another framework.

---

## Capability Discovery vs. Tool Selection: Why the Difference Matters

Most architects who hit the Agent Silo problem reach for the nearest available solution: **Tool Selection**. They write a wrapper function, define it as a tool in their agent's toolset, and hard-code the downstream agent's endpoint. It works for one agent-pair. It does not scale to a network.

**Tool Selection** asks: "Which specific tool do I call?"  
**Capability Discovery** asks: "What kind of outcome do I need, and which agent can produce it?"

The distinction is architectural. Tool Selection produces a *topology* — a fixed graph of which agents call which tools at build time. Capability Discovery produces a *protocol* — a dynamic conversation in which agents find each other and agree on terms at runtime.

An analogy: a phone book entry is Tool Selection (you know the number, you dial it). DNS is Capability Discovery (you know the hostname; the network resolves it to whoever currently answers that name).

AGNTCY — the open multi-agent infrastructure project created by Cisco's Outshift team, with Cisco, Dell Technologies, Google Cloud, Oracle, and Red Hat as formative members alongside 75+ contributing organizations ([agntcy.org](https://agntcy.org/)) — is built on this principle. Its Open Agent Schema Framework (OASF) lets any agent describe its capabilities in a machine-readable format, enabling other agents to find it by *what it can do*, not by a hard-coded endpoint. ([docs.agntcy.org](https://docs.agntcy.org/)) When an agent publishes an OASF-compliant schema, it becomes searchable across organizational boundaries. That's the Internet of Agents model.

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
  A2A v1.0.0 shipped March 2026 and is now natively integrated into Google ADK, Cloud Run, and GKE. ([Google ADK Documentation](https://google.github.io/adk-docs/)) The Google Cloud AI Agent Marketplace lists partner-built A2A agents validated for Gemini Enterprise integration from ISVs, GSIs, and technology providers. ([Google Cloud Blog](https://cloud.google.com/blog/topics/partners/google-cloud-ai-agent-marketplace)) The Intent Gap isn't a theoretical concern — organizations at Salesforce, ServiceNow, and Microsoft are paying the operational tax of traditional API integration with agents today.
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
  prompt="You are an A2A client agent. Write a minimal JSON-RPC 2.0 sendMessage payload to delegate this task to a specialist agent: \"Summarize the Q3 procurement section of the attached report and flag any line items over $50k.\" \n\nInclude: jsonrpc version, method name, params with a message object containing role (ROLE_USER), a parts array with one text Part holding the task description, a contextId (use a UUID placeholder), and a messageId."
  expectedOutput='{"jsonrpc":"2.0","method":"sendMessage","params":{"message":{"role":"ROLE_USER","messageId":"<uuid>","contextId":"<uuid>","parts":[{"text":"Summarize the Q3 procurement section of the attached report and flag any line items over $50k."}]}}}'
/>

---

## Frameworks Are Apps; A2A Is the Network

Here is the misconception that costs teams months of re-architecture: **multi-agent does not mean AutoGen or CrewAI**.

AutoGen, CrewAI, LangGraph — these are *orchestration frameworks*. They're excellent at defining how agents within their ecosystem collaborate. They were never designed to be interoperability protocols.

The distinction:

- A **framework** defines the rules for agents that have already opted into that framework.
- A **protocol** defines how agents that know nothing about each other can still collaborate.

TCP/IP didn't replace application software. It made application software from different vendors interoperable over a common network. A2A occupies exactly the same layer for agents. A CrewAI orchestrator can dispatch tasks to a LangGraph specialist via A2A. A Paperclip agent can hire a Vertex AI agent via A2A. The frameworks run on top; A2A is the network beneath them. For the tool-connection layer that runs *inside* each of those agents, see [[mcp-from-first-principles-to-production/01-why-mcp-exists|MCP: Why It Exists — the N×M problem A2A's complement solves]].

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

[[multi-agent-orchestration-a2a/chapter-03|Chapter 3: The Internet of Agents — AGNTCY & Global Discovery]] goes deeper on cross-vendor registry infrastructure, global Agent Identity design, and the fallback patterns that keep discovery working when no central registry is available.

The theory ends here. In Chapter 2, you write the wire.

---

*Sources: [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [Google A2A Announcement, Apr 2025](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [AGNTCY Internet of Agents](https://agntcy.org/) · [AGNTCY Documentation](https://docs.agntcy.org/) · [Google ADK Documentation](https://google.github.io/adk-docs/)*

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-02.md -->

```yaml
course: multi-agent-orchestration-a2a
chapter_num: 2
chapter_title: "A2A Protocol Architecture — The Message Flow (2026)"
slug: multi-agent-orchestration-a2a-chapter-02
description: "Trace every field in an A2A message envelope, implement the four-step JSON-RPC 2.0 handshake from scratch, and design a Capability Schema that makes your agent discoverable by intent rather than by URL."
author: course-author
ticket: KOEA-6950
date: 2026-05-31
status: g0-passed
level: Advanced
duration_min: 45
reading_time_min: 12
prerequisites_chapters:
  - 1
learning_objectives:
  - Map the A2A wire protocol — Headers, Context, Payload, and Metadata — and explain the role of each field in a live agent exchange
  - Implement the Handshake and Negotiation phase of an A2A agent interaction from scratch using raw JSON-RPC 2.0
  - Explain why JSON-RPC 2.0 outperforms REST for intent-based agent flows and name the three failure modes REST introduces
  - Design a custom Capability Schema for a domain-specific agent using the A2A skills and parts model
positions:
  - mcp-as-interoperability-moat
tags: [A2A, JSON-RPC, multi-agent, protocol, message-flow, agent-card]
chapter_primary_query: "A2A protocol message flow wire format JSON-RPC 2.0"
first_60_words_answer: "A2A messages are JSON-RPC 2.0 envelopes sent over HTTPS. Every message carries a role (ROLE_USER or ROLE_AGENT), a contextId that persists across the full agent session, a parts array holding the actual payload (text, file, data, or image), and optional metadata. The agent-to-agent handshake begins with an AgentCard probe at /.well-known/agent.json, followed by a sendMessage or sendStreamingMessage call."
faq:
  - question: "What wire format does the A2A protocol use?"
    answer: "A2A uses JSON-RPC 2.0 over HTTPS as its transport. Each RPC call is a JSON object with jsonrpc: '2.0', a method name (e.g. sendMessage, getTask, cancelTask), a params object, and an id. Server-Sent Events (SSE) extend the same HTTP connection for streaming responses. An optional gRPC transport is defined in the spec for high-throughput scenarios. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "What is the A2A Handshake and Negotiation phase?"
    answer: "Before delegating a task, a client agent fetches the server agent's AgentCard at /.well-known/agent.json to read its declared capabilities, skills, and auth requirements; validates protocol version compatibility using the A2A-Version header; checks extension support via A2A-Extensions; and authenticates using the declared scheme. Only after this four-step sequence does the client send a sendMessage payload. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "What is a contextId in A2A and why does it matter?"
    answer: "A contextId is a UUID that identifies a logical conversation or workflow session across multiple agent turns and agent boundaries. All messages belonging to the same task chain share the same contextId, letting any agent in the chain resume a failed workflow from the last checkpoint without re-running prior agents. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "Why does A2A use JSON-RPC instead of REST?"
    answer: "REST assumes the client knows which resource to manipulate at design time. Agents operate at runtime with intent — 'produce this outcome.' JSON-RPC lets the caller express a method name that maps to an outcome rather than a resource path, eliminating the Intent Gap: REST routes must be designed in advance; JSON-RPC methods accept arbitrarily rich intent descriptions in their params. ([JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification); [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "What is a Capability Schema (Skill) in A2A?"
    answer: "A Skill is a JSON object inside the AgentCard that declares one task type the agent can fulfill. Each skill includes an id, name, description, optional inputModes and outputModes (text, image, audio), and tags for discovery. A narrow specialist agent publishes one precise skill; a generalist publishes several. The schema is what a discovery registry indexes to match capability queries. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
inline_assets:
  - type: diagram
    path: ./img/ch02-message-envelope.png
    alt: "A2A message envelope anatomy: outer JSON-RPC 2.0 wrapper with jsonrpc, method, and id fields; params object containing a Message with role (ROLE_USER or ROLE_AGENT), messageId (UUID), contextId (UUID shared across session), and parts array; Parts array showing four part types: TextPart with a text string, FilePart with file.bytes or file.uri, DataPart with a data JSON object, and ImagePart with image data. HTTP headers A2A-Version and A2A-Extensions shown alongside."
  - type: diagram
    path: ./img/ch02-handshake-sequence.png
    alt: "A2A Handshake sequence diagram: Client Agent sends GET request to /.well-known/agent.json (AgentCard fetch), receives AgentCard JSON response; Client validates A2A-Version header compatibility and checks A2A-Extensions; Client authenticates per AgentCard security scheme (OAuth2 shown); Client sends sendMessage JSON-RPC POST, Server responds with SendMessageResponse containing Task in SUBMITTED state; Server internal processing transitions Task to WORKING then COMPLETED; Client calls getTask to poll status."
last_updated: 2026-06-15
sources:
  - https://a2a-protocol.org/latest/specification/ # retrieved 2026-06-15
  - https://a2a-protocol.org/latest/topics/agent-discovery/ # retrieved 2026-06-15
  - https://github.com/a2aproject/A2A # retrieved 2026-06-15
  - https://www.jsonrpc.org/specification # retrieved 2026-06-15
  - https://a2a-protocol.org/latest/topics/streaming-and-async/ # retrieved 2026-06-15
  - https://a2a-protocol.org/latest/topics/push-notifications/ # retrieved 2026-06-15
  - https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/ # retrieved 2026-06-15
```

# A2A Protocol Architecture — The Message Flow (2026)

> **Chapter 2 of 10 · 45 min (prose ~12 min + 25 min hands-on exercise)**

---

A2A messages are [[glossary/json-rpc|JSON-RPC 2.0]] envelopes sent over HTTPS. Every message carries a `role` (`ROLE_USER` or `ROLE_AGENT`), a `contextId` that persists across the full agent session, a `parts` array holding the actual payload (text, file, data, or image), and optional metadata. The agent-to-agent handshake begins with an [[glossary/agent-card|AgentCard]] probe at `/.well-known/agent.json`, followed by a `sendMessage` or `sendStreamingMessage` call.

[[multi-agent-orchestration-a2a/chapter-01|Chapter 1]] made the case for *why* the A2A protocol exists. This chapter is where theory hits wire. You'll trace every field in an A2A message, implement the four-step handshake sequence from a blank screen, and design a Capability Schema that makes your agent discoverable by intent rather than by URL.

---

## Why REST Is the Wrong Abstraction for Agents

Before you write a single byte of A2A, you need to understand what the designers chose to *reject*. The answer is REST — or more precisely, the REST model of resources, paths, and verbs.

REST was designed for a world of documents and state. A `GET /reports/q3-summary` fetches a document. A `POST /invoices` creates a resource. The path encodes the *what*; the verb encodes the *operation*. This model is excellent for systems where the client knows, at design time, which object it wants and what to do with it.

Agents don't operate in that world.

An agent arrives at runtime with an *intent*: "I need the key insights from this earnings call, weighted by their impact on our Q3 headcount plan, formatted as a JSON array." That intent cannot be expressed as a REST path. The closest approximation — `POST /analysis` — loses the weighting, the Q3 framing, the output format specification, and the reasoning that connects the earnings call to headcount planning. You've dropped from a goal to a function call, and the gap between them is exactly what causes downstream agents to silently produce wrong results.

This is the **Intent Gap** from Chapter 1, and REST's resource model is its root cause. REST imposes three failure modes on agent-to-agent communication:

| REST Failure Mode | What Goes Wrong in Agent Systems |
|---|---|
| **Route-first design** | API paths must be defined before you know what agents will ask for. This is impossible when agent behavior is emergent. |
| **Verb-object mismatch** | REST verbs (GET, POST, PUT, DELETE) map to CRUD operations, not to outcomes. An agent's request is never "create this resource"; it's "achieve this outcome." |
| **Schema rigidity** | A `POST /analysis` endpoint has a fixed schema. An agent's intent is open-ended and contextually specific. Forcing it into a fixed schema silently truncates what the agent is asking. |

JSON-RPC 2.0 avoids all three by inverting the design question. Instead of "which resource path should this operation address?", JSON-RPC asks "which method should handle this request, and what params does it need?" Methods are flexible; params are arbitrarily structured JSON. The agent encodes its full intent in the params, and the receiving agent decides whether it can fulfill it.

<Callout type="hot">
  The A2A specification (v1.0.0, published March 2026) is explicit about this choice. JSON-RPC was selected because it "provides a standardized, transport-agnostic RPC mechanism" — the `method` field maps naturally to agent capabilities, and the `params` field can carry unbounded, semantically rich task descriptions. REST's path-based routing does not generalize to intent-based agent communication.
</Callout>

---

## JSON-RPC 2.0: The Right Abstraction for Intent

If you've never read the [JSON-RPC 2.0 specification](https://www.jsonrpc.org/specification), the important parts are brief.

Every request is a JSON object:

```json
{
  "jsonrpc": "2.0",
  "method": "sendMessage",
  "params": { ... },
  "id": "req-001"
}
```

Every response is either a result object:

```json
{
  "jsonrpc": "2.0",
  "result": { ... },
  "id": "req-001"
}
```

Or an error object:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32001,
    "message": "Task not found",
    "data": { "taskId": "task-abc" }
  },
  "id": "req-001"
}
```

And that's the entire protocol. No headers encoding semantics, no path routing, no verb interpretation. The `method` string is the entire routing mechanism; the `params` object is the entire payload specification. This simplicity is its power: the A2A spec defines six core operations that cover every pattern agents need — synchronous, streaming, push-notification, polling, cancellation (the full spec defines ≥11 methods, including `listTasks`, `subscribeToTask`, and additional push-management variants).

| A2A Method | Purpose | Response Mode |
|---|---|---|
| `sendMessage` | Initiate a task or send a follow-up turn | Synchronous (Task or Message) |
| `sendStreamingMessage` | Same as `sendMessage` but with SSE streaming | Server-Sent Events |
| `getTask` | Retrieve current task state by ID | Synchronous |
| `cancelTask` | Request graceful cancellation | Synchronous |
| `setTaskPushNotificationConfig` | Register a webhook for task state updates | Synchronous |
| `getTaskPushNotificationConfig` | Retrieve the registered webhook config | Synchronous |

Every agent-to-agent interaction in a multi-agent system is a composition of these core operations. The wire stays simple even when the system grows complex.

---

## The Message Envelope: Anatomy of an A2A Call

Understanding the A2A message envelope is the most important prerequisite for everything that follows. Let's dissect a complete `sendMessage` call layer by layer.

### Layer 1: HTTP Transport and Headers

An A2A request is a standard HTTPS POST to the agent's endpoint (declared in its AgentCard). Two custom headers carry protocol-level metadata:

```
POST https://sentiment-agent.internal/a2a HTTP/1.1
Content-Type: application/json
Authorization: Bearer <dpop-bound-token>
A2A-Version: 1.0
A2A-Extensions: https://a2a-protocol.org/extensions/file-transfer-v1
```

- **`A2A-Version`**: The protocol version the client supports. The server returns a `VersionNotSupportedError` if incompatible. An empty header defaults to `0.3` for backward compatibility with pre-1.0 agents.
- **`A2A-Extensions`**: Space-separated URIs of non-standard extensions the client wants to use. The server checks these against the extensions declared in its AgentCard and may reject the request if a required extension is unsupported.

These two headers are the entire wire-level negotiation surface. Everything else is in the JSON body.

### Layer 2: The JSON-RPC Wrapper

```json
{
  "jsonrpc": "2.0",
  "method": "sendMessage",
  "params": {
    "message": { ... },
    "configuration": {
      "acceptedOutputModes": ["text"],
      "returnImmediately": true
    }
  },
  "id": "req-7f8a3c"
}
```

The `configuration` object is optional but powerful. `acceptedOutputModes` tells the server what Part types the client can consume (text, image, audio, file, data). `returnImmediately` controls whether the call should return immediately with a `SUBMITTED` Task (`true` = fire-and-forget) or wait until the task reaches a terminal state (`false` = blocking) — this is the `Request/Response vs. Fire-and-Forget` control knob.

### Layer 3: The Message Object

```json
{
  "role": "ROLE_USER",
  "messageId": "msg-a1b2c3d4",
  "contextId": "ctx-9f1e7a2b-4c5d-6e7f-8g9h-i0j1k2l3m4n5",
  "taskId": null,
  "parts": [ ... ],
  "metadata": {
    "priority": "high",
    "deadline_utc": "2026-06-01T09:00:00Z"
  }
}
```

**`role`** — either `ROLE_USER` (the message originates from outside the agent, i.e. from the orchestrator or the human user) or `ROLE_AGENT` (the message originates from the agent itself, i.e. a turn in the agent's reasoning or output). This distinction matters for conversation history reconstruction and for security auditing.

**`messageId`** — a UUID unique to this specific message. Used for idempotency: if the same `messageId` arrives twice (due to a retry), the server SHOULD return the same result without re-processing.

**`contextId`** — the session identifier. This is the most architecturally important field in the entire protocol. It identifies the logical workflow or conversation across all agents and all turns. If Agent A delegates to Agent B, and Agent B re-delegates to Agent C, all three agents receive the same `contextId`. If Agent C crashes and Agent A needs to resume the workflow, it can do so by sending a new `sendMessage` with the same `contextId` — Agent B picks up from its last checkpoint rather than starting over. We cover `contextId` continuity patterns in depth in Chapter 7.

**`taskId`** — null for the first message in a new task; populated with the Task UUID on subsequent turns within the same task lifecycle.

**`metadata`** — a free-form JSON object for domain-specific data that doesn't belong in the core protocol. Use it for priority signals, deadlines, routing hints, or any application-layer convention your system uses. Servers SHOULD ignore metadata keys they don't understand.

### Layer 4: The Parts Array

The `parts` array is where the actual payload lives. Each Part is exactly one of four types — the protocol is deliberately multi-modal by design:

```json
"parts": [
  {
    "kind": "text",
    "text": "Analyze the sentiment of the following earnings call transcript and return a JSON array of findings, each with a sentiment score between -1.0 and 1.0 and a cited quote."
  },
  {
    "kind": "file",
    "file": {
      "name": "q3-earnings-call.txt",
      "mimeType": "text/plain",
      "bytes": "<base64-encoded-content>"
    }
  }
]
```

| Part Type | `kind` value | Use case |
|---|---|---|
| TextPart | `"text"` | Natural-language task descriptions, instructions, follow-up questions |
| FilePart | `"file"` | Documents, PDFs, audio clips — as base64 bytes or a URI |
| DataPart | `"data"` | Structured JSON data: tool call results, database records, configuration |
| ImagePart | `"image"` | Screenshots, charts, visual context — as base64 bytes or URI |

You can mix Part types freely in a single message. An orchestrator can send a text instruction + a DataPart with an existing partial result + a FilePart with a reference document, all in one `sendMessage`. The receiving agent processes all three Parts as the context for its task.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You are an A2A client agent building a sendMessage payload to delegate a sentiment analysis task to a specialist agent.\n\nWrite the complete, valid JSON for a sendMessage JSON-RPC 2.0 call with:\n- jsonrpc: \"2.0\"\n- method: \"sendMessage\"\n- id: \"req-001\"\n- params.message.role: \"ROLE_USER\"\n- params.message.messageId: a placeholder UUID\n- params.message.contextId: a different placeholder UUID\n- params.message.parts: one TextPart with the instruction \"Analyze the sentiment of the attached earnings call transcript. Return a JSON array where each item has: quote (string), sentiment_score (float -1.0 to 1.0), and category (enum: positive, negative, neutral).\" and one FilePart where file.name is \"q3-2026-earnings.txt\", file.mimeType is \"text/plain\", and file.bytes is the string \"BASE64_ENCODED_TRANSCRIPT\"\n- params.configuration.acceptedOutputModes: [\"text\", \"data\"]\n- params.configuration.returnImmediately: true\n\nFormat the JSON cleanly with proper indentation."
  expectedOutput="{\n  \"jsonrpc\": \"2.0\",\n  \"method\": \"sendMessage\",\n  \"id\": \"req-001\",\n  \"params\": {\n    \"message\": {\n      \"role\": \"ROLE_USER\",\n      \"messageId\": \"msg-11111111-2222-3333-4444-555555555555\",\n      \"contextId\": \"ctx-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\",\n      \"parts\": [\n        {\n          \"kind\": \"text\",\n          \"text\": \"Analyze the sentiment of the attached earnings call transcript. Return a JSON array where each item has: quote (string), sentiment_score (float -1.0 to 1.0), and category (enum: positive, negative, neutral).\"\n        },\n        {\n          \"kind\": \"file\",\n          \"file\": {\n            \"name\": \"q3-2026-earnings.txt\",\n            \"mimeType\": \"text/plain\",\n            \"bytes\": \"BASE64_ENCODED_TRANSCRIPT\"\n          }\n        }\n      ]\n    },\n    \"configuration\": {\n      \"acceptedOutputModes\": [\"text\", \"data\"],\n      \"returnImmediately\": true\n    }\n  }\n}"
/>

---

## The Handshake and Negotiation Phase

"Negotiation" in A2A isn't a handwave — it's a specific four-step sequence that happens before any `sendMessage` call. If you skip any step, you'll either fail loudly (good) or succeed with a capability mismatch that surfaces as a wrong result three agent hops later (expensive).

### Step 1: AgentCard Fetch

The client fetches the server agent's AgentCard — a JSON document at `/.well-known/agent.json`:

```http
GET /.well-known/agent.json HTTP/1.1
Host: sentiment-agent.internal
```

The AgentCard response:

```json
{
  "name": "Sentiment Analyst",
  "description": "Analyzes earnings call transcripts and financial news for sentiment.",
  "url": "https://sentiment-agent.internal/a2a",
  "version": "1.2.0",
  "protocolVersion": "1.0",
  "capabilities": {
    "streaming": true,
    "pushNotifications": true,
    "extensions": [
      "https://a2a-protocol.org/extensions/file-transfer-v1"
    ]
  },
  "skills": [
    {
      "id": "earnings-sentiment",
      "name": "Earnings Call Sentiment",
      "description": "Analyzes earnings call transcripts and returns per-statement sentiment scores with supporting quotes.",
      "inputModes": ["text", "file"],
      "outputModes": ["text", "data"],
      "tags": ["finance", "sentiment", "NLP", "earnings"]
    }
  ],
  "defaultInputModes": ["text"],
  "defaultOutputModes": ["text"],
  "securitySchemes": {
    "oauth2": {
      "type": "oauth2",
      "flows": {
        "clientCredentials": {
          "tokenUrl": "https://auth.internal/token",
          "scopes": {
            "a2a:tasks:write": "Submit tasks to this agent"
          }
        }
      }
    }
  },
  "security": [{"oauth2": ["a2a:tasks:write"]}]
}
```

This is the entire capability contract between the two agents. The client reads it before sending a single task message.

### Step 2: Version Validation

The client checks `protocolVersion` in the AgentCard against its own supported versions. If the server declares `"protocolVersion": "1.0"` and the client only supports `"0.3"`, the client MUST NOT proceed — a version mismatch means the server may not understand the client's message format.

In the HTTP request, the client declares its own version:

```
A2A-Version: 1.0
```

The server validates this on receipt and returns a `VersionNotSupportedError` if the version is incompatible.

### Step 3: Extension Negotiation

If the client wants to use a non-standard extension (e.g., the file-transfer extension to send large files without base64-encoding them inline), it checks the `capabilities.extensions` array in the AgentCard. If the extension URI appears there, the server supports it. The client then declares intent in the HTTP header:

```
A2A-Extensions: https://a2a-protocol.org/extensions/file-transfer-v1
```

If the extension is *required* for the task and the server doesn't support it, the client MUST NOT proceed and SHOULD surface a capability mismatch error to the operator.

### Step 4: Authentication

The AgentCard declares `securitySchemes` and `security`. In the example above, the server requires an OAuth2 client-credentials token scoped to `a2a:tasks:write`. The client requests a token from `tokenUrl`, then includes it in every subsequent request:

```
Authorization: Bearer <token>
```

In Chapter 8 we cover DPoP-bound tokens, which add a proof-of-possession layer that prevents token theft. For now, bearer tokens are the common baseline.

Only after all four steps succeed does the client send `sendMessage`.

<KnowledgeCheck
  question="What is the correct order of the four A2A Handshake steps before sending a task?"
  answers={[
    "Authenticate → Fetch AgentCard → Validate Version → Negotiate Extensions",
    "Fetch AgentCard → Validate Version → Negotiate Extensions → Authenticate",
    "Validate Version → Fetch AgentCard → Authenticate → Negotiate Extensions",
    "Negotiate Extensions → Authenticate → Fetch AgentCard → Validate Version"
  ]}
  correct={1}
/>

<Callout type="warning">
  **Do not cache AgentCards indefinitely.** An agent's skills, supported extensions, and auth requirements can change on deployment. Cache AgentCards for a maximum of 5 minutes in production, or implement a webhook-based invalidation mechanism. A stale AgentCard is one of the most common causes of capability mismatch failures in A2A networks.
</Callout>

---

## Capability Schemas: Designing Agent Skills

The `skills` array in the AgentCard is the Capability Schema for your agent. It's what a discovery registry indexes, what an orchestrator inspects before delegation, and what determines whether a task negotiation succeeds or produces a `TaskRejectedError`.

A Skill object has these fields:

```json
{
  "id": "string",         // unique identifier within this agent
  "name": "string",       // short human-readable name
  "description": "string", // the semantic capability — what the agent produces
  "inputModes": ["text", "file", "data", "image"],   // accepted Part types
  "outputModes": ["text", "file", "data", "image"],  // produced Part types
  "tags": ["string"]      // discovery tags for registry semantic search
}
```

The `description` field is the highest-leverage field for capability matching. Write it like a job description, not a function signature. The difference:

❌ **Function-signature description** (bad):
```json
"description": "Accepts text and file inputs; returns data output."
```

✅ **Job-description description** (good):
```json
"description": "Analyzes earnings call transcripts and financial news articles. Returns per-statement sentiment scores (float -1.0 to 1.0) with supporting quotes and category labels. Suitable for Q&A filings, analyst calls, and investor day transcripts. Does not process audio; text transcripts only."
```

The good version tells a discovery registry *exactly* what the agent does, what its inputs look like, and where its limits are. "Does not process audio" is as important as "analyzes earnings calls" — it prevents misrouting by orchestrators.

### Designing a Skill for a Domain-Specific Agent

Let's design the capability schema for a "Procurement Risk Analyst" agent that:
- Reads contract PDFs and purchase order summaries
- Identifies risk factors: price spikes, single-source dependencies, regulatory exposure
- Returns a structured JSON risk report with severity scores

```json
{
  "name": "Procurement Risk Analyst",
  "description": "Identifies supply chain and regulatory risks in procurement contracts and purchase orders.",
  "url": "https://procurement-risk.internal/a2a",
  "version": "2.0.1",
  "protocolVersion": "1.0",
  "capabilities": {
    "streaming": false,
    "pushNotifications": true
  },
  "skills": [
    {
      "id": "contract-risk-analysis",
      "name": "Contract Risk Analysis",
      "description": "Analyzes procurement contracts (PDF or text) for price spike risk, single-source dependencies, and regulatory exposure (GDPR, ITAR, EAR). Returns a structured JSON risk report with per-clause severity scores (critical/high/medium/low) and remediation suggestions. Optimal for contracts under 50 pages.",
      "inputModes": ["text", "file"],
      "outputModes": ["data"],
      "tags": ["procurement", "risk", "contract", "supply-chain", "compliance", "GDPR", "ITAR"]
    },
    {
      "id": "po-anomaly-detection",
      "name": "Purchase Order Anomaly Detection",
      "description": "Detects statistical anomalies in purchase order data — price deviations beyond 2σ from historical baseline, unusual vendor concentrations, and split-order patterns indicative of threshold avoidance. Requires structured JSON purchase order data. Returns anomaly flags with confidence scores.",
      "inputModes": ["data"],
      "outputModes": ["data", "text"],
      "tags": ["procurement", "anomaly", "purchase-order", "audit", "fraud-detection"]
    }
  ],
  "defaultInputModes": ["text", "file"],
  "defaultOutputModes": ["data"],
  "securitySchemes": {
    "apiKey": {
      "type": "apiKey",
      "in": "header",
      "name": "X-Agent-Key"
    }
  },
  "security": [{"apiKey": []}]
}
```

Notice several design decisions:
- **Two skills, not one**: Contract analysis and PO anomaly detection are different capabilities with different input requirements. Splitting them makes the agent more discoverable — an orchestrator looking for fraud detection finds the PO skill; one looking for compliance review finds the contract skill.
- **`inputModes` differ between skills**: The contract skill accepts `file` (for PDFs); the PO skill only accepts `data` (structured JSON). This prevents misrouting — an orchestrator sending a PDF to the PO anomaly skill gets a `TaskRejectedError` immediately rather than a silent bad result.
- **Tags are discoverable intent signals**: "GDPR", "ITAR", "fraud-detection" map to real organizational query patterns. A procurement manager's orchestrator will search for "compliance" or "audit" — those tags make this agent findable.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You are designing an A2A AgentCard for a specialist \"Financial Document Summarizer\" agent with these capabilities:\n- Summarizes annual reports, 10-K filings, and earnings releases\n- Extracts key financial metrics: revenue, EBITDA, net income, guidance\n- Outputs either a structured JSON summary or a human-readable executive brief (Markdown)\n- Accepts text and file inputs (PDF or plain text)\n- Does NOT perform sentiment analysis or make investment recommendations\n\nWrite the complete skills array for this agent's AgentCard, following the A2A specification.\nInclude exactly two skills: one for structured JSON metric extraction, one for executive brief generation.\nFor each skill, write a description that a discovery registry could use to match capability queries."
  expectedOutput="[\n  {\n    \"id\": \"financial-metrics-extraction\",\n    \"name\": \"Financial Metrics Extraction\",\n    \"description\": \"Extracts key financial metrics from annual reports, 10-K filings, and earnings releases. Returns structured JSON with revenue, EBITDA, net income, EPS, and forward guidance figures for the current and prior reporting periods. Accepts PDF or plain text input. Does not perform sentiment analysis or investment recommendations.\",\n    \"inputModes\": [\"text\", \"file\"],\n    \"outputModes\": [\"data\"],\n    \"tags\": [\"finance\", \"10-K\", \"annual-report\", \"earnings\", \"metrics\", \"extraction\"]\n  },\n  {\n    \"id\": \"executive-brief-generation\",\n    \"name\": \"Executive Brief Generation\",\n    \"description\": \"Generates a concise Markdown executive brief (500-800 words) from annual reports, 10-K filings, or earnings releases. Covers business highlights, financial performance, risks, and key takeaways. Suitable for board summaries and investor communications. Accepts PDF or plain text. Does not include investment recommendations.\",\n    \"inputModes\": [\"text\", \"file\"],\n    \"outputModes\": [\"text\"],\n    \"tags\": [\"finance\", \"summary\", \"executive-brief\", \"annual-report\", \"earnings\", \"reporting\"]\n  }\n]"
/>

---

## Session Context: Keeping State Across Handoffs

The `contextId` field is A2A's answer to the stateless-HTTP problem in multi-agent workflows. Every message in a task chain carries the same `contextId`. Every agent that participates in the chain can use that `contextId` to:

1. **Retrieve prior messages** in the session from a shared context store
2. **Resume a workflow** after a failure without replaying already-completed agent steps
3. **Correlate distributed traces** across all agents in the chain (covered in Chapter 9)

Here is how context flows in a three-agent orchestration:

```
Orchestrator                  Researcher                 Writer
─────────                     ──────────                 ──────
contextId: ctx-abc
│
├─ sendMessage(contextId=ctx-abc)  →  [Researcher receives ctx-abc]
│                                      │
│                                      ├─ Processes research task
│                                      │
│                                      └─ sendMessage(contextId=ctx-abc)  →  [Writer receives ctx-abc]
│                                                                               │
│                                                                               └─ Processes write task
│                                                                                   Writer crashes →
│                                                                                   [ctx-abc state preserved]
│
└─ Detects Writer failure
   ├─ Sends new sendMessage(contextId=ctx-abc, taskId=task-writer-123)
   │  "Resume the writer task from last checkpoint"
   └─ Writer restarts, reads ctx-abc state → continues from paragraph 4
```

The `contextId` is generated by the *first agent* to initiate the session (typically the orchestrator) and propagated forward. It is never generated by a downstream specialist — that would break context identity. If you see a specialist generating a new `contextId` for its own sub-tasks, that's a bug: sub-tasks should carry the parent `contextId` so the full workflow remains traceable.

<KnowledgeCheck
  question="An Orchestrator starts a workflow and assigns contextId='ctx-xyz'. It delegates to Researcher, which then delegates to Writer. The Writer crashes. When the Orchestrator retries the Writer, what contextId should the retry message carry?"
  answers={[
    "A new UUID — the retry is a new task session",
    "'ctx-xyz' — the same contextId as the original session, with the original taskId to resume",
    "'ctx-xyz' — the same contextId but with a null taskId to start fresh",
    "The Writer's own contextId generated when it first started processing"
  ]}
  correct={1}
/>

---

## Request/Response vs. Fire-and-Forget

A2A supports three distinct interaction patterns. Understanding which to use is a systems architecture decision, not a convenience choice.

### Pattern 1: Blocking Request/Response

Set `configuration.returnImmediately: false` in `sendMessage`. The HTTP connection stays open until the task reaches a terminal state (`COMPLETED`, `FAILED`, `CANCELED`). The response body contains the final Task object with all output Parts.

```json
"configuration": {
  "returnImmediately": false,
  "acceptedOutputModes": ["data"]
}
```

**When to use**: Short tasks (under 30 seconds), low-concurrency workflows, simple synchronous pipelines. Avoid for any task that might take minutes — HTTP timeouts and client reconnection logic add operational complexity that outweighs the simplicity.

### Pattern 2: Fire-and-Forget with Polling

Set `configuration.returnImmediately: true`. The server immediately returns a `Task` object in `SUBMITTED` state. The client stores the `taskId` and polls with `getTask` until the task reaches a terminal state.

```json
// sendMessage response (immediate)
{
  "jsonrpc": "2.0",
  "result": {
    "id": "task-def456",
    "contextId": "ctx-abc",
    "status": {"state": "SUBMITTED"},
    "history": []
  },
  "id": "req-001"
}

// Client polls after 2s:
// getTask({"id": "task-def456"}) → {"status": {"state": "WORKING"}, ...}

// Client polls after 8s:
// getTask({"id": "task-def456"}) → {"status": {"state": "COMPLETED"}, "artifacts": [...]}
```

**When to use**: Medium-duration tasks (30 seconds to 10 minutes), any task where you need to show progress to a user. The polling interval should be adaptive: start at 1 second, back off to 5 seconds after the first `WORKING` state, and reset to 1 second after receiving `INPUT_REQUIRED`.

### Pattern 3: Streaming with Server-Sent Events

Use `sendStreamingMessage` instead of `sendMessage`. The server responds with a `text/event-stream` content type and emits Server-Sent Events as the task progresses:

```
event: TaskStatusUpdateEvent
data: {"taskId": "task-def456", "status": {"state": "WORKING"}}

event: TaskArtifactUpdateEvent
data: {"messageId": "msg-789", "parts": [{"kind": "text", "text": "Based on the Q3 transcript, "}]}

event: TaskArtifactUpdateEvent
data: {"messageId": "msg-789", "parts": [{"kind": "text", "text": "revenue grew 12% year-over-year..."}]}

event: TaskStatusUpdateEvent
data: {"taskId": "task-def456", "status": {"state": "COMPLETED"}}
```

**When to use**: Long tasks (over 10 minutes), any user-facing pipeline where displaying incremental output improves perceived performance, agents that produce large text outputs. SSE is the right default for anything the user will watch in real time.

The A2A specification's use of SSE for streaming is intentional: SSE is natively supported by every modern HTTP client without a custom library, unlike WebSockets. If you're building a Python client, `httpx` with `httpx.stream()` handles SSE trivially.

---

## Hands-On Exercise: Write a Full Task Negotiation Sequence

**Time estimate:** 25 minutes

**Goal:** Write the complete JSON-RPC message sequence for a two-agent Task Negotiation — from AgentCard fetch through final task completion — and verify the state transitions in a mocked agent blackboard.

### The Scenario

You are an Orchestrator agent. You need to hire a "Contract Risk Analyst" specialist agent (the one we designed earlier) to analyze a procurement contract. The contract is short enough to send as plain text.

Write the following messages in order:

---

**Message 0: AgentCard Fetch (HTTP GET, not JSON-RPC)**

Write the HTTP request line and headers for fetching the AgentCard. Include the `Host` header.

---

**Message 1: First `sendMessage` (non-blocking)**

Write the complete JSON-RPC `sendMessage` payload. Include:
- `jsonrpc`, `method`, `id`
- `params.message.role`, `messageId` (placeholder UUID), `contextId` (placeholder UUID)
- `params.message.parts`: one TextPart with the instruction: "Analyze the following contract for price spike risk and single-source dependency risk. Return a JSON array of risk findings, each with: clause (string), risk_type (string), severity (critical|high|medium|low), and remediation (string)." and one TextPart with the contract body: "VENDOR AGREEMENT §3.2: All steel components sourced exclusively from Acme Steel Corp. Pricing subject to quarterly revision without cap. Penalty for early termination: 18% of remaining contract value."
- `params.configuration.returnImmediately: true`
- `params.configuration.acceptedOutputModes: ["data"]`

---

**Message 1 Response: Initial Task State**

Write the JSON-RPC response from the specialist. The task is in `SUBMITTED` state. Include: `taskId`, `contextId`, `status.state`, empty `history` array, empty `artifacts` array.

---

**Message 2: `getTask` Polling Call**

Write the JSON-RPC `getTask` call using the `taskId` from Message 1's response.

---

**Message 2 Response: Working State**

Write the `getTask` response showing the task in `WORKING` state.

---

**Message 3: Final `getTask` Response — Completed**

Write the `getTask` response showing the task in `COMPLETED` state with an `artifacts` array containing one DataPart artifact. The artifact should be a JSON array with two risk findings for the contract text above.

---

### Agent Blackboard — Verify State Transitions

Fill in the state machine table as you complete each message:

| Step | Event | Task State | Expected Next State |
|---|---|---|---|
| 0 | AgentCard fetched | (no task yet) | Ready to send |
| 1 | `sendMessage` sent | `SUBMITTED` | `WORKING` |
| 2 | `getTask` (2s later) | `WORKING` | `COMPLETED` (or still `WORKING`) |
| 3 | `getTask` (8s later) | `COMPLETED` | Terminal — no further polling |

---

### Success Criteria

- Your `sendMessage` payload is valid JSON-RPC 2.0: `jsonrpc`, `method`, `id`, `params` all present.
- The `contextId` is the same UUID in both `sendMessage` and all `getTask` responses.
- The `taskId` in `getTask` matches the `taskId` returned in the `sendMessage` response.
- The `COMPLETED` response includes at least two risk findings in the artifacts DataPart, each with `clause`, `risk_type`, `severity`, and `remediation` fields.
- You correctly identified both risk factors in the contract text: the single-source dependency (§3.2: "exclusively from Acme Steel Corp") and the price spike risk ("quarterly revision without cap").

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| JSON-RPC 2.0 | Lightweight RPC protocol using JSON over HTTP. A2A's transport layer. |
| Message Envelope | The complete A2A message: HTTP headers + JSON-RPC wrapper + Message object + Parts array |
| `contextId` | UUID that identifies a session across all agents and all turns in a workflow |
| `messageId` | UUID unique to one message turn; used for idempotency |
| `taskId` | UUID assigned by the server when a `sendMessage` creates a new task |
| Handshake | Four-step pre-task sequence: AgentCard fetch → version validation → extension negotiation → authentication |
| Skill (Capability Schema) | JSON object in AgentCard declaring one task type the agent can fulfill |
| `returnImmediately` | `sendMessage` config flag; `true` = return `SUBMITTED` immediately (fire-and-forget); `false` = wait for task completion (blocking) |
| Fire-and-Forget | Non-blocking `sendMessage` + subsequent `getTask` polling |
| SSE Streaming | `sendStreamingMessage` → `text/event-stream` response with incremental task events |

---

## What's Next

[[multi-agent-orchestration-a2a/chapter-03|Chapter 3: The Internet of Agents — AGNTCY & Global Discovery]] builds on the Capability Schema you designed in this chapter. You'll publish your agent to a local AGNTCY-style registry using an OASF schema, run a fuzzy capability query against it, and implement the p2p gossip fallback that keeps your network alive when the central registry goes down.

You now know what agents say to each other. In Chapter 3, you'll learn how they find each other.

---

*Sources: [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [A2A Agent Discovery](https://a2a-protocol.org/latest/topics/agent-discovery/) · [A2A Streaming and Async](https://a2a-protocol.org/latest/topics/streaming-and-async/) · [Google A2A Announcement, Apr 2025](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)*

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-03.md -->

```yaml
course: multi-agent-orchestration-a2a
chapter_num: 3
chapter_title: "The Internet of Agents — AGNTCY & Global Discovery (2026)"
author: course-author
ticket: KOEA-6946
date: 2026-05-31
status: g0-passed
level: Advanced
duration_min: 50
reading_time_min: 12
prerequisites_chapters:
  - 1
  - 2
learning_objectives:
  - Explain the AGNTCY Internet of Agents vision and the role of global agent registries in enabling cross-vendor collaboration
  - Implement a Capability Discovery query against a mock AGNTCY-style registry using OASF schema conventions
  - Design a globally unique Agent Identity (AID) and explain the trust implications of centralized versus decentralized identity
  - Describe the Registry-less Discovery fallback pattern using p2p gossip and explain when each discovery mode should be preferred
positions:
  - id: mcp-as-interoperability-moat
    engagement: defends
  - id: audit-trail-as-enterprise-gate
    engagement: defends
slug: multi-agent-orchestration-a2a-ch03
description: "Learn how AGNTCY's Internet of Agents infrastructure enables cross-vendor agent discovery, global registry queries, OASF capability indexing, and p2p gossip fallback for resilient multi-agent systems."
tags: [AGNTCY, A2A, agent-discovery, OASF, multi-agent, Internet-of-Agents]
chapter_primary_query: "how to discover agents using AGNTCY and A2A protocol"
first_60_words_answer: "AGNTCY is the Linux Foundation-hosted open infrastructure for the Internet of Agents. To discover agents, you publish an OASF-compliant schema to an Agent Directory Service and query it by capability — not by hard-coded endpoint. Every A2A-compliant agent also exposes a /.well-known/agent-card.json that any client can probe. Together, these two mechanisms make cross-vendor agent discovery deterministic rather than manual."
faq:
  - question: "What is AGNTCY and why does it matter for multi-agent systems?"
    answer: "AGNTCY is a Linux Foundation open-source initiative that provides the infrastructure layer — discovery, identity, messaging, and observability — that lets AI agents from different vendors and frameworks find and collaborate with each other without bilateral integration agreements. ([AGNTCY.org](https://agntcy.org/))"
  - question: "How does A2A agent discovery work in practice?"
    answer: "Every A2A-compliant agent publishes an AgentCard at /.well-known/agent-card.json describing its capabilities, skills, and auth requirements. Clients can probe this endpoint directly (well-known URI discovery), query a curated registry that indexes many AgentCards (registry discovery), or use a hardcoded endpoint (direct config) for tightly coupled systems. ([A2A agent discovery spec](https://a2a-protocol.org/latest/topics/agent-discovery/))"
  - question: "What is OASF and how does it relate to agent discovery?"
    answer: "The Open Agentic Schema Framework (OASF) is an extensible data model from AGNTCY that formalizes how agents describe their capabilities, identity, and supported protocols. OASF records can be indexed by the Agent Directory Service and queried by fuzzy capability string, enabling agents to find each other by what they can do rather than where they live. ([OASF docs](https://docs.agntcy.org/oasf/open-agentic-schema-framework/))"
  - question: "What happens if the central registry goes down?"
    answer: "Production A2A networks should fall back to p2p gossip discovery using protocols like Hyperspace's GossipSub or libp2p DHT. Agents that have previously established connections share AgentCard updates peer-to-peer, so the network degrades gracefully rather than failing completely if a central directory is unavailable. ([Hyperspace Protocol](https://protocol.hyper.space/))"
inline_assets:
  - type: diagram
    path: ./img/ch03-discovery-modes.png
    alt: "Three A2A agent discovery modes: well-known URI probe (agent exposes /.well-known/agent-card.json), curated registry query (central service indexes many AgentCards, client queries by capability), and direct config (hardcoded endpoint in client application). All three modes return the same AgentCard document."
last_updated: 2026-06-15
sources:
  - https://agntcy.org/
  - https://docs.agntcy.org/
  - https://docs.agntcy.org/oasf/open-agentic-schema-framework/
  - https://github.com/agntcy/oasf
  - https://a2a-protocol.org/latest/topics/agent-discovery/
  - https://a2a-protocol.org/latest/specification/
  - https://www.linuxfoundation.org/press/linux-foundation-welcomes-the-agntcy-project-to-standardize-open-multi-agent-system-infrastructure-and-break-down-ai-agent-silos
  - https://protocol.hyper.space/
```

# The Internet of Agents — AGNTCY & Global Discovery (2026)

> **Chapter 3 of 10 · 50 min (prose ~12 min + 30 min hands-on exercise)**

---

AGNTCY is the Linux Foundation-hosted open infrastructure for the Internet of Agents. To discover agents, you publish an OASF-compliant schema to an Agent Directory Service and query it by capability — not by hard-coded endpoint. Every A2A-compliant agent also exposes a `/.well-known/agent-card.json` that any client can probe. Together, these two mechanisms make cross-vendor agent discovery deterministic rather than manual.

This chapter builds the discovery layer on top of the wire protocol you learned in [[multi-agent-orchestration-a2a/chapter-02|Chapter 2]]. By the end, you'll be able to register an agent in a local registry, query that registry by fuzzy capability string, and implement the p2p gossip fallback that keeps your network alive when the registry goes down. (New to A2A? Start with [[multi-agent-orchestration-a2a/chapter-01|Chapter 1]] for the protocol foundations.)

---

## Why Discovery Is the Hardest Problem in Multi-Agent Systems

You've solved the wire format (Chapter 2). Your agents can send `sendMessage` payloads, negotiate capabilities, and track task state. The next question immediately surfaces: **how does Agent A find Agent B in the first place?**

In traditional microservice architectures, this is solved by a service mesh — Kubernetes DNS, Consul, Eureka. You deploy services with known names, you configure clients to hit those names, done. The topology is static and centrally managed.

Agents break this assumption in three ways:

1. **Dynamic capability emergence.** Agents acquire new skills over time (through tool updates, fine-tuning, or new MCP server connections). A static registry entry becomes stale within hours.
2. **Cross-organizational boundaries.** Your orchestrator needs to hire a specialist that belongs to a different company's infrastructure. There is no shared Kubernetes cluster, no shared Consul, no shared anything.
3. **Intent-based matching.** You don't want to query "give me the agent named `sentiment-analyst-v3`." You want to query "give me an agent that can analyze earnings call transcripts and output JSON sentiment scores." The registry must understand capability semantics, not just string names.

These three constraints rule out every traditional service-discovery approach. What the agent ecosystem needs — and what AGNTCY is building — is a *protocol-level* discovery infrastructure where any agent can advertise capabilities in a standardized schema and any client can find the right agent by semantic query.

---

## AGNTCY — The Internet of Agents Infrastructure

[AGNTCY](https://agntcy.org/) launched in March 2025, founded by Outshift by Cisco, LangChain, and Galileo. By mid-2026, it operates under Linux Foundation governance with Cisco, Dell Technologies, Google Cloud, Oracle, and Red Hat as formative members — the same governance model that gave us Kubernetes and OpenTelemetry. ([Linux Foundation press release](https://www.linuxfoundation.org/press/linux-foundation-welcomes-the-agntcy-project-to-standardize-open-multi-agent-system-infrastructure-and-break-down-ai-agent-silos))

The AGNTCY vision has four capabilities that map exactly to the lifecycle gaps that make multi-agent systems hard to build:

| Capability | What it solves | AGNTCY component |
|---|---|---|
| **Discover** | Finding the right agent for a task across org boundaries | Agent Directory Service + OASF |
| **Compose** | Wiring agents into workflows without bilateral integration | SLIM messaging protocol |
| **Deploy** | Running multi-agent systems securely at cloud scale | Cloud-native deployment specs |
| **Evaluate** | Tracking agent performance and optimizing effectiveness | Observability & telemetry layer |

This chapter focuses almost entirely on **Discover** — the first capability. Compose is covered in Chapter 6; Deploy and Evaluate in Chapters 7 and 9.

AGNTCY is not a product. It is an **infrastructure layer** that frameworks run on top of. LangGraph can use AGNTCY for discovery while orchestrating agents internally. A Paperclip agent and a Vertex AI agent can find each other through AGNTCY without sharing a framework at all. This is the same relationship DNS has to HTTP: the naming layer is independent of what the applications do after they connect.

---

## OASF — The Schema That Powers Discovery

Every agent in an AGNTCY-compatible network publishes an **OASF record** — an Open Agentic Schema Framework document that describes who the agent is and what it can do. ([docs.agntcy.org/oasf](https://docs.agntcy.org/oasf/open-agentic-schema-framework/))

OASF is an OCSF-inspired extensible data model (Open Cybersecurity Schema Framework — not Open Container Initiative). The top-level fields describe the agent's identity and protocol support; the taxonomy of skills uses a dotted-namespace notation that enables semantic search:

```json
{
  "oasf_version": "1.0",
  "uid": "did:agntcy:abc123-sentiment-analyst",
  "name": "SentimentAnalyst",
  "description": "Analyzes financial text — earnings calls, news, filings — and returns structured JSON sentiment scores with per-entity attribution.",
  "version": "2.1.4",
  "endpoints": [
    {
      "type": "a2a",
      "url": "https://agents.acme.io/sentiment-analyst",
      "agent_card_url": "https://agents.acme.io/sentiment-analyst/.well-known/agent-card.json"
    }
  ],
  "skills": [
    {
      "id": "nlp.sentiment.financial",
      "name": "Financial Sentiment Analysis",
      "description": "Returns sentiment polarity and confidence per named entity from earnings transcripts, press releases, and SEC filings.",
      "input_modes": ["text/plain", "application/pdf"],
      "output_modes": ["application/json"],
      "examples": [
        "Analyze the Q3 2025 Apple earnings call transcript",
        "Rate sentiment for all named entities in this press release"
      ]
    },
    {
      "id": "nlp.ner.financial",
      "name": "Financial Named Entity Recognition",
      "description": "Extracts company, person, and financial instrument entities from financial text.",
      "input_modes": ["text/plain"],
      "output_modes": ["application/json"]
    }
  ],
  "extensions": ["a2a/push-notifications", "a2a/streaming"],
  "auth": {
    "schemes": ["oauth2", "dpop"]
  }
}
```

The `skills` array is the key to semantic discovery. The dotted notation (`nlp.sentiment.financial`) is hierarchical — an orchestrator querying for agents with any `nlp.sentiment.*` skill will match this agent even without knowing the exact skill ID. This is capability indexing: the registry stores the taxonomy tree and supports prefix-match and fuzzy queries.

<Callout type="info">
OASF records extend A2A's AgentCard format without replacing it. The AgentCard (at `/.well-known/agent-card.json`) is the A2A wire-level identity document. The OASF record wraps and extends it with richer metadata — cost-per-task, performance SLAs, domain classification, and observability endpoints — that the registry indexes for discovery. When an agent publishes to the AGNTCY directory, it submits its OASF record; the directory extracts and caches the AgentCard URL so A2A clients can probe it directly.
</Callout>

---

## Agent Identity (AID) — Global Uniqueness and Trust Implications

Every agent in an Internet of Agents network needs a globally unique identifier that:

1. **Proves ownership** — the identifier holder controls the private key
2. **Doesn't depend on a registry** — the identity must be verifiable even if the directory is unreachable
3. **Survives relocations** — when an agent moves from `cloud.acme.io` to `on-prem.acme.io`, its identity doesn't change

The emerging pattern, visible in both AGNTCY and Hyperspace Protocol, is **DID-style identifiers**: `did:agntcy:<unique-id>`. DID (Decentralized Identifier) URNs bind identity to a cryptographic key pair, not to a domain name or a registry record.

The trust chain for an AID works like this:

```
Agent generates secp256k1 keypair
        ↓
Public key → hashed to produce AID   (did:agntcy:abc123...)
        ↓
Private key → signs OASF records and A2A message envelopes
        ↓
Any verifier can validate signature without contacting the registry
```

This is why the contrarian angle for this chapter matters so much: **the identity must not be owned by the registry**. The GPT Store model — where OpenAI assigns plugin IDs and revokes them at will — is fundamentally incompatible with an interoperable Internet of Agents. If Acme Corp's orchestrator integrates with your agent, Acme Corp's workflow should not break if you decide to move registries. Your AID is yours; registries are just *indexes* of it.

**Trust implications for production systems:**

- An agent you discover via a registry is only as trustworthy as the registry's vetting process. Use the AID + signature to verify claims independently of the registry.
- Registries can be gamed: a malicious agent can publish a plausible OASF record with false capability claims. Before delegating sensitive tasks, always run the A2A capability negotiation handshake (Chapter 2) to confirm the agent can actually *demonstrate* the skills it claims.
- Enterprise deployments typically run **private registries** that accept only AIDs from known organizational namespaces (`did:agntcy:acme:*`). Public discovery layers on top of private identity — the organization controls which agents appear in public search results.

<KnowledgeCheck
  question="An agent's AID (Agent Identity) is based on a cryptographic key pair rather than a domain name. Which property does this provide?"
  answers={[
    "The agent's identity becomes tied to the hosting provider's infrastructure",
    "The registry gains exclusive authority to revoke agent identities",
    "The agent's identity can be verified without contacting the registry, and survives domain migrations",
    "AIDs prevent agents from being indexed in multiple registries simultaneously"
  ]}
  correct={2}
/>

---

## The Three A2A Discovery Mechanisms

The A2A specification defines three discovery modes. They are not mutually exclusive — a production system typically implements all three in order of preference. ([a2a-protocol.org/latest/topics/agent-discovery](https://a2a-protocol.org/latest/topics/agent-discovery/))

### Mode 1: Well-Known URI Probe

The simplest discovery mechanism. Every A2A server MUST expose its AgentCard at:

```
https://{domain}/.well-known/agent-card.json
```

This follows [RFC 8615](https://www.rfc-editor.org/rfc/rfc8615) conventions. Any client that knows the domain can retrieve the AgentCard without prior agreement:

```python
import httpx

async def probe_agent(domain: str) -> dict:
    url = f"https://{domain}/.well-known/agent-card.json"
    async with httpx.AsyncClient() as client:
        response = await client.get(url, timeout=5.0)
        response.raise_for_status()
        return response.json()

# Usage
card = await probe_agent("agents.acme.io")
print(card["name"])         # SentimentAnalyst
print(card["skills"])       # [...skill list...]
```

**When to use:** Public agents where you know the domain. Dev environments where you're testing a specific agent.

**Limitation:** You must already know the domain. This is not discovery from capability — it is discovery from location. The "I know you exist" problem is not solved.

### Mode 2: Curated Registry Query

A registry service indexes many AgentCards and exposes a query API. The A2A spec does not standardize the registry API (as of v1.0.0), but AGNTCY's Agent Directory Service and the emerging community conventions converge on a pattern:

```python
import httpx

async def discover_by_capability(
    registry_url: str,
    skill_prefix: str,
    min_output_modes: list[str] | None = None,
) -> list[dict]:
    """Query an AGNTCY-style registry for agents by capability prefix."""
    params = {
        "skill": skill_prefix,          # prefix match: "nlp.sentiment.*"
        "output_modes": min_output_modes or [],
    }
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{registry_url}/v1/agents/search",
            params=params,
            timeout=10.0,
        )
        response.raise_for_status()
        return response.json()["agents"]

# An orchestrator looking for a financial sentiment specialist
candidates = await discover_by_capability(
    registry_url="https://registry.agntcy.org",
    skill_prefix="nlp.sentiment.financial",
    min_output_modes=["application/json"],
)

for agent in candidates:
    print(f"{agent['name']} → {agent['endpoints'][0]['agent_card_url']}")
```

**When to use:** Cross-organizational discovery where you don't know what agents exist. Marketplace scenarios where you want to compare multiple candidates before hiring.

**Limitation:** Requires a running registry. The registry's index of capabilities must be kept current — stale OASF records return outdated capability information.

### Mode 3: Direct Configuration

The agent's endpoint is hardcoded in a config file, environment variable, or secrets manager. No runtime discovery occurs.

```yaml
# agents.yaml
specialists:
  sentiment_analyst:
    agent_card_url: https://agents.acme.io/sentiment/.well-known/agent-card.json
    auth: oauth2
```

**When to use:** Tightly coupled production systems with known, stable partners. CI environments where discovery must be deterministic. Fallback when both Mode 1 and Mode 2 fail.

**Limitation:** Breaks the Intent Gap closure — you're back to hard-coding endpoints rather than discovering by capability.

---

## Building a Local AGNTCY-Style Registry

You don't need to run the full AGNTCY stack to experiment with registry-based discovery. The following is a minimal FastAPI implementation that accepts OASF-style registrations and supports prefix-match capability queries:

```python
# registry.py — local AGNTCY-style agent registry
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json, re

app = FastAPI(title="Local Agent Registry")

# In-memory store: aid → oasf_record
_registry: dict[str, dict] = {}

class OASFRecord(BaseModel):
    uid: str                   # AID: did:agntcy:<hash>
    name: str
    description: str
    version: str
    endpoints: list[dict]
    skills: list[dict]         # [{id, name, description, input_modes, output_modes}]
    auth: dict = {}

@app.post("/v1/agents/register", status_code=201)
async def register_agent(record: OASFRecord):
    _registry[record.uid] = record.model_dump()
    return {"registered": record.uid, "total_agents": len(_registry)}

@app.get("/v1/agents/search")
async def search_agents(skill: str = "", output_modes: list[str] = []):
    """Prefix-match agents by skill taxonomy path."""
    pattern = re.compile(
        r"^" + re.escape(skill).replace(r"\*", r".*") + r"$"
    )
    results = []
    for record in _registry.values():
        for s in record["skills"]:
            if pattern.match(s["id"]):
                # filter by output_modes if specified
                if output_modes and not any(
                    m in s.get("output_modes", []) for m in output_modes
                ):
                    continue
                results.append(record)
                break
    return {"agents": results, "count": len(results)}

@app.get("/v1/agents/{uid}")
async def get_agent(uid: str):
    if uid not in _registry:
        raise HTTPException(status_code=404, detail="Agent not found")
    return _registry[uid]
```

Run it:

```bash
pip install fastapi uvicorn httpx pydantic
uvicorn registry:app --port 8001 --reload
```

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You are an A2A orchestrator agent. Generate a complete OASF record (as a JSON object) for a \"Financial News Researcher\" agent with the following properties:\n- uid: did:agntcy:finresearch-001\n- Endpoint: http://localhost:8002 with A2A agent-card URL\n- Two skills: news.fetch.financial (fetches financial news from RSS/web) and news.summarize.earnings (summarizes earnings call transcripts)\n- Input modes: text/plain for both skills\n- Output modes: application/json for news.fetch.financial; text/markdown for news.summarize.earnings\n- Auth: api_key scheme\n\nOutput only valid JSON."
  expectedOutput='{"uid":"did:agntcy:finresearch-001","name":"FinancialNewsResearcher","description":"Fetches and summarizes financial news from RSS feeds and earnings call transcripts.","version":"1.0.0","endpoints":[{"type":"a2a","url":"http://localhost:8002","agent_card_url":"http://localhost:8002/.well-known/agent-card.json"}],"skills":[{"id":"news.fetch.financial","name":"Financial News Fetch","description":"Fetches financial news from RSS feeds and financial news APIs.","input_modes":["text/plain"],"output_modes":["application/json"]},{"id":"news.summarize.earnings","name":"Earnings Call Summarizer","description":"Summarizes earnings call transcripts into structured key-point narratives.","input_modes":["text/plain"],"output_modes":["text/markdown"]}],"auth":{"schemes":["api_key"]}}'
/>

---

## Capability Indexing — How Fuzzy Search Works

The dotted taxonomy notation in OASF (`nlp.sentiment.financial`) is not arbitrary. It encodes a hierarchical capability tree that registries can index efficiently:

```
nlp
├── sentiment
│   ├── financial        ← "does it affect stock prices?"
│   ├── social-media     ← "Twitter/Reddit tone analysis"
│   └── customer         ← "product review analysis"
├── summarization
│   ├── abstractive
│   └── extractive
└── ner
    └── financial

news
├── fetch
│   └── financial
└── summarize
    └── earnings
```

A query for `nlp.*` returns every agent that has any NLP skill. A query for `nlp.sentiment.*` returns sentiment agents across all domains. A query for `nlp.sentiment.financial` returns only the agents that specifically handle financial text. This prefix-match hierarchy is how an orchestrator can be intentionally broad ("find me *any* NLP agent") or intentionally narrow ("find me an agent that specifically handles financial sentiment in JSON output format").

**Scoring and ranking:** Production registries layer fuzzy scoring on top of prefix matching. The AGNTCY Agent Directory Service weights candidates by:
- Skill specificity match (exact match > prefix match)
- Output mode compatibility
- Self-reported performance metadata (latency_p50_ms, success_rate)
- Recency of last OASF update

The orchestrator receives a ranked list of candidates, not a single "best" answer. The agent that's cheapest might not be the most accurate. The final selection — whether to pick by cost, by declared success rate, or by brand trust — belongs to the orchestrator's policy layer, not the registry.

<KnowledgeCheck
  question="An orchestrator queries a registry with skill='nlp.sentiment.*'. Which of the following agents will be returned? (Select all that apply)"
  answers={[
    "An agent with skill id 'nlp.sentiment.financial'",
    "An agent with skill id 'nlp.summarization.abstractive'",
    "An agent with skill id 'nlp.sentiment.social-media'",
    "An agent with skill id 'news.fetch.financial'"
  ]}
  correct={[0, 2]}
  multi={true}
  freeform="Explain in one sentence why skill prefix matching is more useful for orchestrators than exact-match queries."
/>

---

## Registry-less Discovery — The P2P Gossip Fallback

Central registries have a single-point-of-failure problem. For enterprise-grade systems, a 5-minute registry outage should not prevent agents from finding each other at all. The fallback is **p2p gossip discovery**.

The pattern (implemented by Hyperspace Protocol using GossipSub, and by the Pilot Protocol using libp2p DHT) works as follows:

1. **Bootstrap contact list.** Each agent starts with a small list of known peer agents (2-5 bootstrap peers) from direct configuration.
2. **Heartbeat broadcast.** Every 60 seconds, each agent broadcasts a signed OASF summary (uid + skill IDs + endpoint hash) to its connected peers.
3. **Forwarding with TTL.** Peers forward the broadcast to their own connected peers with `TTL - 1`. A TTL of 3 reaches an agent's third-degree network within 3 heartbeat intervals (~3 minutes).
4. **Local cache.** Each agent maintains a local capability cache keyed by AID. Before querying a registry, agents check their local cache for recently-seen matching UIDs.
5. **Fallback trigger.** When the central registry returns an error or times out, the orchestrator degrades to querying the local cache.

```python
# gossip_client.py — minimal p2p capability cache
import time, json, hashlib

class GossipCache:
    def __init__(self, ttl_seconds: int = 300):
        self._cache: dict[str, dict] = {}  # aid → {record, seen_at}
        self._ttl = ttl_seconds

    def update(self, oasf_summary: dict):
        uid = oasf_summary["uid"]
        self._cache[uid] = {
            "record": oasf_summary,
            "seen_at": time.time(),
        }

    def search_by_skill(self, skill_prefix: str) -> list[dict]:
        now = time.time()
        results = []
        for uid, entry in self._cache.items():
            if now - entry["seen_at"] > self._ttl:
                continue  # stale entry
            for skill_id in entry["record"].get("skill_ids", []):
                if skill_id.startswith(skill_prefix.replace("*", "")):
                    results.append(entry["record"])
                    break
        return results

    def evict_stale(self):
        now = time.time()
        self._cache = {
            uid: entry
            for uid, entry in self._cache.items()
            if now - entry["seen_at"] <= self._ttl
        }
```

The complete discovery flow for a production orchestrator looks like:

```python
async def find_agent(
    skill: str,
    registry: RegistryClient,
    gossip: GossipCache,
) -> dict | None:
    # 1. Try registry first (authoritative, fresh data)
    try:
        candidates = await registry.search(skill=skill, timeout=5.0)
        if candidates:
            return candidates[0]  # pick highest-ranked
    except (httpx.TimeoutException, httpx.HTTPStatusError):
        pass  # registry unavailable, fall through

    # 2. Fall back to local gossip cache
    cached = gossip.search_by_skill(skill)
    if cached:
        return cached[0]

    # 3. Fall back to direct config
    return FALLBACK_CONFIG.get(skill)
```

<Callout type="warning">
P2P gossip discovery is eventually consistent. An agent that just registered will not appear in peer caches until the next broadcast cycle (up to 3 minutes). For time-sensitive task delegation in production systems, always try the central registry first and use gossip only as a fallback. Never treat gossip cache results as authoritative — the agent's endpoint or capability set may have changed since the last broadcast. Always validate against the agent's live AgentCard before delegating high-stakes tasks.
</Callout>

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You are an A2A orchestrator. You have just queried a local AGNTCY registry and received the following two candidate agents for the skill 'nlp.sentiment.financial':\n\nAgent A: {\"name\": \"SentimentAnalystPro\", \"uid\": \"did:agntcy:sap-v2\", \"declared_latency_p50_ms\": 800, \"declared_success_rate\": 0.97, \"cost_per_task_usd\": 0.04}\nAgent B: {\"name\": \"QuickSentiment\", \"uid\": \"did:agntcy:qs-v1\", \"declared_latency_p50_ms\": 200, \"declared_success_rate\": 0.88, \"cost_per_task_usd\": 0.01}\n\nYou need to analyze quarterly earnings sentiment across 50 transcripts (high accuracy required). Which agent should you hire and why? Write a 3-sentence justification that references the specific metrics and explains the tradeoff."
  expectedOutput="SentimentAnalystPro (Agent A) is the better choice for high-accuracy batch analysis. Its 0.97 success rate is significantly higher than QuickSentiment's 0.88, which translates to roughly 5 fewer failures per 50 transcripts — important when earnings sentiment errors could influence financial decisions. The 4× cost difference ($2.00 vs. $0.50 total) is acceptable given the accuracy requirement and the higher operational cost of re-running failed tasks."
/>

---

## Centralized vs. Decentralized: The Architectural Choice

The outline's contrarian angle for this chapter is correct and deserves a direct treatment: **centralized registries like the GPT Store are architecturally anti-A2A**.

Here's why. The GPT Store model (and similar plugin marketplaces from other providers) has these properties:

- **Platform-controlled identity**: The platform assigns and can revoke agent IDs.
- **Platform-controlled discovery**: Only agents the platform approves appear in search results.
- **Platform-controlled relationships**: The integration between your orchestrator and a plugin runs through the platform's infrastructure, not directly between you and the plugin.

This is not discovery — it's a **walled garden**. If OpenAI decides to remove a plugin, every orchestrator that relied on it breaks. If Anthropic's plugin store goes down, discovery fails globally. The platform owns the relationship between agents.

An Internet of Agents built on A2A + AGNTCY has the opposite properties:

- **Self-sovereign identity** (DID-style AIDs): You generate your identity; no platform can revoke it.
- **Open directory**: Any agent can publish to AGNTCY; the directory indexes capability, not platform membership.
- **Direct relationships**: After discovery, your orchestrator communicates directly with the specialist over A2A. No intermediary proxy required.

The business implication is significant: building on A2A + AGNTCY means your agent-to-agent integrations survive registry failures, platform policy changes, and organizational boundaries. Building on a proprietary plugin marketplace means you're renting your network topology from a vendor.

This is the same battle that open vs. proprietary email won in the 1990s. SMTP doesn't care which email provider you use. A2A + AGNTCY doesn't care which agent framework you use. That's the point.

---

## Hands-On Exercise: Register, Discover, Hire

**Time estimate:** 30 minutes

**Prerequisites:** Python 3.10+, pip

### Setup

Start the local registry from earlier in this chapter:

```bash
pip install fastapi uvicorn httpx pydantic
uvicorn registry:app --port 8001 --reload
```

### Step 1 — Register two agents

Copy the OASF records below and register each one using the registry's POST endpoint.

**Agent 1 — Financial News Researcher:**
```bash
curl -X POST http://localhost:8001/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "did:agntcy:finresearch-001",
    "name": "FinancialNewsResearcher",
    "description": "Fetches and summarizes financial news.",
    "version": "1.0.0",
    "endpoints": [{"type": "a2a", "url": "http://localhost:8002",
                   "agent_card_url": "http://localhost:8002/.well-known/agent-card.json"}],
    "skills": [
      {"id": "news.fetch.financial", "name": "Financial News Fetch",
       "input_modes": ["text/plain"], "output_modes": ["application/json"]},
      {"id": "news.summarize.earnings", "name": "Earnings Summarizer",
       "input_modes": ["text/plain"], "output_modes": ["text/markdown"]}
    ],
    "auth": {"schemes": ["api_key"]}
  }'
```

**Agent 2 — Sentiment Analyst:**
```bash
curl -X POST http://localhost:8001/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "did:agntcy:sentiment-001",
    "name": "SentimentAnalyst",
    "description": "Analyzes financial text sentiment.",
    "version": "2.1.0",
    "endpoints": [{"type": "a2a", "url": "http://localhost:8003",
                   "agent_card_url": "http://localhost:8003/.well-known/agent-card.json"}],
    "skills": [
      {"id": "nlp.sentiment.financial", "name": "Financial Sentiment Analysis",
       "input_modes": ["text/plain", "application/pdf"], "output_modes": ["application/json"]},
      {"id": "nlp.ner.financial", "name": "Financial NER",
       "input_modes": ["text/plain"], "output_modes": ["application/json"]}
    ],
    "auth": {"schemes": ["oauth2", "dpop"]}
  }'
```

### Step 2 — Discovery queries

Run the following capability queries and record the results:

```bash
# Query 1: Find all NLP agents (broad prefix)
curl "http://localhost:8001/v1/agents/search?skill=nlp.*"

# Query 2: Find financial sentiment agents with JSON output
curl "http://localhost:8001/v1/agents/search?skill=nlp.sentiment.financial&output_modes=application/json"

# Query 3: Find news agents (should return Agent 1 only)
curl "http://localhost:8001/v1/agents/search?skill=news.*"

# Query 4: Find agents that do NOT exist
curl "http://localhost:8001/v1/agents/search?skill=code.generation.*"
```

**Expected results:**
- Query 1 → 1 agent (SentimentAnalyst)
- Query 2 → 1 agent (SentimentAnalyst)
- Query 3 → 1 agent (FinancialNewsResearcher)
- Query 4 → 0 agents

### Step 3 — Orchestrator hire flow

Write a Python function that:
1. Queries the local registry for an agent with skill `nlp.sentiment.financial`
2. Extracts the first result's `agent_card_url`
3. Probes that URL to retrieve the live AgentCard (use `http://localhost:8003/.well-known/agent-card.json` — it won't exist yet, so handle the `ConnectionRefused` gracefully)
4. Prints: "Would hire: {name} at {endpoint}" if the AgentCard probe succeeds, or "Would hire from registry cache: {name}" if the probe fails

**Success criteria:**
- `curl "http://localhost:8001/v1/agents/search?skill=nlp.sentiment.*"` returns exactly 1 agent
- `curl "http://localhost:8001/v1/agents/search?skill=code.*"` returns 0 agents
- Your Python function prints a "Would hire" line (from registry or cache) without crashing on the missing AgentCard endpoint

This is the core loop of every A2A orchestrator: **discover → probe → hire**. Chapter 4 builds on this by defining what a specialist agent does after it's hired.

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| AGNTCY | Linux Foundation initiative providing open infrastructure (discovery, identity, messaging, observability) for cross-vendor agent collaboration |
| OASF | Open Agentic Schema Framework — extensible JSON data model for describing agent capabilities, identity, and endpoints |
| AID | Agent Identity — a DID-style globally unique identifier bound to a cryptographic key pair, independent of any registry |
| Agent Directory Service | AGNTCY's distributed registry for agent announcement and discovery, synchronizable across nodes |
| Capability Indexing | Registry feature that indexes OASF skill taxonomies (dotted notation) for prefix-match and fuzzy search |
| Well-Known URI | RFC 8615-compliant endpoint (`/.well-known/agent-card.json`) where every A2A agent publishes its AgentCard |
| Gossip Discovery | P2P fallback discovery where agents exchange signed OASF summaries via broadcast (GossipSub/DHT), bypassing the central registry |
| Skill Taxonomy | Hierarchical dotted-namespace skill identifiers (e.g., `nlp.sentiment.financial`) enabling broad-to-narrow capability queries |

---

## What's Next

[[multi-agent-orchestration-a2a/chapter-04|Chapter 4: Modeling Roles and Capabilities — The Specialized Agent]] answers the question you haven't asked yet: once an orchestrator *finds* a specialist via discovery, how does the specialist enforce its own boundaries? You'll implement Recursive Task Decomposition, design a Capability Advertisement with cost-per-task, and build a specialist that rejects out-of-scope tasks rather than silently hallucinating an answer. The "No" is load-bearing.

---

*Sources: [AGNTCY — Internet of Agents](https://agntcy.org/) · [AGNTCY Documentation](https://docs.agntcy.org/) · [Open Agentic Schema Framework](https://docs.agntcy.org/oasf/open-agentic-schema-framework/) · [OASF GitHub](https://github.com/agntcy/oasf) · [A2A Agent Discovery](https://a2a-protocol.org/latest/topics/agent-discovery/) · [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [Linux Foundation AGNTCY Announcement](https://www.linuxfoundation.org/press/linux-foundation-welcomes-the-agntcy-project-to-standardize-open-multi-agent-system-infrastructure-and-break-down-ai-agent-silos) · [Hyperspace Gossip Protocol](https://protocol.hyper.space/)*

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-04.md -->

```yaml
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
```

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

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-05.md -->

```yaml
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8548
course: multi-agent-orchestration-a2a
chapter_num: 5
chapter_title: "Tool-Sharing & Resource Injection with MCP"
slug: multi-agent-orchestration-a2a-chapter-05
description: "MCP and A2A are not alternatives — they are protocol layers that compose. This chapter teaches the Tool Proxy and Resource Injection patterns that let specialist agents share tools and context across an A2A network, explains the MCP-to-A2A translation mismatches that break production systems, and walks through a FastMCP SQLite server exposed as a tool-sharing endpoint for a remote Researcher agent."
vendor_tag: anthropic
content_type: article
level: Advanced
duration_min: 55
reading_time_min: 14
last_updated: 2026-06-15
chapter_primary_query: "how to share MCP tools and inject resources between A2A agents"
first_60_words_answer: "MCP handles the vertical agent-to-tool connection; A2A handles horizontal agent-to-agent delegation. Tool Proxying lets Agent A invoke Agent B's MCP-backed capabilities over A2A without ever touching Agent B's MCP server. Resource Injection lets an orchestrator supply context to a specialist via a shared MCP resource URI, preserving role boundaries on both sides. Production systems need both protocols — they compose, not compete."
prerequisites_chapters: [2]
learning_objectives:
  - Integrate an MCP server into an A2A agent's capability set without claiming MCP is A2A-native
  - Implement Tool Proxying so Agent A invokes Agent B's MCP-backed skills via the A2A protocol
  - Design a Resource Injection flow where an orchestrator supplies context to a specialist via MCP Resources
  - Map the four structural MCP-to-A2A mismatches and their production failure modes
positions:
  - id: mcp-as-interoperability-moat
    engagement: defends
tags: [A2A, MCP, tool-sharing, resource-injection, multi-agent, orchestration, tool-proxy, protocol-composition]
status: g0-passed
sources:
  - https://arxiv.org/html/2603.05637v1 # retrieved 2026-06-15
  - https://www.anthropic.com/engineering/code-execution-with-mcp # retrieved 2026-06-15
  - https://www.digitalapplied.com/blog/ai-agent-protocol-ecosystem-map-2026-mcp-a2a-acp-ucp # retrieved 2026-06-15
  - https://subhadipmitra.com/blog/2026/agent-protocol-stack # retrieved 2026-06-15
  - https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI # retrieved 2026-06-15
  - https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02 # retrieved 2026-06-15
  - https://dev.to/aws-heroes/mcp-prompts-and-resources-the-primitives-youre-not-using-3oo1 # retrieved 2026-06-15
  - https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one # retrieved 2026-06-15
  - https://www.augmentcode.com/guides/a2a-vs-mcp # retrieved 2026-06-15
  - https://azure.microsoft.com/en-us/blog/agent-factory-connecting-agents-apps-and-data-with-new-open-standards-like-mcp-and-a2a # retrieved 2026-06-15
faq:
  - question: "What is the difference between MCP and A2A at the architecture level?"
    answer: "MCP is a vertical protocol — one agent, many tools. The agent is the active party; the tool is a passive capability provider with no autonomy, no independent task state, and no peer authentication context. A2A is a horizontal protocol — many agents, each autonomous. Agents maintain their own task lifecycle, authentication context, and failure-recovery logic. The correct production stack runs MCP within each specialist's own scope (agent-to-tool) and A2A across specialist boundaries (agent-to-agent). Mixing the two — for example, giving an orchestrator direct MCP access to a specialist's tools — breaks both protocols' trust models. ([AI Agent Protocol Ecosystem Map 2026, digitalapplied.com](https://www.digitalapplied.com/blog/ai-agent-protocol-ecosystem-map-2026-mcp-a2a-acp-ucp))"
  - question: "What is the confused-deputy problem in tool proxying, and how do you prevent it?"
    answer: "The confused-deputy problem occurs when Agent B proxies an MCP tool call on behalf of an orchestrator using its own standing MCP credential — granting the originating task privileges it was never given. Agent B may execute a database write or an API call that the orchestrator's user or task scope never authorized. The mitigation is threefold: mint a fresh, narrowly scoped OAuth 2.1 token per proxied call (scoped to the specific MCP tool, not Agent B's full MCP access); place an MCP gateway proxy (Gravitee, Pomerium) between agents and MCP servers to enforce per-tool authorization at the network layer; use short-lived signed identity assertions rather than long-lived credentials in agent processes. ([MCP Proxy: How It Works and Why Architects Need One, Gravitee](https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one))"
  - question: "Why should large context be injected as an MCP Resource rather than embedded in an A2A task message?"
    answer: "For large payloads — database schemas, historical datasets, long reference documents — embedding context in the A2A task message body inflates the payload and forces the specialist to load that content into its context window immediately on arrival, regardless of whether it needs all of it. Resource injection externalizes the data to a URI the specialist resolves on demand via resources/read. The specialist loads only what it needs, when it needs it. As an additional benefit, the upcoming MCP resources/subscribe extension (RC for the 2026-07-28 spec) enables the specialist to receive updates when context changes without polling. ([Multi-agent systems with MCP, Pluralsight](https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI))"
```

# Tool-Sharing & Resource Injection with MCP

> **Chapter 5 of 10 · 55 min (prose ~14 min + 25 min hands-on exercise)**

MCP handles the vertical agent-to-tool connection; A2A handles horizontal agent-to-agent delegation. Tool Proxying lets Agent A invoke Agent B's MCP-backed capabilities over A2A without ever touching Agent B's MCP server. Resource Injection lets an orchestrator supply context to a specialist via a shared MCP resource URI, preserving role boundaries on both sides. Production systems need both protocols — they compose, not compete.

---

## The Local Bus and the Network Protocol

MCP is USB. A2A is HTTP. Both move data. Both are protocols. But they operate at different architectural layers, and confusing them breaks multi-agent systems in ways that are hard to diagnose.

MCP (Model Context Protocol) handles the vertical connection between an agent and its tools. The agent is the active party; the tool is passive. When your specialist queries a database, calls an API, or reads a file through an MCP server, MCP is the correct abstraction. The tool has no autonomy, no independent state, and no understanding of why it was called.

A2A handles horizontal coordination between autonomous agents. When an orchestrator delegates a sub-task to a specialist that has its own reasoning, its own tools, and its own task lifecycle, A2A is the correct abstraction. The peer agent is not passive — it can pause, push back, fail, and recover independently.

> "The critical distinction most people miss: MCP treats external systems as tools for agents to use. A2A treats other agents as peers to collaborate with. An agent using MCP to query a database is fundamentally different from an agent using A2A to delegate a sub-task to a specialist agent. The trust models are different. The failure modes are different. The security boundaries are different." — [The Agent Protocol Stack, subhadipmitra.com](https://subhadipmitra.com/blog/2026/agent-protocol-stack)

In production, these protocols compose rather than compete. Each specialist maintains its own MCP connections to its own tools. Inter-agent coordination flows over A2A exclusively. That clean boundary is the subject of this chapter. For the Agent Silo problem that makes this boundary necessary, see [[multi-agent-orchestration-a2a/chapter-01|Chapter 1: Why Your Best Agents Can't Talk to Each Other — and How A2A Fixes That]]. For the A2A wire format and task lifecycle that underpins every pattern in this chapter, see [[multi-agent-orchestration-a2a/chapter-02|Chapter 2: A2A Protocol Architecture — The Message Flow (2026)]].

> "A2A expands agent-to-agent collaboration, while MCP is growing into a foundational layer for context sharing, tool interoperability, and cross-framework coordination." — [Azure Blog, Microsoft](https://azure.microsoft.com/en-us/blog/agent-factory-connecting-agents-apps-and-data-with-new-open-standards-like-mcp-and-a2a)

---

## MCP Primitives: A Quick Primer

Before composing MCP with A2A, you need to know which MCP primitive to reach for. The spec defines three distinct server-side constructs with different execution models and trust surfaces.

**Tools** are callable functions with JSON Schema inputs. They execute actions — database reads, API calls, file writes — and return structured output via `tools/call`. They carry the highest security surface because they modify world state.

**Resources** are read-only data identified by URI. Exposed via `resources/list` and `resources/read`, they never modify state. Think of them as the context an agent pulls into its reasoning before acting: schemas, documentation, configuration, historical data.

> "Resources are read-only reference material — documentation, schemas, configuration, templates. They provide context that helps agents make better decisions. Where tools perform actions and prompts orchestrate workflows, resources serve information on request." — [MCP Prompts and Resources: The Primitives You're Not Using, dev.to](https://dev.to/aws-heroes/mcp-prompts-and-resources-the-primitives-youre-not-using-3oo1)

**Prompts** are server-supplied templates with typed arguments for standardizing how tools are invoked across agent implementations — useful for enforcing consistent call patterns at scale, though rare in current production deployments.

Most community MCP servers only implement tools. Resources are underused. This quality gap matters: tool-only agents spend context-window tokens on intermediate tool results that could be externalized as resources and resolved on demand. The Resource Injection pattern in this chapter closes that gap.

<KnowledgeCheck
  question="Which MCP primitive is the correct choice for supplying a database schema to a specialist before it runs queries?"
  answers={[
    "A Tool, because the orchestrator needs to call into the specialist's MCP server to push the schema",
    "A Resource, because schemas are read-only reference data that the specialist resolves by URI when needed",
    "A Prompt, because the schema defines how the specialist should structure its tool invocations",
    "None — schema context should always be embedded directly in the A2A task message body"
  ]}
  correct={1}
/>

---

## Advertising MCP-Backed Capabilities Without Misrepresenting MCP

When a specialist has MCP-backed capabilities, it must tell the network what it can do via its A2A Agent Card — without implying that orchestrators can directly access its MCP server. The correct framing is outcome-based, not implementation-based:

```json
{
  "skills": [
    {
      "id": "equity_price_history",
      "name": "Equity Price History",
      "description": "Returns OHLCV data for a given ticker and date range. Backed by local SQL database via MCP.",
      "tags": ["market-data", "sql", "time-series"],
      "inputModes": ["text/plain", "application/json"],
      "outputModes": ["application/json"]
    }
  ]
}
```

The `description` field may note MCP backing as a transparency signal — "Backed by local SQL database via MCP" tells orchestrators this is a fast local source rather than a slow external API. But the `url` in the Agent Card points to the agent's A2A endpoint, never to its MCP server. The MCP connection is the agent's private implementation. Orchestrators must not depend on it. Scoping MCP servers to their owning specialist agents also prevents a common context-rot failure: loading every tool from every agent into every agent's context window.

> "For multi-agent coding workspaces, scoping MCP servers to specialist agents avoids loading every tool into every agent's context window." — [A2A vs MCP, Augment Code](https://www.augmentcode.com/guides/a2a-vs-mcp)

---

## Tool Proxying: Agent A Uses Agent B's MCP-Backed Skills

Tool proxying is the pattern where an orchestrator (Agent A) needs a capability it does not own and obtains it by delegating over A2A to a specialist (Agent B). Agent B fulfils the request using its own MCP server. Agent A never holds Agent B's database credentials or MCP server address.

> "the agent does not need custom scraping code – it just 'calls the tool by name'" — [A2A+MCP Practical Guide, medium.com/fossible](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02)

The complete call chain: Orchestrator sends an A2A task → Agent B's A2A handler receives it → Agent B invokes `tools/call` on its local MCP server → SQLite returns rows → Agent B packages the result as an A2A artifact → Orchestrator receives it and forwards it downstream. Agent B's MCP invocation is opaque to the caller at every step.

```python
# Agent B (Market Data Specialist) — A2A handler that wraps an MCP tool call
async def handle_task(task: A2ATask) -> A2AArtifact:
    params = task.message.parts[0].data  # {"ticker": "AAPL", "start": "...", "end": "..."}
    results = await mcp_client.call_tool("query_price_history", params)
    return A2AArtifact(mimeType="application/json", data=results)
```

The reason to route through A2A rather than allowing direct MCP access is correctness, not convenience. Agent B maintains its own task lifecycle, authentication context, and failure-handling logic. An orchestrator that reaches directly into Agent B's MCP server bypasses Agent B's domain logic, couples itself to Agent B's internal implementation, and creates an authorization surface that neither agent owns cleanly. The A2A boundary prevents exactly this coupling.

<KnowledgeCheck
  question="Why does the orchestrator send an A2A task to Agent B rather than calling Agent B's MCP server directly?"
  answers={[
    "Because MCP operates on a different network port that firewall rules typically block at the agent boundary",
    "Because A2A maintains Agent B's task lifecycle and auth context — direct MCP access bypasses Agent B's domain logic and couples the orchestrator to its implementation",
    "Because A2A has lower latency than MCP for the short synchronous calls typical in tool proxying",
    "Because the MCP specification prohibits multiple clients from connecting to the same server simultaneously"
  ]}
  correct={1}
/>

---

## Resource Injection: Sharing Context Without Breaking Role Boundaries

Resource injection is the pattern where an orchestrator supplies context to a specialist — a schema, a constraint set, a prior research artifact — before the A2A task begins. The orchestrator cannot directly populate the specialist's context window; that would require knowledge of the specialist's internal structure. Instead, it writes context to a shared MCP server as a resource URI, and the specialist reads it on task start.

```python
# Orchestrator: store context before dispatching the A2A task
@server.tool()
async def store_research_context(task_id: str, schema: dict, constraints: dict) -> str:
    shared_state[task_id] = {"schema": schema, "constraints": constraints}
    return f"docs://{task_id}/context"
```

```python
# Specialist: read injected context before running tools
context = await mcp_client.read_resource(f"docs://{task_id}/context")
schema = context["schema"]
# validate query scope against schema, then invoke tools
```

> "your agents do not need to talk to each other, but should coordinate through shared infrastructure instead." — [Multi-agent systems with MCP, Pluralsight](https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI)

Role boundaries hold on both sides: the specialist does not know who wrote the context; the orchestrator does not know how the specialist will use it. Both interact with a canonical URI. The specialist remains autonomous; the orchestrator remains decoupled. Embedding large context directly in the A2A task message body inflates the payload and forces the specialist to load all of it into its context window immediately. Resource injection externalizes that data to a URI the specialist resolves on demand, with the option to cache repeated reads.

---

## The MCP-to-A2A Translation Layer

Four structural mismatches between MCP and A2A produce predictable failures when you compose them without deliberate handling:

| Mismatch | MCP assumption | A2A assumption | Production failure |
|----------|---------------|----------------|-------------------|
| **Latency** | Short synchronous calls (<2s) | Can be long-running and async | Wrapping a slow MCP call as a synchronous A2A response times out |
| **Error semantics** | JSON-RPC error: code + message | Structured `TaskFailedEvent` | Unhandled MCP errors surface as opaque A2A failures the orchestrator cannot recover from |
| **Cancellation** | No cancellation primitive | `tasks/cancel` | A long-running MCP tool call cannot be cancelled mid-flight; the A2A layer must manage timeouts externally |
| **Token scope** | Bearer token bound to MCP server | DPoP-bound per-agent identity | Agent B must never forward its MCP access token to Agent A — that grants the orchestrator direct MCP access under Agent B's identity |

<Callout type="warning">
  The token scope mismatch is the most dangerous failure mode. When Agent B proxies an MCP tool call on behalf of an orchestrator, it must mint a new, narrowly scoped OAuth 2.1 token per call — scoped to the specific MCP tool, not Agent B's full MCP access. An MCP gateway proxy (Gravitee, Pomerium, Kong AI Gateway) sitting between agents and MCP servers enforces per-agent, per-tool authorization at the network layer, independently of agent code. Direct tool calls also consume context tokens for every definition and result; agents that write code to call tools instead scale significantly better. ([Code execution with MCP, Anthropic Engineering](https://www.anthropic.com/engineering/code-execution-with-mcp) · [MCP Proxy: How It Works, Gravitee](https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one))
</Callout>

---

## Hands-On Exercise: Connect a Local MCP SQLite Server to an A2A Agent

**Time estimate:** 25 minutes

You will build a Market Data Specialist that wraps a local SQLite database as an MCP server, exposes an A2A endpoint for incoming tasks, and allows a remote Researcher agent to query the database through the specialist — without the Researcher ever touching the MCP server directly.

**Step 1 — Build the MCP server with FastMCP.**

```python
from mcp.server.fastmcp import FastMCP
import sqlite3

mcp = FastMCP("market-data-mcp")

@mcp.tool()
def query_price_history(ticker: str, start_date: str, end_date: str) -> list[dict]:
    """Fetch OHLCV data for a ticker and date range."""
    conn = sqlite3.connect("market_data.db")
    rows = conn.execute(
        "SELECT date, open, high, low, close, volume FROM prices "
        "WHERE ticker=? AND date BETWEEN ? AND ? ORDER BY date",
        (ticker, start_date, end_date)
    ).fetchall()
    return [dict(zip(["date","open","high","low","close","volume"], r)) for r in rows]

@mcp.resource("docs://schema")
def db_schema() -> str:
    """Exposes the database schema for Resource Injection."""
    return "Table: prices(ticker TEXT, date TEXT, open REAL, high REAL, low REAL, close REAL, volume INT)"
```

**Step 2 — Wrap the MCP tool call in an A2A task handler.**

```python
async def handle_task(task: A2ATask) -> A2AArtifact:
    params = task.message.parts[0].data
    results = await mcp_client.call_tool("query_price_history", params)
    return A2AArtifact(mimeType="application/json", data=results)
```

**Step 3 — From the Researcher agent, dispatch the A2A task.**

The Researcher has no direct MCP connection to the Specialist. The Agent Card's description field ("Backed by local SQL database via MCP") already tells the Researcher what capability it is delegating to. The Researcher passes only task parameters in the A2A message body.

```python
# Researcher: dispatch via A2A — no direct MCP connection to the Specialist's server
# The Agent Card description ("Backed by local SQL database via MCP") supplies all
# capability context; the Specialist resolves its own MCP resources internally.
task = await a2a_client.send_task(
    agent_url="http://localhost:8001",
    message=A2AMessage(parts=[DataPart(data={
        "ticker": "AAPL",
        "start_date": "2024-01-01",
        "end_date": "2024-12-31"
    })])
)
artifact = await a2a_client.await_task(task.id)
```

**Success criteria:**
- The Researcher's `a2a_client.send_task` call succeeds and returns a task ID
- The artifact contains a JSON array of OHLCV rows (not an error object)
- The Researcher holds no SQLite connection — all database access is via the Specialist's A2A endpoint
- Replacing the SQLite database with mock data on the Specialist side produces a correct artifact without any change to the Researcher's code

---

## What's Next

You now have tool-sharing and resource injection working across two A2A agents. The next challenge is choosing the right topology for orchestrating three or more of them — chains, hubs, and meshes each make different tradeoffs in bottleneck risk and coordination overhead.

[[multi-agent-orchestration-a2a/chapter-06|Chapter 6: Orchestration Patterns — Chains, Hubs, and Meshes]] maps those topologies, shows the Orchestrator Bottleneck failure mode in hub-and-spoke systems, and implements a peer-to-peer delegation pattern where agents hand off directly without routing back through a central coordinator.

---

*Sources: [AI Agent Protocol Ecosystem Map 2026, DigitalApplied](https://www.digitalapplied.com/blog/ai-agent-protocol-ecosystem-map-2026-mcp-a2a-acp-ucp) · [MCP Prompts and Resources, dev.to](https://dev.to/aws-heroes/mcp-prompts-and-resources-the-primitives-youre-not-using-3oo1) · [A2A+MCP Practical Guide, Fossible](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02) · [Multi-agent systems with MCP, Pluralsight](https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI) · [Code execution with MCP, Anthropic Engineering](https://www.anthropic.com/engineering/code-execution-with-mcp) · [MCP Proxy: How It Works, Gravitee](https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one) · [A2A vs MCP, Augment Code](https://www.augmentcode.com/guides/a2a-vs-mcp)*

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-06.md -->

```yaml
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8552
course: multi-agent-orchestration-a2a
chapter_num: 6
chapter_title: "Orchestration Patterns — Chains, Hubs, and Meshes"
slug: multi-agent-orchestration-a2a-chapter-06
description: "Every multi-agent workflow collapses into one of three topologies — linear chain, hub-and-spoke, or mesh — each with a distinct failure mode that only appears at scale. This chapter shows you how to identify the Orchestrator Bottleneck before it kills hub throughput, implement A2A-native Peer-to-Peer Delegation using contextId to preserve workflow lineage, and design a Dynamic Mesh where agents self-discover and join only when needed."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 50
reading_time_min: 13
last_updated: 2026-06-15
chapter_primary_query: "how to choose between chain hub-and-spoke and mesh orchestration patterns in A2A multi-agent systems"
first_60_words_answer: "Every multi-agent workflow maps to one of three topologies: Linear Chains sequence agents in order; Hub-and-Spoke routes all tasks through a central orchestrator; Fully Connected Meshes let every agent delegate directly to any other. Hub-and-Spoke is the most common entry pattern and also the most dangerous at scale — the central orchestrator becomes a bottleneck, a single point of failure, and a coordination tax on every step."
prerequisites_chapters: [4, 5]
learning_objectives:
  - Compare Linear Chain, Hub-and-Spoke, and Fully Connected Mesh architectures on throughput, failure modes, and coordination complexity
  - Identify the Orchestrator Bottleneck in Hub-and-Spoke systems and apply three concrete mitigation strategies before it becomes a production incident
  - Implement a Peer-to-Peer Delegation pattern where A2A agents collaborate without routing through a central orchestrator, using contextId to preserve lineage
  - Design a Dynamic Mesh where agents discover peers at runtime and join or leave the workflow based on task requirements
positions:
  - id: mcp-as-interoperability-moat
    engagement: neutral
tags: [A2A, multi-agent, orchestration, hub-and-spoke, peer-to-peer, dynamic-mesh, topology, linear-chain, orchestrator-bottleneck]
status: g0-passed
sources:
  - https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/ # retrieved 2026-05-12
  - https://a2a-protocol.org/latest/specification/ # retrieved 2026-05-12
  - https://github.com/a2aproject/A2A # retrieved 2026-05-12
  - https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade # retrieved 2026-05-12
  - https://github.com/a2aproject/A2A/releases/tag/v1.0.0 # retrieved 2026-05-12
  - https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform # retrieved 2026-05-12
  - https://a2a-protocol.org/latest/partners/ # retrieved 2026-05-12
faq:
  - question: "When should I use a Linear Chain over a Hub-and-Spoke?"
    answer: "Use a Linear Chain when the workflow is strictly sequential — every step depends entirely on the previous step's output, parallelism provides no benefit, and each agent only needs to know one downstream address. A chain's single advantage over hub-and-spoke is zero orchestrator overhead after the first dispatch. Hub-and-Spoke is the better default whenever you need conditional routing, parallel dispatch to multiple specialists, or the ability to recover and re-route a single failed step without restarting the chain. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "What is the Orchestrator Bottleneck and what are its three mitigation strategies?"
    answer: "The Orchestrator Bottleneck occurs when a central hub agent is the required routing point for every task in the workflow. As concurrent workflows increase, the orchestrator's task queue grows faster than its throughput. Three mitigations: (1) Direct P2P handoffs — authorize specialist agents to hand off to each other for known sequential sub-task pairs, eliminating round-trips through the hub; (2) Async dispatch — fire tasks in parallel with non-blocking A2A sends and collect results via push notifications rather than waiting for sequential completions; (3) Domain sub-orchestrators — promote domain-specialist agents to handle routing within their own domains, distributing the coordination tax. ([Gemini Enterprise Agent Platform, Google Cloud](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform))"
  - question: "How does A2A enable Peer-to-Peer Delegation without a central orchestrator?"
    answer: "A2A's task delegation primitives are symmetric — any A2A client can call SendMessage on any A2A server endpoint, regardless of who originated the workflow. The spec-defined contextId field propagates the original workflow session ID through every peer-to-peer handoff, so the originating Manager receives the final completion notification without having brokered the intermediate step. Before delegating, the Researcher validates the Writer's capability by fetching the Writer's Agent Card and confirming the required skill ID is listed — the same AgentCard-based capability check used for all A2A task dispatch. ([A2A GitHub repository](https://github.com/a2aproject/A2A))"
```

# Orchestration Patterns — Chains, Hubs, and Meshes

> **Chapter 6 of 10 · 50 min (prose ~13 min + 25 min hands-on exercise)**

Every multi-agent workflow maps to one of three topologies: Linear Chains sequence agents in order; Hub-and-Spoke routes all tasks through a central orchestrator; Fully Connected Meshes let every agent delegate directly to any other. Hub-and-Spoke is the most common entry pattern and also the most dangerous at scale — the central orchestrator becomes a bottleneck, a single point of failure, and a coordination tax on every step.

---

## The Three Topologies

The topology you choose determines where coordination complexity lives and which failure mode will hit you first. None is universally correct.

**Linear Chain**: Agent A passes output directly to Agent B, which passes to Agent C. Dependencies are strictly sequential — each agent starts only when its predecessor finishes. Coordination overhead is minimal: there is no central dispatcher, and each agent only needs to know one downstream address. The cost is inflexibility: a failure at any step halts the full chain, and adding a new agent mid-chain requires modifying two existing agents. Parallelism is structurally impossible.

**Hub-and-Spoke**: A central orchestrator (the hub) receives the top-level goal, decomposes it into sub-tasks, and dispatches each to a specialist (the spokes). All inter-agent communication routes through the hub. The hub holds global state, can re-route failed tasks, and provides a single point for monitoring. This topology maps to how humans think about delegation — one coordinator, many workers — which is why most teams default to it. The failure mode is the Orchestrator Bottleneck, covered next.

**Fully Connected Mesh**: Every agent can delegate directly to every other. No central coordinator exists. Coordination logic distributes across agents. A Researcher can hand off to a Writer; the Writer can invoke a Fact-Checker without looping back through a Manager. A **Dynamic Mesh** is the practical production variant: agents discover and join the workflow based on task requirements and leave when they are no longer needed, rather than maintaining full static connectivity.

| Topology | Throughput ceiling | Failure blast radius | Coordination knowledge |
|---|---|---|---|
| Linear Chain | Sequential only | Full chain halts | Agent N knows only agent N+1 |
| Hub-and-Spoke | Orchestrator queue depth | Hub is single point of failure | All routes known by hub only |
| Fully Connected Mesh | Per-agent × N agents | Single agent only | Every agent knows every other |

<KnowledgeCheck
  question="Which topology eliminates the orchestrator as a single point of failure?"
  answers={[
    "Hub-and-Spoke, because the hub maintains global workflow state and can re-route any failed spoke",
    "Linear Chain, because agents only communicate with their immediate successor and there is no central hub to fail",
    "Fully Connected Mesh, because orchestration logic distributes across agents rather than concentrating in one coordinator",
    "None — all A2A topologies require a designated orchestrator role defined in the A2A specification"
  ]}
  correct={2}
/>

---

## The Orchestrator Bottleneck

Hub-and-Spoke works until it doesn't. The failure arrives quietly: the hub's task queue grows faster than its dispatch throughput. Latency on every workflow step climbs as tasks wait for the orchestrator's attention. Add one high-cost specialist — an agent whose tasks take ten seconds to complete — and the hub serializes every workflow behind it, including workflows that have nothing to do with that specialist.

Three concrete mitigations address the bottleneck without abandoning hub-and-spoke. First, authorize direct P2P handoffs for known sequential sub-task pairs: if Researcher always hands off to Writer, route that specific transition peer-to-peer and eliminate one hub round-trip per workflow. Second, switch to async task dispatch: fire all parallel sub-tasks with non-blocking `SendMessage` calls (the A2A v1.0.0 operation name; the Python SDK exposes this as `send_task()`) and collect results via push notification endpoints — an A2A-spec mechanism — rather than blocking the hub waiting for sequential completions. Third, introduce domain sub-orchestrators: promote a domain-specialist agent to coordinate its own subdomain, distributing the routing tax across domain boundaries. The [Gemini Enterprise Agent Platform](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform) demonstrates this pattern at scale, distributing orchestration across domain-specific coordinators rather than a single hub.

<Callout type="warning">
  Add async push notification handling to your hub before adding your third spoke — retrofitting it later requires updating every specialist's response path. The Orchestrator Bottleneck is a throughput problem first and a reliability problem second; teams typically discover it after the fourth specialist, not the second, when concurrent workflow load finally exceeds hub queue depth. ([A2A Specification v1.0.0, push notification model](https://a2a-protocol.org/latest/specification/) · [A2A v1.0.0 Release Notes](https://github.com/a2aproject/A2A/releases/tag/v1.0.0))
</Callout>

---

## Peer-to-Peer Delegation

A2A's delegation primitives are symmetric by spec design: any A2A client can call `SendMessage` on any A2A server endpoint. The [A2A specification](https://a2a-protocol.org/latest/specification/) does not restrict delegation to originate from a designated orchestrator role. This symmetry makes P2P delegation a first-class pattern rather than a workaround.

In P2P delegation, the Researcher completes its sub-task and issues a `SendMessage` to the Writer's A2A endpoint directly, attaching the research artifact as context. The Manager never loses visibility — the A2A spec's `contextId` field propagates the original workflow session ID through the handoff, so the Manager receives the Writer's completion notification without having brokered the intermediate step.

```python
# Researcher: complete work, then delegate to Writer — no Manager round-trip
async def complete_and_delegate(task: A2ATask, research_artifact: dict):
    writer_card = await a2a_client.fetch_agent_card(WRITER_URL)
    # Spec-grounded: capability check via Agent Card before delegation (see Ch 4)
    assert "content-synthesis" in [s["id"] for s in writer_card["skills"]]

    handoff = await a2a_client.send_task(
        agent_url=WRITER_URL,
        message=A2AMessage(
            parts=[DataPart(data=research_artifact)],
            contextId=task.contextId,         # A2A spec field; propagates lineage
            metadata={"upstream_task": task.id}  # convention, not A2A-mandatory
        )
    )
    await a2a_client.complete_task(task.id, artifact={"delegated_to": handoff.id})
```

Note the separation: `contextId` is a spec-defined field that any A2A-compliant implementation must support. The `metadata.upstream_task` key is a production convention — useful for downstream tracing but not part of the wire protocol.

<KnowledgeCheck
  question="What A2A spec field preserves workflow session lineage when the Researcher delegates directly to the Writer without returning through the Manager?"
  answers={[
    "The task id, which both agents must set to the same value to signal membership in the same workflow session",
    "The contextId field, which the spec defines to propagate the originating session ID through every delegation hop",
    "The Agent Card provider field, which links all agents from the same organization into a shared lineage namespace",
    "There is no built-in A2A field for this — lineage across P2P handoffs requires a custom header from the original orchestrator"
  ]}
  correct={1}
/>

---

## The Dynamic Mesh

A Dynamic Mesh removes the pre-wired topology entirely. Instead of a static graph of known agents, each agent queries a registry — an AGNTCY-style global index or a local agent pool — for a peer satisfying a required capability, fetches that peer's Agent Card at runtime, validates the skill match, and delegates. Agents leave the workflow when their tasks complete rather than idling in a static configuration. The [Google A2A announcement](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) describes this as the long-term model for the Internet of Agents: agents that are sovereign, discoverable, and composable without pre-registration in any specific workflow.

The trade-off is observability. When any agent can reach any other, tracing actual delegation sequences requires propagating `contextId` and trace IDs through every hop — covered in Chapter 9. Architecture convention, not A2A spec, governs how teams enforce this: common practice is to require trace-ID headers at the MCP gateway layer so they are added regardless of individual agent implementation.

---

## Hands-On Exercise: Hub-and-Spoke to Peer-to-Peer Refactor

**Time estimate:** 25 minutes

Build a 3-agent Hub-and-Spoke system, then refactor it so the Researcher hands off directly to the Writer without a Manager round-trip.

**Step 1 — Hub-and-Spoke baseline.**

```python
# Manager: dispatch Researcher, collect result, dispatch Writer
async def manager_workflow(goal: str) -> dict:
    research_task = await a2a_client.send_task(
        agent_url=RESEARCHER_URL,
        message=A2AMessage(parts=[TextPart(text=goal)])
    )
    research = await a2a_client.await_task(research_task.id)

    write_task = await a2a_client.send_task(
        agent_url=WRITER_URL,
        message=A2AMessage(parts=[DataPart(data=research.artifact)])
    )
    return (await a2a_client.await_task(write_task.id)).artifact
```

**Step 2 — Refactor: Researcher delegates to Writer directly.**

```python
# Researcher: run work, then delegate — Manager is not in the handoff path
async def handle_task(task: A2ATask) -> None:
    result = await run_research(task.message.parts[0].text)
    await a2a_client.send_task(
        agent_url=WRITER_URL,
        message=A2AMessage(
            parts=[DataPart(data=result)],
            contextId=task.contextId,
            metadata={"upstream_task": task.id}
        )
    )
    await a2a_client.complete_task(task.id, artifact={"delegated": True})
```

**Step 3 — Manager: switch to awaiting the Writer's completion, not the Researcher's artifact.**

Update `manager_workflow` to dispatch only the Researcher and then listen for the Writer's push notification. The Manager fires one dispatch; the Researcher fires the second.

**Success criteria:**
- Manager calls `send_task` exactly once (to Researcher). It does not call `send_task` to Writer — the Researcher does.
- The Writer's final artifact reaches the Manager via push notification, not via a Manager-initiated `tasks/get` after the Researcher completes.
- The `contextId` on the Writer's task matches the `contextId` on the Researcher's original task — proving lineage continuity through the P2P handoff.
- Replacing the Researcher with a stub that calls Writer directly delivers the correct artifact to the Manager without any Manager code changes.

---

## What's Next

You now have working topologies from hub-and-spoke to peer-to-peer delegation. The next challenge is what happens when agents or the network fail mid-workflow: checkpointing, distributed state management, and the A2A patterns for resuming work after a partial failure.

[[multi-agent-orchestration-a2a/chapter-07|Chapter 7: Resilience, State, and Asynchrony]] implements checkpointing for long-running workflows and shows how the Two-Phase Commit problem surfaces in agentic negotiations.

---

*Sources: [A2A Announcement, Google Developers Blog](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) · [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [A2A v1.0.0 Release Notes](https://github.com/a2aproject/A2A/releases/tag/v1.0.0) · [Gemini Enterprise Agent Platform, Google Cloud](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform)*

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-07.md -->

```yaml
chapter_num: 7
course_slug: multi-agent-orchestration-a2a
title: "Resilience, State, and Asynchrony"
description: "Fire-and-forget fails in multi-agent systems because downstream agent state cannot be replayed. This chapter shows how to implement A2A checkpointing, minimal-sufficient context passing, and idempotent retry to build workflows that survive network failures and agent crashes."
status: g0-passed
last_updated: 2026-06-15
duration_min: 45
vendor_tag: Google A2A
learning_objectives:
  - "Implement checkpointing at natural A2A task lifecycle boundaries so long-running workflows can resume without re-executing completed legs"
  - "Design a distributed context management strategy that passes minimal sufficient structured data across agent handoffs"
  - "Explain the two-phase commit problem in agentic negotiations and how a pre-advance checkpoint prevents unknown-state crashes"
  - "Implement idempotent retry with exponential backoff for A2A task submissions"
sources:
  - url: "https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/" # retrieved 2026-06-15
    title: "A2A: A New Era of Agent Interoperability (Google Developers Blog)"
  - url: "https://a2a-protocol.org" # retrieved 2026-06-15
    title: "A2A Protocol Specification"
  - url: "https://github.com/a2aproject/A2A" # retrieved 2026-06-15
    title: "A2A Protocol GitHub Repository"
  - url: "https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade" # retrieved 2026-06-15
    title: "Agent2Agent Protocol Is Getting an Upgrade (Google Cloud Blog)"
  - url: "https://github.com/a2aproject/A2A/releases/tag/v1.0.0" # retrieved 2026-06-15
    title: "A2A Protocol v1.0.0 Release Notes (GitHub)"
  - url: "https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform" # retrieved 2026-06-15
    title: "Introducing Gemini Enterprise Agent Platform (Google Cloud Blog)"
owns:
  - "Checkpointing for long-running multi-agent workflows"
  - "Distributed context management to avoid context loss during agent handoffs"
  - "Two-phase commit problem in agentic negotiations and A2A-style task state recovery"
  - "Retry with backoff for agentic message passing"
  - "State store (Redis or file-based) checkpoint-resume pattern"
defers_to:
  - "DPoP authentication and delegated trust models → ch8"
  - "Distributed tracing and observability tooling → ch9"
  - "Full capstone multi-agent integration → ch10"
quiz_topics:
  - "Agent Checkpoints"
  - "Context Windows"
  - "Distributed State"
  - "Async Handshakes"
  - "Failure Recovery"
notebooklm_source_focus:
  - "A2A async task lifecycle"
  - "checkpointing patterns"
  - "distributed state management"
word_budget: { min: 800, max: 1200 }
tags: [A2A, resilience, checkpointing, distributed-state, retry, exponential-backoff, two-phase-commit, agentic-workflows]
positions:
  - audit-trail-as-enterprise-gate
chapter_primary_query: "how to make A2A multi-agent workflows resilient to network failures and agent crashes"
first_60_words_answer: "A2A multi-agent workflows survive crashes and network failures by checkpointing task IDs at three protocol boundaries, passing minimal structured context across handoffs, and submitting tasks with a stable pre-generated ID that lets compliant servers deduplicate retries. These three patterns — checkpoint, context compression, and idempotent retry — separate a fire-and-forget chain from a recoverable workflow."
quiz:
  - question: "Which event in the A2A task lifecycle marks the safest point to write a checkpoint before advancing the orchestrator's workflow?"
    options:
      - "When the task is first submitted to the downstream agent"
      - "When the downstream agent returns a task_id confirming task acceptance"
      - "When the downstream agent's PushNotification fires with a progress event"
      - "When the orchestrator's retry timer expires without receiving a response"
    correct_idx: 1
    explanation: "Receiving the task_id confirms Phase 1 success — the downstream agent accepted the task. Writing the checkpoint at this point ensures that a crash after the advance can be detected and retried safely. Writing before the task_id arrives (option A) leaves the orchestrator uncertain whether the task was ever received."
    section_anchor: agent-checkpoints-what-to-save-and-when
  - question: "What does the 'Minimal Sufficient Context' principle require an orchestrator to pass to a downstream specialist?"
    options:
      - "A full chain-of-thought transcript from every upstream agent in the workflow"
      - "Only the structured facts and artifacts the downstream agent needs for its role"
      - "A compressed token summary of all prior agent reasoning steps and outputs"
      - "The complete agent card of every agent that ran before the specialist"
    correct_idx: 1
    explanation: "Minimal Sufficient Context means passing structured, role-relevant facts — not reasoning transcripts or full upstream history. Forwarding reasoning logs bloats the context window and inflates costs without benefiting the downstream agent's specific task."
    section_anchor: distributed-context-management
  - question: "In an A2A two-phase commit pattern, what is the consequence of advancing workflow state before writing the checkpoint?"
    options:
      - "The downstream agent revokes the task and requires a fresh negotiation round"
      - "A crash between those two steps leaves the orchestrator with unknown task state"
      - "The checkpoint write permanently overwrites the downstream agent's working state"
      - "The retry policy fires immediately, causing duplicate task submissions at Phase 1"
    correct_idx: 1
    explanation: "If the orchestrator advances state before writing the checkpoint and then crashes, it cannot determine on restart whether the downstream agent accepted the task. This is the classic 2PC 'commit-before-log' failure: the coordinator loses the ability to distinguish 'task accepted, not yet checkpointed' from 'task never submitted'."
    section_anchor: the-two-phase-commit-problem-in-agentic-negotiations
  - question: "What is the primary purpose of generating an A2A task_id once before the first submission attempt?"
    options:
      - "It ensures A2A task IDs follow a monotonically increasing integer sequence"
      - "It lets the server detect duplicate submissions and return the existing task record"
      - "It signals the server that the request comes from a single trusted orchestrator"
      - "It prevents the backoff timer from resetting between consecutive retry attempts"
    correct_idx: 1
    explanation: "A stable, pre-generated task_id acts as an idempotency key. A compliant A2A server that receives the same task_id twice can return the existing task's state rather than spawning a duplicate task. Generating a new ID on each retry defeats this deduplication and risks running the downstream agent's logic more than once."
    section_anchor: retry-with-backoff-for-agentic-message-passing
faq:
  - question: "When should I write a checkpoint in an A2A workflow?"
    answer: "Write a checkpoint at each of the three natural A2A protocol event boundaries: after the downstream agent returns a task_id confirming task acceptance, after task completion when the status endpoint returns completed with artifacts, and at each agent handoff boundary. The [A2A Protocol Specification](https://a2a-protocol.org) defines task lifecycle transitions (submitted → working → completed/failed) as deterministic points where the orchestrator knows the system's authoritative state. Writing the checkpoint immediately after receiving the task_id — before advancing the workflow — ensures that a crash between phases can be detected and replayed without causing double-execution of the downstream agent's logic."
  - question: "What is the 'Minimal Sufficient Context' principle and why does it matter for agentic pipelines?"
    answer: "Minimal Sufficient Context means passing only the structured facts a downstream agent needs for its specific role — never a transcript of upstream reasoning steps. When an orchestrator forwards 8,000-token reasoning logs, receiving agents exhaust context windows before processing their actual task, inflating costs and creating a failure mode where the downstream agent reasons from your interpretation of events rather than the events themselves. The [A2A Protocol Specification](https://a2a-protocol.org) provides the context field in the task payload precisely for passing versioned, machine-readable state blobs that a resumed agent can deserialize directly without re-reasoning from prose transcripts."
  - question: "How does a pre-generated task_id prevent duplicate execution in A2A retries?"
    answer: "A2A tasks carry a client-provided id field. Generating this ID once before the first submission attempt and reusing it on every retry turns it into an idempotency key. A compliant A2A server that receives a task_id it has already processed returns the existing task's state instead of spawning a second execution — confirmed by the [A2A GitHub repository](https://github.com/a2aproject/A2A) as a core protocol design choice. Generating a fresh UUID on each retry defeats deduplication entirely: the server sees each request as a new task and may run the downstream agent's logic multiple times, producing conflicting outputs and double-charging for the same work."
```

# Resilience, State, and Asynchrony

## Why Fire-and-Forget Fails Agents

A2A multi-agent workflows survive crashes and network failures by checkpointing task IDs at three protocol boundaries, passing minimal structured context across handoffs, and submitting tasks with a stable pre-generated ID that lets compliant servers deduplicate retries. These three patterns — checkpoint, context compression, and idempotent retry — separate a fire-and-forget chain from a recoverable workflow.

When Agent A hands off to Agent B, and B crashes 90 seconds into a 10-minute synthesis chain, you don't just lose a request. You lose everything B had processed up to that point. Restarting from scratch re-executes the most expensive work in the system and doubles the token spend.

This is why the contrarian principle here is blunt: fire-and-forget is an event-log pattern, not an agentic pattern. The [A2A Protocol Specification](https://a2a-protocol.org) was designed from first principles to be stateful — the full task model is detailed in [[chapter-02]]. Every task carries a lifecycle — `submitted → working → completed/failed` — every interaction carries a `context` field, and the specification explicitly supports asynchronous notifications via a `PushNotificationService` endpoint. According to the [A2A launch announcement](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/), these design choices reflect an "agentic-first" principle where agents delegate tasks autonomously and expect structured, resumable interactions — not ephemeral request/response pairs. These aren't nice-to-haves; they are the skeleton of a resumable system.

## Agent Checkpoints: What to Save and When

A checkpoint is a durable snapshot of workflow state at a meaningful transition point. The goal is to define "last known good" — the position from which you can safely resume without re-executing already-committed agent work.

In an A2A-aligned architecture, three natural checkpoint boundaries map to protocol events:

1. **Task submission acknowledgment** — the orchestrator receives a `task_id` back from the downstream agent. Save this ID to your state store before doing anything else.
2. **Task completion** — when `GET /tasks/{task_id}` returns `completed`, checkpoint the resulting artifacts.
3. **Handoff boundary** — when Agent A transfers its artifact to Agent B, checkpoint which agent has custody and what payload was transferred.

<KnowledgeCheck
  question="What does A2A's task lifecycle transition to after a remote agent accepts work but before it completes?"
  options={["submitted", "working", "delegated", "committed"]}
  correctIdx={1}
  explanation="A2A task status moves from 'submitted' (agent accepted the task) to 'working' (actively processing) before resolving to 'completed' or 'failed'. There is no 'delegated' or 'committed' status in the A2A specification."
/>

Checkpoints need a backing store. For local development, a JSON file works. In production, Redis is the standard choice: keys expire automatically, operations are atomic, and pub/sub can trigger resume logic when a checkpoint is written.

```python
import redis, json
from datetime import datetime

r = redis.Redis(host="localhost", port=6379, decode_responses=True)

def save_checkpoint(workflow_id: str, step: str, task_id: str, artifact: dict) -> None:
    key = f"workflow:{workflow_id}:{step}"
    r.set(key, json.dumps({
        "task_id": task_id,
        "artifact": artifact,
        "saved_at": datetime.utcnow().isoformat(),
    }))

def load_checkpoint(workflow_id: str, step: str) -> dict | None:
    val = r.get(f"workflow:{workflow_id}:{step}")
    return json.loads(val) if val else None
```

## Distributed Context Management

When an orchestrator chains agents, each agent builds up local context: tool outputs, intermediate reasoning, structured summaries. The naive approach — forwarding the full context in every message — burns token budget and creates a subtle failure mode: the receiving agent gets *your interpretation* of what happened, not the structured facts themselves.

A2A's `context` field in the task payload provides the hook for passing structured context forward. Instead of embedding a free-text summary in the task's `params`, use `context` to carry versioned state blobs that a resumed agent can deserialize directly, without reasoning from a transcript.

The guiding principle is **Minimal Sufficient Context**: pass only the facts a downstream agent needs to perform its own role, not a transcript of what happened upstream. If the Researcher agent produced 15 structured market events, the Writer agent does not need the Researcher's chain-of-thought — it needs those 15 events in a machine-readable format. The orchestration patterns that produce multi-agent chains — covered in [[chapter-06]] — assume each specialist receives exactly the information it needs, not a full transcript of upstream activity.

<Callout type="warning">
Context bloat is a silent budget killer. An orchestrator that forwards 8,000-token reasoning transcripts to every specialist will exhaust model context windows and inflate costs before the workflow finishes. Pass structured data, not reasoning logs.
</Callout>

## The Two-Phase Commit Problem in Agentic Negotiations

Database transactions use two-phase commit (2PC) to coordinate state changes across distributed nodes: Phase 1 is "prepare" (participants vote yes/no), Phase 2 is "commit" (coordinator issues the final directive). A2A task negotiation follows this structure precisely.

Phase 1 in A2A is the capability negotiation: the orchestrator POSTs a task, the downstream agent checks its `Agent Card`, and either accepts (returns `submitted` status plus a `task_id`) or rejects (returns `failed`). This is the vote. Phase 2 is the commit: the orchestrator receives the `task_id`, writes the checkpoint, and advances the workflow.

The failure mode that breaks this pattern is advancing state *before* confirming Phase 1 succeeded. If Agent B's network request times out with no status returned, the orchestrator does not know whether B received the task. Without a checkpoint, retrying the request risks double-execution — Agent B runs the same synthesis twice, potentially charging twice and producing conflicting outputs.

<KnowledgeCheck
  question="In an A2A-aligned two-phase commit, what is the correct order of operations for the orchestrator?"
  options={[
    "Submit task → receive task_id → advance workflow → write checkpoint",
    "Submit task → receive task_id → write checkpoint → advance workflow",
    "Write checkpoint → submit task → receive task_id → advance workflow",
    "Submit task → advance workflow → write checkpoint → receive task_id"
  ]}
  correctIdx={1}
  explanation="The checkpoint must be written after receiving the task_id (confirming Phase 1 success) but before advancing the workflow (Phase 2). Advancing first creates a window where a crash leaves the workflow in an unknown state with no recoverable record of Phase 1's outcome."
/>

## Retry with Backoff for Agentic Message Passing

Not every failure is a crash. Network blips, transient 503 responses, and model timeouts are more common than hard crashes, and they respond well to retry with exponential backoff.

The critical constraint for agentic retries is **idempotency**: retrying a task submission must not produce duplicate side effects. A2A v1.0.0 [confirms the client-provided `id` field](https://github.com/a2aproject/A2A/releases/tag/v1.0.0) as a stable API contract — generate this ID before the first submission attempt and reuse it on every retry. A compliant A2A server detects the duplicate and returns the existing task's state rather than spawning a second task.

```python
import time, uuid, httpx

def submit_with_backoff(agent_url: str, payload: dict, max_retries: int = 4) -> dict:
    task = {"id": str(uuid.uuid4()), **payload}  # ID generated once, reused on retries
    for attempt in range(max_retries):
        try:
            resp = httpx.post(f"{agent_url}/tasks", json=task, timeout=30)
            resp.raise_for_status()
            return resp.json()
        except (httpx.HTTPError, httpx.TimeoutException) as exc:
            wait = min(2 ** attempt + 0.1 * attempt, 30)
            if attempt < max_retries - 1:
                time.sleep(wait)
            else:
                raise RuntimeError(f"Agent unreachable after {max_retries} attempts") from exc
```

Cap the backoff at ~30 seconds and add a small jitter multiplier (`0.1 * attempt`) to prevent thundering-herd behavior when a shared downstream agent recovers and all orchestrators retry simultaneously.

## Hands-On: Checkpoint-Resume After a Network Failure

Simulate a 3-agent workflow — Researcher → Analyst → Writer — where the middle agent crashes mid-execution, then resume from the last checkpoint.

**Setup:** Run a local Redis instance with `docker run -p 6379:6379 redis:7-alpine`. Implement three minimal A2A-style agents as HTTP servers. Use `save_checkpoint` / `load_checkpoint` from the snippet above to persist each leg's output.

**Failure injection:** After the Researcher's artifact is checkpointed but before the Analyst finishes, send `SIGKILL` to the Analyst process. The orchestrator should detect the failure via a timeout on `GET /tasks/{analyst_task_id}`.

**Success criteria:**

- The orchestrator loads the Researcher checkpoint from Redis without re-calling the Researcher agent.
- A fresh Analyst process is spawned with the checkpointed Researcher artifact as input.
- The Writer receives the correct final artifact and completes normally.
- The total token spend for the resumed run covers only the Analyst and Writer legs — Researcher work is not re-executed.
- For environments without Docker, substitute Redis with a JSON file and `fcntl`-based locking to prevent concurrent writes from corrupting the checkpoint.

When your resume path passes this test, the workflow survives the 5-minute network blips that production guarantees will eventually arrive.

---

Next: lock down the channel itself. [[chapter-08]] covers DPoP-bound token signing, delegated trust chains, and prompt-injection defenses for inter-agent A2A messages.

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-08.md -->

```yaml
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8560
course: multi-agent-orchestration-a2a
chapter_num: 8
title: "Secure Communication — Auth, DPoP, and Trust Models"
slug: multi-agent-orchestration-a2a-chapter-08
description: "Encrypted channels are table stakes. This chapter layers application-level token binding with DPoP, delegated trust chains via OAuth 2.0 Token Exchange, network-layer agent sandboxing, and zero-trust sanitization of every incoming A2A message — so Agent B can verify not just who Agent A is, but what the user actually authorized."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 55
reading_time_min: 15
last_updated: 2026-06-15
chapter_primary_query: "how to secure A2A agent-to-agent communication with DPoP tokens, delegated trust chains, and prompt injection defenses"
first_60_words_answer: "Layer three independent guarantees to secure A2A communication: TLS or mTLS for transport identity, DPoP for application-layer token binding (a stolen token is worthless without the matching private key), and OAuth 2.0 Token Exchange for delegated trust chain verification — Agent B cryptographically confirms the user authorized Agent A's delegation. Treat every incoming task payload as untrusted regardless of caller identity."
prerequisites_chapters: [2]
learning_objectives:
  - Implement DPoP-bound OAuth tokens as an application-layer hardening pattern on top of A2A's security declaration model, correctly framing DPoP as an OAuth 2.0 extension rather than an A2A-native feature
  - Design a delegated trust chain using OAuth 2.0 Token Exchange so Agent B can cryptographically verify the user authorized Agent A's specific delegation
  - Describe the A2A spec's security surface (AgentCard securitySchemes, header-only credentials, Agent Card access controls) versus implementation hardening patterns
  - Implement a security middleware layer that validates identity, scope, replay protection, and prompt injection before handing an inbound A2A task to the agent's LLM core
tags: [A2A, security, DPoP, OAuth, mTLS, delegated-trust, prompt-injection, zero-trust, agent-sandboxing, token-exchange]
status: g0-passed
positions: [audit-trail-as-enterprise-gate]
sources:
  - url: "https://tyk.io/learning-center/a2a-protocol-architecture-and-technical-specification"
    title: "Tyk: A2A Protocol Architecture and Technical Specification"
    retrieved: "2026-06-15"
  - url: "https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security"
    title: "Red Hat Developer: How to Enhance A2A Security"
    retrieved: "2026-06-15"
  - url: "https://datatracker.ietf.org/doc/html/rfc9449"
    title: "RFC 9449: OAuth 2.0 Demonstrating Proof of Possession (DPoP)"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/dpop-rfc-9449-explained"
    title: "WorkOS: DPoP (RFC 9449) Explained"
    retrieved: "2026-06-15"
  - url: "https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf"
    title: "OpenID Foundation: Identity Management for Agentic AI"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/ai-agent-credentials"
    title: "WorkOS: Securing Agentic Apps — AI Agent Credentials"
    retrieved: "2026-06-15"
  - url: "https://www.diagrid.io/blog/making-agent-to-agent-a2a-communication-secure-and-reliable-with-dapr"
    title: "Diagrid: Making A2A Communication Secure with Dapr"
    retrieved: "2026-06-15"
  - url: "https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/"
    title: "Microsoft Open Source: Introducing the Agent Governance Toolkit"
    retrieved: "2026-06-15"
  - url: "https://cloudsecurityalliance.org/blog/2026/02/02/the-agentic-trust-framework-zero-trust-governance-for-ai-agents"
    title: "Cloud Security Alliance: The Agentic Trust Framework"
    retrieved: "2026-06-15"
quiz:
  - question: "DPoP (RFC 9449) is best described as:"
    options:
      - "An A2A-native feature mandated by the v1.0 spec for all compliant agent deployments"
      - "An OAuth 2.0 extension that sender-constrains bearer tokens to the holder's private key"
      - "A TLS extension that replaces mutual certificate exchange with lightweight per-request JWT proofs"
      - "A JSON Web Token profile in the A2A specification used for signing AgentCard payloads at publication"
    correct_idx: 1
    explanation: "DPoP is defined in RFC 9449 as an OAuth 2.0 extension — not part of the A2A protocol. The A2A spec's enterprise guidance endorses it alongside mTLS-bound tokens as a higher-assurance alternative to plain bearer tokens, but mandates neither. A2A's security is at the declaration layer (securitySchemes); DPoP is a hardening choice layered on top."
    section_anchor: dpop-sender-constraining-bearer-tokens

  - question: "The scope attenuation invariant in delegated agent authorization means:"
    options:
      - "Agent B must request the union of its own and Agent A's scopes to ensure full task coverage"
      - "Agent B's effective scope is the intersection of its role and Agent A's delegation — permissions only narrow"
      - "The authorization server grants Agent B all user-level scopes to prevent permission gaps in the chain"
      - "Scope constraints apply only at token-request time; once issued, tokens carry the full delegating agent's authority"
    correct_idx: 1
    explanation: "Scope attenuation requires that each delegation hop can only shrink, not grow, the permission set. Agent B's effective authority is intersection(B's own role, A's delegated scope). This prevents a compromised or over-requesting sub-agent from escalating to permissions its role was never individually authorized to hold."
    section_anchor: delegated-trust-proving-the-user-authorized-the-chain

  - question: "Prompt injection is structurally worse in A2A multi-agent systems than in single-agent systems because:"
    options:
      - "Each additional agent adds untrusted message boundaries, multiplying injection opportunities beyond what classifiers can reliably scan"
      - "The A2A spec omits injection defenses entirely, so no standard detection tooling exists for inter-agent message payloads"
      - "Peer-agent messages carry implicit trust, so one successful injection propagates through every downstream agent that handles the output"
      - "A2A's JSON-RPC framing lacks content-type headers, so injection-detection middleware has no standard field to inspect in payloads"
    correct_idx: 2
    explanation: "Receiving agents tend to treat peer-agent messages as more trusted than user input — the exact inverse of what security requires. An injected instruction in one agent's output can silently propagate if downstream agents don't validate task content as untrusted input at every hop. The structural amplification is why zero-trust per-message validation is required."
    section_anchor: prompt-injection-via-a2a-messages

  - question: "What does the A2A spec define in the AgentCard securitySchemes field?"
    options:
      - "The exact OAuth token endpoint URL and required DPoP key algorithm all callers must implement"
      - "The authentication scheme families the agent accepts (OAuth2, mTLS, OIDC, API key) in OpenAPI format"
      - "A mandatory JWKS discovery endpoint for callers to verify the AgentCard's cryptographic signature before trusting it"
      - "The minimum TLS version and cipher suite required for all transport-layer connections to the agent"
    correct_idx: 1
    explanation: "The A2A spec reuses the OpenAPI Security Scheme format verbatim. It declares which scheme families the agent accepts and which scopes are required per skill — but says nothing about how to obtain tokens, which OAuth flow to use, or what key algorithm callers must provide. Those implementation choices are left entirely to deploying organizations."
    section_anchor: what-the-a2a-spec-actually-defines

  - question: "Network-layer agent sandboxing is categorically stronger than prompt-layer access policy because:"
    options:
      - "Network rules appear in auditable infrastructure logs while prompt-layer policies live only inside volatile LLM context"
      - "Network-blocked resources are unreachable regardless of what the LLM reasons, imagines, or is prompted to attempt"
      - "Prompt-layer policies add latency to every LLM inference call while network packet filtering imposes near-zero overhead"
      - "The A2A v1.0 specification explicitly mandates network-layer enclave isolation for all agents in production by default"
    correct_idx: 1
    explanation: "An LLM can potentially reason around or be prompted to override a system-prompt access restriction. A resource that is genuinely unreachable at the network layer — because no route exists — cannot be accessed regardless of the LLM's reasoning or injected instructions. Network-layer containment is enforced outside the agent's own control plane."
    section_anchor: agent-sandboxing-and-trust-tiers
faq:
  - question: "What exactly does DPoP prevent that plain bearer tokens don't?"
    answer: "A plain bearer token is reusable by any party that intercepts it — equivalent to a door key that works in any lock. A DPoP-bound token contains a cnf.jkt claim: a SHA-256 fingerprint of the caller's JWK public key. The resource server verifies that the caller can sign a fresh proof JWT with the matching private key on every request. Without the private key (which only the legitimate agent holds and never transmits), the stolen token is rejected every time. ([RFC 9449: OAuth 2.0 DPoP](https://datatracker.ietf.org/doc/html/rfc9449))"
  - question: "How does OAuth 2.0 Token Exchange prove user authorization across an agent chain?"
    answer: "RFC 8693 Token Exchange lets Agent A obtain a new token T2 by presenting its existing token T1 at the authorization server's token endpoint. T2 is narrowly scoped to Agent B's specific skill and carries an act claim identifying Agent A as delegating party. When Agent B receives T2, it can verify the full chain — the sub claim names the original user, the act claim names Agent A, and the scope is bounded to exactly what Agent A was authorized to delegate. Neither Agent B's nor Agent A's permissions can exceed what T2's scope allows. ([OpenID Foundation: Identity Management for Agentic AI](https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf))"
  - question: "Does the A2A spec require Agent Cards to be cryptographically signed?"
    answer: "No. As of A2A v1.0, the spec supports card signing (added in v0.3+) but does not mandate it. An unsigned AgentCard served from a compromised DNS or CDN record can be spoofed to redirect callers to a malicious endpoint with a fabricated capability set. Production deployments should either sign cards with a verifiable key or serve them exclusively from mTLS-authenticated endpoints. ([Red Hat Developer: How to Enhance A2A Security](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security))"
```

# Secure Communication — Auth, DPoP, and Trust Models

> **Chapter 8 of 10 · 55 min (prose ~15 min + 25 min hands-on)**

---

## Encrypted Channels Are Table Stakes

Layer three independent guarantees to secure A2A communication: TLS or mTLS for transport identity, DPoP for application-layer token binding (a stolen token is worthless without the matching private key), and OAuth 2.0 Token Exchange for delegated trust chain verification — Agent B cryptographically confirms the user authorized Agent A's delegation. Treat every incoming task payload as untrusted regardless of caller identity. TLS alone achieves only the first layer: it does nothing about stolen tokens, hallucinated authorizations, or prompt injection delivered through the task payload. This chapter builds all three.

---

## What the A2A Spec Actually Defines

The A2A spec's security model is a **declaration layer only**. Three things are spec-grounded (the AgentCard format itself was covered in [[chapter-02.md]]):

1. **AgentCard `securitySchemes`:** Every agent card publishes which authentication scheme families it accepts — OAuth2, API key, mTLS, or OIDC — using the OpenAPI Security Scheme format verbatim. The [Tyk A2A architecture guide](https://tyk.io/learning-center/a2a-protocol-architecture-and-technical-specification) quotes the spec pattern directly: agents bind each skill to required scopes in a `security` block.
2. **Credentials in HTTP headers only.** Authorization material goes in the `Authorization` header on each A2A call — never embedded in JSON-RPC params, where it would appear in structured message traces.
3. **Agent Card endpoints must be access-controlled.** Per the [Red Hat A2A security analysis](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security): *"The specification establishes that the Agent Card endpoint must be protected by appropriate access controls such as authentication, mTLS, network restrictions."* An unprotected card leaks your entire capability and routing surface.

What the spec leaves to implementers: how tokens are obtained, whether cards are signed, how the delegation chain from user to Agent A to Agent B is structured, and all prompt injection defenses.

<KnowledgeCheck question="Where does the A2A spec require credentials to be placed?" options={["Embedded in JSON-RPC method params alongside the task identifiers and skill IDs", "In the HTTP Authorization header attached to every outbound A2A call", "Inside the AgentCard securitySchemes block as a static credential or pre-shared API key", "In a DPoP proof JWT included in the well-known AgentCard endpoint response body"]} correctIdx={1} explanation="The spec requires credentials in HTTP Authorization headers, keeping them out of structured JSON-RPC logs and payload traces. Authorization material in the JSON-RPC params is non-compliant with the spec's security guidance." />

---

## OAuth Scopes and Least-Privilege Declarations

The spec endorses four scheme families, each at a different assurance level:

| Scheme | What it proves | When to use |
|--------|---------------|-------------|
| OAuth 2.0 | Application-level scoped authorization | Default for most agent networks |
| OIDC | Cryptographic identity of the calling agent | When caller identity matters beyond authorization |
| API key | Simple machine-to-machine auth | Low-stakes internal, scope-less calls only |
| mTLS | Transport-layer bidirectional identity via X.509 | Enterprise or high-assurance baseline |

Each skill in the AgentCard maps to specific OAuth scopes. Calling agents request only the scopes they need for the skills they invoke — the direct analog of least-privilege at the capability level. Scope names like `agent:delegate` or `flights:write` are implementation conventions; the A2A spec defines no scope vocabulary.

<Callout type="warning">
AgentCard signing is supported in A2A v0.3+ but is **not mandated** by v1.0. An unsigned card served from a compromised CDN or spoofed DNS record can redirect callers to a malicious endpoint with a fabricated capability advertisement. In production: sign your cards or serve them exclusively from mTLS-authenticated endpoints.
</Callout>

---

## DPoP: Sender-Constraining Bearer Tokens

A plain OAuth bearer token is reusable by anyone who intercepts it. [DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) fixes this at the application layer without a full PKI. The agent holds a P-256 key pair and attaches a short-lived proof JWT on every request:

```http
POST /a2a/ HTTP/1.1
Authorization: DPoP <access-token>
DPoP: <proof-JWT signed with private key>
```

The proof JWT binds the request to the exact HTTP method (`htm`) and URI (`htu`), plus a fresh `jti` for replay prevention. The access token carries a `cnf.jkt` claim — the JWK SHA-256 thumbprint of the agent's public key. A stolen token presented without the matching DPoP proof returns `401 Unauthorized` every time.

**Classification:** DPoP is an OAuth 2.0 hardening extension layered on A2A — not an A2A-native feature. The A2A spec's enterprise guidance endorses it as the application-layer alternative to full mTLS-bound tokens, but mandates neither.

<KnowledgeCheck question="Why does a DPoP-bound token become useless if intercepted and reused by a different party?" options={["Presenting the token requires a fresh proof JWT signed by the private key only the legitimate caller holds", "The authorization server records each token's jti and invalidates the token after the first successful validation", "DPoP tokens embed a 30-second expiry that elapses before a network attacker can redeploy them to another service", "DPoP tokens are end-to-end encrypted and cannot be decoded without the recipient agent's private decryption key"]} correctIdx={0} explanation="The cnf.jkt claim in a DPoP-bound token is a fingerprint of the caller's JWK public key. Every resource server verifies that the DPoP proof header is signed with the key matching that fingerprint. Without the private key — which only the legitimate agent generated and holds — no valid proof can be produced and the token is rejected." />

---

## Delegated Trust: Proving the User Authorized the Chain

mTLS tells Agent B *who* Agent A is. It does not tell Agent B *what the user authorized Agent A to delegate*. This distinction is the chapter's hardest concept and the least addressed by the A2A spec. Orchestration patterns that generate these delegation chains were covered in [[chapter-06.md]] — this chapter addresses how to verify them cryptographically.

The current best pattern is **OAuth 2.0 Token Exchange** (RFC 8693). The [OpenID Foundation's Identity Management for Agentic AI](https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf) describes it for agent chains:

1. User authenticates → authorization server issues token T1 (broad scope)
2. Agent A exchanges T1 for T2, scoped narrowly to Agent B's specific skill, with an `act` claim identifying Agent A as the delegating party
3. Agent B validates T2 — the `sub` claim traces to the original user, `act` traces to Agent A, and `scope` is bounded to this delegation

The **scope attenuation invariant** governs every hop: Agent B's effective permissions are `intersection(B's own role, A's delegated scope)`. As [WorkOS articulates](https://workos.com/blog/ai-agent-credentials): permissions can only narrow through the chain, never widen. An authorization server should reject any sub-agent token request that attempts scope expansion.

Multi-hop chains (A→B→C→D) accumulate one token exchange round-trip per hop. This is a known scalability gap — no standard efficiently handles recursive delegation at depth as of 2026.

---

## Agent Sandboxing and Trust Tiers

Network-layer isolation is categorically stronger than prompt-layer access policy. An agent that cannot reach a resource at the network layer cannot be prompted, tricked, or hallucinated into reaching it. The [Cloud Security Alliance Agentic Trust Framework](https://cloudsecurityalliance.org/blog/2026/02/02/the-agentic-trust-framework-zero-trust-governance-for-ai-agents) describes enclave-based containment: agents assigned to an enclave have zero network visibility of resources outside it — enforced at the routing layer, where the agent has no influence.

The ATF also defines progressive trust tiers for autonomous agents:

| Tier | Autonomy | Gate to promote |
|------|---------|----------------|
| Intern | All actions require human approval | None — default for new agents |
| Junior | Act + notify post-action | Dwell time + performance thresholds |
| Senior | Autonomous within domain | DPoP/mTLS compliance + audit log integrity |
| Principal | Full agency | Governance sign-off |

For inbound A2A tasks: **authentication tells you who sent the message, not whether the content is safe to execute.** Always treat incoming task `message.parts` as untrusted input, regardless of how well-authenticated the calling agent is.

---

## Prompt Injection via A2A Messages

Microsoft's [Agent Governance Toolkit](https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/) (April 2026) frames the core problem: *"Trust is dynamic, not static. A binary trusted and untrusted model doesn't capture reality."* The implication for prompt injection is direct — receiving agents that default to implicit trust in peer-agent messages create exactly the attack surface that multi-agent injection exploits. A successful injection into one upstream agent propagates through every downstream agent that treats the poisoned output as authoritative.

Four attack classes to defend against:

| Attack | Mechanism |
|--------|-----------|
| Control-flow hijacking | Injected metadata redirects which agent handles the next step |
| Confused deputy | Compromised Agent B exploits Agent A's elevated delegated scope |
| Context contamination | Malicious artifact content poisons downstream agents' LLM context |
| Capability bleed | Shared memory or context stores enable cross-task scope leakage |

Defense-in-depth layers (none eliminates the risk alone):
1. **Structural validation first** — schema, type, and size-bound checks before any NLP processing
2. **NLP pattern scanning** — flag instruction-override signatures and role-switch commands
3. **External content tagging** — wrap all incoming task content in `<EXTERNAL_CONTENT>` tags with a system-prompt directive marking tagged content as untrusted regardless of message origin
4. **Intent diffing** — compare original task intent against what downstream agents are being asked to do; semantic drift signals injection

Prompt injection in A2A systems remains an unsolved problem as of 2026. These patterns are defense-in-depth layers, not elimination strategies.

---

## The Secure Inbound Task Middleware

The validation chain below must complete before any inbound A2A task reaches your agent's LLM core. Steps 1–5 are the hard security floor; steps 6–8 are defense-in-depth.

```python
async def validate_inbound_task(request: A2ARequest, task: Task) -> Task:
    # 1. mTLS: terminated at the service mesh/load balancer before application code runs.
    #    If not using mTLS, add client-cert validation here.

    # 2. Auth header extraction
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise AuthenticationError("Missing or malformed Authorization header")
    token = auth.split(" ", 1)[1]

    # 3. DPoP proof validation (if this endpoint requires DPoP)
    dpop = request.headers.get("DPoP")
    if dpop:
        validate_dpop_proof(
            dpop, token,
            method=request.method,
            uri=request.uri,        # htm + htu must match exactly
        )
        # Checks: ES256 signature, iat freshness (<120s),
        # jti uniqueness in Redis store (300s TTL), cnf.jkt binding

    # 4. JWT validation + claims
    claims = verify_jwt(token, audience=THIS_AGENT_AUDIENCE)

    # 5. Scope enforcement for the requested skill
    required = SKILL_SCOPE_MAP[task.skill_id]
    if required not in claims.get("scope", "").split():
        raise AuthorizationError(f"Token missing scope: {required}")

    # 6. Replay protection on task ID
    if not task_nonce_store.add_if_absent(task.id, ttl=300):
        raise ReplayError("Duplicate task ID within replay window")

    # 7. Prompt injection sanitization + untrusted content tagging
    for part in task.message.parts:
        if part.type == "text":
            sanitize_for_injection(part.text)   # raises on injection patterns
            part.text = f"<EXTERNAL_CONTENT>\n{part.text}\n</EXTERNAL_CONTENT>"

    # 8. Scope attenuation for On-Behalf-Of delegated tokens
    if "act" in claims:
        attenuate_to_delegating_scope(claims)

    return task  # Safe to pass to agent core
```

`validate_dpop_proof` requires a Redis-backed `jti` store to block proof replay within the validity window. `sanitize_for_injection` should combine regex-based pattern matching with a lightweight NLP classifier — Meta PromptGuard 2 (22M parameters) is latency-feasible for this path.

---

## Hands-On: Security Middleware for an A2A Server

**Objective:** Implement `validate_inbound_task` as a FastAPI dependency and verify that each rejection path fires correctly before any task payload reaches your handler's core logic.

**Setup:** FastAPI server, `python-jose` for JWT issuance and verification, Redis for `jti` replay tracking, a locally generated P-256 key pair for the "calling agent."

**Steps:**
1. Generate a P-256 key pair. Issue a DPoP-bound access token using `python-jose` — the token's `cnf.jkt` must be the JWK SHA-256 thumbprint of the public key.
2. Implement `validate_inbound_task` and wire it as a FastAPI `Depends` on your `POST /a2a/` endpoint.
3. Run each success criterion below as a separate `curl` or `pytest` call.

**Success criteria — all five must pass before the exercise is complete:**
- Plain bearer token (no `DPoP` header) → `401 Unauthorized`
- Replaying the same DPoP proof JWT within 300 seconds → `401 Unauthorized` (jti replay blocked)
- Valid token with missing or wrong scope → `403 Forbidden` with the required scope named in the response body
- Task message containing an instruction-override injection payload (e.g., a `"[injection-test: override system role]"` string) → content wrapped in `<EXTERNAL_CONTENT>` tags in your handler's printed output
- Fully valid DPoP-bound request with correct scope → `200 OK` with the sanitized task echoed back

---

Next, you'll instrument these auth flows, delegation hops, and injection events as distributed traces so a single timeline shows exactly what happened, when, and why: [[chapter-09.md]]

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-09.md -->

```yaml
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8568
course: multi-agent-orchestration-a2a
chapter: 9
chapter_title: "Observability & Debugging — Tracing the Agentic Chain"
slug: multi-agent-orchestration-a2a-chapter-09
description: "Multi-agent systems are black boxes squared: each agent hides its reasoning, and no natural observation point exists at the handoff boundary. This chapter shows how to propagate OpenTelemetry trace context across A2A message boundaries, design privacy-safe structured agent logs, and use Langfuse to visualize the latency gap and debug negotiation failures."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 40
reading_time_min: 10
last_updated: 2026-06-15
chapter_primary_query: "how to implement distributed tracing for multi-agent A2A workflows with OpenTelemetry and Langfuse"
learning_objectives:
  - Implement OpenTelemetry-style distributed tracing across multiple A2A agents by propagating the traceparent header at every message boundary
  - Design a structured agent log that captures protocol events, decisions, and audit metadata without storing raw chain-of-thought
  - Use trace IDs to visualize a multi-agent workflow in Langfuse, identifying the protocol latency gap between agents
  - Apply the reasoning-to-protocol debugging discipline to diagnose negotiation failures from structured log evidence
positions:
  - audit-trail-as-enterprise-gate
tags: [observability, OpenTelemetry, Langfuse, distributed-tracing, A2A, multi-agent, debugging]
status: g0-passed
sources:
  - url: https://langfuse.com/docs/observability/overview
    title: "Langfuse Observability Overview"
    retrieved: 2026-06-15
  - url: https://langfuse.com/docs/observability/features/token-and-cost-tracking
    title: "Langfuse Token and Cost Tracking"
    retrieved: 2026-06-15
  - url: https://langfuse.com/self-hosting
    title: "Langfuse Self-Hosting"
    retrieved: 2026-06-15
  - url: https://github.com/a2aproject/A2A
    title: "A2A GitHub Repository"
    retrieved: 2026-06-15
  - url: https://a2a-protocol.org/latest/
    title: "A2A Protocol Specification"
    retrieved: 2026-06-15
  - url: https://www.w3.org/TR/trace-context/
    title: "W3C Trace Context — traceparent Header Specification"
    retrieved: 2026-06-15
owns:
  - "OpenTelemetry distributed tracing for multi-agent A2A systems"
  - "Structured agent log design and CoT privacy boundaries"
  - "traceparent header propagation across A2A message boundaries"
  - "Langfuse trace visualization for agentic workflows"
  - "Reasoning-to-protocol gap debugging discipline"
defers_to:
  - "Role Contamination → ch4"
  - "DPoP-bound token security → ch8"
  - "Capstone: end-to-end trace integration → ch10"
quiz_topics:
  - "traceparent header propagation"
  - "structured agent log categories"
  - "protocol latency vs inference latency in Langfuse timeline"
  - "negotiation failure debugging workflow"
notebooklm_source_focus:
  - "agent-observability-langfuse.md"
  - "google-a2a-protocol-2026.md"
word_budget: { min: 800, max: 1200 }
faq:
  - question: "How does traceparent propagation differ from using A2A's contextId for tracing?"
    answer: "The A2A `contextId` is a task-family identifier scoped to the A2A protocol — it groups messages in the same task thread but has no meaning outside A2A. The W3C `traceparent` header is an OpenTelemetry context propagation mechanism that carries the OTel `trace_id` and `span_id` across arbitrary HTTP boundaries, including A2A `sendMessage` calls. You need both: `contextId` for filtering A2A messages in Langfuse trace search, and `traceparent` for linking spans from different agent processes into one distributed trace tree. See [W3C Trace Context](https://www.w3.org/TR/trace-context/) for the full propagation specification."
  - question: "What is the difference between protocol latency and inference latency in Langfuse's timeline view?"
    answer: "In Langfuse's timeline view, **inference latency** appears as the duration of an agent's own child span — the wall-clock time from when the model starts sampling to when it returns a completion. **Protocol latency** is the gap between Agent A's last span ending and Agent B's first span beginning — pure network transit and A2A message queuing, before Agent B begins any computation. Separating these two is the primary value of distributed tracing: a slow pipeline may be dominated by inference, protocol overhead, or both, and each requires a different remedy. See [Langfuse Observability Overview](https://langfuse.com/docs/observability/overview)."
  - question: "Why should raw chain-of-thought not be logged in multi-agent observability systems?"
    answer: "Raw chain-of-thought is simultaneously overspecific (it changes every run, making cross-run comparison useless), storage-expensive (a 10-agent workflow generates hundreds of megabytes of reasoning text per task), and a privacy risk — if a user's query appears in the reasoning trace, that trace may be subject to GDPR data retention and deletion obligations. Log structured audit metadata — decisions, tool call parameters with PII redacted, task lifecycle transitions — not raw model completions. See [Langfuse Observability Overview](https://langfuse.com/docs/observability/overview) for recommended capture patterns."
quiz:
  - question: "Which HTTP header must Agent A inject into its A2A request so that Agent B's spans appear under the same trace in Langfuse?"
    options:
      - "X-Trace-Context-ID header initialized from the current A2A contextId value"
      - "traceparent, specified by the W3C Trace Context propagation standard"
      - "A2A-Correlation-ID derived from the current task's messageId field"
      - "Authorization Bearer token carrying the DPoP-bound operation signature"
    correct_idx: 1
    explanation: "The W3C traceparent header is the standard OTel context propagation mechanism. Without it, every agent produces isolated trace islands and the inter-agent latency gap is invisible."
    section_anchor: distributed-tracing-mechanics-spans-trace-ids-and-context-propagation
  - question: "A structured agent log for a multi-agent system should include which category of information?"
    options:
      - "Full chain-of-thought reasoning tokens to ensure maximum debugging context later"
      - "Raw model output and every LLM completion across the entire agent workflow"
      - "Protocol events, decisions, tool calls, and audit metadata without chain-of-thought"
      - "Task IDs and final output artifacts only, to minimize storage overhead"
    correct_idx: 2
    explanation: "Raw CoT is overspecific (different every run), not comparable across invocations, and a privacy hazard if PII surfaced during the working memory. Log the decision and its structured reason; omit the deliberation."
    section_anchor: what-to-capture-and-what-to-redact
  - question: "In Langfuse's timeline view of a 2-agent A2A workflow, what does the gap between Agent A's last span ending and Agent B's first span beginning represent?"
    options:
      - "Agent B's model inference and token sampling latency"
      - "Protocol latency: network transit and A2A message queuing overhead"
      - "The time Agent A spent computing its chain-of-thought output"
      - "Overhead introduced by the Langfuse OTLP ingestion pipeline"
    correct_idx: 1
    explanation: "This gap is pure protocol latency — it is time lost before Agent B has even started. LLM inference latency appears as the duration of Agent B's own child span after it begins processing."
    section_anchor: visualizing-the-chain-in-langfuse
  - question: "When debugging a negotiation failure where Agent B's output does not match Agent A's intent, what is the correct first diagnostic step?"
    options:
      - "Enable full chain-of-thought logging on Agent B and replay the failed task"
      - "Locate the contextId in Langfuse and inspect the parts[0].text of the sendMessage span"
      - "Increase Agent B's context window budget to allow additional reasoning depth"
      - "Replace Agent B's underlying model with a larger one and re-run the workflow"
    correct_idx: 1
    explanation: "The sendMessage span's parts[0].text is the actual intent string Agent A transmitted. Comparing it to Agent B's decision log reveals the mismatch without requiring raw CoT access."
    section_anchor: the-reasoning-to-protocol-gap-debugging-negotiation-failures
```

# Observability & Debugging — Tracing the Agentic Chain

> **Chapter 9 of 10 · 40 min (prose ~10 min + 20 min hands-on exercise)**

---

## The Black Box Squared Problem

To trace a multi-agent A2A workflow: propagate the W3C `traceparent` header on every `sendMessage` call, create a child OTel span on receipt, and export via OTLP to Langfuse. The result is a single trace tree linking every agent's spans under one `trace_id` — with protocol latency, token cost, and decision audit metadata visible in a single timeline.

The need for this discipline arises from a property unique to multi-agent systems: **compounded opacity**. A single agent is a black box — you see its input and output but not the reasoning in between. Chain two agents together and you have a black box delegating to a black box. Failure modes multiply without any natural observation point between them.

Distributed tracing is a solved problem in every other area of software engineering. OpenTelemetry, the vendor-neutral observability framework, became a CNCF graduated project precisely because it offered a single API surface for traces, metrics, and logs across every major platform. The A2A protocol was designed with observability in mind — each task carries a `contextId` (see [[multi-agent-orchestration-a2a/chapter-02|Chapter 2]] for A2A message structure) that propagates across the agent boundary, giving you the raw material for a trace that spans multiple agents, vendors, and networks. ([A2A Protocol Specification](https://a2a-protocol.org/latest/))

The operational principle: **every A2A task boundary is a trace boundary**. Map A2A's existing structure onto OTel's span model — no new observability discipline required.

---

## What to Capture and What to Redact

For enterprise deployments in regulated environments, structured agent logs are not optional — they are the audit trail that makes AI agent systems enterprise-deployable. SOC 2 and GDPR reviews require a full, queryable record of what each agent read, decided, and changed; raw chain-of-thought doesn't serve that need.

The temptation when you first add observability to a multi-agent system is to log everything: full chain-of-thought, every token generated, every intermediate reasoning step. Resist this. Full reasoning traces are simultaneously overspecific (they change every run, making comparison useless) and a privacy hazard if user data surfaced in the agent's working memory.

A structured agent log captures exactly four categories:

1. **Protocol events** — every A2A message sent and received, including `contextId`, `messageId`, `role`, task lifecycle transitions (`SUBMITTED → WORKING → COMPLETED / FAILED`), and the task description from `parts[0].text`.
2. **Decisions** — the agent's chosen action at each decision point, as a structured summary: *"Selected tool: `query_database`. Reason: task requires structured data lookup."*
3. **Tool calls and results** — function name, input parameters with PII fields redacted, result status, and latency.
4. **Audit metadata** — agent identity from the AgentCard `name` field, model version, token counts (input/output counts, not content), and wall-clock timing.

Raw chain-of-thought does not belong in a log. Log the decision; omit the deliberation. A 10-agent network generates hundreds of megabytes of reasoning text per task — unstructured, incomparable across runs, and irrelevant for protocol debugging.

<Callout type="warning">
Storing full chain-of-thought output in an observability backend can constitute secondary processing of user data. If a user's question appears verbatim in a reasoning trace, that trace may be subject to data retention and deletion obligations. Log structured summaries, decisions, and protocol messages — not raw model completions.
</Callout>

---

## Distributed Tracing Mechanics: Spans, Trace IDs, and Context Propagation

In OpenTelemetry, a **trace** is a tree of **spans**. A span represents one unit of work: an agent receiving a task, calling a tool, or returning a result. Every span carries a `trace_id` shared across the entire tree, a unique `span_id`, and an optional `parent_span_id` that encodes the parent-child relationship.

For an A2A multi-agent flow, the mapping is direct:

| A2A concept | OTel concept |
|---|---|
| `contextId` (task family identifier) | `trace_id` |
| Task received by an agent | Root span or child span |
| Tool execution inside an agent | Child span of the agent span |
| A2A `sendMessage` to downstream agent | Child span + propagate `trace_id` in header |

The step most teams get wrong is the last one. **You must propagate trace context across the A2A message boundary**. When Agent A sends a `sendMessage` to Agent B, it must inject the current OTel context into the request via the [`traceparent` HTTP header](https://www.w3.org/TR/trace-context/) defined in the W3C Trace Context specification. Agent B reads that header, creates a child span under the same trace, and continues. Without this propagation, every agent's telemetry produces an isolated trace island and the inter-agent latency gap is invisible.

```python
from opentelemetry import trace
from opentelemetry.propagate import inject, extract
import httpx

tracer = trace.get_tracer("a2a.agent-a")

async def send_a2a_message(context_id: str, task_text: str, target_url: str):
    with tracer.start_as_current_span("a2a.send_message") as span:
        span.set_attribute("a2a.context_id", context_id)
        span.set_attribute("a2a.target", target_url)

        headers = {}
        inject(headers)  # Injects 'traceparent' and 'tracestate'

        payload = {
            "jsonrpc": "2.0", "method": "sendMessage", "id": 1,
            "params": {"message": {
                "role": "ROLE_USER",
                "contextId": context_id,
                "parts": [{"text": task_text}]
            }}
        }
        async with httpx.AsyncClient() as client:
            resp = await client.post(target_url, json=payload, headers=headers)
        span.set_attribute("a2a.response_status", resp.status_code)
        return resp.json()
```

On the receiving side, Agent B reconnects to the trace before doing any work:

```python
from opentelemetry.propagate import extract

async def handle_a2a_request(request_headers: dict, payload: dict):
    ctx = extract(request_headers)  # Links to Agent A's trace
    with tracer.start_as_current_span("a2a.receive_message", context=ctx) as span:
        context_id = payload["params"]["message"]["contextId"]
        span.set_attribute("a2a.context_id", context_id)
        # ... agent logic, tool calls as child spans ...
```

<KnowledgeCheck
  question="Which HTTP header must Agent A inject into its A2A request so that Agent B's spans appear under the same trace?"
  options={["X-Trace-Context-ID header initialized from the current A2A contextId value", "traceparent, specified by the W3C Trace Context propagation standard", "A2A-Correlation-ID derived from the current task's messageId field", "Authorization Bearer token carrying the DPoP-bound operation signature"]}
  correctIdx={1}
  explanation="The W3C traceparent header is the standard OTel context propagation mechanism. Without it, every agent produces isolated trace islands and the inter-agent latency gap is invisible."
/>

---

## Visualizing the Chain in Langfuse

Langfuse is the strongest open-source choice for visualizing multi-agent traces: fully self-hostable, natively accepting OTLP ingestion, and capable of rendering **agent graphs** — directed flow diagrams of the agent call chain with latency, token counts, and cost overlaid at each node. It requires no proprietary SDK; any OTel-compatible exporter sends data to it. ([Langfuse Observability Overview](https://langfuse.com/docs/observability/overview))

Configure an OTLP HTTP exporter targeting your Langfuse instance:

```python
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(
    endpoint="http://localhost:3000/api/public/otel",
    headers={"Authorization": "Basic <base64_pk:sk>"}
)))
trace.set_tracer_provider(provider)
```

Once traces arrive, three Langfuse views are immediately useful for A2A debugging:

- **Timeline view**: Each span as a horizontal bar, ordered by start time. The gap between Agent A's span ending and Agent B's span starting is **protocol latency** — network transit and queuing, not inference.
- **Agent graph**: Directed flow between agents with cost and latency per edge, exposing orchestration bottlenecks at a glance.
- **Trace search**: Filter by `a2a.context_id` to retrieve every span for one task family across separate agent processes.

Langfuse also ingests token counts from span attributes, inferring cost from 100+ model pricing definitions. ([Langfuse Token and Cost Tracking](https://langfuse.com/docs/observability/features/token-and-cost-tracking)) Set `usage_details` on your spans and Langfuse computes per-span and per-session cost breakdowns automatically.

<KnowledgeCheck
  question="In Langfuse's timeline view of a 2-agent A2A workflow, what does the gap between Agent A's last span ending and Agent B's first span beginning represent?"
  options={["Agent B's model inference and token sampling latency", "Protocol latency: network transit and A2A message queuing overhead", "The time Agent A spent computing its chain-of-thought output", "Overhead introduced by the Langfuse OTLP ingestion pipeline"]}
  correctIdx={1}
  explanation="This gap is pure protocol latency — time lost before Agent B has even started. LLM inference latency appears as the duration of Agent B's own child span after it begins processing."
/>

---

## The Reasoning-to-Protocol Gap: Debugging Negotiation Failures

The hardest class of multi-agent bugs to diagnose are **negotiation failures**: the A2A handshake completes successfully, the task lifecycle reaches `COMPLETED`, but Agent B's output doesn't match Agent A's intent.

The structured log tells you *what happened*: Agent A sent task type X, Agent B returned result Y. It does not tell you *why Agent B chose Y*. The reasoning-to-protocol gap exists because A2A's structured fields — task type, capability schema, `Parts` — do not encode the upstream agent's implicit assumptions about output format or precision.

The debugging discipline for negotiation failures:

1. **Find the `contextId`** of the failing task in Langfuse trace search.
2. **Inspect `parts[0].text`** on the `a2a.send_message` span — this is the exact intent string Agent A transmitted, not what you think you sent.
3. **Check Agent B's AgentCard skills** against the task type. If the task type isn't listed, Agent B is operating outside its declared capability — a Role Contamination bug (covered in [[multi-agent-orchestration-a2a/chapter-04|Chapter 4]]).
4. **Read Agent B's decision log** for that span. A structured entry like *"Chose approach: fallback to general summarization. Reason: no structured schema detected."* exposes the mismatch without requiring raw chain-of-thought.
5. **Tighten the capability schema** on Agent B's AgentCard to require structured input fields explicitly, so the negotiation fails-fast rather than silently producing a wrong answer.

---

## Hands-On: Instrument a 2-Agent A2A Conversation

**Goal**: Generate an OTel trace showing the latency gap between Agent A completing its step and Agent B receiving the message.

**Setup:**

```bash
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-http \
            opentelemetry-api httpx
```

**Step 1 — Launch a trace backend.** Start Langfuse locally (`git clone https://github.com/langfuse/langfuse && docker compose up`) or Jaeger as a single container: `docker run -p 16686:16686 -p 4318:4318 jaegertracing/all-in-one`. ([Langfuse Self-Hosting](https://langfuse.com/self-hosting))

**Step 2 — Instrument Agent A** using `send_a2a_message` from the Distributed Tracing Mechanics section. Wrap Agent A's LLM call in a child span to separate inference latency from protocol latency.

**Step 3 — Instrument Agent B** using `handle_a2a_request`. Add a child span for Agent B's LLM call; set `a2a.context_id` as an attribute on every span in both agents.

**Step 4 — Run a 2-agent task.** After completion, open Langfuse (or Jaeger at `localhost:16686`) and search by `contextId`.

**Success criteria:**

- One trace contains spans from both Agent A and Agent B, linked by the same `trace_id`.
- The timeline shows a measurable gap (≥ 10 ms in local Docker) between Agent A's `a2a.send_message` span ending and Agent B's `a2a.receive_message` span starting. This gap is your protocol latency baseline.
- The Langfuse agent graph renders Agent A → Agent B with latency and token cost annotated on the edge.
- Filtering by `a2a.context_id` returns all spans for that task with no orphaned islands.

If spans appear as disconnected islands with no parent-child link between agents, the `traceparent` header is not propagating — check the `inject(headers)` call in Agent A's send path.

---

Chapter 10 assembles every concept from this course into a working 4-agent sovereign network: A2A handshakes, MCP-backed tool access, DPoP auth, crash-resume validation, and a production distributed trace linking all four agents end to end.

→ [[multi-agent-orchestration-a2a/chapter-10|Chapter 10: Capstone — Building the Sovereign Agent Network]]

---

*Sources: [Langfuse Observability Overview](https://langfuse.com/docs/observability/overview) · [Langfuse Token and Cost Tracking](https://langfuse.com/docs/observability/features/token-and-cost-tracking) · [Langfuse Self-Hosting](https://langfuse.com/self-hosting) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [A2A Protocol Specification](https://a2a-protocol.org/latest/) · [W3C Trace Context](https://www.w3.org/TR/trace-context/)*

<!-- source: vault/courses/multi-agent-orchestration-a2a/chapter-10.md -->

```yaml
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8578
course: multi-agent-orchestration-a2a
chapter_num: 10
title: "Capstone — Building the Sovereign Agent Network"
slug: multi-agent-orchestration-a2a-chapter-10
description: "Every building block from the course converges here: four A2A agents form a runnable Cross-Vendor Investment Researcher network. This capstone wires AgentCard discovery, MCP-backed tool proxying, DPoP-hardened OAuth auth, task resumability across agent failures, and a single distributed trace linking all four handoffs into one production-testable system."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 70
reading_time_min: 18
last_updated: 2026-06-15
chapter_primary_query: "how to build a four-agent A2A sovereign network with MCP tool proxying, DPoP auth, resumability, and distributed tracing"
first_60_words_answer: "Start four Docker containers — Orchestrator, Market Data Specialist (MCP-backed SQLite), Sentiment Analyst, Financial Writer. The orchestrator discovers all three via AgentCards, dispatches sequential A2A tasks, and enforces DPoP-bound OAuth at every handoff. One docker compose up starts the network; one curl proves DPoP rejection; one SIGTERM + resume proves the Writer restarts without re-running Market Data."
prerequisites_chapters: [1, 2, 5, 8, 9]
learning_objectives:
  - Assemble a four-agent A2A network with AgentCard-based capability discovery and sequential task delegation
  - Wire an MCP-backed specialist so the orchestrator consumes its output without holding database credentials
  - Validate DPoP rejection correctly framed as OAuth 2.0 hardening layered on A2A, not an A2A-native feature
  - Prove Writer resumability — the Market Data Specialist is invoked exactly once per root contextId even after Writer failure and re-dispatch
  - Connect all four agents under a single OpenTelemetry trace and inspect the full timeline in Langfuse
tags: [A2A, capstone, sovereign-agent, MCP, DPoP, OAuth, resumability, OpenTelemetry, Langfuse, multi-agent]
status: g0-passed
positions: []  # capstone synthesis — no adversarial stance declared
sources:
  - url: "https://a2a-protocol.org"
    title: "A2A Protocol Specification"
    retrieved: "2026-05-12"
  - url: "https://github.com/a2aproject/A2A"
    title: "A2A GitHub Repository"
    retrieved: "2026-05-12"
  - url: "https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02"
    title: "Part 2: A2A+MCP Practical Guide (Fossible)"
    retrieved: "2026-06-15"
  - url: "https://datatracker.ietf.org/doc/html/rfc9449"
    title: "RFC 9449: OAuth 2.0 Demonstrating Proof of Possession (DPoP)"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/dpop-rfc-9449-explained"
    title: "WorkOS: DPoP (RFC 9449) Explained"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/ai-agent-credentials"
    title: "WorkOS: Securing Agentic Apps — AI Agent Credentials"
    retrieved: "2026-06-15"
  - url: "https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security"
    title: "Red Hat Developer: How to Enhance A2A Security"
    retrieved: "2026-06-15"
  - url: "https://langfuse.com/docs/observability/overview"
    title: "Langfuse Observability Overview"
    retrieved: "2026-05-12"
  - url: "https://langfuse.com/self-hosting"
    title: "Langfuse Self-Hosting"
    retrieved: "2026-05-12"
quiz:
  - question: "Why does the orchestrator in the Sovereign Agent Network never call the Market Data Specialist's MCP server directly?"
    options:
      - "The A2A spec prohibits orchestrators from initiating MCP connections to agents they do not own"
      - "Direct MCP access bypasses the specialist's task lifecycle, role logic, and resumability guarantees"
      - "MCP servers only accept connections from the same Docker network namespace as the specialist agent"
      - "The orchestrator lacks the OAuth scope required to call the specialist's tools/call MCP endpoint"
    correct_idx: 1
    explanation: "Tool-proxying over A2A exists for architectural reasons, not protocol restrictions. The specialist owns its own task lifecycle, authentication context, and failure-handling logic. If the orchestrator reached the MCP server directly, it would bypass the specialist's domain logic, lose the task-ID bookkeeping that enables resumability, and couple itself to the specialist's implementation — exactly the anti-pattern A2A was designed to prevent."
    section_anchor: wiring-the-mcp-backed-market-data-specialist

  - question: "A test sends a valid OAuth bearer token to the Market Data Specialist with no DPoP proof header. The correct outcome is:"
    options:
      - "The specialist accepts the request because DPoP is optional per the A2A v1.0 spec and the bearer token is valid"
      - "The request returns 401 Unauthorized from the security middleware before the task reaches the agent handler"
      - "The A2A protocol rejects the request at the JSON-RPC layer with error code -32600 invalid request"
      - "The specialist generates a new DPoP proof on the caller's behalf using its own key and completes the task"
    correct_idx: 1
    explanation: "DPoP rejection fires in the security middleware — the validate_inbound_task chain from Chapter 8 — before the task reaches the agent's LLM core. DPoP is an OAuth 2.0 hardening extension layered on top of A2A's securitySchemes declaration, not an A2A-native feature. The A2A spec endorses it but mandates nothing; the 401 is the middleware implementer's enforcement, not the protocol's."
    section_anchor: oauth-hardening-rejecting-unauthorized-requests

  - question: "After the Financial Writer is killed mid-run and then re-dispatched, the Market Data Specialist's log shows exactly one request. What guarantees this?"
    options:
      - "The A2A spec mandates at-most-once delivery semantics for all tasks sharing the same contextId"
      - "The orchestrator persists the Market Data artifact in task state and injects it into the Writer's resumed task without re-dispatching"
      - "The Market Data Specialist caches results by ticker symbol and returns the cached value without re-querying SQLite"
      - "DPoP token replay protection prevents the orchestrator from issuing a second request within the 300-second replay window"
    correct_idx: 1
    explanation: "Resumability depends on the orchestrator persisting the completed specialist's artifact in its task state store. When the Writer is re-dispatched, the orchestrator injects the already-stored Market Data artifact into the new task's message payload — the specialist is never contacted again. Re-running it would risk data-consistency violations if prices changed between the original run and the resume."
    section_anchor: crash-resumability-without-re-running-market-data

  - question: "What confirms that all four agents' spans belong to the same distributed trace in Langfuse?"
    options:
      - "All four agents share the same Langfuse API key and project ID, grouping their spans under one dashboard view"
      - "The orchestrator injects traceparent into every outbound A2A task; each specialist propagates the same trace_id in child spans"
      - "A2A's contextId field doubles as an OpenTelemetry trace_id when Langfuse OTLP ingestion is enabled"
      - "Langfuse auto-joins spans from agents on the same Docker network by correlating their request timestamps"
    correct_idx: 1
    explanation: "The W3C traceparent header carries the root trace_id from the orchestrator into each specialist's span context. Without explicit traceparent injection at each A2A task dispatch, every agent generates an isolated trace island and the inter-agent latency gaps become invisible. Langfuse renders all linked spans under the same trace_id in its agent graph view."
    section_anchor: one-trace-four-agents
faq:
  - question: "What happens if a specialist's AgentCard goes stale between orchestrator startup and task dispatch?"
    answer: "The orchestrator's routing table was built from the card fetched at startup. If the specialist updated its skills or required scopes since then, the orchestrator may request a scope that no longer exists or omit one now required. Production deployments should re-fetch and re-validate cards before each task dispatch or subscribe to a registry-change notification pattern. ([A2A Protocol Specification](https://a2a-protocol.org))"
  - question: "Why is an in-process dictionary insufficient for the orchestrator's task state store in production?"
    answer: "An in-process store is lost when the orchestrator process restarts. If the orchestrator dies after receiving the Market Data artifact but before the Writer completes, a cold restart loses the artifact and forces a Market Data re-run — violating the resumability invariant. Redis or a Postgres-backed task table persists artifacts across orchestrator failures independently of specialist failures, keeping the exactly-once Market Data guarantee intact. ([WorkOS: AI Agent Credentials](https://workos.com/blog/ai-agent-credentials))"
  - question: "Can the Sentiment Analyst and Financial Writer run in parallel?"
    answer: "Yes. Sentiment Analysis does not depend on Financial Writing outputs. Once the Market Data artifact is available, the orchestrator can dispatch both tasks in the same batch and wait on both COMPLETED events before assembling the final report. The only hard serialization constraint is that Market Data must complete before either downstream specialist receives its task payload. Parallelizing reduces total wall-clock time at no consistency cost. ([A2A Protocol Specification](https://a2a-protocol.org))"
```

# Capstone — Building the Sovereign Agent Network

> **Chapter 10 of 10 · 70 min (prose ~18 min + 40 min hands-on)**

---

## The Four-Agent Architecture

Start four Docker containers — Orchestrator, Market Data Specialist (MCP-backed SQLite), Sentiment Analyst, Financial Writer. The orchestrator discovers all three via their AgentCards at `/.well-known/agent.json`, dispatches sequential A2A tasks, and enforces DPoP-bound OAuth at every handoff. One `docker compose up` starts the network; one `curl` proves DPoP rejection; one `SIGTERM` + resume proves the Writer restarts without re-running Market Data. This is the hub-and-spoke pattern from [[chapter-06.md]] at full resolution — one orchestrator delegates to three domain specialists, each independently discoverable, authenticated, and observable.

The orchestrator receives a user investment query, serializes work as three sequential A2A tasks: Market Data first (a blocking upstream dependency), then Sentiment Analysis and Financial Writing once the price artifact is available. The MCP-to-A2A boundary from [[chapter-05.md]] sits entirely inside the Market Data Specialist: the specialist wraps a local SQLite database as a FastMCP server, invokes `query_price_history` internally, and delivers the result as an A2A artifact. The orchestrator never holds the database credentials or the MCP server address. [A2A Protocol v1.0.0](https://a2a-protocol.org) defines the task lifecycle states — `SUBMITTED`, `WORKING`, `COMPLETED`, `FAILED` — the orchestrator polls to sequence the handoffs.

---

## Publishing and Consuming AgentCards

Each specialist serves a `/.well-known/agent.json` card declaring the skills it accepts and the OAuth scopes those skills require. The Market Data Specialist's card advertises an `equity_price_history` skill requiring scope `mcp:market_data:read`. The Sentiment Analyst advertises `sentiment_analysis` scoped to `sentiment:read`. The Financial Writer advertises `report_generation` scoped to `report:write`.

The orchestrator fetches all three cards at startup and builds a routing table mapping skill identifiers to agent URLs and required scopes. A task routed to the wrong specialist — one whose card does not declare the required skill — fails during the orchestrator's pre-dispatch scope check rather than silently producing a wrong-domain response. [Red Hat's A2A security analysis](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security) notes that card endpoints must be access-controlled; in this network, every `/.well-known/agent.json` endpoint requires the same OAuth bearer token as the task endpoint to prevent capability-surface leakage to anonymous callers.

<KnowledgeCheck question="The orchestrator fetches all three AgentCards at startup. What is the primary failure mode if it never re-fetches them?" options={["The orchestrator uses stale skill declarations and may request scopes that no longer exist or omit scopes now required", "The orchestrator cannot generate valid DPoP proofs once the specialists rotate their asymmetric key pairs", "The A2A spec mandates card refresh on every task dispatch and rejects tasks built from stale routing tables", "Stale cards cause Langfuse to mismatch span attributes and produce orphaned trace islands in the timeline"]} correctIdx={0} explanation="AgentCards are the orchestrator's only source of truth about what skills a specialist accepts and which scopes it requires. A stale card may describe a skill that has been renamed, scoped differently, or removed. The safe production pattern is to re-validate cards before each task dispatch or subscribe to registry-change notifications." />

---

## Wiring the MCP-Backed Market Data Specialist

The Market Data Specialist's A2A handler follows the tool-proxying pattern: receive A2A task → invoke `query_price_history` on the local FastMCP server → package OHLCV rows as a JSON artifact → return as the A2A task output. The orchestrator then passes this artifact to the Financial Writer as a resource injection embedded in the next task's message payload. The Writer never touches the MCP server.

The constraint [the Fossible A2A+MCP guide](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02) makes explicit: the orchestrator gains role isolation, specialist-managed failure handling, and clean resumability by respecting the protocol boundary. If the orchestrator reached the MCP server directly, it would bypass the specialist's domain logic and lose the task-lifecycle bookkeeping that resumability depends on.

<Callout type="warning">
Wrapping every MCP tool call as a separate A2A task is an anti-pattern. A2A overhead is justified only when the delegated work requires autonomous state, failure isolation, or independent authentication. For fast, synchronous internal tool calls — a SQLite read that completes in milliseconds — MCP is the correct abstraction; A2A is the boundary between agents, not between an agent and its own tools.
</Callout>

---

## Validating the Handshake End to End

With all four agents running (`docker compose up`), the end-to-end handshake validation is deterministic. POST a task to the Orchestrator's `POST /a2a/` endpoint with a ticker symbol and date range. The orchestrator's task log should show three sequential subtask dispatches: Market Data (`COMPLETED`) → then Sentiment Analysis and Financial Writing dispatched in parallel once the artifact is available, both reaching `COMPLETED` before the orchestrator marks its root task done. Any specialist returning `FAILED` halts the root task chain and surfaces the upstream `contextId` for trace inspection in Langfuse.

<KnowledgeCheck question="The Sentiment Analyst returns FAILED while the Financial Writer is still in WORKING state. What should the orchestrator do?" options={["Cancel the Financial Writer's task and surface the contextId for trace inspection — all downstream specialists must succeed", "Allow the Financial Writer to complete independently and assemble the report with an absent sentiment section", "Retry the Sentiment Analyst up to three times using the same task ID before propagating failure to the root task", "Promote the Financial Writer to orchestrator role so it can re-dispatch the Sentiment Analyst task autonomously"]} correctIdx={0} explanation="The Sentiment Analyst's output is a required input to the final report assembly. A FAILED specialist propagates as a FAILED root task. The correct response is to cancel any in-flight downstream tasks, log the contextId, and surface the failure with the Langfuse trace link so a developer can inspect exactly where and why the specialist failed." />

---

## OAuth Hardening: Rejecting Unauthorized Requests

[DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) is not an A2A-native feature — it is an OAuth 2.0 hardening extension layered on top of A2A's `securitySchemes` declaration. The A2A spec endorses sender-constraining tokens but mandates nothing; the enforcement happens in the security middleware from [[chapter-08.md]], not in the A2A protocol itself.

The hardening test is a single `curl`: send a valid bearer token with no `DPoP` header to any specialist that requires DPoP. The expected `401 Unauthorized` with a `WWW-Authenticate: DPoP` challenge proves the middleware fires before the task reaches the agent handler. [WorkOS](https://workos.com/blog/dpop-rfc-9449-explained) describes the standard challenge: the resource server returns `error="use_dpop_nonce"` in `WWW-Authenticate` when a nonce is required. Framing matters for production documentation: this is OAuth 2.0 hardening on top of A2A, not a capability of the protocol layer.

---

## Crash Resumability Without Re-Running Market Data

Halt the Financial Writer mid-run by sending `SIGTERM` after it receives the market data artifact but before it returns `COMPLETED`. Then re-dispatch the Writer's task using the same `contextId`. The resumability invariant: the orchestrator injects the already-stored Market Data artifact into the new task's message payload. The Market Data Specialist is never re-invoked.

Re-running the specialist would violate data consistency — prices at T+5 minutes may differ from prices at T. The orchestrator's task state store (Redis or equivalent) persists the artifact across the Writer's failure so the exactly-once Market Data guarantee holds regardless of Writer restarts. Verify by reading the Market Data Specialist's request log: it must show exactly one `POST /a2a/` for the original `contextId`, even after multiple Writer retries. [WorkOS](https://workos.com/blog/ai-agent-credentials) articulates the scope-attenuation invariant that motivates this: data sourced during a delegation must not silently re-expand or change when a downstream step retries.

---

## One Trace, Four Agents

The `traceparent` header from [[chapter-09.md]] ties the entire run into one timeline. The orchestrator generates the root span and injects `traceparent` into every outbound A2A task. Each specialist extracts the propagated context on receipt and creates child spans under the same `trace_id`. All four agents' spans arrive at Langfuse via OTLP and render as a directed agent graph with latency and token cost annotated per edge. ([Langfuse Observability Overview](https://langfuse.com/docs/observability/overview))

Four observable signals confirm the full network is wired: one `trace_id` spans all four agents; protocol latency gaps appear between each specialist's child span start and the preceding agent's send span end; Langfuse annotates per-agent token cost automatically from span usage attributes; filtering by the root `contextId` returns every span with no orphaned islands.

---

## Production-Readiness Checklist and ADRs

Three architecture decisions close the production gaps that the capstone leaves open.

**ADR-01 — Agent Card Signing.** Cards are served unsigned in this capstone. Production deployments must sign cards or serve them exclusively over mTLS-authenticated endpoints — an unsigned card on a compromised CDN can redirect callers to a malicious agent with a fabricated capability set. ([Red Hat](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security))

**ADR-02 — Scope Attenuation at Every Hop.** Every token the orchestrator mints for a sub-agent task must be scoped to the intersection of the orchestrator's own scope and the specialist's declared skill scope. Permissions only narrow at each delegation hop — a specialist token that exceeds the orchestrator's grant is a security violation, not a configuration choice. ([WorkOS scope attenuation](https://workos.com/blog/ai-agent-credentials))

**ADR-03 — Durable Task State Store.** The capstone uses an in-process state dictionary. That store is lost when the orchestrator restarts. Production requires Redis or a Postgres-backed task table so artifact persistence — and therefore the resumability invariant — survives orchestrator failures independently of specialist failures.

---

## Hands-On: Launch, Test, and Trace the Full Network

**Goal:** All four success criteria pass before the exercise is complete.

```bash
# Start the full network
docker compose up --build

# 1. DPoP rejection test — bearer token, no DPoP proof
curl -X POST http://localhost:8001/a2a/ \
     -H "Authorization: Bearer <valid_token>" \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"tasks/send","id":1,"params":{"task":{"skill":"equity_price_history","message":{"parts":[{"type":"text","text":"AAPL 2024-01-01 2024-12-31"}]}}}}'
# Expected: HTTP 401 — WWW-Authenticate: DPoP header present

# 2. Submit a full investment research task via orchestrator
curl -X POST http://localhost:8000/a2a/ \
     -H "Authorization: DPoP <access_token>" \
     -H "DPoP: <proof_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"query":"AAPL vs MSFT 2024 annual performance","tickers":["AAPL","MSFT"]}'
# Save the contextId from the response.

# 3. Resume test — kill the Writer container after it logs "Market Data artifact received"
docker stop sovereign-agent-writer
# Re-dispatch the Writer with the original contextId (orchestrator retries automatically on FAILED)
docker start sovereign-agent-writer
```

**Success criteria — all four must pass:**

1. **DPoP rejection:** The request with a valid bearer token and no `DPoP` header returns `401` with `WWW-Authenticate: DPoP` — not `403`, not `200`.
2. **End-to-end COMPLETED:** The orchestrator's root task reaches `COMPLETED` with a Financial Writer artifact in its output containing both market data and sentiment sections.
3. **Resume without re-run:** After the Writer is killed and restarted, the Market Data Specialist's request log shows exactly one `POST /a2a/` for the original `contextId`, regardless of how many times the Writer retried.
4. **One trace:** Open Langfuse (`http://localhost:3000`), filter by `contextId`. One trace shows all four agents' spans under the same `trace_id` with no orphaned islands and protocol latency gaps visible between each specialist handoff.

---

You've built the Sovereign Agent Network. Every primitive from this course now operates at full resolution: A2A handshakes from [[chapter-02.md]], AGNTCY-style discovery from [[chapter-03.md]], MCP tool proxying from [[chapter-05.md]], hub-and-spoke orchestration from [[chapter-06.md]], resilience patterns from [[chapter-07.md]], DPoP auth hardening from [[chapter-08.md]], and the distributed trace from [[chapter-09.md]]. The production gaps — card signing, durable state storage, scope attenuation at every delegation hop — are documented as ADRs you own.

---

*Sources: [A2A Protocol Specification](https://a2a-protocol.org) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [Fossible A2A+MCP Practical Guide](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02) · [RFC 9449: DPoP](https://datatracker.ietf.org/doc/html/rfc9449) · [WorkOS: DPoP Explained](https://workos.com/blog/dpop-rfc-9449-explained) · [WorkOS: AI Agent Credentials](https://workos.com/blog/ai-agent-credentials) · [Red Hat: Enhance A2A Security](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security) · [Langfuse Observability Overview](https://langfuse.com/docs/observability/overview) · [Langfuse Self-Hosting](https://langfuse.com/self-hosting)*

