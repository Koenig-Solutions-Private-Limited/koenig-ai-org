---
title: "GTM v2 — Career Compass by Koenig"
status: approved
owner: growth-lead
approved_by: vardaan
updated: 2026-06-11
tags: [gtm, marketing, strategy]
---

# GTM v2 — "Career Compass by Koenig" (enterprise-grade, fully AI-agent-operated)

## 2026-06-12 amendment — domain split

The Career Compass vertical now serves from its own domain, **academy.koenig-solutions.com** (repo `Koenig-Solutions-Private-Limited/koenig-career-academy`). The organic academy stays on **academy.kspl.tech** (learnovaBeast). One vault feeds both; course outlines tagged `course_track: career` publish to the new domain.

Implications for GTM:
- **Career-vertical destinations are now academy.koenig-solutions.com.** Certificate links, readiness-card share links, and referral links (`?via=`) mint on the new domain.
- **pSEO `/skills` pages stay on academy.kspl.tech** (organic SEO equity stays with the established domain). Their CTAs point **cross-domain** to academy.koenig-solutions.com for the gap-analysis funnel.
- Everything below describes the strategy and remains in force; only the career-funnel host changes. Where the body still says academy.kspl.tech for career flows, read it as academy.koenig-solutions.com.

## Context

Mission: help job-seekers get jobs — free AI gap analysis (CV + job posting), free personalized generated courses, skill checks, interview prep, verifiable certificates. India-first; B2C job-seekers + recruiters/TPOs; organic-first with ₹10–20k/mo; **everything designed, executed, measured, and iterated by AI agents** (this session + Paperclip org). Human steps: one-time account creation (Vardaan, with Chrome assistance), pressing "send" on human-fronted channels (Reddit/HN/Quora), and the daily digest.

**Research-verified moat (June 2026): no competitor closes our loop** (Jobscan/Teal stop at scores; Resumly/WorkSchool gap reports end in Coursera links; Simplilearn SkillUp = generic certs; Scaler = ₹2–3L + toxic sales reputation). **Door-opener: Koenig = Microsoft Training Services Partner of the Year 2025** — leads every pitch, post, and partner application.

This v2 adopts the enterprise GTM operating model (Microsoft/AWS/Cisco patterns, researched + adapted): message house, launch tiers, PR/FAQ discipline, champions program, partner motion, Amazon-style WBR — each run by agents.

## 1. Message House (the source of truth for ALL content agents)

Stored as `vault/_brand/MESSAGE-HOUSE.md`; injected into every content-producing agent's instructions; proof points refreshed monthly from live metrics.

**Roof:** *"Career Compass shows you exactly what stands between your CV and the job you want — then closes the gap with a free personalized course and a verifiable certificate, in days not months."*

| Pillar 1: Precision | Pillar 2: Speed-to-credential | Pillar 3: Trust |
|---|---|---|
| "It analyzes MY CV against a REAL job posting — not generic advice" | "Gap report in 2 minutes; course + verifiable certificate in days; free forever" | "Backed by Koenig — 30 yrs IT training, Microsoft Training Partner of the Year 2025" |
| Proof: mechanism + sample report | Proof: N reports / N certs / median completion (live counters) | Proof: award, public /verify pages, named employers who recognize certs |

**Two persona overlays:** Job-seeker (leads Pillar 1, mechanism-first, "try in 2 min, no payment ever"); Recruiter/TPO (leads Pillar 3, outcomes: "see your batch's aggregate gaps, verify any candidate in one click, zero cost"). Differentiation line: *"Unlike LinkedIn Learning or MOOCs, Career Compass starts from a specific job posting and proves the gap was closed."* **Banned claims:** placement rates, salary promises.

## 2. GTM operating model (agent-run, enterprise mechanics)

