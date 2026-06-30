---
chapter_num: 4
course_slug: mobile-app-marketing-performance
title: "Push Notifications & In-App Messaging: Designing Campaigns That Convert"
status: g3-passed
last_updated: 2026-06-11
duration_min: 35
vendor_tag: CleverTap · MoEngage · Firebase
learning_objectives:
  - "Select the correct engagement platform (FCM, MoEngage, or CleverTap) based on segmentation depth and delivery reliability requirements"
  - "Build a segmented push campaign using behavioral, lifecycle-stage, and demographic filters"
  - "Choose the correct in-app message format (banner, modal, full-screen) and configure lifecycle triggers for each scenario"
  - "Distinguish standard deep links from deferred deep links and apply the right type in re-engagement campaigns"
  - "Set opt-out rate alert thresholds and apply send-time optimization to improve reaction rates without cohort splitting"
sources:
  - url: "https://firebase.google.com/docs/cloud-messaging"
    title: "Firebase Cloud Messaging — Google Firebase Documentation"
  - url: "https://docs.clevertap.com/docs/push"
    title: "Push Notification — CleverTap Documentation"
  - url: "https://docs.clevertap.com/docs/create-message-push"
    title: "Create Message (Push) — CleverTap Documentation"
  - url: "https://docs.clevertap.com/docs/ab-multivariate-testing"
    title: "A/B & Multivariate Testing — CleverTap Documentation"
  - url: "https://docs.clevertap.com/docs/segmentation-rules"
    title: "Segmentation Rules — CleverTap Documentation"
  - url: "https://help.moengage.com/hc/en-us/articles/208735856-Overview-Mobile-Push"
    title: "Overview — Mobile Push — MoEngage User Guide"
  - url: "https://help.moengage.com/hc/en-us/articles/360045818091-In-App-Templates"
    title: "In-App Templates — MoEngage User Guide"
  - url: "https://clevertap.com/blog/push-notification-metrics-ctr-open-rate/"
    title: "10 Push Notification Metrics You Need to Track — CleverTap Blog"
  - url: "https://adapty.io/blog/deferred-deep-linking/"
    title: "Deferred Deep Linking in iOS and Android: Guide for 2026 — Adapty"
  - url: "https://www.mobiloud.com/blog/push-notification-opt-in-rate"
    title: "Average Push Notification Opt-In Rate — MobiLoud"
  - url: "https://maestra.io/blog/comparisons/moengage-vs-clevertap"
    title: "MoEngage vs CleverTap: Best Engagement Platform? — Maestra"
owns:
  - "mobile engagement platform selection: CleverTap, MoEngage, and Firebase Cloud Messaging — capability comparison"
  - "user cohort segmentation for push: behavioral, lifecycle-stage, and demographic dimensions"
  - "push notification campaign creation: audience targeting, message copy, scheduling, and send-time optimization"
  - "in-app message formats: banner, modal, and full-screen — when to use each and CTA design"
  - "lifecycle trigger configuration: user action triggers, time-based triggers, and event-sequence triggers for in-app messages"
  - "deep link configuration within push and in-app messages: routing to specific in-app screens (e.g., flight search results)"
  - "deferred deep links for re-engagement: how they differ from standard deep links in push context"
  - "push notification permission prompt timing and permission rate benchmarks by platform"
  - "opt-out rate benchmarks by channel and message frequency"
  - "delivery rate and click-to-open rate benchmarks for mobile push"
  - "alert threshold setup: configuring opt-out rate alerts in CleverTap/MoEngage"
  - "A/B testing push copy and timing in engagement platforms"
defers_to:
  - "URI scheme and Universal Links technical setup → ch3"
  - "GA4 Firebase-linked audiences for retargeting → ch5"
  - "paid re-engagement campaigns on Google and Meta → ch6"
  - "MMP attribution of push-driven installs → ch3"
quiz_topics:
  - "difference between a lifecycle trigger and a time-based trigger for an in-app message"
  - "when to use a deferred deep link in a push notification vs a standard deep link"
  - "industry benchmark for push opt-out rate that should trigger a campaign frequency review"
  - "which engagement platform capability distinguishes CleverTap from plain Firebase Cloud Messaging for segmentation"
  - "how to A/B test push notification send time in a mobile CRM platform without splitting the user cohort"
