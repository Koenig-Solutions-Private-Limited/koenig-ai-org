---
chapter_num: 4
course_slug: microsoft-advertising-bing-ads
title: "Audience Targeting: In-Market Segments, LinkedIn Profile Targeting & Remarketing"
status: g3-passed
duration_min: 10
vendor_tag: microsoft-advertising
learning_objectives:
  - "Install and validate a UET tag using UET Tag Helper for real-time firing confirmation"
  - "Configure in-market audience segments and LinkedIn Profile Targeting in Bid Only mode for travel campaigns"
  - "Build a dynamic cart-abandoner remarketing list with correct pagetype and prodid parameters"
  - "Apply and calculate bid adjustments across Search and Audience Network campaigns"
sources:
  - url: "https://learn.microsoft.com/en-us/advertising/guides/universal-event-tracking?view=bingads-13"
    title: "Universal Event Tracking - Microsoft Advertising API | Microsoft Learn"
  - url: "https://about.ads.microsoft.com/en/blog/post/november-2023/ad-targeting-for-travel-and-credit-card-advertisers"
    title: "Ad targeting for travel and credit card advertisers | Microsoft Advertising"
  - url: "https://about.ads.microsoft.com/en/blog/post/march-2022/reach-specific-audiences-with-linkedin-profile-targeting"
    title: "Reach specific audiences with LinkedIn Profile Targeting | Microsoft Advertising"
  - url: "https://learn.microsoft.com/en-us/advertising/guides/show-ads-target-audience?view=bingads-13"
    title: "Show Ads to Your Target Audience - Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/guides/audience-ads?view=bingads-13"
    title: "Audience Ads - Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/xandr/invest/microsoft-in-market-audiences"
    title: "Microsoft Invest - In-Market Audiences | Microsoft Learn"
owns:
  - "Universal Event Tracking (UET) tag: installation, verification, and firing validation"
  - "in-market audience segments for travel intent"
  - "observation mode vs bid-only audience application"
  - "LinkedIn Profile Targeting: configuration by job function and industry for business traveler segments"
  - "UET-based remarketing list creation (cart-abandoners)"
  - "bid adjustments for Search and Audience Network campaigns"
  - "Audience Network campaign audience layering"
defers_to:
  - "conversion goal creation → ch6"
  - "Performance Max audience signals → ch5"
  - "cross-platform audience analysis → ch7"
quiz_topics:
  - "UET tag firing validation method"
  - "difference between observation mode and bid-only audience targeting"
  - "LinkedIn targeting dimensions available in Microsoft Advertising"
  - "correct bid adjustment range for cart-abandoner remarketing lists"
  - "which audience types work on Audience Network vs Search only"
notebooklm_source_focus:
  - "Microsoft Advertising UET tag setup and verification 2026"
  - "LinkedIn Profile Targeting in Microsoft Advertising documentation"
  - "in-market audience segments for travel vertical"
  - "Microsoft Audience Network targeting options"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "What is the fastest way to confirm a UET tag is firing without waiting for in-platform status?"
    options:
      - "Check Tag Status in Microsoft Advertising; it updates hourly as Active or Inactive"
      - "Open UET Tag Helper in Edge or Chrome; a green badge with count ≥ 1 confirms firing"
      - "Submit a support request and wait for Microsoft Advertising to confirm tag data receipt"
      - "Use the Diagnostics panel to trigger a manual conversion tag fire test event"
    correct_idx: 1
    explanation: "UET Tag Helper provides real-time in-browser validation. In-platform Tag Status only updates after 24 hours of customer activity data."
    section_anchor: "installing-and-verifying-the-uet-tag"
  - question: "In Microsoft Advertising, what does 'Bid Only' mode do when associated with an audience?"
    options:
      - "Restricts ad delivery only to users who are members of the associated audience segment"
      - "Applies the bid adjustment to audience members while still showing ads to all eligible users"
      - "Doubles the base bid for all users in the campaign regardless of audience membership"
      - "Limits audience delivery to the Microsoft Audience Network rather than the Search network"
    correct_idx: 1
    explanation: "Bid Only (Google Ads equivalent: 'Observation') preserves full keyword-based reach while applying the bid adjustment only when a user also qualifies for the audience."
    section_anchor: "bid-only-vs-target-and-bid-choosing-your-mode"
  - question: "Which three dimensions can be targeted using LinkedIn Profile Targeting in Microsoft Advertising?"
    options:
      - "Job Title, Seniority, and Skills"
      - "Company, Industry, and Job Function"
      - "Location, Age, and Job Function"
      - "Education Level, Company Size, and Industry"
    correct_idx: 1
    explanation: "LinkedIn Profile Targeting in Microsoft Advertising offers Company (80,000+ options), Industry (148 options), and Job Function (26 options) drawn from LinkedIn's professional graph."
    section_anchor: "linkedin-profile-targeting-for-business-travelers"
  - question: "What is the full allowed bid adjustment range for audience associations in Microsoft Advertising?"
    options:
      - "-50% to +300%"
      - "-90% to +500%"
      - "-100% to +900%"
      - "-100% to +300%"
    correct_idx: 2
    explanation: "Microsoft Advertising allows audience bid adjustments from -100% (which fully suppresses an audience) to +900%. A new association defaults to +15%."
    section_anchor: "bid-adjustments-for-search-and-audience-network-campaigns"
  - question: "Which statement correctly describes Audience campaign network delivery versus Search campaigns?"
    options:
      - "Search campaigns run on both Search and Audience Network by default; Audience campaigns run on Search only"
      - "Audience campaigns run only on the Audience Network; Search campaigns extend there via image ad extensions"
      - "Both campaign types share the same delivery network but use distinct bidding models"
      - "Audience campaigns start on Search and expand to the Audience Network after 30 days"
    correct_idx: 1
    explanation: "Audience campaigns (CampaignType = Audience) are exclusive to the Microsoft Audience Network. Search campaigns can extend there only by adding image ad extensions."
    section_anchor: "layering-audiences-on-the-audience-network"
