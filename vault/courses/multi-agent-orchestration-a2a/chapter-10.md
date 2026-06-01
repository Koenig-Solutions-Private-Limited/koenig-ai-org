---
date: 2026-05-31
author: course-author
ticket: KOEA-6940
course: multi-agent-orchestration-a2a
chapter: 10
chapter_title: "Capstone — Building the Sovereign Agent Network"
vendor_tag: google
content_type: article
level: Advanced
duration_min: 120
reading_time_min: 25
learning_objectives:
  - Assemble the course components into a working 4-agent A2A network with one orchestrator and three specialists
  - Publish and consume Agent Cards/capability advertisements for every specialist before any task handoff occurs
  - Validate the production path end to end — A2A handshake, MCP-backed market-data lookup, DPoP rejection test, resumability test, and distributed trace export
  - Package the project with a runnable README, test commands, and an architecture decision record that explains each protocol and topology choice
positions:
  - id: stance:arch-claude-agent-sdk
    engagement: defends
  - id: stance:multiagent-protocol-over-framework
    engagement: defends
chapter_primary_query: "how to build a production multi-agent A2A network with orchestrator and specialists"
first_60_words_answer: "To build a production A2A agent network in 2026, you need four components: an Orchestrator that discovers specialists via Agent Cards, a Market Data Specialist backed by an MCP server, a Sentiment Analyst, and a Financial Writer. The Orchestrator dispatches tasks using JSON-RPC 2.0, DPoP signs every message, and a shared state store makes every handoff resumable after failure."
faq:
  - question: "What is a sovereign agent network in the A2A protocol?"
    answer: "A sovereign agent network is a multi-agent system where each agent owns its identity, publishes its capabilities via an Agent Card, and communicates with peers exclusively through the A2A protocol — with no shared framework, no shared runtime, and no single point of coordination."
  - question: "How do you test failure resilience in an A2A multi-agent system?"
    answer: "Inject failures at known handoff boundaries — kill the downstream agent process, then verify the upstream agent reads from the state store and resumes from the last successful checkpoint, skipping completed phases rather than replaying them."
  - question: "What is an Architecture Decision Record (ADR) and why does a capstone project need one?"
    answer: "An ADR documents a single architectural choice, the options considered, the chosen option, and the rationale. In a capstone, an ADR forces you to articulate why you chose Hub-and-Spoke over a mesh, why JSON-RPC over REST, and why DPoP over API keys — so the design is reproducible, not accidental."
inline_assets:
  - type: diagram
    path: ./img/ch10-architecture.svg
    alt: "Four-agent Cross-Vendor Investment Researcher architecture: Orchestrator in the center connected to Market Data Specialist (MCP-backed), Sentiment Analyst, and Financial Writer via A2A JSON-RPC channels; Redis state store shared across all agents; OpenTelemetry collector receiving spans from each agent"
status: draft-for-review
sources:
  - https://a2a-protocol.org/latest/specification/
  - https://github.com/a2aproject/A2A
  - https://agntcy.org/
  - https://modelcontextprotocol.io/
  - https://www.rfc-editor.org/rfc/rfc9449
  - https://opentelemetry.io/docs/concepts/signals/traces/
---

# Build the Sovereign Agent Network — A2A Capstone 2026

> **Chapter 10 of 10 · 120 min (prose ~25 min + 90 min incremental build)**  
> **Prerequisites:** All previous chapters (Ch01–09)

---

A capstone is not a demo script.

If your system only starts cleanly when every service is online, every token is valid, and every agent responds within 100 ms, you have built a conference slide — not a production network. This chapter forces you to prove four things that cannot be faked: a working A2A handshake, a DPoP rejection, a crash-resume with no lost work, and a distributed trace that links every agent handoff. Build all four, and you have the foundation of a genuinely interoperable agent network. Skip any one, and you have a demo.

The project is the **Cross-Vendor Investment Researcher**: a 4-agent network that takes a stock ticker, collects market data, analyzes news sentiment, and produces a formatted research report — with the Orchestrator coordinating three fully independent specialists.

---

## Architecture: The Four-Agent Topology

The Cross-Vendor Investment Researcher uses a Hub-and-Spoke topology with one Orchestrator and three Specialists. Each agent publishes an `AgentCard` at `/.well-known/agent.json`. The Orchestrator discovers Specialists by capability query before issuing any task. No Specialist knows about any other Specialist.

