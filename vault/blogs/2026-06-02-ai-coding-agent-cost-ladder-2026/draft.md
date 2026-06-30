---
date: 2026-06-02
author: blog-author
ticket: KOEA-7173
vendor_tag: multi-vendor
content_type: article
status: g0-passed
reading_time_min: 9
primary_query: "ai coding agent cost per task 2026"
contrarian_angle: "The cheapest AI coding tool is not the one with the lowest subscription price — it's the one whose billing model doesn't surprise you. GitHub Copilot just scrapped its request-quota system on June 1, 2026. Devin's ACU pricing looks expensive until you realize it's the only model where you can calculate ROI before you commit."
first_60_words_answer: "GitHub Copilot is cheapest at $0.04–$0.52 per medium task. Cursor and Codex CLI sit at $0.06–$3.00. Claude Code Max runs $0.50–$5.00 but leads on benchmark accuracy. Devin costs $2.25–$45+ per task but prices by compute time — making it the only tool where you can calculate ROI before you start. Billing model risk matters more than sticker price in 2026."
original_data: true
description: "Normalized $/task benchmarks across GitHub Copilot, Cursor, Codex CLI, Claude Code, and Devin — derived from 14 primary sources and community-tracked billing data. Includes methodology, time-vs-cost scatter, false economy analysis, and team-size recommendations."
seo_description: "Normalized cost-per-task benchmarks for Copilot, Cursor, Codex CLI, Claude Code, and Devin - plus billing-model risk analysis for engineering teams in 2026."
last_updated: 2026-06-02
hero_image:
  url: /img/blogs/2026-06-02-ai-coding-agent-cost-ladder-2026/hero.png
  alt: "Table showing $/task costs across five AI coding tools: Copilot at $0.04, Cursor at $0.06, Codex at $0.15, Claude Code at $0.50, and Devin at $2.25 per task at minimum"
positions: []
faq:
  - question: "How much does Claude Code actually cost per task in 2026?"
    answer: "On the Max 5× plan ($100/month), Claude Code costs roughly $0.50–$3.00 per medium task after amortizing the subscription across a realistic workload of 3–5 complex agent sessions per day. API-only users report $6/day average spend (Anthropic's own data), and one developer tracked $1,200 total over 8 months on the $100/month Max plan — a 93% saving over equivalent raw API pricing. The caveat: Pro plan ($20/month) exhausts in 1–2 hours of focused agent work, making it unusable as a daily driver. [Source: morphllm.com/ai-coding-costs, 2026-06-02]"
  - question: "Is Devin worth the cost in 2026?"
    answer: "Devin's Team plan ($500/month) breaks even at ~7 hours of saved developer time per month for a developer earning $150K/year. At the Core plan ($20 base, $2.25/ACU), simple tasks cost $2.25–$4.50 and are cost-competitive with Claude Code for bounded, well-specified work. Where Devin loses value: exploratory or ambiguous tasks balloon to 20+ ACUs ($40–$45) with no default hard stop. Devin wins on parallelizable, repeatable backlog items where you can template the spec. [Source: idlen.io/devin-review-2026, pensero.ai/devin-pricing, 2026-06-02]"
  - question: "What changed about GitHub Copilot pricing on June 1, 2026?"
    answer: "GitHub switched all Copilot monthly subscribers from a premium-request quota model to usage-based AI Credits billing. Under the old model, Pro users had ~300 premium requests/month at fixed $10. Under the new model, 1 AI Credit = 1 premium request in most cases, but premium models (Claude Opus 4.6, GPT-4.5) consume credits at 2–3× rate. Code review now costs 13× the baseline rate per run. Enterprise finance teams need to re-model Copilot cost projections from scratch as of June 2026. [Source: github.blog/copilot-usage-billing, benday.com/copilot-billing-2026, 2026-06-02]"
  - question: "Why do 60–80% of tokens in AI coding sessions go to navigation, not code generation?"
    answer: "Studies cited by Morph (2026) and an analysis of 42 agent runs on a FastAPI codebase found that most tokens in a coding session are consumed locating context — finding the right file, tracing call chains, reading test output — rather than writing the fix. One documented run found 87% of token spend was on navigation. This is why prompt caching (Codex's $0.25/M cached input) and context compaction (Claude Code's --compact flag) can cut effective $/task by 30–50% without changing the underlying model or task. [Source: morphllm.com/ai-coding-costs, 2026-06-02]"
  - question: "How does Cursor's credit model compare to Claude Code's subscription model?"
    answer: "Both charge a flat monthly fee but exhaust differently. Cursor Pro ($20/month) provides a credit pool billed at API token rates — $1.25/M input, $6.00/M output in Auto mode. Claude Code Max 5× ($100/month) provides a rate-limit cap. One developer tracked Cursor usage over 70 days: 65.7% of requests cost under $0.05, but projected monthly spend was ~$416, implying heavy agent use on frontier models can exceed the plan value by 20×. Claude Code Max converts that variable cost into a predictable ceiling; the tradeoff is a higher entry price. [Source: news.ycombinator.com/item?id=45914307, vantage.sh/cursor-pricing, 2026-06-02]"
  - question: "What is Codex CLI's billing model after April 2026?"
    answer: "OpenAI switched Codex to token-based billing on April 23, 2026. The default model (GPT-5.4) bills at $2.50/M input, $0.25/M cached input, $15/M output. Codex Cloud container sessions add $0.03–$1.92 per 20-minute session (1GB–64GB containers). The 240+ token/second throughput makes Codex CLI the fastest option for high-volume tasks, but the long-context surcharge (2×/1.5× over 272K tokens) makes large-repository work disproportionately expensive. For large codebases, explicit context scoping — rather than repo-wide indexing — is the key cost control. [Source: verdent.ai/codex-pricing-2026, blakecrosley.com/codex-vs-claude-code, 2026-06-02]"
