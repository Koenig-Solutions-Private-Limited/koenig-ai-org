---
date: 2026-07-01
author: blog-author
ticket: KOEA-9838
vendor_tag: anthropic
content_type: article
status: g3-passed
reading_time_min: 9-11
primary_query: "migrating to claude sonnet 5 breaking changes"
contrarian_angle: "The 400 errors are the visible break; the tokenizer inflation is the invisible one that hits your budget after August 31"
first_60_words_answer: "If your Anthropic API calls started returning HTTP 400 errors on July 1, 2026, Claude Sonnet 5 is the cause. Three changes break existing Sonnet 4.6 code: temperature/top_p/top_k return 400 if set to non-default values; manual budget_tokens extended thinking syntax is removed; and adaptive thinking is on by default. Here is the 5-minute fix."
positions:
  - id: benchmark-theater-vs-agent-trace-evaluation
    engagement: defends
  - id: stance:ai-vendor-news-opinionated
    engagement: defends
  - id: stance:harness-over-model
    engagement: neutral
faq:
  - question: "What breaks when migrating from Claude Sonnet 4.6 to Sonnet 5?"
    answer: "Three things break: (1) temperature, top_p, and top_k now return HTTP 400 if set to non-default values — remove these parameters entirely; (2) the old extended thinking syntax (thinking: {type: 'enabled', budget_tokens: N}) returns 400 — migrate to output_config: {effort: 'high'} for high-effort reasoning; (3) adaptive thinking is now on by default, so add thinking: {type: 'disabled'} to any call where you do not want reasoning overhead."
  - question: "How much does the Claude Sonnet 5 tokenizer change affect cost?"
    answer: "Claude Sonnet 5 uses a new tokenizer that produces approximately 30% more tokens from identical input. For English text, Simon Willison measured approximately 1.4x more tokens — meaning equivalent requests cost roughly 37-40% more in total after introductory pricing ends August 31, 2026. Introductory pricing at $2/$10 per MTok partially offsets the inflation versus Sonnet 4.6 standard $3/$15 until then."
  - question: "How do I disable adaptive thinking in Claude Sonnet 5?"
    answer: "Pass thinking: {type: 'disabled'} in your API request body alongside the model parameter. Without this field, Sonnet 5 enables adaptive thinking by default, which increases output token counts, adds first-token latency, and changes response characteristics relative to Sonnet 4.6 behavior."
  - question: "Is Claude Sonnet 5 available on Priority Tier?"
    answer: "No. Priority Tier service is not available for Claude Sonnet 5 as of the June 30, 2026 launch. If your application requires Priority Tier SLA guarantees, you must continue using Claude Sonnet 4.6."
original_data: false
last_updated: 2026-07-01
hero_image:
  url: /img/blogs/2026-07-01-claude-sonnet-5-migration-breaking-changes/hero.png
  alt: "Side-by-side code diff of Sonnet 4.6 versus Sonnet 5 API request bodies showing removed temperature parameter and new output_config.effort field"
sources:
  - https://www.anthropic.com/news/claude-sonnet-5
  - https://platform.claude.com/docs/en/release-notes/api
  - https://platform.claude.com/docs/en/about-claude/models/migration-guide
  - https://platform.claude.com/docs/en/about-claude/models/whats-new-sonnet-5
  - https://simonwillison.net/2026/Jun/30/claude-sonnet-5/
  - https://techcrunch.com/2026/06/30/anthropic-launches-claude-sonnet-5-as-a-cheaper-way-to-run-agents/
  - https://news.ycombinator.com/item?id=48736605
  - https://github.com/anthropics/claude-code/releases/tag/v2.1.197
whats_new:
  - Claude Sonnet 5 ships three API-breaking changes AND a tokenizer that inflates equivalent English requests by ~40% — the benchmark headline is not the story developers need right now
learning_objectives:
  - Identify and fix the three API-breaking changes that return HTTP 400 when calling claude-sonnet-5
  - Understand what the new tokenizer means for your per-request cost after August 31, 2026
  - Decide when to disable adaptive thinking in production workloads
tags:
  - claude
  - anthropic
  - migration
  - api
  - tokenizer
