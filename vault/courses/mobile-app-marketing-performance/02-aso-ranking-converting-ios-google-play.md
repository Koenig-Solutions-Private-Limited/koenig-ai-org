---
chapter_num: 2
course_slug: mobile-app-marketing-performance
title: "App Store Optimization (ASO): Ranking & Converting on iOS and Google Play"
status: g0-blocked
last_updated: 2026-06-11
duration_min: 20
vendor_tag: App Store / Google Play
learning_objectives:
  - "Write keyword-optimized metadata for both App Store and Google Play within correct character limits and 2026 indexing rules"
  - "Design screenshots that pass the 3-second visual test and comply with device-framing standards"
  - "Set up and interpret a Google Play Store Listing Experiment and an Apple Custom Product Page test"
  - "Identify the correct in-app moment to solicit reviews and respond to negative feedback effectively"
  - "Select the right ASO tool (AppTweak, AppFollow, Sensor Tower) for a given research need"
sources:
  - url: "https://developer.apple.com/app-store/search/"
    title: "App Store Search — Apple Developer"
  - url: "https://developer.apple.com/app-store/custom-product-pages/"
    title: "Custom Product Pages — App Store — Apple Developer"
  - url: "https://support.google.com/googleplay/android-developer/answer/12053285?hl=en"
    title: "Run A/B Tests on Your Store Listing — Play Console Help"
  - url: "https://phiture.com/asostack/aso-trends-in-2026/"
    title: "ASO Trends in 2026 — Phiture"
  - url: "https://www.apptweak.com/en/aso-blog/app-store-ranking-factors"
    title: "What Are the Top App Store Ranking Factors? — AppTweak"
  - url: "https://appfollow.io/blog/aso-screenshots-best-practices"
    title: "ASO Screenshots: 2026 Best Practices — AppFollow"
owns:
  - "keyword-optimized metadata for App Store: title (30 chars), subtitle (30 chars), keyword field (100 chars) — 2026 indexing rules"
  - "keyword-optimized metadata for Google Play: title (30 chars), short description (80 chars), long description (4000 chars) — 2026 indexing rules"
  - "iOS vs Google Play metadata differences: indexing mechanics, field weights, and limits"
  - "screenshot set design: 3-second visual test, OCR-readable captions indexed by Apple, device-framing conventions"
  - "app preview video production: autoplay standards, first-3-second retention rule, localization considerations"
  - "Google Play Store Listing Experiments: setup, statistical significance thresholds, and interpreting test results"
  - "Apple Custom Product Pages: creation, audience targeting, and A/B testing creatives"
  - "review solicitation timing: correct in-app moment (post-positive action) vs negative-friction moments to avoid"
  - "responding to negative reviews: response templates, escalation criteria, and impact on rating"
  - "rating trend monitoring via App Store Connect and Google Play Console dashboards"
  - "ASO tools landscape: Sensor Tower, AppFollow, AppTweak — use cases and data types"
defers_to:
  - "paid UA campaigns driving traffic to store listings → ch6"
  - "MMP tracking links for install attribution from ASO traffic → ch3"
  - "deep links routing post-install users to specific in-app screens → ch4"
  - "GA4 reporting on install sources and conversion funnels → ch5"
quiz_topics:
  - "maximum character limits for the iOS title, subtitle, and keyword fields — and which fields Apple indexes"
  - "how Google Play's short description differs from the iOS subtitle in terms of indexing weight"
  - "what the 3-second visual test means for screenshot design and how OCR captions affect App Store indexing"
  - "how to determine statistical significance in a Google Play Store Listing Experiment"
  - "the correct in-app moment to trigger a rating prompt and why post-booking is better than post-launch"
