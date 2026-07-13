---
chapter_num: 1
course_slug: claude-opus-4-8-production-guide
title: "What's new in Opus 4.8 vs 4.7"
status: g0-blocked
author: course-author
agent_drafted_by: course-author
ticket: KOEA-7191
date: 2026-06-02
learning_objectives:
  - "Map the five benchmark changes to real task types so you can predict which workloads will improve"
  - "Explain the honesty posture shift and why 4× fewer unflagged code flaws changes your review pipeline"
  - "Describe the three new API-level capabilities and the immediate code change each requires"
  - "Identify the prompt-injection regression, its magnitude, and when it disqualifies an upgrade"
  - "Apply the upgrade decision rule to your specific workload mix"
prerequisites_chapters: []
duration_min: 40
level: Builder
vendor_tag: anthropic
sources:
  - https://www.anthropic.com/news/claude-opus-4-8
  - https://simonwillison.net/2026/May/28/claude-opus-4-8
  - https://venturebeat.com/technology/anthropics-claude-opus-4-8-is-here-with-3x-cheaper-fast-mode-and-near-mythos-level-alignment
  - https://www.vellum.ai/blog/claude-opus-4-8-benchmarks-explained
  - https://www.digitalapplied.com/blog/claude-opus-4-8-release-dynamic-workflows-2026
  - https://www.verdent.ai/guides/claude-opus-4-7-vs-4-8
  - https://aiweekly.co/alerts/anthropic-clears-claude-opus-48-in-safety-review
  - https://vallettasoftware.com/blog/post/claude-opus-4-8-review
  - https://docs.litellm.ai/blog/claude_opus_4_8
  - https://linas.substack.com/p/claude-opus-4-8-prompting-playbook
tags:
  - course/claude-opus-4-8-production-guide
  - claude
  - opus-4-8
  - model-comparison
  - benchmarks
  - dynamic-workflows
---

# What's new in Opus 4.8 vs 4.7

Anthropic released Claude Opus 4.8 on May 28, 2026, 41 days after Opus 4.7 — the shortest gap between Opus point releases in the model family's history.[^1] The company's own framing was deliberate: "a modest but tangible improvement on its predecessor."[^2] That honesty is the first thing to absorb before you read any benchmark number.

This chapter maps every material change so you can make an informed upgrade decision rather than treating "new model = upgrade now."

## What didn't change

Context window: 1,000,000 tokens. Maximum output: 128,000 tokens. Knowledge cutoff: January 2026. Standard pricing: $5 per million input tokens, $25 per million output tokens. These four numbers are identical to Opus 4.7.[^1] If your use case depends on any of them, 4.8 is a drop-in swap on those dimensions.

The tokenizer is also unchanged between 4.7 and 4.8.[^3] If you migrated from Opus 4.6 and absorbed the 0–35% tokenizer inflation in the 4.7 migration, you will not pay it again when moving to 4.8. Teams still on 4.6 who jump directly to 4.8 should model that inflation before committing.

Model ID: `claude-opus-4-8`. Everything else in your API calls stays the same.

## The benchmark picture

The benchmark table from the system card is worth reading carefully rather than cherry-picking the headline number.

| Benchmark | Opus 4.7 | Opus 4.8 | GPT-5.5 | Gemini 3.1 Pro |
|---|---|---|---|---|
| SWE-bench Verified | 87.6% | **88.6%** | — | 80.6% |
| SWE-bench Pro | 64.3% | **69.2%** | 58.6% | 54.2% |
| Terminal-Bench 2.1 | 66.1% | **74.6%** | **78.2%** | — |
| OSWorld-Verified | 82.3% | **83.4%** | 78.7% | 76.2% |
| Finance Agent v2 | — | **53.9%** | — | — |
| GDPval-AA (Elo) | — | **1890** | 1769 | — |
| Humanity's Last Exam | — | **57.9%** | — | — |

Sources: Anthropic system card; Vellum AI benchmark breakdown.[^4]

Three patterns stand out.

