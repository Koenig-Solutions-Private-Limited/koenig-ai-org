---
chapter_num: 4
course_slug: piping-engineering-fundamentals-asme-b31
title: "Interpreting Stress-Intensification Factors (SIFs) Under ASME B31J: Tees, Bends, and Trunnions"
status: awaiting-g0
duration_min: 12
vendor_tag: "ASME B31J · CAESAR II v14"
learning_objectives:
  - "Explain why ASME B31.3-2020 deleted Appendix D and what ASME B31J replaced it with"
  - "Calculate and compare in-plane and out-of-plane SIFs for a bend using the flexibility parameter h"
  - "Configure B31J SIF and k-factor settings in CAESAR II v14 for tee and trunnion elements"
  - "Select an appropriate design response when B31J SIFs push a code stress ratio above 1.0"
sources:
  - url: "https://www.asme.org/codes-standards/find-codes-standards/b31j-stress-intensification-factors-flexibility-factors-determination-metallic-piping-components"
    title: "ASME B31J – Official Standard Page (2023 edition)"
  - url: "https://stressandintegrity.com/b31-3-2016-stress-issue/"
    title: "B31.3 branch stress own-goal – Stress and Integrity"
  - url: "https://simumech.com/stress-intensification-factors-sifs-in-pipe-stress-analysis/"
    title: "Stress Intensification Factors (SIFs) in Pipe Stress Analysis – SimuMech"
  - url: "https://whatispiping.com/bend-sif/"
    title: "Piping Elbow or Bend SIF (Stress Intensification Factor) – What Is Piping"
  - url: "https://cadeengineering.com/study-case/stress-intensity-factor-sif-for-special-geometries-in-piping-stress-analyisis/"
    title: "Stress Intensity Factor (SIF) For Special Geometries In Piping Stress Analysis – CADE Engineering"
  - url: "https://docs.hexagonppm.com/r/en-US/CAESAR-II-Users-Guide/Version-14/1467330"
    title: "B31J Methods – CAESAR II Users Guide Version 14 – Hexagon"
  - url: "https://epcland.com/pipe-expansion-loops/"
    title: "How to Design Pipe Expansion Loops for Piping Systems – EPCLand"
owns:
  - "Explaining the B31.3 Appendix D deletion context and the shift to ASME B31J for SIF and flexibility-factor determination"
  - "Calculating and interpreting in-plane and out-plane SIF behavior for welding tees, bends, and trunnion-style attachments at a conceptual worked-example level"
  - "Configuring B31J SIF options in CAESAR II v14 for a tee and trunnion model"
  - "Deciding whether higher B31J-derived SIFs require a design response such as a loop, heavier fitting, or support/layout change"
defers_to:
  - "Pipe schedule and wall-thickness selection -> ch2"
  - "CAESAR II node entry, restraints, and load-case setup -> ch3"
  - "Support drawings and BOMs in AutoCAD Plant 3D -> ch5"
  - "Full package integration from P&ID to sign-off -> ch6"
quiz_topics:
  - "Appendix D deletion and B31J scope"
  - "In-plane vs out-plane SIF interpretation"
  - "B31J setup in CAESAR II v14"
  - "Design responses to SIF-driven overstress"
