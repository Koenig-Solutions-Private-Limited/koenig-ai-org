---
chapter_num: 3
course_slug: prometheus-grafana-opentelemetry-for-sres
title: "Building Grafana 13 Dashboards Backed by Prometheus with Git Sync and Alerting"
status: g3-passed
last_updated: 2026-06-12
duration_min: 35
vendor_tag: grafana-labs
learning_objectives:
  - "Provision a Prometheus data source in Grafana 13 using datasources.yaml without touching the UI"
  - "Construct a dashboard JSON model with time series, stat, gauge, and table panels"
  - "Configure query and custom template variables for dynamic service and environment selectors"
  - "Implement the Git Sync PR workflow to manage dashboards as code in a Git repository"
  - "Create Grafana-managed multi-condition alert rules and wire them to contact points"
  - "Explain the Pending → Firing alert state transition and set an appropriate pending period"
sources:
  - url: "https://grafana.com/docs/grafana/latest/administration/provisioning/"
    title: "Grafana provisioning documentation (datasources.yaml, dashboards.yaml)"
  - url: "https://grafana.com/docs/grafana/latest/as-code/observability-as-code/git-sync/key-concepts/"
    title: "Git Sync Key Concepts"
  - url: "https://grafana.com/docs/grafana/latest/alerting/alerting-rules/create-grafana-managed-rule/"
    title: "Configure Grafana-managed alert rules"
  - url: "https://grafana.com/docs/grafana/latest/alerting/fundamentals/alert-rules/state-and-health/"
    title: "Alert rule state and health"
  - url: "https://grafana.com/docs/grafana/latest/dashboards/variables/add-template-variables/"
    title: "Add and manage variables"
  - url: "https://devopscube.com/observability-as-code-with-grafana-git-sync/"
    title: "Observability as Code with Grafana Git Sync"
  - url: "https://grafana.com/press/2026/03/18/grafana-labs-4th-annual-observability-survey-reveals-a-field-at-a-crossroads-ai-economics-complexity-and-the-enduring-power-of-open-source/"
    title: "Grafana Labs 4th Annual Observability Survey 2026"
owns:
  - "Grafana 13 Prometheus data source provisioning via YAML (no manual UI)"
  - "Dashboard JSON model: time series, stat, gauge, table panel types"
  - "Template variables for service and environment selectors"
  - "Grafana 13 GA Git Sync: branch workflow, PR merge, dashboard update"
  - "Grafana-managed alert rules: multi-condition thresholds, contact points"
  - "Grafana alert state machine: Pending → Firing transitions"
defers_to:
  - "Prometheus scrape configuration and recording rules → ch1"
  - "PrometheusRule CRD and Alertmanager routing → ch2"
  - "Grafana Explore trace-to-metrics and Jaeger data source → ch5"
quiz_topics:
  - "Grafana-managed alerts vs. data-source-managed alerts: architectural difference and when to use each"
  - "Git Sync merge conflict resolution for dashboard JSON: what causes conflicts and how to avoid them"
  - "Template variables vs. repeated panels: when each pattern is appropriate"
  - "Provisioning YAML vs. manual UI configuration: idempotency and GitOps implications"