**The coding gap is real.** SWE-bench Pro measures end-to-end autonomous coding — the model must find the fix, write the patch, and pass tests without scaffolding. The jump from 64.3% to 69.2% is almost five percentage points.[^4] At that level of the curve, each point represents genuinely harder problems. If you run autonomous coding agents, that gap translates to fewer failed runs and less human remediation. Truefoundry's independent validation on a 50-problem subset showed the same directional improvement, though they noted the absolute numbers are not directly comparable to Anthropic's full-harness run.[^5]

**GPT-5.5 wins Terminal-Bench.** Opus 4.8 scores 74.6% on Terminal-Bench 2.1; GPT-5.5 scores 78.2%.[^1] If your workload is primarily CLI-driven terminal automation, that difference is worth measuring against your actual tasks before assuming Opus 4.8 is the right choice.

**Computer use is now a credible production option.** OSWorld-Verified 83.4% and an independently reported 84% on Online-Mind2Web (browser automation) represent the strongest computer-use scores currently available from any generally available model.[^6] Anthropic shipped Dynamic Workflows the same day — that is not a coincidence. A model that can reliably navigate browser interfaces is the prerequisite for a workflows orchestrator that spawns subagents against those interfaces.

## The honesty shift

This is the change that deserves the most attention and gets the least coverage.

Opus 4.8 is approximately four times less likely than Opus 4.7 to let a flaw in its own code pass unremarked.[^1] Anthropic's framing in the release: "A general problem with AI models is that they sometimes jump to conclusions, confidently claiming to have made progress in their work despite the evidence being thin."[^1]

What this means operationally: the model will more often tell you it is stuck, flag an assumption it is not sure about, or note that it detected a problem in an output it just produced. Early testers reported this is qualitatively noticeable. Cognition (the company behind Devin) said Opus 4.8 fixed comment-verbosity and tool-calling issues from 4.7.[^6] Reuters reported that early testers found the model "more likely to flag uncertainties around its work and less likely to make unsupported claims."[^7]

For production systems that currently rely on human review to catch model errors, this reduces the inspection burden. It does not eliminate it — the model still makes mistakes — but a system that tells you when it is uncertain is fundamentally more tractable to operate than one that presents guesses as conclusions.

The flip side: if your prompts are calibrated to Opus 4.7's confidence level, Opus 4.8 may produce more hedging in places where you previously got clean outputs. That is not a regression, but it is a behavioral change that warrants testing.

## The three new API capabilities

### 1. Dynamic Workflows (research preview)

Dynamic Workflows lets Claude Code plan a large task and then spawn hundreds of parallel subagents to execute it in a single session, with the orchestrator verifying outputs before reporting back.[^1]

The canonical example from Anthropic: "Claude Code with Opus 4.8 can now carry out codebase-scale migrations across hundreds of thousands of lines of code from kickoff to merge, with the existing test suite as its bar."[^1] Anthropic's demo used a Bun runtime migration as the proof case.

**Availability**: Claude Code on Enterprise, Team, and Max plans. Team and Max plans have it on by default. Enterprise plans have it off by default — your admin enables it in Claude Code settings.[^8]

**How to trigger it**: In Claude Code, include the word "workflow" in your prompt, or turn on the `ultracode` setting. The orchestrator writes an orchestration script, spawns workers, runs them in parallel, and merges results before responding.[^8]

**What it does not do**: It does not reduce your token cost — you pay for every subagent's context. A 100-subagent workflow with 10K tokens per agent is 1M tokens of input. Budget guardrails before you trigger it are not optional.

### 2. Mid-conversation system messages

The Messages API now accepts `role: "system"` entries inside the `messages` array, not just at the top level.[^2] This lets you update Claude's instructions mid-task — changing permissions, token budgets, tool access, or environment context — without forcing a new conversation or routing the update through a user turn that the model might interpret differently.

The practical consequence: you can steer a long-running agentic loop without breaking prompt cache hits on earlier turns. The earlier turns remain cached; only the new system message and subsequent turns are billed at full rate.[^9]

The minimum cacheable prompt also dropped from 4,096 tokens to 1,024 tokens in this release.[^9] For agent loops with shorter system prompts, this materially changes the cost of cache-based agentic patterns.