notebooklm_source_focus:
  - "Official ASME B31J scope and table-of-contents material"
  - "Public technical papers or vendor notes on B31J SIF and flexibility-factor changes"
  - "Hexagon CAESAR II B31J option documentation and release notes"
  - "Worked examples from reputable engineering sources that avoid copying proprietary ASME tables"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "ASME B31.3-2020 deleted Appendix D, which previously governed SIF and flexibility-factor calculation. What does B31.3-2020 mandate in its place?"
    options:
      - "Engineers must derive SIFs by FEA for every component, with no tabulated alternative permitted"
      - "ASME B31J is now the required standard for all SIF and flexibility-factor determination"
      - "Appendix D values remain in force but are now informative rather than mandatory"
      - "The code reverts to Markl's original 1952 fatigue-test formulas for all piping fittings"
    correct_idx: 1
    explanation: "B31.3-2020 deleted Appendix D entirely and redirected all SIF and k-factor determination to the standalone ASME B31J standard, which provides geometry-specific tables and a formal FEA virtual-test method."
    section_anchor: "the-end-of-appendix-d"
  - question: "A 6-inch long-radius elbow has flexibility parameter h approximately 0.25. Which statement correctly describes the relationship between h and in-plane SIF?"
    options:
      - "A higher h always produces a higher in-plane SIF because the bend radius increases"
      - "A lower h produces a higher in-plane SIF, meaning thin-wall or tight-radius bends are more fatigue-susceptible"
      - "The in-plane SIF equals the h parameter directly, so SIF equals 0.25 for this elbow"
      - "The in-plane and out-of-plane SIFs are always identical for any given value of h"
    correct_idx: 1
    explanation: "i_i = 0.9/h^(2/3). As h decreases from a thin wall or small bend radius, SIF increases. At h approximately 0.25 the in-plane SIF is about 2.27, well above the straight-pipe baseline of 1.0."
    section_anchor: "in-plane-vs-out-of-plane-reading-your-bend-numbers"
  - question: "In CAESAR II v14, what is the consequence of enabling Apply B31J SIFs and Flexibilities without also enabling Enforce B31J SIFs Only?"
    options:
      - "CAESAR II will refuse to execute analysis until both B31J switches are enabled together"
      - "CAESAR II may silently fall back to non-B31J SIFs for unlisted components, producing a non-compliant hybrid result"
      - "All tee k-factors revert to 1.0, removing the B31J flexibility contribution from the analysis"
      - "B31J flexibility factors apply globally but SIFs are doubled for all components as a conservative measure"
    correct_idx: 1
    explanation: "Without Enforce B31J SIFs Only, CAESAR II can revert to legacy Appendix D SIFs for any component not explicitly listed in B31J tables, yielding a mixed analysis that may not satisfy full B31.3-2020 code compliance."
    section_anchor: "configuring-b31j-in-caesar-ii-v14"
  - question: "After enabling B31J in an existing model, a welding tee shows a thermal-expansion code stress ratio of 1.21, up from 0.84 under Appendix D. Which design response most directly addresses the cause?"
    options:
      - "Add a fixed anchor at the tee to prevent thermal displacement at the fitting"
      - "Increase the pipe wall schedule at the tee node to eliminate the k-factor contribution"
      - "Add a 3D expansion loop upstream to reduce the thermal moment magnitude at the tee"
      - "Switch the governing code from ASME B31.3 to ASME B31.1 to apply a higher allowable stress"
    correct_idx: 2
    explanation: "An expansion-case overstress is driven by excess thermal moment. Adding a loop increases system flexibility and reduces the moment reaching the tee. Anchoring the tee would increase loads; switching codes is not a valid design response."
    section_anchor: "design-responses-when-sifs-drive-overstress"
---

## The End of Appendix D

