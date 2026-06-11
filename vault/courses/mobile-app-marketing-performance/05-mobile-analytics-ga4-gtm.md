---
chapter_num: 5
course_slug: mobile-app-marketing-performance
title: "Mobile Campaign Analytics: Google Analytics 4 & GTM for Apps"
status: g3-passed
last_updated: 2026-06-11
duration_min: 25
vendor_tag: GA4 / GTM / Firebase
learning_objectives:
  - "Link a Firebase project to a GA4 property and explain why the connection is required before data streams activate"
  - "Identify which Firebase events are automatically collected vs which require custom instrumentation"
  - "Validate custom events in GA4 DebugView using ADB debug mode on Android"
  - "Deploy new event tracking in a mobile app using the GTM Firebase tag type without a new app release"
  - "Build a behavioral retargeting audience in GA4 and verify it meets the Google Ads 100-user eligibility threshold"
  - "Construct a Funnel Exploration in GA4 that maps acquisition channel to in-app steps to revenue"
  - "Explain why GA4 install counts differ from MMP install counts and which to use for budget decisions"
sources:
  - url: "https://support.google.com/analytics/answer/9289234"
    title: "Connect Firebase to Google Analytics"
  - url: "https://firebase.google.com/docs/analytics/debugview"
    title: "Debug events | Google Analytics for Firebase"
  - url: "https://support.google.com/analytics/answer/12800258"
    title: "Share audiences in GA4 with linked advertising products"
  - url: "https://support.google.com/analytics/answer/9327974"
    title: "GA4 Funnel exploration"
  - url: "https://developers.google.com/tag-platform/tag-manager/android/v5"
    title: "Google Tag Manager for Android v5"
  - url: "https://support.google.com/analytics/answer/9234069"
    title: "Automatically collected events in GA4/Firebase"
  - url: "https://support.google.com/google-ads/answer/7558048"
    title: "About audience segments in Audience Manager"
  - url: "https://support.google.com/analytics/answer/12229021"
    title: "Custom events – naming conventions and limits"
  - url: "https://support.google.com/analytics/answer/9353532"
    title: "Set up data collection for an app"
  - url: "https://support.google.com/analytics/answer/13656908"
    title: "Audience size differences between Google Analytics and Google Ads"
owns:
  - "GA4 property creation for a mobile app: data stream setup, Firebase project linking, and app registration"
  - "GA4 DebugView for mobile: verifying custom events flow in from the app"
  - "custom event configuration in GA4: naming conventions, parameter definitions, and event registration"
  - "Google Tag Manager Firebase tag type: deploying and updating event tracking without a new app release"
  - "GTM container setup for mobile (Firebase tag type): how it differs from web GTM containers"
  - "Firebase-linked audiences in GA4: building behavioral audiences (e.g., searched but did not book)"
  - "audience export from GA4 to Google Ads for retargeting — audience eligibility and size thresholds"
  - "GA4 Exploration reports: building funnels that combine channel acquisition, in-app steps, and revenue"
  - "channel-level ROAS calculation in GA4 using acquisition + revenue exploration"
  - "GA4 vs MMP attribution: understanding the relationship and why numbers differ"
  - "Firebase Analytics automatic events: what fires by default vs what requires custom instrumentation"
defers_to:
  - "MMP SDK setup, AppsFlyer/Branch event taxonomy, attribution models → ch3"
  - "push notification and in-app messaging campaign creation → ch4"
  - "Google App Campaigns and Meta App Ads campaign creation → ch6"
  - "unified cross-source dashboard joining GA4 + AppsFlyer in Looker Studio → ch7"
  - "ASO and store listing metadata → ch2"
  - "audience export via MMP (AppsFlyer audiences) → ch3 / ch7"
quiz_topics:
  - "how to link a Firebase project to a GA4 property and why this step is required before data streams activate"
  - "what the GTM Firebase tag type enables that a native SDK call does not — and its limitation"
  - "how to build a GA4 Exploration report that shows the acquisition-to-purchase funnel across channels"
  - "minimum audience size required before a GA4 Firebase-linked audience can be exported to Google Ads"
  - "why GA4-attributed installs differ from MMP-attributed installs and which source to use for budget decisions"
