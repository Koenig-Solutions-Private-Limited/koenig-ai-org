---
course: multi-agent-orchestration-a2a
chapter_num: 5
chapter_title: "Tool-Sharing & Resource Injection with MCP (2026)"
author: course-author
ticket: KOEA-6978
date: 2026-05-31
status: draft-for-review
level: Advanced
duration_min: 55
reading_time_min: 14
prerequisites_chapters:
  - 2
  - 4
learning_objectives:
  - Integrate an MCP server into an A2A agent's capability set by mapping MCP tool schemas into the A2A skills array at startup
  - Implement the Tool Proxy pattern — Agent A serves Agent B's tool calls by translating an incoming A2A sendMessage into a local MCP tools/call without duplicating any tool implementation
  - Design a Resource Injection flow in which an Orchestrator serializes MCP Resources into A2A DataParts before task delegation, so downstream specialists receive pre-loaded context in one message
  - Map every step of the MCP-to-A2A translation layer — from incoming A2A sendMessage to MCP tool call to packaged A2A artifact
positions:
  - id: stance:open-standards-over-vendor-lock-in
    engagement: defends
chapter_primary_query: "MCP tool sharing A2A protocol cross-agent tool injection 2026"
first_60_words_answer: "To share MCP tools across A2A agents: expose the tools through an MCP server running inside Agent A; advertise those tools as A2A skills in Agent A's AgentCard; when Agent B needs a tool, it sends an A2A sendMessage to Agent A, which translates the message into an MCP tools/call request, executes it locally, and returns the result as a DataPart in the A2A response."
faq:
  - question: "How do you share MCP tools between A2A agents?"
    answer: "Run the MCP server inside the agent that owns the capability. Advertise its tools as skills in that agent's A2A AgentCard. Other agents send A2A sendMessage requests to the owner agent, which proxies the request to its local MCP server via a tools/call and returns the result as a DataPart. This is the Tool Proxy pattern — no tool duplication, no hidden dependency."
  - question: "What is the difference between MCP and A2A?"
    answer: "MCP (Model Context Protocol) is the local bus — it connects an LLM to its tools, resources, and context within a single agent process boundary. A2A is the network protocol — it connects agents to other agents across process, host, or organization boundaries. You need both: MCP for what an agent can do locally, A2A for how it shares that capability with the rest of the network."
  - question: "What is Resource Injection in A2A and MCP?"
    answer: "Resource Injection is the pattern where an Orchestrator agent reads MCP Resources (documents, schemas, config data) and serializes them as DataParts or TextParts inside an A2A sendMessage before delegating a task. The downstream specialist receives both the task instructions and the pre-loaded context in one message, without needing to re-fetch those resources itself."
  - question: "What is MCP Server Pooling and when should I use it?"
    answer: "MCP Server Pooling means running a single MCP server instance (using the SSE or HTTP transport) that multiple A2A agents connect to simultaneously over the network. Use it when more than one agent needs the same tool — for example, both a Market Data Agent and a Synthesis Agent need SQLite access. The pool centralizes implementation and connection management; each agent connects as a client."
  - question: "How does the MCP-to-A2A translation layer work?"
    answer: "The bridge extracts the skill_id and arguments from the incoming A2A DataPart, maps the skill_id to the corresponding MCP tool name, sends an MCP tools/call request to the local MCP server, receives the result, parses the MCP text content as JSON, and packages it into an A2A DataPart inside the artifacts array of the sendMessage response. The A2A contextId and taskId are managed by the bridge; MCP is stateless per-call."
inline_assets:
  - type: diagram
    path: ./img/ch05-mcp-a2a-bridge-architecture.png
    alt: "MCP-A2A Bridge Architecture: left side shows Researcher Agent sending A2A sendMessage (JSON-RPC 2.0 POST) to Market Data Agent; center shows Market Data Agent's Bridge layer receiving the A2A message, extracting skill_id 'mcp.market-data.query_sqlite' and SQL arguments from DataPart, translating to MCP tools/call request (name: query_sqlite, arguments: {sql: '...'}), and sending to the MCP SQLite Server via SSE transport on port 8080; right side shows MCP SQLite Server executing the SQL query against market_data.db, returning MCP tool result (content[0].text: JSON array string), which the Bridge parses and packages into an A2A response DataPart inside the artifacts array."
  - type: diagram
    path: ./img/ch05-resource-injection-flow.png
    alt: "Resource Injection flow: Orchestrator Agent reads two MCP Resources from its local MCP server — company_profile.json (uri: mcp:///company-profiles/AAPL.json) and earnings-output-schema.json; serializes both into DataParts; constructs A2A sendMessage with one TextPart (task instruction) and two DataParts (injected resources); sends the enriched sendMessage to the Analyst Specialist Agent; Analyst Specialist receives all three parts simultaneously, uses DataParts as pre-loaded context without any re-fetch; produces analysis result and sends A2A sendMessage response (DataPart artifact) back to Orchestrator."
last_updated: 2026-05-31
sources:
  - https://modelcontextprotocol.io/introduction
  - https://modelcontextprotocol.io/docs/concepts/tools
  - https://modelcontextprotocol.io/docs/concepts/resources
  - https://modelcontextprotocol.io/docs/concepts/transports
  - https://a2a-protocol.org/latest/specification/
  - https://github.com/modelcontextprotocol/servers
  - https://github.com/a2aproject/A2A
---

# Tool-Sharing & Resource Injection with MCP (2026)

