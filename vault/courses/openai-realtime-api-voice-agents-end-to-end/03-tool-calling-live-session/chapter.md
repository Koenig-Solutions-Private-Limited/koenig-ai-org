---
date: 2026-06-15
author: chapter-author-1
vendor_tag: openai
content_type: course-chapter
course_slug: openai-realtime-api-voice-agents-end-to-end
chapter_number: 3
chapter_slug: tool-calling-live-session
title: "Your Voice Agent Can Now Do Things: Tool Calling in a Live Session"
description: "Add tools to your voice agent: register functions in session.update, dispatch them without blocking the audio stream, inject results via conversation.item.create + response.create, and recover verbally from errors — with runnable TypeScript for every step."
slug: openai-realtime-api-voice-agents-ch03-tool-calling-live-session
learning_objectives:
  - "Register function tools in a Realtime session and handle response.function_call events"
  - "Execute tools server-side without breaking the audio stream (non-blocking tool dispatch)"
  - "Inject tool results back into the session via conversation.item.create and response.create"
  - "Handle tool errors gracefully — the agent must recover verbally, not crash silently"
whats_new:
  - "Complete TypeScript runnable examples for tool registration, async dispatch, and result injection"
  - "200ms SLA design pattern with verbal acknowledgment fallback for slow tools"
  - "Error recovery pattern: always inject a result so the model speaks, never goes silent"
status: g3-passed
last_updated: 2026-06-15
reading_time_min: 60
positions: []
faq:
  - question: "Why must tool dispatch be non-blocking in the OpenAI Realtime API?"
    answer: "Tool dispatch must be non-blocking because the OpenAI Realtime API runs over a persistent WebSocket where audio events arrive continuously. Awaiting a tool call inside the WebSocket message handler blocks Node.js's single-threaded event loop, preventing the handler from processing incoming messages — including barge-in signals and user audio chunks — for the entire duration of tool execution. By firing dispatchTool without await, the event loop stays free, keeping your agent responsive to new speech while the tool runs in the background. See the [OpenAI Realtime API reference](https://developers.openai.com/api/reference/resources/realtime) for the event model details."
  - question: "How do you inject a tool result back into a live voice session?"
    answer: "After your tool resolves, send two back-to-back WebSocket messages: first a conversation.item.create event with a function_call_output item (where call_id exactly matches the id from the original response.output_item.added event and output is the JSON-serialized result string), then immediately a response.create event to trigger the model's next verbal turn. Without response.create, the tool result sits in conversation history but the model generates no speech and the user hears silence. Both events are required, sent back-to-back, for the model to incorporate the result and resume speaking. See the [OpenAI Realtime API reference](https://developers.openai.com/api/reference/resources/realtime) for the full event contract."
  - question: "What happens if you skip response.create after conversation.item.create?"
    answer: "Without response.create, the function_call_output item is stored in the session's conversation history and the model has access to the tool result, but it never begins a new output turn. The model waits indefinitely for an explicit trigger to generate speech. The user hears silence on the line, which in a voice session feels like a crash or hang-up. This is a common mistake in the injection loop: both events are always required. See the [OpenAI Realtime API reference](https://developers.openai.com/api/reference/resources/realtime) for the response lifecycle."
---

# Your Voice Agent Can Now Do Things: Tool Calling in a Live Session

Register tools in `session.update`, listen for `response.function_call_arguments.done`, dispatch your implementation asynchronously so the WebSocket stays alive, inject the result with `conversation.item.create` + `response.create`, and wrap everything in error handling so your agent speaks a recovery phrase instead of going silent. That is the complete tool calling loop for a live voice session — and this chapter gives you runnable TypeScript for every step.

## Why Voice Tool Calling Is Different From Text

In a Chat Completions tool call, the user sends a message and waits for a response. A two-second tool execution is annoying but tolerable. The user is not listening — they submitted a form and walked away mentally. In a live voice session, the user is still on the line. Their ear is trained on your agent's output stream. The moment the model decides to call a tool, audio stops, and the user hears silence. Every millisecond of tool latency is perceptible dead air.

This is the governing constraint for everything in this chapter: **voice tool calls need a latency budget**. Target 200ms end-to-end — from the moment the model issues the call to the moment the first audio token of the model's verbal response begins streaming. If your tool cannot hit that SLA, you buffer the gap with a verbal acknowledgment: the model speaks "Let me check that for you" while the real tool runs in the background. You will implement both strategies below.

