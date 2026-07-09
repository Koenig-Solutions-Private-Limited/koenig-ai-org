---
chapter_num: 4
course_slug: performance-marketing-budget-management
title: "Cross-Channel Attribution, ROI Forecasting, and Making the Budget Case"
status: g3-passed
author: course-author
ticket: KOEA-7478
learning_objectives:
  - "Explain the four main attribution models and what each over- or under-credits"
  - "Describe the walled garden problem: why Google, Meta, and Bing each claim credit for the same conversion"
  - "Build a de-duplicated cross-channel attribution view using a simple dedupe heuristic"
  - "Construct a 30-day ROI forecast with input assumptions, sensitivity table, and worst/base/best scenario"
  - "Design a geo holdout incrementality test: how to set it up, interpret the lift ratio, and use the result to justify a budget change"
prerequisites_chapters:
  - 1
  - 2
  - 3
duration_min: 60
level: Practitioner
vendor_tag: google-ads meta microsoft-ads
positions: []
sources:
  - https://support.google.com/google-ads/answer/1722054
  - https://www.facebook.com/business/help/1713977868859069
  - https://about.ads.microsoft.com/en-us/resources/training/courses
tags:
  - course/performance-marketing-budget-management
  - performance-marketing
  - attribution
  - roi-forecasting
  - incrementality
  - google-ads
  - meta-ads
quiz:
  - question: "A customer's purchase journey is: Meta Prospecting ad → Google non-brand click → Google branded click → Purchase. Under last-click attribution, which channel receives 100% of the credit?"
    options:
      - "Meta Prospecting — it initiated the customer journey and deserves credit for awareness"
      - "Google non-brand search — it was the middle touchpoint that bridged awareness to intent"
      - "Google branded search — it was the final click immediately before the purchase"
      - "Credit is split equally across all three channels in last-click attribution"
    correct_idx: 2
    explanation: "Last-click attribution assigns 100% of credit to the final touchpoint before conversion. The branded search click immediately before purchase receives all credit, regardless of which channel drove initial purchase intent."
    section_anchor: the-four-attribution-models
  - question: "Google reports 600 conversions and Meta reports 400 conversions last month. Your CRM shows 750 actual orders. What does this tell you?"
    options:
      - "Your CRM tracking is broken — platform-reported numbers are always the authoritative source"
      - "There is significant cross-channel overlap: approximately 250 conversions were counted by both platforms simultaneously"
      - "Meta's tracking is malfunctioning — it is overcounting conversions by approximately 150"
      - "All numbers are correct because each platform uses different attribution windows that explain the discrepancy"
    correct_idx: 1
    explanation: "Platform-reported total (600 + 400 = 1,000) vs. CRM actual (750) implies approximately 250 conversions were attributed by both platforms for the same order — the classic walled garden double-counting problem, not a tracking error."
    section_anchor: the-walled-garden-problem-why-reported-conversions-dont-add-up
  - question: "Your platform reports a 4x ROAS for a Google Search campaign last month. Your de-duplicated model shows a 2.9x adjusted ROAS (correction factor 0.73). Which number should you use in your 30-day forecast to the CMO?"
    options:
      - "4x — platform-reported is always the most accurate source for forecasting purposes"
      - "2.9x — the de-duplicated number is the better basis because it anchors to actual backend orders"
      - "3.45x — average the two numbers to arrive at a conservative midpoint estimate"
      - "Neither — present both figures and let the CMO decide which baseline to use"
    correct_idx: 1
    explanation: "The de-duplicated 2.9x anchors to actual backend order data and removes cross-channel double-counting. Forecasting from the inflated 4x platform number overstates expected revenue and erodes your credibility when actuals come in 25% lower than the forecast."
    section_anchor: the-30-day-roi-forecast
  - question: "A geo holdout test shows a 15% conversion lift from your Meta Prospecting campaign. The campaign currently reports 2,000 conversions per month. What is the estimated number of truly incremental conversions?"
    options:
      - "2,000 — all platform-reported conversions are incremental by definition"
      - "300 — 15% of 2,000 represents the conversions driven purely by the Meta ads"
      - "1,700 — the non-incremental share that would have happened regardless of Meta"
      - "400 — factoring in a standard 2x Meta over-reporting correction alongside the lift ratio"
    correct_idx: 1
    explanation: "A 15% incrementality lift means 15% of reported conversions are attributable to the ads — 15% × 2,000 = 300 truly incremental conversions. The remaining 1,700 would have happened through organic search, direct, or other channels even without Meta running."
    section_anchor: incrementality-testing-the-only-way-to-measure-true-impact
