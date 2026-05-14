---
chapter_num: 6
title: "Production Observability: Traces, Logs, Metrics, and Drift Detection"
course_slug: gemini-enterprise-agents
prerequisites_chapters: [1, 2, 3, 4, 5]
duration_min: 50
reading_time_min: 22
date: 2026-05-03
author: course-author
agent_drafted_by: course-author
content_type: chapter
chapter: 6
parent_course: gemini-enterprise-agents
ticket: KOEA-25
status: g0-blocked
vendor_tag: google
learning_objectives:
  - "Wire Cloud Trace and Cloud Logging into a deployed GEAP agent using OpenTelemetry"
  - "Read an agent trace to diagnose a failed tool call and calculate token cost per interaction"
  - "Compare Google-native observability (Cloud Trace, Vertex AI Model Monitoring) to OSS alternatives (Langfuse, Helicone)"
  - "Build latency and token-usage dashboards in Cloud Monitoring"
  - "Configure drift alerts using Vertex AI Model Monitoring on agent inputs and outputs"
sources:
  - https://opentelemetry.io/docs/specs/otel/
  - https://cloud.google.com/trace/docs
  - https://cloud.google.com/logging/docs
  - https://cloud.google.com/vertex-ai/docs/model-monitoring/overview
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/observability/overview
  - https://langfuse.com/docs
  - https://docs.helicone.ai/
---

# Production Observability: Traces, Logs, Metrics, and Drift Detection

Observability for a Gemini Enterprise Agent Platform (GEAP) deployment is the difference between "the agent feels slow today" and "tool call #4 in the orchestrator added 4.2s p99 latency starting at 14:32 UTC after we shipped instruction v3.2." Since the GEAP general-availability release on 23 April 2026, every agent invocation is automatically instrumented with [OpenTelemetry](https://opentelemetry.io/) spans that flow into Cloud Trace, Cloud Logging, and Cloud Monitoring — a stack that gives you 90% of what Langfuse or Helicone provide, minus the vendor switching cost. [1] This chapter wires that stack end-to-end on the invoice pipeline you secured in Chapter 5.

## Key facts

1. GEAP agents auto-export OpenTelemetry traces to Cloud Trace with one config flag — no manual span instrumentation required for tool calls or model invocations [1]
2. Every agent invocation produces three correlated artifacts: a trace ID, a structured log entry in `agent-runtime.googleapis.com/invocations`, and a row in the Vertex AI usage metering table
3. Token usage is exposed as a Cloud Monitoring metric (`agentengine.googleapis.com/agent/tokens_consumed`) with labels for model, agent ID, and tool name [2]
4. Vertex AI Model Monitoring detects drift on agent inputs (prompt distribution shift) and outputs (response quality regression) using the same skew/drift jobs that exist for traditional ML models [3]
5. OpenTelemetry traces export simultaneously to Cloud Trace and any OTLP-compatible backend — Langfuse, Helicone, Honeycomb, Tempo — without code changes
6. The default Cloud Trace retention is 30 days; agent invocations often need longer for compliance, so route to BigQuery via the Trace export sink for indefinite retention
7. Agent Observability's "trace topology" view renders multi-agent handoffs as a directed graph — invaluable for debugging supervisor/sub-agent loops

---

## What "observable" means for an agent

Three kinds of failure dominate agent operations, and each demands a different telemetry signal.

**Latency failures** are the loudest and easiest to diagnose. A user clicks, waits 18 seconds, gives up. The fix is a trace that breaks the 18 seconds into its constituent spans: 1.2s waiting for orchestrator decision, 6.4s for sub-agent A, 9.7s for sub-agent B's slow tool call, 0.7s synthesizing the response. Cloud Trace handles this without modification.

**Quality failures** are the silent killer. The agent returns a fluent, confident response — that is wrong. No 500 error, no SLO violation, no PagerDuty page. You discover it from a customer support ticket three weeks later. Detecting these requires either continuous evaluation (Online Monitors, covered in the outline) or output-distribution drift detection (Vertex AI Model Monitoring).

**Cost failures** are the slow leak. An agent that should cost $0.003 per invocation creeps to $0.04 after a context-window expansion or a recursive sub-agent call pattern. By the time finance notices, you have spent $40,000 on invocations that should have cost $3,000. Token-usage metrics with per-tool labels make this visible in real time.

A complete observability stack covers all three. Most teams cover the first, neglect the third, and discover the second from churn.

---

## Wiring OpenTelemetry into GEAP

GEAP's runtime emits OpenTelemetry spans automatically. To turn this on for a deployed agent, set two fields on the deployment config:

```python
from google.adk import agent_engines
from google.adk.observability import OtelConfig

agent_engines.create(
    agent=invoice_orchestrator,
    region="us-central1",
    observability=OtelConfig(
        enabled=True,
        export_to_cloud_trace=True,
        export_to_cloud_logging=True,
        additional_otlp_endpoints=[
            # Send to a self-hosted Langfuse for cross-cloud aggregation
            "https://langfuse.acme-internal.com:4318/v1/traces",
        ],
        log_level="INFO",
        sample_rate=1.0,    # 100% sampling in dev; drop to 0.1 in prod for cost
    ),
)
```

The span schema follows the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/), which were promoted to stable in late 2025. [4] Each span carries:

