---
chapter_num: 2
course_slug: google-tag-manager-mastery
title: "GA4 Integration via GTM: Configuration Tag and Custom Event Tracking"
status: g0-blocked
duration_min: 22
vendor_tag: Google Tag Manager / GA4
learning_objectives:
  - "Deploy a Google tag in GTM with a valid GA4 Measurement ID and confirm pageview data in GA4 DebugView"
  - "Create a Form Submission trigger scoped to a CSS selector and wire it to a GA4 Event tag"
  - "Configure Scroll Depth and Click – Just Links triggers to track engagement events"
  - "Cross-validate custom events and parameters in GA4 DebugView before publishing"
  - "Publish a named GTM container version to make GA4 event tracking live for real users"
sources:
  - url: "https://support.google.com/tagmanager/answer/9442095"
    title: "Set up Google Analytics in Tag Manager"
  - url: "https://support.google.com/tagmanager/answer/13034206"
    title: "Set up Google Analytics events in Tag Manager"
  - url: "https://support.google.com/tagmanager/answer/7679217"
    title: "Form submission trigger - Tag Manager Help"
  - url: "https://support.google.com/tagmanager/answer/7679218"
    title: "Scroll Depth trigger - Tag Manager Help"
  - url: "https://support.google.com/tagmanager/answer/7679320"
    title: "Click trigger - Tag Manager Help"
  - url: "https://support.google.com/analytics/answer/7201382"
    title: "[GA4] Monitor events in DebugView"
  - url: "https://support.google.com/analytics/answer/12270356"
    title: "[GA4] Measurement ID"
  - url: "https://support.google.com/tagmanager/answer/6107163"
    title: "Publishing, versions, and approvals - Tag Manager Help"
owns:
  - "GA4 Configuration tag deployment via GTM with correct Measurement ID"
  - "GA4 pageview validation in GA4 DebugView"
  - "GA4 Event tag for form submission using a Form Submission trigger scoped to a CSS selector"
  - "scroll-depth event tracking using GTM's built-in Scroll Depth trigger"
  - "outbound-click event tracking using GTM's built-in Click – Just Links trigger with outbound condition"
  - "GA4 DebugView: cross-validating that events and parameters arrive before container version publish"
  - "GTM container version publish for GA4 events as the final step before going live"
defers_to:
  - "Google Ads Conversion Tracking tag and dataLayer.push() for purchase events → ch3"
  - "advanced GTM Preview Mode debugging workflow → ch5"
  - "Consent Mode impact on GA4 tag behavior → ch6"
quiz_topics:
  - "where to find the GA4 Measurement ID and which GTM tag field it populates"
  - "which GTM trigger type to use for form submission scoped to a specific CSS selector"
  - "difference between the GA4 Configuration tag and a GA4 Event tag"
  - "how to confirm a custom event and its parameters appear in GA4 DebugView"
  - "built-in GTM trigger type used to track scroll depth"
