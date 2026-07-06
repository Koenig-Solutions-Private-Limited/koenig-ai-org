---
chapter_num: 5
course_slug: ppc-team-leadership-analyst-onboarding-and-workflow-design
title: "Coaching Analysts Through Performance Gaps and Running Structured 1-on-1s"
status: awaiting-g0
duration_min: 22
vendor_tag: Google Ads
learning_objectives:
  - "Build a data-driven coaching brief using CTR and CPA trends before each analyst 1-on-1"
  - "Distinguish skill gaps from tool/access gaps and workload-distribution problems using a three-question diagnostic sequence"
  - "Rewrite vague feedback as SBI statements anchored to specific campaign data and measurable impact"
  - "Set specific, measurable two-week sprint targets and run a mid-point check-in on Day 7"
  - "Design a three-domain quarterly scorecard that separates KPI outcomes from analysis quality and process adherence"
sources:
  - url: "https://www.wordstream.com/blog/2025-google-ads-benchmarks"
    title: "Google Ads Benchmarks 2025: Competitive Data & Insights for Every Industry"
  - url: "https://www.ccl.org/articles/leading-effectively-articles/sbi-feedback-model-a-quick-win-to-improve-talent-conversations-development/"
    title: "SBI Feedback Model & Talent Development Conversations"
  - url: "https://www.performanceconsultants.com/resources/the-grow-model/"
    title: "A Complete Guide to the GROW Coaching Model"
  - url: "https://www.aihr.com/blog/skills-gap-analysis/"
    title: "Skills Gap Analysis: All You Need To Know [FREE Templates]"
  - url: "https://asana.com/resources/performance-improvement-plan-template"
    title: "Performance Improvement Plan Template"
  - url: "https://www.cultureamp.com/blog/one-on-one-meeting-template"
    title: "One-on-One Meeting Template: How to Lead Effective Meetings"
  - url: "https://etumos.com/marketing-automation/the-essential-guide-to-marketing-operations-performance-reviews-with-free-scorecard-template/"
    title: "The Essential Guide to Marketing Operations Performance Reviews (with FREE scorecard template)"
owns:
  - "data-grounded PPC analyst 1-on-1 structure"
  - "coaching brief creation from analyst performance datasets with declining CTR and rising CPA"
  - "diagnosis of skill gaps, tool-access gaps, and workload-distribution problems"
  - "specific, observable, time-bound feedback statements using campaign evidence"
  - "two-week measurable improvement targets for analyst performance gaps"
  - "quarterly PPC analyst performance review scorecard separating KPI outcomes, analysis quality, and process adherence"
defers_to:
  - "reporting automation and Looker Studio dashboards → ch6"
quiz_topics:
  - "turning campaign performance evidence into a coaching brief"
  - "distinguishing skill gaps from access gaps and workload-distribution issues"
  - "rewriting vague feedback into specific, observable, time-bound improvement requests"
  - "setting measurable two-week improvement targets from CTR and CPA data"
  - "weighting KPI outcomes, analysis quality, and process adherence in a quarterly analyst scorecard"
notebooklm_source_focus:
  - "performance coaching frameworks for marketing and analytics managers"
  - "structured 1-on-1 formats for data-driven teams"
  - "PPC analyst performance review scorecard examples"
  - "feedback models using observable campaign data and measurable improvement targets"
