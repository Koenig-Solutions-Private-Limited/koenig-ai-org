---
course_slug: production-agents-claude-agent-sdk-mcp-connector
chapter_num: 5
chapter_slug: production-deploy-observability
title: "Production: deploy + observability + cost controls"
description: "Ship Claude Agent SDK workloads with hooks, structured logging, cost circuit breakers, permission controls, and deployment guardrails."
tags: [observability, hooks, cost-control]
faq:
  - q: "What is the safest alternative to bypassPermissions?"
    a: "Use explicit allowedTools grants and acceptEdits for file editing instead of disabling all permission checks."
  - q: "When should I use PreToolUse instead of PostToolUse?"
    a: "Use PreToolUse when you need to block a risky call before it executes; use PostToolUse for logging after execution."
  - q: "What should every production agent log?"
    a: "Log tool name, session ID, file or resource target, result status, and cumulative cost or token usage where available."
status: awaiting-g0
author: vardaan-koenig
agent_drafted_by: course-author
date: 2026-04-30
duration_min: 45
prerequisites_chapters: [1, 2, 3, 4]
learning_objectives:
  - "Implement a production hook stack: audit logging (PostToolUse), pre-execution cost/tool guard (PreToolUse), prompt sanitization (UserPromptSubmit), and TypeScript-only session lifecycle telemetry where available"
  - "Configure structured JSON logging for every tool call"
  - "Apply the five-step deployment checklist before taking an agent to production"
  - "Explain why bypassPermissions is dangerous and what to use instead"
key_concepts:
  [hooks, hooksystem, preToolUse, postToolUse, circuit-breaker, structured-logging, settingSources, langfuse, permissionMode]
hands_on_exercise: "Add the production hook stack to an existing agent, add a cost cap, and verify that a simulated runaway session terminates before hitting budget"
sources:
  - https://docs.anthropic.com/en/docs/claude-code/sdk
  - https://platform.claude.com/docs/en/managed-agents/overview
  - https://platform.claude.com/docs/en/build-with-claude/files
  - https://code.claude.com/docs/en/agent-sdk/hooks
  - https://code.claude.com/docs/en/agent-sdk/claude-code-features
  - https://code.claude.com/docs/en/agent-sdk/permissions
---

# Production: deploy + observability + cost controls

The Claude Agent SDK's hook system is a lifecycle callback framework — inspired by HTTP middleware — that lets you attach Python or TypeScript functions to agent events such as `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, and permission events. Claude Code also has settings-file shell hooks with their own event matrix. Those two surfaces run side by side, but they are not identical: Python SDK callback hooks do not support `SessionStart` or `SessionEnd`, while TypeScript SDK callbacks do [3]. This chapter turns the [[course/production-agents-claude-agent-sdk-mcp-connector/03-mcp-connector-multi-server|MCP tool layer]] and [[course/production-agents-claude-agent-sdk-mcp-connector/04-files-api-code-execution|Files API IO layer]] into deployable production behavior.

Most teams discover the need for this the hard way: an agent that works perfectly in development starts generating surprise API bills in production, or silently modifies files it shouldn't touch, or loops on a subtask for 40 minutes. The [[course/production-agents-claude-agent-sdk-mcp-connector/01-sdk-rename-what-changed|Agent SDK]] includes a hook system specifically for these scenarios [1]. The biggest production failure mode is not model hallucination — it's cost runaway. This chapter gives you the four hooks you need before any agent goes live, and the deployment checklist that ties everything together.

> **Prerequisites**: Chapters 1–4
>
> **Time**: 45 minutes
>
> **Learning objectives**: By the end of this chapter you have a production hook stack, structured logging, a cost circuit breaker, and a deployment checklist you can apply to any new agent.

## Key facts

