---
chapter_num: 2
course_slug: claude-tool-use-from-zero
title: "Beyond Function Calling: Understanding MCP"
status: draft-for-review
author: course-author
ticket: KOEA-2461
learning_objectives:
  - "Explain what MCP adds beyond native client-side tool calls"
  - "Distinguish MCP tools, resources, and prompts"
  - "Describe host, client, and server responsibilities"
  - "Connect Claude Code to an MCP server at a high level"
prerequisites_chapters:
  - 1
duration_min: 50
level: Builder
vendor_tag: anthropic
sources:
  - https://modelcontextprotocol.io/
  - https://github.com/modelcontextprotocol/typescript-sdk
  - https://docs.anthropic.com/en/docs/claude-code/mcp
tags:
  - course/claude-tool-use-from-zero
  - mcp
  - claude-code
  - connectors
---

# Beyond Function Calling: Understanding MCP

Chapter 1 gave Claude one client-side function. That pattern works for small applications, but it does not scale well when every AI product needs the same connectors. The Model Context Protocol (MCP) is the standard layer that lets AI applications connect to external tools and data sources through reusable servers.[^1]

Think of native tool use as "my app gave Claude a function." Think of MCP as "my app can connect to a server that advertises tools, resources, and prompts using a shared protocol." That shift is the difference between a one-off integration and a connector ecosystem.

## Prerequisites check

You should already be able to explain a `tool_use` block, a tool input schema, and a `tool_result`. If not, repeat the Chapter 1 hands-on before continuing. MCP still uses tool calls; it just moves discovery and execution behind a protocol boundary.

## What MCP adds

MCP gives you three practical upgrades:

1. Discovery: a host can ask a server what it offers instead of hard-coding every function in the host.
2. Reuse: one MCP server can serve many hosts.
3. Separation: the connector owner can maintain auth, data access, and domain logic outside the LLM application.

The official TypeScript SDK describes MCP servers as exposing tools, resources, prompts, transports, and deployment patterns.[^2] Anthropic's Claude Code documentation describes MCP as the way Claude Code connects to external tools and data sources.[^3]

## Host, client, server

MCP uses three terms that are easy to blur:

- Host: the user-facing AI application, such as Claude Code or another agent UI.
- Client: the protocol component inside the host that speaks MCP.
- Server: the external process or service that exposes capabilities.

When a learner says "Claude calls my MCP server," the precise version is: the host's MCP client connects to your MCP server, discovers capabilities, and sends protocol requests when the model needs them.

<Callout type="info">
MCP is not a replacement for authorization. It standardizes how capabilities are exposed and called. Your server still owns credentials, input validation, policy checks, logging, and rate limits.
</Callout>

## Tools, resources, and prompts

Tools are callable actions. Use tools for operations like `search_invoices`, `create_support_ticket`, or `lookup_stock_price`.

Resources are context objects the model can read. Use resources for project files, policy documents, account summaries, or configuration records. A resource should feel like "read this thing" rather than "perform this action."

Prompts are reusable prompt templates exposed by the server. Use prompts when a connector knows the right instruction pattern for a workflow, such as "summarize this compliance document against policy X."

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Classify each MCP capability as a tool, resource, or prompt: (1) list_unpaid_invoices(customer_id), (2) company://policies/refund-policy, (3) a reusable template named draft_collection_email."
  expectedOutput={`1. list_unpaid_invoices(customer_id): tool, because it is a callable action that queries a business system.
2. company://policies/refund-policy: resource, because it is readable context.
3. draft_collection_email: prompt, because it is a reusable instruction template for a workflow.`}
/>

## Why this matters for connector design

Bad MCP servers expose raw platform primitives: `http_request`, `sql_query`, `run_command`. Good MCP servers expose business capabilities: `get_customer_balance`, `search_contract_clauses`, `draft_invoice_reminder`. The server boundary is your chance to turn a messy API into a model-friendly interface.

The connector designer's job is not to mirror every endpoint. It is to decide which operations are safe, useful, observable, and understandable.

## Connecting to an existing server

Claude Code supports adding MCP servers through CLI configuration. Anthropic's docs show commands for stdio and remote transports, including environment variables for local commands.[^3] For this chapter, the operational goal is simple: you should be able to read a server command, identify whether it is local or remote, and explain which credentials it needs.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I am about to add an MCP server with: claude mcp add finance-demo -e FINANCE_API_KEY=... -- node ./server.js. Explain what runs locally, what secret is passed, and what Claude Code should discover after connection."
  expectedOutput={`The local command is node ./server.js. Claude Code starts that process as the MCP server.

FINANCE_API_KEY is passed as an environment variable to the server process. It should not be written into prompts or logs.

After connection, Claude Code's MCP client should discover the server capabilities: any tools, resources, and prompts the finance-demo server advertises.`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Which MCP primitive is best for a read-only policy document?",
      answers: ["Tool", "Resource", "Prompt", "Transport"],
      correct: 1,
      explanation: "A policy document is context to read, so it should be modeled as a resource."
    },
    {
      question: "What does MCP standardize?",
      answers: [
        "The external service's business rules",
        "The way AI applications connect to tools and data sources",
        "The pricing model for Claude",
        "The content of every prompt"
      ],
      correct: 1,
      explanation: "MCP standardizes the connection and capability model, not your domain policy."
    }
  ]}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Pick one workflow from your work. Name one tool, one resource, and one prompt an MCP server for that workflow might expose."
    }
  ]}
/>

## Hands-on exercise

Connect Claude Code to one existing MCP server in a sandbox environment. Use a server that does not have write access to production systems.

Success criteria:

- You can identify the host, client, and server in your setup.
- You can list at least one advertised capability.
- You can classify each capability as a tool, resource, or prompt.
- You can explain where secrets are stored and which process receives them.

## What's next

Chapter 3 builds your first MCP server instead of merely connecting to one. You will expose a file-browsing tool with a narrow root and controlled errors.

[^1]: Model Context Protocol documentation, https://modelcontextprotocol.io/
[^2]: Model Context Protocol TypeScript SDK, https://github.com/modelcontextprotocol/typescript-sdk
[^3]: Anthropic, "Connect Claude Code to tools via MCP", https://docs.anthropic.com/en/docs/claude-code/mcp
