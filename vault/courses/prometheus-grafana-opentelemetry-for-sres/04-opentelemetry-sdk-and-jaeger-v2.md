---
chapter_num: 4
course_slug: prometheus-grafana-opentelemetry-for-sres
title: "Instrumenting Services with OpenTelemetry SDKs and Routing Traces through the OTel Collector to Jaeger v2"
status: g3-passed
duration_min: 20
vendor_tag: Prometheus / Grafana / OpenTelemetry
learning_objectives:
  - "Auto-instrument a Node.js or Python service using OTel SDK zero-code instrumentation and the OTEL_SERVICE_NAME resource attribute"
  - "Configure an OTel Collector pipeline with OTLP receiver, tail_sampling processor, batch processor, and Jaeger OTLP exporter"
  - "Write tail-sampling policies that guarantee 100% capture of ERROR traces and traces exceeding a 500 ms latency threshold"
  - "Deploy Jaeger v2 using the single-binary Docker image and understand its OTLP-native ingestion architecture"
  - "Explain the W3C traceparent header format and diagnose context propagation failures across service boundaries"
sources:
  - url: "https://opentelemetry.io/docs/zero-code/js/"
    title: "OpenTelemetry Node.js Zero-Code Instrumentation"
  - url: "https://opentelemetry.io/docs/zero-code/python/"
    title: "OpenTelemetry Python Zero-Code Instrumentation"
  - url: "https://opentelemetry.io/docs/collector/configuration/"
    title: "OpenTelemetry Collector Configuration"
  - url: "https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/tailsamplingprocessor/README.md"
    title: "OTel Collector Tail Sampling Processor README"
  - url: "https://www.jaegertracing.io/docs/2.19/architecture/"
    title: "Jaeger v2 Architecture"
  - url: "https://www.cncf.io/blog/2024/11/12/jaeger-v2-released-opentelemetry-in-the-core/"
    title: "Jaeger v2 Released: OpenTelemetry in the Core | CNCF"
  - url: "https://www.w3.org/TR/trace-context/"
    title: "W3C Trace Context Level 1 Specification"
  - url: "https://opentelemetry.io/blog/2023/jaeger-exporter-collector-migration/"
    title: "Migrating away from the Jaeger exporter in the OTel Collector"
  - url: "https://www.michal-drozd.com/en/blog/otel-tail-sampling/"
    title: "Tail-Based Sampling in OpenTelemetry: Sizing, Memory Crashes and Cost Model"
owns:
  - "OpenTelemetry SDK auto-instrumentation and service.name resource attributes"
  - "OTel Collector pipeline: OTLP receiver, tail_sampling processor, batch processor, Jaeger OTLP exporter"
  - "Tail-based sampling policies: ERROR-status spans and slow-trace threshold (>500 ms)"
  - "Jaeger v2 deployment (cr.jaegertracing.io/jaegertracing/jaeger:2.x) and native OTLP ingestion"
  - "W3C traceparent header format and cross-service context propagation"
  - "OTel Collector debug exporter for span-level diagnostics"
  - "Context propagation failure diagnosis"
defers_to:
  - "Grafana Jaeger data source setup and trace-to-metrics linking → ch5"
  - "SLO burn-rate alert correlation with distributed traces → ch5"
quiz_topics:
  - "Head-based vs. tail-based sampling: when each is appropriate for high-throughput fintech workloads"
  - "Why Jaeger v2 replaced the Jaeger agent with the OTel Collector as its ingestion pipeline"
  - "OTLP gRPC vs. HTTP exporter: latency, payload, and firewall tradeoffs"
  - "How W3C traceparent propagation enables parent-child span correlation across service boundaries"
notebooklm_source_focus:
  - "OpenTelemetry Collector tail sampling processor documentation and policy config"
  - "Jaeger v2 migration guide: removed components, new architecture, OTLP-native ingestion"
  - "OpenTelemetry SDK auto-instrumentation guides (Node.js and Python)"
