---
chapter_num: 3
course_slug: piping-engineering-fundamentals-asme-b31
title: "Building a Pipe Stress Model in CAESAR II v14: Geometry, Supports, and Load Cases"
status: g3-passed
duration_min: 15
vendor_tag: "CAESAR II v14 (Hexagon PPM)"
learning_objectives:
  - "Build a single-branch CAESAR II v14 piping model by entering node coordinates, pipe properties, temperature, pressure, and material from a supplied isometric"
  - "Select and apply anchors, guides, rests, and spring hangers, and explain the effect of each restraint type on the sustained stress ratio"
  - "Configure the three mandatory ASME B31.3 static load cases — Sustained, Operating, and Thermal Expansion — in the CAESAR II load-case editor"
  - "Read the CAESAR II stress summary to identify an overstressed node and reposition a support to achieve a code stress ratio below 1.0"
sources:
  - url: "https://docs.hexagonppm.com/r/en-US/CAESAR-II-Users-Guide/Version-14/334785"
    title: "CAESAR II v14 User Guide — Introduction"
  - url: "https://whatispiping.com/load-cases/"
    title: "Load Cases for Pipe Stress Analysis: Caesar II Load Cases — What Is Piping"
  - url: "https://whatispiping.com/spring-hanger-selection/"
    title: "Spring Hanger Selection and Design Guidelines in Caesar II — What Is Piping"
  - url: "https://jscengineers.com/pipe-support-design-anchors-guides-springs/"
    title: "Pipe Support Design: Anchors, Guides & Spring Hangers — JSC Engineers"
owns:
  - "Creating a CAESAR II v14 single-branch piping model from node coordinates, pipe properties, temperatures, pressure, and material inputs"
  - "Applying anchors, guides, rests, and spring hangers inside the stress model and checking their effect on sustained stress ratio"
  - "Configuring standard operating, sustained, and thermal-expansion load cases for static analysis"
  - "Reading CAESAR II output to diagnose an overstressed node and repositioning one support to bring the code stress ratio below 1.0"
defers_to:
  - "B31J SIF values for elbows, tees, and bends → ch4"
  - "AutoCAD Plant 3D support placement and BOM deliverables → ch5"
quiz_topics:
  - "CAESAR II v14 node, element, and restraint setup"
  - "Anchor, guide, rest, and spring hanger behavior"
  - "Operating, sustained, and expansion load-case definitions"
  - "Stress summary interpretation and support repositioning"
notebooklm_source_focus:
  - "Hexagon CAESAR II v14 release and training materials"
  - "Public CAESAR II static load case editor and output interpretation resources"
  - "Introductory pipe support modeling references for anchors, guides, rests, and spring hangers"
  - "Version note: preserve the approved v14 workflow while mentioning that newer CAESAR II releases exist"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "In CAESAR II v14, what is the primary reason stress engineers assign node numbers in increments of 10?"
    options:
      - "CAESAR II requires node numbers divisible by 10 to calculate friction coefficients correctly"
      - "Gaps in the numbering sequence let engineers insert intermediate nodes later without renumbering the chain"
      - "The stress summary output only reports results at nodes whose numbers are multiples of 10"
      - "The v14 geometry engine uses node number magnitude to sort coordinate data during input"
    correct_idx: 1
    explanation: "Spacing node numbers by 10 (or 5) is a workflow convention that reserves numbered gaps for future insertions — a rest, a flange, or instrumentation added mid-project — without triggering a renumber cascade downstream. CAESAR II has no rule that forces multiples of 10."
    section_anchor: from-isometric-to-model-node-and-element-entry
  - question: "A guide restraint is applied to a long hot horizontal run. Which statement correctly describes its effect on the pipe?"
    options:
      - "It prevents lateral displacement and rotation while allowing free axial thermal growth along the pipe run"
      - "It anchors the pipe fully by suppressing all six degrees of freedom at the attachment point"
      - "It provides a constant upward force that resists gravity loading regardless of vertical pipe movement"
      - "It blocks axial movement in both directions to protect the downstream equipment nozzle from thrust"
    correct_idx: 0
    explanation: "A guide suppresses the two lateral translational DOFs (and the rotational DOFs about those axes) while leaving the axial DOF free. The pipe can grow thermally along its own axis without generating axial reaction loads on the guide structure."
    section_anchor: support-types-and-restraint-behavior
  - question: "Which CAESAR II load case combination correctly computes the thermal-expansion stress range SE per ASME B31.3?"
    options:
      - "W + T1 + P1 applied as a single combined operating case without further subtraction"
      - "T1 entered alone as a standalone thermal load without subtracting the sustained baseline"
      - "The algebraic difference of the operating case minus the sustained case, L2 minus L1"
      - "P1 multiplied by the thermal expansion coefficient to capture combined pressure and temperature effects"
    correct_idx: 2
    explanation: "The expansion case isolates the thermal contribution by computing OPE − SUS = (W+T1+P1) − (W+P1) = T1 effect. Entering T1 alone skips the sustained baseline subtraction and understates SE, which is non-conservative."
    section_anchor: configuring-the-three-load-cases
  - question: "A CAESAR II stress summary shows a sustained (SUS) ratio of 1.18 at an elbow node. What is the most direct corrective action?"
    options:
      - "Switch the nearest anchor to a guide to release axial restraint and reduce reaction loads"
      - "Increase the design temperature input so CAESAR II uses a higher allowable stress for that material"
      - "Move an adjacent rest support closer to the overstressed node to reduce the unsupported span"
      - "Replace the variable spring at the mid-span with a constant-effort spring to lower load variability"
    correct_idx: 2
    explanation: "Sustained overstress at an elbow is almost always a bending-moment problem driven by a long unsupported span. Bending moment scales with the square of span length, so moving the adjacent rest closer is the highest-leverage geometric fix. Switching an anchor to a guide addresses a different failure mode (axial stress), and changing temperature inputs falsifies the analysis."
    section_anchor: reading-the-stress-summary-and-fixing-an-overstress