---

## Installing and Verifying the UET Tag

Before you can build remarketing lists or layer audience signals onto campaigns, the Universal Event Tracking (UET) tag must fire on every page of your site. Create one tag in Microsoft Advertising (Tools → UET tag → Create new), copy the JavaScript snippet, and paste it into your site's global `<head>` template. One tag, site-wide — multiple tags cause duplicate event counts.

Validation does not require a 24-hour wait. Install the **UET Tag Helper** browser extension for Edge or Chrome, then open your site. The extension shows a badge count of UET requests fired on the current page; a green badge with count ≥ 1 means the tag is firing correctly. Red or yellow signals a JavaScript error, script conflict, or ad blocker interference — open the browser console to diagnose.

After 24 hours of live traffic, Microsoft Advertising reports tracking status as either **"Tag active"** or **"Tag inactive."** An inactive status means no customer data has been received. Verify the snippet is in the rendered HTML and not suppressed by a Content Security Policy or tag manager misconfiguration.

<KnowledgeCheck
  question="After UET Tag Helper shows a green badge on your site, what in-platform check confirms receipt after 24 hours?"
  options={["'Tag active' status in Tools → UET tags", "A confirmed conversion event in the Conversions report", "An audience list showing at least 1 user member", "A green indicator on the All Campaigns dashboard"]}
  correctIdx={0}
  explanation="In-platform Tag Status confirms that Microsoft received customer activity from the tag. UET Tag Helper confirms in-browser firing; Tag Status confirms server-side receipt after 24 hours."
/>

## In-Market Audience Segments for Travel Intent

