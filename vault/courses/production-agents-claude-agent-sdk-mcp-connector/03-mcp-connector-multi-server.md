---
course_slug: production-agents-claude-agent-sdk-mcp-connector
chapter_num: 3
chapter_slug: mcp-connector-multi-server
title: "MCP connector: orchestrating multi-server agents"
description: "Configure multi-server MCP tool access in the Claude Agent SDK while controlling transport choices, permission grants, and startup failures."
tags: [mcp, tool-permissions, multi-server-agents]
faq:
  - q: "How are MCP tools named in the Agent SDK?"
    a: "They use the mcp__server-name__tool-name pattern, which is also what you grant in allowedTools."
  - q: "Does acceptEdits approve MCP calls?"
    a: "No. acceptEdits covers file edits; MCP tools still need explicit allowedTools grants."
  - q: "Which MCP transport should I use first?"
    a: "Use stdio for local server processes, HTTP for stateless remote APIs, and SSE when the server needs streaming."
status: g3-passed
last_updated: 2026-06-14
author: vardaan-koenig
agent_drafted_by: course-author
date: 2026-04-30
duration_min: 50
prerequisites_chapters: [1]
learning_objectives:
  - "Configure stdio, HTTP, and SSE MCP servers in a single query() call"
  - "Scope MCP tool access with allowedTools wildcards and per-tool grants"
  - "Detect and handle server connection failures via the system init message"
  - "Explain why permissionMode acceptEdits is NOT sufficient for MCP tool approval"
key_concepts:
  [mcp-tool-naming, mcpServers, transport-types, mcp-json, tool-search, oauth2-headers, connection-timeout]
hands_on_exercise: "Wire a GitHub MCP server (stdio) and a Postgres MCP server (stdio) and a cloud docs server (HTTP) into one agent that pulls an issue, queries a related DB table, and writes a summary"
sources:
  - https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-mcp
  - https://modelcontextprotocol.io/docs/getting-started/intro
  - https://platform.claude.com/docs/en/agent-sdk/overview
  - https://github.com/modelcontextprotocol/servers
  - https://claude.com/blog/agent-capabilities-api
  - https://modelcontextprotocol.io/specification/2025-03-26/basic/authorization
---

# MCP connector: orchestrating multi-server agents

The MCP connector in the Claude Agent SDK attaches external tool servers — databases, APIs, browsers — to an agent at runtime. Three transport modes (stdio, HTTP, SSE) handle connection management, tool discovery, and error signaling automatically [1]. For a breakdown of which community servers teams are actually deploying, see [[blogs/2026-05-31-mcp-server-adoption-2026|MCP server adoption 2026]].

## Key facts

1. MCP tools are named `mcp__<server-name>__<tool-name>` — e.g., server `"github"` + tool `list_issues` = `mcp__github__list_issues` [1].
2. MCP tools need explicit `allowedTools` grants; `permissionMode: "acceptEdits"` does NOT cover MCP [1].
3. stdio: local process; HTTP: stateless remote; SSE: streaming remote. Default stdio timeout: 60 seconds [1].
4. Tool search is enabled by default — withholds tool definitions from context and loads only what's needed per turn [1].

## The MCP naming convention

Given `mcpServers` key `"github"`, every tool is prefixed `mcp__github__`. Example:

```
mcp__github__list_issues
mcp__github__search_issues
mcp__github__create_issue
mcp__github__get_pull_request
```

`mcp__github__*` allows all tools from the server; `mcp__github__list_issues` allows only that one.

```takeaways
- MCP tools follow the naming pattern `mcp__<server-name>__<tool-name>` where the server name is the key used in `mcpServers`, not the package name.
- Use `mcp__<server>__*` wildcards during development; narrow to specific tool names in production to minimize blast radius.
- All MCP tools require explicit `allowedTools` grants — `permissionMode: "acceptEdits"` does not auto-approve MCP tool calls.
```

## The three transport types

### stdio — local process servers

stdio is the most common transport for development and for community-published servers on npm or PyPI. The SDK spawns a child process and communicates over stdin/stdout.