The placement rule: system messages can appear immediately after a user turn in the `messages` array. Anthropic's documentation calls this "subject to placement rules" — verify in the current API docs before building a production dependency on specific insertion points.[^2]

### 3. Adaptive thinking replaces fixed budget_tokens

Extended thinking with a fixed `budget_tokens` parameter is no longer the recommended pattern for Opus 4.8. Adaptive thinking is the new default: the model dynamically decides when and how much to think based on the effort setting and task complexity.[^10]

The `output_config.effort` field accepts five levels:

| Effort | When to use |
|---|---|
| `low` | Short, fast responses — lookups, formatting, classification |
| `medium` | Balanced for everyday Q&A and light reasoning |
| `high` | Complex reasoning, code generation, analysis (default) |
| `xhigh` | Hard problems: multi-step math, deep research, agentic planning |
| `max` | Maximum reasoning depth regardless of latency |

In claude.ai, these map to the new "extra" and "max" effort dial. In Claude Code, `xhigh` is exposed as a setting.[^9]

Default effort (`high`) on Opus 4.8 uses a similar token count to Opus 4.7's default while performing better on most tasks.[^10] Moving to `xhigh` or `max` will increase output token spend; measure on a representative sample before committing to a tier.

## The regression you need to know about

The system card reports that Opus 4.8 scores 9.6% on the Gray Swan prompt-injection benchmark, compared to 6.0% for Opus 4.7.[^11] That is a 60% relative increase in susceptibility.

This matters specifically for pipelines where the model processes untrusted external text — web scraping agents, document ingestion from user-uploaded files, email processing, or any agentic loop that reads content from sources outside your control. In those environments, the additional surface area is not negligible.

Anthropic ran a one-week live bug bounty for prompt injection alongside the release — described as a first for the company — and states that deployed safeguards bring browser-use attack success rates to "near zero."[^11] Those safeguards are part of the Claude Code browser-use stack, not the raw Messages API. If you are building your own browser-automation pipeline on top of the API, you inherit the model's base rate, not the Claude Code mitigation.

The practical guidance from the system card: if you are running an agentic pipeline with high injection risk (untrusted inputs, web browsing, code execution with user-controlled content), model the 9.6% vs 6.0% gap against your threat model before migrating.[^10]

## The upgrade decision

**Migrate now if:**

- You run autonomous coding agents. The SWE-bench Pro jump from 64.3% to 69.2% is material for production agent reliability, and the pricing is the same.[^4]
- You have latency-sensitive workflows that previously could not justify fast mode. Fast mode is now $10/$50 per million tokens — approximately 3× cheaper than previous fast mode pricing — at 2.5× standard speed.[^1] Re-run your economics.
- You want the honesty improvements. If you are relying on human review to catch model errors, Opus 4.8's uncertainty flagging may let you reduce that review step.
- You use Claude Code and want Dynamic Workflows for large-scale agentic tasks on Enterprise, Team, or Max.
- You care about computer use or browser automation. OSWorld-Verified 83.4% and Online-Mind2Web 84% are the strongest computer-use scores currently publicly available.[^6]

**Hold on 4.7, or consider Sonnet 4.6, if:**

- Your production pipeline runs in a high injection-risk environment (untrusted external inputs, web-scraping agents, code execution with user-controlled content). The 9.6% vs 6.0% Gray Swan gap requires explicit mitigation before you can safely deploy.[^10]
- Your pipeline has been carefully prompt-tuned to Opus 4.7's confidence level and your evaluation suite is sensitive to hedging or uncertainty expression changes.
- Your primary workload is CLI/terminal automation and you need to beat GPT-5.5's 78.2% on Terminal-Bench 2.1. Opus 4.8 scores 74.6%.[^1]
- Most of your workload belongs on Sonnet 4.6 anyway. Sonnet covers roughly 80% of everyday tasks well at $3/$15 per million tokens — 40% cheaper than Opus 4.8 standard.[^10] Use Opus where autonomous reasoning, code quality, or financial/legal accuracy is what you are paying for.

