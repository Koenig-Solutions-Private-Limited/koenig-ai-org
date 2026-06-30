---
title: "Press Playbook — Career Compass"
status: active
owner: chief-marketing-seo
updated: 2026-06-15
tags: [brand, gtm, press, pr]
---

# Press Playbook — Career Compass

How the CMO (and team) produce and distribute press releases for **Career Compass** (academy.koenig-solutions.com). Scope is Career Compass only for now; academy.kspl.tech press is deferred. Gate every release against [[MESSAGE-HOUSE]] — same banned-claims rules, same proof-point discipline.

## What a press release is here

A press release is a `status: published` markdown file at `koenig-ai-org/vault/press/<YYYY-MM-DD>-<slug>.md`. The career app renders it at `/press/<slug>` with `NewsArticle` JSON-LD on build (see `koenig-career-academy/src/lib/press.ts`). It flows through the same vault→deploy pipeline as blogs.

### Frontmatter (required)

```yaml
title: "<internal editorial title>"
status: draft | in_review | approved | published   # only `published` renders
headline: "<≤110 chars, active voice, the news>"
subhead: "<one line, ≤140 chars, no repetition of headline>"
dateline: "NEW DELHI, India — June 15, 2026"
summary: "<the lede, ≤160 chars; used as meta description + index summary>"
quote: "<one authentic spokesperson quote, 1–2 sentences>"
quote_attribution: "<Name, Title, Koenig AI Academy>"
cta_label: "Try Career Compass — free"
cta_url: "https://academy.koenig-solutions.com/career"
slug: <kebab-case>
published_at: 2026-06-15
tags: [product, career-compass, ...]
distribution_log: []   # audit only — appended by the wire/IndexNow steps; never rendered
```

### Body structure (≤400–500 words)

1. **Lede** (30–50 words) — answers the 5 Ws in the first sentence (answer-first for GEO).
2. **2–3 short paragraphs** — context, the mechanism, who it's for.
3. **One `## About` section at the end** — the boilerplate verbatim from [[MESSAGE-HOUSE]].

The headline must read as *news*, not a slogan. The single biggest failure mode is a promotional/slogan headline a journalist deletes on sight — lead with what is new and verifiable.

## Hard rules (gate at G3 — Chief Content, then CEO)

- **No fabricated numbers.** Cite only [[MESSAGE-HOUSE]] proof points or verifiable facts (e.g. "Microsoft Training Services Partner of the Year 2025", "30 years", "6+ courses generated end-to-end"). If a number isn't in the message house's monthly-refreshed metrics, don't print it.
- **No placement-rate, job-guarantee, or salary-uplift claims, ever.**
- **No disparaging named competitors.**
- **Real quotes only.** Attribute to a named spokesperson who has approved the quote. For VIP-initiated releases, Rohit approves; otherwise the CEO agent approves on the org's behalf.

## Approval & cadence

- **Routine milestone releases**: CMO drafts → Chief Content editorial review (this playbook + [[MESSAGE-HOUSE]]) → CEO/board approval → publish. Auto-publishes on the internal gate; Rohit is notified, not blocking.
- **Rohit-initiated releases**: same internal review first, then shown to Rohit (Telegram + email) for his approval before publish.
- **Cadence**: milestone / major-accomplishment driven, ≥ weekly when there is real news; a monthly digest consolidates smaller updates. Quality over volume — skip a week rather than ship non-news.

## Distribution

1. **Owned newsroom (autonomous)** — publishing the vault file makes `/press/<slug>` live on deploy. Run the IndexNow ping:
   ```bash
   node scripts/press-publish-ping.mjs <slug>
   ```
   The release is also in `sitemap.xml` automatically.
2. **Free wires (handheld)** — PRLog and openPR. Accounts are created by the operator (Vardaan) once; the CMO drafts the wire copy from the same release; submission is done via the web form (operator or assisted). Record the live wire URL back into the release's `distribution_log`.
   - These give nofollow links of limited SEO weight — the owned newsroom carries the real value; wires are amplification.
3. **Formal draft delivery** — for review, the CMO emails the draft from its official address (Resend) and posts it to the VIP Telegram channel with Approve/Request-changes buttons.

## Accounts / credentials (operator-provisioned)

| Channel | Who creates | Notes |
|---|---|---|
| PRLog | Vardaan | free; web-form submit |
| openPR | Vardaan | free; 1/month free tier |
| IndexNow | done | key file committed in career app `public/` |
| Resend (CMO from-address) | Vardaan | `cmo@kspl.tech`; domain DKIM-verified |
