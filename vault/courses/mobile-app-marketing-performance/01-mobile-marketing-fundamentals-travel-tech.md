---
chapter_num: 1
course_slug: mobile-app-marketing-performance
title: "Mobile App Marketing Fundamentals & the Travel-Tech Context"
status: g3-passed
last_updated: 2026-06-11
duration_min: 40
vendor_tag: AppsFlyer · Google App Campaigns · Meta App Ads · GA4 · CleverTap
learning_objectives:
  - "Map the five-stage mobile marketing funnel and name the primary KPI at each stage"
  - "Define DAU/MAU ratio, install-to-event rate, ROAS, and LTV — and explain what each signals about campaign health"
  - "Distinguish the roles of ASO, paid UA, and in-app engagement within a single growth strategy"
  - "Identify the appropriate mobile marketing channel and tool category for each funnel stage"
  - "Apply EaseMyTrip's OTA revenue model to explain why LTV is the dominant KPI for repeat-purchase travel apps"
  - "Explain the iOS vs Google Play revenue asymmetry and its implications for platform budget allocation"
sources:
  - url: "https://www.airship.com/explainer/mobile-app-marketing-explained/"
    title: "Mobile App Marketing Explained — Airship"
  - url: "https://uxcam.com/blog/top-50-mobile-app-kpis/"
    title: "Top 51 Mobile App KPIs: The Complete List for 2026 — UXCam"
  - url: "https://segwise.ai/blog/mobile-measurement-partners"
    title: "Top Mobile Measurement Partners (MMPs) in 2026 — Segwise"
  - url: "https://42matters.com/stats"
    title: "Google Play vs iOS App Store Store Stats — 42matters (live)"
  - url: "https://startuptalky.com/easemytrip-success-story/"
    title: "EaseMyTrip Success Story — Business Model, Revenue Model — StartupTalky"
  - url: "https://newtonco.ai/en/blog/combining-aso-and-paid-user-acquisition-for-app-growth"
    title: "Combining ASO and Paid User Acquisition for App Growth — Newton.co"
  - url: "https://www.promodo.com/blog/mobile-marketing-benchmarks"
    title: "Mobile App Marketing Benchmarks for Growth in 2026 — Promodo"
owns:
  - "mobile marketing funnel stages: awareness → install → activation → retention → revenue"
  - "funnel-stage KPI mapping: what metric belongs to each stage and why"
  - "DAU/MAU ratio, install-to-event rate, ROAS, LTV — definitions and what each signals about campaign health"
  - "role distinction: organic ASO vs paid UA vs in-app engagement within a single growth strategy"
  - "primary mobile marketing channels: app stores, push, in-app messages, paid social, deep links — overview only"
  - "tool landscape overview per channel: MMPs, engagement platforms, ASO tools, paid campaign managers"
  - "travel-tech app context: how EaseMyTrip's funnel and revenue model shapes mobile KPI priorities"
  - "mobile ecosystem overview: iOS App Store vs Google Play distribution mechanics"
defers_to:
  - "ASO keyword metadata and creative optimization → ch2"
  - "MMP SDK integration and attribution event taxonomy → ch3"
  - "push and in-app messaging campaign creation → ch4"
  - "GA4 property configuration and GTM instrumentation → ch5"
  - "Google App Campaigns and Meta App Ads campaign setup → ch6"
  - "unified dashboard construction and reporting templates → ch7"
quiz_topics:
  - "correct order of the five mobile marketing funnel stages and which KPI belongs to each"
  - "difference between DAU/MAU ratio and install-to-event rate as health signals"
  - "what ROAS measures and why it differs from CPI as a campaign success metric"
  - "which channel — ASO, paid UA, or in-app engagement — impacts the activation stage most directly"
  - "why LTV is the north-star metric for a subscription-model travel app vs a transactional one"
