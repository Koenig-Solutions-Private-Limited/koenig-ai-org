---
chapter_num: 2
course_slug: claude-tool-use-from-zero
title: "Beyond Function Calling: Understanding MCP"
status: awaiting-g0
author: course-author
ticket: KOEA-6160
learning_objectives:
  - "Explain what MCP adds beyond native client-side tool calls"
  - "Distinguish MCP tools, resources, and prompts using real connector examples"
  - "Describe host, client, and server responsibilities in an MCP connection"
  - "Choose the right transport and configuration scope for a Claude Code MCP server"
  - "Connect Claude Code to a sandbox MCP server and inspect its advertised capabilities"
prerequisites_chapters:
  - 1
duration_min: 50
level: Builder
vendor_tag: anthropic
sources:
  - https://modelcontextprotocol.io/docs/learn/architecture
  - https://modelcontextprotocol.io/specification/draft/server/tools
  - https://modelcontextprotocol.io/specification/draft/server/resources
  - https://modelcontextprotocol.io/specification/draft/server/prompts
  - https://github.com/modelcontextprotocol/typescript-sdk
  - https://code.claude.com/docs/en/mcp
tags:
  - course/claude-tool-use-from-zero
  - mcp
  - claude-code
  - connectors
---

# Beyond Function Calling: Understanding MCP

Chapter 1 gave Claude one client-side function: a stock-price lookup that your host application described, executed, and returned to the model. That pattern is the foundation of tool use. It also exposes the first scaling problem. If every AI application has to hand-code its own GitHub connector, database connector, design-system connector, and finance connector, the industry ends up with dozens of one-off integrations that all solve discovery, credentials, logs, and safety in slightly different ways.

The Model Context Protocol, or MCP, is the standard layer that moves reusable capabilities behind a protocol boundary. The official architecture documentation describes MCP as a system where host applications connect to MCP servers through MCP clients, and those servers expose capabilities such as tools, resources, and prompts.[^architecture] The practical result is simple: instead of saying, "My app gave Claude a Python function," you can say, "Claude Code connected to a server that advertises a controlled set of capabilities."

That distinction matters for the rest of this course. Native function calling teaches the turn-by-turn mechanics: describe a tool, receive a tool request, run code, return the result. MCP teaches connector architecture: discover capabilities, isolate domain logic, reuse the same server across hosts, and keep policy enforcement out of the model prompt.

By the end of this chapter, you should be able to look at an MCP server and answer five production questions:

1. Which application is the host?
2. Which process or remote endpoint is the server?
3. Which advertised capabilities are tools, resources, and prompts?
4. Which transport connects them?
5. Where do secrets and security decisions live?

Those five questions are enough to keep you out of most early MCP design mistakes.

## Prerequisites check

Before continuing, make sure you can explain the Chapter 1 tool-use loop without looking at notes:

1. Claude receives a user request plus a list of available tools.
2. Claude returns a `tool_use` block when it wants one of those tools.
3. Your host validates the tool name and input.
4. Your host executes the real code.
5. Your host sends a `tool_result` back to Claude.

If that loop is still fuzzy, repeat the Chapter 1 stock-price exercise first. MCP does not remove the loop. It puts a standard client-server protocol around the capabilities that the host can offer to Claude.

You also need a terminal where you can run basic commands. The hands-on exercise uses Claude Code's MCP configuration flow, but the conceptual work applies to Claude Desktop, API-hosted MCP connectors, and custom MCP clients as well.

## From one-off functions to connector servers

Native tool use is local to an application. You describe a tool in the API request, and your application handles the result. This is ideal when the tool is small, private to your product, or not worth sharing across environments.

```takeaways
- Native tool use is per-application; MCP moves capability behind a protocol boundary that any MCP-compatible host can reuse.
- An MCP server encapsulates domain logic, credentials, and policy so every host application does not have to re-implement them.
- The official TypeScript SDK structure is: create an McpServer, register capabilities, create a transport, connect — the same shape applies in Python.
```

MCP becomes useful when a capability should be reusable. A finance connector might need to query invoices, summarize customer balances, expose an accounts-receivable policy, and offer a reusable collection-email prompt. Those pieces should not be copied into every AI application. They belong in a connector server maintained by the team that understands the finance system.

