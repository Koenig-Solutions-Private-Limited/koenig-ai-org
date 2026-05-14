---
chapter_num: 7
title: "Scale and Cost: Throughput, Quotas, Autoscaling, and Cost Attribution"
course_slug: gemini-enterprise-agents
prerequisites_chapters: [1, 2, 3, 4, 5, 6]
duration_min: 45
reading_time_min: 22
date: 2026-05-03
author: content-author
agent_drafted_by: course-author
content_type: chapter
chapter: 7
parent_course: gemini-enterprise-agents
ticket: KOEA-25
status: g3-passed
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
  - https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations
  - https://cloud.google.com/vertex-ai/generative-ai/docs/quotas
  - https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/optimize-and-scale
  - https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
  - https://cloud.google.com/resource-manager/docs/labels-overview
---

# Scale and Cost: Throughput, Quotas, Autoscaling, and Cost Attribution

A multi-agent system on Gemini Enterprise Agent Platform (GEAP) that costs $200/month at 1,000 invocations a day will not cost $20,000/month at 100,000 invocations a day — it will cost more, because the cost curve includes super-linear terms (recursive sub-agent loops, context-window growth, retry storms) that only surface at scale. This chapter, the last in the course, makes those terms visible and gives you the five levers — Provisioned Throughput, regional vs global endpoints, batch prediction, quotas, and autoscaling — to keep production economics defensible. As of May 2026, Vertex AI prices Gemini 3.1 Pro at $2.00 per 1M input tokens and $8.00 per 1M output tokens on-demand; Provisioned Throughput is sold in 100-token-per-second units. [1]

## Key facts

1. Provisioned Throughput is sold in committed units of 100 tokens/second of generation; one unit is roughly $35,000/month for Gemini 3.1 Pro at the time of writing [2]
2. On-demand pricing for Gemini 3.1 Pro: $2.00 per 1M input tokens, $8.00 per 1M output tokens (May 2026) [1]
3. Gemini 3.1 Flash is priced at $0.15 per 1M input / $0.60 per 1M output — roughly 13× cheaper than Pro [1]
4. Batch prediction discounts the per-token rate by 50% with a 24-hour SLA on completion [3]
5. Vertex AI exposes Google and partner generative models through regional endpoints and a global endpoint; do not use the global endpoint when you need to control the ML-processing region [4]
6. Generative AI quotas are enforced by project, region, model, and capability; raise them through the quota workflow with a documented capacity plan [5]
7. Agent Runtime autoscales between 0 and `max_replicas`; pre-warmed instances reduce first-request latency while scale-to-zero saves idle cost [6]
8. Prompt caching can materially reduce repeated-prefix cost on multi-turn and multi-agent workloads; read the provider-specific caching rules before designing sub-agent handoffs [7]

---

## The unit economics that actually matter

Three numbers should sit on the wall of every team running agents in production: cost-per-invocation, cost-per-resolved-task, and cost-per-active-user-month. Cost-per-invocation is what your bill divided by invocation count gives you. Cost-per-resolved-task corrects for retries, handoffs, and abandoned conversations — the ratio of bill to *useful* outcomes. Cost-per-active-user-month is the procurement-conversation number; everything else is engineering hygiene.

Use this as illustrative arithmetic, not a Koenig benchmark: a three-agent invoice pipeline running 2,000 invoices/day, with Gemini Pro for the orchestrator and Gemini Flash for two sub-agents. If the orchestrator uses 3,000 input tokens and 500 output tokens while the Flash sub-agents use a combined 8,400 input tokens and 1,400 output tokens, the published on-demand prices in source [1] put the mixed-model path near $0.012 per invoice, or about $726/month. Rebuilding the same token shape with Pro everywhere lands near $0.038 per invoice, or about $2,280/month. Same traffic model, about 3.1x more expensive. Model selection is the single largest lever, and the next four sections all bow to it.

<RunPromptCell
  model="gemini-pro-latest"
  prompt="Build a cost-per-invoice estimate for this Gemini Enterprise Agent Platform workload. Traffic: 2,000 invoices/day, 30 days/month. Orchestrator uses Gemini Pro for 3,000 input tokens and 500 output tokens per invoice. Two sub-agents use Gemini Flash for a combined 8,400 input tokens and 1,400 output tokens per invoice. Use these prices: Pro $2.00/M input and $8.00/M output; Flash $0.15/M input and $0.60/M output. Show per-invoice cost, monthly cost, and what changes if all three steps use Pro."
  expectedOutput="The model should compute Pro orchestrator cost plus Flash sub-agent cost, divide by invoice count, and show the all-Pro comparison. Expected range: mixed-model cost around $0.012 per invoice from the stated token split; all-Pro cost around $0.038 per invoice. The monthly estimate should multiply by 60,000 invoices/month."
