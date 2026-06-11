---
chapter_num: 6
course_slug: mobile-app-marketing-performance
title: "Paid Mobile User Acquisition: Google App Campaigns & Meta App Ads"
status: awaiting-g0
duration_min: 30
vendor_tag: "Google Ads / Meta Ads / AppsFlyer"
learning_objectives:
  - "Configure a Google App Campaign for installs with an asset group covering headlines, descriptions, images, HTML5, and video"
  - "Link Firebase/GA4 `first_open` and post-install events to Google Ads as key events for campaign attribution"
  - "Choose between tCPI and tCPA bidding, set correct targets, and know the 100-conversion graduation threshold"
  - "Read asset performance ratings (Learning/Low/Good/Best) from the Google Ads dashboard"
  - "Set up a Meta App Installs campaign and configure AEO for a purchase or booking-initiated event"
  - "Enable SKAdNetwork in Meta Events Manager and verify SKAN postback receipt in AppsFlyer"
  - "Build lapsed-user cohorts in AppsFlyer and configure re-engagement campaigns with deferred deep links"
  - "Diagnose campaign underperformance using the MMP install-to-event funnel and apply two creative and two audience tactics"
sources:
  - url: "https://support.google.com/google-ads/answer/6247380"
    title: "About App campaigns - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/6310436"
    title: "About asset reporting for App campaigns - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/7100895"
    title: "About bidding in App campaigns - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/12073727"
    title: "Choose a bid strategy for your App campaign - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/14104492"
    title: "Best practices for App campaigns - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/6366292"
    title: "GA4 Measure and optimize App campaign performance - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/9234102"
    title: "Create an App campaign for engagement - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/16420273"
    title: "About deferred deep linking - Google Ads Help"
  - url: "https://developers.facebook.com/docs/app-ads/overview"
    title: "Overview - Facebook App Ads - Meta for Developers"
  - url: "https://en-gb.facebook.com/business/help/2308889442692949"
    title: "About app event optimisation - Meta Business Help Centre"
  - url: "https://www.facebook.com/business/help/670955636925518"
    title: "Configure SKAdNetwork in Meta Events Manager - Meta Business Help"
  - url: "https://support.appsflyer.com/hc/en-us/articles/360017095198-SKAdNetwork-SKAN-interoperation-with-Meta-ads"
    title: "SKAdNetwork (SKAN) interoperation with Meta ads - AppsFlyer Help Center"
  - url: "https://support.appsflyer.com/hc/en-us/articles/207040496-Cohort-and-retention-dashboard"
    title: "Cohort and retention dashboard - AppsFlyer Help Center"
  - url: "https://support.appsflyer.com/hc/en-us/articles/207033786-Retargeting-attribution-guide"
    title: "Retargeting attribution guide - AppsFlyer Help Center"
  - url: "https://www.appsflyer.com/blog/trends-insights/optimizing-path-install-conversion/"
    title: "CTR, CTI, and IPM: Optimizing the path to install conversion - AppsFlyer Blog"
owns:
  - "Google App Campaign structure: installs objective, asset groups — headlines, descriptions, images, HTML5, and video"
  - "Firebase/GA4 conversion event linking to Google App Campaign for install attribution"
  - "Google App Campaign bidding: tCPI vs tCPA post-install — when to use each and how to set targets"
  - "asset group quality signals: what the Google Ads dashboard shows about creative performance"
  - "Meta App Ads campaign structure: app installs objective, ad set, and ad-level creative"
  - "SKAdNetwork integration for Meta App Ads: enabling SKAN, verifying postback receipt in AppsFlyer"
  - "App Event Optimization (AEO) in Meta beyond installs: configuring purchase or booking-initiated as the optimization goal"
  - "re-engagement campaign setup on Google (re-engagement app campaign type) or Meta (app re-engagement objective)"
  - "deferred deep links in re-engagement campaigns: routing lapsed users to a specific in-app flow"
  - "MMP cohort data usage for re-engagement targeting: identifying lapsed user segments via AppsFlyer cohort reports"
  - "campaign diagnosis methodology: using MMP install-to-event funnel to pinpoint creative vs audience vs landing-experience drop-offs"
  - "two creative adjustment tactics and two audience adjustment tactics backed by funnel data"
  - "CPI, CPM, CTR, ITR (install-to-event rate) as paid UA diagnostic metrics"
defers_to:
  - "MMP SDK setup and AppsFlyer attribution configuration → ch3"
  - "GA4 Firebase-linked audience creation → ch5"
  - "push notification re-engagement campaigns → ch4"
  - "unified cross-source reporting dashboard → ch7"
  - "ASO store listing quality for landing paid traffic → ch2"
