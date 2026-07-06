---
chapter_num: 3
course_slug: ppc-team-leadership-analyst-onboarding-and-workflow-design
title: "Onboarding Analysts with a 30-60-90 Day Ramp Plan Tied to Campaign Ownership"
status: g0-passed
duration_min: 10
vendor_tag: "Google Ads / GA4 / Looker Studio"
learning_objectives:
  - "Build a 30-60-90 day PPC analyst ramp plan with phase-specific deliverables and numeric KPI thresholds"
  - "Provision the correct Google Ads, GA4, Looker Studio, and CRM connector access before a new analyst's first day"
  - "Apply the three-category diagnosis framework when a new analyst misses a Day-45 KPI"
  - "Define and enforce the countersign protocol for handing off first solo campaign ownership"
sources:
  - url: "https://support.google.com/google-ads/answer/9978556"
    title: "About access levels in your Google Ads account"
  - url: "https://support.google.com/analytics/answer/9305587"
    title: "GA4 Access and data-restriction management"
  - url: "https://trainual.com/manual/30-60-90-day-onboarding-plan"
    title: "30-60-90 Day Onboarding Plan: A Template for Managers"
  - url: "https://www.allencomm.com/2026/04/successful-onboarding-time-to-productivity-early-performance-signals/"
    title: "Successful Onboarding: Time-to-Productivity + Early Performance Signals"
  - url: "https://we-interactive.com/the-ultimate-ppc-campaign-management-checklist-for-2026/"
    title: "The Ultimate PPC Campaign Management Checklist for 2026"
  - url: "https://www.aihr.com/blog/onboarding-metrics/"
    title: "9 Onboarding Metrics to Track at Your Organization"
  - url: "https://docs.cloud.google.com/looker/docs/studio/roles-and-permissions"
    title: "Looker Studio Roles and Permissions"
owns:
  - "30-60-90 day onboarding plan for a new PPC analyst"
  - "day-by-day and milestone-based deliverables for account audit, campaign QA, and first optimisation recommendation"
  - "access and permissions checklist for Google Ads, GA4, CRM data connectors, and Looker Studio workspaces"
  - "onboarding KPIs including time-to-first-solo-campaign, QA pass rate, and report accuracy score"
  - "day-45 underperformance diagnosis during onboarding and targeted ramp interventions"
  - "handoff from supervised platform tasks to independent live campaign ownership by day 30"
defers_to:
  - "team org design and role boundaries → ch1"
  - "candidate screening and selection → ch2"
  - "ongoing portfolio allocation after ramp completes → ch4"
quiz_topics:
  - "which deliverables belong at day 30, day 60, and day 90 in a PPC analyst ramp plan"
  - "access grants needed before a PPC analyst can work independently on day one"
  - "defining measurable onboarding KPIs and thresholds"
  - "diagnosing whether a day-45 onboarding issue is caused by access, skill, or workload mismatch"
  - "when a new analyst is ready for first solo live campaign ownership"