The official MCP TypeScript SDK frames server development around three steps: create an `McpServer`, register tools/resources/prompts, create a transport, and connect the server to that transport.[^typescript-sdk] That shape is what you will build in Chapter 3. For now, focus on the architecture:

- The host is the user-facing AI application, such as Claude Code.
- The client is the MCP protocol component inside that host.
- The server is the external process or service that exposes capabilities.
- The transport is the connection mechanism, such as local stdio or remote HTTP.

When someone says "Claude called my MCP server," translate that into the precise version: the host's MCP client discovered capabilities from the MCP server, the model chose or benefited from one of those capabilities, and the host sent the server a protocol request.

<Callout type="warning">
MCP is not a security product by itself. It standardizes how capabilities are exposed and called. Your server still owns authentication, authorization, input validation, rate limits, error handling, and audit logs.
</Callout>

## The three primitives: tools, resources, and prompts

MCP has several protocol concepts, but this course starts with the three primitives you will use constantly: tools, resources, and prompts.

```takeaways
- Tools are callable actions with side effects or query logic; resources are stable, readable context identified by URIs; prompts are reusable instruction templates.
- Modeling a stable policy document as a tool (`get_refund_policy()`) obscures its read-only nature and pollutes the action surface.
- Classifying capabilities correctly affects safety, UX, and observability — not just naming convention.
```

Tools are callable actions. The MCP tools specification describes tools as functions exposed by a server that can be invoked by clients, with names, descriptions, input schemas, and returned content.[^tools] Use a tool when something needs to happen: search invoices, create a ticket, list files, run a diagnostic query, or draft a document from live data.

Resources are readable context. The MCP resources specification describes resources as data exposed by servers that clients can read, often identified by URIs.[^resources] Use a resource when the model needs context rather than an action: a refund policy, a project README, a database schema summary, or a localized configuration file.

Prompts are reusable prompt templates. The MCP prompts specification describes prompts as server-provided templates that can accept arguments and return messages for a workflow.[^prompts] Use a prompt when the server knows a repeatable instruction pattern: draft a polite collection email, summarize a pull request against team standards, or prepare a compliance review checklist.

Here is the rule of thumb:

- If the model should ask the server to do something, use a tool.
- If the host should attach known context for the model to read, use a resource.
- If the connector should provide a reusable instruction pattern, use a prompt.

That classification is not academic. It changes safety, UX, and observability. A refund policy modeled as `get_refund_policy()` makes a read-only document look like an action. A write-capable operation modeled as a resource hides its side effect. A long workflow prompt buried inside a tool description becomes hard to version and test.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Classify each MCP capability as a tool, resource, or prompt. Use one sentence of reasoning for each: (1) list_unpaid_invoices(customer_id), (2) company://policies/refund-policy, (3) draft_collection_email(customer_id, tone), (4) support://runbooks/password-reset, (5) create_refund(order_id, amount_cents)."
  expectedOutput={`1. list_unpaid_invoices(customer_id): tool, because it performs a query action against a finance system.
2. company://policies/refund-policy: resource, because it is read-only context identified by a stable URI.
3. draft_collection_email(customer_id, tone): prompt, because it is a reusable instruction template for a communication workflow.
4. support://runbooks/password-reset: resource, because it is a runbook the host can retrieve as context.
5. create_refund(order_id, amount_cents): tool, because it changes business state and must be invoked with validation and authorization.`}
/>

Notice that "read-only" does not automatically mean "resource." `list_unpaid_invoices(customer_id)` is read-only from the business user's perspective, but it is still an action because the server must execute a query with arguments. A resource is better when the item is stable enough to identify and retrieve directly.

## A connector example: accounts receivable

Generic examples like `foo()` and `bar()` do not teach connector design. Use a domain.

Imagine a small business wants Claude Code to help with accounts receivable. The underlying system has customers, invoices, payments, and reminder-email templates. A weak MCP server mirrors the database:

```text
query_database(sql)
http_request(method, url, body)
send_email(to, subject, body)
```

Those tools are flexible, but they force Claude to reason at the wrong layer. They also create serious safety problems. `query_database(sql)` can over-fetch sensitive records. `http_request()` can reach unapproved endpoints. `send_email()` can contact customers without a business approval step.

A stronger server exposes business capabilities:

```text
Tools:
- list_overdue_invoices(customer_id, max_age_days)
- draft_invoice_reminder(customer_id, invoice_ids)
- submit_reminder_for_approval(draft_id)

Resources:
- finance://policies/collections
- finance://customers/{customer_id}/account-summary

Prompts:
- write_polite_payment_reminder(customer_name, invoice_summary, policy_uri)
- summarize_receivables_risk(customer_summary_uri)
```

This design gives the model useful verbs without handing it raw infrastructure. It also gives the server natural enforcement points. `list_overdue_invoices` can cap result size. `draft_invoice_reminder` can redact sensitive notes. `submit_reminder_for_approval` can require a human approval state. The resources provide stable context, and the prompts encode the organization's preferred language.

The server boundary is where you turn a messy internal system into a model-friendly, policy-aware interface.

## Host, client, server, and transport

The MCP architecture is easiest to understand as a responsibility split:

```takeaways
- The host is the user-facing application (e.g., Claude Code), the client is its protocol component, and the server is the external capability provider.
- Use local stdio for scripts that need direct machine access; use remote HTTP for cloud services; SSE is deprecated for new work.
- Configuration scope (local, project, user) controls who can see the server, and secrets should use environment variable expansion rather than committed values.
```

| Part | Responsibility | Example |
|---|---|---|
| Host | User-facing AI application and UX | Claude Code |
| Client | Protocol connection managed by the host | Claude Code's MCP client for one configured server |
| Server | External capability provider | A local Node.js file-browser server |
| Transport | How messages move | stdio for local, HTTP for remote |

Claude Code's MCP documentation shows three broad connection options: remote HTTP servers, remote SSE servers, and local stdio servers.[^claude-code] The same documentation marks HTTP as the recommended option for remote cloud services and explains that local stdio servers run as local processes on your machine.[^claude-code] It also notes that SSE is deprecated in favor of HTTP where available.[^claude-code]

For a beginner, this gives you a clear decision tree:

- Use local stdio when the server is a local script or needs direct local machine access.
- Use remote HTTP when the server is a cloud service or team-managed endpoint.
- Avoid starting new SSE work unless you are integrating with an existing server that only supports it.

Configuration scope is the next decision. Claude Code supports local, project, and user scopes for MCP servers.[^claude-code] Local scope is private to your current project entry in your user configuration. Project scope writes a `.mcp.json` file that can be shared with the repository. User scope makes a server available across projects. For course work, start local unless the exercise explicitly asks for project sharing. For team connectors, project scope can be useful, but only when secrets are handled through environment variable expansion or secure authentication rather than committed values.

<Callout type="info">
Treat `.mcp.json` like infrastructure configuration. It can describe which server to use, but it should not contain production secrets. Claude Code supports environment variable expansion in MCP configuration, including command, args, env, url, and headers fields.[^claude-code]
</Callout>

## What discovery changes

In Chapter 1, your application passed tool definitions directly to Claude in the request. With MCP, the host can discover what the server offers. That discovery shift affects maintenance.

```takeaways
- MCP discovery means a server can advertise new capabilities without requiring every host application to be updated with hardcoded tool definitions.
- Discovery does not grant automatic trust; a responsible host can still filter, require approval, or disable advertised capabilities.
- Tool names and descriptions are part of the interface the model and host use to determine relevance, so a vague name is a bad MCP tool even if the code works.
```

Suppose the finance team adds a new `explain_late_fee(customer_id, invoice_id)` tool. In a one-off native integration, every host application might need code or configuration changes. In an MCP setup, the finance server can advertise the new capability through the protocol. The host still needs UX and approval policies, but the connector's capability surface is no longer embedded inside every application.

Discovery does not mean the model should automatically use everything. A responsible host can still filter tools, ask for user approval, display server trust state, or disable a capability. Discovery only means the server has a standard way to say what it can provide.

This is why good descriptions matter. The tool name and description are not documentation for humans only; they are part of the interface that helps the model and host understand when a capability is relevant. A tool named `action()` with a vague description is a bad MCP tool even if the code works.

## Common anti-patterns

The first anti-pattern is the raw executor tool: `run_shell`, `query_sql`, `http_request`, or `eval_code`. These are attractive because they make demos feel powerful. In production, they shift too much decision-making to the model. Replace them with bounded domain tools such as `list_failed_deployments`, `get_customer_balance`, or `search_contract_clauses`.

The second anti-pattern is hiding writes behind harmless names. A tool named `sync_customer` might update a CRM, email an owner, and trigger billing workflows. If a tool changes state, name the side effect and require appropriate approval in the host or server.

