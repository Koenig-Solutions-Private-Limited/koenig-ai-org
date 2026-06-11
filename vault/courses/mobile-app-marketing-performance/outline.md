---
course_slug: mobile-app-marketing-performance
title: "App & Mobile Marketing for Performance Marketers: ASO, Attribution & In-App Engagement"
status: outline-g0-passed
course_track: career
toc_locked: true
video_overview: true
koenig_recommendation: "The single most critical skill gap for Performance Marketing Specialists targeting travel-tech, fintech, or e-commerce: most PPC-trained marketers know Google/Meta web campaigns but cannot operate an MMP, run store listing experiments, or read SKAN attribution. This course closes that gap end-to-end — from ASO keyword taxonomy to a Looker Studio dashboard that joins AppsFlyer cohort data with GA4 behavioral data. A candidate who completes it can walk into a mobile-first company and own the full performance stack on day one."
author: course-architect
level: Builder
vendor_tag: AppsFlyer · Google App Campaigns · Meta App Ads · GA4 · CleverTap
target_audience: "Mid-level marketers targeting Performance Marketing Specialist roles at travel-tech, fintech, or consumer app companies who know web paid campaigns (Google/Meta) but lack hands-on mobile marketing skills: MMP setup, ASO, push engagement, and app analytics."
prerequisites:
  - "Familiarity with paid digital marketing concepts: campaigns, conversions, audiences, ROAS"
  - "Basic understanding of the App Store and Google Play as distribution channels"
  - "Access to a Google account; free-tier AppsFlyer and Firebase accounts are sufficient for exercises"
learning_outcomes:
  - "Map the full mobile marketing funnel from store discovery to in-app revenue, naming the KPI at every stage"
  - "Write keyword-optimized ASO metadata for both iOS and Google Play following 2026 indexing rules, and run a store listing A/B test"
  - "Configure an MMP (AppsFlyer or Branch), define an in-app event taxonomy, and read attribution reports across last-click, multi-touch, and SKAN models"
  - "Build segmented push and in-app messaging campaigns in CleverTap or MoEngage, with deep links and opt-out threshold alerts"
  - "Instrument a mobile app with GA4 via GTM Firebase tag type, build Firebase-linked retargeting audiences, and generate channel-ROAS Exploration reports"
  - "Launch, optimize, and diagnose paid app install and re-engagement campaigns on Google App Campaigns and Meta App Ads using MMP funnel data"
  - "Construct a unified Looker Studio dashboard joining AppsFlyer cohort data with GA4 behavioral data, and deliver a data-backed optimization recommendation"
total_duration_min: 365
chapter_count: 7
sources: []
---

## Chapter 1: Mobile App Marketing Fundamentals & the Travel-Tech Context

**Duration:** ~40 min
**Learning objectives:**
- Diagram the mobile marketing funnel (awareness → install → activation → retention → revenue) and label the key KPI at each stage
- Distinguish the roles of organic ASO, paid UA, and in-app engagement within a single growth strategy
- Identify the primary mobile marketing channels (app stores, push, in-app, paid social, deep links) and the tools used to manage each
- Define core mobile metrics — DAU/MAU, install-to-event rate, ROAS, LTV — and explain what each signals about campaign health

**Key concepts:** mobile marketing funnel, funnel-stage KPI mapping, DAU/MAU ratio, install-to-event rate, ROAS, LTV, organic ASO vs paid UA vs in-app engagement distinction, channel and tool landscape overview, iOS App Store vs Google Play ecosystem, travel-tech revenue model context

**Hands-on exercise:** Map a fictional travel-tech app (EaseMyTrip-inspired) to the five funnel stages. For each stage, write the one KPI you would report to a growth manager and explain what a 20% drop in that metric would mean operationally.

---

## Chapter 2: App Store Optimization (ASO): Ranking & Converting on iOS and Google Play

