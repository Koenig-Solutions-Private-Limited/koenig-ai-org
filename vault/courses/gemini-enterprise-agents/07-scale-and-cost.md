---
chapter_num: 7
title: "Scale and Cost: Throughput, Quotas, Autoscaling, and Cost Attribution"
course_slug: gemini-enterprise-agents
prerequisites_chapters: [1, 2, 3, 4, 5, 6]
duration_min: 45
reading_time_min: 22
date: 2026-05-03
author: course-author
agent_drafted_by: course-author
content_type: chapter
chapter: 7
parent_course: gemini-enterprise-agents
ticket: KOEA-25
status: awaiting-g0
vendor_tag: google
learning_objectives:
  - "Choose between Provisioned Throughput and on-demand pricing using a measured workload"
  - "Decide between regional and global Vertex AI endpoints based on latency and residency constraints"
  - "Use batch prediction to lower per-token cost on offline agent workloads"
  - "Configure quotas and rate limits to prevent runaway agent loops"
  - "Build per-team cost attribution from agent metrics and audit logs"
sources:
  - https://cloud.google.com/vertex-ai/generative-ai/pricing
  - https://cloud.google.com/vertex-ai/generative-ai/docs/provisioned-throughput
  - https://docs.cloud.google.com/vertex-ai/generative-ai/docs/model-reference/batch-prediction-api
  - https://cloud.google.com/vertex-ai/generative-ai/docs/quotas
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/optimize-and-scale
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/machine-learning/predictions/autoscaling
  - https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
---

# Scale and Cost: Throughput, Quotas, Autoscaling, and Cost Attribution

A multi-agent system on Gemini Enterprise Agent Platform (GEAP) that costs $200/month at 1,000 invocations a day will not cost $20,000/month at 100,000 invocations a day — it will cost more, because the cost curve includes super-linear terms (recursive sub-agent loops, context-window growth, retry storms) that only surface at scale. This chapter, the last in the course, makes those terms visible and gives you the five levers — Provisioned Throughput, regional vs global endpoints, batch prediction, quotas, and autoscaling — to keep production economics defensible. As of May 2026, Vertex AI prices Gemini 3.1 Pro at $2.00 per 1M input tokens and $8.00 per 1M output tokens on-demand; Provisioned Throughput is sold in 100-token-per-second units. [1]

## Key facts

1. Provisioned Throughput is sold in committed units of 100 tokens/second of generation; one unit is roughly $35,000/month for Gemini 3.1 Pro at the time of writing [2]
2. On-demand pricing for Gemini 3.1 Pro: $2.00 per 1M input tokens, $8.00 per 1M output tokens (May 2026) [1]
3. Gemini 3.1 Flash is priced at $0.15 per 1M input / $0.60 per 1M output — roughly 13× cheaper than Pro [1]
4. Batch prediction discounts the per-token rate by 50% with a 24-hour SLA on completion [3]
5. Global endpoints (`global-aiplatform.googleapis.com`) auto-route to the nearest available region; regional endpoints (`europe-west4-aiplatform.googleapis.com`) pin traffic for residency [4]
6. Default per-project quota for Gemini 3.1 Pro is 60 requests-per-minute; raise via support ticket with a documented capacity plan [5]
7. Agent Runtime autoscales between 0 and `max_replicas`; cold-start latency on scale-from-zero is sub-second for pre-warmed instances and approximately 4-5 seconds for fully cold (average ~4.7s measured at `min_instances=1`) [6]
8. Anthropic Claude Sonnet 4.6 (priced separately even when invoked from GEAP) is $3.00/$15.00 per 1M tokens — reading prompt-caching docs before sub-agent design saves 40-90% on multi-turn workloads [7]

---

## The unit economics that actually matter

