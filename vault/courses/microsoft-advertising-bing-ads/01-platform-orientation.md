---
chapter_num: 1
course_slug: microsoft-advertising-bing-ads
title: "Microsoft Advertising Platform Orientation: Interface, Account Structure & the Google Ads Migrant's Mindset"
status: awaiting-g0
duration_min: 15
vendor_tag: microsoft-advertising
learning_objectives:
  - "Identify the five levels of the Microsoft Advertising entity hierarchy and the hard capacity limits at each level"
  - "Configure account-level settings — time zone, currency, tracking template, and AutoTagType — correctly before any campaign goes live"
  - "Build a Search campaign skeleton end-to-end in the Microsoft Advertising UI"
  - "Articulate five structural differences between Microsoft Advertising and Google Ads that shape every campaign decision"
sources:
  - url: "https://learn.microsoft.com/en-us/advertising/guides/entity-hierarchy-limits?view=bingads-13"
    title: "Entity Limits — Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/guides/account-hierarchy-permissions?view=bingads-13"
    title: "Account Hierarchy and User Permissions — Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/guides/url-tracking-upgraded-urls?view=bingads-13"
    title: "URL Tracking with Upgraded URLs — Microsoft Advertising API | Microsoft Learn"
  - url: "https://learn.microsoft.com/en-us/advertising/customer-management-service/autotagtype?view=bingads-13"
    title: "AutoTagType Value Set — Customer Management — Microsoft Advertising API | Microsoft Learn"
  - url: "https://gs.statcounter.com/search-engine-market-share/desktop/united-states-of-america/"
    title: "Desktop Search Engine Market Share United States — StatCounter Global Stats"
  - url: "https://about.ads.microsoft.com/en/tools/productivity/copilot-in-microsoft-advertising"
    title: "Copilot in Microsoft Advertising Platform — Microsoft Advertising"
  - url: "https://learn.microsoft.com/en-us/advertising/guides/google-ads-import?view=bingads-13"
    title: "Google Ads Import — Microsoft Advertising API | Microsoft Learn"
owns:
  - "Microsoft Advertising UI navigation"
  - "account hierarchy (account → campaign → ad group → ad)"
  - "campaign-level and ad group-level settings setup"
  - "five structural differences vs Google Ads: network reach, auction mechanics, LinkedIn targeting (structural overview only), Copilot surfaces (structural overview only), import fidelity (structural overview only)"
  - "account-level settings: time zone, currency, tracking template, auto-tagging"
  - "Search campaign skeleton creation"
  - "Google Ads migrant's mental model"
defers_to:
  - "Import Center end-to-end import workflow → ch2"
  - "keyword research and Keyword Planner → ch3"
  - "LinkedIn Profile Targeting configuration and UET tag → ch4"
  - "Performance Max campaign creation → ch5"
quiz_topics:
  - "Microsoft Advertising account hierarchy levels"
  - "structural difference: LinkedIn profile targeting vs Google's audience approach"
  - "correct tracking template syntax for auto-tagging"
  - "where to find the Import Center in the UI"
  - "key auction mechanics difference between Bing and Google"