notebooklm_source_focus:
  - "GA4 Configuration tag setup via GTM documentation 2025–2026"
  - "GTM form submission trigger and CSS selector scoping guide"
  - "GA4 DebugView real-time event validation documentation"
  - "GTM built-in triggers: Scroll Depth and Click Just Links reference"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Where do you find the GA4 Measurement ID, and which GTM tag field does it populate?"
    options:
      - "In GTM Container Settings — labeled 'Container ID,' starting with GTM-, entered in the Google tag Tag ID field"
      - "In GA4 Admin → Data streams → click your web stream → Stream details pane — entered in the Google tag Tag ID field"
      - "In GA4 Admin → Reports → Realtime overview → active sessions panel — entered in the GA4 Event tag Measurement ID field"
      - "In Google Ads → Tools → Measurement → Conversion tracking settings — entered in the Google tag Conversion ID field"
    correct_idx: 1
    explanation: "The Measurement ID (format G-XXXXXXXXXX) lives in GA4 Admin → Data streams → your web stream → Stream details. It populates the Tag ID field of the Google tag — not the GTM Container ID or any Google Ads field."
    section_anchor: setting-up-the-google-tag

  - question: "A site has multiple forms. You only want to track the checkout form (class='checkout-form') as a GA4 event. Which trigger configuration is correct?"
    options:
      - "Form Submission trigger → All Forms — scoping is handled at the GA4 Event tag level using an event parameter filter"
      - "Element Visibility trigger → CSS selector '.checkout-form' — fires when the form element scrolls into view instead of on submit"
      - "Form Submission trigger → Some Forms → CSS Selector condition matching '.checkout-form' — fires only when that form submits"
      - "Custom Event trigger listening for 'form_submit' — requires the developer to dispatch a JavaScript event on each submission"
    correct_idx: 2
    explanation: "The Form Submission trigger's 'Some Forms' option with a 'CSS Selector matches .checkout-form' condition scopes firing to that specific form. 'All Forms' fires on every form on the site — search bars, login fields, and newsletter signups included."
    section_anchor: form-submission-event-with-css-selector-scoping

  - question: "What is the functional difference between the Google tag and a GA4 Event tag in GTM?"
    options:
      - "The Google tag initializes GA4 and fires page_view on every page; GA4 Event tags fire individual named events only when their specific trigger conditions are met"
      - "The Google tag sends all events including custom ones to GA4; the GA4 Event tag is reserved only for standard e-commerce purchase events"
      - "Both tags send identical data to GA4; the difference is that GA4 Event tags require a dataLayer.push() call from the developer to activate"
      - "The Google tag fires on custom triggers like form submissions; the GA4 Event tag fires on All Pages to initialize the GA4 connection"
    correct_idx: 0
    explanation: "The Google tag (formerly GA4 Configuration tag) establishes the GA4 connection and sends page_view automatically. Each custom event — form_submit, scroll, click — requires a separate GA4 Event tag with its own trigger. One Google tag initializes; multiple Event tags extend."
    section_anchor: setting-up-the-google-tag

  - question: "You have created a GA4 Event tag for form submission. How do you confirm the event and its parameters are arriving correctly in GA4?"
    options:
      - "Check GTM Preview's Tags Fired list for a green badge next to the tag name — no further verification is needed"
      - "Open GA4 Admin → Data display → DebugView, click the event name in the Seconds stream, and verify parameters in the detail panel"
      - "Open Google Ads Conversion Manager and check whether the GA4 event has been imported as a conversion action"
      - "Open GA4 Reports → Events table and filter by the past hour to find the event row in the standard report"
    correct_idx: 1
    explanation: "GA4 DebugView shows events in real time (Seconds stream = last 60 seconds). Clicking an event expands its parameter list so you can confirm both the event name and parameter values. GTM Preview confirms client-side firing; DebugView confirms GA4-side arrival — both checks are required."
    section_anchor: validating-events-in-ga4-debugview

  - question: "Which GTM built-in trigger type tracks when users scroll to 25%, 50%, 75%, and 100% of a page?"
    options:
      - "Element Visibility trigger targeting a pixel-height beacon element placed at each scroll depth on the page"
      - "Custom Event trigger listening for a native browser scroll event dispatched by client-side JavaScript code"
      - "Window Loaded trigger combined with a JavaScript variable that reads window.scrollY on a repeating interval"
      - "Scroll Depth trigger configured with percentage thresholds 25,50,75,100 and default Window Load listener timing"
    correct_idx: 3
    explanation: "The Scroll Depth trigger is GTM's built-in solution for this use case. It fires once per threshold per page load at Window Load timing (ensuring accurate page height). Enter thresholds as comma-separated integers and select Percentages as the unit."
    section_anchor: scroll-depth-and-outbound-click-events
---

## Setting Up the Google Tag

GA4 needs the Google tag — formerly called the "GA4 Configuration tag," renamed by Google in 2023 but functionally identical — to initialize on every page before any custom event can land. Your chapter 1 container is already live; this chapter layers the GA4 connection and four event types on top of it.

**Get your Measurement ID first.** In GA4, go to Admin → Data collection and modification → Data streams → click your web stream name → find the ID under *Stream details*. It looks like `G-PSW1MY7HB4`. This string is also called the Google tag ID and the destination ID — all three names refer to the same value. Editor-level permission on the GA4 property is required to view it. Copy it from GA4, not from Google Ads; Ads IDs begin with `AW-`, not `G-`, and entering the wrong prefix means your tag silently sends data nowhere.

