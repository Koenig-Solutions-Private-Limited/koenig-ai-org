---
chapter_num: 6
course_slug: piping-engineering-fundamentals-asme-b31
title: "Integrating a Complete Piping Package: From P&ID Mark-Up to Code-Compliant Stress Sign-Off"
status: awaiting-g0
duration_min: 14
vendor_tag: Hexagon CAESAR II v14
learning_objectives:
  - "Complete a piping input data sheet from a P&ID and process datasheet by reconciling operating conditions, fluid-service classification, pipe class, and wall-thickness adequacy"
  - "Build a multi-branch CAESAR II v14 model with B31J SIFs enabled, identify the governing load case, and read the code stress ratio"
  - "Evaluate thermal-expansion overstress remedies by comparing expansion loop addition against bellows joint use on space, cost, maintainability, and code criteria"
  - "Compile the final design-review package: stress report, annotated isometric, support list, and signed cover sheet"
sources:
  - url: "https://whatispiping.com/stress-check-list/"
    title: "Checklist for Piping Stress Analysis using Caesar II"
  - url: "https://whatispiping.com/documentation-of-a-stress-system/"
    title: "Pipe Stress Analysis Report Preparation for Issuing to the Client"
  - url: "https://epcland.com/asme-b31-3-thickness-calculation/"
    title: "ASME B31.3 Pipe Thickness Calculation: Formula, Examples & Schedule Selection"
  - url: "https://epcland.com/piping-thermal-expansion-design-guide/"
    title: "Piping Thermal Expansion Design Guide: Calculations, Loops & B31.3 Limits"
  - url: "https://simumech.com/expansion-joints-vs-expansion-loops/"
    title: "Bellows Expansion Joints vs Expansion Loops in Aboveground Piping"
  - url: "https://whatispiping.com/asme-b31j-b31j-essentials/"
    title: "ASME B31J & B31J Essentials: Why these are useful in Piping Stress Analysis"
  - url: "https://docs.hexagonppm.com/r/en-US/CAESAR-II-Users-Guide/Version-14/334785"
    title: "CAESAR II v14 User Guide — Introduction & What's New"
  - url: "https://whatispiping.com/engineering-deliverables/"
    title: "Engineering Deliverables for Chemical, Oil & Gas Projects"
owns:
  - "Completing a piping input data sheet from a supplied P&ID and process datasheet by combining operating conditions, fluid-service classification, pipe class, and wall thickness"
  - "Building a multi-branch CAESAR II v14 model that incorporates B31J SIFs and identifying the governing load case and code stress ratio"
  - "Resolving a thermal-expansion overstress by comparing loop addition against expansion-joint use on space, cost, maintainability, and code criteria"
  - "Compiling the final design-review package: stress report, annotated isometric, support list, and sign-off notes"
defers_to:
  - "P&ID symbols, line designations, and isometric reading → ch1"
  - "B31.3 wall-thickness formula derivation and fluid-service classification theory → ch2"
  - "CAESAR II node entry, restraint types, and load-case configuration basics → ch3"
  - "B31J SIF theory, in-plane/out-of-plane/torsional factor derivations → ch4"
  - "AutoCAD Plant 3D navigation, isometric extraction, and PCF export → ch5"
quiz_topics:
  - "Piping input data sheet completeness"
  - "Integrated CAESAR II model and B31J SIF application"
  - "Loop addition vs expansion-joint tradeoffs"
  - "Stress report, annotated isometric, and support-list package review"