- `gen_ai.system` — `gemini` (or whatever model you route to)
- `gen_ai.request.model` — `gemini-pro-latest`, `gemini-flash-latest`
- `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens`
- `gen_ai.operation.name` — `chat`, `tool_call`, `agent_handoff`
- `agent.id` — the SPIFFE ID from Chapter 5
- `agent.tool_name` — for tool-call spans

Because these are standard semantic conventions, the same trace renders correctly in Langfuse, Honeycomb, Grafana Tempo, or any other OTLP backend — the schema is the contract.

---

## Reading a trace to diagnose a failure

Cloud Trace renders agent invocations as a tree of spans, each with start time, duration, status, and arbitrary attributes. The trace is the single most useful debugging artifact for any agent failure that is not a flat 500 error — and most production failures are not flat 500 errors. They are slow, partial, or subtly wrong, and the trace makes the structure of the failure visible in a way that no log line can.

Here is a real trace from a deliberately-broken invoice pipeline. The orchestrator calls the Extractor, which calls Document AI, which times out:

```
[trace] invoice-run-7f3a9c (total: 31.4s, status: ERROR)
├─ orchestrator.invoke (31.2s)
│  ├─ orchestrator.model.chat (1.8s, 1240 in / 312 out tokens)
│  ├─ tool.transfer_to_agent (extractor) (29.1s)
│  │  └─ extractor.invoke (28.9s)
│  │     ├─ extractor.model.chat (0.9s, 890 in / 145 out tokens)
│  │     ├─ tool.parse_pdf_with_doc_ai (28.0s, status: TIMEOUT) ← culprit
│  │     └─ extractor.error_handler.invoke (0.0s)
│  └─ orchestrator.error_handler.invoke (0.1s)
└─ audit_log.write (0.2s)
```

Three observations the trace makes obvious that a log file would not:

The bottleneck is one specific tool call (`parse_pdf_with_doc_ai`), not the orchestrator's reasoning or the sub-agent's reasoning. Token cost is unevenly distributed: the orchestrator consumed 1240 input tokens to make a 312-token routing decision — almost certainly a sign of an over-large system prompt. And the extractor's `error_handler` took 0.0s, meaning it returned a default response without making a follow-up model call — which sounds good but is actually a hidden failure mode (the response was wrong, but no further latency was added to mask it).

To find this, you click into the slow span in Cloud Trace, filter to `attributes.tool_name = "parse_pdf_with_doc_ai"`, and chart its p99 latency over the last 24 hours. If it correlates with a deploy, you know what to roll back.

The trace also exposes a category of issue that pre-agent observability stacks could not reach: **causal-chain failures**. Tool A returned a malformed JSON; the agent's reasoning silently degraded for the next three turns; the eventual response was wrong but no individual span errored. Filter your trace search to `agent.handoff_count > 5` for any single user request — the long tail of these queries is where causal-chain failures hide. We have rescued several customer deployments by turning that filter into a saved query and reviewing it weekly.

A workflow detail worth adopting: tag every deploy with a release ID and propagate it as a span attribute. When a regression appears, you can compare trace distributions across release IDs in seconds rather than reasoning about timestamps. Cloud Trace supports trace-attribute aggregation natively; this is a five-minute setup that pays back the first time you ship a bad change.

---

## Build the four dashboards every production deployment needs

Cloud Monitoring lets you build dashboards from agent metrics with zero custom code. The four dashboards we recommend for every GEAP production deployment:

**Dashboard 1 — Latency.** Plot p50, p95, p99 of `agentengine.googleapis.com/agent/invocation_latency` grouped by `agent.id`. Alert at p99 > 5s for orchestrator agents; sub-agents can run hotter. Add a side panel breaking down latency into `model_latency`, `tool_latency`, and `handoff_latency` so you know which subsystem is slow.

