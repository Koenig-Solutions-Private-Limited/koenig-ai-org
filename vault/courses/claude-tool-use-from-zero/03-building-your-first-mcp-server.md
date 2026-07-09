---
chapter_num: 3
course_slug: claude-tool-use-from-zero
title: "Building Your First MCP Server"
status: draft-for-review
author: course-author
ticket: KOEA-2461
learning_objectives:
  - "Scaffold a minimal MCP server with one domain-specific tool"
  - "Define a narrow input schema for a filesystem browsing workflow"
  - "Return structured tool results and controlled errors"
  - "Explain why server-side root restriction is mandatory"
prerequisites_chapters:
  - 1
  - 2
duration_min: 60
level: Builder
vendor_tag: anthropic
sources:
  - https://github.com/modelcontextprotocol/typescript-sdk
  - https://modelcontextprotocol.io/
  - https://docs.anthropic.com/en/docs/claude-code/mcp
tags:
  - course/claude-tool-use-from-zero
  - mcp
  - typescript
  - server
quiz:
  - question: "What is the purpose of the `path.resolve` + `startsWith` check in the file-browser server?"
    options:
      - "It caches resolved paths to reduce file-system lookup latency on repeated directory requests"
      - "It prevents directory traversal attacks by rejecting any path that escapes the approved root"
      - "It converts all user-supplied relative paths to lowercase before passing them to readdir"
      - "It resolves symbolic links so the server can log the canonical destination path correctly"
    correct_idx: 1
    explanation: "path.resolve constructs an absolute path from the user-supplied relative input, and startsWith(root) verifies it stays inside the approved directory. Without this check, a caller could supply '../../etc/passwd' and escape the intended root. Caching, lowercasing, and symlink resolution are separate concerns."
    section_anchor: minimal-server-shape
  - question: "Why is a generic `read_file(path)` tool considered dangerous in an MCP server?"
    options:
      - "It requires too many input parameters for Claude to fill correctly in a single turn"
      - "It exposes every file the server process can read, including secrets and credentials"
      - "It forces the host to validate all MIME types before returning any binary file content"
      - "It creates excessive round-trip latency when reading files larger than ten kilobytes"
    correct_idx: 1
    explanation: "read_file(path) with no root restriction lets Claude — or a prompt injection attack — request .env files, SSH keys, browser profiles, or system files. The server process often has broader filesystem access than intended. Separating list from read and fixing the allowed root is the correct defense."
    section_anchor: why-this-is-safer-than-read_filepath
  - question: "In the chapter's file-browser design, who enforces the rule that certain paths are off-limits?"
    options:
      - "Claude, based on the tool description and the instructions in the model's system prompt"
      - "The host application, by filtering the tool_use blocks before they reach the MCP server"
      - "The server, by enforcing a root restriction in code that the model cannot override"
      - "The MCP protocol layer, which automatically blocks path traversal sequences in tool arguments"
    correct_idx: 2
    explanation: "The server enforces the boundary in code. Claude may helpfully avoid sensitive paths, but prompt instructions are not a security control. The host can validate requests, but server-side enforcement is what guarantees the boundary. The MCP protocol itself has no path-traversal guard."
    section_anchor: what-the-server-will-do
---

# Building Your First MCP Server

Now you will build the first reusable connector in this course: a local MCP server that exposes a safe file-browsing tool. The point is not to create a full file manager. The point is to practice the server shape: define a capability, constrain inputs, execute domain code, and return useful results.

The official TypeScript SDK includes server libraries for tools, resources, prompts, transports, and examples.[^1] This chapter uses TypeScript-style examples because the SDK's minimal `McpServer` shape is compact and maps cleanly to production servers. The same design ideas apply in Python.

## Prerequisites check

You should have completed the MCP classification exercise from Chapter 2. You should also be comfortable running a Node.js script locally. If your environment cannot run TypeScript directly, use plain JavaScript or follow the SDK quickstart from the official repository.[^1]

## What the server will do

The server exposes one tool:

```text
list_project_files(root_label, relative_path)
```

It lists files under a pre-approved project root. The user can ask Claude to inspect project structure, but the server will not allow arbitrary filesystem traversal.

```takeaways
- The server enforces the security boundary; the model never decides which paths are off-limits.
- Starting with a list-only tool (no file-content access) is the correct first step for filesystem connectors.
- The `root_label` enum approach prevents arbitrary path construction at the input-schema level before any validation code runs.
```

This is the key production lesson: the model should not decide the security boundary. The server decides the boundary, then offers Claude a useful operation inside it.

## Minimal server shape

An MCP server has identity, registered capabilities, and a transport. The SDK README shows a minimal server that registers a `greet` tool and connects over stdio.[^1] Your file browser follows the same shape, but with stricter validation.

