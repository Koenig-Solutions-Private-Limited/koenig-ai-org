---
chapter_num: 1
course_slug: fixed-income-ldi-structured-products-for-operations-analysts
title: "Bond Pricing Mechanics: Calculating Yield, Duration, and Convexity from Scratch"
status: awaiting-g0
duration_min: 35
vendor_tag: Fixed Income / Investment Operations
learning_objectives:
  - "Construct a fixed-rate bond cash-flow schedule from coupon rate, par value, maturity, and payment frequency"
  - "Calculate a bond's clean price using the DCF formula and Excel's PV() or PRICE() function"
  - "Interpret yield-to-maturity and explain the inverse price-yield relationship with numerical examples"
  - "Apply modified duration to estimate the percentage price change for a 100 bps parallel yield shift"
  - "Use the convexity correction to improve price-change estimates for large yield moves"
  - "Locate YTM, modified duration, convexity, and DV01 on Bloomberg DES and YAS pages"
sources:
  - url: "https://www.pimco.com/en-us/resources/education"
    title: "Understanding Duration — PIMCO Education"
  - url: "https://docs.microsoft.com/en-us/office/vba/api/excel.worksheetfunction.price"
    title: "Excel PRICE Function Reference — Microsoft"
  - url: "https://www.cfainstitute.org/en/membership/professional-development/refresher-readings/introduction-to-fixed-income-valuation"
    title: "CFA Institute: Introduction to Fixed Income Valuation"
owns:
  - "Fixed-rate bond cash-flow schedule construction from coupon, par, maturity, and payment frequency"
  - "Discounted cash-flow bond price calculation in Excel using spot or flat yield assumptions"
  - "Yield-to-maturity interpretation and the inverse price-yield relationship"
  - "Modified duration calculation and interpretation as approximate percentage price change for a 100 bps yield move"
  - "Convexity calculation and why duration alone misstates large rate moves"
  - "Parallel yield curve shift impact on a single bond or simple bond portfolio given duration and convexity"
  - "Bloomberg DES and YAS field mapping for yield, spread, modified duration, and convexity"
defers_to:
  - "Negative convexity mechanics in callable bonds and mortgage-backed securities → ch4"
  - "Steepening and flattening yield curve attribution line items → ch2"
  - "Z-spread, OAS, and ASW spread analytics → ch2"
  - "LDI liability duration, BPV, hedge ratios, and swap overlay mechanics → ch3"
quiz_topics:
  - "Discounted cash-flow price calculation for a fixed-rate bond"
  - "How yield changes affect bond price direction and magnitude"
  - "Modified duration interpretation for a 100 bps yield move"
  - "Convexity adjustment for larger rate moves"
  - "Mapping Bloomberg DES/YAS fields to economic meaning"
