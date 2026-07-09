---
title: "Structured Products — MBS, ABS, CMBS, and CLO Tranching for Reporting Analysts"
course: fixed-income-ldi-structured-products-for-operations-analysts
chapter: 4
slug: structured-products-mbs-abs-cmbs-clo-tranching
status: draft
type: chapter
level: Builder
duration_min: 15
tags:
  - structured-products
  - mbs
  - abs
  - cmbs
  - clo
  - tranching
  - waterfall
  - credit-enhancement
  - bloomberg-des
  - oc-test
  - ic-test
  - ccc-bucket
  - was
  - operations
  - fixed-income
created: 2026-07-09
---

# Chapter 4: Structured Products — MBS, ABS, CMBS, and CLO Tranching for Reporting Analysts

## Learning Objectives

- Distinguish MBS, ABS, CMBS, and CLO securities by collateral type, SPV structure, and typical tranche stack
- Explain sequential loss absorption and credit enhancement by tracing a loss through a three-tranche waterfall
- Interpret OC/IC test cushions, CCC bucket drift, and weighted-average spread in a mock CLO trustee report extract
- Validate a structured product holdings line for rating, attachment point, CUSIP, notional, and tranche seniority consistency

---

## Why Structured Products Demand Different Reporting Skills

When a fund's holdings include a CUSIP labelled "BlueMountain CLO XXIII, Ltd. Class B-1" sitting next to a FNMA pool number, you are looking at two fundamentally different instruments — different cash-flow sources, different risk layers, and entirely different validation workflows. This chapter builds the classification fluency and field-level intuition you need to work with structured products correctly in a reporting or operations role.

---

## Classifying Structured Products: Four Asset Classes, One SPV Pattern

Every securitised product follows the same structural skeleton: an originator sells a pool of loans to a **Special Purpose Vehicle (SPV)** — a legally separate, bankruptcy-remote entity. The SPV issues notes (tranches) to investors, and loan cash flows repay them through a defined priority order. Your classification job starts with identifying what is in the pool.

**MBS (Mortgage-Backed Securities)** — collateral is residential mortgages. Agency MBS (FNMA, FHLMC, GNMA pools) carry a GSE guarantee and pool identifiers beginning with FN, FG, or GN. Non-agency RMBS carry names like "Bear Stearns Mortgage Funding Trust 2007-AR2" — the trust name encodes the originator and vintage. Bloomberg DES Security Type shows "MBS" or "CMO." Agency pass-throughs are generally single-class; CMOs carve cash flows into sequential or planned-amortisation tranches.

**ABS (Asset-Backed Securities)** — collateral is consumer receivables: auto loans, credit cards, student loans, or equipment leases. Deal names contain the asset type ("Ford Motor Credit Auto Owner Trust 2023-A, Class A-2"). Average lives are short — auto ABS typically run 1–4 years.

**CMBS (Commercial Mortgage-Backed Securities)** — collateral is commercial real estate loans. Trust names include year and sequence ("CSMC 2021-RPL1"). Watch for "IO" or "X" tranches: interest-only strips that carry a notional balance but no funded principal. The IO strip's value collapses if the underlying loans prepay faster than assumed.

**CLO (Collateralised Loan Obligation)** — collateral is leveraged loans. Trust names follow the pattern "[Manager] CLO YYYY-N, Ltd." All tranches pay floating: SOFR plus a spread in basis points. Bloomberg DES Security Type = "CLO," Collateral Type = leveraged loans. The critical distinction from RMBS and ABS: a CLO manager actively buys and sells loans during the reinvestment period. The pool is not static.

**Bloomberg DES classification drill**: open DES on any structured CUSIP and check four fields in sequence — (1) Security Name for the trust-name pattern, (2) Security Type, (3) Collateral Type, (4) coupon structure. Fixed coupon → MBS, CMBS, or ABS; floating SOFR+spread → CLO. A factor below 1.0 on the Mortgage/ABS tab shows how much original principal remains outstanding; for example, a factor of 0.3842 means only 38.42 cents of every original dollar of face value is still outstanding.

---

## Sequential Loss Absorption: How the Waterfall Works

Tranches are stacked by seniority. Losses flow **bottom-up**; cash flows flow **top-down**.

Consider a $100m deal with three tranches:

| Tranche | Rating | Balance | % of Pool |
|---------|--------|---------|-----------|
| A (senior) | AAA | $75m | 75% |
| B (mezzanine) | BBB | $15m | 15% |
| C (equity) | NR | $10m | 10% |

If the collateral pool loses **$8m**: Tranche C absorbs the entire $8m; A and B are untouched.

If the pool loses **$18m**: Tranche C is fully wiped ($10m), and Tranche B absorbs the remaining $8m — leaving $7m of its original $15m intact. Tranche A still has zero loss.

Tranche A is not exposed until B and C combined — $25m — are exhausted. That $25m is its **credit enhancement through subordination**: 25% of the pool must default before the AAA note takes a single dollar of loss.

Each tranche's position is defined by its **attachment** and **detachment points**:

- Tranche C: attachment = 0%, detachment = 10%
- Tranche B: attachment = 10%, detachment = 25%
- Tranche A: attachment = 25%, detachment = 100%

These fields appear on Bloomberg DES under the Structure tab. The validation rule is: `attachment + tranche thickness = detachment`. Thickness for Tranche B = 15%, so: 10% + 15% = 25% ✓. A mismatch between your fund system and DES flags a data error — often caused by incomplete population on secondary-market purchases.

---

## CLO Trustee Reports: Four Fields That Signal Deal Health

For CLOs, the periodic trustee report is the authoritative data source. Four fields dominate operations surveillance:

**Over-Collateralisation (OC) Test Cushion** measures the buffer between the collateral pool's par value and the notes it backs. OC ratio = collateral par / (par of tested class + all senior classes). OC cushion = actual ratio minus the trigger. Example: Class A/B OC trigger 120.0%, actual ratio 122.4% → cushion +2.4%. When the cushion hits zero, the deal redirects cash flows away from junior tranches to deleverage senior notes. A cushion that trends from +3.5% to +1.0% over three months is an early-warning signal — flag it.

**Interest Coverage (IC) Test Cushion** compares collateral interest income to interest owed on the tested tranche and all senior tranches. IC cushion = actual IC ratio minus the IC trigger. Failure triggers the same cash-flow diversion. IC failures are less frequent than OC failures but can put mezzanine interest at risk.

**CCC Bucket Drift** tracks the percentage of the loan pool rated CCC/Caa or below. Most CLO indentures cap this bucket at 7.5%. Once breached, the excess is carried at market value — not par — in the OC numerator. A market value of, say, 65 cents on loans that were counted at par effectively shrinks the OC ratio even before any loans default. Rising CCC drift (4.2% → 5.8% → 7.1% over three consecutive reports) is a compound stress signal that warrants immediate escalation.

**Weighted-Average Spread (WAS)** is the average floating spread earned on loans in the pool, weighted by par balance. Indentures set a minimum WAS floor — for example, ≥ 380 bps. If the manager adds lower-spread loans and WAS falls to 372 bps, the deal breaches its floor and cash-flow diversion begins. WAS declining toward its floor while the CCC bucket rises simultaneously is the most common pre-stress pattern in CLO surveillance work.

---

## Holdings-Line Validation: Five Anomaly Flags

When reviewing a structured product line in fund records, check these five fields against Bloomberg DES and the trustee report:

1. **Notional overstated from a stale factor.** MBS and ABS fund records must carry current notional = factor × original face. If DES shows factor 0.41 but the system holds original face, notional is overstated by 59%. Recalculate and update.

2. **Rating lag after a downgrade.** If the Bloomberg current rating is two or more notches below the fund record rating, escalate to risk immediately — mandate eligibility may be breached and the holding may need to be flagged for disposal.

3. **Attachment point blank or wrong.** On secondary purchases, attachment and detachment points frequently fail to populate. Derive them from the indenture: attachment point = sum of all subordinate tranche par / original deal par.

4. **Tranche seniority misclassification.** CLO Class A = senior. Class B and below = mezzanine or subordinate. An AA-rated CLO Class B recorded as "senior" in the risk system mis-buckets the credit exposure and distorts the portfolio's risk profile.

5. **IO strip price anomaly.** An IO (interest-only) strip carries notional but no principal. Its value depends entirely on prepayment speed; fast prepayment destroys it. Flag any IO strip priced above 20 (20% of notional) on a high-CPR pool, or any IO where par value equals market value — that is almost certainly a mis-mark.

