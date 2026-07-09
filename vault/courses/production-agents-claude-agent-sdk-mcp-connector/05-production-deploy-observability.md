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
status: g3-passed
last_updated: 2026-06-14
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
quiz:
  - question: "What is the key functional difference between `PreToolUse` and `PostToolUse` hooks?"
    options:
      - "`PreToolUse` blocks calls before side effects occur; `PostToolUse` logs after execution"
      - "`PreToolUse` fires only for read tools; `PostToolUse` fires for all state-modifying tools"
      - "`PreToolUse` receives tool output; `PostToolUse` receives tool input before execution"
      - "`PreToolUse` is Python-only; `PostToolUse` works in both Python and TypeScript SDKs"
    correct_idx: 0
    explanation: "`PreToolUse` runs before the tool executes and can return a `deny` decision to block the call — use it for cost circuit breakers and access control. `PostToolUse` runs after execution and suits audit logging but cannot prevent side effects that already occurred."
    section_anchor: the-hook-system
  - question: "A cost circuit breaker must stop an expensive MCP tool call before it modifies external state. Which hook type applies?"
    options:
      - "`PostToolUse` — to detect and reverse any filesystem or API change after it occurs"
      - "`UserPromptSubmit` — to intercept the user's request before any tools are invoked at all"
      - "`Stop` — to terminate the entire agent session when the spending threshold is reached"
      - "`PreToolUse` — to deny the call before any filesystem or external state change occurs"
    correct_idx: 3
    explanation: "`PreToolUse` is the right hook for a cost circuit breaker because it fires before execution. Returning a `deny` `permissionDecision` in the hook output blocks the tool call entirely. `PostToolUse` runs after — by then the MCP call has already happened and state has already changed."
    section_anchor: hook-2-cost-circuit-breaker-pretooluse
  - question: "A Python developer wants to fire callbacks on session start and end. Why can't the SDK hook system do this?"
    options:
      - "Python asyncio cannot synchronously emit lifecycle events during session startup and teardown"
      - "Python SDK callbacks lack `SessionStart`/`SessionEnd`; those events exist only in the TypeScript SDK"
      - "Session lifecycle events are only available in Managed Agents, not the local Agent SDK runtime"
      - "The Python SDK uses a separate `telemetry.session` API for lifecycle events instead of hooks"
    correct_idx: 1
    explanation: "The Python Agent SDK's callback system exposes tool, prompt, stop, compaction, permission, notification, and subagent events — but not `SessionStart` or `SessionEnd`. The TypeScript SDK adds these two session lifecycle events. Work around this in Python by logging session IDs from the `init` SystemMessage."
    section_anchor: hook-3-session-lifecycle-telemetry
  - question: "Why is `bypassPermissions: true` specifically dangerous in a production agent deployment?"
    options:
      - "It removes context compression, causing runaway token spend that overwhelms cost circuit breakers"
      - "It grants access to Managed Agents beta endpoints without requiring explicit operator authorization"
      - "It disables all safety checks, including file-edit prompts and destructive Bash confirmations"
      - "It forces the agent to ignore budget caps and run with an unbounded token allocation by default"
    correct_idx: 2
    explanation: "`bypassPermissions` disables ALL safety checks — file-edit confirmation prompts, destructive Bash command confirmations, and MCP tool approval gates. In production, use explicit `allowedTools` grants and `acceptEdits` for file editing instead of disabling the entire permission system."
    section_anchor: the-five-step-deployment-checklist
---

# Production: deploy + observability + cost controls

The Agent SDK hook system attaches Python or TypeScript callbacks to agent events: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, and permission events. Python SDK callbacks do not support `SessionStart` or `SessionEnd`; TypeScript callbacks add those [3]. The biggest production failure mode is cost runaway — this chapter gives you the four hooks and deployment checklist to prevent it.

## Key facts

1. Python SDK callbacks: tool, prompt, stop, compaction, permission, notification, subagent events — no `SessionStart`/`SessionEnd`; TypeScript adds session lifecycle [3].
2. `bypassPermissions` disables ALL safety checks including file-edit prompts and destructive Bash confirmations [1].
3. Session JSONL files: `~/.claude/sessions/` by default; redirect with `CLAUDE_SESSIONS_DIR` [1].
4. `PreToolUse` can deny/allow before execution; `PostToolUse` runs after — use for logging, not prevention [3].

## The hook system

Hooks are synchronous callbacks that run in your process. `HookMatcher` filters by tool name via regex:

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

```takeaways
- Hooks are synchronous callback functions that run in your process before or after every tool call; `HookMatcher` filters by tool name using a Python regex.
- `PreToolUse` runs before execution — use it to block risky calls before side effects occur; `PostToolUse` runs after — use it for logging and audit, not prevention.
- Python SDK callbacks do not support `SessionStart` or `SessionEnd`; TypeScript SDK callbacks add these session lifecycle events.
```

## Hook 1: Audit log (PostToolUse)

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

Use `PreToolUse` to block tool calls before filesystem or MCP side effects occur:

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

