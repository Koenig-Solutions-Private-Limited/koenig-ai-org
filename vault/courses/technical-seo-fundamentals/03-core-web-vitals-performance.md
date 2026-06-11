---
chapter_num: 3
course_slug: technical-seo-fundamentals
title: "Core Web Vitals & Page Performance Optimization"
status: g0-passed
last_updated: 2026-06-11
duration_min: 20
vendor_tag: Google
learning_objectives:
  - "State the Good, Needs Improvement, and Poor thresholds for LCP, INP, and CLS"
  - "Explain why INP replaced FID and how the two metrics differ conceptually"
  - "Distinguish lab data from field data in PageSpeed Insights and know when to use each"
  - "Identify render-blocking resources in Lighthouse and select the correct deferral attribute"
  - "Diagnose and fix oversized images, lazy-load violations, and layout shift sources"
  - "Write a developer performance brief with quantified acceptance criteria"
  - "Validate a CWV fix using the 28-day window in Google Search Console"
sources:
  - url: "https://web.dev/articles/vitals"
    title: "Web Vitals — web.dev"
  - url: "https://web.dev/articles/inp"
    title: "Interaction to Next Paint (INP) — web.dev"
  - url: "https://web.dev/blog/inp-cwv-march-12"
    title: "INP becomes a Core Web Vital on March 12 — web.dev"
  - url: "https://developers.google.com/speed/docs/insights/v5/about"
    title: "PageSpeed Insights API — Google Developers"
  - url: "https://developer.chrome.com/docs/lighthouse/performance/render-blocking-resources"
    title: "Eliminate Render-Blocking Resources — Chrome Developers"
  - url: "https://web.dev/articles/lazy-loading"
    title: "Browser-level image lazy loading — web.dev"
  - url: "https://web.dev/articles/serve-images-webp"
    title: "Use WebP Images — web.dev"
  - url: "https://web.dev/articles/debug-layout-shifts"
    title: "Debug Layout Shifts — web.dev"
  - url: "https://support.google.com/webmasters/answer/9205520"
    title: "Core Web Vitals report in Search Console"
owns:
  - "LCP (<2.5 s), INP (<200 ms), and CLS (<0.1) 2026 thresholds and pass/fail boundaries"
  - "INP vs the deprecated FID metric: conceptual distinction and why INP replaced FID"
  - "PageSpeed Insights: running lab vs field audits, reading CrUX data"
  - "Chrome DevTools Lighthouse panel: performance tab, opportunities, diagnostics"
  - "render-blocking script identification and deferral (defer/async attributes)"
  - "oversized image diagnosis: WebP/AVIF format upgrades, compression tooling"
  - "lazy-load directives for below-the-fold images and iframes"
  - "layout shift culprit identification (reserved space, ad slots, font swap)"
  - "developer performance brief writing: format, specificity, acceptance criteria"
  - "before/after CrUX validation methodology in GSC"
defers_to:
  - "crawl-side performance signals → ch1"
  - "Screaming Frog audit workflow → ch2"
  - "JSON-LD structured data → ch4"
  - "developer ticket Jira/Linear workflow → ch6"
quiz_topics:
  - "2026 Core Web Vitals thresholds for LCP, INP, and CLS (pass/needs-improvement/poor bands)"
  - "difference between INP and FID and why INP replaced FID in 2024"
  - "how to distinguish lab data from field data in PageSpeed Insights"
  - "three render-blocking patterns Lighthouse flags in the Opportunities section"
  - "correct HTML attribute to defer a non-critical third-party script"