1. SDK callback hooks and Claude Code settings-file hooks are related but separate surfaces. Python SDK callbacks support tool, prompt, stop, compaction, permission, notification, and subagent events, but not `SessionStart` or `SessionEnd`; TypeScript callbacks add session lifecycle events and several teammate/worktree events [3].
2. `permissionMode: "bypassPermissions"` disables ALL safety checks, including file-edit confirmations and destructive Bash command prompts — not just MCP [1].
3. Session JSONL files are written to `~/.claude/sessions/` by default and can be redirected with the `CLAUDE_SESSIONS_DIR` environment variable [1].
4. Setting sources load in order: global (`~/.claude/`), then project (`.claude/`), then inline options. Inline options override everything [1].
5. The correct alternative to `bypassPermissions` for MCP is `allowedTools` wildcards; for file edits is `permissionMode: "acceptEdits"` — combine them [1].
6. `PreToolUse` callbacks can deny, ask, defer, allow, or update tool input before execution; `PostToolUse` callbacks run after execution and are best for logging or adding context, not preventing the tool call that just happened [3].

## The hook system

Hooks are callback functions attached to the agent lifecycle. They run synchronously in your process before or after every tool call. The SDK provides `HookMatcher` for filtering by tool name using regex:

```python
from claude_agent_sdk import query, ClaudeAgentOptions, HookMatcher

async def my_hook(input_data: dict, tool_use_id: str, context: dict) -> dict:
    # Return {} to pass through, or raise to block
    return {}

options = ClaudeAgentOptions(
    hooks={
        "PostToolUse": [
            HookMatcher(matcher="Edit|Write", hooks=[my_hook])
        ]
    }
)
```

The `matcher` is a Python regex. `"Edit|Write"` matches any tool whose name contains "Edit" or "Write". Use `".*"` to match everything.

## Hook 1: Audit log (PostToolUse)

Every file modification should be logged with a timestamp, file path, and session ID. This hook runs after every successful Edit or Write call:

```python
import asyncio
import json
import logging
from datetime import datetime
from claude_agent_sdk import query, ClaudeAgentOptions, HookMatcher

# Configure structured JSON logging
logging.basicConfig(
    format='%(message)s',
    level=logging.INFO,
)
logger = logging.getLogger("agent.audit")

async def audit_file_change(input_data: dict, tool_use_id: str, context: dict) -> dict:
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", tool_input.get("path", "unknown"))
    tool_name = input_data.get("tool_name", "unknown")
    
    log_entry = {
        "event": "file_modified",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "tool": tool_name,
        "file_path": file_path,
        "session_id": context.get("session_id", "unknown"),
        "tool_use_id": tool_use_id,
    }
    logger.info(json.dumps(log_entry))
    return {}  # pass through — don't block

options = ClaudeAgentOptions(
    allowed_tools=["Read", "Write", "Edit", "Bash", "Glob", "Grep"],
    hooks={
        "PostToolUse": [
            HookMatcher(matcher="Edit|Write", hooks=[audit_file_change])
        ]
    }
)
```

Sample audit output:
```json
{"event": "file_modified", "timestamp": "2026-04-30T10:23:44Z", "tool": "Edit", "file_path": "src/auth.py", "session_id": "sess_01XxXxxXx", "tool_use_id": "toolu_01Abc123"}
```

## Hook 2: Cost circuit breaker (PreToolUse)

The `Stop` hook fires when the agent is trying to finish. It is useful for final-state validation, but it is the wrong tool for preventing a costly or risky operation before it happens. Use `PreToolUse` when the next tool call must be blocked before filesystem or MCP side effects occur:

```python
class CostCircuitBreaker:
    """Deny the next tool call once the application-managed token cap is reached."""
    
    def __init__(self, max_input_tokens: int = 500_000):
        self.max_input_tokens = max_input_tokens
        self.total_input_tokens = 0

    def update_usage(self, usage: dict) -> None:
        # Call this from your message loop when result/usage metadata is available.
        self.total_input_tokens = usage.get("input_tokens", self.total_input_tokens)
    
    async def check_cost(self, input_data: dict, tool_use_id: str, context: dict) -> dict:
        if self.total_input_tokens > self.max_input_tokens:
            return {
                "hookSpecificOutput": {
                    "hookEventName": input_data["hook_event_name"],
                    "permissionDecision": "deny",
                    "permissionDecisionReason": (
                        f"Circuit breaker triggered: {self.total_input_tokens:,} input tokens "
                        f"exceeds cap of {self.max_input_tokens:,}. Tool call blocked before execution."
                    ),
                }
            }
        
        return {}


circuit_breaker = CostCircuitBreaker(max_input_tokens=500_000)

options = ClaudeAgentOptions(
    allowed_tools=["Read", "Write", "Edit", "Bash", "Glob", "Grep"],
    hooks={
        "PreToolUse": [
            HookMatcher(matcher=".*", hooks=[circuit_breaker.check_cost])
        ]
    }
)
```

