---
chapter_num: 5
course_slug: technical-seo-fundamentals
title: "Link Strategy: Earning, Auditing & Disavowing Backlinks"
status: g3-passed
last_updated: 2026-06-11
duration_min: 25
vendor_tag: ahrefs
learning_objectives:
  - "Export and interpret a backlink profile in Ahrefs and SEMrush: referring domains, anchor text distribution, and domain quality proxies"
  - "Detect anchor text over-optimization and link velocity anomalies before they become ranking liabilities"
  - "Construct a correctly formatted disavow file and submit it via Google Search Console"
  - "Identify high-priority link-earning opportunities using competitor backlink gap analysis and OTA-specific channels"
  - "Build a 90-day link acquisition campaign with tiered target sites and a documented outreach cadence"
sources:
  - url: "https://support.google.com/webmasters/answer/2648487"
    title: "Disavow links to your site - Google Search Console Help"
  - url: "https://ahrefs.com/blog/backlink-audit/"
    title: "How to Do a Basic Backlink Audit (in Under 30 Minutes)"
  - url: "https://ahrefs.com/blog/toxic-backlinks/"
    title: "Toxic Backlinks: SEO Woe or a Load of Baloney? - Ahrefs"
  - url: "https://www.semrush.com/kb/965-toxic-markers-description"
    title: "What do all of the Toxic Markers in Backlink Audit mean? - Semrush KB"
  - url: "https://www.semrush.com/kb/773-backlink-gap"
    title: "Backlink Gap - Semrush KB"
  - url: "https://www.reporteroutreach.com/blog/digital-pr-link-building"
    title: "Digital PR Link Building: The Complete Guide for 2026 - Reporter Outreach"
  - url: "https://searcharoo.com/link-building-for-travel-websites/"
    title: "Link Building for Travel Websites: Effective Strategies - Searcharoo"
owns:
  - "backlink profile export in Ahrefs and SEMrush: referring domains, anchor text distribution, domain authority/rating"
  - "spam score analysis: Moz Spam Score, Ahrefs domain rating as quality proxy"
  - "anchor text over-optimization detection and natural anchor ratio benchmarks"
  - "link velocity anomalies: sudden spikes and their algorithmic risk"
  - "disavow file format (domain: prefix, .txt, comment syntax) and Google Search Console disavow submission"
  - "disavow decision rationale documentation: criteria for inclusion"
  - "link-earning opportunity identification: resource page prospecting, digital PR angles, competitor backlink gap analysis"
  - "travel/OTA-specific link-earning channels: tourism boards, travel bloggers, destination guides"
  - "outreach template structure and personalization principles"
  - "90-day link acquisition campaign plan with target site tiers and acquisition timeline"
defers_to:
  - "internal linking and link equity distribution → ch4"
  - "on-page signals that affect rankings alongside links → ch4"
  - "technical crawl issues that dilute link equity → ch1 and ch2"
  - "developer handoff for link-related fixes like redirect consolidation → ch6"
quiz_topics:
  - "disavow file correct format: domain-level vs URL-level entries and the 'domain:' prefix"
  - "three anchor text patterns that signal over-optimization to Google's algorithm"
  - "how to identify a link velocity anomaly in Ahrefs' referring domain graph"
  - "two OTA-specific link-earning channels suited to a travel brand"
  - "minimum data points needed to justify a domain disavow decision"
notebooklm_source_focus:
  - "Google Search Console disavow links tool documentation 2026"
  - "Ahrefs backlink audit and disavow workflow guide"
  - "SEMrush backlink audit toxic score methodology"
  - "link-earning strategies for travel and OTA vertical 2026"
  - "digital PR link building techniques and outreach templates"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which disavow file entry correctly instructs Google to ignore all links from an entire domain and its subdomains?"
    options:
      - "spammydomain.com"
      - "domain:spammydomain.com"
      - "disavow:spammydomain.com"
      - "*.spammydomain.com"
    correct_idx: 1
    explanation: "The 'domain:' prefix covers the root domain and all subdomains. A bare URL entry applies to that single page only. Subpath wildcards are not supported. 'domain:spammydomain.com' is the correct domain-level format."
    section_anchor: the-disavow-file-format-submission-and-rationale
  - question: "A backlink profile shows 14% exact-match anchors, 22% branded, and 19% partial-match. Which category is in the over-optimization danger zone?"
    options:
      - "Partial-match at 19% — above the 15–25% recommended ceiling"
      - "Exact-match at 14% — above the 10% algorithmic risk threshold"
      - "Branded at 22% — below the 30–50% recommended floor"
      - "Generic anchors are the primary Penguin-era over-optimization signal"
    correct_idx: 1
    explanation: "The safe ceiling for exact-match anchors is 1–5% of the referring-domain profile. Exceeding 10% enters the danger zone associated with Penguin-era penalties. Branded at 22% is under-optimized but not a penalty risk; partial-match at 19% is within range."
    section_anchor: anchor-text-over-optimization
  - question: "In Ahrefs Site Explorer, what is the primary visual indicator for a link velocity anomaly?"
    options:
      - "The Top Pages report sorted by Referring Domains descending"
      - "The Anchors report filtered to Exact Match entries"
      - "The Referring Domains graph plotting the daily domain acquisition rate"
      - "The Backlinks report filtered to Dofollow and sorted by DR ascending"
    correct_idx: 2
    explanation: "The Referring Domains graph shows new domain acquisition rate over time. A sudden vertical spike is the primary trigger. You then filter to 'New' referring domains in the spike's date range and sort by DR ascending to assess quality."
    section_anchor: link-velocity-anomalies
  - question: "Which two link-earning channels are most specific to travel and OTA brands seeking editorial, high-authority links?"
    options:
      - "Tourism board resource pages and destination guide features in major travel media"
      - "SaaS review aggregators and technology press release distribution services"
      - "Social media influencer bio links and YouTube channel description links"
      - "Forum signature links and travel community profile directory pages"
    correct_idx: 0
    explanation: "Tourism boards (DR 50–80) maintain 'official partner' resource pages accessible to licensed operators. Major travel media (Lonely Planet, BBC Travel, Condé Nast Traveler) run 'best operators' destination features where original data or exclusive photography earns a placement."
    section_anchor: travel-and-ota-specific-channels
