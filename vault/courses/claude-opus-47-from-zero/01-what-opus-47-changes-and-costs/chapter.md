---
chapter_num: 1
course_slug: claude-opus-47-from-zero
title: "Five capability shifts in Claude Opus 4.7 — and how to control their cost"
status: awaiting-g0
author: content-author
date: 2026-06-10
reading_time_min: 11
vendor_tag: anthropic
content_type: course-chapter
learning_objectives:
  - "Identify the five most important capability changes from Opus 4.6 to Opus 4.7 (coding, vision, instruction following, memory, effort levels)"
  - "Predict token-cost impact using the updated tokenizer (1.0–1.35× factor) and configure effort and task_budget parameters to control spend"
  - "Migrate an existing claude-opus-4-6 API call to claude-opus-4-7 and verify that output quality and cost match expectations"
  - "Explain why Opus 4.7's stricter instruction following can break prompts written for earlier models"
whats_new:
  - "New xhigh effort level between high and max — now the Claude Code default"
  - "Task budgets in public beta: advisory token spend control for agentic loops"
  - "Vision: 2,576px long edge (~3.75 MP), up from ~1,568px (~1.15 MP)"
  - "Updated tokenizer: up to 35% more tokens for the same fixed text"
  - "Stricter literal instruction following — implied-context prompts need re-tuning"
tags:
  - claude-opus-4-7
  - anthropic
  - api-migration
  - effort-levels
  - task-budget
  - tokenizer
  - vision
  - agentic
sources:
  - https://www.anthropic.com/news/claude-opus-4-7
  - https://docs.anthropic.com/en/docs/about-claude/pricing
  - https://docs.anthropic.com/en/docs/about-claude/models/migrating-to-claude-4
  - https://docs.anthropic.com/en/docs/build-with-claude/effort
  - https://www.anthropic.com/engineering/april-23-postmortem
  - https://anthropic.com/claude-opus-4-7-system-card
  - https://caylent.com/blog/claude-opus-4-7-deep-dive-capabilities-migration-and-the-new-economics-of-long-running-agents
  - https://lushbinary.com/blog/claude-opus-4-7-developer-guide-benchmarks-vision-migration
  - https://docs.anthropic.com/en/docs/about-claude/models
---

# Five capability shifts in Claude Opus 4.7 — and how to control their cost

Claude Opus 4.7 launched on April 16, 2026 at the same $5/$25 per million token price as Opus 4.6, but it is **not a drop-in replacement**.[^1] The model ships with a new tokenizer that can add up to 35% more tokens to the same text,[^2] a new `xhigh` effort level that is already the default in Claude Code,[^1] and an instruction-following engine that interprets prompts literally — which breaks implied-context prompts you may have been running for months.[^1] This chapter maps all five capability shifts, shows you how to predict their cost impact, and walks you through the migration checklist before you touch production.

> **Before you start:** if this is your first time working with Claude tool-use and the Messages API, the [[claude-tool-use-from-zero]] course covers the foundational API patterns this chapter builds on.

---

## The five capability shifts

Anthropic describes Opus 4.7 as "highly autonomous" and oriented around long-horizon agentic work.[^3] The five dimensions that matter most to developers are:

### 1. Coding and agentic performance

On Rakuten's internal SWE-Bench, Opus 4.7 resolves **3× more production tasks** than Opus 4.6.[^1] Partners running multi-step agent workflows report substantially less step-by-step guidance needed. For agentic coding, this is the headline reason to upgrade — the model's planning reliability, tool-use precision, and loop resistance have all improved materially.

### 2. High-resolution vision

Opus 4.7 accepts images up to **2,576px on the long edge** (~3.75 megapixels) — more than three times the ~1,568px ceiling of prior Claude models.[^1] This is a model-level change, not an API parameter, so no code change is needed. XBOW, which runs autonomous penetration testing with heavy computer-use workloads, reported Opus 4.7 scoring **98.5% on their visual-acuity benchmark** versus 54.5% for Opus 4.6.[^1] Coordinate-based computer-use agents now get 1:1 pixel mapping instead of scale-factor arithmetic.