quiz_topics:
  - "which Firebase/GA4 conversion event type Google App Campaigns require and how to link it in the Google Ads UI"
  - "what SKAdNetwork postback receipt in AppsFlyer confirms about a Meta App Ads campaign"
  - "difference between Google App Campaign tCPI bidding and tCPA post-install bidding and when to graduate between them"
  - "how to identify that a re-engagement campaign underperformance is a creative issue vs an audience targeting issue using MMP funnel data"
  - "what App Event Optimization (AEO) for purchase means for Meta campaign delivery vs standard app installs objective"
notebooklm_source_focus:
  - "Google App Campaigns installs and tCPA bidding setup guide 2025–2026"
  - "Meta App Ads SKAdNetwork integration and App Event Optimization documentation 2026"
  - "AppsFlyer cohort analysis for lapsed user re-engagement targeting guide"
  - "Google App Campaign re-engagement campaign type setup and deferred deep links"
  - "Meta App Ads campaign diagnosis using MMP install-to-event funnel data"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which Firebase/GA4 event must be imported into Google Ads as a conversion action before a Google App Campaign for installs can attribute installs correctly?"
    options:
      - "session_start, because it fires at the start of every new user session after app install"
      - "first_open, because it fires the first time a user opens the app after installation"
      - "app_install, a custom event you define in GA4 Admin to signal the install"
      - "user_engagement, because it fires when the user has interacted meaningfully with the app"
    correct_idx: 1
    explanation: "Google App Campaigns require the `first_open` event — auto-collected by the Firebase SDK on the first app launch after installation — as the install attribution conversion signal. It must be marked as a key event in GA4, linked to Google Ads, with auto-tagging enabled."
    section_anchor: linking-firebasega4-for-install-attribution
  - question: "After checking AppsFlyer's SKAN postbacks filtered by Meta, you see a postback with a valid attribution-signature and a decoded conversion value. What does this confirm?"
    options:
      - "The iOS user consented to ATT tracking and full user-level IDFA data is now available for attribution"
      - "The install occurred on a real device, Apple verified the Meta network ID, and the conversion value was not manipulated"
      - "The campaign's tCPA bid is correctly calibrated and the SKAN conversion window aligns with the target event"
      - "Meta's Aggregated Event Measurement configuration is correctly set up and reporting iOS install conversion data"
    correct_idx: 1
    explanation: "A validated SKAN postback in AppsFlyer confirms three things: the install was on a real device, Apple recognized the Meta ad network ID, and the conversion value wasn't tampered with. SKAN is aggregated by design — it does not restore user-level data regardless of ATT consent."
    section_anchor: meta-app-ads-campaign-structure-and-skadnetwork
  - question: "Your Google App Campaign for installs has accumulated 120 post-install purchase events. You want to shift optimization from install volume to purchases. What is the correct approach?"
    options:
      - "Add purchase as a second conversion action alongside first_open so the algorithm optimizes for both simultaneously"
      - "Switch to tCPA targeting the purchase event, set the opening tCPA bid 20% above the observed actual CPA"
      - "Switch to tCPA immediately at your maximum acceptable CPA to capture the highest-quality users first"
      - "Keep tCPI but raise the bid by 50% to attract higher-intent users who are more likely to purchase"
    correct_idx: 1
    explanation: "Graduate to tCPA after ≥100 post-install conversions. Set the opening tCPA bid at ~20% above the observed actual CPA from the tCPI phase. Never target multiple actions under one tCPA campaign — that creates a blended target and degrades delivery for high-value events."
    section_anchor: google-app-campaign-bidding-tcpi-vs-tcpa
  - question: "Your Meta App Ads campaign shows high CTR but low install-to-event rate (ITR) for hotel bookings. What does this pattern indicate?"
    options:
      - "The creative is weak — users are not clicking on the ad at sufficient rate"
      - "The audience is correct and the creative works, but post-install onboarding or paywall friction is losing users"
      - "The CPM is too high, causing the algorithm to deliver to a narrow low-quality audience"
      - "SKAdNetwork postbacks for this campaign are not arriving or decoding correctly in AppsFlyer"
    correct_idx: 1
    explanation: "High CTR means the creative is engaging the right users. Low ITR means users are installing but not converting inside the app. The funnel break is post-install — onboarding friction, paywall design, or creative-audience mismatch where clicks do not match purchase intent."
    section_anchor: campaign-diagnosis-using-the-install-to-event-funnel
  - question: "What is the primary difference between running a Meta App Ads campaign with the App Installs objective vs switching the optimization goal to App Event Optimization (AEO) for purchase?"
    options:
      - "AEO bills on CPC rather than CPM, making it more cost-efficient at small budgets"
      - "AEO changes delivery to target users predicted to complete a specific in-app event rather than users predicted to install"
      - "AEO disables SKAdNetwork entirely and switches to direct IDFA-based user-level attribution for iOS campaigns"
      - "AEO is available only on Android because Apple's ATT blocks purchase signal for iOS delivery"
    correct_idx: 1
    explanation: "AEO changes Meta's delivery algorithm from 'find users likely to install' to 'find users likely to perform the specified in-app event (e.g., purchase).' Both objectives bill on CPM. AEO requires the target event to be mapped in Meta Events Manager and listed in the SKAN event priority configuration for iOS."
    section_anchor: app-event-optimization-aeo-going-beyond-installs