```python
from claude_agent_sdk import query, ClaudeAgentOptions

options = ClaudeAgentOptions(
    mcp_servers={
        "github": {
            "command": "npx",
            "args": ["-y", "@modelcontextprotocol/server-github"],
            "env": {"GITHUB_TOKEN": "ghp_xxxxxxxxxxxx"},
        }
    },
    allowed_tools=["mcp__github__list_issues", "mcp__github__search_issues"],
)

async for message in query(
    prompt="List the 5 most recent open issues in anthropics/claude-code",
    options=options,
):
    if hasattr(message, "result"):
        print(message.result)
```

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "List the 5 most recent open issues in anthropics/claude-code",
  options: {
    mcpServers: {
      github: {
        command: "npx",
        args: ["-y", "@modelcontextprotocol/server-github"],
        env: { GITHUB_TOKEN: process.env.GITHUB_TOKEN }
      }
    },
    allowedTools: ["mcp__github__list_issues", "mcp__github__search_issues"]
  }
})) {
  if (message.type === "result" && message.subtype === "success") {
    console.log(message.result);
  }
}
```

<Callout type="warn">
Never hard-code secrets in the `env` field. The values shown above are illustrative. Use `process.env.GITHUB_TOKEN` (TypeScript) or `os.environ["GITHUB_TOKEN"]` (Python) to pull from environment variables. The `.mcp.json` config file syntax uses `${GITHUB_TOKEN}` for shell-style expansion.
</Callout>

### HTTP — stateless remote servers

Use HTTP for cloud-hosted servers that expose a standard MCP endpoint. No child process, no local installation required:

```python
options = ClaudeAgentOptions(
    mcp_servers={
        "claude-code-docs": {
            "type": "http",
            "url": "https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-mcp",
        }
    },
    allowed_tools=["mcp__claude-code-docs__*"],
)
```

```typescript
options = {
  mcpServers: {
    "remote-api": {
      type: "http",
      url: "https://api.yourcompany.com/mcp",
      headers: {
        Authorization: `Bearer ${process.env.API_TOKEN}`
      }
    }
  },
  allowedTools: ["mcp__remote-api__*"]
}
```

### SSE — streaming remote servers

SSE is the right transport when the remote server needs to push events as it processes (e.g., long-running queries, real-time data feeds):

```python
options = ClaudeAgentOptions(
    mcp_servers={
        "analytics-stream": {
            "type": "sse",
            "url": "https://analytics.yourcompany.com/mcp/sse",
            "headers": {"Authorization": f"Bearer {os.environ['ANALYTICS_TOKEN']}"},
        }
    },
    allowed_tools=["mcp__analytics-stream__*"],
)
```

The SDK transparently handles SSE reconnection — you don't need to manage the event stream yourself.

## Orchestrating three servers in one agent

Multiple servers with different transports go in one `mcpServers` dict:

```python
import asyncio
import os
from claude_agent_sdk import (
    query, ClaudeAgentOptions,
    SystemMessage, ResultMessage, AssistantMessage
)

async def investigate_issue(issue_ref: str, db_connection: str):
    """Pull a GitHub issue, query related DB records, write a summary."""
    options = ClaudeAgentOptions(
        mcp_servers={
            # stdio: GitHub MCP server
            "github": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-github"],
                "env": {"GITHUB_TOKEN": os.environ["GITHUB_TOKEN"]},
            },
            # stdio: Postgres MCP server
            "postgres": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-postgres", db_connection],
            },
            # HTTP: Cloud docs server
            "docs": {
                "type": "http",
                "url": "https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-mcp",
            },
        },
        allowed_tools=[
            "mcp__github__get_issue",
            "mcp__github__list_comments",
            "mcp__postgres__query",        # read-only
            "mcp__docs__*",                # all doc tools
        ],
    )

    prompt = (
        f"1. Fetch the GitHub issue at {issue_ref}. "
        "2. Query the postgres DB for any records mentioning the issue number. "
        "3. Look up relevant documentation from the docs server. "
        "4. Write a one-paragraph summary of what the issue is about and whether the DB has related data."
    )

    async for message in query(prompt=prompt, options=options):
        # Verify all three servers connected on the first message
        if isinstance(message, SystemMessage) and message.subtype == "init":
            servers = message.data.get("mcp_servers", [])
            for server in servers:
                status = server.get("status")
                name = server.get("name")
                if status != "connected":
                    print(f"WARNING: {name} failed to connect — {server}")
        
        # Show which MCP tools are being called
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if hasattr(block, "name") and block.name.startswith("mcp__"):
                    print(f"[MCP call: {block.name}]")
        
        if isinstance(message, ResultMessage) and message.subtype == "success":
            print(message.result)

