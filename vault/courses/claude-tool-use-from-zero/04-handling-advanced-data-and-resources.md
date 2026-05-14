---
chapter_num: 4
course_slug: claude-tool-use-from-zero
title: "Handling Advanced Data and Resources"
status: draft-for-review
author: course-author
ticket: KOEA-2461
learning_objectives:
  - "Model read-only context as MCP resources instead of tools"
  - "Design stable resource URIs for localized configuration data"
  - "Explain when binary or large data should be summarized instead of embedded"
  - "Add one resource workflow to the file-browser server"
prerequisites_chapters:
  - 1
  - 2
  - 3
duration_min: 60
level: Builder
vendor_tag: anthropic
sources:
  - https://modelcontextprotocol.io/
  - https://github.com/modelcontextprotocol/typescript-sdk
  - https://docs.anthropic.com/en/docs/claude-code/mcp
tags:
  - course/claude-tool-use-from-zero
  - mcp
  - resources
  - structured-data
---

# Handling Advanced Data and Resources

Tools perform actions. Resources provide context. That distinction is the difference between a connector that feels clean and one where every read looks like a side effect.

MCP's core primitives include tools, resources, and prompts.[^1] The TypeScript SDK documents server support for all three.[^2] In this chapter you add a resource pattern to the file-browser server: localized configuration files exposed as stable context.

## Prerequisites check

You need the Chapter 3 file browser server or an equivalent local MCP server. You should be able to start it and connect a host. You should also understand why `list_project_files` was modeled as a tool: it performs a directory listing action and may fail depending on path.

## The resource design problem

Imagine a support assistant that needs the refund policy in English and German. You could expose a tool:

```text
get_refund_policy(locale)
```

That works, but it tells the model "call an action." If the policy is stable context, a resource URI is clearer:

```text
company-config://policies/refund/en-US
company-config://policies/refund/de-DE
```

The URI names the thing. Claude can read it as context. Your server can still enforce access rules and log reads.

## Resource URI rules

Good resource URIs are:

- Stable: the same policy has the same URI tomorrow.
- Meaningful: a human can infer what the resource represents.
- Scoped: the URI includes tenant, project, locale, or environment when needed.
- Non-secret: the URI should not contain credentials or private tokens.

Bad resource URIs include raw file paths from a developer laptop, signed URLs with secrets, or database primary keys that reveal internal implementation details.

<Callout type="info">
A resource URI is an interface, not a storage location. It can map to a file, database row, object store item, or generated summary. Keep storage decisions behind the server boundary.
</Callout>

## Localized configuration example

Create a `config/` directory inside the demo project:

```text
demo-project/
  config/
    refund.en-US.json
    refund.de-DE.json
```

Each file should contain structured policy data:

```json
{
  "policy": "refund",
  "locale": "en-US",
  "window_days": 30,
  "requires_receipt": true,
  "exceptions": ["downloaded digital goods", "custom services"]
}
```

Your server can expose this as a resource instead of a broad file-read tool. The host sees policy context, not arbitrary disk access.

<RunPromptCell
  model="claude-sonnet-4-6"
  tools={["course-file-browser"]}
  prompt="Read the company refund policy resource for en-US and summarize the refund window, receipt requirement, and exceptions."
  expectedOutput={`Claude should request the resource URI:

company-config://policies/refund/en-US

Expected resource content:
{
  "policy": "refund",
  "locale": "en-US",
  "window_days": 30,
  "requires_receipt": true,
  "exceptions": ["downloaded digital goods", "custom services"]
}

Claude should summarize:
The en-US refund policy allows refunds within 30 days, requires a receipt, and excludes downloaded digital goods and custom services.`}
/>

## Handling binary and large data

Resources can represent more than text, but large or binary data needs care. If a PDF contract is 80 pages, blindly injecting it into the model context is slow, expensive, and often useless. Better patterns include:

- Expose metadata first: title, type, page count, owner, updated time.
- Expose section resources: `contract://123/section/payment-terms`.
- Expose summaries with provenance: include page numbers or section IDs.
- Offer a tool for targeted extraction when the model needs specific clauses.

The goal is not "Claude sees everything." The goal is "Claude sees the right context with enough structure to act."

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I have a 90-page vendor contract. Design MCP resources and tools so Claude can answer payment-term questions without loading the entire PDF into context."
  expectedOutput={`A good design:

Resources:
- contract://vendor-123/metadata
- contract://vendor-123/sections/payment-terms
- contract://vendor-123/sections/termination

Tools:
- search_contract(contract_id, query)
- extract_clause(contract_id, clause_type)

This keeps context targeted. Claude can read metadata, then the payment terms section, and only call extraction when needed.`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Which should be modeled as an MCP resource?",
      answers: [
        "send_invoice_reminder(customer_id)",
        "company-config://policies/refund/en-US",
        "delete_temp_files()",
        "approve_payroll_run(run_id)"
      ],
      correct: 1,
      explanation: "The policy URI is read-only context."
    }
  ]}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Design one stable resource URI for a configuration document in your domain. Explain what storage details you would hide behind the URI."
    }
  ]}
/>

## Hands-on exercise

Extend your Chapter 3 server with a localized refund-policy resource.

Success criteria:

- The server exposes `company-config://policies/refund/en-US`.
- The resource returns structured JSON with policy, locale, refund window, receipt rule, and exceptions.
- Claude can summarize the policy without calling a write-capable tool.
- You can explain why the URI is stable and non-secret.

## What's next

Chapter 5 adds observability. You will make every tool and resource access visible through structured logs and audit events.

[^1]: Model Context Protocol documentation, https://modelcontextprotocol.io/
[^2]: Model Context Protocol TypeScript SDK, https://github.com/modelcontextprotocol/typescript-sdk
[^3]: Anthropic, "Connect Claude Code to tools via MCP", https://docs.anthropic.com/en/docs/claude-code/mcp