notebooklm_source_focus:
  - "mobile app marketing funnel and growth strategy framework 2025–2026"
  - "DAU/MAU, LTV, ROAS, CPI mobile KPI definitions and benchmarks"
  - "iOS App Store vs Google Play distribution mechanics and market share 2026"
  - "travel-tech mobile app marketing case studies and funnel benchmarks"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which answer correctly states both the five funnel stages in order AND the primary KPI at the Retention stage?"
    options:
      - "Awareness → Install → Activation → Retention → Revenue; primary Retention KPI is D7/D30 retention and DAU/MAU ratio"
      - "Awareness → Install → Retention → Activation → Revenue; primary Retention KPI is D7/D30 retention and DAU/MAU ratio"
      - "Awareness → Install → Activation → Retention → Revenue; primary Retention KPI is ROAS and LTV combined"
      - "Awareness → Activation → Install → Retention → Revenue; primary Retention KPI is install-to-event rate"
    correct_idx: 0
    explanation: "The canonical order is Awareness → Install → Activation → Retention → Revenue. Retention is measured by D7/D30 cohort retention rates and the DAU/MAU stickiness ratio — not ROAS (Revenue stage) or install-to-event rate (Activation stage)."
    section_anchor: the-five-stage-mobile-marketing-funnel

  - question: "A travel app reports DAU/MAU of 0.05. A colleague argues this signals dangerously low retention. What is the correct response?"
    options:
      - "Agree — any DAU/MAU below 0.20 signals a critical retention failure requiring immediate intervention"
      - "Disagree — travel apps are episodic; 0.05 is normal and must be benchmarked against category peers"
      - "Agree — the 0.20 healthy threshold applies universally across all app categories and verticals"
      - "Disagree — DAU/MAU is a gaming metric and holds no diagnostic value for travel app retention"
    correct_idx: 1
    explanation: "Travel app users book flights 3–5 times per year, not daily. A DAU/MAU of 0.05 reflects normal episodic booking behaviour. The ≥0.20 healthy threshold is derived from social and messaging apps; applying it to travel produces false retention alarms."
    section_anchor: the-four-core-metrics-explained

  - question: "Campaign A: CPI $1.50, D30 ROAS 15%. Campaign B: CPI $4.00, D30 ROAS 55%. Which campaign deserves more budget and why?"
    options:
      - "Campaign A — lower CPI delivers more installs per dollar, maximising top-of-funnel install volume"
      - "Campaign B — higher ROAS shows each acquired user generates substantially more downstream revenue"
      - "Campaign A — higher install volume compounds into greater total lifetime revenue across all cohorts"
      - "Campaign B — but only after confirming Android-platform CPI benchmarks are consistent with averages"
    correct_idx: 1
    explanation: "Campaign B recovers $0.55 per $1 spent within 30 days vs $0.15 for Campaign A — nearly 4× the revenue efficiency. ROAS measures downstream user quality; CPI measures acquisition volume only. Optimising for CPI without checking ROAS destroys unit economics."
    section_anchor: the-four-core-metrics-explained

  - question: "Which mobile marketing channel most directly impacts the Activation stage of the funnel?"
    options:
      - "ASO — improving store listing metadata raises organic install quality reaching the app's onboarding flow"
      - "Paid UA — running campaigns optimised for post-install events drives users toward first activation actions"
      - "In-app engagement — push notifications and in-app messages guide installed users to complete first high-value actions"
      - "Deep links — routing paid traffic to specific in-app screens removes friction at the store listing level"
    correct_idx: 2
    explanation: "In-app engagement (push notifications, in-app messages, personalised offers) sits explicitly at the Activation and Retention stages of the funnel — it reaches users who are already installed and guides them to the activation event. ASO and paid UA primarily drive Awareness → Install."
    section_anchor: three-growth-levers-aso-paid-ua-and-in-app-engagement

  - question: "Why is LTV the north-star metric for EaseMyTrip's repeat-purchase OTA model rather than CPI?"
    options:
      - "LTV is always the primary north-star metric for any app with more than one million registered users"
      - "EaseMyTrip's >95% repeat-customer rate means user quality over the lifetime outweighs cheap acquisition volume"
      - "CPI is irrelevant for OTA apps because all installs arrive via organic App Store search, not paid campaigns"
      - "LTV is preferred because it is simpler to calculate than CPI on Android-dominant markets like India"
    correct_idx: 1
    explanation: "When >95% of revenue comes from repeat customers, a low-CPI campaign that acquires one-time searchers who never rebook produces negative ROI. LTV (booking frequency × average booking value × net margin) captures the compounding value of retained users that CPI entirely ignores."
    section_anchor: easemytrip-where-travel-tech-kpis-diverge-from-defaults
---

Most marketers trained on web campaigns bring the wrong mental model to mobile: they treat CPI as the primary success metric, ignore the two-platform duopoly's revenue asymmetry, and misread travel-category retention numbers as failures. This chapter builds the framework that makes every subsequent chapter's tactics make sense.

## The Five-Stage Mobile Marketing Funnel

The canonical funnel runs in strict order: **Awareness → Install → Activation → Retention → Revenue**. These are causal dependencies, not loose labels. A user cannot activate without first installing; revenue cannot compound without retention. Which stage a metric belongs to determines every budget allocation you will make.

**Awareness** is discoverability — app store search, paid social impressions, word-of-mouth. **Install** is the download event. **Activation** is the first meaningful in-app action that delivers the core value proposition: for a travel OTA, that is a completed flight search or first booking, not merely opening the app. **Retention** is the pattern of repeated use. **Revenue** is monetisation — booking commissions, in-app purchases, or ad impressions.