notebooklm_source_focus:
  - "Google Core Web Vitals 2026 thresholds and INP transition documentation"
  - "PageSpeed Insights and CrUX field data guide"
  - "Chrome DevTools Lighthouse performance audit documentation"
  - "image optimization guide: WebP AVIF lazy loading Google Search Central"
  - "CLS layout shift root causes and fixes web.dev"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which set of values correctly lists the 2026 Good thresholds for all three Core Web Vitals?"
    options:
      - "LCP ≤ 2.5 s, INP ≤ 200 ms, and CLS ≤ 0.1"
      - "LCP ≤ 1.5 s, INP ≤ 100 ms, and CLS ≤ 0.05"
      - "LCP ≤ 2.5 s, FID ≤ 100 ms, and CLS ≤ 0.1"
      - "LCP ≤ 4.0 s, INP ≤ 200 ms, and CLS ≤ 0.25"
    correct_idx: 0
    explanation: "The 2026 CWV Good thresholds—measured at the 75th percentile of CrUX field data—are LCP ≤ 2.5 s, INP ≤ 200 ms, and CLS ≤ 0.1. Option C includes the retired FID metric; options B and D use incorrect values."
    section_anchor: "the-three-core-web-vitals-in-2026"
  - question: "Why did Google replace FID with INP as a Core Web Vital in March 2024?"
    options:
      - "INP captures full interaction latency—input delay, processing, and presentation—for every interaction; FID only measured the first interaction's input delay"
      - "FID produced too many false positives on mobile SPAs, making it an unreliable signal for rankings"
      - "INP is faster to compute in the browser, reducing measurement overhead and latency on older devices"
      - "INP unifies click, scroll, and touch inputs into one metric; FID only tracked keyboard and tap interactions"
    correct_idx: 0
    explanation: "FID's fatal flaw was coverage: it measured only the browser's delay before starting to process the very first interaction, ignoring all subsequent interactions and the time to actually paint the result. INP measures the worst full-latency interaction across the page's entire lifetime."
    section_anchor: "inp-vs-fid-why-the-metric-changed"
  - question: "In PageSpeed Insights, how do you identify which metrics come from real users vs a simulated audit?"
    options:
      - "Lab data is a Lighthouse simulation on a controlled device profile; field data reflects real CrUX measurements at the 75th percentile"
      - "Field data is a Lighthouse simulation on a controlled device; lab data shows real CrUX measurements at the 75th percentile"
      - "Both sections show CrUX data but at different percentiles: lab data uses the 50th and field data uses the 75th"
      - "Lab data covers mobile only with a slower simulated connection; field data aggregates all devices into a single composite score"
    correct_idx: 0
    explanation: "PageSpeed Insights shows field data (CrUX, 28-day rolling real-user data at the 75th percentile) at the top and lab data (Lighthouse simulation on a throttled Moto G4 profile) below. They often diverge: lab may show passing LCP while field shows Poor because real users have slower devices."
    section_anchor: "pagespeed-insights-lab-vs-field-data"
  - question: "Lighthouse lists render-blocking resources under Opportunities. Which set of patterns causes render blocking?"
    options:
      - "Scripts in <head> without defer or async; stylesheets without a matching media query; inline scripts calling document.write()"
      - "Deferred scripts executing after DOMContentLoaded; print stylesheets with media='print'; JavaScript modules using dynamic import"
      - "JavaScript bundles over 100 KB; CSS files with unused selectors; custom fonts loaded with font-display: swap"
      - "Scripts with async in <head>; stylesheets linking to a CDN origin; images missing width and height attributes"
    correct_idx: 0
    explanation: "Render-blocking resources are scripts in <head> without defer/async (must finish before any rendering), stylesheets without a media query match (applied unconditionally), and inline document.write() calls. Options B and D describe non-blocking or unrelated patterns; option C describes bundle size, not render blocking."
    section_anchor: "fixing-render-blocking-scripts"
  - question: "Which HTML attribute is most appropriate for an independent third-party analytics script with no dependencies on other scripts?"
    options:
      - "async — downloads in parallel and executes immediately when ready, regardless of HTML parse state"
      - "defer — downloads in parallel and executes after HTML parsing is complete, preserving document order"
      - "preload — tells the browser to fetch the resource early but does not affect when the script executes"
      - "type='module' — treats the script as an ES module, which defers execution automatically and allows imports"
    correct_idx: 0
    explanation: "async is the right choice for independent third-party scripts (analytics, review widgets, chat tools): the browser downloads the script without blocking the parser and executes it as soon as it arrives. Use defer for order-dependent scripts that need the full DOM; async executes whenever ready, not in document order."
    section_anchor: "fixing-render-blocking-scripts"
---

## The Three Core Web Vitals in 2026

Google's Core Web Vitals are three field-measured signals used to assess page experience: **Largest Contentful Paint (LCP)** for loading speed, **Interaction to Next Paint (INP)** for responsiveness, and **Cumulative Layout Shift (CLS)** for visual stability. A page passes CWV assessment only when all three reach Good simultaneously. All three are measured at the **75th percentile** of CrUX field data, segmented by mobile and desktop. [Web Vitals — web.dev](https://web.dev/articles/vitals)

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP | ≤ 2.5 s | 2.5 – 4.0 s | > 4.0 s |
| INP | ≤ 200 ms | 201 – 500 ms | > 500 ms |
| CLS | ≤ 0.1 | 0.1 – 0.25 | > 0.25 |

