---
chapter_num: 2
course_slug: prometheus-grafana-opentelemetry-for-sres
title: "Writing PromQL Queries and Alertmanager Rules for Payment-Path SLOs"
status: g3-passed
last_updated: 2026-06-12
duration_min: 28
vendor_tag: prometheus
learning_objectives:
  - "Write histogram_quantile() expressions for p99 latency and explain the accuracy gap between classic and native histograms"
  - "Implement multi-window multi-burn-rate SLO alerting for a payment service using the three-tier Google SRE Workbook methodology"
  - "Configure Alertmanager routing trees with inhibition rules and distinguish group_wait, group_interval, and repeat_interval semantics"
  - "Deploy PrometheusRule CRDs and validate alert rules with promtool unit tests and Alertmanager API diagnostics"
sources:
  - url: "https://prometheus.io/docs/prometheus/latest/querying/functions/"
    title: "Query functions | Prometheus"
  - url: "https://prometheus.io/docs/practices/histograms/"
    title: "Histograms and summaries | Prometheus"
  - url: "https://prometheus.io/docs/specs/native_histograms/"
    title: "Native Histograms | Prometheus"
  - url: "https://sre.google/workbook/alerting-on-slos/"
    title: "Alerting on SLOs | Google SRE Workbook"
  - url: "https://prometheus.io/docs/alerting/latest/configuration/"
    title: "Configuration | Prometheus Alertmanager"
  - url: "https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/"
    title: "Unit testing for rules | Prometheus"
  - url: "https://prometheus-operator.dev/docs/developer/alerting/"
    title: "Alerting Routes | Prometheus Operator"
owns:
  - "histogram_quantile() expressions for p99 latency SLO modeling"
  - "Multi-window multi-burn-rate SLO alerting methodology"
  - "Alertmanager routing tree: receiver groups, inhibition rules, repeat_interval"
  - "PrometheusRule CRD structure and unit-test syntax"
  - "promtool test rules validation workflow"
  - "Alertmanager /api/v2/alerts endpoint diagnostics and route tracing"
  - "Payment-service reliability modeling: error rate, latency percentiles, saturation"
defers_to:
  - "Basic rate() PromQL and recording rule syntax → ch1"
  - "Grafana-managed alert rules and contact points → ch3"
  - "Grafana Explore and trace-to-metrics correlation → ch5"
quiz_topics:
  - "Why multi-window multi-burn-rate alerts reduce both false positives and detection lag vs. single-threshold alerts"
  - "histogram_quantile() accuracy tradeoffs: classic fixed buckets vs. Prometheus 3 native histograms"
  - "Alertmanager repeat_interval vs. group_wait vs. group_interval: semantic distinctions"
  - "How inhibition rules prevent alert storms during a full-outage incident"