```
                    ┌─────────────────────────────┐
                    │         Orchestrator          │
                    │   (Hub · Port 9000)           │
                    │  discovers via AgentCards      │
                    └──────────────┬───────────────┘
                          A2A JSON-RPC 2.0
            ┌─────────────┼──────────────────┐
            │             │                  │
   ┌────────▼──────┐  ┌───▼──────────┐  ┌───▼──────────────┐
   │ Market Data   │  │  Sentiment   │  │ Financial Writer  │
   │  Specialist   │  │   Analyst    │  │  (Port 9003)      │
   │  (Port 9001)  │  │  (Port 9002) │  │                   │
   │  MCP-backed   │  │              │  │  PDF output       │
   └───────────────┘  └─────────────┘  └──────────────────┘
                              │
                    ┌─────────▼────────┐
                    │  Redis State Store│
                    │  (shared context) │
                    └──────────────────┘
                              │
                    ┌─────────▼────────────┐
                    │  OpenTelemetry        │
                    │  Collector (Port 4317)│
                    └──────────────────────┘
```

*(Diagram: `./img/ch10-architecture.svg`)*

**Why Hub-and-Spoke for this capstone?** The Orchestrator controls workflow sequencing and state persistence. Market Data must complete before Sentiment Analysis begins (the sentiment model needs ticker context). A mesh topology would require Specialists to know each other's states — complicating the resumability story. The ADR at the end of this chapter formalizes this choice.

<Callout type="hot">
A2A v1.0.0 uses `contextId` as the global correlation key across agent boundaries. Every message in this project must carry the same `contextId` — this is what makes the distributed trace coherent and the state store lookup possible. Set it once in the Orchestrator when the research request arrives; pass it through every subsequent `sendMessage` call.
</Callout>

---

## Phase 1: The Minimal Viable Handshake

Before building the full network, prove that two agents can discover each other and exchange a task. Start with the Orchestrator and the Market Data Specialist only. Everything else is scaffolding until this succeeds.

### Agent Card Publication

Every Specialist publishes its `AgentCard` at startup. The card is the only source of truth about what the agent can do. The Orchestrator reads cards before dispatching — never after.

```python
# market_data_specialist/main.py
from fastapi import FastAPI
import uvicorn

AGENT_CARD = {
    "name": "Market Data Specialist",
    "description": "Fetches historical OHLCV data and fundamentals for equities",
    "version": "1.0.0",
    "url": "http://localhost:9001",
    "skills": [
        {
            "id": "market-data-lookup",
            "name": "Market Data Lookup",
            "description": "Retrieve 30-day OHLCV data and P/E ratio for a given ticker",
            "tags": ["finance", "market-data", "ohlcv"],
            "inputModes": ["text"],
            "outputModes": ["application/json"]
        }
    ],
    "defaultInputModes": ["text"],
    "defaultOutputModes": ["application/json", "text"],
    "capabilities": {
        "streaming": False,
        "pushNotifications": False,
        "stateTransitionHistory": True
    },
    "securitySchemes": {
        "dpop": {
            "type": "dpop",
            "description": "DPoP-bound token required for all task requests"
        }
    }
}

app = FastAPI()

@app.get("/.well-known/agent.json")
async def agent_card():
    return AGENT_CARD
```

The Orchestrator probes this endpoint before issuing any task:

```python
# orchestrator/discovery.py
import httpx
from typing import Optional

async def discover_specialist(base_url: str) -> Optional[dict]:
    """Fetch and validate a specialist's AgentCard."""
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{base_url}/.well-known/agent.json")
        if resp.status_code != 200:
            return None
        card = resp.json()
        required_fields = {"name", "skills", "url", "securitySchemes"}
        if not required_fields.issubset(card.keys()):
            raise ValueError(f"Incomplete AgentCard from {base_url}: missing {required_fields - card.keys()}")
        return card
```

### The First A2A Task

Once cards are verified, the Orchestrator dispatches a `sendMessage` call:

```python
# orchestrator/dispatch.py
import httpx
import uuid

async def dispatch_market_data(ticker: str, context_id: str, dpop_token: str) -> dict:
    payload = {
        "jsonrpc": "2.0",
        "id": str(uuid.uuid4()),
        "method": "message/send",
        "params": {
            "message": {
                "role": "user",
                "messageId": str(uuid.uuid4()),
                "contextId": context_id,
                "parts": [
                    {
                        "kind": "text",
                        "text": f"Retrieve 30-day OHLCV data and current P/E ratio for ticker: {ticker}"
                    }
                ]
            }
        }
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "http://localhost:9001/",
            json=payload,
            headers={
                "Content-Type": "application/json",
                "A2A-Version": "1.0",
                "Authorization": f"DPoP {dpop_token}"
            }
        )
        return resp.json()
```

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt={`You are an A2A Orchestrator. I have discovered a Market Data Specialist with this AgentCard skill:
{
  "id": "market-data-lookup",
  "description": "Retrieve 30-day OHLCV data and P/E ratio for a given ticker",
  "inputModes": ["text"],
  "outputModes": ["application/json"]
}

Write the complete JSON-RPC 2.0 sendMessage payload to request market data for ticker "NVDA". Include: jsonrpc field, id (UUID placeholder), method "message/send", and params.message with role "user", messageId (UUID placeholder), contextId "ctx-capstone-001", and a parts array with one text part containing the task description.`}
  expectedOutput='{"jsonrpc":"2.0","id":"<uuid>","method":"message/send","params":{"message":{"role":"user","messageId":"<uuid>","contextId":"ctx-capstone-001","parts":[{"kind":"text","text":"Retrieve 30-day OHLCV data and P/E ratio for ticker: NVDA"}]}}}'