---

CAESAR II v14 holds roughly 70–80 percent of global EPC pipe-stress market share. Once you have the pipe properties assembled in the previous chapter, the model-building sequence is methodical: lay out node-element geometry, assign restraints, configure three load cases, run static analysis, and read the stress summary. This chapter walks through each step on a single-branch refinery crude line so the workflow is concrete before you attempt the full package.

## From Isometric to Model: Node and Element Entry

A CAESAR II model is a chain of elements. Each **element** runs between two numbered nodes and carries: outside diameter, wall thickness, material grade, corrosion allowance, insulation weight, operating temperature (T1), and internal pressure (P1). CAESAR II v14 ships with the ASME B31.3 2022-edition material library, so selecting ASTM A106 Gr. B from the dropdown automatically retrieves temperature-dependent allowable stress, elastic modulus, and thermal expansion coefficient — no manual table lookup required. Newer CAESAR II releases beyond v14 may update code-edition defaults; always verify which B31.3 edition is active in your installation's configuration file.

**Node numbering**: assign in increments of 10 (10, 20, 30 …). This is a workflow convention, not a software requirement: the gaps let you insert intermediate nodes for a later-added restraint or flange without renumbering every downstream element.

For the worked example: a 4-inch NPS, Schedule 40, A106 Gr. B crude line carries 200°C process fluid at 12 bar(g). The line runs 10 m east from a vessel nozzle (node 10) to a 90° elbow (node 20), then 15 m north to a pump suction nozzle (node 80). Enter elements 10–20 and 20–80 with T1 = 200°C, P1 = 12 bar(g), and 1.5 mm corrosion allowance. Flag the downstream element at node 20 as a long-radius bend (1.5D). CAESAR II v14 applies a flexibility correction to the elbow internally — SIF values at this fitting are covered in [[04-interpreting-b31j-sifs]].

<KnowledgeCheck question="In CAESAR II v14, what is the primary reason stress engineers assign node numbers in increments of 10?" options={["CAESAR II requires node numbers divisible by 10 to calculate friction coefficients correctly", "Gaps in the numbering sequence let engineers insert intermediate nodes later without renumbering the chain", "The stress summary output only reports results at nodes whose numbers are multiples of 10", "The v14 geometry engine uses node number magnitude to sort coordinate data during input"]} correctIdx={1} explanation="Spacing node numbers by 10 (or 5) is a workflow convention that reserves numbered gaps for future insertions — a rest, a flange, or instrumentation added mid-project — without triggering a renumber cascade downstream. CAESAR II has no rule that forces multiples of 10." />

## Support Types and Restraint Behavior

Every support in CAESAR II is a set of degree-of-freedom (DOF) constraints. Choosing the wrong type either blocks thermal growth that should remain free or leaves movement uncontrolled where buckling is possible.

| Type | CAESAR II entry | DOFs suppressed | DOFs free |
|---|---|---|---|
| Anchor | `ANC` | All 6 (TX, TY, TZ, RX, RY, RZ) | None |
| Guide | ±Y and ±Z (or ±X) | Lateral + rotational | Axial translation |
| Rest | `+Y` | Downward (−Y) | Upward, axial, lateral |
| Variable spring | Hanger design | −Y at operating load | Upward, axial, lateral |

**Anchors** belong at equipment nozzles and fixed structural boundaries. Because they suppress all six DOFs, they transmit maximum thermal reaction load to the connected nozzle and structure. Always verify anchor reaction forces against published equipment allowable nozzle loads after placement — for pumps, this means API 610.