When `circuit_breaker.check_cost` returns `permissionDecision: "deny"`, the current tool call is blocked before it executes and Claude receives the denial reason as feedback. The session JSONL is preserved, so you can inspect exactly what happened.

<Callout type="hot">
Do NOT block silently inside hooks. When a hook denies a tool call in production, you need the context to diagnose it. Log the full `input_data`, `tool_use_id`, and denial reason before returning `permissionDecision: "deny"`.
</Callout>

## Hook 3: Session lifecycle telemetry

`SessionStart` and `SessionEnd` are available as TypeScript SDK callback hooks, but official docs mark them unavailable for Python SDK callbacks [3]. In Python, use one of two patterns:

- For SDK-local telemetry, emit your session-start event when the first response arrives from `ClaudeSDKClient.receive_response()`.
- For Claude Code lifecycle hooks shared with CLI sessions, define shell hooks in `.claude/settings.json` and load them with `setting_sources=["project"]`.

Here is the Python SDK-local pattern:

```python
async def log_session_start_from_first_message(message, logger):
    session_id = getattr(message, "session_id", "unknown")
    start_event = {
        "event": "session_started",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "session_id": session_id,
        "environment": os.environ.get("DEPLOY_ENV", "development"),
    }
    logger.info(json.dumps(start_event))
```

And here is a TypeScript callback hook when you want true `SessionStart` support:

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

const sessionStart = async (input, toolUseId, context) => {
  console.log(JSON.stringify({
    event: "session_started",
    session_id: input.session_id,
    cwd: input.cwd,
    timestamp: new Date().toISOString()
  }));
  return {};
};

for await (const message of query({
  prompt: "Run the production agent",
  options: {
    hooks: {
      SessionStart: [{ hooks: [sessionStart] }]
    }
  }
})) {
  console.log(message);
}
```

## Hook 4: Prompt sanitization (UserPromptSubmit)

`UserPromptSubmit` fires when a user message is submitted to the agent. Use it to strip PII or dangerous patterns before they reach the model:

```python
import re

