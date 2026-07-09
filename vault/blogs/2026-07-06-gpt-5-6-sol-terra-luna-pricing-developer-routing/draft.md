---
date: 2026-07-09
author: vardaan-koenig
ticket: KOEA-10181
vendor_tag: openai
content_type: article
status: awaiting-g0
reading_time_min: 6
primary_query: "GPT-5.6 API pricing"
contrarian_angle: "Sol Ultra exists as an API parameter with no published pricing. OpenAI is reserving the price anchor — meaning the model that tops the leaderboard has undefined cost. Teams budgeting around GPT-5.6 today are building on a price-unstable foundation."
sources:
  - https://openai.com/index/previewing-gpt-5-6-sol/
  - https://help.openai.com/en/articles/20001325-a-preview-of-gpt-56-sol-terra-and-luna
  - https://techcrunch.com/2026/06/26/openai-limits-gpt-5-6-rollout-after-government-request-says-restrictions-shouldnt-be-the-norm/
  - https://lushbinary.com/blog/gpt-5-6-pricing-cost-optimization-sol-terra-luna
  - https://www.finout.io/blog/gpt-5.6-pricing-2026-sol-terra-and-luna-tiers-explained
  - https://community.openai.com/t/introducing-gpt-5-6-series-sol-terra-and-luna-coming-july-9/1384931
  - https://github.com/openai/codex/releases
---

# GPT-5.6 Sol, Terra, Luna pricing decoded — and why Sol Ultra should worry you

GPT-5.6 is OpenAI's three-tier frontier model family — Sol, Terra, and Luna — currently in limited preview as of July 2026, priced from $1 to $5 per million input tokens depending on capability tier. It replaces the single-SKU model selection developers used with GPT-5.5: Sol targets frontier agentic reasoning, Terra is the new production workhorse, and Luna handles high-volume cost-sensitive workloads — and one tier has no published price at all.

## Key Facts

1. **Sol:** $5 input / $30 output per million tokens — flagship tier for frontier reasoning, complex coding, and long-horizon agentic work [1][2]
2. **Terra:** $2.50 input / $15 output per million tokens — balanced everyday model with GPT-5.5-competitive performance at 2× lower cost [2][6]
3. **Luna:** $1 input / $6 output per million tokens — fastest and most affordable tier for high-throughput, cost-sensitive use cases [2][6]
4. **Cache-write billing change:** Cache writes are now billed at 1.25× the model's uncached input rate — previously free. Cache reads keep the existing 90% discount [2]
5. **Sol Ultra:** Exists as an API parameter (`ultra` mode, activating subagent orchestration). No published price [1]
6. **Competitive context:** Claude Fable 5 runs at $10/$50 per million tokens (input/output) — 2× Sol's input cost [4]. Gemini 3.1 Pro sits at $2.00/$12 — under Terra's input rate [5]
7. **Access status:** GPT-5.6 is in limited preview, available only to approved API and Codex partners. No public waitlist, no ChatGPT access, no GA date announced [2][6]

## The Tier Selection Framework

OpenAI is being unusually explicit about routing with this release. The preview documentation describes Sol as designed for "frontier reasoning and long-horizon agentic work," Terra as "a balanced everyday model with GPT-5.5-competitive performance at 2× lower cost," and Luna as "the fastest, most affordable member of the family" [1][6]. That is a routing signal encoded in the product definition — not just marketing.

| Workload type | Recommended tier | Reason |
|---|---|---|
| Hard codebase analysis, multi-step debugging, adversarial tasks | **Sol** | Needs `max` reasoning effort and deep deliberation; cost is justified by single correct output |
| Standard business workflows, API integrations, document processing | **Terra** | GPT-5.5-equivalent at half the price; correct default for most production pipelines |
| Classification, summarisation, high-volume data labelling, cheap verification loops | **Luna** | 5× cheaper than Sol; correctness can be verified downstream, so cost is the primary constraint |
| Long-horizon multi-agent orchestration | **Sol Ultra** | Uses subagents to parallelise complex work — but **no published price** (see below) |

The practical rule: default to Terra, escalate to Sol only for tasks where an incorrect answer has measurable downstream cost, and use Luna where you can cheaply verify the output. Do not route anything to Sol Ultra yet.

## The Cache-Write Billing Change: What It Actually Costs You

This is the most underreported change in GPT-5.6. Cache writes are now billed at 1.25× the model's uncached input rate. Previously, writing to the prompt cache was free — you only paid on reads, which still receive a 90% discount [2].

**Concrete example:** an application using Terra ($2.50/MTok input) with a 10,000-token system prompt cached on every cold start:

- **Before GPT-5.6:** $0 for the cache write, then $0.025 per cached read (10k tokens × $2.50/MTok × 10% of uncached rate)
- **After GPT-5.6:** $0.03125 per cache write (10k × $2.50/MTok × 1.25 / 1,000,000)

If your application cold-starts 1,000 times per day, that is $31.25/day in new cache-write costs — roughly $940/month at Terra rates, and $2,500/month at Sol rates. For teams who built their GPT-5.5 cost models assuming cache writes were free, this is a material budget change.

The mitigation: extend cache lifetime. GPT-5.6 introduces a 30-minute minimum cache life and explicit cache breakpoints [2], so a single write can be amortised across more reads before expiry. Audit your cold-start frequency and session length before migrating.

## Competitive Routing: Where GPT-5.6 Fits Against Claude Fable 5 and Gemini 3.1 Pro