**Guides** allow axial thermal growth while blocking lateral movement, making them the correct choice for long straight hot runs. A common error is placing an anchor where a guide belongs: the anchor prevents axial growth entirely and introduces high compressive stress in a run that was designed to grow. [Pipe Support Design: Anchors, Guides & Spring Hangers — JSC Engineers](https://jscengineers.com/pipe-support-design-anchors-guides-springs/)

**Rests (+Y)** provide deadweight support on horizontal runs. In the operating case, upward thermal growth can lift the pipe off the shoe — contact force drops to zero. Always inspect L2 output for zero-load rests; a rest that lifts off provides no weight support during hot operation and the adjacent spans pick up the load.

**Variable spring hangers** carry weight while permitting vertical thermal movement. Per [Spring Hanger Selection and Design Guidelines — What Is Piping](https://whatispiping.com/spring-hanger-selection/), load variability must stay ≤ 25 percent (many project specs tighten this to 20 percent). When vertical travel exceeds 50 mm, switch to a constant-effort spring; a variable spring coil-binds at high travel and generates uncontrolled impact loads.

<KnowledgeCheck question="A guide restraint is applied to a long hot horizontal run. Which statement correctly describes its effect on the pipe?" options={["It prevents lateral displacement and rotation while allowing free axial thermal growth along the pipe run", "It anchors the pipe fully by suppressing all six degrees of freedom at the attachment point", "It provides a constant upward force that resists gravity loading regardless of vertical pipe movement", "It blocks axial movement in both directions to protect the downstream equipment nozzle from thrust"]} correctIdx={0} explanation="A guide suppresses the two lateral translational DOFs (and the rotational DOFs about those axes) while leaving the axial DOF free. The pipe can grow thermally along its own axis without generating axial reaction loads on the guide structure." />

## Configuring the Three Load Cases

Every ASME B31.3 static analysis requires three load cases at minimum. [Load Cases for Pipe Stress Analysis — What Is Piping](https://whatispiping.com/load-cases/)

```
L1: W + P1          → SUS  → SL ≤ Sh   (primary stress check)
L2: W + T1 + P1     → OPE  → displacements, nozzle loads
L3: L2 − L1         → EXP  → SE ≤ SA   (secondary stress check)
```

**L1 — Sustained**: deadweight plus internal pressure. CAESAR II computes sustained longitudinal stress SL and checks it against Sh, the hot allowable stress from the B31.3 2022-edition material tables stored in v14. A ratio ≥ 1.0 is a primary stress failure — the pipe cannot carry its own weight and pressure load within code allowables.

**L2 — Operating**: adds thermal displacement to L1. ASME B31.3 does not directly code-check the operating case, but L2 output drives the nozzle-load report and feeds the subtraction that defines L3.

**L3 — Thermal Expansion**: computed as L2 minus L1, which algebraically isolates the thermal contribution T1. CAESAR II checks the resulting expansion stress range SE against SA = f(1.25Sc + 0.25Sh). The cyclic reduction factor f = 1.0 for most process plants (fewer than 7,000 full thermal cycles). In the ASME B31.3 2022 edition now active in v14, Sc and Sh are each capped at 20 ksi when computing SA.

<Callout type="warning">
Do not enter L3 as T1 alone. The correct definition is OPE − SUS (L2 − L1). Entering only the thermal load without subtracting the sustained baseline omits the weight contribution to the expansion case and understates SE — a non-conservative result that will fail a code review.
</Callout>

## Reading the Stress Summary and Fixing an Overstress

After running static analysis, open **Output → Stress Summary**. Each row shows: Node | Load Case | Stress Type | Calculated Stress (MPa) | Allowable (MPa) | **Ratio**. Any ratio ≥ 1.0 in the SUS or EXP column requires a design change before the model can be issued for construction.

In the crude-line scenario, the elbow at node 20 shows SUS ratio = 1.18: sustained stress is 18 percent over allowable. The cause is a long unsupported east leg generating high self-weight bending moment at the elbow. Bending moment at a point is proportional to the square of the unsupported span — halving the span roughly quarters the bending moment.

**Fix**: add a rest at node 15, the mid-point of the 10-m east leg, shortening each unsupported half-span to approximately 5 m. Rerun static analysis:

- SUS ratio at node 20: 0.86 → PASS
- EXP ratio at vessel anchor (node 10): 0.81 → PASS

No new restraint type was introduced — only the span geometry changed. The iteration loop — read ratio, trace to span or restraint configuration, adjust one variable, rerun, verify — is the practical core of CAESAR II stress engineering.

---

**Hands-On Exercise**

Using a CAESAR II v14 trial installation (or the [CAESAR II v14 User Guide](https://docs.hexagonppm.com/r/en-US/CAESAR-II-Users-Guide/Version-14/334785) worked examples if a seat license is unavailable), build the crude line from this chapter:

1. Enter elements 10–20 (10 m east) and 20–80 (15 m north): T1 = 200°C, P1 = 12 bar(g), 4" Sch 40, A106 Gr. B, 1.5 mm corrosion allowance, 50 mm mineral wool insulation.
2. Apply anchors at nodes 10 and 80; a guide at node 20 (suppress Y and Z, free X).
3. Configure L1 (SUS = W+P1), L2 (OPE = W+T1+P1), and L3 = L2−L1 (EXP).
4. Run static analysis and record the SUS stress ratio at node 20.
5. If the ratio exceeds 1.0, insert a rest at node 15 and rerun.

**Success criteria**: SUS and EXP ratios < 1.0 at all nodes; L2 output shows a non-zero contact force at the rest.

Next: [[04-interpreting-b31j-sifs]] covers how ASME B31J replaces the Appendix D SIF tables for the elbow and fitting connections you just modeled.
