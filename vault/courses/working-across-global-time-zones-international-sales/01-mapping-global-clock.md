---
chapter_num: 1
course_slug: working-across-global-time-zones-international-sales
title: "Mapping the Global Clock: Time Zone Arithmetic and Shift Structures for Client-Facing Roles"
status: g0-passed
last_updated: "2026-07-09"
word_count: 1199
duration_min: 18
vendor_tag: Global Account Management
learning_objectives:
  - "Identify the UTC offset, DST behaviour, and IANA identifier for IST, GST, CET, EST, PST, and SGT"
  - "Calculate pairwise and multi-way overlap windows using the UTC grid method"
  - "Select the correct shift pattern (morning, afternoon, split) for a given client portfolio"
  - "Choose between follow-the-sun and rotating-shift models for a described team scenario"
  - "Configure a world-clock calendar sidebar to display three client regions simultaneously"
sources:
  - url: "https://clockzilla.io/blog/time-zone-abbreviations-explained"
    title: "Time Zone Abbreviations Explained: EST, PST, GMT, CET, IST & More (2026)"
  - url: "https://zonecross.com/guides/timezone-abbreviations/"
    title: "Time Zone Abbreviations Cheat Sheet: EST, PST, CET, IST & More"
  - url: "https://sotalented.com/blog/time-zone-overlap-india-europe-uk-australia"
    title: "Time zone overlap with India from Europe, the UK, and Australia"
  - url: "https://www.nextutils.com/tools/time/working-hours-overlap"
    title: "Working Hours Overlap Calculator — Check PST, EST & Timezone Overlap Free"
  - url: "https://www.piton-global.com/blog/follow-the-sun-support-models-building-24-7-customer-service-excellence/"
    title: "Follow-the-Sun Support Models: Building 24/7 Customer Service Excellence"
  - url: "https://www.keeping.com/content/follow-the-sun-model/"
    title: "Follow the Sun Model Explained"
  - url: "https://onlinetoolguides.com/google-calendar-multiple-time-zones/"
    title: "How to Use Google Calendar with Multiple Time Zones for Remote Teams"
  - url: "https://thesoftwarepro.com/display-multiple-time-zones-in-microsoft-outlook-calendar/"
    title: "How to Display Multiple Time Zones in the Microsoft Outlook Calendar"
owns:
  - "time zone identification (IST, GST, CET, EST, PST, SGT)"
  - "time zone arithmetic and overlap window calculation"
  - "shift pattern classification (morning, afternoon, split)"
  - "follow-the-sun vs rotating-shift model selection"
  - "world-clock calendar configuration for multi-region view"
defers_to:
  - "daily shift schedule design and time-blocking → ch2"
  - "async communication protocols and availability signalling → ch2"
  - "cross-cultural communication norms by region → ch3"
  - "CRM time-zone display widgets and scheduling tools → ch4"
  - "interview/profile evidence of shift flexibility → ch5"
quiz_topics:
  - "calculate overlap window for IST/EST/SGT client trio"
  - "identify correct shift pattern for a given regional portfolio"
  - "distinguish follow-the-sun from rotating-shift and select for scenario"
  - "configure world-clock calendar to show three client regions simultaneously"