word_budget: { min: 800, max: 1200 }
last_updated: 2026-06-12
positions: []
faq:
  - question: "Do I need to change my application code to add OpenTelemetry tracing?"
    answer: "No. Zero-code instrumentation lets you add tracing by installing the OTel SDK package and setting environment variables before running your process. The SDK intercepts HTTP, database, and queue calls automatically using framework hooks — no changes to application source files are required."
  - question: "What is the difference between head-based and tail-based sampling?"
    answer: "Head-based sampling decides at trace initiation whether to keep or discard a trace, before any spans are emitted. Tail-based sampling buffers all spans in the OTel Collector for the decision_wait window (default 30 s) and evaluates policies against the complete trace — enabling 100% capture of error traces and latency-breaching traces that head sampling would randomly discard."
  - question: "Why was the jaeger-agent removed in Jaeger v2?"
    answer: "Jaeger v2 is built on the OTel Collector framework and accepts OTLP natively on ports 4317 (gRPC) and 4318 (HTTP). The separate jaeger-agent DaemonSet, which accepted Jaeger Thrift over UDP, is no longer needed because the OTel Collector — or a direct OTLP export from the SDK — handles ingestion with better protocol support and no additional sidecar to manage."
quiz:
  - question: "A fintech platform processes 2,000 payment traces per second, with a 0.3% error rate. Compliance requires capturing 100% of failures. Which sampling strategy satisfies this requirement, and why?"
    options:
      - "Head-based at 10% — stateless and low-overhead, it captures the vast majority of errors without dedicated infrastructure"
      - "Tail-based with status_code: [ERROR] — the Collector evaluates complete trace state and guarantees capture of every error span"
      - "Head-based at 100% — every trace is guaranteed since the SDK never discards a span before emitting it"
      - "Head-based at 0.3% — matching the sampling rate to the error rate keeps storage costs proportional to failure volume"
    correct_idx: 1
    explanation: "Head-based sampling decides at trace initiation, before any spans are emitted, so it cannot know which traces will contain errors. Tail-based sampling buffers the complete trace in the Collector for the decision_wait window (default 30 s), then evaluates policies against final span state. The status_code: [ERROR] policy guarantees 100% capture; head sampling below 100% randomly misses error traces regardless of the chosen rate."
    section_anchor: tail-based-sampling-guaranteeing-error-and-slow-trace-capture

  - question: "Jaeger v2 eliminated the jaeger-agent sidecar DaemonSet. What replaced its role in the ingestion pipeline?"
    options:
      - "A lightweight in-process agent embedded in the SDK that buffers and forwards Jaeger Thrift spans to the collector"
      - "A Kubernetes admission webhook that intercepts span payloads before they leave the pod network boundary"
      - "The OTel Collector, which accepts OTLP spans directly and forwards them to Jaeger's port 4317"
      - "A Kafka consumer sidecar that reads spans from a topic and writes them to jaeger-query"
    correct_idx: 2
    explanation: "Jaeger v2 is built on the OTel Collector framework and accepts OTLP natively on port 4317 (gRPC) and 4318 (HTTP). The jaeger-agent — a host-level DaemonSet that accepted Jaeger Thrift over UDP — no longer exists in v2. The OTel Collector (or a direct OTLP export from the SDK) replaces it. This is documented in the Jaeger v2 Architecture guide and the CNCF v2 release announcement."
    section_anchor: deploying-jaeger-v2-and-its-otlp-native-architecture

  - question: "Your OTel Collector runs inside a Kubernetes cluster and exports traces to Jaeger in the same cluster. Which OTLP transport should you use for the Collector-to-Jaeger leg, and why?"
    options:
      - "OTLP/HTTP on port 4318 — HTTP connections inside Kubernetes are always more reliable than long-lived gRPC streams"
      - "OTLP/gRPC on port 4317 — multiplexed HTTP/2 connections cut per-batch latency, and port 4317 is reachable within-cluster"
      - "OTLP/HTTP on port 4318 — gRPC always requires additional firewall configuration that is unavailable inside a cluster"
      - "OTLP/gRPC on port 4317 — the HTTP transport drops gzip compression support and increases per-record overhead"
    correct_idx: 1
    explanation: "OTLP/gRPC uses persistent multiplexed HTTP/2 connections, reducing per-batch connection establishment overhead compared to OTLP/HTTP. Within a Kubernetes cluster, port 4317 is reachable via a Service resource and is not blocked by typical network policies. OTLP/HTTP is the right fallback when crossing a firewall or API gateway that blocks non-standard ports, or when JSON-encoded spans are needed for debugging."
    section_anchor: the-otel-collector-pipeline-receive-sample-export

  - question: "Service A injects a W3C traceparent header into its HTTP call to Service B. An Nginx proxy between them strips the header before it reaches Service B. What does Jaeger display?"
    options:
      - "Service B's spans appear under Service A's trace tree because the trace-id is also embedded in the URL path"
      - "Service B's spans appear as a disconnected root trace, unrelated to Service A's trace in Jaeger"
      - "The trace is dropped by Service B's OTel SDK and no spans from Service B reach Jaeger at all"
      - "Service B generates a fresh trace-id but reuses the parent-id, so spans sort correctly but show mismatched IDs"
    correct_idx: 1
    explanation: "The OTel SDK extracts trace-id and parent-id exclusively from the traceparent header on the receiving side. If the header is stripped, the SDK receives no propagation context and creates a new root span with a fresh trace-id. Jaeger then shows Service B's call as a separate unrelated trace — the classic context propagation failure symptom. Fix by adding traceparent and tracestate to your proxy's header pass-through allowlist."
    section_anchor: w3c-traceparent-and-cross-service-context-propagation
