---
course_slug: fixed-income-ldi-structured-products-for-operations-analysts
title: "Fixed Income, LDI, and Structured Products for Investment Operations Analysts"
status: outline-g3-passed
course_track: career
toc_locked: true
video_overview: true
koenig_recommendation: "Institutional Investment Product Knowledge"
author: course-architect
level: Builder
vendor_tag: Fixed Income / Investment Operations
target_audience: "Entry candidates targeting Investment Operations Analyst or Client Reporting Analyst roles who need institutional product fluency across bonds, LDI funds, and structured products."
prerequisites:
  - "Basic Excel fluency, including formulas and tabular calculations"
  - "Introductory finance knowledge: present value, interest rates, and portfolio return"
  - "Comfort reading fund holdings tables and simple performance reports"
learning_outcomes:
  - "Price a fixed-rate bond from cash flows and interpret yield, modified duration, and convexity fields from Bloomberg DES/YAS-style references"
  - "Diagnose whether fixed income performance came from rates, credit spreads, carry, or yield curve shape changes"
  - "Read an LDI fund report using funded status, duration gap, BPV, hedge ratio, and liability-relative attribution"
  - "Classify MBS, ABS, CMBS, and CLO securities and validate tranche-level reporting fields against waterfall logic"
  - "QA a multi-instrument institutional fund pack and draft concise client-ready commentary from validated data"
total_duration_min: 70
chapter_count: 5
sources: []
---

## Chapter 1: Bond Pricing Mechanics: Calculating Yield, Duration, and Convexity from Scratch
**Duration:** ~14 min | **Dossier:** vault/research/courses/fixed-income-ldi-structured-products-for-operations-analysts/01-bond-pricing-yield-duration-convexity.md

### Learning Objectives
- Calculate the price of a fixed-rate bond from coupon, par, yield, maturity, and payment frequency using a discounted cash-flow table in Excel
- Compute modified duration and interpret it as the approximate percentage price change for a 100 bps yield move
- Explain how convexity changes the duration-only estimate when rates move by more than a small amount
- Read Bloomberg DES/YAS-style fields and map yield, spread, modified duration, and convexity to their economic meanings

### Key Concepts
- Fixed-rate bond cash flows, coupon, par value, maturity, discount factor, yield-to-maturity, price-yield inverse relationship, modified duration, convexity, parallel yield curve shift, Bloomberg DES/YAS fields

### Hands-On Exercise
Build a bond pricing worksheet from provided coupon, par, maturity, and yield inputs. Calculate price, modified duration, and convexity, then estimate the portfolio value impact of a +100 bps parallel yield shift and annotate the corresponding YAS-style fields.

---

## Chapter 2: Credit Spreads, Yield Curves, and the Reporting Metrics That Come From Them
**Duration:** ~12 min | **Dossier:** vault/research/courses/fixed-income-ldi-structured-products-for-operations-analysts/02-credit-spreads-yield-curves-reporting-metrics.md

### Learning Objectives
- Decompose a bond's total yield into risk-free rate plus credit spread and explain what can move each component
- Diagnose whether a portfolio return was driven by rate movement, spread compression/widening, carry, or a combination of those drivers
- Distinguish steepening and flattening curve scenarios and state the directional impact on a long-duration portfolio
- Label duration contribution, spread contribution, and carry in a mock fixed income performance attribution report

### Key Concepts
- Risk-free rate, credit spread, spread widening, spread compression, yield curve steepening, yield curve flattening, duration contribution, spread contribution, carry, attribution table, client-report narrative

### Hands-On Exercise
Given a simplified attribution table and two yield curve snapshots, identify the rate, spread, and carry drivers of return. Write three bullets explaining the movement in client-report language without using unsupported claims.

---

## Chapter 3: LDI Funds: Funded Status, Hedge Ratios, and Liability-Relative Performance Attribution
**Duration:** ~15 min | **Dossier:** vault/research/courses/fixed-income-ldi-structured-products-for-operations-analysts/03-ldi-funded-status-hedge-ratios-attribution.md

### Learning Objectives
- Define and compute funded status, duration gap, BPV, and hedge ratio from a simplified pension balance sheet and swap overlay schedule
- Explain why LDI funds benchmark against liabilities rather than only against a market index
- Identify whether a receive-fixed swap overlay increases or decreases the interest rate hedge ratio
- Draft concise LDI performance commentary explaining a hedge-ratio move in the context of a gilt rally

### Key Concepts
- Defined-benefit pension plan, funded status, liability duration, asset duration, duration gap, basis point value (BPV), hedge ratio, glidepath, receive-fixed swap, liability-relative benchmark, asset-only performance, liability-relative attribution

### Hands-On Exercise
Use a simplified pension balance sheet and swap overlay schedule to calculate funded status, BPV, duration gap, and hedge ratio. Then write a three-sentence monthly commentary explaining why the hedge ratio moved from 80% to 85% during a gilt rally.

---

## Chapter 4: Structured Products — MBS, ABS, CMBS, and CLO Tranching for Reporting Analysts
**Duration:** ~15 min | **Dossier:** vault/research/courses/fixed-income-ldi-structured-products-for-operations-analysts/04-structured-products-mbs-abs-cmbs-clo-tranching.md

### Learning Objectives
- Distinguish MBS, ABS, CMBS, and CLO securities by collateral type, SPV structure, and typical tranche stack
- Explain sequential loss absorption and credit enhancement by tracing a loss through a three-tranche waterfall
- Interpret OC/IC test cushions, CCC bucket drift, and weighted-average spread in a mock CLO trustee report extract
- Validate a structured product holdings line for rating, attachment point, CUSIP, notional, and tranche seniority consistency

### Key Concepts
- MBS, ABS, CMBS, CLO, collateral pool, SPV, tranche stack, senior tranche, mezzanine tranche, equity tranche, subordination, attachment point, credit enhancement, sequential loss absorption, OC test, IC test, CCC bucket, weighted-average spread

### Hands-On Exercise
Classify four securities from DES-style descriptions, build a three-tranche CLO waterfall from a template, trace a principal loss through the structure, and flag inconsistent fields in a mock holdings line.

---

## Chapter 5: Validating and Narrating a Multi-Instrument Institutional Fund Report
**Duration:** ~14 min | **Dossier:** vault/research/courses/fixed-income-ldi-structured-products-for-operations-analysts/05-validating-narrating-multi-instrument-fund-report.md

### Learning Objectives
- Identify deliberate anomalies in a mock fund report across duration, swap overlay, CLO tranche rating, waterfall position, and funded-status movement
- Write one-line remediation notes that tell operations, portfolio management, or reporting teams exactly what must be checked
- Draft a coherent 150-word performance commentary covering rate, spread, LDI hedge-ratio, and structured product contributions using only validated data
- Build a six-field pre-release QA checklist for fixed income and LDI client reports

### Key Concepts
- Fund pack QA, fixed income attribution validation, LDI hedge-ratio validation, structured product holdings validation, anomaly triage, remediation note, client-ready commentary, pre-release reporting checklist

### Hands-On Exercise
Work through a complete mock fund pack containing fixed income attribution, LDI-relative commentary, and structured product holdings. Find at least three anomalies, document each with a one-line remediation note, and draft a 150-word client-ready commentary from the corrected data.

---

## Capstone
Learners validate a full mock institutional fund report covering fixed income attribution, an LDI sleeve, and structured product holdings. Deliverables: a completed anomaly log with remediation notes, a six-field pre-release QA checklist, and a 150-word client-ready performance commentary that explains rate, spread, LDI hedge-ratio, and structured product contributions using only validated data.