In-market audiences are Microsoft-curated segments built from Bing search queries, ad clicks, and Microsoft property page views. You cannot create or edit these lists — you associate them with campaigns and set bid adjustments. They are available in [90+ markets globally](https://learn.microsoft.com/en-us/xandr/invest/microsoft-in-market-audiences).

For travel campaigns, prioritize: **Travel - Air Travel**, **Travel - Hotels & Resorts**, **Travel - Vacation Packages**, and **Travel - Car Rentals**. According to [Microsoft Advertising travel targeting data](https://about.ads.microsoft.com/en/blog/post/november-2023/ad-targeting-for-travel-and-credit-card-advertisers), 75% of travel credit card shoppers are associated with an in-market audience category, and combined travel and credit card audience targeting delivers a 4.2x CTR lift and 6.7x conversion rate lift versus unaudited baseline.

One hard platform constraint: in-market audiences cannot be added to Combined Lists. To build a "travel in-market AND past visitor" audience, apply both audiences separately to the same ad group rather than attempting a combined list.

## Bid Only vs Target and Bid: Choosing Your Mode

Every audience association uses one of two delivery modes:

- **Bid Only** (Google Ads equivalent: "Observation"): ads show to all users meeting campaign criteria; the bid adjustment applies only to those who are also audience members. Full reach, refined bidding.
- **Target and Bid**: ads deliver *only* to users who are members of the associated audience. Use this when the audience is large and you have conversion evidence.

<Callout type="warning">
Launching a new in-market association in Target and Bid mode will quietly throttle your traffic without your noticing. Always start in Bid Only, collect 2–4 weeks of conversion data, then graduate high-performing segments to Target and Bid.
</Callout>

New audience associations default to a **+15% bid adjustment** — replace this immediately with a deliberate value calibrated to the segment's conversion premium.

<KnowledgeCheck
  question="An in-market travel audience is associated with a search campaign in Bid Only mode at +30%. Which users receive ads?"
  options={["Only in-market audience members, at a +30% higher bid", "All users meeting campaign criteria; in-market members receive a +30% higher bid", "All users at a +30% higher bid regardless of audience membership", "Only in-market audience members, at the base bid"]}
  correctIdx={1}
  explanation="Bid Only preserves full campaign reach. The +30% adjustment applies on top of the base bid only when a user is also a member of the in-market audience."
/>

## LinkedIn Profile Targeting for Business Travelers

Microsoft Advertising is the only non-LinkedIn advertising platform with access to LinkedIn profile data for targeting. Three dimensions are available per the [LinkedIn Profile Targeting announcement](https://about.ads.microsoft.com/en/blog/post/march-2022/reach-specific-audiences-with-linkedin-profile-targeting):

- **Job Function** — 26 options including Purchasing, Operations, Sales, and Supply Chain & Logistics
- **Industry** — 148 options including Airlines/Aviation, Hospitality, and Transportation
- **Company** — 80,000+ companies; up to 1,000 per campaign across up to 20 ad groups

For a corporate travel management company targeting procurement officers, configure Job Function = "Purchasing" + "Operations" and Industry = "Airlines/Aviation" + "Hospitality" in Bid Only mode. After 30 days, run the Professional Demographics report to identify which dimension combinations convert, then shift top performers to Target and Bid.

Watch for `PrivacyStatus = Inactive` when stacking all three dimensions narrowly on an Audience campaign. When the intersection is too small for compliant delivery, no ads serve. Broaden one dimension — typically the company list — until PrivacyStatus returns to Active.

## Building a Cart-Abandoner Remarketing List

The base UET tag records page visits but cannot classify them by intent. To build a cart-abandoner list, the booking cart page must also fire custom parameters alongside the base tag:

```js
window.uetq = window.uetq || [];
window.uetq.push({'pagetype': 'cart', 'prodid': 'hotel-SKU-123'});
```

Create the audience in Microsoft Advertising via Audiences → Dynamic Remarketing → **Shopping cart abandoners** as the Page Type. Set membership duration to 30 days. The list activates once it reaches 1,000 users. Cart abandoners on travel bookings typically justify a bid adjustment of **+50% to +100%** — well above the platform default of +15%.

If the list populates as "general visitors" instead of cart abandoners, the `pagetype` parameter is missing or firing on the wrong page. Verify with UET Tag Helper on the cart page specifically: both the base tag and the custom event must fire. Conversion goal linking is covered in chapter 6 — this chapter owns tag installation and remarketing list creation only.

## Bid Adjustments for Search and Audience Network Campaigns

Audience bid adjustments in Microsoft Advertising range from **-100% to +900%**. Adjustments from multiple criterion types multiply rather than add: a +50% audience adjustment combined with a +20% device adjustment yields approximately +80% combined, not +70%.

Practical starting points for travel campaigns: +20%–+30% for in-market audience observation, +50%–+100% for cart-abandoner lists, +15%–+25% for LinkedIn professional segments during the data-gathering phase.

To fully suppress a segment, use audience **exclusions** (negative audience associations) rather than a low bid adjustment. Setting -90% still permits delivery at a steeply discounted bid; only -100% or a hard exclusion prevents delivery to that audience entirely. Use exclusions for audiences that generate consistently irrelevant traffic.

## Layering Audiences on the Audience Network

Audience campaigns (`CampaignType = Audience`) run exclusively on the Microsoft Audience Network — MSN, Microsoft Outlook, Microsoft 365, and Microsoft Casual Games — and never appear in standard search results. Standard search campaigns cannot reach the Audience Network without image ad extensions.

For a travel prospecting Audience campaign, layer an in-market travel segment (+25%), LinkedIn Job Function = Operations + Sales (+15%), and LinkedIn Industry = Airlines/Aviation + Hospitality (+15%). Upload landscape-wide plus three additional image aspect ratios for maximum placement eligibility. Once the audience pool is validated and large, switch the ad group to Target and Bid to restrict delivery to users matching at least one of the layered criteria.

---

## Hands-On Exercise: UET to Cart-Abandoner in One Session

**Goal:** Install UET, validate firing in-browser and in-platform, and create a cart-abandoner remarketing list ready for campaign association.

1. In Microsoft Advertising, go to Tools → UET tag → Create new. Name it descriptively (e.g., "Brand-Global-UET"). Copy the snippet.
2. Add the snippet to your site's global `<head>` template. Open UET Tag Helper in Edge or Chrome on your homepage — confirm a green badge with count ≥ 1.
3. On your booking cart page, add the custom event push (`pagetype: 'cart'`, `prodid: '[SKU]'`) alongside the base UET tag. Confirm UET Tag Helper shows an additional event on this page.
4. In Microsoft Advertising: Audiences → Dynamic Remarketing → Shopping cart abandoners. Membership duration: 30 days.
5. Associate the audience with your primary search ad group: Mode = **Bid Only**, bid adjustment = **+70%**.
6. After 24 hours, confirm Tools → UET tags shows "Tag active."

**Success criteria:** Tag status is active; cart-abandoner list exists and shows "Populating" or a user count; the ad group association shows Bid Only with +70% adjustment.

Chapter 5 builds on this UET foundation — [[05-performance-max-setup]] covers Performance Max campaign creation, asset groups for travel verticals, and how PMax configures its own audience signals independently of the remarketing lists you created here.
