---
date: 2026-07-08
author: content-author
ticket: KOEA-9621
vendor_tag: sap
content_type: explainer
learning_objectives:
  - Trace the SAP PM maintenance workflow from notification creation to work order to confirmation and closure
  - Answer common SAP PM interview questions on plant maintenance master data, order types, and integration
  - Identify the key SAP PM transaction codes interviewers expect candidates to know
whats_new:
  - Sequence diagram of the SAP PM maintenance workflow from notification to work order to confirmation/closure
status: awaiting-g0
reading_time_min: 7
seo_description: "SAP PM interview questions and answers: maintenance workflow sequence diagram, master data, order types, transaction codes, and functional concepts for plant maintenance consultant roles."
sources:
  - "https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/5f2f8b1f44a64d7b8c699ac3f000cdb5/b07dea20c61447588080e24af24e9dc5.html"
  - "https://learning.sap.com/learning-journeys/implement-sap-s-4hana-plant-maintenance"
  - "https://help.sap.com/docs/SAP_ERP/03b5af6c2e124b25a2e2b8e4b33f9c09/c3e5c45c2e4a4df0862fb4de8e3a3e6e.html"
references:
  - n: 1
    title: "SAP Help — Plant Maintenance in S/4HANA"
    url: "https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/5f2f8b1f44a64d7b8c699ac3f000cdb5/b07dea20c61447588080e24af24e9dc5.html"
    retrieved: 2026-07-08
  - n: 2
    title: "SAP Learning — S/4HANA Plant Maintenance Journey"
    url: "https://learning.sap.com/learning-journeys/implement-sap-s-4hana-plant-maintenance"
    retrieved: 2026-07-08
  - n: 3
    title: "SAP Help — PM Maintenance Orders"
    url: "https://help.sap.com/docs/SAP_ERP/03b5af6c2e124b25a2e2b8e4b33f9c09/c3e5c45c2e4a4df0862fb4de8e3a3e6e.html"
    retrieved: 2026-07-08
---

# SAP PM Interview Questions and Answers

SAP Plant Maintenance (PM) is the module that tracks and manages physical assets — machinery, equipment, functional locations — and the maintenance work orders that keep them running. PM consultants are expected to understand both the business process (from notification to completion) and the SAP configuration that implements it.

## The SAP PM Maintenance Workflow

Before answering individual questions, tracing the end-to-end workflow anchors the concepts. Every SAP PM implementation follows this sequence.

```mermaid
sequenceDiagram
    title SAP PM Maintenance Workflow: Notification to Closure
    actor Tech as Technician / Operator
    participant IW24 as IW24/IW21<br/>Notification
    participant Planner as Maintenance Planner
    participant IW31 as IW31/IW32<br/>Work Order
    participant Shop as Shop Floor / Execution
    participant IW41 as IW41<br/>Confirmation
    participant IW65 as IW65<br/>Order Closure

    Tech->>IW24: Create maintenance notification\n(malfunction report or damage report)
    IW24-->>Planner: Notification triggers planner review
    Planner->>IW31: Convert notification to work order\nor create order directly
    IW31->>IW31: Assign operations, materials,\ncost centre, work centre
    IW31-->>Shop: Release work order (TECO/REL status)
    Shop->>IW41: Execute work, post time confirmation\n(actual hours per operation)
    IW41-->>IW31: Confirmation updates order actual costs
    IW31->>IW65: Technically complete order (TECO)\nor close (CLSD) after settlement
    IW65-->>Tech: Feedback: order closed, asset updated
```

*Figure 1 — SAP PM maintenance workflow: 8 steps from technician notification to order closure. Notifications (IW24/IW21) feed planners; work orders (IW31/IW32) drive execution and cost capture; confirmations (IW41) close the loop; TECO/CLSD status triggers settlement to cost centre or asset.*

The diagram shows the standard corrective maintenance path. Preventive maintenance follows a similar order cycle but is triggered by a maintenance plan (IP10) rather than a technician notification.

## Master Data Questions

### What are the key master data objects in SAP PM?

| Object | Transaction | Purpose |
|---|---|---|
| Functional Location | IL01 | Logical position in plant hierarchy (building, floor, machine area) |
| Equipment | IE01 | Individual physical asset (pump, motor, conveyor) |
| Measuring Point | IK01 | Point on equipment where readings are taken (temperature, pressure) |
| Work Centre | IR01 | Team or resource that performs maintenance (mechanical team, electrical team) |
| Maintenance Plan | IP01 | Schedule for preventive maintenance tasks |
| Task List | IA01/IA05 | Standard operations for recurring maintenance types |

### What is the difference between a Functional Location and Equipment?

A **Functional Location** is a place in the plant — a position in the physical or logical hierarchy. It is permanent and location-specific: "Pump Station 2, Floor 3."

**Equipment** is an individual asset that can be installed at a Functional Location. Equipment can be moved: you can deinstall a pump from one location and install it at another, creating a full history of where the equipment has been.

When equipment is installed at a functional location, maintenance notifications and orders can be created against either object, but costs and history accumulate on the equipment master.

### What is a Measuring Document and when is it created?

A Measuring Document (transaction IK11) records a reading taken at a Measuring Point — such as a temperature reading from a sensor or an odometer reading from a vehicle. SAP PM uses measuring documents to:
- Track counter readings (kilometres, operating hours, cycles)
- Trigger maintenance plans based on counter thresholds rather than calendar dates
- Provide a history of equipment operating conditions

