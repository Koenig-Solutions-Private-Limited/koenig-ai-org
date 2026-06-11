---
chapter_num: 1
course_slug: technical-seo-fundamentals
title: "Crawlability, Indexation & Site Architecture Fundamentals"
status: g3-passed
last_updated: 2026-06-11
duration_min: 20
vendor_tag: Google Search Central
learning_objectives:
  - "Write robots.txt rules that correctly control Googlebot and AI crawlers using Disallow/Allow precedence"
  - "Build and submit an XML sitemap in GSC and interpret coverage errors"
  - "Choose between rel=canonical and noindex for near-duplicate pages without conflicting signals"
  - "Identify three signs of a crawl budget problem on a large site"
  - "Triage the GSC Page Indexing report by distinguishing Error from Excluded statuses"
sources:
  - url: "https://developers.google.com/search/docs/crawling-indexing/robots/intro"
    title: "Robots.txt Introduction and Guide | Google Search Central"
  - url: "https://developers.google.com/search/docs/crawling-indexing/robots/create-robots-txt"
    title: "Create and Submit a robots.txt File | Google Search Central"
  - url: "https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls"
    title: "How to Specify a Canonical with rel=canonical | Google Search Central"
  - url: "https://developers.google.com/search/docs/crawling-indexing/canonicalization"
    title: "What is URL Canonicalization | Google Search Central"
  - url: "https://support.google.com/webmasters/answer/7440203"
    title: "Page Indexing Report - Search Console Help"
  - url: "https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag"
    title: "Robots Meta Tag Specifications | Google Search Central"
  - url: "https://www.sitemaps.org/protocol.html"
    title: "Sitemaps XML Protocol | sitemaps.org"
  - url: "https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap"
    title: "Build and Submit a Sitemap | Google Search Central"
  - url: "https://developers.google.com/search/docs/crawling-indexing/large-site-managing-crawl-budget"
    title: "Crawl Budget Management | Google Search Central"
  - url: "https://developers.openai.com/api/docs/bots"
    title: "OpenAI Web Crawlers: GPTBot and OAI-SearchBot | OpenAI Docs"
  - url: "https://privacy.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler"
    title: "Does Anthropic crawl data from the web? | Anthropic Privacy Center"
  - url: "https://docs.perplexity.ai/docs/resources/perplexity-crawlers"
    title: "Perplexity Crawlers | Perplexity Docs"
owns:
  - "robots.txt syntax and allow/disallow rules for Googlebot and AI bots (GPTBot, PerplexityBot, ClaudeBot)"
  - "XML sitemap creation, submission in Google Search Console, and coverage error resolution"
  - "canonical tag mechanics: self-referencing, cross-domain, and conflict resolution"
  - "noindex tag usage and noindex vs canonical decision framework for duplicate content"
  - "crawl budget concepts: crawl demand, crawl capacity, crawl rate"
  - "site URL hierarchy mapping and orphaned page identification"
  - "internal link gap audit as a crawlability diagnostic (not as link equity strategy)"
  - "GSC Index Coverage report: reading status categories (Excluded, Error, Valid, Warning)"
defers_to:
  - "Screaming Frog crawl toolchain and full audit workflow → ch2"
  - "Core Web Vitals and page performance metrics → ch3"
  - "JSON-LD structured data implementation → ch4"
  - "internal link equity and topic-cluster linking strategy → ch4"
  - "backlink profile analysis and disavow → ch5"
  - "developer ticket writing and migration checklists → ch6"
quiz_topics:
  - "robots.txt Disallow vs Allow directive precedence"
  - "correct AI bot user-agent names in robots.txt (GPTBot, PerplexityBot)"
  - "when to use noindex vs canonical for near-duplicate pages"
  - "GSC Index Coverage status: difference between Excluded and Error categories"
  - "three signals that indicate a crawl budget problem on a large site"