notebooklm_source_focus:
  - "PPC analyst onboarding plans and 30-60-90 ramp frameworks"
  - "Google Ads, GA4, CRM connector, and Looker Studio access management"
  - "marketing operations onboarding KPI examples"
  - "campaign QA and first optimisation recommendation workflows for new analysts"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which outcome correctly describes the primary Day 30 milestone for a PPC analyst ramp plan?"
    options:
      - "Independent management of the primary account for at least three weeks without manager escalation"
      - "Accepted account audit delivered plus a 100% QA pass rate on the first supervised campaign launch"
      - "First formal optimisation recommendation written, reviewed by the team lead, and implemented"
      - "Monthly strategy memo produced and at least one client call led independently"
    correct_idx: 1
    explanation: "Day 30 closes the Learn phase. The analyst must submit an accepted account audit and achieve a 100% QA pass rate on their first supervised campaign before the team lead countersigns. Independent management (option A) is a Day 60 measure; the first optimisation recommendation (C) belongs to Days 31–60; the strategy memo and client call (D) are Day 90 deliverables."
    section_anchor: milestone-deliverables-and-kpis
  - question: "A new PPC analyst starts on Monday. What is the correct GA4 role and scope to provision before Day 1?"
    options:
      - "Viewer — the minimum read-only role sufficient for Day 1 reporting access"
      - "Analyst — assigned at property level on the primary client's GA4 property"
      - "Editor — enabling immediate Looker Studio data source connections from Day 1"
      - "Administrator — ensuring the analyst has no permission-based workflow blockers"
    correct_idx: 1
    explanation: "New analysts start at GA4 Analyst role, assigned at property level (not account level). Account-level assignment propagates access to all properties, exposing other clients' data in agency setups. Editor is only added at Day 30, when the analyst needs to connect Looker Studio and modify audience configurations."
    section_anchor: day-one-access-provisioning
  - question: "At the Day 60 check-in, an analyst has a QA pass rate of 85% and a report accuracy score of 93%. What is the correct team lead decision?"
    options:
      - "Pass — both QA and accuracy metrics exceed the standard 80% training threshold"
      - "Pass — the analyst is trending upward and met the spirit of the target"
      - "Conditional pass — document gaps and hold expansion until QA ≥90% and accuracy ≥95%"
      - "Fail — restart the Apply phase from Day 31 until both targets are achieved"
    correct_idx: 2
    explanation: "Day 60 thresholds are ≥90% QA pass rate and ≥95% report accuracy. Both are below target. A conditional pass with documented improvement goals is the right call — not restarting the full phase, but not expanding to additional accounts until the metrics are met."
    section_anchor: milestone-deliverables-and-kpis
  - question: "At Day 45, a PPC analyst's QA pass rate is 72%. Investigation shows their GA4 role is still Analyst, not Editor, so they cannot verify Custom Dimension data after landing page URL changes. What is the root cause?"
    options:
      - "Skill gap — the analyst needs targeted training on GA4 Custom Dimension validation"
      - "Access gap — the analyst lacks GA4 Editor permission to verify Custom Dimension data"
      - "Workload mismatch — the analyst was assigned too many campaigns before the Day 45 checkpoint"
      - "Performance gap — formal improvement plan required before the analyst proceeds to Day 60"
    correct_idx: 1
    explanation: "The analyst cannot complete the QA task because of a missing permission — an access/tooling gap. The fix is to upgrade GA4 to Editor and re-run the task with a one-week grace period. Treating this as a skill or performance gap wastes a week on the wrong intervention."
    section_anchor: the-day-45-diagnosis
  - question: "A team lead spot-checks three items on an analyst's first campaign QA checklist and finds one failure: conversion tracking is not confirmed. What happens next under the countersign protocol?"
    options:
      - "The team lead fixes the tracking issue and countersigns the campaign for immediate launch"
      - "The analyst corrects the single failure; the team lead countersigns only that checklist item before launch"
      - "The analyst corrects the failure and restarts the full QA checklist before the team lead re-checks"
      - "The campaign launches with the tracking issue logged as a known limitation to monitor post-launch"
    correct_idx: 2
    explanation: "The countersign protocol requires a clean pass across the full QA checklist. A single failure means the analyst corrects it and restarts from step one — no partial passes or spot-fixes allowed. The team lead re-checks only after the complete checklist is resubmitted."
    section_anchor: handing-off-to-solo-campaign-ownership
---

Your new analyst is hired, their start date is set, and their laptop is ready. What happens next determines whether they are independently running campaigns by Day 30 or still asking for help on basic tasks by Day 60. The answer is almost never about talent — it is almost always about structure.

## The Three-Phase Ramp Framework

The 30-60-90 framework maps a new analyst's first quarter to three phases: **Learn (Days 1–30)**, **Apply (Days 31–60)**, and **Own (Days 61–90)**. Each phase has one primary goal, a set of concrete deliverables, and a numeric KPI checkpoint at the boundary. Programmes built this way are 2.5× more likely to be rated effective, [according to the Association for Talent Development via AllenComm](https://www.allencomm.com/2026/04/successful-onboarding-time-to-productivity-early-performance-signals/) — and the stakes for getting it wrong are significant: mid-level replacement costs exceed $30,000 [per Oxford Economics data cited by AllenComm](https://www.allencomm.com/2026/04/successful-onboarding-time-to-productivity-early-performance-signals/), with [SHRM](https://www.shrm.org/topics-tools/topics/onboarding/measuring-success) estimating total turnover costs at 50–200% of annual salary.

