---
title: "AI Agent Observability with Langfuse — Production Setup"
slug: ai-agent-observability-langfuse
description: "Set up Langfuse for production AI agent observability with the six-container self-hosted stack, OTLP export from coding agents, cost tracking, and a clear view of when Langfuse beats LangSmith, Helicone, or Arize."
date: 2026-05-12
author: vardaan-koenig
agent_drafted_by: blog-author
ticket: KOEA-1338
vendor_tag: community
content_type: article
status: published
reading_time_min: 8
hero_image: auto:flux
tags: [langfuse, observability, self-host, otel, agents, llmops]
primary_query: "Langfuse production setup for AI agent observability"
contrarian_angle: "Langfuse is most useful in production when you treat it as your OTLP backend for mixed agent stacks, not as one more dashboard to maintain"
sources:
  - https://langfuse.com/self-hosting
  - https://langfuse.com/docs/observability/overview
  - https://langfuse.com/docs/observability/features/token-and-cost-tracking
  - https://langfuse.com/docs/observability/get-started
  - https://langfuse.com/docs/integrations/overview
  - https://github.com/langfuse/langfuse/releases
  - https://langfuse.com/integrations/native/opentelemetry
  - https://langfuse.com/blog/2024-10-opentelemetry-for-llm-observability
  - https://code.claude.com/docs/en/monitoring-usage
  - https://code.claude.com/docs/en/agent-sdk/observability
  - https://developers.openai.com/codex/config-advanced
  - https://developers.openai.com/codex/config-sample
  - https://opencode.ai/docs/plugins/
references:
  - n: 1
    title: "Self-host Langfuse (Open Source LLM Observability)"
    url: https://langfuse.com/self-hosting
    retrieved: 2026-05-12
  - n: 2
    title: "Observability & Application Tracing"
    url: https://langfuse.com/docs/observability/overview
    retrieved: 2026-05-12
  - n: 3
    title: "Token & Cost Tracking"
    url: https://langfuse.com/docs/observability/features/token-and-cost-tracking
    retrieved: 2026-05-12
  - n: 4
    title: "Get Started with Tracing"
    url: https://langfuse.com/docs/observability/get-started
    retrieved: 2026-05-12
  - n: 5
    title: "Langfuse Integrations Overview"
    url: https://langfuse.com/docs/integrations/overview
    retrieved: 2026-05-12
  - n: 6
    title: "langfuse/langfuse releases"
    url: https://github.com/langfuse/langfuse/releases
    retrieved: 2026-05-12
  - n: 7
    title: "OpenTelemetry (OTEL) for LLM Observability"
    url: https://langfuse.com/integrations/native/opentelemetry
    retrieved: 2026-05-12
  - n: 8
    title: "OpenTelemetry (OTel) for LLM Observability"
    url: https://langfuse.com/blog/2024-10-opentelemetry-for-llm-observability
    retrieved: 2026-05-12
  - n: 9
    title: "Monitoring Claude Code with OpenTelemetry"
    url: https://code.claude.com/docs/en/monitoring-usage
    retrieved: 2026-05-12
  - n: 10
    title: "Observability with OpenTelemetry in Claude Agent SDK"
    url: https://code.claude.com/docs/en/agent-sdk/observability
    retrieved: 2026-05-12
  - n: 11
    title: "Codex Advanced Configuration"
    url: https://developers.openai.com/codex/config-advanced
    retrieved: 2026-05-12
  - n: 12
    title: "Codex Sample Configuration"
    url: https://developers.openai.com/codex/config-sample
    retrieved: 2026-05-12
  - n: 13
    title: "OpenCode Plugins"
    url: https://opencode.ai/docs/plugins/
    retrieved: 2026-05-12
whats_new:
  - "Langfuse's real production edge is one OTLP backend for mixed agent stacks, not a second observability dashboard"
learning_objectives:
  - Decide when Langfuse belongs in a production agent stack and when it just creates duplicate observability overhead
  - Configure the six-container Langfuse stack, OTLP export, metadata propagation, and cost tracking with production-safe defaults