### 3. Stricter instruction following

Opus 4.7 interprets your instructions literally. Where Opus 4.6 inferred intent from context and filled in gaps, Opus 4.7 does exactly what you wrote — no more, no less.[^1] This is good for precision but means prompts written with implied context for Opus 4.6 may need explicit re-tuning before deploying to 4.7.

### 4. Improved file-system memory and loop resistance

Opus 4.7 makes substantially better use of file-system memory to carry state across multi-session long-horizon work without re-providing context from scratch.[^7] It also exhibits higher quality per tool call and fewer redundant actions — what the community is calling "loop resistance."

### 5. New `xhigh` effort level and task budgets

The `effort` parameter now has five levels instead of four: `low`, `medium`, `high`, `xhigh` (new), `max`. Anthropic has raised Claude Code's default to `xhigh` for all plans.[^1] Task budgets — a public beta that lets you set an advisory token ceiling for a full agentic loop — ship alongside the model.[^3]

<KnowledgeCheck
  question="Which of the following capability changes in Opus 4.7 requires no API code change — it works automatically when you send data to the model?"
  options={[
    "Task budgets (advisory token ceiling)",
    "The xhigh effort level",
    "High-resolution vision (2,576px ceiling)",
    "Adaptive thinking"
  ]}
  correct={2}
  explanation="The 2,576px vision ceiling is baked into the model. You send the image as before and Claude processes it at higher resolution automatically. Task budgets require the beta header 'task-budgets-2026-03-13', xhigh requires setting effort explicitly, and adaptive thinking requires opt-in via thinking: {type: 'adaptive'}."
/>

---

## The new tokenizer: measure your cost delta first

Opus 4.7 ships with an updated tokenizer.[^2] Anthropic's pricing documentation states explicitly: **the new tokenizer may use up to 35% more tokens for the same fixed text**.[^2] Pricing is unchanged at $5/MTok input and $25/MTok output, so the cost impact is purely from token-count change, not a rate increase.

The practical range is **1.0–1.35×**. Short, heavily English alphanumeric text will land near 1.0×. Code-heavy prompts with identifiers, multi-language content, or structured data may approach 1.35×.[^8]

Measure your actual delta before switching production traffic:

```python
import anthropic

client = anthropic.Anthropic()

messages = [{"role": "user", "content": "Your representative production prompt here"}]

old_count = client.messages.count_tokens(
    model="claude-opus-4-6", messages=messages
)
new_count = client.messages.count_tokens(
    model="claude-opus-4-7", messages=messages
)

ratio = new_count.input_tokens / old_count.input_tokens
print(f"Token ratio: {ratio:.2f}x  ({'+' if ratio > 1 else ''}{(ratio - 1) * 100:.1f}%)")
```

Run this across a **representative sample** of your production traffic — not just one prompt. Averages across diverse inputs are more predictive than single-prompt tests.

<RunPromptCell
  model="claude-opus-4-7"
  prompt="I want to compare token usage between claude-opus-4-6 and claude-opus-4-7 for the following prompt: 'Analyze this Python async function for potential race conditions: async def fetch_user(user_id): conn = await db.connect(); result = await conn.execute(SELECT * FROM users WHERE id = ?); return result'. Using the Anthropic token counting endpoint, call count_tokens on both models and report: (1) token count for each model, (2) the ratio, (3) the percentage difference."
  expectedOutput="Token counts will differ slightly by ~5–15% for typical code-heavy content. The ratio should be 1.05–1.15x. The model should explain that exact numbers depend on the tokenizer and that representative sampling across real traffic is more reliable than a single prompt."
  <!-- TODO: verify exact ratio with QA on this specific code snippet -->
/>

---

## Effort levels: five tiers, one new default

The `effort` parameter controls how deeply Claude reasons before responding. Opus 4.7 adds `xhigh` between `high` and `max`.[^4]

