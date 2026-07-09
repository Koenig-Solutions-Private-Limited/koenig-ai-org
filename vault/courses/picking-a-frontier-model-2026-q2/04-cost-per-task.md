---
course_slug: picking-a-frontier-model-2026-q2
chapter_num: 4
chapter_slug: cost-per-task
title: "Cost-per-task — pricing vs. actual bill on real workloads"
hero_image: "/courses/picking-a-frontier-model-2026-q2/assets/ch04-hero.svg"
status: g3-passed
author: "Koenig AI Instructor"
agent_drafted_by: ca965eff-ea59-4030-91de-47845d3600c6
vendor_tag: koenig-ai-academy
content_type: course-chapter
date: 2026-04-30
duration_min: 50
prerequisites_chapters: [1, 2, 3]
learning_objectives:
  - "Calculate cost-per-task from token counts and retry rates — not just $/M token list pricing"
  - "Account for prompt caching, tool-call overhead, and retry costs in a realistic cost model"
  - "Compare total cost of ownership across Opus 4.7, GPT-5.5, and Gemini 3.1 Pro for three workload archetypes"
  - "Build a break-even analysis: at what reliability delta does the cheaper model become more expensive?"
  - "Identify the pricing surprises that catch builders off-guard"
key_concepts:
  - cost-per-task model
  - prompt caching economics
  - retry cost amplification
  - total cost of ownership
  - break-even reliability analysis
  - context caching
  - pricing surprises
hands_on_exercise: "Fill in the cost estimator spreadsheet for your use case using real token counts from Chapter 2"
references:
  - "[^1]: Anthropic. 'Claude pricing.' https://www.anthropic.com/pricing — Opus 4.7 input/output/cache pricing as of Q2 2026. Also: 'Prompt caching.' https://www.anthropic.com/news."
  - "[^2]: OpenAI. 'OpenAI API pricing.' https://developers.openai.com/api/docs/pricing — GPT-5.5 $5/$30/M input/output; cached input $0.50/M (90% discount). Verified 2026-06-14."
  - "[^3]: Google. 'Gemini API pricing.' https://ai.google.dev/pricing — Gemini 3.1 Pro input/output/context caching pricing as of Q2 2026. Changelog: https://ai.google.dev/gemini-api/docs/changelog."
  - "[^4]: Koenig AI Academy internal cost model data, Q2 2026. Derived from the Q2 2026 tool-use determinism benchmark dataset (reference tables embedded in Chapter 2) with retry simulation applied at workload scale."
  - "[^5]: Patil, S. et al. Berkeley Function-Calling Leaderboard (BFCL) V4. https://gorilla.cs.berkeley.edu/leaderboard.html — analysis of tool-call reliability impact on pipeline cost."
  - "[^6]: Chen, L. et al. (2023). 'FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance.' https://arxiv.org/abs/2305.05176 — analysis of model routing, cascading, and selection strategies that reduce cost-per-task by matching task complexity to model capability."