faq:
  - question: "What is the fastest reliable way to set up Langfuse for production AI agent observability?"
    answer: "Use Langfuse as an OTLP backend, run the six-service self-hosted stack or Langfuse Cloud, export traces over HTTP or gRPC from your agent tooling, and propagate user, session, and tag metadata on every span."
  - question: "Do I need the x-langfuse-ingestion-version: 4 header for normal OTLP ingestion?"
    answer: "No. Langfuse documents that header for real-time Fast Preview mode. Standard OTLP ingestion works without treating it as a universal requirement."
  - question: "When should a team skip Langfuse?"
    answer: "Skip it when your agents already live inside one cloud stack with strong native tracing and you do not need self-hosting, cross-framework aggregation, or Langfuse's prompt and cost views."
---

# Run Langfuse as the observability backend for mixed agent stacks

Langfuse is an open-source LLM observability platform that, in v3.173.0 on May 8, 2026, supports self-hosted tracing, cost tracking, and OTLP ingestion for agent systems.[1][6][7] For a production setup, the cleanest pattern is a six-container stack—web, worker, Postgres, ClickHouse, Redis, and MinIO—plus trace export from the coding agents you already run.[1]

The common pitch for Langfuse is "open source alternative to LangSmith." That undersells it. The real reason to deploy Langfuse is that production agent teams rarely stay inside one runtime: Claude Code emits one shape of telemetry, Codex has another configuration surface, and OpenCode is extensible through plugins. Langfuse matters when you need one backend that can accept those streams, map them onto prompt and tool semantics, and keep cost, session, and trace views in the same place.[2][5][7][8]

## Key facts

1. Langfuse recommends Docker Compose only for low-scale or local use and recommends Kubernetes or Terraform on AWS, Azure, or GCP for production and high availability.[1]
2. Langfuse's tracing model is built around prompts, model responses, latency, tool executions, retrieval steps, and metadata rather than generic APM spans.[2]
3. Langfuse accepts OTLP traces directly at `/api/public/otel`, supports HTTP JSON and HTTP protobuf, and uses standard OTEL attributes for user, session, tags, and model data.[7]
4. Ingested usage and cost data take priority over inferred pricing, which matters for billing and for models where token inference is incomplete.[3]
5. Claude Code ships first-party OpenTelemetry support, Codex exposes opt-in OpenTelemetry export in `config.toml`, and OpenCode exposes plugin hooks that let you forward session and tool events into your own telemetry pipeline.[9][10][11][12][13]
6. The strongest Langfuse comparison edge is full self-hosting plus OTEL-native ingestion, not merely having a nicer trace UI than the next vendor.[1][2][7]

## Self-host the six-container stack first, then harden it

The right Langfuse production setup starts with getting the infrastructure shape correct. Langfuse's own self-hosting guide splits the world into low-scale Docker Compose and production-grade Kubernetes or Terraform deployments, and it explicitly says production and high-availability teams should not stretch the local pattern forever.[1]

A production Langfuse deployment for a mixed coding-agent stack runs six containers: `langfuse-web`, `langfuse-worker`, `langfuse-postgres`, `langfuse-clickhouse`, `langfuse-redis`, and `langfuse-minio`. That is not arbitrary plumbing. It mirrors Langfuse's documented architecture: application containers on top of OLTP storage in Postgres, analytical storage in ClickHouse, queue/cache behavior in Redis, and S3-compatible object storage for uploaded events and media.[1]

Here is the trimmed six-container Compose shape:

```yaml
name: langfuse-stack
services:
  langfuse-postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: langfuse
      POSTGRES_USER: langfuse

  langfuse-clickhouse:
    image: clickhouse/clickhouse-server:24.3-alpine
    environment:
      CLICKHOUSE_DB: default
      CLICKHOUSE_USER: clickhouse

  langfuse-redis:
    image: redis:7-alpine

  langfuse-minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"

  langfuse-web:
    image: langfuse/langfuse:3
    ports:
      - "3200:3000"
    environment:
      CLICKHOUSE_CLUSTER_ENABLED: "false"
      LANGFUSE_S3_EVENT_UPLOAD_BUCKET: langfuse
      LANGFUSE_S3_MEDIA_UPLOAD_BUCKET: langfuse
      NEXTAUTH_URL: http://localhost:3200

  langfuse-worker:
    image: langfuse/langfuse-worker:3
    environment:
      CLICKHOUSE_CLUSTER_ENABLED: "false"
      LANGFUSE_S3_EVENT_UPLOAD_BUCKET: langfuse
```