For a PPC analyst, the three phases map directly to campaign ownership:

- **Learn:** The analyst observes, audits, and builds under supervision. No live campaign changes without a manager countersign.
- **Apply:** The analyst manages one primary account independently, with weekly check-ins. The first formal optimisation recommendation requires manager review before implementation.
- **Own:** The analyst carries a full portfolio, delivers monthly strategy memos, and leads at least one client call.

Phase transitions are earned by hitting KPIs — not granted by calendar time.

## Day-One Access Provisioning

Access gaps are the most common — and most avoidable — reason a ramp starts a week late. The minimum access stack must be provisioned before the analyst's first login.

| Platform | Day 1 Role | Scope | Day 30 Upgrade |
|----------|-----------|-------|---------------|
| Google Ads (primary account) | Standard | Child account only (not MCC Admin) | Standard — no change |
| Google Ads (secondary accounts) | Read-only | Observe only | Standard at Day 30 |
| GA4 (primary property) | Analyst | Property level, not account level | Editor at Day 30 |
| Looker Studio (all dashboards) | Viewer | All client reports | Editor at Day 30 |
| CRM partner connector (e.g., Supermetrics) | Viewer seat | Vendor portal — flag to procurement 2 weeks before start | Contributor at Day 60 |

Two provisioning actions require lead time. MCC invitations must be sent the week before start date — Google Ads MCC invites require the invitee to accept, and a same-day invite loses Day 1 to an email queue. CRM partner connector seats require vendor portal action, which may need a procurement approval cycle; flag this two weeks in advance.

<Callout type="warning">
Never grant a new analyst Google Ads Admin access "for convenience." Admin allows adding and removing users across all MCC-linked client accounts. Standard access on specific child accounts is the correct Day 1 grant. Earned access at each phase boundary is both a security control and a ramp signal.
</Callout>