sources:
  - https://www.morphllm.com/ai-coding-costs
  - https://www.morphllm.com/ai-coding-agent
  - https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing
  - https://www.benday.com/blog/copilot-billing-2026
  - https://www.verdent.ai/guides/codex-pricing-2026
  - https://blakecrosley.com/blog/codex-vs-claude-code-2026
  - https://pensero.ai/blog/devin-pricing
  - https://www.idlen.io/blog/devin-ai-engineer-review-limits-2026
  - https://uibakery.io/blog/cursor-ai-pricing-explained
  - https://www.vantage.sh/blog/cursor-pricing-explained
  - https://news.ycombinator.com/item?id=45914307
  - https://ijonis.com/en/ai-coding-tools-pricing
  - https://www.developersdigest.tech/blog/ai-coding-tools-pricing-2026
  - https://cosine.sh/blog/ai-coding-agent-pricing-task-vs-token
whats_new:
  - "GitHub Copilot switched from request quotas to usage-based AI Credits on June 1, 2026 — code review now costs 13× the baseline per run."
  - "OpenAI Codex moved to token-based billing in April 2026, replacing per-message estimates with GPT-5.4 token rates."
  - "Research data: 60–80% of tokens in coding agent sessions go to navigation, not code generation — meaning most of your bill is context overhead, not productive output."
learning_objectives:
  - "Calculate normalized $/task for your workload using the subscription amortization method in the methodology section."
  - "Identify the billing model trap most likely to hit your team — request quotas, credit pools, or ACU compute units."
  - "Apply context compaction and prompt caching to recapture 30–50% of token waste before upgrading to a pricier plan."
---

# The 2026 AI Coding Agent Cost Ladder: What You Actually Pay Per Task

**GitHub Copilot is cheapest at $0.04–$0.52 per medium task. Cursor and Codex CLI run $0.06–$3.00. Claude Code Max costs $0.50–$5.00 but leads on benchmark accuracy. Devin prices by compute time ($2.25–$45+ per task) — making it the only tool where you can calculate ROI before you commit. Billing model risk matters more than subscription price in 2026.**

The sticker price is a floor, not a ceiling. Every major AI coding tool advertises an entry price between $10 and $20/month, but production developers routinely spend 5–20× that. Heavy Claude Code API users report $500–$2,000/month. One Cursor Pro team burned through a $7,000 annual subscription in a single day after a June 2025 billing model change. GitHub Copilot silently rewrote its billing model on June 1, 2026 — code reviews now consume 13× more credits per run than a standard request.