PHONE_RE = re.compile(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b')
SSN_RE = re.compile(r'\b\d{3}-\d{2}-\d{4}\b')

async def sanitize_prompt(input_data: dict, tool_use_id: str, context: dict) -> dict:
    prompt = input_data.get("prompt", "")
    
    # Redact phone numbers and SSNs
    cleaned = PHONE_RE.sub("[PHONE_REDACTED]", prompt)
    cleaned = SSN_RE.sub("[SSN_REDACTED]", cleaned)
    
    if cleaned != prompt:
        logger.warning(json.dumps({
            "event": "pii_redacted",
            "session_id": context.get("session_id"),
            "patterns_found": ["phone" if PHONE_RE.search(prompt) else None,
                               "ssn" if SSN_RE.search(prompt) else None]
        }))
    
    # Return modified input_data with cleaned prompt
    return {**input_data, "prompt": cleaned}

options = ClaudeAgentOptions(
    hooks={
        "UserPromptSubmit": [
            HookMatcher(matcher=".*", hooks=[sanitize_prompt])
        ],
        # ... other hooks
    }
)
```

## The complete production hook stack

Put it all together into a factory function you can reuse across agents:

```python
def production_options(
    allowed_tools: list[str],
    mcp_servers: dict = None,
    max_input_tokens: int = 500_000,
    permission_mode: str = "acceptEdits",
) -> ClaudeAgentOptions:
    cb = CostCircuitBreaker(max_input_tokens=max_input_tokens)
    
    return ClaudeAgentOptions(
        allowed_tools=allowed_tools,
        mcp_servers=mcp_servers or {},
        permission_mode=permission_mode,
        hooks={
            "UserPromptSubmit": [
                HookMatcher(matcher=".*", hooks=[sanitize_prompt])
            ],
            "PreToolUse": [
                HookMatcher(matcher=".*", hooks=[cb.check_cost]),
            ],
            "PostToolUse": [
                HookMatcher(matcher="Edit|Write", hooks=[audit_file_change]),
            ],
        }
    )
```

Usage:

```python
# Apply to the MCP agent from Chapter 3
async for message in query(
    prompt="Investigate issue #1234 and write a summary",
    options=production_options(
        allowed_tools=["mcp__github__*", "mcp__postgres__query", "mcp__docs__*"],
        mcp_servers={
            "github": github_config,
            "postgres": postgres_config,
            "docs": docs_config,
        },
        max_input_tokens=1_000_000,  # verify the matching token budget against current model pricing
    ),
):
    if hasattr(message, "result"):
        print(message.result)
```

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I'm running an agent with a PreToolUse hook backed by an application-managed token counter. After 12 tool calls, the counter shows 505,000 input tokens against a cap of 500,000. The agent is about to call Edit on three more files. Walk me through what the circuit breaker will do."
  expectedOutput="Claude explains: the PreToolUse hook runs before the next Edit call executes. Because the tracked total is already over 500,000 input tokens, the hook returns permissionDecision: deny with a reason. The first pending Edit is blocked before it writes to disk, and Claude receives feedback that the budget cap was exceeded. A PostToolUse guard would be too late for the edit that triggered it."
/>

## Langfuse integration for observability

Langfuse is the recommended observability backend for Koenig AI Academy's [[company/learnova-academy|agent stack]]. In Python, create the trace when the first session message arrives, then add spans from `PostToolUse` hooks:

```python
from langfuse import Langfuse

langfuse = Langfuse(
    public_key=os.environ["LANGFUSE_PUBLIC_KEY"],
    secret_key=os.environ["LANGFUSE_SECRET_KEY"],
    host=os.environ.get("LANGFUSE_HOST", "http://localhost:3100"),
)

traces_by_session = {}

def langfuse_session_start(message):
    session_id = getattr(message, "session_id", "unknown")
    trace = langfuse.trace(
        id=session_id,
        name="agent_session",
        metadata={"environment": os.environ.get("DEPLOY_ENV", "dev")},
    )
    traces_by_session[session_id] = trace
    return trace

async def langfuse_tool_log(input_data: dict, tool_use_id: str, context: dict) -> dict:
    trace = traces_by_session.get(input_data.get("session_id"))
    if trace:
        trace.span(
            name=input_data.get("tool_name", "unknown_tool"),
            input=input_data.get("tool_input"),
            metadata={"tool_use_id": tool_use_id},
        )
    return {}
```

## The five-step deployment checklist

Before any agent goes to production, verify all five:

### 1. Permissions are minimal

- `allowedTools` lists only the specific tools the agent needs — no `.*` wildcards in production
- `permissionMode` is `acceptEdits` or `default` — never `bypassPermissions`
- MCP tools are scoped to specific tool names where possible (not `mcp__github__*` for agents that only need `list_issues`)

### 2. Cost controls are wired

- A `PreToolUse` circuit breaker with a tested token cap, plus `PostToolUse` usage logging
- A session timeout mechanism (for Managed Agents: explicit session.update to "completed")
- Langfuse (or equivalent) traces enabled with cost annotations

### 3. Audit logging is active

- Every Edit and Write logged with file path + session ID + timestamp
- Bash tool calls logged with the command (be careful with secrets in commands)
- Logs are structured JSON, not raw print statements

### 4. Secrets are out of config

- No API keys in `mcpServers.env` values — use environment variable references
- No hardcoded tokens in `headers` — use `os.environ["KEY"]` or `process.env.KEY`
- `.mcp.json` uses `${VAR}` syntax, committed to version control

### 5. Session files have a retention policy

- `CLAUDE_SESSIONS_DIR` points to a location with log rotation
- JSONL files are not written to a disk that's part of user-facing data storage
- For Managed Agents: sessions are marked `completed` when done, not left idle

<Callout type="warn">
`bypassPermissions` is occasionally used in CI/CD pipelines where there's no human in the loop to approve tool calls. This is understandable but risky: it disables ALL safety prompts, including protections against destructive Bash commands. The safer alternative is to list every allowed tool explicitly in `allowedTools` and use `permissionMode: "acceptEdits"` for file operations. If your CI pipeline runs code that generates new files, that combination covers the common cases without the blast radius of `bypassPermissions`.
</Callout>

## Hands-on exercise

**Harden an existing agent with the production hook stack and verify the circuit breaker.**

Setup: Use the MCP-wired agent from Chapter 3, or any agent that makes multiple tool calls.

Steps:
1. Apply the `production_options()` factory function from this chapter to your agent
2. Set `max_input_tokens=50_000` (intentionally low to trigger the circuit breaker)
3. Run the agent with a prompt that requires multiple tool calls: "Analyze every Python file in this directory and write a summary of each one's purpose"
4. Observe the circuit breaker trigger — the next tool call after the cap is exceeded should be denied before execution
5. Check your structured logs for the `session_started`, `file_modified`, and any `pii_redacted` entries

**Verification**:
- The session stops before processing all files
- The terminal output or transcript shows the `permissionDecision: "deny"` reason from the circuit breaker
- At least one `{"event": "file_modified"}` log entry exists (for any Write/Edit the agent made before tripping the breaker)
- Raising `max_input_tokens` to `2_000_000` allows the full run to complete

**Estimated time**: 20 minutes

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I need to run a Claude Agent in a CI/CD pipeline where there's no human to approve tool calls. The agent reads test results, edits configuration files, and runs bash commands to restart services. What permission configuration should I use, and what risks should I document?"
  expectedOutput="Claude recommends: use allowedTools with an explicit list (e.g. ['Read', 'Edit', 'Bash']) plus permissionMode: 'acceptEdits' — not bypassPermissions. This pre-approves file edits and Bash without disabling all safety checks. The agent can still be stopped by hooks. Risks to document: (1) Bash is allowed and can run destructive commands — scope the working directory; (2) Edit can overwrite production config — add a PostToolUse hook that logs every edit to a change log; (3) No human review means runaway loops go undetected — add a token circuit breaker."
/>

<KnowledgeCheck
  question="A PostToolUse guard blocks the session when cumulative tokens exceed the cap. However, your team reports that the file edit that triggered the cap was already written to disk. What hook type should you use instead to prevent the write, and why?"
  options={[
    "PreToolUse — it runs before the tool executes, allowing you to block the call before any filesystem change occurs",
    "PostToolUse with a file rollback — reverse the write after detecting the breach",
    "SessionEnd — it fires before any tool results are persisted",
    "Stop — it intercepts the agent's stop signal before cleanup"
  ]}
  correctIdx={0}
  explanation="PostToolUse runs after the tool has already executed — the file is already written. PreToolUse runs before execution, giving you the chance to deny the tool call before side effects occur. For a cost circuit breaker that needs to prevent writes (not just log them), move the cap check to PreToolUse. For pure logging and alerting, PostToolUse is fine."
/>

<KnowledgeCheck
  question="You're deploying an agent that uses the GitHub MCP server and needs to read and write files. List the minimum `allowedTools` and `permissionMode` configuration to avoid using bypassPermissions."
  options={["self-check"]}
  correctIdx={0}
  explanation="Self-check: Set permissionMode to 'acceptEdits' (covers file read/write without prompting). Add to allowedTools: ['Read', 'Write', 'Edit', 'Glob', 'Grep'] for filesystem operations, plus 'mcp__github__list_issues' (or whichever specific GitHub tools you need — not mcp__github__* unless you genuinely need all of them). This gives the agent exactly what it needs with no bypassPermissions blast radius."
/>

## Monitoring with structured logging in production

Structured JSON logs let you query agent behavior with standard log tooling. Here's the complete logging setup used by the Koenig AI Academy agent pipeline:

```python
import logging
import json
import os
import sys

def setup_agent_logging(agent_name: str) -> logging.Logger:
    """Configure structured JSON logging for a production agent."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter('%(message)s'))
    
    logger = logging.getLogger(f"agent.{agent_name}")
    logger.setLevel(logging.INFO)
    logger.addHandler(handler)
    logger.propagate = False
    return logger

def log_tool_event(logger: logging.Logger, event: str, tool_name: str,
                   session_id: str, extra: dict = None):
    """Emit a structured tool event."""
    entry = {
        "event": event,
        "tool": tool_name,
        "session_id": session_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "service": os.environ.get("SERVICE_NAME", "agent"),
        "env": os.environ.get("DEPLOY_ENV", "development"),
    }
    if extra:
        entry.update(extra)
    logger.info(json.dumps(entry))
```

In Langfuse, these log entries correlate to spans on a trace timeline. In Datadog or CloudWatch Logs Insights, they're filterable with JMESPath or structured queries. In any system, they give you:

- Per-session cost breakdown (how many tool calls, which tools, which files modified)
- Error rate by tool type (which MCP servers fail most often)
- Session duration distribution (identify runaway sessions before the circuit breaker)
- Token efficiency (input tokens per useful tool call result)

## Deploying to production environments

The Agent SDK runs in your process — you can deploy it anywhere Python or Node.js runs. The key differences between deployment targets:

**Lambda / Cloud Functions** (short-lived): best for agents that complete in under 15 minutes. Package the SDK and your agent code together. Set `CLAUDE_SESSIONS_DIR` to `/tmp` (ephemeral, disappears after the function cold-starts). Session resume doesn't work across invocations unless you serialize the session ID to a database.

**Long-running container** (EC2, Cloud Run, K8s): best for agents with sessions that span multiple turns or that need to resume. Sessions persist on the container's disk. The risk: unbounded session file growth. Add a cron job inside the container that trims JSONL files older than 7 days.

**Managed Agents** (Anthropic-hosted): as covered in [[course/production-agents-claude-agent-sdk-mcp-connector/02-managed-agents-when-to-use|Chapter 2]], the right choice for long-running async tasks where you don't want to manage the container. Event history persists server-side.

For all environments:
```bash
# Required environment variables in production
ANTHROPIC_API_KEY=sk-ant-...          # or use Bedrock/Vertex credentials
CLAUDE_SESSIONS_DIR=/var/agent/sessions  # writable, with retention policy
DEPLOY_ENV=production                   # for log filtering
SERVICE_NAME=research-agent             # for log correlation
```

## The contrarian production advice: log before you optimize

Most teams' first instinct after deploying an agent is to optimize for cost — reduce token usage, tune the model size, add caching. The better first move is to log everything and let data drive optimization decisions.

Until you have structured logs for at least 100 real sessions, you don't know:
- Which tool is called most often (and thus where caching would help most)
- Which prompts consume the most tokens (and thus where prompt engineering ROI is highest)
- What your actual p99 session cost is (different from the estimate you calculated before launch)

The production hook stack from this chapter gives you that data for free as a side effect of safe operations. Run for two weeks, then optimize from evidence.

## What's next

You've now completed the full five-chapter arc. The capstone project ties it together: you'll build a production research agent that orchestrates GitHub + Postgres + a cloud docs MCP server, uses the Files API for document context, and runs behind the complete hook stack from this chapter. The capstone repo is described in the [[course/production-agents-claude-agent-sdk-mcp-connector/outline|course outline]].

The field is moving fast. Watch the [Claude Agent SDK changelog](https://github.com/anthropics/claude-agent-sdk-typescript/blob/main/CHANGELOG.md) and the [Managed Agents release notes](https://platform.claude.com/docs/en/release-notes/overview) for breaking changes — both are updated on a rolling basis.

## References

[1] Claude Agent SDK Overview — https://docs.anthropic.com/en/docs/claude-code/sdk · retrieved 2026-05-14
[2] Claude Managed Agents Overview — https://platform.claude.com/docs/en/managed-agents/overview · retrieved 2026-04-30
[3] Agent SDK Hooks — https://code.claude.com/docs/en/agent-sdk/hooks · retrieved 2026-05-14
[4] Claude Agent SDK Permissions — https://code.claude.com/docs/en/agent-sdk/permissions · retrieved 2026-04-30
[5] Files API — https://platform.claude.com/docs/en/build-with-claude/files · retrieved 2026-04-30
[6] Langfuse Observability — https://langfuse.com · retrieved 2026-04-30