> **Sonnet 5 migration note:** If you switch to `claude-sonnet-5`, rebaseline your `max_input_tokens` cap. The Sonnet 5 tokenizer produces ~30% more tokens for equivalent text, and adaptive thinking creates additional text-only decision turns that accumulate input tokens. A cap calibrated for Sonnet 4.x will fire significantly earlier on Sonnet 5 workloads with equivalent prompts.

<Callout type="hot">
Do NOT block silently inside hooks. When a hook denies a tool call in production, you need the context to diagnose it. Log the full `input_data`, `tool_use_id`, and denial reason before returning `permissionDecision: "deny"`.
</Callout>

## Hook 3: Session lifecycle telemetry

`SessionStart`/`SessionEnd` are TypeScript-only SDK callbacks. In Python, emit the session-start event when the first message arrives:

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

TypeScript for true `SessionStart` support:

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

Fires before the user message reaches the model — strip PII here:

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

```takeaways
- `UserPromptSubmit` fires before the user message reaches the model — use it to strip PII, redact phone numbers and SSNs, and prevent sensitive data from entering the model's context.
- Always log when PII redaction occurs, including which pattern was found and the session ID, to maintain compliance audit trails.
- The four production hooks together cover the full agent lifecycle: input sanitization, pre-execution cost control, post-execution audit logging, and session telemetry.
```

## The complete production hook stack

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

Usage — apply to the MCP agent from [[course/production-agents-claude-agent-sdk-mcp-connector/03-mcp-connector-multi-server|Chapter 3]] or any agent with multiple tool calls:

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

## Langfuse integration

For a broader look at Langfuse setup and why it fits agent workloads, see [[blogs/2026-05-12-ai-agent-observability-langfuse|AI agent observability with Langfuse 2026]]. Create the trace on first session message; add spans from `PostToolUse` hooks:

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

### 1. Permissions are minimal
- `allowedTools` names specific tools — no `.*` wildcards
- `permissionMode`: `acceptEdits` or `default` — never `bypassPermissions`

### 2. Cost controls are wired
- `PreToolUse` circuit breaker with a tested token cap
- Session timeout (Managed Agents: explicit `status="completed"`)

### 3. Audit logging is active
- Every Edit/Write logged: file path + session ID + timestamp
- Structured JSON, not print statements

### 4. Secrets are out of config
- No API keys in `mcpServers.env` — use `os.environ["KEY"]`
- `.mcp.json` uses `${VAR}` syntax

### 5. Session files have a retention policy
- `CLAUDE_SESSIONS_DIR` with log rotation
- JSONL files off user-facing storage

<Callout type="warn">
`bypassPermissions` is occasionally used in CI/CD pipelines where there's no human in the loop to approve tool calls. This is understandable but risky: it disables ALL safety prompts, including protections against destructive Bash commands. The safer alternative is to list every allowed tool explicitly in `allowedTools` and use `permissionMode: "acceptEdits"` for file operations. If your CI pipeline runs code that generates new files, that combination covers the common cases without the blast radius of `bypassPermissions`.
</Callout>

```takeaways
- Never use `bypassPermissions` in production; combine `permissionMode: "acceptEdits"` with explicit `allowedTools` grants to cover both file edits and MCP tool calls safely.
- Production agents must pass five checks: minimal permissions, wired cost controls, active audit logging, secrets out of config, and session files with a retention policy.
- Structured JSON logs — not print statements — enable per-session cost breakdown, error rate by tool type, and session duration distribution from day one.
```

## Hands-on exercise

**Add the production hook stack to an existing agent and verify the circuit breaker fires.**

1. Apply `production_options()` to any multi-tool agent
2. Set `max_input_tokens=50_000` (intentionally low)
3. Run: "Analyze every Python file in this directory and summarize each one's purpose"
4. Confirm circuit breaker fires: `permissionDecision: "deny"` appears before all files are processed
5. Check logs for `file_modified` and `session_started` entries

**Verify**: Session stops mid-run; raising cap to 2M allows full completion. **Est. time**: 20 min

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

## What's next

The capstone project ties all five chapters together: a production research agent that orchestrates GitHub + Postgres + a cloud docs MCP server, uses the Files API for document context, and runs behind the complete hook stack. Details in the [[course/production-agents-claude-agent-sdk-mcp-connector/outline|course outline]].

## References

[1] Claude Agent SDK Overview — https://code.claude.com/docs/en/sdk · retrieved 2026-06-14
[2] Claude Managed Agents Overview — https://platform.claude.com/docs/en/managed-agents/overview · retrieved 2026-04-30
[3] Agent SDK Hooks — https://code.claude.com/docs/en/agent-sdk/hooks · retrieved 2026-05-14
[4] Claude Agent SDK Permissions — https://code.claude.com/docs/en/agent-sdk/permissions · retrieved 2026-04-30
[5] Files API — https://platform.claude.com/docs/en/build-with-claude/files · retrieved 2026-04-30
[6] Langfuse Observability — https://langfuse.com · retrieved 2026-04-30