notebooklm_source_focus:
  - "CFA fixed income basics: bond pricing, yield-to-maturity, duration, and convexity"
  - "Bloomberg DES and YAS page field definitions for fixed income securities"
  - "Excel fixed income DCF modeling examples for fixed-rate bonds"
  - "Institutional bond reporting examples using modified duration and convexity"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "A bond pays a 4% annual coupon, has $1,000 par value, 5-year maturity, and semi-annual payments. At a 5% YTM, what is its approximate clean price?"
    options:
      - "$1,000.00 — par value, reached only when the YTM equals the annual coupon rate of 4%"
      - "$956.25 — a discount below par, because the 5% market yield exceeds the 4% coupon rate"
      - "$1,045.79 — a premium above par, matching the price implied by a 3% YTM on this bond"
      - "$978.35 — the dirty price after adding one period's accrued coupon interest to the clean figure"
    correct_idx: 1
    explanation: "DCF discounts ten $20 coupon payments and the $1,020 final cash flow at r = 2.5% per period. The sum is $956.25. The bond trades at a discount because the market yield (5%) exceeds the coupon rate (4%); the price shortfall is the concession that brings the buyer's total return up to 5%."
    section_anchor: pricing-a-bond-with-discounted-cash-flows
  - question: "A bond's YTM rises above its coupon rate. Which outcome does the inverse price-yield relationship predict?"
    options:
      - "Price rises to a premium above par, because higher yields signal stronger investor demand for the bond"
      - "Price falls to a discount below par, because investors require more return than the fixed coupon delivers"
      - "Price holds at par throughout, since the bond's face value is contractually fixed and cannot change"
      - "Price rises initially then falls, with the turning point determined by the bond's remaining tenor"
    correct_idx: 1
    explanation: "When yields rise above the coupon rate, the bond's fixed cash flows are less competitive than new-issue alternatives. Price must fall below par so that total effective return — coupon income plus pull-to-par appreciation — equals the market yield. When YTM equals the coupon rate, price equals par exactly."
    section_anchor: yield-to-maturity-and-the-price-yield-relationship
  - question: "A bond has a modified duration of 4.37. Market yields rise by 100 basis points. The approximate percentage price change is:"
    options:
      - "A gain of approximately 4.37%, because duration measures price sensitivity symmetrically in either yield direction"
      - "A loss of approximately 0.44%, because duration applies only to the short end of the yield curve"
      - "A loss of approximately 4.37%, because %ΔP ≈ −D_Mod × Δy and 100 bps expressed as 0.01 yields −4.37%"
      - "A loss of approximately 43.7%, because the basis-point sensitivity compounds over the bond's full maturity horizon"
    correct_idx: 2
    explanation: "The modified-duration formula is %ΔP ≈ −D_Mod × Δy. With D_Mod = 4.37 and Δy = +0.01, the result is −4.37%. The sign is always negative for a yield increase. In dollar terms on a $956.25 bond, this is approximately −$41.79."
    section_anchor: modified-duration-your-rate-sensitivity-shortcut
  - question: "For a 200 bps yield increase, adding the convexity correction to a duration-only estimate has which effect?"
    options:
      - "It increases the predicted price loss, because the convexity term amplifies the directional duration effect"
      - "It has no effect on the estimate, because convexity adjustments apply only to yield decreases"
      - "It reduces the predicted price loss, because the positive convexity correction adds back a price offset"
      - "It turns the predicted loss into a net price gain for any yield move exceeding 150 basis points"
    correct_idx: 2
    explanation: "The convexity term is +0.5 × Convexity × (Δy)², which is always positive. For Δy = 0.02 and Convexity = 22.5, the correction is +0.45%, trimming the duration-only −8.74% estimate to −8.29% — versus the actual DCF result of −8.22%. The convexity term always adds to the price estimate, in both directions."
    section_anchor: convexity-correcting-durations-error-on-large-moves
  - question: "An ops analyst needs to verify a bond's modified duration and DV01 against the risk system. Which Bloomberg page provides these analytics?"
    options:
      - "DES — the bond description page, which shows the coupon rate, maturity, settlement date, and day count"
      - "YAS — the yield and spread analysis page, displaying YTM, modified duration, convexity, and DV01"
      - "CSHF — the cash-flow schedule page, which shows each coupon date and projected payment amount"
      - "SECF — the security finder, which searches for bonds by rating, currency, maturity, and issuer type"
    correct_idx: 1
    explanation: "YAS is Bloomberg's analytics pricing screen. It shows YTM (YLD_YTM_MID), clean and dirty price, modified duration (DUR_ADJ_MID), convexity (CONVEXITY_MID), and DV01/RISK. DES provides static description fields — useful for verifying inputs such as coupon, maturity, and day-count convention, but not rate-sensitivity analytics."
    section_anchor: bloomberg-des-and-yas-the-ops-analysts-reference
---

Every fixed income calculation in this course traces back to four mechanics: cash-flow construction, DCF pricing, duration, and convexity. Master them on a single bond here, then apply them to portfolios, LDI mandates, and client reports in the chapters that follow.

## Building the Cash-Flow Schedule

A fixed-rate bond delivers two types of cash flows: periodic coupon payments and a par repayment at maturity. Before you can price or stress-test anything, you need the complete schedule of those flows.

Four inputs: par value ($1,000 in examples), annual coupon rate, maturity, and payment frequency. US investment-grade corporates and Treasuries pay semi-annually. A 4% coupon on $1,000 par produces $20 every six months. Over 5 years that is ten $20 coupons, with the final period delivering $1,020 (last coupon + par). This bond is the anchor example for the chapter.

## Pricing a Bond with Discounted Cash Flows

Bond price equals the present value of all future cash flows discounted at the yield-to-maturity. The formula:

$$P = \sum_{t=1}^{N} \frac{C}{(1 + y/m)^t} + \frac{F}{(1 + y/m)^N}$$

Where C = coupon per period, F = face value, y = annual YTM, m = periods per year, N = total periods.

For the anchor bond at 5% YTM: r = 2.5%, N = 10, C = $20. Discounting all cash flows at 2.5% per period gives **$956.25** — a discount to par, because market yield (5%) exceeds the coupon rate (4%). That shortfall is the concession that brings the buyer's return to 5%.