For nearly five decades, engineers derived stress intensification factors (SIFs) and flexibility factors from ASME B31.3 Appendix D. The B31.3-2020 edition deleted that appendix entirely, redirecting all SIF and k-factor determination to the standalone [ASME B31J standard](https://www.asme.org/codes-standards/find-codes-standards/b31j-stress-intensification-factors-flexibility-factors-determination-metallic-piping-components). B31J-2023, issued February 7, 2024, is the current edition and is now on stabilized maintenance.

Three documented flaws drove the deletion. Appendix D's test data came from 4-inch Schedule 40 specimens and extrapolated without diameter or thickness terms — non-conservative for large-bore pipe. Its tee equations applied the same SIF to both run and branch, underpredicting branches in reducing configurations. Most critically, a formulation flaw in B31.3-2016 caused sustained bending stress at branches to compute at only about [69% of actual](https://stressandintegrity.com/b31-3-2016-stress-issue/) — a 30% underestimate that B31J corrects by eliminating the effective section modulus term.

## What B31J Changes

A stress intensification factor is a dimensionless ratio: the actual bending stress at a fitting divided by the nominal stress in a girth-butt-welded straight pipe under the same applied moment. Straight pipe is the baseline at SIF = 1.0; every fitting carries a SIF of at least 1.0. Higher SIF means greater fatigue susceptibility under cyclic thermal loading. [SimuMech's SIF reference](https://simumech.com/stress-intensification-factors-sifs-in-pipe-stress-analysis/) covers the underlying fatigue model in depth.

B31J makes three fundamental changes relative to Appendix D. First, torsional SIF (i_t) is now geometry-derived; Appendix D hard-coded it at 1.0 for all components, a known non-conservatism. Second, the run and branch of a welding tee each receive independent directional SIFs, where Appendix D used the same equation for both. Third, tee flexibility factors (k-factors) are now geometry-specific — [typically 2 to 8 times higher than Appendix D's rigid k = 1.0](https://www.asme.org/codes-standards/find-codes-standards/b31j-stress-intensification-factors-flexibility-factors-determination-metallic-piping-components), with 6 independent k-factor directions per tee versus 2 under Appendix D. Those higher k-factors model the tee as a local rotational spring: switching to B31J redistributes moments system-wide, altering stress ratios at the tee and reaction loads at every connected anchor and nozzle.

<KnowledgeCheck question="Under ASME B31J, how is the torsional SIF (i_t) determined for a welding tee, compared to B31.3 Appendix D?" options={["B31J keeps i_t = 1.0, the same as Appendix D, because torsion does not govern fatigue at tees", "B31J provides a geometry-derived i_t greater than 1.0, correcting the Appendix D assumption that i_t = 1.0 for all components", "B31J eliminates the torsional SIF term and folds torsion into the out-of-plane equation", "Appendix D already provided geometry-specific torsional SIF values; B31J only revised the in-plane term"]} correctIdx={1} explanation="Appendix D hard-coded torsional SIF at 1.0 for every fitting — a known non-conservatism. B31J replaces that with geometry-derived i_t values greater than 1.0 for most component types." />

## In-Plane vs Out-of-Plane: Reading Your Bend Numbers

For bends and elbows, both SIF directions depend on the characteristic flexibility parameter:

h = T * R1 / r2^2

where T is nominal wall thickness, R1 is the centerline bend radius, and r2 is the mean pipe radius. Higher h — from a thicker wall or larger bend radius — pushes SIF lower. The [governing formulas for bends](https://whatispiping.com/bend-sif/) are:

- In-plane (elbow opening or closing): i_i = 0.9 / h^(2/3)
- Out-of-plane (elbow rotating out of its plane): i_o = 0.75 / h^(2/3)

**Worked example — 6" NPS long-radius elbow, Sch 40:** OD = 6.625 in, t = 0.280 in, R1 = 9 in, r2 = 3.173 in.

h = 0.280 x 9 / 3.173^2 = 0.250 → i_i = 2.27, i_o = 1.89

Upgrading to Sch 80 (t = 0.432 in): h = 0.386 → i_i = 1.69, i_o = 1.41 — a 26% reduction in in-plane SIF with no routing change.

In-plane SIF always exceeds out-of-plane for the same elbow because in-plane bending concentrates stress most severely at the intrados and extrados. That 26% drop from a schedule upgrade is the mechanical basis for "heavier schedule" as a design lever — procurement change only, no layout revision.

**Trunnions** are not covered by B31J Table 1-1. The code-sanctioned path is a shell-element FEA virtual specimen per B31J Appendix A; enter the resulting values in CAESAR II v14's User SIFs Dialog, which accepts independent in-plane, out-of-plane, torsional, axial, and pressure SIF inputs. If FEA is unavailable, treating the trunnion as a reinforced fabricated branch and flagging the assumption in the stress report is the conservative fallback — see [CADE Engineering's case study](https://cadeengineering.com/study-case/stress-intensity-factor-sif-for-special-geometries-in-piping-stress-analyisis/) for the FEA workflow.

## Configuring B31J in CAESAR II v14

Two binary switches in **Utilities → Configuration Editor → SIFs and Stresses → Advanced Settings** control B31J behavior:

1. **"Apply B31J SIFs and Flexibilities"** — replaces Appendix D SIF and k-factor sources with B31J geometry-specific tables.
2. **"Enforce B31J SIFs Only"** — prevents fallback to legacy methods for any component not explicitly listed in B31J's tables.

Both must be active for a fully code-compliant B31.3-2020 analysis. Enabling only the first switch can produce a hybrid result that fails project code requirements, because CAESAR II may silently revert to Appendix D values for unlisted components. The [CAESAR II v14 B31J Methods documentation](https://docs.hexagonppm.com/r/en-US/CAESAR-II-Users-Guide/Version-14/1467330) describes the exact fallback logic.

A third option applies to tee elements: **"Verified Welding and Contour Tees per B16.9."** Activate this when the fitting meets the geometric minimums — crotch radius rx of at least (1/8)*d_o and crotch thickness Tc of at least 1.5T. Qualifying fittings receive a lower B31J SIF, reflecting their improved stress distribution at the crotch.

<Callout type="warning">Enabling B31J changes tee k-factors by 2–8x relative to Appendix D's rigid-node assumption. That redistributes moments system-wide. After enabling B31J, recheck all nozzle loads and support reactions — not only the node that triggered the re-run.</Callout>

<KnowledgeCheck question="In CAESAR II v14, what is the consequence of enabling Apply B31J SIFs and Flexibilities without also enabling Enforce B31J SIFs Only?" options={["CAESAR II will refuse to execute analysis until both B31J switches are active together", "CAESAR II may silently fall back to non-B31J SIFs for unlisted components, yielding a hybrid non-compliant result", "All tee k-factors revert to 1.0, removing B31J flexibility gains from the analysis", "B31J flexibility factors apply globally but SIFs are doubled for every component as a conservative measure"]} correctIdx={1} explanation="Without Enforce B31J SIFs Only, CAESAR II can revert to legacy Appendix D values for unlisted components, producing a mixed-method analysis that may not satisfy full B31.3-2020 code compliance when B31J-only is the project requirement." />

## Design Responses When SIFs Drive Overstress

If enabling B31J pushes a code stress ratio above 1.0, first confirm which load case governs — thermal expansion or sustained (weight + pressure) — because the remedies differ.

**Expansion-case overstress** means the thermal moment is too large for the local SIF. Three levers address it:

- **Add a 3D expansion loop** upstream of the fitting. In a published CAESAR II case study, a 15-ft symmetric loop reduced expansion stress by 72% and nozzle loads by 75%. ([EPCLand expansion loop guide](https://epcland.com/pipe-expansion-loops/))
- **Upgrade to long-radius bends**, which increase R1, raise h, and directly lower both i_i and i_o at every elbow.
- **Specify a contour or integrally reinforced tee** (Sweepolet class or equivalent). Fittings meeting B31J's crotch-geometry thresholds qualify for the "Verified Welding and Contour Tees" option and carry a lower tabular SIF.

**Sustained-case overstress** means the weight or pressure moment at the fitting exceeds what the B31J SIF allows. The fix is moment reduction via support repositioning — shortening the unsupported span to reduce bending at the tee. That workflow is covered in [[05-pipe-support-design-and-layout-review]].

**FEA re-evaluation** is warranted for non-standard geometries or when D/t approaches 100. Above that limit B31J tables are invalid and a virtual specimen FEA per B31J Appendix A is mandatory; above D/t = 50, tabulated values may already be under-conservative due to shell buckling.


---

**Hands-on exercise**

In your CAESAR II v14 training model from chapter 3, complete the following:

1. Open **Utilities → Configuration Editor → SIFs and Stresses → Advanced Settings** and set both B31J toggles to True. Re-run static analysis.
2. Compare the maximum expansion stress ratio to your Appendix D result from chapter 3. Record which node changed most and by how much.
3. On the tee element, check whether the fitting qualifies for "Verified Welding and Contour Tees per B16.9." Toggle the option and note the change in SIF and stress ratio.
4. Record reaction forces at two anchor or nozzle nodes before and after the B31J switch. Note any change in magnitude or direction.

**Success criteria:** Your B31J run shows a stress ratio differing from the Appendix D result by more than 5% at at least one node, and you can identify the SIF parameter (h, i_i, i_o, or k-factor) responsible and explain why.

Chapter 5 moves the corrected model into the plant layout environment: [[05-pipe-support-design-and-layout-review]] covers placing supports in AutoCAD Plant 3D and exporting geometry to CAESAR II.
