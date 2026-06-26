---
date: 2026-06-15
author: chapter-author-3
vendor_tag: OpenAI
content_type: course-chapter
course_slug: openai-realtime-api-voice-agents-end-to-end
chapter_num: 5
chapter_slug: production-deployment-scaling
title: "Production Deployment and Scaling"
duration_min: 65
prerequisites:
  - "Chapter 3: Tool Calling in a Live Voice Session"
  - "Chapter 4: Latency Engineering — Making Voice Feel Fast"
learning_objectives:
  - "Deploy a WebSocket voice agent server with horizontal scaling and sticky sessions"
  - "Implement session lifecycle management: timeouts, reconnects, and orphan session cleanup"
  - "Apply compliance guardrails: PII redaction from transcripts, audit logging of all tool calls"
  - "Set up cost controls: per-session token budgets, model fallback on quota exhaustion"
whats_new:
  - "Sticky session architecture for horizontal WebSocket scaling"
  - "Durable reconnect protocol with Postgres-backed conversation history"
  - "PII redaction pipeline for transcript compliance"
  - "Per-session token budgets with graceful budget-exhaustion handling"
status: g4-approved
description: "Deploy a voice agent to production: nginx sticky-session config, Postgres-backed reconnect protocol with item-type filtering, PII redaction pipeline, audit log schema, and per-session token budget enforcement."
last_updated: 2026-06-15
reading_time_min: 18
tags: [OpenAI, Realtime-API, Voice-Agents, Production, Scaling, WebSocket, PII, Compliance, Cost-Control]
positions: []
faq:
  - question: "How do sticky sessions work for horizontal WebSocket voice agent scaling?"
    answer: "Sticky sessions route every request from a given client to the same upstream server for the life of the connection, using a signal like client IP (`ip_hash` in nginx) or a session-scoped cookie. This is necessary because WebSocket voice session state — conversation history, VAD buffer, pending tool calls — lives in server process memory, not in a shared external store. A reconnect that lands on a different server has no state and must open a fresh model session, losing all prior context. The [nginx upstream module](http://nginx.org/en/docs/http/ngx_http_upstream_module.html) provides `ip_hash` as the simplest sticky routing mechanism for most deployments."
  - question: "What must a reconnect handler do when the OpenAI Realtime API drops a TCP connection?"
    answer: "The OpenAI Realtime API starts fresh on every new TCP connection with no server-side session persistence across drops. Your reconnect handler must query your Postgres session history store for all conversation items from the previous connection, re-inject each one in order via `conversation.item.create` before the user's first utterance, and resend the original session configuration via `session.update`. Without this replay, the model has no context for what was said before the drop and the user's session appears to restart from scratch. See the [OpenAI Realtime API reference](https://developers.openai.com/api/reference/resources/realtime) for the full `conversation.item.create` event schema."
  - question: "Why must PII redaction happen at transcript write time rather than as a scheduled batch job?"
    answer: "Applying redaction at write time prevents raw PII from ever entering persistent storage. A batch job running later leaves a window — potentially hours — during which a service outage, backup run, logging middleware, or unauthorized read could expose unredacted transcripts containing card numbers, SSNs, or phone numbers. In regulated domains such as healthcare or finance, that window constitutes a compliance violation regardless of intent. Regex-based redaction at write time adds negligible latency. For unstructured PII like proper names, follow with an async NLP enrichment pass after the synchronous write to cover the longer tail without blocking the hot path. See the [OpenAI Realtime API guide](https://developers.openai.com/api/docs/guides/realtime) for data handling considerations around voice transcripts."
---

# Voice Agent Scaling Is a State Problem, Not a Load Balancing Problem

The path to horizontal scaling for WebSocket voice agents is not adding servers — it's routing each session to exactly one server and keeping it there. This chapter gives you a runnable nginx sticky-session configuration, a Postgres-backed reconnect protocol, a PII redaction pipeline for transcripts, an audit log schema that captures every tool call, and a per-session token budget with graceful exhaustion handling. All four production concerns, working together.

## Why Stateless Scaling Breaks Voice Sessions

In a stateless HTTP service, any server can handle any request — there is no per-client state. The load balancer can round-robin freely. Voice agents are the opposite. A WebSocket voice session accumulates state on the server that established the connection: the model's conversation history, the VAD buffer state, the pending tool call map from Chapter 3, and the session configuration. None of that lives in the load balancer. It lives in the server process's heap.