notebooklm_source_focus:
  - "Google Search Central: robots.txt documentation and AI bot guidance 2026"
  - "Google Search Console Index Coverage report help"
  - "canonical tag implementation guide Google Search Central"
  - "XML sitemap protocol and GSC sitemap submission walkthrough"
  - "crawl budget and large site optimization Google documentation"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "A robots.txt file contains two Googlebot rules: `Disallow: /blog/` and `Allow: /blog/post/`. Which URL is crawlable?"
    options:
      - "`/blog/` only — Disallow always takes priority over Allow when there is any conflict"
      - "Neither URL — conflicting Disallow and Allow rules cause both paths to be blocked"
      - "`/blog/post/` — the longer, more specific Allow rule takes precedence over the shorter Disallow"
      - "Both URLs — Allow always beats Disallow regardless of which path is longer or shorter"
    correct_idx: 2
    explanation: "When two rules match the same URL at different path lengths, the longer (more specific) path wins. `/blog/post/` matches both rules; the Allow path (12 characters) is longer than the Disallow path (7 characters), so Allow wins."
    section_anchor: controlling-crawler-access-with-robotstxt
  - question: "A site owner wants to block OpenAI's model-training crawler but allow ChatGPT to surface the site in search answers. Which robots.txt configuration is correct?"
    options:
      - "`User-agent: OpenAI-Bot` with `Disallow: /` to block all OpenAI access from training and search"
      - "`User-agent: GPTBot` with `Disallow: /` plus `User-agent: OAI-SearchBot` with `Allow: /` declared separately"
      - "`User-agent: GPTBot` with `Disallow: /` alone — ChatGPT search results are unaffected without a separate rule"
      - "`User-agent: ChatGPT-User` with `Disallow: /` to block both model training and ChatGPT search together"
    correct_idx: 1
    explanation: "GPTBot collects training data; OAI-SearchBot powers ChatGPT search results. Blocking GPTBot does not affect ChatGPT search inclusion — that requires a separate OAI-SearchBot rule. `OpenAI-Bot` is not a valid user-agent string."
    section_anchor: controlling-crawler-access-with-robotstxt
  - question: "A travel site has `/tours/rome-walking/` and `/tours/rome-walking/?currency=USD` — identical content, but the parameter URL occasionally receives external backlinks. Which signal belongs on the parameter URL?"
    options:
      - "`<meta name='robots' content='noindex'>` to remove the parameter URL from search results entirely"
      - "`<link rel='canonical' href='/tours/rome-walking/'>` to consolidate link equity to the preferred URL"
      - "Both noindex and rel=canonical tags together, since they cover different aspects of duplicate control"
      - "No tag at all — Google automatically consolidates parameter URLs without any explicit guidance needed"
    correct_idx: 1
    explanation: "Canonical consolidates link equity from external backlinks to the preferred URL. noindex discards that equity and won't help pass value. Combining noindex and canonical on the same page sends contradictory signals — Google explicitly warns against this combination."
    section_anchor: canonical-tags-and-noindex
  - question: "The GSC Page Indexing report shows 3,000 URLs in 'Excluded' and 200 URLs in 'Error.' How should remediation be prioritized?"
    options:
      - "Address all 3,200 URLs immediately — both statuses mean the pages are absent from Google's index"
      - "Focus on the 200 Error URLs first; Excluded pages are not indexed but mostly for expected or intentional reasons"
      - "Prioritize the 3,000 Excluded URLs — they represent far more missing pages and outweigh the Error count"
      - "Neither status requires immediate action — both resolve automatically as Google recrawls the site over time"
    correct_idx: 1
    explanation: "Error means not indexed due to a problem requiring intervention (5xx, redirect error, soft 404). Excluded means not indexed for expected reasons — noindex, robots.txt block, or Google-chosen canonical. Treating all Excluded pages as problems wastes remediation time."
    section_anchor: reading-the-gsc-page-indexing-report
  - question: "Which combination of signals most strongly indicates a crawl budget problem on a 500,000-URL e-commerce site?"
    options:
      - "Increasing bounce rate, declining organic traffic, and shorter average session duration across the site"
      - "Growing 'Discovered — not indexed' count in GSC, new pages taking 7+ days to appear, and Googlebot crawling cart and checkout URLs heavily"
      - "Strong domain authority score, fast LCP times, and a large number of external referring domains pointing to the site"
      - "Numerous duplicate title tags, thin-content pages, and missing meta descriptions flagged across the site"
    correct_idx: 1
    explanation: "The three crawl-budget indicators are: GSC showing a growing 'Discovered — currently not indexed' count, new pages taking 7+ days to appear in URL Inspection, and server logs showing Googlebot spending time on low-value URL patterns like cart, checkout, or session-parameterized pages."
    section_anchor: crawl-budget
---

## How Googlebot Discovers and Indexes Pages

Search engines operate in three phases: crawl, index, serve. Googlebot discovers URLs by following links across the web and by reading XML sitemaps you submit. It fetches each URL, renders the page using headless Chromium, and passes the content to the indexer. The indexer selects a canonical URL to store and decides whether to include the page in search results.

