---
chapter_num: 1
course_slug: prometheus-grafana-opentelemetry-for-sres
title: "Deploying Prometheus 3 and Scraping Microservice Metrics at Scale"
status: g3-passed
duration_min: 25
vendor_tag: Prometheus / Kubernetes
learning_objectives:
  - "Deploy kube-prometheus-stack via Helm and configure EndpointSlice service discovery"
  - "Distinguish kube-state-metrics from node-exporter and know what each exposes"
  - "Write correct rate() queries and understand counter reset behavior"
  - "Author recording rules and validate them with promtool check rules"
  - "Verify scrape health using the Prometheus Targets UI and the up metric"
sources:
  - url: "https://prometheus.io/blog/2024/11/14/prometheus-3-0/"
    title: "Announcing Prometheus 3.0"
  - url: "https://github.com/prometheus-operator/prometheus-operator/pull/6672"
    title: "Add ServiceDiscoveryRole configuration (EndpointSlice vs Endpoints) – PR #6672"
  - url: "https://prometheus.io/docs/prometheus/latest/querying/functions/"
    title: "Prometheus Query Functions (rate, irate, delta)"
  - url: "https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/"
    title: "Prometheus Defining Recording Rules"
  - url: "https://prometheus.io/docs/practices/rules/"
    title: "Prometheus Recording Rules Best Practices"
  - url: "https://prometheus.io/docs/prometheus/latest/command-line/promtool/"
    title: "Prometheus promtool CLI Reference"
  - url: "https://prometheus.io/docs/concepts/jobs_instances/"
    title: "Prometheus Jobs and Instances – up metric, scrape health"
  - url: "https://github.com/kubernetes/kube-state-metrics"
    title: "kube-state-metrics – Kubernetes object state metrics"
  - url: "https://github.com/prometheus/node_exporter"
    title: "Prometheus node_exporter – hardware and OS metrics"
owns:
  - "kube-prometheus-stack Helm chart deployment and configuration"
  - "Kubernetes service discovery with kubernetes_sd_configs endpointslice role"
  - "node-exporter and kube-state-metrics Helm sub-chart setup"
  - "PromQL rate() fundamentals and counter reset handling"
  - "Recording rule syntax and promtool check rules validation"
  - "Prometheus targets UI scrape health verification"
defers_to:
  - "histogram_quantile() for SLO latency percentiles → ch2"
  - "Alertmanager routing trees and PrometheusRule CRD alert configuration → ch2"
  - "Grafana dashboard construction and data source provisioning → ch3"
  - "OpenTelemetry SDK instrumentation and OTel Collector pipelines → ch4"
  - "Trace-to-metrics correlation and incident triage synthesis → ch5"
quiz_topics:
  - "kubernetes_sd_configs endpointslice role vs. legacy endpoints role: why the default changed in chart v29+"
  - "Difference between recording rules and alerting rules in promtool"
  - "How rate() handles counter resets vs. increase()"
  - "Purpose of kube-state-metrics vs. node-exporter: what each exposes"
