---
chapter_num: 6
course_slug: production-agents-claude-agent-sdk-mcp-connector
title: "Cross-CLI Context Persistence"
description: "Learn how to persist context across Claude Code, Codex CLI, and Agent SDK sessions using JSONL relays, the Files API, and MCP context brokers — eliminating the cross-CLI context gap in multi-agent pipelines."
chapter_slug: "cross-cli-context-persistence"
status: g3-passed
author: content-author
duration_min: 50
vendor_tag: anthropic
tags: [claude-agent-sdk, context-persistence, multi-agent, JSONL, Files-API, MCP]
learning_objectives:
  - "Identify the four layers of CLI context that must survive a cross-agent handoff"
  - "Implement a JSONL-based context relay that works across Claude Code, Codex CLI, and Agent SDK scripts"
  - "Use the Claude Agent SDK Files API to store session context durably between invocations"
  - "Wire an MCP server as a shared context broker for multi-agent pipelines"
  - "Recognise and avoid the five most common cross-CLI context anti-patterns"
sources:
  - url: "https://code.claude.com/docs/en/agent-sdk/overview"
    title: "Claude Agent SDK Overview"
    retrieved: "2026-06-15"
  - url: "https://platform.claude.com/docs/en/build-with-claude/files"
    title: "Files API"
    retrieved: "2026-06-15"
  - url: "https://code.claude.com/docs/en/agent-sdk/mcp"
    title: "MCP Connector"
    retrieved: "2026-06-15"
  - url: "https://code.claude.com/docs/en/agent-sdk/sessions"
    title: "Claude Agent SDK — Session Continuity"
    retrieved: "2026-06-15"
  - url: "https://code.claude.com/docs/en/agent-sdk/hooks"
    title: "Claude Agent SDK — Hooks"
    retrieved: "2026-06-15"
  - url: "https://jsonlines.org/"
    title: "JSONL (JSON Lines) Format Specification"
    retrieved: "2026-06-15"
faq:
  - q: "How do I share context between Claude Code and a Codex CLI agent?"
    a: "The most portable method is a JSONL relay file — each agent appends typed context events (decisions, tool outputs, file references, metadata) to `.agent-context/session.jsonl`. Codex CLI loads the file at startup via `--system-prompt \"$(python load_context_summary.py)\"`, injecting a distilled summary of prior decisions and confirmed outputs without passing the full conversation log. See the [Agent SDK hooks docs](https://code.claude.com/docs/en/agent-sdk/hooks) for automating writes from Claude Code's PostToolUse hook."
  - q: "When should I use session IDs vs the Files API for context persistence?"
    a: "Use session IDs for intra-SDK continuity — resuming the same `@anthropic-ai/claude-agent-sdk` `query()` call across process restarts while staying on the same CLI surface. Use the [Files API](https://platform.claude.com/docs/en/build-with-claude/files) when context must outlive the agent runtime, cross a CLI boundary, or be referenced by multiple downstream agents. Files API context snapshots are stable by `file_id`, require no re-injection of raw text, and survive indefinitely until explicitly deleted."
  - q: "What are the most common cross-CLI context anti-patterns to avoid?"
    a: "The five most common anti-patterns are: (1) injecting full conversation history into every new session — distil decisions instead; (2) using git as a context transport — context files belong in `.gitignore`; (3) relying on environment variables — they vanish at shell exit; (4) mixing all context types in a flat undifferentiated blob — type your events from day one; and (5) omitting a `schema_version` field — without it you cannot safely evolve the schema when tool names or model conventions change (see the [JSONL spec](https://jsonlines.org/) for schema evolution patterns). See the Anti-Patterns section for full detail."
positions:
  - id: "cli-first-workflows-for-production-teams"
    engagement: "defends"
  - id: "mcp-as-interoperability-moat"
    engagement: "defends"
