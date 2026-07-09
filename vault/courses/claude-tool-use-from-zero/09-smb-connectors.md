---
chapter_num: 9
course_slug: claude-tool-use-from-zero
title: "SMB and Growth Connectors"
status: g4-approved
author: course-author
ticket: KOEA-2461
g3_passed_by: ceo
g3_passed_at: 2026-06-11
g3_bundle_ticket: KOEA-7719
g4_approved_by: vardaan-koenig
g4_approved_at: 2026-06-11
g4_approval_id: 57cf6a00-c85f-439c-89ea-5ef6286e9424
parent_brief: KOEA-2241
learning_objectives:
  - "Design SMB connectors that coordinate finance, CRM, document, and workspace tools"
  - "Separate reconciliation, drafting, and sending actions into distinct tool calls"
  - "Implement human approval gates for payment and customer-facing workflows"
  - "Define a capstone-ready Payroll Assistant connector"
prerequisites_chapters:
  - 1
  - 2
  - 3
  - 4
  - 5
  - 6
  - 7
  - 8
duration_min: 60
level: Builder
vendor_tag: anthropic
sources:
  - https://www.anthropic.com/news
  - https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
  - https://modelcontextprotocol.io/
tags:
  - course/claude-tool-use-from-zero
  - smb
  - finance
  - approvals
  - connectors
quiz:
  - question: "Why should an SMB connector replace vendor-specific API primitives like `quickbooks_query(sql)` with workflow-level tools?"
    options:
      - "Vendor APIs have higher latency than workflow-level abstractions running in the same connector process"
      - "Workflow-level tools describe business actions, making approval gates and audit logging tractable"
      - "The MCP specification prohibits raw SQL queries in tool input schema definitions"
      - "Claude cannot reliably generate valid SQL, so natural-language tool names are required instead"
    correct_idx: 1
    explanation: "quickbooks_query(sql) forces Claude to reason at the database level and makes every call look like an arbitrary data operation. Workflow-level tools like find_unmatched_settlements describe what the business needs to happen. This makes it clear what each tool does, where an approval gate belongs, and what should be logged."
    section_anchor: the-smb-workflow-stack
  - question: "Why must the Payroll Assistant separate reconciliation from the customer-facing send action into distinct tools?"
    options:
      - "Running both actions in one call exceeds the MCP tool input size limit for financial payloads"
      - "Combining them makes human approval impossible because there is no natural pause point for review"
      - "The MCP protocol does not support multi-stage tool calls within a single server session connection"
      - "QuickBooks and PayPal rate limits require the two API calls to be spaced at least thirty seconds apart"
    correct_idx: 1
    explanation: "Each stage carries different risk: matching is read-heavy, drafting is reversible, and sending is external and customer-facing. Combining them means you cannot insert a human approval gate between 'we found a mismatch' and 'we emailed the customer.' Splitting also prevents a matching failure from rolling back a send that already executed."
    section_anchor: split-reconciliation-from-action
  - question: "What makes an `awaiting_approval` object more useful than Claude describing the draft action in prose?"
    options:
      - "The awaiting_approval object is smaller in tokens, which reduces the cost of each tool response"
      - "The object gives the host application a machine-readable state it can enforce as control flow"
      - "Prose descriptions are filtered by the MCP protocol before reaching the host application layer"
      - "Only structured JSON objects are visible to the user; prose text is hidden from the UI rendering layer"
    correct_idx: 1
    explanation: "An awaiting_approval object with run_id, summary, and approval_required_for gives the host a state it can enforce: it knows an approval is pending and can gate the next write action on a confirmed approval event. Claude explaining the draft in prose is advisory — the application cannot reliably gate on prose without fragile parsing."
    section_anchor: approval-state
---

# SMB and Growth Connectors

Small businesses do not need a beautiful generic "tool calling" demo. They need reliable help across messy workflows: payments, invoices, CRM updates, documents, customer emails, and approvals. This final chapter turns the patterns from the course into an SMB connector design you can actually ship.

The outline for this course names a Payroll Assistant: reconcile PayPal settlements against a QuickBooks-style ledger and draft reminder emails for missing payments. We will use that as the capstone bridge. The exact vendor APIs may differ in your environment, but the connector architecture should not.

## Prerequisites check

You should have completed Chapters 1-8. In particular, you need:

- Native Claude tool-use flow from Chapter 1.
- MCP tools/resources/prompts from Chapters 2-4.
- Structured logs from Chapter 5.
- Authorization and approval gates from Chapter 6.
- Domain-specific connector thinking from Chapters 7 and 8.

If any of those are missing, do not build the payroll workflow yet. Finance connectors amplify every weak spot.

## The SMB workflow stack

An SMB connector rarely talks to one system. A real workflow may touch:

- Finance ledger: invoices, payments, payouts, fees.
- Payment processor: settlements, disputes, transaction IDs.
- CRM: customer owner, deal stage, account notes.
- Email or workspace: reminders, internal review threads, attachments.
- Document system: statements, contracts, receipts.

```takeaways
- An SMB connector typically spans multiple systems; the design job is to present a coherent set of business actions rather than one raw endpoint per vendor.
- Replacing vendor-specific primitives (quickbooks_query, paypal_get) with workflow-level tools (find_unmatched_settlements, draft_missing_payment_reminders) makes approval and logging tractable.
- Finance connectors specifically benefit from boring, narrow interfaces — the more sensitive the action, the less ambiguity the tool should allow.
```

The connector should present these as business actions, not raw vendor endpoints.

Bad:

```text
quickbooks_query(sql)
paypal_get(path)
hubspot_patch(object)
gmail_send(raw)
```

Better:

```text
find_unmatched_settlements(date_range)
match_payment_to_invoice(settlement_id, invoice_id)
draft_missing_payment_reminders(run_id)
request_approval_for_reminders(run_id)
```

The better tools describe the accounting workflow. They also make approval and logging tractable.

<Callout type="hot">
Finance connectors need boring interfaces. The more sensitive the action, the less clever the tool should be. Make each operation narrow, typed, logged, and reviewable.
</Callout>

## Split reconciliation from action

The Payroll Assistant should not combine "find mismatches" and "email customers" into one call. Use stages:

1. Collect ledger entries for the period.
2. Collect payment settlements for the same period.
3. Match by amount, date window, payer, and reference.
4. Produce exceptions.
5. Draft reminders for exceptions.
6. Request human approval.
7. Send only after approval.

```takeaways
- Combining reconciliation and customer-facing send into one tool call makes approval impossible and audit trail ambiguous.
- Each stage carries different risk: matching is read-heavy, drafting is reversible, sending is external — these belong in separate tools.
- Splitting stages also means a failure in matching does not roll back a send that already happened.
```

Each stage has different risk. Matching is read-heavy. Drafting is reversible. Sending is external and customer-facing.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Design MCP tools for a Payroll Assistant that reconciles PayPal settlements against an invoice ledger. Keep reconciliation separate from customer-facing email."
  expectedOutput={`Suggested tools:

- list_invoice_ledger(date_range): read ledger entries.
- list_payment_settlements(date_range): read settlement records.
- propose_settlement_matches(date_range): returns matched and unmatched records.
- draft_missing_payment_reminders(reconciliation_run_id): drafts reminder emails.
- request_reminder_send_approval(reconciliation_run_id): creates an approval package.
- send_approved_reminders(approval_id): sends only after approval.

This separates read, draft, approval, and send phases.`}
/>

## Approval state

Use an explicit `awaiting_approval` state for sensitive actions. Do not hide it in prose.

```json
{
  "status": "awaiting_approval",
  "workflow": "payroll_reminders",
  "run_id": "payroll_2026_05_14",
  "summary": {
    "unmatched_settlements": 4,
    "drafted_reminders": 3,
    "total_amount": "USD 1840.00"
  },
  "approval_required_for": "send_customer_emails"
}
```

```takeaways
- An explicit `awaiting_approval` status in the tool result gives the host application a machine-readable state it can enforce, not just prose Claude can explain away.
- The approval object should include run_id, a quantitative summary, and what specifically requires approval — enough for a human to decide without seeing full private data.
- The host must gate the next write action on a confirmed approval event; Claude presenting the draft is not an approval.
```

This object gives Claude something clear to explain and gives the host application a state machine it can enforce.

## CRM coordination

CRM updates are also write actions. A safe connector can draft proposed updates:

- "Move deal to Payment follow-up."
- "Add note: settlement missing for invoice INV-123."
- "Assign owner Alex because account owner is Alex."

```takeaways
- CRM updates that trigger automated sequences are effectively external actions and require the same approval gate as customer-facing emails.
- The safe pattern is propose_crm_updates → human approval → apply_approved_crm_updates, not a direct write after finding a mismatch.
- Whether CRM notes are low-risk depends on whether they trigger downstream automations — risk must be assessed at the workflow level, not just the field level.
```

But the connector should not silently update every customer record. If your organization treats CRM notes as low-risk, you may allow writes with role-based authorization. If CRM updates trigger automations, treat them like external actions and require approval.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="A CRM update will trigger an automated customer success sequence. Should the Payroll Assistant write the CRM stage directly after finding a missing payment? Explain the safer connector design."
  expectedOutput={`No. If the CRM stage triggers an automated customer-facing sequence, the update is effectively an external action.

Safer design:
- propose_crm_updates(reconciliation_run_id)
- show affected accounts and stage changes
- require human approval
- apply_approved_crm_updates(approval_id)

This keeps automation behind an explicit approval gate.`}
/>

## Capstone architecture

Your final connector should expose:

Resources:

- `payroll://runs/{run_id}/summary`
- `payroll://runs/{run_id}/exceptions`
- `payroll://policies/reminder-template`

Tools:

- `start_reconciliation(date_range)`
- `propose_settlement_matches(run_id)`
- `draft_missing_payment_reminders(run_id)`
- `request_send_approval(run_id)`
- `send_approved_reminders(approval_id)`

Prompts:

- `explain_reconciliation_summary`
- `review_reminder_drafts`

Logs:

- operational events for every tool call.
- audit events for approval creation and sending.

<KnowledgeCheck
  questions={[
    {
      question: "Which tool should require human approval?",
      answers: [
        "list_invoice_ledger(date_range)",
        "propose_settlement_matches(run_id)",
        "send_approved_reminders(approval_id)",
        "read_reminder_template()"
      ],
      correct: 2,
      explanation: "Sending customer-facing reminders is an external action and should be approval-gated."
    }
  ]}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Identify one SMB workflow in your organization and split it into read, draft, approval, and execute tools."
    }
  ]}
/>

## Hands-on exercise

Build the Payroll Assistant design document and one runnable stub tool.

Success criteria:

- You define resources, tools, prompts, logs, and audit events.
- You implement a stub `propose_settlement_matches(run_id)` tool against demo JSON data.
- The tool returns matched records and exceptions.
- Customer-facing email remains a draft until an approval object is created.
- You can explain how this connector satisfies the course outcomes.

## What's next

This is the final chapter. Your capstone is to turn the Payroll Assistant or another domain connector into a production-ready MCP server with narrow tools, resources, structured logs, authorization, and approval gates.

[^1]: Anthropic news index, https://www.anthropic.com/news
[^2]: Anthropic, "Tool use with Claude", https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
[^3]: Model Context Protocol documentation, https://modelcontextprotocol.io/
