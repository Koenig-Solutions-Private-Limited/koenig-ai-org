---
chapter_num: 3
course_slug: google-tag-manager-mastery
title: "Conversion Tracking: Google Ads Tags and the dataLayer"
status: g0-passed
last_updated: 2026-06-11
duration_min: 35
vendor_tag: Google Tag Manager / Google Ads
learning_objectives:
  - "Write a correct dataLayer.push() call for a purchase event with dynamic order value, currency, and transaction ID"
  - "Create GTM Data Layer Variables (Version 2) to read nested ecommerce values from the dataLayer"
  - "Configure a Google Ads Conversion Tracking tag with dynamic revenue value and transaction ID for tROAS bidding"
  - "Install and test a Conversion Linker tag including cross-domain attribution setup"
  - "Implement deduplication logic to prevent duplicate conversion counting using trigger conditions and transaction IDs"
  - "Explain how deduplicated, value-carrying conversions improve Smart Bidding tROAS signal accuracy"
sources:
  - url: "https://developers.google.com/tag-platform/tag-manager/datalayer"
    title: "The data layer | Tag Platform | Google for Developers"
  - url: "https://support.google.com/tagmanager/answer/7683362"
    title: "User-defined variable types for web - Tag Manager Help"
  - url: "https://support.google.com/tagmanager/answer/6105160"
    title: "Google Ads conversions - Tag Manager Help"
  - url: "https://support.google.com/tagmanager/answer/7549390"
    title: "Conversion linker - Tag Manager Help"
  - url: "https://support.google.com/google-ads/answer/6386790"
    title: "Use a transaction ID to minimize duplicate conversions - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/6268637"
    title: "About Target ROAS bidding - Google Ads Help"
  - url: "https://support.google.com/google-ads/answer/14792795"
    title: "Value-based Bidding Best Practices - Google Ads Help"
owns:
  - "dataLayer.push() syntax for purchase events: structure with event name, order value, and transaction ID"
  - "GTM Data Layer variable type: configuration to read values pushed by the page"
  - "Google Ads Conversion Tracking tag: setup with dynamic revenue value, currency, and transaction ID to support tROAS bidding"
  - "Conversion Linker tag: installation, cross-domain attribution setup, and test in GTM Preview Mode"
  - "duplicate conversion detection: identifying tags firing multiple times per transaction"
  - "event deduplication logic using trigger conditions and unique transaction ID checks"
  - "Smart Bidding signal accuracy: why deduplicated, value-carrying conversions improve tROAS performance"
defers_to:
  - "Google Ads Remarketing tag → ch4"
  - "Meta Pixel and other ad-platform pixels → ch4"
  - "advanced debugging of misfiring conversion tags → ch5"
  - "Consent Mode impact on conversion tag firing → ch6"
  - "conversion tag audit and removal of legacy conversion actions → ch7"
quiz_topics:
  - "correct dataLayer.push() structure for a purchase event with order value and transaction ID"
  - "which GTM variable type reads a value pushed to the dataLayer"
  - "why passing a unique transaction ID to the Google Ads conversion tag prevents duplicate counting"
  - "what the Conversion Linker tag does and when it is required for accurate attribution"
  - "how tROAS Smart Bidding uses the dynamic revenue value from the Google Ads conversion tag"
