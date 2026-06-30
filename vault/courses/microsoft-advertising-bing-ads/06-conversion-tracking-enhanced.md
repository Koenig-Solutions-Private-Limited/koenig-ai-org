---
chapter_num: 6
course_slug: microsoft-advertising-bing-ads
title: "Conversion Tracking, Enhanced Conversions & Performance Reporting"
status: g3-passed
last_updated: "2026-06-10"
positions: []
duration_min: 22
vendor_tag: microsoft-advertising
learning_objectives:
  - "Create UrlGoal and EventGoal conversion goals and link each to an existing UET tag"
  - "Implement Enhanced Conversions by preprocessing and SHA-256 hashing email and phone data"
  - "Validate conversion health using the conversion diagnostics panel"
  - "Build a standard performance dashboard with the correct reporting columns"
  - "Read the Bid Strategy Report to identify and remediate a learning period"
sources:
  - url: "https://learn.microsoft.com/en-us/advertising/guides/uet-conversion-api-integration?view=bingads-13"
    title: "Conversions API (CAPI) Guide - Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/guides/universal-event-tracking?view=bingads-13"
    title: "Universal Event Tracking - Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/guides/budget-bid-strategies?view=bingads-13"
    title: "Budget and Bid Strategies - Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/reporting-service/bidstrategyreportcolumn?view=bingads-13"
    title: "BidStrategyReportColumn Value Set - Reporting - Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/reporting-service/adperformancereportcolumn?view=bingads-13"
    title: "AdPerformanceReportColumn Value Set - Reporting - Microsoft Advertising API | Microsoft Learn"
  - url: "https://about.ads.microsoft.com/en/blog/post/february-2024/enhanced-conversions-and-other-updates-for-february"
    title: "Enhanced conversions and other updates for February | Microsoft Advertising"
  - url: "https://about.ads.microsoft.com/en/blog/post/may-2026/new-import-center-and-other-product-news-for-may-2026"
    title: "New import center and other product news for May 2026 | Microsoft Advertising"
owns:
  - "conversion goal types: page visit, booking confirmation, micro-conversion events"
  - "linking conversion goals to the UET tag (uses ch4's installed UET; ch6 owns goal creation)"
  - "Enhanced Conversions: hashed first-party data implementation"
  - "conversion diagnostics panel validation"
  - "custom reporting dashboard: Impressions, Clicks, CTR, CPC, Conversions, CPA, ROAS, Impression Share"
  - "Bid Strategy Report: Target CPA, Target ROAS, Avg. Target Impression Share metrics"
  - "learning period identification and remediation"
defers_to:
  - "UET tag installation and verification → ch4"
  - "audience remarketing lists → ch4"
  - "PMax transparency reports → ch5"
  - "cross-platform unified reporting and GA4 integration → ch7"
quiz_topics:
  - "difference between a page-visit and micro-conversion goal type"
  - "how Enhanced Conversions hashes first-party data"
  - "steps to validate Enhanced Conversions in diagnostics panel"
  - "Bid Strategy Report metric that signals learning period"
  - "required columns for a standard performance dashboard"