Partial compliance earns no ranking benefit.

## INP vs FID: Why the Metric Changed

First Input Delay (FID) measured only the browser's queue delay before beginning to process the very first user interaction on a page. It ignored what happened after processing started, and it never recorded any interaction after the first one. A single click that opened a dropdown fast would produce a Good FID score even if every subsequent date-picker selection stalled the main thread for 600 ms.

Interaction to Next Paint (INP), which officially replaced FID on **March 12, 2024**, closes these gaps. INP observes every click, tap, and keyboard input across the page's full lifetime and reports the worst full-latency interaction—covering input delay, main-thread processing time, and the delay until the next visible frame is presented. [INP becomes a Core Web Vital](https://web.dev/blog/inp-cwv-march-12)

## PageSpeed Insights: Lab vs Field Data

Run PageSpeed Insights for any URL and you'll see two distinct sections. **Field data** (top) pulls from CrUX—28 rolling days of real Chrome user measurements at the 75th percentile. **Lab data** (below) is a Lighthouse simulation on a throttled mid-tier Moto G4 device. Lab data is reproducible and debuggable; field data reflects real device and network diversity. [PageSpeed Insights API](https://developers.google.com/speed/docs/insights/v5/about)

The two sections frequently disagree. Lab LCP might show 2.3 s (Good) while field LCP shows 4.1 s (Poor) because real users have slower devices and active background tabs. Always prioritize field data findings—they're what affects ranking. Use lab data to root-cause issues and measure whether a specific fix moved the needle.

<Callout type="warning">
Never declare a CWV fix "done" after a Lighthouse improvement alone. CrUX is a 28-day rolling dataset; a fix deployed today will not fully register in field data for approximately four weeks. Confirm lab improvement first, then monitor GSC's Core Web Vitals report for the full 28-day validation window before closing the ticket.
</Callout>

The **Chrome DevTools Lighthouse panel** gives you the same lab simulation locally. In the Performance tab, the **Opportunities** section lists actionable optimizations; **Diagnostics** lists contributing factors that do not directly affect the score. The Lighthouse score weights Total Blocking Time at 30%, LCP and CLS at 25% each—so reducing main-thread blocking is the highest-leverage route to a higher score.

<KnowledgeCheck question="A page shows Lab LCP = 2.1 s (Good) in PageSpeed Insights but Field LCP = 4.3 s (Poor). Which dataset should drive your fix priority and why?" options={["Field data, because it reflects real user measurements at the 75th percentile and is the signal that affects Google ranking", "Lab data, because Lighthouse produces reproducible results that are easier to verify after a fix is deployed", "Neither — a discrepancy this large means the CrUX data is likely stale and should be disregarded", "Both equally — you should fix both simultaneously rather than treating one as higher priority"]} correctIdx={0} explanation="Field data (CrUX) is the ranking signal; lab data is a diagnostic tool. The 4.3 s field LCP is what harms ranking, so fix that first. Use lab data to verify that individual changes improve the underlying issue before waiting 28 days for CrUX to update." />

## Fixing Render-Blocking Scripts