quiz:
  - question: "Which of the four context layers is most expensive to reconstruct if not captured before a session ends?"
    options:
      - "Conversation history — the full message log is large but straightforward to regenerate with the same prompt"
      - "Tool execution outputs — re-running pipelines, API calls, and long analyses can cost hours of compute"
      - "Session metadata — working directory, branch state, and environment variables are the hardest to recover"
      - "File references — `file_id` values from the Files API expire quickly and must be captured at upload time"
    correct_idx: 1
    explanation: "Tool execution outputs are the most expensive to reconstruct: a 10-minute data pipeline, five external API calls, or a processed 50-page PDF can't be cheaply re-run just to recover context. Conversation history can be distilled; file references are lightweight; session metadata is usually cheap to re-establish."
    section_anchor: anatomy-of-cli-context
  - question: "Why is JSONL the preferred format for a cross-CLI context relay file over standard JSON?"
    options:
      - "JSONL files compress better than JSON objects, reducing storage overhead for large context payloads"
      - "JSONL allows append-friendly writes and streaming reads without loading the entire file into memory"
      - "JSONL is the only format Claude Code's PostToolUse hook natively serializes context events into"
      - "JSONL provides built-in schema validation that catches malformed context events at write time"
    correct_idx: 1
    explanation: "JSONL (JSON Lines) writes one JSON object per line, enabling append-only writes with no file locking and streaming reads without loading the whole file. It also creates a natural audit trail of how context evolved across sessions. Standard JSON requires reading the full file to append a record."
    section_anchor: file-based-context-the-universal-bridge
  - question: "When should you use the Files API for context persistence instead of Agent SDK session IDs?"
    options:
      - "When resuming the same `query()` call within the same process after a brief network interruption"
      - "When context must outlive the agent runtime, cross a CLI boundary, or be shared across multiple agents"
      - "When the accumulated context size exceeds the JSONL relay file's practical storage capacity limit"
      - "When a Claude Code session ID must be forwarded directly into a running Codex CLI process"
    correct_idx: 1
    explanation: "Session IDs are for intra-SDK continuity within one CLI surface. The Files API is the right layer when context must survive process exit, be consumed by a different CLI (Codex, Gemini, raw API), or be referenced by multiple downstream agents in a pipeline. Files API context is stable by `file_id` and survives indefinitely."
    section_anchor: the-files-api-as-a-durable-context-layer
  - question: "Which cross-CLI anti-pattern is most insidious because the context loss is invisible until the next agent starts?"
    options:
      - "Injecting full conversation history — the window bloats but the downstream agent still receives valid context"
      - "Using git commits as context transport — historical context is preserved but mixed with code change history"
      - "Omitting `schema_version` — the relay file still works initially but breaks when the event schema evolves"
      - "Relying on environment variables for context — they vanish silently when the originating shell exits"
    correct_idx: 3
    explanation: "Environment variables look like a lightweight context mechanism but vanish silently at shell exit — the next agent starts with no error and no context, often producing subtly wrong output rather than an explicit failure. Git transport preserves data but pollutes history. Full conversation injection is wasteful but works."
    section_anchor: anti-patterns-and-pitfalls
---

# Cross-CLI Context Persistence

When a developer shifts from Claude Code to a Codex CLI subtask, or hands a long-running analysis off to a specialised [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) script, something predictable happens: context evaporates. Not the files — those are on disk. Not the code — that is in git. What disappears is the cognitive state that accumulated in the previous session: decisions made, tools already run, intermediate results computed, and the implicit understanding of what was tried and why it was rejected.

In a single-agent workflow this is handled automatically. The conversation window carries every tool call and every result forward. But the moment you introduce a second agent — even one running the same model — you are starting from zero unless you designed the handoff deliberately. The second agent has no knowledge of the context window the first agent held. It cannot see the tool calls that shaped the prior session's output. It does not know what was rejected and why.

This is not a theoretical concern. Real multi-CLI workflows fail in exactly this way: the second agent proposes the architecture the first agent already rejected in the third turn, re-runs the data pipeline that took 15 minutes the first time, or diverges onto a different branch because it did not know which file was the active one. The result is duplicated compute, inconsistent outputs, and frustrated developers who assumed the agents were "working together."

This chapter is about designing the handoff that prevents those failures. You will learn to identify the four layers of context that matter across CLI agents, to implement a file-based relay that works with any two CLIs, to use the [[Files-API]] for durable multi-session context, and to expose context through [[MCP]] so any downstream agent can query it selectively. By the end you will have a concrete pattern that scales from a two-agent workflow to a full multi-CLI pipeline.

## The Context Gap No One Tells You About

The illusion of seamless multi-agent context comes from watching demos where every agent is pre-loaded with the same carefully crafted system prompt. Real workflows are not like that. Agents are spun up at different times for different sub-problems, each one carrying only what it was explicitly given at startup. The gap between "what the first agent knew" and "what the second agent starts with" is the cross-CLI context gap, and it is wider than most practitioners expect.

Three things make this gap worse than it looks on the surface. First, most context is implicit. The first agent never bothered to write down that it rejected SQLite in favour of PostgreSQL because of write concurrency, because that decision felt obvious in the moment. It knew — but it never said so aloud in a way that could be captured. Second, tool outputs are transient. The first agent ran a 10-minute analysis pipeline and the results lived in its context window. When that window closes, those results are gone. No other agent has access to them without re-running the work. Third, the agents do not share a session namespace. Claude Code's session IDs are meaningful only within Claude Code's runtime. A Codex CLI process does not know what they mean. A raw Anthropic API call does not know what they mean. Each CLI manages its own session space, and those spaces do not overlap.