notebooklm_source_focus:
  - "Microsoft Advertising UI overview and account setup documentation"
  - "Google Ads vs Microsoft Advertising structural comparison 2026"
  - "Microsoft Advertising Copilot surfaces overview"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "How many levels does the Microsoft Advertising entity hierarchy have, counted from Manager Account down to Ad?"
    options:
      - "Three levels: Manager Account, Campaign, and Ad are the only tiers"
      - "Four levels: Account, Campaign, Ad Group, and Ad form the full hierarchy"
      - "Five levels: Manager Account, Account, Campaign, Ad Group, and Ad in sequence"
      - "Six levels, with a separate Asset entity sitting below the Ad level"
    correct_idx: 2
    explanation: "Microsoft Advertising uses five levels: Customer (Manager Account) → Advertiser Account → Campaign → Ad Group → Ad. There is no standalone Asset level in the standard hierarchy."
    section_anchor: the-microsoft-advertising-hierarchy
  - question: "How does LinkedIn Profile Targeting in Microsoft Advertising work compared to Google's audience targeting on Search?"
    options:
      - "It operates in target-and-bid mode, showing ads only to users who match the specified LinkedIn profile criteria"
      - "It operates in bid-only mode, raising bids for matching users without excluding users who do not match"
      - "It is available only on Audience Network campaigns and cannot be applied to standard Search campaigns at all"
      - "It targets users by hashed email address rather than by LinkedIn profile attributes like Job Function"
    correct_idx: 1
    explanation: "LinkedIn Profile Targeting works in bid-only (observation) mode — it adjusts bids upward for matching users but does not restrict ad delivery to those users alone. Non-matching users can still see the ads."
    section_anchor: five-structural-differences-vs-google-ads
  - question: "Which of the following is a valid account-level tracking template in Microsoft Advertising?"
    options:
      - "A plain query string like utm_source=bing that starts without http://, https://, or a landing-page placeholder"
      - "A string beginning with {lpurl}?utm_source=bing&utm_medium=cpc using the required landing-page placeholder"
      - "A string beginning with ftp://tracking.example.com, which uses a protocol Microsoft Advertising disallows"
      - "A string beginning with https:// but substituting {finalurl} instead of a recognized landing-page placeholder tag"
    correct_idx: 1
    explanation: "Account-level tracking templates must begin with http://, https://, {lpurl}, or {unescapedlpurl}, and must contain at least one landing-page placeholder such as {lpurl}. The ftp:// protocol is invalid, and {finalurl} is not a recognized placeholder."
    section_anchor: account-level-settings-lock-these-in-first
  - question: "Where in the Microsoft Advertising UI do you find the Import Center to import campaigns from Google Ads post-signup?"
    options:
      - "Campaigns → Shared Library → Import Center in the left navigation"
      - "Tools → Billing & Payments → Import under financial settings"
      - "Tools → Import → Import from Google Ads in the top navigation bar"
      - "Settings → Account → Import Center in account configuration section"
    correct_idx: 2
    explanation: "Post-signup, the Import Center is accessed via Tools → Import → Import from Google Ads. During initial account creation, an Import from Google shortcut appears at the foot of each signup page as well."
    section_anchor: five-structural-differences-vs-google-ads
  - question: "Which statement best describes Microsoft Advertising's Ad Rank formula compared to Google Ads as of late 2025?"
    options:
      - "Microsoft uses only the bid amount with no Quality Score component in its Ad Rank calculation at all"
      - "Microsoft uses Quality Score × Bid and gives exact-match keywords explicit tie-breaking priority since December 2025"
      - "Microsoft runs a first-price auction where the highest-bidding advertiser always wins the top position"
      - "Microsoft multiplies Quality Score by both Bid and Impression Share, making Impression Share the dominant factor"
    correct_idx: 1
    explanation: "Ad Rank in Microsoft Advertising is Quality Score × Bid — the same conceptual formula as Google. The December 2025 change added explicit auction tie-breaking priority for exact-match keywords, a distinction that does not exist in Google Ads."
    section_anchor: five-structural-differences-vs-google-ads
---

## The Microsoft Advertising Hierarchy

Microsoft Advertising organizes everything into five levels: **Customer (Manager Account) → Advertiser Account → Campaign → Ad Group → Ad**. If you come from Google Ads, the Customer level maps to a Google MCC — it holds billing authority and user permissions for all accounts beneath it. The Advertiser Account is where the payment instrument lives; campaigns draw budget from here.

