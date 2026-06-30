---
chapter_num: 5
course_slug: microsoft-advertising-bing-ads
title: "Performance Max on Microsoft Advertising: Setup, Asset Groups & AI Optimization"
status: g3-passed
duration_min: 22
vendor_tag: Microsoft Advertising
learning_objectives:
  - "Configure a PMax campaign with the correct bid strategy for purchase or lead-gen goals"
  - "Set weekly budgets that sustain the 2-4 week AI learning period without constraining delivery"
  - "Segment travel-vertical asset groups by product intent (domestic vs. international)"
  - "Meet compliant image and copy asset requirements for Microsoft PMax"
  - "Configure the New Customer Acquisition Goal in bid-only mode with a value uplift"
  - "Use the three PMax transparency reports to identify underperforming placements and refine search themes"
sources:
  - url: "https://learn.microsoft.com/en-us/advertising/guides/performance-max?view=bingads-13"
    title: "Performance Max Campaigns - Microsoft Advertising API"
  - url: "https://learn.microsoft.com/en-us/advertising/bulk-service/asset-group?view=bingads-13"
    title: "Asset Group Record - Bulk - Microsoft Advertising API"
  - url: "https://learn.microsoft.com/en-us/advertising/campaign-management-service/image?view=bingads-13"
    title: "Image Data Object - Campaign Management - Microsoft Advertising API"
  - url: "https://learn.microsoft.com/en-us/advertising/campaign-management-service/newcustomeracquisitiongoalsetting?view=bingads-13"
    title: "NewCustomerAcquisitionGoalSetting Data Object - Microsoft Advertising API"
  - url: "https://about.ads.microsoft.com/en/blog/post/may-2026/providing-more-transparency-for-your-performance-max-campaigns"
    title: "Providing more transparency for your Performance Max campaigns"
  - url: "https://about.ads.microsoft.com/en/blog/post/january-2026/performance-max-updates-and-other-product-news-for-january-2026"
    title: "January 2026 product updates - Microsoft Advertising"
  - url: "https://about.ads.microsoft.com/en/blog/post/november-2024/how-to-increase-conversions-with-performance-max-campaigns"
    title: "How to increase conversions from Performance Max"
  - url: "https://almcorp.com/blog/microsoft-performance-max-customer-acquisition-2026-guide/"
    title: "Microsoft Performance Max: New Customer Acquisition Goals & Advanced Visibility Features 2026"
  - url: "https://www.lunio.ai/blog/microsoft-performance-max-guide"
    title: "Microsoft Performance Max: Specs, setup and conversion tips"
owns:
  - "Performance Max campaign creation and goal configuration (purchase / lead-gen)"
  - "weekly budget sizing for the 2-4 week AI learning period"
  - "asset group structure for travel verticals (domestic flights vs international packages)"
  - "compliant creative asset requirements for PMax"
  - "new customer acquisition goal (open beta) and new-customer bid uplift"
  - "PMax transparency reports: Website URL, Landing Page, Search Term reports"
  - "search theme refinement in PMax"
  - "PMax underperforming placement identification"
defers_to:
  - "UET tag installation → ch4"
  - "conversion goal initial setup and diagnostics → ch6"
  - "budget split between platforms → ch7"
quiz_topics:
  - "duration of PMax AI learning period and budget sizing principles"
  - "how to segment PMax asset groups for travel products"
  - "new customer acquisition goal beta configuration"
  - "which PMax report identifies underperforming search placements"
  - "compliant image asset specs for Microsoft PMax"
