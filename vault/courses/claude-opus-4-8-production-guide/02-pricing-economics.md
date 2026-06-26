---
chapter_num: 2
course_slug: claude-opus-4-8-production-guide
title: "Pricing + Economics: Picking the Right Mode for Every Workload"
status: awaiting-g0
duration_min: 40
vendor_tag: anthropic
learning_objectives:
  - "Calculate per-task cost for four workflow types across standard, fast, and batch modes"
  - "Explain why fast mode's 3× price cut changes the Opus-vs-Sonnet decision for latency-sensitive pipelines"
  - "Apply the Databricks 61% savings result to your own cost model"
  - "Decide when Sonnet 4.6 ($3/$15 per million tokens) is correct versus when Opus 4.8 pays back its premium via fewer retries"
  - "Configure batch mode ($2.50/$12.50) for overnight async workloads that don't need real-time results"
sources:
  - url: https://docs.anthropic.com/en/docs/about-claude/pricing
    title: "Claude Pricing — Anthropic Docs"
  - url: https://www.anthropic.com/news/claude-opus-4-8
    title: "Introducing Claude Opus 4.8 — Anthropic"
  - url: https://docs.anthropic.com/en/docs/about-claude/models/choosing-a-model
    title: "Choosing a Model — Anthropic Docs"
  - url: https://docs.anthropic.com/en/docs/about-claude/models/migrating-to-claude-4
    title: "Migrating to Claude 4 — Anthropic Docs"
owns:
  - "Standard/fast/batch pricing math and mode selection logic"
  - "Per-task cost calculation for coding agent, financial analysis, document review, and browser automation workflows"
  - "Sonnet 4.6 vs Opus 4.8 decision framework and fallback thresholds"
  - "Batch mode configuration for async workloads"
  - "Databricks 61% savings figure and prompt cache economics"
  - "Tool system-prompt token overhead reduction (675→290 tokens)"
defers_to:
  - "Fallback chain implementation with LiteLLM or Vercel AI SDK → ch5"
  - "Dynamic Workflows cost impact in production agent runs → ch3"
  - "Databricks Genie architecture deep-dive → ch6"
quiz_topics:
  - "Opus 4.8 pricing tiers and when to use each mode"
  - "Fast mode economics and the Databricks 61% savings result"
  - "Batch API discount and which workloads justify it"
  - "Sonnet 4.6 vs Opus 4.8 decision criteria including retry-rate economics"
notebooklm_source_focus:
  - "Pricing table across standard/fast/batch modes"
  - "Databricks 61% token cost reduction on financial document workflows"
  - "Batch API making Opus 4.8 cheaper than Sonnet 4.6 standard for async work"
  - "Tool system-prompt token reduction: 675→290 tokens for auto mode"
  - "Prompt cache economics: 1024-token minimum and cache read at $0.50/MTok"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "What is the input token price for Opus 4.8 in batch mode?"
    options:
      - "$2.50 per million tokens"
      - "$5.00 per million tokens"
      - "$10.00 per million tokens"
      - "$3.00 per million tokens"
    correct_idx: 0
    explanation: "Batch mode applies a 50% discount to standard pricing, reducing input cost from $5.00 to $2.50 per million tokens. This makes Opus 4.8 batch cheaper than Sonnet 4.6 standard ($3.00 input) for offline or async workloads."
    section_anchor: the-three-pricing-tiers
  - question: "Databricks reported Opus 4.8 cut their Genie agent's token cost by roughly how much compared to Opus 4.7?"
    options:
      - "About 20% cheaper"
      - "About 40% cheaper"
      - "About 61% cheaper"
      - "About 80% cheaper"
    correct_idx: 2
    explanation: "Databricks CTO Hanlin Tang reported 61% cheaper token cost on their Genie financial-document agent after switching to Opus 4.8 fast mode. The savings came primarily from fast mode's 3× price drop from the previous generation, making high-frequency agent loops economically viable."
    section_anchor: the-fast-mode-economics-shift
  - question: "Which workload is the best fit for Opus 4.8 batch mode?"
    options:
      - "An interactive coding assistant where developers wait for each response"
      - "A nightly job that classifies ten thousand support tickets for overnight triage"
      - "A real-time browser automation agent tracking a live auction feed"
      - "A customer-facing chatbot required to respond in under two seconds"
    correct_idx: 1
    explanation: "Batch mode returns results asynchronously, often within 24 hours. It is the right choice for workloads where no user or downstream system is blocking on the result — nightly analysis, bulk classification, and evaluation harnesses are canonical fits. The other options all require low-latency streaming."
    section_anchor: batch-mode-for-async-workloads
  - question: "Which scenario most strongly favors Sonnet 4.6 over Opus 4.8 standard pricing?"
    options:
      - "Dense multi-step contract analysis across two hundred pages of legal text"
      - "Simple transactional queries where retrying a failed response costs almost nothing"
      - "A codebase migration agent refactoring tens of thousands of source files"
      - "Financial filing analysis requiring high citation precision across numerical tables"
    correct_idx: 1
    explanation: "Sonnet 4.6 wins when tasks are simple, high-volume, and cheap to retry. On hard tasks where Opus 4.8 fails meaningfully less often, the retry-rate economics close the price gap — or eliminate it entirely. Complex reasoning, agentic coding, and citation-sensitive analysis all favor Opus 4.8."
    section_anchor: sonnet-46-vs-opus-48-the-decision-framework