The Day 30 upgrade on GA4 from Analyst to Editor is not optional — [GA4's access model](https://support.google.com/analytics/answer/9305587) requires Editor role before an analyst can connect a property to Looker Studio or modify audience and event definitions. Assign these roles at property level, not account level, to avoid propagating access to other clients' properties.

<KnowledgeCheck
  question="A new analyst's GA4 access was granted at the account level, not the property level. What is the practical risk in an agency running multiple clients in one GA4 account?"
  options={["The analyst will be locked out of all reports until the role is reassigned", "The analyst's access propagates to every property in the account, including properties for other clients", "The analyst cannot create explorations in the primary client property", "The role is invalid at account level and will be rejected by GA4 automatically"]}
  correctIdx={1}
  explanation="Account-level GA4 role assignment propagates to all properties beneath it. In a multi-client GA4 account, this exposes cross-client data. Always assign at the property level during the ramp period, and only elevate to account-level once the analyst has full portfolio ownership."
/>

## Milestone Deliverables and KPIs

Each phase boundary is a formal check-in with numeric pass/fail thresholds. An analyst who misses a Day 30 KPI does not automatically progress to the Apply phase.

**Day 30 — Learn phase close:**
- Account audit submitted and accepted by team lead (binary: accepted or not)
- QA pass rate on first supervised campaign: 100% before countersign
- Time-to-first-solo-campaign: ≤Day 30

**Day 60 — Apply phase close:**
- QA pass rate across all active campaigns: ≥90%
- Report accuracy score (spot-check 5 metrics against platform source data, tolerance ±1%): ≥95%
- Weeks of primary account managed without escalation: ≥3
- First formal optimisation recommendation: approved and implemented

**Day 90 — Own phase close:**
- QA pass rate: ≥95%
- Report accuracy score: ≥98%
- Manager satisfaction rating: ≥4.0 / 5.0
- 90-day retention: analyst still in role (binary pass/fail)

These thresholds are illustrative — calibrate your own targets after two ramp cycles.

<KnowledgeCheck
  question="A Day 45 review shows the analyst's first formal optimisation recommendation was implemented two days before the team lead reviewed it. Why is this a ramp design failure, not just an individual mistake?"
  options={["The analyst skipped a required training module", "The ramp plan did not specify that the first recommendation requires manager sign-off before implementation", "The team lead should have countersigned the recommendation on Day 38", "The optimisation recommendation belongs in the Day 30 phase, not Day 45"]}
  correctIdx={1}
  explanation="The first optimisation recommendation must be written, reviewed, and approved before implementation — that sequence must be explicit in the ramp plan. If the plan only says 'deliver a recommendation by Day 42,' the analyst reasonably interprets that as 'submit and implement.' The ramp design is at fault, not just the analyst's judgment."
/>

## The Day-45 Diagnosis

Studies suggest up to 20% of new-hire turnover occurs within the first 90 days, [per AIHR](https://www.aihr.com/blog/onboarding-metrics/), making mid-ramp the most critical diagnostic window. When an analyst misses a KPI at Day 45, diagnose root cause before assigning remediation. There are exactly three categories:

1. **Access or tooling gap.** The analyst cannot physically complete the task because a permission is missing or a tool is unavailable. Example: low QA pass rate because GA4 Custom Dimensions are invisible to an Analyst-role user after a landing page URL change. Fix: provision the correct access, re-run the task with a one-week grace period.

2. **Skill or knowledge gap.** The analyst has access but lacks the training to use it correctly. Fix: a targeted session on the specific failure mode — not a broad remediation plan.

3. **Workload mismatch.** Two or more major deliverables collided in the same week. Fix: redistribute account load and reschedule the missed milestone. Do not treat a scheduling conflict as a performance problem.

Diagnose all three before assigning any intervention. A tooling diagnosis demands a tooling fix. Conflating an access gap with a skill gap wastes two weeks on the wrong solution and signals to the analyst that you are not paying close attention.

## Handing Off to Solo Campaign Ownership

First solo campaign ownership happens when the analyst earns it through the countersign protocol, not when the calendar reaches Day 28. The target window is Day 25–35.

The protocol:
1. Analyst completes the QA checklist in full: tracking verified (conversion actions firing in preview), bid strategy confirmed, creative assets approved, negative keywords attached, landing page live with <2.1s mobile load time per [WE Interactive's 2026 PPC Checklist](https://we-interactive.com/the-ultimate-ppc-campaign-management-checklist-for-2026/).
2. Team lead spot-checks three checklist items at random.
3. All three pass → team lead countersigns → campaign goes live.
4. Any fail → analyst corrects and restarts the checklist from step one. No partial passes.

Once countersigned, daily oversight drops to weekly check-ins. The analyst has explicit authority over keyword, bid, and budget pacing — with one constraint: the first formal optimisation recommendation still requires written manager sign-off before implementation, a gate removed at Day 60 once QA and accuracy targets are met.

New campaigns need 30+ days of conversion data before bid signals are reliable — brief the analyst in week one so optimisation recommendations reference the correct window.

Portfolio expansion follows the same ladder, phase-shifted 30 days per account → [[04-campaign-portfolio-accountability-rhythms]].

---

**Hands-On Exercise**

Using the framework from this chapter, apply it to a real or hypothetical analyst joining your team next month:

1. Write out the Day 1 access provisioning checklist for your specific platforms (include scope level for each — child account vs. MCC, property vs. account, etc.). Mark which items require vendor or procurement action and their minimum lead time.
2. Define three Day 30 KPIs with explicit pass/fail thresholds, tied to the specific accounts and campaign types that analyst will own.
3. Draft a Day-45 diagnosis checklist: three root-cause questions — one per category (access, skill, workload) — that you would work through before assigning any remediation.

**Success criteria:** Each Day 30 KPI has a numeric threshold and is tied to a named deliverable. Your diagnosis checklist asks root-cause questions that could produce three different answers, not questions that lead to a single predetermined conclusion.
