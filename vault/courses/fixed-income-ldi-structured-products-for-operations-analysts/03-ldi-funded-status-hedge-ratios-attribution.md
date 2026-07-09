---
title: "LDI Funds: Funded Status, Hedge Ratios, and Liability-Relative Performance Attribution"
chapter: 3
course: fixed-income-ldi-structured-products-for-operations-analysts
status: draft
date: 2026-07-09
agent: chapter-author-3
type: course-draft
tags:
  - course/fixed-income-ldi-structured-products-for-operations-analysts
  - ldi
  - pension
  - funded-status
  - hedge-ratio
  - bpv
  - liability-relative
quiz:
  - question: "A pension plan has MVA of £500m and PVL of £550m. What is the funded ratio?"
    answer: "90.9% (500 ÷ 550 × 100). The plan is underfunded by £50m."
    topic: "Funded status, duration gap, BPV, and hedge ratio calculations"
  - question: "Why do LDI funds use a liability-relative benchmark rather than a standard bond index?"
    answer: "Because the fund's goal is to pay future benefits, not maximise total return. A plan can outperform its bond index while its funded status deteriorates if liabilities rise faster than assets. Risk for a pension plan is funded-status volatility, not tracking error against an index."
    topic: "Why LDI funds benchmark against liabilities rather than only a market index"
  - question: "A pension enters a receive-fixed interest rate swap on £200m notional with a duration of 14 years. BPV_A (physical assets) is £400,000. What is the new total BPV_A and revised hedge ratio if BPV_L is £990,000?"
    answer: "BPV_swap = 14 × £200m × 0.0001 = £280,000. Total BPV_A = £400k + £280k = £680k. New hedge ratio = £680k ÷ £990k = 68.7%, up from 40.4%."
    topic: "Effect of a receive-fixed swap overlay on the interest rate hedge ratio"
  - question: "An LDI portfolio returned +3% in a quarter while liabilities rose 5%. What does each benchmark show, and what actually happened to funded status?"
    answer: "Asset-only: manager outperformed (assuming the market index returned less than 3%). Liability-relative: the fund underperformed by 2 percentage points. Funded status deteriorated — the plan became more underfunded even though the asset portfolio gained."
    topic: "Asset-only versus liability-relative performance commentary"
  - question: "After a 50 bp gilt rally, a pension's BPV_L grows from £990k to £1,079k while BPV_A grows from £400k to £416k. What happens to the hedge ratio, and why?"
    answer: "Hedge ratio falls from 40.4% to 38.6% (£416k ÷ £1,079k). It falls because liability duration exceeds asset duration, so PVL rises faster than MVA, growing BPV_L faster than BPV_A. This is passive drift — no trading occurred."
    topic: "Explaining hedge-ratio movement after a gilt rally"
---

## Chapter 3: LDI Funds — Funded Status, Hedge Ratios, and Liability-Relative Performance Attribution

A defined-benefit (DB) pension plan promises to pay specific retirement benefits decades into the future. The present value of those promises moves with interest rates — and so does the value of the assets meant to fund them, but not by the same amount. Liability-driven investment (LDI) is the discipline of managing that gap.

---

### 1. Funded Status: The Balance Sheet View

Funded status is the primary health metric for a DB pension plan:

$$\text{Funded Status} = \text{Market Value of Assets (MVA)} - \text{Present Value of Liabilities (PVL)}$$

$$\text{Funded Ratio} = \frac{\text{MVA}}{\text{PVL}} \times 100\%$$

**Anchor example** — use these numbers throughout the chapter:

| Item | Value |
|------|-------|
| Plan assets (MVA) | £500m |
| Projected liabilities (PVL) | £550m |
| Funded status | –£50m (deficit) |
| Funded ratio | 90.9% |

A funded ratio above 100% means surplus; below 100% means deficit and the employer may face mandatory top-up contributions. Under IAS 19 / US GAAP, the discount rate used to calculate PVL is tied to high-quality corporate bond yields. When rates fall, PVL rises — the plan becomes more underfunded even if assets are unchanged.

---

### 2. Duration Gap and Basis Point Value (BPV)

Both the asset portfolio and the liability stream have duration. **Liability duration (D_L)** reflects the weighted average maturity of future benefit cash flows — typically 12–20 years for a UK final-salary scheme. **Asset duration (D_A)** is the market-value-weighted average duration of held assets.

The **duration gap** measures the mismatch:

$$\text{Duration Gap} = D_A - D_L$$

A negative gap means assets are shorter in duration than liabilities. When rates fall, PVL rises more than MVA rises — funded status deteriorates.

**Basis Point Value (BPV)** translates that mismatch into pound terms per basis point:

$$\text{BPV}_A = D_A \times \text{MVA} \times 0.0001$$
$$\text{BPV}_L = D_L \times \text{PVL} \times 0.0001$$

Continuing the anchor example (D_A = 8 years, D_L = 18 years):

| Metric | Calculation | Result |
|--------|-------------|--------|
| BPV_A | 8 × £500m × 0.0001 | £400,000/bp |
| BPV_L | 18 × £550m × 0.0001 | £990,000/bp |
| Duration gap | 8 – 18 | –10 years |
| BPV gap | £400k – £990k | –£590,000/bp |

