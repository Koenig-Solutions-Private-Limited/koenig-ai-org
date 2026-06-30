---
chapter_num: 6
course_slug: google-tag-manager-mastery
title: "Consent Mode v2 and Privacy-Compliant Tracking for Performance Campaigns"
status: g3-passed
last_updated: 2026-06-11
duration_min: 18
vendor_tag: Google Tag Manager
learning_objectives:
  - "Explain the four consent parameters in Consent Mode v2 and how they differ from v1"
  - "Configure a Consent Initialization trigger and default consent state tag in GTM"
  - "Wire a CMP consent update event to dynamically update consent state in GTM"
  - "Verify consent state and tag behavior using GTM Preview's consent debug panel"
  - "Confirm that modelled conversions appear in Google Ads when user consent is withheld"
sources:
  - url: "https://developers.google.com/tag-platform/security/concepts/consent-mode"
    title: "Consent Mode Overview — Tag Platform"
  - url: "https://support.google.com/tagmanager/answer/10718549"
    title: "Tag Manager Consent Mode Support — GTM Help"
  - url: "https://support.google.com/google-ads/answer/13695607"
    title: "Updates to Consent Mode for EEA Traffic — Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/10548233"
    title: "About Consent Mode Modelling — Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/10081327"
    title: "About Modeled Online Conversions — Google Ads Help"
  - url: "https://developers.google.com/tag-platform/security/guides/consent-debugging"
    title: "Troubleshoot Consent Mode with Tag Assistant — Tag Platform"
  - url: "https://www.simoahava.com/analytics/consent-mode-v2-google-tags/"
    title: "Consent Mode V2 for Google Tags — Simo Ahava"
  - url: "https://developers.google.com/tag-platform/security/guides/consent"
    title: "Set Up Consent Mode on Websites — Tag Platform"
owns:
  - "Google Consent Mode v2: what it is, how it differs from v1, and why it matters for Smart Bidding signal completeness"
  - "Consent Initialization trigger: configuration and why it must fire before any other tags"
  - "default consent state setup: setting ad_storage and analytics_storage defaults via a GTM variable (denied by default pattern)"
  - "CMP consent update event: wiring a CMP's consent-granted/rejected event to dynamically update consent state in GTM"
  - "Consent Mode impact on Google Ads conversion and GA4 tags: what fires, what is blocked, and what is modelled"
  - "GTM Preview consent debug panel: verifying consent state at each tag fire event"
  - "opted-in vs opted-out tag behavior testing in Preview Mode"
  - "modelled conversions in Google Ads: confirming they appear when consent is withheld"
defers_to:
  - "Google Ads Conversion Tracking tag configuration → ch3"
  - "Meta Pixel tag configuration → ch4"
  - "container QA checklist → ch5"
  - "consent compliance as part of quarterly audit → ch7"
quiz_topics:
  - "why the Consent Initialization trigger must fire before all other tags in GTM"
  - "which two consent types are required by Google Consent Mode v2 for ad and analytics tags"
  - "how GTM detects when a user accepts consent via a CMP and updates the consent state"
  - "in GTM Preview's consent debug panel, what does 'ad_storage: denied' indicate about tag behavior"
  - "how modelled conversions in Google Ads preserve Smart Bidding signals when consent is withheld"