| Model | Input / Output ($/MTok) | Best for |
|---|---|---|
| GPT-5.6 Sol | $5 / $30 | Agentic, reasoning-heavy tasks; lower cost than Fable 5 at comparable frontier claims |
| GPT-5.6 Terra | $2.50 / $15 | Production default; sits between Gemini 3.1 Pro and Sol on price |
| GPT-5.6 Luna | $1 / $6 | High-volume; cheapest OpenAI frontier option |
| Claude Fable 5 | $10 / $50 | Top-tier reasoning; 2× Sol input — justified for regulated or compliance-sensitive workloads [4] |
| Gemini 3.1 Pro | $2.00 / $12 | Under Terra on input price; strong fit for GCP-native pipelines [5] |

For teams already on OpenAI's API, Terra is the competitive answer to Gemini 3.1 Pro — similar price band, no provider switch required. For teams choosing between Sol and Claude Fable 5, capability tradeoffs will matter more than the 2× price gap once independent benchmarks appear. Until then, Sol is the lower-cost bet at comparable capability claims.

## The Sol Ultra Problem

Sol's preview announcement describes an `ultra` mode that uses subagents to accelerate complex, multi-step work [1]. It surfaces as an API parameter in the Sol spec. It has no published price.

This is a planning risk for any team sizing infrastructure costs now. If your pipeline will eventually require Sol Ultra for long-horizon agentic tasks, you are designing around a cost anchor that OpenAI has not published. OpenAI is reserving the right to set the price for the model tier that sits above the leaderboard — and teams who commit infrastructure design to Sol Ultra before that price lands have no floor to budget against.

The conservative design posture: scope your budgets to Sol ($5/$30) and treat Sol Ultra as out-of-scope until pricing is announced. Do not architect workflows that require it for correctness unless you can absorb an unknown multiplier.

## Try It: Route a Task to the Right GPT-5.6 Tier

<RunPromptCell
  model="gpt-5.6-terra"
  prompt="You are a model routing assistant. Given a task description, output which GPT-5.6 tier — Sol, Terra, or Luna — to route to, and a one-sentence reason. Do not recommend Sol Ultra.\n\nTask: Classify 50,000 customer support tickets by intent category using a fixed 8-category taxonomy. Accuracy target: >85%. Each ticket is 50–200 words.\n\nTier:"
  expectedOutput="Luna. This is a high-volume classification task with a verifiable accuracy target — once Luna hits 85% on a held-out set, cost becomes the primary constraint, and Luna's $1/MTok input rate is 5× cheaper than Sol."
/>

## What Changes If You Are Already Using GPT-5.5

Three checks before migrating:

1. **Cache-write billing:** Audit workflows that cache frequently — the 1.25× write rate is a new cost GPT-5.5 budgets did not include.
2. **Access gating:** Confirm preview access before blocking roadmap work on a migration that has not been granted.
3. **Sol Ultra unknowns:** Hold off on cost commitments for top-tier agentic workloads until OpenAI publishes Sol Ultra pricing.

## Knowledge Check

<KnowledgeCheck
  question="Your application writes a 10,000-token system prompt to the GPT-5.6 Terra cache on every cold start and reads it back 20 times per session. Compared to GPT-5.5 prompt caching (where writes were free), how does the new cache-write billing at 1.25× input rate change your per-session economics?"
  answers={[
    "No change — cache reads are still discounted 90%, so the net cost per session decreases.",
    "The per-session cost increases because you now pay 1.25× Terra's input rate for the initial write, in addition to the discounted read costs.",
    "The per-session cost decreases because the 30-minute minimum cache life automatically amortises writes across all sessions.",
    "Cache-write billing only applies to Sol and Sol Ultra — Terra cache writes remain free."
  ]}
  correct={1}
/>

## The Bottom Line

GPT-5.6's three-tier structure makes model routing explicit for the first time at OpenAI's frontier tier. Terra is the default move for most production workloads — similar price to Gemini 3.1 Pro, no provider switch required. Sol is justified where an incorrect answer has measurable downstream cost. Luna is the right call for high-volume, verifiable tasks.

The cache-write billing change is the sleeper cost: audit cold-start cache patterns before migrating. Treat Sol Ultra as a planning unknown until pricing appears.

Want a structured framework for picking the right frontier model? The Koenig AI Academy's [Picking a Frontier Model in 2026 Q2](https://academy.kspl.tech/courses/picking-a-frontier-model-2026-q2) course covers the full decision matrix, including cost modelling for agentic pipelines.

---

## References

[1] OpenAI — "Previewing GPT-5.6 Sol" — https://openai.com/index/previewing-gpt-5-6-sol/ (retrieved 2026-07-09)

[2] OpenAI Help Center — "A preview of GPT-5.6: Sol, Terra, and Luna" — https://help.openai.com/en/articles/20001325-a-preview-of-gpt-56-sol-terra-and-luna (retrieved 2026-07-09)

[3] TechCrunch — "OpenAI limits GPT-5.6 rollout after government request" — https://techcrunch.com/2026/06/26/openai-limits-gpt-5-6-rollout-after-government-request-says-restrictions-shouldnt-be-the-norm/ (retrieved 2026-07-03)

[4] Lush Binary — "GPT-5.6 pricing and cost optimization: Sol, Terra, Luna" — https://lushbinary.com/blog/gpt-5-6-pricing-cost-optimization-sol-terra-luna (retrieved 2026-07-03)

[5] Finout — "GPT-5.6 pricing 2026: Sol, Terra and Luna tiers explained" — https://www.finout.io/blog/gpt-5.6-pricing-2026-sol-terra-and-luna-tiers-explained (retrieved 2026-07-03)

[6] OpenAI Community — "Introducing GPT-5.6 series: Sol, Terra, and Luna coming July 9" — https://community.openai.com/t/introducing-gpt-5-6-series-sol-terra-and-luna-coming-july-9/1384931 (retrieved 2026-07-09)