notebooklm_source_focus:
  - "Microsoft Advertising Enhanced Conversions documentation 2026"
  - "conversion goal types and UET linking"
  - "Bid Strategy Report metrics guide"
  - "custom reporting columns in Microsoft Advertising"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "A hotel booking site's detail modal opens without changing the URL. Which goal type captures this interaction?"
    options:
      - "UrlGoal — the destination URL pattern can match the current page"
      - "EventGoal — no URL change occurs; an explicit event push fires it"
      - "DurationGoal — time spent viewing the modal qualifies as a conversion"
      - "PagesViewedPerVisitGoal — the modal registers as an additional page view"
    correct_idx: 1
    explanation: "UrlGoal requires the browser to navigate to a matching destination URL. A single-page-application modal that doesn't change the URL produces zero UrlGoal conversions. EventGoal, triggered by window.uetq.push() or a CAPI custom event, is the correct type for URL-stable interactions."
    section_anchor: conversion-goal-types-page-visit-vs-micro-conversion
  - question: "Before SHA-256 hashing for Enhanced Conversions, which preprocessing order is correct for an email address?"
    options:
      - "Trim whitespace, remove dots from user portion, strip +alias, then lowercase"
      - "Lowercase the address first, then remove the +alias, then apply the hash"
      - "Remove the domain entirely and hash only the user portion of the string"
      - "SHA-256 accepts any raw email address without any normalization steps"
    correct_idx: 0
    explanation: "Microsoft's normalization pipeline is order-sensitive: trim → remove dots from user portion → strip +alias → lowercase → SHA-256. Reversing any pair of steps produces a hash that won't match Microsoft's user graph, yielding zero Enhanced Conversion uplift."
    section_anchor: enhanced-conversions-hashed-first-party-data
  - question: "After enabling Enhanced Conversions, where do you confirm hashed data is arriving and being matched?"
    options:
      - "The campaign performance chart on the Campaigns overview page"
      - "The UET tag helper browser extension in the account Tools menu"
      - "The conversion diagnostics panel inside the conversion goal's detail view"
      - "The BidStrategyReport ConversionsQualified column in the Reporting tab"
    correct_idx: 2
    explanation: "The conversion diagnostics panel shows goal status, tag status, and Enhanced Conversions match status in one place. The UET tag helper validates client-side tag firing (ch4's domain) but does not confirm Enhanced Conversions data flow."
    section_anchor: validating-with-the-conversion-diagnostics-panel
  - question: "Which Bid Strategy Report column is the primary signal that a Target CPA campaign is in a learning period?"
    options:
      - "TargetCPA — the set target value diverges from actual spend"
      - "ConversionDelay — rising lag between ad click and conversion"
      - "ImpressionSharePercent — share falls below the threshold amount"
      - "AvgTargetImpressionShare — target was adjusted too many times"
    correct_idx: 1
    explanation: "ConversionDelay measures the average gap between an ad click and conversion completion. A rising ConversionDelay combined with ConversionsQualified below 30 over a 30-day window is the diagnostic signature of a campaign stuck in learning."
    section_anchor: bid-strategy-report-reading-learning-period-signals
  - question: "Your dashboard shows zero conversions despite active traffic. What is the most likely cause?"
    options:
      - "The campaign daily budget is set too low to record conversions"
      - "The report is using the deprecated Conversions column not ConversionsQualified"
      - "Impression Share columns are missing from the required dashboard setup"
      - "The BidStrategyReport does not capture macro-conversion events by default"
    correct_idx: 1
    explanation: "The Conversions and AllConversions columns were deprecated in 2022. Reports now return 0 in those columns regardless of actual activity. The correct replacement is ConversionsQualified, which uses double-precision floats and supports offline attribution."
    section_anchor: building-your-performance-dashboard
---

## Conversion Goal Types: Page-Visit vs. Micro-Conversion

UET supports seven conversion goal types. For a hotel or travel advertiser, two cover the majority of use cases.

