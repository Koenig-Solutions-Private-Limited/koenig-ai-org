---
chapter_num: 2
course_slug: technical-seo-fundamentals
title: "Running a Full Technical SEO Audit with Screaming Frog & GSC"
status: g3-passed
last_updated: "2026-06-10"
duration_min: 18
vendor_tag: "Screaming Frog & Google Search Console"
learning_objectives:
  - "Configure Screaming Frog SEO Spider with the correct render mode, user-agent, and custom extraction rules for JavaScript-heavy sites"
  - "Export structured issue reports and interpret redirect chain vs redirect loop findings"
  - "Detect broken links, duplicate title tags, and thin-content pages using Screaming Frog filters"
  - "Cross-reference Screaming Frog crawl data with GSC Page Indexing status codes"
  - "Build a prioritized fix backlog using traffic-impact × effort scoring"
sources:
  - url: "https://www.screamingfrog.co.uk/seo-spider/user-guide/configuration/"
    title: "SEO Spider Configuration - Screaming Frog"
  - url: "https://www.screamingfrog.co.uk/seo-spider/issues/response-codes/internal-redirect-loop/"
    title: "Issues - Response Codes: Internal Redirect Loop - Screaming Frog"
  - url: "https://support.google.com/webmasters/answer/7440203?hl=en"
    title: "Page Indexing Report - Search Console Help"
  - url: "https://yoast.com/what-is-thin-content/"
    title: "What Is Thin Content? - Yoast SEO"
owns:
  - "Screaming Frog SEO Spider: crawl configuration (user-agent, render mode, custom extraction rules)"
  - "structured issue report export from Screaming Frog"
  - "redirect chain and redirect loop diagnosis from crawl data"
  - "broken internal and external link detection"
  - "duplicate title tag and meta description identification"
  - "thin-content page detection and assessment criteria"
  - "cross-referencing Screaming Frog findings with GSC Page Indexing and Coverage reports"
  - "prioritized fix backlog: traffic-impact scoring, quick-wins vs developer-dependent tasks"
defers_to:
  - "robots.txt and canonical tag fundamentals → ch1"
  - "GSC Index Coverage conceptual framework → ch1"
  - "Core Web Vitals measurement → ch3"
  - "on-page rewrites and structured data → ch4"
  - "backlink export and toxic link analysis → ch5"
  - "developer ticket authoring → ch6"
quiz_topics:
  - "Screaming Frog render mode options: Spider vs JavaScript rendering"
  - "how to identify a redirect chain vs a redirect loop in Screaming Frog"
  - "GSC Page Indexing status types and what each means for a fix priority"
  - "thin-content threshold and when to consolidate vs expand a page"
  - "two criteria used to rank items in a prioritized SEO fix backlog"
notebooklm_source_focus:
  - "Screaming Frog SEO Spider user guide 2025/2026"
  - "Google Search Console Page Indexing report documentation"
  - "technical SEO audit process and prioritization frameworks 2026"
  - "redirect chain diagnosis and resolution best practices"
  - "duplicate content detection methods and resolution strategies"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "A site uses React with client-side routing and injects canonical tags via JavaScript. Which Screaming Frog render mode must you enable to correctly discover all internal links and canonical values?"
    options:
      - "Text Only — parse raw HTML without script execution"
      - "Old AJAX Crawling Scheme — Google's legacy protocol support"
      - "JavaScript — execute client-side scripts in headless Chromium"
      - "Spider mode — follow links recursively from a seed URL"
    correct_idx: 2
    explanation: "JavaScript mode runs pages through headless Chromium, executing client-side scripts and capturing links, meta tags, and structured data injected after page load. Text Only parses raw HTML only and silently misses all dynamically rendered content."
    section_anchor: configure-your-crawl-before-you-click-start
  - question: "In Screaming Frog's All Redirects report, URL /offers/summer shows 'Number of Redirects: 2' and 'Redirect Loop: True.' What does this mean, and what severity does the Issues tab assign?"
    options:
      - "A two-hop chain resolving to a 200 — medium severity warning"
      - "A loop cycling back to a visited URL — high severity error"
      - "A temporary redirect via Meta Refresh — medium severity warning"
      - "A cross-domain redirect to an external URL — low severity notice"
    correct_idx: 1
    explanation: "Redirect Loop = True means the chain revisits a URL it has already seen, creating an infinite cycle Googlebot cannot resolve. Screaming Frog flags loops as high-severity errors. A chain with multiple hops but no loop is medium severity."
    section_anchor: reading-the-issue-export-redirects-links-and-duplicates
  - question: "GSC Page Indexing shows 600 destination-guide pages with status 'Crawled – currently not indexed.' What does this status mean and what is the correct fix action?"
    options:
      - "Google found the URLs but hasn't crawled them; investigate crawl budget pressure"
      - "A robots.txt Disallow rule is blocking Googlebot; update the Disallow directive"
      - "Google crawled but judged quality too low to index; improve or consolidate content"
      - "A canonical conflict prevents indexing; set a self-referencing canonical on each page"
    correct_idx: 2
    explanation: "'Crawled – currently not indexed' means Google accessed the pages but decided not to include them, typically due to thin, duplicate, or low-value content. Request Indexing does not fix this — content quality improvement or consolidation is required."
    section_anchor: diagnosing-thin-content-and-gsc-cross-reference
  - question: "What word count does Screaming Frog's Low Content Pages filter use by default to flag thin content?"
    options:
      - "100 words — any page below this threshold is flagged"
      - "200 words — the default Low Content Pages filter threshold"
      - "300 words — Yoast's recommended editorial content minimum"
      - "500 words — the standard SEO minimum for ranking pages"
    correct_idx: 1
    explanation: "Screaming Frog defaults to flagging pages with fewer than 200 words as Low Content Pages (configurable). Yoast's separate practitioner guideline recommends a 300-word floor for editorial content."
    section_anchor: diagnosing-thin-content-and-gsc-cross-reference
  - question: "Using a traffic-impact × implementation-effort matrix, which quadrant should your first sprint address?"
    options:
      - "High traffic impact and high implementation effort items"
      - "Low traffic impact and low implementation effort items"
      - "High traffic impact and low implementation effort items"
      - "Low traffic impact and high implementation effort items"
    correct_idx: 2
    explanation: "High-impact / low-effort items deliver the most SEO value for the least developer time — the first-sprint priority. High-impact / high-effort items belong on the roadmap. Low-impact items are quick wins or deferred."
    section_anchor: building-a-prioritized-fix-backlog