The problem isn't which tool is cheapest. The problem is that none of them make $/task legible by default — except Devin, which is why developers perceive it as expensive even when the per-task math is often competitive.

This post normalizes billing data from 14 primary sources into a per-task cost ladder across five mainstream tools. Raw data: [`vault/research/_benchmarks/cost-ladder-2026-06.csv`](/research/cost-ladder-2026-06.csv).

---

## Methodology

**Normalization approach:** We translated each tool's billing model into $/task using three representative task complexities: simple (CRUD endpoint, ~10 min active work), medium (function refactor, ~20–30 min), and complex (multi-file bug in streaming server, ~40–60 min). For subscription tools, we amortized the monthly plan across a realistic daily workload (3–5 complex agent sessions per working day = ~75 sessions/month). For ACU-based tools (Devin), we used vendor-published rates directly.

**Data sources:** 14 sources retrieved June 2, 2026 — vendor pricing pages, community-tracked billing logs (HackerNews thread with 70-day individual Cursor usage data), independent developer breakdowns, and a Morph Labs token-waste analysis. Freshness: 79% of citations under 30 days old.

**What we did not measure:** We did not run the tools against a live test harness in this analysis (watch KOEA-7169 for live benchmark results). These are derived costs from the best-available community data, normalized to a consistent per-task model. They represent credible ranges, not laboratory measurements.

**Important caveat:** Two billing models changed in Q2 2026 and break prior cost estimates:
- **GitHub Copilot → AI Credits** (June 1, 2026): Enterprise teams must re-model from scratch.
- **OpenAI Codex → token-based billing** (April 23, 2026): Per-message estimates no longer apply.

---

## The Cost Ladder: Results Table

**Medium complexity task (~20–30 min active work, e.g., refactoring a 200-line monolithic function)**

| Tool | Plan | Monthly Cost | $/Task Low | $/Task Mid | $/Task High | Billing Model | SWE-bench |
|------|------|-------------|-----------|-----------|------------|---------------|-----------|
| GitHub Copilot | Pro | $10 | $0.08 | $0.26 | $0.52 | AI Credits (usage-based, June 2026) | 55–65% |
| Cursor | Pro | $20 | $0.15 | $0.60 | $1.50 | Credit pool at API token prices | 60–75% |
| Codex CLI | ChatGPT Plus | $20 | $0.15 | $0.50 | $1.20 | Token-based (Apr 2026), GPT-5.4 | 77.3% |
| Claude Code | Max 5× | $100 | $0.75 | $1.50 | $3.00 | Subscription cap + API | 80.9% |
| Devin | Core (ACU) | $20 base | $4.50 | $9.00 | $13.50 | $2.25/ACU (≈15 min active work) | 67% merge rate |

**Simple task (~10 min active work, e.g., add a single CRUD endpoint)**

| Tool | $/Task Low | $/Task Mid | $/Task High |
|------|-----------|-----------|------------|
| GitHub Copilot Pro | $0.04 | $0.08 | $0.17 |
| Cursor Pro | $0.05 | $0.10 | $0.25 |
| Codex CLI (Plus) | $0.10 | $0.15 | $0.25 |
| Claude Code Max 5× | $0.25 | $0.60 | $1.20 |
| Devin Core | $2.25 | $2.25 | $4.50 |

**Key observation:** On simple tasks, Devin's minimum cost ($2.25/task) is already 4× Claude Code's mid estimate. Devin earns its keep only on tasks where human engineer time exceeds the ACU cost — roughly 15–30 minutes of saved review and iteration time per task at $75/hour fully-loaded.

---

## Time vs. Cost: Where Each Tool Lives

The chart below maps each tool on a medium task (function refactor). X-axis = time to first compile-clean; Y-axis = $/task. Fast and cheap is bottom-left.