> **Chapter 5 of 10 · 55 min (prose ~14 min + 30 min hands-on exercise)**

---

To share MCP tools across A2A agents: expose the tools through an MCP server running inside Agent A; advertise those tools as A2A skills in Agent A's AgentCard; when Agent B needs a tool, it sends an A2A `sendMessage` to Agent A, which translates the message into an MCP `tools/call` request, executes it locally, and returns the result as a DataPart in the A2A response.

Chapter 4 defined what each specialist does in isolation — precise role boundaries, scope enforcement, cost models. This chapter answers the next question: when a specialist needs a tool that another agent owns, how does it get access without duplicating the implementation or creating a hidden dependency? The answer is the **MCP-A2A Bridge**: MCP as the local capability bus, A2A as the sharing network.

---

## The Contrarian Opening: You Need Both, and Here's Why Most Systems Get It Wrong

Most multi-agent tutorials treat tool access as a solved problem. They give every agent an identical tool list, assume each agent can call any tool at any time, and call it "shared tooling." This is not tool sharing — it's tool duplication with a veneer of coordination.

The failure mode is subtle but expensive. When you duplicate the SQLite connection, the web scraper, or the PDF parser across six agents, you create six independent implementations. When the database schema changes, you update six code paths and miss two. When the scraper's auth token expires, it expires in six places independently. When you add rate limiting, you add it six times. And when the MCP server's behavior changes after a library upgrade, you discover the inconsistency in production, three agents deep in a workflow.

The right mental model is borrowed from two protocols you already know.

**USB** is the local bus. It connects a peripheral — a keyboard, a drive, a camera — to a host. The peripheral exposes a capability; the host invokes it. USB works within a single device's physical boundary. You do not use USB to share a keyboard between two laptops in different rooms.

**HTTP** is the network protocol. It connects a client to a server across network boundaries. HTTP does not define what the server can do; it defines how client and server communicate about it.