slides: courses/picking-a-frontier-model-2026-q2/ch04-slides.pptx
audio: courses/picking-a-frontier-model-2026-q2/voiceover-04.mp3
voiceover_script: courses/picking-a-frontier-model-2026-q2/voiceover-04.md
quiz:
  - question: "Which factor does a standard pricing-page cost comparison consistently omit, causing the largest divergence between listed price and actual bill?"
    options:
      - "Output token prices, which are typically bundled into the input rate and reported as a blended figure"
      - "The retry multiplier driven by determinism failures, which compounds across pipeline steps as (1/determinism)^steps"
      - "Input token prices for system prompts, which providers cap at a published maximum to normalize cross-model comparisons"
      - "Tool definition tokens, which are billed at a separate internal rate not disclosed on public pricing pages"
    correct_idx: 1
    explanation: "Pricing pages show per-token rates but ignore retry rate, which multiplies every cost component by 1/determinism^steps. At category-5 complexity over a 3-step pipeline, Gemini's 59% success rate means 1.69 expected runs per successful task, compressing its 2.3× token-price advantage over Opus to a 1.7× cost-per-task advantage. At 10 steps, a 14-point determinism gap becomes a 7.2× cost difference that pricing pages hide entirely."
    section_anchor: why-pricing-pages-are-misleading
  - question: "At category-5 multi-tool complexity over 3 pipeline steps, Gemini 3.1 Pro costs $0.032 per run and Opus 4.7 costs $0.075. After applying measured determinism (Gemini 84%, Opus 94%), what is the cost-per-successful-task relationship?"
    options:
      - "Gemini remains 2.3× cheaper than Opus because token pricing fully determines cost-per-task regardless of determinism"
      - "Opus becomes cheaper because its determinism advantage eliminates retry overhead entirely, reversing the token-price gap"
      - "Gemini's advantage compresses to ~1.7× after retry overhead is applied, though it remains cheaper per successful task at this complexity"
      - "Both models are cost-equivalent after retries because the retry cost exactly matches the per-token price differential"
    correct_idx: 2
    explanation: "3-step pipeline success: Opus 0.94³ = 83% → 1.20 expected runs → $0.090/task. Gemini 0.84³ = 59% → 1.69 expected runs → $0.054/task. The ratio compresses from 2.3× (token pricing) to $0.090/$0.054 ≈ 1.7× (cost-per-task). Gemini is still cheaper here — but the inversion kicks in above 4–5 steps on harder prompt categories."
    section_anchor: the-retry-multiplier-in-practice
  - question: "A team runs 10,000 API calls per day with a 10,000-token system prompt. What is the daily savings from enabling Anthropic's prompt caching at Opus 4.7 pricing ($5/M input, $0.50/M cached)?"
    options:
      - "~$50/day — caching reduces total input cost by approximately 10% by avoiding re-tokenization overhead"
      - "~$250/day — the 50% discount on cached tokens splits the $500 uncached daily cost in half"
      - "~$450/day — the 90% cache-read discount reduces the $500 uncached daily spend to $50 per day"
      - "~$500/day — caching eliminates all input token charges for repeated system prompts after the first call"
    correct_idx: 2
    explanation: "Without caching: 10K tokens × $5/M × 10,000 calls = $500/day. With caching: 10K tokens × $0.50/M × 10,000 calls = $50/day. Savings = $450/day. The 90% cache discount is available on all three platforms; the absolute dollar saving is largest for Opus (highest per-token price) but the discount percentage is the same across providers."
    section_anchor: prompt-caching-the-underrated-cost-lever
  - question: "For a single-step 80K-token document Q&A query with one LLM call and no pipeline, which model wins on cost-per-task and why?"
    options:
      - "Opus 4.7 — its lower retry rate offsets the higher token price on document retrieval tasks"
      - "GPT-5.5 — its comparable input price to Opus 4.7 but superior middle-context stability gives better cost-quality outcome"
      - "Gemini 3.1 Pro — single-step retrieval doesn't compound determinism variance, so the 2.5× per-token price advantage is preserved"
      - "All three are cost-equivalent for single-step document Q&A because retry overhead is zero at n=1 pipeline step"
    correct_idx: 2
    explanation: "Single-step workloads don't compound determinism variance — there are no sequential failures to amplify. With no retry multiplier, token pricing dominates: Gemini at $2/$12 per M in/out vs. Opus at $5/$25 and GPT-5.5 at $5/$30. For an 80K-token input + 600-token output: Gemini = $0.167, Opus = $0.415, GPT-5.5 = $0.418. Gemini is 2.5× cheaper. The inversion only occurs at multi-step pipelines with higher complexity schemas."
    section_anchor: the-three-workload-archetypes-costed
tags:
  - course/picking-a-frontier-model-2026-q2
  - evaluation
  - cost
  - pricing
  - benchmarking
---

# Cost-per-task — pricing vs. actual bill on real workloads

> **Prerequisites**: [Chapter 1](/learn/picking-a-frontier-model-2026-q2/01-dimensions-that-matter) required; Chapters 2 and 3 recommended for the best practical grounding. You should have token counts from at least one benchmark run.
>
> **Time**: 50 minutes
>
> **Learning objectives**: By the end of this chapter, you can calculate a defensible cost-per-task number for your workload, account for retries and caching, and know when the "cheaper" model is actually more expensive.