Create the Google tag in GTM: Tags → New → name it `GA4 – Google tag – All Pages`. Tag type: **Google Tag**. In the *Tag ID* field, paste your Measurement ID. Triggering: **Initialization – All Pages**. The Initialization trigger fires earlier in the page lifecycle than Page View, giving GA4 time to initialize before any subsequent Event tags attempt to send data. Save, enter Preview mode, reload the page, and confirm the tag appears under *Tags Fired*.

<KnowledgeCheck question="The Google tag shows as fired in GTM Preview. What does this confirm, and what still needs verification?" options={["The event data has arrived in GA4 with correct parameters — no further step is needed", "The tag executed on the client side; you still need to open GA4 DebugView and confirm page_view appears there", "GA4 is now receiving data from all real users on the production site", "The Measurement ID was accepted by GTM and GA4 will auto-validate within 24 hours"]} correctIdx={1} explanation="GTM Preview confirms client-side execution. Whether data actually reaches GA4 — and with correct parameters — requires a separate check in GA4 DebugView, which shows events in real time as they arrive."/>

## Form Submission Event with CSS Selector Scoping

The Google tag handles `page_view` automatically. Every other event needs its own GA4 Event tag with an appropriate trigger.

For form tracking, **scope is the critical design decision**. Nearly every site has multiple forms — search bars, login fields, newsletter signups, and checkout — and you rarely want all of them mapped to the same GA4 event. The Form Submission trigger's *Some Forms* option lets you restrict firing to a single form via a CSS selector condition, as documented in the [Form submission trigger reference](https://support.google.com/tagmanager/answer/7679217).

