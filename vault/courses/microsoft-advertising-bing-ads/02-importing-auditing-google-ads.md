---
chapter_num: 2
course_slug: microsoft-advertising-bing-ads
title: "Importing & Auditing Google Ads Campaigns into Microsoft Advertising"
status: g3-passed
last_updated: 2026-06-10
positions: []
duration_min: 22
vendor_tag: Microsoft Advertising
learning_objectives:
  - "Schedule a recurring Google Ads import using the Import Center"
  - "Configure PauseNewCampaigns, DeleteRemovedEntities, and other critical import flags"
  - "Identify and remediate the five most common import fidelity failures"
  - "Calibrate device bid modifiers for Bing's desktop-dominant audience"
  - "Verify import status and read item-level error logs in the Import Center"
sources:
  - url: "https://learn.microsoft.com/en-us/advertising/guides/google-ads-import?view=bingads-13"
    title: "Google Ads Import - Microsoft Advertising API"
  - url: "https://learn.microsoft.com/en-us/advertising/campaign-management-service/googleimportoption?view=bingads-13"
    title: "GoogleImportOption Data Object - Campaign Management - Microsoft Advertising API"
  - url: "https://about.ads.microsoft.com/en/blog/post/may-2026/new-import-center-and-other-product-news-for-may-2026"
    title: "New Import Center and Other Product News for May 2026 - Microsoft Advertising"
  - url: "https://blog.promonavigator.com/how-to-import-google-ads-campaigns-to-microsoft/"
    title: "How to Import Google Ads Campaigns to Microsoft (Bing) Advertising - PromoNavigator"
  - url: "https://affinco.com/bing-statistics/"
    title: "Bing Statistics 2026: Market Share & Advertising Insights - Affinco"
  - url: "https://learn.microsoft.com/en-ca/answers/questions/5879618/auto-import-reactivated-paused-campaigns-same-patt"
    title: "Auto-import reactivated paused campaigns - Microsoft Q&A"
owns:
  - "Import Center workflow: scheduled Google Ads import, import status verification"
  - "import audit checklist: paused items, missing ad extensions, bid strategy incompatibilities"
  - "post-import device bid modifier adjustments for desktop-heavy Bing audience"
  - "post-import match type adjustments for Microsoft auction environment"
  - "Import Center's post-import performance tips"
  - "import fidelity failures and remediation"
defers_to:
  - "platform UI navigation → ch1"
  - "keyword planning from scratch → ch3"
  - "audience layering and UET setup → ch4"
  - "Performance Max → ch5"
  - "conversion goal configuration → ch6"
  - "cross-platform budget allocation → ch7"
quiz_topics:
  - "steps to schedule a recurring Google Ads import"
  - "most common import breakage: paused ad extensions"
  - "device bid modifier adjustment rationale for Bing desktop share"
  - "bid strategy types that fail to import cleanly"
  - "how to verify import status in the Import Center"
notebooklm_source_focus:
  - "Microsoft Advertising Import Center 2026 documentation"
  - "common Google Ads to Microsoft Advertising import issues and fixes"
  - "Bing vs Google desktop/mobile traffic split 2026"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "When scheduling a recurring Google Ads import, what must you complete before choosing a frequency in the Import Center?"
    options:
      - "Pause all intended source campaigns in the Google Ads interface first"
      - "Create an Import Credential ID by authenticating with your Google account"
      - "Configure device bid modifiers for each campaign you plan to import"
      - "Set up a separate Microsoft Advertising billing method for import costs"
    correct_idx: 1
    explanation: "The Import Credential ID is an OAuth token that links your Microsoft Advertising user to the source Google account. Without it, the Import Center wizard cannot connect to Google Ads."
    section_anchor: scheduling-a-recurring-import
  - question: "Which ad extension types fail to transfer during a Google Ads import and must be built natively in Microsoft Advertising?"
    options:
      - "Sitelink extensions and callout extensions"
      - "Structured snippet extensions and price extensions"
      - "Image extensions and lead form extensions"
      - "Call extensions and location extensions"
    correct_idx: 2
    explanation: "Image extensions and lead form extensions are not importable from Google Ads. Sitelinks, callouts, structured snippets, call extensions, and most standard extension types do carry over."
    section_anchor: post-import-audit-checklist
  - question: "Why should mobile bid modifiers be reduced after importing Google Ads campaigns into Microsoft Advertising?"
    options:
      - "Microsoft's auction algorithm caps mobile bid adjustments at a lower maximum than Google"
      - "Bing's audience is desktop-dominant, so Google's mobile-optimized bids over-index on Bing's weakest device"
      - "Microsoft Advertising charges higher CPCs for mobile traffic than Google does"
      - "Imported mobile modifiers use a syntax incompatible with Microsoft's device targeting"
    correct_idx: 1
    explanation: "Bing's global mobile search share is ~0.8% versus desktop's ~12% globally and ~17.58% in the US. Google campaigns are typically tuned for a mobile-majority audience, so those bid adjustments directly over-spend on Microsoft's smallest device segment."
    section_anchor: device-bid-modifiers-calibrating-for-bings-desktop-audience
  - question: "What bid strategy does Microsoft Advertising silently assign to campaigns that used Google Smart Bidding strategies during import?"
    options:
      - "Target Impression Share"
      - "Maximize Clicks"
      - "Enhanced CPC"
      - "Target CPA"
    correct_idx: 2
    explanation: "When a Google Smart Bidding strategy (Target CPA, Target ROAS, Maximize Conversion Value) has no direct Microsoft equivalent, the import converts it to Enhanced CPC without surfacing the change in the error log."
    section_anchor: import-fidelity-failures-and-remediation
  - question: "After a scheduled import completes, where do you review item-level error details in Microsoft Advertising?"
    options:
      - "Check each campaign's status column in the main Campaigns grid view"
      - "Open the import in Import Center and click into the Errors count"
      - "Filter campaign reports by the date range matching the import run"
      - "Look in the Recommendations tab under Microsoft Advertising Tools"
    correct_idx: 1
    explanation: "The Import Center shows Added, Updated, Skipped, and Errors tallies per run. Clicking the Errors count opens inline, item-level resolution steps."
    section_anchor: post-import-audit-checklist