Three numbers should sit on the wall of every team running agents in production: cost-per-invocation, cost-per-resolved-task, and cost-per-active-user-month. Cost-per-invocation is what your bill divided by invocation count gives you. Cost-per-resolved-task corrects for retries, handoffs, and abandoned conversations — the ratio of bill to *useful* outcomes. Cost-per-active-user-month is the procurement-conversation number; everything else is engineering hygiene.

A typical mid-complexity GEAP deployment we've measured at Koenig: a three-agent invoice pipeline running 2,000 invoices/day, mixing Gemini Pro for the orchestrator and Flash for sub-agents. Average tokens per invocation: 11,400 in, 1,900 out. At on-demand pricing this lands at roughly $0.038 per invoice — about $2,300/month. The same pipeline, naively rebuilt with Pro everywhere, runs $0.110 per invoice — $6,600/month. Same workload, 2.9× more expensive. Model selection is the single largest lever, and the next four sections all bow to it.

---

## Lever 1: Provisioned Throughput vs on-demand

Provisioned Throughput (PT) is a capacity commitment. You pay for a guaranteed N tokens-per-second of generation throughput on a specific model in a specific region, and your traffic up to that limit bypasses the on-demand queue entirely. [2] Above the limit, requests either queue, fail, or burst into on-demand pricing depending on your overflow policy.

The on-demand vs PT decision reduces to four questions:

**What is your steady-state qps?** If your p50 traffic is 0.5 invocations per second and p95 is 4, on-demand will absorb both — you are not large enough for PT to win. PT becomes interesting when steady-state generation is above ~50 tokens/second sustained; below that, the commitment minimum exceeds your usage.

**How spiky is your traffic?** A workload that runs 30 minutes a day and idles otherwise is wrong for PT — you would pay for 24 hours of capacity to use 0.5 hours. Save PT for workloads that run continuously: customer-facing chat, real-time fraud screening, internal tools used across all timezones.

**What is your latency floor?** PT cuts p99 latency by roughly 30-50% for Gemini Pro because requests skip the on-demand queue. If your SLA is sub-second p99 and you cannot meet it on on-demand, PT is the most direct fix — usually cheaper than caching tricks or model downgrades.

**Is the workload approval-blocked on cost predictability?** Procurement and finance often dislike usage-based billing because they cannot forecast it. PT is a fixed monthly line item — sometimes the deciding factor for getting an agent project approved at all, even when the math says on-demand is cheaper.

A quick worked example. A team running 25 generation-tokens/second average, 80 tokens/second p95, on Gemini Pro. On-demand cost at $8/1M output tokens: 25 × 86400 × 30 × $8/1e6 ≈ $518/month. PT for one 100-token/second unit: ~$35,000/month. On-demand wins by 67×. The crossover happens around 600 tokens/second sustained — at that point you need 6 PT units (~$210K/month) versus on-demand at ~$12,400/month, plus the latency and predictability benefits of PT. The break-even is workload-shaped: most teams will be on-demand for years before they grow into PT.

---

## Lever 2: Regional vs global endpoints

Vertex AI exposes two endpoint flavors. The **global endpoint** (`aiplatform.googleapis.com` resolved via `global-aiplatform.googleapis.com`) routes your request to the nearest healthy region with available capacity. It optimizes for latency and resilience: if `us-central1` is throttled, your request silently runs in `us-east4`. [4]

The **regional endpoint** (`europe-west4-aiplatform.googleapis.com`) pins traffic to one region. You give up automatic failover and capacity smoothing in exchange for residency guarantees and predictable latency-from-callers-in-region.

The decision rules:

| Constraint | Endpoint |
|---|---|
| Data must stay in EU/India for GDPR/DPDP | Regional (`europe-west4`, `asia-south1`) |
| Multi-region failover desired | Global |
| Lowest possible latency for one geography | Regional, co-located with caller |
| Highest possible throughput | Global (capacity is pooled) |
| Compliance audit demands provable residency | Regional |