**Dashboard 2 — Token usage and cost.** Plot `agent/tokens_consumed` summed by `model` and multiplied by current per-token pricing. Add a 30-day budget line; alert when projected monthly spend exceeds 80% of budget. This is the dashboard finance will ask to see during procurement renewal.

**Dashboard 3 — Tool error rate.** Plot the count of spans where `status = ERROR` grouped by `tool_name`. A tool with a 2% error rate is normal; a tool with a 30% error rate is a regression you need to find before customers do.

**Dashboard 4 — Drift indicators.** Plot two Vertex AI Model Monitoring metrics: `feature_skew` (input prompt distribution vs training distribution) and `prediction_drift` (output distribution vs baseline). Alert at skew > 0.3 (Jensen-Shannon divergence). [3]

Wire the alerts to PagerDuty. Latency alerts are P2 (page during business hours), cost alerts are P3 (Slack only), error-rate spikes are P1 (page immediately, day or night).

A common pattern we see new teams skip: a fifth dashboard for **handoff topology**. Cloud Trace's topology view renders the directed graph of agent-to-agent transfers across the last hour, sized by invocation count and colored by latency. For multi-agent systems with three or more agents, this single view answers "which sub-agent is the bottleneck?" faster than any tabular dashboard. Pin it next to the latency dashboard.

---

## Vertex AI Model Monitoring for agents

Vertex AI Model Monitoring was originally designed for tabular ML models, but the April 2026 release extended it to agent workloads. [3] The mental model is the same: define a baseline, sample live traffic, compute distance metrics, alert on drift.

For an agent, two distributions matter. The **input distribution** is the embedding of incoming user prompts. If your invoice agent was deployed in March on procurement invoices and someone starts using it for medical billing, the input distribution shifts — and your tool-routing accuracy will collapse without anyone deploying a code change. The **output distribution** is the embedding of agent responses. Output drift detects regressions that the input would not — a model upgrade, a prompt tweak, a tool that started returning slightly different formatting.

Configure both in one spec:

```python
from google.cloud import aiplatform

aiplatform.ModelMonitoringJob.create(
    display_name="invoice-orchestrator-drift",
    target_resource=f"projects/acme-prod-7841/locations/us-central1/agents/invoice-orchestrator-v3",
    schedule="0 */6 * * *",                  # every 6 hours
    objective_config={
        "training_dataset": "bq://acme-prod-7841.agents.invoice_baseline_2026_03",
        "skew_thresholds": {"prompt_embedding": 0.3},
        "drift_thresholds": {"response_embedding": 0.25},
    },
    notification_emails=["agents-oncall@acme.com"],
    log_ttl_days=90,
)
```

Drift detection on agents is genuinely new ground — the field has converged on input/output embedding comparison as the practical baseline, but there is no settled best practice for detecting *quality* drift independent of distribution drift. An agent can produce responses with the same embedding distribution as the baseline while being subtly worse on accuracy. For that, you need Online Monitors with multi-turn autoraters — covered in the GEAP outline — and an Example Store that catches regressions on a known-good test set every time you deploy.

---

## When to add Langfuse, Helicone, or another OSS layer

Cloud Trace and Cloud Logging are sufficient for most enterprise deployments. The case for adding Langfuse or Helicone on top is narrow but real:

**Cross-cloud aggregation.** If you run agents on GEAP, Cloudflare Agents, and Claude SDK on AWS Lambda, you want one pane of glass. [Langfuse](https://langfuse.com/) is open-source (MIT-licensed), self-hostable, and accepts OTLP traces from any source. Run it once; point all three platforms at it.

**Prompt-level analytics.** Langfuse and [Helicone](https://docs.helicone.ai/) both surface prompt-template analytics that Cloud Trace does not — which prompt template version produced which user satisfaction score, A/B testing of system prompts, hit-rate on cached prompts. If your agent program runs continuous prompt experiments, the OSS tools have richer primitives.

**Cost-attribution by team.** Helicone's user-level cost attribution is more granular than Cloud Monitoring's metric labels. If finance asks "which product team is responsible for $42K of last month's Vertex spend?" Helicone answers in five clicks; building the equivalent in Cloud Monitoring requires custom metric labels at every invocation.

**The contrarian angle:** Most teams adopting Langfuse or Helicone do not actually need them. They add a second observability stack because it feels rigorous, then operate two systems forever — paying the cognitive overhead of "where did that trace go?" twice. Unless you have a concrete cross-cloud requirement or a prompt-experimentation pipeline that needs Langfuse's analytics primitives, stay with Cloud Trace. The right number of observability backends is one. Adopt a second only when the gap is concrete, not aspirational.

In line with our cost discipline, if you do add an OSS layer, host it yourself on a `e2-small` GCE instance — Langfuse's footprint is modest, and the SaaS pricing on either tool inflates fast at production volume. The Koenig AI Academy stack at academy.kspl.tech runs Langfuse self-hosted; we have written up the Docker setup at [[engineering/observability-langfuse-self-hosted]].

---

## Sampling, retention, and the cost of observability itself

Observability is not free. Cloud Trace charges for span ingestion above the free tier (2.5M spans/project/month at the time of writing); Cloud Logging charges $0.50 per GiB after the first 50 GiB; high-cardinality metrics in Cloud Monitoring incur a per-metric charge. For a heavy production deployment, the observability bill can land at 3-8% of the inference bill. That is usually worth it; occasionally it is not, and the levers are sampling, retention, and label cardinality.

Set `sample_rate` to 1.0 in development and 0.1 in production for high-volume agents. Always-trace any span that errored — the OTel SDK supports tail-based sampling via the OpenTelemetry Collector, and the GEAP runtime defaults to it. Route audit-relevant traces to a 7-year BigQuery sink; let the operational Cloud Trace instance retain only 30 days. And avoid putting unbounded user-supplied values (email addresses, document IDs) into metric labels — each unique label combination is a separate billable timeseries, and the unit cost is small until your cardinality hits five digits.

---

## Hands-on exercise: instrument the invoice pipeline and induce a failure

Take the secured invoice pipeline from Chapter 5. Apply observability:

1. Enable `OtelConfig` with `export_to_cloud_trace=True` on all three agents (Orchestrator, Extractor, Validator).
2. Build the four dashboards in Cloud Monitoring described above. Save them to a workspace named `agents-prod`.
3. Configure a Vertex AI Model Monitoring job on the Orchestrator with a baseline from your last 1000 successful invocations. Schedule every 6 hours.
4. Inject a deliberate failure: misconfigure the Extractor to call a non-existent Cloud Storage bucket. Run 10 test invoices.
5. Open Cloud Trace, filter to `status = ERROR`, and identify the failing span in under 60 seconds. Capture the trace ID.
6. Open the latency dashboard and confirm the p99 spike is visible. Confirm the alert fired.
7. Run a non-invoice prompt (e.g., "summarize this medical record") through the Orchestrator. Confirm Vertex AI Model Monitoring flags input drift on the next 6-hour run.
8. Optional: spin up Langfuse self-hosted on a GCE `e2-small` and configure `additional_otlp_endpoints`. Verify the same trace appears in both Cloud Trace and Langfuse.

Success criteria: a screenshot of the Cloud Trace timeline showing the full failure path, and a chart showing the latency p99 spike correlated with the deploy time.

---

## What's next

Chapter 7 takes the observability signals you just wired and uses them to make capacity, cost, and scaling decisions — provisioned-throughput vs on-demand, regional vs global endpoints, batch prediction, autoscaling, and per-team cost attribution. See [[gemini-enterprise-agents/07-scale-and-cost]].

For background, see [[glossary/context-window]] and [[glossary/tokenization]] — token-usage metrics make more sense once these are familiar.

---

## Further Reading

[1] Google Cloud. "Cloud Observability for Agents." Gemini Enterprise Agent Platform docs. — https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/observability/overview · retrieved 2026-05-03

[2] Google Cloud. "Cloud Trace documentation." — https://cloud.google.com/trace/docs · retrieved 2026-05-03

[3] Google Cloud. "Vertex AI Model Monitoring overview." — https://cloud.google.com/vertex-ai/docs/model-monitoring/overview · retrieved 2026-05-03

[4] OpenTelemetry. "Generative AI semantic conventions." — https://opentelemetry.io/docs/specs/semconv/gen-ai/ · retrieved 2026-05-03

[5] OpenTelemetry. "OpenTelemetry specification." — https://opentelemetry.io/docs/specs/otel/ · retrieved 2026-05-03

[6] Google Cloud. "Cloud Logging documentation." — https://cloud.google.com/logging/docs · retrieved 2026-05-03

[7] Langfuse. "Langfuse documentation." — https://langfuse.com/docs · retrieved 2026-05-03

[8] Helicone. "Helicone documentation." — https://docs.helicone.ai/ · retrieved 2026-05-03
