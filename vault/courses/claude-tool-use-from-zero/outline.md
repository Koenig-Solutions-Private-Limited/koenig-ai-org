---
course_slug: claude-tool-use-from-zero
title: "Claude Tool Use from Zero: From Basics to Production Connectors"
status: awaiting-g0
author: course-author
level: Builder
target_audience: "Developers who want to master Claude's tool use capabilities, from simple function calling to building robust specialized MCP servers."
prerequisites:
  - "Fundamental understanding of LLMs"
  - "Basic Python or TypeScript"
learning_outcomes:
  - "Understand and implement Claude's native tool use"
  - "Build, test, and deploy compliant MCP servers"
  - "Design secure, observable tool connectors for real-world domains"
  - "Debug complex tool interaction and authorization issues"
  - "Implement structured logging and audit trails for tool operations"
total_duration_min: 540
chapter_count: 10
description: "Master Claude tool use from basics to production: function calling, MCP server design, secure connector architecture, and audit logging in one course."
---

# Course outline: Claude Tool Use from Zero

> **Model pinning note (2026-Q3):** All `RunPromptCell` examples in this course are pinned to `claude-sonnet-4-6` for exercise reproducibility. If you run these exercises on Claude Sonnet 5, be aware of three changes: (1) Sonnet 5 rejects non-default temperature, top_p, and top_k — omit these parameters entirely; (2) Sonnet 5 enables adaptive thinking by default — pass `thinking: {type: "disabled"}` if you want concise, non-extended text responses; (3) the Sonnet 5 tokenizer produces ~30% more tokens for equivalent text, so rebaseline any `max_tokens` budgets. The tool-use patterns taught here remain valid across model versions.

## Chapter 1: Introduction to Claude's Tool Use
- Learning objectives: Understand the tool use pattern, configure initial setup, execute basic function calling.
- Duration: 40 min
- Key concepts: Claude architecture, function definitions, response parsing.
- Hands-on exercise: Set up a basic script that allows Claude to query a current stock price.

## Chapter 2: Beyond Function Calling — Understanding MCP
- Learning objectives: Grasp the Model Context Protocol, compare MCP to native tool integrations.
- Duration: 50 min
- Key concepts: MCP specifications, resources, prompts, tools.
- Hands-on exercise: Connect to an existing MCP server using the Claude CLI.

## Chapter 3: Building Your First MCP Server
- Learning objectives: Scaffold a server, define custom tools, manage state.
- Duration: 60 min
- Key concepts: MCP SDK, tool lifecycle, error handling in tools.
- Hands-on exercise: Build a server that provides a file system browsing tool.

## Chapter 4: Handling Advanced Data and Resources
- Learning objectives: Implement MCP resource transport, serve structured data as context.
- Duration: 60 min
- Key concepts: Resources, resource templates, Binary support.
- Hands-on exercise: Create a resource tool that serves localized configuration files.

## Chapter 5: Observability and Logging in MCP
- Learning objectives: Add structured logging, log tool calls, implement auditing.
- Duration: 60 min
- Key concepts: Instrumentation, logs, tracing tool executions.
- Hands-on exercise: Add structured logging to your file browser server and verify it in logs.

## Chapter 6: Security and Authentication
- Learning objectives: Understand transport security, implement basic authentication, handle authorization.
- Duration: 60 min
- Key concepts: Auth patterns, Principle of Least Privilege, secure transport.
- Hands-on exercise: Add a decorator for authorization to your tool definitions.

## Chapter 7: Creative Connectors
- Learning objectives: Apply tool use to creative domains, managing non-textual tool inputs.
- Duration: 50 min
- Key concepts: Tool parameters for creative tasks, state persistence for generative output.
- Hands-on exercise: Build a "style guide" tool that maintains persistent visual preferences.

## Chapter 8: Legal and Regulatory Connectors
- Learning objectives: Understand regulatory requirements for legal data, implement redaction, ensure compliance.
- Duration: 60 min
- Key concepts: Confidentiality, audit trails, data residency, PII redaction.
- Hands-on exercise: Extend your MCP server with a document redaction tool.

## Chapter 9: SMB and Growth Connectors (May 2026 Update)
- Learning objectives: Master the Claude SMB workflow stack, coordinate financial and CRM tool calls, implement "human-in-the-loop" approval gates for sensitive business actions.
- Duration: 60 min
- Key concepts: Claude Cowork toggle, QuickBooks + PayPal reconciliation pattern, HubSpot lead-to-deal automation, Awaiting Approval state, Canva/DocuSign/Google Workspace/Microsoft 365 connectors.
- Hands-on exercise: Build a "Payroll Assistant" that reconciles PayPal settlements against a QuickBooks ledger and drafts reminder emails for missing payments.

## Chapter 10: Claude Code Dynamic Workflows — Fan-Out, Checkpoint, and Verify (2026)
- Learning objectives: Explain dynamic workflows vs static chains; design homogeneous and heterogeneous fan-out patterns; implement checkpoint-based resume; verify sub-agent results before assembly; identify when dynamic workflows hurt more than they help.
- Duration: 65 min
- Key concepts: [[orchestrator]], [[sub-agent]], [[fan-out]], [[checkpoint]], [[verification]], token budget, weekly plan limits.
- Hands-on exercise: Build a checkpointed Python code reviewer that fans out one `claude -p` sub-agent per file, checkpoints results, verifies schema, and produces a token-cost summary.

## Capstone Project
- Build a production-ready MCP "Agentic Connector" that bridges a secure corporate system (e.g., medical, legal, or SMB finance) to Claude. It must include:
  - Custom tool definitions for data retrieval and modification.
  - Full observability (structured logs of all calls).
  - Implemented authorization per-tool call.
  - A documented compliance and audit trail configuration.