notebooklm_source_focus:
  - "GA4 mobile app data stream and Firebase project linking setup guide 2025–2026"
  - "Google Tag Manager Firebase tag type for mobile event tracking documentation"
  - "GA4 Firebase-linked audiences export to Google Ads for retargeting guide"
  - "GA4 Exploration reports funnel analysis and channel ROAS calculation 2026"
  - "GA4 DebugView mobile app custom event validation documentation"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "What is the correct path to link a Firebase project to an existing GA4 property, and why must this link exist before app data streams activate?"
    options:
      - "Firebase console → Project Settings → Integrations → Link Google Analytics; without this link, GA4 app data streams have no Firebase source and cannot receive any events from the app SDK"
      - "Google Ads Manager → Data Sources → Firebase → Connect; this step grants Google Ads the permissions needed before GA4 property data streams are allowed to activate"
      - "GA4 Admin → Data Streams → Enable Firebase SDK toggle; once enabled, GA4 automatically provisions a matching Firebase project and data begins flowing within minutes"
      - "GTM Mobile Container → Firebase reporting settings → Connect GA4 property; GTM acts as the required data bridge between Firebase SDK event collection and GA4 ingestion"
    correct_idx: 0
    explanation: "The Firebase ↔ GA4 link is established in Firebase console (Project Settings → Integrations) or in GA4 (Admin → Property → Firebase links). Without this one-to-one link, the app data stream has no Firebase project to receive events from, so data never flows into GA4 reports."
    section_anchor: linking-firebase-to-ga4-the-one-to-one-foundation
  - question: "What does the GTM Firebase tag type enable that a standard native SDK call cannot match — and what is its key limitation?"
    options:
      - "It lets you deploy new event definitions and parameter mappings without an app store release; its limitation is that auto-collected events like first_open and session_start cannot be blocked via GTM"
      - "It removes the need for a Firebase project link by routing events directly to the GA4 Measurement Protocol; its limitation is a mandatory 24-hour processing delay on all tag updates"
      - "It replaces the Firebase Analytics SDK entirely so the app needs no native Firebase initialization; its limitation is that the tag type only supports Android apps in the current 2026 SDK"
      - "It fires standard HTTP requests from the app to the GA4 Measurement Protocol endpoint on every event trigger; its limitation is that deployment requires an active GTM Premium subscription"
    correct_idx: 0
    explanation: "Mobile GTM intercepts Firebase logEvent() calls so you can define or modify tags in the GTM UI and publish them without going through app store review. However, auto-collected events (first_open, session_start, screen_view) fire regardless of GTM configuration and cannot be suppressed from mobile containers."
    section_anchor: gtm-for-mobile-the-firebase-tag-type
  - question: "In a GA4 Funnel Exploration for a travel app, you want to compare how paid vs organic users convert from install to booking. Which configuration achieves this?"
    options:
      - "Build a 5-step Funnel exploration from first_open to purchase, set First user source / medium as the breakdown dimension, and add paid vs organic segment overlays to compare channels"
      - "Build a Free-form exploration with purchase_revenue as the metric, filter rows by first_open event date, and use campaign name as the row dimension to compare channels"
      - "Use Path Exploration starting at first_open, apply a session source filter for 'google / cpc', and count completions through to the purchase event for each channel"
      - "Build a Cohort exploration with a 30-day cohort window, break down by default channel grouping, and configure purchase as the return-event criterion for measuring conversion"
    correct_idx: 0
    explanation: "Funnel Exploration is the correct technique for sequential step analysis. Using 'First user source / medium' as a breakdown dimension and segment overlays lets you see drop-off rates per acquisition channel side-by-side within the same funnel view."
    section_anchor: funnel-explorations-and-channel-roas
  - question: "You create a GA4 Firebase-linked audience called 'Searched – No Booking – 7d' and it shows 2,400 users in GA4. What must you verify before launching a Google Ads retargeting campaign against it?"
    options:
      - "Check Google Ads Audience Manager for at least 100 active users in the past 30 days; GA4 counts non-remarketable users who are excluded by consent and identity filters in Google Ads"
      - "Confirm the audience has existed for at least 90 days, because GA4 only activates the export pipeline after a minimum membership history requirement has been satisfied in the property"
      - "Export the audience to BigQuery to get the true count, since GA4 Audience Manager systematically inflates user estimates by 2–3x compared to actual exportable audience size"
      - "Enable Firebase auto-tagging in Google Ads linked account settings, as the audience export pipeline is disabled by default until auto-tagging is explicitly activated and confirmed"
    correct_idx: 0
    explanation: "Google Ads requires at least 100 active users (last 30 days) before a remarketing audience can serve ads. GA4 counts all users meeting criteria including those without ads personalization consent; Google Ads counts only remarketable users. A GA4 audience of 2,400 could show fewer than 100 in Google Ads Audience Manager."
    section_anchor: building-behavioral-audiences-for-retargeting
  - question: "Your GA4 shows 4,200 first_open events for a campaign, but your MMP shows only 3,100 attributed installs for the same period. Which statement correctly explains the gap and which source to use for budget decisions?"
    options:
      - "GA4 only attributes Google-network installs; MMPs track across Meta, Apple Search Ads, and other networks using cross-platform signals — making MMP installs the correct basis for multi-channel budget decisions"
      - "MMPs undercount because they deduplicate organic installs that GA4 double-counts; use GA4 for budget decisions when your campaigns are running only on Google-owned paid network properties"
      - "GA4 uses probabilistic fingerprinting while MMPs rely on deterministic device IDs; with iOS ATT restrictions, GA4 probabilistic matching is more accurate and should guide spend decisions"
      - "The gap is a time-zone processing lag that resolves in 7 days; use whichever number appears first for immediate decisions, then reconcile the final counts afterward"
    correct_idx: 0
    explanation: "GA4 attributes installs using Google-only signals (auto-tagging, Firebase SDK). It lacks visibility into attribution signals from non-Google networks. MMPs operate cross-network attribution using their own SDK data, probabilistic matching, and SKAN postbacks. Use MMP data when allocating budget across Google, Meta, and other paid channels."
    section_anchor: ga4-vs-mmp-two-attribution-lenses