word_budget: { min: 800, max: 1200 }
positions: []
# neutral methodology chapter — no current STANCES entries engaged
faq:
  - question: "What is a coaching brief and when should I prepare it?"
    answer: |
      A coaching brief is a one-page document the manager prepares the day before each
      analyst 1-on-1. It contains four parts: the campaign evidence (account, metric, dates),
      a preliminary gap hypothesis (skill, tool/access, or workload — not a verdict), 1-2 open
      GROW Reality questions, and draft two-week targets to negotiate in the meeting. It takes
      about 15 minutes to build. Per the [GROW coaching model](https://www.performanceconsultants.com/resources/the-grow-model/),
      grounding the conversation in data before entering the room prevents defensive reactions
      and produces actionable commitments.
  - question: "How do I tell whether an analyst has a skill gap or a tool-access gap?"
    answer: |
      Use the three-question diagnostic sequence in order: (1) "Do you have access to X?"
      before (2) "Do you know how to do X?" before (3) "How often are you doing X?" If an
      analyst cannot pull GA4 cohort data because the property is not linked to their Google
      Ads account, training sessions will not fix it — the permission must be provisioned first.
      Per [AIHR's skills gap analysis framework](https://www.aihr.com/blog/skills-gap-analysis/),
      premature coaching (reaching for training when the root cause is missing access) is the
      most common mis-triage managers make.
  - question: "What makes a two-week sprint target measurable?"
    answer: |
      A well-formed sprint target names the exact action, a day-specific deadline, a numeric
      baseline and success threshold, and a verification artefact. Example: "Refresh RSA
      headlines on all ad groups with CTR below 5% by Day 5; bring account CTR from 5.1% to at
      least 6.0% by Day 14, confirmed in the weekly performance report." A target like "improve
      CTR on Account A" fails all four criteria. Per [Asana's PIP guidance](https://asana.com/resources/performance-improvement-plan-template),
      the pre-PIP two-week sprint needs 2-3 tightly defined, observable targets with explicit
      success criteria defined in advance.
quiz:
  - question: "An analyst's Account A CTR fell from 7.8% to 5.1% while impressions held steady over six weeks. What is the correct first section of your coaching brief for the upcoming 1-on-1?"
    options:
      - "A statement of intent naming the agenda for the 1-on-1, so the analyst knows the meeting will cover recent performance and new campaign goals for the quarter ahead"
      - "A summary of the analyst's general attitude toward data, noting whether she tends to act on metric changes or usually waits for explicit manager direction"
      - "The campaign evidence with specific dates and metric deltas, followed by a preliminary gap hypothesis — not a verdict, but a starting-point question to negotiate in the room"
      - "A list of industry benchmark comparisons calling out every metric where the analyst falls below the Google Ads cross-industry average of 6.66% CTR"
    correct_idx: 2
    explanation: "The first section of a coaching brief is always evidence — specific account, dates, and the measurable delta. The gap hypothesis follows as a provisional question, not a conclusion. Agenda statements and benchmark comparisons belong later, if at all."
    section_anchor: build-the-coaching-brief-before-you-enter-the-room

  - question: "An analyst's CPA has risen 25% this quarter. She says she cannot pull GA4 cohort data, and you verify her GA4 property is not linked to her Google Ads account. What type of gap is this?"
    options:
      - "A skill gap — she lacks knowledge to configure the GA4 and Google Ads integration, so the fix is a structured training session on the GA4 setup process"
      - "A workload distribution gap — managing too many accounts means she has no time to set up or maintain GA4 cohort reporting correctly across all of them"
      - "A tool/access gap — she is likely capable of running the report but is blocked by a missing system permission, which a training intervention will not fix"
      - "A process adherence gap — she should have caught and escalated the missing GA4 link in her weekly performance report rather than waiting for the quarterly 1-on-1"
    correct_idx: 2
    explanation: "When an analyst cannot access data she knows how to use, the gap is in permissions, not skill. Diagnosing it as a skill gap and scheduling training sessions wastes both parties' time and erodes trust."
    section_anchor: diagnosing-the-gap-skill-tool-access-or-workload

  - question: "A manager tells an analyst: 'Your Account B campaigns have been weak lately. You need to dig deeper into the data.' Which rewrite applies the SBI model correctly?"
    options:
      - "In Account B last week, CVR fell 24% while industry-wide CPC rose only 8%, so I would like to see more detailed root-cause reporting on conversion rate from you going forward"
      - "In Account B's performance report submitted Monday, you flagged a 24% CVR drop but included no GA4 funnel analysis or proposed next step, so we ran the same targeting for nine days without a pivot decision"
      - "Account B was submitted on time, which I appreciate, but the CVR trend is concerning and we should probably schedule time to discuss it more thoroughly in the near future"
      - "Account B CVR dropped 24% against last quarter's baseline, and I need you to find ways to improve conversion performance and report back within the next two to three weeks"
    correct_idx: 1
    explanation: "The SBI rewrite names a specific document and date (Situation), an observable omission (Behavior), and a quantified consequence (Impact). The other options either omit the Situation, soften the Behavior, or skip the Impact entirely."
    section_anchor: from-data-to-feedback-the-sbi-method-with-campaign-evidence

  - question: "After a 1-on-1, you want to set a two-week sprint target for an analyst whose Account A CTR has dropped to 5.1%. Which target is correctly formed?"
    options:
      - "Improve Account A CTR over the next two weeks by reviewing and updating ad copy on underperforming ad groups, then reporting back on any measurable CTR change you can achieve"
      - "Refresh Account A RSA headlines on low-CTR ad groups by Day 5, then confirm account CTR has improved from 5.1% to at least 6.0% by Day 14, documented in the weekly report"
      - "Work on Account A ad quality to return CTR above the 6.66% industry benchmark before the end-of-month review, with a brief progress update in next week's 1-on-1 meeting"
      - "Focus on Account A ad copy quality improvements, test at least two new RSA headline variants per ad group, and share a measurable progress update before the two-week window closes"
    correct_idx: 1
    explanation: "A well-formed sprint target names the exact action (RSA refresh), a day-specific deadline (Day 5), a measurable numeric outcome (5.1% → 6.0%), and a verification method (weekly report). Options A, C, and D are vague on at least one of these dimensions."
    section_anchor: setting-two-week-improvement-targets-that-stick

  - question: "In a three-domain quarterly analyst scorecard, which weighting is most defensible and why?"
    options:
      - "KPI Outcomes 70%, Analysis Quality 20%, Process Adherence 10% — because campaign results are the primary deliverable and should dominate the quarterly performance review"
      - "KPI Outcomes 30%, Analysis Quality 40%, Process Adherence 30% — because KPIs are partly market-driven, while analysis quality and process adherence are both fully analyst-controlled"
      - "KPI Outcomes 50%, Analysis Quality 25%, Process Adherence 25% — because balancing outcomes with analyst behaviour equally seems fair and removes complexity from designing weighted domains"
      - "KPI Outcomes 40%, Analysis Quality 30%, Process Adherence 30% — because outcomes should lead the scorecard, but process and analysis quality both deserve meaningful recognition too"
    correct_idx: 1
    explanation: "KPI Outcomes are partly determined by market conditions the analyst cannot control (e.g., industry-wide CPC rose 12.88% YoY). Over-weighting them punishes analysts for external headwinds. Analysis Quality and Process Adherence are fully analyst-controlled and better predictors of long-term performance."
    section_anchor: the-quarterly-analyst-scorecard-three-domains-one-picture
---

Most coaching conversations fail before they start — not because the manager lacks empathy, but because they walk in without evidence. A hunch that "the numbers look off" produces a defensive analyst and a vague commitment. A coaching brief built from the same data your analyst owns produces a diagnosis you can act on together.

## Build the Coaching Brief Before You Enter the Room

Prepare the brief the day before each 1-on-1. Pull Tier-1 signals from your manager dashboard: impressions, clicks, CTR, and CPA for each of the analyst's accounts. Compare CTR against the analyst's own 90-day baseline first — then against industry benchmarks. The cross-industry average Google Ads CTR is 6.66% (n=16,446 US campaigns, [WordStream Google Ads Benchmarks 2025](https://www.wordstream.com/blog/2025-google-ads-benchmarks)), but Finance & Insurance averages 2.55% CVR versus Auto Repair's 14.67% — benchmarking against fleet averages instead of vertical norms is one of the fastest ways to lose an analyst's trust.

Your brief has four parts:

1. **Evidence** — which specific accounts, which metrics, over what time window
2. **Preliminary gap hypothesis** — skill, tool/access, or workload (a hypothesis, not a verdict)
3. **GROW entry questions** — one or two open Reality questions drawn from the [GROW coaching model](https://www.performanceconsultants.com/resources/the-grow-model/) (Goal → Reality → Options → Will) to probe what actually happened
4. **Draft two-week targets** — written in advance, shared and negotiated in the meeting, not handed down after

The brief takes about 15 minutes to build. Without it, the first 10 minutes of every 1-on-1 burn on locating the same data together — leaving no time for the conversation that matters.

<KnowledgeCheck
  question="An analyst's Account A CTR dropped from 7.8% to 5.1% while impressions held steady over six weeks. What should the 'Gap Hypothesis' section of your coaching brief say?"
  options={["A statement of intent: the 1-on-1 will cover recent performance and set new campaign goals", "A summary of the analyst's general attitude and whether she acts on metric changes proactively", "Stable impressions rule out budget issues — the likely gap is ad copy or Quality Score, to confirm in the 1-on-1", "A list of every metric where the analyst falls below the 6.66% cross-industry CTR average"]}
  correctIdx={2}
  explanation="Stable impressions rule out budget and bidding issues. The ad copy or Quality Score hypothesis is correct — but it stays a hypothesis until the 1-on-1 surfaces the analyst's own account of what happened."
/>

## Diagnosing the Gap: Skill, Tool Access, or Workload

Before you write a coaching plan, you must identify which type of gap you are dealing with — because each one requires a different intervention.

- **Skill gap**: The analyst does not know how to do something. Fix: training, shadowing, or structured review.
- **Tool/access gap**: The analyst knows how but cannot do it — a GA4 property is not linked to her Google Ads account, or a negative keyword list is admin-locked. Fix: permissions change or tool provisioning.
- **Workload distribution gap**: The analyst is capable and has access but is managing more accounts than the team model supports. Fix: redistribution or hiring. (Within the first 90 days, check [[03-onboarding-analysts-30-60-90-ramp]] for Day-45 triage before escalating to redistribution.)

[AIHR's skills gap analysis framework](https://www.aihr.com/blog/skills-gap-analysis/) identifies premature coaching as the most common mis-triage: managers reach for skill training when the root cause is missing access. The diagnostic sequence is three questions in order: (1) "Do you have access to X?" before (2) "Do you know how to do X?" before (3) "How often are you doing X?"

A 31% CVR drop accompanied by only an 8% CPC increase is a signal that warrants access and workload checks before coaching. Industry-wide CPC rose 12.88% YoY — a CPC rise of 8% sits below that trend, which means the CPA pressure here is unlikely to be market-driven. But if the analyst recently absorbed extra accounts and has not been provisioned GA4 access for them, the problem is structural, and coaching it as a skill deficiency will damage the relationship.

<Callout type="warning">
Always confirm tool access before writing a coaching plan. Ask the analyst to share their screen and pull the report you expect them to run. One minute reveals an access gap that three coaching sessions would never fix.
</Callout>

## From Data to Feedback: The SBI Method with Campaign Evidence

Vague feedback is the most common trust-eroder in analyst management. "Your performance has been poor lately" has no Situation, no observable Behavior, and no quantified Impact. The [SBI Feedback Model from the Center for Creative Leadership](https://www.ccl.org/articles/leading-effectively-articles/sbi-feedback-model-a-quick-win-to-improve-talent-conversations-development/) — CCL's programs reach two-thirds of the Fortune 1000, and SBI is among their most-deployed feedback frameworks — solves this by requiring each element:

**Situation**: Name the campaign, account, and date. "In the Account A performance report submitted last Tuesday..."

**Behavior**: Name the observable action or omission. "...you flagged a CTR drop to 5.1% but did not include a root-cause hypothesis or a proposed next step within 24 hours, which is the team standard."

**Impact**: Quantify the result. "...We ran the same underperforming ads for six additional days, continuing to spend budget without a pivot decision."

Then add the SBII extension — "What was happening on your end that made it hard to complete that step?" — before closing. This opens dialogue rather than ending on judgment, and frequently surfaces that the real gap is a process expectation the analyst never knew existed.

<KnowledgeCheck
  question="A manager says: 'Your Account B campaigns have been weak lately — you need to dig deeper into the data.' What is missing from this statement?"
  options={["The Situation only — no account date or reporting context is given", "The Impact only — the consequence of the weak performance is not quantified", "All three components: no Situation, no observable Behavior, and no measurable Impact", "The Behavior only — the specific omission is not named"]}
  correctIdx={2}
  explanation="'Dig deeper into the data' names no specific date or document (no Situation), identifies no observable action or omission (no Behavior), and cites no measurable consequence (no Impact). It will not change behavior."
/>

## Setting Two-Week Improvement Targets That Stick

When a coaching conversation surfaces a genuine gap, close the 1-on-1 with a two-week sprint: 2–3 specific, observable, time-bound targets agreed in the room, not assigned in a follow-up email.

A well-formed target: "Refresh RSA headlines and descriptions on all ad groups with CTR below 5% by Day 5; bring account CTR from 5.1% to at least 6.0% by Day 14, confirmed in the weekly performance report." A poorly formed target: "Improve CTR on Account A."

Structure the sprint with a mid-point check on Day 7 — 10 minutes, not a full 1-on-1. At Day 14, either the metric moved and the sprint closes, or it did not and you escalate to a formal 30-day plan. According to Asana's [Performance Improvement Plan guidance](https://asana.com/resources/performance-improvement-plan-template), the pre-PIP two-week sprint is the standard early-alert structure: 2–3 tightly defined targets, a mid-point check, and explicit success criteria defined in advance. Its value is in catching gaps while they are still correctable without formal documentation (see [[04-campaign-portfolio-accountability-rhythms]]).

## The Quarterly Analyst Scorecard: Three Domains, One Picture

A scorecard that measures only CTR and CPA punishes analysts for market conditions they cannot control and rewards those who happened to inherit strong accounts. Separate the quarterly review into three domains:

| Domain | Weight | What It Measures |
|---|---|---|
| KPI Outcomes | 30% | CTR, CPA, ROAS, Impression Share vs. agreed targets |
| Analysis Quality | 40% | Accuracy of diagnostic write-ups, GA4 integration, recommendation rationale |
| Process Adherence | 30% | Negative keyword hygiene cadence, ad copy rotation, reporting deadlines met |

KPI Outcomes carry the lowest weight because they are partly market-driven. Analysis Quality carries the highest (40%) because it is the best long-term predictor of analyst performance and is entirely within the analyst's control. An analyst whose CTR is flat due to competitive auction pressure but who delivers sharp diagnostic write-ups with GA4-sourced hypotheses is building capability — a KPI-only scorecard misses that entirely. Process Adherence (30%) is a leading indicator: an analyst who maintains negative keyword lists and files reports on time tends to catch CPA drift before it becomes a coaching event.

Share the scorecard template with analysts at the start of the quarter ([Culture Amp 1-on-1 research](https://www.cultureamp.com/blog/one-on-one-meeting-template)). Criteria that arrive as surprises at review time are not evaluation tools — they are grievances waiting to happen.

## Hands-On Exercise

**Goal**: Build a coaching brief and two-week sprint plan for a real or anonymised analyst on your team.

1. Pull six weeks of CTR and CPA data for one analyst account where you have noticed a shift.
2. Check the analyst's 90-day baseline before comparing to any industry benchmark.
3. Confirm the analyst has tool access to investigate the gap — GA4 property linked, read permissions in place.
4. Write the four-part brief: Evidence, Gap Hypothesis, GROW Reality questions, Draft two-week targets.
5. Run the 1-on-1. Update the hypothesis based on what the analyst tells you before agreeing on final targets.

**Success criteria**: Your brief names a specific account, dates, and the metric delta. Your GROW questions are open-ended and cannot be answered yes or no. Your two-week targets follow the format "metric from X to Y by [date], confirmed in [artefact]."

Next chapter: [[06-reporting-automation-ai-assisted-workflows]] covers how to build the reporting infrastructure that makes coaching conversations data-ready every week — automated Looker Studio dashboards, anomaly alerts, and the team workflow shift from manual CSV exports to decision-making.
