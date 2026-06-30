---
chapter_num: 2
course_slug: piping-engineering-fundamentals-asme-b31
title: "Selecting Pipe Materials, Schedules, and Piping-Class Specifications to ASME B31.3 (2022/2024 Edition)"
status: awaiting-g0
duration_min: 14
vendor_tag: ASME B31.3
learning_objectives:
  - "Apply the B31.3 Para. 304.1.2 wall-thickness equation using all seven required inputs"
  - "Classify a piping system into the correct B31.3 fluid service category from process conditions"
  - "Select pipe schedule, material grade, and corrosion allowance for a carbon-steel hydrocarbon example"
  - "Diagnose and correct wall-thickness errors caused by wrong Y coefficient or quality factor E"
sources:
  - url: "https://www.asme.org/codes-standards/find-codes-standards/b31-3-process-piping"
    title: "ASME B31.3-2024 Process Piping — Official Product Page"
  - url: "https://epcland.com/fluid-list-fluid-categories/"
    title: "ASME B31.3 Fluid Service Categories: The 2026 Engineering Guide — EPCLand"
  - url: "https://makepipingeasy.com/pipe-thickness-calculation-for-internal-pressure/"
    title: "Pipe Thickness Calculation for Internal Pressure — Make Piping Easy"
  - url: "https://blog.projectmaterials.com/pipes/pipe-tube-sizes/asme-b36-10-19-pipe-sizes-charts/"
    title: "ASME B36.10 Pipe Sizes & Schedules — Projectmaterials"
  - url: "https://industrialmonitordirect.com/blogs/knowledgebase/asme-b313-efw-vs-smls-pipe-pressure-classification-weld-factors"
    title: "EFW vs SMLS Pipe: ASME B31.3 Weld Joint Quality Factors — Industrial Monitor Direct"
  - url: "https://whatispiping.com/importance-of-y-factor-asme-b31-3/"
    title: "The Importance of Y Factor in ASME B31.3 — What Is Piping"
  - url: "https://becht.com/becht-blog/entry/when-should-category-m-fluid-service-be-selected-for-asme-b31-3-piping-systems/"
    title: "When Should Category M Fluid Service be Selected — Becht Engineering"
  - url: "https://www.servicesteel.org/resources/astm-a106-pipe"
    title: "ASTM A106 Pipe Explained: Specs & Properties — Service Steel"
  - url: "https://epcland.com/corrosion-allowance-piping/"
    title: "Corrosion Allowance in Piping: ASME B31.3 Calculation & Mistakes — EPCLand"
  - url: "https://blog.projectmaterials.com/epc-projects/engineering/pipe-class-vs-specification/"
    title: "Pipe Class vs Pipe Specification — Projectmaterials"
owns:
  - "Applying ASME B31.3 wall-thickness logic for NPS, design pressure, temperature, material, quality factor, Y coefficient, and corrosion allowance"
  - "Classifying B31.3 fluid service as Normal, Category D, Category M, or High-Pressure from supplied process conditions"
  - "Selecting a piping class, pipe schedule, material grade, and examination basis for carbon-steel hydrocarbon and high-temperature steam examples"
  - "Finding and correcting common B31.3 sizing errors involving elevated-temperature Y coefficients and quality factor E"
defers_to:
  - "P&ID symbol extraction and line designation interpretation → ch1"
  - "CAESAR II stress model setup and geometry entry → ch3"
  - "B31J SIF calculation and comparison to Appendix D → ch4"
  - "AutoCAD Plant 3D layout and material take-off → ch5"
quiz_topics:
  - "ASME B31.3 wall-thickness inputs and equation terms"
  - "Fluid-service classification"
  - "Pipe schedule, material grade, and corrosion allowance selection"
  - "Y coefficient and quality factor error diagnosis"