- **Launch tiers** (launch agent enforces checklist gates):
  - **Tier 1** (2/yr, timed to India hiring seasons — next: **placement season, July**): PR/FAQ approved → launch page ("mini Book of News") + blog + 90-sec demo video + learner stories + social asset pack + email blast + Peerlist/Product Hunt/Show HN + PR pitches + TPO webinar kit. Nothing ships until the checklist is green.
  - **Tier 2** (monthly: new domains, report v2): lightweight PR/FAQ → blog + changelog + 1 social asset + in-product banner.
  - **Tier 3** (weekly): auto-written "What's New" changelog feed (SEO-compounding page).
- **PR/FAQ discipline (Amazon working-backwards):** every Tier-1/2 item gets an agent-drafted future press release + internal FAQ red-teamed at G3 before build; the PR becomes the launch blog.
- **WBR (Amazon-style, agent-operated):** Sunday 00:00 IST a metrics agent generates a 6–12 chart deck (6-week + 12-month trails, targets) from PostHog/GSC/channel APIs → exception-only annotations ("routine variance" / "investigating" — confabulation banned) → Monday human reads exceptions in 10 min via digest. **Inputs managed, outputs tracked**: agents are goaled on controllable inputs (posts published, TPO emails sent, share-rate, verification-page visits), not signups. Quarterly: agent-drafted 6-page OP1-style narrative; drop input metrics that didn't prove causal.
- **North star:** weekly job-seekers completing ≥1 chapter.

## 3. The five growth loops (priority order)

1. **Certificate → LinkedIn** (zero competitors): share rail + OG card on certificates + "Add to LinkedIn" deep link (`linkedin.com/profile/add?startTask=CERTIFICATION_NAME&organizationId=<page>&certUrl=<verify>`) + post-issuance email within 1 hour with pre-written LinkedIn post copy (the moment of pride = moment of sharing). Public crawlable /verify pages = recruiter top-of-funnel.
2. **Shareable gap report** (16Personalities mechanic): opt-in public readiness card — match %, archetype, gap chips, NO PII — OG card + share rail; score visible pre-signup.
3. **Programmatic SEO + GEO** (roadmap.sh model): `/skills/[role]` hubs, interview-question banks, downloadable **"Koenig Gap Sheets"** (the Striver-SDE-Sheet forwardable artifact), quarterly **"India Skills Gap Index"** data report (the PR magnet — we sit on unique CV×JD gap data). Bing Webmaster + IndexNow; direct-answer leads + tables (2.3× AI-citation lift); emit existing `faqPageLd()`.
4. **Community answer engine**: agent-drafted, human-fronted where required (see channel plan).
5. **Recruiter/TPO B2B2C**: "Campus Partner" program (NetAcad-in-miniature) — co-branded `/campus/[college]` page, **TPO dashboard of their batch's aggregate skill gaps** (the killer asset no TPO has seen), bulk invites, monthly gap report as retention. Staffing-firm pitch: send rejected candidates a gap report instead of a rejection.

## 4. Channel plan (top-10 by impact × feasibility; full research in session notes)