notebooklm_source_focus:
  - "Google Consent Mode v2 implementation guide 2025–2026"
  - "GTM Consent Initialization trigger and default consent state configuration"
  - "CMP GTM integration: consent update event wiring for OneTrust, Cookiebot, and Usercentrics"
  - "Google Ads modelled conversions and Consent Mode data gaps documentation"
  - "GTM consent debug panel and opted-in vs opted-out testing workflow"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Why must the Consent Initialization trigger fire before all other GTM triggers, including Initialization triggers?"
    options:
      - "It establishes the default consent state so Google tags cannot read stale or undefined consent before making measurement decisions"
      - "It initializes the GTM dataLayer object, which must exist before any tag can push events to it"
      - "It loads the CMP banner script, which must render before any other tag can execute safely"
      - "It sets the container's firing order priority so that newer tags take precedence over older ones"
    correct_idx: 0
    explanation: "The Consent Initialization trigger fires before all other trigger types precisely to establish the default consent state. If another tag reads consent before the default is set, GTM reports an error and tag behavior becomes undefined."
    section_anchor: "the-consent-initialization-trigger-fire-order-guarantee"
  - question: "Consent Mode v2 added two new parameters on top of v1's ad_storage and analytics_storage. Which two were added?"
    options:
      - "ad_user_data and ad_personalization"
      - "user_storage and personalization_storage"
      - "remarketing_storage and enhanced_conversions"
      - "conversion_tracking and audience_targeting"
    correct_idx: 0
    explanation: "v2 added ad_user_data (controls whether personal data may be sent to Google for advertising) and ad_personalization (controls whether the user may receive personalized ads and be added to remarketing lists). These are downstream instructions to Google services, not cookie controls."
    section_anchor: "consent-mode-v2-four-parameters-and-the-upgrade-from-v1"
  - question: "How does GTM detect that a user accepted consent on a CMP banner and then update the consent state?"
    options:
      - "A CMP community template listens for the CMP's own consent-accepted event and fires gtag consent update automatically"
      - "GTM polls the CMP's API every 500 ms and updates consent state when the API response changes"
      - "A custom trigger on All Pages reads a CMP cookie and updates consent state on the next page load"
      - "The GTM container reads the CMP's localStorage key on each tag fire and adjusts consent parameters accordingly"
    correct_idx: 0
    explanation: "Official CMP community templates in GTM's Template Gallery listen for the CMP's own consent-accepted event internally and automatically fire gtag consent update with the correct granted values. No manual polling or custom trigger is needed."
    section_anchor: "wiring-your-cmp-to-gtm-the-consent-update-flow"
  - question: "In GTM Preview's consent debug panel, what does 'ad_storage: denied' tell you about tag behavior in Advanced Mode?"
    options:
      - "The tag fires a cookieless ping rather than a full cookie-carrying hit, because advertising cookies cannot be read or written"
      - "The tag is completely blocked and sends no data to Google, including any modelling signals whatsoever"
      - "The tag fires normally and writes cookies, but those cookies expire at the end of the browser session"
      - "The tag fires normally but omits the transaction ID to prevent direct user identification by Google"
    correct_idx: 0
    explanation: "In Advanced Mode, ad_storage: denied means the tag fires but cannot read or write advertising cookies. It sends a cookieless ping instead of a full measurement hit. Google uses these pings for conversion modelling. Only Basic Mode blocks the tag entirely."
    section_anchor: "verifying-consent-state-in-gtm-preview"
  - question: "How do modelled conversions in Google Ads help preserve Smart Bidding signal quality when users withhold consent?"
    options:
      - "Google AI estimates non-consenting conversions using patterns from consented users; the combined Conversions column total is Smart Bidding's full optimization signal"
      - "Smart Bidding ignores non-consenting users and optimizes only toward consented conversions to prevent contamination from unconsented audience segments"
      - "Google Ads statistically duplicates each consented conversion to compensate for non-consenting users and maintain stable bid signals"
      - "Modelled conversions appear only in a separate Consent Mode Impact column and do not influence Smart Bidding bid targets"
    correct_idx: 0
    explanation: "Modelled conversions are AI estimates for the non-consenting audience, derived from patterns in consented user data. They appear in the same Conversions column as observed conversions, giving Smart Bidding a complete optimization signal that includes the denied-consent segment."
    section_anchor: "modelled-conversions-smart-bidding-with-a-consent-gap"
---

## Consent Mode v2: Four Parameters and the Upgrade from v1