---

# Cross-Channel Attribution, ROI Forecasting, and Making the Budget Case

Every channel claims credit for your conversions. Google's data-driven attribution model assigns credit to Google touchpoints. Meta's delivery algorithm attributes purchases to Meta impressions and clicks. Bing does the same. At ₹50L/month of combined spend across three channels, your platform-reported total conversions can easily add up to 1.5–2x your actual conversion count.

This is the walled garden problem: each platform is a credible narrator of its own version of the truth. None of them shows you the whole story.

This chapter gives you a practical framework for building a de-duplicated view of cross-channel performance, forecasting ROI in a way that doesn't mislead stakeholders, and using incrementality tests to establish the ground truth your attribution models can't provide.

## Prerequisites check

Before starting, confirm you can:

1. Export a conversion report from Google Ads segmented by date and campaign
2. Export a conversion report from Meta Ads Manager segmented by date and ad set
3. Pull your backend CRM/revenue data for the same date range (even a simple CSV of purchase date + revenue works)

If your platform data and backend data have never been reconciled, this chapter will show you how and why to do it. The exercise at the end requires at least one week of data from two channels plus backend order data.

## The four attribution models

An **attribution model** decides how to distribute credit for a conversion across the touchpoints in the customer journey.

**Last-click attribution:** 100% of credit goes to the last channel the customer touched before converting. Simple and auditable. Problem: it systematically over-credits bottom-funnel channels (branded search, retargeting) and gives zero credit to awareness channels that initiated the purchase intent.

**First-click attribution:** 100% of credit goes to the first touchpoint. The opposite bias: it over-credits awareness campaigns and ignores the channels that closed the sale.

**Linear attribution:** Credit is distributed equally across all touchpoints in the journey. A customer touched by Meta ad → Google non-brand → Google brand → purchase would give each channel one-third of the credit. Less extreme than first- or last-click, but still arbitrary — assumes all touchpoints contribute equally.

**Data-driven attribution (DDA):** A machine learning model trained on actual conversion paths in your account, assigning credit based on observed lift from each touchpoint. Google and Meta both offer platform-specific DDA models.

DDA sounds like the obvious winner, but it has a critical limitation: it is trained only on data the platform can observe. Google's DDA sees Google touchpoints; Meta's DDA sees Meta touchpoints. Neither model sees the full customer journey. Both models are biased toward their own inventory.

<Callout type="info">
For internal reporting, use Google's data-driven attribution for Google campaign optimisation decisions and Meta's data-driven attribution for Meta optimisation decisions. This is fine — each platform optimising against its own DDA is sensible. The problem arises when you try to use platform-level attribution to answer cross-channel questions like "should I shift ₹5L from Google to Meta?"
</Callout>

<KnowledgeCheck
  questions={[
    {
      question: "A customer's purchase journey is: Meta Prospecting ad → Google non-brand search click → Google branded search click → Purchase. Under last-click attribution, which channel gets 100% of the credit?",
      answers: [
        "Meta Prospecting — it initiated the journey",
        "Google non-brand search — it was the middle touch",
        "Google branded search — it was the final click before purchase",
        "Credit is split equally between all three"
      ],
      correct: 2,
      explanation: "Last-click attributes 100% of credit to the final touchpoint before conversion. The branded search click immediately before purchase receives all the credit, regardless of what drove the initial intent."
    }
  ]}
/>

## The walled garden problem: why reported conversions don't add up

Here's the scenario that every large-scale performance marketer eventually discovers: you run Google Search and Meta Prospecting. Google reports 1,200 conversions last month. Meta reports 800 conversions. Your backend shows 1,100 actual orders. The math: 1,200 + 800 = 2,000 attributed conversions for 1,100 real orders.

Why does this happen?

**Cross-channel overlap:** The same customer was reached by both a Google ad and a Meta ad before converting. Both platforms count the conversion in their own reporting. There's no automatic deduplication at the platform level.