| Level | Guidance for Opus 4.7 |
|-------|----------------------|
| `low` | Short, scoped tasks. Pair with explicit checklists for multi-section work. |
| `medium` | Cost-sensitive workloads where good output beats perfect output. |
| `high` | Most intelligence-sensitive workloads; the sweet spot for quality/cost balance. |
| `xhigh` | **Recommended starting point for coding and agentic work.** Claude Code default. |
| `max` | When evals show measurable headroom beyond `xhigh`. Can overthink structured tasks. |

One behavioral change from 4.6 that trips developers up: **Opus 4.7 respects effort levels strictly**, especially at `low` and `medium`.[^4] At those levels the model scopes its work to exactly what was asked and does not go above and beyond. If you observe shallow reasoning on a complex problem, raise effort rather than prompting around it. If you must stay at `low` for latency reasons, add targeted guidance: *"This task involves multi-step reasoning. Think carefully before responding."*[^3]

<Callout type="warn">
**`max` effort warning.** Anthropic's own documentation cautions that `max` can materially increase token usage for relatively small quality gains — and on some structured tasks it can overthink its way into worse answers. Only step up to `max` when your evals show measurable headroom beyond `xhigh`.[^4]
</Callout>

**Why `xhigh` became the Claude Code default — and why it was bumpy.** This wasn't a smooth rollout. On April 23, Anthropic published a postmortem revealing that an initial decision to set Claude Code's default to `high` produced quality complaints from users.[^5] After hearing feedback, they reversed it on April 7: all users now default to `xhigh` for Opus 4.7.[^5] The postmortem also documented a separate caching optimization that accidentally dropped prior reasoning from conversation history, compounding the quality drop on multi-turn tasks. Both issues are resolved, but the incident is worth knowing: `xhigh` is not just a marketing recommendation, it is Anthropic's own revised operational default after a real incident.[^5]

<KnowledgeCheck
  question="You're running a cost-sensitive batch summarization job: single-turn prompts, no tool use, 100k requests/day. Which effort level should you start with?"
  options={[
    "max — for the highest quality summaries",
    "xhigh — it's the recommended default for all work",
    "medium — cost-sensitive, single-turn; lower if quality holds",
    "low — always start lowest and tune up"
  ]}
  correct={2}
  explanation="xhigh is the recommended starting point specifically for coding and agentic work. For cost-sensitive single-turn summarization, start at medium — it gives good output with lower token spend. Drop to low only if medium already overshoots quality needs. Only step up to high or xhigh if summarization quality is measurably insufficient."
/>

---

## Task budgets: advisory spend control for long-running agents

Task budgets let you inform Claude how many tokens it has for a complete agentic loop — thinking, tool calls, tool results, and final output.[^3] The model sees a running countdown and uses it to prioritize work and finish gracefully as the budget is consumed. This is **advisory**, not a hard cap — that remains `max_tokens`.

Enable with the beta header `task-budgets-2026-03-13`:

```python
import anthropic

client = anthropic.Anthropic()

response = client.messages.create(
    model="claude-opus-4-7",
    max_tokens=65536,                          # hard ceiling
    thinking={"type": "adaptive"},
    extra_headers={"anthropic-beta": "task-budgets-2026-03-13"},
    output_config={
        "effort": "xhigh",
        "task_budget": {"type": "tokens", "total": 50000},   # advisory target
    },
    messages=[{
        "role": "user",
        "content": "Refactor the auth module to use JWT refresh tokens. Verify tests pass."
    }]
)
```

Use `task_budget` when you want the model to self-moderate spend across a long agent run. Use `max_tokens` as the absolute ceiling above it. For the migration exercise below, you will set `task_budget` to 150% of your Opus 4.6 output-token baseline to keep the upgrade cost-neutral by default.[^3]

---

## Why stricter instruction following breaks your old prompts

This is the migration risk that most teams discover in production rather than testing. Opus 4.6 was a lenient interpreter: if you wrote a vague instruction, it used context clues to fill in what you probably meant. **Opus 4.7 does not do this.** It treats your instructions as a specification and follows them literally.[^1]

Two patterns that reliably break:

**Implied format expectations.** Prompt: *"Summarize this document."* Opus 4.6 would infer a reasonable length from document size and context. Opus 4.7 may produce a single sentence — technically correct given the instruction, but not what you wanted.

