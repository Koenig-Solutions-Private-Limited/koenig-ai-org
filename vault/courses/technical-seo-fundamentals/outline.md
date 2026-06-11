---
course_slug: technical-seo-fundamentals
title: "Technical & Advanced SEO: Audits, On-Page, and Link Strategy for Performance Marketers"
status: outline-g0-passed
course_track: career
toc_locked: true
video_overview: true
koenig_recommendation: "Performance Marketing Specialists who can't speak to crawl budgets, Core Web Vitals, and structured data get screened out at mid-level technical interviews. This course closes the gap between 'runs paid search' and 'owns organic performance': six tightly scoped chapters that move from site architecture theory to live Screaming Frog audits, CWV briefs, JSON-LD schema, backlink disavow, and developer-sprint collaboration."
author: course-architect
level: Builder
vendor_tag: Technical SEO
target_audience: "Mid-level marketers targeting Performance Marketing Specialist roles who manage paid acquisition and need to extend their fluency to organic/technical SEO — particularly those working in travel, OTA, or e-commerce verticals where crawl health and link strategy directly affect revenue."
prerequisites:
  - "Familiarity with Google Search Console (adding a property, reading basic reports)"
  - "Basic understanding of how search engines crawl and index pages"
  - "Access to a live or staging website to audit (or instructor-provided sample crawl data)"
learning_outcomes:
  - "Configure robots.txt, XML sitemaps, and canonical tags to control how Googlebot and AI bots crawl and index a site"
  - "Run a structured Screaming Frog + GSC audit and produce a prioritized fix backlog ranked by traffic impact"
  - "Measure LCP, INP, and CLS against 2026 thresholds and write a developer-ready performance brief"
  - "Audit and rewrite title tags, implement JSON-LD schema for three entity types, and build a topic-cluster internal link structure"
  - "Audit a backlink profile in Ahrefs/SEMrush, build a disavow file, and pitch a 90-day link-earning campaign"
  - "Translate SEO findings into sprint-ready developer tickets and manage organic visibility through a site migration"
total_duration_min: 305
chapter_count: 6
sources: []
---

## Chapter 1: Crawlability, Indexation & Site Architecture Fundamentals

**Duration:** ~50 min
**Learning objectives:**
- Configure robots.txt to correctly allow/disallow crawl paths for Googlebot and AI bots (GPTBot, PerplexityBot)
- Submit and validate an XML sitemap in Google Search Console, resolving coverage errors
- Audit a site's Index Coverage report to identify and fix noindex conflicts, canonicalization issues, and crawl anomalies
- Map an existing site's URL hierarchy to identify orphaned pages and internal link gaps as crawlability diagnostics

**Key concepts:** robots.txt directives, AI bot user-agents, XML sitemap protocol, canonical tag mechanics, noindex vs canonical decision framework, crawl budget, site URL hierarchy, orphaned pages, GSC Index Coverage status categories

**Hands-on exercise:** Given a sample robots.txt with three deliberate errors (blocked CSS/JS, GPTBot not addressed, conflicting allow/disallow), correct all three. Submit a provided sitemap to GSC and resolve two simulated coverage errors (noindex conflict + canonical mismatch). Map a 20-URL site hierarchy and flag two orphaned pages.

---

## Chapter 2: Running a Full Technical SEO Audit with Screaming Frog & GSC

**Duration:** ~55 min
**Learning objectives:**
- Configure a Screaming Frog crawl with appropriate user-agent, render mode, and custom extraction rules, then export a structured issue report
- Diagnose redirect chains, broken links, duplicate title tags/meta descriptions, and thin-content pages from crawl data
- Cross-reference Screaming Frog findings with GSC Page Indexing and Coverage reports to confirm real-world impact
- Build a prioritized fix backlog ranked by estimated traffic impact, distinguishing quick wins from developer-dependent tasks

**Key concepts:** Screaming Frog user-agent and render modes, custom extraction, structured issue export, redirect chains vs redirect loops, broken link detection, duplicate content signals, thin-content thresholds, GSC cross-reference, traffic-impact prioritization

**Hands-on exercise:** Crawl a provided sample site (or instructor export), identify the top five issues by category in Screaming Frog, cross-reference two of them against a sample GSC Coverage export, and produce a two-tab backlog spreadsheet: Tab 1 quick wins (SEO-team executable, <1 day), Tab 2 developer tickets (scoped for sprint planning).

---

## Chapter 3: Core Web Vitals & Page Performance Optimization

**Duration:** ~50 min
**Learning objectives:**
- Measure LCP (<2.5 s), INP (<200 ms), and CLS (<0.1) on mobile using PageSpeed Insights and CrUX field data
- Identify render-blocking scripts, oversized images, and layout-shift culprits using Chrome DevTools Lighthouse
- Write a developer-ready performance brief specifying image format upgrades (WebP/AVIF), lazy-load directives, and script deferral targets
- Validate performance improvements post-deployment using before/after CrUX comparisons in GSC