notebooklm_source_focus:
  - "Microsoft Advertising Performance Max 2026 documentation"
  - "PMax transparency reports and search themes 2026"
  - "new customer acquisition goal in Microsoft PMax beta"
  - "asset group creative requirements Microsoft Advertising"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "How long does Microsoft PMax typically remain in AI learning mode after launch?"
    options:
      - "Two to four weeks, equivalent to roughly two to three conversion cycles"
      - "Twenty-four to forty-eight hours after the campaign's first ad impression"
      - "Exactly thirty calendar days, regardless of conversion volume or account size"
      - "There is no fixed learning period; PMax campaigns optimize continuously from launch"
    correct_idx: 0
    explanation: "PMax enters an AI learning period typically lasting 2-4 weeks or 2-3 conversion cycles (the time from click to conversion). During this window, the AI discovers which audience segments, placements, and creative combinations convert most efficiently. Campaigns with constrained budgets may stay in extended learning with volatile cost-per-acquisition."
    section_anchor: fueling-the-ai-the-2-4-week-learning-period
  - question: "Why should a travel OTA create separate PMax asset groups for domestic flights and international packages?"
    options:
      - "Microsoft requires advertisers to create a separate campaign for each destination category"
      - "Separate groups let the AI build distinct optimization signals per product type"
      - "Asset groups can only target users in a single geographic region"
      - "Domestic and international products must each use a different bid strategy"
    correct_idx: 1
    explanation: "Domestic and international buyers have different search intent, creative needs, and final URLs. Separate asset groups give the AI distinct training data per product segment, enabling better per-category optimization."
    section_anchor: asset-group-architecture-for-travel-verticals
  - question: "Which PMax transparency report shows the actual customer search queries that triggered your ads?"
    options:
      - "The Landing Page report, which shows performance by final URL"
      - "The Website URL (publisher) report, which shows performance by placement"
      - "The Impression Share report, which shows missed auction opportunities"
      - "The Search Term report, which shows actual user queries that matched"
    correct_idx: 3
    explanation: "The Search Term report (rolling out May 2026) shows actual user queries that triggered PMax ads. It is the primary tool for validating search themes and identifying candidates for negative keywords."
    section_anchor: transparency-reports-and-placement-optimization
  - question: "What are the minimum required image assets for a non-retail Microsoft PMax asset group?"
    options:
      - "Landscape (1.91:1, min 703×368 px) + square (1:1, min 300×300 px), both required"
      - "Landscape (1.91:1) only — the square image is optional for non-retail groups"
      - "Landscape (1.91:1), portrait (1:2), and square (1:1) — all three aspect ratios required"
      - "Any three images in valid aspect ratios, with no required format"
    correct_idx: 0
    explanation: "Non-retail PMax asset groups require at minimum one LandscapeImageMedia (1.91:1, min 703×368 px) and one SquareImageMedia (1:1, min 300×300 px). Additional aspect ratios improve placement coverage but are optional."
    section_anchor: compliant-creative-assets
  - question: "What does setting NewCustomerAcquisitionBidOnlyMode = true accomplish in a PMax NCA Goal?"
    options:
      - "Restricts ad delivery to users absent from the uploaded customer list"
      - "Bids higher for new customers while still showing ads to existing customers"
      - "Removes bid adjustments for all returning customers and sets bids to zero"
      - "Applies a uniform flat bid for both new and existing customers equally"
    correct_idx: 1
    explanation: "Bid-only mode (true) raises bids for identified new customers while still serving ads to existing ones. Exclusive mode (false) restricts delivery to new customers only, which severely limits reach and is not the recommended default."
    section_anchor: new-customer-acquisition-goal
---

Performance Max (PMax) is Microsoft Advertising's unified AI-driven campaign type — one campaign, one budget, and one creative supply chain served across search, display, native, shopping, and Copilot inventory simultaneously. It reached open beta worldwide in mid-2026, making it available to any qualifying account without allowlisting. If you have run Google's PMax, the model is familiar; this chapter covers Microsoft's specific implementation, where asset group design and three new transparency reports create meaningful operational differences.

## Creating Your First PMax Campaign

Create a PMax campaign by selecting **Campaign type: Performance Max** in the Microsoft Advertising UI. You must choose exactly one bid strategy: **Maximize Conversion Value** (with an optional Target ROAS) for purchase goals where transactions vary in size, or **Maximize Conversions** (with an optional Target CPA) for lead-gen goals where each conversion has roughly equal value. Do not add a Target ROAS or Target CPA at launch — efficiency constraints before the AI has enough data produce volatile delivery.

PMax campaigns do not support shared budgets; each requires its own daily budget. UET tag installation is covered in [[04-audience-targeting-linkedin-remarketing]]; conversion goal initial setup is covered in [[06-conversion-tracking-enhanced]].