**View-through attribution:** Meta by default counts any conversion where the customer saw (but did not click) a Meta ad in the previous 1 day (1-day view default, though 7-day view is also available). If a customer was served a Meta ad in the morning and searched Google that afternoon to purchase, both platforms count the conversion.

**Cross-device attribution:** The customer saw a Meta ad on mobile but converted on desktop. Meta attributes the conversion via its cross-device matching (Facebook's first-party identity graph). Google also attributes via its signed-in user tracking. Double-count.

**Platform-specific reporting windows:** Google Ads defaults to a 30-day click attribution window and 1-day view-through window. Meta defaults to 7-day click + 1-day view. The windows don't align, creating further overlap.

<KnowledgeCheck
  questions={[
    {
      question: "Google reports 600 conversions and Meta reports 400 conversions last month. Your CRM shows 750 actual orders. What does this tell you?",
      answers: [
        "Your CRM tracking is broken — platform numbers are always more accurate",
        "There is significant cross-channel overlap: approximately 250 conversions were counted by both platforms",
        "Meta's tracking is broken — it's overcounting by 150",
        "All numbers are correct because attribution windows are different for each platform"
      ],
      correct: 1,
      explanation: "Platform-reported total (600 + 400 = 1,000) vs. CRM actual (750) implies ~250 conversions attributed by both platforms. This is typical cross-channel double-counting, not a tracking error."
    }
  ]}
/>

## Building a de-duplicated attribution view

You can't perfectly attribute every sale to a single channel without a full multi-touch attribution platform. But you can build a directionally accurate de-duplicated view with three steps.

**Step 1: Anchor to backend order data.**

Your CRM or order management system is the source of truth for conversion count. Pull: date, order ID, revenue, and any UTM parameters attached to the order (if your site properly passes UTM source, medium, and campaign to the backend on checkout).

**Step 2: Apply a channel priority hierarchy.**

Assign each order to the highest-priority channel that touched it, using a simple waterfall rule:

1. If the order has a Google click within 30 days → attribute to Google (channel + campaign)
2. Else if the order has a Meta click within 7 days → attribute to Meta
3. Else if the order has a Bing click within 30 days → attribute to Bing
4. Else → attribute to Direct / Organic

This is a simple ordered-priority model. It's not statistically perfect, but it eliminates double-counting, anchors to real order count, and gives you a single row per order.

**Step 3: Compare the de-duplicated view to platform-reported metrics.**

The ratio of (de-duplicated channel revenue) ÷ (platform-reported revenue) tells you your "attribution inflation factor" per channel. If Google is claiming ₹30L in revenue but the de-duplicated view gives it credit for ₹22L, the inflation factor is 1.36x — Google is over-reporting by 36% in your account. This factor becomes a correction coefficient for future platform-reported numbers.

<Callout type="warning">
The ordered-priority waterfall is not an industry standard — it reflects a deliberate choice to credit click-through above view-through and to prioritise Google over Meta (or vice versa, depending on your business). Document and communicate the rule clearly to stakeholders so they know what "attributed to Meta" means in your reports.
</Callout>

## The 30-day ROI forecast

Before requesting a budget increase or presenting a quarterly plan to a CMO, you need a credible ROI forecast. Here's a practical model structure.

**Inputs (per channel):**

| Input | Description |
|-------|-------------|
| Planned monthly spend (₹) | The budget you're requesting or defending |
| Current avg CPA or avg CRev | Historical performance baseline |
| Expected conversion volume | Spend ÷ CPA |
| Expected revenue | Conversions × Avg order value (or use tROAS target) |
| Attribution correction factor | De-duplication adjustment (e.g., 0.85 if platform over-reports by 15%) |
| Adjusted revenue | Expected revenue × correction factor |

**The sensitivity table:**

A single-point forecast ("we'll generate ₹X in revenue") is fragile. Replace it with a three-scenario table:

| Scenario | Assumption | Revenue | ROAS |
|----------|-----------|---------|------|
| Worst case | CPA +20% above baseline | Lower | Below target |
| Base case | CPA at historical baseline | Expected | At target |
| Best case | CPA −15% below baseline | Higher | Above target |

**What makes a forecast credible to a CMO:**

1. It's anchored to backend-reconciled historical data, not platform-reported numbers
2. It shows a range, not a single point
3. The key assumptions are explicit (e.g., "assumes iOS 18 does not change Meta's attribution window")
4. It identifies the one or two variables that move the outcome most (usually: conversion rate and average order value, not CPM or CTR)

<KnowledgeCheck
  questions={[
    {
      question: "You're building a 30-day forecast for a Google Search campaign. Your platform reports a 4x ROAS last month. Your de-duplicated model shows a 2.9x adjusted ROAS (attribution correction factor of 0.73). Which number should you use in your forecast to the CMO?",
      answers: [
        "4x — platform-reported is the most accurate source",
        "2.9x — the de-duplicated number is the better basis for a business forecast",
        "The average: 3.45x — split the difference to be conservative",
        "Neither — present both and let the CMO decide"
      ],
      correct: 1,
      explanation: "The de-duplicated 2.9x is the better basis because it anchors to actual backend orders and removes cross-channel double-counting. Forecasting from the inflated 4x platform number would overstate expected revenue and erode your credibility when actuals come in lower."
    }
  ]}
/>

## Incrementality testing: the only way to measure true impact

Attribution models, even good ones, don't answer the core business question: **would these customers have converted anyway, without the ads?**

This is the incrementality question. It matters enormously at large budgets. If 40% of your Google branded search conversions would have typed your domain directly (organic), then your true incremental ROAS on branded search is much lower than the 6–7x typically reported.

The most reliable way to measure incrementality is a **geo holdout test**: a controlled experiment where you withhold advertising from a randomly selected geographic region for a defined period, measure conversion rates in that region vs. a matched control group that continued seeing ads, and calculate the incremental lift.

### How to set up a geo holdout test

**Step 1: Select test and control geographies.**

Choose 4–6 comparable cities or regions. Split them into two matched groups based on historical conversion rate, population size, and seasonality patterns. One group is the test group (ads turned off or significantly reduced). One group is the control (ads continue as normal).

For Indian B2C campaigns, a typical setup: Test cities = Pune, Ahmedabad, Chandigarh. Control cities = Mumbai, Bangalore, Delhi. These are approximate matches in terms of digital-native urban consumers.

**Step 2: Define the test period.**

Minimum 2 weeks. 4 weeks is better — long enough to smooth out day-of-week variation and observe the full conversion cycle (from ad exposure to confirmed booking for an OTA, for example). Avoid overlapping with known demand events (festivals, sales) that affect geos differently.

**Step 3: Measure the lift ratio.**

```
Incrementality Lift = (Conversion rate in control) − (Conversion rate in test) / (Conversion rate in control)
```

If the control group maintains a 2.4% conversion rate and the test group drops to 1.8% when ads are removed:

```
Lift = (2.4% − 1.8%) ÷ 2.4% = 25%
```

This means 25% of your conversions in this channel are incremental — they wouldn't have happened without the ads. The other 75% would have happened through organic search, direct, or other channels.

**Using the lift result to justify a budget change:**

If your branded search campaign reports 3,000 conversions/month at ₹1.2Cr and an incrementality test shows 25% lift:

- Incremental conversions: 3,000 × 25% = 750
- Incremental revenue (at ₹3,000 avg order): 750 × ₹3,000 = ₹22.5L
- True incremental ROAS: ₹22.5L ÷ ₹1.2Cr = 1.88x

This is far from the 6x the platform reports. It may or may not justify the spend depending on your profitability thresholds — but now you have an honest number to present.

<Callout type="info">
Meta offers a native "Conversion Lift" study product that runs a similar experiment automatically within Meta's ad delivery. It's easier to implement than a manual geo holdout but has the limitation of measuring only Meta-to-Meta incrementality — it doesn't tell you how Meta ads affect Google or direct conversions.
</Callout>

<KnowledgeCheck
  questions={[
    {
      question: "A geo holdout test shows a 15% conversion lift from your Meta Prospecting campaign. The campaign currently reports 2,000 conversions/month. What is the estimated number of truly incremental conversions?",
      answers: [
        "2,000 — all reported conversions are incremental by definition",
        "300 — 15% of 2,000",
        "1,700 — the non-incremental share",
        "400 — factoring in the typical 2x Meta over-reporting discount"
      ],
      correct: 1,
      explanation: "A 15% lift means 15% of conversions are incremental — 15% × 2,000 = 300. The remaining 1,700 conversions would have happened through other channels without the Meta ads."
    }
  ]}
/>

## Making the budget case to a CMO

Combining everything in this chapter, here is the structure for a persuasive budget case:

**1. Start with the business question, not the ad metrics.**

Wrong opening: "Our ROAS improved from 3.2x to 3.8x last month."
Right opening: "We have evidence that ₹1L of additional Meta spend generates ₹3.5L of incremental revenue with 85% statistical confidence."

**2. Present the de-duplicated baseline, not platform-reported.**

Show the CMO your reconciliation methodology in a footnote. It demonstrates analytical credibility and pre-empts the "why don't our numbers add up" question.

**3. Lead with the incrementality result if you have one.**

Nothing cuts through attribution debate like a controlled experiment. "In our Q1 geo holdout test, Meta Prospecting showed 28% incremental lift, which is 12 points higher than we estimated from last-click attribution" is a decisive piece of evidence.

**4. Use the three-scenario forecast.**

Never present a single-point forecast. A range with explicit assumptions makes you look rigorous, not uncertain. "Base case: ₹18Cr incremental revenue on ₹5Cr spend. Worst case: ₹14Cr if conversion rates drop 15% from baseline."

**5. Name the risk.**

Every budget increase has a risk. Name it. "The main risk is that Meta's learning phase after the 30% budget increase takes 2 weeks, during which CPRs will be 15–20% above target. We recommend a 4-week hold period before evaluating the new baseline."

A CMO who approves a budget increase after seeing a rigorous, risk-acknowledged case is a partner. A CMO who approves based on inflated platform numbers will blame you when actuals miss.

## Hands-on exercise

**Build a de-duplicated attribution model and 30-day ROI forecast.**

**Dataset (provided as a scenario):**

You're managing a B2C travel platform account with the following platform-reported data for the past 30 days:

| Channel | Platform Spend (₹) | Platform Conversions | Platform Revenue (₹) | ROAS |
|---------|-------------------|---------------------|---------------------|------|
| Google Branded | 12,00,000 | 800 | 80,00,000 | 6.7x |
| Google Non-Brand | 22,00,000 | 540 | 72,90,000 | 3.3x |
| Meta Prospecting | 10,00,000 | 320 | 22,40,000 | 2.2x |
| Meta Retargeting | 6,00,000 | 280 | 25,20,000 | 4.2x |
| **Platform Total** | **50,00,000** | **1,940** | **2,00,50,000** | **4.0x** |

Your backend shows: **1,480 actual orders, ₹1,65,00,000 actual revenue.**

**Part 1 — De-duplication:**
1. Calculate the platform total-to-backend reconciliation ratio (actual ÷ platform-reported) for both conversions and revenue
2. Apply that ratio as a correction factor to each channel's reported revenue
3. Calculate the de-duplicated ROAS for each channel

**Part 2 — 30-day forecast:**
Propose a new 30-day budget allocation with a total of ₹55L (a ₹5L increase from current ₹50L). Use your de-duplicated ROAS to guide the allocation. Build a three-scenario table (worst/base/best) showing expected revenue and ROAS for your proposed allocation.

**Part 3 — Stakeholder memo:**
Write a one-page budget recommendation memo (300–400 words) addressed to the VP Marketing. Your memo should:
- Open with the business case (incremental revenue per rupee), not ad metrics
- Reference the reconciliation gap and explain it briefly
- Propose the ₹5L increase with allocation logic
- State one risk and how you'd monitor it

**Success criteria:**
- De-duplicated conversion and revenue totals match backend data
- Proposed allocation uses marginal ROAS logic from Chapter 1
- Three-scenario forecast includes explicit assumption statements
- Memo uses the word "incremental" at least once and avoids claiming platform-reported ROAS as the basis for the business case

## What's next

This chapter completes the four-part framework. The capstone project asks you to apply all four lenses — allocation, pacing, bid strategy, and attribution — to a single account scenario: build a 90-day budget allocation brief for a ₹1Cr/month B2C performance marketing account.

[^1]: Google Ads Help, "Attribution models", https://support.google.com/google-ads/answer/1722054
[^2]: Meta Business Help, "About conversion attribution", https://www.facebook.com/business/help/1713977868859069
[^3]: Microsoft Advertising, "About attribution", https://about.ads.microsoft.com/en-us/resources/training/courses