---

## Hands-On Exercise

You are given four Bloomberg DES-style descriptions. Classify each as MBS, ABS, CMBS, or CLO, and state the one field that made the classification decisive.

Then, using the three-tranche deal above ($75m A / $15m B / $10m C, $100m pool), calculate: (a) the credit enhancement for Tranche A, (b) the attachment point for Tranche B, and (c) the maximum pool loss Tranche A can absorb before any impairment.

Finally, review this CLO trustee report extract:

| Field | Current month | Prior month |
|-------|---------------|-------------|
| Class A/B OC ratio | 119.8% | 121.2% |
| Class A/B OC trigger | 120.0% | 120.0% |
| CCC bucket | 7.9% | 6.8% |
| WAS | 377 bps | 384 bps |

Identify every breach or warning signal and state the immediate operational consequence of each.

---

## Quiz

**Question 1 — Classification**
A fund holding has Security Type "CLO," Collateral Type "Leveraged Loans," coupon SOFR+210, and deal name "Carlyle CLO 2022-1, Ltd., Class C." Which of the following is the primary classification clue?

A) The fixed coupon rate
B) The collateral type: leveraged loans
C) The 2022 vintage year
D) The mezzanine tranche label

**Answer: B.** Leveraged loan collateral, SOFR-floating coupon, and the "[Manager] CLO YYYY-N" naming pattern together confirm CLO classification. The collateral type is the decisive signal.

---

**Question 2 — Sequential loss absorption**
A CLO has three tranches: Tranche A (AAA, $80m), Tranche B (BBB, $12m), Tranche C (equity, $8m). The collateral pool suffers a $15m loss. What is the remaining balance of Tranche B?

A) $12m (fully protected)
B) $5m
C) $0m (fully wiped)
D) $7m

**Answer: B.** Tranche C absorbs the first $8m (fully wiped). Tranche B absorbs the remaining $7m, leaving $12m − $7m = **$5m** intact. Tranche A is unaffected.

---

**Question 3 — Attachment point and credit enhancement**
In a $100m deal with Tranche A ($75m), Tranche B ($15m), and Tranche C ($10m), what is the attachment point for Tranche B, and what does it represent?

A) 15%; the percentage of pool that constitutes Tranche B itself
B) 10%; the cumulative loss level at which Tranche B begins absorbing losses
C) 25%; the loss level at which Tranche A begins absorbing losses
D) 75%; Tranche A's share of the pool

**Answer: B.** Attachment point for B = equity (Tranche C) as a percentage of the pool = 10%. Losses must exceed 10% before Tranche B is impaired at all.

---

**Question 4 — CLO trustee report interpretation**
The latest CLO trustee report shows: Class A/B OC ratio = 119.4%, trigger = 120.0%, CCC bucket = 8.1% (cap 7.5%), WAS = 378 bps (floor 380 bps). Which statement correctly describes the situation?

A) Only the CCC bucket is in breach; OC and WAS are healthy
B) All three metrics are in breach; the deal will redirect cash flows away from junior tranches
C) The OC breach is the only actionable item; CCC and WAS are within tolerance
D) No breach has occurred; all metrics are within acceptable ranges

**Answer: B.** OC ratio 119.4% < 120.0% trigger = OC breach. CCC bucket 8.1% > 7.5% cap = CCC breach (and haircutting the OC numerator). WAS 378 bps < 380 bps floor = WAS breach. All three trigger cash-flow diversion to deleverage senior notes.

---

**Question 5 — Holdings-line anomaly flag**
Your fund's record for a CLO Class B (AA) shows: notional $10m, current Bloomberg rating BBB (two notches below the fund record of AA), attachment point blank, tranche seniority = "Senior." How many anomalies are present and which is highest priority?

A) One anomaly: the blank attachment point
B) Two anomalies: the rating lag and the seniority misclassification
C) Three anomalies: the rating lag, the blank attachment point, and the seniority misclassification
D) No anomalies; CLO Class B is routinely classified as senior

**Answer: C.** Three anomalies are present. Highest priority is the two-notch rating lag (BBB vs. AA) — mandate eligibility must be reviewed immediately. Second is the seniority misclassification (Class B is mezzanine, not senior). Third is the blank attachment point, which must be derived from the indenture.