In Excel, two approaches work for flat-yield pricing:

```excel
=PV(YTM/2, years*2, -coupon_payment, -par)         ← clear; use for learning
=PRICE(settlement, maturity, coupon, YTM, 100, 2)   ← production-ready; handles day count
```

The [Excel PRICE function](https://docs.microsoft.com/en-us/office/vba/api/excel.worksheetfunction.price) returns clean price per $100 par and handles settlement date and day-count conventions automatically. Traders quote clean price; settlement uses the dirty price (clean + accrued interest). Bloomberg YAS shows both.

<KnowledgeCheck question="A bond pays a 4% annual coupon, has $1,000 par value, 5-year maturity, and semi-annual payments. At a 5% YTM, what is its approximate clean price?" options={["$1,000.00 — par value, reached only when the YTM equals the annual coupon rate of 4%", "$956.25 — a discount below par, because the 5% market yield exceeds the 4% coupon rate", "$1,045.79 — a premium above par, matching the price implied by a 3% YTM on this bond", "$978.35 — the dirty price after adding one period's accrued coupon interest to the clean figure"]} correctIdx={1} explanation="DCF discounts ten $20 coupon payments and the $1,020 final cash flow at r = 2.5% per period. The sum is $956.25. The bond trades at a discount because the market yield (5%) exceeds the coupon rate (4%); the price shortfall is the concession that brings the buyer's total return to 5%." />

## Yield-to-Maturity and the Price-Yield Relationship

YTM is the discount rate that equates a bond's present value to its market price, assuming you hold to maturity and reinvest all coupons at that same rate. The reinvestment assumption rarely holds — treat YTM as a promised yield, not a guaranteed return.

The governing rule is the inverse price-yield relationship: **yields rise → prices fall; yields fall → prices rise.** If the market demands 6% but your bond pays 4%, the price must fall until the effective return reaches 6%. The cash flows are fixed; the price adjusts.

For the anchor bond, three scenarios illustrate this:

| YTM | Price | Status |
|-----|-------|--------|
| 3% | $1,045.79 | Premium |
| 4% | $1,000.00 | Par |
| 5% | $956.25 | Discount |

When YTM equals the coupon rate, price equals par exactly — a quick sanity check on any incoming data feed.

## Modified Duration: Your Rate-Sensitivity Shortcut

Modified duration tells you how much a bond's price changes, in percentage terms, for a small parallel yield shift. It derives from Macaulay duration — the weighted-average time to receive cash flows — adjusted for compounding:

$$D_{Mod} = \frac{D_{Mac}}{1 + y/m}$$

For the anchor bond at 5% YTM: D_Mac ≈ 4.48 years, so D_Mod = 4.48 ÷ 1.025 = **4.37**.

The practical rule: **%ΔP ≈ −D_Mod × Δy** (Δy in decimal).

A 100 bps yield increase gives −4.37 × 0.01 = **−4.37%**, or −$41.79 on the $956.25 bond. Longer bonds carry higher duration; higher-coupon bonds carry lower duration because early coupons pull the weighted-average timing forward.

Dollar duration — DV01 or PVBP — converts this to dollars per basis point: D_Mod × Price × 0.0001. Here: 4.37 × $956.25 × 0.0001 = **$0.42 per $1,000 par**, visible on Bloomberg YAS as "Risk." [PIMCO's Understanding Duration](https://www.pimco.com/en-us/resources/education) covers DV01 in institutional reporting context.

<Callout type="warning">Duration is a **linear approximation** of a **curved** price-yield relationship. For yield moves of ≤25 bps the error is negligible. For moves of 100 bps or more, the error compounds — and that is where convexity earns its place.</Callout>

<KnowledgeCheck question="A bond has a modified duration of 4.37. Market yields rise by 100 basis points. The approximate percentage price change is:" options={["A gain of approximately 4.37%, because duration measures price sensitivity symmetrically in either yield direction", "A loss of approximately 0.44%, because duration applies only to the short end of the yield curve", "A loss of approximately 4.37%, because %ΔP ≈ −D_Mod × Δy and 100 bps expressed as 0.01 yields −4.37%", "A loss of approximately 43.7%, because the basis-point sensitivity compounds over the bond's full maturity horizon"]} correctIdx={2} explanation="The modified-duration formula is %ΔP ≈ −D_Mod × Δy. With D_Mod = 4.37 and Δy = +0.01, the result is −4.37%. The sign is always negative for a yield increase. In dollar terms on a $956.25 bond, this is approximately −$41.79." />

## Convexity: Correcting Duration's Error on Large Moves

Duration is a tangent line on the price-yield curve. The curve bows outward — that curvature is convexity, which becomes material when yield moves exceed a few dozen basis points.

The full second-order price-change formula:

$$\%\Delta P \approx -D_{Mod} \cdot \Delta y + \frac{1}{2} \cdot \text{Convexity} \cdot (\Delta y)^2$$

For the anchor bond (Convexity ≈ 22.5), on a **200 bps yield increase** (Δy = 0.02):

| Component | Estimate |
|-----------|----------|
| Duration effect | −4.37 × 0.02 = −8.74% |
| Convexity correction | +0.5 × 22.5 × (0.02)² = +0.45% |
| Total estimate | **−8.29%** |
| Actual DCF result | **−8.22%** |

The convexity correction cuts the error from 52 bps to 7 bps. The term is always positive: it reduces losses on yield rises and amplifies gains on yield falls — the asymmetric advantage that makes high-convexity bonds command a premium.

Negative convexity, where callable bonds and mortgage-backed securities lose price upside as yields fall, is covered in [[04-structured-products-mbs-abs-cmbs-clo-tranching]].

## Parallel Shifts on a Bond Portfolio

For a portfolio, modified duration is the market-value-weighted average of each holding's duration:

$$D_{Port} = \sum_{i} w_i \cdot D_{Mod,i}$$

A two-bond portfolio with equal allocations to a 4.37-duration bond and a 7.85-duration bond has a portfolio duration of **6.11**. A parallel 100 bps yield decrease adds an estimated **+$61,100** to a $1,000,000 portfolio.

DV01 is simply additive across positions. If portfolio DV01 = $1,000 per basis point, selling $1,000 DV01 of Treasury futures eliminates the parallel-shift exposure.

This analysis assumes a fully parallel shift. Non-parallel moves — steepening and flattening — and their attribution line items are owned by [[02-credit-spreads-yield-curves-reporting-metrics]].

## Bloomberg DES and YAS: The Ops Analyst's Reference

Bloomberg's **DES** page is the bond fact sheet. For pricing mechanics, check COUPON, MATURITY, PAYMENT_FREQUENCY (Cpn Freq), SETTLE_DT, and DAY_CNT (30/360 for corporates; Actual/Actual for Treasuries). Settlement date and day-count drive accrued interest — a mismatch here is where to look first when dirty price diverges from a counterparty confirm.

Bloomberg's **YAS** page is the analytics hub. Fields directly in scope for this chapter:

| YAS Field | Bloomberg Label | Economic Meaning |
|-----------|-----------------|-----------------|
| YLD_YTM_MID | Yield | YTM at current market price |
| PX_MID / PX_LAST | Price | Clean price |
| PX_DIRTY | Full Price | Dirty price (clean + accrued interest) |
| DUR_ADJ_MID | Mod Dur | Modified duration |
| CONVEXITY_MID | Convexity | Annual convexity |
| DV01 / RISK | Risk | Dollar value of 1 bp per $1M face |

Z-Spread, OAS, and ASW also appear on YAS — those spread analytics are owned by [[02-credit-spreads-yield-curves-reporting-metrics]].

Ops reconciliation check: your risk system's modified duration should match YAS `Mod Dur` within ±0.05 years. A larger gap traces to a settlement-date mismatch, a day-count difference, or a stale price feed. Quick sanity check: if a bond's price rose on a day when rates also rose, the feed is wrong — the inverse price-yield relationship has no exceptions.

---

## Hands-On Exercise

Load any investment-grade corporate bond in Bloomberg (e.g., `AAPL 3.85 05/04/43 <Corp> DES <GO>`). Record COUPON, MATURITY, PAYMENT_FREQUENCY, and DAY_CNT. Switch to YAS and record clean price, YTM, modified duration, and DV01. In Excel, replicate the clean price with `=PRICE(TODAY()+2, maturity_date, coupon, YTM, 100, 2)`. Then estimate the repriced clean price for a 50 bps yield rise using `clean_price × (1 − D_Mod × 0.005)` and compare against Bloomberg's repriced YAS result.

**Success criteria:** Excel DCF price within ±$0.05 per $100 par of Bloomberg's clean price; duration-estimated price change within ±0.25% of Bloomberg's repriced result.

---

Next up: [[02-credit-spreads-yield-curves-reporting-metrics]] — decomposing bond yield into a risk-free rate and credit spread, and reading the attribution line items that result.