When your load balancer sends a reconnect request to a different server — which is the default with round-robin or least-connections balancing — the new server has none of that state. It opens a fresh model session. The user's conversation context is gone. If they asked about their account balance two turns ago, the agent no longer knows. If a tool call was in flight when the reconnect happened, the `call_id` is orphaned. The session appears to restart from scratch.

Two architectures avoid this failure. **Sticky sessions**: the load balancer commits all requests from a given client to the same upstream server for the life of the connection. **Shared session state**: all servers write live state to Redis or Postgres so any server can serve any session. Shared state sounds more resilient, but it introduces a remote store roundtrip on every streaming event — at 10–20 events per second in a live voice session, that's a Redis read on every audio delta. Teams that choose shared state as their first architecture consistently report that the latency cost alone makes it non-viable without a caching layer that reintroduces the consistency problems they were trying to solve. Start with sticky sessions.

<KnowledgeCheck
  question="Why does round-robin load balancing break WebSocket voice sessions?"
  options={[
    "WebSocket connections require HTTPS, which round-robin load balancers do not support",
    "Round-robin can route a reconnect to a different server, which holds none of the live session state",
    "The OpenAI Realtime API rate-limits connections originating from multiple server IPs",
    "Round-robin terminates WebSocket connections after 60 seconds as a protocol enforcement"
  ]}
  correctIdx={1}
  explanation="Voice session state lives in the server process memory. Round-robin routing can send a reconnect to a different server with no knowledge of the previous session, losing conversation history, VAD state, and any in-flight tool calls."
/>

## Sticky Sessions with nginx