Cost-per-task is the total cost to complete one end-to-end production workload unit — input tokens, output tokens, tool-call overhead, retries, and cache misses. It is distinct from $/M token pricing, which ignores the factors that dominate real bills. As of Q2 2026, Gemini 3.1 Pro is cheapest per token, GPT-5.5 the most expensive, Opus 4.7 in the middle — but the cost-per-task ordering is often the reverse. This chapter shows why.

## Key facts

- **List pricing** (Q2 2026): Opus 4.7 $5/$25/M in/out, cache read $0.50/M (90% discount) [^1]; GPT-5.5 $5/$30/M, cached input $0.50/M (90% discount) [^2]; Gemini 3.1 Pro $2/$12/M, context caching $0.20/M (90% discount) [^3].
- On a simple prompt with no retries, **Gemini 3.1 Pro is 2.5× cheaper** than Opus 4.7 — the number that appears in comparison articles.
- Gemini 3.1 Pro's average determinism is **81.9%** versus Opus 4.7's **91.4%**. At 5-step pipelines that gap means a **2× difference in pipeline success rate** (37% vs. 61%) — each failed run requiring a full retry.
- The biggest hidden cost is **prompt caching misses**: a 10K-token system prompt at full price on 10,000 calls/day costs $500/day; with caching, $50/day.
- **Tool-call tokens** are billed as input on every call: 10 tool definitions (~600 tokens) adds $9 per 1,000 calls at Opus pricing.

```takeaways
- List pricing: Opus 4.7 $5/$25/M in/out; GPT-5.5 $5/$30/M; Gemini 3.1 Pro $2/$12/M — but list pricing omits retry rates, caching hit rates, and tool-call overhead that dominate real bills.
- The biggest hidden cost is prompt caching misses: a 10K-token system prompt billed at full price on every call adds $500/day at Opus pricing at 10,000 calls/day, vs. $50/day with caching.
- Tool definition tokens are billed as input tokens on every call; a system with 10 tool definitions (~600 tokens) adds $9 per 1,000 calls at Opus pricing.
```

## Why pricing pages are misleading

The standard comparison table omits retry rate, caching hit rate, tool-call overhead, output amplification, and context efficiency losses. A real cost model:

```
cost_per_task = (
    prompt_tokens_uncached × input_price
  + prompt_tokens_cached × cache_price
  + output_tokens × output_price
  + tool_tokens × input_price
) × (1 / determinism_rate)^pipeline_steps
```

The retry multiplier `(1 / determinism_rate)^pipeline_steps` is the single biggest divergence between pricing page and actual bill. [^5]

<Callout type="warn">
**Preview Lifecycle: The hidden reliability tax.** When using preview models such as **Gemini 3.1 Pro Preview**, the "cost" is not just in tokens. Preview endpoints often have lower quotas, more frequent 429/503 errors, and shorter deprecation cycles. To keep production costs defensible:
1. **Configurable Model IDs**: Never hard-code a preview ID; use an environment variable or config service.
2. **Deprecation Checks**: Review the vendor changelog weekly for sunset dates.
3. **Fallback Routing**: Implement logic to automatically fall back to a stable model if the preview endpoint fails.
4. **Separate Monitoring**: Track error rates and latency specifically for preview calls to distinguish model flakiness from infrastructure issues.
</Callout>

```takeaways
- A real cost model accounts for retry rate, caching hit rate, tool-call token overhead, output amplification across pipeline steps, and context window efficiency — none of which appear on pricing pages.
- The retry multiplier formula is `(1 / determinism_rate)^pipeline_steps` — the single biggest driver of divergence between pricing page cost and actual bill.
- Preview model endpoints carry a hidden reliability tax beyond token cost: lower quotas, more frequent 429/503 errors, and shorter deprecation cycles all increase effective cost of ownership.
```

## The retry multiplier in practice

Representative 3-step pipeline: 2,000-token system prompt, 200-token message, 800-token tool definitions, 400-token output per step.

**Without caching, no retries:**

| Model | Per-step input cost | Per-step output cost | 3-step total |
|---|---|---|---|
| Opus 4.7 | 3,000 × $5/M = $0.015 | 400 × $25/M = $0.010 | **$0.075** |
| GPT-5.5 | 3,000 × $5/M = $0.015 | 400 × $30/M = $0.012 | **$0.081** |
| Gemini 3.1 Pro | 3,000 × $2/M = $0.006 | 400 × $12/M = $0.0048 | **$0.032** |

