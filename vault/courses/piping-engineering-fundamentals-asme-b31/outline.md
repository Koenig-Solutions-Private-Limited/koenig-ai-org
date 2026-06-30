---
course_slug: piping-engineering-fundamentals-asme-b31
title: "Piping Engineering for Process & Oil-Gas Projects: From P&IDs to Stress-Code Compliance"
status: outline-g3-passed
course_track: career
toc_locked: true
video_overview: true
koenig_recommendation: "Site Reliability Engineering (SRE) Practitioner(SM) (https://www.koenig-solutions.com/sre-practitioner-course-training)"
author: course-architect
level: Builder
vendor_tag: asme-b31
target_audience: "Candidates targeting Mechanical engineer, Project engineer, Maintenance engineer, piping engineer, and Team lead roles who need practical process and oil-gas piping engineering competence."
prerequisites:
  - "Basic mechanical engineering vocabulary: pressure, temperature, stress, strain, and material grade"
  - "Familiarity with process plant equipment such as pumps, vessels, valves, and heat exchangers"
  - "Ability to read simple 2D engineering drawings and tables"
  - "Comfort using Windows-based engineering software or CAD tools"
learning_outcomes:
  - "Extract piping design intent from P&IDs, isometrics, line designations, and revision changes"
  - "Select pipe material, schedule, corrosion allowance, and fluid-service basis using ASME B31.3 inputs"
  - "Build and troubleshoot a CAESAR II v14 static stress model with realistic supports and load cases"
  - "Interpret ASME B31J SIF effects for tees, bends, and trunnions and choose an appropriate design response"
  - "Review AutoCAD Plant 3D layout deliverables, support locations, isometrics, BOMs, and PCF transfer into CAESAR II"
  - "Assemble a complete piping design-review package from P&ID mark-up to stress-code sign-off"
total_duration_min: 80
chapter_count: 6
sources: []
---

# Piping Engineering for Process & Oil-Gas Projects: From P&IDs to Stress-Code Compliance

## Chapter 1: Reading P&IDs and Piping Drawings: Extracting Engineering Intent from Plant Documentation

- **Duration**: 12 min
- **Learning objectives**:
  1. Identify line designation, pipe class reference, fluid service label, and instrument tags from a process plant P&ID.
  2. Extract nozzle data, tie-in points, scope breaks, and battery limits from a supplied isometric.
  3. Compare a P&ID revision against a matching isometric for one pipe line and flag inconsistencies.
  4. Mark missing information that would block a stress-analysis input sheet.
- **Key concepts**: P&ID symbols, line numbering, instrument tags, pipe class references, tie-ins, nozzles, battery limits, isometric revision checks, stress-input readiness.
- **Hands-on exercise**: Annotate a supplied P&ID and isometric for one process line, then produce a missing-data list for stress-analysis handoff.

## Chapter 2: Selecting Pipe Materials, Schedules, and Piping-Class Specifications to ASME B31.3 (2022/2024 Edition)

- **Duration**: 14 min
- **Learning objectives**:
  1. Calculate minimum required wall thickness from NPS, design pressure, temperature, material, quality factor, Y coefficient, and corrosion allowance inputs.
  2. Classify a supplied service as Normal, Category D, Category M, or High-Pressure.
  3. Select pipe schedule, material grade, piping class, corrosion allowance, and examination basis for two realistic process lines.
  4. Diagnose and correct common sizing mistakes involving elevated-temperature Y coefficient and quality factor E.
- **Key concepts**: ASME B31.3 design pressure and temperature, wall-thickness inputs, pipe schedule, corrosion allowance, material grade, fluid-service classification, examination requirements, piping class.
- **Hands-on exercise**: Complete a pipe selection worksheet for a carbon-steel hydrocarbon line and a high-temperature steam line, including schedule choice and error correction.

## Chapter 3: Building a Pipe Stress Model in CAESAR II v14: Geometry, Supports, and Load Cases

- **Duration**: 15 min
- **Learning objectives**:
  1. Build a CAESAR II v14 single-branch piping model from node coordinates, pipe properties, operating temperature, and pressure inputs.
  2. Apply anchors, guides, rests, and spring hangers and explain how each restraint changes the model behavior.
  3. Configure operating, sustained, and thermal-expansion load cases for a static analysis run.
  4. Read the stress summary, locate an overstressed node, and reposition one support to reduce the code stress ratio below 1.0.
