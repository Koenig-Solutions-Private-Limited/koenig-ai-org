---
issue: KOEA-9352
course: piping-engineering-fundamentals-asme-b31
chapter: 1
title: "Reading P&IDs and Piping Drawings: Extracting Engineering Intent from Plant Documentation"
verdict: BLOCK
review_date: 2026-06-30
reviewer: QA Verifier (reassigned from Content Reviewer KOEA-9782)
---

# G0 REVIEW VERDICT — KOEA-9352

**Status:** ❌ **BLOCK** (do not advance to G1 assembly)

---

## BLOCKERS (2) — Must Fix Before Resubmission

### 1. Word Budget Exceeded by 54%

**Specification:** 800–1,200 words (body prose, excluding frontmatter and markdown tables)  
**Measured:** ~1,850 words  
**Gap:** +650 words over max  
**Severity:** Hard blocker — spec is non-negotiable  

**Revision guideline:**
- Consolidate explanatory passages in one major section (recommend: "Reading Instrument Tags" or "P&ID-to-Isometric Consistency")
- Avoid cutting any learning content from the four `owns[]` topics
- Preserve all quiz example explanations and hands-on exercise instructions
- Consider moving the advanced "Common pitfalls" or "Visual frameworks" content to a supplementary file

**Verification:** Recount prose only (exclude frontmatter, YAML, tables, code blocks, KnowledgeCheck components, Callout wrappers)

---

### 2. Source Unavailability

**Problematic source:**  
- URL: https://blog.ansi.org/ansi/ansi-isa-5-1-2024-instrumentation-symbols/
- Status: HTTP 403 Forbidden (verified 2026-06-30)
- Citation: sources array, line 14 of frontmatter

**Other sources verified live:**
- ✓ PIP PIC001: https://pip.org/disciplines/pid-and-process/ (200)
- ✓ Arveng Training: https://arvengtraining.com/en/pipeline-codification-in-pids/ (200)
- ✓ What Is Piping: https://whatispiping.com/piping-isometric-drawings/ (200)
- ✓ Piping Engineer Stress: https://www.pipingengineer.org/pipe-stress-analysis-procedure/ (200)
- ✓ Industrial Monitor Direct: https://industrialmonitordirect.com/blogs/knowledgebase/piping-stress-analysis-critical-lines-selection-criteria (200)
- ✓ Piping and Interface: https://pipingandinterface.com/battery-limit-isbl-osbl/ (200)
- ✓ Pathnovo EPC Rework: https://pathnovo.com/blog/reduce-epc-project-rework (200)

**Recommended replacement:**  
Use ISA direct (verified 200):  
- **New source:** https://www.isa.org/standards-and-publications/isa-standards/isa-standards-committees/isa5-1  
- **Alternative:** InstruNexus ISA 5.1 source from dossier (also listed in research file)  
- **Coverage:** Both cover ISA 5.1 symbol standards, matching the cited content

**Revision step:**
Replace line 14 in frontmatter sources array with ISA direct URL, or use dossier's InstruNexus entry

---

## PASSING CRITERIA MET ✓

All other G0 review criteria passed without issue:

✓ **Frontmatter complete & coherent**
- All required fields present: chapter_num, course_slug, title, status, duration_min, vendor_tag, learning_objectives, sources, owns[], defers_to, quiz_topics, word_budget, quiz

✓ **All owns[] are taught**
- "Interpreting P&ID symbols, line designations, instrument tags, and revision marks as design intent"  
  → Taught in: Decoding the Line Designation, Reading Instrument Tags, sections 92–122
  
- "Extracting existing pipe class references, fluid service labels, equipment nozzles, tie-ins, and battery limits from P&IDs and isometrics"  
  → Taught in: Battery Limits, Tie-Ins, and Nozzle Interfaces section, lines 141–148
  
- "Checking consistency between a P&ID revision and a matching piping isometric for one line"  
  → Taught in: P&ID-to-Isometric Consistency section, lines 123–140; hands-on exercise, lines 168–182
  
- "Marking missing documentation inputs that would block a pipe stress input sheet"  
  → Taught in: What Blocks a Stress-Analysis Input Sheet section, lines 149–165; hands-on exercise, lines 176–179

✓ **does_not_cover[] territory avoided**
- Chapter correctly defers pipe material selection (ch2), CAESAR II (ch3), B31J (ch4), AutoCAD Plant 3D (ch5)
- No overlap with deferred chapters

✓ **Quiz coverage complete — all 4 required topics**
- **Q1:** P&ID line-number and tag decoding  
  Topic: "In the line designation 4"-FG-03-0035-A1A1-HC, what does the field 'A1A1' encode?"  
  Correct answer: "The full piping specification covering material grade, pressure class, and fitting types"  
  ✓ Tests owns[] #1

- **Q2:** P&ID-to-isometric consistency checks  
  Topic: "A P&ID at revision IFC adds a spec break on a line whose isometric is still at revision IFD. What is the most likely consequence?"  
  Correct answer: "Field installation may use the wrong pipe class across the break, creating a material safety defect"  
  ✓ Tests owns[] #3

- **Q3:** Battery limits, tie-ins, and nozzle data  
  Topic: "What does a battery-limit (BL) annotation at the terminal end of a piping isometric indicate?"  
  Correct answer: "The boundary where the plant owner's engineering scope ends and an external system begins"  
  ✓ Tests owns[] #2

- **Q4:** Missing data that blocks stress-analysis inputs  
  Topic: "A stress engineer receives a piping isometric but no fluid density is available in the process documents. Which calculation is directly blocked?"  
  Correct answer: "Dead-weight calculation, because total pipe weight includes the mass of the contained fluid"  
  ✓ Tests owns[] #4

✓ **Source content accuracy verified**
- 7 of 8 live sources match cited content claims
- No proprietary ASME B31.3 or B16.5 standard text copying detected
- Dossier citations align with body content

✓ **Vendor tag present**
- ISA / PIP PIC001 ✓

---

## NEXT STEPS FOR AUTHOR

1. **Trim chapter to ≤1,200 words**
   - Recount after edits to confirm compliance
   - Submit with this verified count in a resubmission note

2. **Replace ANSI Blog source with accessible alternative**
   - Recommended: ISA direct URL (verified 200)
   - Update frontmatter sources array, line 14

3. **Resubmit with status=awaiting-g0**
   - No other frontmatter changes needed; all other fields pass
   - Include resubmission comment referencing blockers #1 and #2

4. **Post-revision re-check**
   - QA Verifier will re-verify word count and source URL liveness
   - If both pass, issue will be marked **g0-passed** and frontmatter will be advanced to `status: g0-passed`

---

## UNBLOCK GATE

**Do not advance this chapter to G1 assembly or downstream tasks until:**
1. Word budget ≤1,200 words (verified)
2. Source availability confirmed (HTTP 200 for all 8 sources)

**Issue status:** Keep as `in_progress` (with g0-blocked marker) until author resubmits; QA Verifier will re-check and flip to `g0-passed` or escalate if new blockers appear.

---

**Review contract source:** KOEA-9352 issue description, G0 review gate definition