## Work Order Questions

### What is the difference between PM01, PM02, PM03, and PM04 order types?

SAP PM ships with default order types that can be configured:

| Order type | Name | Typical use |
|---|---|---|
| PM01 | Corrective maintenance | Reactive repair after a breakdown or malfunction |
| PM02 | Preventive maintenance | Scheduled inspection or service |
| PM03 | Refurbishment | Overhaul of a repairable spare for return to stock |
| PM04 | Investment measure | Maintenance work capitalised as an asset improvement |

Order types control which settlement rules, status profiles, and cost centre assignments are available. Projects with capital expenditure requirements use PM04 so costs flow to a WBS element rather than a cost centre. <CitationFootnote source="https://help.sap.com/docs/SAP_ERP/03b5af6c2e124b25a2e2b8e4b33f9c09/c3e5c45c2e4a4df0862fb4de8e3a3e6e.html">SAP Help — PM Maintenance Orders [3]</CitationFootnote>

### What is the difference between TECO and CLSD order status?

**TECO (Technically Complete)** means the physical work is done. The order can no longer have confirmations posted, but it is still open for financial settlement. Costs can still be settled to cost centres or assets. <CitationFootnote source="https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/5f2f8b1f44a64d7b8c699ac3f000cdb5/b07dea20c61447588080e24af24e9dc5.html">SAP Help — PM in S/4HANA [1]</CitationFootnote>

**CLSD (Closed)** means financial settlement is complete. The order is locked — no more confirmations, goods movements, or settlements. This is the terminal status.

The typical sequence: REL → TECO → CLSD (after month-end settlement).

### What is order settlement and how does it work in PM?

Settlement transfers costs from the work order (a cost collector) to a receiver object — typically a cost centre, a fixed asset, or a WBS element. Settlement runs at month-end via transaction KO88 (order-by-order) or KO8G (mass settlement).

If equipment is directly linked to a fixed asset in the Asset Accounting module, maintenance costs can be capitalised and depreciated over the asset's remaining life — connecting PM to FI-AA.

## Preventive Maintenance Questions

### What is a Maintenance Plan and what are the two cycle types?

A Maintenance Plan (IP01) defines the schedule for recurring maintenance. Two cycle types:

1. **Time-based** — triggers a work order every N days/weeks/months (e.g. every 90 days).
2. **Counter-based** — triggers a work order when a counter reaches a threshold (e.g. every 5,000 km or 500 operating hours).

Multi-cycle plans can combine both: "every 90 days or 5,000 km, whichever comes first."

### What is the transaction to schedule and start a maintenance plan?

- **IP10** — Schedule maintenance plan (generates maintenance calls)
- **IP30** — Deadline monitoring (background job that converts maintenance calls into work orders automatically)
- **IP19** — Maintenance plan overview / planning board

## Integration Questions

### How does SAP PM integrate with other modules?

| Module | Integration point |
|---|---|
| MM (Materials Management) | Work orders issue spare parts as goods issues; PM triggers purchase requisitions for parts not in stock |
| FI/CO (Finance) | Work order costs settle to cost centres (CO), assets (FI-AA), or WBS elements (PS); planned/actual cost comparison |
| PP (Production Planning) | Maintenance downtime can be recorded against production orders; PM work centres share capacity planning with PP |
| WM/EWM (Warehouse Management) | Spare parts storage, bin management, and goods movement integration |

### What is the role of Plant Maintenance in SAP S/4HANA vs ECC?

In S/4HANA, the PM module is rebranded as **Asset Management** and tightly integrated with the SAP Asset Intelligence Network and IoT capabilities. Key differences:

- Linear asset management for pipelines, roads, and cable networks (not available in ECC)
- SAP Fiori apps replace classic transactions (IW21, IW31, IW41 → Fiori equivalents)
- Predictive maintenance via sensor data integration through SAP BTP <CitationFootnote source="https://learning.sap.com/learning-journeys/implement-sap-s-4hana-plant-maintenance">SAP Learning — S/4HANA PM Journey [2]</CitationFootnote>

Core configuration (order types, status profiles, settlement rules) remains similar between ECC and S/4HANA.

<Callout type="info">
In SAP PM interviews, the notification-to-closure workflow is the most frequently tested area. Know the status sequence (OSNO → REL → TECO → CLSD), what each status allows and blocks, and why costs must settle before CLSD. Candidates who can trace a work order through all statuses with the correct transactions almost always advance to the next round.
</Callout>

## Key Transaction Codes Quick Reference

| Transaction | Purpose |
|---|---|
| IW21 | Create PM notification (general) |
| IW24 | Create malfunction report |
| IW31 | Create maintenance order |
| IW32 | Change maintenance order |
| IW33 | Display maintenance order |
| IW41 | Enter time confirmation |
| IW65 | Complete or close order |
| IP01 | Create maintenance plan |
| IP10 | Schedule maintenance plan |
| IP30 | Deadline monitoring |
| IE01 | Create equipment master |
| IL01 | Create functional location |
| IK01 | Create measuring point |

## Learn More

- [How SAP ABAP and ECC Process Every Enterprise Transaction](/blog/sap-abap-ecc) — understand the ABAP runtime behind every SAP transaction, including the PM transactions listed above.
- [All About SAP Courses](/blog/all-about-sap-course-overview-eligibility-duration-and-fee-structure) — SAP PM certification path, duration, and fee structure for training providers.