notebooklm_source_focus:
  - "Public EPC design-package checklists for piping stress deliverables"
  - "Examples of piping input data sheets and stress report review workflows"
  - "Engineering guidance on expansion loops versus expansion joints"
  - "Quality-review checklists for stress reports, marked-up isometrics, and support lists"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "A stress engineer starts building a CAESAR II model before the process datasheet revision B is issued. Which data sheet field is most likely to carry an incorrect value?"
    options:
      - "Operating temperature and pressure, sourced exclusively from the process datasheet"
      - "Pipe class and nominal schedule, sourced from the pipe class specification"
      - "Corrosion allowance and examination basis, sourced from the pipe class document"
      - "Fluid service classification, determined from the P&ID and hazard assessment"
    correct_idx: 0
    explanation: "Operating temperature and pressure come from the process datasheet. If that document is still at a preliminary revision, those fields are unreliable. Pipe class, corrosion allowance, and fluid-service classification are typically determined from documents available before the process datasheet is finalized."
    section_anchor: completing-the-piping-input-data-sheet

  - question: "In CAESAR II v14, what is the primary consequence of leaving 'Apply B31J SIFs and Flexibilities' disabled when the project specification mandates B31J?"
    options:
      - "Torsional SIFs at branch connections default to 1.0, potentially hiding real overstresses at multi-branch tees"
      - "The Expansion load case is omitted from the run, causing the thermal stress report to be incomplete"
      - "CAESAR II automatically flags nodes with D/T > 100 as failed, even when they are within allowable limits"
      - "All flexibility factors are set to zero, causing the model to behave as if every fitting is rigid"
    correct_idx: 0
    explanation: "With B31J disabled, CAESAR II falls back to B31.3 Appendix D, which always assigns a torsional SIF of 1.0 at branch connections. B31J calculates a geometry-dependent value that can exceed 1.0, potentially revealing overstresses that Appendix D would miss."
    section_anchor: building-the-multi-branch-caesar-ii-v14-model

  - question: "A 6\" carbon-steel crude oil line with elevated H₂S content shows an expansion stress ratio of 1.42. The pipeway has 2 m of lateral clearance. Which remedy is correct, and why?"
    options:
      - "Expansion loop — H₂S service typically bans expansion joints because bellows flanges introduce additional leak paths in a hazardous service"
      - "Expansion joint — a 2 m clearance is insufficient for a loop on a 6\" line, making the joint the only viable option"
      - "Neither — expansion overstress requires adding support weight to reduce the Sustained load case stress, not adding flexibility"
      - "Expansion joint — it requires no extra structural steelwork and always costs less than a loop on a congested pipeway"
    correct_idx: 0
    explanation: "In H₂S service, project specifications routinely prohibit bellows joints because any leak path is unacceptable. Space (2 m) is also adequate for a 6\" loop. Option B is wrong — 2 m of clearance is sufficient. Option C confuses the governing load case: expansion overstress requires flexibility, not weight support."
    section_anchor: resolving-the-thermal-expansion-overstress

  - question: "Which condition must be satisfied before the stress-report approver adds their signature to release a package as Issued for Construction?"
    options:
      - "Nozzle loads at all connected equipment must be within the vendor's published allowable table before sign-off"
      - "All pipe material certificates must be physically appended to the report before the checker reviews it"
      - "The CAESAR II model must be rebuilt in the current software release because older version outputs are client-rejected"
      - "The process datasheet must reach its final revision with zero open comments before the performer begins analysis"
    correct_idx: 0
    explanation: "Nozzle load qualification against vendor allowables (e.g., API 610 for pumps) is a hard sign-off gate. Issuing a report without this check — or flagging it as 'assumed OK' — creates a hidden compliance gap that frequently surfaces during commissioning when equipment is connected and loaded."
    section_anchor: compiling-the-final-design-review-package
---

Every piping stress deliverable begins the same way: a P&ID mark-up, a stack of process datasheets, and a blank input form. This chapter walks one crude-service line — `6"-CS-1055-A1B-H1` on a refinery crude distillation revamp — through the full workflow. By the end you will have completed the data sheet, built and corrected the CAESAR II model, chosen and justified a thermal-expansion fix, and assembled the package for sign-off.

## Completing the Piping Input Data Sheet

The data sheet is a formal declaration that the stress model reproduces actual design-document intent. Three source documents must be reconciled before a single node is entered.

**From the P&ID**, decode the line number: 6" NPS, crude service (CS), unit 1055, pipe class A1B, insulation code H1 (hot-insulated). The fluid service is **Normal** — crude oil at these conditions does not meet the temperature or pressure thresholds for Category D, and it is not a lethal service requiring Category M treatment.

**From the process datasheet**: operating temperature = 305°C, operating pressure = 24 bar gauge, fluid density = 820 kg/m³.