Google Consent Mode is the API layer between your cookie banner and your Google tags. Version 1 gave you two controls: `ad_storage` (whether Google's advertising tags can read or write cookies) and `analytics_storage` (whether analytics cookies can operate). Both accept only `"granted"` or `"denied"`.

Version 2, launched November 2023, added two downstream parameters: `ad_user_data` and `ad_personalization`. [Updates to Consent Mode for EEA Traffic](https://support.google.com/google-ads/answer/13695607) These are not cookie controls. `ad_user_data` tells Google whether your implementation may send personal data—like hashed emails for Enhanced Conversions—to Google for advertising purposes. `ad_personalization` tells Google whether a user may receive personalized ads and be added to remarketing audiences. A common v2 mistake is setting only these two while believing cookies are blocked. `ad_storage` remains the sole parameter that prevents cookie read/write.

For EEA traffic under the updated EU User Consent Policy, all four parameters are required. Accounts still running v1 must upgrade, or risk under-reporting signals that Smart Bidding depends on.

## The Consent Initialization Trigger: Fire-Order Guarantee

GTM triggers execute in this sequence: **Consent Initialization → Initialization → all other triggers**. That top slot exists for one purpose: to set the default consent state before any tag can read it. The built-in "Consent Initialization – All Pages" trigger ships with every GTM web container and is the only trigger you should attach to your consent default tag.

If another tag fires before the default is established, Tag Assistant reports: "A tag read consent state before a default was set." Without a default, Google's ad tags may treat the absence of a state as `granted`—the opposite of safe. Set your consent default tag's **Tag Priority** to `10` within the Consent Initialization phase to guarantee it fires before any CMP template also running on this trigger.

[Tag Manager Consent Mode Support](https://support.google.com/tagmanager/answer/10718549) documents this trigger type as non-negotiable for a correct consent implementation.

<KnowledgeCheck question="Which GTM trigger type must you assign to the default consent state tag to guarantee it fires before any other tag?" options={["Consent Initialization - All Pages", "Initialization - All Pages", "All Pages (Page View)", "Custom Event - Consent Default"]} correctIdx={0} explanation="The Consent Initialization trigger fires before Initialization and all other trigger types. It exists specifically so the consent default is set before any measuring tag executes and reads an undefined state." />

## Default Consent State: Denied by Default

Your default consent state tag runs a single `gtag('consent', 'default', {...})` call. The denied-by-default pattern is the correct starting position for EEA users:

```html
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('consent', 'default', {
    'ad_storage': 'denied',
    'analytics_storage': 'denied',
    'ad_user_data': 'denied',
    'ad_personalization': 'denied',
    'wait_for_update': 500
  });
</script>
```

The `wait_for_update: 500` parameter is critical when your CMP loads asynchronously. It instructs Google tags to hold for up to 500 ms, allowing the CMP's update call to arrive first for returning visitors whose consent cookie already records a prior grant. Without it, those users see an unnecessary denial window on every page load. [Set Up Consent Mode on Websites](https://developers.google.com/tag-platform/security/guides/consent)

## Wiring Your CMP to GTM: The Consent Update Flow

When a user clicks "Accept All," your CMP must tell GTM which consent types were granted. The cleanest path is a CMP community template from GTM's Template Gallery—over 35 partner templates are available, including OneTrust, Cookiebot, and Usercentrics, each pre-wired to the CMP's own consent event schema.

For OneTrust: add the OneTrust CMP template, enter your Script ID, enable "Use Google Consent Mode?", map each OneTrust category to its consent parameter (Performance cookies → `analytics_storage`; Targeting cookies → `ad_storage`, `ad_user_data`, `ad_personalization`), set all four defaults to `denied`, and trigger on Consent Initialization – All Pages. When a user accepts, the template automatically fires `gtag('consent', 'update', {...})` with `granted` values—no custom trigger needed.

If you hand-roll a custom update instead of using a template, you must create a Custom Trigger listening for your CMP's exact event name and maintain that integration manually as the CMP's event schema evolves. Use the official template.

<KnowledgeCheck question="A user visits your site, declines the cookie banner, then clicks Accept on the same page. What happens to GA4 events collected before acceptance?" options={["They are automatically reprocessed with granted consent status for the current page session", "They are permanently lost because consent cannot be retroactively applied to sent events", "They are sent to GA4 with a modelling flag indicating estimated rather than observed data", "They are held in the dataLayer queue and resent on the next page load after consent is stored"]} correctIdx={0} explanation="Consent Mode's hit reprocessing applies to same-page events: measurement hits collected while consent was denied are reprocessed once the update call grants consent. Cross-page hits from earlier sessions are not reprocessed because the identifiers to link them are missing." />

## What Fires, What Blocks, and What Is Modelled

The outcome when consent is denied depends on which implementation mode you chose—and this choice directly affects Smart Bidding quality.

**Advanced Mode** (recommended): Tags fire immediately with denied consent state, sending cookieless pings—minimal, cookie-free measurement signals. Google uses these pings for advertiser-specific conversion modelling, recovering 30–50% more attribution than Basic Mode.

**Basic Mode**: Tags are completely blocked until consent is granted. Only general, non-advertiser-specific modelling is available. Choose Basic Mode only when a legal review explicitly requires it; for most performance advertisers, it is the wrong default.

When `ad_storage` is `denied` in Advanced Mode, your Google Ads Conversion and GA4 tags fire but cannot access cookies. [Consent Mode Overview](https://developers.google.com/tag-platform/security/concepts/consent-mode) The `gcd` URL parameter on each hit encodes all four consent states so Google can correctly model from the signal. When `ad_storage` is `granted`, both tags fire normally with full cookie access.

<Callout type="warning">
Advanced Mode fires tags as cookieless pings when consent is denied; Basic Mode blocks them entirely. If your container silently uses Basic Mode, Smart Bidding loses 30–50% of its attribution signal compared to Advanced Mode. Confirm your mode in the GTM Consent tab before publishing.
</Callout>

## Verifying Consent State in GTM Preview

Open GTM Preview, connect to your site, and interact with the cookie banner. In Tag Assistant, click the **Consent** tab. Two events must appear:

1. **Consent (default)** — the earliest event, from your Consent Initialization tag. Verify all four parameters show `denied`.
2. **Consent (update)** — fired after user interaction. Verify accepted categories show `granted`.

If the Consent tab is empty, consent mode is not implemented—[Troubleshoot Consent Mode with Tag Assistant](https://developers.google.com/tag-platform/security/guides/consent-debugging) lists this as the first-pass diagnostic.

For tag-level verification: select your Google Ads Conversion tag and check the consent column. In Advanced Mode, `ad_storage: denied` appears alongside a "Fired" status—the tag sent a cookieless ping, not a full hit, and that is correct. In Basic Mode, the same scenario shows "Not Fired" with a consent block reason. Test both paths explicitly: reject cookies and confirm the denied state; accept and confirm `ad_storage: granted` with a full hit.

## Modelled Conversions: Smart Bidding with a Consent Gap

When part of your audience declines cookies, Google AI estimates those conversions using behavioral patterns from consented users. Consented users convert 2–5× more frequently than unconsented users in Google's models, providing a strong statistical prior. [About Consent Mode Modelling](https://support.google.com/google-ads/answer/10548233)

Modelled conversions appear in the standard **Conversions** column alongside observed conversions—not in a separate column. Smart Bidding reads the combined total as its optimization signal and bids correctly for the non-consenting segment rather than treating it as zero-conversion traffic.

To confirm modelling is active: open Google Ads → Measurement → Consent Mode Impact report. If no modelled conversions appear despite a correct implementation, check volume: Google requires ≥700 ad clicks per 7-day period per country+domain grouping before modelling activates.

## Hands-On Exercise: Full Consent Mode v2 Implementation

Implement Consent Mode v2 on a GTM Preview-connected page.

**Steps:**

1. Create a Custom HTML tag with `gtag('consent', 'default', {...})` denying all four parameters and `wait_for_update: 500`. Trigger: Consent Initialization – All Pages. Tag Priority: 10.
2. Add a CMP community template from GTM Template Gallery (or simulate a consent update via a custom event firing `gtag('consent', 'update', {...})`).
3. Open GTM Preview. Load the page without touching the banner. In Tag Assistant → Consent tab, confirm the default event shows all four parameters as `denied`.
4. Accept the cookie banner. Confirm a second Consent (update) event shows `ad_storage: granted` and `analytics_storage: granted`.
5. Load a page with your Google Ads Conversion tag. Reject all cookies. Verify the tag shows `ad_storage: denied` and status "Fired" (Advanced Mode cookieless ping).
6. Accept cookies. Verify `ad_storage: granted` and the conversion tag fires a full hit.

**Success criteria:** Two consent events in Tag Assistant (default → update); conversion tag shows denied state in the reject path and granted state in the accept path; no "tag read consent before default was set" warning.

Next chapter: [[07-auditing-container-maintenance]] adds consent compliance to the recurring quarterly review that keeps your container accurate over time.
