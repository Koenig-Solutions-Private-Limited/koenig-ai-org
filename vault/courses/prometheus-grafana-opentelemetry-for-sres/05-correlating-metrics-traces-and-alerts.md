---
chapter_num: 5
course_slug: prometheus-grafana-opentelemetry-for-sres
title: "Correlating Metrics, Traces, and Alerts to Diagnose a Degraded Payment Microservice"
status: g0-passed
duration_min: 30
vendor_tag: "Grafana / Prometheus / OpenTelemetry"
learning_objectives:
  - "Enable Prometheus exemplar storage and configure OpenMetrics scraping to embed trace_id labels in metric samples"
  - "Configure the Grafana Jaeger data source with tracesToMetrics linking for bidirectional metric-to-trace navigation"
  - "Execute the on-call incident triage workflow: SLO alert → exemplar click-through → Jaeger trace → slow span"
  - "Write a multi-burn-rate PrometheusRule with a runbook_url annotation applied to a live payment-service incident"
  - "Analyze tail-sampling latency threshold tradeoffs and produce a written decision record"
  - "Describe how metrics, traces, and alerts compose into a complete three-pillar observability workflow"
sources:
  - url: "https://prometheus.io/docs/prometheus/latest/feature_flags/"
    title: "Feature Flags | Prometheus"
  - url: "https://prometheus.io/docs/specs/om/open_metrics_spec/"
    title: "OpenMetrics 1.0 Specification | Prometheus"
  - url: "https://grafana.com/docs/grafana/latest/fundamentals/exemplars/"
    title: "Introduction to Exemplars | Grafana Documentation"
  - url: "https://grafana.com/docs/grafana/latest/datasources/jaeger/configure/"
    title: "Configure the Jaeger Data Source | Grafana Documentation"
  - url: "https://sre.google/workbook/alerting-on-slos/"
    title: "Alerting on SLOs | Google SRE Workbook"
  - url: "https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/tailsamplingprocessor/README.md"
    title: "Tail Sampling Processor | opentelemetry-collector-contrib"
  - url: "https://grafana.com/observability-survey/2025/"
    title: "Observability Survey Report 2025 | Grafana Labs"
owns:
  - "Prometheus exemplar scraping configuration and OpenMetrics spec"
  - "Grafana Explore trace-to-metrics link: exemplar click-through to Jaeger"
  - "Grafana Jaeger data source setup (builds on ch4 Jaeger v2 deployment)"
  - "On-call incident triage workflow: metric spike → correlated trace → slow span identification"
  - "Multi-burn-rate SLO alert with runbook URL annotation (applying ch2 methodology to a live incident)"
  - "Tail-sampling threshold tradeoff analysis and written decision record"
  - "End-to-end three-pillar observability synthesis"
defers_to:
  - "Initial Prometheus deployment, scrape config, recording rules → ch1"
  - "Alertmanager routing trees and PrometheusRule CRD creation from scratch → ch2"
  - "Grafana dashboard panel construction and Git Sync → ch3"
  - "OTel Collector pipeline configuration and Jaeger v2 deployment from scratch → ch4"
quiz_topics:
  - "What are exemplars and why are they needed to bridge Prometheus metrics with distributed traces"
  - "Multi-burn-rate alert: 14× consumption over 1 hour vs. 1× over 30 days — what failure modes each catches"
  - "Tradeoff: raising tail-sampling slow-trace threshold from 500 ms to 1000 ms — volume reduction vs. coverage loss"
  - "Grafana Explore split view: correlating logs, traces, and metrics simultaneously"