A 1 bp fall in yields widens the deficit by ~£590,000; a 50 bp rally worsens funded status by £29.5m (50 × £590k).

---

### 3. Hedge Ratio and the Glidepath

The **hedge ratio** measures how much of the liability's interest-rate sensitivity the assets actually cover:

$$\text{Hedge Ratio} = \frac{\text{BPV}_A}{\text{BPV}_L} = \frac{£400k}{£990k} = 40.4\%$$

A ratio of 100% would mean the portfolio is fully immunised against parallel rate moves. At 40%, roughly 60% of the liability risk is unhedged.

Because fully hedging at a low funded ratio locks in the deficit, trustees use a **glidepath** — a pre-agreed schedule that raises the hedge ratio target as the funded ratio improves:

| Funded ratio trigger | Target hedge ratio |
|---------------------|--------------------|
| Below 90% | ~40% |
| 90–95% | ~60% |
| 95–100% | ~80% |
| Above 100% | 95–100% |

At low funded ratios, return-seeking assets (equities, alternatives) provide recovery growth. As funding improves, protecting the surplus takes priority.

---

### 4. Receive-Fixed Swap Overlay

To raise the hedge ratio without selling growth assets, LDI managers add a **receive-fixed interest rate swap**. The plan receives a fixed rate and pays floating (e.g. SONIA) on an agreed notional. The fixed leg behaves like a long-dated bond — it adds positive duration.

$$\text{BPV}_{\text{swap}} \approx D_{\text{swap}} \times \text{Notional} \times 0.0001$$

For a 20-year swap on £200m notional with 14-year duration: BPV_swap = 14 × £200m × 0.0001 = **£280,000/bp**.

| Item | Before swap | After swap |
|------|-------------|------------|
| BPV_A (physical) | £400,000 | £400,000 |
| BPV_swap | — | £280,000 |
| Total BPV | £400,000 | **£680,000** |
| Hedge ratio | 40.4% | **68.7%** |

The swap overlay raised the hedge ratio by 28 percentage points without touching growth assets. Swaps require collateral posting (initial and variation margin under post-2022 clearing rules), and daily mark-to-market flows through the fund's reported asset value.

---

### 5. Liability-Relative vs Asset-Only Benchmark

An **asset-only benchmark** measures portfolio return against a market index (e.g. Bloomberg Sterling Aggregate). A manager can beat that index and still leave the plan worse off if liabilities rose faster than assets.

A **liability-relative benchmark** measures the change in funded status directly:

$$\text{Liability-Relative Return} = R_A - R_L$$

where R_L is the return on a notional portfolio replicating the liability cash-flow stream.

LDI funds use a liability-relative benchmark because the fund's purpose is meeting future benefit obligations, not maximising total return; regulatory frameworks (UK TPR, ERISA) require trustees to monitor funded status; and "risk" for a pension plan means funded-status volatility, not tracking error against a bond index.

---

### 6. Liability-Relative Performance Attribution

When reporting monthly LDI performance, the attribution should decompose what drove the funded-status movement:

| Driver | Impact on Funded Status |
|--------|------------------------|
| Interest rate fall of 15 bps | –£8.85m |
| Swap overlay offset (receive-fixed) | +£4.20m |
| Return-seeking assets (equities +1.5%) | +£3.50m |
| Employer contribution | +£2.00m |
| **Net change** | **–£0.85m** |
| Opening funded status | –£50.0m |
| **Closing funded status** | **–£50.85m** |

An important operations pitfall: **not all hedge-ratio movement is caused by trading**. When yields fall, BPV_L grows faster than BPV_A (because D_L > D_A), so the hedge ratio drifts down passively. Always distinguish passive drift from yield moves versus changes driven by portfolio transactions.

---

### 7. Sample Monthly Commentary

Here is a three-sentence commentary for the anchor pension following a 15 bp rate fall:

> "During the month, the fund's funded ratio declined from 90.9% to 90.8%, as a 15 bp fall in gilt yields increased the present value of liabilities by approximately £14.9m. The receive-fixed swap overlay offset £4.2m of that liability increase, limiting the interest-rate drag to £8.85m net; the 40.4% hedge ratio reflects the plan's current glidepath position targeting growth-asset exposure while the funded ratio remains below 90%. Return-seeking assets contributed +£3.5m and the quarterly employer contribution of £2.0m partially offset the rate impact, leaving a net funded-status movement of –£0.85m for the period."

This structure — opening metric, rate driver and hedge offset, other contributors and net — is standard in LDI manager monthly reports.

---

### Key Takeaways

- **Funded status** = MVA – PVL; **funded ratio** = MVA ÷ PVL × 100%.
- **Duration gap** = D_A – D_L; negative means assets are shorter-duration than liabilities and funded status falls when rates fall.
- **BPV** converts the duration gap into £ sensitivity per basis point; the **hedge ratio** = BPV_A ÷ BPV_L.
- A **receive-fixed swap overlay** adds BPV to the numerator, raising the hedge ratio without disturbing growth assets.
- After a gilt rally, the hedge ratio **falls passively** because BPV_L rises faster than BPV_A — this is not a trading error.
- LDI funds benchmark against liabilities because the plan's numeraire is funded status, not total return.
