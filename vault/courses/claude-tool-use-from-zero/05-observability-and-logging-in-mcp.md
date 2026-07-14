---
chapter_num: 5
course_slug: claude-tool-use-from-zero
title: "Observability and Logging in MCP"
status: draft-for-review
author: course-author
ticket: KOEA-2461
learning_objectives:
  - "Add structured logs around MCP tool and resource calls"
  - "Separate operational logs from audit events"
  - "Record enough context to debug failures without leaking secrets"
  - "Verify one tool call through log output"
prerequisites_chapters:
  - 1
  - 2
  - 3
  - 4
duration_min: 60
level: Builder
vendor_tag: anthropic
sources:
  - https://modelcontextprotocol.io/
  - https://github.com/modelcontextprotocol/typescript-sdk
  - https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
tags:
  - course/claude-tool-use-from-zero
  - mcp
  - observability
  - logging
quiz:
  - question: "Which event belongs in an audit log rather than an operational log?"
    options:
      - "A timeout reading the refund-policy config file after two seconds of network delay"
      - "A high-latency directory listing that took 800ms due to a cold file-system cache"
      - "A user approving the send_invoice_reminder action in the invoice approval workflow UI"
      - "A connection pool exhaustion error that triggered an automatic retry on the database"
    correct_idx: 2
    explanation: "A user approving a customer-facing send is a sensitive business action that compliance reviewers need to reconstruct — it belongs in an audit log. Timeouts, latency spikes, and connection retries are operational signals that help engineers debug reliability; they go in operational logs."
    section_anchor: operational-logs-vs-audit-events
  - question: "What must the `input_summary` field in an MCP tool log event contain?"
    options:
      - "The full raw input object, including all credential fields and customer record values"
      - "A sanitized summary of the input that omits secrets, credentials, and private data"
      - "Only the tool name and the stop reason from the upstream API response header"
      - "A SHA-256 hash of the full input payload for downstream integrity verification"
    correct_idx: 1
    explanation: "input_summary must be a sanitized version — the raw input may contain API keys, customer names, or financial data that creates a second incident if written to logs. The other options either expose sensitive data (raw input), lose the input entirely (tool name only), or create an opaque audit trail (hash only)."
    section_anchor: the-minimum-useful-log-event
  - question: "Why should observability logic be added via a logging wrapper rather than copied into each tool handler?"
    options:
      - "Wrappers run before the tool definition is registered in the server's capability list"
      - "The MCP transport specification prohibits direct logging calls inside individual tool handlers"
      - "Consistent event shape across all tools makes the log stream searchable and correlatable"
      - "Individual tool handlers cannot access the request_id correlation identifier by design"
    correct_idx: 2
    explanation: "When every handler copies its own logging code, small differences accumulate: field names drift, some handlers miss duration_ms, others forget error_code. A wrapper enforces the same event shape for every tool automatically. Consistency is what makes logs searchable — not merely the presence of log statements."
    section_anchor: add-a-wrapper
---

# Observability and Logging in MCP

A connector you cannot observe is not production software. When Claude calls a tool, you need to know what was requested, what policy decision was made, how long execution took, and whether the result was successful. Without that trail, debugging becomes guesswork and compliance review becomes impossible.

MCP standardizes how hosts connect to servers and discover capabilities.[^1] It does not remove the need for application observability. Your server must emit logs and audit events around every meaningful operation.

## Prerequisites check

You should have a working local MCP server with at least one tool from Chapter 3 and one resource from Chapter 4. If you only have a tool, you can still complete this chapter, but the final exercise is stronger when you log both tool calls and resource reads.

## Operational logs vs audit events

Use two categories:

- Operational logs help engineers debug reliability: latency, exception class, retry count, dependency status.
- Audit events help reviewers reconstruct sensitive actions: actor, tool name, target object, authorization result, timestamp.

```takeaways
- Operational logs serve engineers debugging reliability; audit events serve reviewers reconstructing sensitive actions — both can share a pipeline but must be distinguishable.
- A timeout reading a config file is operational; a user approving an external send is audit-worthy.
- Mixing the two categories makes logs harder to search and compliance reviews harder to scope.
```

They can go to the same logging pipeline, but they should be distinguishable. A timeout reading `config/refund.en-US.json` is operational. A user approving `send_invoice_reminder` is audit-worthy.

## The minimum useful log event

Every tool call should emit:

- `event`: stable event name, such as `mcp.tool.completed`.
- `tool_name`: the MCP tool called.
- `request_id`: correlation ID from the host or generated server-side.
- `actor`: user or agent identity when available.
- `input_summary`: sanitized summary, not raw secrets.
- `success`: boolean.
- `duration_ms`: elapsed time.
- `error_code`: controlled code when failed.