asyncio.run(investigate_issue(
    issue_ref="anthropics/claude-code#1234",
    db_connection=os.environ["DATABASE_URL"],
))
```

```takeaways
- Multiple MCP servers with different transport types (stdio, HTTP, SSE) can be configured in a single `mcpServers` dict; the agent uses whichever tools match the task.
- Check the `mcp_servers` list in the `SystemMessage` init event before the agent starts work to catch connection failures before tokens are wasted.
- Never hard-code secrets in `mcpServers.env` — use `os.environ["KEY"]` or `process.env.KEY` to pull credentials from environment variables.
```

## Why `permissionMode: "acceptEdits"` is not enough

The Agent SDK has three permission modes:

| Mode | What it auto-approves | Auto-approves MCP? |
|---|---|---|
| `default` | Nothing — every tool call prompts for approval | No |
| `acceptEdits` | File edit and filesystem Bash commands | **No** |
| `bypassPermissions` | Everything including MCP | Yes (but dangerous) |

`acceptEdits` does not cover MCP. The agent sees the tools but refuses to call them without explicit grants:

```python
# WRONG — permissionMode doesn't cover MCP
options = ClaudeAgentOptions(
    permission_mode="acceptEdits",
    mcp_servers={"github": github_config},
)

# RIGHT — explicit allowedTools grants MCP access
options = ClaudeAgentOptions(
    permission_mode="acceptEdits",  # for file ops
    mcp_servers={"github": github_config},
    allowed_tools=["mcp__github__*"],  # for MCP ops
)
```

`bypassPermissions` disables all safety checks — do not use it to work around missing `allowedTools`. The complete production-safe permission model — combining `allowedTools`, `permissionMode`, and cost circuit breakers — is detailed in [[course/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability|Chapter 5]].

## Detecting connection failures

The `SystemMessage` with subtype `init` arrives before the agent does any work. Check its `mcp_servers` list — servers fail silently otherwise:

```python
async for message in query(prompt=..., options=options):
    if isinstance(message, SystemMessage) and message.subtype == "init":
        failed = [
            s for s in message.data.get("mcp_servers", [])
            if s.get("status") != "connected"
        ]
        if failed:
            # Abort or handle gracefully before the agent wastes tokens
            raise RuntimeError(f"MCP servers failed to connect: {failed}")
```

```typescript
for await (const message of query({ prompt, options })) {
  if (message.type === "system" && message.subtype === "init") {
    const failed = message.mcp_servers.filter(s => s.status !== "connected");
    if (failed.length > 0) {
      throw new Error(`MCP servers failed: ${JSON.stringify(failed)}`);
    }
  }
}
```

Common failure causes by transport:

- **stdio**: `npx` not on PATH, package not published, missing `env` vars
- **HTTP**: URL unreachable, invalid SSL certificate, wrong endpoint path
- **SSE**: CORS headers missing on the server, auth token expired

Pre-warm slow stdio servers before querying to avoid the 60-second connection timeout.

```takeaways
- Check the `mcp_servers` list in the `SystemMessage` init event before the agent does any work — servers fail silently if you don't inspect this event.
- The three most common stdio failure causes are: `npx` not on PATH, missing environment variables, and servers that take longer than 60 seconds to start.
- Pre-warm slow server processes before starting a query to avoid the default 60-second connection timeout.
```

## Project-level config with `.mcp.json`

Put shared servers in `.mcp.json` at the project root — the SDK loads it automatically:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"]
    }
  }
}
```