According to [Mobile App Marketing Explained — Airship](https://www.airship.com/explainer/mobile-app-marketing-explained/), activation must be defined as a concrete, observable in-app event before any activation-rate measurement is valid. Defining "user opened the app" as activation is one of the most expensive mistakes in mobile marketing.

<KnowledgeCheck question="A user downloads EaseMyTrip and opens it but does not search for a flight. Which funnel stage have they stalled at?" options={["Awareness — they haven't yet been exposed to the core product value", "Install — opening the app only completes the Install stage, nothing more", "Activation — opening the app is insufficient; a meaningful in-app action is required", "Retention — the user must return a second time before activation can be measured"]} correctIdx={2} explanation="The user completed Install (downloaded and opened the app) but has not reached Activation, which requires a meaningful in-app action — for a travel OTA, a flight search or first booking counts; a cold open does not." />

## Funnel-Stage KPI Mapping

Applying the wrong KPI to a funnel stage produces decisions that optimise the wrong outcome:

| Funnel Stage | Primary KPI | Signal |
|---|---|---|
| Awareness | App Store impressions, branded search volume | Discoverability against competitors |
| Install | CPI by channel (iOS vs Android) | Acquisition cost efficiency |
| Activation | Install-to-event rate | Onboarding friction or audience mismatch |
| Retention | D7/D30 retention; DAU/MAU ratio | Habit formation and usage stickiness |
| Revenue | ROAS, LTV | User value relative to acquisition cost |

A low CPI at Install looks like a win — until you check install-to-event rate. According to [Top 51 Mobile App KPIs — UXCam](https://uxcam.com/blog/top-50-mobile-app-kpis/), a healthy install-to-active conversion is 25–40% for general apps. A campaign at $0.50 CPI with 2% activation is economically worse than a $3.00 CPI campaign achieving 40% activation.

## The Four Core Metrics Explained

**DAU/MAU Ratio** (Daily Active Users ÷ Monthly Active Users) measures engagement stickiness. A ratio ≥ 0.20 is healthy for most categories; ≥ 0.50 is exceptional. The critical travel-app caveat: a flight-booking app with DAU/MAU of 0.05 is not failing — users book 3–5 times per year, not daily. Applying a gaming-derived threshold to a travel app produces false alarms.

**Install-to-Event Rate** measures the percentage of installs that complete a defined high-value in-app event (first search, first booking). A low rate is not always a creative problem — it is often an onboarding UX problem. Before launching new paid spend to compensate for low activation, audit the post-install flow first.

**ROAS** answers whether acquired users were worth what was spent: revenue attributed to a campaign ÷ campaign spend. Unlike CPI, ROAS captures downstream user quality. A campaign at CPI $4.00 with D30 ROAS 55% produces $0.55 per dollar spent; a campaign at CPI $1.50 with D30 ROAS 15% produces only $0.15. The cheaper-to-acquire users destroy value. [Segwise's MMP Guide 2026](https://segwise.ai/blog/mobile-measurement-partners) notes a D30 ROAS above 40% on iOS is a solid non-gaming benchmark.

**LTV (Lifetime Value)** is the projected total net revenue per user across their full relationship with the app: ARPU × average customer lifespan. For repeat-purchase businesses, LTV determines whether an acquisition investment was rational. A user who books once and churns has near-zero LTV; a user who books eight times per year for three years has compounding LTV that justifies a higher CPI.

<KnowledgeCheck question="Two campaigns — A: CPI $1.50, D30 ROAS 15%; B: CPI $4.00, D30 ROAS 55%. Which deserves more budget?" options={["Campaign A — lower CPI means more installs per dollar of acquisition spend", "Campaign B — higher ROAS means each acquired user generates far more downstream revenue", "Campaign A — greater install volume compounds into higher total LTV across all cohorts", "Campaign B — but only if Android CPI benchmarks align with platform-wide averages"]} correctIdx={1} explanation="Campaign B recovers $0.55 per $1 spent within 30 days vs $0.15 for Campaign A — nearly 4× the revenue efficiency. ROAS measures user quality; CPI measures volume only. Optimising CPI without ROAS context destroys unit economics." />

## Three Growth Levers: ASO, Paid UA, and In-App Engagement

Mobile growth runs through three parallel levers, each targeting different funnel stages.

**ASO (App Store Optimization)** improves organic visibility and store-page conversion rate. It primarily drives Awareness → Install, but its influence now extends further: iOS In-App Events and Google Play Promotional Content feed retention signals back to store ranking algorithms, collapsing the traditional ASO/retention boundary.

**Paid UA** runs advertising campaigns on Google App Campaigns, Meta App Ads, Apple Search Ads, and TikTok to drive installs and downstream events. When campaigns are optimised beyond raw installs — toward post-install events like "first booking" — Paid UA can also meaningfully accelerate Activation.

**In-App Engagement** — push notifications, in-app messages, personalised offers, and deep links — operates at Activation and Retention with near-zero marginal cost per interaction. Engagement platforms (CleverTap, MoEngage, Airship, Braze) manage these campaigns.

Running these levers in silos is expensive. [Newton.co's analysis on combining ASO and paid UA](https://newtonco.ai/en/blog/combining-aso-and-paid-user-acquisition-for-app-growth) shows that paid campaigns landing on a poorly optimised store page pay for the click but lose the install. A 1% → 3% store-page CVR lift from ASO triples effective install volume from identical ad spend.

## The Mobile Tool Landscape

Each lever has a dedicated toolset:

- **MMPs (Attribution)**: AppsFlyer (8,000+ network integrations), Adjust, Branch, Singular — connect ad spend to in-app events. The global MMP market was USD 284 million in 2024, projected to reach USD 639 million by 2032. ([Segwise MMP Guide 2026](https://segwise.ai/blog/mobile-measurement-partners))
- **ASO Tools**: AppTweak ($99/mo entry-tier), MobileAction (~$149/mo), Sensor Tower (enterprise ~$25K/year).
- **Engagement Platforms**: CleverTap, MoEngage, Airship, Braze.
- **Paid Campaign Managers**: Google Ads, Meta Ads Manager, Apple Search Ads Console.

This chapter gives you the map. Chapters 2–7 deliver the operational detail for each tool category.

## EaseMyTrip: Where Travel-Tech KPIs Diverge from Defaults

EaseMyTrip is a commission-based OTA earning revenue from flights, hotels, packages, and buses via a no-convenience-fee model. With [>95% of business coming from repeat customers](https://startuptalky.com/easemytrip-success-story/) and 11 million registered users, its funnel economics invert the acquisition-heavy playbook.

When repeat customers dominate, **LTV is the north-star — not CPI**. A low-CPI campaign that fills the funnel with one-time searchers who never rebook produces negative ROI once LTV is properly calculated. The Revenue-stage KPI (booking frequency × average booking value × net margin) matters more than acquisition efficiency.

Travel apps post distinct retention benchmarks: Day-1 retention ~18% versus the 26% all-app average; Day-30 retention ~2.8% versus 5.4% ([Promodo Mobile Benchmarks 2026](https://www.promodo.com/blog/mobile-marketing-benchmarks)). This is not underperformance — it reflects episodic booking patterns. Install-to-purchase conversion in travel sits at 2.41%, above the 1–2% e-commerce norm, because users install with high intent. But sessions-to-booking conversion is low due to comparison shopping — a constraint in-app engagement campaigns are built to address.

## iOS vs Google Play: The Revenue Asymmetry

iOS commands ~67–70% of total app store consumer spending despite Android holding ~68–72% of global device share ([42matters live stats](https://42matters.com/stats)). This inverse relationship directly shapes budget allocation: teams splitting UA spend in proportion to device-install share (72% Android / 28% iOS) under-index the platform generating two-thirds of app store revenue.

For a mass-market travel app targeting India — where Android dominates device share — the right strategy is Android-led volume acquisition via ASO (organic installs at zero marginal cost), with iOS budget reserved for premium segments or international markets where iOS spending parity justifies the higher CPI ($5.84 iOS vs $1.92 Android globally in Q1 2026).

<Callout type="warning">
Never benchmark travel app DAU/MAU against gaming or social norms. A flight-booking app with DAU/MAU of 0.05 is operating normally — users book 3–5 flights per year, not daily. Misapplying the ≥0.20 healthy threshold triggers false retention alarms and misdirects remediation spend.
</Callout>

---

## Hands-On Exercise

**Build your EaseMyTrip funnel KPI table.**

Using Google Sheets or Excel:

1. Create a table with five columns: Funnel Stage / Primary KPI / Travel-App Benchmark / What a Below-Benchmark Reading Signals / Corrective Action.
2. Complete all five funnel stages using definitions and travel-specific benchmarks from this chapter (not all-app averages for Retention rows).
3. Add a row below the table titled "North-Star Metric" — write one cell explaining why LTV, not CPI, holds that position for EaseMyTrip's repeat-customer model, and what campaign decision it would change versus a CPI-first framework.

**Success criteria**: Your table stands alone — a growth marketer who has never read this chapter can use it to understand what to measure, what healthy looks like, and what to do when a metric goes red. Every "Corrective Action" cell names a specific lever (e.g., "audit onboarding UX" for low install-to-event rate), not a vague directive like "investigate further."

---

Next chapter covers ASO in full operational detail — keyword metadata, screenshot design, store listing experiments, and review management: [[02-aso-ranking-converting-ios-google-play]]