Two facts to internalize before anything else. First, robots.txt is a *hint*, not a lock — Googlebot respects it, but a disallowed page can still appear in search results if external sites link to it (shown without a snippet). Second, [Googlebot fetches up to 2 MB of HTML per URL](https://developers.google.com/search/docs/crawling-indexing/large-site-managing-crawl-budget); content beyond that threshold is silently dropped, which matters for long single-page applications.

## Controlling Crawler Access with robots.txt

The robots.txt file lives at `https://example.com/robots.txt`. It uses the Robots Exclusion Protocol: declare a `User-agent:` target, then list `Disallow:` and `Allow:` rules beneath it.

**Precedence rule:** When two rules match the same URL at different path lengths, the *longer* (more specific) path wins. When paths are equal length, `Allow` beats `Disallow`. This is the most-tested rule in crawl audits and the most common misconfiguration vector — know it cold.

In 2026, robots.txt must manage a fleet of AI crawlers, each with a distinct user-agent:

| Crawler purpose | User-agent |
|---|---|
| Google search ranking | `Googlebot` |
| Google AI model training | `Google-Extended` |
| OpenAI model training | `GPTBot` |
| ChatGPT search results | `OAI-SearchBot` |
| Anthropic model training | `ClaudeBot` |
| Perplexity search indexing | `PerplexityBot` |

A critical distinction: blocking `GPTBot` prevents OpenAI training data collection but does *not* exclude the site from [ChatGPT search answers](https://developers.openai.com/api/docs/bots) — that requires a separate `OAI-SearchBot` rule. The same separation applies to [Anthropic's crawlers](https://privacy.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler): `ClaudeBot` handles training; `Claude-SearchBot` handles real-time search.

Never block JavaScript or CSS files in robots.txt. Googlebot renders pages with headless Chromium; blocking `.js` and `.css` paths degrades rendering quality and produces "Indexed, though blocked by robots.txt" warnings in GSC.

<KnowledgeCheck
  question="A robots.txt file contains: `Disallow: /private/` and `Allow: /private/press/`. What happens when Googlebot requests `/private/press/news`?"
  options={[
    "Blocked — Disallow always overrides Allow for any path under /private/",
    "Crawlable — the Allow rule for /private/press/ is longer and wins",
    "Blocked — equal-length rules default to Disallow",
    "Crawlable — Allow always wins regardless of path length"
  ]}
  correctIdx={1}
  explanation="The URL /private/press/news matches both rules. The Allow path (/private/press/) has 15 characters; the Disallow path (/private/) has 9 characters. Longer path wins — the URL is crawlable."
/>

## XML Sitemaps and GSC Submission

A sitemap is your crawl invitation list — a structured declaration of URLs you want Google to discover. The [XML sitemap protocol](https://www.sitemaps.org/protocol.html) caps each file at 50,000 URLs and 50 MB uncompressed. Sites exceeding that limit use a *sitemap index file* that points to multiple individual sitemaps, each under the cap.

The only field [Google actually uses](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap): `<lastmod>`, and only when it accurately reflects actual page modification dates. `<changefreq>` and `<priority>` are explicitly ignored — setting `<priority>1.0</priority>` on every URL provides zero crawl benefit.

To submit: in GSC go to **Indexing → Sitemaps**, enter the sitemap URL, and click Submit. The Sitemaps report shows last-read date, URL count, and processing errors. A "Couldn't fetch" error almost always means the URL you entered doesn't match the actual file path — verify it in a browser before troubleshooting further.

## Canonical Tags and noindex

`rel="canonical"` is a *strong hint*, not a directive: `<link rel="canonical" href="https://example.com/preferred-url/">` in the `<head>`. Google may override your canonical if the specified page has quality problems — slow load, HTTPS issues, or conflicting signals. You will see this as "Duplicate, Google chose different canonical" in the Page Indexing report's Excluded section. Every indexable page should carry a self-referencing canonical to prevent parameter variants and tracking-appended URLs from fragmenting canonical signals.

`noindex` (`<meta name="robots" content="noindex">`) tells Google not to index the page. One hard constraint: **the page must be crawlable** for Google to read the tag. If robots.txt blocks the URL, the noindex tag is never discovered and the page can still appear in results via link-based discovery.

**Decision framework for near-duplicate pages:**

- **Use canonical** when you want link equity consolidated from any external backlinks pointing at the duplicate, or when the page serves users but has near-identical content (e.g., print-friendly variants, filtered e-commerce listing pages).
- **Use noindex** when the page should never appear in search results and no link equity consolidation is needed (e.g., internal search results, cart pages, checkout steps).
- **Never use both on the same page.** [Google explicitly warns](https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag) that noindex + canonical is a contradictory combination — one blocks indexing, the other declares equivalence to an indexed URL.

<KnowledgeCheck
  question="A site has a print-friendly variant at `/article/slug/print/` that occasionally receives external backlinks. The team wants it excluded from search results. What is the correct approach?"
  options={[
    "Add noindex to the print page — it removes it from search results and handles backlinks",
    "Add rel=canonical pointing to the main article — excludes from search while passing link equity",
    "Add both noindex and rel=canonical to cover both exclusion and equity consolidation",
    "Leave it untagged — Google deduplicates print variants automatically"
  ]}
  correctIdx={1}
  explanation="Canonical on the print page points equity from any external backlinks to the canonical article URL. noindex would discard that equity and doesn't consolidate it. Using both tags sends contradictory signals. Untagged pages leave canonical selection to Google's algorithm."
/>

## Crawl Budget

Crawl budget is the product of two factors: *crawl capacity* (the maximum crawl rate Google allocates based on your server's responsiveness) and *crawl demand* (how strongly Google wants to crawl based on URL freshness, popularity, and perceived value). Crawl rate — the speed at which Googlebot fetches pages — can be reduced but not increased via GSC settings.

<Callout type="warning">
Crawl budget is a practical concern only for sites with hundreds of thousands of URLs, high publish frequency, or heavy JavaScript rendering. For sites under 10,000 pages with clean architecture, crawl budget is rarely a bottleneck.
</Callout>

Three signals that a large site has a crawl budget problem: (1) GSC shows a growing "Discovered — currently not indexed" count with no corresponding Error reason; (2) newly published pages take 7+ days to appear in URL Inspection despite being submitted in the sitemap; (3) server logs reveal Googlebot spending significant time on `/cart/`, `/checkout/`, session-parameterized, or paginated search URLs. The fix is robots.txt blocking of low-value URL patterns and returning 404/410 responses for discontinued pages rather than soft 404s.

## Site Architecture and Orphaned Pages

A URL hierarchy map shows how deep each page sits from the homepage and which URLs share parent paths. Orphaned pages — URLs that exist but have no internal links pointing to them — are invisible to Googlebot's link-following pass and typically receive little crawl budget.

The only way to find orphaned pages is to compare a complete URL list (from sitemap, server logs, or analytics exports) against your internal link graph. This is an *internal link gap audit used as a crawlability diagnostic*: you're identifying which pages Googlebot cannot reach by following links — not distributing link equity. Internal link equity strategy and topic-cluster linking belong to [[04-on-page-optimization-structured-data]].

## Reading the GSC Page Indexing Report

The Page Indexing report (formerly Index Coverage) classifies every URL Google has discovered into four statuses:

| Status | Meaning | Response |
|---|---|---|
| **Error** | Not indexed; a problem exists | Investigate and fix |
| **Valid with warning** | Indexed but issues present | Review case by case |
| **Valid** | Indexed normally | None needed |
| **Excluded** | Not indexed; intentional or acceptable | Verify it's expected |

The most common confusion: treating the total Excluded count as a measure of indexation failure. [Excluded covers](https://support.google.com/webmasters/answer/7440203) pages with noindex, pages where Google selected a different canonical, robots.txt-blocked URLs, and duplicate pages Google deduped — most of which are working as intended. Audit the Excluded sub-reason breakdown rather than the aggregate number. Error statuses always deserve investigation; Excluded statuses deserve verification.

## Hands-On Exercise: Baseline Crawlability Audit (15–20 min)

**Tools required:** Google Search Console (free), access to your site's robots.txt URL.

**Step 1 — robots.txt review.** Open `https://yourdomain.com/robots.txt` in a browser. Answer: Is there a `User-agent: *` catchall? Are any AI crawlers (GPTBot, ClaudeBot, PerplexityBot) explicitly allowed or blocked? In GSC, go to **Settings → robots.txt** to use the built-in tester and confirm rules parse as expected.

**Step 2 — Sitemap status check.** In GSC, go to **Indexing → Sitemaps**. If no sitemap is submitted, create a minimal XML sitemap and submit it now. Note the URL count and last-read date. Record any processing errors.

**Step 3 — Page Indexing triage.** Go to **Indexing → Pages**. Record: total Error count, the top two error reasons by volume, and the three largest Excluded sub-reasons. For each Error reason, open one example URL in URL Inspection and note the recommended fix.

**Success criteria:** You can name one Error status item and its specific remediation, and confirm whether your top Excluded sub-reason is intentional (e.g., noindex on checkout pages) or a misconfiguration (e.g., a key landing page showing "Excluded by noindex tag" that was never meant to have one).

[[02-technical-seo-audit-screaming-frog]] covers how to run a full crawl with Screaming Frog to systematically surface and prioritize every issue category you've identified in this baseline.
