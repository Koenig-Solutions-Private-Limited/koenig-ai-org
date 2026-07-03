---
chapter_num: 7
course_slug: claude-agent-sdk-zero-to-production
title: "Build channel-scoped agents for multi-user teams"
status: g3-passed
last_updated: "2026-07-02"
duration_min: 55
vendor_tag: anthropic
learning_objectives:
  - "Distinguish per-task runs, per-user sessions, and channel-scoped shared context and choose the right model for a given team workflow"
  - "Map Slack-style workspace, channel, thread, user, task, session, run, and artifact IDs to SDK primitives"
  - "Enforce channel memory isolation using explicit allowedTools, dontAsk permission mode, and artifact namespace prefixing"
  - "Instrument an admin audit log using PreToolUse and PostToolUse hooks with full requester attribution"
sources:
  - url: "https://www.anthropic.com/news/introducing-claude-tag"
    title: "Introducing Claude Tag (Anthropic, 2026-06-23)"
  - url: "https://code.claude.com/docs/en/agent-sdk/sessions"
    title: "Claude Agent SDK — Sessions"
  - url: "https://code.claude.com/docs/en/agent-sdk/permissions"
    title: "Claude Agent SDK — Permissions"
  - url: "https://code.claude.com/docs/en/agent-sdk/hooks"
    title: "Claude Agent SDK — Hooks"
owns:
  - "per-user sessions versus per-task runs versus channel-scoped shared agent context"
  - "Slack-style channel adapter identity mapping across workspace, channel, thread, user, task, session, run, and artifact IDs"
  - "channel-scoped memory boundaries and permission inheritance"
  - "admin audit log event schema for reads, decisions, tool calls, writes, spend, and requester attribution"
  - "Claude Tag as the production reference pattern for multiplayer delegation, ambient context, budget limits, and channel-level logs"
defers_to:
  - "basic SDK setup and model selection → ch1"
  - "single-user persona harnesses and session resume → ch2"
  - "MCP tool schema and basic read/write gates → ch3"
  - "artifact storage and crash resume mechanics → ch4"
  - "generic evals and traces → ch5"
  - "HTTP/CLI deployment and operator runbook basics → ch6"
quiz_topics:
  - "channel-scoped versus user-scoped context"
  - "workspace/channel/thread/user identity mapping"
  - "audit log event fields"
  - "cross-channel leakage tests"
  - "Claude Tag reference architecture"
notebooklm_source_focus:
  - "Anthropic Claude Tag announcement"
  - "Claude Agent SDK TypeScript docs"
  - "Claude Agent SDK permissions docs"
  - "MCP docs for tool boundaries"
  - "enterprise audit logging patterns for AI agents"
chapter_primary_query: "How do I build channel-scoped agents for multi-user teams with the Claude Agent SDK?"
first_60_words_answer: "Channel-scoped agents share a single SDK session across all users in a Slack channel, enforced at the channel_id boundary. This chapter adds the channel adapter, memory isolation rules, and an admin audit log to the incident-triage agent from ch 6, using Claude Tag as the production reference pattern for multiplayer delegation and per-channel budget controls."
positions: []
word_budget: { min: 800, max: 1200 }
faq:
  - question: "How do multiple users share agent context in a Slack channel?"
    answer: "All users in a channel share a single SDK session keyed to the `channel_id`. The adapter captures `session_id` from the first run's init `SystemMessage` and passes it to `resume:` on every subsequent `query()` call for that channel, so every team member's messages accumulate into the same conversation history — Claude picks up from where the last person left off. See [Claude Agent SDK — Sessions](https://code.claude.com/docs/en/agent-sdk/sessions) for full session lifecycle details."
  - question: "Why is `continue: true` unsafe in a multi-channel deployment?"
    answer: "When `continue: true` is passed to `query()`, the SDK resumes whichever session was most recently written in the current working directory. In a multi-channel deployment that is non-deterministic — the last run in any channel wins, and a request for `#marketing` could resume an `#infra-oncall` session instead, exposing privileged context. The [Claude Agent SDK — Sessions](https://code.claude.com/docs/en/agent-sdk/sessions) docs note that `continue: true` is designed for single-process interactive use, not concurrent multi-channel adapters."
  - question: "What fields must an admin audit log record for full requester attribution?"
    answer: "Every `AuditEvent` must include `requesterId` (the platform user ID of the person who triggered the task), `channelId`, `sessionId`, `taskId`, `runId`, and `timestamp`. The `requesterId` must be injected by your adapter layer at task creation time — never derived from model output, because the model can be wrong or prompted to lie. The [Claude Agent SDK — Hooks](https://code.claude.com/docs/en/agent-sdk/hooks) docs describe `PreToolUse` and `PostToolUse` payloads used to populate `toolName`, `toolInput`, and `toolOutput`."