notebooklm_source_focus:
  - "Prometheus exemplar documentation (OpenMetrics spec, Prometheus 3.x exemplar scraping config)"
  - "Grafana Explore trace-to-metrics and exemplar documentation"
  - "Google SRE multi-burn-rate alerting: 1h/5h/30d windows methodology"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "What is an exemplar in the Prometheus/OpenMetrics context, and why is it required to connect a metric spike to a distributed trace?"
    options:
      - "An exemplar is a trace_id label embedded inline in a Counter or Histogram bucket sample, creating a direct pointer from a specific metric data point to the request trace that produced that measurement"
      - "An exemplar is a push-based forwarding mechanism that streams high-latency request data from Prometheus into the OTel Collector, where each forwarded entry is tagged with the corresponding Jaeger span ID"
      - "An exemplar is a sampling policy rule inside the OTel Collector that marks representative histogram bucket values as must-keep traces, reducing the volume forwarded to Jaeger storage without losing statistical coverage"
      - "An exemplar is a Grafana annotation layer requiring the SRE to manually paste a trace ID from Jaeger onto a time-series panel, providing a visual marker that links the graph spike to an external trace"
    correct_idx: 0
    explanation: "OpenMetrics 1.0 defines an exemplar as a label set (minimally trace_id) plus a numeric value, appended to Counter and Histogram samples. It is the only mechanism that ties a specific metric observation to the trace of the individual request that drove it."
    section_anchor: what-are-exemplars-and-why-they-bridge-the-gap
  - question: "A payment service runs under a 99.9% SLO on a 30-day window. The multi-burn-rate rule pages at 14.4× burn rate over 1 hour and tickets at 1× burn rate over 3 days. Which failure mode does each tier target?"
    options:
      - "14.4× / 1h catches complete or near-complete outages that exhaust the error budget in roughly two days; 1× / 3d catches persistent low-level error creep that would silently drain the budget without causing acute customer impact"
      - "14.4× / 1h catches gradual latency degradations that accumulate across multiple deployment cycles; 1× / 3d catches sudden catastrophic spikes that produce immediate page-worthy impact within the first few minutes of an incident"
      - "14.4× / 1h fires only after the short 5-minute confirmation window falls below the threshold to suppress noise; 1× / 3d requires a matching 6-hour window to stay below threshold before the rule escalates to a page"
      - "Both tiers target the same failure mode — elevated error rates — but 14.4× uses a tighter time window to reduce alert lag while 1× uses a wider window to ensure lower-severity incidents are not missed by on-call"
    correct_idx: 0
    explanation: "The 14.4× / 1h tier detects fast-moving outages: at 14.4× burn, the full 30-day budget is exhausted in about 50 hours, causing severe immediate impact. The 1× / 3d tier catches slow bleed — a barely elevated error rate that would exhaust the budget over the full SLO window with no single moment of high impact."
    section_anchor: multi-burn-rate-alert-with-runbook-annotation
  - question: "For payment-svc (p50=120 ms, p90=380 ms, p99=4,200 ms during incident), what is the primary coverage risk of raising the tail-sampling threshold from 500 ms to 1000 ms?"
    options:
      - "Traces in the 500–999 ms zone are dropped, eliminating evidence of gradual degradations that plateau before reaching 1 s — the early-onset signal window that precedes SLO alert firing and exemplar generation"
      - "The OTel Collector runs out of memory because all spans below 1 s are buffered indefinitely in the tail sampler's decision_wait queue without ever being evaluated against any latency sampling policy"
      - "Prometheus exemplars stop being generated because exemplars are only attached to trace spans that exceed the active sampling threshold, creating time-series gaps at every metric point below the new 1 s boundary"
      - "The 35% volume reduction causes the remaining sampled traces to be stored at a higher per-trace fidelity cost, inflating Jaeger storage spend beyond the savings expected from raising the latency threshold"
    correct_idx: 0
    explanation: "During the v2.3.1 incident, traces in the 600–900 ms range appeared during the degradation ramp-up before the 4,200 ms peak. A 1,000 ms threshold would have dropped all of them, leaving no sampled evidence of the early-onset degradation and no exemplars for Grafana to display during the most diagnostically useful window."
    section_anchor: tail-sampling-threshold-tradeoff
  - question: "What is the prerequisite for Grafana Explore's exemplar click-through to open a Jaeger trace in a split pane rather than showing only the trace_id label in a tooltip?"
    options:
      - "The Prometheus data source must have an Exemplar configuration block that explicitly references the Jaeger data source UID; without this linkage, Grafana shows the traceID label but no 'Query with Jaeger' button appears"
      - "The Grafana Loki data source must be configured with a trace-to-logs link, because Explore opens the split pane only after first correlating the metric timestamp to a matching log line containing the trace ID"
      - "The OTel Collector must publish a unified telemetry index via Prometheus remote write so that Grafana Explore can join metrics, logs, and traces into a single correlated split-pane view without a separate data source link"
      - "The Prometheus recording rule must pre-join histogram bucket data with span attributes at evaluation time so that the resulting metric already carries the span reference Grafana needs to resolve the trace view"
    correct_idx: 0
    explanation: "Grafana's Exemplar feature renders the ◆ star and the trace tooltip regardless of data source linking. However, the 'Query with Jaeger' button — and the split-pane trace view — only appear when the Prometheus data source's Exemplar section points to a configured Jaeger data source UID."
    section_anchor: incident-triage-from-alert-to-root-cause-in-minutes
---

## What Are Exemplars and Why They Bridge the Gap

Metrics tell you *something* is wrong. Traces tell you *why*. The missing link is the exemplar — a `trace_id` embedded directly inside a Counter or Histogram bucket sample. When your p99 latency time series spikes at 14:12, the exemplar stored alongside that data point carries the exact trace ID of a representative slow request. One click in Grafana Explore jumps from the spike to the full distributed trace without any manual log-grepping or time-range searching in Jaeger.