`${VAR}` expands environment variables at load time — credentials stay out of code.

## Tool search for large tool sets

Tool search is enabled by default: the SDK withholds all tool definitions from context and loads only those relevant to each turn via vector similarity search. With 200 tools across servers, this prevents context exhaustion before any work begins. Disable per-server via `mcpServers` config if a server's tools always need to be in context.

```takeaways
- Tool search is enabled by default; it withholds all tool definitions from context and loads only tools relevant to each turn using vector similarity search.
- Without tool search, a system with 200 MCP tools sends every definition to Claude on every turn, consuming large amounts of context window before any work begins.
- Project-level `.mcp.json` files keep MCP config declarative and version-controllable; use `${VAR}` syntax for environment variable expansion.
```

## Hands-on exercise

**Wire GitHub (stdio) + Postgres (stdio) + Claude Code docs (HTTP) into one agent.**

Setup: `GITHUB_TOKEN` (repo:read), `DATABASE_URL` (any Postgres instance).

Prompt: "Get the README from anthropics/claude-code. Check for an 'issues' table in postgres. Look up 'hooks' in the docs. Write a three-sentence summary."

**Verify**: init shows all 3 servers connected; at least 2 different `mcp__*` tool calls appear. **Est. time**: 25 min

<KnowledgeCheck
  question="Your agent is configured with `permissionMode: 'acceptEdits'` and an MCP server named `db`. You've added the server to `mcpServers` but NOT listed any MCP tools in `allowedTools`. What happens when Claude tries to call `mcp__db__query`?"
  options={[
    "The tool call is blocked — MCP tools require explicit allowedTools grants regardless of permissionMode",
    "The tool call succeeds — acceptEdits covers all tool types including MCP",
    "The tool call prompts the user for approval",
    "The tool call succeeds but only for read operations"
  ]}
  correctIdx={0}
  explanation="MCP tools require explicit `allowedTools` grants. `permissionMode: 'acceptEdits'` covers only file edits and filesystem Bash commands — it does not extend to MCP servers. To allow all tools from the db server, add `mcp__db__*` to `allowedTools`. The only permission mode that auto-approves MCP is `bypassPermissions`, which also disables all other safety checks."
/>

<KnowledgeCheck
  question="You're building an agent that uses four MCP servers with a combined total of 200 tools. You notice that context window usage is high even before the agent has called any tools. What feature should you check and what does it do?"
  options={["self-check"]}
  correctIdx={0}
  explanation="Self-check: Tool search. When enabled (the default), the SDK withholds all MCP tool definitions from the context window and loads only the tools relevant to each turn using vector similarity search over tool names and descriptions. If tool search is disabled or misconfigured, all 200 tool definitions appear in context on every turn. Verify it's enabled by checking your agent SDK configuration per the tool search docs at code.claude.com/docs/en/agent-sdk/tool-search."
/>

## What's next

[[course/production-agents-claude-agent-sdk-mcp-connector/04-files-api-code-execution|Chapter 4]] covers the Files API and code execution tool — upload documents once, reference by `file_id`, generate and download chart output.

## References

[1] Agent SDK MCP Connector — https://code.claude.com/docs/en/sdk/sdk-mcp · retrieved 2026-06-14
[2] Model Context Protocol specification — https://modelcontextprotocol.io/docs/getting-started/intro · retrieved 2026-04-30
[3] MCP server registry — https://github.com/modelcontextprotocol/servers · retrieved 2026-04-30
[4] Claude Agent SDK Overview — https://code.claude.com/docs/en/agent-sdk/overview · retrieved 2026-04-30
[5] Agent Capabilities API announcement — https://claude.com/blog/agent-capabilities-api · retrieved 2026-04-30
[6] MCP OAuth 2.1 specification — https://modelcontextprotocol.io/specification/2025-03-26/basic/authorization · retrieved 2026-04-30