quiz:
  - question: "Multiple users in a Slack channel share a single Claude agent session. Which SDK option correctly implements this channel-scoped model?"
    options:
      - "Pass `continue: true` to automatically resume the most recent session in the working directory"
      - "Pass `resume: channelSessionId` using the channel's stable session ID for every query call"
      - "Pass `resume: userId` to resume each team member's private session on their requests"
      - "Pass `persistSession: false` to keep all requests stateless with no accumulated history"
    correct_idx: 1
    explanation: "`continue: true` resumes the most recent session in cwd, which can belong to any channel — dangerous in a multi-channel deployment. `resume: channelSessionId` targets the exact session keyed to that channel, ensuring all users share the same accumulated history without touching other channels."
    section_anchor: "the-three-execution-contexts"
  - question: "In the Slack-style channel adapter hierarchy, what does `channel_id` map to in SDK terms?"
    options:
      - "A unique run identifier generated fresh for every `query()` call made by the adapter"
      - "The SDK `session_id` stored per channel in the application database and passed to `resume:`"
      - "The user identifier injected into the system prompt for audit log requester attribution"
      - "The artifact path prefix used to scope output storage to a single channel namespace"
    correct_idx: 1
    explanation: "`channel_id` is the primary permission boundary and maps one-to-one to a stable SDK `session_id`. The application persists that `session_id` keyed by `channel_id` and passes it to `resume:` on every subsequent request for that channel. Run IDs, user IDs, and artifact prefixes are derived from other levels of the hierarchy."
    section_anchor: "channel-adapter-identity-mapping"
  - question: "Which audit event field records the Slack user who originally tagged `@Claude`?"
    options:
      - "`taskId` — the UUID assigned to each individual `@Claude` delegation event"
      - "`sessionId` — the SDK session identifier that maps to the channel context"
      - "`requesterId` — the platform user ID of the person who initiated the task"
      - "`runId` — the UUID assigned per `query()` call within the current session"
    correct_idx: 2
    explanation: "`requesterId` is set by the adapter layer at task creation time and injected into every `AuditEvent`. It must come from your application, not from model output. `taskId` scopes a delegation, `sessionId` scopes a channel, and `runId` scopes a single execution attempt — none of these identify the human requester."
    section_anchor: "admin-audit-log-event-schema"
  - question: "You need to verify that channel B cannot read context injected into channel A. Which test pattern should you use?"
    options:
      - "Confirm that the `allowedTools` arrays for both channels contain no shared tool names"
      - "Inject a canary string into channel A and verify that channel B responses do not contain it"
      - "Compare both channels' stored `session_id` values and confirm they point to separate files"
      - "Call `listSessions()` and verify that each channel has exactly one session file"
    correct_idx: 1
    explanation: "The canary test is the only option that validates runtime isolation: channel B's Claude must not retrieve a value from channel A's session history. Confirming different `session_id` values only checks your storage layer; calling `listSessions()` only checks file count; confirming disjoint `allowedTools` checks permissions, not memory isolation."
    section_anchor: "memory-boundaries-and-permission-inheritance"
  - question: "Claude Tag launched in June 2026 on which model, and what budget controls does it expose to administrators?"
    options:
      - "Opus 4.7 with a single organization-level token spend limit set in the admin console"
      - "Opus 4.8 with both organization-level and per-channel token spend caps configurable by admins"
      - "Sonnet 4.6 with per-user token caps tied to individual Slack workspace user accounts"
      - "Haiku 4.5 with soft budget alert thresholds that notify admins when a channel overspends"
    correct_idx: 1
    explanation: "Claude Tag runs on Opus 4.8 (distinct from Opus 4.7) and exposes two-tier budget controls: an organization-level cap and a per-channel cap. In SDK terms these map to a global guard plus a per-channel `maxBudgetUsd` enforced by cumulative spend tracking in application state. Per-user caps and soft alerts are not part of the Claude Tag model."
    section_anchor: "claude-tag-the-production-reference"
---

