---
chapter_num: 1
course_slug: performance-marketing-budget-management
title: "The Cross-Channel Budget Mental Model — Marginal ROAS and Diminishing Returns"
status: g3-passed
author: course-author
ticket: KOEA-7478
learning_objectives:
  - "Explain the core difference between single-channel optimisation and cross-channel portfolio thinking"
  - "Define marginal ROAS and use it to decide whether to increase or decrease spend on a channel"
  - "Draw a diminishing returns curve from first principles and identify the efficient frontier spend zone"
  - "Map a multi-channel budget hierarchy: account budget vs. campaign budget vs. ad-set/ad-group controls"
  - "State why eCPA and ROAS benchmarks mislead without incrementality context"
prerequisites_chapters: []
duration_min: 45
level: Practitioner
vendor_tag: google-ads meta microsoft-ads
positions: []
sources:
  - https://support.google.com/google-ads/answer/2471188
  - https://www.facebook.com/business/help/214319818801882
tags:
  - course/performance-marketing-budget-management
  - performance-marketing
  - budget-allocation
  - marginal-roas
  - google-ads
  - meta-ads
---

# The Cross-Channel Budget Mental Model — Marginal ROAS and Diminishing Returns

Most performance marketers spend their careers optimising a single channel. You get good at Google Search. Or you learn Meta cold audiences. That expertise is real and valuable. But the moment you own a budget across multiple channels, the game changes completely.

Single-channel optimisation asks: "How do I get the best ROAS from this channel?" Cross-channel portfolio management asks a harder question: "Where does the next rupee produce the most return?" Those two questions have different answers, and confusing them is how teams waste 20–30% of large-scale budgets every month.

This chapter builds the mental model you need to answer the second question consistently.

## Prerequisites check

Before starting, confirm you can:

1. Define CPA, ROAS, and conversion rate in your own words.
2. Log in to Google Ads and navigate to campaign-level reporting.
3. Read a basic performance table: impressions, clicks, conversions, spend, revenue.

If conversion tracking is unfamiliar territory — you don't know how a Google conversion action or Meta Pixel event is set up — pause and review your platform's conversion setup guide first. Budget decisions are only as reliable as the conversion data underneath them.

## The problem with single-channel ROAS

Imagine you run three campaign groups: Google Search (branded), Google Search (non-branded), and Meta Prospecting. You review last month's numbers:

| Channel | Spend (₹) | Revenue (₹) | ROAS |
|---------|-----------|-------------|------|
| Google Search — Branded | 4,00,000 | 24,00,000 | 6.0x |
| Google Search — Non-Branded | 10,00,000 | 30,00,000 | 3.0x |
| Meta Prospecting | 6,00,000 | 12,00,000 | 2.0x |

A naive optimiser looks at this table and concludes: shift budget to Branded (6x ROAS!) and cut Meta (only 2x). This is the most common mistake in multi-channel budget management — and it misses two critical facts.

**Fact 1: Branded search is bounded.** Branded search captures people already searching for your company. You cannot scale it arbitrarily — the demand is fixed by how many people know your brand. Doubling branded search spend does not double branded searches. At some point, every additional rupee returns less than the last.

**Fact 2: ROAS is an average, not a signal of where to invest next.** The 6x ROAS on branded search describes performance on the budget you've already spent. It says nothing about what happens if you spend ₹1 more.

The right question is: "What does the *next* rupee earn?" That's marginal ROAS.

## Marginal ROAS: the correct allocation signal

**Marginal ROAS** = (change in revenue) ÷ (change in spend) for a small increment of additional budget.

In practice, you estimate it from the diminishing returns curve of each channel. But the intuition is simple: if Google Search already captures 95% of relevant demand at current spend, adding ₹1L more will earn very little in incremental revenue — marginal ROAS is low. If Meta Prospecting still has a large untapped audience, adding ₹1L there may produce ₹2.5–3L in attributable revenue — marginal ROAS is higher.

The allocation rule: **move budget from the channel with the lower marginal ROAS to the channel with the higher marginal ROAS until they equalise.**

This is the same logic as any portfolio optimisation. You're maximising the return on each marginal rupee spent, not the average return across all rupees already committed.

<Callout type="info">
The efficient portfolio is the one where every channel's marginal ROAS is equal. If one channel's marginal return is higher than another's, you haven't finished optimising — shift budget until they equalise.
</Callout>

### A worked example

Continuing the table above, suppose you have data suggesting the following marginal ROAS estimates at current spend levels:

| Channel | Current Spend | Avg ROAS | Est. Marginal ROAS |
|---------|--------------|----------|--------------------|
| Google Branded | ₹4L | 6.0x | 1.8x (near-saturated) |
| Google Non-Branded | ₹10L | 3.0x | 2.8x |
| Meta Prospecting | ₹6L | 2.0x | 3.5x (room to scale) |