slug: migrating-to-claude-sonnet-5-breaking-changes-tokenizer-cost
seo_description: "Claude Sonnet 5 breaks 3 API params and inflates tokens ~40%. Fix the temperature/top_k errors, extended thinking syntax, and adaptive thinking default fast."
---

# Migrate to Claude Sonnet 5 in 2026: Fix the 3 Breaking Changes and Plan for the Tokenizer Tax

If your Anthropic API calls started returning HTTP 400 errors on July 1, 2026, Claude Sonnet 5 is the cause. Three changes break existing Sonnet 4.6 code: `temperature`, `top_p`, and `top_k` now return 400 if set to non-default values; manual `budget_tokens` extended thinking syntax is removed; and adaptive thinking is on by default. Here is the 5-minute fix.

Most coverage is leading with the benchmark story — Humanity's Last Exam at 46.8% with tools, SWE-bench Pro at 63.2%, a near-tie with Opus 4.8 on knowledge work. That is the press release narrative. The story that will actually affect your production budget is quieter: a new tokenizer that produces approximately 30% more tokens from identical text. [Simon Willison's independent measurement](https://simonwillison.net/2026/Jun/30/claude-sonnet-5/) puts English inflation at ~1.4×. At post-introductory pricing, equivalent English requests will cost roughly 37–40% more. Introductory pricing hides this until August 31, 2026 — then the invoice arrives.

![Side-by-side code comparison showing the before and after of migrating Sonnet 4.6 API calls to Sonnet 5, with temperature parameter removed and output_config.effort added](/img/blogs/2026-07-01-claude-sonnet-5-migration-breaking-changes/hero.png)

---

## Breaking Change #1: Remove temperature, top_p, and top_k

The most immediate production break. Claude Sonnet 5 rejects non-default sampling parameters with an immediate HTTP 400. There is no deprecation window and no silent fallback — the request fails on the first call.

**What fails:**

```python
# Previously worked with claude-sonnet-4-6
# On claude-sonnet-5, returns: {"type": "error", "error": {"type": "invalid_request_error"}}

response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    temperature=0.7,    # HTTP 400
    top_p=0.9,          # HTTP 400
    top_k=40,           # HTTP 400
    messages=[{"role": "user", "content": "Explain quantum entanglement simply"}]
)
```

**The fix — remove them entirely:**

```python
response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Explain quantum entanglement simply"}]
)
```

Per the [official Sonnet 5 migration guide](https://platform.claude.com/docs/en/about-claude/models/migration-guide), Anthropic's position is that adaptive thinking provides a superior mechanism for shaping output quality compared to manual sampling parameters. The model's internal reasoning process replaces temperature as the quality dial.

For most workloads, this is the right move. Temperature hacking was a proxy for "I want more or less creative output" — a blunt instrument. With effort-level control over extended thinking, Sonnet 5 handles this more precisely. If you were using `temperature=0` for determinism, that was never a true guarantee anyway. Switch to structured output schemas via response format constraints, which provide consistent output structure without relying on sampling parameters Sonnet 5 no longer accepts.

One important caveat from the [Sonnet 5 announcement](https://www.anthropic.com/news/claude-sonnet-5): **Priority Tier service is not available on Sonnet 5** at launch. If your production SLA requires Priority Tier guarantees, stay on Sonnet 4.6 until Anthropic adds Priority Tier support for Sonnet 5.

**Grep to find all affected call sites:**

```bash
# Find files with sampling params passed to any Anthropic call
rg -n 'temperature|top_p|top_k' --glob '*.{py,ts,js,mjs}' src/
```

---

## Breaking Change #2: Rewrite Extended Thinking Calls

If your code used the extended thinking feature, it is broken. The `budget_tokens` syntax was deprecated on Sonnet 4.6 and now returns HTTP 400 on Sonnet 5. The primary replacement is `thinking: {type: "adaptive"}`, with `output_config.effort` controlling reasoning depth.

**What fails:**

```python
# Old Sonnet 4.6 extended thinking syntax — returns 400 on Sonnet 5
response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=8000,
    thinking={
        "type": "enabled",
        "budget_tokens": 5000  # HTTP 400: parameter removed
    },
    messages=[{"role": "user", "content": "Debug this race condition..."}]
)
```

**The fix — use `thinking: {type: "adaptive"}` with `output_config.effort`:**

```python
# Sonnet 5 extended thinking: thinking=adaptive is primary, effort controls depth
response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=8000,
    thinking={"type": "adaptive"},      # Primary: explicitly enable adaptive thinking
    output_config={"effort": "high"},   # "low", "medium", "high", "xhigh", or "max"
    messages=[{"role": "user", "content": "Debug this race condition..."}]
)
```

The `effort` parameter maps to the intent behind `budget_tokens`: `"low"` for quick tasks, `"medium"` for standard reasoning, `"high"` for complex multi-step problem-solving, `"xhigh"` for extended deep reasoning, and `"max"` for maximum reasoning capacity. You no longer set an explicit token ceiling — Anthropic allocates internally based on effort level.

This is an improvement in API ergonomics. Choosing a `budget_tokens` value was guesswork: too low and the model reasoned incompletely; too high and you paid for unused thinking capacity. Effort levels abstract this into a practical tradeoff developers can actually make.

The cost observability tradeoff is real. With `budget_tokens` you had an explicit ceiling on thinking spend. With `effort`, trust Anthropic's allocation but monitor `usage.thinking_input_tokens` and `usage.thinking_output_tokens` in the response to track actual spend. Set conservative `max_tokens` ceilings on high-effort calls until you have a baseline for your specific workloads.

**Grep to find all affected call sites:**

```bash
# Find extended thinking calls using deprecated syntax
rg -n 'budget_tokens|"type".*"enabled"' --glob '*.{py,ts,js,mjs}' src/
```

---

## Breaking Change #3: Opt Out of Adaptive Thinking Explicitly

This is the behavioral change most likely to cause silent regressions. Unlike the previous two changes that fail loudly with a 400 error, this one modifies how Sonnet 5 responds without any error signal — your call succeeds, but the response behavior is different.

On Sonnet 4.6, extended thinking was opt-in. On Sonnet 5, **adaptive thinking is on by default**. Without an explicit `thinking: {type: "disabled"}` parameter, every Sonnet 5 call may include chain-of-thought reasoning — producing more output tokens, higher first-token latency, and different response characteristics than your Sonnet 4.6 code expected.

**For workloads that do not need extended reasoning:**

```python
response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    thinking={"type": "disabled"},  # Restore Sonnet 4.6 behavior
    messages=[{"role": "user", "content": "Summarize this document in 3 bullet points"}]
)
```

For straightforward tasks — summarization, classification, structured extraction, short-form content generation — `thinking: {type: "disabled"}` is the right default. It reduces latency, keeps output token counts predictable, and preserves the response cadence your users experienced on Sonnet 4.6.

Reserve adaptive thinking for tasks that genuinely benefit from extended reasoning: complex debugging, multi-step planning, long-context synthesis, agentic task decomposition. The latency difference is material — adaptive thinking adds observable delay before the first response token arrives, which is meaningful for user-facing streaming interfaces.

**Grep to audit which call sites need the explicit disable:**

```bash
# Find message create calls that lack explicit thinking configuration
rg -n 'messages.create\|messages\.create' --glob '*.{py,ts,js,mjs}' src/ | grep -v 'thinking'
```

---

## The Performance Story (With One Important Caveat)

Sonnet 5's benchmark numbers are legitimately strong. [Anthropic's announcement](https://www.anthropic.com/news/claude-sonnet-5) reports Humanity's Last Exam at 46.8% with tools — versus 34.6% for Sonnet 4.6, a 12-point lift. SWE-bench Pro reaches 63.2% versus Sonnet 4.6's 58.1%. On GDPval-AA v2 (knowledge work), Sonnet 5 scores 1,618 — essentially tied with Opus 4.8 at 1,615, at significantly lower cost.

That last number is the headline Anthropic wants: near-Opus quality at Sonnet pricing.

Per our position on [benchmark evaluation](/courses/picking-a-frontier-model-2026-q2): treat these numbers as weak signals, not purchase decisions. The [Hacker News launch thread](https://news.ycombinator.com/item?id=48736605) (top comment: 838 points) surfaced a substantive practitioner counter-argument — at high effort settings, Sonnet 5 costs roughly the same per task as Opus 4.8 at medium effort, but Opus wins on output quality for complex reasoning chains.

The more meaningful signal is where practitioners report actual production gains. Zapier and Lovable engineers report Sonnet 5 completing multi-step agentic tasks that previously stalled at tool-chaining failures. On the agentic coding benchmark CursorBench, Sonnet 5 reaches 57% versus 49% for Sonnet 4.6 — a trace-level measurement with lower contamination risk than the headline benchmarks. That is where the real improvement lives: not on isolated reasoning tasks, but on compound tool-use chains where pass/fail rate matters more than any single answer quality score.

The GLM-5.2 comparison from community benchmarks is a live question: that evaluation predates Sonnet 5 and will need to be rerun. Watch for updated numbers in the next 5–7 days.

---

## The Hidden Cost: Tokenizer Inflation Math

This is the change most coverage has not quantified — and the one that will affect your budget most tangibly after August 31.

Claude Sonnet 5 ships with a new tokenizer (the same one used in Opus 4.7). [Simon Willison's June 30 analysis](https://simonwillison.net/2026/Jun/30/claude-sonnet-5/) — the most technically detailed community measurement available — confirms: identical input text produces approximately 30% more tokens than on Sonnet 4.6. The variance is content-dependent:

| Content Type | Token Inflation Factor |
|---|---|
| English prose | ~1.40× |
| Spanish text | ~1.33× |
| Python code | ~1.27× |
| Simplified Mandarin | ~1.0× (effectively unchanged) |

**What this means for your cost projections:**

Consider a document summarization pipeline processing 10,000-character English documents. On Sonnet 4.6 at standard pricing ($3 input / $15 output per MTok):

- Input: ~3,300 tokens × $3/MTok = **$0.0099**
- Output: ~500 tokens × $15/MTok = **$0.0075**
- **Per-request total: ~$0.0174**

On Sonnet 5 after introductory pricing ends (same $3/$15):

- Input: ~4,620 tokens (3,300 × 1.4) × $3/MTok = **$0.0139**
- Output: ~665 tokens (500 × ~1.33) × $15/MTok = **$0.0100**
- **Per-request total: ~$0.0239 — a 37% increase over Sonnet 4.6 standard**

The introductory pricing window ($2 input / $10 output, through August 31) changes the picture temporarily:

- Input: 4,620 tokens × $2/MTok = **$0.0092**
- Output: 665 tokens × $10/MTok = **$0.0067**
- **Introductory total: ~$0.0159 — 9% cheaper than Sonnet 4.6 standard**

The introductory rate is specifically designed to make migration roughly cost-neutral. After August 31, the tokenizer tax reasserts fully.

**Three additional effects beyond raw cost:**

First, the **1M context window holds less content**. The window is still 1 million tokens, but those tokens now represent approximately 30% less English text. Any retrieval-augmented system stuffing context windows needs to revise its document-to-token estimates downward accordingly.

Second, **token budget limits behave differently**. If your code sets `max_tokens: 4096` expecting a certain response length, Sonnet 5 may reach that ceiling earlier when adaptive thinking is active — thinking tokens and output tokens share the `max_tokens` ceiling. Re-test your ceiling values.

Third, **cost dashboards and circuit breakers need rebasing**. Any per-request cost alarm, monthly budget ceiling, or circuit breaker threshold calibrated on Sonnet 4.6 token counts will underfire on Sonnet 5. Multiply your per-request token estimates by 1.27–1.40 for English workloads before August 31 and update those thresholds.

**Action — re-baseline now while introductory pricing masks the delta:**

```python
import anthropic

client = anthropic.Anthropic()

# Count tokens for your actual production prompts against Sonnet 5
token_count = client.beta.messages.count_tokens(
    model="claude-sonnet-5",
    messages=[{"role": "user", "content": your_production_prompt}]
)

print(f"Sonnet 5 input tokens: {token_count.input_tokens}")
# Compare against your Sonnet 4.6 baseline to measure your specific inflation factor
```

Run this against your top 10 prompt templates before August 31. The inflation factor varies meaningfully by content type — your actual number may differ from the 1.4× English average.

---

## TL;DR: 5-Minute Migration Checklist

```python
import anthropic

client = anthropic.Anthropic()

# ── BEFORE (claude-sonnet-4-6) ──────────────────────────────────────────────
response_old = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    temperature=0.7,       # REMOVE: HTTP 400 on Sonnet 5
    top_p=0.9,             # REMOVE: HTTP 400 on Sonnet 5
    messages=[{"role": "user", "content": "Your prompt here"}]
)

# ── AFTER: Standard call, thinking disabled ─────────────────────────────────
response_standard = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    thinking={"type": "disabled"},  # ADD: preserve Sonnet 4.6 behavior
    # No temperature, top_p, or top_k
    messages=[{"role": "user", "content": "Your prompt here"}]
)

# ── AFTER: High-effort reasoning (replaces budget_tokens) ───────────────────
response_thinking = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=8000,
    thinking={"type": "adaptive"},      # ADD: explicit adaptive thinking
    output_config={"effort": "high"},   # REPLACE budget_tokens with this ("low"–"max")
    messages=[{"role": "user", "content": "Complex multi-step task here"}]
)
```

**Step-by-step checklist:**

- [ ] Replace `claude-sonnet-4-6` with `claude-sonnet-5` in all model parameters
- [ ] Remove `temperature`, `top_p`, and `top_k` from all Sonnet 5 call sites
- [ ] Replace `thinking: {type: "enabled", budget_tokens: N}` with `thinking: {type: "adaptive"}` and `output_config: {effort: "low" | "medium" | "high" | "xhigh" | "max"}`
- [ ] Add `thinking: {type: "disabled"}` to calls that do not need extended reasoning
- [ ] Re-count tokens with `client.beta.messages.count_tokens(model="claude-sonnet-5", ...)` on your production prompts
- [ ] Multiply Sonnet 4.6 token estimates by 1.27–1.40 for English/Spanish to update cost forecasts
- [ ] Rebaseline `max_tokens` ceilings if previously set based on Sonnet 4.6 output length expectations
- [ ] Update cost circuit breakers and dashboards before August 31 when introductory pricing ends
- [ ] Confirm whether your application requires Priority Tier — if yes, hold on Sonnet 4.6 for now (Priority Tier not confirmed for other models at Sonnet 5 launch)

The [Claude Code v2.1.197 release](https://github.com/anthropics/claude-code/releases/tag/v2.1.197) ships Sonnet 5 as the new default model in Claude Code sessions. If your team uses Claude Code for code generation that feeds into tests or CI, the model default change is already in effect — review any sampling parameter usage in code generation prompts immediately.

---

**Knowledge Check:** Your existing pipeline uses `temperature=0` when calling Sonnet 4.6 to get consistent classification output. After switching to `claude-sonnet-5`, what happens to the call, and what is the correct approach to maintain consistent output?

<details>
<summary>Answer</summary>

Sonnet 5 returns an HTTP 400 error immediately on any call with `temperature=0`. Remove the parameter entirely. For consistent structured classification output on Sonnet 5, use Anthropic's response format constraints to define a JSON schema — this enforces consistent output structure at the API level without relying on sampling parameters. Alternatively, pass `thinking: {type: "disabled"}` to suppress adaptive reasoning for simple classification calls where determinism matters more than reasoning depth.

</details>

---

The migration is mechanical once you know what changed. The 400 errors surface the first two breaking changes on the first failed call. Adaptive thinking default is subtler — it will not error, but it will change your latency profile and output token counts silently until you add `thinking: {type: "disabled"}`. And the tokenizer change is invisible until August 31 when introductory pricing ends.

If you are building production agent pipelines on Claude, [[course/claude-agent-sdk-zero-to-production]] covers updated Sonnet 5 patterns including token budget management for the 1M context window, adaptive thinking posture for multi-turn agents, and cost circuit breaker calibration after the tokenizer change.