The solution is not to build a distributed context store from day one. The solution is discipline: explicitly capture what matters, in a format that any subsequent agent can consume, before the current session ends. This means treating context handoff as a first-class concern in your workflow design — not an afterthought.

## Anatomy of CLI Context

Not all context deserves equal treatment. Before you can design a persistence strategy you need to know what you are persisting and how costly it is to reconstruct each type. Context in a CLI agent workflow falls into four layers with different persistence costs, reconstruction costs, and relevance half-lives.

**Conversation history** is the literal message log — the back-and-forth between user and assistant. It is cheap to persist (plain JSON) and cheap to re-inject (just tokens). It is also the largest layer by volume and the one with the shortest relevance half-life. Most of a conversation is scaffolding, clarification, and dead-end exploration that is irrelevant to the downstream agent. The useful subset is usually small: final decisions, blocking constraints, key findings. Never pass the full conversation log forward. Distil it to the decisions and facts that the downstream agent actually needs to do its job.

**Tool execution outputs** are the results of tool calls made during the session — file contents read, API responses received, computation outputs generated, search results returned, data analysis completed. These are the most expensive layer to reconstruct. If the prior agent ran a 10-minute data pipeline, called five external APIs, and processed a 50-page PDF, re-running all of that to re-establish context is not acceptable in a production workflow. Tool outputs must be captured explicitly and passed forward as ground truth. They should be treated as immutable facts that the downstream agent can trust without needing to verify.

**File and resource references** are the handles to persistent state: file paths, `file_id` values from the Files API, database record IDs, git commit hashes, versioned artefact identifiers. These are lightweight to persist but critical to carry forward accurately. A second agent that does not know which `file_id` represents the uploaded dataset, or which branch was active, or which specific version of a schema file was in play, will immediately diverge from the established work. Even a small drift in file references compounds into large inconsistencies when multiple tool calls chain off the same reference.

**Session metadata** covers the active working directory, git branch, environment variable states, model settings, MCP server connection status, total cost spent so far in the pipeline, and any feature flags or configuration active during the prior session. This layer is often overlooked, but it causes some of the most subtle failures. A second agent that starts with the wrong working directory will write to the wrong location. An agent that does not know the first agent already established a particular MCP server connection may attempt to reconnect and receive a conflict error. An agent unaware of the cost already spent may proceed with expensive operations that push the total past the intended budget cap.

The practical rule for most workflows: you need a precise summary of layer 2 (tool outputs), a compact distillation of layer 1 (decisions, not full conversation), and the complete layer 3 and 4. Design your persistence strategy around that shape. Completeness for layers 3 and 4 is cheap and critical. Selective distillation for layers 1 and 2 is cheap and necessary. Passing layers 1 and 2 in full is expensive and counterproductive.

## File-Based Context: The Universal Bridge

The simplest cross-CLI persistence mechanism is a shared file. Every CLI agent can read and write files. No API integration required, no shared service, no network dependency. A well-structured context file on disk is the lowest-friction handoff that works with every CLI in the ecosystem.

