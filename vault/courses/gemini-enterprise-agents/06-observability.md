---
chapter_num: 6
title: "Production Observability and Evaluation for Gemini Enterprise Agents"
course_slug: gemini-enterprise-agents
prerequisites_chapters: [1, 2, 3, 4, 5]
duration_min: 50
reading_time_min: 27
date: 2026-05-14
author: course-author
agent_drafted_by: course-author
content_type: chapter
chapter: 6
parent_course: gemini-enterprise-agents
ticket: KOEA-2633
status: g0-blocked
review_target: content-reviewer
revision_note: "KOEA-2633 G0 fixes complete: unsupported auto-instrumentation, metric, OTel status, Model Monitoring, pricing, retention, and OTLP claims removed or replaced with sourced Agent Runtime observability and Agent Platform evaluation guidance."
vendor_tag: google
learning_objectives:
  - "Configure OpenTelemetry-backed tracing and logging for an ADK agent on Agent Runtime"
  - "Read a trace DAG to isolate a slow or failed tool call in the invoice pipeline"
  - "Build Cloud Monitoring views for request count, latency, error rate, and tool-call volume"
  - "Set up offline evaluations and Online Monitors to catch quality regressions"
  - "Use failure clusters and prompt optimization output to choose the next fix"
sources:
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/tracing
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/logging
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/monitoring
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/observability/overview
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-agents
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-offline
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-online
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/view-results
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/optimize-agent
---

# Production Observability and Evaluation for Gemini Enterprise Agents

Chapter 5 made the invoice pipeline defensible: every agent had an identity, traffic flowed through governance controls, and risky tool calls could be inspected. That is necessary, but it does not tell you whether the system is healthy after launch.

This chapter turns the secured pipeline into an observable system. By the end, you will know how to answer four production questions without guessing:

1. Which agent, model call, or tool made this request slow?
2. Did this failure come from infrastructure, a tool, policy enforcement, or agent reasoning?
3. Are latency and error rates trending in the wrong direction?
4. Is answer quality drifting even when the runtime looks healthy?

The correction from the earlier draft is important: do not treat classic Vertex AI Model Monitoring as the agent-quality answer. For Gemini Enterprise Agent Platform, the documented path is trace-backed observability plus the Agent Platform evaluation workflow: offline evaluations for test sets, Online Monitors for production traffic, and failure-cluster analysis for root-cause work. Google documents Agent Runtime tracing through OpenTelemetry environment variables, built-in Cloud Monitoring metrics for the `aiplatform.googleapis.com/ReasoningEngine` resource, Cloud Logging routes for deployed agents, and Agent Platform Online Monitors that sample Cloud Trace and Cloud Logging on a schedule.[^trace][^monitoring][^logging][^online]

<Callout type="warn">
**Do not make prompt and response capture your default production setting.** Agent traces can include inputs and outputs when you enable content capture. That is useful during debugging and evaluation, but it can also store customer data in observability systems. Start with metadata-only traces, enable content capture only for controlled environments or sampled monitors, and record large multimodal artifacts to Cloud Storage when the docs recommend it.
</Callout>

---

## Prerequisites check

You should have:

- The three-agent invoice pipeline from Chapter 4: Orchestrator, Extractor, and Validator.
- The security controls from Chapter 5: agent identities, gateway routing, and Model Armor inspection where your deployment uses it.
- A deployed Agent Runtime instance or a staging deployment you can redeploy.
- Google Cloud permissions to view Cloud Trace, Cloud Logging, and Cloud Monitoring. At minimum, reviewers need Monitoring Viewer and Logs Viewer-style access for this chapter's checks.

If you do not have a deployed agent yet, you can still complete the reasoning exercises and RunPromptCells, but the hands-on exercise requires a staging deployment.

---

## The agent observability stack