---

## Google App Campaign Structure and Asset Groups

Google App Campaigns for Installs (ACi) take creative ingredients, not manually assembled ads. Supply up to 20 assets per type: headlines (30 chars), descriptions (90 chars), landscape images (1.91:1) and square (1:1), HTML5 bundles, and video. Google's ML assembles combinations across Search, Play, YouTube, Display, Discover, and Gmail. ([About App campaigns - Google Ads Help](https://support.google.com/google-ads/answer/6247380))

Within the campaign, an **asset group** holds all creative elements plus audience signals. The dashboard rates each asset in a rolling 14-day window as **Learning** (insufficient data), **Low**, **Good**, or **Best** — relative to other assets of the same type in the same campaign. "Low" means the asset consistently loses internal comparisons; replace it rather than wait for it to recover. ([About asset reporting for App campaigns - Google Ads Help](https://support.google.com/google-ads/answer/6310436))

<KnowledgeCheck question="An asset in your Google App Campaign asset group is rated 'Low' after two weeks. What does this mean?" options={["It has insufficient data and is still learning", "It performs below the median for its asset type within this campaign", "Google has automatically paused it to protect budget", "It has zero clicks and must be manually removed"]} correctIdx={1} explanation="Asset ratings compare performance relative to other assets of the same type in the same campaign, over a 14-day window. 'Low' means it loses those internal comparisons. 'Learning' is the insufficient-data state." />

## Linking Firebase/GA4 for Install Attribution

Google App Campaigns require a specific conversion signal: the `first_open` event, auto-collected by the Firebase SDK the first time a user opens the app after installation. Link it in four steps:

1. In **GA4 Admin → Events**, mark `first_open` as a **key event**.
2. Also mark your target post-install event — `purchase` or `hotel_booking_completed` — as a key event now, so it's ready when you graduate to tCPA bidding.
3. In **GA4 Admin → Google Ads Links**, connect the GA4 property and enable **auto-tagging** — without it, conversions will not appear in Google Ads.
4. In **Google Ads: Goals → Summary → Create conversion action → Import from GA4** → select `first_open`, set a 30-day conversion window. ([GA4 Measure and optimize App campaign performance - Google Ads Help](https://support.google.com/google-ads/answer/6366292))

## Google App Campaign Bidding: tCPI vs tCPA

**tCPI (Target Cost Per Install)** targets a set average cost per install. Use tCPI when building install volume from scratch. The daily budget must be **≥50× the tCPI bid** — at a $4 tCPI, the minimum daily budget is $200. For iOS, set bids 1.5× higher than Android to account for ATT consent losses.

**Graduate to tCPA (Target Cost Per Action)** — targeting a post-install event like `hotel_booking_completed` — when the campaign has accumulated **>100 post-install conversion events**. Set the opening tCPA bid at 20% above the observed actual CPA from the tCPI phase. Budget minimum shifts to ≥10× the tCPA bid. Never target more than one in-app action per tCPA campaign — combining events creates a blended target that under-delivers on high-value conversions. ([Choose a bid strategy for your App campaign - Google Ads Help](https://support.google.com/google-ads/answer/12073727))

<Callout type="warning">
Switching from tCPI to tCPA before 100 post-install conversions resets the learning phase and causes erratic delivery — typically doubling effective CPI for two to three weeks. Hold tCPI until the install volume supports the transition. ([Best practices for App campaigns - Google Ads Help](https://support.google.com/google-ads/answer/14104492))
</Callout>

## Meta App Ads Campaign Structure and SKAdNetwork

Meta App Ads use a three-tier structure: **Campaign** (App Installs) → **Ad Set** (audience, budget, optimization) → **Ad** (creative). Installs and AEO both bill on CPM.

For iOS, **SKAdNetwork (SKAN)** is the privacy-preserving attribution layer, limiting reportable data to 8 of 63 possible per-app events. Before launch, set SKAN priority in **Meta Events Manager → App → iOS App Settings → Aggregated Event Measurement**: place your AEO target event (e.g., `fb_mobile_purchase`) as priority 1. ([Configure SKAdNetwork in Meta Events Manager - Meta Business Help](https://www.facebook.com/business/help/670955636925518))

Verify in **AppsFlyer** ([[03-mobile-attribution-appsflyer-branch]]): Reports → SKAN → Postbacks, filtered by Meta. A valid postback with a decoded CV confirms the install was on a real device, Apple recognized Meta's network ID, and the CV was not tampered with. ([SKAdNetwork (SKAN) interoperation with Meta ads - AppsFlyer Help Center](https://support.appsflyer.com/hc/en-us/articles/360017095198-SKAdNetwork-SKAN-interoperation-with-Meta-ads))

<KnowledgeCheck question="You're launching a Meta iOS App Ads campaign. Why must you configure the SKAN event priority list in Meta Events Manager before launch?" options={["SKAN blocks all ad delivery until the priority list is submitted to Apple", "SKAN limits iOS to 8 reportable events — if your AEO target event is not prioritized, Meta cannot report or optimize on it", "The priority list sets the iOS bid floor for each conversion event", "Without a priority list, AppsFlyer cannot receive any iOS postbacks from Meta"]} correctIdx={1} explanation="SKAN restricts an app to 8 usable conversion events from 63 possible. If the AEO target event isn't in that priority list before campaign launch, Meta's algorithm has no signal to optimize delivery against for iOS users." />

## App Event Optimization (AEO): Going Beyond Installs

AEO shifts delivery from targeting users likely to install to users predicted to complete a specific in-app event — purchase, initiated checkout, subscribe, and others. Configure at the **ad set level**: Optimization & Delivery → App Events → select target event.

Ensure the event is mapped in Meta Events Manager before launching. Without a standard event mapping, the delivery algorithm has no training signal. ([About app event optimisation - Meta Business Help Centre](https://en-gb.facebook.com/business/help/2308889442692949))

## Re-engagement Campaigns and Deferred Deep Links

To retarget lapsed users on Google, use **App Campaign for Engagement (ACe)** — requiring ≥50,000 installs and working deep links. Select the "Re-engage non-purchasers" or "Re-engage lapsed users" (inactive 7+ days) objective. Add a **deferred deep link** via the Firebase SDK (e.g., `/hotels?promo=welcome_back`) to queue the destination before first open, routing returning users to the relevant screen. ([About deferred deep linking - Google Ads Help](https://support.google.com/google-ads/answer/16420273))

Build the lapsed-user audience in **AppsFlyer Cohort Report**: filter by `install_date`, target event completions = 0, activity window = last 180 days. Export as a Customer Match list for Google Ads. Set AppsFlyer's **retargeting inactivity window** to 7 days to exclude recently active users; push notification re-engagement is in [[04-push-notifications-in-app-messaging]]. ([Retargeting attribution guide - AppsFlyer Help Center](https://support.appsflyer.com/hc/en-us/articles/207033786-Retargeting-attribution-guide))

## Campaign Diagnosis Using the Install-to-Event Funnel

When performance drops, trace the four-stage funnel using MMP data:

| Funnel Stage | Metric | Low Signal Means |
|---|---|---|
| Impression → Click | CTR | Creative is failing to engage the audience |
| Click → Install | CVR | App store listing friction or audience-creative mismatch |
| Install → Target Event | ITR | Poor user quality, onboarding friction, or paywall design |

**Two creative adjustment tactics:**
1. In the Google Ads asset report, swap all "Low"-rated assets with variants using a different visual style — user testimonial video instead of a feature-demo screen recording.
2. If CTR is high but ITR is low, narrow the creative message to match the conversion goal: "Save 30% on your next hotel booking" targets purchase intent; "Book Hotels Anywhere" does not.

**Two audience adjustment tactics:**
1. In Meta, replace broad interest targeting with a lookalike built from past-90-day `fb_mobile_purchase` completers — not all-time installers — for tighter ITR gains. Firebase audience setup is in [[05-mobile-analytics-ga4-gtm]].
2. In the AppsFlyer cohort report, identify media sources where Day-7 ITR is below 2% and add them to exclusion lists in both Google and Meta.

---

## Hands-On Exercise

**Objective:** Configure a Google App Campaign for installs on a travel app and verify the Firebase/GA4 attribution link.

**Steps:**
1. In GA4 Admin → Events, mark `first_open` and `hotel_booking_completed` as key events.
2. Create a GA4 → Google Ads link; confirm auto-tagging is enabled.
3. In Google Ads, import `first_open` as a conversion action with a 30-day window.
4. Create an App campaign for installs with one asset group: 3 headlines, 2 descriptions, 3 images (1.91:1 and 1:1), and 2 video assets (one under 15 seconds).
5. Set a tCPI bid where your daily budget is at least 50× the bid.

**Success criteria:** The conversion action status in Google Ads shows "Recording conversions" within 48 hours of first install attributed to the campaign. The asset group shows at least one asset rated "Good" or "Best" after 14 days of delivery.

Next chapter covers the unified reporting layer that joins AppsFlyer cohort data with GA4 behavioral data across every channel you've now set up: [[07-measuring-reporting-performance-end-to-end]]
