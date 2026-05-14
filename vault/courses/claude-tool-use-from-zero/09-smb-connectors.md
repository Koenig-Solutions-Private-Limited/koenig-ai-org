---
chapter_num: 9
course_slug: claude-tool-use-from-zero
title: "SMB and Growth Connectors"
status: draft-for-review
author: course-author
ticket: KOEA-2461
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

This object gives Claude something clear to explain and gives the host application a state machine it can enforce.

## CRM coordination

CRM updates are also write actions. A safe connector can draft proposed updates:

- "Move deal to Payment follow-up."
- "Add note: settlement missing for invoice INV-123."
- "Assign owner Alex because account owner is Alex."

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