notebooklm_source_focus:
  - "Google Ads Conversion Tracking via GTM with dynamic values documentation 2025–2026"
  - "GTM dataLayer variable type and dataLayer.push() reference"
  - "Google Ads Conversion Linker tag setup and cross-domain tracking guide"
  - "Smart Bidding tROAS signal quality and conversion deduplication best practices"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which JavaScript object structure is correct for a GTM purchase event dataLayer push that passes order value and transaction ID?"
    options:
      - "dataLayer.push({ event: 'purchase', ecommerce: { transaction_id: 'ORD-001', value: 89.97, currency: 'USD' } })"
      - "dataLayer.push({ type: 'purchase', revenue: 89.97, orderId: 'ORD-001', currency: 'USD' })"
      - "dataLayer.send('purchase', { value: '89.97', transaction_id: 'ORD-001', currency: 'USD' })"
      - "gtag('event', 'purchase', { ecommerce: { value: 89.97, transaction_id: 'ORD-001', currency: 'USD' } })"
    correct_idx: 0
    explanation: "dataLayer.push() with an event key of 'purchase' and an ecommerce object containing a numeric value, transaction_id, and ISO 4217 currency string is the correct GTM-compatible structure. The event key triggers GTM rule evaluation; the ecommerce object carries the payload variables."
    section_anchor: how-the-datalayer-bridges-your-page-and-gtm

  - question: "In GTM, which variable type should you configure to read ecommerce.transaction_id from a dataLayer.push() call that uses a nested ecommerce object?"
    options:
      - "Data Layer Variable (Version 2) with Data Layer Variable Name set to ecommerce.transaction_id"
      - "JavaScript Variable referencing window.ecommerce.transaction_id directly in the browser scope"
      - "URL Variable configured to read the transaction_id query parameter from the page URL"
      - "Constant Variable set to the expected transaction ID format as a validation placeholder"
    correct_idx: 0
    explanation: "The Data Layer Variable type (Version 2) interprets dots as nested-object traversal. Setting the key to ecommerce.transaction_id reads the nested transaction_id inside the ecommerce object. Version 1 treats dots as literal key characters and returns undefined for nested structures."
    section_anchor: reading-datalayer-values-the-data-layer-variable-type

  - question: "Why does passing a unique transaction ID in the Google Ads Conversion Tracking tag prevent inflated conversion counts?"
    options:
      - "Google Ads discards repeat pings that share the same transaction ID for a given conversion action, so each purchase is counted once regardless of how many times the tag fires"
      - "GTM detects the duplicate transaction ID in the dataLayer and prevents the tag from firing a second time on the same page session"
      - "The Conversion Linker stores the transaction ID in a cookie and blocks subsequent conversion tag fires originating from the same browser session"
      - "Google Ads groups all pings sharing a transaction ID and records a single averaged-value conversion event for the order"
    correct_idx: 0
    explanation: "Google Ads performs server-side deduplication: after the first conversion ping with a given transaction ID is recorded for that conversion action, subsequent pings with the same ID are silently discarded. GTM does not enforce this — the protection depends on passing the ID at the tag level."
    section_anchor: stopping-duplicate-conversions

  - question: "What does the Conversion Linker tag do and on which pages should it fire?"
    options:
      - "It stores ad click identifiers from landing-page URL parameters into first-party cookies so conversion tags on later pages can attribute back to the original click; it must fire on all pages"
      - "It fires on the order-confirmation page to capture the final purchase event and transmit the transaction value directly to Google Ads attribution servers"
      - "It generates a session-scoped linker ID per conversion tag fire and embeds it in the Google Ads conversion ping to prevent cross-session double-counting"
      - "It reads the Conversion ID and Label from the Google Ads interface and injects them into conversion tags automatically without requiring manual tag configuration"
    correct_idx: 0
    explanation: "The Conversion Linker reads gclid, wbraid, and gbraid parameters from landing-page URLs and writes them into first-party cookies (_gcl_aw etc.). Without it on all pages, a conversion tag on the thank-you page has no click to attribute. An All Pages trigger ensures every ad-driven landing is captured."
    section_anchor: installing-the-conversion-linker

  - question: "How does Google Ads tROAS Smart Bidding use the dynamic revenue value passed by the Google Ads Conversion Tracking tag?"
    options:
      - "It trains a per-auction value prediction model that bids higher for users likely to generate more revenue and lower for low-value signals, making accurate dynamic values essential to efficient bidding"
      - "It calculates a post-campaign ROAS ratio by dividing total revenue by total spend, then scales the next campaign budget proportionally to hit the advertiser's target"
      - "It applies the revenue value as a bid multiplier at the ad group level, raising or lowering bids by the percentage difference between actual and target ROAS"
      - "It averages all incoming revenue values across recent conversion events and uses that single figure as the fixed conversion value at every auction"
    correct_idx: 0
    explanation: "tROAS predicts the expected conversion value at each auction and sets bids accordingly — higher for high-value predictions, lower for low-value ones. Inaccurate, zero, or missing revenue values corrupt the prediction model, causing erratic bidding that cannot achieve the target ROAS."
    section_anchor: why-clean-conversions-power-troas
---

## How the dataLayer Bridges Your Page and GTM

The `dataLayer` is a JavaScript array — `window.dataLayer` — that acts as a communication bus between your page code and Google Tag Manager. Your site writes to it; GTM reads from it.