The format that performs best in practice is [[JSONL]] ([JSON Lines](https://jsonlines.org/)) — one JSON object per line, each representing a discrete context event. This gives you append-friendly writes without file locking, easy streaming reads without loading the entire file, and a natural audit trail of how context evolved across agents and sessions. When something goes wrong in a multi-agent pipeline, the JSONL file is where you look to understand the state each agent inherited.

The schema matters. A flat list of key-value pairs is not enough — you need typed events so downstream agents can selectively load only the context relevant to their task. A minimal event schema that covers the four layers looks like this:

```python
# context_writer.py — append context events from any agent session
import json
import time
from pathlib import Path
from typing import Any

CONTEXT_FILE = Path(".agent-context/session.jsonl")

def write_context_event(event_type: str, payload: dict[str, Any], agent: str = "unknown") -> None:
    """Append a typed context event to the shared JSONL relay file."""
    CONTEXT_FILE.parent.mkdir(exist_ok=True)
    event = {
        "ts": time.time(),
        "schema_version": 1,
        "type": event_type,   # "decision" | "tool_output" | "file_ref" | "metadata"
        "agent": agent,       # which CLI or script wrote this event
        "payload": payload,
    }
    with CONTEXT_FILE.open("a") as f:
        f.write(json.dumps(event) + "\n")

# Called from a PostToolUse hook after a significant bash execution:
# write_context_event("tool_output", {
#     "key": "schema_analysis",
#     "tool": "bash",
#     "output": "Three N+1 query patterns found at lines 47, 89, 134.",
# }, agent="claude-code")
#
# Called when the agent reaches a firm decision worth carrying forward:
# write_context_event("decision", {
#     "summary": "PostgreSQL over SQLite — multi-user write load",
#     "reasoning": "SQLite WAL mode cannot handle 50+ concurrent writers under our target load",
# }, agent="claude-code")
#
# Called when a significant file reference is established:
# write_context_event("file_ref", {
#     "path": "src/db/schema.sql",
#     "role": "active_schema",
#     "git_sha": "abc1234",
# }, agent="claude-code")
```

Claude Code's [PostToolUse hooks](https://code.claude.com/docs/en/agent-sdk/hooks) can fire `write_context_event` automatically after every significant tool call — no changes to the agent's core behaviour needed. Codex CLI's `--system-prompt` flag injects the summary at startup. Any CLI or Agent SDK script that accepts a system prompt can consume context this way without knowing anything about where it came from.

The receiving agent reads the JSONL file and injects a rendered summary into its system prompt. Crucially, it filters by event type — a code-generation agent needs decisions and file refs, not raw tool outputs from a separate analysis pass:

```python
# context_reader.py — load and render context for a new agent session
import json
from pathlib import Path

CONTEXT_FILE = Path(".agent-context/session.jsonl")

def load_context_summary(event_types: list[str] | None = None) -> str:
    """Load typed context events and render them as an injectable system prompt block."""
    if not CONTEXT_FILE.exists():
        return ""

    events = []
    with CONTEXT_FILE.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            ev = json.loads(line)
            if event_types is None or ev["type"] in event_types:
                events.append(ev)

    if not events:
        return ""

    lines = ["## Context inherited from prior agent session\n"]
    for ev in events:
        if ev["type"] == "decision":
            lines.append(f"- **Decision** ({ev['agent']}): {ev['payload']['summary']}")
            lines.append(f"  Rationale: {ev['payload']['reasoning']}")
        elif ev["type"] == "tool_output":
            truncated = str(ev["payload"].get("output", ""))[:400]
            lines.append(f"- **{ev['payload'].get('key', 'output')}**: {truncated}")
        elif ev["type"] == "file_ref":
            lines.append(
                f"- **Active file** `{ev['payload']['path']}` — role: {ev['payload']['role']}"
            )
        elif ev["type"] == "metadata":
            for k, v in ev["payload"].items():
                lines.append(f"- **{k}**: {v}")

    return "\n".join(lines)

# In the new session's startup code:
# context = load_context_summary(event_types=["decision", "file_ref"])
# system_prompt = f"{base_system_prompt}\n\n{context}"
```

This pattern is portable across the entire CLI ecosystem. The [[ch03-mcp-connector-orchestrating-multi-server-agents]] chapter covers how to wire Claude Code's MCP connector for richer inter-agent communication; the JSONL relay is the simpler starting point that requires no MCP infrastructure.

## CLAUDE.md and the Memory File System

Claude Code has a native mechanism for context persistence that most developers underuse: the `CLAUDE.md` file system. When Claude Code starts it reads `CLAUDE.md` files from the project root, all parent directories, and `~/.claude/`. This makes `CLAUDE.md` a persistent, human-readable context layer that survives across sessions without any custom code, and is available to every future Claude Code session in the project automatically.

For cross-CLI workflows, `CLAUDE.md` serves a specific role: it is the right place for project-level facts that every Claude Code session and any human reading the project should know from the start. Think of it as the standing brief that never expires. A well-maintained `CLAUDE.md` for a multi-agent project should document the canonical working directory and active branch, which agents have been active and what each one owns, key architectural decisions already made and why the obvious alternatives were rejected, active file handles and their roles, MCP server configurations in use, and the cost and budget status if the project has a spending cap.

The memory file system at `.claude/memory/` extends this to agent-specific accumulated notes. When Claude Code writes to a memory file via its internal tools, those notes persist across every future Claude Code session in the project. Memory files are the right home for session-to-session accumulated knowledge that a human editor would put in a notebook: patterns observed, caveats discovered, partial progress on ongoing tasks.

The important limitation is scope. `CLAUDE.md` and memory files are Claude Code-native. Codex CLI does not read them. An Agent SDK script does not read them. For genuine cross-CLI persistence you need both: keep `CLAUDE.md` as the human-readable shadow of the machine-readable JSONL context file. Write the same key facts to both. Each consumer reads whichever format it understands. The two representations should stay in sync, but they serve different audiences: CLAUDE.md for Claude Code and humans, JSONL for programmatic consumers.

## Session IDs and Native Resumption

The [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/sessions) provides session continuity that eliminates manual context serialisation when you are staying within the SDK. Every `query()` call returns a session identifier, and subsequent calls that pass the same ID via `options: { resume: sessionId }` are treated as continuations of the same conversation — including the full tool call history and intermediate state accumulated during the prior call.

The critical distinction: the Agent SDK's `query()` function lives in `@anthropic-ai/claude-agent-sdk`, not in the general-purpose `@anthropic-ai/sdk` Anthropic Client package. Using the wrong package means you are calling the Managed Agents REST API with a different call shape — not the Agent SDK's native session resumption. Here is the correct pattern:

```typescript
// session_continuity.ts — persist and resume Agent SDK sessions across process restarts
import { query } from "@anthropic-ai/claude-agent-sdk";
import { readFile, writeFile } from "fs/promises";

const SESSION_FILE = ".agent-context/.session-id";

async function loadSessionId(): Promise<string | undefined> {
  try {
    return (await readFile(SESSION_FILE, "utf8")).trim() || undefined;
  } catch {
    return undefined;
  }
}

async function runWithResumption(prompt: string): Promise<string> {
  const existingSessionId = await loadSessionId();
  let result = "";
  let newSessionId = "";

  // Pass options.resume to resume a prior session; omit for a fresh session.
  // See: https://code.claude.com/docs/en/agent-sdk/sessions
  for await (const message of query({
    prompt,
    ...(existingSessionId ? { options: { resume: existingSessionId } } : {}),
  })) {
    if (message.type === "result" && message.subtype === "success") {
      result = message.result ?? "";
      newSessionId = message.session_id ?? "";
    }
  }

  if (newSessionId) {
    // Persist the session ID so the next invocation resumes from this exact state
    await writeFile(SESSION_FILE, newSessionId, "utf8");
  }
  return result;
}

// First call creates a new session
const analysis = await runWithResumption("Analyse the database schema");
console.log("Session persisted. Run again to continue from this point.");

// Subsequent call resumes from full prior context without re-injecting history
const migration = await runWithResumption("Now generate the migration script");
```

Session IDs are the right tool for intra-SDK resumption: same CLI, different process invocations, with full conversation continuity. They are not the right tool for cross-CLI handoffs. A Codex CLI process cannot resume an Agent SDK session. An Agent SDK script cannot resume a Claude Code session. Each CLI manages its own session namespace, and those namespaces do not intersect.

The practical rule is straightforward. Within a single SDK surface across multiple invocations of the same process, use session IDs. At any CLI boundary, use the JSONL or Files API approach. The two mechanisms complement each other: the session ID provides seamless intra-SDK continuity, while the JSONL file and Files API provide the cross-CLI bridge. Persist the session ID into the JSONL context file alongside your semantic events so any orchestrating script has both the structured context and the resumable session handle available in one place.

## The Files API as a Durable Context Layer

The [Files API](https://platform.claude.com/docs/en/build-with-claude/files), available with the `files-api-2025-04-14` beta header, provides a hosted document store that persists beyond any single session or process lifetime. A context snapshot uploaded as a file can be referenced by any subsequent API call regardless of which CLI or orchestration layer is making the call. The `file_id` becomes a portable, stable identifier for a specific version of your context state.

This makes the Files API the right persistence layer for context that needs to outlive the agent runtime: processed analysis results, compiled knowledge bases, and intermediate artefacts that required significant compute to produce. Rather than re-running expensive operations or injecting raw tool output text as part of a prompt, you upload the output once and reference it by ID in every downstream call that needs it.

```python
# context_files_api.py — upload context snapshots and reference them in downstream calls
import anthropic
import json
from io import BytesIO

client = anthropic.Anthropic()

def upload_context_snapshot(context: dict, label: str) -> str:
    """Upload a context snapshot dict and return the stable file_id."""
    payload = json.dumps(context, indent=2).encode("utf-8")
    response = client.beta.files.upload(
        file=(f"context-{label}.json", BytesIO(payload), "application/json"),
    )
    file_id = response.id   # e.g. "file_01XyzAbc..."
    print(f"Context snapshot uploaded: {file_id}")
    return file_id


def build_context_message(file_id: str, task: str) -> list[dict]:
    """Build a messages array that references the uploaded context snapshot."""
    return [
        {
            "role": "user",
            "content": [
                {
                    "type": "document",
                    "source": {"type": "file", "file_id": file_id},
                },
                {
                    "type": "text",
                    "text": f"Using the context document above as ground truth, {task}",
                },
            ],
        }
    ]


# Agent A finishes its session and uploads a context snapshot
context = {
    "schema_version": 1,
    "session": "claude-code-analysis-2026-06-12",
    "decisions": [
        "Async generators for streaming — synchronous approach caused memory pressure under load",
        "PostgreSQL chosen over MongoDB — ACID requirements and existing team expertise",
    ],
    "active_files": {
        "schema": "src/db/schema.sql",
        "tests": "tests/test_db.py",
    },
    "tool_outputs": {
        "schema_analysis": "Three N+1 query patterns found at lines 47, 89, 134",
        "test_coverage": "68% overall; auth module 42%",
    },
}

file_id = upload_context_snapshot(context, "agent-a-handoff")
# Write file_id to JSONL context file so Agent B can find it
# write_context_event("file_ref", {"path": file_id, "role": "context_snapshot"}, agent="agent-a")

# Agent B loads the file_id and uses it without re-injecting raw text
# messages = build_context_message(file_id, "generate the migration script for the schema")
```

Two constraints are important for context persistence with the Files API. First, files are not zero-data-retention eligible — they are stored server-side under Anthropic's standard data handling policies. Sanitise context snapshots before upload if they contain personally identifiable information, credentials, or other sensitive data. Your JSONL context file on disk is a safe staging area where you can redact before uploading. Second, files count against your organisation's storage quota, which the [Files API documentation](https://platform.claude.com/docs/en/build-with-claude/files) states as 500 GB across all workspaces. Context snapshots are typically small (a few kilobytes), but long-running pipelines with many handoffs accumulate. Add a cleanup step to your pipeline that calls `client.beta.files.delete(file_id)` once the downstream agent has confirmed it consumed the context successfully.

Use `document` content blocks for JSON and text context files. Use `image` blocks for visual artefacts. Use `container_upload` for code execution outputs that need downstream programmatic processing.

## MCP Servers as Context Brokers

File-based handoff works well for two-agent workflows but does not scale cleanly to pipelines with three or more agents operating concurrently. When multiple agents read and write the same JSONL file, concurrent appends are safe but readers get inconsistent views of a rapidly changing file. Each agent reads a different snapshot of the context state depending on when it opens the file.

The cleaner architecture for multi-agent context is an MCP server that exposes context as queryable tools. Each agent connects to the context broker via the [MCP Connector](https://code.claude.com/docs/en/agent-sdk/mcp), calls structured tools to read or write context, and receives exactly the slice relevant to its current task — without loading the entire session history or dealing with concurrent file access. The [Model Context Protocol specification](https://modelcontextprotocol.io/specification) defines the wire format for these tool calls, making the broker interoperable with any MCP-compatible client.

```python
# context_mcp_server.py — minimal stdio MCP context broker for multi-agent pipelines
import json
from pathlib import Path

STORE = Path(".agent-context/mcp-store.json")

def load_store() -> dict:
    if STORE.exists():
        return json.loads(STORE.read_text())
    return {"decisions": [], "tool_outputs": [], "file_refs": {}, "metadata": {}}

def save_store(data: dict) -> None:
    STORE.parent.mkdir(exist_ok=True)
    STORE.write_text(json.dumps(data, indent=2))

def handle_tool(name: str, args: dict) -> str:
    store = load_store()

    if name == "write_decision":
        store["decisions"].append({
            "summary": args["summary"],
            "reasoning": args["reasoning"],
            "agent": args.get("agent", "unknown"),
        })
        save_store(store)
        return "Decision recorded."

    elif name == "write_tool_output":
        store["tool_outputs"].append({
            "key": args["key"],
            "output": args["output"],
            "agent": args.get("agent", "unknown"),
        })
        save_store(store)
        return "Output recorded."

    elif name == "get_context_summary":
        lines = []
        for d in store["decisions"]:
            lines.append(f"- Decision ({d.get('agent','?')}): {d['summary']}")
        for o in store["tool_outputs"]:
            lines.append(f"- Output [{o['key']}]: {str(o['output'])[:300]}")
        return "\n".join(lines) if lines else "No context recorded yet."

    elif name == "get_session_metadata":
        return json.dumps(store.get("metadata", {}), indent=2)

    return f"Unknown tool: {name}"
```

Wire this broker into any agent's `.mcp.json` using stdio transport:

```json
{
  "mcpServers": {
    "context-broker": {
      "type": "stdio",
      "command": "python",
      "args": ["scripts/context_mcp_server.py"]
    }
  }
}
```

In the Agent SDK's `query()` call, scope tool access using `allowedTools`:

- Read-only agents: `["mcp__context-broker__get_context_summary", "mcp__context-broker__get_session_metadata"]`
- Orchestrator agents: `["mcp__context-broker__*"]` to permit writes

The MCP approach has one key advantage over file-based handoff: the agent does not need to know anything about the context file format, storage location, or schema version. It calls `get_context_summary` and receives exactly what it needs. Schema evolution, storage backend changes, and concurrent access coordination are all handled by the broker, fully transparent to the agents using it. When the context schema needs to change, you update the broker in one place rather than updating every agent that reads the JSONL file.

## Plan Mode, Rollback Coupling, and Approval-Mode Transitions

Three runtime behaviours of Claude Code interact directly with context persistence in ways the earlier sections do not cover: plan mode, git-based rollback, and approval-mode switching. Each creates a handoff-time obligation that most pipelines overlook until they hit a failure in production.

### Plan mode and plan artefact persistence

Claude Code's plan mode (`/plan` command, or `planning` permission mode) lets Claude draft an ordered list of steps, constraints, and expected outcomes before executing any tool calls. The plan is the result of alignment between the agent and the developer — it represents intent, not just code state. The problem in multi-CLI pipelines is that the plan exists only inside Claude Code's conversation context. When the session ends and a downstream Codex CLI or Agent SDK script continues the work, the plan evaporates. The second agent re-plans from scratch, frequently producing a different plan that diverges from the agreed approach.

The fix is to write the plan artefact to context at the moment of plan acceptance. Use a [PostToolUse hook](https://code.claude.com/docs/en/agent-sdk/hooks) that fires when Claude Code finalises a plan and appends a `decision` event of sub-type `plan` to the JSONL relay:

```python
write_context_event("decision", {
    "sub_type": "plan",
    "title": "Migration plan — accepted 2026-06-15",
    "steps": [
        "Step 1: audit schema for N+1 patterns",
        "Step 2: generate migration script",
        "Step 3: run test suite with coverage check",
    ],
    "constraints": [
        "No destructive DDL on the users table",
        "Total wall-clock time under 10 minutes",
    ],
}, agent="claude-code")
```

A downstream agent reads the plan event at startup, injects it into its system prompt, and inherits the agreed approach rather than generating a conflicting one. For longer-lived pipelines, store the active plan in the MCP context broker so any agent — not just the immediate successor — can query the currently agreed plan without loading the full JSONL history.

### Rollback coupling

Every context event that modifies the codebase should carry the git SHA active at the time of the modification. This coupling between context state and git state makes rollback recoverable. Without it, a `git reset --hard <sha>` leaves your context file describing a codebase that no longer exists — the next agent inherits ground truth that contradicts the actual files on disk.

The pattern is one additional field on `tool_output` and `file_ref` events:

```python
import subprocess

def current_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()

write_context_event("file_ref", {
    "path": "src/db/schema.sql",
    "role": "active_schema",
    "git_sha": current_sha(),   # pins context to the exact commit that introduced this ref
}, agent="claude-code")
```

When a rollback occurs, filter the JSONL relay file to events whose `git_sha` is an ancestor of the target SHA. Any event tied to a newer SHA describes a state that no longer exists and must be discarded before the next agent session starts. For observability on cost and timing, the [[ch05-production-deploy-observability-cost-controls]] chapter covers how to instrument multi-agent pipelines so rollback events appear in your traces alongside cost attribution.

### Approval-mode switching

Claude Code supports three permission modes — `default`, `acceptEdits`, and `bypassPermissions` — and agents may need to transition between them across session handoffs: for example, a planning agent in `default` mode handing off to an autonomous execution agent in `acceptEdits` mode. These transitions create two risks that context persistence must address.

First, the new session may not know which mode the prior session operated under. An agent that inherits a context file describing file modifications has no way to tell whether those modifications were human-approved (`default`) or autonomously applied (`acceptEdits`) unless the context explicitly records it. Annotate every `tool_output` and `file_ref` event with the active `permission_mode`:

```python
write_context_event("metadata", {
    "permission_mode": "acceptEdits",   # or "default" | "bypassPermissions"
    "mcp_servers_active": ["context-broker", "github"],
    "safe_paths_confirmed": ["src/", "tests/"],
    "cost_spent_usd": 0.42,             # carry forward for budget enforcement
})
```

Second, when a new session starts in a more permissive mode than the prior session, safe operating state is not automatically inherited. Safe file paths confirmed in the prior session are not confirmed in the new one — they are session-local. MCP server authentication must be re-established from scratch. The `cost_spent_usd` from the metadata event lets the new session's orchestration layer enforce the remaining budget without re-querying billing APIs. Write these session-start checks into your orchestration layer rather than relying on the agent to infer them from context alone.

## Anti-Patterns and Pitfalls

**Injecting full conversation history into every new session.** Conversation history grows fast — a two-hour Claude Code session can produce 100k or more tokens of log. Most of it is scaffolding, clarification, and dead-end exploration. Injecting all of it into a new session wastes tokens, pushes the relevant decisions further back in the attention window where they receive less attention from the model, and risks hitting the context window limit for longer sessions. Distil decisions and confirmed outputs; never dump raw conversation logs.

**Using git as a context transport.** Committing the JSONL context file after every session and expecting the next agent to pull it works, but it creates unintended coupling between your agent workflow and your project's git history. Context files accumulate rapidly, pollute the commit log with machine-generated noise, and create merge conflicts in multi-agent pipelines where more than one agent writes context concurrently. Keep context files in `.gitignore` and manage them entirely outside git.

**Relying on environment variables for context handoff.** Environment variables look appealing because they are universally accessible from any process. The fatal flaw is that they vanish the moment the shell exits. Any context stored in environment variables is scoped to the current process tree and is not persistent. Reserve environment variables for static configuration — API keys, model names, feature flags — never for runtime context that needs to survive a process boundary.

**Mixing context layers in a flat undifferentiated blob.** Storing decisions, tool outputs, file references, and session metadata as a single untyped text block makes it impossible for downstream agents to load only the context relevant to their task. A code generation agent does not need the full tool output history from a data analysis phase. Structure context by type from the start, even if you initially write everything to a single file. The overhead is negligible; the benefit at read time is large.

**Not versioning the context schema.** Context files written today will be read by agents running next month, after the context schema has evolved, tool names have changed, and models have been upgraded. Add a `schema_version` field to every context event from day one. When the schema changes, write an explicit migration function that transforms old events to the new shape rather than silently breaking backward compatibility. Consumers should check `schema_version` at read time and refuse to proceed if they encounter a version they do not understand.

## Hands-On Exercise: Building a Cross-CLI Context Relay

**Goal:** Implement a complete context relay that captures output from an initial script, persists it through the Files API, and makes it available to a subsequent Agent SDK session.

**Prerequisites:**
- Python 3.10+ with `anthropic>=0.40.0` installed
- An Anthropic API key with Files API access
- A project directory with at least two Python source files you can use as analysis targets

**Steps:**

1. Create `.agent-context/session.jsonl` in your project root. Manually add two `decision` events and one `tool_output` event as separate JSON lines, following the schema from the "File-Based Context" section. Each event must include `schema_version: 1`, a `type`, an `agent`, and a `payload`.

2. Write `load_and_run.py` that calls `load_context_summary()` filtering for `decision` and `file_ref` events, injects the rendered result into an Agent SDK `query()` system prompt, and asks the agent to summarise the project's current state based on the inherited context. Run it and verify the response explicitly references at least one decision from your JSONL file.

3. Extend `load_and_run.py` to upload the JSONL file to the Files API using `upload_context_snapshot()` with the raw JSONL content as the payload, write the returned `file_id` to `.agent-context/.file-id`, and modify the Agent SDK call to reference the uploaded file via a `document` content block. Run the extended version and confirm the agent response references the uploaded context document.

4. Add schema version validation to `context_reader.py`: if any event has `schema_version` greater than 1, raise a descriptive `ValueError` instructing the caller to run the migration function. Test this by appending a synthetic event with `"schema_version": 2` to your JSONL file and confirming the error surfaces cleanly.

5. Add `.agent-context/` to your `.gitignore` and confirm `git status` shows no untracked files from that directory.

**Success criteria:**
- Agent response in step 2 mentions at least one decision from the JSONL file verbatim or by clear paraphrase
- `file_id` in step 3 begins with `file_` and can be listed via `client.beta.files.list()`
- Agent response in step 3 explicitly references the uploaded context document
- Schema version validation in step 4 raises `ValueError` on the synthetic v2 event
- `.agent-context/` is absent from `git status` after step 5

**Stretch goal:** Wire the context broker MCP server from the "MCP Servers" section into a second standalone Agent SDK script. Call `get_context_summary` via MCP tool use and confirm the returned summary matches the decisions you recorded in the JSONL file, proving that the two persistence mechanisms stay consistent with each other.

The capstone project [[capstone-project-production-research-agent]] assembles every layer from this course — Managed Agents, MCP, the [[Files-API]], production hooks, and the cross-CLI context relay — into a single deployable research agent that handles real-world workload patterns from start to finish.