Channel-scoped agents share a single SDK session across all users in a Slack channel, enforced at the `channel_id` boundary. This chapter adds the channel adapter, memory isolation rules, and an admin audit log to the incident-triage agent from ch 6, using [Claude Tag](https://www.anthropic.com/news/introducing-claude-tag) as the production reference pattern for multiplayer delegation and per-channel budget controls.

## The Three Execution Contexts

The SDK supports three distinct ways to scope an agent's memory and identity. Choose the wrong one and you either leak context across users or lose continuity across turns.

**Per-task run.** A single `query()` call with no `resume` option. Each request is stateless: Claude sees only the current prompt, with no accumulated history. Right for one-shot jobs where isolation matters more than continuity — a CI check, a single data transform.

**Per-user session.** One session per user, resumed with a user-specific `session_id`. Each user's conversation history is private, accumulated only from their turns. The single-user harness from ch 2 uses this model. Covered in [[Turn a prompt script into a controllable agent harness]].

**Channel-scoped shared context.** A single session shared across every requester in a channel. All team members contribute to and read from the same accumulated history, so Claude can "pick up the conversation from where the last person left off." This is the model [Claude Tag](https://www.anthropic.com/news/introducing-claude-tag) uses in production, and the model this chapter implements.

<KnowledgeCheck
  question="A team wants Claude to remember context from a colleague's earlier request in the same Slack channel. Which execution model fits?"
  options={["Per-task run with no resume option", "Per-user session with a user-specific session_id", "Channel-scoped shared context with a single channel session_id", "Per-task run with persistSession: false"]}
  correctIdx={2}
  explanation="Only the channel-scoped model shares accumulated history across requesters. Per-user and per-task models produce private or stateless contexts — a second user would see no evidence of the first."
/>

## Claude Tag: The Production Reference

[Anthropic's Claude Tag](https://www.anthropic.com/news/introducing-claude-tag), launched on 2026-06-23 for Claude Enterprise and Team customers, is the canonical production pattern for channel-scoped agents. It runs on **Opus 4.8** in Slack: a user tags `@Claude`, the agent plans and executes stages with available tools, and responds in the thread.

Claude Tag expresses the full multiplayer architecture:

- **Channel-level permissions.** Admins define which tools and information each channel can access. A `#security-incidents` channel might have `Bash`; `#marketing-copy` does not. Permission sets are fully independent per channel, not per user.
- **Isolated channel identities.** The agent instance for the sales channel has zero access to engineering-channel history — enforced at the channel permission boundary, not the user level.
- **Two-tier budget controls.** Admins set token-spend limits at both the organization level and per channel. In SDK terms: a global cap plus a per-channel `maxBudgetUsd` you enforce by accumulating `ResultMessage.total_cost_usd` across runs. *(Sonnet 5 migration note: the Sonnet 5 tokenizer produces ~30% more tokens for equivalent prompts, and adaptive thinking creates additional text-only decision turns that count toward `total_cost_usd`. Rebaseline your per-channel budget thresholds when migrating from Sonnet 4.x.)*
- **Full activity log with requester attribution.** Admins view everything Claude did and who requested each task — the audit schema you will implement below.
- **Ambient mode.** When enabled, Claude proactively flags relevant updates and schedules tasks for itself over hours or days. This requires a persistent harness with an event-driven wake mechanism; it is not covered in this chapter.

## Channel Adapter Identity Mapping

The SDK has no native concepts of workspace, channel, thread, or user. Your adapter layer maps platform IDs to SDK primitives:

```
Workspace ID
  └─ Channel ID          ← one SDK session_id (primary permission boundary)
       └─ Thread ID      ← Slack thread timestamp; used for response routing
            └─ User ID   ← requester attribution in prompt + audit log
                 └─ Task ID  ← one @Claude delegation (application UUID)
                      └─ Run ID   ← one query() call
                           └─ Artifact IDs  ← <channel_id>/<task_id>/<name>
```

The critical mapping is **`channel_id` → `session_id`**. Capture the SDK `session_id` from the init `SystemMessage`'s `message.session_id` on the first run, persist it in your application database keyed by `channel_id`, and pass it to `resume:` on every subsequent call for that channel.

Never use `continue: true` in a multi-channel deployment. It resumes the most recent session in the working directory — which may belong to a different channel.

```typescript
for await (const message of query({ prompt, options })) {
  if (message.type === "system" && message.subtype === "init") {
    ctx.sessionId = message.session_id; // persist to DB keyed by channel_id
  }
}
```

<KnowledgeCheck
  question="Your multi-channel deployment runs all channels from the same working directory. A developer suggests using `continue: true` for simplicity. What is the risk?"
  options={["`continue: true` requires a session file to already exist on disk", "`continue: true` resumes the most recent cwd session, which may belong to another channel", "`continue: true` creates a new session on every call, losing accumulated history", "`continue: true` is not a valid option in the TypeScript SDK"]}
  correctIdx={1}
  explanation="`continue: true` resolves to whichever session was most recently written in the working directory. In a multi-channel deployment that's non-deterministic — the last run in any channel wins. Explicit `resume: channelSessionId` is the only reliable option."
/>

## Memory Boundaries and Permission Inheritance

Channel isolation is not enforced by the SDK — it is your application's responsibility. Four rules keep channels from bleeding into each other:

1. **One session per channel.** Never share or merge `session_id` values across channels. A misrouted `session_id` gives the recipient full read access to another channel's history.
2. **Explicit `allowedTools` per channel, with `permissionMode: "dontAsk"`.** In `dontAsk` mode, any tool not on the `allowedTools` list is hard-denied — no fallback to `canUseTool`. Tool schema design for individual tools is covered in ch 3.
3. **No `bypassPermissions` in channel agents.** Subagents inherit the parent's permission mode and cannot override it. `bypassPermissions` grants every subagent unconditional access to all tools.
4. **Artifact namespace prefixing.** Store all outputs under `<channel_id>/<task_id>/<artifact_name>` to prevent cross-channel artifact reads via tool calls.

Permission evaluation order from the [Claude Agent SDK permissions docs](https://code.claude.com/docs/en/agent-sdk/permissions): Hooks → Deny rules → Ask rules → Permission mode → Allow rules → `canUseTool`. Populate both `allowedTools` (positive grant) and `disallowedTools` (hard blocklist). Do not rely on `canUseTool` as your primary gate — it is a last resort, not an enforcement mechanism.

## Admin Audit Log Event Schema

Build the log from SDK hooks. Every `PreToolUse` and `PostToolUse` event carries `session_id`, `hook_event_name`, `tool_name`, and `tool_input`. `PostToolUse` also carries the tool result. Correlate pre/post pairs via `tool_use_id`.

```typescript
interface AuditEvent {
  eventId: string;        // UUID per event
  taskId: string;         // one @Claude delegation
  runId: string;          // one query() call
  sessionId: string;      // SDK session_id — maps to channelId
  channelId: string;
  requesterId: string;    // set by adapter layer, never derived from model output
  eventType: "tool_read" | "tool_write" | "tool_call" | "decision" | "spend";
  toolName: string | null;
  toolInput: unknown | null;  // sanitise secrets before persisting
  toolOutput: unknown | null;
  costUsd: number | null;
  timestamp: string;          // ISO 8601
}
```

Wire the hooks via the [Claude Agent SDK hooks docs](https://code.claude.com/docs/en/agent-sdk/hooks):

```typescript
const options = {
  hooks: {
    PreToolUse:  [{ hooks: [makeAuditHook(ctx)] }],
    PostToolUse: [{ hooks: [makeAuditHook(ctx)] }],
  },
};
```

Text-only model turns — Claude thinking out loud or issuing a recommendation without calling a tool — do not fire tool hooks. Capture these by processing `AssistantMessage` objects in your message stream loop and emitting `eventType: "decision"` records.

<Callout type="warning">
**Requester attribution must come from your adapter layer, not from model output.** Inject `requesterId` at task creation time and stamp every `AuditEvent` with it. Never derive the requester from what Claude says — the model can be wrong, and an attacker can prompt it to lie.
</Callout>

## Hands-On Exercise

Extend the incident-triage agent from ch 6 to support two Slack channels: `#infra-oncall` and `#product-alerts`. Each channel should have its own isolated session and a distinct `allowedTools` list (`#infra-oncall` allows `Bash`; `#product-alerts` does not).

**Steps:**

1. Create a `ChannelContextStore` (in-memory Map for now) keyed by `channel_id`. Store `sessionId`, `allowedTools`, and `totalSpendUsd` per entry.
2. On each simulated `@Claude` mention, call `handleChannelRequest(channelId, userId, threadId, prompt, ctx)`. Capture and persist `session_id` from the init `SystemMessage`.
3. Wire `PreToolUse` and `PostToolUse` hooks that write `AuditEvent` records to a local JSON file, including `requesterId` injected from the caller.
4. Run the CANARY leakage test: inject `"CANARY-INFRA"` into `#infra-oncall`, then ask `#product-alerts` "what was discussed earlier?" — the string must not appear.

**Success criteria:**
- The CANARY string never surfaces in `#product-alerts` responses.
- `#product-alerts` returns a hard denial if a request triggers a `Bash` tool call.
- The audit log JSON contains at least one `PreToolUse` event with `channelId`, `requesterId`, and `toolName` populated.
- Cumulative spend is tracked per channel and would trigger a budget block if it exceeded `maxBudgetUsdPerRun`.

You have completed the course. Return to [[Ship the smallest useful Claude Agent SDK app]] to build a new agent from scratch applying everything you have shipped across these seven chapters.