notebooklm_source_focus:
  - "Prometheus 3.x release notes and kube-prometheus-stack v29+ changelog"
  - "Kubernetes service discovery endpointslice role documentation"
  - "PromQL rate() function reference, recording rules specification, and promtool docs"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "In kube-prometheus-stack, what is the default kubernetes_sd_configs role when serviceDiscoveryRole is not set in the Prometheus CRD?"
    options:
      - "endpointslice, because the operator defaults to the newer GA API for better scaling performance"
      - "endpoints (legacy), because the operator defaults to the v1/Endpoints API unless explicitly overridden"
      - "pod, because individual pod IP scraping is the most granular discovery approach available"
      - "service, because a ClusterIP endpoint provides a single stable scrape target per service"
    correct_idx: 1
    explanation: "When serviceDiscoveryRole is not set, prometheus-operator ≥ v0.76.0 silently defaults to the legacy 'endpoints' role (v1/Endpoints API). To get EndpointSlice discovery, you must explicitly set serviceDiscoveryRole: EndpointSlice in values.yaml or the Prometheus CRD spec."
    section_anchor: kubernetes-service-discovery-endpointslice-vs-endpoints
  - question: "Which keyword distinguishes a recording rule from an alerting rule in a Prometheus rules YAML file?"
    options:
      - "A recording rule uses the record: key; an alerting rule uses the alert: key"
      - "A recording rule uses the store: key; an alerting rule uses the notify: key"
      - "A recording rule uses the metric: key; an alerting rule uses the threshold: key"
      - "A recording rule uses the aggregate: key; an alerting rule uses the fire: key"
    correct_idx: 0
    explanation: "Recording rules use 'record:' to define the output metric name and 'expr:' for the PromQL expression. Alerting rules use 'alert:' for the alert name, 'expr:' for the firing condition, 'for:' for the pending duration, and optionally 'annotations:'. Both are validated by 'promtool check rules'."
    section_anchor: recording-rules-and-promtool-validation
  - question: "An SRE wants to display 'total HTTP requests in the last 5 minutes' on a Grafana panel. Which PromQL function is most readable for this purpose?"
    options:
      - "rate(), because it produces a per-second value that is independent of the window duration"
      - "increase(), because it returns a total count over the window and reads naturally in a dashboard"
      - "irate(), because it uses only the last two samples for a precise instantaneous count"
      - "delta(), because it measures the absolute change in the counter value over the window"
    correct_idx: 1
    explanation: "increase(metric[5m]) equals rate(metric[5m]) * 300 and returns the total estimated count over the 5-minute window. Both functions handle counter resets identically. For dashboard readability, increase() is preferred; for alerting, rate() is preferred because its output is time-window agnostic."
    section_anchor: promql-rate-and-counter-reset-handling
  - question: "An alert fires because node_memory_MemAvailable_bytes is critically low on a Kubernetes worker node. Which kube-prometheus-stack component exposes this metric?"
    options:
      - "kube-state-metrics, which reads Kubernetes object state from the API server and exposes kube_-prefixed metrics"
      - "node-exporter, which runs as a DaemonSet and reads OS metrics from /proc and /sys on each host"
      - "kube-state-metrics, which runs as a single Deployment and exposes per-pod resource usage metrics"
      - "the Kubernetes API server, which aggregates node resource metrics from the kubelet on each node"
    correct_idx: 1
    explanation: "node-exporter is a DaemonSet (one pod per node) that reads hardware and OS metrics from /proc and /sys, exposing them with the node_ prefix. kube-state-metrics is a single Deployment that exposes Kubernetes object state (kube_* metrics) and has no knowledge of node-level OS metrics."
    section_anchor: node-exporter-and-kube-state-metrics
---

## Installing kube-prometheus-stack