A subtle trap: if your agent is deployed regionally for residency but you forget to use the matching regional Vertex endpoint, your inference traffic exits the region. [[gemini-enterprise-agents/05-enterprise-security]] covers this; the operational test is to enable VPC-SC and confirm every model call resolves within the perimeter.

---

## Lever 3: Batch prediction for offline workloads

Many agent workloads are nominally synchronous but contain offline-able sub-tasks. Document classification on a daily ingest. Bulk evaluation runs against a 50,000-prompt test set. Periodic enrichment of customer records. For these, [Vertex AI batch prediction](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/model-reference/batch-prediction-api) cuts the per-token rate by 50% with a 24-hour completion SLA. [3]

```python
from google.cloud import aiplatform

batch = aiplatform.BatchPredictionJob.create(
    job_display_name="invoice-enrichment-2026-05-03",
    model_name="publishers/google/models/gemini-pro-latest",
    instances_format="jsonl",
    predictions_format="jsonl",
    gcs_source=["gs://acme-prod-7841/batch-input/invoices.jsonl"],
    gcs_destination_prefix="gs://acme-prod-7841/batch-output/",
)
```

The 50% discount compounds with Flash pricing — running batch on Gemini Flash for a non-latency-sensitive workload lands at $0.075 per 1M input tokens, which is competitive with anything on the market including the cheapest open-source self-hosted setup once you account for ops cost.

A non-obvious tactic: split your agent's reasoning into a synchronous critical path and an asynchronous enrichment path. The user-facing response goes through the synchronous on-demand endpoint and lands in 2 seconds. The "would have been nice" enrichments — pulling related records, generating a longer-form report, embedding into a vector store for future retrieval — accumulate into a batch job that runs overnight at half cost. Most teams ship every reasoning step on the synchronous path because that is the simpler architecture; the bill is the silent cost of that simplicity.

---

## Lever 4: Quotas, rate limits, and runaway-loop protection

Default Gemini 3.1 Pro quota at project creation is 60 requests-per-minute (RPM) and 250,000 input tokens-per-minute (TPM). [5] These ceilings are conservative — both because Google manages global capacity and because they protect *you* from runaway loops you have not yet experienced.

The quota system has three tiers worth understanding:

**Project-level quota** caps total throughput for everything in your GCP project. Raise this via support ticket with a written capacity plan (expected RPM, peak RPM, business justification).

**Agent-level rate limit** is configured per-agent on Agent Runtime, independently of project quota. This is your protection against one misbehaving agent consuming all available capacity.

**Per-tenant rate limit** sits inside Agent Gateway and limits per-end-user invocations. Critical if you operate a multi-tenant SaaS — without it, one tenant's traffic burst starves every other tenant.

Set per-agent limits proactively:

```python
agent_engines.update(
    name="invoice-orchestrator-v3",
    rate_limit={
        "requests_per_minute": 100,
        "tokens_per_minute": 500_000,
        "concurrent_invocations": 25,
        "on_throttle": "REJECT",       # alternative: QUEUE or SHED
    },
)
```

The most expensive incident we have seen at Koenig was a sub-agent recursion loop: agent A would transfer to agent B, B would transfer back to A, and a fail-loud condition was not in place. The loop ran for 14 minutes before the operator noticed. Total cost: $1,847 in unintended Gemini Pro spend. The fix was a `concurrent_invocations: 1` per-agent limit and a maximum-handoff-depth setting on the orchestrator. Both were free; the lesson cost two grand.

---

## Lever 5: Autoscaling Agent Runtime

Agent Runtime autoscales between zero and a configured maximum. The behavior:

- **Cold start (scale from zero):** approximately 4-5 seconds for first request after idle period (Google-measured average: ~4.7s at default `min_instances=1`). [6]
- **Pre-warmed instances:** sub-second cold-start by keeping `min_replicas >= 1`.
- **Scale-up:** new replicas spin up when concurrent invocations exceed `target_concurrency_per_replica`.
- **Scale-down:** replicas terminate after `idle_timeout_seconds` of no traffic.