Lighthouse flags render-blocking resources under Opportunities. Three patterns cause blocking: a `<script>` in `<head>` without `defer` or `async`; a `<link rel="stylesheet">` without a `media` attribute matching the current render context (for example, a print stylesheet missing `media="print"`); and inline scripts calling `document.write()`, which forces the parser to stop and re-execute. [Eliminate Render-Blocking Resources](https://developer.chrome.com/docs/lighthouse/performance/render-blocking-resources)

Use `async` for independent third-party scripts—analytics beacons, review widgets, chat tools—where execution order doesn't matter. Use `defer` for scripts that depend on other scripts or need the full DOM. The choice matters: `async` on a jQuery-dependent script will break the page if jQuery loads after it. A print stylesheet becomes non-blocking with one attribute: `media="print"`.

## Oversized Images and Lazy Loading

Lighthouse flags images as optimizable when recompression would save ≥4 KiB. Converting JPEG hero images to **WebP** reduces file size by 25–35%; **AVIF** compresses further and is supported in Chrome 85+, Firefox 93+, and Safari 16+. Serve both formats using a `<picture>` element—AVIF as the first `<source>`, WebP second, JPEG as the `<img>` fallback—so browsers select the best format they support. [Use WebP Images — web.dev](https://web.dev/articles/serve-images-webp)

Apply `loading="lazy"` to every below-the-fold image and iframe to defer their network requests. **Never lazy-load the LCP element.** Adding `loading="lazy"` to the hero hotel photo on a travel detail page defers its load until the user scrolls near it—guaranteeing a Poor LCP. Use `loading="eager"` plus `fetchpriority="high"` on the LCP image instead. Always include explicit `width` and `height` attributes: without them, the browser cannot reserve space before the image loads and surrounding content shifts—a direct CLS contribution. [Browser-level image lazy loading — web.dev](https://web.dev/articles/lazy-loading)

<KnowledgeCheck question="An SEO audit finds that the hero image on a hotel detail page has loading='lazy' and the page's LCP is 5.8 s (Poor). What is the likely root cause and the correct fix?" options={["The lazy attribute is deferring the LCP image's load; remove it and add fetchpriority='high' to trigger early loading", "The image is too large; convert it from JPEG to WebP and add loading='lazy' to all images including the hero", "The LCP element is not an image; use Chrome DevTools to identify the actual LCP element and optimize it instead", "The page has render-blocking scripts that delay the LCP image; add defer to all script tags in <head>"]} correctIdx={0} explanation="loading='lazy' on the LCP image is one of the most common self-inflicted LCP regressions. The browser postpones loading it until the user scrolls near it—which never happens on a typical above-the-fold hero. Remove the attribute (or explicitly set loading='eager') and add fetchpriority='high'." />

## Layout Shift: Finding and Fixing the Culprit

CLS accumulates from every unexpected shift during the page's lifetime. The three most common culprits on travel and e-commerce pages are: **ad slots without reserved height** (third-party ad containers that expand after initial paint); **web font swaps** (the custom font loads and displaces the fallback due to different metrics—use `font-display: optional` or `size-adjust` to eliminate the shift); and **images without explicit dimensions** (covered above).

To find the source: enable "Layout Shift Regions" in Chrome DevTools → Settings → More Tools → Rendering. Purple overlays flash on shifting elements during page load. The Performance panel's Layout Shifts track shows each event with a source element and its movement distance, letting you precisely identify the responsible DOM node. [Debug Layout Shifts](https://web.dev/articles/debug-layout-shifts)

## Writing a Developer Performance Brief

A performance brief translates your CWV findings into work a developer can execute without asking clarifying questions. Include: the metric and its current value; the diagnosed root cause with evidence (tool used, screenshot or network waterfall); the specific code change required including file path; and acceptance criteria using both lab and field thresholds. Without acceptance criteria, a developer might close the ticket after a Lighthouse improvement that leaves the field CrUX unchanged.

Example acceptance criteria: *Lab LCP < 2.5 s on Lighthouse mobile; CrUX LCP reaches Good band in GSC Core Web Vitals report after 28-day validation; CLS does not increase above 0.1.* Include an explicit "Out of Scope" section—ambiguity becomes implicit permission to touch adjacent code.

## Before/After CrUX Validation in GSC

After deploying a fix, open the **Core Web Vitals report** in Google Search Console, navigate to the affected URL group, and click **"Start Tracking"** to begin a 28-day validation window. [Core Web Vitals report in Search Console](https://support.google.com/webmasters/answer/9205520) CrUX is a rolling 28-day dataset, so a fix deployed today will not fully register for approximately four weeks. Confirm lab LCP improves first—if lab is unchanged, field won't improve. Then monitor GSC weekly for regressions during the window.

## Hands-On Exercise: Audit a Page in 20 Minutes

Use PageSpeed Insights and Chrome DevTools to audit one live URL.

**Steps:**
1. Run PageSpeed Insights. Record field values for LCP, INP, and CLS; note which are Good, Needs Improvement, or Poor.
2. In the lab section, open Opportunities. List every render-blocking resource Lighthouse identifies.
3. Open Chrome DevTools → Lighthouse → run Mobile audit → identify which of the five scored metrics (TBT, LCP, CLS, FCP, SI) is dragging the score lowest.
4. Enable "Layout Shift Regions" (Rendering panel). Reload the page. Note any purple overlays and their source elements.
5. Write a developer performance brief for the single highest-priority finding: current metric value, root cause, required code change, and acceptance criteria.

**Success criteria:** Brief includes a quantified current value, a specific element or attribute to change, and both a lab and a field acceptance criterion.

Next chapter: [[04-on-page-optimization-structured-data]] covers title tags, JSON-LD schema, and internal linking—the on-page signals that work alongside your CWV improvements.