```takeaways
- A stable `event` name and a `request_id` make logs searchable and correlatable across distributed systems.
- `input_summary` must be a sanitized version of the input — never log raw credentials or full customer records.
- Consistent event shape across every tool is what makes logs usable; copying logging code into each handler destroys consistency.
```

<Callout type="warning">
Do not log raw credentials, full customer records, or prompt transcripts by default. Observability that leaks sensitive data creates a second incident.
</Callout>

## Add a wrapper

Wrap tool handlers instead of copying logging code into every tool.

```ts
async function withToolLogging<T>(
  toolName: string,
  input: unknown,
  handler: () => Promise<T>
): Promise<T> {
  const started = Date.now();
  const requestId = crypto.randomUUID();
  try {
    const result = await handler();
    console.log(JSON.stringify({
      event: "mcp.tool.completed",
      request_id: requestId,
      tool_name: toolName,
      input_summary: summarizeInput(input),
      success: true,
      duration_ms: Date.now() - started
    }));
    return result;
  } catch (error) {
    console.log(JSON.stringify({
      event: "mcp.tool.failed",
      request_id: requestId,
      tool_name: toolName,
      input_summary: summarizeInput(input),
      success: false,
      duration_ms: Date.now() - started,
      error_code: classifyError(error)
    }));
    throw error;
  }
}
```

This wrapper gives every tool a consistent event shape. Consistency is what makes logs searchable.

<RunPromptCell
  model="claude-sonnet-4-6"
  tools={["course-file-browser"]}
  prompt="Use list_project_files to list the demo project root. Then explain which log fields should appear for this call."
  expectedOutput="Claude calls list_project_files({\"root_label\":\"demo\",\"relative_path\":\".\"}).\n\nThe server should emit a structured log similar to:\n{\n  \"event\": \"mcp.tool.completed\",\n  \"request_id\": \"generated-id\",\n  \"tool_name\": \"list_project_files\",\n  \"input_summary\": {\"root_label\":\"demo\",\"relative_path\":\".\"},\n  \"success\": true,\n  \"duration_ms\": 12\n}\n\nClaude should explain that request_id, tool_name, sanitized input, success, and duration make the call debuggable."
/>

## Audit examples

Read-only file listing may not need a durable audit record in a toy project. A legal document redaction tool does. A payroll approval tool definitely does.

```takeaways
- The sensitivity of the operation determines whether a durable audit record is required, not just whether the call succeeded.
- Audit records should capture actor, connector, tool, target, authorization result, and timestamp — without dumping private data into logs.
- Separating the audit event from the operational log means compliance reviewers can read one stream without sorting through latency metrics.
```

Audit records should focus on business meaning:

```json
{
  "event": "audit.connector.action_requested",
  "actor": "user_123",
  "connector": "payroll-assistant",
  "tool_name": "draft_payment_reminders",
  "target": "payroll_run_2026_05_14",
  "authorization": "allowed",
  "approval_required": true,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

That event tells a reviewer what happened without dumping private payment details into logs.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Design an audit event for a tool named redact_contract(document_id, redaction_policy). Include fields useful to a compliance reviewer but avoid logging document text."
  expectedOutput="A good audit event:\n{\n  \"event\": \"audit.connector.action_completed\",\n  \"connector\": \"legal-redaction\",\n  \"tool_name\": \"redact_contract\",\n  \"actor\": \"user_or_agent_id\",\n  \"document_id\": \"contract_123\",\n  \"redaction_policy\": \"pii-v1\",\n  \"authorization\": \"allowed\",\n  \"success\": true,\n  \"timestamp\": \"2026-05-14T12:00:00Z\"\n}\n\nIt avoids logging document text while preserving actor, target, policy, authorization, and outcome."
/>

<KnowledgeCheck
  questions={[
    {
      question: "Which field is risky to log by default?",
      answers: [
        "tool_name",
        "duration_ms",
        "raw_api_key",
        "success"
      ],
      correct: 2,
      explanation: "Secrets should never be logged."
    }
  ]}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: For your Chapter 3 tool, write one operational log event and one audit event. Explain why they are different."
    }
  ]}
/>

## Hands-on exercise

Add structured logging to your file-browser server.

Success criteria:

- Every `list_project_files` call emits one completion or failure log.
- Logs include request ID, tool name, sanitized input, success, duration, and controlled error code when failed.
- Path traversal attempts are logged as failures without exposing host filesystem details.
- You can paste one successful log and one failed log into your notes.

## What's next

Chapter 6 adds authentication and authorization. Logging tells you what happened; authorization decides whether it should happen.

[^1]: Model Context Protocol documentation, https://modelcontextprotocol.io/
[^2]: Model Context Protocol TypeScript SDK, https://github.com/modelcontextprotocol/typescript-sdk
[^3]: Anthropic, "Tool use with Claude", https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