notebooklm_source_focus:
  - "Prometheus native histogram documentation (Prometheus 3.x)"
  - "Google SRE Workbook Chapter 5: Alerting on SLOs (multi-burn-rate methodology)"
  - "Alertmanager routing tree and inhibition rules configuration reference"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Why does the MWMBR method reduce false positives compared to a single short-window threshold alert?"
    options:
      - "Short windows fire fast but reset slowly, while long windows provide a grace period before sending pages"
      - "Both windows must fire simultaneously, so transient spikes do not page; the short window clears within minutes post-incident"
      - "Multi-burn-rate alerts skip the 'for' duration clause entirely, relying on window duration alone to filter noise"
      - "Each tier in MWMBR uses a progressively longer window, so later tiers catch incidents the earlier tiers missed entirely"
    correct_idx: 1
    explanation: "The AND condition means both the long window (1h) and the short window (5m) must simultaneously exceed the burn-rate threshold. A 30-second traffic spike raises the 5m window but not the 1h window, so the alert never fires. After the incident resolves, the 5m short window drains within minutes, cutting reset time versus a standalone long-window alert."
    section_anchor: multi-window-multi-burn-rate-slo-alerting
  - question: "What is the key accuracy difference between classic fixed-bucket histograms and Prometheus 3 native histograms when computing p99 latency?"
    options:
      - "Native histograms compute the quantile using the median of each bucket, while classic histograms use linear interpolation"
      - "Classic histograms interpolate linearly within coarse fixed buckets, causing large errors when the true value falls near the bucket midpoint"
      - "Native histograms require four times the storage of classic histograms because each bucket stores both minimum and maximum sample values"
      - "Classic histograms are more accurate because they precompute quantiles at scrape time, avoiding interpolation errors during query evaluation"
    correct_idx: 1
    explanation: "Classic histograms fix bucket boundaries at instrumentation time. histogram_quantile() uses linear interpolation within the containing bucket. If the true p95 is 220ms and your buckets span 200–300ms, the function may return 295ms — a 34% overestimate. Native histograms use exponential interpolation with dynamic ~4%-wide buckets, returning 228ms for the same data."
    section_anchor: histogram_quantile-and-the-case-for-native-histograms
  - question: "An on-call engineer notices warning-level alerts keep firing repeatedly for an incident that has already been paged. Which Alertmanager parameter should be increased to reduce repeated re-notifications for the unchanged active group?"
    options:
      - "group_wait, which buffers additional alerts after the first notification before the next grouped send is triggered"
      - "group_interval, which controls how long after the initial notification before checking whether new alerts have joined the group"
      - "repeat_interval, which sets the minimum time between re-notifications for an alert group whose firing state has not changed"
      - "resolve_timeout, which determines how long an alert must remain inactive before Alertmanager marks it as resolved"
    correct_idx: 2
    explanation: "repeat_interval is the nag timer: it governs how often Alertmanager re-sends for an alert group that is still firing but unchanged. The default is 4h. Setting it too low (e.g., 5m) floods on-call; group_interval and group_wait control different phases — co-arrival buffering and new-alert detection, not repeat notification cadence."
    section_anchor: alertmanager-routing-tree-and-inhibition-rules
  - question: "A payment cluster suffers a full outage. Without inhibition rules, what happens to warning-severity alerts for the same service?"
    options:
      - "Warning alerts are automatically silenced by Alertmanager because the page-severity route has higher priority in the routing tree"
      - "Warning alerts fire and route to their configured receivers alongside the page alert, flooding on-call with redundant notifications"
      - "Warning alerts are delayed by group_wait until the page alert resolves, then sent as a batch notification to on-call"
      - "Warning alerts are automatically suppressed because Prometheus stops evaluating lower-severity rules when a critical threshold is breached"
    correct_idx: 1
    explanation: "Alertmanager routes all firing alerts independently. Without an inhibition rule, a page-severity alert and multiple warning-severity alerts for the same service fire simultaneously to their respective receivers. Inhibition rules with a scoped 'equal' field (e.g., equal: ['alertname', 'team']) suppress the warning alerts while the page is active, reducing notification noise during outages."
    section_anchor: alertmanager-routing-tree-and-inhibition-rules
---

## Modeling Payment-Service Reliability with Latency Percentiles

A payment-path SLO covers three reliability dimensions: **error rate** (fraction of HTTP 5xx responses), **latency percentiles** (p99 < 500ms is the industry benchmark for checkout), and **saturation** (queue depth, thread-pool utilization). Together they answer: does the service keep its promises? Error rate tells you *if* requests succeed; latency tells you *how well*; saturation predicts *when* the next failure arrives.

p99 matters more than p95 on payment paths. A checkout that fails or times out means a lost transaction, not a slow page. Industry targets consistently land at p99 < 500ms for checkout services. When each percentile tick above that represents direct revenue exposure, you model at p99 or p99.9, not p95.

## histogram_quantile() and the Case for Native Histograms

`histogram_quantile(φ, b)` estimates any quantile from a histogram. The call looks identical for classic and native histograms — the difference is in interpolation accuracy.