---

## The Three Pricing Tiers

Opus 4.8 ships at the same token price as Opus 4.7 — $5 per million input tokens, $25 per million output tokens — but that headline obscures the real economics story, which is entirely about mode selection. Three modes are available, each mapping to a distinct production use case.

| Mode | Input (per MTok) | Output (per MTok) | Latency |
|------|-----------------|-------------------|---------| 
| Standard | $5.00 | $25.00 | Streaming |
| Fast (research preview) | $10.00 | $50.00 | 2.5× faster |
| Batch API | $2.50 | $12.50 | Async, ≤24h |
| Prompt cache write | $6.25 | — | — |
| Prompt cache read | $0.50 | — | — |

[Source: Anthropic Pricing Docs](https://docs.anthropic.com/en/docs/about-claude/pricing)

The counterintuitive result: **Opus 4.8 batch at $2.50 input is cheaper than Sonnet 4.6 standard at $3.00 input.** For async workloads that don't need real-time results, you can run the most capable Claude model in production for less than the cost of the mid-tier alternative on the same input volume. That single fact should reshape how you assign workloads to tiers.

One more cost lever ships with the model and requires no configuration change: the tool system-prompt overhead dropped from 675 tokens to 290 tokens for the `auto` tool mode. An agent making 1,000 tool-augmented calls per day saves 385,000 tokens of overhead — $1.93 daily at standard pricing before any other optimizations.

<KnowledgeCheck question="Which Opus 4.8 mode delivers the lowest per-token cost?" options={["Standard ($5/$25 per MTok)", "Fast mode ($10/$50 per MTok)", "Batch API ($2.50/$12.50 per MTok)", "All three modes cost the same"]} correctIdx={2} explanation="Batch API applies a 50% discount on standard pricing, making it $2.50/$12.50 per million tokens — the cheapest way to run Opus 4.8. The trade-off is asynchronous delivery rather than real-time streaming." />

## Per-Task Cost Across Workflow Types

List prices don't tell you what a task actually costs. What matters is your token profile — how much context you carry per turn, how long outputs run, and whether prompt caching applies. Two workflow profiles illustrate the range.

**Workflow A: Coding agent (3-turn interactive session)**

A typical coding task carries a 2,000-token system prompt plus 6,000 tokens of file context, producing roughly 3,000 tokens of output per turn across three turns.

- Total input: ~24,000 tokens (0.024 MTok)
- Total output: ~9,000 tokens (0.009 MTok)
- Opus 4.8 standard: (0.024 × $5) + (0.009 × $25) = **$0.345/task**
- Opus 4.8 batch: (0.024 × $2.50) + (0.009 × $12.50) = **$0.173/task**
- Sonnet 4.6 standard: (0.024 × $3) + (0.009 × $15) = **$0.207/task**

At standard pricing, Opus 4.8 costs 1.67× more than Sonnet 4.6. Under batch mode, Opus 4.8 is 16% *cheaper* than Sonnet 4.6 standard while delivering a materially stronger model. The crossover only applies to async work, but it directly affects nightly code-review pipelines and batch evaluation harnesses where this pattern is common.

**Workflow B: Document review with prompt caching**

A contract review agent processing 50,000-token documents, where the same document context is reused across 10 analysis passes in a single session:

- Cache write cost (first load): 0.050 MTok × $6.25 = **$0.31 one-time**
- Cache read per subsequent turn: 0.050 MTok × $0.50 = **$0.025/turn**
- Output per turn: ~2,000 tokens × $25/MTok = **$0.05/turn**
- Effective per-turn cost from turn 2 onward: **$0.075/turn**

Without caching, each turn would cost 0.050 × $5 + $0.05 = **$0.30/turn** — a 4× premium. The lowered prompt cache minimum in Opus 4.8 (now 1,024 tokens, down from a higher floor on 4.7) means shorter system prompts that previously couldn't cache now qualify. For document-heavy workloads, caching strategy is worth more to your cost model than model choice.

## The Fast Mode Economics Shift

Fast mode charges $10/$50 per million tokens — twice the standard rate — but its 2.5× speed improvement makes it the right choice for pipelines where latency determines user experience or where a slow model creates a bottleneck for downstream agents.

The headline result comes from Databricks: CTO Hanlin Tang reported that their [Genie agent achieved 61% cheaper token cost than Opus 4.7](https://www.anthropic.com/news/claude-opus-4-8) on financial document workflows after adopting Opus 4.8 fast mode. That figure is not about fast mode being cheap — it reflects that the previous fast-mode tier cost roughly three times the current $10/$50 rate, putting it outside production economics for high-frequency agent loops. The 3× price reduction brought fast mode within practical range for the first time.

The practical rule: use fast mode when a user or a pipeline stage is blocking on the response and that delay is measurable. For a developer-facing coding assistant, the 2× premium over standard is recovered in user satisfaction from near-instant responses. For an overnight batch job, fast mode adds cost with no user-visible benefit.

<Callout type="warning">
Fast mode is a research preview as of mid-2026 and may have limited availability by region and plan tier. Before building a production dependency on it, verify availability in your account, and configure Opus 4.8 standard at `effort: xhigh` as a fallback path for when fast mode is unavailable.
</Callout>

<KnowledgeCheck question="Why did Databricks achieve 61% token cost savings on Opus 4.8, not by switching to a cheaper model?" options={["Opus 4.8 standard pricing is lower than Opus 4.7 standard pricing", "Fast mode's price dropped 3× from the previous generation, making agent loops viable", "Opus 4.8 uses a new tokenizer that produces fewer tokens for equivalent outputs", "Databricks switched their pipeline to batch mode for all financial analysis tasks"]} correctIdx={1} explanation="Standard pricing is unchanged from Opus 4.7 ($5/$25). The savings came from fast mode falling from roughly $30/$150 per MTok to $10/$50 — a 3× reduction that opened fast mode as an economically viable option for production agent loops where latency-sensitive response was previously too expensive." />

## Sonnet 4.6 vs Opus 4.8: The Decision Framework

Sonnet 4.6 at $3/$15 handles most tasks adequately. Opus 4.8 standard at $5/$25 costs 1.67× more on both input and output. The premium pays back only when quality differences show up in task-level outcomes — which is rarer than most teams assume.

| Task profile | Recommended choice |
|-------------|-------------------|
| Simple, high-volume, cheap to retry | Sonnet 4.6 standard |
| Latency-sensitive, medium complexity | Sonnet 4.6 or Opus 4.8 fast mode |
| Complex reasoning, correctness-critical | Opus 4.8 standard |
| Async batch, high complexity | Opus 4.8 batch (cheaper than Sonnet standard) |
| Agentic coding at large scale | Opus 4.8 standard or fast mode |

The retry-rate argument is often decisive in ways teams don't model. If Sonnet 4.6 fails 15% of hard tasks and each retry costs as much as the original call, the effective cost per successful task is 1.15× the nominal rate. Opus 4.8 failing 5% of the same tasks puts its effective cost at roughly 1.05× — shrinking the real gap between models from 67% to under 10% on challenging workloads. Before concluding that the cheaper model wins on economics, measure your actual task-specific failure and retry rate against each model.

[Source: Anthropic Choosing a Model Docs](https://docs.anthropic.com/en/docs/about-claude/models/choosing-a-model)

## Batch Mode for Async Workloads

Batch mode applies a 50% discount to standard pricing: $2.50 input, $12.50 output per million tokens. Results are returned asynchronously via JSONL response file, typically within 24 hours. The Anthropic Batch API accepts up to 10,000 requests per batch submission.

To configure a batch job, replace `client.messages.create` with `client.messages.batches.create` and supply a `requests` array. Each element carries its own `model`, `messages`, and `max_tokens` — the API fans out execution and delivers results in a single output file when all requests complete. There are no changes to prompt format, tool definitions, or message structure.

Batch mode is correct whenever a real-time response would be wasted: nightly code review across a repository, bulk document classification for legal discovery, evaluation harness runs against a test set, or financial analysis scheduled after market close. For all of these, Opus 4.8 batch at $2.50/$12.50 delivers flagship-model quality at a lower input cost than Sonnet 4.6 standard — and the quality difference on dense, multi-step tasks is not marginal.

---

## Hands-On Exercise: Build Your Cost Projection

Build a cost-estimation script that replays a sample of production request logs against three configurations — Opus 4.8 standard, Opus 4.8 batch, and Sonnet 4.6 standard — and outputs a monthly cost projection with break-even analysis.

**Steps:**
1. Export 100 representative requests from your API logs. If you don't have production logs yet, mock them with realistic token counts for your primary use case (coding agent: ~24K input/9K output per session; document review: ~52K input/2K output per pass).
2. For each request, calculate cost under all three configurations using the pricing table in this chapter.
3. Aggregate to a monthly total using your actual daily request volume.
4. Add a retry-rate adjustment column: assume Opus 4.8 fails 5% of hard tasks and Sonnet 4.6 fails 15% of the same tasks, then compute effective cost per successful task for each model.

**Success criteria:** Your script outputs a three-column table — model/mode, nominal monthly cost, and effective cost after retries. If Opus 4.8 batch is cheaper than Sonnet 4.6 standard for your input-heavy async workloads, you have a production optimization ready to deploy without accepting any quality trade-off.

---

The next chapter moves from pricing to wiring — Dynamic Workflows, mid-conversation system messages, and effort-level controls all interact in ways that affect both quality and cost. [[03-production-deployment-patterns]]