The third anti-pattern is modeling everything as a tool. Policies, schemas, runbooks, and reference docs should usually be resources. If the model needs the same policy across many tasks, a stable resource URI is easier to inspect, cache, and cite.

The fourth anti-pattern is modeling a workflow prompt as application code only. If the connector's domain expertise includes "how our legal team wants contract-risk summaries formatted," expose that as an MCP prompt. Then the prompt can evolve with the connector instead of being copied into every host application.

The fifth anti-pattern is treating MCP connection success as production readiness. A server can connect and still be unsafe, unobservable, over-broad, or impossible to debug. Later chapters cover logging, security, and approval gates because a connected connector is only the starting line.

<KnowledgeCheck
  questions={[
    {
      question: "Which MCP primitive is the best fit for `finance://policies/collections`?",
      answers: ["Tool", "Resource", "Prompt", "Transport"],
      correct: 1,
      explanation: "A stable policy URI is readable context, so it should be modeled as a resource."
    },
    {
      question: "Which design is safer for a production finance connector?",
      answers: [
        "query_database(sql)",
        "http_request(method, url, body)",
        "list_overdue_invoices(customer_id, max_age_days)",
        "run_shell(command)"
      ],
      correct: 2,
      explanation: "The domain-specific tool is narrower, easier to validate, and easier to audit."
    },
    {
      question: "In MCP, what is the host?",
      answers: [
        "The user-facing AI application",
        "The external capability server",
        "The input schema validator",
        "The transport name"
      ],
      correct: 0,
      explanation: "The host is the application the user interacts with, such as Claude Code."
    }
  ]}
/>

## Reading a Claude Code MCP configuration

Now connect the architecture to the command line.

Claude Code can add a local stdio server with a command shaped like this:

```sh
claude mcp add --transport stdio --env FINANCE_API_KEY=demo finance-demo -- node ./server.js
```

Read it from left to right:

- `claude mcp add` modifies Claude Code's MCP configuration.
- `--transport stdio` says Claude Code will start a local process and speak MCP over standard input/output.
- `--env FINANCE_API_KEY=demo` passes an environment variable to the server process.
- `finance-demo` is the server name inside Claude Code.
- `-- node ./server.js` is the command Claude Code runs as the server.

For a remote HTTP server, the shape changes:

```sh
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```

In that case, Claude Code does not start a local Node.js process. It connects to a remote endpoint over HTTP. If the server needs authentication, Claude Code supports headers and OAuth flows for remote servers.[^claude-code]

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Read this Claude Code MCP command and explain the host, server, transport, secret handling, and likely discovered capabilities: claude mcp add --transport stdio --env FINANCE_API_KEY=demo finance-demo -- node ./server.js"
  expectedOutput={`Host: Claude Code.
Server: the local process started by node ./server.js, registered under the name finance-demo.
Transport: stdio, because Claude Code communicates with the local process over standard input/output.
Secret handling: FINANCE_API_KEY=demo is passed to the server process as an environment variable. It should not be written into prompts, source control, or logs.
Likely discovered capabilities: whatever tools, resources, and prompts the finance-demo MCP server registers, such as invoice lookup tools, finance policy resources, or collection-email prompts.`}
/>

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="A team wants to share an MCP server config in a repository. The config points to https://api.example.com/mcp and needs an API key. Recommend a Claude Code scope and explain how to avoid committing the secret."
  expectedOutput={`Use project scope if the team intentionally wants the server configuration shared through the repository's .mcp.json file. Put the endpoint and non-secret structure in the config, but reference the API key through environment variable expansion or an authentication flow instead of committing the key. Each developer or CI environment should provide its own secret value outside source control.`}
/>

## Capability design checklist

Before you build your first server in Chapter 3, practice reviewing a server's advertised surface. For every capability, ask:

1. Is the name a business action or a raw technical primitive?
2. Does the description say when to use it and what it will not do?
3. Are inputs narrow enough to validate?
4. Is the operation read-only or state-changing?
5. If it reads context, should it be a resource instead?
6. If it encodes a repeatable workflow, should it be a prompt instead?
7. Where will detailed errors be logged?
8. What should Claude see when the server refuses a request?

Here is a practical rewrite exercise:

```text
Bad:
tool: http_request
input: { method, url, body }

Better:
tool: search_customer_invoices
input: { customer_id, status, max_results }

resource: finance://policies/invoice-collection

prompt: draft_invoice_followup
arguments: { customer_name, invoice_summary, policy_uri }
```

The better version gives the model enough flexibility to help while keeping control in the server. It also creates separate places for policy, workflow language, and business actions.

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Design an MCP surface for one workflow in your own work. Name one tool, one resource, and one prompt. For each, explain why that primitive fits."
    },
    {
      question: "Free-form: Take this unsafe tool, `query_database(sql)`, and rewrite it as one or two domain-specific tools for a support team. Include input fields."
    }
  ]}
/>

## Hands-on exercise: connect and inspect a sandbox MCP server

Your goal is to connect Claude Code to one existing MCP server in a sandbox environment and inspect what it advertises. Do not use a production system. Do not use a server with write access to real customer data.

Use any safe server you already trust, or create a temporary demo server from official SDK examples. The TypeScript SDK repository includes server examples and a minimal server pattern that registers a tool and connects over stdio.[^typescript-sdk] The exact server is less important than the inspection habit.

### Step 1: choose the server

Pick one of these:

- A local demo MCP server from the official TypeScript SDK examples.
- A read-only local server you wrote earlier.
- A remote server owned by a trusted vendor, connected with a non-production account.

Avoid:

- Servers that can delete files, send messages, change billing, or update customer records.
- Servers that ask you to paste secrets into prompts.
- Random packages you have not inspected.

### Step 2: add the server to Claude Code

For a local stdio server, the command shape is:

```sh
claude mcp add --transport stdio sandbox-demo -- node ./server.js
```

For a remote HTTP server, the command shape is:

```sh
claude mcp add --transport http sandbox-demo https://example.com/mcp
```

If credentials are required, prefer environment variables, OAuth, or a dedicated sandbox token. Claude Code's documentation includes commands for server listing, detail inspection, removal, and `/mcp` status checking.[^claude-code]

### Step 3: inspect capabilities

Run:

```sh
claude mcp list
claude mcp get sandbox-demo
```

Then open Claude Code's `/mcp` view and inspect the server status.

Write down:

- Server name.
- Transport.
- Scope.
- Command or URL.
- Any environment variables or headers involved.
- Advertised tools.
- Advertised resources.
- Advertised prompts.

### Step 4: classify and critique

For each advertised capability, classify it as tool, resource, or prompt. Then answer:

- Is the name domain-specific?
- Could the input schema allow over-broad access?
- Does any capability write state?
- Would you allow this server in a shared team project?

Success criteria:

- You can identify the host, client, server, and transport in your setup.
- You can list at least one advertised capability.
- You can classify each visible capability as a tool, resource, or prompt.
- You can explain where secrets are stored and which process or endpoint receives them.
- You can name one risk you would fix before using the server in production.

## Slide outline for Slide+Audio Producer

- Slide 1: Chapter goal: move from one-off function calls to reusable connector servers.
- Slide 2: MCP architecture: host, client, server, transport.
- Slide 3: Tools vs resources vs prompts, using accounts-receivable examples.
- Slide 4: Anti-patterns: raw executors, hidden writes, everything-as-tool.
- Slide 5: Claude Code configuration: stdio vs HTTP, scope, secrets.
- Slide 6: Hands-on workflow: connect, inspect, classify, critique.
- Slide 7: Bridge to Chapter 3: building the first safe file-browser MCP server.

## What's next

Chapter 3 turns this architecture into code. You will build a local MCP server with one narrow file-browsing tool, connect it through stdio, and practice returning controlled errors instead of leaking raw filesystem or stack-trace details.

[^architecture]: Model Context Protocol, "Architecture overview," https://modelcontextprotocol.io/docs/learn/architecture
[^tools]: Model Context Protocol specification, "Tools," https://modelcontextprotocol.io/specification/draft/server/tools
[^resources]: Model Context Protocol specification, "Resources," https://modelcontextprotocol.io/specification/draft/server/resources
[^prompts]: Model Context Protocol specification, "Prompts," https://modelcontextprotocol.io/specification/draft/server/prompts
[^typescript-sdk]: Model Context Protocol TypeScript SDK, https://github.com/modelcontextprotocol/typescript-sdk
[^claude-code]: Anthropic Claude Code docs, "Connect Claude Code to tools via MCP," https://code.claude.com/docs/en/mcp