A production agent needs more than "the endpoint returned 200." Agent behavior is a chain: user request, orchestrator decision, tool call, sub-agent handoff, model call, policy check, final response. A normal HTTP metric tells you whether the outer request succeeded. It does not tell you whether the agent silently skipped a required tool, called the wrong extractor, or spent 24 seconds waiting on Document AI before returning a fallback answer.

Gemini Enterprise Agent Platform splits the problem across four layers.

**Traces** show the execution path. Google describes a trace as a timeline for a query, composed of spans that represent units of work such as function calls, LLM interactions, or tool executions.[^trace] For your invoice pipeline, the trace is where you see that the Orchestrator called the Extractor, the Extractor called Document AI, and the Validator rejected a schema field.

**Logs** capture event detail. Agent Runtime can route stdout and stderr to Cloud Logging by default, and Python logging or the Cloud Logging client can write structured log entries against the Reasoning Engine resource.[^logging] Logs are best for durable business facts: invoice ID, supplier class, gateway policy decision, retry count, or the evaluation case ID that produced a failure.

**Metrics** capture trends. Agent Runtime automatically collects operational metrics for deployed agents, including request count, request latencies, container CPU allocation time, and container memory allocation time for the Reasoning Engine monitored resource.[^monitoring] If you need tool-call counts or custom business counters, Google recommends log-based metrics or user-defined metrics.[^monitoring]

**Evaluation signals** capture quality. Agent Platform evaluation supports rapid evaluation, test-case evaluation, and Online Monitoring. Google frames these as development, CI/CD, and production evaluation modes respectively.[^eval] Online Monitors continuously score sampled live traces using predefined or custom metrics and export results to Cloud Logging and Cloud Monitoring.[^online]

The practical rule is simple: use traces to debug one request, logs to preserve event facts, metrics to detect trend changes, and evaluations to detect answer-quality regressions.

---

## Configure tracing without inventing an API

The previous version of this chapter used a fictional `OtelConfig` object. The current documented setup for ADK agents on Agent Runtime is environment-variable based. To enable tracing for an ADK agent, set OpenTelemetry-related environment variables when deploying to Agent Runtime:

```python
env_vars = {
    "GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY": "true",
    "OTEL_SEMCONV_STABILITY_OPT_IN": "gen_ai_latest_experimental",
    "OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT": "EVENT_ONLY",
}
```

Google's tracing documentation says `GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY` enables agent traces and logs but does not include prompt and response data by itself. The semantic-convention opt-in enables the latest generative AI conventions. The content-capture setting enables logging of input prompts and output responses.[^trace]

That last setting deserves a design decision, not a copy-paste. For the invoice pipeline, prompt and response capture might include supplier names, addresses, bank details, purchase-order numbers, and invoice attachments. In development, capture is useful because it lets you inspect the exact evidence behind a bad extraction. In production, capture should be sampled, access-controlled, and retention-limited. If the agent processes large documents or multimodal payloads, Google recommends recording media in Cloud Storage instead of embedding it directly in trace spans for Online Monitors.[^online]

For non-ADK frameworks, the setup differs. LangChain and LangGraph agent wrappers can enable tracing with an `enable_tracing=True` parameter in Google's examples, while custom agents should use OpenTelemetry instrumentation directly.[^trace] The goal is the same: emit spans that Cloud Trace and Agent Platform observability can assemble into a useful request timeline.

<RunPromptCell
  model="gemini-3.1-pro-preview"
  prompt="You are reviewing this Agent Runtime telemetry config for a regulated invoice-processing agent:\n\nGOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY=true\nOTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental\nOTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=EVENT_ONLY\n\nProduce a deployment review with three sections: (1) what each variable does, (2) what privacy or retention risk it introduces, and (3) the production policy you would recommend for a staging environment versus a production environment. Keep the answer specific to invoices and supplier data."
  expectedOutput="A strong answer explains that telemetry enables traces/logs, semantic-convention opt-in standardizes gen-ai attributes, and content capture can log prompts/responses. It should recommend full or high capture in staging, sampled or disabled content capture in production unless needed for controlled Online Monitors, and explicit retention/access controls for invoice and supplier data."