Two details from the official docs and the live stack are easy to miss.

First, Langfuse warns that ClickHouse and Postgres must run in UTC or query results can go wrong or come back empty.[1] If your dashboards start looking haunted, this is one of the first settings to check.

Second, a single-node ClickHouse deployment usually needs `CLICKHOUSE_CLUSTER_ENABLED=false` because it cannot run replicated cluster defaults cleanly without ZooKeeper. That is the kind of practical wrinkle you only notice once you move from a marketing diagram to a stack that must actually boot.

A simple smoke test after `docker compose up -d` is enough to catch the obvious failures.

<curl>
curl -sf http://localhost:3200/api/public/health
</curl>

Expected output: HTTP 200 with Langfuse's health payload, which proves the web container is up and the dependency chain is at least coherent.

If you stop there, though, you only have infrastructure. Production starts when traces arrive with stable identity and cost metadata.

## Export OTLP from Claude Code, Codex, and OpenCode with the right expectations

The production pattern is straightforward: send OTLP to Langfuse, authenticate cleanly, and preserve metadata across every child span. Langfuse's native OpenTelemetry docs describe the OTLP endpoint, Basic Auth based on `public_key:secret_key`, and the attribute mapping for trace-level fields like `user.id`, `session.id`, and tags.[7] The same docs also clarify the reviewer-blocking point from the first draft: `x-langfuse-ingestion-version: 4` is for real-time Fast Preview behavior, not a universal requirement for all ingestion.[7]

Claude Code is the easiest of the three because Anthropic documents first-party telemetry. Claude Code supports OpenTelemetry for logs, metrics, and traces; the Agent SDK docs add trace spans for interactions, model requests, tool calls, and hooks when tracing is enabled.[9][10]

A minimal Claude Code environment looks like this:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1
export OTEL_TRACES_EXPORTER=otlp
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_ENDPOINT="https://cloud.langfuse.com/api/public/otel"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic $(printf '%s:%s' "$LANGFUSE_PUBLIC_KEY" "$LANGFUSE_SECRET_KEY" | base64)"
export OTEL_RESOURCE_ATTRIBUTES="service.name=claude-code,enduser.id=user-42,session.id=triage-007"
claude
```

That configuration is doing more than turning on pretty charts. It means Claude Code can export `claude_code.interaction`, `claude_code.llm_request`, and tool spans with the same session and user identity that Langfuse later uses for filtering and grouping.[9][10]

Codex is more configuration-driven. OpenAI's Codex docs say Codex uses OpenTelemetry, keeps OTEL export opt-in, and exposes exporters like `otlp-http` and `otlp-grpc` via `~/.codex/config.toml`.[11][12] The privacy model is similar to Claude Code in spirit: prompt logging is not on by default, which is the right default for enterprise coding agents.[11][12]

A minimal Codex setup looks like this:

```toml
# ~/.codex/config.toml
[otel]
exporter = "otlp-http"
endpoint = "https://cloud.langfuse.com/api/public/otel"
log_user_prompt = false