notebooklm_source_focus:
  - "Official ASME B31.3 product and table-of-contents pages for scope and edition framing"
  - "Public engineering references explaining B31.3 pipe wall thickness inputs without reproducing restricted code text"
  - "Fluid-service classification summaries from reputable training or engineering sources"
  - "ASTM pipe material and schedule reference tables from public manufacturer or engineering handbooks"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which term in the B31.3 Para. 304.1.2 equation is defined as 1.0 for seamless pipe because it has no longitudinal seam weld?"
    options:
      - "The Y coefficient, which represents ductility and approaches 1.0 for highly ductile metals at any temperature"
      - "The weld joint strength reduction factor W, which is 1.0 for all pipe types operated below the creep temperature"
      - "The weld joint quality factor E, which equals 1.0 for seamless pipe because there is no longitudinal seam to reduce"
      - "The allowable stress S, which is read from Table A-1 at full material strength for seamless pipe grades"
    correct_idx: 2
    explanation: "E (weld joint quality factor) is specifically tied to the longitudinal weld type and NDE level. Seamless pipe has no longitudinal weld, so E = 1.0 by definition. W = 1.0 below the creep range for all pipe types — that is a temperature condition, not a manufacturing condition. Y and S are independent of seam weld presence."
    section_anchor: the-b313-wall-thickness-equation-seven-inputs-one-result
  - question: "A utility steam line runs at 120 psig and 175°C. The fluid is non-flammable and non-toxic. Which B31.3 fluid service category applies?"
    options:
      - "Normal Fluid Service, because steam is a utility fluid rather than a classified process stream"
      - "Category M, because steam at 175°C can cause serious irreversible scalding injury on skin contact"
      - "Category D, because pressure is below 150 psig and both temperature and fluid conditions qualify"
      - "High Pressure, because saturated steam at 175°C requires a minimum Class 300 flange rating"
    correct_idx: 2
    explanation: "Category D requires all four: pressure ≤ 150 psig, temperature between −29°C and +186°C, non-flammable, and non-toxic. 120 psig / 175°C utility steam meets every criterion. Category M requires risk of irreversible harm from a single small undetected leak — general scalding risk from steam does not clear that bar."
    section_anchor: fluid-service-classification-where-your-examination-budget-comes-from
  - question: "Which procedure correctly converts a calculated minimum required thickness (tm) into a pipe schedule selection?"
    options:
      - "Select the lightest standard schedule whose nominal wall thickness equals or exceeds tm directly"
      - "Select the lightest standard schedule whose nominal wall, multiplied by 0.875, equals or exceeds tm"
      - "Select the lightest standard schedule whose nominal wall, divided by 1.125, equals or exceeds tm"
      - "Select the schedule whose nominal wall equals tm plus the full corrosion allowance applied again as margin"
    correct_idx: 1
    explanation: "B36.10M permits a manufacturing undertolerance of −12.5%, so the minimum guaranteed wall is 87.5% of nominal. A nominal wall that exactly matches tm will be below tm in worst-case material. Dividing tm by 0.875 gives the minimum acceptable nominal wall; the next heavier standard schedule above that value is the selection."
    section_anchor: selecting-material-grade-schedule-and-corrosion-allowance
  - question: "A 550°C steam header uses A335 P22 pipe. An engineer applies Y = 0.4, the sub-482°C ferritic default, rather than looking up the correct elevated-temperature value. What is the consequence?"
    options:
      - "The calculated wall is dangerously thin because the correct elevated-temperature Y reduces the denominator further"
      - "The calculated wall is unnecessarily thick because the correct elevated-temperature Y is higher, increasing the denominator and lowering required t"
      - "The calculation fails entirely because B31.3 prohibits ferritic steel above 482°C without engineering approval"
      - "There is no consequence because Y = 0.4 is the universal default for all ferritic grades at any temperature"
    correct_idx: 1
    explanation: "For ferritic steels above 482°C (900°F), Table 304.1.1 specifies Y values higher than 0.4 (approaching 0.7). A higher Y makes the denominator 2(SEW + PY) larger, which reduces calculated t. Using the lower Y = 0.4 gives a larger t than needed — conservative but costly in premium Cr-Mo alloy pipe priced by schedule. The inverse error (using a high-temperature Y at low temperature) produces a dangerously thin wall."
    section_anchor: two-errors-that-can-sink-a-design
---

## The B31.3 Wall-Thickness Equation: Seven Inputs, One Result

