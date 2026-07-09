---
term: "Telemetry"
definition: "Telemetry is the automated collection and transmission of data from remote sources (like agents or distributed tools) to an IT system for monitoring, analysis, and alerting."
seo_description: "Telemetry explained: data collection for AI systems."
category: "observability"
related_terms: [observability, structured-logging, agent-heartbeat]
related_courses: [gemini-enterprise-agents]
---

Telemetry is the raw material of [[observability]]. It encompasses three distinct pillars, each answering a different operational question: **metrics** answer "how is the system performing over time?", **traces** answer "what path did this specific request take?", and **logs** answer "what happened at this exact moment?" Treating all three as interchangeable — or worse, substituting verbose logging for the other two — is the most common observability mistake in agent deployments.

**Agent-specific metrics.** Standard application metrics (request rate, error rate, p99 latency) are necessary but insufficient for agents. Critical agent-specific signals include: token usage per task (directly maps to cost), cost per completed task (the economics unit), [[tool-use]] call latency broken down by tool name, task completion rate vs. abandonment rate, and retry count per task (a leading indicator of instability). These metrics feed dashboards and, more importantly, cost circuit breakers that can halt a runaway [[agent-loop]] before it exhausts the [[agent-budget]].

**Distributed tracing.** An agent task is not a single request — it is a tree of model calls, tool invocations, and sub-agent dispatches, potentially spanning multiple services over minutes or hours. Distributed tracing assigns a `trace_id` to the root task and a unique `span_id` to each child operation. Every system that participates in the task — the model API, the [[mcp]] tool server, the vector database, the [[structured-logging]] pipeline — emits spans tagged with these IDs. The result is a complete causal graph of what happened and when.

**OpenTelemetry as the open standard.** OpenTelemetry (OTel) is the vendor-neutral SDK and wire protocol for all three pillars. Instrumenting an agent with OTel allows telemetry to be routed to any backend — Langfuse, Honeycomb, Grafana, Datadog — without changing application code. Prefer OTel instrumentation over provider-specific SDKs to avoid lock-in.

**Privacy tension.** Telemetry that captures span attributes can inadvertently include prompt snippets, retrieved document excerpts, or user-identifiable data in trace metadata. Establish explicit attribute allowlists that define which fields may be exported to the telemetry backend. PII in traces is both a [[confidentiality]] risk and a compliance liability.

**Common misconception.** Telemetry is not just logs. Logs are unstructured or semi-structured event records; traces are causally linked spans with timing; metrics are aggregated numeric time series. Each has different storage, query, and alerting characteristics. A production agent system needs all three.

See [[gemini-enterprise-agents]] for a worked example of wiring OTel telemetry into an enterprise agent deployment alongside [[agent-heartbeat]] monitoring and cost alerting.

## Related Terms

- [[glossary/observability|Observability]] — the practice of capturing traces, logs, and metrics to understand agent runtime behaviour
- [[glossary/structured-logging|Structured Logging]] — machine-parseable log output with consistent fields for reliable querying and alerting
- [[glossary/agent-heartbeat|Agent Heartbeat]] — the periodic liveness signal agents emit to detect stuck or crashed runs
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