**Implied scope boundaries.** Prompt: *"Fix the bug in this function."* Opus 4.6 might notice and fix three related issues. Opus 4.7 fixes the one bug you named and stops.

**Remediation pattern:** Audit every system prompt for implied context. Make length, format, scope, and edge-case handling explicit. Treat your prompts like a function signature — every parameter the model needs to make a decision should be spelled out.

The system card provides an additional caution: stricter instruction following extends to safety-relevant behavior too.[^6] Instructions that previously produced mild refusals may now either strictly comply or strictly refuse depending on exact wording. Test edge cases before deploying to production.

<KnowledgeCheck
  question="You migrate a customer-support bot from Opus 4.6 to Opus 4.7. Your system prompt says: 'Respond helpfully to user questions.' In testing, responses are unusually terse — sometimes a single sentence. What is the most likely cause?"
  options={[
    "The new tokenizer is compressing output to save tokens",
    "effort defaults to low on the API, producing minimal output",
    "Stricter instruction following: 'helpfully' with no length or format spec allows a one-sentence answer",
    "A bug in task_budget is cutting off output early"
  ]}
  correct={2}
  explanation="Opus 4.7's literal instruction following means 'respond helpfully' with no length or format guidance allows a minimal-but-technically-correct response. Fix: add explicit guidance — 'Respond in 2–4 sentences. If the user's question would benefit from clarification, ask one follow-up question.'"
/>

---

## Migration checklist

Before switching `claude-opus-4-6` to `claude-opus-4-7` in production:[^3]

1. **Remove `temperature`, `top_p`, and `top_k`** — setting any of these to non-default values returns a 400 error.
2. **Replace manual thinking budgets** — `thinking: {type: "enabled", budget_tokens: N}` is removed. Use `thinking: {type: "adaptive"}`.
3. **Audit token-count expectations** — run representative prompts through the Token Counting API against both models and measure the ratio.
4. **Set explicit effort** — start with `xhigh` for coding and agentic work; `high` as the minimum for most intelligence-sensitive workloads.
5. **Set a generous `max_tokens`** at `xhigh` or `max` — start at 64k and tune down. The model needs headroom to think across tool calls and subagents.[^3]
6. **Audit system prompts for implied context** — make length, format, scope, and edge cases explicit.
7. **Adopt task budgets (beta)** — for long-running agentic loops, set `task_budget` to an advisory token target to help the model self-manage spend.[^3]

What **does not change**: 1M context window, 128k max output, $5/$25 pricing, prompt caching, 50%-discount batch processing, Files API, PDF support, and the full server-side and client-side tool set (bash, code execution, computer use).[^1][^9]

---

## Hands-on exercise

**Migrate a three-turn tool-use script from Opus 4.6 to Opus 4.7, compare token usage across effort levels, and set a task budget that caps spend at 150% of the Opus 4.6 baseline.**

Prerequisites: Anthropic API key with credits; Python 3.10+.

```python
import anthropic

client = anthropic.Anthropic()

# ── Step 1: Measure the tokenizer delta ──────────────────────────────────────
messages = [
    {"role": "user", "content": (
        "Get the weather for London and Tokyo, compare them, "
        "and recommend which city is better for an outdoor event this weekend."
    )}
]

old_tokens = client.messages.count_tokens(model="claude-opus-4-6", messages=messages).input_tokens
new_tokens = client.messages.count_tokens(model="claude-opus-4-7", messages=messages).input_tokens
print(f"Tokenizer ratio: {new_tokens / old_tokens:.2f}x")

# ── Step 2: Establish Opus 4.6 output-token baseline ─────────────────────────
baseline = client.messages.create(
    model="claude-opus-4-6",
    max_tokens=4096,
    messages=messages,
)
baseline_output_tokens = baseline.usage.output_tokens
print(f"Opus 4.6 baseline output tokens: {baseline_output_tokens}")

# ── Step 3: Run Opus 4.7 with task_budget capped at 150% of baseline ─────────
budget = int(baseline_output_tokens * 1.5)

response = client.messages.create(
    model="claude-opus-4-7",
    max_tokens=65536,
    thinking={"type": "adaptive"},
    extra_headers={"anthropic-beta": "task-budgets-2026-03-13"},
    output_config={
        "effort": "xhigh",
        "task_budget": {"type": "tokens", "total": budget},
    },
    messages=messages,
)

print(f"Task budget: {budget} tokens (150% of baseline)")
print(f"Output tokens used: {response.usage.output_tokens}")
print(f"Budget utilization: {response.usage.output_tokens / budget:.1%}")
print(f"\nResponse:\n{response.content[0].text}")
```