notebooklm_source_focus:
  - "Grafana 13 release notes and Git Sync GA announcement (June 2026)"
  - "Grafana dashboard provisioning documentation (datasources.yaml, dashboards.yaml)"
  - "Grafana alerting architecture: unified alerting, rule groups, contact points"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which capability is available in Grafana-managed alert rules but absent from data-source-managed rules?"
    options:
      - "Multi-condition expressions combining results from multiple queries using Math and Reduce operators"
      - "Horizontal scalability by distributing evaluation across the data source's ruler component nodes"
      - "Native configuration via Prometheus ruler YAML for GitOps-style alerting infrastructure"
      - "Evaluation of alert conditions at the data source layer, independent of the Grafana server process"
    correct_idx: 0
    explanation: "Grafana-managed rules support Reduce, Resample, and Math expressions across multiple queries and any data source. Data-source-managed rules evaluate a single PromQL query per rule against Mimir or Loki only — no cross-query Math, no RBAC, no alert state history."
    section_anchor: "grafana-managed-alert-rules-and-the-alert-state-machine"
  - question: "Why do simultaneous edits to different panels of the same dashboard cause Git Sync merge conflicts?"
    options:
      - "Git Sync tracks each panel in a separate branch, and two branches targeting the same dashboard folder create naming collisions"
      - "Grafana serializes an entire dashboard as one JSON file, so concurrent panel edits both modify the same file in the repository"
      - "Grafana webhooks allow only one push event per repository per minute, causing queued edits to collide on arrival"
      - "The 60-second polling interval pulls both in-flight saves into the same sync batch, generating a forced three-way merge"
    correct_idx: 1
    explanation: "A Grafana dashboard has no sub-file granularity — all panels, variables, and layout live in one JSON object. Any two concurrent edits touching separate panels produce conflicting modifications to the same file, triggering a standard Git merge conflict."
    section_anchor: "git-sync-dashboards-as-code"
  - question: "An SRE team wants all six payment microservices displayed side-by-side on a single screen for real-time comparison. Which approach is most appropriate?"
    options:
      - "A query template variable with multi-value support so the viewer selects all services via a single dropdown"
      - "Panel repetition, which auto-generates one panel instance per variable value and renders them all simultaneously"
      - "A custom variable with a static comma-separated list to eliminate the need for dynamic PromQL label-values queries"
      - "Six separate dashboards connected via Grafana dashboard-link annotations for coordinated side-by-side navigation"
    correct_idx: 1
    explanation: "Panel repetition renders N copies of the panel, one per variable value, all visible at once — ideal for side-by-side comparison. A multi-select template variable layers all series onto a single panel, which is better for switching focus between services than comparing them simultaneously."
    section_anchor: "template-variables-for-dynamic-dashboards"
  - question: "Why is YAML-based data source provisioning considered idempotent while manual UI configuration is not?"
    options:
      - "YAML files are content-hashed on each reload so Grafana skips re-processing when the hash matches the stored configuration"
      - "Applying the same datasources.yaml file repeatedly always converges to the same end state; each UI operation is a one-shot mutation with no built-in reconciliation"
      - "Grafana encrypts credentials in secureJsonData at write time, preventing the same YAML block from being applied twice safely"
      - "YAML provisioning sets the data source to read-only in the UI layer, which the REST API cannot override without a corresponding YAML change"
    correct_idx: 1
    explanation: "Idempotency means re-applying the same input always produces the same output. The YAML provisioner reconciles declared state against Grafana's current state on every reload — creates if missing, updates if changed, prunes if removed. Manual UI clicks mutate state once with no equivalent reconciliation step."
    section_anchor: "provisioning-prometheus-as-a-data-source-via-yaml"
---

## Provisioning Prometheus as a Data Source via YAML

Grafana's provisioning system reads YAML files at startup and on every reload, making data source configuration repeatable and auditable without a single UI click. Drop a `datasources.yaml` file into `provisioning/datasources/` and Grafana wires the connection — the source of truth stays in your Git repository, not Grafana's database.

A production-ready Prometheus configuration:

```yaml
# provisioning/datasources/prometheus.yaml
apiVersion: 1
prune: true
datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus-main
    url: http://prometheus:9090
    isDefault: true
    editable: false
    jsonData:
      scrapeInterval: "15s"
      httpMethod: "POST"
```

Two fields are load-bearing. `uid: prometheus-main` creates a stable identifier that every dashboard panel references in its `datasource.uid` field. Omit it and Grafana auto-generates a UID from the name; rename the data source and every dependent panel breaks silently. `editable: false` greys out the settings in the UI so no one can drift the connection away from the declared configuration. The top-level `prune: true` makes deletions declarative: remove the stanza from YAML and Grafana deletes the data source on the next reload, no manual UI cleanup required.