/>

---

## Read the trace DAG, not just the top-line latency

Cloud Trace and the Agent Platform Traces tab let you inspect a session or span and view a directed acyclic graph of spans, inputs/outputs, and metadata attributes.[^trace] That DAG is the fastest way to debug a multi-agent request because it preserves the causal path.

Suppose a customer uploads an invoice and the system takes 31 seconds before returning "unable to validate." A flat log search gives you several events. The trace shows the shape:

```text
invoice-run-7f3a9c total=31.4s status=ERROR
  orchestrator.invoke 31.2s
    orchestrator.model 1.8s
    transfer_to_agent extractor 29.1s
      extractor.invoke 28.9s
        extractor.model 0.9s
        tool.parse_pdf_with_document_ai 28.0s status=TIMEOUT
        extractor.fallback 0.0s
    validator.invoke skipped
  audit_log.write 0.2s
```

This trace tells you three things immediately.

First, the bottleneck is a tool call, not model reasoning. The orchestrator and extractor model spans are small compared with the Document AI span.

Second, the Validator did not run. That matters because a user-facing "unable to validate" message might imply validation failed, when the trace shows extraction never produced input for validation.

Third, the fallback path is suspicious. A zero-duration fallback might be a deterministic error template, which is fine, or it might be a hidden path that returns a generic answer without logging the root cause. Either way, it deserves inspection.

The anti-pattern is staring at the top-level p99 chart and guessing. The chart tells you there is pain. The trace tells you where the pain entered the system.

When reviewing a trace, use this order:

1. Confirm the top-level status and total duration.
2. Identify the longest child span and its status.
3. Check whether expected downstream spans are missing.
4. Compare model spans, tool spans, gateway or policy spans, and handoff spans separately.
5. Copy the trace ID into your incident notes and any evaluation case you create from the failure.

This last step connects operations to improvement. A trace that caused a customer incident should become either an offline evaluation case or an Online Monitor filter.

---

## Build the minimum production dashboard

Agent Runtime's built-in metrics are intentionally operational. They do not replace evaluations. They answer health questions: is the service receiving traffic, how slow are requests, are errors increasing, and is the container resource profile changing?

Start with four dashboard panels:

**Request volume.** Use `aiplatform.googleapis.com/reasoning_engine/request_count`, grouped by `reasoning_engine_id` and `response_code_class`. This catches traffic drops, deploy routing mistakes, and sudden error spikes. Google shows this metric under the Reasoning Engine monitored resource and documents PromQL examples for request count and error-rate ratios.[^monitoring]

**Latency percentiles.** Use the built-in request latency metric. Track p50, p95, and p99 by agent deployment. The SRE mistake is alerting only on average latency. Agent workloads often have a long tail: one slow document parser or retrieval call can make 5% of requests unusable while the average remains acceptable.

**Error rate.** Calculate failed requests over total requests, filtering by `response_code` or response-code class. For the invoice pipeline, treat sustained 5xx errors as infrastructure incidents and sustained 4xx or policy-denial spikes as product or integration incidents. They need different owners.

**Tool-call volume and tool-call errors.** Built-in metrics do not give you every business-specific counter you may want. For tool calls, use structured logs and create a log-based metric. Google's monitoring docs show a `tool_calling_count` example where log entries like `tool-<tool-id> invoked by agent-<agent-id>` become a counter with `tool` and `agent` labels.[^monitoring] In a real invoice system, prefer stable IDs such as `tool=parse_pdf_with_document_ai` and `agent=extractor`.

Do not overload metric labels with unbounded values. Supplier name, invoice ID, customer email, and raw filename do not belong in metric labels. Put those in structured logs with retention and access policy. Metric cardinality problems are quiet until your dashboards slow down and your bill grows.