```mermaid
quadrantChart
  title Time vs. Cost — Medium Task (Function Refactor)
  x-axis Fast --> Slow
  y-axis Cheap --> Expensive
  quadrant-1 Expensive & Slow
  quadrant-2 Expensive & Fast
  quadrant-3 Cheap & Fast
  quadrant-4 Cheap & Slow
  Codex CLI: [0.18, 0.20]
  Cursor Pro: [0.28, 0.26]
  GitHub Copilot: [0.38, 0.06]
  Claude Code Max: [0.42, 0.65]
  Devin Core: [0.76, 0.90]
```

**Copilot's position is misleading.** Its low Y-axis position (cheap) conceals two costs: (1) the June 2026 AI Credits switch means code review now consumes 13× credits per run, dramatically raising real-world cost for CI-heavy teams; (2) the lower SWE-bench score (55–65% vs 80.9% for Claude Code) means more human follow-up per task. The true cost is shifted onto developer time, not the billing statement.

**Devin's top-right position is honest.** It is slow and expensive per task. But it is the only tool in this comparison where you can forecast the cost before you start: 1 ACU ≈ 15 minutes of active work, and the task spec lets you estimate ACU count. Every other tool's cost is opaque until the session ends.

---

## The False Economy Cases

### "I'll just use Copilot — it's $10/month"

A developer on Copilot Pro ($10/month) with 300 AI Credits triggers a code review on a 400-file PR. Under the new June 2026 model, code review costs 13× the baseline rate. That single run can consume 200+ credits — 67% of the monthly budget — before touching a single inline chat request. The team hits the cap on day three, work stops, and the "cheapest" choice becomes the most disruptive.

The correct comparison: **$0.08/request overage on Copilot vs. $1.50/session on Claude Code Max, where the monthly cap means sessions don't interrupt workflow.** For teams with daily CI code review, Copilot Pro is now a variable-cost tool pretending to be a fixed-cost one.

### "I'll just use Cursor Pro — it's $20/month"

Cursor Pro's credit pool is billed at market token rates: $1.25/M input, $6.00/M output in Auto mode. One developer's 70-day log showed an average of $0.06/request — but the distribution matters. 65.7% of requests cost under $0.05, while complex agent sessions ranged up to $2.78/request. A single Cloud Agent run on a 50,000-line codebase can consume 22.5% of the monthly credit in one session. The $20/month plan is designed for light use; the $200/month Ultra plan is what power users actually need.

The practical number: **$300–$400/month is the community-reported real cost for a Cursor power user**, not $20. The sticker price is a loss leader for the hobby tier.

### "Claude Code is too expensive at $100/month"

One developer tracked 8 months of Claude Code API use: 10 billion tokens consumed at Sonnet 4.6 rates would cost $15,000+ on raw API pricing. On the Max 5× plan ($100/month), total spend was ~$1,200 — a 93% saving. The Max plan converts unpredictable API billing into a fixed ceiling, which is why the apparent high cost ($100/month) is actually a cost floor and a budget guarantee.

The false economy: using the $20 Pro plan and treating it as a daily driver. Pro limits exhaust in 1–2 hours of focused agent work. **Every hour of context loss from rate-limiting is more expensive than the $80 delta between Pro and Max.**

---

## Real-World Recommendations by Team Size

### Solo developer / freelancer

**Default:** Cursor Pro ($20/month) for daily IDE work; upgrade to Claude Code Max ($100/month) if you routinely hit complex multi-file tasks. Cursor's unlimited tab completions are credit-free — the cost kicks in only with heavy Composer/Agent use.

**Watch:** Cursor credit drain on frontier models. If you're selecting Claude Sonnet or Opus manually, you're drawing from the credit pool. Stick to Auto mode for routine work.

### Team of 2–10 (startups, agencies)

**Default:** Codex CLI via ChatGPT Pro ($200/month) for high-volume code review pipelines; Claude Code Max for the 2–3 engineers doing complex reasoning work. Claude Code's 80.9% SWE-bench score means fewer follow-up prompts — which matters at team scale where iteration cost compounds.

**Watch:** Copilot Business ($19/user/month) is now usage-based. At 10 engineers, one high-activity day can exhaust a team's monthly AI Credits budget.

### Team of 10–50 (scale-ups, enterprise units)

