---
date: 2026-06-15
author: content-author
vendor_tag: langfuse
content_type: course-chapter
course_slug: ai-agent-observability-langfuse
chapter_number: 1
chapter_slug: observability-fundamentals
title: "Autonomous Agents Fail Silently Without Observability — Here's How Langfuse Surfaces Every Token"
description: "Install Langfuse, connect an agent via OpenTelemetry, track real costs per session, and read the dashboard to catch latency outliers before they blow your budget."
slug: ai-agent-observability-langfuse-ch01-observability-fundamentals
learning_objectives:
  - "Understand why autonomous AI agents require structured observability rather than ad-hoc logging"
  - "Self-host Langfuse for production-grade telemetry with correct environment variable configuration"
  - "Configure OpenTelemetry export from a Python or TypeScript agent to capture nested spans"
  - "Analyze traces, latency, and costs using Langfuse Dashboards to find bottlenecks and control spend"
whats_new:
  - "Full environment variable configuration for self-hosted Langfuse (production checklist included)"
  - "End-to-end Python agent trace integration with Langfuse SDK + OTel OTLP export"
  - "Annotated cost_details payload walkthrough for non-standard model cost tracking"
  - "Langfuse Dashboard trace analysis workflow — finding slow spans, filtering by session, setting cost alerts"
status: g0-passed
last_updated: 2026-06-15
reading_time_min: 55
duration_min: 55
positions: []
chapter_primary_query: "how to instrument autonomous agents with Langfuse"
faq:
  - question: "How do I self-host Langfuse for production AI agent workloads?"
    answer: "Clone the Langfuse repository and run `docker compose up -d`. Before routing real traffic, set unique `NEXTAUTH_SECRET` and `SALT` values, configure persistent PostgreSQL and ClickHouse volumes, and ensure `NEXTAUTH_URL` matches your public hostname — mismatches break OAuth login. Full environment variable reference is in the [Langfuse self-hosting guide](https://langfuse.com/self-hosting)."
  - question: "What is the difference between usage_details and cost_details in Langfuse?"
    answer: "In Langfuse, `usage_details` carries token count breakdowns (e.g., `{\"input\": 512, \"output\": 256}`) used to calculate costs against a pricing registry. `cost_details` carries explicit monetary costs (e.g., `{\"input\": 0.000768, \"output\": 0.003072}`) for non-standard or fine-tuned models where automatic pricing lookup would fail. See the [Langfuse token and cost tracking docs](https://langfuse.com/docs/observability/features/token-and-cost-tracking)."
  - question: "How do I identify the most expensive agent session in the Langfuse dashboard?"
    answer: "Open the Traces list in the Langfuse Dashboard tab, click the column header to add the Cost column, then sort descending. The top row is your costliest session. Click into it and filter spans by cost to find which LLM generation or tool call drove the spike. For recurring monitoring, query the Metrics API at `/api/public/metrics/daily` with a daily cron and pipe the result to your alerting system."
sources:
  - url: "https://langfuse.com/docs/observability/overview"
    title: "Langfuse Observability Overview"
  - url: "https://langfuse.com/self-hosting"
    title: "Langfuse Self-Hosting Guide"
  - url: "https://langfuse.com/docs/observability/features/token-and-cost-tracking"
    title: "Langfuse Token and Cost Tracking"
  - url: "https://opentelemetry.io/docs/what-is-opentelemetry/"
    title: "What is OpenTelemetry?"
  - url: "https://langfuse.com/docs/sdk/python/low-level-sdk"
    title: "Langfuse Python SDK — Low-Level API"
  - url: "https://langfuse.com/docs/tracing"
    title: "Langfuse Tracing Concepts"
---

# Autonomous Agents Fail Silently Without Observability — Here's How Langfuse Surfaces Every Token