**[MCP](https://modelcontextprotocol.io/introduction) is USB. A2A is HTTP.**

MCP (Model Context Protocol) connects an LLM to its local tools, resources, and context within a single agent process boundary. It defines the wire format for tool calls, resource reads, and context injection between an agent and its capability layer. An MCP server runs as a subprocess (stdio transport) or as a local HTTP/SSE server — both within or adjacent to a single agent instance.

A2A is the protocol that connects agents to *other agents* across process, host, or organization boundaries. It defines how agents negotiate capabilities, delegate tasks, and exchange results. A2A does not know what a tool is; it knows that Agent B has a skill that Agent A needs.

The bridge between the two — the **MCP-A2A Bridge** — is the architectural component that:
1. Translates an incoming A2A `sendMessage` into an MCP `tools/call` request
2. Executes the tool via the local MCP server
3. Packages the MCP result into an A2A response DataPart

Without this bridge, your A2A specialists are isolated silos. With it, every MCP tool an agent owns becomes a shareable capability across the entire agent network.

<Callout type="hot">
  The MCP specification (version 2025-11-05, the current stable release as of 2026) distinguishes between three transport types: **stdio** (subprocess, for local tools owned by a single process), **SSE** (Server-Sent Events over HTTP, for shared/pooled servers accessible to multiple agents), and **HTTP** (stateless, for REST-compatible deployments). For cross-agent tool sharing via A2A, the SSE or HTTP transport is required — stdio is per-process and cannot be shared across A2A endpoints. Choose your transport before designing the bridge.
</Callout>

---

## MCP in 60 Seconds: The Concepts You Need for This Chapter

If you've worked with MCP before, skip ahead. If MCP is hazy, here are the three concepts this chapter builds on.

### Concept 1: Tools

An MCP Tool is a callable function with a JSON Schema input definition. The MCP server exposes a `tools/list` endpoint that returns the catalog and a `tools/call` endpoint that executes a specific tool:

```json
// tools/list response (abbreviated)
{
  "tools": [
    {
      "name": "query_sqlite",
      "description": "Run a read-only SQL query against the market data SQLite database. Returns rows as a JSON array.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "sql": { "type": "string", "description": "The SQL SELECT query to execute." }
        },
        "required": ["sql"]
      }
    }
  ]
}
```

```json
// tools/call request
{
  "name": "query_sqlite",
  "arguments": {
    "sql": "SELECT ticker, close_price, date FROM prices WHERE ticker = 'AAPL' ORDER BY date DESC LIMIT 10"
  }
}

// tools/call response
{
  "content": [
    {
      "type": "text",
      "text": "[{\"ticker\": \"AAPL\", \"close_price\": 198.42, \"date\": \"2026-05-30\"}, ...]"
    }
  ],
  "isError": false
}
```

### Concept 2: Resources

An MCP Resource is a named document or data item readable by the agent. Resources have a `uri` (e.g., `sqlite:///market.db/schema`) and a `mimeType`. They are read via `resources/read`, not invoked like tools. Resources are ideal for injecting static or slow-changing context — database schemas, configuration files, reference documents — before a task begins.

### Concept 3: Transport

The **stdio** transport runs the MCP server as a subprocess of the agent process. The **SSE** transport runs the MCP server as a standalone HTTP server that any number of agents can connect to over the network. For single-agent local tooling: stdio. For shared cross-agent capability: SSE (or HTTP).

---

## Integrating an MCP Server into an A2A Agent's Capability Set

The first step in building an MCP-A2A Bridge is advertising the MCP server's tools in the A2A agent's AgentCard. This makes the tools discoverable to the rest of the A2A network without exposing the MCP server directly.

The pattern: on startup, the agent queries its local MCP server for the tool catalog (`tools/list`), then maps each MCP Tool into an A2A Skill. The mapping is direct because both MCP Tools and A2A Skills share the same core semantic: a name, a natural-language description, input types, and output types.

### The MCP-to-Skill Mapping

| MCP Tool Field | A2A Skill Field | Notes |
|---|---|---|
| `name` | `id` | Use `mcp.<server-name>.<tool-name>` as the A2A skill ID to avoid collisions with non-MCP skills |
| `description` | `description` | Copy verbatim — MCP tool descriptions are already natural-language capability statements |
| `inputSchema` (JSON Schema) | stored in `metadata.mcp_input_schema` | A2A Skills don't carry JSON Schema; store it in metadata for the bridge to use at call time |
| JSON result (always) | `outputModes: ["data"]` | MCP tool results serialize to JSON; map to A2A DataPart |
| text or data arguments | `inputModes: ["text", "data"]` | Callers send tool arguments as a DataPart; some accept a plain TextPart for natural-language queries |

```python
import httpx
import json


MCP_SERVER_URL = "http://localhost:8080"  # SSE transport


def build_a2a_skills_from_mcp() -> list[dict]:
    """
    Query the MCP server's tool catalog and map each tool to an A2A Skill.
    Called at agent startup to populate the AgentCard dynamically.
    """
    response = httpx.get(f"{MCP_SERVER_URL}/tools/list")
    tools = response.json()["tools"]

    skills = []
    for tool in tools:
        skill = {
            "id": f"mcp.market-data.{tool['name']}",
            "name": tool["name"].replace("_", " ").title(),
            "description": tool["description"],
            "inputModes": ["text", "data"],
            "outputModes": ["data"],
            "tags": ["mcp-backed", "market-data", "database"],
            "metadata": {
                "mcp_server": MCP_SERVER_URL,
                "mcp_tool_name": tool["name"],
                "mcp_input_schema": tool.get("inputSchema", {})
            }
        }
        skills.append(skill)

    return skills
```

When the Market Data Agent starts, it calls `build_a2a_skills_from_mcp()` and includes the returned skills in its AgentCard response at `/.well-known/agent.json`. The Researcher Agent, when it fetches the AgentCard, sees skills like `mcp.market-data.query_sqlite` — it doesn't need to know the skill is MCP-backed. From A2A's perspective, it is just a skill.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt={`You are building the Market Data Agent's A2A AgentCard. The agent runs an MCP SQLite server with these three tools:

1. name: "query_sqlite"
   description: "Run a read-only SQL SELECT query against the market data SQLite database. Returns rows as a JSON array of objects. Supports standard SQLite SQL syntax. Maximum 1000 rows returned."
   inputSchema requires: sql (string)

2. name: "list_tickers"
   description: "Returns a JSON array of all ticker symbols available in the database, each with their company name and sector."
   inputSchema: no required arguments (empty object)

3. name: "get_price_range"
   description: "Returns daily OHLCV (open, high, low, close, volume) data for a ticker between two dates. Returns a JSON array with fields: date, open, high, low, close, volume."
   inputSchema requires: ticker (string), start_date (string YYYY-MM-DD), end_date (string YYYY-MM-DD)

Generate the complete A2A AgentCard JSON for the Market Data Agent. Map each MCP tool to an A2A Skill using the skill id format "mcp.market-data.<tool_name>". Include:
- name: "Market Data Agent"
- url: "https://market-data-agent.internal/a2a"
- version: "1.0.0", protocolVersion: "1.0"
- capabilities: streaming false, pushNotifications true
- For each skill: id, name (title-cased), description (copy from MCP), inputModes ["text","data"], outputModes ["data"], tags ["mcp-backed","market-data","database"], and a metadata object with mcp_tool_name and mcp_input_schema
- defaultInputModes: ["text", "data"], defaultOutputModes: ["data"]
- securitySchemes: apiKey in header "X-Agent-Key"

Format as clean, properly indented JSON.`}
  expectedOutput={`{
  "name": "Market Data Agent",
  "url": "https://market-data-agent.internal/a2a",
  "version": "1.0.0",
  "protocolVersion": "1.0",
  "capabilities": {
    "streaming": false,
    "pushNotifications": true
  },
  "skills": [
    {
      "id": "mcp.market-data.query_sqlite",
      "name": "Query Sqlite",
      "description": "Run a read-only SQL SELECT query against the market data SQLite database. Returns rows as a JSON array of objects. Supports standard SQLite SQL syntax. Maximum 1000 rows returned.",
      "inputModes": ["text", "data"],
      "outputModes": ["data"],
      "tags": ["mcp-backed", "market-data", "database"],
      "metadata": {
        "mcp_tool_name": "query_sqlite",
        "mcp_input_schema": {
          "type": "object",
          "properties": {"sql": {"type": "string"}},
          "required": ["sql"]
        }
      }
    },
    {
      "id": "mcp.market-data.list_tickers",
      "name": "List Tickers",
      "description": "Returns a JSON array of all ticker symbols available in the database, each with their company name and sector.",
      "inputModes": ["text", "data"],
      "outputModes": ["data"],
      "tags": ["mcp-backed", "market-data", "database"],
      "metadata": {
        "mcp_tool_name": "list_tickers",
        "mcp_input_schema": {}
      }
    },
    {
      "id": "mcp.market-data.get_price_range",
      "name": "Get Price Range",
      "description": "Returns daily OHLCV (open, high, low, close, volume) data for a ticker between two dates. Returns a JSON array with fields: date, open, high, low, close, volume.",
      "inputModes": ["text", "data"],
      "outputModes": ["data"],
      "tags": ["mcp-backed", "market-data", "database"],
      "metadata": {
        "mcp_tool_name": "get_price_range",
        "mcp_input_schema": {
          "type": "object",
          "properties": {
            "ticker": {"type": "string"},
            "start_date": {"type": "string"},
            "end_date": {"type": "string"}
          },
          "required": ["ticker", "start_date", "end_date"]
        }
      }
    }
  ],
  "defaultInputModes": ["text", "data"],
  "defaultOutputModes": ["data"],
  "securitySchemes": {
    "apiKey": {"type": "apiKey", "in": "header", "name": "X-Agent-Key"}
  },
  "security": [{"apiKey": []}]
}`}
/>

---

## Tool Proxying: How Agent A Exposes Its MCP Tools to Agent B

With the AgentCard advertising the MCP-backed skills, the next piece is the server-side handler that executes the tool call. This is the **Tool Proxy**: when an A2A `sendMessage` arrives for skill `mcp.market-data.query_sqlite`, the Market Data Agent's handler translates it into an MCP `tools/call` request, gets the result, and packages it back as an A2A response.

### The Full Translation Sequence

```
Researcher Agent                    Market Data Agent
───────────────                     ─────────────────────────────────────
                                    [MCP SQLite Server: localhost:8080]

sendMessage ──────────────────────>
{
  method: "sendMessage",
  params: {
    message: {
      role: "ROLE_USER",
      parts: [{
        kind: "data",
        data: {
          skill_id: "mcp.market-data.query_sqlite",
          arguments: {
            sql: "SELECT ticker, close_price
                  FROM prices WHERE ticker='AAPL'
                  ORDER BY date DESC LIMIT 5"
          }
        }
      }]
    }
  }
}

                                    [Bridge: extract skill_id + arguments]
                                    [Map skill_id → MCP tool name]
                                    ──> MCP tools/call {
                                          name: "query_sqlite",
                                          arguments: {sql: "..."}
                                        }

                                    <── MCP result: {
                                          content: [{type:"text",
                                            text:"[{\"ticker\":\"AAPL\",...}]"}],
                                          isError: false
                                        }

                                    [Bridge: parse JSON, build A2A DataPart]

<────────────────── sendMessage response {
                      result: {
                        id: "task-abc",
                        status: {state: "COMPLETED"},
                        artifacts: [{parts: [{
                          kind: "data",
                          data: [{ticker:"AAPL", close_price:198.42}, ...]
                        }]}]
                      }
                    }
```

### Python Implementation

```python
import httpx
import json
from typing import Any


MCP_SERVER_URL = "http://localhost:8080"

SKILL_TO_MCP_TOOL = {
    "mcp.market-data.query_sqlite": "query_sqlite",
    "mcp.market-data.list_tickers": "list_tickers",
    "mcp.market-data.get_price_range": "get_price_range",
}


def extract_tool_call_from_a2a(message: dict) -> tuple[str, dict]:
    """
    Extracts the MCP tool name and arguments from an A2A sendMessage payload.
    Expects a DataPart with skill_id and arguments fields.
    """
    parts = message.get("params", {}).get("message", {}).get("parts", [])

    for part in parts:
        if part.get("kind") == "data":
            data = part.get("data", {})
            skill_id = data.get("skill_id")
            arguments = data.get("arguments", {})

            mcp_tool_name = SKILL_TO_MCP_TOOL.get(skill_id)
            if not mcp_tool_name:
                raise ValueError(f"Unknown skill_id: {skill_id}")

            return mcp_tool_name, arguments

    raise ValueError("No DataPart with skill_id found in A2A message")


def call_mcp_tool(tool_name: str, arguments: dict) -> Any:
    """
    Executes a tool call against the local MCP server (SSE transport).
    Returns the parsed tool result.
    """
    response = httpx.post(
        f"{MCP_SERVER_URL}/tools/call",
        json={"name": tool_name, "arguments": arguments},
        timeout=30.0
    )
    response.raise_for_status()
    result = response.json()

    if result.get("isError"):
        raise RuntimeError(f"MCP tool error: {result['content'][0]['text']}")

    raw = result["content"][0]["text"]
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def handle_mcp_tool_proxy(request_body: dict, task_id: str) -> dict:
    """
    Full A2A handler for MCP-backed skills.
    Translates A2A sendMessage → MCP tools/call → A2A response.
    """
    try:
        tool_name, arguments = extract_tool_call_from_a2a(request_body)
        result = call_mcp_tool(tool_name, arguments)
    except (ValueError, RuntimeError) as err:
        return {
            "jsonrpc": "2.0",
            "error": {"code": -32001, "message": str(err)},
            "id": request_body.get("id")
        }

    context_id = (
        request_body.get("params", {})
        .get("message", {})
        .get("contextId", "")
    )

    return {
        "jsonrpc": "2.0",
        "result": {
            "id": task_id,
            "contextId": context_id,
            "status": {"state": "COMPLETED"},
            "artifacts": [{
                "artifactId": f"result-{task_id}",
                "parts": [{"kind": "data", "data": result}]
            }]
        },
        "id": request_body.get("id")
    }
```

The key insight: the Researcher Agent never imports `sqlite3`, never holds a database connection, and never implements a query engine. It sends an A2A message and receives a result. All the database machinery lives in the Market Data Agent's MCP server, where it belongs. When the database schema changes, you update one agent and one MCP server — not six.

<KnowledgeCheck
  question="The Researcher Agent wants to call the `get_price_range` tool owned by the Market Data Agent. Which statement correctly describes the role of A2A versus MCP in this interaction?"
  answers={[
    "A2A replaces MCP — the Researcher Agent uses A2A to call the MCP tool's JSON Schema directly",
    "A2A is the network transport between the Researcher and Market Data agents; MCP is the local transport between the Market Data agent and its SQLite server — both protocols are required",
    "The Researcher Agent uses A2A to register itself as a named MCP client of the Market Data Agent's MCP server",
    "A2A's DataPart is the same wire format as an MCP tools/call request — no translation is needed at the bridge"
  ]}
  correct={1}
/>

---

## Resource Injection: Orchestrators Loading Context Before Delegation

Tool Proxying handles capability sharing: Agent B can *do* what Agent A can do. Resource Injection handles context sharing: Agent B can *know* what Agent A knows before it starts its task.

The problem it solves: an Orchestrator has assembled rich context — a company's financial profile, the user's stated constraints, a required output schema — before deciding which specialist to hire. Without Resource Injection, the specialist must re-fetch all of that context itself. This creates duplicate network calls, potential data staleness (the Specialist's fetch may return different data than the Orchestrator's), and wasted tokens on repeated retrieval.

With Resource Injection, the Orchestrator:
1. Reads the relevant MCP Resources from its own context store via `resources/read`
2. Serializes them as A2A DataParts
3. Includes them in the `sendMessage` payload alongside the task instructions

The specialist receives both the task and the pre-loaded context in one message.

### Reading an MCP Resource for Injection

```python
def read_mcp_resource(resource_uri: str) -> dict:
    """
    Reads an MCP Resource from the Orchestrator's local MCP server.
    Returns a structured dict suitable for injection into an A2A DataPart.
    """
    response = httpx.post(
        f"{MCP_SERVER_URL}/resources/read",
        json={"uri": resource_uri}
    )
    response.raise_for_status()
    content = response.json()["contents"][0]

    if content.get("mimeType") == "application/json":
        return json.loads(content["text"])
    return {"raw": content["text"], "mimeType": content.get("mimeType")}


def build_injected_sendmessage(
    task_instruction: str,
    context_id: str,
    resource_uris: list[str]
) -> dict:
    """
    Builds an A2A sendMessage payload with injected MCP resources as DataParts.
    The task instruction goes in a TextPart; each resource becomes a DataPart.
    """
    import uuid

    parts = [{"kind": "text", "text": task_instruction}]

    for uri in resource_uris:
        resource_data = read_mcp_resource(uri)
        parts.append({
            "kind": "data",
            "data": {
                "resource_uri": uri,
                "content": resource_data
            }
        })

    return {
        "jsonrpc": "2.0",
        "method": "sendMessage",
        "params": {
            "message": {
                "role": "ROLE_USER",
                "messageId": str(uuid.uuid4()),
                "contextId": context_id,
                "parts": parts
            },
            "configuration": {
                "blocking": False,
                "acceptedOutputModes": ["data"]
            }
        },
        "id": str(uuid.uuid4())
    }
```

### A Concrete Injection Example

The Orchestrator is delegating an "Earnings Analysis" task to the Analyst Specialist. Before dispatching, it loads two MCP Resources from its own context store — a company financial profile and the required output schema — and injects both:

```python
payload = build_injected_sendmessage(
    task_instruction=(
        "Analyze Apple's Q2 2026 earnings release against the injected company profile. "
        "Use the injected output schema for your response format. "
        "Focus on revenue by segment and any forward guidance changes."
    ),
    context_id="ctx-invest-research-0001",
    resource_uris=[
        "mcp:///company-profiles/AAPL.json",
        "mcp:///schemas/earnings-analysis-output-v2.json"
    ]
)
```

The Analyst Specialist receives a single `sendMessage` with three Parts: one TextPart (the task instruction) and two DataParts (the injected resources). It reads the company profile and output schema from those DataParts without any additional network call.

<Callout type="warning">
  **Resource injection is a one-way snapshot.** The Specialist works with the resource data at the moment the `sendMessage` was built. If the resource changes after the message is sent — for example, a company profile is updated mid-workflow — the Specialist uses the stale snapshot. For resources that change frequently (live prices, real-time news feeds), use Tool Proxying instead: let the Specialist call the Market Data Agent's `get_price_range` skill at execution time rather than injecting a snapshot. Use injection for slow-changing reference data (schemas, profiles, configuration), and proxying for live data.
</Callout>

---

## The MCP-to-A2A Translation Layer: Full Capability Map

You've seen Tool Proxying and Resource Injection as separate patterns. In a production bridge, both live in the same component. This section maps the full translation layer and introduces **MCP Server Pooling** — the pattern for sharing a single MCP server across multiple A2A agents.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Market Data Agent                      │
│                                                         │
│  ┌──────────────┐    ┌───────────────────────────────┐  │
│  │   A2A Server │    │       MCP-A2A Bridge           │  │
│  │  (FastAPI/   │    │                               │  │
│  │   JSON-RPC)  │───>│  1. Route by skill_id          │  │
│  │              │    │  2. Extract tool name + args   │  │
│  │ /.well-known │    │  3. Call MCP tools/call        │  │
│  │ /agent.json  │    │  4. Package result as DataPart │  │
│  └──────────────┘    └────────────────┬──────────────┘  │
│                                        │                 │
└────────────────────────────────────────┼─────────────────┘
                                         │ SSE transport
                                         ▼
                          ┌─────────────────────────┐
                          │   MCP SQLite Server      │
                          │   (port 8080, SSE)       │
                          │                          │
                          │  tools/list              │
                          │  tools/call              │
                          │  resources/list          │
                          │  resources/read          │
                          └──────────────┬───────────┘
                                         │
                                         ▼
                          ┌─────────────────────────┐
                          │    market_data.db        │
                          │    (SQLite)              │
                          └─────────────────────────┘
```

### MCP Server Pooling

In production, the MCP SQLite server doesn't need to run as a subprocess of the Market Data Agent. Running it as a standalone SSE server means multiple agents can connect simultaneously:

```bash
# Start once; all agents connect to port 8080
uvx mcp-server-sqlite --db-path ./market_data.db --transport sse --port 8080
```

Benefits:
- A single MCP server instance serves the Market Data Agent, the Synthesis Agent, and any future agent that needs database access
- The database connection pool is centralized — no per-agent connection overhead
- Tool implementation updates deploy once, propagate to all agents immediately via the shared endpoint

Any A2A agent that needs database access connects to `http://mcp-sqlite.internal:8080` using the same `httpx.post(f"{MCP_SERVER_URL}/tools/call", ...)` pattern from the Tool Proxy implementation.

### Full Capability Mapping Reference

| A2A Concept | MCP Equivalent | Translation |
|---|---|---|
| `skill.id` | `tool.name` | Startup: MCP tool name → A2A skill ID (prefix `mcp.<server>.<name>`) |
| `skill.description` | `tool.description` | Startup: direct copy, MCP → A2A |
| `skill.inputModes` | `tool.inputSchema` | Startup: any MCP tool → `["text", "data"]` (A2A Skills don't carry JSON Schema) |
| `skill.outputModes` | implicit JSON result | Startup: MCP text/JSON output → `["data"]` |
| A2A DataPart in request | `tool.arguments` | Per-call: DataPart.data.arguments → MCP `tools/call` arguments object |
| MCP tool result text | A2A DataPart in artifact | Per-call: parse MCP `content[0].text` as JSON → A2A artifacts DataPart |
| MCP Resource content | A2A DataPart (injected) | Pre-delegation: Orchestrator `resources/read` → A2A DataPart inside `sendMessage` |
| A2A `contextId` | (no MCP equivalent) | Bridge manages; MCP calls are stateless per-invocation |
| A2A Task state machine | (no MCP equivalent) | Bridge manages SUBMITTED/WORKING/COMPLETED; MCP `tools/call` is synchronous |

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt={`You are implementing the MCP-A2A bridge for a Market Data Agent. An incoming A2A sendMessage payload arrives:

{
  "jsonrpc": "2.0",
  "method": "sendMessage",
  "params": {
    "message": {
      "role": "ROLE_USER",
      "messageId": "msg-aaa111",
      "contextId": "ctx-invest-001",
      "taskId": null,
      "parts": [
        {
          "kind": "data",
          "data": {
            "skill_id": "mcp.market-data.get_price_range",
            "arguments": {
              "ticker": "MSFT",
              "start_date": "2026-01-01",
              "end_date": "2026-03-31"
            }
          }
        }
      ]
    },
    "configuration": {"blocking": false, "acceptedOutputModes": ["data"]}
  },
  "id": "req-xyz789"
}

The MCP server returned this tools/call response:
{
  "content": [{"type": "text", "text": "[{\"date\":\"2026-03-31\",\"open\":412.50,\"high\":415.20,\"low\":410.80,\"close\":414.30,\"volume\":18500000},{\"date\":\"2026-03-30\",\"open\":409.10,\"high\":413.40,\"low\":408.50,\"close\":412.50,\"volume\":21300000}]"}],
  "isError": false
}

Write the complete A2A JSON-RPC response the Market Data Agent should return. The task_id is "task-mda-20260531-001". Include: jsonrpc, result.id, result.contextId (from the incoming message), result.status.state ("COMPLETED"), result.artifacts array with one artifact containing a DataPart with the parsed MSFT OHLCV data. The "id" field must match the incoming request id.`}
  expectedOutput={`{
  "jsonrpc": "2.0",
  "result": {
    "id": "task-mda-20260531-001",
    "contextId": "ctx-invest-001",
    "status": {
      "state": "COMPLETED"
    },
    "artifacts": [
      {
        "artifactId": "result-task-mda-20260531-001",
        "parts": [
          {
            "kind": "data",
            "data": [
              {
                "date": "2026-03-31",
                "open": 412.50,
                "high": 415.20,
                "low": 410.80,
                "close": 414.30,
                "volume": 18500000
              },
              {
                "date": "2026-03-30",
                "open": 409.10,
                "high": 413.40,
                "low": 408.50,
                "close": 412.50,
                "volume": 21300000
              }
            ]
          }
        ]
      }
    ]
  },
  "id": "req-xyz789"
}`}
/>

<KnowledgeCheck
  question="In the MCP-A2A bridge, what is the correct mapping when an MCP tool returns a result where content[0].text is a JSON string (e.g., '[{\"ticker\":\"AAPL\",...}]')?"
  answers={[
    "The raw MCP text string is placed directly in an A2A TextPart inside the artifacts array",
    "The MCP text content is parsed as JSON and placed in an A2A DataPart inside the artifacts array; if JSON parsing fails, fall back to a TextPart",
    "The MCP tool result is stored server-side and the A2A response includes only a taskId for the client to getTask later",
    "The MCP result is base64-encoded and placed in an A2A FilePart inside the artifacts array"
  ]}
  correct={1}
/>

---

## Hands-On Exercise: Connect a SQLite MCP Server to an A2A Agent and Implement Tool Sharing

**Time estimate:** 30 minutes

**Goal:** Set up a local MCP SQLite server, wire it to a Market Data Agent that serves A2A requests, and verify that a mock Researcher Agent can query the database via A2A without holding a direct database connection.

### Prerequisites

- Python 3.10+ and `pip` or `uv` installed
- `pip install mcp httpx fastapi uvicorn` (or `uv pip install ...`)
- Ports 8080 (MCP server) and 9000 (A2A agent) available

---

### Step 1: Create the SQLite Database

```python
# setup_db.py
import sqlite3

conn = sqlite3.connect("market_data.db")
conn.executescript("""
CREATE TABLE IF NOT EXISTS prices (
    ticker TEXT NOT NULL,
    date TEXT NOT NULL,
    close_price REAL NOT NULL,
    volume INTEGER NOT NULL,
    PRIMARY KEY (ticker, date)
);

INSERT OR IGNORE INTO prices VALUES
    ('AAPL', '2026-05-30', 198.42, 52300000),
    ('AAPL', '2026-05-29', 196.10, 48100000),
    ('MSFT', '2026-05-30', 414.30, 18500000),
    ('MSFT', '2026-05-29', 412.50, 21300000),
    ('NVDA', '2026-05-30', 1024.60, 33200000),
    ('NVDA', '2026-05-29', 1018.20, 29800000);
""")
conn.commit()
conn.close()
print("Database created: market_data.db")
```

Run: `python setup_db.py`

---

### Step 2: Start the MCP SQLite Server

The [`mcp-server-sqlite`](https://github.com/modelcontextprotocol/servers) reference implementation exposes `query` (or `query_sqlite`) as a built-in tool over the SSE transport.

```bash
# Terminal 1: start the MCP server
uvx mcp-server-sqlite --db-path ./market_data.db --transport sse --port 8080
```

Verify:
```bash
curl -s http://localhost:8080/tools/list | python3 -m json.tool
```

Expected: a JSON object with a `tools` array containing at least one tool (`query` or `query_sqlite`).

---

### Step 3: Implement the Market Data Agent

Create `market_data_agent.py`:

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import httpx
import json
import uuid


app = FastAPI()
MCP_SERVER_URL = "http://localhost:8080"

SKILL_TO_MCP = {
    "mcp.market-data.query_sqlite": "query_sqlite"
}


def call_mcp_tool(tool_name: str, arguments: dict):
    r = httpx.post(
        f"{MCP_SERVER_URL}/tools/call",
        json={"name": tool_name, "arguments": arguments},
        timeout=30.0
    )
    r.raise_for_status()
    result = r.json()
    if result.get("isError"):
        raise RuntimeError(result["content"][0]["text"])
    raw = result["content"][0]["text"]
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


@app.get("/.well-known/agent.json")
def agent_card():
    return {
        "name": "Market Data Agent",
        "url": "http://localhost:9000/a2a",
        "version": "1.0.0",
        "protocolVersion": "1.0",
        "capabilities": {"streaming": False, "pushNotifications": False},
        "skills": [{
            "id": "mcp.market-data.query_sqlite",
            "name": "Query SQLite",
            "description": (
                "Run a read-only SQL SELECT query against the market data database. "
                "Returns rows as a JSON array. Supports standard SQLite syntax. Max 1000 rows."
            ),
            "inputModes": ["text", "data"],
            "outputModes": ["data"],
            "tags": ["mcp-backed", "market-data", "sqlite"]
        }],
        "defaultInputModes": ["text", "data"],
        "defaultOutputModes": ["data"]
    }


@app.post("/a2a")
async def a2a_handler(request: Request):
    body = await request.json()
    req_id = body.get("id")
    msg = body.get("params", {}).get("message", {})
    context_id = msg.get("contextId", str(uuid.uuid4()))
    task_id = f"task-{uuid.uuid4().hex[:8]}"

    skill_id = None
    arguments = {}
    for part in msg.get("parts", []):
        if part.get("kind") == "data":
            skill_id = part["data"].get("skill_id")
            arguments = part["data"].get("arguments", {})
            break

    if not skill_id or skill_id not in SKILL_TO_MCP:
        return JSONResponse({
            "jsonrpc": "2.0",
            "error": {
                "code": -32001,
                "message": f"Unknown skill_id: {skill_id}",
                "data": {"offered_skills": list(SKILL_TO_MCP.keys())}
            },
            "id": req_id
        })

    try:
        result = call_mcp_tool(SKILL_TO_MCP[skill_id], arguments)
    except Exception as err:
        return JSONResponse({
            "jsonrpc": "2.0",
            "error": {"code": -32002, "message": str(err)},
            "id": req_id
        })

    return JSONResponse({
        "jsonrpc": "2.0",
        "result": {
            "id": task_id,
            "contextId": context_id,
            "status": {"state": "COMPLETED"},
            "artifacts": [{
                "artifactId": f"result-{task_id}",
                "parts": [{"kind": "data", "data": result}]
            }]
        },
        "id": req_id
    })
```

Start the agent:
```bash
# Terminal 2: start the A2A agent
uvicorn market_data_agent:app --port 9000
```

---

### Step 4: Test with a Mock Researcher Agent

```python
# test_researcher.py
import httpx
import json
import uuid


MARKET_DATA_AGENT = "http://localhost:9000"
ctx_id = str(uuid.uuid4())

# 1. Fetch AgentCard — verify the skill is advertised
card = httpx.get(f"{MARKET_DATA_AGENT}/.well-known/agent.json").json()
print("AgentCard skills:", [s["id"] for s in card["skills"]])

# 2. Send a tool call via A2A
payload = {
    "jsonrpc": "2.0",
    "method": "sendMessage",
    "params": {
        "message": {
            "role": "ROLE_USER",
            "messageId": str(uuid.uuid4()),
            "contextId": ctx_id,
            "taskId": None,
            "parts": [{
                "kind": "data",
                "data": {
                    "skill_id": "mcp.market-data.query_sqlite",
                    "arguments": {
                        "sql": "SELECT ticker, date, close_price FROM prices ORDER BY date DESC LIMIT 6"
                    }
                }
            }]
        },
        "configuration": {"blocking": False, "acceptedOutputModes": ["data"]}
    },
    "id": str(uuid.uuid4())
}

response = httpx.post(f"{MARKET_DATA_AGENT}/a2a", json=payload)
result = response.json()
print("Task status:", result["result"]["status"]["state"])
print("Query result:")
for row in result["result"]["artifacts"][0]["parts"][0]["data"]:
    print(f"  {row['ticker']}  {row['date']}  ${row['close_price']:.2f}")

# 3. Test rejection: unknown skill_id
bad_payload = {**payload, "id": str(uuid.uuid4())}
bad_payload["params"]["message"]["parts"][0]["data"]["skill_id"] = "mcp.market-data.nonexistent"
bad_response = httpx.post(f"{MARKET_DATA_AGENT}/a2a", json=bad_payload)
print("\nRejection test:")
print("Error code:", bad_response.json()["error"]["code"])
print("Error message:", bad_response.json()["error"]["message"])
```

Run: `python test_researcher.py`

---

### Success Criteria

- `curl http://localhost:8080/tools/list` returns a `tools` array with at least one tool
- `curl http://localhost:9000/.well-known/agent.json` returns an AgentCard with a skill id matching `mcp.market-data.query_sqlite`
- `test_researcher.py` prints `Task status: COMPLETED`
- The printed query result shows 6 rows with `ticker`, `date`, and `close_price` fields matching the database values from Step 1
- A call with skill_id `mcp.market-data.nonexistent` returns a JSON-RPC error with code `-32001` and a `data.offered_skills` list
- The Researcher test file has **zero** `import sqlite3` statements — all database access goes through the A2A→MCP chain

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| MCP (Model Context Protocol) | The "local bus" protocol connecting an agent to its tools, resources, and context within a single process boundary |
| A2A (Agent-to-Agent Protocol) | The "network protocol" connecting agents to other agents across process or host boundaries |
| MCP-A2A Bridge | The component inside an A2A agent that translates incoming `sendMessage` requests into MCP `tools/call` requests and packages results as DataParts |
| Tool Proxy | The pattern where Agent A serves Agent B's tool calls by proxying the A2A `sendMessage` to its local MCP `tools/call` — no tool duplication, single implementation |
| Resource Injection | The pattern where an Orchestrator reads MCP Resources and includes them as DataParts in the `sendMessage` to a Specialist, providing pre-loaded context without re-fetch |
| MCP Tool | A callable function exposed by an MCP server with a JSON Schema input definition; maps to an A2A Skill at startup |
| MCP Resource | A named data item readable via `resources/read`; used for context injection, not computation |
| MCP Server Pooling | Running a single MCP server instance (SSE transport) shared across multiple A2A agents to centralize capability and connection management |
| Capability Mapping | The translation table that converts MCP tool names, schemas, and results into A2A skill IDs, DataParts, and artifacts |
| SSE Transport | Server-Sent Events HTTP transport for MCP; enables one MCP server to serve multiple simultaneous agent connections over the network |

---

## What's Next

[[multi-agent-orchestration-a2a/chapter-06|Chapter 6: Orchestration Patterns — Chains, Hubs, and Meshes]] builds on the shared capability layer you've just established. You've given your specialists shared tools via Tool Proxying and shared context via Resource Injection. In Chapter 6, you'll wire those specialists into three distinct orchestration topologies — Linear Chain, Hub-and-Spoke, and Fully Connected Mesh — and measure the tradeoffs of each under production load.

You know how to share capability. Chapter 6 shows you how to orchestrate it at scale.

---

*Sources: [Model Context Protocol — Introduction](https://modelcontextprotocol.io/introduction) · [MCP Tools](https://modelcontextprotocol.io/docs/concepts/tools) · [MCP Resources](https://modelcontextprotocol.io/docs/concepts/resources) · [MCP Transports](https://modelcontextprotocol.io/docs/concepts/transports) · [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [MCP Reference Servers (GitHub)](https://github.com/modelcontextprotocol/servers) · [A2A GitHub Repository](https://github.com/a2aproject/A2A)*
