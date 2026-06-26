---
course_slug: prometheus-grafana-opentelemetry-for-sres
title: "Observability Engineering for Microservices: Prometheus 3, Grafana 13 & OpenTelemetry Tracing"
status: g3-passed
publish_state: g4-approved
course_track: career
toc_locked: true
video_overview: true
koenig_recommendation: "Site Reliability Engineering (SRE) Practitioner℠ (https://www.koenig-solutions.com/sre-practitioner-course-training)"
author: course-architect
level: Advanced
vendor_tag: Prometheus / Grafana / OpenTelemetry
target_audience: "Senior candidates targeting Senior Site Reliability Engineer roles with production experience in microservices and Kubernetes-based distributed systems"
prerequisites:
  - "Working knowledge of Kubernetes (deployments, services, namespaces, Helm)"
  - "Familiarity with core metrics concepts (counters, gauges, histograms)"
  - "Experience with at least one observability or monitoring tool (Datadog, CloudWatch, New Relic, or similar)"
  - "Basic comfort with YAML configuration files and terminal-driven workflows"
learning_outcomes:
  - "Deploy and configure Prometheus 3.x with Kubernetes-native service discovery using kube-prometheus-stack and endpointslice roles"
  - "Write production-grade PromQL expressions modeling SLO error budgets, p99 latency percentiles, and multi-window multi-burn-rate alerts"
  - "Build Grafana 13 dashboards with Git Sync-managed versioning, template variables, and Grafana-managed alert rules"
  - "Instrument microservices with the OpenTelemetry SDK and configure an OTel Collector with tail-based sampling routing traces to Jaeger v2"
  - "Execute an end-to-end incident triage workflow correlating Prometheus exemplars, Grafana Explore, and Jaeger traces to pinpoint a degraded downstream call"
total_duration_min: 70
chapter_count: 5
sources: []
---

## Chapter 1 · Deploying Prometheus 3 and Scraping Microservice Metrics at Scale (~14 min)

**Learning Objectives**
- Configure a `prometheus.yml` or PrometheusOperator ServiceMonitor CRD with `kubernetes_sd_configs` using the `endpointslice` role so that at least three microservice targets appear as UP
- Deploy `node-exporter` and `kube-state-metrics` as Helm sub-charts and verify gap-free scraping
- Write and validate a `rate()` recording rule with `promtool check rules` before applying it to the cluster

**Key Concepts**
- kube-prometheus-stack Helm chart architecture and PrometheusOperator ServiceMonitor CRD
- `kubernetes_sd_configs` with `endpointslice` role (default as of chart v29+) vs. legacy `endpoints` role
- PromQL `rate()` function internals: counter reset handling, lookback window selection
- Recording rules: purpose, syntax, validation workflow with `promtool`

**Hands-On Exercise**
Stand up kube-prometheus-stack on Kind or Minikube, wire three microservice endpoints to appear as UP in the Prometheus targets UI, deploy node-exporter and kube-state-metrics, write a `rate()` recording rule for request throughput, and run `promtool check rules` to validate before applying.

---

## Chapter 2 · Writing PromQL Queries and Alertmanager Rules for Payment-Path SLOs (~15 min)

**Learning Objectives**
- Build `histogram_quantile()` expressions computing p99 request latency for a payment service and validate against sample data
- Configure an Alertmanager routing tree with two receiver groups (critical vs. warning), inhibition rules, and a `repeat_interval` that suppresses flapping
- Define a PrometheusRule CRD with a multi-window multi-burn-rate alert for a 99.9% availability SLO and verify it fires with `promtool test rules`

**Key Concepts**
- `histogram_quantile()` with classic fixed buckets vs. Prometheus 3 native histograms: accuracy and cardinality tradeoffs
- Multi-window multi-burn-rate alerting: Google SRE Workbook methodology — 1 h / 5 h / 30 d burn windows
- Alertmanager route tree: `receiver`, `match`, `inhibit_rules`, `group_wait`, `group_interval`, `repeat_interval` semantics
- PrometheusRule CRD structure and `promtool` unit test YAML syntax

**Hands-On Exercise**
Build a payment-service SLO pipeline: write `histogram_quantile()` for p99 latency, configure an Alertmanager routing tree routing to critical and warning receivers with inhibition, define a 99.9% multi-burn-rate PrometheusRule, write a `promtool test rules` unit test file, and diagnose a silenced alert via the Alertmanager `/api/v2/alerts` endpoint.

---

## Chapter 3 · Building Grafana 13 Dashboards Backed by Prometheus with Git Sync and Alerting (~13 min)