---

## Linking Firebase to GA4: The One-to-One Foundation

The relationship between Firebase and GA4 is one-to-one: a single Firebase project connects to exactly one GA4 property, and vice versa. This constraint shapes your analytics architecture from day one — if you try to route two apps into the same property via two Firebase projects, you'll need separate properties for each.

To create the link, go to **Firebase console → Project Settings → Integrations** and click Link on the Google Analytics card. Select your GA4 account and property (or create one), then confirm. You can also initiate the link from GA4 at **Admin → Property → Product links → Firebase links**. After linking, your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) already contains the `google_app_id` — no SDK code change is required for the initial connection, as documented in [Connect Firebase to Google Analytics](https://support.google.com/analytics/answer/9289234).

Budget up to 24 hours after the initial link before events appear in GA4 reports. The linking account must hold Owner, Editor, or Admin in Firebase and Editor or above at the GA4 property level — role mismatches are the most common reason the link step fails silently.

## What Auto-Fires vs What You Instrument

Once the Firebase Analytics SDK initializes, a set of events fires with zero instrumentation. [Automatically collected events](https://support.google.com/analytics/answer/9234069) include `first_open`, `session_start`, `user_engagement`, `screen_view`, `in_app_purchase`, `app_update`, and `notification_open`. Some are platform-specific: `app_clear_data` is Android-only; `firebase_in_app_message_action` fires only on iOS.

These free events establish your install-to-session baseline immediately. Every step beyond them — `search_initiated`, `hotel_view`, `booking_complete` — requires either a `logEvent()` call in your app code or a GTM Firebase tag deployment.

## Custom Events: Naming Rules and Limits

Custom event names are case-sensitive, must start with a letter, and cap at 40 characters. `Add_To_Cart` and `add_to_cart` are counted as two distinct events in GA4 — a mistake that is easy to make and expensive to untangle post-launch. Each event supports up to 25 parameters. The hard ceiling for a mobile app is 500 distinct event types; names beyond that limit are silently dropped, creating invisible gaps between what your tags fire and what GA4 records. Establish `lowercase_snake_case` as your organization-wide convention and enforce it in code review before the first release, as described in [Custom events – naming conventions and limits](https://support.google.com/analytics/answer/12229021).

<KnowledgeCheck
  question="Your Android app fires both 'search_Initiated' and 'search_initiated' depending on which developer wrote the call. What is the impact in GA4?"
  options={[
    "GA4 treats them as two separate events, splitting your search event count across both names",
    "GA4 normalizes event names to lowercase automatically, so both map to the same event",
    "GA4 rejects the mixed-case version and logs a validation error in DebugView",
    "Only the first event name encountered per session is recorded; duplicates are deduplicated"
  ]}
  correctIdx={0}
  explanation="GA4 event names are case-sensitive. 'search_Initiated' and 'search_initiated' are counted as completely separate events, fragmenting your data. Enforce a single casing convention across all SDK and GTM calls."
/>

## Validating Events with DebugView

In production, the Firebase SDK batches events and uploads approximately every hour — far too slow for QA. Enable debug mode on an Android test device with a single ADB command:

```
adb shell setprop debug.firebase.analytics.app com.yourapp.android
```

Events now upload in near-real time. In GA4, navigate to **Reports → DebugView** and select your device from the DEBUG DEVICE dropdown. The Seconds stream shows the last 60 seconds of events; the circular timeline covers the last 30 minutes. Click any event to inspect individual parameter values.

[Debug events | Google Analytics for Firebase](https://firebase.google.com/docs/analytics/debugview) confirms that debug-mode events are excluded from production reports and BigQuery exports, so QA testing never contaminates your live metrics. Disable debug mode as soon as validation is complete: `adb shell setprop debug.firebase.analytics.app .none.`

<Callout type="warning">
Never leave a test device in debug mode during a production demo or stakeholder review. All events from that device are silently excluded from Analytics reports — creating invisible data gaps that only appear when you notice the device's sessions have vanished from your funnels.
</Callout>

## GTM for Mobile: The Firebase Tag Type

Mobile GTM works differently from web GTM. Web containers fire HTTP requests to collection endpoints on each page load. Mobile GTM intercepts Firebase `logEvent()` calls and reroutes or extends them — enabling tag changes without an app store release.

The **Google Analytics: Firebase** tag type lets you define an event name, map parameters to DataLayer variables, set a trigger, and publish the container from the GTM web UI. On the next container refresh — defaulting to approximately 12 hours — the app downloads the updated container and the new tag is live. The first app launch after install uses a bundled default container before any live container has been fetched. Full setup details are in [Google Tag Manager for Android v5](https://developers.google.com/tag-platform/tag-manager/android/v5).

The non-negotiable limitation: auto-collected Firebase events (`first_open`, `session_start`, `screen_view`) cannot be blocked or suppressed via GTM. If you need to prevent them from reaching GA4, that requires changes in the app's SDK initialization code — not a GTM publish.

<KnowledgeCheck
  question="A product manager asks you to use GTM to stop 'session_start' events from appearing in GA4 without shipping a new app version. What is the correct answer?"
  options={[
    "This is not possible via GTM on mobile — auto-collected events cannot be blocked by the mobile GTM container; an SDK code change is required",
    "Create a blocking trigger in GTM that matches event name equals 'session_start' — this suppresses the event before it reaches GA4",
    "Unpublish the GTM container; with no active container, auto-collected events stop firing",
    "Add a custom dimension filter in GA4 Admin that excludes session_start from all reports"
  ]}
  correctIdx={0}
  explanation="Mobile GTM cannot block automatically collected Firebase events. They fire from the SDK regardless of GTM configuration. Suppressing them requires disabling auto-initialization in the app code itself."
/>

## Building Behavioral Audiences for Retargeting

GA4's behavioral audiences let you define retargeting lists based on in-app actions, not just demographic attributes. A "searched but did not book" audience for a travel app:

1. **Admin → Audiences → New Audience → Create custom audience**
2. Include users who triggered `search_initiated` at least once
3. Exclude users who triggered `purchase` at least once
4. Membership duration: 7 days (matching a typical booking consideration window)

GA4 backfills the audience with qualifying users from the past 30 days. Within 24–48 hours, the audience exports automatically to your linked Google Ads account, as detailed in [Share audiences in GA4 with linked advertising products](https://support.google.com/analytics/answer/12800258).

Before scheduling campaigns, open Google Ads Audience Manager and verify the audience size shows at least 100 active users in the past 30 days — the minimum threshold for ads to serve. Your GA4 audience view may show 2,500 users; Google Ads may show 900 after filtering for consent and identity signals. This divergence is expected: GA4 counts all users meeting the criteria, while Google Ads counts only remarketable users with advertising cookies and active Google signals.

## Funnel Explorations and Channel ROAS

Funnel Exploration — one of GA4's seven Explore techniques — sequences up to 10 user steps with up to 4 segment comparisons. For a travel app, an acquisition-to-revenue funnel maps five events:

| Step | Event | Label |
|------|-------|-------|
| 1 | `first_open` | Install |
| 2 | `session_start` (second session) | Return visit |
| 3 | `search_initiated` | Search |
| 4 | `hotel_view` | Hotel viewed |
| 5 | `purchase` | Booking complete |

Drag `First user source / medium` into the Breakdown slot to compare paid vs organic channels side-by-side. Add segment overlays — "Google Ads / CPC" vs "Organic / (none)" — to see where each channel drops off at each step, per the [GA4 Funnel exploration](https://support.google.com/analytics/answer/9327974) guide.

For channel-level ROAS, build a parallel Free-form exploration: rows by `First user medium`, metrics `Purchase revenue` and `Ad cost` (imported via linked Google Ads or cost-data import). Revenue ÷ Ad cost per row gives ROAS without leaving GA4.

## GA4 vs MMP: Two Attribution Lenses

GA4 and your MMP will never show identical install counts — and that is by design, not a bug. GA4 attributes `first_open` events using Google-observed signals: auto-tagging on Google Ads clicks and Firebase SDK data. It cannot see attribution signals from Meta App Ads, Apple Search Ads, or other non-Google networks unless an MMP relays them.

MMPs (Adjust, AppsFlyer, Branch, and similar tools covered in [[Mobile Attribution with AppsFlyer & Branch: Setup, Events & Privacy]]) operate their own SDK, apply cross-network attribution, and can use probabilistic matching for privacy-constrained environments where deterministic IDs are unavailable. They observe installs from networks Google cannot access.

The practical rule: use GA4 for in-app behavior analysis — funnels, retention cohorts, and custom event measurement. Use MMP data when making budget allocation decisions across paid channels, especially where non-Google networks are involved. Treating GA4 as your install-attribution source for multi-channel budget decisions will systematically over-credit Google channels.

---

## Hands-On Exercise

**Goal:** Build and validate a "searched but did not book" retargeting audience from scratch and confirm its Google Ads eligibility.

**Steps:**
1. In GA4 Admin → Audiences, create a custom audience that includes users who triggered `search_initiated` and excludes those who triggered `purchase`. Set membership duration to 7 days. Save.
2. Navigate to Reports → DebugView on a test device with ADB debug mode enabled. Trigger a search flow in your app and confirm `search_initiated` appears in the Seconds stream with the expected parameters.
3. After 24–48 hours, open Google Ads → Tools → Audience Manager. Locate the exported audience and check whether it shows ≥ 100 active users. Note the size difference between GA4's reported count and the Google Ads count; record your explanation for the gap.

**Success criteria:** The audience appears in Google Ads Audience Manager with status "Active" (not "Too small to serve"). You can explain in writing why the GA4 user count differs from the Google Ads count.

---

Next up: building the paid campaigns that consume these audiences — see [[Paid Mobile User Acquisition: Google App Campaigns & Meta App Ads]].