notebooklm_source_focus:
  - "App Store Connect and Google Play Console metadata guidelines 2026"
  - "iOS App Store keyword field indexing mechanics and 2026 algorithm updates"
  - "Google Play Store Listing Experiments setup and statistical analysis guide"
  - "Apple Custom Product Pages creation and A/B testing documentation"
  - "ASO screenshot design best practices and OCR caption indexing for iOS 2026"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which three fields does Apple index for App Store keyword search?"
    options:
      - "Title, full description, and keyword field"
      - "Title, subtitle, and keyword field"
      - "Title, subtitle, and full description"
      - "Subtitle, keyword field, and promotional text"
    correct_idx: 1
    explanation: "Apple indexes only the title (30 chars), subtitle (30 chars), and keyword field (100 chars). The full description, promotional text, and release notes have no effect on keyword ranking."
    section_anchor: ios-metadata-three-fields-three-rules
  - question: "How does Google Play's short description (80 chars) differ from the iOS subtitle (30 chars) in indexing mechanics?"
    options:
      - "The iOS subtitle is not indexed; Google Play's short description is indexed by Google"
      - "Both are indexed, but Google Play has no hidden keyword field — the long description carries keyword depth instead"
      - "The iOS subtitle carries less weight per character; the short description carries higher indexing weight"
      - "Both carry equal keyword weight; the only meaningful difference is their character count allocations"
    correct_idx: 1
    explanation: "Both fields are indexed, but the key structural difference is that Google Play offers no hidden keyword field — keyword depth lives in the 4,000-character long description. iOS splits keyword surface into a public subtitle and a hidden keyword field."
    section_anchor: google-play-metadata-different-mechanics
  - question: "What does the 3-second visual test evaluate for App Store screenshots?"
    options:
      - "Whether screenshot file sizes comply with Apple's technical upload specifications per device"
      - "Whether the first 1–3 screenshots communicate the app's core value before a user scrolls past"
      - "Whether on-screen captions pass Apple's automated OCR keyword-match threshold at review time"
      - "Whether the app preview video's poster frame loads within three seconds on a mobile data connection"
    correct_idx: 1
    explanation: "The 3-second test is a conversion heuristic: users spend roughly 1–3 seconds scanning search results before deciding to tap or scroll. The first three screenshots must convey the core value proposition at thumbnail scale within that window."
    section_anchor: screenshots-that-pass-the-3-second-test
  - question: "When does Google Play declare a Store Listing Experiment winner?"
    options:
      - "After 14 days of runtime, regardless of whether statistical significance has been reached"
      - "When one variant reaches 90% confidence via jackknife resampling, then auto-stops 14 days later"
      - "When the developer manually stops the test after observing a consistent uplift in install rates"
      - "After 6 weeks of runtime using a t-test applied to total install volume at 95% confidence"
    correct_idx: 1
    explanation: "Google Play uses jackknife resampling plus sequential probability ratio testing at a 90% confidence threshold. Once significance is declared, the experiment auto-stops 14 days later. Developers must apply the winning variant within that window."
    section_anchor: testing-creatives-play-experiments-and-apple-cpps
  - question: "A travel app is deciding when to trigger an iOS rating prompt. Which moment is most effective?"
    options:
      - "Immediately after the app first launches, while the user's initial curiosity is at its peak"
      - "After the user successfully completes a flight booking, when positive affect about the app is highest"
      - "After the user dismisses the onboarding tutorial and sees the home screen for the first time"
      - "Before displaying the subscription paywall, to capture ratings from users who are engaged and willing to pay"
    correct_idx: 1
    explanation: "Post-positive-action moments — like completing a booking — maximize rating response quality because user satisfaction is highest. Post-launch, post-onboarding, and pre-paywall prompts hit users before they've experienced real value or in contexts that create negative associations."
    section_anchor: reviews-and-ratings-as-aso-levers
---

The store listing is your silent salesperson — it works 24/7 and determines whether search traffic converts into installs or bounces. This chapter gives you exact character budgets, creative standards, and testing workflows for both iOS and Google Play in 2026.

## iOS Metadata: Three Fields, Three Rules