---

## Auto-Instrumenting Your Services Without Code Changes

The fastest path to traces is zero-code instrumentation: the OTel SDK intercepts your framework's HTTP, database, and queue calls at runtime without any changes to application source files.

For Node.js, install two packages and set three environment variables:

```bash
npm install --save @opentelemetry/api @opentelemetry/auto-instrumentations-node

OTEL_SERVICE_NAME=payment-service \
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:4317 \
OTEL_TRACES_EXPORTER=otlp \
node --require @opentelemetry/auto-instrumentations-node/register app.js
```

For Python, `opentelemetry-bootstrap` scans your installed packages, installs matching instrumentation libraries, and the `opentelemetry-instrument` wrapper monkey-patches them before your first import — no code changes required:

```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install

OTEL_SERVICE_NAME=inventory-service \
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:4317 \
opentelemetry-instrument python app.py
```

`OTEL_SERVICE_NAME` sets the `service.name` resource attribute on every span. Without it, Jaeger labels all traces `unknown_service` and your RED dashboards collapse every service into one unfiltered noise bucket. This is the single most important variable to get right before anything else. See the [Node.js](https://opentelemetry.io/docs/zero-code/js/) and [Python](https://opentelemetry.io/docs/zero-code/python/) zero-code guides for the full list of supported frameworks.

<KnowledgeCheck
  question="What happens in Jaeger if you omit OTEL_SERVICE_NAME from your instrumented process?"
  options={["All traces are dropped by the OTel Collector because service.name is a required field", "All traces appear under the label unknown_service, making per-service trace filtering impossible", "The SDK falls back to the process hostname as the service name automatically", "The OTel Collector rejects spans without service.name and logs a parse error"]}
  correctIdx={1}
  explanation="service.name is a semantic convention attribute, not a hard wire-level requirement — spans without it still reach Jaeger but are labeled unknown_service. This collapses all unlabeled services into a single stream, making per-service trace queries and RED dashboard panels meaningless."
/>

## The OTel Collector Pipeline: Receive, Sample, Export

The OTel Collector sits between your SDKs and Jaeger, running a three-stage pipeline: receivers → processors → exporters. The production configuration for a traces pipeline is:

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 1000
    spike_limit_mib: 200
  tail_sampling:
    decision_wait: 30s
    num_traces: 50000
    policies:
      - name: capture-errors
        type: status_code
        status_code:
          status_codes: [ERROR]
      - name: capture-slow-traces
        type: latency
        latency:
          threshold_ms: 500
  batch:
    send_batch_size: 8192
    timeout: 200ms

exporters:
  debug:
    verbosity: detailed   # remove in production
  otlp/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, tail_sampling, batch]
      exporters: [debug, otlp/jaeger]