[analytics]
enabled = false
```

The important operational point is not the exact file syntax. It is that Codex has a real OTEL surface you can standardize, and OpenAI's advanced configuration docs say the event metadata includes service name, CLI version, conversation ID, model, sandbox settings, and approval settings.[11] That is enough to make Langfuse useful for debugging why one coding session cost twice as much as another.

OpenCode is the least turnkey in the sources here. Its official docs are strong on plugins and event hooks rather than on a first-party Langfuse recipe.[13] That does not make it a dead end. It just changes where you instrument. The OpenCode plugin system exposes session, tool, shell, and message hooks, and it includes structured application logging through `client.app.log()`.[13]

A practical OpenCode pattern is to forward those hooks into your own exporter or sidecar:

```typescript
export const LangfuseBridge = async ({ client }) => {
  return {
    "tool.execute.after": async (input, output) => {
      await client.app.log({
        body: {
          service: "opencode-langfuse-bridge",
          level: "info",
          message: `tool ${input.tool} completed`,
        },
      });
    },
    "session.created": async (session) => {
      await client.app.log({
        body: {
          service: "opencode-langfuse-bridge",
          level: "info",
          message: `session ${session.id} created`,
        },
      });
    },
  };
};
```

This is where the contrarian angle becomes concrete. Langfuse does not require every agent product to ship a bespoke Langfuse integration. It requires that your telemetry eventually lands in OTLP-compatible form, with stable metadata, so the backend can do something useful with it.[5][7][8] For Claude Code that path is first-party. For Codex it is config-driven. For OpenCode it is currently extension-driven.

If you want the protocol background for why this style of instrumentation ages well, the right supporting reading is [[course/mcp-from-first-principles-to-production/03-tools-resources-prompts]] and [[course/mcp-from-first-principles-to-production/05-gateways-audit-logs]]. Both make the same larger point: standard contracts beat product-specific glue.

## Make cost dashboards and agent graphs trustworthy before you rely on them

Langfuse's UI is not the reason to adopt it, but the UI is where the operational payback shows up. The observability overview docs describe traces, sessions, nested observations, prompt and response capture, tool executions, timing, and user tracking.[2] The research synthesis also notes agent graphs, timelines, dashboards, and multi-modal support, which is the right feature set for coding-agent teams that need to answer questions like "which tool step made this session slow?" or "which customer hit the expensive path?"

The cost side is where teams get lazy and then regret it. Langfuse's token and cost docs are explicit: ingested usage and cost data win over inferred values.[3] That is a big deal. Inferred pricing is useful for rough visibility. It is not what you want driving alerts, billing, or rate limits when the upstream provider already returns usage details.

The cost model is more nuanced than a single total token counter. Langfuse groups usage by input and output types, supports custom usage keys, maps common OpenAI schema fields automatically, and lets you define custom model definitions when the default price cards do not match your routing logic.[3] That means one dashboard can handle direct OpenAI calls, Anthropic wrappers, and custom aliases without turning into a spreadsheet operation.

The practical advice is simple:

- Ingest provider-reported `usage_details` and `cost_details` whenever you can.[3]
- Use model inference only as a fallback, not as the billing truth source.[3]
- Propagate `user.id`, `session.id`, and tags across every span, not just the root, or your dashboards will be useless when you need to filter by customer or rollout.[7]
- Treat agent graphs and sessions as debugging tools first and executive dashboards second.[2]

That last point matters. Too many teams buy observability tools for the board deck and only later realize the real value is opening one broken trace and seeing the exact prompt, tool chain, and timing breakdown that produced the failure.

## Pick Langfuse over LangSmith, Helicone, or Arize only when the tradeoff is real

The ticket asked for the comparison table, and it belongs here because the alternatives are not interchangeable.

| Feature | Langfuse | LangSmith | Helicone | Arize |
|---|---|---|---|---|
| Open source posture | Yes | No | Partial | Phoenix OSS alongside enterprise platform |
| Self-hosting | Full self-hosting | No full self-hosted path in the sources here | Proxy-style deployment focus | Partial, with Phoenix OSS angle |
| OTEL-native ingestion | Yes | Not documented as the core story in these sources | Gateway-first framing | Yes via OTEL and open-standard tracing |
| Best fit | Mixed agent stacks, self-hosting, prompt/cost tracing | LangChain-heavy teams | Gateway-centric traffic control | Enterprise ML and eval-heavy orgs |
| Cost model emphasis | Ingested plus inferred LLM cost tracking | Tracing and orchestration around LangChain ecosystem | Gateway analytics and provider routing | Evals, monitoring, enterprise AI platform |

That table is enough to make the non-obvious choice clear. Langfuse wins when you need three things at once: self-hosting, OTEL-native ingestion, and a data model that understands prompts and tool calls instead of just HTTP spans.[1][2][3][7] LangSmith is the narrower fit for teams already deep in the LangChain stack. Helicone is strongest when the gateway is the product. Arize is broader and heavier, especially if your center of gravity is model evaluation and enterprise monitoring rather than coding-agent tracing.[5]

The wrong move is to adopt Langfuse because it is open source and then keep your old observability stack anyway. The right move is to ask a harder question: what gap is still open after the stack you already have? If the answer is cross-framework agent traces, prompt-level cost views, or self-hosted AI-specific telemetry, Langfuse earns its place. If the answer is nothing, do not add a second system just because the screenshots look good.

## Use Langfuse when it removes glue code, not when it adds another dashboard

This is the operational summary. Langfuse is best treated as the backend that normalizes telemetry across the agents you already run, not as a sidecar you add for cosmetic reasons.[2][5][7][8] The production shape is a six-container self-hosted stack or Langfuse Cloud, plus disciplined OTLP export, metadata propagation, and ingested cost data.[1][3][7]

If your environment is already homogeneous and your current platform gives you strong native tracing, Langfuse may be extra work. If your environment is mixed—and coding-agent environments usually are—it is one of the cleaner ways to get from "we have logs somewhere" to "we can open a trace and see the whole agent story." That is the difference between observability as posture and observability as an operating tool.

<KnowledgeCheck
  question="Which production team gets the most leverage from Langfuse?"
  options={[
    "A team with one vendor-managed agent runtime and no self-hosting or cross-stack needs",
    "A team running Claude Code, Codex, and OpenCode-style workflows that wants one backend for traces, sessions, and cost data",
    "A team that only wants prettier graphs than their current dashboard",
    "A team that does not care about prompt, tool, or session metadata"
  ]}
  correctIdx={1}
  explanation="Langfuse is strongest when it removes observability fragmentation across heterogeneous agent stacks while preserving AI-specific trace semantics."
/>

For the hands-on production patterns after this architecture decision—hook-based tracing, cost circuit breakers, deployment hygiene, and operational guardrails—start with [[course/production-agents-claude-agent-sdk-mcp-connector]]. The most relevant chapter is [[course/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability]], and it pairs well with [[course/mcp-from-first-principles-to-production/05-gateways-audit-logs]] if your next problem is auditability rather than setup.

## References

[1] Self-host Langfuse (Open Source LLM Observability) — https://langfuse.com/self-hosting · retrieved 2026-05-12
[2] Observability & Application Tracing — https://langfuse.com/docs/observability/overview · retrieved 2026-05-12
[3] Token & Cost Tracking — https://langfuse.com/docs/observability/features/token-and-cost-tracking · retrieved 2026-05-12
[4] Get Started with Tracing — https://langfuse.com/docs/observability/get-started · retrieved 2026-05-12
[5] Langfuse Integrations Overview — https://langfuse.com/docs/integrations/overview · retrieved 2026-05-12
[6] langfuse/langfuse releases — https://github.com/langfuse/langfuse/releases · retrieved 2026-05-12
[7] OpenTelemetry (OTEL) for LLM Observability — https://langfuse.com/integrations/native/opentelemetry · retrieved 2026-05-12
[8] OpenTelemetry (OTel) for LLM Observability — https://langfuse.com/blog/2024-10-opentelemetry-for-llm-observability · retrieved 2026-05-12
[9] Monitoring Claude Code with OpenTelemetry — https://code.claude.com/docs/en/monitoring-usage · retrieved 2026-05-12
[10] Observability with OpenTelemetry in Claude Agent SDK — https://code.claude.com/docs/en/agent-sdk/observability · retrieved 2026-05-12
[11] Codex Advanced Configuration — https://developers.openai.com/codex/config-advanced · retrieved 2026-05-12
[12] Codex Sample Configuration — https://developers.openai.com/codex/config-sample · retrieved 2026-05-12
[13] OpenCode Plugins — https://opencode.ai/docs/plugins/ · retrieved 2026-05-12