**UrlGoal (page-visit / booking confirmation)** fires automatically whenever a user loads a destination URL that matches your configured pattern. No custom event code is needed — the base UET tag sends a page load event, and Microsoft matches it against the goal. Use UrlGoal for macro-conversions where the final action is defined by reaching a unique URL: `/booking/confirmed`, `/order-complete`, `/thank-you`. According to the [Universal Event Tracking documentation](https://learn.microsoft.com/en-us/advertising/guides/universal-event-tracking?view=bingads-13), this is the simplest goal type to deploy and should be your first conversion goal in any new account.

**EventGoal (micro-conversion)** fires when a specific custom event is pushed to the UET data layer — either `window.uetq.push('event', 'action', {…})` in JavaScript, or a `custom` CAPI payload. Use EventGoal for intent signals that don't change the URL: "viewed hotel details," "started checkout," "added to cart," "completed search." Each micro-conversion feeds additional signal to your bidding model and gives you full-funnel visibility. Critically, a single-page-application modal that opens without a URL change will never trigger a UrlGoal — those interactions require EventGoal.

One UET tag ID supports multiple conversion goals simultaneously. There is no need to create separate tags per goal.

<KnowledgeCheck question="A hotel booking site's detail modal opens without changing the URL. Which goal type captures this?" options={["UrlGoal", "EventGoal", "DurationGoal", "InStoreTransactionGoal"]} correctIdx={1} explanation="UrlGoal requires a URL change to fire. EventGoal fires on explicit event pushes, making it the correct choice for SPA interactions that keep the URL static." />

## Linking Goals to Your UET Tag

Your UET tag was installed and verified in chapter 4. Goal creation follows this path in Microsoft Advertising: **Tools → Conversion Tracking → Conversion Goals → Create Conversion Goal**.

Select the goal type (Url or Event), configure the revenue value (fixed or variable), and choose the UET tag ID from the dropdown. That tag ID is the bridge between user behavior on your site and conversion credit in your campaigns. For your booking confirmation UrlGoal, assign a fixed revenue value equal to your average booking amount — this populates `Revenue` in your performance dashboard and is what drives Target ROAS optimization.

For EventGoals, configure the event action name to match exactly what your JavaScript pushes. A mismatch between the UI's event name and the `window.uetq.push` action string produces silent zero-conversion recording with no error surfaced.

## Enhanced Conversions: Hashed First-Party Data

Enhanced Conversions recovers conversions that cookie restrictions and cross-device journeys would otherwise miss by supplementing UET data with hashed customer identity signals. Launched across Americas and Europe in February 2024 per the [Enhanced Conversions blog](https://about.ads.microsoft.com/en/blog/post/february-2024/enhanced-conversions-and-other-updates-for-february), it is now broadly available.

Implementation requires SHA-256 hashing of both the customer's email (`em`) and phone (`ph`) at the point of conversion, passed in the CAPI `userData` object. Microsoft matches these hashes against its logged-in user graph. No plaintext PII ever leaves your server.

Email normalization is **order-sensitive**. Apply all five steps before hashing:

1. Trim leading/trailing whitespace
2. Split at `@`; remove all dots from the user portion
3. Remove `+alias` from the user portion
4. Convert the entire address to lowercase
5. Apply SHA-256; format output as lowercase hexadecimal

```python
import hashlib

def hash_email_for_enhanced_conversions(raw_email: str) -> str:
    email = raw_email.strip()
    user, domain = email.split('@', 1)
    user = user.replace('.', '')
    user = user.split('+')[0]
    normalized = f"{user}@{domain}".lower()
    return hashlib.sha256(normalized.encode('utf-8')).hexdigest()

def hash_phone_for_enhanced_conversions(e164_phone: str) -> str:
    # Input must be E.164 format, e.g., "+14255551234"
    return hashlib.sha256(e164_phone.encode('utf-8')).hexdigest()
```

<Callout type="warning">
Sending an un-normalized email like `John.Doe+alias@EXAMPLE.COM` through SHA-256 without preprocessing produces a hash Microsoft's user graph won't match — yielding zero Enhanced Conversion uplift with no error in the UI. The normalization steps are mandatory and order-sensitive. Per the [CAPI Guide](https://learn.microsoft.com/en-us/advertising/guides/uet-conversion-api-integration?view=bingads-13), skipping any single step produces a non-canonical hash.
</Callout>

<KnowledgeCheck question="What preprocessing must be applied to an email before SHA-256 hashing for Enhanced Conversions?" options={["Lowercase → strip alias → remove dots → SHA-256", "Trim whitespace → remove dots → strip +alias → lowercase → SHA-256", "Remove the domain → hash user portion only", "SHA-256 directly on the raw email string"]} correctIdx={1} explanation="The pipeline is strict: trim → remove dots from user portion → strip +alias → lowercase → SHA-256. Out-of-order normalization produces a non-canonical hash that won't match the Microsoft user graph." />

## Validating with the Conversion Diagnostics Panel

After deploying Enhanced Conversions, verify it is working at **Tools → Conversion Tracking → Conversion Goals → [Select Goal] → Diagnostics**. The panel reports three independent health indicators:

- **Goal status:** Active, Inactive, or No recent conversions
- **Tag status:** Whether the UET tag is sending events to this goal
- **Enhanced Conversions status:** Whether hashed user data is arriving and being matched

A healthy goal shows green on all three. If Enhanced Conversions status shows "No data received," audit your CAPI payload for the `userData.em` or `userData.ph` fields — they are most likely absent or structurally malformed. The diagnostics panel does not replace the UET Tag Helper extension; use both, since the extension confirms client-side tag firing (ch4) while the panel confirms goal-level data health (ch6).

## Building Your Performance Dashboard

Use the AdPerformanceReport to build a standard dashboard. Per the [AdPerformanceReportColumn documentation](https://learn.microsoft.com/en-us/advertising/reporting-service/adperformancereportcolumn?view=bingads-13), these columns are required for meaningful analysis:

| Column | API Name | Formula |
|---|---|---|
| Impressions | `Impressions` | Raw count of ad displays |
| Clicks | `Clicks` | Paid clicks |
| CTR | `Ctr` | (Clicks / Impressions) × 100 |
| Avg. CPC | `AverageCpc` | Spend / Clicks |
| Conversions | `ConversionsQualified` | Use this — not deprecated `Conversions` |
| CPA | `CostPerConversion` | Spend / Conversions |
| Revenue | `Revenue` | Advertiser-reported conversion revenue |
| ROAS | `ReturnOnAdSpend` | Revenue / Spend |
| Top Impression Rate | `TopImpressionRatePercent` | % of impressions in mainline positions |

The `Conversions` and `AllConversions` columns were deprecated in 2022 and now return `0` in all reports. `ConversionsQualified` is the replacement; it returns double-precision floats that support partial offline attribution.

## Bid Strategy Report: Reading Learning-Period Signals

Pull a BidStrategyReport with a 30-day date range whenever a Target CPA or Target ROAS campaign is underperforming. Key columns: `ConversionDelay`, `ConversionsQualified`, `AvgTargetCPA`, `CostPerConversionQualified`.

Three new metrics launched in May 2026 per the [product news blog](https://about.ads.microsoft.com/en/blog/post/may-2026/new-import-center-and-other-product-news-for-may-2026): `AvgTargetCPA`, `AvgTargetRoas`, and `AvgTargetImpressionShare`, available at campaign, account, and portfolio scope. At account scope, `AvgTargetImpressionShare` is weighted by campaign daily spend.

**Learning period diagnostic checklist:**
- `ConversionsQualified` < 30 over 30 days → bid strategy has stopped optimizing; this is the prerequisite failure
- `ConversionDelay` rising → conversions lagging significantly behind clicks
- `AvgTargetCPA` diverging from `TargetCPA` → algorithm struggling to hit the set target
- `CostPerConversionQualified` > 150% of `TargetCPA` → system still in pattern-matching mode

Per the [Budget and Bid Strategies guide](https://learn.microsoft.com/en-us/advertising/guides/budget-bid-strategies?view=bingads-13), Target CPA stops optimizing below 30 conversions per 30-day period; Target ROAS requires 30 conversions AND non-zero revenue. Remediation priority: first add micro-conversion EventGoals to feed more signal; then broaden match types to increase eligible volume; then temporarily switch to Maximize Conversions until the threshold is met.

## Hands-On Exercise

**Build a full conversion tracking stack for a hotel booking campaign.**

1. In Microsoft Advertising, create a **UrlGoal** named "Booking Confirmed" pointing to your `/booking/confirmed` URL. Assign fixed revenue equal to your average booking value. Link it to the UET tag installed in ch4.
2. Create an **EventGoal** named "Checkout Started" with event action `begin_checkout`. Link it to the same UET tag.
3. Enable Enhanced Conversions on the Booking Confirmed goal. Add the Python hashing function above to your checkout server. Pass hashed `em` and `ph` in the CAPI `userData` object alongside the `msclkid`.
4. Wait 24 hours, then open the conversion diagnostics panel for each goal. Confirm all three status indicators are green.
5. Pull an AdPerformanceReport using the dashboard columns from this chapter. Verify `ConversionsQualified` returns non-zero data and that ROAS calculates correctly.

**Success criteria:** Both goals show Active status in diagnostics, Enhanced Conversions shows "Data received," and your performance dashboard returns `ConversionsQualified` > 0 with correct CPA and ROAS values.

Next: [[07-cross-platform-budget-allocation]] — using your per-channel conversion data to split budget intelligently between Google Ads and Microsoft Advertising.
