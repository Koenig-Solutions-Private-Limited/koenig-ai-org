---
chapter_num: 2
course_slug: fixed-income-ldi-structured-products-for-operations-analysts
title: "Credit Spreads, Yield Curves, and the Reporting Metrics That Come From Them"
status: g0-passed
duration_min: 12
vendor_tag: Fixed Income / Investment Operations
learning_objectives:
  - "Decompose a bond's total yield into risk-free rate plus credit spread and explain what can move each component"
  - "Diagnose whether a portfolio return was driven by rate movement, spread compression/widening, carry, or a combination of those drivers"
  - "Distinguish steepening and flattening curve scenarios and state the directional impact on a long-duration portfolio"
  - "Label duration contribution, spread contribution, and carry in a mock fixed income performance attribution report"
sources:
  - url: "https://www.pimco.com/en-us/resources/education"
    title: "PIMCO Education: Understanding Option-Adjusted Spread Analysis"
  - url: "https://fred.stlouisfed.org/series/BAMLC0A0CMEY"
    title: "ICE BofA US Corporate Index OAS — FRED"
  - url: "https://fred.stlouisfed.org/series/T10Y2Y"
    title: "10-Year Treasury Minus 2-Year Treasury Yield Spread — FRED"
owns:
  - "Bond total yield decomposition into risk-free rate plus credit spread"
  - "Credit spread widening/compression drivers and their effect on bond returns"
  - "Yield curve steepening and flattening scenarios and directional portfolio impact"
  - "Rate movement versus spread movement diagnosis from a simplified attribution table"
  - "Duration contribution, spread contribution, and carry line-item interpretation in fixed income performance attribution"
  - "Client-report narrative logic for explaining rate, spread, and carry contributions without drifting into LDI-specific reporting"
does_not_cover:
  - "Full bond pricing DCF mechanics, duration formulas, and convexity calculations (ch 1 owns them)"
  - "Funded status, hedge ratio, BPV, duration gap, and liability-relative LDI attribution (ch 3 owns them)"
  - "Structured products, tranche-level reporting fields, OC/IC tests, and waterfall analysis (ch 4 owns them)"
  - "End-to-end multi-instrument anomaly detection and final 150-word commentary deliverable (ch 5 owns it)"
defers_to:
  - "DCF bond price, YTM, modified duration, and convexity → ch1"
  - "Funded status, liability duration, BPV, hedge ratio, and swap overlay → ch3"
  - "OC/IC tests, tranche waterfall, CLO structured products → ch4"
  - "150-word client commentary capstone deliverable → ch5"
quiz_topics:
  - "Risk-free rate plus credit spread yield decomposition"
  - "Diagnosing rate return versus spread return in attribution"
  - "Steepening versus flattening yield curve scenarios"
  - "Duration contribution, spread contribution, and carry line items"
  - "Client-report language for spread compression and rate moves"
notebooklm_source_focus:
  - "Fixed income performance attribution: rate, spread, and carry components"
  - "Yield curve steepening and flattening explanations for bond portfolios"
  - "Credit spread drivers and spread duration in institutional reporting"
  - "Sample fixed income attribution reports for investment operations analysts"