Even though Meta Prospecting has the worst average ROAS, it has the best marginal ROAS — each additional rupee there earns more than an additional rupee on any other channel. The correct move is to reallocate from branded search (marginal ROAS 1.8x) toward Meta Prospecting (marginal ROAS 3.5x).

<KnowledgeCheck
  questions={[
    {
      question: "A Google branded campaign has a 7x average ROAS and a 1.5x marginal ROAS. A Meta prospecting campaign has a 2x average ROAS and a 4x marginal ROAS. Where should you add the next ₹1L of budget?",
      answers: [
        "Google branded — higher average ROAS",
        "Meta prospecting — higher marginal ROAS",
        "Split equally between both",
        "Neither — both average and marginal ROAS must agree before spending more"
      ],
      correct: 1,
      explanation: "Marginal ROAS is the correct signal for where the next rupee earns more. Average ROAS reflects past performance on already-spent budget, not future incremental return."
    }
  ]}
/>

## Diminishing returns curves: the underlying mechanic

Every marketing channel follows a diminishing returns curve. The first rupee you spend on a channel reaches the most valuable, easiest-to-reach audience. The second rupee reaches slightly less valuable audience. Eventually, you're spending on audiences so marginal that the return barely justifies the cost.

Visualise it as a curve: X-axis is spend, Y-axis is revenue. Early spend is steep (high return per rupee). The curve flattens as you approach saturation.

The **efficient frontier** is the spend range where the curve is still meaningfully steep — where each additional rupee returns more than a defined floor (typically 2–3x for B2C). Beyond the efficient frontier, you're in diminishing returns territory: you can still spend more, but the incremental return per rupee is falling fast.

For practical budget decisions, you need a rough sense of where each channel sits on its curve:

- **Below efficient frontier**: under-investing. Marginal ROAS is high. Increase spend.
- **In the efficient frontier zone**: well-calibrated. Monitor marginal ROAS for changes.
- **Above efficient frontier**: near-saturated. Marginal ROAS is declining. Reallocate.

You estimate this from historical data: run the channel at different spend levels over several weeks (or use dayparting to observe weekend/weekday variation in efficiency) and observe how ROAS changes as spend increases. A steep drop in ROAS as spend rises is the classic saturation signal.

<Callout type="warning">
Don't confuse creative fatigue with saturation. If a campaign's ROAS drops sharply after 3 weeks of consistent spend, the cause may be audience exhaustion at the ad-set level (the same people have seen your ad too many times), not true channel saturation. Refresh creatives or expand audiences before concluding the channel is saturated.
</Callout>

## Budget hierarchy: how controls are structured

Before you can allocate budget, you need to understand how budget controls are structured on each platform.

### Google Ads hierarchy

```
Account (no budget control)
  └── Campaign (budget set here — daily budget)
        └── Ad Group (no budget control)
              └── Ad (no budget control)
```

Google budgets are set at the **campaign level** as a daily budget. Google may spend up to 2x the daily budget on high-demand days, but will not exceed the monthly equivalent (daily budget × 30.4) over the course of a month. For multi-campaign management, use **shared budgets** to pool a single budget across multiple campaigns and let Google allocate automatically.

### Meta (Facebook/Instagram) hierarchy

```
Ad Account (has account-level spending limit — optional)
  └── Campaign (Campaign Budget Optimisation — optional)
        └── Ad Set (budget set here by default — daily or lifetime)
              └── Ad (no budget control)
```

Meta offers two budget models. With **Ad Set Budget Optimisation (ABO)**, you set budgets per ad set — full manual control, but no automatic reallocation. With **Campaign Budget Optimisation (CBO, now Advantage+ Budget)**, you set a campaign-level budget and Meta's delivery system allocates it across ad sets in real time based on performance signals. For large accounts, CBO/Advantage+ Budget reduces manual pacing work but requires trusting Meta's allocation logic.

### Microsoft Ads (Bing)

Microsoft Ads mirrors Google's structure: daily budgets at the campaign level with a monthly cap option. For most B2C advertisers, Bing spends are 10–20% of Google spend at comparable CPAs — useful for incremental reach but rarely the primary allocation decision.