ASME B31.3 Para. 304.1.2 governs wall-thickness design for straight pipe under internal pressure. The equation is:

```
t  = PD / [2(SEW + PY)]
tm = t + c
```

Seven inputs feed this equation. Getting any one wrong shifts every downstream decision — schedule, material cost, and examination programme.

| Symbol | Quantity | Source |
|--------|----------|--------|
| P | Internal design pressure | Process datasheet |
| D | Pipe outside diameter | ASME B36.10M / B36.19M — fixed per NPS |
| S | Allowable stress at design temperature | B31.3 Table A-1 |
| E | Weld joint quality factor (0.60–1.00) | B31.3 Table A-1B |
| W | Weld joint strength reduction factor | B31.3 Table 302.3.5 |
| Y | Temperature coefficient | B31.3 Table 304.1.1 |
| c | Total allowances (corrosion + erosion + mechanical) | Specified by discipline |

The equation is valid only when t < D/6. Walls thicker than that threshold require the Lamé thick-wall equation instead.

Two facts about D matter immediately. The outside diameter is fixed per NPS — NPS 6" always has OD = 168.3 mm regardless of which schedule you choose; only the wall thickness and bore change. And once you have tm (minimum required thickness), you cannot select a schedule by comparing nominal wall to tm directly. [ASME B36.10M permits a manufacturing undertolerance of −12.5%](https://blog.projectmaterials.com/pipes/pipe-tube-sizes/asme-b36-10-19-pipe-sizes-charts/), so the pipe you receive is guaranteed to be at minimum 87.5% of its nominal wall. The correct procedure: divide tm by 0.875 to find the minimum acceptable nominal wall, then step up to the next heavier standard schedule.

**Worked example — NPS 6" crude oil, 20 MPa, 100°C, A106 Gr.B seamless.** E = 1.0 (seamless, no longitudinal weld), W = 1.0 (below creep range), Y = 0.4 (ferritic steel below 482°C), S ≈ 138 MPa, corrosion allowance c = 3.0 mm (sweet hydrocarbon service).

```
t  = (20 × 168.3) / [2(138 × 1.0 × 1.0 + 20 × 0.4)] = 3366 / 292 ≈ 11.5 mm
tm = 11.5 + 3.0 = 14.5 mm
Required nominal wall = 14.5 / 0.875 = 16.6 mm
```