**From the pipe class document (A1B)**: material = A106 Gr. B seamless, corrosion allowance = 3 mm, nominal schedule = Schedule 80 (wall = 10.97 mm for 6" NPS).

Verify wall adequacy using B31.3 §304.1.2: t = PD/2(SE + PY). With design pressure 28 bar, OD 168.3 mm, S ≈ 117 MPa at 320°C (illustrative — confirm from current B31.3 Table A-1), and Y = 0.4 for ferritic steel below 482°C, calculated t ≈ 2.0 mm. Adding 3 mm corrosion allowance gives 5.0 mm; dividing by 0.875 for the 12.5% mill under-tolerance gives a **required nominal wall of 5.7 mm**. Schedule 80 at 10.97 mm passes with large margin — the schedule driver here is corrosion allowance, not pressure alone.

Flag one open item before closing the sheet: the process datasheet does not confirm an upset temperature for the relief-valve scenario. Note it as a **missing-data query** and do not proceed to modeling with an assumed value. According to the [Checklist for Piping Stress Analysis — What Is Piping](https://whatispiping.com/stress-check-list/), assumed inputs that survive into the final run are the most common source of rework on EPC projects.

<KnowledgeCheck question="Which field on a piping input data sheet is sourced exclusively from the process datasheet?" options={["Operating temperature and pressure", "Corrosion allowance", "Nominal pipe schedule", "Fluid service classification"]} correctIdx={0} explanation="Operating temperature and pressure come from the process datasheet. Corrosion allowance and schedule come from the pipe class spec. Fluid service classification is determined from the P&ID and the project hazard assessment."/>

## Building the Multi-Branch CAESAR II v14 Model

Open CAESAR II v14 and navigate to **Configuration Editor → Allowable Stress → Apply B31J SIFs and Flexibilities: On** before placing the first node. If this toggle is left off, the program defaults to B31.3 Appendix D, which sets all torsional SIFs to exactly 1.0 — a non-conservative assumption at branch connections, as covered by the [ASME B31J Essentials — What Is Piping](https://whatispiping.com/asme-b31j-b31j-essentials/) reference in your dossier.

The 50-metre main run has one 2" bypass branch at the 20 m mark. Model the run from the E-101 (heat exchanger outlet) nozzle anchor to the C-101 (crude column inlet) nozzle anchor, with intermediate nodes at 6 m support intervals. At the reducing tee (6" × 2"), CAESAR II automatically applies B31J separate in-plane, out-of-plane, and torsional SIFs for the branch leg and both run legs — the torsional values are now geometry-calculated rather than defaulted to 1.0.

Define four load cases: (a) Sustained W + P1, (b) Operating W + P1 + T1, (c) Expansion L1 = OPE − SUS, (d) Occasional W + P1 + Wind.

With ΔT = 285°C (305°C − 20°C ambient) and α = 12.1 × 10⁻⁶ mm/m/°C for A106 Gr. B carbon steel, the 50 m run generates **172 mm of free thermal growth** (50 × 12.1×10⁻⁶ × 285 × 1000). The Expansion load case will govern. Running the analysis confirms this: expansion stress ratio at the E-101 nozzle node = **1.42** — a code violation requiring a design fix.

<KnowledgeCheck question="After running a CAESAR II stress analysis on this line, the stress summary shows a code stress ratio of 1.42 on the Expansion load case and 0.65 on the Sustained load case. What does this tell you about the fix strategy?" options={["The fix must add flexibility — a loop or joint — not additional support weight", "The fix must add support weight to reduce dead-load deflection", "Both load cases need independent fixes applied simultaneously", "A ratio below 1.5 on Expansion is acceptable under B31.3 for carbon steel"]} correctIdx={0} explanation="The Expansion load case governs, which means thermal flexibility is insufficient — the fix adds a loop or joint. Adding support weight addresses Sustained overstress, not thermal expansion. A ratio above 1.0 on any governed load case is a code violation regardless of the margin."/>

## Resolving the Thermal-Expansion Overstress

Two options compete to reduce the 1.42 ratio to below 1.0.

**Option A — Expansion loop**: A U-loop inserted at the 25 m midpoint splits the effective anchor span in half. Each side then has 86 mm of free growth, which the loop legs absorb elastically. A 6" line requires roughly 1.5–2 m of lateral clearance perpendicular to the pipeway. This run's rack confirms 2 m available. The loop contains no moving parts, has no finite fatigue life, and introduces zero additional leak paths.

**Option B — Bellows expansion joint**: An axial bellows at mid-run absorbs the full 172 mm within approximately 200 mm of added straight length. Near-zero lateral footprint and no extra structural steelwork make it attractive on a congested rack. However, this crude service carries elevated H₂S content. The project specification bans expansion joints in H₂S service: bellows flanges introduce leak paths that are unacceptable in a hazardous service stream.

Apply the decision framework from [Bellows Expansion Joints vs Expansion Loops — SimuMech](https://simumech.com/expansion-joints-vs-expansion-loops/) in order:
1. Is space available for the loop? → 2 m confirmed. Yes.
2. Does the service have a zero-leak-path constraint? → H₂S flags the project-spec ban. Yes.

**Decision: expansion loop** — driven by the project-spec constraint, not space alone.

<Callout type="warning">
If an expansion joint is used in any service, install a rigid anchor directly upstream of the bellows and close-clearance directional guides within one pipe diameter of each bellows end. Internal pressure on an unguided bellows produces lateral buckling force (pressure thrust) that causes squirm-and-fatigue failure. Most field bellows failures trace to missing or misplaced guides.
</Callout>

Re-run CAESAR II with the loop inserted. Expansion stress ratio at the E-101 nozzle: **0.78 — passes**.

The [Piping Thermal Expansion Design Guide — EPCLand](https://epcland.com/piping-thermal-expansion-design-guide/) ranks the design hierarchy: natural directional changes first, fabricated offsets second, U-loops third, and bellows joints only as a last resort. Follow this priority before reaching for a manufactured component.

## Compiling the Final Design-Review Package

A signed CAESAR II printout is not a deliverable. Per [Pipe Stress Analysis Report Preparation — What Is Piping](https://whatispiping.com/documentation-of-a-stress-system/), a complete EPC stress package requires:

- **Stress report**: input echo + stress summary with governing load case identified and stress ratios listed by node
- **Annotated stress isometric**: loop location marked, support numbers labeled, displacement callout at E-101 ("max 22 mm — confirm civil clearance"), nozzle load table for E-101 and C-101 with API 610 allowables checked off
- **Support list**: 10 standard rests, 2 loop supports (special fabrication), 1 spring hanger at the E-101 nozzle approach
- **Sign-off cover sheet**: performer signs (stress analyst), checker signs (senior engineer), approver signs (discipline lead) — report issued as Rev A for IFC (Issued for Construction)

If nozzle loads at any connected equipment exceed the vendor's published allowable table, the package cannot be signed off. This qualification must happen before the approver's signature, not flagged as a post-issue assumption.

## Hands-On Exercise

**Scenario**: A 4" A312 TP304 stainless-steel line, 30 m straight between two fixed equipment nozzles, operating at 200°C / 8 bar, ambient 20°C. α for 304 stainless = 16.9 × 10⁻⁶ mm/m/°C.

1. Calculate the free thermal growth of the 30 m run.
2. State which CAESAR II load case is most likely to govern.
3. Name two criteria from the loop-vs-joint decision framework that would steer you toward an expansion loop for this stainless service.
4. List the four minimum deliverables required before the stress-report approver can sign off.

**Success criteria**:
- Growth = 30 × 16.9×10⁻⁶ × 180 × 1000 = **91.3 mm**
- Governing load case = **Expansion**
- Loop criteria (any two): space available for lateral clearance; austenitic stainless in corrosive or high-purity service may prohibit a bellows joint due to crevice corrosion or leak-path risk; cycle count exceeds EJMA bellows fatigue life
- Deliverables: stress report, annotated stress isometric, support list, signed cover sheet

This is the capstone chapter of the course. You have now walked the complete end-to-end EPC workflow — from reading a P&ID through data-sheet completion, CAESAR II multi-branch modeling with B31J SIFs, overstress resolution, and design-review package compilation — at the level expected of a junior stress engineer on a live project.