<KnowledgeCheck
  question="You set `editable: false` on a provisioned data source. A colleague tries to change the URL in the Grafana UI. What happens?"
  options={[
    "Grafana rejects the edit immediately — the URL field is greyed out and uneditable in the UI",
    "The UI edit persists in the database until the next Grafana restart, then the YAML overwrites it",
    "Grafana accepts the edit and also writes the new URL back to the datasources.yaml file on disk",
    "The editable flag controls visibility only; the URL field remains writable via the REST API"
  ]}
  correctIdx={0}
  explanation="`editable: false` is enforced at the UI layer. Fields are greyed out and the save button is disabled. The YAML file remains the sole source of truth for all connection settings."
/>

## Building the Dashboard JSON Model

Every Grafana dashboard is a JSON document. The root object carries metadata (`title`, `uid`, `tags`, `refresh`), a `templating` block for variables, and a `panels` array. Each panel has a `type`, a `gridPos` object positioning it on the 24-column grid, and type-specific `options` and `fieldConfig` blocks.

Choose the panel type based on the shape of data you need to render:

| Panel type | Use when | Typical PromQL shape |
|---|---|---|
| Time Series | Trends over time, multiple series | `rate()`, `histogram_quantile()` |
| Stat | Single current value with optional sparkline | `sum()` returning one vector |
| Gauge | Value plotted against a min/max target | Same as Stat, with threshold steps |
| Table | Multi-dimensional label breakdowns | `sum(...) by (label)` returning table |

The `fieldConfig.defaults.unit` and `thresholds` fields apply uniform formatting across all series. A Gauge panel colors a payment success rate red below 99% with no conditional logic — the threshold steps carry it.

## Template Variables for Dynamic Dashboards

Template variables turn a static dashboard into a multi-service explorer. A `query` variable executes PromQL against your data source to populate its dropdown:

```
label_values(http_requests_total, service)
```

Set refresh to "On dashboard load" so new services appear automatically as your workload grows. A `custom` variable uses a static comma-separated list — exactly right for an environment selector (`prod,staging,dev`) whose options do not change with your workload.

Reference variables in panel queries as `$service` or `${service}`. Chain them when one variable constrains another: a `$service` query whose PromQL reads `label_values(up{env="$env"}, service)` shows only services active in the chosen environment, eliminating phantom entries from decommissioned workloads.

Template variables and repeated panels solve different problems. A template variable with multi-select parameterizes all panels simultaneously — right when a viewer wants to focus on one service at a time. Panel repetition auto-generates N copies of a panel, one per variable value, all visible at once — right when the goal is side-by-side comparison across all services. Mixing both on the same dashboard usually signals it needs to be split by purpose.

<KnowledgeCheck
  question="A query variable was configured with refresh set to 'Never' when only three services existed. A fourth service was added last week. What is the user-visible problem?"
  options={[
    "The variable's PromQL expression becomes invalid and throws a data source error on dashboard load",
    "The new service does not appear in the dropdown until the refresh setting is changed to 'On dashboard load'",
    "Panel repetition will still render four panels but the fourth will display a no-data placeholder",
    "The variable auto-refreshes when the user changes the time range, so no manual action is required"
  ]}
  correctIdx={1}
  explanation="A 'Never' refresh setting freezes the variable options to the values captured when the variable was last manually refreshed. The new service is invisible in the dropdown until the setting is updated to 'On dashboard load' or 'On time range change' and the dashboard is reloaded."
/>

## Git Sync: Dashboards as Code