/>

<KnowledgeCheck
  question="Why does the Orchestrator read each Specialist's AgentCard BEFORE dispatching any task, rather than just dispatching and handling errors?"
  answers={[
    "AgentCards are required by the JSON-RPC 2.0 specification before any method call",
    "Reading the card first catches capability mismatches at negotiation time — before the Orchestrator has committed work or consumed tokens on a task the Specialist can't fulfill",
    "The DPoP token can only be generated after reading the AgentCard's security scheme",
    "AgentCards contain the port number the agent is listening on, which is required to construct the URL"
  ]}
  correct={1}
/>

---

## Phase 2: MCP Tool Integration — The Market Data Specialist

The Market Data Specialist doesn't fetch data from the internet — it reads from a local SQLite database exposed via an MCP server. This is the Ch5 MCP bridge pattern applied at full scale.

### Setting Up the MCP Server

```bash
# Start the MCP SQLite server (using the official reference implementation)
npx @modelcontextprotocol/server-sqlite --db-path ./data/market_data.db
```

Populate the database with test data:

```sql
CREATE TABLE ohlcv (
    ticker TEXT NOT NULL,
    date TEXT NOT NULL,
    open REAL,
    high REAL,
    low REAL,
    close REAL,
    volume INTEGER,
    pe_ratio REAL,
    PRIMARY KEY (ticker, date)
);

INSERT INTO ohlcv VALUES ('NVDA', '2026-05-01', 875.20, 903.50, 870.10, 895.40, 42800000, 35.2);
-- ... 29 more rows
```

### Tool Proxy in the Specialist

The Market Data Specialist wraps the MCP tool as an A2A-reachable capability:

```python
# market_data_specialist/mcp_bridge.py
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import json

async def query_market_data(ticker: str) -> dict:
    """Bridge: A2A task → MCP SQLite query → structured JSON response."""
    server_params = StdioServerParameters(
        command="npx",
        args=["@modelcontextprotocol/server-sqlite", "--db-path", "./data/market_data.db"]
    )
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool(
                "query",
                arguments={
                    "query": f"""
                        SELECT date, open, high, low, close, volume, pe_ratio
                        FROM ohlcv
                        WHERE ticker = '{ticker}'
                        ORDER BY date DESC
                        LIMIT 30
                    """
                }
            )
            rows = json.loads(result.content[0].text)
            return {
                "ticker": ticker,
                "days_returned": len(rows),
                "ohlcv": rows,
                "pe_ratio": rows[0]["pe_ratio"] if rows else None
            }
```

<Callout type="warning">
Never interpolate untrusted input directly into SQL strings in a production MCP bridge. The ticker above comes from a trusted A2A message, but you must validate it against an allowlist of known ticker symbols before executing. The `query_market_data` function above should add `assert ticker in ALLOWED_TICKERS` before calling the MCP tool. An A2A message is not inherently trusted input — apply the same validation you would to any external source.
</Callout>

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt={`You are an A2A Market Data Specialist. You have received this A2A task:
"Retrieve 30-day OHLCV data and current P/E ratio for ticker: NVDA"

Your MCP SQLite query returned 30 rows with the following summary stats:
- Latest close: $895.40 (2026-05-31)
- 30-day high: $912.50
- 30-day low: $841.20
- Average daily volume: 44.2M shares
- Current P/E ratio: 35.2

Write the complete A2A JSON-RPC 2.0 response payload your agent should return. Use method "message/send" response format with a parts array. Include one text part with a human-readable summary and one data part (kind: "data") with the structured JSON containing ticker, close, high_30d, low_30d, avg_volume, and pe_ratio fields.`}
  expectedOutput='{"jsonrpc":"2.0","id":"<matches-request-id>","result":{"contextId":"<matches-request-contextId>","messageId":"<uuid>","role":"agent","parts":[{"kind":"text","text":"NVDA 30-day data: latest close $895.40, 30d high $912.50, 30d low $841.20, avg volume 44.2M, P/E 35.2"},{"kind":"data","data":{"ticker":"NVDA","close":895.40,"high_30d":912.50,"low_30d":841.20,"avg_volume":44200000,"pe_ratio":35.2}}]}}'