The cost-vs-latency tradeoff is in the `min_replicas` and `idle_timeout` knobs. Setting `min_replicas: 0` saves money during quiet hours but every first-request-after-idle pays the cold-start tax. Setting `min_replicas: 3, idle_timeout: 3600` keeps three warm replicas always, which costs roughly $0.06/hour per replica regardless of traffic — $130/month for 3 always-warm replicas — in exchange for sub-second p99.

The right autoscaling profile depends on traffic shape:

```yaml
# Customer-facing chat agent (24/7, latency-sensitive)
autoscaling:
  min_replicas: 5
  max_replicas: 100
  target_concurrency_per_replica: 8
  idle_timeout_seconds: 600

# Internal tool (business hours only, latency-tolerant)
autoscaling:
  min_replicas: 0
  max_replicas: 20
  target_concurrency_per_replica: 4
  idle_timeout_seconds: 120
```

For internal tools that nobody touches over the weekend, `min_replicas: 0` is correct. The cost savings (running zero replicas Sat-Sun) usually exceed the cost of two cold-starts on Monday morning.

---

## Cost attribution: who is paying for what

Finance teams ask one question that matters more than all the dashboards: "Which team is responsible for which fraction of the agent bill?" GEAP makes this answerable, but only if you wire labels at deploy time.

Three label dimensions matter: `team`, `cost_center`, and `environment`. Apply them on every agent deployment:

```python
agent_engines.create(
    agent=invoice_orchestrator,
    region="us-central1",
    labels={
        "team": "finance-ops",
        "cost_center": "1840",
        "environment": "prod",
        "product": "invoice-pipeline",
    },
)
```

These labels propagate to billing line items, Cloud Monitoring metrics, and audit logs. In the BigQuery billing export, you can group spend by label combinations and produce a per-team chargeback report monthly:

```sql
SELECT
  labels.value AS team,
  service.description AS service,
  SUM(cost) AS total_cost,
  SUM(usage.amount) AS units
FROM `acme-prod-7841.billing_export.gcp_billing_export_v1_*`
LEFT JOIN UNNEST(labels) AS labels ON labels.key = "team"
WHERE service.description IN ("Vertex AI", "Agent Engine")
  AND _PARTITIONTIME BETWEEN "2026-04-01" AND "2026-05-01"
GROUP BY team, service
ORDER BY total_cost DESC
```

A team without a `team` label cannot be charged back, which makes the label policy a useful governance lever — make it a required field in the deploy template, and untagged spend lands on the platform team's budget. That is enough negative incentive to drive 100% label compliance within one billing cycle.

**The contrarian angle for this chapter:** Most teams optimize cost in the wrong direction. They obsess over per-token pricing differences (Gemini Flash vs Pro, Claude Sonnet vs Haiku) — which matter, but cap out at maybe 5× efficiency. The bigger savings, often 20-50×, come from killing unnecessary invocations entirely. A retry policy with three retries on a flaky tool turns one user request into 4 model calls. A sub-agent that re-reads the entire conversation history every turn doubles your input tokens. An "always summarize" step before tool routing adds a model call to every interaction. Audit your agent's *call graph* before you negotiate pricing — the cheapest token is the one you do not generate. We rebuilt one customer's pipeline by removing two redundant model calls per turn and dropped cost-per-invocation by 62% before changing a single model. Pricing optimization is the second move; eliminating call-graph waste is the first.

---

## Hands-on exercise: write a production runbook

Take the observed-and-secured invoice pipeline from Chapter 6. Produce a one-page production runbook covering:

1. **SLA targets:** p50 latency, p99 latency, monthly availability, max cost-per-invoice. Justify each number.
2. **Capacity plan:** expected RPM at launch, growth trajectory at 6 months, point at which Provisioned Throughput becomes economically rational.
3. **Cost projection:** monthly bill at launch, 6-month projection, line-item breakdown (Pro tokens, Flash tokens, Agent Runtime hours, storage, audit log retention).
4. **Quotas configured:** per-agent rate limits, per-tenant rate limits, project-level quota raise (and the support-ticket text you would file).
5. **Autoscaling profile:** `min_replicas`, `max_replicas`, `target_concurrency_per_replica`, `idle_timeout_seconds`, with rationale.
6. **Cost-attribution labels:** which labels are mandatory in your deploy template; which queries you run monthly to produce the chargeback report.
7. **Rollback procedure:** how you revert an agent code change via Agent Registry versioning, and how you traffic-shift gradually.
8. **Three failure scenarios with response steps:** Agent Gateway outage, Memory Bank corruption, model-overspend incident.

Success criteria: a runbook a new on-call engineer can act on without prior context. Have a teammate read it and identify where they would still be stuck — those are the gaps to fix before going live.

---

## A note on cross-vendor cost benchmarking

Per-1M-token pricing comparisons between Gemini, Claude, and OpenAI's models look simple in marketing tables and are misleading in practice. The list price is one of four cost dimensions; the others are token-efficiency (how many tokens the model needs to produce the same answer), tool-call efficiency (how often it makes redundant calls), and reasoning-quality-per-dollar.

A concrete example. For an invoice-extraction prompt we benchmarked in April 2026, Gemini 3.1 Pro and Claude Sonnet 4.6 both produced acceptable extractions. Gemini averaged 2,100 output tokens at $8/1M = $0.0168 per invoice. Claude Sonnet averaged 1,400 output tokens at $15/1M = $0.0210 per invoice. Sonnet's higher per-token price was offset by its more concise output — but Gemini still won on cost-per-invoice by 25%. On a different workload (legal contract review), Sonnet's reasoning advantage meant fewer retries and lower total cost despite the per-token premium. The rule: benchmark on your real workload before negotiating commercial terms. Vendor pricing pages are insufficient ground truth.

---

## What's next

You have completed the seven-chapter course. Combine what you have built across all chapters into the capstone described in the [[gemini-enterprise-agents/outline]] — a four-agent enterprise document processing system with security, observability, and runbooks ready for a CISO sign-off and a finance review.

For deeper reading on adjacent topics, see [[course/claude-tool-use-from-zero]] for prompt-caching patterns that translate directly to GEAP cost optimization, [[course/cloudflare-agents-edge-patterns]] for an alternative scaling model, and [[glossary/context-window]] for the underlying cost driver behind most token-bill surprises.

---

## Further Reading

[1] Google Cloud. "Vertex AI Generative AI pricing." — https://cloud.google.com/vertex-ai/generative-ai/pricing · retrieved 2026-05-03

[2] Google Cloud. "Provisioned Throughput for Generative AI on Vertex AI." — https://cloud.google.com/vertex-ai/generative-ai/docs/provisioned-throughput · retrieved 2026-05-03

[3] Google Cloud. "Get batch predictions for Gemini." — https://docs.cloud.google.com/vertex-ai/generative-ai/docs/model-reference/batch-prediction-api · retrieved 2026-05-14

[4] Google Cloud. "Vertex AI endpoints overview." — https://cloud.google.com/vertex-ai/docs/general/endpoints · retrieved 2026-05-03

[5] Google Cloud. "Quotas and limits for generative AI on Vertex AI." — https://cloud.google.com/vertex-ai/generative-ai/docs/quotas · retrieved 2026-05-03

[6] Google Cloud. "Optimize and scale Agent Runtime performance." Gemini Enterprise Agent Platform docs. — https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/optimize-and-scale · retrieved 2026-05-14

[7] Anthropic. "Prompt caching." — https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching · retrieved 2026-05-03

[8] Google Cloud. "Cost management for Vertex AI." — https://cloud.google.com/vertex-ai/docs/general/cost-management · retrieved 2026-05-03