Create the trigger: Triggers → New → **Form Submission**. Under *This trigger fires on*, select **Some Forms**. Add condition: *CSS Selector* → *matches CSS selector* → `.newsletter-form` (replace with your target form's class or ID). Enable **Wait for Tags** — this holds the browser's default form action until your tags have fired, preventing data loss when a form redirects the page before the tag completes. Enable **Check Validation** so the trigger only fires on successfully validated submissions. Name it `Form Submit – Newsletter`.

Create the GA4 Event tag: Tags → New → **Google Analytics: GA4 Event**. Measurement ID: your `G-XXXXXXXXXX`. Event Name: `generate_lead` (a GA4 recommended event name that appears in standard reports). Add parameter: `form_id` = `{{Form ID}}`. Triggering: `Form Submit – Newsletter`.

<KnowledgeCheck question="Why use 'Some Forms' instead of 'All Forms' for a newsletter signup trigger?" options={["'All Forms' is unavailable — GTM always requires a CSS selector condition to create a Form Submission trigger", "'All Forms' would fire the generate_lead event on every form submit across the site, including search bars and login forms", "'Some Forms' fires earlier in the page lifecycle, preventing data loss on fast-redirecting forms", "CSS selector conditions are required to enable the Wait for Tags option in GTM"]} correctIdx={1} explanation="'All Forms' fires on every form on the page — a search submission or login attempt would trigger generate_lead alongside the actual newsletter signup. Scoping with a CSS selector targets only the intended form element."/>

## Scroll-Depth and Outbound-Click Events

**Scroll Depth** uses GTM's built-in [Scroll Depth trigger](https://support.google.com/tagmanager/answer/7679218). Create the trigger: Triggers → New → **Scroll Depth**. Enable *Vertical Scrolls*, enter thresholds `25,50,75,100` as Percentages. Leave listener timing at the default **Window Load** — this ensures the browser has finished rendering all content before percentage thresholds are calculated, so "25%" is consistent across long and short pages. The trigger fires once per threshold per page load; scrolling back toward the top never re-fires a threshold that has already fired. Three built-in variables populate automatically: Scroll Depth Threshold, Scroll Depth Units, and Scroll Direction.

Create the event tag: GA4 Event → Event Name `scroll` → parameter `percent_scrolled` = `{{Scroll Depth Threshold}}`.

**Outbound click** uses the **Click – Just Links** trigger, which fires exclusively on `<a>` anchor elements and ignores buttons, divs, and images. First enable the Click URL built-in variable: Variables → Configure → Clicks section → check *Click URL*. Then create the trigger: Triggers → New → **Click – Just Links** → Some Link Clicks → *Click URL* → *does not contain* → `yourdomain.com`. Enable Wait for Tags.

Create the event tag: Event Name `click`, parameters `link_url` = `{{Click URL}}` and `outbound` = `true`.

<Callout type="warning">
**Scroll Depth listener timing matters.** If you change the default from Window Load to Container Load, GTM calculates percentage thresholds before the page finishes rendering. The measured `scrollHeight` may be shorter than the fully loaded page, causing the 75% threshold to fire at what is actually 50% of the content. Leave the default Window Load unless you have a specific technical reason to change it.
</Callout>

## Validating Events in GA4 DebugView

GTM Preview confirms a tag fires on the client side. GA4 DebugView confirms the data actually arrives in your GA4 property — with the correct event name and parameter values. Both checks are required before publishing.

When GTM Preview launches, Tag Assistant automatically appends a `_dbg` parameter to the site URL, which enables DebugView for your session. No separate `debug_mode: true` tag parameter is needed. Open GA4: Admin → Data display → DebugView.

According to the [GA4 DebugView documentation](https://support.google.com/analytics/answer/7201382), DebugView provides two time windows: a *Seconds stream* showing the last 60 seconds of events, and a *Minutes stream* showing per-minute event counts across the last 30 minutes. Click any event name to expand its parameter list. For each event you configured, confirm: the event name matches exactly what you set in the GA4 Event tag; expected parameters appear with correct values (`form_id`, `percent_scrolled`, `link_url`); and no unexpected duplicate events appear. A `generate_lead` that fires twice per form submission points to a trigger scoping problem — fix it before you publish.

DebugView data is a diagnostic overlay; it is not included in standard GA4 reports and does not affect production metrics.

## Publishing the Container Version

Preview mode tests your workspace draft. Real users see none of these events until you publish. Once DebugView confirms all four events are landing correctly, click **Submit → Publish and Create Version**. Name the version descriptively — for example, `v2 – GA4 base tag + form, scroll, outbound events`. Click **Publish**.

The version goes live immediately and creates a permanent, timestamped snapshot in [GTM version history](https://support.google.com/tagmanager/answer/6107163) — your rollback point if a future change breaks something. Publishing requires Approve access or above on the GTM container. Analysts and editors below that threshold can save workspace changes but cannot push them live.

## Hands-On Exercise: GA4 Event Suite

Using a real or sandbox GTM container connected to a GA4 property, build and validate the complete event suite:

1. Create the Google tag with your GA4 Measurement ID on the Initialization – All Pages trigger. In GTM Preview, confirm it fires. In GA4 DebugView, confirm `page_view` appears within five seconds with `page_location` and `page_title` parameters.
2. Identify a form on your site. Create a Form Submission trigger scoped to that form's CSS selector with Wait for Tags and Check Validation enabled. Create a GA4 Event tag named `generate_lead` with a `form_id` parameter. Submit the form in Preview mode and confirm the event in DebugView.
3. Create a Scroll Depth trigger for `25,50,75,100` percent at Window Load. Wire it to a GA4 Event tag named `scroll` with `percent_scrolled` as a parameter. Scroll through a long page in Preview mode and confirm four separate `scroll` events in DebugView with the correct threshold values.
4. Enable the Click URL built-in variable. Create a Click – Just Links trigger for outbound links. Create a GA4 Event tag named `click` with `link_url` and `outbound` parameters. Click an external link in Preview mode and confirm in DebugView.
5. Publish the container. Name the version to reflect its contents.

**Success criteria:** All four events visible in GA4 DebugView with correct parameter values before publish. Container version published with a descriptive name that includes the event types added.

Chapter 3 covers how the `dataLayer` passes purchase data from your site to GTM — and how the Google Ads Conversion Tracking tag reads it to carry revenue values into Smart Bidding. See [[03-google-ads-conversion-datalayer]].