/>

---

## Phase 3: Adding Sentiment Analyst and Financial Writer

With the Market Data Specialist working, add the remaining two Specialists. Each follows the same pattern: publish an `AgentCard`, accept A2A tasks, return structured responses.

**Sentiment Analyst** — scrapes recent news headlines for the ticker and scores sentiment on a -1.0 to +1.0 scale:

```python
# sentiment_analyst/main.py
AGENT_CARD = {
    "name": "Sentiment Analyst",
    "skills": [{
        "id": "news-sentiment",
        "description": "Analyze news headlines for a ticker; return sentiment score -1.0 to +1.0 and top 5 relevant headlines",
        "tags": ["sentiment", "nlp", "news"],
        "inputModes": ["text"],
        "outputModes": ["application/json"]
    }],
    "securitySchemes": {"dpop": {"type": "dpop"}}
}
```

**Financial Writer** — accepts market data + sentiment JSON and produces a Markdown research report (PDF rendering is a stretch goal):

```python
# financial_writer/main.py
AGENT_CARD = {
    "name": "Financial Writer",
    "skills": [{
        "id": "research-report",
        "description": "Synthesize market data and sentiment into a formatted investment research report",
        "tags": ["writing", "finance", "report"],
        "inputModes": ["application/json"],
        "outputModes": ["text/markdown", "application/pdf"]
    }],
    "securitySchemes": {"dpop": {"type": "dpop"}}
}
```

### Orchestrator Workflow — The Full Sequence

```python
# orchestrator/workflow.py
import asyncio
import uuid
from .discovery import discover_specialist
from .dispatch import dispatch_market_data, dispatch_sentiment, dispatch_writer
from .state_store import StateStore

SPECIALISTS = {
    "market_data": "http://localhost:9001",
    "sentiment":   "http://localhost:9002",
    "writer":      "http://localhost:9003"
}

async def run_research(ticker: str, context_id: str, dpop_token: str):
    store = StateStore(context_id)

    # Step 1: Discover all specialists (fail fast if any card is missing)
    cards = {}
    for name, url in SPECIALISTS.items():
        card = await discover_specialist(url)
        if card is None:
            raise RuntimeError(f"Specialist {name} unreachable at {url}")
        cards[name] = card
        print(f"[{context_id}] Discovered: {card['name']}")

    # Step 2: Market data (skip if already in state store from a prior run)
    if not store.has("market_data"):
        market_result = await dispatch_market_data(ticker, context_id, dpop_token)
        store.save("market_data", market_result)
    else:
        market_result = store.load("market_data")
        print(f"[{context_id}] Resumed: market_data from state store")

    # Step 3: Sentiment (skip if stored)
    if not store.has("sentiment"):
        sentiment_result = await dispatch_sentiment(ticker, context_id, dpop_token)
        store.save("sentiment", sentiment_result)
    else:
        sentiment_result = store.load("sentiment")
        print(f"[{context_id}] Resumed: sentiment from state store")

    # Step 4: Writer (always re-runnable; produces the final report)
    report = await dispatch_writer(
        ticker=ticker,
        market_data=market_result,
        sentiment=sentiment_result,
        context_id=context_id,
        dpop_token=dpop_token
    )
    store.save("report", report)
    return report
```

---

## Phase 4: Security Hardening — DPoP Rejection Test

Every A2A message must carry a valid DPoP-bound token. The rejection test proves your middleware is active — not just your happy-path code.

### DPoP Token Generation

```python
# shared/dpop.py
import jwt
import uuid
import time
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

def generate_dpop_token(private_key: Ed25519PrivateKey, http_method: str, htu: str) -> str:
    """Generate a DPoP proof token per RFC 9449."""
    public_key = private_key.public_key()
    public_key_jwk = {
        "kty": "OKP",
        "crv": "Ed25519",
        "x": public_key.public_bytes_raw().hex()
    }
    headers = {
        "typ": "dpop+jwt",
        "alg": "EdDSA",
        "jwk": public_key_jwk
    }
    payload = {
        "jti": str(uuid.uuid4()),
        "htm": http_method,
        "htu": htu,
        "iat": int(time.time()),
        "exp": int(time.time()) + 300  # 5-minute window
    }
    return jwt.encode(payload, private_key, algorithm="EdDSA", headers=headers)
```