---

## Setting Up the Import Center Connection

The [New Import Center](https://about.ads.microsoft.com/en/blog/post/may-2026/new-import-center-and-other-product-news-for-may-2026) (launched May 2026) consolidates all Google Ads and Meta imports into a single searchable, filterable dashboard with inline error resolution. Before you can schedule anything, you need an **Import Credential ID** — an OAuth token that binds one Microsoft Advertising user to one Google account.

To create it: type "Import credential ID" in the Microsoft Advertising platform search bar, authenticate with the Google account that owns the source campaigns, and copy the resulting ID. This credential is scoped to your Microsoft Advertising user — if the user changes or the BingAdsImport App permission is revoked in Google, the credential breaks. Changing your Google password alone does not invalidate it.

With the credential ready, navigate to **Tools → Import → Import from Google Ads** or open the Import Center directly. Sign in with Google when prompted and select the correct manager or child account.

## Scheduling a Recurring Import

Name your import job clearly — for example, "Weekly Sync — US Search." Under **Schedule**, choose a frequency: **Auto** (Microsoft picks the optimal cadence), **Now**, **Once**, **Daily**, **Weekly**, or **Monthly**. For live accounts, Weekly is the standard starting cadence — it picks up Google changes without introducing hourly churn.

<KnowledgeCheck question="Which schedule option delegates the import cadence entirely to Microsoft Advertising?" options={["Now", "Once", "Auto", "Daily"]} correctIdx={2} explanation="'Auto' lets Microsoft's system determine when to pull changes for optimal sync quality. All other options require you to specify a fixed frequency or a one-time run." />

Before clicking **Import**, select **Advanced import options** — not the plain "Start import" button. The default path lets Microsoft apply its own preferences silently; the Advanced path gives you explicit control over every `GoogleImportOption` flag. This distinction matters because the flags that cause the most post-import damage all default to the wrong value for a cautious first run.

## Advanced Import Options That Matter

The most consequential flags, with their defaults:

| Flag | Default | Risk if you ignore it |
|------|---------|----------------------|
| `PauseNewCampaigns` | false | Imported campaigns launch immediately and start spending |
| `DeleteRemovedEntities` | false | Items deleted in Google stay active in Microsoft |
| `RaiseBidsToMinimum` | true | Keywords below $0.05 are auto-lifted to Microsoft's floor |
| `AdjustmentForCampaignBudgets` | 0% | Budgets transfer 1:1; may under-serve at Microsoft's CPCs |

For any first import, set `PauseNewCampaigns = Yes`. The [GoogleImportOption reference](https://learn.microsoft.com/en-us/advertising/campaign-management-service/googleimportoption?view=bingads-13) documents every flag in full. Treating the defaults as safe is the most common cause of day-one overspend.

<Callout type="warning">
`PauseNewCampaigns` defaults to **false**. On a first import, all new campaigns launch immediately and begin spending before any audit is complete. Always enable this flag in Advanced import options — it's the single highest-leverage safeguard on a first run.
</Callout>

## Post-Import Audit Checklist

After the import runs, open the Import Center, click the import name, and review the **Added / Updated / Skipped / Errors** tallies. Click into **Errors** for inline, item-level resolution steps. The May 2026 Import Center also surfaces tailored performance tips specific to your import results — read this panel before editing any campaign settings.

Work through this checklist in order:

1. **Campaign status** — Confirm intended campaigns are paused if you enabled `PauseNewCampaigns`.
2. **Bid strategies** — Any campaign using Google Smart Bidding now shows "Enhanced CPC." This is a silent conversion with no error log entry. Enhanced CPC does not optimize toward a conversion target; manually select Target CPA or Target ROAS after import.
3. **Ad extensions** — Sitelinks, callouts, and structured snippets import. Image extensions and lead form extensions do not — build these natively in Microsoft Advertising.
4. **Negative keyword match types** — Broad match negatives from Google become phrase match negatives in Microsoft. Exclusion scope narrows; queries that were blocked may now show ads. Review and supplement as needed.
5. **Tracking templates** — Replace Google-specific `{gclid}` parameters with `{msclkid}`.
6. **Audience lists** — Google remarketing lists do not transfer. Rebuild them in Microsoft after installing UET (covered in [[04-audience-targeting-linkedin-remarketing]]).

<KnowledgeCheck question="What happens to broad match negative keywords when they are imported from Google Ads?" options={["They import as broad match negatives", "They are dropped from the import entirely", "They are silently converted to phrase match negatives", "They are converted to exact match negatives"]} correctIdx={2} explanation="Microsoft Advertising cannot recreate broad match negatives, so they are converted to phrase match negatives during import. The blocking scope narrows, and previously excluded queries may begin triggering ads." />

## Device Bid Modifiers: Calibrating for Bing's Desktop Audience

Google campaigns are typically tuned for a mobile-first audience — Google's global mobile search share sits around 93%. [Bing's figures run the other direction: mobile share of roughly 0.8% globally, desktop at nearly 12% globally and approximately 17.58% in the US](https://affinco.com/bing-statistics/). Applying Google's mobile-uplifted bids unchanged on Microsoft means over-spending on the platform's weakest device channel.

Standard calibration after a first import:

- **Mobile**: reduce by −30% to −50% as a starting baseline
- **Desktop**: hold at 0% or test a +10–15% uplift to match the skewed audience
- **Tablet**: start at −20% as a conservative position

After three weeks, run a Segment → Device report and adjust modifiers until CPAs align across device types. `AutoDeviceBidOptimization` (defaults to false) can take over device bidding once the account has accumulated 30 days of conversion data — do not enable it on day one with no baseline.

## Import Fidelity Failures and Remediation

Two failure modes catch advertisers by surprise well after the initial import.

**The campaign reactivation trap.** You pause a Microsoft Advertising campaign in the UI. The next scheduled import runs and [overwrites that status from Google's active record — reactivating the campaign and restarting spend](https://learn.microsoft.com/en-ca/answers/questions/5879618/auto-import-reactivated-paused-campaigns-same-patt). The import job is the sync authority; your UI change does not persist. Fix: pause the campaign in Google Ads itself, or stop the import schedule before editing status in Microsoft.

**The silent bid strategy downgrade.** Google Smart Bidding strategies — Target CPA, Target ROAS, Maximize Conversion Value — have no 1:1 Microsoft equivalent. The [import converts them to Enhanced CPC with no error log entry](https://blog.promonavigator.com/how-to-import-google-ads-campaigns-to-microsoft/). Find affected campaigns by filtering to bid strategy type post-import, then manually assign the appropriate Microsoft smart bidding strategy and link it to a conversion goal. Conversion goal setup is covered in ch6.

---

## Hands-On Exercise

**Goal:** Import a single Google Ads campaign into Microsoft Advertising and complete the post-import audit.

**Steps:**

1. Generate an Import Credential ID: search "Import credential ID" in the Microsoft Advertising platform search bar and authenticate with the Google account that owns the source campaigns.
2. Navigate to **Tools → Import → Import from Google Ads**. Select one low-spend or paused test campaign.
3. Open **Advanced import options** and set: `PauseNewCampaigns = Yes`, `DeleteRemovedEntities = Yes`, `RaiseBidsToMinimum = Yes`. Schedule as **Once**.
4. Click **Import**. In the Import Center, confirm the job shows status "Scheduled" or "Completed."
5. Open the import results. Record the Errors count. Click into at least one error item and read its inline resolution steps.
6. Check the imported campaign's bid strategy. If the source used Smart Bidding, note the resulting strategy type and document what you would set it to manually.
7. Open **Device targeting**. Apply a −40% mobile modifier and hold desktop at 0%.

**Success criteria:** Import Center shows "Completed"; imported campaign is in a paused state; you can identify at least one audit finding — a missing extension, a match type conversion, or a bid strategy downgrade — that requires post-import remediation.

Next up: building keyword lists and Responsive Search Ads calibrated for Bing's distinct user demographic in [[03-keyword-strategy-rsa]].
