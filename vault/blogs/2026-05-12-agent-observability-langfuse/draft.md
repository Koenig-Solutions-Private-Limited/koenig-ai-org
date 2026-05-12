---
date: 2026-05-12
author: blog-author
ticket: KOEA-1338
vendor_tag: community
content_type: article
status: draft-for-review
reading_time_min: 6
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
whats_new:
  - Langfuse's real production value is acting as one OTLP backend for mixed agent stacks, not adding another pretty trace UI
learning_objectives:
  - Decide when Langfuse belongs in a production agent stack and when it just creates a second observability system
  - Configure a production-grade setup around self-hosting, OTLP export, metadata propagation, and cost tracking
faq:
  - question: "What is the fastest reliable way to set up Langfuse for production AI agent observability?"
    answer: "Use Langfuse as an OTLP backend, export traces over HTTP to /api/public/otel with Basic Auth, propagate user and session metadata on every span, and run Helm or Terraform instead of stretching Docker Compose into production."
  - question: "When should a team skip Langfuse?"
    answer: "Skip it when your agents already live inside one cloud stack with strong native tracing and you do not need cross-framework aggregation, prompt analytics, or self-hosting."
---

# Use Langfuse as your OTLP backend when agent observability has to survive production

If you are setting up Langfuse for production AI agent observability, the shortest reliable path is to treat it as an OpenTelemetry backend, not just a trace viewer. Langfuse supports low scale Docker deployments for trials, recommends Helm or Terraform for high-availability production, and exposes an OTLP ingestion endpoint so standard-instrumented agent stacks can send traces without bespoke adapters.[^1][^4][^7]

Most coverage frames Langfuse as an open source alternative to other AI observability tools. That misses the production point. The real advantage appears when your agents do not all live in the same runtime: maybe one flow uses the OpenAI SDK, another uses LangChain, and a third emits plain OTEL spans. In that world, the value is not "another dashboard." The value is one backend that can accept all of it while still understanding prompts, token usage, tool calls, sessions, and evaluations.[^2][^5][^7][^8]

## Use Langfuse when you need one trace backend across agent frameworks

Langfuse makes the most sense when observability has to cut across multiple agent stacks. Its docs position the product around application tracing for LLM systems, capturing prompts, responses, latency, tool executions, retrieval steps, and metadata, while the integrations catalog spans major providers, frameworks, agent runtimes, and gateways.[^2][^5]

That matters because production agent systems rarely stay clean for long. A team might start with direct OpenAI calls, add LiteLLM for routing, introduce LangChain for one workflow, and later instrument internal tools with plain OpenTelemetry. If every step picks its own observability layer, debugging one bad customer session turns into archaeology. Langfuse's OTEL-native endpoint is the cleaner pattern: keep the tracing contract standard, then let Langfuse map those spans into LLM-specific concepts.[^5][^7][^8]

The flip side is just as important. If you already run one platform with good native traces and you do not need cross-cloud or cross-framework aggregation, Langfuse may be unnecessary overhead. The right number of observability systems is usually one, not two.

## Self-host with Docker for trials and Helm or Terraform for production

For a proof of concept, Docker Compose is enough. For production, Langfuse explicitly steers teams toward Kubernetes or Terraform deployments on AWS, Azure, or GCP instead of stretching the low-scale setup past its limits.[^1]

The self-hosting guide is clear about the split. Docker Compose is for local and testing use. Production deployments are the supported path when you care about high availability, scaling, backups, or stricter network boundaries.[^1] The same guide describes the underlying shape: two application containers, PostgreSQL and ClickHouse for storage, plus optional object storage and other operational components.[^1] It also carries one detail teams often miss until dashboards go weird: ClickHouse and Postgres must run in UTC, or queries can return incorrect or empty results.[^1]

That makes the production decision simpler than it first looks:

- Use Docker Compose when one engineer wants traces today.
- Use Helm or Terraform when observability is now shared infrastructure.
- Self-host at all only when privacy, network policy, regional control, or procurement rules justify owning the stack.[^1]

If none of those pressures exist, Langfuse Cloud is the faster path. If they do, the open source self-host story is one of Langfuse's strongest practical advantages.[^1][^2]

## Export OTLP to Langfuse and propagate metadata on every span

The core production wiring is simple: export OTLP over HTTP to Langfuse, authenticate with Basic Auth, and make sure user, session, and tag metadata follows the whole trace. Langfuse's OTEL endpoint supports HTTP JSON and HTTP protobuf, uses `/api/public/otel` or signal-specific paths, and requires the `x-langfuse-ingestion-version: 4` header for the current ingestion format.[^7]