**Learning Objectives**
- Provision a Prometheus data source in Grafana 13 via `datasources.yaml` and confirm the health check passes without manual UI steps
- Build a dashboard with four panel types (time series, stat, gauge, table) and template variables for service and environment selectors, then export it as versioned JSON
- Enable Git Sync, merge a dashboard change via PR, and configure a Grafana-managed alert rule that transitions from Pending to Firing

**Key Concepts**
- Grafana 13 provisioning: `datasources.yaml`, `dashboards.yaml`, idempotency guarantees
- Dashboard JSON model: panel type properties, template variable scoping, repeat panels
- Grafana 13 GA Git Sync: branch workflow, webhook triggers, merge conflict resolution
- Grafana alerting architecture: unified alerting, rule groups, contact points, `Pending → Firing` state machine

**Hands-On Exercise**
Provision a Grafana 13 instance with a Prometheus data source via YAML, build a four-panel service dashboard with environment and service template variables, commit it via Git Sync through a pull request, and configure a multi-condition threshold Grafana alert rule with a Slack contact point and verify the Pending → Firing transition.

---

## Chapter 4 · Instrumenting Services with OpenTelemetry SDKs and Routing Traces through the OTel Collector to Jaeger v2 (~15 min)

**Learning Objectives**
- Add OpenTelemetry SDK auto-instrumentation to a sample service and confirm spans with correct `service.name` resource attributes appear in OTel Collector logs
- Configure an `otel-collector-config.yaml` with an OTLP receiver, a `tail_sampling` processor (always-sample ERROR spans and traces > 500 ms), a `batch` processor, and a Jaeger OTLP exporter
- Deploy Jaeger v2 and verify the Jaeger UI shows end-to-end traces with parent-child relationships across two services; diagnose a broken context propagation issue via the debug exporter

**Key Concepts**
- OpenTelemetry SDK auto-instrumentation vs. manual: tradeoffs and language-specific approaches
- OTel Collector architecture: receivers, processors, exporters, service pipelines
- Tail-based sampling: decision delay, policy types (status_code, latency), memory_limiter interaction
- Jaeger v2: removed Jaeger agent, native OTLP ingestion via OTel Collector, port mapping changes (4317/4318)
- W3C `traceparent` header: trace-id, span-id, trace-flags format and propagation failure modes

**Hands-On Exercise**
Auto-instrument a Node.js or Python sample service, configure a local OTel Collector with tail sampling (always sample ERROR spans and spans > 500 ms), deploy Jaeger v2, and verify parent-child trace spans across a frontend → payment-service boundary in the Jaeger UI. Inject a deliberate W3C `traceparent` header omission and diagnose the broken propagation using the Collector debug exporter.

---

## Chapter 5 · Correlating Metrics, Traces, and Alerts to Diagnose a Degraded Payment Microservice (~13 min)

**Learning Objectives**
- Configure Prometheus exemplar scraping and the Grafana Jaeger data source, then build a trace-to-metrics link so clicking a histogram exemplar in Explore opens the correlated Jaeger trace
- Use Grafana Explore to correlate a p99 latency spike to a specific Jaeger trace ID and identify the slow span and its attributes
- Write and apply a multi-burn-rate PrometheusRule that fires when the 1-hour error rate exceeds 14× budget consumption, with a `runbook_url` annotation; evaluate a tail-sampling threshold change in a written decision record

**Key Concepts**
- Prometheus exemplars: OpenMetrics spec, enabling in Prometheus 3, application-SDK emission
- Grafana Explore: split view, trace-to-metrics link configuration, exemplar click-through flow
- On-call incident triage workflow: alert fires → metric Explore → exemplar → Jaeger trace → slow span
- Decision record format: context, options, tradeoff quantification, outcome

**Hands-On Exercise**
Configure exemplar scraping in Prometheus and the Jaeger data source in Grafana, then work through a simulated payment degradation scenario: identify a p99 latency spike in Grafana Explore, click a histogram exemplar to open the correlated Jaeger trace, locate the slow downstream span and its attributes, trigger the multi-burn-rate SLO alert, and write a ≤200-word decision record evaluating a sampling threshold increase from 500 ms to 1000 ms.

---

## Capstone

Chapter 5 is the capstone. Learners execute a full synthetic on-call incident from alert fire to root-cause identification using the complete three-pillar observability stack assembled across chapters 1–4. The decision record exercise forces structured written reasoning about sampling tradeoffs — the artifact a senior SRE presents in a post-incident review at a fintech engineering org.