| # | Channel | Mode | First action |
|---|---|---|---|
| 1 | **Telegram fresher-job channels** (100k–500k subs: Freshershunt, FresherOffCampus, Placement Fellas…) + own bot channel "Career Compass Daily" (one real JD + its gap, daily) | Agent-automated (Bot API); ₹10–20k buys shoutouts | Admin outreach w/ ready-made post; stand up own channel |
| 2 | **r/developersIndia** (~1.5M) | Human-fronted; agents draft | Message mods re Showcase Sunday / AMA ("Microsoft Partner of the Year built a free career-gap tool") |
| 3 | **Unstop** (17M students; orgs host free challenges) | One-time setup, then agent-run | Register org; host "Career Gap Challenge" |
| 4 | **LinkedIn newsletter "The Skills Gap Weekly"** from Academy page (newsletters = only compounding LinkedIn surface; email+push per edition) + 1–2 page posts/day via official API | Agent-automated post-G3 | Page + Community Mgmt API app (setup C) |
| 5 | **Peerlist Launchpad** (Indian builder network, weekly launches) | One-time + repeatable | Launch next Monday window; precedes PH |
| 6 | **GeeksforGeeks Write Portal** (open contributor program; ranks brilliantly on Indian dev queries) | Agent-drafted, human-submitted | 2 genuinely useful articles ("skills-gap analysis against a job posting") |
| 7 | **Inc42 / YourStory / AIM / EdTechReview PR** + HARO-successors (Source of Sources, Qwoted, Featured — agent monitors, human approves quotes) | Agent-drafted pitches | Pitch the award + Skills Gap Index story |
| 8 | **AI directories batch** (Toolify free, Futurepedia, AlternativeTo, TAAFT if budget) + dev.to/Hashnode/Medium canonical crossposts + daily.dev squad | Agent-automated forms/APIs | One batch afternoon; permanent backlinks/GEO |
| 9 | **TPO/Campus program** + background: **Skill India Digital (NSDC) + AICTE NEAT applications** (Koenig's pedigree clears committees) + **Microsoft partner directory/Tech Community** listing | Agent outreach; corporate paperwork human | 10 TPO emails/wk pilot; start SIDH/NEAT forms |
| 10 | **Show HN + Product Hunt** (one proper cycle; gap report must work without email gate; HUMAN answers comments — explicit HN norm) | Agent prepares everything; Vardaan fronts | After Peerlist dry run, during Tier-1 week |

**Skip** (researched, deliberate): Blind, Workplace SE, LinkedIn Groups (~90% dead), Fishbowl, TimesJobs/Shine/foundit "communities", X/Twitter API ($0.20/URL-post), mass Quora link-dropping (AI moderation = account-fatal; owned Quora Space + slow aged answers instead). WhatsApp Channel: keep as low-effort mirror of Telegram content.

## 5. Workstream A — Product growth surfaces (learnova-academy; Claude implements)

Existing to reuse: `share-rail.tsx` (blog-only today), `/api/og/route.tsx` (parameterized cards), `faqPageLd()` (built, unemitted), Resend + audience, PostHog funnel events, `/career/ops` patterns, catalogIndex/static catalog (vault absent in lambdas!).

- **A1 Certificate virality**: share rail + `/api/og?type=certificate` + Add-to-LinkedIn deep link + post-claim "Close your next gap →" CTA + post-issuance share email (1hr).
- **A2 Report readiness card**: opt-in public share page (PII-stripped) + OG card + share rail + PostHog `report_shared`.
- **A3 Referral**: `?via=<code>` on all share URLs → PostHog person property + R2 counter; reward = priority course generation.
- **A4 Email lifecycle (Resend)**: welcome → day-2 chapter nudge → course-ready (exists) → 50% nudge → cert congrats w/ share copy → day-7 next-gap. UTM auto-capture.
- **A5 pSEO**: `/skills/[role]` hubs (25 roles → 100+), interview-question banks from anonymized generated quizzes, Gap Sheet PDFs, "What's New" feed page, quarterly Skills Gap Index page. IndexNow ping on publish.
- **A6 GEO hardening**: direct-answer leads, tables, `faqPageLd()` emission, `dateModified` everywhere.
- **A7 Live proof counters**: public stats (reports generated, certs issued) for the message-house proof points + launch page.

## 6. Workstream B — Distribution org (Paperclip)

**Hire 2 agents** (one per day per org rules; paperclip-create-agent flow):
1. **Growth Lead** (Sonnet) — owns the WBR (Sunday deck gen, exception annotations), channel mix, experiment tickets, Telegram shoutout proposals (board approval per spend), quarterly OP1 narrative, Compass Ambassadors program ledger.
2. **Distribution Writer** (Sonnet/Haiku) — daily: LinkedIn page posts + newsletter editions, Telegram/WhatsApp broadcasts, dev.to/Hashnode/Medium crossposts, directory submissions, GfG/Quora/Reddit DRAFTS for human fronting, HARO-successor quote drafts. All public posts → G3 CEO gate → API publish → `vault/marketing/social-posts/<date>.md` → EOD digest.

**Mandate updates** (one agent per step): Chief Marketing/SEO adds Bing/IndexNow + channel analytics; Editor in Chief gates social voice via STANCES.md + MESSAGE-HOUSE.md; Blog Author gets quarterly Skills-Gap-Index brief. New scripts: `koenig-ai-org/scripts/social-distribute.mjs` (LinkedIn Posts API, Telegram Bot API, dev.to/Hashnode APIs, IndexNow; creds via .env.koenig per env contract). Official APIs only.

**Community program — "Compass Ambassadors / Champions"** (MLSA/AWS-Builders mechanics, agent-operated): quarterly cohorts ~50, contributions ledger (LinkedIn posts, campus session, 25 referrals via code) → badge on certificate, early access, Koenig cert voucher (the upsell bridge), LinkedIn recommendation; invite-only Champions tier (~10) named in PR. Agent runs applications, ledger, renewal scorecards, "Meet our newest Ambassadors" posts.

## 7. Workstream C — One-time human setup (Vardaan + Chrome assistance)

1. Gmail account for the Academy → anchors everything below.
2. LinkedIn: Academy page (or Koenig showcase) + Developer app w/ Community Management API; note `organizationId`.
3. Telegram channel + BotFather bot → token.
4. WhatsApp Business → Channel.
5. Peerlist org profile; Unstop organization account; GeeksforGeeks contributor; dev.to/Hashnode/Medium; Quora (+ Space "AI Careers India"); daily.dev squad.
6. Bing Webmaster verify; G2 free profile (recruiter side); AI-directory accounts.
7. Corporate (background, Koenig staff may own): SIDH/NSDC Training Provider registration; AICTE NEAT application; Career Compass added to Koenig's Microsoft partner listing.
All keys → .env.koenig operator block (env contract). I assist via Chrome for form-filling wherever Vardaan prefers (he stays the account owner; credentials/payment/identity steps are his).

## 8. Workstream D — Tier-1 Launch Week (placement season, July)

Agent-prepared, checklist-gated: PR/FAQ → launch page (mini Book of News listing every capability w/ screenshots) → demo video (90s, from existing course media pipeline) → 5 learner stories (from Yash + early users, consented) → social asset pack → email blast → Peerlist Monday → Product Hunt Tue–Thu 12:01 AM PT → Show HN (no signup gate for the gap report; Vardaan answers comments) → Inc42/YourStory/AIM pitches (award + Index angle) → TPO webinar kit → Telegram shoutout burst (the ₹10–20k). 

## 9. Rollout

- **Week 1**: A1+A2+A7 ship; C accounts; hire Growth Lead + Distribution Writer; MESSAGE-HOUSE.md + STANCES update; own Telegram channel + LinkedIn cadence live; AI-directory batch; Peerlist launch.
- **Week 2–3**: A3+A4; first 25 `/skills/` pages + 5 Gap Sheets; GfG articles; Quora Space; WBR v1 running; TPO email pilot; r/developersIndia mod outreach.
- **Week 4 (launch week)**: Tier-1 stack executes; Telegram shoutout burst; PR pitches; Show HN/PH.
- **Week 5–8**: pSEO →100+ pages; Skills Gap Index v1 + PR wave 2; Campus Partner dashboard; Ambassadors cohort 1; NEAT/SIDH progressing; budget reallocation per WBR data.

## 10. Verification

- Each A-item: tsc + deploy + live URL + PostHog event observed (today's funnel-verification pattern).
- Distribution: posts G3-gated, API response URLs logged in vault, visible in EOD digest.
- WBR deck generated from real PostHog/GSC data by week 2; week-4 checkpoint decides budget deploy; loop kill/scale decisions agent-made, digest-surfaced.

## 11. Guardrails

- Human-fronted at point of posting: Reddit, HN, Quora answers, Discord (platform norms ban AI-voiced posting; agents draft + monitor only).
- LinkedIn official API only, 1–2 page posts/day, format rotation; no browser automation.
- Share pages PII-stripped, opt-in; anonymous-by-default invariant intact; certificates noindex except opt-in share/verify surfaces.
- No placement-rate/salary claims ever. All public posting behind G3; spends behind board approval. Per-sub rule check before any community post.
