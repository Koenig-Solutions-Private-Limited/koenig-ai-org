---
chapter_num: 3
course_slug: mobile-app-marketing-performance
title: "Mobile Attribution with AppsFlyer & Branch: Setup, Events & Privacy"
status: g3-passed
duration_min: 30
vendor_tag: AppsFlyer | Branch
learning_objectives:
  - "Select an MMP based on feature differences between AppsFlyer and Branch for a travel-tech context"
  - "Initialize the AppsFlyer SDK on iOS with correct ATT sequencing and on Android with AD_ID awareness"
  - "Build a correctly structured tracking link for Google UAC, Meta App Ads, and organic sources"
  - "Design a 5–10 event taxonomy that maps in-app actions to business outcomes"
  - "Explain the limitations of last-click, multi-touch, and SKAN attribution models"
  - "Configure Protect360 CTIT validation rules to block install flooding and click injection"
sources:
  - url: "https://dev.appsflyer.com/hc/docs/integrate-ios-sdk"
    title: "AppsFlyer iOS SDK Integration Guide"
  - url: "https://dev.appsflyer.com/hc/docs/install-android-sdk"
    title: "AppsFlyer Android SDK Installation Guide"
  - url: "https://dev.appsflyer.com/hc/docs/in-app-events-sdk"
    title: "AppsFlyer In-App Events SDK Guide"
  - url: "https://www.appsflyer.com/product/protect360/"
    title: "AppsFlyer Protect360 Ad Fraud Protection"
  - url: "https://developer.apple.com/documentation/apptrackingtransparency"
    title: "App Tracking Transparency — Apple Developer Documentation"
  - url: "https://help.adjust.com/en/article/how-skadnetwork-4-works"
    title: "How SKAdNetwork 4 Works — Adjust Help Center"
  - url: "https://www.branch.io/branch-vs-appsflyer/"
    title: "Branch vs AppsFlyer Comparison — Branch"
  - url: "https://support.appsflyer.com/hc/en-us/articles/218254203-Protect360-anti-fraud-guide"
    title: "Protect360 Anti-Fraud Guide — AppsFlyer Help Center"
  - url: "https://support.appsflyer.com/hc/en-us/articles/207447163-About-link-structure-and-parameters"
    title: "About Link Structure and Parameters — AppsFlyer Help Center"
owns:
  - "MMP selection criteria: AppsFlyer vs Branch feature comparison for a travel-tech use case"
  - "AppsFlyer SDK integration: iOS and Android setup, initialization, and first-launch event verification"
  - "Branch SDK integration: URI scheme, Universal Links, and App Links configuration"
  - "tracking link structure: UTM parameters, campaign naming conventions, ad network configuration"
  - "campaign source configuration for Google UAC, Meta App Ads, and organic — correct naming taxonomy"
  - "in-app event taxonomy design: defining 5–10 critical events (search, booking-initiated, purchase, etc.) mapped to business outcomes"
  - "event verification: confirming events fire correctly in the MMP dashboard and event log"
  - "attribution model comparison: last-click vs multi-touch vs SKAN/privacy-modeled data — what each can and cannot assert"
  - "iOS ATT (App Tracking Transparency) prompt: timing, consent rates, and impact on attribution completeness"
  - "Android Privacy Sandbox: topics API, protected audience, and attribution API implications for MMP data"
  - "SKAN (StoreKit Ad Network) attribution: postback windows, conversion value schema, limitations"
  - "attribution fraud detection: install flooding signal patterns and click injection signal patterns"
  - "fraud prevention settings in AppsFlyer: Protect360 configuration and block rules"
  - "MMP attribution report reading: channel breakdown, cohort view, and data confidence levels"
defers_to:
  - "GA4 Firebase-linked audiences and property setup → ch5"
  - "Google App Campaign and Meta App Ads campaign creation → ch6"
  - "post-install push notification deep links → ch4"
  - "unified cross-source reporting dashboard → ch7"
quiz_topics:
  - "three required components of a correctly structured AppsFlyer tracking link for a Google UAC campaign"
  - "difference between last-click attribution and SKAN privacy-modeled attribution — what each cannot assert"
  - "what install flooding looks like in an MMP attribution report and which Protect360 setting blocks it"
  - "how iOS ATT consent rate affects MMP data completeness and what modeled attribution fills the gap"
  - "why a 'search' in-app event needs to be mapped to a business outcome and not just tracked as a pageview"