Apple indexes exactly three text fields for keyword search: the **title** (30 characters), **subtitle** (30 characters), and **keyword field** (100 characters). The full description, promotional text, and release notes have zero effect on search ranking. [App Store Search — Apple Developer](https://developer.apple.com/app-store/search/)

Three rules govern how you allocate those characters:

**Rule 1: Never duplicate across fields.** If "timer" appears in your title, repeating it in the subtitle or keyword field wastes those characters permanently. The App Store awards no bonus relevance for repetition.

**Rule 2: The subtitle is prime real estate.** It carries the second-highest keyword weight after the title and is displayed below the app name in search results. Use it for a high-value keyword phrase — not tagline copy or brand voice.

**Rule 3: The keyword field is comma-separated, no spaces after commas.** `pomodoro,focus,timer` is correct; `pomodoro, focus, timer` wastes three characters on spaces. Spaces between words within a phrase are fine. With only 100 characters, every space is a keyword you didn't write.

The [promotional text](https://developer.apple.com/app-store/product-page/) field (170 characters) can be updated without a new app submission — useful for seasonal offers — but has no effect on ranking.

## Google Play Metadata: Different Mechanics

Google Play surfaces three fields, but they work differently. The **title** (30 characters) carries the highest weight per character. The **short description** (80 characters) is indexed and shown in search result cards — it is both a conversion and an indexing surface. The **long description** (4,000 characters) is fully indexed and functions as your primary keyword depth layer, the functional equivalent of the iOS keyword field but public-facing.

The critical difference: Google Play has no hidden keyword field. Keyword strategy must live in readable prose. Keyword spamming — pipe-separated lists, repeated phrases, ALL-CAPS terms — violates [Google Play Metadata Policy](https://support.google.com/googleplay/android-developer/answer/9898842?hl=en) and can trigger listing removal. Embed target keywords naturally in the first sentence of the long description and in each feature bullet.

<KnowledgeCheck
  question="You're optimizing a travel app on iOS. Where should you NOT place keywords for search ranking purposes?"
  options={["Title (30 characters)", "Subtitle (30 characters)", "Keyword field (100 characters)", "Full description"]}
  correctIdx={3}
  explanation="Apple indexes only the title, subtitle, and keyword field. The full description, promotional text, and release notes carry zero keyword ranking weight — time spent optimizing those fields is misallocated."
/>

## Screenshots That Pass the 3-Second Test

Screenshots are displayed at thumbnail scale in search results. The **3-second visual test** is a design heuristic: the first 1–3 screenshots must communicate your app's core value proposition within the 3 seconds a user spends scanning before tapping in or scrolling past.

Two practical rules for screenshot design:

**Caption clarity at scale.** OCR-readable captions are treated as a keyword-aware surface by most ASO practitioners, following observed ranking shifts since June 2025 — Apple officially confirms indexing only the title, subtitle, and keyword field. Write captions that carry the page's benefit promise even at thumbnail resolution. The "squint test" is reliable: zoom out until your screenshot is postage-stamp size and check whether hierarchy and text remain legible. [ASO Trends 2026 — Phiture](https://phiture.com/asostack/aso-trends-in-2026/) The top-grossing app analysis from AppFollow found the first three screenshot frames account for roughly 70% of conversion weight. [ASO Screenshots 2026 — AppFollow](https://appfollow.io/blog/aso-screenshots-best-practices)

**Device framing conventions.** Use the correct dimensions per device: iPhone 6.9" requires 1320×2868 px; iPad requires its own set, not stretched phone screenshots. Submitting incorrect dimensions or cross-device reuse is a common reason for App Store review rejection.

## App Preview Videos

iOS app previews autoplay muted at up to 30 seconds — audio activates only when the user unmutes. Google Play promo videos require a public or unlisted YouTube URL; only the first 30 seconds autoplay muted, and **core features must appear within the first 10 seconds**.

For Google Play, portrait format yields 7% higher watch time and 5% better conversion than landscape for most app categories. Localization matters: since autoplay is muted, any voiceover is inaudible — translate or localize on-screen text overlays for international markets rather than relying on dubbed audio tracks.

<KnowledgeCheck
  question="A developer's Google Play promo video shows the app's booking flow for the first time at the 18-second mark. What is the likely conversion impact?"
  options={["Positive — a longer setup builds context before the CTA", "Neutral — users who want to convert will watch the full 30 seconds", "Negative — core features must appear within the first 10 seconds to catch autoplaying viewers", "No impact — the video is muted, so feature visibility doesn't affect conversion rate"]}
  correctIdx={2}
  explanation="Google Play requires core features within the first 10 seconds of the promo video. Most users watching the muted autoplay preview will not reach the 18-second mark, so the booking flow — the app's key value — is missed entirely."
/>

## Testing Creatives: Play Experiments and Apple Custom Product Pages

**Google Play Store Listing Experiments** let you A/B test icons, feature graphics, screenshots, and description text across up to 3 variants. The platform uses jackknife resampling plus sequential probability ratio testing at a **90% confidence threshold**. Once significance is declared, the experiment auto-stops 14 days later — apply the winning variant within that window. Check both conversion rate and 1-day retention for each variant; a higher-converting icon that attracts low-quality installs is a false win. [Run A/B Tests — Play Console Help](https://support.google.com/googleplay/android-developer/answer/12053285?hl=en)

**Apple Custom Product Pages (CPPs)** allow up to 70 alternative versions of your App Store product page, each with different screenshots, promotional text, and/or app previews. Since July 2025, CPPs assigned specific keywords can appear in organic search results for those terms — making CPPs a core ASO lever, not just a paid campaign landing page. Apple's internal benchmark shows an average 2.5 percentage point conversion uplift for CPP-targeted traffic. [Custom Product Pages — Apple Developer](https://developer.apple.com/app-store/custom-product-pages/)

<Callout type="warning">
Never stop a Google Play Listing Experiment early because a variant "looks like it's winning." Jackknife resampling corrects for continuous monitoring bias — but only if you wait for the formally declared winner. Pulling results early (peeking) inflates false-positive rates and risks applying variants that regress conversion once traffic normalizes.
</Callout>

## Reviews and Ratings as ASO Levers

Apps with ratings below 3.5 stars face reduced visibility in App Store search results, making rating trend an active ranking variable, not just a reputation metric. [What Are the Top App Store Ranking Factors? — AppTweak](https://www.apptweak.com/en/aso-blog/app-store-ranking-factors)

**Solicitation timing.** iOS limits you to three `requestReview()` calls per device per 365 days — calls beyond that cap are silently ignored. Use them after high-positive-affect moments: a completed flight booking, a streak milestone, or the fifth session. Never prompt at app launch, after an error, or immediately before a paywall.

**Responding to negative reviews.** Specific, issue-focused responses notify the reviewer and frequently result in an upward rating update. Template copy ("We appreciate your feedback!") that doesn't address the specific complaint is visible to all potential customers and signals poor support quality. Escalate — using "Report a Concern" in App Store Connect — rather than publicly reply to reviews containing offensive language, spam, or Terms of Service violations.

**Monitoring.** Check rating trend weekly in App Store Connect and Google Play Console alongside the current average. A declining 7-day trend predicts aggregate rating erosion before it becomes visible to users browsing the store.

## ASO Tools Landscape

Choose based on your primary research need:

- **AppTweak** (mid-to-enterprise): pulls keyword volume directly from Apple's Search Popularity API — the most accurate iOS keyword research available. Best for metadata strategy and competitive keyword gap analysis.
- **AppFollow** (SMB-to-mid): optimized for review management automation with 30+ CRM integrations. Best for teams where review response speed and volume are tracked KPIs.
- **Sensor Tower** (enterprise): competitive intelligence across downloads, revenue, and advertising spend across global markets. Use when you need market-level benchmarking beyond your own listing.

---

## Hands-On Exercise: iOS Keyword Field Audit

**Task:** Take any live iOS app you have App Store Connect access to (or use a public competitor's listing you can analyze in AppTweak).

1. Extract every unique word in the current title and subtitle.
2. Open the keyword field and highlight every word already present in step 1 — each duplicate is a wasted character allocation.
3. Source replacement terms from your ASO tool's keyword suggestions, filtering for terms with Search Popularity Score ≥ 30.
4. Rewrite the keyword field replacing all duplicates with new terms, keeping the total to 100 characters or fewer with no spaces after commas.
5. **Success criteria:** Zero duplicated words across title, subtitle, and keyword field; keyword field utilizes ≥85 characters; at least two net-new keyword terms added that are relevant to your app's core use case.

The attribution layer that turns your optimized listing into measurable install data is next — [[Mobile Attribution with AppsFlyer & Branch: Setup, Events & Privacy]]