---

Links from authoritative, relevant sites remain one of Google's strongest ranking signals. An unmanaged backlink profile — spammy referring domains, keyword-stuffed anchors, unexplained velocity spikes — can suppress rankings as effectively as broken crawl paths. This chapter covers the full external-link lifecycle: profiling what you have, auditing for risk, disavowing confirmed spam, and earning quality links through competitor analysis and digital PR.

## Exporting Your Backlink Profile

Start in Ahrefs Site Explorer: open the **Referring Domains** report, filter to dofollow links, and export as CSV. Pull the **Anchors** report as a second export. These two files — who links to you and with what text — are the foundation for every decision in this chapter.

SEMrush Backlink Audit adds a machine-learning layer. It scores each backlink on a [0–100 Toxicity Score across 45+ markers](https://www.semrush.com/kb/965-toxic-markers-description) and classifies your portfolio as High (>10% toxic), Medium (3–9%), or Low (<3%). Treat the classification as a triage filter, not a verdict — every flagged domain still requires manual review before any disavow action.

## Spam Score and Quality Proxies

No third-party spam score is a Google signal. [Ahrefs states explicitly](https://ahrefs.com/blog/toxic-backlinks/) that "toxic backlinks" is a tool-invented label, not a Google concept, and that John Mueller "has no notion" of toxic links. Moz Spam Score (0–100%) uses 27 machine-learned signals to evaluate the *linking domain's* characteristics — it does not represent how Google treats that link. Domain Rating and Domain Authority are useful quality proxies during manual triage, but a low-DR domain is a candidate for investigation, not automatic disavowal.

## Anchor Text Over-Optimization

A natural profile benchmarks at 30–50% branded, 15–25% partial-match keyword, 10–20% generic, 5–15% naked URL, and **1–5% exact-match keyword**. Exact-match above 10% crosses into the over-optimization zone associated with Penguin-era algorithmic scrutiny.

The fix is dilution, not disavowal: for the next three to six months, specify branded or partial-match anchors in every outreach request. If a site has accumulated 14% exact-match anchors on phrases like "cheap vietnam tours," future outreach must request "TigerTrails" or "Southeast Asia tour operators" until the ratio normalizes. Recovery from documented over-optimization typically takes around 60 days once the anchor ratio starts improving.

<KnowledgeCheck
  question="Your exact-match anchor ratio is 14%. What is the correct remediation?"
  options={[
    "Disavow all domains using exact-match anchors",
    "Request branded or partial-match anchors in new outreach until the ratio falls below 5%",
    "Add nofollow attributes to exact-match anchor links in your own content",
    "Submit a reconsideration request to Google explaining the anchor history"
  ]}
  correctIdx={1}
  explanation="Disavowal removes referring domains — the right tool for spam, not for an anchor-text problem. The fix for over-optimization is diluting the ratio through new link acquisition that specifies branded or partial-match anchors."
/>

## Link Velocity Anomalies

Link velocity is the rate at which new referring domains arrive each month. [Google's SpamBrain analyzes billions of links daily](https://ahrefs.com/blog/backlink-audit/); a monthly count exceeding 2× the site's historical median raises the probability of algorithmic review.

In Ahrefs, the **Referring Domains graph** is your primary detector. Filter to **New** referring domains over the spike's date range, sort by DR ascending, and check the Anchors report for the same window. A spam or PBN attack shows low-DR domains sharing identical exact-match anchors in c-class IP clusters. A PR campaign shows editorial sites with organic traffic. The diagnostic difference matters: a spam spike may warrant disavowal; a PR spike warrants documentation. Record all confirmed campaign dates in your rationale log — a future auditor cannot distinguish earned velocity from an attack without it.

## The Disavow File: Format, Submission, and Rationale

A disavow file is a plain-text `.txt` file (UTF-8 or 7-bit ASCII, max 2 MB / 100,000 lines) submitted via the [Google Search Console Disavow Links tool](https://support.google.com/webmasters/answer/2648487). Three constructs cover all cases:

- `domain:spammydomain.com` — disavows the root domain and all subdomains. Use for confirmed PBNs and spam networks.
- A bare URL — disavows that single page only. A sitewide PBN needs a domain entry, not one URL entry per page.
- Lines starting with `#` — comments ignored by Google; use them for inline rationale documentation.

<Callout type="warning">
**Each GSC upload replaces the previous file entirely.** A site that previously disavowed 150 domains and uploads a new 5-domain file silently re-enables the 145 domains absent from the new file. Always download the existing disavow file, merge new entries, then upload the combined version.
</Callout>

Google recommends disavowal only for confirmed manual actions or large volumes of manipulative links — not for tool-assigned toxicity scores alone. For every disavowed domain, maintain a rationale spreadsheet: domain, DR, link type, risk signal, outreach attempt date and outcome, decision date, and auditor. This record is required evidence for any reconsideration request.

<KnowledgeCheck
  question="You need to disavow links from a PBN that generates 200 sitewide links across different URL paths. Which file entry is correct?"
  options={[
    "List all 200 individual page URLs, one per line",
    "domain:pbn-example.com",
    "*.pbn-example.com",
    "disavow:pbn-example.com/all"
  ]}
  correctIdx={1}
  explanation="A domain-level entry (domain:pbn-example.com) covers all current and future URLs from the root domain and subdomains. Listing 200 individual URLs would miss any URL path not explicitly entered and requires manual updates as the PBN adds pages."
/>

## Finding Link-Earning Opportunities

The highest-conversion prospecting method is a competitor backlink gap analysis. [SEMrush Backlink Gap](https://www.semrush.com/kb/773-backlink-gap) and Ahrefs Link Intersect surface domains linking to competitors but not you. The **"Best" category** in SEMrush — domains that link to *all* selected competitors — is your highest-priority prospect list; editorial willingness in the niche is already proven. Run this before any cold outreach.

Resource page prospecting is the second channel: search `intitle:"resources" "southeast asia travel"` to surface curated link pages, then pitch with a specific asset that earns inclusion. Conversion exceeds cold outreach because the curator has already opted into linking behavior.

## Travel and OTA-Specific Channels

Two channels are uniquely accessible to travel brands:

**Tourism board resource pages** — Organizations like the Tourism Authority of Thailand or Vietnam National Administration of Tourism maintain "where to book" pages with DR typically between 50 and 80. The pitch is credentialing: licensed operator status, authenticated guide network, or regulatory certification.

**Destination guide features in travel media** — Lonely Planet, Condé Nast Traveler, and BBC Travel run "best operators" sections. [The winning pitch](https://searcharoo.com/link-building-for-travel-websites/) is original data — a three-year weather analysis, a visa-free travel matrix — or exclusive photography. Product descriptions do not earn editorial placements.

## Outreach Template Structure

Every email must clear four tests: (1) **Reference** a specific recent article — proof you read the publication. (2) **Offer** something concrete: an exclusive data excerpt or a resource their audience would bookmark. (3) **State relevance** in one sentence. (4) **Make one ask** — an addition to an existing article or consideration for a future piece.

Never use the word "backlink." Never request an exact-match anchor. [Cision's 2025 data](https://www.reporteroutreach.com/blog/digital-pr-link-building) shows 98% of journalists reject pitches over 400 words and 86% immediately discard off-beat pitches.

## 90-Day Link Acquisition Campaign

Structure outreach against three target tiers:

| Tier | DR Range | Count | Site Types |
|---|---|---|---|
| 1 | > 50 | 10 | Tourism boards, major travel publishers, .edu |
| 2 | 30–50 | 30 | Destination guides, travel blogs, niche PR outlets |
| 3 | 15–30 | 20 | Regional communities, hospitality blogs |

**Days 1–14:** Run Backlink Gap against three competitors; commission a linkable asset (original survey or evergreen resource page). **Days 15–60:** Tier 1 outreach first; Tier 2 blogger and resource page outreach in parallel with the .edu scholarship announcement. **Days 61–90:** One follow-up per non-respondent; re-audit anchor ratios; report new RD count, DR distribution, and velocity chart.

---

## Hands-On Exercise: Anchor Text Audit (15–20 Minutes)

Using Ahrefs (free account or 7-day trial):

1. Site Explorer → enter your domain → click **Anchors** → sort by Referring Domains descending → export CSV.
2. In a spreadsheet, categorize each anchor row: branded, exact-match, partial-match, generic, or naked URL.
3. Calculate each category's percentage share of total referring domains.
4. Compare your exact-match percentage against the 1–5% safe ceiling and the 10% danger threshold.
5. List the top three exact-match anchor strings with their top-linking domain DRs.

**Success criteria:** You can state whether your exact-match ratio is inside or outside the safe ceiling and name one dilution action — a specific anchor text to request in future outreach.

---

[[06-developer-collaboration-seo-change-management]] — *Developer Collaboration & SEO Change Management* — translates every finding from this course into sprint-ready developer tickets and manages the change process through to post-launch monitoring.