```

<Callout type="warning">
**Processor order is load-bearing.** Always sequence: `memory_limiter → tail_sampling → batch`. Putting `batch` before `tail_sampling` scatters spans from the same trace across different batches before the sampler can assemble them, causing the tail sampler to evaluate partial traces and make wrong keep/drop decisions. `memory_limiter` must be first so it creates backpressure before the Collector runs out of memory.
</Callout>

The `otlp/jaeger` exporter name is intentional — the legacy `jaeger` exporter was removed from the [OTel Collector at v0.85.0](https://opentelemetry.io/blog/2023/jaeger-exporter-collector-migration/). Teams porting v1 playbooks who still write `exporters: jaeger:` will see `unknown exporter type: jaeger` at startup. Replace it with an `otlp/jaeger` block pointing at Jaeger's port 4317.

For the SDK-to-Collector transport, prefer OTLP/gRPC (port 4317) when both are in the same cluster: persistent multiplexed HTTP/2 connections reduce per-batch latency compared to OTLP/HTTP. Use OTLP/HTTP (port 4318) when crossing a firewall that blocks non-standard ports, or when you need JSON-encoded spans for debugging with standard HTTP tools.

The `debug` exporter (named `logging` before Collector v0.86.0) prints full span payloads to stdout. Use it to confirm the Collector is receiving spans before Jaeger is even running, then remove it in production.

## Tail-Based Sampling: Guaranteeing Error and Slow-Trace Capture

Head-based sampling makes its decision at trace initiation, before a single span is emitted. At 5% head sampling, 95% of your traces are gone before you know which ones contained errors or breached your latency SLO. For a fintech payment platform with a 0.3% error rate and a compliance requirement to capture every failure, head sampling at any rate below 100% is the wrong tool.

Tail-based sampling defers the decision to the OTel Collector, which buffers incoming spans for the `decision_wait` window (default 30 seconds) and evaluates policies against the complete trace. The two canonical SRE policies are:

- **`status_code: [ERROR]`** — retains any trace where at least one span carries ERROR status, guaranteeing 100% error capture.
- **`latency: threshold_ms: 500`** — retains any trace whose end-to-end duration exceeds 500 ms, capturing every p99 SLO breach with early-onset headroom.

The memory cost is real. According to a [practitioner sizing analysis](https://www.michal-drozd.com/en/blog/otel-tail-sampling/), 1,000 traces/second with a 15-second `decision_wait` and 10 spans per trace at 1 KB each requires roughly 150 MB of span buffer and at least 500 MB total — with 1 GB recommended to include overhead and safety margin. At 5,000 traces/second with the same wait, the buffer alone hits 2.4 GB. At that scale, adding a 5% probabilistic head-sampling pre-filter at the SDK layer reduces what reaches the tail sampler without sacrificing error coverage.

<KnowledgeCheck
  question="A 30-second decision_wait is set on the OTel Collector tail sampler. A microservice chain takes 35 seconds end-to-end. What risk does this create?"
  options={["The Collector rejects the trace at ingestion because it exceeds the decision_wait TTL", "Late-arriving spans miss the verdict window; the sampler evaluates a partial trace and may incorrectly drop it", "The batch processor times out before flushing the trace, causing silent data loss at the exporter", "The trace-id collides with an existing in-memory trace and Jaeger creates a duplicate entry"]}
  correctIdx={1}
  explanation="decision_wait is the window the Collector holds spans before making a keep/drop verdict. If the trace duration exceeds decision_wait, downstream spans arrive after the verdict is already made. The sampler may evaluate an incomplete trace that shows no errors and no latency breach, and drop it — even if the missing spans would have triggered a keep policy. Set decision_wait to at least your longest expected trace duration plus a network jitter buffer."
/>

## Deploying Jaeger v2 and Its OTLP-Native Architecture

[Jaeger v2 was released by the CNCF on November 12, 2024](https://www.cncf.io/blog/2024/11/12/jaeger-v2-released-opentelemetry-in-the-core/). The most visible change: four separate binaries (agent, collector, ingester, query) collapsed into one — `jaegertracing/jaeger:2.x` — configured entirely via a YAML file.

Jaeger v2 is built on the OTel Collector framework, so it uses the same receiver/processor/exporter pipeline model as the standalone Collector. It accepts OTLP natively on port 4317 (gRPC) and 4318 (HTTP) with no translation layer between the wire format and internal storage. The jaeger-agent DaemonSet that teams ran as a sidecar in v1 is eliminated; the OTel Collector (or a direct SDK OTLP export) replaces its role entirely.

```yaml
services:
  jaeger:
    image: jaegertracing/jaeger:2.19.0
    command: ["--config", "/jaeger/config.yaml"]
    volumes:
      - ./jaeger-config.yaml:/jaeger/config.yaml
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "16686:16686" # Jaeger UI
      - "8888:8888"   # Prometheus-compatible metrics