The other difference is the execution model. The [OpenAI Realtime API](https://developers.openai.com/api/docs/guides/realtime) runs over a persistent WebSocket connection where events arrive continuously. Tool calling is not a single request/response exchange — it is a sequence of events streaming in over time. You accumulate argument fragments, detect completion, fire the tool, and inject a result — all without breaking the event loop that keeps your WebSocket processing new audio from the user.

There is also a model-level difference worth naming explicitly. In Chat Completions, tool calls are part of an atomic response: the model generates a function call in one shot and the API returns it synchronously. In the Realtime API, the model is generating tokens continuously inside a live session. It decides mid-stream to call a tool, emits that decision as a stream of events, and then pauses output until you inject a result. Your server code must observe those events, execute the tool entirely outside the model's processing, and re-enter the session with a result. The model does not pause and call you — you watch its output stream, respond when it acts, and feed it what it needs to continue speaking.

## Registering Tools in a Realtime Session

Tools are declared in `session.update` using the same JSON Schema format as Chat Completions. Add a `tools` array and set `tool_choice: "auto"` to let the model decide when to call.

```typescript
// session-with-tools.ts
import WebSocket from "ws";

const ws = new WebSocket(
  "wss://api.openai.com/v1/realtime?model=gpt-realtime-2.1",
  {
    headers: {
      Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
    },
  }
);

ws.on("open", () => {
  ws.send(
    JSON.stringify({
      type: "session.update",
      session: {
        modalities: ["text", "audio"],
        voice: "alloy",
        turn_detection: { type: "server_vad", silence_duration_ms: 500 },
        tool_choice: "auto",
        tools: [
          {
            type: "function",
            name: "get_weather",
            description:
              "Get current weather for a location. Returns temperature in Celsius and a short condition string like 'partly cloudy'.",
            parameters: {
              type: "object",
              properties: {
                location: {
                  type: "string",
                  description: "City name, e.g. 'London' or 'New York'",
                },
              },
              required: ["location"],
            },
          },
          {
            type: "function",
            name: "create_reminder",
            description:
              "Create a reminder for the user. Returns the reminder ID and confirms the scheduled time.",
            parameters: {
              type: "object",
              properties: {
                text: { type: "string", description: "Reminder message content" },
                time: {
                  type: "string",
                  description: "ISO 8601 datetime string, e.g. '2026-06-15T15:00:00Z'",
                },
              },
              required: ["text", "time"],
            },
          },
        ],
      },
    })
  );
});
```

Tool descriptions are not documentation — they are instructions the model reads at inference time to decide whether and how to call the tool. A vague description like `"Gets weather"` leads to missed calls and poor argument population. Specific descriptions that include the return format (`"Returns temperature in Celsius and a short condition string"`) help the model compose natural verbal responses after the tool completes. Write descriptions the way you would brief a human assistant who has never used the tool before.

<KnowledgeCheck
  question="What does setting tool_choice: 'auto' tell the Realtime API model?"
  options={[
    "The model will call a tool on every single turn without exception",
    "The model contextually decides whether any tool call is needed for each turn",
    "The user selects the active tool interactively during the session",
    "Tool calling is disabled; the model will respond without tools"
  ]}
  correctIdx={1}
  explanation="'auto' means the model applies its reasoning to decide whether a tool call is appropriate for each turn. Setting tool_choice to a specific function name forces that tool on every response, which is rarely what you want."
/>

## Handling response.function_call Events

When the model decides to call a tool, it emits a sequence of events you must handle in order. Each tool call starts with `response.output_item.added` — carrying the tool name and a unique item ID — then streams argument JSON in fragments via `response.function_call_arguments.delta`, and signals completion with `response.function_call_arguments.done`. The [Realtime API server events reference](https://developers.openai.com/api/reference/resources/realtime) documents the full shape of each event.

You need a buffer per in-flight call to accumulate argument deltas. Use the item ID as the key, since multiple tools can be called in a single response. The item ID you receive in `response.output_item.added` is the same ID you will use as `call_id` when injecting the result — store it immediately when the function call item first appears, not when arguments are complete. If you plan to send a verbal acknowledgment before dispatching (covered in the next section), you need the ID available at `response.output_item.added` time, well before `response.function_call_arguments.done` arrives.

```typescript
// event-handler.ts
const pendingCalls = new Map<string, { name: string; argsBuffer: string }>();

ws.on("message", async (raw) => {
  const event = JSON.parse(raw.toString());

  switch (event.type) {
    case "response.output_item.added":
      if (event.item.type === "function_call") {
        pendingCalls.set(event.item.id, {
          name: event.item.name,
          argsBuffer: "",
        });
      }
      break;

    case "response.function_call_arguments.delta":
      if (pendingCalls.has(event.item_id)) {
        pendingCalls.get(event.item_id)!.argsBuffer += event.delta;
      }
      break;

    case "response.function_call_arguments.done": {
      const call = pendingCalls.get(event.item_id);
      if (call) {
        const args = JSON.parse(call.argsBuffer);
        // Fire and do NOT await — see the next section for why
        dispatchTool(event.item_id, call.name, args);
        pendingCalls.delete(event.item_id);
      }
      break;
    }
  }
});
```

The comment on the dispatch line is the most important line in this file. The next section explains it in full.

## Non-Blocking Tool Dispatch: The Critical Constraint

The `// do NOT await` comment from above is not a stylistic choice — it is a correctness requirement. Node.js runs on a single-threaded event loop. If you `await dispatchTool(...)` inside the WebSocket message handler, you block the event loop for the duration of the tool call. During that time, the WebSocket cannot process incoming messages — including `input_audio_buffer.speech_started` events that signal barge-in, and `input_audio_buffer.append` events carrying new user audio. Your agent goes deaf while the tool runs.

The fix is to fire the async function without awaiting it, letting it resolve in the background while the event loop remains free to process new events.

```typescript
// dispatch.ts
async function dispatchTool(
  callId: string,
  name: string,
  args: Record<string, unknown>
): Promise<void> {
  const start = Date.now();
  try {
    const result = await runTool(name, args);
    console.log(`[tool] ${name} completed in ${Date.now() - start}ms`);
    injectResult(callId, JSON.stringify(result));
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : "Tool failed unexpectedly";
    console.error(`[tool] ${name} failed: ${errorMsg}`);
    injectResult(callId, JSON.stringify({ error: errorMsg }));
  }
}

async function runTool(
  name: string,
  args: Record<string, unknown>
): Promise<unknown> {
  switch (name) {
    case "get_weather":
      return fetchWeather(args.location as string);
    case "create_reminder":
      return saveReminder(args.text as string, args.time as string);
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

async function fetchWeather(location: string) {
  // Mock: replace with real HTTP call. Target < 150ms.
  await new Promise((r) => setTimeout(r, 80));
  return { temperature: 18, condition: "partly cloudy", location };
}

async function saveReminder(text: string, time: string) {
  // Mock: replace with your reminder store
  await new Promise((r) => setTimeout(r, 40));
  return { success: true, reminder_id: `rem-${Date.now()}`, scheduled_at: time };
}
```

<Callout type="warning">
**The 200ms SLA — and what to do when you can't hit it**

Tool execution plus result injection should complete in under 200ms. For tools that genuinely need longer — external API calls, database queries — send a verbal acknowledgment *before* dispatching the tool. Inject an assistant text item and call `response.create` immediately:

```typescript
ws.send(JSON.stringify({
  type: "conversation.item.create",
  item: {
    type: "message",
    role: "assistant",
    content: [{ type: "text", text: "Let me check that for you." }],
  },
}));
ws.send(JSON.stringify({ type: "response.create" }));
```

The model speaks "Let me check that for you" while the real tool runs in the background. The user hears natural filler instead of silence. Do this before calling `dispatchTool`, not after.
</Callout>

<KnowledgeCheck
  question="Why must you NOT await dispatchTool() inside the WebSocket message handler?"
  options={[
    "The WebSocket library does not support async message handlers",
    "Awaiting blocks the Node.js event loop, preventing processing of incoming audio events",
    "The OpenAI API will close the connection if no new events are sent within 100ms",
    "Awaited tool results are discarded by the Realtime API automatically"
  ]}
  correctIdx={1}
  explanation="Awaiting inside the handler blocks Node.js's single-threaded event loop. New WebSocket messages — including user audio and barge-in signals — queue up and go unprocessed until the tool completes. Fire the async function without awaiting it so the event loop stays free."
/>

## Injecting Tool Results Back into the Session

After your tool resolves, you inject the result using two back-to-back WebSocket sends: a [`conversation.item.create`](https://developers.openai.com/api/reference/resources/realtime) event with a `function_call_output` item, then a `response.create` event to trigger the model's verbal response.

```typescript
// inject-result.ts
function injectResult(callId: string, resultJson: string): void {
  // Step 1: add the tool result to the conversation history
  ws.send(
    JSON.stringify({
      type: "conversation.item.create",
      item: {
        type: "function_call_output",
        call_id: callId,   // must match the item ID from response.output_item.added
        output: resultJson,
      },
    })
  );

  // Step 2: ask the model to generate its next turn using the result
  ws.send(JSON.stringify({ type: "response.create" }));
}
```

`call_id` is the load-bearing field. It must exactly match the `id` from the `response.output_item.added` event — that is the `event.item.id` you stored in `pendingCalls`. A mismatched or absent `call_id` produces a session error. Track this value from the moment the function call item appears, not from `response.function_call_arguments.done`, where only `item_id` is available.

`response.create` is what triggers the model's next speech turn. Without it, the `function_call_output` item sits in conversation history but the model generates nothing. The user hears silence. Always send `response.create` immediately after `conversation.item.create`.

<KnowledgeCheck
  question="What happens if you send conversation.item.create with a function_call_output but skip response.create?"
  options={[
    "The model automatically detects the new tool result and starts speaking",
    "The result is stored in conversation history but the model produces no verbal response",
    "The API returns a 400 validation error requiring response.create",
    "The WebSocket connection closes due to an unacknowledged tool result"
  ]}
  correctIdx={1}
  explanation="function_call_output adds the result to context but does not start a model turn. Without response.create, the model waits indefinitely. The turn never begins and the user hears silence. Always send both events."
/>

## Handling Tool Errors Gracefully

In a text interface, an unhandled tool error shows an error UI component. Embarrassing, but the user recovers — they click retry or reload. In a live voice session, the same failure produces silence. The user hears nothing, assumes a crash, and hangs up.

The rule is: `dispatchTool` must never fail silently. Wrap every tool in a try/catch, catch all thrown errors, and inject a result even when that result describes a failure. The `output` field of `function_call_output` is a plain string — it can carry any content, including an error description.

```typescript
// Error path — already shown in dispatchTool above, isolated here for clarity
try {
  const result = await runTool(name, args);
  injectResult(callId, JSON.stringify(result));
} catch (err) {
  // Always inject something — never leave the call_id unresolved
  injectResult(
    callId,
    JSON.stringify({ error: "Weather service unavailable. Try again shortly." })
  );
}
```

Given an output like `{ "error": "Weather service unavailable..." }`, the model generates a natural verbal recovery: *"I'm sorry, I wasn't able to get the weather right now — the service seems to be down. You could try asking me again in a moment."* No crash, no silence, conversation continues.

One timing edge case: if the user barge-ins and speaks again before your tool resolves, the conversation moves forward and the model may start a new response turn. When your tool finally completes and you call `injectResult`, the `function_call_output` still lands in conversation history and `response.create` still triggers a new turn. This is correct behavior — the model incorporates the tool result into its understanding of the full updated context. You do not need to cancel in-flight tool calls or suppress injection if the conversation has progressed. Just inject and continue.

There is one additional failure mode to guard against: uncaught promise rejections from `dispatchTool` itself. Because you fire it without awaiting, an unhandled rejection does not propagate to the message handler. In Node.js, it surfaces as an `unhandledRejection` event that — in older Node versions or misconfigured environments — crashes the process and terminates every active session. Add a top-level handler during development:

```typescript
process.on("unhandledRejection", (reason) => {
  console.error("[fatal] unhandled rejection in tool dispatch:", reason);
  // Alert your monitoring system — do not crash in production
});
```

<KnowledgeCheck
  question="What is the safest way to handle a tool execution failure in a voice session?"
  options={[
    "Throw the error and let Node's unhandledRejection handler log it",
    "Catch the error and inject a function_call_output with an error description",
    "Close the WebSocket session and prompt the user to call back",
    "Retry the tool call up to three times before returning silence"
  ]}
  correctIdx={1}
  explanation="Always inject a result — even an error description — so the model has something to verbalize. An uninjected call_id leaves the model waiting for a result that never arrives. The model naturally produces graceful verbal recovery from error outputs."
/>

## Hands-On Exercise: Weather + Reminder Tools

Extend your Chapter 2 WebSocket agent with the tools from this chapter.

**What to build:** a voice session with `get_weather(location)` and `create_reminder(text, time)`, both fully integrated into the event handling, dispatch, and injection loop above.

**Success criteria:**

1. Say *"What's the weather in Tokyo?"* — the agent responds with temperature and condition within 500ms of your end-of-utterance. Check your timestamp logs to verify the tool completed in under 200ms.
2. Say *"Remind me to call Alice at 3pm tomorrow"* — the agent confirms the reminder was created and reads back the scheduled time in natural language.
3. Simulate a tool failure by throwing inside `fetchWeather`. Verify the agent responds with a verbal acknowledgment rather than going silent. Measure that the silence gap before verbal recovery is under 300ms.
4. Add a verbal acknowledgment ("Let me check that for you.") before `get_weather` dispatches. Verify the user hears speech immediately while the 80ms mock delay runs in the background.

Once all four criteria pass, your agent handles the full tool calling loop: registration, event handling, async dispatch, result injection, and graceful failure recovery.

For deeper patterns around multi-agent tool routing and tool handoffs between agents, see the [[openai-agents-sdk-mastery]] course. If you want to understand how tool calling maps to the emerging open standard for agent interoperability, the [[mcp-from-first-principles-to-production]] course covers the Model Context Protocol in depth.

Next chapter: [[04-latency-engineering]] — profiling your voice pipeline end-to-end, implementing barge-in interrupt handling, and applying speculative response patterns to eliminate the silences that make users hang up.