notebooklm_source_focus:
  - "CleverTap and MoEngage push notification campaign setup and segmentation documentation 2025–2026"
  - "Firebase Cloud Messaging FCM push notification setup guide"
  - "mobile push notification benchmarks opt-out rates delivery rates click-to-open 2026"
  - "deep links within push notifications routing and deferred deep link setup"
  - "in-app messaging formats banner modal full-screen best practices and CTA design"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which capability does CleverTap provide for audience segmentation that Firebase Cloud Messaging alone cannot offer?"
    options:
      - "Delivery of push notifications to iOS and Android devices from a single API endpoint"
      - "Behavioral segment filtering using up to 10,000 stored user data points per month"
      - "Topic-based fan-out messaging to groups of devices sharing a subscription key"
      - "Automatic fallback delivery when the primary device push token is stale"
    correct_idx: 1
    explanation: "FCM handles message transport only. CleverTap's TesseractDB stores up to 10,000 user data points per user per month with 10-year history, enabling behavioral and lifecycle segments that FCM cannot build natively."
    section_anchor: choosing-your-engagement-stack

  - question: "Which best describes the difference between a user action trigger and a time-based trigger?"
    options:
      - "A user action trigger fires on a fixed calendar schedule; a time-based trigger fires when the user completes an event"
      - "A user action trigger fires when a specific in-app event occurs; a time-based trigger fires on a clock schedule regardless of user behavior"
      - "A user action trigger requires the user to be in an active session; a time-based trigger only fires when the user is offline"
      - "A user action trigger applies to push notifications only; a time-based trigger applies to in-app messages only"
    correct_idx: 1
    explanation: "A user action (behavioral) trigger fires in response to a specific in-app event such as 'added to cart.' A time-based trigger fires at a defined clock time or duration milestone — independent of what the user did or did not do."
    section_anchor: lifecycle-triggers

  - question: "When should you use a deferred deep link instead of a standard deep link in a push re-engagement campaign?"
    options:
      - "When you want to route active users to an in-app screen more than two navigation levels deep"
      - "When a portion of the target audience may have uninstalled the app and must be routed to the correct screen post-reinstall"
      - "When the push campaign targets users who have never opened the app in the current version"
      - "When the in-app destination requires a server-side parameter that changes every session"
    correct_idx: 1
    explanation: "A standard deep link silently fails if the app is not installed. A deferred deep link stores the intended destination, routes the user through the app store install, and then navigates to the correct screen on first post-install launch."
    section_anchor: deep-links-in-push-standard-vs-deferred

  - question: "At what sustained per-campaign push opt-out rate should a team trigger a frequency review?"
    options:
      - "When opt-out rate exceeds 10% in a single campaign send to any audience segment"
      - "When the per-campaign opt-out rate exceeds 2% on a sustained basis"
      - "When 50 or more absolute users opt out from a single campaign send"
      - "When opt-out rate exceeds the platform's default 5% monthly alert threshold"
    correct_idx: 1
    explanation: "Industry guidance treats a sustained per-campaign opt-out rate above 2% as the threshold for reviewing message frequency. A documented example: 120 opt-outs from a 5,000-user send (2.4%) is the monitoring benchmark cited in CleverTap documentation."
    section_anchor: permission-rates-opt-out-and-alert-thresholds

  - question: "How can a marketer A/B test push send time in CleverTap or MoEngage without splitting the user cohort into separate arms?"
    options:
      - "Create two campaigns at different times and merge analytics reports after 48 hours"
      - "Enable send-time optimization so the platform delivers to each user at their individually predicted best time"
      - "Use a holdout group for each time window and compare open rates after the campaign closes"
      - "Schedule the campaign at three different times and rotate the audience across windows daily"
    correct_idx: 1
    explanation: "Send-time optimization (STO) uses each user's historical engagement timestamps to predict their personal optimal delivery window. The full audience receives one campaign — no cohort split — each user at a different time. Impact: 40% improvement in reaction rate."
    section_anchor: campaign-build-copy-scheduling-and-send-time-optimization
---

# Push Notifications & In-App Messaging: Designing Campaigns That Convert

The gap between a push that converts and one that triggers an opt-out comes down to three decisions: right platform, right segment, right trigger. This chapter walks you through each.

## Choosing Your Engagement Stack