### Rejection Middleware in Each Specialist

```python
# shared/dpop_middleware.py
from fastapi import Request, HTTPException
import jwt

async def require_dpop(request: Request):
    """FastAPI dependency — reject any request without a valid DPoP proof."""
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("DPoP "):
        raise HTTPException(
            status_code=401,
            detail={"error": "missing_dpop", "message": "Authorization header must use DPoP scheme"}
        )
    dpop_token = auth_header[5:]
    try:
        # Verify token structure without signature check (signature check requires key registry)
        unverified = jwt.decode(dpop_token, options={"verify_signature": False})
        assert unverified.get("typ") == "dpop+jwt", "typ must be dpop+jwt"
        assert unverified.get("htm") == request.method, "htm mismatch"
        assert unverified.get("htu") == str(request.url), "htu mismatch"
    except Exception as e:
        raise HTTPException(status_code=401, detail={"error": "invalid_dpop", "message": str(e)})
```

### The Rejection Test

```python
# tests/test_dpop_rejection.py
import pytest
import httpx

@pytest.mark.asyncio
async def test_unsigned_message_is_rejected():
    """A2A message without DPoP Authorization header must return 401."""
    payload = {
        "jsonrpc": "2.0",
        "id": "test-001",
        "method": "message/send",
        "params": {
            "message": {
                "role": "user",
                "messageId": "msg-001",
                "contextId": "ctx-test-001",
                "parts": [{"kind": "text", "text": "Retrieve data for NVDA"}]
            }
        }
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "http://localhost:9001/",
            json=payload,
            headers={"Content-Type": "application/json", "A2A-Version": "1.0"}
            # No Authorization header
        )
    assert resp.status_code == 401
    body = resp.json()
    assert body["error"] == "missing_dpop"
```

<KnowledgeCheck
  question="The DPoP rejection test sends an A2A message WITHOUT an Authorization header and asserts a 401 response. Why is this test essential for production readiness?"
  answers={[
    "It verifies the network firewall is configured correctly to block unauthorized traffic",
    "It proves the middleware is active and will reject real unauthorized callers — without it you cannot know whether your security code is on the happy path or genuinely enforced",
    "It satisfies the A2A v1.0.0 compliance suite requirement for certification",
    "DPoP tokens expire after 5 minutes, so the rejection test confirms the clock sync is correct"
  ]}
  correct={1}
/>

---

## Phase 5: Crash-Resume — The Resumability Test

A Financial Writer crash mid-report is not a data loss event — it is a workflow branch. The state store already holds completed Market Data and Sentiment results. The resumability test proves the Orchestrator never re-runs expensive upstream phases when only the downstream Writer failed.

### The State Store

```python
# shared/state_store.py
import json
import redis
import os

class StateStore:
    """Redis-backed checkpoint store keyed by contextId."""

    def __init__(self, context_id: str):
        self.r = redis.Redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379"))
        self.prefix = f"a2a:ctx:{context_id}"

    def save(self, phase: str, data: dict) -> None:
        self.r.hset(self.prefix, phase, json.dumps(data))
        self.r.expire(self.prefix, 3600)  # 1h TTL

    def load(self, phase: str) -> dict:
        raw = self.r.hget(self.prefix, phase)
        if raw is None:
            raise KeyError(f"Phase '{phase}' not found in state store for context {self.prefix}")
        return json.loads(raw)

    def has(self, phase: str) -> bool:
        return self.r.hexists(self.prefix, phase)
```

### The Crash-Resume Test

```python
# tests/test_resumability.py
import pytest
import asyncio
import subprocess
import time
from orchestrator.workflow import run_research
from shared.state_store import StateStore
from shared.dpop import generate_dpop_token
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

@pytest.mark.asyncio
async def test_writer_crash_resumes_without_rerunning_market_data():
    """
    Scenario:
      1. Run workflow until Writer receives its task.
      2. Kill the Writer process mid-run.
      3. Re-run the workflow with the same contextId.
      4. Assert that market_data and sentiment are loaded from state store
         (not re-fetched), and report is eventually produced.
    """
    private_key = Ed25519PrivateKey.generate()
    context_id = "ctx-resumability-test"
    ticker = "NVDA"

    # Pre-populate state store as if phases 1+2 already completed
    store = StateStore(context_id)
    store.save("market_data", {"ticker": "NVDA", "close": 895.40, "pe_ratio": 35.2})
    store.save("sentiment", {"ticker": "NVDA", "score": 0.62, "headlines": ["NVDA beats earnings"]})

    # Simulate Writer being down
    # (in integration test, we'd kill the process; here we mock unavailability)
    import unittest.mock as mock
    call_count = {"market_data": 0, "sentiment": 0, "writer": 0}

    original_dispatch_market = dispatch_market_data
    original_dispatch_sentiment = dispatch_sentiment

    async def tracked_market(*args, **kwargs):
        call_count["market_data"] += 1
        return await original_dispatch_market(*args, **kwargs)

    async def tracked_sentiment(*args, **kwargs):
        call_count["sentiment"] += 1
        return await original_dispatch_sentiment(*args, **kwargs)

    dpop_token = generate_dpop_token(private_key, "POST", "http://localhost:9001/")

    with mock.patch("orchestrator.workflow.dispatch_market_data", tracked_market), \
         mock.patch("orchestrator.workflow.dispatch_sentiment", tracked_sentiment):
        report = await run_research(ticker, context_id, dpop_token)

    # Market data and sentiment should NOT have been re-fetched
    assert call_count["market_data"] == 0, "Market Data was re-fetched — state store not used"
    assert call_count["sentiment"] == 0, "Sentiment was re-fetched — state store not used"
    assert report is not None
```