```

A critical migration trap: Jaeger v2 does not accept v1 environment variables like `COLLECTOR_OTLP_ENABLED` or `SPAN_STORAGE_TYPE`. Teams porting Kubernetes manifests that set these env vars will get silent defaults or startup errors. The [Jaeger v2 Deployment docs](https://www.jaegertracing.io/docs/2.19/deployment/) document the YAML equivalents for each former env var.

Connecting these traces to your Prometheus dashboards via Grafana Explore and exemplar click-through is covered in [[05-correlating-metrics-traces-and-alerts]].

## W3C traceparent and Cross-Service Context Propagation

Every OTel SDK injects and extracts the `traceparent` HTTP header on outbound and inbound requests. The [W3C Trace Context specification](https://www.w3.org/TR/trace-context/) defines four fields in that header:

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
             ^^                                                        version (always 00)
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                      trace-id (32 hex = 16 bytes)
                                                ^^^^^^^^^^^^^^^^      parent-id (16 hex = 8 bytes)
                                                                 ^^   trace-flags (01 = sampled)
```

When Service A calls Service B, Service A's SDK injects this header into the outbound HTTP request. Service B's SDK extracts the `trace-id` and `parent-id`, creates a child span under the same `trace-id`, and sets its parent span ID to Service A's span ID. Jaeger then renders both spans in one unified trace tree, letting you trace the full call chain across service boundaries in a single view.

## Diagnosing Context Propagation Failures

The symptom of a broken propagation chain is unmistakable: instead of one trace tree spanning multiple services, Jaeger shows disconnected root spans — Service B appears to have started its own independent trace rather than a child of Service A.

The most common production cause is a proxy or API gateway stripping `traceparent` before it reaches the downstream service. Nginx, Envoy, and some managed API gateways drop headers they do not recognize by default. Fix: explicitly add `traceparent` and `tracestate` to your proxy's header pass-through allowlist. To verify, enable the OTel Collector `debug` exporter on the receiving service and confirm that incoming spans carry a `trace_id` matching the upstream service — if the `trace_id` is fresh on every request, the header is being stripped upstream.

---

## Hands-On Exercise: End-to-End Trace Pipeline

**Goal:** Emit a trace from a Node.js service and verify it appears in Jaeger v2 with the correct service name.

1. Start Jaeger v2 in Docker: `docker run -p 4317:4317 -p 16686:16686 jaegertracing/jaeger:2.19.0`
2. Start the OTel Collector with the full config above, setting `endpoint: localhost:4317` in the `otlp/jaeger` exporter block.
3. Launch your Node.js app with `OTEL_SERVICE_NAME=payment-service` and the `--require @opentelemetry/auto-instrumentations-node/register` flag.
4. Make one HTTP request to the app to trigger a trace.
5. Open `http://localhost:16686`, select `payment-service` from the Service dropdown, and click **Find Traces**.

**Success criteria:**
- At least one trace appears under `payment-service` in the Jaeger UI — not `unknown_service`.
- The trace shows at least one span with an HTTP method and status code.
- The OTel Collector stdout (from the `debug` exporter) shows the span payload before the trace appears in Jaeger, confirming the pipeline is live end-to-end.

Next chapter: [[05-correlating-metrics-traces-and-alerts]] connects these Jaeger traces to your Prometheus RED metrics via exemplars and Grafana Explore, completing the three-pillar observability loop.