The [OpenMetrics 1.0 Specification](https://prometheus.io/docs/specs/om/open_metrics_spec/) defines an exemplar as a label set (at minimum `trace_id`) plus a numeric value, appended inline to Counter and Histogram bucket samples. Gauges and summaries cannot carry exemplars. The spec enforces a hard 128-character limit on the combined label set — a 32-hex trace ID plus a 16-hex span ID plus both label names sums to roughly 58 characters, comfortably within the limit.

<KnowledgeCheck question="Which OpenMetrics 1.0 metric types can carry exemplars?" options={["Counter and Histogram only", "Counter, Histogram, and Gauge", "All PromQL-queryable types", "Only native histograms in Prometheus 3"]} correctIdx={0} explanation="OpenMetrics 1.0 permits exemplars on Counter, Histogram, and GaugeHistogram only. Gauges and summaries are explicitly excluded from the spec." />

## Enabling Exemplar Scraping in Prometheus

Prometheus ships with exemplar storage disabled. Enable it with the `--enable-feature=exemplar-storage` startup flag, then configure the circular buffer capacity in `prometheus.yml`:

```yaml
storage:
  exemplars:
    max_exemplars: 100000   # ~10 MB at 100 bytes/exemplar

scrape_configs:
  - job_name: "payment-svc"
    scrape_protocols:
      - OpenMetricsText1.0.0
      - OpenMetricsText0.0.1
      - PrometheusText1.0.0
    static_configs:
      - targets: ["payment-svc:8080"]
```

The `scrape_protocols` list is not optional detail. Without it, Prometheus negotiates the legacy text format and silently discards every exemplar at scrape time — no error, no warning, just missing data when you need it most. Verify exemplars are actually arriving before an incident forces you to find out they weren't:

```bash
curl -g 'http://localhost:9090/api/v1/query_exemplars?query=http_request_duration_seconds_bucket&start=<start>&end=<end>'
```

An empty `data` array means the wrong content-type was negotiated. Check the raw `Content-Type` response header on the service's `/metrics` endpoint.

<Callout type="warning">
The `--enable-feature=exemplar-storage` flag and the `scrape_protocols` block are both required. Either one alone is insufficient. Miss the protocols list and the flag is inert: Prometheus stores nothing.
</Callout>

## Connecting Grafana to Jaeger

With Jaeger v2 already deployed (chapter 4), add the Jaeger data source via a provisioning YAML so the configuration is version-controlled and idempotent:

```yaml
# grafana/provisioning/datasources/jaeger.yaml
apiVersion: 1
datasources:
  - name: Jaeger
    type: jaeger
    url: http://jaeger-query:16686
    access: proxy
    jsonData:
      tracesToMetrics:
        datasourceUid: prometheus-uid    # must match your Prometheus DS uid
        spanStartTimeShift: "-1m"
        spanEndTimeShift: "1m"
        tags:
          - key: "service.name"
            value: "service"
        queries:
          - name: "Request rate"
            query: "rate(http_requests_total{service=\"$__tags.service\"}[5m])"
```

The `tracesToMetrics` block enables bidirectional navigation: from a Jaeger span back to the Prometheus panel for the same service. The inverse direction — metric to trace — requires the Prometheus data source to also reference the Jaeger UID in an `Exemplar` section. Missing either linkage silently breaks one direction of the workflow.

## Incident Triage: From Alert to Root Cause in Minutes

The payment degradation scenario ties all three pillars together. At 14:12 IST, `payment-svc v2.3.1` deployed with a missing index on `account_id`. The p99 latency climbed from 145 ms to 4,200 ms within minutes. `PaymentSvcFastBurn` fired when both the 1-hour and 5-minute burn-rate windows simultaneously exceeded 14.4×.

The on-call SRE opened Grafana Explore and queried `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{job="payment-svc"}[5m]))`. An exemplar ◆ star was overlaid on the p99 spike at 14:12. Hovering revealed `trace_id="a3f8b1c92d45e670f9812345abcd6789"`. One click opened the full 6-span Jaeger trace in a split pane: the `db-query` child span — `payment-svc → postgres-primary` — accounted for 3,847 ms of the 4,187 ms root span. The `db.statement` attribute exposed an unindexed full-table scan on `account_id`.

From alert fire to root cause: 4 minutes — versus the 15–30 minutes a manual Jaeger search typically requires.

<KnowledgeCheck question="An on-call SRE clicks the exemplar ◆ in Grafana Explore but sees only a tooltip with the traceID label and no 'Query with Jaeger' button. What is the most likely cause?" options={["The Prometheus data source is missing an Exemplar configuration block pointing to the Jaeger data source UID", "Exemplar storage was not enabled with the --enable-feature flag when Prometheus was started", "The trace ID in the exemplar exceeds the 128-character OpenMetrics label length limit", "Jaeger v2 removed the Grafana query API endpoint present in Jaeger v1"]} correctIdx={0} explanation="Grafana renders the ◆ star and the tooltip regardless of data source linking. The 'Query with Jaeger' button only appears when the Prometheus data source's Exemplar section explicitly references the Jaeger data source UID." />

## Multi-Burn-Rate Alert with Runbook Annotation

The `PaymentSvcFastBurn` rule applies the [Google SRE Workbook multi-burn-rate methodology](https://sre.google/workbook/alerting-on-slos/) — built on the ch2 alerting foundation — to this live incident:

```yaml
- alert: PaymentSvcFastBurn
  expr: |
    (
      job:payment_errors_per_request:ratio_rate1h > (14.4 * 0.001)
    and
      job:payment_errors_per_request:ratio_rate5m > (14.4 * 0.001)
    )
  labels:
    severity: page
  annotations:
    summary: "Payment SVC fast error budget burn (14.4x over 1h)"
    runbook_url: "https://runbooks.internal/payment-svc/high-error-rate"
```

The `and` between long and short windows is load-bearing logic. A single-window rule at 14.4× would page on any 1-minute transient spike that has already resolved. Requiring both windows simultaneously confirms the elevated burn rate is *still ongoing* at evaluation time, not historical. The `runbook_url` annotation is surfaced by Alertmanager in the notification payload — the on-call engineer can open the playbook before reaching the Grafana dashboard.

The three tiers serve distinct failure modes: 14.4× / 1h catches complete outages; 6× / 6h catches partial degradations; 1× / 3d tickets low-level error creep that would drain the budget invisibly across deployment cycles.

## Tail-Sampling Threshold Tradeoff

Chapter 4 established a 500 ms `threshold_ms` for the tail-sampling latency policy. A seemingly attractive optimization is to raise it to 1,000 ms to reduce trace storage costs. Here is the analysis.

With `payment-svc` generating ~8,000 spans per minute (p50=120 ms, p90=380 ms), a 500 ms threshold retains roughly 12% of traces — about 960 per minute. Raising to 1,000 ms would reduce retained volume by an estimated 35%, saving roughly 1.8 GB per month.

The tradeoff is coverage loss in the 500–999 ms zone. During the v2.3.1 incident, the degradation ramp-up from 14:12 to 14:15 produced traces in the 600–900 ms range before the 4,200 ms peak appeared. At a 1,000 ms threshold, those early-onset traces would have been dropped — and with them, the exemplars that would have guided the investigation.

**Decision record (retain 500 ms):** The 35% storage saving (~1.8 GB/month) does not justify losing the 500–999 ms evidence window, which is precisely where gradual degradations appear before an SLO alert fires. Document this decision inline in the `tail_sampling` config as a comment referencing the incident date and this analysis.

## Three-Pillar Observability Synthesis

Metrics, traces, and alerts each solve part of the incident workflow: metrics give continuously evaluated aggregate signals for SLO evaluation, traces give surgical root-cause evidence, and alerts make the system proactive. Exemplars bridge all three — a `trace_id` embedded in a Counter or Histogram sample links the metric spike to the exact causative request, converting a reactive page into a directed investigation.

## Hands-On Exercise

**Objective:** Reproduce the full exemplar click-through workflow against a local `payment-svc` simulation and produce a written tail-sampling decision record.

**Steps:**

1. Start Prometheus with `--enable-feature=exemplar-storage` and the `scrape_protocols` block targeting a local service exposing OpenMetrics exemplars on `/metrics`.
2. Verify exemplar ingestion: run the `query_exemplars` curl command and confirm `data` is non-empty with `trace_id` labels present.
3. Configure the Jaeger data source in Grafana using the provisioning YAML above, with `tracesToMetrics` pointing to your Prometheus data source UID.
4. In Grafana Explore, query `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{job="payment-svc"}[5m]))` during a simulated latency spike. Confirm a ◆ marker appears on the graph.
5. Click the ◆ exemplar and verify the "Query with Jaeger" button appears and opens the trace in a split pane.
6. Write a ≤200-word decision record justifying whether to set `threshold_ms` to 500 ms or 1,000 ms for your service's observed latency distribution. Address both the storage saving and the coverage tradeoff explicitly.

**Success criteria:** The exemplar ◆ is visible in Explore, clicking it opens a Jaeger trace in split-pane view, and your decision record names a specific latency zone that would be lost at the higher threshold.