/>

<KnowledgeCheck
  question="Why is cost-per-resolved-task more useful than cost-per-invocation for an agent workflow?"
  options={[
    "It ignores token costs so the finance team can focus on subscriptions",
    "It includes retries, handoffs, and abandoned work instead of counting every model call as equally valuable",
    "It only applies to batch prediction jobs",
    "It is the same metric as requests per minute"
  ]}
  correctIdx={1}
  explanation="Cost-per-invocation is easy to calculate but hides whether the invocation produced a useful outcome. Cost-per-resolved-task includes retries, handoffs, and failed or abandoned runs, which is the number a production owner can actually optimize."
/>

---

## Lever 1: Provisioned Throughput vs on-demand

Provisioned Throughput (PT) is a capacity commitment. You pay for a guaranteed N tokens-per-second of generation throughput on a specific model in a specific region, and your traffic up to that limit bypasses the on-demand queue entirely. [2] Above the limit, requests either queue, fail, or burst into on-demand pricing depending on your overflow policy.

The on-demand vs PT decision reduces to four questions:

**What is your steady-state qps?** If your p50 traffic is 0.5 invocations per second and p95 is 4, on-demand will absorb both — you are not large enough for PT to win. PT becomes interesting when steady-state generation is above ~50 tokens/second sustained; below that, the commitment minimum exceeds your usage.

**How spiky is your traffic?** A workload that runs 30 minutes a day and idles otherwise is wrong for PT — you would pay for 24 hours of capacity to use 0.5 hours. Save PT for workloads that run continuously: customer-facing chat, real-time fraud screening, internal tools used across all timezones.

**What is your latency floor?** PT gives you reserved capacity instead of relying entirely on shared on-demand capacity. If your p99 misses are driven by capacity contention rather than tool latency, PT is the most direct fix; if p99 is dominated by slow tools or oversized prompts, PT will not solve the root cause.

**Is the workload approval-blocked on cost predictability?** Procurement and finance often dislike usage-based billing because they cannot forecast it. PT is a fixed monthly line item — sometimes the deciding factor for getting an agent project approved at all, even when the math says on-demand is cheaper.

A quick worked example. A team running 25 generation-tokens/second average, 80 tokens/second p95, on Gemini Pro. On-demand output cost at $8/M output tokens is 25 x 86,400 x 30 x $8 / 1,000,000, or about $518/month. One 100-token/second PT unit is a capacity reservation, so the purchase decision is not "which line item is cheaper at average load?" It is "do we need reserved capacity, predictable approval, or p99 protection enough to justify the commitment?" Most teams will stay on-demand until the reliability or procurement constraint is stronger than the raw token-price math.

---

## Lever 2: Regional vs global endpoints

Vertex AI exposes two endpoint flavors. The **global endpoint** uses the `global` location and can improve availability while reducing resource-exhausted errors. Google warns not to use it when you have ML-processing location requirements, because you cannot control or know which region handles a given request. [4]

The **regional endpoint** sends requests to the region you specify, such as `europe-west4` or `us-central1`. You give up global capacity smoothing in exchange for an auditable processing-location decision.

The decision rules:

| Constraint | Endpoint |
|---|---|
| ML processing must stay in a controlled geography | Regional or multi-region endpoint supported by the model |
| Multi-region failover desired | Global |
| Lowest possible latency for one geography | Regional, co-located with caller |
| Highest possible throughput | Global (capacity is pooled) |
| Compliance audit demands provable residency | Regional |

A subtle trap: if your agent is deployed regionally for residency but you call the global endpoint, you have made the runtime regional while leaving inference processing uncontrolled. [[gemini-enterprise-agents/05-enterprise-security]] covers the perimeter side; the operational test is to record the configured Vertex location for every model call and reject deploys that mix a residency-sensitive agent with `global`.

<KnowledgeCheck
  question="A regulated workload must keep model processing in an approved geography. Which endpoint choice is the safest default?"
  options={[
    "Global, because it has better availability",
    "Regional or supported multi-region, because the global endpoint does not let you control the processing region",
    "Any endpoint, because data at rest and ML processing are the same control",
    "The cheapest endpoint listed on the pricing page"
  ]}
  correctIdx={1}
  explanation="Google's endpoint guidance separates availability from processing-location control. Use the regional or supported multi-region location that matches the residency requirement; reserve global for workloads where availability is the priority and processing location is not constrained."
/>

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

Generative AI quotas are not one universal number. They vary by model, region, request type, and project, and Google documents separate quota dimensions for requests, tokens, batch prediction, tuning, and Live API usage. [5] Treat the quota page and your project's Quotas console as the source of truth, then set stricter application-level limits before production traffic arrives.

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