**Consider Devin** for parallelizable backlog items (migration scripts, env setup, CI pipeline work) alongside a subscription IDE tool for interactive work. Devin's 67% PR merge rate on well-defined tasks means it earns back cost for bounded, templated work — while Cursor or Claude Code handles the exploratory sessions where Devin fails.

**ROI threshold:** A developer earning $150K/year (≈ $75/hour fully-loaded) needs Devin to save 7+ hours/month to break even on the $500/month Team plan. That's one complex delegated task per week, completed autonomously.

### Enterprise (50+ developers)

Re-model your Copilot cost projections immediately. The June 2026 AI Credits switch is not backward-compatible with request-quota budget assumptions. Run a 30-day pilot with AI Credits tracking before renewing enterprise Copilot agreements.

---

## FAQ

**What is the single biggest cost control lever across all five tools?**

Context compaction. Research data shows 60–80% of tokens in coding agent sessions go to navigation — locating the right file, reading test output, tracing call chains — rather than writing code. Claude Code's `--compact` flag and Codex CLI's $0.25/M cached input pricing can recapture 30–50% of that waste. Before upgrading your plan tier, audit whether your sessions are letting context accumulate across unrelated tasks.

**Is there a standard $/task benchmark for AI coding tools?**

No — and that is the central problem. Each vendor uses a different billing unit (AI Credits, credit pools, ACUs, token rates), making apples-to-apples comparison structurally difficult. The methodology in this post — amortizing subscription cost over realistic session volume and normalizing by task complexity — is one reproducible approach. Track your own $/task for one week by logging session cost from your API dashboard and dividing by task count.

**Does SWE-bench score predict cost-effectiveness?**

Not directly. Claude Code leads SWE-bench at 80.9% but is not the cheapest tool. GitHub Copilot is cheapest but trails at 55–65%. What benchmark score *does* predict is the number of follow-up prompts and human review cycles needed per task — a higher-scoring tool means fewer iterations, which reduces actual wall-clock time and token spend on corrections. For complex tasks, Claude Code's higher accuracy often makes it cheaper per *successfully completed task*, even if raw $/session is higher.

**When should I switch from subscription to API-only billing?**

When your usage reliably saturates the subscription cap every month. At that point, you are paying the fixed ceiling regardless of actual token consumption, and the effective $/token is favorable. Below saturation — the case for most teams — subscription plans dilute cost per token if you're not heavy enough users. The crossover point for Claude Code: Max 5× ($100/month) becomes cost-positive if you spend more than ~33K Sonnet tokens/day on average (≈ $100/month at API rates).

**Which tool is best for Aider-style open-source workflows?**

This analysis covers closed/subscription tools. Aider with a local or cheap hosted model (DeepSeek V3, Gemini 2.5 Flash) can reduce $/task to near zero for developers comfortable with CLI tooling and model-quality tradeoffs. For a comparison of Aider against the tools above, watch KOEA-7169 for the live benchmark results.

---

## What This Means for Your Stack

The AI coding agent cost conversation in 2026 has two layers: the billing statement you see, and the workflow interruption cost you don't. Copilot's June credit switch, Codex's April token migration, and Cursor's documented credit drain incidents are all reminders that **the cheapest tool at sign-up is not the cheapest tool in production**.

Concrete steps:
1. **Audit your current $/task** using one week of API logs divided by task count.
2. **Identify your billing model risk** — are you on a request quota (now extinct for Copilot), a credit pool (Cursor), or a subscription cap (Claude Code)?
3. **Apply context compaction before upgrading** — 30–50% of current spend is likely recoverable before you pay for a higher tier.

For a broader look at which AI coding tools belong in a production stack — not just their cost profiles — see our [2026 AI coding agents production buyer's guide](/blog/ai-coding-agents-production-2026-buyers-guide).

*Raw $/task data: [`vault/research/_benchmarks/cost-ladder-2026-06.csv`](/research/cost-ladder-2026-06.csv) · Research synthesis: KOEA-7172*

[[ai-coding-agents]] [[developer-tools]] [[cost-analysis]] [[2026]] [[original-data]]