**Classic histograms** decompose into `_sum`, `_count`, and `_bucket{le="..."}` series with bucket boundaries fixed at instrumentation time. The function uses linear interpolation within whichever bucket contains the target quantile. If your true p95 is 220ms but your buckets are `[100ms, 200ms, 300ms]`, the function returns 295ms — a 34% overestimate — because it treats the entire 200–300ms bucket as uniformly occupied. [Histograms and summaries | Prometheus](https://prometheus.io/docs/practices/histograms/)

**Native histograms** (stable since Prometheus 3.8.0) encode a single composite sample with dynamic exponential buckets. With `NativeHistogramBucketFactor: 1.1`, each bucket is roughly 4% wider than its predecessor. The same 220ms p95 value returns 228ms — a 4% error versus 34%. Native histograms also compress to roughly 8× smaller protobuf payloads when many buckets are active. [Native Histograms | Prometheus](https://prometheus.io/docs/specs/native_histograms/)

The accuracy gap matters on payment paths because a 100ms SLO margin is not a rounding error. Misidentifying a 220ms true latency as 295ms means your alert fires on histogram noise before the actual SLO boundary.

<KnowledgeCheck question="A classic histogram has buckets at [100ms, 200ms, 300ms]. The true p99 latency is 240ms. What does histogram_quantile(0.99, ...) return?" options={["240ms — linear interpolation precisely locates the true value within the bucket", "A value significantly higher than 240ms — linear interpolation spreads the quantile across the full 200–300ms bucket", "300ms — histogram_quantile always returns the upper bucket boundary for p99", "NaN — histogram_quantile requires at least four buckets to compute p99 accurately"]} correctIdx={1} explanation="Classic histograms use linear interpolation assuming the bucket's samples are spread uniformly. With the true value at 240ms inside the 200–300ms bucket, the function estimates based on the fraction of counts in that bucket, typically returning a value well above the true quantile when bucket boundaries are coarse." />

## Multi-Window Multi-Burn-Rate SLO Alerting

A **burn rate** is how fast, relative to the SLO window, the service consumes its error budget. Burn rate 1 means the budget exhausts exactly by window end; burn rate 14.4 on a 30-day window exhausts it in roughly 50 hours. The [Google SRE Workbook](https://sre.google/workbook/alerting-on-slos/) defines three alert tiers using this concept.

Single-threshold alerts fail in two opposite directions: a short window fires on transient spikes (false positives); a long window takes hours to reset after the incident resolves (alert fatigue). The multi-window multi-burn-rate (MWMBR) AND gate fixes both.

**Tier 1** (page, 14.4× burn rate) requires both a 1-hour window AND a 5-minute window to simultaneously exceed the threshold. A 30-second traffic spike raises the 5m window but not the 1h window — no page fires. An actual outage raises both within minutes. After the fix, the 5m window drains in under five minutes, cutting reset time from hours to minutes.

```yaml
- alert: CheckoutHighErrorBurnRate
  expr: |
    (sum(rate(checkout_requests_total{status=~"5.."}[1h]))
     / sum(rate(checkout_requests_total[1h])) > 0.01440)
    and
    (sum(rate(checkout_requests_total{status=~"5.."}[5m]))
     / sum(rate(checkout_requests_total[5m])) > 0.01440)
  for: 2m
  labels:
    severity: page
    team: payments
  annotations:
    summary: "Checkout error budget burning at >14.4× — both 1h and 5m windows exceeded"
```

**Tier 2** uses a 6× burn rate over 6h + 30m windows (fires after ~5% of monthly budget consumed). **Tier 3** uses 1× burn rate over 3d + 6h windows for slow-burn detection. All three tiers together provide complete coverage: acute outages hit Tier 1 within ~5 minutes; slow degradations accumulate into Tier 3 over hours.

The latency SLO alert follows the same AND-gate pattern, replacing the error ratio with a `histogram_quantile()` expression evaluated over two windows.

<KnowledgeCheck question="Which statement correctly describes the MWMBR AND gate's role in reducing alert fatigue after an incident resolves?" options={["The long window resets immediately when errors stop, preventing re-notification within the same on-call shift", "The short window drains within minutes after errors stop, and the AND gate means a resolved short window alone resolves the alert", "Alertmanager silences the alert automatically once the on-call acknowledges the initial page", "The AND gate delays the initial alert by summing both window durations before evaluating the threshold"]} correctIdx={1} explanation="After errors stop, the 5m short window reflects a clean error rate within minutes. Because the AND gate requires both windows to exceed the threshold, a clean short window breaks the AND condition and the alert resolves — even while the 1h long window still shows elevated rates from earlier in the incident." />

## Alertmanager Routing Tree and Inhibition Rules

The Alertmanager routing tree routes firing alerts to receivers (PagerDuty, Slack, email) based on label matchers. The root route matches all alerts; child routes refine by label. Three timing parameters govern notification behavior with distinct semantics:

- **`group_wait`** (default 30s): hold time before sending the *first* notification for a new alert group, allowing co-firing alerts to arrive and be batched
- **`group_interval`** (default 5m): after the initial notification, how long before re-checking whether *new* alerts have joined the group
- **`repeat_interval`** (default 4h): how long before re-sending for an *unchanged* active group — the nag timer

<Callout type="warning">
Setting `repeat_interval` too low (e.g., 5m) causes alert fatigue — on-call receives a notification every five minutes for the entire duration of a long incident. For payment-path pages, 30m is a common production value: frequent enough to keep incidents visible, rare enough not to desensitize the responder.
</Callout>

**Inhibition rules** suppress target alerts while a source alert is active. During a full checkout outage, you want the page to fire cleanly — not alongside a flood of redundant warning-level alerts for the same service:

```yaml
inhibit_rules:
  - source_matchers: [severity=page, team=payments]
    target_matchers: [severity=warning, team=payments]
    equal: ['alertname']
```

The `equal` field is critical: without it, any page alert in any cluster silences all warning alerts globally. For multi-cluster deployments, always scope with `equal: ['cluster', 'namespace']`.

## PrometheusRule CRD and promtool Unit Tests

In Kubernetes-native setups, alerting rules live in `PrometheusRule` CRDs (`kind: PrometheusRule`, `apiVersion: monitoring.coreos.com/v1`). The prometheus-operator watches these resources and injects matching rules into any Prometheus instance whose `spec.ruleSelector` labels match the CRD's labels. A missing label — e.g., omitting `release: prometheus-stack` — causes the rule to be **silently ignored**: no error, no alert. Always confirm the resource loaded with `kubectl get prometheusrule -n payments`.

Before applying, validate with promtool:

```bash
promtool check rules checkout_slo_rules.yaml          # syntax only
promtool test rules tests/checkout_slo_test.yaml      # full unit test
```

Unit test files supply `input_series` (mock counter increments), `evaluation_interval`, and `alert_rule_test` blocks asserting which alerts should fire at each `eval_time`. A test simulating a 1-minute error spike should assert `exp_alerts: []` for the Tier 1 alert — the 1h long window dilutes the single-minute spike below the 14.4× threshold.

## Diagnosing Alerts with the Alertmanager API

When a page doesn't arrive or routes to the wrong receiver, the Alertmanager v2 API is the first diagnostic stop:

```bash
# Show all currently active alerts
curl http://alertmanager:9093/api/v2/alerts?active=true | jq .

# Trace how a label set routes through the tree
amtool config routes test --config.file=alertmanager.yml \
  team=payments severity=page alertname=CheckoutHighErrorBurnRate
```

`amtool config routes test` prints the matched receiver without sending a real notification — run this in CI and before on-call handoffs. Alertmanager 0.33.0 also accepts `receiver_matchers` filters on `/api/v2/alerts` for targeted diagnostics by receiver name.

## Hands-On Exercise

Deploy a complete payment-path SLO alert stack against a local checkout service:

1. Instrument a checkout service with `NativeHistogramBucketFactor: 1.1` (Go SDK) and confirm `histogram_quantile(0.99, ...)` returns a value against live traffic.
2. Write `checkout_slo_rules.yaml` with the Tier 1 (14.4×, 1h+5m) and Tier 2 (6×, 6h+30m) alert expressions from this chapter.
3. Run `promtool check rules checkout_slo_rules.yaml` — fix any reported syntax errors.
4. Write a unit test that (a) simulates a 2% error rate for 60 minutes and asserts Tier 1 fires at eval_time 62m, and (b) simulates a 1-minute spike and asserts Tier 1 does *not* fire. Run `promtool test rules` — both test cases must pass.
5. Apply a `PrometheusRule` CRD with `release: prometheus-stack` label; confirm with `kubectl get prometheusrule -n payments`.
6. Add an inhibition rule that suppresses warning alerts while a page fires for the same `alertname`. Run `amtool config routes test` for a payment page alert and confirm the receiver is `payments-pagerduty`.

**Success criteria:** `promtool test rules` exits 0 with "SUCCESS: N tests passed"; `amtool config routes test` prints `payments-pagerduty` as the resolved receiver.

Next: [[03-grafana-13-dashboards-and-git-sync]] builds on these Alertmanager rules by adding Grafana-managed alert rules, contact points, and Git Sync for dashboard versioning.