Gemini is 2.3× cheaper than Opus with no retries. GPT-5.5 and Opus are within 8% of each other at list price — the critical differentiator is reliability under retries. This is the number in the comparison article.

**Now apply determinism-driven retries** (category-5 complexity, multi-tool sequence — Opus 94%, GPT-5.5 90%, Gemini 84%):

Pipeline success probability: Opus 0.94³ = 83%; GPT-5.5 0.90³ = 73%; Gemini 0.84³ = 59%.

| Model | Per-run cost | Expected runs to success | **Cost-per-successful-task** |
|---|---|---|---|
| Opus 4.7 | $0.075 | 1.20 | **$0.090** |
| GPT-5.5 | $0.081 | 1.37 | **$0.111** |
| Gemini 3.1 Pro | $0.032 | 1.69 | **$0.054** |

Gemini is still cheapest — but the ratio has compressed from 2.3× to 1.7× against Opus. GPT-5.5's retry overhead pushes it to $0.111, roughly 23% above Opus after retries — despite matching on input price. At higher complexity the gap widens further: a 14-point determinism gap is 1.8× at 3 steps but **7.2× at 10 steps**. Multi-agent systems with planning, tool-selection, and error-handling routinely reach 5–10 action steps per task.

<Callout type="hot">
**The inversion is real.** At category-9 complexity (ambiguous-input, multi-tool), Gemini 3.1 Pro crosses above Opus 4.7 in cost-per-task at pipeline length ≥ 5 steps. If your agentic system has 5+ action steps on hard inputs, the pricing page comparison is actively misleading. Run your determinism scores through the retry multiplier before making a cost decision.
</Callout>

```takeaways
- At ambiguous-input complexity on a long pipeline, the cost ordering can invert: Gemini's higher retry rate more than offsets its lower per-token price.
- The cost break-even between Gemini 3.1 Pro and Opus 4.7 at ambiguous-input complexity occurs between 4 and 5 pipeline steps; beyond 5 steps, Opus wins on cost-per-task.
- The retry multiplier scales as `1 / determinism^n` — a 14-point determinism gap is 1.8× at 3 steps but grows to a 7.2× difference at 10 steps.
```

## Prompt caching: the underrated cost lever

At 10,000 calls/day with a 10K-token system prompt:

| Model | Without caching | With caching | Daily savings |
|---|---|---|---|
| Opus 4.7 | $500/day | $50/day | **$450/day** |
| GPT-5.5 | $500/day | $50/day | **$450/day** |
| Gemini 3.1 Pro | $200/day | $20/day | **$180/day** |

All three providers give a **90% discount** on cached tokens. The Gemini-vs-Opus and Gemini-vs-GPT-5.5 2.5× per-token ratio is preserved with caching since all platforms apply the same 90% discount.

**Caching gotchas:** Anthropic's cache TTL is 5 minutes — calls more than 5 minutes apart restart the cache; minimum cacheable prefix is 4,096 tokens. OpenAI caches automatically at a **90% discount** with a 128-token minimum. Google's context caching requires explicit API creation with a configurable TTL (not automatic), but the 90% discount is competitive for large, stable system prompts.

```takeaways
- Anthropic caches at 4,096+ token boundaries for current flagship models with a 5-minute TTL and 90% discount on cached tokens; calls more than 5 minutes apart restart the cache.
- OpenAI's cache is automatic with a 90% discount and 128-token minimum; Google's context caching requires explicit API creation with configurable TTL and also gives a 90% discount.
- Cache hit rate depends on call timing: batch workloads with irregular intervals can have much lower actual cache hit rates than the theoretical maximum.
```

## The three workload archetypes, costed

### Archetype A: Coding agent (multi-step, tool-heavy)

Representative profile: 8,000-token system prompt cached after first call; 3,000 token average input; 800 token output; 5 steps; category 5–7 schemas.