---

## Configure Your Crawl Before You Click Start

Before Screaming Frog returns a single URL, three configuration decisions determine the quality of everything downstream: render mode, user-agent, and custom extraction.

**Render mode** lives under Configuration > Spider > Rendering. The default, *Text Only*, parses raw HTML. On React, Next.js, Angular, or Vue sites, this silently misses links, canonical tags, and structured data injected by JavaScript after page load. Set the mode to *JavaScript* for any modern frontend — it runs pages through a headless Chromium instance and captures dynamically rendered elements. The [Screaming Frog configuration guide](https://www.screamingfrog.co.uk/seo-spider/user-guide/configuration/) defines three rendering options: Text Only, Old AJAX Crawling Scheme (a deprecated Google protocol), and JavaScript. For the vast majority of current-stack sites, the practical choice is Text Only versus JavaScript.

**User-agent** has two independent settings: the HTTP Request User-Agent (sent in crawl headers) and the Robots User-Agent (governs which robots.txt rules apply). Set both to Googlebot when auditing for organic visibility so directives and crawl-delay settings match what Googlebot actually experiences.

**Custom extraction** (Configuration > Custom > Extraction) captures values Screaming Frog does not surface natively — JSON-LD text, data-attributes, canonical href values for downstream GSC comparison. Up to 100 XPath, CSS path, or regex extractors run per crawl.

<KnowledgeCheck
  question="A site uses React with client-side routing and injects canonical tags via JavaScript. Which Screaming Frog render mode must you enable?"
  options={["Text Only — parse raw HTML without scripts", "Old AJAX Crawling Scheme — legacy Google protocol", "JavaScript — execute scripts in headless Chromium", "Spider mode — follow links from a seed URL"]}
  correctIdx={2}
  explanation="JavaScript mode runs pages through headless Chromium, executing client-side scripts. Text Only parses raw HTML only and misses every dynamically injected link, canonical tag, or structured data element."
/>

## Reading the Issue Export: Redirects, Links, and Duplicates

After a crawl, use **Bulk Export > Issues > All** for a CSV per issue category. The two highest-value exports for redirect and link diagnosis:

- **Reports > All Redirects** — each row shows Address, hop count, and a "Redirect Loop" True/False column.
- **Bulk Export > Response Codes > 4xx Inlinks** — identifies which pages link to broken URLs. Without inlinks, a developer can confirm a 404 exists but cannot locate the source links to update.

Redirect chains and redirect loops appear in the same report but carry different severity and fixes. A *redirect chain* is two or more sequential hops (A→B→C) that resolves to a final 200 — it costs crawl budget and dilutes link equity, but Googlebot reaches the destination. Screaming Frog flags chains at **medium severity (Warning)**. A *redirect loop* has "Redirect Loop = True" in the report — the sequence revisits a URL it has already seen and can never resolve to a final destination; Googlebot cannot index the page. Loops are flagged at **high severity (Error)**. According to [Screaming Frog's redirect loop documentation](https://www.screamingfrog.co.uk/seo-spider/issues/response-codes/internal-redirect-loop/), the fix sequence is: resolve the circular reference in server config or CMS, update internal links pointing to the original URL, then implement a direct 301 to the correct final destination. Fix loops before chains.

**Duplicate title detection** uses the Page Titles tab with the "Duplicate" filter — pages sharing identical title strings appear here along with an Occurrences count. Apply the same filter in the Meta Description tab for duplicate descriptions. Screaming Frog flags titles outside 30–60 characters and meta descriptions outside 70–155 characters under the over/under length filters.

<KnowledgeCheck
  question="In Screaming Frog's All Redirects report, what distinguishes a redirect loop from a chain with multiple hops?"
  options={["Hop count exceeds 3 sequential redirects", "The 'Redirect Loop' column shows True", "Final status code is 404 not 200", "Chain type is labeled Meta Refresh"]}
  correctIdx={1}
  explanation="Redirect Loop = True means the chain cycles back to a URL already in the sequence — Googlebot can never resolve a final destination. Multiple hops without looping are a chain, flagged at medium severity. Loops are high severity and must be fixed first."
/>

## Diagnosing Thin Content and GSC Cross-Reference

Screaming Frog's **Low Content Pages** filter flags HTML pages below **200 words** by default (configurable in the HTML tab). Apply this threshold critically: product pages, booking confirmation pages, and contact pages legitimately have low word counts. For editorial content — destination guides, how-to articles, blog posts — the [Yoast SEO thin content guide](https://yoast.com/what-is-thin-content/) sets a practitioner floor of 300 words. The fix decision: if a thin page has unique value, expand it with original content; if it substantially duplicates a sibling page, consolidate into one comprehensive page with a 301 redirect from the thinner version.

**Cross-referencing with GSC** requires connecting the URL Inspection API at Config > API Access > Google Search Console (2,000 URLs/day/property limit). After crawl, the Search Console tab provides the "Indexable URL Not Indexed" filter — URLs that Screaming Frog classifies as crawlable but Google has not indexed.

The [GSC Page Indexing report](https://support.google.com/webmasters/answer/7440203?hl=en) categorizes non-indexed URLs with four primary statuses:

| Status | Fix priority | Action |
|---|---|---|
| Crawled – currently not indexed | High | Improve content quality or consolidate duplicates |
| Discovered – currently not indexed | Medium | Investigate crawl budget; not a content problem |
| Duplicate, Google chose different canonical | High | Resolve the canonicalization disagreement |
| Alternate page with proper canonical tag | None | Expected behavior — no action required |

<Callout type="warning">
"Discovered – currently not indexed" is not an error. Google found the URL but has not yet crawled it — typically a crawl budget issue on large sites, not a content quality failure. Resubmitting via Request Indexing does not accelerate crawling. Crawl budget fundamentals are in [[01-crawlability-indexation-fundamentals]].
</Callout>

## Building a Prioritized Fix Backlog

A flat list sorted by Screaming Frog severity is not a fix plan. Use a **traffic impact × implementation effort** matrix to sequence work: high-impact / low-effort items fill the first sprint; high-impact / high-effort items belong on the roadmap; low-impact items are quick wins or deferred. Score traffic impact from GSC Search Analytics impressions for each affected URL set (>500 impressions/month = High; 50–500 = Medium; <50 = Low). Aira's 2026 State of Technical SEO Report found 67% of in-house SEO teams cite developer bandwidth as their primary barrier — priority order is the only lever the SEO team controls.

Split the backlog into two lanes: **SEO-team-executable** (meta description updates, internal link corrections, content expansions) and **developer-dependent** (server-side redirect resolution, template-level duplicate title fixes, JavaScript render configuration). Developer-dependent items require clear acceptance criteria; the format for writing those tickets is covered in [[06-developer-collaboration-seo-change-management]].

## Hands-On Exercise: Audit a 500-URL Site Segment

**Time:** 15–20 minutes | **Tools:** Screaming Frog free tier (500-URL limit)

1. Launch Screaming Frog. Under Configuration > Spider > Rendering, select **Text Only**. Enter a site URL you own or manage and start the crawl.
2. When complete, open the **Issues** tab. Screenshot the top three issues by severity.
3. Navigate to **Reports > All Redirects**. In the exported CSV, identify any rows where "Redirect Loop" = True. Note the Address and find its inlink sources via Bulk Export > Response Codes > 3xx Inlinks.
4. Apply **Page Titles > Duplicate** filter. Record the count and note which URL pattern repeats most.
5. Apply **HTML > Low Content Pages** filter. Identify three flagged URLs and classify each: editorial page needing expansion, structural page with legitimately low content, or duplicate candidate for consolidation.
6. If you have GSC access, connect the URL Inspection API under Config > API Access. Re-crawl and apply "Indexable URL Not Indexed" in the Search Console tab.

**Success criteria:** You have an Issues tab screenshot, a list of redirect loops (or a confirmed zero-loop result), a duplicate title count, and a three-row thin-content classification table with a recommended action — expand, consolidate, or no action — for each flagged URL.

---

Next: [[03-core-web-vitals-performance]] — measuring LCP, INP, and CLS with PageSpeed Insights and CrUX.