<RunPromptCell
  model="claude-opus-4-7"
  prompt="You have an advisory token budget of 800 tokens for this full response. Task: (1) Get weather for London (assume 12°C, partly cloudy) and Tokyo (assume 28°C, sunny). (2) Compare both cities for an outdoor event this weekend. (3) Make a recommendation with one sentence of reasoning. Stay within the advisory budget — if you are close to the limit, finish the recommendation concisely rather than elaborating."
  expectedOutput="A three-part response: weather summary for each city, a brief comparison (Tokyo clearly warmer/sunnier), and a concise recommendation for Tokyo. Total should be well under 800 tokens. The model should not pad the response beyond what's needed."
  <!-- TODO: verify with QA that model self-limits to budget appropriately -->
/>

**What to look for:**
- The tokenizer ratio should be between 1.0× and 1.35×. If it's higher, your prompt may have unusual content — check for dense multi-language or special-character sections.
- Budget utilization near 100% means the task is well-scoped for the budget. Utilization well under 50% means the budget was generous — you can lower it on future runs to catch overruns earlier.
- Compare the Opus 4.7 output to the Opus 4.6 baseline for quality: if 4.7 is meaningfully better at the same or lower token count, you have headroom to tighten the budget further.

---

## What's next

Chapter 2 covers the Managed Agents architecture — the decoupled brain/hands design that runs Opus 4.7 as an orchestrating substrate for multi-step work rather than a single-turn model. If you plan to build multi-server MCP pipelines after completing this course, the [[production-agents-claude-agent-sdk-mcp-connector]] course covers the full production deployment stack.

---

<CitationFootnote source="[^1] Anthropic — Introducing Claude Opus 4.7 — https://www.anthropic.com/news/claude-opus-4-7 · retrieved 2026-04-16" />
<CitationFootnote source="[^2] Anthropic — Pricing — https://docs.anthropic.com/en/docs/about-claude/pricing · retrieved 2026-06-10" />
<CitationFootnote source="[^3] Anthropic — Migration guide: Migrating to Claude Opus 4.7 — https://docs.anthropic.com/en/docs/about-claude/models/migrating-to-claude-4 · retrieved 2026-06-10" />
<CitationFootnote source="[^4] Anthropic — Effort — https://docs.anthropic.com/en/docs/build-with-claude/effort · retrieved 2026-06-10" />
<CitationFootnote source="[^5] Anthropic Engineering — April 23 quality postmortem — https://www.anthropic.com/engineering/april-23-postmortem · retrieved 2026-04-23" />
<CitationFootnote source="[^6] Anthropic — Claude Opus 4.7 System Card — https://anthropic.com/claude-opus-4-7-system-card · retrieved 2026-04-16" />
<CitationFootnote source="[^7] Caylent — Claude Opus 4.7 Deep Dive: Capabilities, Migration, and the New Economics of Long-Running Agents — https://caylent.com/blog/claude-opus-4-7-deep-dive-capabilities-migration-and-the-new-economics-of-long-running-agents · retrieved 2026-06-10" />
<CitationFootnote source="[^8] Lushbinary — Claude Opus 4.7: Benchmarks, Vision, Migration — https://lushbinary.com/blog/claude-opus-4-7-developer-guide-benchmarks-vision-migration · retrieved 2026-06-10" />
<CitationFootnote source="[^9] Anthropic — Models overview — https://docs.anthropic.com/en/docs/about-claude/models · retrieved 2026-06-10" />