word_budget: { min: 800, max: 1200 }
positions: []
quiz:
  - question: "A 5-year investment-grade corporate bond yields 5.15%. The on-the-run 5-year Treasury yields 4.20%. What is the bond's option-adjusted spread, and what does it compensate investors for?"
    options:
      - "95 bps; compensates for default risk, liquidity premium, and market/regulatory risk premium relative to the government benchmark"
      - "95 bps; compensates for the interest rate duration exposure embedded in holding a 5-year bond"
      - "420 bps; the risk-free rate is subtracted from the coupon rate, not from the YTM, to derive the credit spread"
      - "5.15%; the OAS equals the full YTM because spread measures total compensation above a zero benchmark"
    correct_idx: 0
    explanation: "OAS = YTM − risk-free rate = 5.15% − 4.20% = 0.95% = 95 bps. The credit spread compensates for default probability, expected loss-given-default, liquidity costs, and market/regulatory risk premium. Interest rate duration risk is already captured in the risk-free rate component — it is not what the credit spread compensates for."
    section_anchor: yield-decomposition-every-bond-yield-has-two-parts
  - question: "An investment-grade corporate bond has a spread duration of 4.5 years and a current OAS of 95 bps. Credit stress causes OAS to widen by 50 bps. What is the approximate price change?"
    options:
      - "+2.25%, because the widened spread increases the bond's income yield, lifting its price"
      - "−0.225%, because the spread duration factor is divided by 100 to convert basis-point sensitivity to percent"
      - "−2.25%, because Spread return ≈ −SpreadDuration × ΔOAS = −4.5 × 0.0050"
      - "−22.5%, because spread changes compound over the full remaining maturity of the bond"
    correct_idx: 2
    explanation: "The spread return formula is −SpreadDuration × ΔOAS (in decimal). With SpreadDuration = 4.5 years and ΔOAS = +50 bps = +0.0050: return ≈ −4.5 × 0.0050 = −2.25%. Spread widening means the market demands a higher yield, which forces price down — widening is always a price headwind for existing holders."
    section_anchor: spread-drivers-and-return-impact
  - question: "In a bear steepening scenario — long-end yields rise more than short-end yields — which portfolio experiences the largest loss?"
    options:
      - "A portfolio concentrated in 2-year bonds, because short-end yields rise in a bear scenario"
      - "A barbell portfolio, because both the short and long ends are simultaneously exposed to rate increases"
      - "A bullet portfolio concentrated in 5-year bonds, because the belly of the curve is always the most volatile"
      - "A portfolio concentrated in 10-year bonds, because the long end rises most and long-duration bonds suffer the largest price loss per basis point"
    correct_idx: 3
    explanation: "In a bear steepening the long end moves most. Duration amplifies that move: a 10-year bond with duration ≈ 8 loses approximately 3.2% if 10yr yields rise 40 bps (−8 × 0.0040), while a 2-year bond with duration ≈ 1.9 loses only 0.2% if 2yr yields rise 10 bps. Long-end concentration means the largest duration penalty at the part of the curve where the move is largest."
    section_anchor: yield-curve-shapes-and-their-portfolio-impact
  - question: "An attribution report shows: rate return = −100 bps, spread return = +60 bps, carry = +30 bps. What does this tell you about the quarter's market environment?"
    options:
      - "Both rates and spreads moved against the portfolio; carry was the only positive contributor"
      - "Interest rates rose (rate return negative), but credit spreads compressed, partially offsetting the rate headwind; carry added a further cushion for a net −10 bps total return"
      - "The rate return is wrong — a negative rate return can only occur when spreads also widen simultaneously"
      - "The carry line overstates income because positive carry is only possible when the yield curve is inverted"
    correct_idx: 1
    explanation: "Rate return is negative when interest rates rise (bond prices fall). Spread return is positive when OAS compressed (prices rose from tighter spreads). The opposite signs show a rotation: a rate headwind partially offset by a spread tailwind, with stable carry income. Net total ≈ −100 + 60 + 30 = −10 bps — a modest loss despite a significant rate-driven headwind."
    section_anchor: reading-the-attribution-table
  - question: "A client report draft states: 'Credit fundamentals improved, with the issuer's financial strength driving tighter spreads.' The spread contribution line shows +80 bps. What should the operations analyst check before clearing this narrative?"
    options:
      - "Whether the issuer reported positive earnings, because attribution systems require a confirmed earnings-improvement source for positive spread return"
      - "Whether the carry contribution is also positive, because spread compression and carry always move together in improving credit environments"
      - "Whether sector-wide or market-wide OAS compression explains the spread return, and escalate to the PM if market-driven tightening is being attributed to issuer-specific credit quality"
      - "Whether the rate return was negative, because only when rates fall can positive spread compression occur in a standard attribution table"
    correct_idx: 2
    explanation: "Spread compression can be issuer-specific (upgrade, strong earnings) or market-wide (risk-on sentiment, Fed QE, yield-search environment). If the entire IG market tightened 80 bps that quarter, attributing the result to the issuer's financial strength is inaccurate. The analyst should compare the bond's OAS move to the sector or benchmark OAS move, and escalate if the narrative overstates issuer-specific drivers."
    section_anchor: client-report-language
---

Every bond yield on a Bloomberg screen blends two separate risks into one number. Splitting that number apart — and tracking what moves each piece — is the foundation of fixed income performance attribution.

## Yield Decomposition: Every Bond Yield Has Two Parts

For any non-government fixed-rate bond, yield to maturity decomposes into two additive components:

```
YTM = Risk-free rate + Credit spread
```

For a 5-year investment-grade corporate bond yielding 5.15%, with the on-the-run 5-year Treasury at 4.20%:

```
5.15% = 4.20% (risk-free rate) + 0.95% (95 bps credit spread)
```

The **risk-free rate** reflects the time value of money and the market's expectation of the Federal Reserve's policy path. The **credit spread** compensates investors for default risk, expected loss if the issuer fails, a liquidity premium (the bond trades less easily than a Treasury), and a market/regulatory risk premium.

The dominant institutional spread measure is the **option-adjusted spread (OAS)** — visible in Bloomberg as the `OAS1` field. OAS strips out embedded options such as call features, producing a comparable spread across bonds with different structures. `OASD` — option-adjusted spread duration — measures how sensitive a bond's price is to a one-basis-point change in OAS. For plain-vanilla non-callable investment-grade bonds, OASD ≈ modified duration: the same number that measures rate sensitivity also measures spread sensitivity.

<KnowledgeCheck question="A 5-year investment-grade corporate bond yields 5.15%. The on-the-run 5-year Treasury yields 4.20%. What is the bond's option-adjusted spread, and what does it compensate investors for?" options={["95 bps; compensates for default risk, liquidity premium, and market/regulatory risk premium relative to the government benchmark", "95 bps; compensates for the interest rate duration exposure embedded in holding a 5-year bond", "420 bps; the risk-free rate is subtracted from the coupon rate, not from the YTM, to derive the credit spread", "5.15%; the OAS equals the full YTM because spread measures total compensation above a zero benchmark"]} correctIdx={0} explanation="OAS = YTM − risk-free rate = 5.15% − 4.20% = 0.95% = 95 bps. The credit spread compensates for default probability, expected loss-given-default, liquidity costs, and market/regulatory risk premium. Interest rate duration risk is already captured in the risk-free rate component — it is not what the credit spread compensates for." />

## Spread Drivers and Return Impact

Credit spreads widen when investors demand more compensation for credit risk. Recession fears, rating downgrades, equity market stress, and liquidity shocks each push spreads wider. During the 2020 COVID shock, US investment-grade OAS widened roughly 250 basis points in four weeks. Spreads compress when the macro backdrop improves — strong GDP data, central bank purchase programs, and post-crisis normalization draw yield-seeking buyers who drive spreads toward fundamental floors.

The return impact of any spread move is approximated by:

```
Spread return ≈ −SpreadDuration × ΔOAS
```

For the running example (spread duration 4.5 years, OAS 95 bps):

- OAS widens +50 bps → −4.5 × 0.0050 = **−2.25%** price loss
- OAS compresses −30 bps → −4.5 × (−0.0030) = **+1.35%** price gain

The symmetry matters: the same mechanism that destroys value in a spread-widening episode creates value when spreads tighten. When a portfolio manager says "spreads rallied," that positive spread return will appear as a discrete positive line in the attribution table — separate from any rate movement.

<KnowledgeCheck question="An investment-grade corporate bond has a spread duration of 4.5 years and a current OAS of 95 bps. Credit stress causes OAS to widen by 50 bps. What is the approximate price change?" options={["+2.25%, because the widened spread increases the bond's income yield, lifting its price", "−0.225%, because the spread duration factor is divided by 100 to convert basis-point sensitivity to percent", "−2.25%, because Spread return ≈ −SpreadDuration × ΔOAS = −4.5 × 0.0050", "−22.5%, because spread changes compound over the full remaining maturity of the bond"]} correctIdx={2} explanation="The spread return formula is −SpreadDuration × ΔOAS (in decimal). With SpreadDuration = 4.5 years and ΔOAS = +50 bps = +0.0050: return ≈ −4.5 × 0.0050 = −2.25%. Spread widening means the market demands a higher yield, which forces price down — widening is always a price headwind for existing holders." />

## Yield Curve Shapes and Their Portfolio Impact

The yield curve plots government bond yields across maturities. Four shapes dominate institutional commentary:

| Shape | Description | Indicator |
|---|---|---|
| Normal (upward-sloping) | Short rates < long rates; positive term premium | Positive 2/10 spread |
| Inverted | Short rates > long rates; negative term premium | Negative 2/10 spread; recession signal |
| Flat | Rates roughly equal across maturities | Transition period; late-cycle uncertainty |
| Humped | Intermediate yields peak above both ends | Supply/demand imbalance at the belly |