notebooklm_source_focus:
  - "commercial time zone standards (IST, GST, CET, EST, PST, SGT) and UTC offsets"
  - "overlap window calculation methodology for global account management"
  - "follow-the-sun coverage models in IT services and sales"
  - "shift pattern design for client-facing roles spanning multiple continents"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "An account manager in Bengaluru (IST, UTC+5:30) manages clients in New York (EST, UTC−5) and Singapore (SGT, UTC+8). All observe 9am–6pm business hours. What is the three-way standard-hours overlap?"
    options:
      - "Zero — IST closes before EST opens, breaking the three-way chain"
      - "1.5 hours — the UTC gap between IST closing and EST opening"
      - "3.5 hours — IST early afternoon aligns across both partner zones"
      - "6.5 hours — the IST–SGT pair anchors all three zones together"
    correct_idx: 0
    explanation: "IST business hours end at 12:30 UTC; EST business hours begin at 14:00 UTC — a 1.5-hour gap means zero standard-hours IST+EST overlap. Without IST+EST overlap, the three-way window is also zero. IST+SGT overlap is 6.5 hours, but EST does not participate."
    section_anchor: overlap-window-calculation
  - question: "A sales rep in Mumbai manages four accounts in Paris, Berlin, Warsaw, and Madrid (all CET, UTC+1 in winter). Which shift pattern best captures the IST–CET overlap window?"
    options:
      - "Morning shift — IST 9am to 3:30pm, catching CET when it first opens"
      - "Afternoon shift — IST 1pm to 7pm, when CET is in its 9am–2:30pm window"
      - "Split shift — IST 9am block plus a separate IST 7pm evening block"
      - "Night shift — IST 11pm onward, waiting for CET to reopen next morning"
    correct_idx: 1
    explanation: "CET 9:00am = IST 1:30pm (UTC+1 vs UTC+5:30). The IST–CET overlap window is 4.0–4.5 hours in winter, running IST 1:30pm–6:00pm. An afternoon shift centred on this window (IST 1pm–7pm) captures the full overlap. A morning shift ends too early; a split shift and night shift are unnecessary complexity for a Europe-only portfolio."
    section_anchor: shift-pattern-classification
  - question: "A software firm has delivery centers in Bengaluru, Amsterdam, and Austin. They need 24/7 account coverage across APAC, EMEA, and Americas. Which coverage model fits?"
    options:
      - "Rotating shifts — cycle Bengaluru reps through night windows on a weekly schedule"
      - "Split shifts — each Bengaluru rep works two non-consecutive blocks each day"
      - "Follow-the-sun — hand off between Bengaluru, Amsterdam, and Austin by region"
      - "Morning-only IST shift — overlapping both EMEA and Americas from one location"
    correct_idx: 2
    explanation: "Three centers roughly 8 hours apart (Bengaluru UTC+5:30, Amsterdam UTC+2, Austin UTC−5) match the follow-the-sun template. Each team works daylight hours and passes open work to the next center. Rotating shifts impose night work; split shifts don't provide 24/7 team-level coverage; a morning IST shift does not reach Americas standard hours."
    section_anchor: follow-the-sun-vs-rotating-shifts
  - question: "How many additional client time zones can a sales rep add to the Google Calendar World Clock sidebar?"
    options:
      - "One — the sidebar displays only a single secondary location"
      - "Two — the sidebar is limited to two secondary locations total"
      - "Three — the sidebar supports three simultaneous World Clock locations"
      - "Unlimited — Google Calendar imposes no cap on World Clock entries"
    correct_idx: 2
    explanation: "Google Calendar's World Clock sidebar supports three simultaneous locations. A rep covering GST, SGT, and CET clients can add all three to the sidebar, labelled by account name for instant reference. Classic Microsoft Outlook also supports three total (your local zone plus two additions); New Outlook and Outlook Online support unlimited zones."
    section_anchor: configuring-your-world-clock-calendar
---

## The Six Commercial Time Zones

Six abbreviations govern scheduling for India-based global sales roles: IST, GST, CET, EST, PST, and SGT. Each maps to a UTC offset — the signed displacement from Coordinated Universal Time, the fixed reference grid used by every calendar application and operating system on the planet.

| Zone | Full Name | UTC Offset | DST? | IANA Identifier |
|------|-----------|------------|------|-----------------|
| IST | India Standard Time | +5:30 | No | Asia/Kolkata |
| GST | Gulf Standard Time | +4:00 | No | Asia/Dubai |
| CET | Central European Time | +1:00 (winter) / +2:00 CEST (summer) | Yes | Europe/Berlin |
| EST | Eastern Standard Time | −5:00 (winter) / −4:00 EDT (summer) | Yes | America/New_York |
| PST | Pacific Standard Time | −8:00 (winter) / −7:00 PDT (summer) | Yes | America/Los_Angeles |
| SGT | Singapore Time | +8:00 | No | Asia/Singapore |