<RunPromptCell
  model="gemini-3.1-pro-preview"
  prompt="Design a Cloud Monitoring dashboard for a three-agent invoice pipeline deployed on Gemini Enterprise Agent Platform. Agents: orchestrator, extractor, validator. Available built-in metrics include request_count and request_latencies on a ReasoningEngine resource. You may also create log-based metrics from structured logs. Return a markdown table with columns: panel, signal, grouping labels, alert threshold, and why it matters. Include exactly six panels."
  expectedOutput="Expected panels include request volume by agent and response code, p95/p99 latency by agent, error-rate ratio, tool-call count by tool and agent from logs, gateway or policy-denial count if logged, and Online Monitor quality or hallucination score once configured. A good answer avoids invoice IDs or supplier names as metric labels."
/>

---

## Use logs for facts that traces should not carry alone

Logs are not a substitute for traces. They are the durable event stream that lets you answer questions a trace DAG may not answer cleanly:

- Which supplier class was this invoice?
- Which extraction schema version ran?
- Which gateway policy decision applied?
- Which evaluation case was generated from this incident?
- Which retry attempt finally succeeded?

Agent Runtime supports stdout/stderr routing to `reasoning_engine_stdout` and `reasoning_engine_stderr` by default. That is convenient for early development, but structured logs are better once the pipeline has operational value. Python logging and the Cloud Logging client can write JSON payloads with severity, labels, trace correlation fields, and the `aiplatform.googleapis.com/ReasoningEngine` resource.[^logging]

For the invoice pipeline, use one structured log per major business event:

```json
{
  "event": "invoice_extraction_completed",
  "agent": "extractor",
  "trace_id": "TRACE_ID",
  "schema_version": "invoice_v4",
  "supplier_class": "strategic_vendor",
  "document_pages": 12,
  "tool": "parse_pdf_with_document_ai",
  "duration_ms": 2800,
  "retry_count": 0
}
```

Notice what is missing: invoice number, supplier bank account, raw address, and uploaded filename. Those may be needed in a secure audit store, but they do not belong in ordinary operational logs unless your governance policy explicitly allows it.

The strongest pattern is to log identifiers that let authorized responders join to the right system of record, not the sensitive record itself. That keeps observability useful without turning Cloud Logging into an uncontrolled copy of your finance data.

---

## Evaluation is the quality layer

Latency, error rate, and trace topology catch runtime failures. They do not prove the agent gave a correct answer. A fast wrong answer is still wrong.

Agent Platform evaluation gives you the quality layer. Google describes three evaluation types:

- Rapid Evaluation for frequent development checks.
- Test Case Evaluation for scheduled regression testing against a dataset.
- Online Monitoring for continuous production quality tracking.[^eval]

Use all three, but do not blur them.

**Rapid evaluations** are for local iteration. You changed the orchestrator instruction and want to know whether tool-routing improved on ten examples.

**Offline evaluations** are for regression. Google describes offline evaluation as measuring performance, safety, and quality by analyzing historical data, individual traces, or full sessions against predefined or custom metrics.[^offline] For the invoice pipeline, your first offline set should include 30 cases: clean invoices, rotated scans, duplicate invoice numbers, missing purchase orders, unsupported currencies, and supplier-name ambiguity.

**Online Monitors** are for production drift. Google says Online Monitors run on a scheduled loop: sample data from Cloud Trace and Cloud Logging, evaluate with the Gemini Enterprise Agent Platform Evaluation Service, then write results back to Cloud Logging and Cloud Monitoring.[^online] They can track metrics such as response quality, safety, hallucination rates, and tool-use quality in the observability dashboard.[^online]

This is more useful for agents than trying to force all quality concerns through traditional feature drift. The quality question is not only "did the prompt distribution move?" It is "did the agent still complete the task, use the right tools, handle tool outputs correctly, and avoid inventing unsupported facts?" Agent evaluation metrics and failure clusters are designed around those agent behaviors.