<KnowledgeCheck question="Which two bid strategies are available exclusively for Microsoft Advertising PMax campaigns?" options={["Maximize Conversions and Maximize Conversion Value only", "Manual CPC and Enhanced CPC only", "Target CPA, Target ROAS, or Manual CPC", "Any bid strategy available for standard Search campaigns"]} correctIdx={0} explanation="PMax campaigns support only Maximize Conversions (with optional Target CPA) and Maximize Conversion Value (with optional Target ROAS). No other bid strategies are permitted." />

## Fueling the AI: The 2-4 Week Learning Period

PMax enters a [learning period of two to four weeks after launch](https://about.ads.microsoft.com/en/blog/post/november-2024/how-to-increase-conversions-with-performance-max-campaigns) — or approximately 2-3 conversion cycles (the time from first click to conversion). During this window, the AI is discovering which audience segments, placements, and creative combinations convert. Starving the campaign of budget during this phase risks extended learning with volatile cost-per-acquisition.

For a travel OTA at a $100 average booking value, a $150 daily budget gives the AI room to accumulate consistent weekly conversions without being starved of signal. Wait until 30+ conversions have accumulated before layering in a Target ROAS or Target CPA constraint.

<Callout type="warning">
Adding a Target ROAS or Target CPA before accumulating 30+ conversions forces the campaign to constrain its own delivery while still learning. The result is low impressions, unpredictable CPAs, and a self-defeating cycle where the campaign can't convert because it can't spend freely enough to reach customers.
</Callout>

## Asset Group Architecture for Travel Verticals

The [[asset-group]] replaces the traditional ad group inside PMax. Each group holds all creative assets — headlines, descriptions, images, logos, final URLs — plus up to 50 search themes and one optional audience group. The AI dynamically assembles ads from these assets for every eligible placement.

For a travel OTA, the right architecture separates groups by product intent. Domestic flight buyers and international package buyers have distinct search signals, respond to different creative, and convert on different landing pages. A "Domestic Flights" group routes to `flyease.com/flights/domestic`, uses search themes like *"book last-minute domestic flight"* and *"compare cheap US flights,"* and shows terminal or airport photography. An "International Packages" group routes to `flyease.com/packages/international`, uses themes like *"Europe vacation packages"* and *"international flight and hotel deals,"* and features destination lifestyle imagery.

[Microsoft recommends against over-segmenting at launch](https://about.ads.microsoft.com/en/blog/post/november-2024/how-to-increase-conversions-with-performance-max-campaigns). Starting with 10+ asset groups dilutes conversion data, leaving each group with insufficient weekly conversions to exit learning mode reliably. Start with two to four groups and subdivide only after each reaches steady weekly conversion volume.

<KnowledgeCheck question="Why should a travel OTA create separate PMax asset groups for domestic flights and international packages?" options={["Microsoft requires advertisers to create a separate campaign for each destination category", "Separate groups let the AI build distinct optimization signals per product type", "Asset groups can only target users in a single geographic region", "Domestic and international products must each use a different bid strategy"]} correctIdx={1} explanation="Domestic and international buyers have different search intent, creative needs, and final URLs. Separate asset groups give the AI distinct training data per product segment, enabling better per-category optimization." />

## Compliant Creative Assets

Every non-retail PMax asset group requires at minimum: three to fifteen headlines (30 characters each), one to five long headlines (90 characters), two to five descriptions (90 characters), one **LandscapeImageMedia** at 1.91:1 ratio (min 703×368 px), and one **SquareImageMedia** at 1:1 (min 300×300 px). [The Asset Group Bulk Record documentation](https://learn.microsoft.com/en-us/advertising/bulk-service/asset-group?view=bingads-13) details additional optional aspect ratios — adding portrait and wide formats improves ad coverage across display and native surfaces.

Image files must be under 5 MB. JPEG is the preferred format — [PNG uploads are accepted but auto-converted to JPEG by Microsoft's servers](https://learn.microsoft.com/en-us/advertising/campaign-management-service/image?view=bingads-13), which can introduce quality loss on images with fine gradients or text overlays. Export as JPEG directly. Provide as many asset variants as possible: 15 headlines and 5 descriptions give the AI far more combinatorial options than the three-and-two minimums.

## New Customer Acquisition Goal

The New Customer Acquisition (NCA) Goal is in open beta for purchase-goal PMax campaigns. It adds a `NewCustomerAcquisitionGoalSetting` to the campaign, using your uploaded CRM customer list to classify converters as new or returning and applying a bid uplift for new-customer conversions.

Two modes exist. **Bid-only mode** (`NewCustomerAcquisitionBidOnlyMode = true`) bids higher for new customers while still serving ads to existing ones — the right default for most travel advertisers who want incremental reach without restricting their audience. **Exclusive mode** (`false`) shows ads only to users not on your customer list, which severely limits reach and should be reserved for campaigns explicitly targeting acquisition over retention.

Set `AdditionalConversionValue` to roughly 30% above your average order value. [ALM Corp's 2026 NCA guide](https://almcorp.com/blog/microsoft-performance-max-customer-acquisition-2026-guide/) recommends a $130 uplift signal on a $100 AOV booking, training the AI to value new-customer conversions more highly. Refresh your CRM customer list weekly — stale lists cause returning customers to be mislabeled as new, inflating acquisition costs without delivering genuine new bookings.

## Transparency Reports and Placement Optimization

Microsoft released three PMax transparency reports in [May 2026](https://about.ads.microsoft.com/en/blog/post/may-2026/providing-more-transparency-for-your-performance-max-campaigns), giving advertisers meaningful visibility into where and why PMax budget is being spent:

- **Website URL (publisher) report** — breaks down spend, clicks, and conversions by placement URL. Use it to identify which network surfaces are absorbing budget without converting (e.g., gaming content sites with no travel intent).
- **Landing Page report** — shows performance by final URL, revealing whether Final URL Expansion is routing users to off-topic pages instead of the booking form.
- **Search Term report** — the newest report (rolling out May 2026), shows the actual customer queries that triggered your PMax ads. This is the primary tool for identifying irrelevant query traffic and informing search theme refinements.

To find underperforming placements, filter the Website URL report for spend and ROAS below your target across multiple weeks. Add underperformers to a campaign-level placement exclusion list. The May 2026 guidance warns against excluding placements during the first two to four weeks — early exclusions interrupt the AI's ability to discover where conversions occur.

## Search Theme Refinement

Search themes are optimization signals, not keywords. The AI is not required to match them literally — they guide the optimizer toward relevant query territory. Since the [January 2026 update](https://about.ads.microsoft.com/en/blog/post/january-2026/performance-max-updates-and-other-product-news-for-january-2026), each asset group now supports up to 50 search themes, doubled from the previous 25-theme limit.

Use the Search Term report to drive refinement. Export queries with 10+ impressions and zero conversions, group by intent (booking, research, off-topic), and update themes to reinforce purchase signals. Removing a theme does not block a query — for hard exclusions, add self-serve negative keywords (available since 2026).

## Hands-On Exercise: Launch a Two-Asset-Group PMax Campaign

**Objective:** Build a two-asset-group PMax campaign for a travel OTA and verify all three transparency reports return data.

**Steps:**
1. Create a **Performance Max** campaign with **Maximize Conversions** bid strategy and a daily budget sized for consistent weekly conversions during the learning period.
2. Build **AG_DomesticFlights**: 5+ headlines, 2+ descriptions, landscape image (1.91:1, ≥703×368 px), square (1:1, ≥300×300 px), 5-10 booking-intent themes.
3. Build **AG_InternationalPkgs** with destination-specific creative and themes.
4. Do not add Target ROAS or Target CPA. Note the campaign launch date.
5. After seven days, open **Reports → Performance Max** and verify all three reports return populated rows.

**Success criteria:** Both asset groups active, 5+ conversions in week 1, all three transparency reports populated.

Next up — conversion goals that feed PMax and standard Search campaigns with accurate attribution: [[06-conversion-tracking-enhanced]].