<KnowledgeCheck
  questions={[
    {
      question: "You're managing a Google Ads account with a daily campaign budget of ₹10,000. What is the maximum Google can spend in a single day without violating the monthly cap?",
      answers: [
        "₹10,000 — Google never exceeds the daily budget",
        "₹20,000 — Google can spend up to 2x the daily budget on high-demand days",
        "₹3,04,000 — the full monthly equivalent all in one day",
        "₹15,000 — Google can spend up to 1.5x the daily budget"
      ],
      correct: 1,
      explanation: "Google may spend up to 2x the daily budget on high-traffic days, but will not exceed the monthly cap (daily budget × 30.4) over the month."
    },
    {
      question: "In Meta Ads, what is the difference between ABO and CBO?",
      answers: [
        "ABO sets budgets per ad set; CBO sets a campaign-level budget and lets Meta allocate across ad sets",
        "ABO is for app campaigns; CBO is for website campaigns",
        "ABO uses manual CPC; CBO uses automated bidding only",
        "They are different names for the same thing"
      ],
      correct: 0,
      explanation: "ABO (Ad Set Budget Optimisation) gives you control per ad set. CBO (Campaign Budget Optimisation, also called Advantage+ Budget) sets one campaign-level budget and Meta's system allocates it dynamically across ad sets."
    }
  ]}
/>

## Why ROAS benchmarks mislead without incrementality context

You've probably heard benchmarks like "a 3x ROAS is good for e-commerce" or "target a ₹200 CPA for travel." These benchmarks cause expensive mistakes at scale for one reason: they don't account for whether your spend is actually *causing* the conversions you're counting.

At ₹5L/month, your attribution error is small — most conversions you're counting were probably driven by your ads. At ₹1Cr/month, you're operating in markets where consumers are exposed to your ads multiple times across channels, and where organic brand demand creates many conversions that would have happened anyway.

Platforms make this worse. Google's default attribution model (data-driven, but trained on Google-observed data) will attribute credit to Google touchpoints. Meta's delivery system does the same. Both platforms count many of the same conversions. A campaign reporting 3x ROAS on Google and 2.5x ROAS on Meta may actually be sharing the same pool of conversions — the "true" incremental ROAS is much lower.

The practical implication: **use ROAS benchmarks for directional sanity-checks only.** To know whether spend is actually producing incremental conversions — above what would have happened without advertising — you need an incrementality test. Chapter 4 covers how to run one. For now, carry this rule: *any ROAS number from a platform's own reporting overstates the true incremental ROAS*.

<KnowledgeCheck
  questions={[
    {
      question: "Why do industry ROAS benchmarks (e.g. '3x is good for e-commerce') become unreliable at large budget scales?",
      answers: [
        "Larger accounts pay higher CPMs that reduce ROAS mechanically",
        "At scale, attribution overlap between channels inflates reported ROAS, and organic demand creates conversions that would have happened without ads",
        "ROAS benchmarks are only valid for small accounts under ₹10L/month",
        "Benchmarks assume manual bidding; automated bidding produces different ROAS ranges"
      ],
      correct: 1,
      explanation: "At scale, the same conversion gets attributed across multiple channels simultaneously, and high organic brand awareness means many conversions happen regardless of ad exposure. Both inflate reported ROAS above the true incremental return."
    }
  ]}
/>

## Hands-on exercise

**Given:** A fictional account spending ₹50L/month with the data below. Apply marginal ROAS thinking to propose a reallocation.

| Channel | Monthly Spend (₹) | Reported Revenue (₹) | Avg ROAS | Notes |
|---------|------------------|---------------------|----------|----|
| Google Search — Branded | 8,00,000 | 56,00,000 | 7.0x | Impression share: 98% |
| Google Search — Non-Brand | 18,00,000 | 63,00,000 | 3.5x | Impression share: 52% |
| Google Shopping | 10,00,000 | 28,00,000 | 2.8x | Impression share: 41% |
| Meta Prospecting | 8,00,000 | 16,00,000 | 2.0x | Frequency: 1.8 |
| Meta Retargeting | 6,00,000 | 22,80,000 | 3.8x | Audience: 90,000 users |

**Your task:**

1. Identify which channels are likely near-saturated (high impression share or frequency) and which have room to scale.
2. Use marginal ROAS reasoning to propose a revised monthly allocation across the same ₹50L total budget.
3. For each reallocation decision, write one sentence explaining the marginal ROAS logic.
4. Identify one caveat or unknown that would change your recommendation if the data showed it.

**Success criteria:**
- Your revised allocation sums to ₹50L
- Each channel's budget change has a clear marginal ROAS justification
- You named at least one channel as near-saturated with supporting evidence from the data
- You identified one attribution caveat (e.g., retargeting and branded search likely share the same pool of high-intent converters)

## What's next

Chapter 2 moves from the allocation decision to the operational discipline of running a budget: how to pace spend across the month, what to check weekly, and how to reallocate mid-flight without destroying campaign learning phases.

[^1]: Google Ads Help, "About daily budgets", https://support.google.com/google-ads/answer/2471188
[^2]: Meta Business Help, "Campaign budget optimisation", https://www.facebook.com/business/help/214319818801882