```takeaways
- Every MCP server needs three things: an identity object, registered capabilities, and a connected transport.
- `path.resolve` plus a `startsWith` check is the minimal server-side path-escape guard; omitting it means any caller can traverse to arbitrary directories.
- The `StdioServerTransport` connects the server to the host via standard input/output, which is appropriate for local processes started by a host like Claude Code.
```

```ts
import { McpServer } from "@modelcontextprotocol/server";
import { StdioServerTransport } from "@modelcontextprotocol/server/stdio";
import * as z from "zod/v4";
import { readdir } from "node:fs/promises";
import path from "node:path";

const ROOTS = {
  demo: path.resolve(process.cwd(), "demo-project")
};

const server = new McpServer({ name: "course-file-browser", version: "1.0.0" });

server.registerTool(
  "list_project_files",
  {
    description: "List files inside an approved demo project root. Does not read file contents.",
    inputSchema: z.object({
      root_label: z.enum(["demo"]),
      relative_path: z.string().default(".")
    })
  },
  async ({ root_label, relative_path }) => {
    const root = ROOTS[root_label];
    const target = path.resolve(root, relative_path);

    if (!target.startsWith(root)) {
      throw new Error("Path escapes approved root");
    }

    const entries = await readdir(target, { withFileTypes: true });
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            entries.map((entry) => ({
              name: entry.name,
              type: entry.isDirectory() ? "directory" : "file"
            })),
            null,
            2
          )
        }
      ]
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

## Why this is safer than `read_file(path)`

A raw `read_file(path)` tool looks convenient. It is also an invitation to leak secrets. The model might request `.env`, SSH keys, browser profiles, or system files because the prompt says "inspect the project." A safer server starts with a narrow list operation, a fixed root, and no file-content access.

```takeaways
- A generic `read_file(path)` tool exposes every file the server process can read, including secrets and credentials.
- Relying on "Claude will know not to ask for secrets" is not a security control — enforcement must be in server code.
- Separating listing from content-reading into distinct tools makes it possible to permit one without the other.
```

<Callout type="warning">
Never rely on "Claude will know not to ask for secrets." A connector must enforce policy in code. The model can be helpful, but the server is responsible for security boundaries.
</Callout>

## Controlled errors

Errors are part of the user experience. A stack trace is useful to an attacker and confusing to a learner. A controlled error says what failed and what the caller can do next.

```takeaways
- Returning a raw stack trace leaks implementation details that help attackers and confuse end users.
- Controlled errors should classify the failure (unknown root, path escape, not readable) without revealing host filesystem layout.
- Log the full exception server-side and return only the minimal useful message to the model.
```

For this chapter, use three predictable errors:

- Unknown root label.
- Path escapes approved root.
- Path does not exist or is not readable.

In production, log the detailed exception server-side and return the minimal useful error to Claude.

<RunPromptCell
  model="claude-sonnet-4-6"
  tools={["course-file-browser"]}
  prompt="Use the file browser tool to list the top-level files in the demo project. Do not read file contents."
  expectedOutput={`Claude should call:

list_project_files({
  "root_label": "demo",
  "relative_path": "."
})

Expected result:
[
  {"name":"package.json","type":"file"},
  {"name":"src","type":"directory"},
  {"name":"README.md","type":"file"}
]

Claude should summarize the project structure without inventing file contents.`}
/>

<RunPromptCell
  model="claude-sonnet-4-6"
  tools={["course-file-browser"]}
  prompt="Try to list ../ so I can see what is outside the demo project."
  expectedOutput={`The server should reject the request with a controlled error such as:

Path escapes approved root.

Claude should explain that the connector is restricted to the approved demo project root and ask for a path inside that root.`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Where should the approved filesystem root be enforced?",
      answers: [
        "Only in the prompt",
        "Only in Claude's reasoning",
        "In the MCP server code before filesystem access",
        "In the README"
      ],
      correct: 2,
      explanation: "The server must enforce the root because it owns the actual filesystem access."
    }
  ]}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Rewrite a dangerous generic tool named read_any_file(path) into a safer domain-specific MCP tool."
    }
  ]}
/>

## Hands-on exercise

Create a local MCP server named `course-file-browser` with one `list_project_files` tool.

Success criteria:

- The server starts over stdio.
- The tool lists files under one approved demo directory.
- `../` traversal is rejected.
- The tool returns names and types, not file contents.
- You can connect Claude Code to the server using its MCP configuration flow.[^3]

## What's next

Chapter 4 expands the server from callable tools to resources: structured context Claude can read without treating every retrieval as an action.

[^1]: Model Context Protocol TypeScript SDK, https://github.com/modelcontextprotocol/typescript-sdk
[^2]: Model Context Protocol documentation, https://modelcontextprotocol.io/
[^3]: Anthropic, "Connect Claude Code to tools via MCP", https://docs.anthropic.com/en/docs/claude-code/mcp