The **2/10 spread** (10-year Treasury yield minus 2-year Treasury yield, FRED: T10Y2Y) is the standard curve-shape signal in institutional reports. The "belly of the curve" — 5- to 7-year maturities — is where most investment-grade corporate benchmark bonds cluster.

What matters for portfolios is not just the curve's static shape but *how it moves*:

| Curve scenario | Definition | Long-duration portfolio impact |
|---|---|---|
| Bear steepening | Long yields rise more than short yields | Negative — long-end bonds take the largest loss |
| Bull steepening | Short yields fall more than long yields | Mildly positive — long-end gains modestly |
| Bear flattening | Short yields rise more than long yields | Negative for front-end positions; 2022 pattern |
| Bull flattening | Long yields fall more than short yields | Positive — long-end bonds gain the most |

**Worked example**: Portfolio A holds $10M in a 10-year bond (duration ≈ 8). Portfolio B holds $10M in a 2-year bond (duration ≈ 1.9). Bear steepening: 10-year yield rises 40 bps, 2-year yield rises 10 bps. Portfolio A loses ≈ 3.2%; Portfolio B loses ≈ 0.2%. The attribution report shows Portfolio A absorbed nearly all the rate-driven loss — because its duration sits at the part of the curve where the move was largest.

<KnowledgeCheck question="In a bear steepening scenario — long-end yields rise more than short-end yields — which portfolio experiences the largest loss?" options={["A portfolio concentrated in 2-year bonds, because short-end yields rise in a bear scenario", "A barbell portfolio, because both the short and long ends are simultaneously exposed to rate increases", "A bullet portfolio concentrated in 5-year bonds, because the belly of the curve is always the most volatile", "A portfolio concentrated in 10-year bonds, because the long end rises most and long-duration bonds suffer the largest price loss per basis point"]} correctIdx={3} explanation="In a bear steepening the long end moves most. Duration amplifies that move: a 10-year bond with duration ≈ 8 loses approximately 3.2% if 10yr yields rise 40 bps (−8 × 0.0040), while a 2-year bond with duration ≈ 1.9 loses only 0.2% if 2yr yields rise 10 bps. Long-end concentration means the largest duration penalty at the part of the curve where the move is largest." />

## Reading the Attribution Table

Fixed income performance attribution decomposes total return into three additive lines:

```
Total return ≈ Rate return + Spread return + Carry
```

**Rate return** captures the return from movements in the risk-free curve, holding spreads constant:
```
Rate return ≈ −Duration × ΔTreasury rate
```

**Spread return** captures the return from OAS changes, holding the risk-free curve constant:
```
Spread return ≈ −SpreadDuration × ΔOAS
```

**Carry** captures coupon income plus roll-down. Coupon income is the bond's yield expressed as a holding-period return. Roll-down is the additional price appreciation that occurs as a bond ages toward a shorter — and in a normal curve, lower-yielding — maturity. Carry is almost always positive for long-only bond portfolios, though an inverted curve reduces or eliminates the roll-down component.

Applying all three to the running example (duration 4.5 years, OAS 95 bps, YTM 5.15%) for a quarter where the 5-year Treasury fell 30 bps and OAS widened 40 bps:

| Component | Q1 contribution | Interpretation |
|---|---|---|
| Rate return | +135 bps | Rates fell; 4.5yr duration benefited |
| Spread return | −180 bps | OAS widened 40 bps; 4.5yr spread duration hurt |
| Carry | +32 bps | Coupon income + modest roll-down |
| **Total return** | **−13 bps** | Spread headwind overwhelmed rate tailwind |

Despite a rate tailwind, the spread widening overwhelmed the portfolio. An operations analyst reviewing these numbers sees a quarter where credit market conditions deteriorated even as Treasuries rallied — the two components told opposite stories.

In benchmark-relative mandates, each line item is computed as portfolio minus benchmark. A portfolio that had 30 bps more positive spread return than the index means the PM was underweight credit risk relative to the index when spreads widened — active value was added on the spread line.