<KnowledgeCheck
  question="Your invoice pipeline p95 latency is stable, request count is normal, and 5xx errors are near zero. Customer support still reports that the agent is approving invoices without checking purchase-order matches. Which signal is most likely to catch this class of regression?"
  options={[
    "Cloud Monitoring request_count grouped by response_code",
    "Container CPU allocation time",
    "An Online Monitor or offline evaluation metric for tool-use/task success",
    "Cloud Logging stdout volume"
  ]}
  correctIdx={2}
  explanation="This is a quality and tool-use regression, not primarily an infrastructure failure. Runtime metrics can look healthy while the agent silently skips a required tool. A trace-backed evaluation metric or offline regression case is the right control."
/>

---

## Turn incidents into evaluation cases

The fastest way to build a useful evaluation set is to harvest real failures. Every production incident should leave behind one durable test case.

For the invoice pipeline, use this incident-to-eval template:

| Incident evidence | Evaluation case field |
|---|---|
| Trace ID | Source trace |
| User request category | Scenario |
| Expected tool path | Rubric criterion |
| Actual tool path | Failure evidence |
| Correct final behavior | Expected answer |
| Policy or safety concern | Safety metric |

Example:

```yaml
case_id: invoice-po-match-017
source_trace_id: invoice-run-7f3a9c
scenario: "Invoice has a valid supplier but missing purchase-order match"
expected_tool_path:
  - extractor.parse_pdf_with_document_ai
  - validator.lookup_purchase_order
  - validator.reject_invoice
expected_final_behavior: "Reject invoice and explain missing PO match"
rubric:
  task_success: "Agent rejects the invoice unless the purchase order exists"
  tool_use_quality: "Agent must call validator.lookup_purchase_order before final decision"
  hallucination: "Agent must not invent a purchase-order ID"
```

Once the case exists, run it offline before every prompt or model-routing change. Then create an Online Monitor that samples production traces where the Validator is expected to run. If the monitor starts reporting tool-use failures, you have caught the regression before support tickets pile up.

Google's evaluation-results docs also describe failure clusters and Automatic Loss Analysis. The predefined loss patterns include tool calling, tool output handling, instruction following, and hallucination categories, including cases where an agent claims an action happened without executing the required tool call or invents details not present in user input or tool output.[^clusters] These categories map directly to the failures that matter in an enterprise invoice workflow.

---

## Use failure clusters to choose the next fix

A weak evaluation report says "score dropped from 0.89 to 0.74." A useful evaluation report says "score dropped because the Validator ignores missing PO matches when the supplier is a strategic vendor."

Failure clusters are the bridge. After an evaluation run, Agent Platform can group failures into semantic clusters and loss patterns so you can see systemic causes instead of reading 100 individual bad traces.[^clusters]

Treat each cluster as a product bug, not a model mood. Assign one owner and one fix type:

| Cluster | Likely fix |
|---|---|
| Agent skipped required PO lookup | Orchestrator instruction and tool policy |
| Tool returned malformed JSON | Tool wrapper/schema validation |
| Agent invented supplier ID | Grounding and final-answer rubric |
| Model Armor blocked content unexpectedly | Gateway policy tuning or safer tool output |
| Extractor timed out on long scans | Tool timeout/retry and document preprocessing |

Prompt optimization comes after diagnosis. Google's prompt-optimization docs frame the Quality Flywheel as evaluation, analysis, then optimization.[^optimize] Keep that order. If the failure is a bad tool timeout, prompt optimization is theater. If the failure is instruction-following under ambiguous supplier names, prompt optimization may be exactly right.

<KnowledgeCheck
  question="An evaluation run produces a failure cluster: 'Hallucination of Tool or Capability' for 12 invoice cases. The agent told users it had checked a purchase-order system, but traces show no PO lookup tool call. What is the first fix you should try?"
  options={[
    "Increase Agent Runtime CPU allocation",
    "Add a required tool-use rule and regression case for PO lookup before approval",
    "Lower the Online Monitor sampling percentage",
    "Move all traces to a longer retention bucket"
  ]}
  correctIdx={1}
  explanation="The cluster says the agent claimed a capability/action without executing the tool. The fix is to constrain the behavior and make it testable: require the PO lookup before approval and add regression coverage. CPU, sampling, and retention do not address the behavioral defect."