<KnowledgeCheck
  question="The state store uses `contextId` as the lookup key for checkpoints. What property of contextId makes it suitable for cross-agent state correlation?"
  answers={[
    "contextId is generated by the A2A registry and is guaranteed to be globally unique across all agent networks",
    "contextId is set once by the Orchestrator at workflow start and passed unchanged through every sendMessage call, creating a single correlation key that all agents share",
    "contextId maps to a specific DPoP token, so any agent can verify the identity of the workflow owner",
    "contextId contains a timestamp that allows agents to reconstruct the workflow sequence order independently"
  ]}
  correct={1}
/>

---

## Phase 6: Distributed Tracing

A trace that links every agent handoff answers the question: "Where did 47 seconds go between the Orchestrator dispatching to Market Data and receiving the result?" OpenTelemetry propagates trace context through A2A headers.

### Instrumentation

```python
# shared/tracing.py
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.propagate import inject, extract
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

def setup_tracer(service_name: str) -> trace.Tracer:
    provider = TracerProvider()
    exporter = OTLPSpanExporter(endpoint="http://localhost:4317")
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)
    return trace.get_tracer(service_name)

def inject_trace_headers(headers: dict) -> dict:
    """Inject W3C trace context into outgoing A2A request headers."""
    inject(headers, setter=lambda carrier, key, val: carrier.__setitem__(key, val))
    return headers

def extract_trace_context(headers: dict) -> object:
    """Extract W3C trace context from incoming A2A request headers."""
    return extract(headers)
```

### Trace Propagation in the Orchestrator Dispatch

```python
# orchestrator/dispatch.py (updated with tracing)
from shared.tracing import setup_tracer, inject_trace_headers

tracer = setup_tracer("orchestrator")

async def dispatch_market_data(ticker: str, context_id: str, dpop_token: str) -> dict:
    with tracer.start_as_current_span(
        "dispatch.market_data",
        attributes={"a2a.ticker": ticker, "a2a.context_id": context_id}
    ) as span:
        headers = {
            "Content-Type": "application/json",
            "A2A-Version": "1.0",
            "Authorization": f"DPoP {dpop_token}"
        }
        inject_trace_headers(headers)  # Adds traceparent + tracestate

        payload = { ... }  # as before
        async with httpx.AsyncClient() as client:
            resp = await client.post("http://localhost:9001/", json=payload, headers=headers)
            result = resp.json()
            span.set_attribute("a2a.response_status", resp.status_code)
            return result
```

Each Specialist extracts the trace context from incoming headers and creates child spans:

```python
# market_data_specialist/handler.py
from shared.tracing import setup_tracer, extract_trace_context
from opentelemetry import context as otel_context

tracer = setup_tracer("market-data-specialist")

async def handle_task(request: Request, body: dict):
    parent_ctx = extract_trace_context(dict(request.headers))
    with tracer.start_as_current_span(
        "specialist.market_data",
        context=parent_ctx,
        attributes={"a2a.skill": "market-data-lookup"}
    ) as span:
        ticker = extract_ticker(body)
        result = await query_market_data(ticker)
        span.set_attribute("a2a.rows_returned", result["days_returned"])
        return result
```

The resulting Jaeger trace will show a single root span (`orchestrator.run_research`) with three child spans — one per Specialist — and their MCP/DB sub-spans nested beneath, linked by `traceId`.

---

## Architecture Decision Record (ADR)

An ADR is a short document that records a single architectural choice, the alternatives considered, and why this option was chosen. Each major decision in this capstone gets its own ADR entry.

