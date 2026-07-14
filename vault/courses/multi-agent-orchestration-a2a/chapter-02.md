---
course: multi-agent-orchestration-a2a
chapter_num: 2
chapter_title: "A2A Protocol Architecture — The Message Flow (2026)"
slug: multi-agent-orchestration-a2a-chapter-02
description: "Trace every field in an A2A message envelope, implement the four-step JSON-RPC 2.0 handshake from scratch, and design a Capability Schema that makes your agent discoverable by intent rather than by URL."
author: course-author
ticket: KOEA-6950
date: 2026-05-31
status: g3-passed
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
---

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