The `ip_hash` directive in the [nginx upstream module](http://nginx.org/en/docs/http/ngx_http_upstream_module.html) routes requests from the same client IP to the same upstream server. For most voice agent deployments — browser clients, mobile apps, dedicated call-center workstations — client IPs are stable within a session, making `ip_hash` a reliable default.

```nginx
# nginx.conf — sticky WebSocket proxy for voice agents
upstream voice_agents {
    ip_hash;                          # same client IP → same upstream, consistently
    server 10.0.0.1:3000;
    server 10.0.0.2:3000;
    server 10.0.0.3:3000;
    keepalive 64;                     # persistent upstream connection pool
}

server {
    listen 443 ssl;
    server_name api.your-domain.com;

    location /voice {
        proxy_pass http://voice_agents;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 3600s;     # hold open for up to 1 hour
        proxy_send_timeout 3600s;
    }
}
```

The `proxy_http_version 1.1` and the `Upgrade`/`Connection` headers are required for WebSocket proxying — without them, nginx treats the connection as HTTP/1.0 and the upgrade handshake fails silently.

For deployments where clients share a corporate NAT gateway — a common call-center scenario where hundreds of agents appear to originate from a single IP — `ip_hash` breaks down: all sessions land on one upstream server. In that case, use AWS ALB's [session stickiness by cookie](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/sticky-sessions.html) or nginx Plus's `sticky cookie` directive to route by a session-scoped cookie instead.

<Callout type="warning">
**Set proxy timeouts to match your session duration.** nginx's default `proxy_read_timeout` is 60 seconds. A user silent for 90 seconds — pausing to think, interrupted by a notification — will have their connection dropped by the proxy even though the underlying session is alive. Set `proxy_read_timeout` and `proxy_send_timeout` to at least `3600s` for voice workloads. The [OpenAI Realtime API](https://developers.openai.com/api/docs/guides/realtime) sends periodic keepalive pings on the WebSocket; ensure your proxy forwards rather than strips them.
</Callout>

## Session Lifecycle Management

Production sessions end in three ways: the user disconnects cleanly, the network drops, or the server restarts. Each requires a different code path.

**Idle timeouts.** Track the timestamp of the last `input_audio_buffer.speech_started` event. Schedule a teardown if no user speech arrives within your tolerance window. Five minutes is a reasonable default for customer support; 30 seconds for kiosk deployments where idle sessions block hardware resources.

```typescript
// session-manager.ts
const IDLE_TIMEOUT_MS = 5 * 60 * 1000;

class VoiceSession {
  private idleTimer: NodeJS.Timeout | null = null;

  resetIdleTimer(): void {
    if (this.idleTimer) clearTimeout(this.idleTimer);
    this.idleTimer = setTimeout(() => this.teardown("idle_timeout"), IDLE_TIMEOUT_MS);
  }

  async teardown(reason: string): Promise<void> {
    console.log(`[session:${this.id}] teardown — reason: ${reason}`);
    await this.persistConversationHistory();
    await this.flushAuditLog();
    this.ws.close(1000, reason);
  }
}
```

**Reconnect protocol.** The [Realtime API](https://developers.openai.com/api/reference/resources/realtime) does not persist session context across dropped TCP connections. Each reconnect opens a fresh model session with no history. Your server must maintain its own durable history store: after each `conversation.item.created` server event, write the item to Postgres keyed by session ID. On reconnect, re-inject stored items into the new session via `conversation.item.create` before the user's first utterance.

**Critical: not all stored item types survive `conversation.item.create` replay.** The API accepts `function_call`, `function_call_output`, and `message` items whose content consists only of `text` or `input_text` parts. It rejects assistant audio items — turns where the model responded with speech, stored as `content.type: "audio"` — silently or with an error depending on the client. This is the central production footgun for reconnect implementations: teams store every `conversation.item.created` event faithfully, then replay the full history and discover audio items are dropped or cause 400s, corrupting the context injection order. Filter at replay time. Convert assistant audio turns to text using the transcript captured from the preceding `response.audio_transcript.done` event if you need to preserve them as context; otherwise skip them.

```typescript
// reconnect-handler.ts
async function handleReconnect(sessionId: string, ws: WebSocket): Promise<void> {
  const { rows } = await db.query(
    `SELECT item_payload FROM session_history
     WHERE session_id = $1 ORDER BY seq ASC`,
    [sessionId]
  );

  let replayed = 0;
  for (const row of rows) {
    const item = JSON.parse(row.item_payload);

    // conversation.item.create cannot populate assistant audio items.
    // Replay only: function_call, function_call_output, and message items
    // whose content parts are exclusively text/input_text.
    const replayable =
      item.type === "function_call" ||
      item.type === "function_call_output" ||
      (item.type === "message" &&
        Array.isArray(item.content) &&
        item.content.every(
          (c: { type: string }) => c.type === "text" || c.type === "input_text"
        ));
    if (!replayable) continue;

    ws.send(JSON.stringify({
      type: "conversation.item.create",
      item,
    }));
    replayed++;
  }

  ws.send(JSON.stringify({
    type: "session.update",
    session: await loadSessionConfig(sessionId),
  }));

  console.log(`[session:${sessionId}] reconnected — ${replayed}/${rows.length} history items restored`);
}
```

**Orphan cleanup.** When a server crashes, sessions in its memory die without a clean teardown. Their records in the session store remain open. Run a background sweep every five minutes that queries for sessions with a `last_heartbeat` older than your idle timeout and marks them closed, freeing associated locks and audit log handles.

<KnowledgeCheck
  question="What must a server do when a client reconnects after a network drop with the OpenAI Realtime API?"
  options={[
    "Nothing — the Realtime API automatically preserves session state across dropped TCP connections",
    "Re-inject stored conversation history via conversation.item.create before the user's first utterance",
    "Replay the raw audio buffer from the beginning so the model reconstructs context from speech",
    "Require the user to explicitly request context restoration via a spoken command"
  ]}
  correctIdx={1}
  explanation="The Realtime API starts fresh on every new connection. Your server must maintain a durable conversation history store and replay it into the new session via conversation.item.create before the user speaks, so the model has the context it needs to continue coherently."
/>

## PII Redaction from Transcripts

The Realtime API emits transcripts via `response.audio_transcript.done` events. If your agent operates in a regulated domain — healthcare, finance, insurance, customer support — those transcripts contain structured PII: card numbers, SSNs, phone numbers, and email addresses spoken aloud by users. Writing raw transcripts to any persistent store exposes your system to compliance violations.

Redact before you write. Apply the redaction pass to each transcript before it is inserted into your database, not as a post-processing job that runs later — a service outage during that window leaves raw PII in your store.

```typescript
// pii-redactor.ts
const PII_PATTERNS: Array<{ pattern: RegExp; replacement: string }> = [
  { pattern: /\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b/g,       replacement: "[CARD_REDACTED]" },
  { pattern: /\b\d{3}-\d{2}-\d{4}\b/g,                            replacement: "[SSN_REDACTED]" },
  { pattern: /\b(\+1\s?)?\(?\d{3}\)?[- .]?\d{3}[- .]?\d{4}\b/g, replacement: "[PHONE_REDACTED]" },
  { pattern: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g, replacement: "[EMAIL_REDACTED]" },
];

export function redactPII(text: string): string {
  return PII_PATTERNS.reduce((t, { pattern, replacement }) => t.replace(pattern, replacement), text);
}

// In your event handler:
case "response.audio_transcript.done": {
  const safeTranscript = redactPII(event.transcript);
  await db.query(
    "INSERT INTO session_transcripts (session_id, role, content) VALUES ($1, $2, $3)",
    [sessionId, "assistant", safeTranscript]
  );
  break;
}
```

Regex catches structured PII reliably. For unstructured PII — a person's full name spoken mid-sentence — route transcripts through a cloud NLP entity-detection pass before final long-term storage. The regex handles the highest-risk tokens synchronously at write time; NLP handles the longer tail in an async enrichment job. Do not rely on regex alone when asserting compliance to an auditor.

<KnowledgeCheck
  question="When should PII redaction be applied to voice session transcripts?"
  options={[
    "As a nightly batch job over all transcripts stored in the previous 24 hours",
    "At write time, before the transcript is inserted into any persistent store",
    "Only for transcripts that explicitly contain credit card numbers, not all sessions",
    "After the session ends, triggered by the user's explicit consent to data processing"
  ]}
  correctIdx={1}
  explanation="Applying redaction at write time — before the transcript enters any store — eliminates the window where raw PII can be exposed by a service outage, backup, or logging middleware. Post-processing jobs leave raw data in place until they run."
/>

## Audit Logging All Tool Calls

Every tool call your agent makes must be traceable for debugging and compliance: which session, which tool, with which arguments, at what time, for how long, and what the result was. This is the minimum audit record for explaining agent behavior to a customer, an auditor, or your own engineering team when a session goes wrong.

```typescript
// audit-logger.ts
interface ToolCallLog {
  sessionId:  string;
  callId:     string;
  toolName:   string;
  arguments:  Record<string, unknown>;
  result:     unknown;
  errorMsg:   string | null;
  durationMs: number;
  timestamp:  string;
}

async function logToolCall(log: ToolCallLog): Promise<void> {
  await db.query(
    `INSERT INTO tool_call_audit
       (session_id, call_id, tool_name, arguments, result, error_msg, duration_ms, called_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [
      log.sessionId, log.callId, log.toolName,
      JSON.stringify(log.arguments), JSON.stringify(log.result),
      log.errorMsg, log.durationMs, log.timestamp,
    ]
  );
}

// Wrap dispatchTool from Chapter 3:
async function auditedDispatch(
  sessionId: string, callId: string,
  name: string, args: Record<string, unknown>
): Promise<void> {
  const start = Date.now();
  let result: unknown = null;
  let errorMsg: string | null = null;

  try {
    result = await runTool(name, args);
    injectResult(callId, JSON.stringify(result));
  } catch (err) {
    errorMsg = err instanceof Error ? err.message : "unknown error";
    injectResult(callId, JSON.stringify({ error: errorMsg }));
  } finally {
    // always logs — even if runTool throws or injectResult fails
    await logToolCall({
      sessionId, callId, toolName: name, arguments: args,
      result, errorMsg,
      durationMs: Date.now() - start,
      timestamp: new Date().toISOString(),
    });
  }
}
```

The `finally` block guarantees a log entry even on error paths. An audit log with gaps is worse than no audit log — the gaps look like evidence tampering, not system failures.

Set a retention policy when you design the schema. Most compliance frameworks require audit records for 6–12 months; regulated healthcare and financial services contexts can mandate 7 years or more. Keep your audit table in a separate Postgres database from your conversation data — a single database failure should not simultaneously take down your voice service and its compliance evidence. Add an `archived_at` column and run a weekly job to move records older than your hot window to cold storage, keeping the table fast for recent incident queries.

For incident triage, the audit log supports two essential query patterns: all tool calls for a specific session (for a customer complaint) and all calls to a specific tool across sessions in a given time window (for diagnosing a bug introduced by a tool code change). Index on `(session_id, called_at)` and `(tool_name, called_at)` separately — the first query drives customer support workflows; the second drives engineering postmortems.

## Per-Session Token Budgets and Model Fallback

A 30-minute customer support call can consume 50,000+ tokens. Without a budget, one runaway session — a confused user who keeps repeating themselves — can consume a disproportionate share of your monthly quota. The `response.done` event carries a `usage` object with token counts for each completed model turn.

```typescript
// budget-manager.ts
const MAX_TOKENS_PER_SESSION = 50_000;

class BudgetManager {
  private tokenCount = 0;

  consumeTokens(usage: { total_tokens: number }): boolean {
    this.tokenCount += usage.total_tokens;
    return this.tokenCount < MAX_TOKENS_PER_SESSION;
  }
}

// In your event handler:
case "response.done": {
  const withinBudget = budget.consumeTokens(event.response.usage);
  if (!withinBudget) {
    // Inject a closing message and schedule graceful teardown
    ws.send(JSON.stringify({
      type: "conversation.item.create",
      item: {
        type: "message",
        role: "assistant",
        content: [{
          type: "text",
          text: "I need to wrap up our session — we've reached the session limit. Is there anything final you need before we close?"
        }],
      },
    }));
    ws.send(JSON.stringify({ type: "response.create" }));
    setTimeout(() => session.teardown("budget_exhausted"), 15_000);
  }
  break;
}
```

For API-level quota exhaustion — OpenAI returns an error event on the WebSocket when you hit a rate limit — implement a fallback that injects a human-readable apology and closes the session cleanly. Do not let the connection hang in an error state; the user should hear a verbal acknowledgment before the call drops.

Distinguish between soft and hard budget limits in your implementation. A soft limit triggers the closing message and starts a graceful teardown countdown, as shown above. A hard limit disconnects immediately when the countdown expires. In practice, giving users a 15–30 second warning before disconnecting is the minimum courteous behavior — the alternative is a voice call that falls silent, which in customer support contexts reads as a system failure rather than a designed boundary. Log all budget exhaustion events with the session ID and final token count: these records reveal which user flows generate the most expensive sessions, directly informing prompt engineering and tool dispatch improvements that reduce cost without degrading call quality.

<KnowledgeCheck
  question="Which Realtime API server event carries the per-turn token usage data you need for budget tracking?"
  options={[
    "session.created — emitted once when the session opens with total token allocation",
    "response.done — emitted after each complete model turn with a usage object",
    "rate_limit_exceeded — emitted when token budget is consumed and the session must close",
    "response.audio_transcript.done — includes token counts alongside the transcript text"
  ]}
  correctIdx={1}
  explanation="response.done fires after every complete model response turn. Its payload includes a usage object with input_tokens, output_tokens, and total_tokens for that turn — accumulate these across turns to track session-level consumption against your budget."
/>

## Hands-On Exercise: Two-Server Deployment with Full Audit Trail

Deploy your Chapter 3 agent to a two-server Node.js cluster behind the nginx sticky-session configuration from this chapter.

**What to build:**
1. Two Node.js server instances on different ports, both running your voice agent
2. nginx `ip_hash` routing both instances with `proxy_read_timeout 3600s`
3. A Postgres table `tool_call_audit` with the schema above
4. A `BudgetManager` tracking tokens per session, limit set to 10,000 for the exercise
5. A `handleReconnect` function that restores conversation history from a `session_history` table

**Success criteria:**

1. **Sticky routing**: Start two sessions from the same machine. Both must route to the same upstream server — verify by checking server process logs for session IDs.
2. **Reconnect**: Kill one server instance mid-conversation, restart it, reconnect the client. Confirm the model references prior conversation context correctly in the first post-reconnect turn.
3. **Audit log**: After a 5-minute session with at least 3 tool calls, query `SELECT * FROM tool_call_audit WHERE session_id = '<your id>'`. Every tool call must appear with correct arguments, result, and a duration under 500ms for mocked tools.
4. **Budget cap**: Reduce the limit to 5,000 tokens and hold a conversation until it exhausts. Verify the agent delivers the closing message rather than silently dropping the connection.

Once all four criteria pass, your deployment handles the production concerns that separate a demo from a shippable service: sticky scaling, resilient reconnection, complete tool call auditability, and bounded cost per session.

For cost modeling across Realtime API vs Whisper + LLM + Kokoro architectures, see [[06-cost-quality-model-tradeoffs]] — the next chapter compares true per-session costs across all three stacks. For multi-agent coordination patterns in production, including per-tenant budget isolation, the [[cursor-composer-2]] course covers horizontal agent scaling in depth. For tool-call architecture and MCP integration patterns that complement this chapter's audit logging approach, see [[claude-mcp-mastery]].