notebooklm_source_focus:
  - "AppsFlyer SDK integration guide iOS and Android 2025–2026"
  - "Branch SDK setup Universal Links and App Links configuration guide"
  - "iOS App Tracking Transparency ATT prompt best practices and consent rates 2026"
  - "SKAdNetwork SKAN attribution conversion value schema and postback windows 2026"
  - "AppsFlyer Protect360 fraud detection install flooding and click injection guide"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which three elements must a correctly structured AppsFlyer tracking link include for Google UAC attribution to work?"
    options:
      - "pid=googleadwords_int, the c= campaign name parameter, and clickid={gclid} for deterministic install matching"
      - "utm_source=google, utm_medium=cpc, and a utm_campaign= value carrying the campaign name for Google attribution"
      - "pid=google_ads, the af_channel=UAC parameter, and an af_adset= value with the ad set name"
      - "pid=googleadwords_int, the af_c_id={campaignid} macro, and af_adset_id={adgroupid} for campaign and ad group ID reporting"
    correct_idx: 0
    explanation: "pid=googleadwords_int maps the install to the Google Ads partner integration; c= populates the campaign dimension in reporting; clickid={gclid} passes Google's click ID for deterministic click-to-install matching. UTM parameters alone are insufficient — AppsFlyer's priority chain reads pid= first."
    section_anchor: tracking-links-and-campaign-naming
  - question: "What is the fundamental difference between last-click attribution and SKAN privacy-modeled attribution in terms of what each cannot assert?"
    options:
      - "Last-click cannot attribute installs across multiple ad networks; SKAN cannot identify which user installed the app"
      - "Last-click credits only the final touchpoint and misses assist channels; SKAN reports aggregated cohort signals without individual user-level install data"
      - "Last-click attribution is limited to Android campaigns; SKAN only applies to iOS paid campaigns run on Meta"
      - "Last-click requires IDFA to function on iOS; SKAN requires GAID and breaks entirely when ATT consent is denied"
    correct_idx: 1
    explanation: "Last-click overattributes to the last ad click and cannot assert what assist channels contributed. SKAN postbacks are aggregated and anonymized — they cannot assert which individual user installed, only aggregate conversion signals by ad network and campaign."
    section_anchor: attribution-models-and-privacy-signals
  - question: "In an AppsFlyer MMP report, which pattern indicates install flooding, and which Protect360 configuration directly blocks it?"
    options:
      - "CTIT under 10 seconds from a single publisher IP; configure a device-blacklist rule in Protect360"
      - "Unusually high click volume with a long, variable CTIT distribution; enable a CTIT validation rule blocking installs where CTIT exceeds 24 hours"
      - "Post-install event rates near zero from an install cohort; enable Protect360 post-attribution detection window"
      - "Repeated device fingerprints across multiple install records; configure IP geo-blocking rules in Fraud Protection Studio"
    correct_idx: 1
    explanation: "Install flooding sends massive click volumes so a fraudulent click statistically lands nearest to an organic install — the tell is high click count with CTITs spread across implausible ranges, including many over 24 hours. Protect360's CTIT validation rule flags or blocks these outliers."
    section_anchor: fraud-detection-with-protect360
  - question: "A travel app's iOS ATT consent rate is 28%. How does this affect MMP attribution completeness, and what fills the data gap?"
    options:
      - "72% of iOS installs default to organic attribution; manual UTM log matching can restore most paid source data"
      - "IDFA is unavailable for 72% of users, reducing deterministic attribution; SKAN aggregated postbacks and probabilistic modeling partially fill the gap"
      - "The AppsFlyer SDK stops reporting data for ATT-denied users; Branch PAM automatically takes over attribution"
      - "Meta and Google pause delivery to ATT-denied devices automatically; attribution is incomplete but spend adjusts proportionally"
    correct_idx: 1
    explanation: "Without IDFA, AppsFlyer cannot deterministically match ad clicks to installs for the opted-out majority. SKAN postbacks provide aggregate cohort signals by ad network, and probabilistic modeling uses privacy-permitted device signals to partially recover attribution."
    section_anchor: attribution-models-and-privacy-signals
  - question: "Why must an af_search event be mapped to a business outcome before it can be used for paid campaign optimization?"
    options:
      - "Ad networks reject non-standard event names lacking outcome mapping, defaulting campaigns to CPM delivery"
      - "A raw search event gives the ad network's optimizer a noise signal that cannot separate high-booking-intent from low-intent searches"
      - "SKAN conversion values cannot encode search events in postback 1 without an outcome-mapped parameter attached"
      - "AppsFlyer's event log buffers only 40 offline events and drops unmapped events before network delivery"
    correct_idx: 1
    explanation: "af_search alone means 'user typed in the search box.' Without outcome context — for example, which searches correlate with a booking within 48 hours — the ad network's ML model cannot distinguish high-value users from aimless browsers and cannot target bids effectively."
    section_anchor: in-app-event-taxonomy
---

Before your first campaign goes live, one question determines whether your performance data will be trustworthy: which Mobile Measurement Partner (MMP) sits between your app and your ad networks? Get this right and installs become attributable, fraud-scrubbed, privacy-compliant signals. Get it wrong and every optimization decision downstream is silently corrupted.