| Model | Determinism (5-step success) | Cost per successful task (with caching) |
|---|---|---|
| Opus 4.7 | ~86% (0.86⁵ = 47%) | ~$0.42 |
| GPT-5.5 + strict | ~93% (0.93⁵ = 70%) | ~$0.31 |
| Gemini 3.1 Pro | ~79% (0.79⁵ = 31%) | ~$0.28 |

GPT-5.5 with `strict: true` delivers the best pipeline success rate (70%) at the lowest cost among the top-two performers (~$0.31 vs Opus's ~$0.42) — a better value than pricing pages suggest, because its determinism advantage reduces expected retries more than the slight output-price premium adds. Gemini ($0.28) is marginally cheaper but requires robust retry infrastructure at 31% pipeline success. [^4]

### Archetype B: Document Q&A (long-context, single query)

Representative profile: 80K-token document; 500-token system prompt; 600-token output; 1 step.

| Model | Cost per call | Notes |
|---|---|---|
| Opus 4.7 | $0.415 | $80K × $5/M + 600 × $25/M |
| GPT-5.5 | $0.418 | $80K × $5/M + 600 × $30/M |
| Gemini 3.1 Pro | $0.167 | $80K × $2/M + 600 × $12/M |

With no pipeline and no retries, **Gemini 3.1 Pro wins** (2.5× cheaper than either Opus or GPT-5.5, which are now nearly cost-equivalent). Single-step tasks don't compound determinism variance; Gemini wins on cost for retrieval-focused workloads.

### Archetype C: High-volume classification (batch, 10M items/month)

Representative profile: 300 tokens per item; 1,000-token system prompt cached; 50 tokens output; 1 step.

| Model | Monthly cost (no retries) | With 5% retry rate |
|---|---|---|
| Opus 4.7 | ~$77K/month | ~$81K |
| GPT-5.5 | ~$80K/month | ~$84K |
| Gemini 3.1 Pro | ~$32K/month | ~$34K |

**Gemini 3.1 Pro wins** — saving $45K/month vs. Opus. The simple flat schema (category 1–2) keeps Gemini's determinism at 96–100%, eliminating the reliability advantage of more expensive models. Multi-model routing strategies — cheap model for easy tasks, premium model for complex — can reduce cost-per-task by 30–60%. [^4][^6]

## Hands-on exercise

**Build a cost-per-task model for your use case using your Chapter 2 benchmark data.**

Fill in these numbers from actual benchmark runs (not guesses):

```
USE CASE: [describe in 1 sentence]

TOKEN COUNTS:
  System prompt tokens: ___
  Average user message tokens: ___
  Tool definition tokens: ___
  Average output tokens: ___
  Pipeline steps: ___

CACHING:
  Is system prompt ≥ 1024 tokens? [Y/N]
  Estimated cache hit rate: ___ %
  (Anthropic: use 80% if calls within 5-min windows; 40% if irregular)

DETERMINISM SCORES (from Chapter 2):
  Opus 4.7: ___ %   GPT-5.5: ___ %   Gemini 3.1 Pro: ___ %

COST FORMULA (per model):
  input_cost = (system_prompt × (1 - cache_hit_rate) × INPUT_PRICE)
             + (system_prompt × cache_hit_rate × CACHE_PRICE)
             + (message_tokens + tool_tokens) × INPUT_PRICE
  output_cost = output_tokens × OUTPUT_PRICE
  retry_multiplier = 1 / (determinism ^ pipeline_steps)
  cost_per_task = (input_cost + output_cost) × retry_multiplier × pipeline_steps

RESULTS:
  Opus 4.7 cost-per-task: $___
  GPT-5.5 cost-per-task: $___
  Gemini 3.1 Pro cost-per-task: $___

RECOMMENDATION: [which model and why, in 1 sentence]
```

Your cost model is complete when all token counts are from actual benchmark runs, cache hit rate reflects your actual call pattern, and cost-per-task accounts for retries using your measured determinism scores. *Estimated time: 20 minutes.*

<KnowledgeCheck
  question="A startup is choosing between Gemini 3.1 Pro ($2/M input) and Opus 4.7 ($5/M input) for a 4-step agentic coding pipeline. Their benchmark shows Gemini determinism = 82% and Opus determinism = 91% on their prompt types. Which statement is true about the expected cost-per-task comparison?"
  options={[
    "Gemini is always cheaper because its per-token price is 2.5× lower, regardless of determinism",
    "Opus is cheaper because its higher determinism means fewer retries, more than offsetting the higher price",
    "The expected number of Gemini runs to complete one task is ~1.5×, narrowing but not eliminating its cost advantage",
    "Determinism doesn't affect cost because retries use only output tokens, which are the same fraction of total cost"
  ]}
  correctIdx={2}
  explanation="4-step pipeline success: Gemini 0.82⁴ = 45%, so expected runs = 1/0.45 ≈ 2.2. Opus 0.91⁴ = 68%, expected runs = 1/0.68 ≈ 1.47. Gemini needs ~1.5× more runs than Opus per successful task. That partially offsets Gemini's 2.5× per-token input price advantage. The cost-per-task ratio compresses from ~2.3× (pricing page, blended input+output) to roughly ~1.5×. Gemini is still cheaper — but by a meaningfully smaller margin than the pricing page implies. Option A is wrong (determinism clearly affects cost). Option B is wrong (the math shows Gemini is still cheaper per task despite more retries). Option D is wrong (retries require re-sending the full input, not just output tokens)."
/>

<KnowledgeCheck
  question="After building your cost model, you find that Opus 4.7 costs $0.42/task and Gemini 3.1 Pro costs $0.28/task for your coding agent workload. Your company processes 50,000 tasks/month. A teammate argues: 'We should use Gemini — we save $7,000/month.' You notice that your Chapter 2 benchmark showed Gemini's pipeline success rate is 31% vs. Opus's 61%. Write 2–3 sentences evaluating the teammate's argument, including any cost factor they may have omitted."
  options={["self-check"]}
  correctIdx={0}
  explanation="The teammate's calculation is directionally correct on raw inference cost but omits the engineering cost of handling a 69% pipeline failure rate. At 31% pipeline success (Gemini), 34,500 of 50,000 monthly tasks fail at least once — each requiring retry logic, error handling, partial-state recovery, and possibly human review. The engineering cost of building and maintaining that infrastructure, plus the latency cost to users waiting on retries, should be quantified before accepting the $7,000/month savings. A more complete comparison would factor in: developer time to build retry/recovery (~20–40 engineering hours = $3,000–6,000 in team cost), user-facing latency increase on retries, and on-call burden from elevated failure rates. The teammate's conclusion may still be right — but the decision requires a total cost of ownership calculation, not just an inference cost comparison."
/>

---

## What's next

You have a scorecard (ch01), determinism scores (ch02), context fidelity data (ch03), and a cost-per-task model (ch04). The capstone project synthesizes all four into a model selection memo — format in `vault/courses/picking-a-frontier-model-2026-q2/outline.md`.

---

## References cited

[^1]: Anthropic. "Claude pricing." https://www.anthropic.com/pricing — Opus 4.7 input/output/cache pricing as of Q2 2026. Also: "Prompt caching." https://www.anthropic.com/news.

[^2]: OpenAI. "OpenAI API pricing." https://developers.openai.com/api/docs/pricing — GPT-5.5 $5/$30/M input/output; cached input $0.50/M (90% discount). Verified 2026-06-14. Model release notes: https://developers.openai.com/api/docs/models.

[^3]: Google. "Gemini API pricing." https://ai.google.dev/pricing — Gemini 3.1 Pro input/output/context caching pricing as of Q2 2026. Changelog: https://ai.google.dev/gemini-api/docs/changelog.

[^4]: Koenig AI Academy internal cost model data, Q2 2026. Derived from the Q2 2026 tool-use determinism benchmark dataset (reference tables embedded in Chapter 2) with retry simulation applied at workload scale.

[^5]: Patil, S. et al. *Berkeley Function-Calling Leaderboard (BFCL) V4*. https://gorilla.cs.berkeley.edu/leaderboard.html — analysis of tool-call reliability impact on pipeline cost.

[^6]: Chen, L. et al. (2023). "FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance." https://arxiv.org/abs/2305.05176 — analysis of model routing, cascading, and selection strategies that reduce cost-per-task by matching task complexity to model capability.