```markdown
# ADR-001: Hub-and-Spoke vs. Peer-to-Peer Mesh

**Date:** 2026-05-31  
**Status:** Accepted

## Context
The Orchestrator must sequence Market Data → Sentiment → Writer strictly, 
because Sentiment analysis benefits from ticker context and Writer needs both upstream results.

## Decision
Hub-and-Spoke: Orchestrator dispatches to each Specialist sequentially and 
holds all intermediate state in the shared Redis store.

## Alternatives considered
- **P2P Mesh**: Market Data → hands off directly to Sentiment. Rejected: 
  the Orchestrator can no longer control sequence or provide crash-resume 
  without coupling Specialists to each other.
- **Event Bus**: Publish/subscribe via a message broker. Rejected: adds a 
  new infrastructure dependency for a 4-agent system; premature at this scale.

## Consequences
- Orchestrator is the single point of workflow knowledge. If it crashes, a 
  new Orchestrator can resume from the state store using the same contextId.
- Specialists remain fully decoupled. Adding a 5th Specialist requires zero 
  changes to existing Specialists.

---

# ADR-002: JSON-RPC 2.0 over REST

**Date:** 2026-05-31  
**Status:** Accepted

## Context
Inter-agent communication is intent-based ("research this ticker") not resource-based 
("GET this data object"). 

## Decision
A2A's JSON-RPC 2.0 transport. Method names describe intent (`message/send`); 
the payload carries structured context; errors are typed.

## Consequences
Tooling support is narrower than REST (no OpenAPI auto-discovery). Mitigated by 
AgentCards — every agent's callable intents are described in the card, not a Swagger file.

---

# ADR-003: DPoP over Static API Keys

**Date:** 2026-05-31  
**Status:** Accepted

## Context
Inter-agent messages must prove that the sending agent is who it claims to be 
and that the token was generated for this specific HTTP request — preventing token theft.

## Decision
DPoP-bound tokens (RFC 9449). Each token is cryptographically bound to the 
HTTP method and URL, making replayed tokens useless.

## Consequences
Key management complexity increases: each agent needs an Ed25519 key pair. 
Mitigated by generating keys at startup (non-persistent) for this course; 
production systems should use a key management service.
```

---

## Production Readiness Checklist

Before you call this network "production-ready," verify all six items:

| # | Check | How to verify |
|---|---|---|
| 1 | All four Agent Cards resolve at `/.well-known/agent.json` | `curl http://localhost:900{0,1,2,3}/.well-known/agent.json` returns 200 JSON |
| 2 | DPoP rejection active on all Specialists | `pytest tests/test_dpop_rejection.py` — all three Specialists return 401 |
| 3 | Full workflow completes end-to-end | `python -m orchestrator.main --ticker NVDA` produces a Markdown report |
| 4 | Crash-resume works | `pytest tests/test_resumability.py` — zero Market Data or Sentiment re-fetches |
| 5 | Trace links all agents | Jaeger UI at `localhost:16686` shows one root span with three child spans under the same traceId |
| 6 | Architecture Decision Record committed | `vault/courses/multi-agent-orchestration-a2a/adr/` contains ADR-001, ADR-002, ADR-003 |

<Callout type="info">
**One-command start:** Add a `docker-compose.yml` that starts all four agents, Redis, the MCP SQLite server, and the OpenTelemetry collector. The command `docker compose up` should bring the full network to a ready state. A capstone that requires six terminal windows and a startup order ritual is not production-ready.
</Callout>

---

## Hands-On Exercise: Build the Cross-Vendor Investment Researcher

**Time estimate:** 90 minutes

Build the network incrementally. Each phase must pass its verification before you move to the next.

### Phase 1 — Two-Agent Handshake (15 min)

**Goal:** Orchestrator discovers Market Data Specialist and completes one A2A task.

1. Create the project structure:
   ```
   investment-researcher/
   ├── orchestrator/
   ├── market_data_specialist/
   ├── shared/
   ├── tests/
   └── docker-compose.yml
   ```
2. Implement `AgentCard` endpoint in Market Data Specialist.
3. Implement `discover_specialist()` in Orchestrator.
4. Send one `sendMessage` request (no DPoP yet) and assert a 200 response.

**Success gate:** `curl http://localhost:9001/.well-known/agent.json` returns a valid JSON card with at least one skill entry.

---

### Phase 2 — MCP Integration (20 min)

**Goal:** Market Data Specialist returns real data from SQLite via MCP.

1. Start the MCP SQLite server with the provided schema.
2. Implement `query_market_data()` in `mcp_bridge.py`.
3. Wire the A2A task handler to call `query_market_data()` and return a structured JSON response.

**Success gate:** Orchestrator receives an A2A response containing NVDA market data with at least one OHLCV row.