The subtle part is metadata propagation. Langfuse's OTEL docs warn that attributes like `user.id`, `session.id`, and `langfuse.trace.tags` need to reach every span if you want reliable filtering and aggregation later.[^7] Their recommended pattern is OpenTelemetry baggage, which copies those values through downstream spans automatically.[^7] That is the difference between "we have traces" and "we can answer which customer, session, and rollout variant produced this failure in under a minute."

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Show a minimal Node.js OpenTelemetry setup that exports agent traces to Langfuse over OTLP HTTP. Use Langfuse Basic Auth from LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY, set the endpoint to LANGFUSE_HOST + '/api/public/otel', include the x-langfuse-ingestion-version: 4 header, and propagate user.id, session.id, and langfuse.trace.tags to downstream spans with baggage."
  expectedOutput="A short Node.js module that configures OTLPTraceExporter for Langfuse, builds the Basic Auth header from public and secret keys, and includes a helper that stamps user.id, session.id, and tags onto all child spans via baggage."
/>

This is also where Langfuse's positioning becomes concrete. You do not have to wait for a first-party integration for every new agent library. If the library can emit sane OTEL spans, Langfuse can already ingest them.[^5][^7][^8]

## Trust ingested token and cost data more than inferred pricing

Langfuse can infer usage and cost, but production billing and cost guardrails should prefer ingested numbers whenever the model provider returns them. Langfuse's token and cost docs state that ingested usage and cost take precedence over inferred values, and they call out cases where inference is not reliable enough, including reasoning models whose hidden tokens cannot be reconstructed from tokenization alone.[^3]

That distinction matters more than it sounds. In a demo, inferred usage is fine. In production, cost dashboards often drive rate limits, alerts, customer billing, or internal budget reviews. If you depend on those numbers, send the real `usage_details` and `cost_details` from the provider response when you can.[^3] Langfuse will still map common provider schemas automatically, including OpenAI-style `prompt_tokens` and `completion_tokens`, but automatic mapping is a convenience, not a substitute for clean upstream telemetry.[^3]

The same page also notes that custom model definitions can override defaults through the UI or API.[^3] That is useful in mixed fleets where the model string alone is not enough to map to the right price card. If your team changes pricing, routing tiers, or internal aliases frequently, keeping those definitions explicit will save you a surprising amount of debugging.

## Skip Langfuse if it does not remove a real observability gap

The strongest case for Langfuse is cross-framework visibility with LLM-specific analytics. The weakest case is adding it out of habit. Langfuse's own docs lean into openness, self-hosting, and OTEL compatibility, which is exactly why it works well as a shared backend for heterogeneous agent systems.[^1][^5][^7]

That does not mean every team should install it. If your current stack already gives you reliable traces, cost visibility, and retention in one place, adding Langfuse can create duplicate pipelines, duplicate access controls, and duplicate failure modes. The standard to apply is simple: does Langfuse remove glue code, unlock self-hosting, or unify tracing across runtimes you actually run? If yes, it is a production tool. If not, it is another thing to operate.

<KnowledgeCheck
  question="Which production setup gets the most leverage from Langfuse?"
  options={[
    "A single vendor stack that already has strong native tracing and no self-hosting requirement",
    "A mixed agent stack that emits OTEL from multiple frameworks and needs one backend for prompts, tools, sessions, and cost data",
    "A prototype with no tracing yet where cost tracking does not matter",
    "A local script that runs once a week and writes logs to stdout"
  ]}
  correctIdx={1}
  explanation="Langfuse is strongest when it unifies observability across heterogeneous agent runtimes while preserving LLM-specific trace semantics."
/>

If you want the implementation playbook after this architecture call, work through [[course/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability]]. It is the right Academy follow-on once you need hook-based tracing, cost circuit breakers, and production deployment patterns around Langfuse.

## Further reading

1. Langfuse, "Self-host Langfuse (Open Source LLM Observability)" — https://langfuse.com/self-hosting · retrieved 2026-05-12
2. Langfuse, "Observability & Application Tracing" — https://langfuse.com/docs/observability/overview · retrieved 2026-05-12
3. Langfuse, "Token & Cost Tracking" — https://langfuse.com/docs/observability/features/token-and-cost-tracking · retrieved 2026-05-12
4. Langfuse, "Get Started with Tracing" — https://langfuse.com/docs/observability/get-started · retrieved 2026-05-12
5. Langfuse, "Langfuse Integrations Overview" — https://langfuse.com/docs/integrations/overview · retrieved 2026-05-12
6. Langfuse, "langfuse/langfuse releases" — https://github.com/langfuse/langfuse/releases · retrieved 2026-05-12
7. Langfuse, "OpenTelemetry (OTEL) for LLM Observability" — https://langfuse.com/integrations/native/opentelemetry · retrieved 2026-05-12
8. Langfuse, "OpenTelemetry (OTel) for LLM Observability" — https://langfuse.com/blog/2024-10-opentelemetry-for-llm-observability · retrieved 2026-05-12