FCM is delivery infrastructure, not a marketing platform. It routes notification payloads to iOS, Android, and web but provides no audience segmentation, A/B testing, send-time optimization, or campaign analytics. [Firebase Cloud Messaging — Google Firebase Documentation](https://firebase.google.com/docs/cloud-messaging) CleverTap and MoEngage sit on top of FCM and add all campaign-management capabilities.

The decisive differentiator between the two engagement platforms is data depth. CleverTap's TesseractDB stores up to 10,000 user data points per month with 10-year actionable history, enabling fine-grained multi-event behavioral segments. MoEngage retains 50–150 data points per user per month — adequate for lifecycle and demographic segmentation, but limiting for complex behavioral cohorts. [MoEngage vs CleverTap — Maestra](https://maestra.io/blog/comparisons/moengage-vs-clevertap)

Android delivery reliability is another split: CleverTap's RenderMax™ achieves 90%+ push render rates by counteracting OS-level power-optimization on Samsung OneUI and Xiaomi MIUI devices that otherwise silently drop notifications. MoEngage has no comparable mechanism. On budget, MoEngage offers a free tier up to 10,000 monthly tracked users; CleverTap has no free tier and requires an enterprise contract.

<KnowledgeCheck question="What does Firebase Cloud Messaging provide that CleverTap and MoEngage do not?" options={["Behavioral audience segmentation and multi-event cohort filters", "Push delivery infrastructure routing payloads to iOS, Android, and web", "Send-time optimization based on individual user engagement history", "A/B testing with automatic winner deployment to the remaining audience"]} correctIdx={1} explanation="FCM handles message transport only — it has no campaign management layer. CleverTap and MoEngage are marketing platforms that use FCM as a delivery layer while adding segmentation, analytics, and optimization on top." />

## Segmenting Push Audiences

Three dimensions define a targeted push segment:

**Behavioral:** Target users by actions taken or not taken — "users who searched a flight route in the last 7 days but did not complete a booking." In CleverTap, this uses Event (Did) and Event (Have Not Done) filters with count and sum aggregations.

**Lifecycle-stage:** Combine event-frequency filters with timestamp properties — new users (0–7 days post-install), at-risk (declining session frequency), lapsed (no activity 30+ days).

**Demographic:** Target by user property attributes — geography, device OS, language, or custom profile fields such as subscription tier.

Segment precision drives results: contextual campaigns personalized to user behavior average a 16.3% open rate, versus 4.7% for generic broadcasts. [10 Push Notification Metrics — CleverTap Blog](https://clevertap.com/blog/push-notification-metrics-ctr-open-rate/)

## Campaign Build: Copy, Scheduling, and Send-Time Optimization

CleverTap's push campaign wizard runs four steps: **Start Here** (platform, conversion goal) → **Who** (audience segment) → **What** (message content, deep link URL, A/B variant config) → **When** (schedule, DND window, Time-to-Live). The deep link destination field lives in the What step.

Keep notification titles under 40 characters to avoid lock-screen truncation on most Android devices. Personalized bodies referencing a specific user action — "your saved flights just dropped" — consistently outperform generic copy.

**Send-time optimization (STO)** removes the false constraint of a single broadcast time. Both platforms analyze each user's historical engagement timestamps and deliver at the user's individual predicted best window. No cohort split is needed — the full audience receives one campaign, each user at a different time. The measured impact: tailored send times improve reaction rates by 40%.

<Callout type="info">
STO is not appropriate for time-sensitive pushes like flash sales or breaking news, because delivery is spread over a window (typically 24 hours). Use STO for evergreen lifecycle notifications where timing flexibility exists.
</Callout>

## In-App Message Formats

Choose the format by urgency and the action you need the user to take:

| Format | MoEngage name | Use when |
|--------|---------------|----------|
| Banner | Nudge | Ambient promotion; user stays in current app flow |
| Modal | Popup | Mid-funnel CTA; a brief pause is acceptable |
| Full-screen | Full-screen | Critical interruption: mandatory update, major onboarding milestone |

The most common misuse is full-screen for routine promotions. Full-screen blocks all app interaction until dismissed — that friction is appropriate for mandatory app updates, not a discount banner. Use a nudge for lightweight announcements; use a popup modal for single-CTA conversion moments.

CTA design matches format: a nudge uses a text link with minimal visual weight; a modal uses one primary button (minimum 48 dp touch target) plus a secondary dismiss option; full-screen shows one dominant CTA with a dismiss option appearing after 3 seconds. [In-App Templates — MoEngage User Guide](https://help.moengage.com/hc/en-us/articles/360045818091-In-App-Templates)

## Lifecycle Triggers

Three trigger types determine when a campaign fires:

**User action trigger:** Fires when the user performs a specific in-app event — "added to cart," "app opened after 14-day gap." Sends immediately or after a configurable delay following the event.

**Time-based trigger:** Fires at a fixed clock time or duration milestone, independent of user behavior — "send at 10 AM every Monday" or "3 days after install date."

**Event-sequence trigger:** Fires after a defined multi-step pattern with a negative condition — "viewed flight search → did NOT complete booking within 2 hours." Captures abandoned funnels without false-firing on already-converted users.

Event-triggered campaigns convert at 4× the rate of scheduled pushes, per MoEngage's platform data. [Overview — Mobile Push — MoEngage User Guide](https://help.moengage.com/hc/en-us/articles/208735856-Overview-Mobile-Push) Use time-based triggers only when business logic is genuinely clock-driven — weekly digests, renewal reminders, birthday offers.

<KnowledgeCheck question="A welcome message fires 24 hours after install — including to users who already completed onboarding. Which trigger type caused this?" options={["Event-sequence trigger with an incorrect negative condition", "Time-based trigger set to 24h after install date", "User action trigger without a lifecycle-stage filter", "Behavioral trigger firing on the first app_open event"]} correctIdx={1} explanation="A time-based trigger fires on the clock schedule regardless of what the user did. Configuring a welcome message as '24h after install' will send it to fully-onboarded users and users who never returned. A user action trigger (e.g., onboarding_not_completed after 24h) correctly excludes converted users." />

## Deep Links in Push: Standard vs Deferred

A **standard deep link** (`myapp://flights/BOM-DEL`) routes an existing app user directly to a specific screen. If the app is not installed, the link fails — the user lands on the App Store home screen with no context and no conversion path.

A **deferred deep link** stores the intended destination before routing the user to the app store. On first post-install launch, the app retrieves the stored destination and navigates there directly. For re-engagement campaigns targeting lapsed users (30–90 days inactive), a meaningful fraction will have uninstalled the app. A deferred deep link recovers those users; a standard link loses them entirely. Campaigns using deferred deep links improve conversion rates by over 50% compared to standard link fallback. [Deferred Deep Linking in iOS and Android — Adapty](https://adapty.io/blog/deferred-deep-linking/)

<Callout type="warning">
Firebase Dynamic Links — the dominant deferred deep link solution until 2024 — shut down in August 2025. Any CleverTap or MoEngage campaign configuration still using FDL URLs will silently fail for uninstalled users. Migrate to Branch, AppsFlyer deep links, Adjust, or a custom HTTPS universal link implementation before running re-engagement campaigns.
</Callout>

Configure deep links in CleverTap in the **What** step of the campaign wizard's URL field. In MoEngage, set the Notification Action type to "Deep-link to URI." URI scheme and Universal Links technical setup is covered in [[03-mobile-attribution-appsflyer-branch]].

## Permission Rates, Opt-Out, and Alert Thresholds

**Permission prompt timing** is the highest-leverage variable for opt-in rate. Triggering the OS permission dialog on first app launch produces 30–40% iOS opt-in. A custom pre-permission screen shown at the user's first clear value moment — after a successful flight search or account activation — achieves 55–70% opt-in. [Average Push Notification Opt-In Rate — MobiLoud](https://www.mobiloud.com/blog/push-notification-opt-in-rate)

Android 13+, widespread since 2024, requires an explicit opt-in prompt — functionally identical to iOS. Legacy dashboards may show ~91% Android opt-in from pre-Android 13 installs; plan new-user acquisition funnels on both platforms as requiring the same priming strategy.

**Key benchmarks:**

| Metric | Value |
|--------|-------|
| iOS opt-in rate (2025–2026) | 44–56% |
| Android 13+ opt-in (new installs) | ~67% |
| Opt-in with immediate OS prompt | 30–40% |
| Opt-in with pre-permission priming screen | 55–70% |
| Push delivery rate | ~95% |
| Average push CTR | 2.25–4.6% |
| Contextual push open rate | 16.3% |

**Opt-out alert threshold:** Sustained per-campaign opt-out rates above 2% signal over-notification and warrant a frequency review. Configure this in CleverTap under Settings → Setup → Campaign Limits (global DND and per-user frequency cap), or in MoEngage's campaign-level frequency cap fields. A 2.4% opt-out rate — 120 users from a 5,000-user send — is the documented monitoring benchmark.

---

## Hands-On Exercise: Re-Engagement Push with Deferred Deep Link

**Scenario:** A travel app has 25,000 opted-in Android users. Build a re-engagement campaign targeting users who searched a flight but did not book within 48 hours, including users who may have uninstalled.

1. Create a **segment** using an event-sequence trigger: Event "flight_search" completed AND Event "booking_initiated" NOT completed within 48 hours.
2. Write two push variants for an A/B test. Variant A references the searched route by name; Variant B offers a generic discount. Set equal distribution with auto-deployment of the winner after 30 minutes, minimum 5,000 users per variant.
3. Configure the push CTA as a **deferred deep link** (Branch or AppsFlyer) pointing to the flight search results screen for the user's last searched route.
4. Set an opt-out rate alert at the 2% threshold in your platform's campaign limits settings.

**Success criteria:** A/B winner declared within 1 hour; delivery rate ≥93% of opted-in segment; deep link routes installed-app users directly to their last flight search (verify in platform click preview); opt-out alert fires a test notification to the dashboard before the live send.

Next chapter: [[05-mobile-analytics-ga4-gtm]] covers how to wire GA4 and GTM for Apps to measure the conversions your push and in-app campaigns drive.