---

### Phase 3 — Full Network (20 min)

**Goal:** All four agents running; Orchestrator sequences all three Specialists.

1. Add Sentiment Analyst (stub the news scraper — return hardcoded scores for now).
2. Add Financial Writer (use Claude Haiku to synthesize the Markdown report from market + sentiment JSON).
3. Implement `run_research()` workflow in Orchestrator.

**Success gate:** `python -m orchestrator.main --ticker NVDA` produces a Markdown research report.

---

### Phase 4 — DPoP and Resumability Tests (20 min)

**Goal:** Security and resilience proven by automated tests.

1. Add DPoP middleware to all three Specialists.
2. Generate DPoP tokens in Orchestrator dispatch functions.
3. Run `pytest tests/test_dpop_rejection.py` — must pass for all three Specialists.
4. Implement `StateStore` with Redis.
5. Run `pytest tests/test_resumability.py` — must pass with zero upstream re-fetches.

**Success gate:** Both test files pass with zero failures.

---

### Phase 5 — Distributed Trace (15 min)

**Goal:** One trace visible in Jaeger linking all agent handoffs.

1. Add `setup_tracer()` to each agent.
2. Inject W3C trace headers in Orchestrator dispatch functions.
3. Extract and continue trace context in each Specialist handler.
4. Start Jaeger (`docker compose up jaeger`) and run the full workflow.
5. Open `http://localhost:16686`, search for service `orchestrator`, and open the latest trace.

**Success gate:** One trace with a root span `orchestrator.run_research` and three child spans — one per Specialist — all sharing the same traceId.

---

### Deliverables

Commit the following to your repository before calling the capstone complete:

```
investment-researcher/
├── README.md                  # one-command start + test instructions
├── docker-compose.yml         # full network: 4 agents + Redis + MCP + OTel + Jaeger
├── orchestrator/
├── market_data_specialist/
├── sentiment_analyst/
├── financial_writer/
├── shared/                    # dpop.py, state_store.py, tracing.py
├── tests/
│   ├── test_dpop_rejection.py
│   └── test_resumability.py
└── adr/
    ├── ADR-001-topology.md
    ├── ADR-002-transport.md
    └── ADR-003-auth.md
```

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| Agent Card | JSON manifest at `/.well-known/agent.json` — every A2A agent's identity and capability contract |
| contextId | The single correlation key set by the Orchestrator and passed through every A2A message in a workflow |
| DPoP | RFC 9449 Demonstration of Proof-of-Possession — token bound to HTTP method + URL, non-replayable |
| State Store | Redis-backed checkpoint store keyed by contextId; enables crash-resume without re-running completed phases |
| Hub-and-Spoke | Orchestration topology where a central Hub controls sequencing and all Specialists remain decoupled |
| ADR | Architecture Decision Record — a short document capturing one architectural choice, alternatives, and rationale |
| W3C Trace Context | HTTP header standard (`traceparent`, `tracestate`) for propagating distributed trace IDs across service boundaries |
| MCP Bridge | Code that translates an incoming A2A task into an MCP tool call and returns the result as an A2A response |

---

## What's Next

You have built a sovereign agent network: four agents, three protocols (A2A, MCP, DPoP), one state store, one trace. What comes next depends on which boundary you want to push.

**For production hardening:**
- Replace key-at-startup DPoP with a hardware-backed key management service (AWS KMS, HashiCorp Vault).
- Add A2A push notifications so the Orchestrator doesn't poll — Specialists call back when complete.
- Move the Orchestrator to a durable workflow engine (Temporal, Inngest) so the Orchestrator itself is resumable.

**For network expansion:**
- Register your Specialists in a live AGNTCY OASF registry and discover them by capability query rather than hardcoded URL.
- Add a second Orchestrator from a different framework (AutoGen, LangGraph) and prove it can hire your A2A Specialists without modification.

**For the Internet of Agents:**
- The A2A specification is open and evolving at [github.com/a2aproject/A2A](https://github.com/a2aproject/A2A). The next frontier is Agent-to-Agent trust delegation — the ability for an agent to pass its user-granted permissions to a downstream agent with cryptographic proof. That problem is unsolved in production at scale. The builders who solve it will define the next chapter of this protocol.

---

*Sources: [A2A Protocol Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [AGNTCY Internet of Agents](https://agntcy.org/) · [Model Context Protocol](https://modelcontextprotocol.io/) · [RFC 9449 — OAuth 2.0 DPoP](https://www.rfc-editor.org/rfc/rfc9449) · [OpenTelemetry Distributed Traces](https://opentelemetry.io/docs/concepts/signals/traces/)*
