---
chapter_num: 6
course_slug: claude-tool-use-from-zero
title: "Security and Authentication"
status: draft-for-review
author: course-author
ticket: KOEA-2461
learning_objectives:
  - "Distinguish authentication from authorization in MCP connectors"
  - "Apply least privilege to tool design and credential scope"
  - "Add an authorization wrapper around tool handlers"
  - "Design a human approval gate for sensitive actions"
prerequisites_chapters:
  - 1
  - 2
  - 3
  - 4
  - 5
duration_min: 60
level: Builder
vendor_tag: anthropic
sources:
  - https://docs.anthropic.com/en/docs/claude-code/mcp
  - https://modelcontextprotocol.io/
  - https://github.com/modelcontextprotocol/typescript-sdk
tags:
  - course/claude-tool-use-from-zero
  - mcp
  - security
  - authentication
quiz:
  - question: "A request carries a valid bearer token that maps to user_123. Which question requires authorization (not authentication)?"
    options:
      - "Was this token cryptographically signed by the expected identity provider certificate?"
      - "Is this token within its expiry window and absent from the revocation set?"
      - "May user_123 call the draft_invoice_reminder tool on customer account A-107?"
      - "Does this request include the required API version header for the connector version?"
    correct_idx: 2
    explanation: "Authentication asks 'who is this caller?' — whether the token is valid and unexpired. Authorization asks 'may this caller do this action to this target?' — whether user_123 has permission for a specific tool and a specific target object. The other three options all concern the validity of the credential, not what the credential permits."
    section_anchor: authentication-vs-authorization
  - question: "A payroll assistant only drafts and queues reminder emails; it never sends them. Which credential violates least privilege?"
    options:
      - "A read-only token scoped to payroll ledger records for the current billing period"
      - "A full send token for external payment instructions and outbound wire transfers"
      - "An email:draft scope for creating unsubmitted reminder drafts in the approval queue"
      - "An invoice:read scope limited to the vendor records needed for payment reconciliation"
    correct_idx: 1
    explanation: "A connector that only drafts emails has no business need for a payment-send token. Granting it violates least privilege by giving the connector access to write-capable operations it was never designed to perform. The other three options all match the connector's declared scope of reading ledger data and creating draft messages."
    section_anchor: least-privilege-for-connectors
  - question: "Which design correctly implements a human approval gate for a sensitive MCP action?"
    options:
      - "Return the completed action immediately and include a confirmation string in the tool result"
      - "Return an `awaiting_approval` object with an approval_id and preview data for human review"
      - "Ask Claude to include a polite 'please confirm before I proceed' sentence in its text reply"
      - "Add a system prompt instruction telling the model to pause before executing any write tools"
    correct_idx: 1
    explanation: "An awaiting_approval object gives the host application a machine-readable state it can enforce: it knows an approval is pending and can gate the next write action on a confirmed approval event. A confirmation string in a response, Claude's prose reply, or a prompt instruction are all advisory — the application cannot enforce them as control flow."
    section_anchor: human-in-the-loop-approval
---

# Security and Authentication

By now your connector can expose tools, resources, and logs. That is enough for a demo and not enough for production. Production connectors need authentication, authorization, least privilege, and approval gates.

Anthropic's Claude Code MCP documentation warns that third-party MCP servers should be used carefully, especially when they communicate with the internet, because they can introduce prompt-injection risks.[^1] The lesson is broader than Claude Code: every connector is a new trust boundary.

## Prerequisites check

You need the structured logs from Chapter 5. If a tool call is not logged, you cannot audit security behavior. You should also have at least one tool that can be denied without breaking the whole server.

## Authentication vs authorization

Authentication answers "who is calling?" Authorization answers "may this caller do this action to this target?"

Examples:

- Authentication: request includes a bearer token that maps to `user_123`.
- Authorization: `user_123` may read demo project files but may not list production secrets.
- Authentication: the MCP server receives `FINANCE_API_KEY` as an environment variable.
- Authorization: that key can read settlement records but cannot issue refunds.

```takeaways
- Authentication and authorization are separate concerns: a valid credential does not automatically permit every tool or every target.
- Per-tool authorization (not just per-server) is necessary because different tools carry different risk levels.
- The pattern "authenticate → derive actor → authorize action → execute → log result" is the correct ordering for every tool handler.
```

Do not collapse these concepts. A valid credential does not imply permission for every tool.

## Least privilege for connectors

Least privilege means the connector receives only the access needed for its declared operations. A file browser for a demo project should not mount the whole home directory. A payroll assistant should not receive a write token if it only drafts reminder emails. A legal redaction tool should not retain original documents after output is produced unless policy requires retention.