- **Key concepts**: Nodes, elements, restraints, anchors, guides, spring hangers, sustained stress, expansion stress, operating load case, stress ratio, output report triage.
- **Hands-on exercise**: Build and run a simple thermal-expansion model in CAESAR II v14, then adjust one support location and document the before/after stress ratio.

## Chapter 4: Interpreting Stress-Intensification Factors (SIFs) Under ASME B31J: Tees, Bends, and Trunnions

- **Duration**: 12 min
- **Learning objectives**:
  1. Explain why the ASME B31.3 Appendix D workflow changed and when ASME B31J governs SIF handling.
  2. Interpret in-plane and out-plane SIF behavior for welding tees, bends, and trunnion-style attachments.
  3. Configure B31J SIF options in CAESAR II v14 and verify that updated factors are being applied.
  4. Decide whether a SIF-driven overstress calls for a layout loop, heavier fitting, support change, or other design response.
- **Key concepts**: ASME B31J, SIF, flexibility factor, Appendix D transition, welding tee, bend, trunnion, in-plane stress, out-plane stress, fitting-driven overstress.
- **Hands-on exercise**: Compare a tee/trunnion stress-analysis report before and after B31J SIF application, then recommend a design response for the governing overstress.

## Chapter 5: Pipe Support Design and Layout Review Using AutoCAD Plant 3D

- **Duration**: 13 min
- **Learning objectives**:
  1. Navigate an AutoCAD Plant 3D project, apply the correct piping specification, and check routed pipework for clashes.
  2. Place and annotate rest supports, guides, and fixed anchors using a supplied support-spacing table.
  3. Extract a fully dimensioned isometric drawing and verify bill-of-materials quantities against the design intent.
  4. Export a PCF file and import it into CAESAR II v14 to confirm geometry transfer.
- **Key concepts**: AutoCAD Plant 3D project, piping specification, clash detection, rest support, guide, fixed anchor, support spacing, isometric extraction, BOM verification, PCF export.
- **Hands-on exercise**: Review a small Plant 3D layout, add support annotations, extract an isometric and BOM, then confirm PCF geometry import into CAESAR II.

## Chapter 6: Integrating a Complete Piping Package: From P&ID Mark-Up to Code-Compliant Stress Sign-Off

- **Duration**: 14 min
- **Learning objectives**:
  1. Complete a piping input data sheet from a supplied P&ID and process datasheet.
  2. Build a multi-branch CAESAR II v14 model that incorporates selected pipe class inputs and B31J SIFs.
  3. Identify the governing load case and code stress ratio from the stress summary.
  4. Resolve a thermal-expansion overstress by comparing loop addition against expansion-joint use on space, cost, maintainability, and code criteria.
  5. Compile the stress report, annotated isometric, support list, and sign-off notes into a design-review package.
- **Key concepts**: Piping input data sheet, process datasheet, multi-branch model, B31J SIF integration, governing load case, expansion loop, expansion joint, stress report, support list, design sign-off.
- **Hands-on exercise**: Produce a complete mini design package for one oil-and-gas process line, including input sheet, stress-analysis summary, selected overstress fix, annotated isometric, and support list.

## Capstone

Learners complete a realistic piping engineering closeout: receive a P&ID, isometric, process datasheet, support-spacing table, and preliminary layout; extract the required inputs; select the pipe class and schedule; build or review the CAESAR II v14 model with B31J SIFs; resolve the governing overstress; and submit a design-review package.

Deliverables:

- Marked-up P&ID and isometric with tie-ins, battery limits, and missing-data notes.
- Piping input data sheet with service classification, wall-thickness basis, material, schedule, and corrosion allowance.
- CAESAR II stress-summary excerpt with governing load case, critical node, stress ratio, and support/design response.
- Plant 3D-derived isometric, BOM check, support list, and PCF transfer note.
- One-page engineer-of-record sign-off memo explaining the final code-compliance argument and remaining review assumptions.