**Key concepts:** LCP/INP/CLS 2026 thresholds, INP vs FID, PageSpeed Insights lab vs field data, CrUX, Chrome DevTools Lighthouse, render-blocking scripts, WebP/AVIF optimization, lazy-load, layout shift culprits, developer performance brief format

**Hands-on exercise:** Run PageSpeed Insights on a provided URL. Use the Lighthouse Opportunities section to identify one render-blocking script and one oversized image. Write a structured developer brief (problem → impact → fix specification → acceptance criteria) for both findings. Document the CrUX baseline to validate the fix after deployment.

---

## Chapter 4: On-Page Optimization & Structured Data Implementation

**Duration:** ~55 min
**Learning objectives:**
- Audit and rewrite title tags, H1s, and meta descriptions for a set of target pages using search-intent alignment and character-limit rules
- Build and validate JSON-LD structured data (Article, Product, BreadcrumbList) using Google's Rich Results Test and Schema.org guidelines
- Strengthen E-E-A-T signals by adding author entity markup, datePublished/dateModified fields, and publisher schema
- Implement a topic-cluster internal linking structure that distributes link equity from pillar pages to supporting content

**Key concepts:** Title tag character limits, H1 hierarchy, meta description framing, JSON-LD Article/Product/BreadcrumbList, Rich Results Test, E-E-A-T author schema, datePublished/dateModified, publisher schema, pillar-spoke internal link model, link equity distribution

**Hands-on exercise:** Audit five sample pages — rewrite two title tags and one meta description. Write complete JSON-LD for an Article page (with author entity and publisher schema) and validate it in Google's Rich Results Test. Map a pillar-spoke internal link plan for a three-page cluster and specify anchor text for each spoke link.

---

## Chapter 5: Link Strategy: Earning, Auditing & Disavowing Backlinks

**Duration:** ~50 min
**Learning objectives:**
- Export and analyse a backlink profile in Ahrefs or SEMrush, flagging spammy domains by spam score, anchor over-optimisation, and link velocity anomalies
- Build a disavow file for toxic links and submit it via Google Search Console, documenting the rationale for each disavowed domain
- Identify link-earning opportunities (resource pages, digital PR, competitor gap analysis) relevant to the travel and OTA vertical
- Pitch a link-building campaign plan with target sites, outreach templates, and a 90-day acquisition timeline

**Key concepts:** Backlink profile export, referring domain analysis, spam score, anchor text over-optimization, link velocity, disavow file format (domain: prefix), GSC disavow submission, resource page prospecting, digital PR link-earning, competitor backlink gap, OTA link channels, outreach templates

**Hands-on exercise:** Given a sample 200-domain backlink export, flag five toxic domains using spam score and anchor criteria, and write the disavow file. Identify three link-earning opportunities from a competitor gap report. Draft one outreach email for a resource page target in the travel vertical. Outline a 90-day acquisition plan with monthly milestones.

---

## Chapter 6: Developer Collaboration & SEO Change Management

**Duration:** ~45 min
**Learning objectives:**
- Translate technical SEO audit findings into actionable Jira/Linear tickets with acceptance criteria a front-end developer can implement and test
- Create a pre-launch SEO checklist for a site migration covering redirect mapping, staging noindex removal, and GSC re-verification
- Conduct a post-launch audit within 48 hours to detect regressions in crawl access, indexation, or Core Web Vitals
- Monitor GSC and rank-tracking tools for 30-day post-migration signals and prepare a stakeholder performance summary

**Key concepts:** SEO ticket structure and acceptance criteria, developer-executable vs SEO-executable tasks, site migration SEO checklist, redirect mapping, staging noindex removal, GSC re-verification, post-launch 48h audit, 30-day monitoring plan, stakeholder report format

**Hands-on exercise:** Given three Screaming Frog findings from Chapter 2, write three developer-ready Jira tickets (title, description, acceptance criteria, priority). Build a 10-item pre-launch migration checklist for a provided scenario. Define the two GSC queries you would run 48h after go-live and interpret a sample GSC coverage delta.

---

## Capstone: Full Technical SEO Audit & Migration Readiness Report

Using a provided travel brand brief (site crawl export + GSC data + backlink report), learners will: (1) produce a prioritized 10-issue fix backlog using the Chapter 2 audit framework; (2) implement JSON-LD schema for one Article page and validate it; (3) build a disavow file for three flagged domains; and (4) write a migration readiness checklist and a one-page post-launch monitoring plan. Deliverable: a structured audit report (Google Doc or Notion page) plus all code/file artifacts.