Grafana 13.0 (April 21, 2026) promoted [Git Sync to General Availability](https://grafana.com/docs/grafana/latest/as-code/observability-as-code/git-sync/key-concepts/) across Cloud, Enterprise, and OSS editions. Git Sync connects Grafana to a GitHub, GitLab, or Bitbucket repository and keeps dashboards synchronized bidirectionally: UI edits commit back to Git; Git merges propagate back to Grafana.

The PR workflow turns every change into a reviewable event: an engineer edits a panel and clicks **Save**; Grafana commits the JSON to a feature branch and opens a PR automatically; a reviewer merges it; Git Sync detects the merge within 5 seconds via webhook (or 30 seconds via polling) and updates the live dashboard.

The structural risk is merge conflicts. A dashboard has no sub-file granularity — all panels, variables, and layout live in one JSON object, so any two concurrent edits touch the same file. The PR workflow mitigates this by serializing changes through review, but the root cause remains: **one editor per dashboard at a time.** Per [Observability as Code with Grafana Git Sync](https://devopscube.com/observability-as-code-with-grafana-git-sync/), start with a small subset; performance degrades above 200 dashboards.

<Callout type="warning">
**Upgrade to v13.0.1 before enabling Git Sync in production.** A migration bug in Grafana v13.0.0 can cause dashboards and folders to revert or be deleted when upgrading from v12.x with Git Sync active. The fix shipped in v13.0.1, the current stable release. Confirm your version with `grafana-cli --version` before connecting any repository.
</Callout>

## Grafana-Managed Alert Rules and the Alert State Machine

Grafana's unified alerting engine offers two architectures. **Data-source-managed rules** are stored and evaluated by the data source's ruler component — available only for Mimir and Loki — and are the right choice when horizontal evaluation scalability matters more than multi-condition logic. **Grafana-managed rules** are stored in Grafana's own database, evaluated by the Grafana server, and support any connected data source plus multi-query expressions using Reduce, Resample, and Math operators.

Build a multi-condition rule that fires if P99 latency exceeds 500 ms **or** error rate exceeds 1%:

- **Query A:** `histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{service="payments"}[5m])) by (le))`
- **Query B:** `sum(rate(http_requests_total{status=~"5..",service="payments"}[5m])) / sum(rate(http_requests_total{service="payments"}[5m]))`
- **Math expression C:** `$A > 0.5 || $B > 0.01`

Assign the rule to an evaluation group and set the **Pending period** to 2–5 minutes for any signal that can spike transiently. The Pending period is a hysteresis buffer: the condition must breach continuously for the full duration before the alert transitions to Firing. Setting it to zero fires on the first evaluation breach — right only for signals where every false positive is acceptable. The [Grafana Labs 4th Annual Observability Survey](https://grafana.com/press/2026/03/18/grafana-labs-4th-annual-observability-survey-reveals-a-field-at-a-crossroads-ai-economics-complexity-and-the-enduring-power-of-open-source/) found 30% of SREs cite alert fatigue as their biggest obstacle; a nonzero pending period is the cheapest mitigation.

Attach a **contact point** to route notifications when the alert fires. Contact points bundle one or more integrations — Grafana ships over 25 types including Slack, PagerDuty, Microsoft Teams, email, and webhook — into a single named destination. A single contact point can aggregate several integrations, so a critical alert simultaneously pages on-call via PagerDuty and posts a Slack summary in one delivery step.

## Hands-On Exercise

**Goal:** Provision a Prometheus data source, build a two-panel dashboard with template variables, connect Git Sync, and observe a multi-condition alert cycle through the full state machine.

**Steps:**

1. Create `provisioning/datasources/prometheus.yaml` with the YAML from this chapter. Restart Grafana and verify the data source appears under **Configuration → Data sources** with a "Managed" badge and the URL field greyed out.

2. Open **Dashboards → New Dashboard → JSON model**, paste the dashboard skeleton, and confirm the `$service` and `$env` dropdowns populate.

3. Edit the P99 panel title to `P99 Latency — $service ($env)` and click **Save**. Verify a PR appears in your linked repository within 30 seconds. Merge it and confirm the title updates live in Grafana.

4. Navigate to **Alerting → Alert rules → New alert rule**. Create a Grafana-managed rule with Query A (P99), Query B (error rate), and Math expression C as above. Set the pending period to **2m**. Attach a contact point wired to a test Slack webhook. Temporarily lower the threshold to `$A > 0` to force a breach. Watch Normal → Pending → Firing in the state view and confirm a Slack notification arrives.

**Success criteria:**
- Data source shows "Managed" badge; connection test passes.
- Git PR was opened on save; dashboard reflected the merged title change within 30 seconds.
- Alert transitioned through Pending and reached Firing within 2 minutes; Slack notification received.

---

Next, we instrument the services whose metrics you just charted and route their distributed traces into a backend: [[04-opentelemetry-sdk-and-jaeger-v2]].