Two facts carry the most scheduling risk. IST's half-hour offset (+5:30) makes arithmetic with full-hour zones non-intuitive — always compute via UTC rather than estimating. Three zones observe daylight saving time: CET, EST, and PST each shift one hour in summer; IST, GST, and SGT never shift, so IST–CET and IST–EST overlap windows change seasonally even though India's clock stays fixed. In software, use IANA identifiers rather than abbreviations: "IST" can resolve to India, Ireland, or Israel depending on the application. [Time Zone Abbreviations Explained: EST, PST, GMT, CET, IST & More (2026)](https://clockzilla.io/blog/time-zone-abbreviations-explained)

## Overlap Window Calculation

An overlap window is the slice of time when two parties are simultaneously within their defined business hours. Compute it by converting both parties to UTC and finding the intersection:

`overlap = min(UTC_end₁, UTC_end₂) − max(UTC_start₁, UTC_start₂)`

If the result is zero or negative, no standard-hours overlap exists.

The most instructive case for Indian sales teams is the IST/EST/SGT trio. Assuming 9:00am–6:00pm local business hours everywhere:

| Location | UTC Start | UTC End |
|----------|-----------|---------|
| Bengaluru (IST, UTC+5:30) | 03:30 | 12:30 |
| New York (EST, UTC−5:00) | 14:00 | 23:00 |
| Singapore (SGT, UTC+8:00) | 01:00 | 10:00 |

IST+SGT: min(12:30, 10:00) − max(03:30, 01:00) = 10:00 − 03:30 = **6.5 hours** (IST 9:00am–3:30pm). IST+EST: EST opens at 14:00 UTC; IST closes at 12:30 UTC — a 1.5-hour gap means **zero overlap**. The three-way window is also zero. [Time zone overlap with India from Europe, the UK, and Australia](https://sotalented.com/blog/time-zone-overlap-india-europe-uk-australia)

This is a structural fact, not a scheduling failure. IST and EST business cycles do not overlap at standard hours — no amount of calendar wrangling changes the UTC arithmetic. The right response is to choose a shift pattern that accommodates it.

<KnowledgeCheck question="An account manager in Bengaluru (IST, UTC+5:30) serves a Singapore client (SGT, UTC+8). Both observe 9am–6pm business hours. What is their standard overlap window?" options={["Zero — the time difference makes same-day overlap impossible", "3.5 hours, covering SGT 9:00am to SGT 12:30pm local time", "6.5 hours, covering IST 9:00am through IST 3:30pm local time", "8.0 hours — nearly the full standard business day"]} correctIdx={2} explanation="IST 9am = 03:30 UTC; SGT 6pm = 10:00 UTC. Overlap = 03:30–10:00 UTC = 6.5 hours. In IST local time this is 9:00am–3:30pm; in SGT it is 11:30am–6:00pm." />

## Shift Pattern Classification

Once you know where the overlap windows fall in your calendar, three patterns cover virtually every client portfolio:

**Morning shift** (IST 9:00am–3:30pm): Captures the full 6.5-hour IST–SGT window and most of the IST–GST overlap (~7.5 hours). The right choice for APAC-only or APAC+Gulf portfolios.

**Afternoon shift** (IST 1:00pm–7:00pm): Targets the IST–CET window, which runs 4.0–4.5 hours in winter (CET 9:00am = IST 1:30pm) and narrows to ~3.5 hours in summer when CET becomes CEST. Correct for European-only portfolios.

**Split shift**: Two non-consecutive work blocks in the same calendar day. For an APAC+Americas book of business, a split of IST 9:00–11:00am (SGT coverage) and IST 7:00–10:00pm (EST 8:30–11:30am coverage) eliminates the need for a night shift while preserving two high-value call windows. The mid-day gap becomes protected time for deep work or account preparation.

<Callout type="warning">
A split shift solves the IST+Americas coverage problem at near-zero cost — but only if the schedule is formally documented. Informal split arrangements tend to accumulate morning meetings in the first block and extend evening calls in the second. Get the hours, the protected gap, and the shift allowance (if any) in writing before you commit.
</Callout>

When a portfolio spans all three regions with no after-hours flexibility, no single IST shift covers SGT, CET, and EST simultaneously. That is the structural trigger for the model described next.

## Follow-the-Sun vs Rotating Shifts

Both models extend coverage beyond a standard working day. The right choice turns on team geography and tolerance for night work.

**Follow-the-sun (FTS)** distributes teams across centers roughly eight hours apart — typically APAC, EMEA, and Americas. Each team works normal daylight hours and hands open accounts to the next center at day's end, eliminating night shifts. [Follow-the-Sun Support Models: Building 24/7 Customer Service Excellence](https://www.piton-global.com/blog/follow-the-sun-support-models-building-24-7-customer-service-excellence/) reports FTS reduces attrition by 35–40% over night-shift staffing because daylight roles attract stronger candidates. FTS requires at least two geographically distributed partner teams and 12–18 months before full ROI is realized — it is an organizational architecture, not a single-rep scheduling fix.

**Rotating shifts** keep all staff at one location and cycle personnel through morning, afternoon, and evening windows on a set roster. Night coverage is unavoidable when the time zone span exceeds roughly 14 hours. Night rotations carry real costs — error rates 37% higher and absenteeism 42% higher than daytime windows — but rotating shifts can be operational within weeks and require no partner offices or geographic expansion.

**Selection rule**: Choose FTS when your firm needs continuous 24/7 coverage and already has (or plans to hire) regional partner teams. Choose rotating shifts when the team is single-location and the coverage window is bounded. Choose a split shift when one rep needs two live windows per day and no roster rotation is required.

<KnowledgeCheck question="A three-rep India sales team needs to cover US East Coast (EST) client calls five days a week. They have no partner offices abroad. Which model fits?" options={["Follow-the-sun using three geographically distributed regional centers", "Morning IST shift, since IST 9am naturally overlaps EST business hours", "Rotating shift, cycling reps through structured evening IST windows weekly", "Split shift, with each rep personally working two non-consecutive daily blocks"]} correctIdx={2} explanation="FTS requires geographically distributed partner offices — this team has none. Morning IST shift ends at 12:30 UTC; EST business hours begin at 14:00 UTC, leaving a 1.5-hour gap. A rotating shift is the correct single-location model: reps cycle through evening IST slots (7pm–11pm IST = 8:30am–12:30pm EST) on a structured roster. A split shift applies to individual reps, not to team-level roster planning." />

## Configuring Your World-Clock Calendar

The right calendar setup surfaces overlap windows at a glance so you are not re-computing them from memory each morning.

In **Google Calendar**, open Settings → World Clock and add up to three locations. Label each slot with the client's company name rather than the generic city name — so the sidebar reads as a live account reference throughout your day. [How to Use Google Calendar with Multiple Time Zones for Remote Teams](https://onlinetoolguides.com/google-calendar-multiple-time-zones/)

In **Microsoft Outlook** (classic desktop), go to File → Options → Calendar → Time zones and add up to two additional zones beneath your local zone, giving three total. New Outlook and Outlook Online support unlimited additional zones via the same settings path. [How to Display Multiple Time Zones in the Microsoft Outlook Calendar](https://thesoftwarepro.com/display-multiple-time-zones-in-microsoft-outlook-calendar/)

In both tools, select zones by full location name (`Asia/Singapore`, `America/New_York`, `Europe/Berlin`) so DST transitions apply automatically for CET, EST, and PST while your IST clock stays fixed.

---

## Hands-on Exercise: Build Your Overlap Map

**Setup:** You are an account manager in Hyderabad (IST). Three active accounts: TechCorp Dubai (GST, UTC+4), FinBank Singapore (SGT, UTC+8), MedGroup Berlin (CET, UTC+1, winter). Standard hours 9:00am–6:00pm local everywhere.

**Steps:**
1. Convert each client's 9:00am–6:00pm window to UTC.
2. Calculate each pairwise overlap with IST and express it in IST local time.
3. Determine whether a standard 9:00am–6:00pm IST day shift covers all three windows or whether a split or afternoon shift is needed.
4. Add all three client zones to your calendar's World Clock sidebar, labelled by account name.

**Success criteria:** IST–GST overlap ≈ 7.5 hours (IST 10:30am–6:00pm); IST–SGT overlap = 6.5 hours (IST 9:00am–3:30pm); IST–CET overlap ≈ 4.5 hours (IST 1:30pm–6:00pm). You correctly identify that a standard 9:00am–6:00pm IST day shift covers all three client windows without a split or evening extension. Your calendar shows all three client zones labelled by account name.

Once your overlap map is built, the next challenge is structuring those hours into a productive daily schedule — time blocking, deep-work protection, and async handoffs. That is the focus of [[02-structuring-shift-ready-workday]].