<KnowledgeCheck question="An attribution report shows: rate return = −100 bps, spread return = +60 bps, carry = +30 bps. What does this tell you about the quarter's market environment?" options={["Both rates and spreads moved against the portfolio; carry was the only positive contributor", "Interest rates rose (rate return negative), but credit spreads compressed, partially offsetting the rate headwind; carry added a further cushion for a net −10 bps total return", "The rate return is wrong — a negative rate return can only occur when spreads also widen simultaneously", "The carry line overstates income because positive carry is only possible when the yield curve is inverted"]} correctIdx={1} explanation="Rate return is negative when interest rates rise (bond prices fall). Spread return is positive when OAS compressed (prices rose from tighter spreads). The opposite signs show a rotation: a rate headwind partially offset by a spread tailwind, with stable carry income. Net total ≈ −100 + 60 + 30 = −10 bps — a modest loss despite a significant rate-driven headwind." />

## Client-Report Language

Operations analysts assemble the attribution numbers and verify that the client-report narrative is internally consistent before it goes out. The language follows predictable patterns:

**Negative rate contribution** (rates rose):
> "Rising interest rates were the primary headwind during the quarter. The 10-year Treasury yield increased approximately X basis points, resulting in an estimated −Y basis points of rate return, reflecting the portfolio's duration exposure to the rate increase."

**Positive spread contribution** (spreads compressed):
> "Credit spreads tightened during the quarter as risk appetite improved, contributing approximately +Y basis points to total return."

**Carry as a buffer**:
> "Carry, representing coupon income and roll-down, contributed approximately +Y basis points, providing a stable income offset against rate and spread headwinds."

<Callout type="warning">Do not use "credit deterioration" or "fundamental weakness" language for market-wide spread moves. When the entire IG market widened 80 bps in a risk-off episode, attributing the loss to issuer-specific credit quality is inaccurate and potentially misleading to clients. Use "spread widening driven by risk-off market sentiment" instead, and escalate to the PM if you suspect the commentary overstates issuer-level causality.</Callout>

Consistency checks before clearing any attribution report:

| Check | Red flag |
|---|---|
| Rate return sign matches direction Treasury yields moved | Rate return positive when Treasuries rose → model error |
| Spread return sign matches direction of sector OAS | Spread return positive when sector OAS widened → data or benchmark error |
| Carry is positive | Negative carry in long-only portfolio → investigate |
| Rate + spread + carry ≈ total return | Residual > 10 bps: investigate; > 30 bps: escalate |

<KnowledgeCheck question="A client report draft states: 'Credit fundamentals improved, with the issuer's financial strength driving tighter spreads.' The spread contribution line shows +80 bps. What should the operations analyst check before clearing this narrative?" options={["Whether the issuer reported positive earnings, because attribution systems require a confirmed earnings-improvement source for positive spread return", "Whether the carry contribution is also positive, because spread compression and carry always move together in improving credit environments", "Whether sector-wide or market-wide OAS compression explains the spread return, and escalate to the PM if market-driven tightening is being attributed to issuer-specific credit quality", "Whether the rate return was negative, because only when rates fall can positive spread compression occur in a standard attribution table"]} correctIdx={2} explanation="Spread compression can be issuer-specific (upgrade, strong earnings) or market-wide (risk-on sentiment, Fed QE, yield-search environment). If the entire IG market tightened 80 bps that quarter, attributing the result to the issuer's financial strength is inaccurate. The analyst should compare the bond's OAS move to the sector or benchmark OAS move, and escalate if the narrative overstates issuer-specific drivers." />

---

## Hands-On Exercise

You are given a simplified attribution table for a Q1 period, two yield curve snapshots, and the following portfolio inputs: duration 4.5 years, spread duration 4.5 years, carry yield 5.15% annualized. Market inputs: 5-year Treasury yield fell 25 bps; portfolio OAS widened 35 bps.

1. Calculate rate return, spread return, and carry (assume a 90-day quarter, or approximately 0.25 years).
2. Sum all three components to estimate total return in basis points.
3. Write three client-report bullets — one for rate, one for spread, one for carry — using the language patterns from this chapter. Do not attribute spread widening to issuer fundamentals unless the data explicitly shows issuer-specific OAS moves.

**Success criteria:** Rate and spread calculations within ±5 bps of the worked answer; all three bullets state direction, magnitude, and cause without unsupported claims.

---

Next up: [[03-ldi-funded-status-hedge-ratios-attribution]] — reading funded status, duration gap, BPV, and hedge ratios in liability-driven investment mandates.