[Prometheus 3.0.0, released November 14, 2024](https://prometheus.io/blog/2024/11/14/prometheus-3-0/), is the first major version in seven years. For Kubernetes deployments, `kube-prometheus-stack` (currently v86.2.2) is the de facto standard — a single Helm chart that installs Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter together as a cohesive, operator-managed unit.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kps prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set prometheus.prometheusSpec.serviceDiscoveryRole=EndpointSlice \
  --set prometheus.prometheusSpec.scrapeInterval=30s \
  --set prometheus.prometheusSpec.evaluationInterval=30s
```

The `serviceDiscoveryRole=EndpointSlice` flag is critical. Without it, prometheus-operator defaults to the legacy `endpoints` role even on modern clusters — covered in the next section.

## Kubernetes Service Discovery: endpointslice vs. endpoints

Prometheus discovers scrape targets through `kubernetes_sd_configs`. The `role` value controls which Kubernetes API it queries to enumerate targets.

The **endpoints** role uses the classic `v1/Endpoints` API — one object per Service, growing unbounded as pods scale. The **endpointslice** role uses `discovery.k8s.io/v1` (GA since Kubernetes 1.21), which shards a Service's endpoints into slices of up to 100 each. Smaller watch events mean lower memory pressure in Prometheus and the API server as you scale past dozens of services.

[prometheus-operator v0.76.0](https://github.com/prometheus-operator/prometheus-operator/pull/6672) (merged July 25, 2024) introduced the `serviceDiscoveryRole` field on the `Prometheus` CRD. When unset, it silently defaults to `"Endpoints"`. For any cluster running Kubernetes 1.21 or later, set it explicitly to `EndpointSlice`. Prometheus 3.0 also removed support for the deprecated `discovery.k8s.io/v1beta1` EndpointSlice API — clusters relying on the beta API will lose all scrape target discovery silently after upgrading to Prometheus 3.

Use the Service Discovery tab at `http://localhost:9090/service-discovery` to confirm that endpointslice discovery found the correct pod targets before they enter the active scrape pool.

<KnowledgeCheck
  question="A team upgrades kube-prometheus-stack but leaves serviceDiscoveryRole unset. Which SD role does prometheus-operator use?"
  options={["endpointslice, because it defaults to the newer GA API for better performance", "endpoints (legacy), because the operator defaults to the v1/Endpoints API unless explicitly overridden", "pod, because individual pod IP scraping provides the most granular target resolution", "service, because a ClusterIP endpoint gives one stable scrape target per service"]}
  correctIdx={1}
  explanation="When serviceDiscoveryRole is not set, prometheus-operator ≥ v0.76.0 defaults to the legacy 'endpoints' role. You must explicitly set serviceDiscoveryRole: EndpointSlice in values.yaml or the Prometheus CRD spec to get EndpointSlice discovery."
/>

## node-exporter and kube-state-metrics

The stack ships two exporters that answer fundamentally different questions.

[**node-exporter**](https://github.com/prometheus/node_exporter) is a DaemonSet — one pod per node. It reads from the host's `/proc` and `/sys` and exposes hardware and OS metrics with the `node_` prefix: `node_cpu_seconds_total`, `node_memory_MemAvailable_bytes`, `node_filesystem_avail_bytes`. It has zero knowledge of Kubernetes objects. Query it to answer "Is this node's disk filling up?" or "Is a node's CPU saturated?"

[**kube-state-metrics**](https://github.com/kubernetes/kube-state-metrics) (KSM) is a single Deployment. It watches the Kubernetes API server and synthesizes object-state metrics with the `kube_` prefix: `kube_pod_status_phase`, `kube_deployment_status_replicas_available`. It answers "Are my pods running?" and "How many replicas are ready?" — but exposes nothing about actual CPU or memory consumption.

<Callout type="warning">
kube-state-metrics does not expose resource consumption. Querying kube_* metrics for CPU or memory usage returns no results. For actual node-level usage, query node_cpu_seconds_total from node-exporter, or container_cpu_usage_seconds_total from cAdvisor (embedded in the kubelet).
</Callout>

## PromQL rate() and Counter Reset Handling

[`rate(v[window])`](https://prometheus.io/docs/prometheus/latest/querying/functions/) calculates the per-second average rate of increase for a counter over the specified time window. It handles counter resets — which happen on every pod restart — by detecting any decrease in value and treating it as a reset to zero, then computing pre-reset and post-restart trends independently before combining them into a single smooth average.

Consider an `api-server` pod restarting at 14:02 with `http_requests_total` dropping from 1,432,100 to 0. `rate()` detects the drop, computes separate pre- and post-reset segments, and returns a smooth per-second average for the full five-minute window. No spike, no NaN.

```promql
# CORRECT: rate first, then aggregate across instances
sum(rate(http_requests_total{job="api-server"}[5m])) by (instance)
```

Applying `rate()` after aggregation defeats reset detection — summing across pods first masks a single-pod reset inside the group total. Always call `rate()` before `sum()`.

`increase(metric[5m])` equals `rate(metric[5m]) * 300`. Both handle resets identically; the difference is units. Use `rate()` for alerting because its output is time-window agnostic. Use `increase()` for human-readable panels showing "requests in the last 5 minutes." For a 30-second scrape interval, set your minimum rate window to `[2m]` — four times the scrape interval — to guarantee at least two samples are always present in the window.

<KnowledgeCheck
  question="A pod restart causes http_requests_total to drop from 500,000 to 0. How does rate(http_requests_total[5m]) respond?"
  options={["It returns NaN for the entire 5-minute window until the counter recovers", "It detects the drop as a reset, computes separate pre- and post-restart trends, and returns a correct per-second average", "It produces a large negative value representing the counter drop from 500,000 to 0", "It waits until the counter exceeds 500,000 again before resuming the rate computation"]}
  correctIdx={1}
  explanation="rate() treats any decrease in a counter's value as a reset to zero. It computes the rate for each continuous monotonic segment independently and combines them. The output is a smooth, accurate per-second average — no NaN, no spike, no stall."
/>

## Recording Rules and promtool Validation

A recording rule pre-computes an expensive PromQL expression and writes the result as a new time series at each evaluation interval. Dashboards that would take four seconds to load eight separate `sum(rate(...))` panels load in milliseconds after pre-computation.

```yaml
groups:
  - name: api_request_rates
    interval: 60s
    rules:
      - record: job_path:http_requests_total:rate5m
        expr: |
          sum by (job, path) (
            rate(http_requests_total[5m])
          )
```

The [naming convention `level:metric:operations`](https://prometheus.io/docs/practices/rules/) is a Prometheus best practice: `job_path` is the aggregation level, `http_requests_total` is the base metric, `rate5m` is the operation. The colon character is reserved exclusively for recording rule names — never use it in raw exporter metric names or application instrumentation.

Validate rules without starting Prometheus:

```bash
promtool check rules rules/request_rates.yaml
# Exit 0: success  |  Exit 1: syntax error  |  Exit 3: lint-fatal violation (--lint-fatal flag)
```

[Recording rules](https://prometheus.io/docs/prometheus/latest/command-line/promtool/) use `record:`. Alerting rules use `alert:`, add a `for:` duration for the pending state, and support `annotations:`. `promtool check rules` validates both rule types with the same command; `promtool test rules` runs unit tests against expected output metric values.

## Verifying Scrape Health in the Targets UI

After installing the stack, open `http://localhost:9090/targets`. Each row shows target state (UP/DOWN), last scrape time, scrape duration, and the error message when a target is DOWN. The [`up` metric](https://prometheus.io/docs/concepts/jobs_instances/) equals 1 on a successful scrape and 0 on failure, and is automatically populated for every scrape target.

Three PromQL queries to keep in your scrape-health runbook:

```promql
up == 0                                           # targets currently failing
scrape_duration_seconds > 10                      # approaching timeout (warn early)
scrape_samples_post_metric_relabeling > 5000      # cardinality spike detection
```

The cardinality query is particularly valuable at cluster onboarding: a newly deployed service that accidentally includes a `user_id` label on every metric will multiply TSDB size by an order of magnitude and first appear here, not in a billing alert.

---

## Hands-on Exercise

**Goal:** Deploy kube-prometheus-stack on a local cluster and verify scrape health end-to-end.

1. Install into a kind or minikube cluster with `serviceDiscoveryRole: EndpointSlice` and `scrapeInterval: 30s` set in `values.yaml`.
2. Port-forward the Prometheus service: `kubectl -n monitoring port-forward svc/kps-prometheus-prometheus 9090:9090`.
3. Open `http://localhost:9090/targets` — every target should show **State: UP**.
4. Run `up == 0` in the Expression Browser. Expect an empty result set.
5. Write a recording rule `job:up:avg` with `expr: avg by (job) (up)` in `rules/health.yaml`. Validate with `promtool check rules rules/health.yaml` and confirm exit code 0.
6. Apply the rule via a `values.yaml` `additionalPrometheusRulesMap` entry and reload with `curl -X POST http://localhost:9090/-/reload`. Query `job:up:avg` in the Graph view — it should return values near 1.0 for all jobs.

**Success criteria:** No `up == 0` results; `promtool` exits 0; `job:up:avg` is queryable and returns expected values near 1.0.

[[02-promql-slos-and-alertmanager]] covers `histogram_quantile()` for SLO latency percentiles and multi-burn-rate alerting with Alertmanager.