Illustrative incident arithmetic: agent A transfers to agent B, B transfers back to A, and no fail-loud condition stops the recursion. If the loop emits 90,000 output tokens/minute for 14 minutes on a model priced at $8/M output tokens, output spend alone is 90,000 x 14 x $8 / 1,000,000 = $10.08. If each loop also resends a large prompt, fans out to tools, and retries on throttling, the incident total can climb quickly. The fix is still cheap: `concurrent_invocations: 1` per-agent limits, max handoff depth on the orchestrator, and an alert that fires on repeated agent pairs.

<RunPromptCell
  model="gemini-pro-latest"
  prompt="Act as the on-call engineer for a Gemini Enterprise Agent Platform deployment. A loop detector reports repeated transfers between invoice_orchestrator and vendor_lookup_agent. Current metrics: 40 invocations/minute, 22,000 input tokens/invocation, 2,500 output tokens/invocation, model price $2/M input and $8/M output. Estimate spend per minute, identify the first two controls to apply, and draft a 4-line incident note for finance."
  expectedOutput="The model should calculate about $2.56/minute: input 40*22000*$2/1e6 = $1.76, output 40*2500*$8/1e6 = $0.80. It should recommend throttling or pausing the affected agents plus adding max handoff depth / repeated-pair loop detection. The finance note should say the number is an estimate, name the affected agents, state the containment action, and promise a final billing-export reconciliation."
/>

<KnowledgeCheck
  question="A loop detector sees A -> B -> A repeated six times in one conversation. Which control should fire first?"
  options={[
    "Raise project quota so the loop can finish faster",
    "Switch the model to a larger context window",
    "Stop or throttle the agent pair and mark the run failed-loud",
    "Move the workload to batch prediction"
  ]}
  correctIdx={2}
  explanation="Runaway loops are reliability and cost incidents. The immediate control is containment: stop, throttle, or fail-loud before raising quotas or changing models."
/>

---

## Lever 5: Autoscaling Agent Runtime

Agent Runtime autoscales between zero and a configured maximum. The behavior:

- **Scale from zero:** saves idle cost but makes the first request after an idle period pay startup latency. [6]
- **Pre-warmed instances:** reduce first-request latency by keeping `min_replicas >= 1`.
- **Scale-up:** new replicas spin up when concurrent invocations exceed `target_concurrency_per_replica`.
- **Scale-down:** replicas terminate after `idle_timeout_seconds` of no traffic.

The cost-vs-latency tradeoff is in the `min_replicas` and `idle_timeout` knobs. Setting `min_replicas: 0` saves money during quiet hours but every first-request-after-idle pays startup latency. Setting `min_replicas: 3, idle_timeout: 3600` keeps three warm replicas always, which adds a fixed runtime line item in exchange for a tighter p99.

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

## Deploying Preview Endpoints: The Lifecycle Checklist

As of May 2026, many capable models appear first as preview or experimental model IDs. While tempting for their reasoning quality, they introduce lifecycle risk. Use this checklist before deploying any `preview` or `experimental` model ID to production:

1. **Launch Stage Verification**: Is this `PREVIEW`, `BETA`, or `GA`? GEAP features may only be partially supported on preview endpoints.
2. **Deprecation Window**: Check the [Gemini API changelog](https://ai.google.dev/gemini-api/docs/changelog) for the sunset date of the specific model ID. Preview IDs often expire in 90 days.
3. **Quota Differential**: Preview endpoints often have significantly lower RPM/TPM quotas than GA models. Ensure your capacity plan accounts for this ceiling.
4. **Automated Fallback**: Implement a stable fallback in your ADK configuration. If the preview call fails with a 429 or 503, the orchestrator should automatically retry against a GA model approved for the same task class.
5. **Per-Model Logging**: Use GEAP labels to log latency and cost specifically for the preview model. Do not aggregate it with stable model metrics.
6. **Changelog Review**: Review the Google Cloud AI release notes weekly. Preview models can receive "silent" updates that change output structure or reasoning quality.

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

Google Cloud labels are forwarded to the billing system and can be used in billing reports and BigQuery billing exports. [8] In the BigQuery billing export, you can group spend by label combinations and produce a per-team chargeback report monthly:

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

A team without a `team` label cannot be charged back reliably, which makes the label policy a useful governance lever. Make it a required field in the deploy template, and route untagged spend to a visible "unallocated AI" report until the owner fixes the deployment metadata.

**The contrarian angle for this chapter:** Most teams optimize cost in the wrong direction. They obsess over per-token pricing differences (Gemini Flash vs Pro, Claude Sonnet vs Haiku), which matter, but they miss larger savings from killing unnecessary invocations entirely. A retry policy with three retries on a flaky tool turns one user request into four model calls. A sub-agent that re-reads the entire conversation history every turn doubles your input tokens. An "always summarize" step before tool routing adds a model call to every interaction. Audit your agent's *call graph* before you negotiate pricing. Illustrative arithmetic: if a request costs $0.10 and two redundant calls account for $0.062 of that cost, deleting them drops cost-per-invocation by 62% before changing a single model. Pricing optimization is the second move; eliminating call-graph waste is the first.

<KnowledgeCheck
  question="Your billing export shows 18% of Vertex AI spend has no `team` label. What is the best governance response?"
  options={[
    "Ignore it because labels are optional metadata",
    "Require the deploy template to include `team`, `cost_center`, and `environment`, then report unallocated spend until owners fix missing labels",
    "Delete all unlabeled resources immediately",
    "Move the workload to a global endpoint"
  ]}
  correctIdx={1}
  explanation="Labels are the practical join key for cost attribution. The durable fix is to make them required at deployment and visible in finance reporting, not to rely on manual cleanup after the invoice arrives."
/>

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

Illustrative comparison: on one invoice-extraction prompt, assume Gemini Pro emits 2,100 output tokens at $8/M output tokens, or $0.0168 per invoice, while Claude Sonnet emits 1,400 output tokens at $15/M output tokens, or $0.0210 per invoice. The higher per-token price is partly offset by a shorter answer, but Gemini still wins this narrow output-cost example by 20%. On a different workload, a higher-priced model can still win if it needs fewer retries or fewer tool calls. The rule: benchmark on your real workload before negotiating commercial terms. Vendor pricing pages are insufficient ground truth.

<RunPromptCell
  model="gemini-pro-latest"
  prompt="Compare two vendors on cost-per-resolved-task, not list price. Vendor A costs $8/M output tokens and averages 2,100 output tokens per successful invoice extraction with a 90% first-pass success rate. Vendor B costs $15/M output tokens and averages 1,400 output tokens per successful extraction with a 97% first-pass success rate. Ignore input tokens for this narrow exercise. Compute raw output cost, retry-adjusted cost using 1/success_rate, and which vendor is cheaper on this workload."
  expectedOutput="The model should compute Vendor A raw output cost $0.0168 and retry-adjusted cost about $0.0187. Vendor B raw output cost $0.0210 and retry-adjusted cost about $0.0216. Vendor A remains cheaper on this narrow output-only workload, but the margin shrinks once retries are included."
/>

<KnowledgeCheck
  question="In a vendor cost benchmark, why is list price alone insufficient?"
  options={[
    "Because vendors never publish prices",
    "Because total cost also depends on token efficiency, tool-call efficiency, retry rate, and whether the answer satisfies the task",
    "Because only output tokens are billed",
    "Because batch prediction makes all models free"
  ]}
  correctIdx={1}
  explanation="The same task can use different numbers of input tokens, output tokens, tool calls, and retries across models. Cost-per-task is the decision metric; list price is only one input."
/>

---

## What's next

You have completed the seven-chapter course. Combine what you have built across all chapters into the capstone described in the [[gemini-enterprise-agents/outline]] — a four-agent enterprise document processing system with security, observability, and runbooks ready for a CISO sign-off and a finance review.

For deeper reading on adjacent topics, see [[course/claude-tool-use-from-zero]] for prompt-caching patterns that translate directly to GEAP cost optimization, [[blog/cloudflare-agents-week-2026-explained|Cloudflare Agents]] for an alternative scaling model, and [[glossary/context-window]] for the underlying cost driver behind most token-bill surprises.

---

## Further Reading

[1] Google Cloud. "Vertex AI Generative AI pricing." — https://cloud.google.com/vertex-ai/generative-ai/pricing · retrieved 2026-05-14

[2] Google Cloud. "Provisioned Throughput for Generative AI on Vertex AI." — https://cloud.google.com/vertex-ai/generative-ai/docs/provisioned-throughput · retrieved 2026-05-14

[3] Google Cloud. "Get batch predictions for Gemini." — https://docs.cloud.google.com/vertex-ai/generative-ai/docs/model-reference/batch-prediction-api · retrieved 2026-05-14

[4] Google Cloud. "Deployments and endpoints." Generative AI on Vertex AI. — https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations · retrieved 2026-05-14

[5] Google Cloud. "Quotas and limits for generative AI on Vertex AI." — https://cloud.google.com/vertex-ai/generative-ai/docs/quotas · retrieved 2026-05-14

[6] Google Cloud. "Optimize and scale Agent Runtime performance." Gemini Enterprise Agent Platform docs. — https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale/runtime/optimize-and-scale · retrieved 2026-05-14

[7] Anthropic. "Prompt caching." — https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching · retrieved 2026-05-14

[8] Google Cloud. "Labels overview." Resource Manager documentation. — https://cloud.google.com/resource-manager/docs/labels-overview · retrieved 2026-05-14