/>

<KnowledgeCheck
  question="In 2-3 sentences, explain why Cloud Monitoring metrics and Agent Platform evaluation metrics are both required for this chapter's invoice pipeline."
  options={["self-check"]}
  correctIdx={0}
  explanation="Cloud Monitoring metrics show runtime health: request volume, latency, error rates, and resource use. Agent Platform evaluation metrics show task quality: whether the agent followed the right path, used tools correctly, avoided hallucination, and met the rubric. A production agent can be operationally healthy and behaviorally wrong, so both layers are necessary."
/>

---

## Hands-on exercise: instrument, break, evaluate, and fix

Use the secured invoice pipeline from Chapter 5.

1. Enable telemetry for the staging ADK deployment with `GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY=true`, `OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental`, and an explicit decision on prompt/response capture.
2. Confirm traces appear in the Agent Platform Traces tab or Cloud Trace. Run one successful invoice and capture the trace ID.
3. Add structured logs for three events: extraction completed, validation decision made, and gateway policy decision applied. Include `trace_id`, `agent`, `tool`, `schema_version`, and `duration_ms`; exclude raw invoice identifiers and bank details.
4. Build a Cloud Monitoring dashboard with request count, p95/p99 latency, error-rate ratio, and a log-based metric for tool-call count.
5. Inject a failure: configure the Extractor to reference a non-existent document bucket or an invalid Document AI processor ID. Run 10 test invoices.
6. Open the failed trace and identify the failing span in under 60 seconds. Write down the top-level trace ID, failing span, expected downstream span that did not run, and user-visible symptom.
7. Convert the failure into one offline evaluation case. The expected behavior should require a clear user-facing error and no invoice approval.
8. Create an Online Monitor for production-like traffic that samples traces where validation should occur. Track at least one quality or tool-use metric and confirm results appear in the Evaluation dashboard.
9. Review any failure clusters. Choose one fix type: prompt/tool policy, tool wrapper, gateway policy, retry/timeout, or eval rubric.

Success criteria:

- Traces are visible for both successful and failed invoice runs.
- The failing span is identified from the trace DAG, not guessed from the endpoint response.
- The dashboard shows request count, latency, error rate, and tool-call volume.
- At least one offline evaluation case exists from the induced failure.
- An Online Monitor is configured with a sampling cap and a named quality or tool-use metric.
- You can explain whether the next fix belongs in prompt instructions, tool code, gateway policy, or evaluation rubric.

---

## What's next

Chapter 7 uses these signals to make scaling and cost decisions. Once you can see request volume, latency, tool-call count, error rate, and quality drift, you can decide when to use on-demand capacity, provisioned throughput, cheaper model routes, context caching, or stricter runbooks. See [[gemini-enterprise-agents/07-scale-and-cost]].

---

## Further reading

[^trace]: Google Cloud. "Set up tracing." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/tracing - retrieved 2026-05-14.

[^logging]: Google Cloud. "Set up logging." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/logging - retrieved 2026-05-14.

[^monitoring]: Google Cloud. "Set up monitoring." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/monitoring - retrieved 2026-05-14.

[^observability]: Google Cloud. "Observability overview." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/observability/overview - retrieved 2026-05-14.

[^eval]: Google Cloud. "Evaluate your agents." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-agents - retrieved 2026-05-14.

[^offline]: Google Cloud. "Run offline evaluations." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-offline - retrieved 2026-05-14.

[^online]: Google Cloud. "Continuous evaluation with online monitors." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-online - retrieved 2026-05-14.

[^clusters]: Google Cloud. "Analyze evaluation results and failure clusters." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/view-results - retrieved 2026-05-14.

[^optimize]: Google Cloud. "Optimize agent prompts." Gemini Enterprise Agent Platform documentation. https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/optimize-agent - retrieved 2026-05-14.