## Choosing Your MMP: AppsFlyer vs Branch

AppsFlyer is the de-facto standard for travel-tech apps running Google UAC and Meta App Ads. It measures over 200,000 apps and tracks more than $28 billion in annual ad spend, giving its attribution graph deterministic matching power backed by signed integrations with every major ad network, including full [AppsFlyer Protect360](https://www.appsflyer.com/product/protect360/) fraud coverage. Branch holds less than 1% global attribution market share but excels as a deep-linking layer — its SDK-level Universal Links and App Links infrastructure is covered in this chapter; routing users to specific in-app screens post-install is deferred to ch4.

For a travel app with Google UAC, Meta App Ads, and a meaningful organic install base, AppsFlyer is the correct primary MMP. Branch adds Predictive Aggregate Measurement (PAM), claiming ~40% fewer missing iOS attribution claims than SKAN-only per [Branch vs AppsFlyer](https://www.branch.io/branch-vs-appsflyer/).

## SDK Integration

**iOS setup** requires two credentials before `start()` fires: `AppsFlyerLib.shared().appsFlyerDevKey` (your account-level key, shared across all apps) and `AppsFlyerLib.shared().appleAppID` (numeric App Store ID, no "id" prefix). On iOS 14.5+ you must call `waitForATTUserAuthorization(timeoutInterval: 60)` before `start()`. If `start()` fires first, the SDK sends attribution data without the IDFA — and that install is permanently attributed probabilistically; IDFA cannot be retroactively applied. Request the ATT prompt in `applicationDidBecomeActive` — after users experience app value, not on cold launch.

**Android setup** adds `af-android-sdk` and `installreferrer` to Gradle. From SDK v6.8.0 the `AD_ID` permission is auto-merged into the manifest; children's app developers must revoke it explicitly. Android attribution is more stable in 2026 than iOS: Google cancelled the Privacy Sandbox initiative on October 17, 2025, leaving GAID fully available and eliminating the previously planned migration to the Attribution Reporting API.

**Branch setup** requires a URI scheme fallback in both platform manifests and domain registration in the Branch dashboard. Branch auto-generates the Apple App Site Association (AASA) file for Universal Links and the `assetlinks.json` fingerprint for Android App Links, removing manual domain verification steps.

<KnowledgeCheck question="You call AppsFlyerLib.shared().start() in didFinishLaunchingWithOptions before requesting ATT authorization. What is the permanent consequence?" options={["The SDK crashes and requires a fresh app launch to recover", "That install session is attributed probabilistically; IDFA cannot be applied retroactively", "The ATT prompt is suppressed permanently on this device", "AppsFlyer logs a warning but applies IDFA when consent is later granted"]} correctIdx={1} explanation="Once start() fires, AppsFlyer sends the attribution request without IDFA. Even if the user grants ATT consent seconds later, that install event has already been processed with only probabilistic signals. Always call waitForATTUserAuthorization before start()." />

## Tracking Links and Campaign Naming

AppsFlyer's attribution priority chain reads `pid=` before any UTM parameter. A link with only `utm_source=google` may attribute installs to a generic "google" bucket that breaks ROAS reporting and auto-cost pulls, as documented in [About Link Structure and Parameters](https://support.appsflyer.com/hc/en-us/articles/207447163-About-link-structure-and-parameters).

Three components are required for a Google UAC link to work correctly: `pid=googleadwords_int` (the reserved partner ID), `c={campaign_name}` (populates the campaign dimension in reporting), and `clickid={gclid}` (enables deterministic click-to-install matching). For Meta App Ads use `pid=facebook_int`. Organic traffic receives `pid=organic` automatically — never construct an organic tracking link.

Parameter values are case-sensitive. `pid=GoogleAdwords_Int` is unrecognized; only the lowercase exact string maps to the Google Ads integration.

## In-App Event Taxonomy

Standard `af_` event names matter because ad networks use them to trigger conversion optimization signals. Naming an event `purchase_confirmed` instead of `af_purchase` causes Meta and Google optimizers to see zero conversion data and default to CPM delivery, inflating CPA without any visible error, per the [AppsFlyer In-App Events SDK Guide](https://dev.appsflyer.com/hc/docs/in-app-events-sdk).

For a travel app, define at minimum five events with explicit business outcome mappings:

| Event | Business outcome |
|---|---|
| `af_complete_registration` | Qualifies user as a real prospect; CAC denominator |
| `af_search` + `af_content_type=flight` | Users who search flights within 48h of install convert at 2–3× baseline |
| `af_initiated_checkout` | Funnel drop-off measurement; predicts booking probability |
| `af_purchase` + `af_revenue` | Direct revenue; required for ROAS campaign optimization |
| `af_content_view` | Engagement seed for lookalike audiences |

`af_search` without outcome context is a pageview wearing an event label. Attach a content type and downstream booking-rate measurement and it becomes the signal that tells your Meta ROAS campaign which users are worth bidding up.

Verify every event using the AppsFlyer Event Log dashboard within 24 hours of integration. Filter by your test device ID and confirm that each event name, parameter set, and timestamp are correct before any paid campaign launches.

<KnowledgeCheck question="Your team named the in-app event 'booking_started' instead of 'af_initiated_checkout'. What operational failure occurs?" options={["AppsFlyer returns a 400 error to the SDK and the event is dropped", "The ad network optimizer cannot map the non-standard name, defaulting to CPM delivery instead of event optimization", "The event fires but is attributed to organic regardless of the actual paid source", "AppsFlyer buffers the event but never delivers it once the offline 40-event cache fills"]} correctIdx={1} explanation="Non-standard event names fail to trigger ad network conversion-signal mappings. The campaign continues running, but the optimizer receives no relevant in-app event data and optimizes for impressions rather than the intended action — silently inflating CPA." />

## Attribution Models and Privacy Signals

Three attribution models coexist in every MMP report, and none is sufficient alone.

**Last-click** assigns 100% credit to the final click before install. It cannot assert assist-channel contributions: a Meta retargeting ad that re-engaged a lapsed user before a Google UAC click closed the install gets zero credit. Last-click is reliable for CPI benchmarking but misleads budget allocation decisions.

**Multi-touch** distributes credit across all touchpoints. Data-driven models require ≥600 monthly conversions; below that, rule-based models (linear or time-decay) are more stable.

**SKAN 4.0** is Apple's privacy-preserving framework for iOS. It cannot assert individual user-level install data — only aggregated cohort signals by ad network. Three asynchronous postbacks cover 35 days post-install: postback 1 (days 0–2) carries fine 6-bit conversion values (0–63); postbacks 2 and 3 (days 3–7 and 8–35) return only coarse tiers (`none/low/medium/high`). Design your conversion value schema before launch — changing it mid-campaign invalidates historical comparisons, per [How SKAdNetwork 4 Works](https://help.adjust.com/en/article/how-skadnetwork-4-works).

**iOS ATT and consent rates**: the global average ATT opt-in rate is ~35%. Apps showing a custom pre-permission screen before the system prompt reach 50–65% opt-in. Without IDFA, AppsFlyer falls back to SKAN aggregated data and probabilistic modeling for the opted-out majority.

<Callout type="warning">
Define your SKAN conversion value schema in AppsFlyer before your first iOS paid campaign launches. Installs recorded before the schema is saved contribute null or misinterpreted conversion values that cannot be corrected retroactively — the first days of campaign data are permanently unreliable.
</Callout>

## Fraud Detection with Protect360

Install flooding generates massive click volumes so a fraudulent click statistically lands nearest to an organic install moment. The signal in an MMP report is high click volume from a publisher with a long or variable CTIT distribution — specifically, CTITs exceeding 24 hours, which no legitimate campaign produces. Click injection (Android only) broadcasts a fake click milliseconds before an organic install completes; its signal is CTIT under 10 seconds.

Configure Protect360 with two CTIT validation rules: block installs where CTIT < 10 seconds (click injection) and flag installs where CTIT > 24 hours (flooding). Customers report a 66% fraud rate reduction and 90% decrease in post-attribution fraud after Protect360 activation, per the [Protect360 Anti-Fraud Guide](https://support.appsflyer.com/hc/en-us/articles/218254203-Protect360-anti-fraud-guide). Post-attribution detection covers up to 7 days, so installs that pass real-time rules can still be retroactively flagged and clawed back from publishers.

## Reading Your Attribution Reports

The channel breakdown report shows media source → campaign → ad set → creative with install counts, in-app event rates, and revenue per row. Cohort view adds D1/D7/D30 retention per acquisition source — use this to compare paid vs organic user quality, not just install volume.


---

**Hands-On Exercise**

Set up a test AppsFlyer tracking link for a Google UAC campaign in your staging environment:

1. Build the link with `pid=googleadwords_int`, a `c=` campaign name, and `clickid={gclid}`.
2. Click the link on a test device and complete an install.
3. Open the AppsFlyer Event Log and confirm `af_install` fired with the correct `pid` and `c` values.
4. Fire a test `af_search` event with parameter `af_content_type=flight` and verify it appears in the Event Log within 5 minutes.

**Success criteria**: Install attributed to `googleadwords_int`, `c` matches your campaign name, and `af_search` shows the `af_content_type=flight` parameter in the log.

---

Next: push notification and in-app message campaign design — [[04-push-notifications-in-app-messaging]].