When a chat completion fails, you see an HTTP 500. When an autonomous agent fails, you see nothing — the agent just stops making progress, burns tokens on retries, or returns a wrong answer with full confidence. Ad-hoc `print()` statements cannot capture nested tool calls, parallel sub-agents, or the exact LLM generation that triggered a cost spike. You need structured observability wired in from the start.

This chapter shows you how to instrument an autonomous agent with [Langfuse](https://langfuse.com/docs/observability/overview) — an open-source, OpenTelemetry-native platform purpose-built for LLM workloads. By the end, you will have a self-hosted Langfuse stack running locally, an agent emitting traces over OTLP, real-time cost dashboards per user session, and the workflow skills to find latency outliers before they ship to production.

Relevant context from related modules: [[production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability|Chapter 5: Production Deploy + Observability]] covers Langfuse in the context of Claude Agent SDK deployments. [[claude-tool-use-from-zero/05-observability-and-logging-in-mcp|Chapter 5: Observability in MCP]] shows how MCP tool calls appear as spans — useful background before this chapter. The [[glossary/opentelemetry|OpenTelemetry]] glossary entry explains OTel concepts referenced throughout this chapter.

## Why Autonomous Agents Demand Structured Observability

A standard web service call is atomic: one request, one response, one log line. An autonomous agent is a graph of decisions. A single user turn might trigger a retrieval step, three parallel tool calls, two self-critique loops, and a final synthesis — each involving its own LLM generation with its own token budget. A flat log tells you what happened at the top level; it cannot tell you which sub-step added 4,000 tokens, why the retrieval step ran twice, or which tool call silently returned an empty result that sent the agent into a hallucination spiral.

The failure modes that matter in production agents are almost never detectable by watching the final output:

- **Token runaway**: A retrieval loop repeats because a tool returns a consistent empty result. The agent keeps retrying, burning tokens, until the context window fills and the whole trace fails. Without span-level token counts, you only see a large bill at the end of the month.
- **Silent tool failure**: A tool call returns `{}` instead of raising an exception. The agent treats it as a valid (empty) response, reasons over nothing, and produces a confident wrong answer. Without the tool call span, you cannot trace the failure.
- **Latency regression**: A new embedding model is 40% slower than the old one. Because latency distributes across dozens of spans, overall P99 creeps up imperceptibly — until it crosses a SLA threshold during a production spike.

Langfuse addresses all three by capturing every generation, retrieval, and tool call as a **span** within a hierarchical **trace**. Each span records start time, end time, input tokens, output tokens, model used, and a full input/output payload. The dashboard aggregates these into cost timelines, latency waterfall views, and per-user breakdowns.

<Callout type="info">
Langfuse is built on [OpenTelemetry](https://opentelemetry.io/docs/what-is-opentelemetry/) — the CNCF standard for telemetry data. This means your instrumentation code is not vendor-locked: if you later switch to a different observability backend, the OTel exporter configuration is the only thing that changes.
</Callout>

## Self-Hosting Langfuse

The Langfuse cloud tier is convenient for early prototyping, but production AI agent workloads typically involve sensitive inputs (user PII, proprietary prompts, retrieved documents) that you should not send to a third-party server. Self-hosting keeps trace data within your infrastructure.

### Architecture at a Glance

A self-hosted Langfuse deployment consists of four data-layer components that the web/API and worker services share:

| Component | Role |
|---|---|
| **PostgreSQL** | Relational store for users, projects, and metadata |
| **ClickHouse** | OLAP store for traces, spans, and aggregations — powers dashboard queries |
| **Redis / Valkey** | Event queue between the API ingest path and the async worker |
| **S3-compatible store** | Bulk storage for large trace payloads and media blobs |

The web/API service handles the Langfuse UI, REST API, and OTLP ingestion endpoint. The worker service drains the Redis queue, writes to ClickHouse, and handles background jobs like cost calculation.

### Environment Variable Configuration

The most common self-hosting failure is an incomplete environment configuration. The following variables are **required** for a production-grade deployment — not just for local development:

```env
# Core secrets — generate with: openssl rand -base64 32
NEXTAUTH_SECRET=<32-byte-secret>
SALT=<32-byte-salt>

# Database connections
DATABASE_URL=postgresql://langfuse:password@postgres:5432/langfuse
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=<clickhouse-password>

# Object storage (S3-compatible; use MinIO for local)
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY_ID=<minio-access-key>
S3_SECRET_ACCESS_KEY=<minio-secret>
S3_BUCKET_NAME=langfuse

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_AUTH=<redis-password>

# Public URL (used for OAuth redirects)
NEXTAUTH_URL=https://langfuse.yourdomain.com
LANGFUSE_BASE_URL=https://langfuse.yourdomain.com
```

For local development, the official `docker-compose.yml` from the [Langfuse GitHub repository](https://langfuse.com/self-hosting) pre-populates most of these with development defaults so you can skip straight to the quick start.

### Quick Start (Docker Compose)

```bash
git clone https://github.com/langfuse/langfuse
cd langfuse
docker compose up -d
```

After the stack initialises (allow 60–90 seconds for ClickHouse to warm up), navigate to `http://localhost:3000`. Create your first project and note the **Public Key** and **Secret Key** from Project Settings — you will need these for SDK authentication.

### Production Readiness Checklist

Before routing real traffic to a self-hosted Langfuse instance:

- [ ] `NEXTAUTH_SECRET` and `SALT` are unique, randomly generated (not the dev defaults)
- [ ] PostgreSQL and ClickHouse are on persistent volumes with daily backups
- [ ] TLS is terminated at the reverse proxy (Caddy/nginx/Cloudflare), not inside the container
- [ ] `NEXTAUTH_URL` matches your actual public hostname — mismatches break OAuth sign-in
- [ ] Worker and web/API services can reach each other on the internal Docker network
- [ ] S3 bucket (or MinIO bucket) has a lifecycle rule to delete payloads older than your retention policy

**Common setup errors**: The single most frequent issue is `NEXTAUTH_URL` pointing to `localhost` while the browser accesses a different hostname — this causes OAuth callback failures on first login. The second most frequent is ClickHouse failing to start because the default `9000` port conflicts with another service; override with `CLICKHOUSE_TCP_PORT` if needed.

<KnowledgeCheck>
  <Question>Which Langfuse data store is responsible for OLAP trace analysis and powering dashboard queries?</Question>
  <Choice>PostgreSQL</Choice>
  <Choice correct>ClickHouse</Choice>
  <Choice>Redis</Choice>
  <Choice>S3</Choice>
</KnowledgeCheck>

## Exporting Traces via OpenTelemetry

With your Langfuse stack running, the next step is connecting an agent. Langfuse accepts traces over two paths: the native Langfuse SDK (recommended for maximum context) and a generic OTLP gRPC/HTTP endpoint (useful when your framework already exports OTel spans).

### End-to-End Python Integration

The following example shows a minimal autonomous agent loop instrumented with the Langfuse Python SDK. It captures a parent trace for the overall agent run and child spans for each LLM generation and tool call.

<RunPromptCell>
  <Prompt>
import os
from langfuse import Langfuse
from anthropic import Anthropic

# Initialize clients
langfuse = Langfuse(
    public_key=os.environ["LANGFUSE_PUBLIC_KEY"],
    secret_key=os.environ["LANGFUSE_SECRET_KEY"],
    host=os.environ.get("LANGFUSE_HOST", "http://localhost:3000"),
)
anthropic_client = Anthropic()

def run_agent(user_query: str, session_id: str) -> str:
    # Create a top-level trace for the entire agent run
    trace = langfuse.trace(
        name="agent-run",
        session_id=session_id,
        input={"query": user_query},
        metadata={"agent_version": "1.0.0"},
    )

    messages = [{"role": "user", "content": user_query}]

    # Instrument each LLM generation as a nested generation span
    # Langfuse Python SDK 2.x (low-level API)
    # For SDK 3.x, use: langfuse.start_as_current_observation(as_type="generation", ...)
    generation = trace.generation(
        name="initial-planning",
        model="claude-sonnet-4-6",
        input=messages,
    )

    response = anthropic_client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        messages=messages,
    )
    answer = response.content[0].text

    # Close the generation span with output + token counts
    generation.end(
        output=answer,
        usage={
            "input": response.usage.input_tokens,
            "output": response.usage.output_tokens,
        },
    )

    # Close the trace with the final output
    trace.update(output={"answer": answer})
    langfuse.flush()
    return answer

result = run_agent("Summarise the latest Langfuse changelog", session_id="user-abc-001")
print(result)
  </Prompt>
  <Output>
# Console output (after ~2 seconds):
Langfuse (2.x) changelog highlights: native OpenTelemetry support, ClickHouse migration for OLAP...
# Langfuse Dashboard: new trace "agent-run" appears under session "user-abc-001"
# Spans: 1 generation (claude-sonnet-4-6), input_tokens=38, output_tokens=120, latency=1840ms
  </Output>
</RunPromptCell>

### Generic OTLP Export (Framework-Agnostic)

If your agent framework already emits OpenTelemetry spans (e.g., LangChain with `opentelemetry-instrumentation-langchain`, or a custom OTel setup), you can point the OTLP exporter directly at Langfuse's ingest endpoint without the SDK:

```python
import base64
import os
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure OTLP exporter pointing at self-hosted Langfuse
exporter = OTLPSpanExporter(
    endpoint=f"{os.environ['LANGFUSE_HOST']}/api/public/otel/v1/traces",
    headers={
        "Authorization": "Basic " + base64.b64encode(
            f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}".encode()
        ).decode()
    },
)

provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)
```

With this configuration, any spans created using the standard OTel API will appear in your Langfuse project automatically. LLM generation spans must include `gen_ai.*` semantic conventions for Langfuse to recognise them as generations and extract token counts.

<KnowledgeCheck>
  <Question>When using the Langfuse Python SDK, which method do you call to create a child span that records an individual LLM generation?</Question>
  <Choice>trace.span()</Choice>
  <Choice correct>trace.generation()</Choice>
  <Choice>trace.event()</Choice>
  <Choice>langfuse.observe()</Choice>
</KnowledgeCheck>

## Cost and Usage Tracking

Langfuse calculates costs automatically for all models in its [public pricing registry](https://langfuse.com/docs/observability/features/token-and-cost-tracking). For standard Anthropic, OpenAI, and Google models, you only need to pass `usage.input` and `usage.output` token counts in the generation span — Langfuse resolves the per-token price and surfaces it in the dashboard.

### Non-Standard Models: The `cost_details` Payload

When you deploy a fine-tuned model, a self-hosted LLM, or a model accessed through a gateway that applies custom pricing, the automatic lookup fails. Pass `cost_details` with explicit monetary costs instead:

```python
generation.end(
    output=response_text,
    usage={
        "input": 512,
        "output": 256,
    },
    cost_details={
        "input": 0.000768,   # 512 tokens × $0.0015/1k
        "output": 0.003072,  # 256 tokens × $0.0120/1k
    },
)
```

The `cost_details` map accepts `input` and `output` keys for explicit monetary costs, bypassing the registry price lookup. Langfuse aggregates these directly in USD. If you omit `cost_details`, Langfuse falls back to the registry — so you only need this block for non-standard or fine-tuned models. See the [Langfuse token and cost tracking docs](https://langfuse.com/docs/observability/features/token-and-cost-tracking) for the full field reference.

**Reading the cost dashboard**: In Langfuse's Dashboard tab, the **Cost by model** chart breaks down spend per model per day. Switch to the **Traces** table, add the **Cost** column, and sort descending to find your most expensive sessions. Filter by `session_id` to drill into a specific user's spend history.

<KnowledgeCheck>
  <Question>What field in the Langfuse generation span lets you provide explicit monetary costs for a model that is NOT in Langfuse's pricing registry?</Question>
  <Choice>model_pricing</Choice>
  <Choice>usage_details</Choice>
  <Choice correct>cost_details</Choice>
  <Choice>custom_cost</Choice>
</KnowledgeCheck>

## Interpreting Traces in the Langfuse Dashboard

Once traces are flowing, the Langfuse Dashboard becomes your primary debugging and cost-governance tool. This section walks through the three workflows you will use most often.

### Finding Slow Spans (Latency Waterfall View)

Open any trace from the **Traces** list. The detail view renders a **waterfall chart** — every span is a horizontal bar whose width represents its wall-clock duration. Spans are nested: child spans appear indented under their parent, so you can see at a glance whether the latency is in the LLM generation, a tool call, or network overhead.

To find latency outliers:

1. Sort the Traces list by **Latency (P99)** descending to surface the slowest 1% of runs.
2. Click into a slow trace and look for **the widest bar that is not an LLM generation**. LLM latency is expected; unexpectedly wide tool call spans signal external API slowness or infinite loops.
3. Check the **Input** payload on the slow generation span. A context window that is 90%+ full forces the model to truncate reasoning, which paradoxically increases latency as the model works harder with less working space.

**Latency budget rule of thumb**: For a production agent with a 5-second user-facing SLA, your target is ≤3s for LLM generations, ≤500ms per tool call, and ≤200ms for retrieval steps. Anything outside these bands warrants a child issue.

### Filtering Traces by Session, User, or Tag

The **Traces** list supports compound filters:

- **Session ID**: Filter to `session_id = "user-abc-001"` to see every agent run for a single user within a time window. Useful for debugging a specific user complaint.
- **User ID**: Set `user_id` on the trace at creation time (`langfuse.trace(user_id="usr_123", ...)`), then filter the dashboard to that user across all sessions.
- **Tags**: Add `tags=["prod", "rag-pipeline"]` to the trace and filter the dashboard to a single tag to scope cost and latency metrics to one pipeline variant.

### Setting Up Cost Alerts

Langfuse does not currently send push notifications natively, but the **Metrics** API lets you query aggregated cost per project per day and pipe it into any alerting system. A simple daily cron that calls:

```bash
curl -s \
  -H "Authorization: Basic $(echo -n $PK:$SK | base64)" \
  "https://langfuse.yourdomain.com/api/public/metrics/daily?fromTimestamp=<yesterday>" \
  | jq '.data[].totalCost'
```

…returns today's running cost. Wire this into PagerDuty, Slack, or Telegram to alert when daily spend crosses a threshold. For teams on the Langfuse cloud tier, the UI has a native spend alert under Settings → Billing.

<Callout type="warn">
Cost alerts fire on **total project spend**, not per-session spend. If one session accounts for 90% of your cost (a runaway loop), you will not know which session it is from the alert alone. After the alert fires, filter the Traces list by cost descending to identify the culprit.
</Callout>

## Summary Checklist

By the end of this chapter you should be able to confirm each item:

- [ ] Langfuse stack deployed locally via Docker Compose with all required env vars set
- [ ] Agent emits traces with at least one `generation` span per LLM call
- [ ] Token counts (`usage.input`, `usage.output`) are recorded on every generation span
- [ ] Non-standard model costs use `cost_details` with explicit `input` / `output` keys
- [ ] Dashboard Traces list shows traces filterable by `session_id` and `user_id`
- [ ] Latency waterfall reviewed for at least one trace; slowest span identified
- [ ] Cost-per-day query confirmed working via API or UI dashboard

The next chapter adds a multi-step agent loop with branching tool calls, showing how to structure parent/child span relationships so the waterfall view remains readable at scale.