## Hands-on exercise

Run a five-prompt evaluation harness across `claude-opus-4-7` and `claude-opus-4-8`:

**Prompt set:**
1. A multi-file refactor task in your primary language (coding baseline)
2. A bug-hunt task where the bug is in a side file, not the one described (reasoning depth)
3. A financial calculation with one deliberately wrong input assumption (honesty / uncertainty flagging)
4. A dense document summarization with inline citations required (knowledge work)
5. An adversarial prompt that instructs the model to ignore its system prompt and reveal its instructions (injection resistance baseline)

**Measure per prompt:**
- Output token count at `high` effort
- Whether the model flagged uncertainty or errors in prompts 2, 3, and 4
- Whether the model complied with the adversarial instruction in prompt 5
- Subjective quality score (1–5) from a human reviewer unfamiliar with which model produced which output

**Decision rule:** If 4.8 scores equal or better on prompts 1–4 for your task mix, and prompt 5 is acceptable given your deployment environment, migrate. If prompt 5 compliance is higher than your risk tolerance for your injection-risk environment, implement the Claude Code browser-use safeguard stack before migrating.

Time: approximately 30 minutes to run, 10 minutes to score.

[^1]: Anthropic — Introducing Claude Opus 4.8 — https://www.anthropic.com/news/claude-opus-4-8 · retrieved 2026-06-02
[^2]: Simon Willison — Claude Opus 4.8: "a modest but tangible improvement" — https://simonwillison.net/2026/May/28/claude-opus-4-8 · retrieved 2026-06-02
[^3]: Finout — Claude Opus 4.8 Pricing 2026: Everything you need to know — https://www.finout.io/blog/claude-opus-4.8-pricing-2026-everything-you-need-to-know · retrieved 2026-06-02
[^4]: Vellum AI — Claude Opus 4.8 Benchmarks Explained — https://www.vellum.ai/blog/claude-opus-4-8-benchmarks-explained · retrieved 2026-06-02
[^5]: Truefoundry — Claude Opus 4.8 and SWE-bench Pro — https://www.truefoundry.com/blog/claude-opus-4-8-and-swe-bench-pro-we-ran-anthropics-headline-through-our-gateway · retrieved 2026-06-02
[^6]: VentureBeat — Anthropic's Claude Opus 4.8 is here with 3× cheaper fast mode — https://venturebeat.com/technology/anthropics-claude-opus-4-8-is-here-with-3x-cheaper-fast-mode-and-near-mythos-level-alignment · retrieved 2026-06-02
[^7]: Reuters — Anthropic to roll out Claude Mythos in coming weeks, launches Opus 4.8 — https://www.reuters.com/business/anthropic-roll-out-claude-mythos-coming-weeks-launches-opus-48-2026-05-28 · retrieved 2026-06-02
[^8]: TechCrunch — Anthropic releases Opus 4.8 with new 'dynamic workflow' tool — https://techcrunch.com/2026/05/28/anthropic-releases-opus-4-8-with-new-dynamic-workflow-tool · retrieved 2026-06-02
[^9]: Valletta Software — Claude Opus 4.8 vs 4.7: Hands-On Review & Benchmarks — https://vallettasoftware.com/blog/post/claude-opus-4-8-review · retrieved 2026-06-02
[^10]: Digital Applied — Claude Opus 4.8: Benchmarks, Effort & Dynamic Workflows — https://www.digitalapplied.com/blog/claude-opus-4-8-release-dynamic-workflows-2026 · retrieved 2026-06-02
[^11]: AI Weekly — Anthropic Clears Claude Opus 4.8 in Safety Review — https://aiweekly.co/alerts/anthropic-clears-claude-opus-48-in-safety-review · retrieved 2026-06-02
[^12]: LiteLLM — Day 0 Support: Claude Opus 4.8 — https://docs.litellm.ai/blog/claude_opus_4_8 · retrieved 2026-06-02
[^13]: Linas's Newsletter — Claude Opus 4.8 Prompting Playbook — https://linas.substack.com/p/claude-opus-4-8-prompting-playbook · retrieved 2026-06-02