The write mechanism is `dataLayer.push()`. You call it with a plain JavaScript object containing an `event` key and whatever variable data you want GTM to consume. The `event` key is special: per [The data layer | Google for Developers](https://developers.google.com/tag-platform/tag-manager/datalayer), GTM evaluates all triggers against it immediately in FIFO order — all matching tags fire before the next push is processed.

On your order-confirmation page, the correct push looks like this:

```javascript
window.dataLayer = window.dataLayer || [];
dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'ORD-20260610-00042',  // server-rendered, unique per order
    value: 89.97,                           // number — not a string
    currency: 'USD',                        // ISO 4217
    tax: 7.20,
    shipping: 5.99
  }
});
```

Two details carry real consequences. First, `value` must be a numeric type — not the string `"89.97"`. Google Ads silently rejects or zeros string values, poisoning tROAS signal. Second, `transaction_id` must come from server-rendered order data, never a placeholder. A hardcoded ID causes every subsequent purchase to be deduplicated against the first order ever recorded — catastrophic under-reporting that is invisible until you audit your conversion history.

## Reading dataLayer Values: the Data Layer Variable Type

To use `ecommerce.transaction_id` inside a GTM tag you need a **Data Layer Variable**. Navigate to Variables → New → Variable Configuration → Data Layer Variable.

Set the **Data Layer Variable Name** to the dot-notation key path. For Version 2 containers — the default for all new GTM containers — dots mean nested-object traversal:

| GTM variable name | Data Layer Variable Name | What it reads |
|---|---|---|
| DLV - Transaction ID | `ecommerce.transaction_id` | The nested transaction ID string |
| DLV - Order Value | `ecommerce.value` | The numeric revenue amount |
| DLV - Currency | `ecommerce.currency` | The ISO 4217 currency code |

Per [User-defined variable types for web](https://support.google.com/tagmanager/answer/7683362), Version 1 containers treat dots as literal key characters — `ecommerce.transaction_id` in V1 looks for a top-level key named `"ecommerce.transaction_id"` and returns `undefined` for nested structures. Confirm your container is Version 2 before building these variables.

<KnowledgeCheck
  question="You create a Data Layer Variable with name 'ecommerce.transaction_id' in a Version 2 GTM container. What does it return when the dataLayer contains { event: 'purchase', ecommerce: { transaction_id: 'ORD-001', value: 59.99 } }?"
  options={["The string 'ORD-001'", "The entire ecommerce object", "undefined — Version 2 requires bracket notation instead", "The number 59.99"]}
  correctIdx={0}
  explanation="Version 2 uses dot notation to traverse nested objects. ecommerce.transaction_id navigates into the ecommerce key and reads transaction_id, returning 'ORD-001'. Bracket notation is not required — that is a Version 1 misconception."
/>

## Building the Google Ads Conversion Tracking Tag

Once your Data Layer Variables exist, configure the tag: Tags → New → Google Ads Conversion Tracking.

Fill in:
- **Conversion ID**: your `AW-XXXXXXXXX` from the Google Ads conversion action setup screen
- **Conversion Label**: the action-specific label from the same screen
- **Conversion Value**: `{{DLV - Order Value}}`
- **Currency Code**: `{{DLV - Currency}}`
- **Transaction ID**: `{{DLV - Transaction ID}}`

Set the trigger to a **Custom Event** with Event Name = `purchase` (exact match). Avoid a Page View trigger on the thank-you URL — URL conditions fire on every reload and can match sessions that never completed a purchase.

<Callout type="warning">
**Pass value as a number; pass currency as an ISO 4217 string.** Writing `value: "89.97"` (quoted) causes Google Ads to record zero revenue for the conversion — tROAS has no accurate signal to bid against. Verify in GTM Preview Mode that DLV - Order Value resolves to a number. The Preview panel shows each variable's resolved value alongside the tag fire event.
</Callout>

## Installing the Conversion Linker

The Conversion Linker tag persists Google Ads click parameters — `gclid`, `wbraid`, `gbraid` — from landing-page URL parameters into first-party cookies (`_gcl_aw` for Google Ads clicks). Without it, a conversion tag firing on a downstream page has no click to attribute, and the conversion is lost or misattributed.

Install it in GTM: Tags → New → Conversion Linker, trigger = **All Pages**.

For cross-domain flows — ad click on `shop.example.com`, purchase on `secure.payments-example.com`:

1. **Landing-page container**: check "Enable linking across domains" and list `secure.payments-example.com` in Auto Link Domains. GTM appends a `_gl` linker parameter to outbound links.
2. **Checkout-domain container**: install a Conversion Linker with no cross-domain settings — it reads the `_gl` parameter and writes the `_gcl_aw` cookie.

To test in Preview Mode: append `?gclid=test123` to a landing-page URL, confirm the Conversion Linker fires in the Summary panel, then run `document.cookie` in the browser console and verify `_gcl_aw=GCL.timestamp.test123` is present. Per [Conversion linker - Tag Manager Help](https://support.google.com/tagmanager/answer/7549390), this cookie is what the conversion tag reads at attribution time.

<KnowledgeCheck
  question="An ad click lands on shop.example.com and the purchase completes on secure.payments-example.com. Where must the Conversion Linker fire, and with what cross-domain setting?"
  options={[
    "On shop.example.com with 'Enable linking across domains' listing secure.payments-example.com, plus a standard Conversion Linker on secure.payments-example.com",
    "Only on secure.payments-example.com on the order-confirmation page trigger",
    "On both domains with identical cross-domain settings listing each other as linked domains",
    "Only on shop.example.com — the confirmation page reads the gclid directly from the referrer URL"
  ]}
  correctIdx={0}
  explanation="The landing-page container appends the _gl linker parameter to outbound cross-domain links. The checkout-domain container reads the _gl parameter from the inbound URL and writes the _gcl_aw cookie. Both tags are required; only the landing-page tag needs the Auto Link Domains cross-domain configuration."
/>

## Stopping Duplicate Conversions

Thank-you pages can be revisited — users bookmark them, press back after receiving an email, or refresh after a timeout. Without protection, each visit fires the conversion tag again.

The primary defense is the **Transaction ID field** in the Google Ads Conversion Tracking tag. When Google Ads receives a conversion ping for a transaction ID it has already recorded for that conversion action, the duplicate is silently discarded server-side. Per [Use a transaction ID to minimize duplicate conversions](https://support.google.com/google-ads/answer/6386790), the ID must be unique per transaction, no longer than 64 characters, and must never contain PII.

A complementary trigger-level guard: use a **Custom Event trigger** (`event` = `purchase`) rather than a Page View trigger on the thank-you URL. The `purchase` dataLayer push executes once per order — the server embeds it in the confirmation page HTML at render time. A page-view trigger fires on every reload regardless of whether a new purchase occurred.

## Why Clean Conversions Power tROAS

Target ROAS Smart Bidding predicts the value of every potential conversion at auction time — bidding higher for users likely to generate high revenue, lower for low-value signals. The prediction model trains on the `value` parameter from every past conversion event your tags have sent.

Three failure modes collapse tROAS performance simultaneously. Missing values leave the model treating a €10 order identically to a €500 order. String-typed values recorded as zero teach the model that certain audiences are worth nothing, distorting every future bid. Duplicate conversions inflate the reported count, telling the model the campaign is performing better than it actually is and causing overspend relative to real revenue.

Per [About Target ROAS bidding](https://support.google.com/google-ads/answer/6268637), the strategy requires 15 conversions with valid revenue values in the past 30 days before it becomes available for Search and Shopping campaigns, and Google recommends 4 weeks of baseline data before activating it. [Value-based Bidding Best Practices](https://support.google.com/google-ads/answer/14792795) explicitly warns against mixing zero-value conversions into a value-based goal — it trains the model against itself.

---

## Hands-On Exercise

**Goal:** Implement a complete purchase conversion tracking setup on a staging e-commerce site and verify each layer end-to-end in GTM Preview Mode.

1. On the order-confirmation page, add a `dataLayer.push()` call with `event: 'purchase'`, a **numeric** `value`, an ISO 4217 `currency`, and a unique `transaction_id` sourced from server-rendered order data (not a placeholder).
2. In GTM, create three Data Layer Variables (Version 2): DLV - Transaction ID (`ecommerce.transaction_id`), DLV - Order Value (`ecommerce.value`), DLV - Currency (`ecommerce.currency`).
3. Create a Custom Event trigger: Event Name = `purchase`, exact match.
4. Create a Google Ads Conversion Tracking tag wired to all three variables. Use a real or sandbox Conversion ID and Label from a Google Ads test account.
5. Install a Conversion Linker tag on an All Pages trigger.
6. Open GTM Preview Mode. Load the confirmation page. Confirm: the Conversion Linker fires, the `purchase` event appears in the Summary panel, and the Conversion Tracking tag fires with correctly typed values for all three DLV fields.
7. Reload the page — the tag fires again. That is expected: Google Ads deduplicates via transaction ID server-side, not GTM.

**Success criteria:** DLV - Order Value resolves to a **number**, DLV - Transaction ID resolves to a unique non-empty string, DLV - Currency resolves to a valid ISO 4217 code.

---

Next, you'll deploy audience-building pixels for Google Ads Remarketing and Meta — mapping your dataLayer events to platform-specific standard events for cross-platform audience consistency. [[04-remarketing-pixels-meta-multi-platform.md]]