Schedule 80 (nominal 10.97 mm, minimum guaranteed 9.60 mm) fails outright. Schedule 160 (nominal 18.26 mm, minimum guaranteed 15.98 mm) clears the required 14.5 mm and is the correct selection. [Make Piping Easy's pipe thickness walkthrough](https://makepipingeasy.com/pipe-thickness-calculation-for-internal-pressure/) provides an independently verified step-through of the same procedure.

<KnowledgeCheck question="In the B31.3 Para. 304.1.2 equation, NPS 6\" pipe always has OD = 168.3 mm regardless of the schedule chosen. Why?" options={["OD scales with schedule so flow velocity stays constant across thicker-wall grades", "OD is fixed per NPS by ASME B36.10M; only wall thickness changes, which cuts into the bore", "OD differs between B36.10M and B36.19M for the same NPS designation", "OD equals the NPS number in inches for all pipe sizes above NPS 2\""]} correctIdx={1} explanation="ASME B36.10M fixes the OD for each NPS. Higher schedule numbers produce thicker walls that reduce the bore (ID), while the OD stays constant so flanges and fittings remain interchangeable." />

## Fluid Service Classification: Where Your Examination Budget Comes From

Before you size a single fitting, classify the fluid service. That classification determines the entire NDE and proof-testing programme — which means it directly controls a large fraction of construction cost and schedule.

**Category D** is the lowest-stringency category. All four criteria must be met: design gauge pressure ≤ 150 psig, design temperature between −29°C and +186°C, fluid is non-flammable, and fluid is non-toxic. Cooling water, instrument air, and low-pressure nitrogen are classic examples. No volumetric NDE is required; the leak test is a service test at operating pressure rather than the 1.5× hydrostatic proof test required elsewhere.

**Normal Fluid Service** is the default for everything that fails any one of the Category D criteria. Most hydrocarbon process piping — crude oil, propylene, naphtha at typical refinery conditions — lands here. Requirements include a minimum of 5% random volumetric examination on butt welds and a hydrostatic test at 1.5× design pressure.

**Category M** is the most frequently misclassified category. The test is not "this fluid is toxic." The standard is whether a single small, undetected leak could cause serious and irreversible harm before a response could be mounted. [Becht Engineering's Category M guidance](https://becht.com/becht-blog/entry/when-should-category-m-fluid-service-be-selected-for-asme-b31-3-piping-systems/) is precise on this: HF acid in many open-air plant configurations is not Category M because supplemental safeguards (PPE, dispersion distances, emergency response) make harm avoidable. Phosgene and methyl isocyanate qualify because a small release at point of use causes irreversible injury before evacuation is possible. Category M drives ≥ 20% random RT on welds plus a mandatory sensitive leak test added to the standard 1.5× hydrostatic test — a major cost and schedule increment.

**High Pressure (Chapter IX)** applies when design pressure exceeds the ASME B16.5 Class 2500 flange rating at coincident design temperature. The owner designates Chapter IX applicability. NDE requirements jump to 100% volumetric examination — a 20× increase in scope relative to Normal Fluid Service. The [EPCLand fluid service categories guide](https://epcland.com/fluid-list-fluid-categories/) tabulates all categories side by side and is useful for rapid cross-checks.

<KnowledgeCheck question="Butane at 80 psig and 40°C: which B31.3 fluid service category applies?" options={["Category D, because the design pressure is well below the 150 psig threshold", "Normal Fluid Service, because butane is flammable and therefore fails one of the Category D criteria", "Category M, because butane vapour is harmful if inhaled at sufficient concentration", "High Pressure, because liquefied petroleum gases require Chapter IX treatment regardless of pressure"]} correctIdx={1} explanation="Category D excludes all flammable fluids. Butane is flammable, so it cannot qualify for Category D regardless of how low the pressure is. It defaults to Normal Fluid Service, which requires 5% random RT on butt welds and a 1.5× hydrostatic test." />

## Selecting Material Grade, Schedule, and Corrosion Allowance

Three decisions execute in sequence once you have classified the fluid service and computed tm.

**Material grade** sets S and defines the valid temperature ceiling. [ASTM A106 Grade B](https://www.servicesteel.org/resources/astm-a106-pipe) seamless is the industry default for carbon-steel process piping to roughly 425°C (800°F): 60,000 psi (415 MPa) tensile strength, 35,000 psi (241 MPa) yield, and broad mill availability. Above 425°C, chromium-molybdenum grades take over — A335 P11 (1.25Cr-0.5Mo) to about 540°C, then P22 (2.25Cr-1Mo) or P91 for sustained high-temperature steam headers. For corrosive or high-purity service, ASTM A312 TP316L austenitic stainless eliminates the corrosion allowance term: CA = 0 mm.

**Schedule** selection follows directly from tm. Confirm the OD from B36.10M (carbon/alloy) or B36.19M (stainless), compute the required nominal wall as tm ÷ 0.875, and step up to the next heavier standard schedule. Note that the "S" suffix schedules on B36.19M (5S, 10S, 40S, 80S) can have different wall thicknesses from their non-suffix counterparts at small NPS sizes — use the correct table for the material.

**Corrosion allowance** is service-dependent. [EPCLand's corrosion allowance guide](https://epcland.com/corrosion-allowance-piping/) summarises industry defaults: sweet hydrocarbon service (crude, light condensate) conventionally takes 3.0 mm; dry steam utility lines take 1.5 mm; austenitic stainless gets zero. For threaded small-bore connections, the mechanical allowance for thread depth (typically 1.8 mm for NPS 2") must be added to the corrosion component to form the total c term. Omitting it is a recurring error on piping ≤ NPS 1½" with threaded or socket-weld fittings.

**Piping class** wraps all these decisions into a project document — not an industry standard — covering the full service envelope: materials, schedules, break sizes between socket-weld and butt-weld connections, fittings, flanges, gaskets, bolting, and the NDE examination basis. A class label such as "A1A" is company-proprietary. As [Projectmaterials explains](https://blog.projectmaterials.com/epc-projects/engineering/pipe-class-vs-specification/), "A1A" in one EPC may specify Schedule 80 small-bore with socket-weld fittings; in another it may specify Schedule 40 with slip-on flanges. Always read the class document; never assume meaning from the label.

<Callout type="warning">
A piping class label (e.g., "A1A", "CS150A") is company-proprietary and carries no universal meaning. Before specifying any class on a drawing, verify you hold the correct revision of that company's piping class document — wrong revision can mean wrong schedule, wrong corrosion allowance, and wrong examination basis all at once.
</Callout>

## Two Errors That Can Sink a Design

**Wrong Y coefficient at elevated temperature.** For a high-temperature steam header in A335 P22 at 550°C (1022°F), B31.3 Table 304.1.1 specifies a Y value higher than the sub-482°C ferritic default of 0.4 — approximately 0.7 at that temperature (verify from a licensed code copy). Using Y = 0.4 produces a larger denominator shortfall and therefore a thicker calculated wall than necessary. The error is conservative but expensive: premium Cr-Mo alloy pipe is priced by schedule, and an over-specified wall inflates both material cost and weight. The inverse error — applying a high-temperature Y value at a low design temperature by misreading the table row — underdesigns the wall and is genuinely dangerous. [What Is Piping's Y factor explanation](https://whatispiping.com/importance-of-y-factor-asme-b31-3/) traces the directional effect for each material class.

**E = 1.0 for ERW pipe without NDE qualification.** ASTM A53 Grade B electric-resistance-welded pipe carries a default E = 0.85. If procurement substitutes ERW A53 for seamless A106 of the same schedule without updating the design calculation, the wall thickness sized with E = 1.0 is roughly 15–18% thinner than the code requires for the ERW product. Seamless and ERW of the same schedule are physically interchangeable — they share the same OD and fit the same flanges — but they are not code-interchangeable without recalculation. [Industrial Monitor Direct's EFW vs SMLS quality factor guide](https://industrialmonitordirect.com/blogs/knowledgebase/asme-b313-efw-vs-smls-pipe-pressure-classification-weld-factors) details the three correction paths: revert to seamless, specify 100% seam-weld radiography to qualify E = 1.0, or step up the schedule. The substitution note must return to the responsible piping engineer — it cannot be absorbed in procurement alone.

## Hands-On Exercise: Size and Classify an NPS 4" Condensate Line

**Given:** Hydrocarbon condensate (sweet), P = 400 psig (2.75 MPa), T = 150°C, ASTM A106 Grade B seamless, S ≈ 138 MPa at 150°C (verify from B31.3 Table A-1), E = 1.0, W = 1.0, Y = 0.4, corrosion allowance = 3.0 mm. NPS 4" OD = 114.3 mm. B36.10M schedule data: Sch 40 nominal WT = 6.02 mm; Sch 80 nominal WT = 8.56 mm.

1. Classify the fluid service. State exactly which Category D criterion the condensate line fails.
2. Calculate t using the Para. 304.1.2 equation. Show each substitution.
3. Calculate tm. Determine the required minimum nominal wall after applying the 12.5% mill tolerance.
4. Select the lightest acceptable schedule and confirm it passes the mill-tolerance check.
5. State the examination basis that applies to this fluid service classification.

**Success criteria:** Fluid service = Normal Fluid Service (condensate is flammable; fails the Category D non-flammable criterion regardless of pressure). t ≈ 1.1 mm; tm ≈ 4.1 mm; required nominal wall ≈ 4.7 mm. Schedule 40 (minimum guaranteed wall = 6.02 × 0.875 = 5.27 mm) clears the required 4.7 mm and is the correct selection. Examination basis = 5% random RT on butt welds plus a 1.5× hydrostatic test.

The next chapter covers how this sized pipe is represented geometrically in a stress model and what support configurations keep code stress ratios below 1.0. Continue with [[03-building-a-caesar-ii-stress-model.md]].