**Duration:** ~55 min
**Learning objectives:**
- Write keyword-optimized metadata (title, subtitle/short description, keyword field) following 2026 indexing rules for both App Store and Google Play separately
- Audit and redesign screenshot sets and preview videos to pass the 3-second visual test and incorporate OCR-readable captions indexed by Apple
- Set up and interpret a store listing experiment (Google Play Store Listing Experiments or Apple's Custom Product Pages) to A/B test creatives
- Build a review-management workflow: solicit ratings at the right in-app moment, respond to negative reviews, and monitor rating trends via App Store Connect or Google Play Console

**Key concepts:** iOS metadata field limits and indexing rules (title 30 chars, subtitle 30 chars, keyword field 100 chars), Google Play metadata fields (title 30 chars, short description 80 chars, long description 4000 chars), screenshot 3-second test, Apple OCR caption indexing, app preview video autoplay standards, Google Play Store Listing Experiments, Apple Custom Product Pages, review solicitation timing, negative review response templates, rating trend monitoring

**Hands-on exercise:** Write a complete ASO metadata set for a travel booking app — one version for the App Store and one for Google Play — using a provided keyword list. Critique a supplied screenshot set against the 3-second visual test checklist and propose two improvements. Set up a two-variant store listing experiment in Google Play Console comparing two icon designs.

---

## Chapter 3: Mobile Attribution with AppsFlyer & Branch: Setup, Events & Privacy

**Duration:** ~60 min
**Learning objectives:**
- Integrate AppsFlyer or Branch SDK tracking links and configure at least three campaign sources (Google UAC, Meta, organic) with correct UTM and campaign naming conventions
- Define and map 5–10 critical in-app events (e.g., search, booking-initiated, purchase) to business outcomes and verify they fire correctly in the MMP dashboard
- Read an attribution report and distinguish last-click, multi-touch, and SKAN/privacy-modeled data — documenting what each can and cannot assert
- Identify and flag two common attribution fraud signals (install flooding, click injection) and describe the platform settings used to block them

**Key concepts:** AppsFlyer SDK integration, Branch Universal Links/App Links, tracking link anatomy (UTM parameters, campaign naming taxonomy), in-app event taxonomy design, event verification in MMP dashboard, last-click vs multi-touch vs SKAN attribution models, iOS ATT consent and attribution completeness, Android Privacy Sandbox implications, SKAN conversion value schema, AppsFlyer Protect360, install flooding pattern, click injection pattern

**Hands-on exercise:** Using AppsFlyer's free account, create three tracking links for Google UAC, a Meta campaign, and organic. Define a five-event taxonomy (search → select-flight → booking-initiated → payment-entered → purchase) with business outcome mapping. Simulate a test install and verify all five events appear in the MMP dashboard. Review a provided attribution report screenshot and annotate: which rows are last-click, which are SKAN-modeled, and which show fraud signals.

---

## Chapter 4: Push Notifications & In-App Messaging: Designing Campaigns That Convert

**Duration:** ~50 min
**Learning objectives:**
- Create a segmented push notification campaign in a mobile engagement platform (CleverTap, MoEngage, or Firebase Cloud Messaging) targeting at least two distinct user cohorts
- Write and schedule an in-app message (banner, modal, or full-screen) tied to a specific user action or lifecycle trigger, with a measurable CTA
- Configure deep links within push and in-app messages so tapping routes users to the correct in-app screen (e.g., a specific flight search result)
- Define opt-out rate, delivery rate, and click-to-open rate benchmarks and set up an alert when opt-out rate exceeds a threshold

**Key concepts:** CleverTap/MoEngage campaign builder, user cohort segmentation (behavioral + lifecycle), push notification copy and scheduling, send-time optimization, in-app message formats (banner vs modal vs full-screen), lifecycle trigger vs time-based trigger vs event-sequence trigger, deep link routing within push messages, deferred deep links for re-engagement, push permission prompt timing, opt-out rate benchmarks, delivery rate and CTOR benchmarks, alert threshold configuration

**Hands-on exercise:** In a CleverTap or MoEngage trial account, create a push notification campaign targeting two cohorts: (1) users who searched but did not book in the last 7 days; (2) users who booked more than 30 days ago. Write distinct message copy for each. Add a deep link that routes the recipient to the flight-search screen pre-populated with their last searched route. Set an opt-out rate alert threshold of 3%.

---

## Chapter 5: Mobile Campaign Analytics: Google Analytics 4 & GTM for Apps

**Duration:** ~55 min
**Learning objectives:**
- Configure a GA4 property for a mobile app, enable data streams, and verify that custom events flow in correctly using DebugView
- Set up Firebase-linked audiences in GA4 based on in-app behavior (e.g., users who searched but did not book) and export them to Google Ads for retargeting
- Use Google Tag Manager's Firebase tag type to deploy or update event tracking without a new app release
- Build a GA4 Exploration report combining channel acquisition, in-app funnel steps, and revenue to calculate channel-level ROAS

**Key concepts:** GA4 mobile data stream setup, Firebase project linking, GA4 DebugView for mobile event validation, custom event naming conventions, GTM Firebase tag type, GTM mobile container vs web container differences, Firebase-linked audiences (behavioral segments), Google Ads audience export eligibility and size minimums, GA4 Exploration funnel reports, channel-level ROAS calculation in GA4, GA4 vs MMP attribution discrepancy

**Hands-on exercise:** Create a GA4 property, link a Firebase project, and use DebugView to confirm three custom events arrive (search, booking-initiated, purchase). Build a Firebase-linked audience: "users who triggered search but not purchase in last 14 days." Build a GA4 Exploration funnel from channel (first user source) → search event → booking-initiated → purchase, and calculate the ROAS for two channels using the provided mock revenue data.

---

## Chapter 6: Paid Mobile User Acquisition: Google App Campaigns & Meta App Ads

**Duration:** ~55 min
**Learning objectives:**
- Create a Google App Campaign (installs objective) with correctly structured asset groups — headlines, descriptions, images, HTML5, and video — and link it to the Firebase/GA4 conversion event
- Set up a Meta App Ads campaign with SKAdNetwork integration enabled, configure an App Event Optimization goal beyond installs (e.g., purchase), and verify postback receipt in AppsFlyer
- Build a re-engagement campaign on either platform targeting lapsed users identified via MMP cohort data, using deferred deep links to return them to a specific in-app flow
- Diagnose an underperforming campaign using MMP install-to-event funnel data and propose two creative or audience adjustments backed by the data

**Key concepts:** Google App Campaign asset groups, tCPI vs tCPA bidding, Firebase/GA4 conversion event linking, Meta App Ads structure, SKAdNetwork SKAN postback receipt verification, App Event Optimization (AEO) for purchase, re-engagement campaign types (Google re-engagement / Meta app re-engagement), deferred deep links in re-engagement ads, MMP cohort lapsed-user segment export, install-to-event funnel diagnosis, creative vs audience root-cause identification

**Hands-on exercise:** In Google Ads, create an App Campaign draft with an installs objective: populate one asset group with 3 headlines, 2 descriptions, 3 images, and a 15-second video asset. Link it to the Firebase purchase event. In Meta Ads Manager, create an App Ads campaign with AEO set to purchase and confirm SKAdNetwork is enabled. Review a provided MMP funnel report (install → search → booking-initiated: 42% → 8% → 2%) and write a two-paragraph diagnosis identifying whether the drop is a creative, audience, or in-app experience issue.

---

## Chapter 7: Measuring & Reporting Mobile Marketing Performance End-to-End

**Duration:** ~50 min
**Learning objectives:**
- Design a mobile marketing KPI framework covering acquisition (CPI, organic install share), activation (D1 retention, onboarding completion), monetization (ROAS, LTV), and ASO health (keyword rank, CVR)
- Export and join AppsFlyer cohort data with GA4 behavioral data to produce a channel-level LTV comparison across at least three acquisition sources
- Construct a weekly performance report template (using Google Looker Studio or similar) with traffic-light thresholds that highlight channels needing budget reallocation
- Present a data-backed optimization recommendation — covering ASO, paid spend, and push messaging — for a hypothetical month where bookings declined 15%

**Key concepts:** mobile KPI framework (AARRR applied to mobile), four metric tiers (acquisition, activation, monetization, ASO health), AppsFlyer cohort data export methodology, GA4 behavioral data export (BigQuery or CSV), cross-source data joining for LTV calculation, Looker Studio data connectors (AppsFlyer + GA4), weekly performance report structure, traffic-light threshold design, optimization recommendation framework, 15%-decline diagnosis worked example, reporting cadence (weekly vs monthly vs quarterly)

**Hands-on exercise:** Using provided CSV exports from a mock AppsFlyer cohort report and a GA4 channel acquisition report, join them on channel name and calculate 30-day LTV for three acquisition sources (Google App Campaigns, Meta App Ads, organic ASO). Build a Looker Studio dashboard with four scorecard tiles (CPI, D1 retention, ROAS, keyword rank CVR) and set traffic-light thresholds. Write a one-page optimization recommendation for the 15% booking decline scenario provided, citing at least three specific data points.

---

## Capstone: Full Mobile Marketing Audit & Optimization Plan

Using a provided mock data package (AppsFlyer cohort CSV, GA4 export, ASO audit snapshot, push campaign performance report, paid campaign MMP funnel), learners will: score ASO health using the ch2 metadata checklist; identify attribution gaps using ch3's fraud-signal criteria and SKAN confidence assessment; evaluate push campaign opt-out rate against the ch4 benchmark and propose one copy or segmentation fix; diagnose the highest-drop funnel stage using ch6's MMP diagnosis methodology; and deliver a prioritized two-week optimization plan with one action per channel (ASO, paid UA, push) backed by specific data evidence. Deliverable: a completed Looker Studio dashboard (or Sheets mock) and a one-page written optimization recommendation.