The capacity limits matter for planning. According to [Microsoft's entity hierarchy documentation](https://learn.microsoft.com/en-us/advertising/guides/entity-hierarchy-limits?view=bingads-13), each account supports up to 10,000 campaigns, each campaign up to 20,000 ad groups, and each ad group up to 100 ads (active and paused combined), with a hard cap of 3 active Responsive Search Ads per ad group and 20,000 keywords per ad group. These ceilings rarely bind a standard advertiser but matter at agency scale.

One rule that trips up Google Ads migrants from day one: **bid strategies are set at the campaign level only.** Since April 2021, Microsoft Advertising does not support bid strategy assignment at the ad group or keyword level. You cannot apply Target CPA per ad group — set the strategy once per campaign and keep your ad groups tightly themed so the algorithm has clean signal to work with.

<KnowledgeCheck question="At which level can you assign a bid strategy in Microsoft Advertising?" options={["Campaign level only", "Ad group level only", "Both campaign and ad group level", "Keyword level with Enhanced CPC"]} correctIdx={0} explanation="Since April 2021, bid strategies can only be assigned at the campaign level. Ad group and keyword-level strategy assignment is not supported in Microsoft Advertising." />

## Account-Level Settings: Lock These In First

Two account settings are permanently locked after the first billing transaction: **time zone** and **currency**. Choose the wrong timezone during free-trial setup and your reporting never realigns without creating a new account. Set the time zone to your business's primary operating timezone and confirm the currency matches your Google Ads account if you plan to run both platforms in parallel.

The third setting to configure before any campaign goes live is the **tracking template**. At the account level, the template must include at least one landing-page URL placeholder — `{lpurl}`, `{unescapedlpurl}`, `{lpurl+2}`, `{lpurl+3}`, or `{escapedlpurl}` — and must begin with `http://`, `https://`, or the placeholder itself. The [URL Tracking with Upgraded URLs documentation](https://learn.microsoft.com/en-us/advertising/guides/url-tracking-upgraded-urls?view=bingads-13) specifies a maximum length of 2,048 characters. A reliable starting template for most advertisers:

```
{lpurl}?utm_source=bing&utm_medium=cpc&utm_campaign={CampaignName}&utm_term={KeyWord}&utm_content={AdId}&msclkid={msclkid}
```

Set this once at the account level and it covers every campaign automatically; override at campaign or ad group level only where you need different parameters, since lower levels take precedence.

Fourth, configure **UTM auto-tagging** via the `AutoTagType` setting. Three modes: `Inactive` (nothing appended), `Preserve` (append UTM tags without overwriting manually-added parameters), `Replace` (append and overwrite existing UTM values). `Preserve` is the safe default for accounts that already use custom UTM strings. Note that UTM auto-tagging and MSCLKID auto-tagging are **two separate toggles** — enabling one does not enable the other. MSCLKID feeds Microsoft Advertising's conversion tracking; UTM feeds GA4 and other analytics tools.

<Callout type="warning">
Time zone and currency lock permanently the moment your first billing transaction processes. Configure them before entering a payment method — there is no edit path afterward short of creating a new account.
</Callout>

<KnowledgeCheck question="Which AutoTagType value adds UTM parameters without overwriting existing custom tracking parameters in the URL?" options={["Inactive", "Preserve", "Replace", "Append"]} correctIdx={1} explanation="AutoTagType 'Preserve' appends standard UTM tags while leaving any manually-added tracking parameters intact. 'Replace' would overwrite existing supported UTM values." />

## Building Your First Search Campaign Skeleton

Navigate to **Campaigns → Create campaign** and select **Search** as the campaign type. The campaign form asks for budget type (Daily is the default and the easiest to control early on), bid strategy (start with Maximize Clicks until conversion data accumulates), location targeting, language, and ad distribution network.

The network toggle deserves attention: **Search Partners** extends your reach to Yahoo, AOL, DuckDuckGo, and Ecosia in addition to Bing. For an initial test, disable Search Partners so you can isolate pure Bing performance first — partner traffic quality varies by category and can distort early CPCs.

Inside the campaign, create at least one ad group with a tightly themed keyword set. Three to five exact-match terms aligned to a single user intent is the right starting size. Set a default CPC bid, then add at least one Responsive Search Ad placeholder — you will build out the full RSA with 15 headlines and 4 descriptions in [[03-keyword-strategy-rsa]]. The goal here is a working skeleton, not a finished creative.

## Five Structural Differences vs Google Ads

Reprogramming your Google Ads assumptions is half the work of launching on Microsoft Advertising. Here are the five structural differences that shape every decision.

**Network reach.** Microsoft Search Ads serve on Bing, Yahoo, AOL, DuckDuckGo, and Ecosia. [StatCounter's 2026 US desktop data](https://gs.statcounter.com/search-engine-market-share/desktop/united-states-of-america/) shows Bing at ~17.6% versus Google at ~76.3%. Smaller audience, but measurably less competition — CPCs run 30–42% lower than comparable Google Ads categories.

**Auction mechanics.** Ad Rank = Quality Score × Bid, with Quality Score a 1–10 composite of Expected CTR, Ad Relevance, and Landing Page Experience. The components match Google's, but the signal weights differ. As of December 2025, exact-match keywords receive explicit auction tie-breaking priority — a nuance without a Google equivalent.

**LinkedIn Profile Targeting.** Microsoft Advertising is the only platform other than LinkedIn itself that lets you layer LinkedIn profile attributes — Company, Industry, and Job Function — onto Search and Audience campaigns. It operates in **bid-only mode**: it raises bids for matching users but does not exclude others. Full configuration is covered in [[04-audience-targeting-linkedin-remarketing]].

**Copilot surfaces.** "Copilot" refers to two distinct things here. First, **Copilot in Microsoft Advertising** is the AI assistant embedded in the platform UI — it generates ad copy, images, and banners, runs campaign diagnostics, and surfaces performance root causes. Second, **Ads in Copilot** is a distribution channel: your campaigns can appear inside Bing Copilot conversations via an "ad voice" format, with no extra bid required — Performance Max campaigns are auto-eligible (see [[05-performance-max-setup]]). According to [Microsoft's Copilot advertising overview](https://about.ads.microsoft.com/en/tools/productivity/copilot-in-microsoft-advertising), Copilot reached 320 million MAUs in Q2 FY2026 (+148% YoY), and advertisers in Copilot placements see on average 18% more reach without additional CPC cost.

**Import fidelity.** The Import Center lives at **Tools → Import → Import from Google Ads** and pulls campaigns directly from Google via OAuth, with scheduled recurring imports available. The import is fast but not 1:1 — bid strategies without a Microsoft equivalent (e.g., Target Impression Share) revert to Manual CPC, and some ad extensions need manual re-association after import. The full import workflow and audit checklist are in [[02-importing-auditing-google-ads]].

<KnowledgeCheck question="How is Ad Rank calculated in Microsoft Advertising, and what changed in December 2025?" options={["Bid amount only — there is no Quality Score component in the Microsoft formula", "Quality Score × Bid, with exact-match keywords getting explicit tie-breaking priority since December 2025", "Quality Score × Bid × Impression Share percentage, making Impression Share the dominant factor", "CPC × CTR divided by Landing Page Experience, using a 1–5 scale instead of 1–10"]} correctIdx={1} explanation="Microsoft Advertising uses Quality Score × Bid — the same formula concept as Google Ads. As of December 2025, exact-match keywords also receive explicit auction tie-breaking priority, a distinction that does not exist in Google Ads." />

## Hands-on Exercise: Orient and Configure

**Scenario:** Set up a new Microsoft Advertising account for a travel agency and build a one-campaign skeleton.

1. Create or open an account. Before entering payment details, set the **time zone** to your business's primary timezone and **currency** to match your Google Ads account.
2. In **Account Settings**, add the tracking template: `{lpurl}?utm_source=bing&utm_medium=cpc&utm_campaign={CampaignName}&utm_term={KeyWord}&msclkid={msclkid}`.
3. Set **AutoTagType** to `Preserve`.
4. Create a Search campaign named `[Brand]_Search_Test_[Country]` with a $10 daily budget, Maximize Clicks bid strategy, and one target location. Disable Search Partners for now.
5. Add one ad group with three exact-match keywords relevant to your product.
6. Navigate to **Tools → Import** and confirm you can see the Import Center — but do not run an import yet.

**Success criteria:** Account settings saved without errors; tracking template passes the validation check; campaign and ad group appear in the Campaigns view with status Enabled; Import Center is accessible and shows the Google Ads import option.

Next chapter: [[02-importing-auditing-google-ads]] walks you through running and auditing the Google Ads import end-to-end.