```takeaways
- Least privilege applies at the credential level (scope of the API key or token) and at the tool level (which operations the connector exposes).
- An "admin token plus prompt instructions" security model is not authorization — prompt rules are suggestions, authorization checks are enforced in code.
- MCP's ease of exposing capabilities is a design pressure toward over-permission; narrow tools and scoped credentials counteract it.
```

MCP makes it easy to expose capabilities. That ease is exactly why you must design them narrowly.

<Callout type="warning">
Avoid "admin token plus prompt rules" as a security model. Prompt rules are instructions; authorization checks are code.
</Callout>

## Authorization wrapper

Put authorization before tool execution and before detailed logging of target data.

```ts
type Actor = {
  id: string;
  roles: string[];
};

function requirePermission(actor: Actor, permission: string) {
  if (!actor.roles.includes(permission)) {
    const error = new Error("Forbidden");
    error.name = "FORBIDDEN";
    throw error;
  }
}

async function authorizedTool<T>(
  actor: Actor,
  permission: string,
  run: () => Promise<T>
): Promise<T> {
  requirePermission(actor, permission);
  return run();
}
```

Then call it inside a tool handler:

```ts
server.registerTool("list_project_files", schema, async (input, context) => {
  const actor = actorFromContext(context);
  return authorizedTool(actor, "project:read", async () => {
    return listProjectFiles(input);
  });
});
```

The exact context object depends on your transport and host. The pattern is stable: authenticate, derive actor, authorize action, execute tool, log result.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="A connector has tools read_invoice, draft_invoice_reminder, and send_invoice_reminder. Assign read/write/approval requirements for each using least privilege."
  expectedOutput={`A least-privilege design:

- read_invoice: requires invoice:read. No human approval if read-only and scoped.
- draft_invoice_reminder: requires invoice:read and email:draft. No external send; approval optional.
- send_invoice_reminder: requires invoice:read and email:send, plus human approval before sending.

The write-capable external action has the strongest gate.`}
/>

## Human-in-the-loop approval

Some tools should not execute immediately even when authorized. Approval gates are appropriate when a tool sends money, changes legal text, deletes data, emails customers, or modifies production systems.

```takeaways
- Authorization is necessary but not sufficient for high-risk actions; approval gates add a human decision point after authorization passes.
- A tool should return an `awaiting_approval` object with enough preview data for a human to make an informed decision without exposing full private content.
- The application must enforce the approval state in code; Claude explaining the draft is not a substitute for a required user click.
```

A safe tool can return a pending action:

```json
{
  "status": "awaiting_approval",
  "action": "send_invoice_reminder",
  "preview": {
    "to": "ap@example.test",
    "subject": "Reminder: invoice INV-123",
    "body_excerpt": "This is a reminder that..."
  },
  "approval_id": "appr_123"
}
```

Claude can explain the draft, but your application should require a user click or separate approval event before sending.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Design the result object for a tool that prepares, but does not send, payroll reminder emails. Include enough data for human review."
  expectedOutput={`A safe result:
{
  "status": "awaiting_approval",
  "action": "send_payroll_reminders",
  "approval_id": "approval_2026_05_14_001",
  "reminder_count": 3,
  "recipients": [
    {"vendor_id":"vendor_17","email":"masked@example.test","amount_due":"USD 420.00"}
  ],
  "preview_available": true
}

The tool prepares the action and creates an approval record. It does not send messages automatically.`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Which statement is correct?",
      answers: [
        "Authentication means every tool is allowed",
        "Authorization decides whether an authenticated actor may perform a specific action",
        "Approval gates are only for read-only actions",
        "Prompt instructions can replace server-side checks"
      ],
      correct: 1,
      explanation: "Authorization is action-specific and must be enforced in code."
    }
  ]}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Pick one sensitive tool in your domain and specify authentication, authorization, and human approval requirements."
    }
  ]}
/>

## Hands-on exercise

Add an authorization wrapper to your Chapter 3 file-browser tool.

Success criteria:

- The server derives an actor from context or a local demo token.
- `list_project_files` requires `project:read`.
- An actor without `project:read` receives a controlled forbidden error.
- The denial is logged without leaking the requested filesystem path outside the approved root.

## What's next

Chapter 7 applies the connector pattern to creative tools. You will see how state, non-textual outputs, and professional applications change the design pressure.

[^1]: Anthropic, "Connect Claude Code to tools via MCP", https://docs.anthropic.com/en/docs/claude-code/mcp
[^2]: Model Context Protocol documentation, https://modelcontextprotocol.io/
[^3]: Model Context Protocol TypeScript SDK, https://github.com/modelcontextprotocol/typescript-sdk
