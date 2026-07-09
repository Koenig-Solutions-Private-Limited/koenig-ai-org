---
chapter_num: 4
course_slug: cloudflare-agents-platform-workers-to-production
title: "Durable Workflows: Cloudflare Agents That Survive Failures (2026)"
status: g3-passed
author: course-author
ticket: KOEA-6699
learning_objectives:
  - "Model a multi-step agent task as a Cloudflare Workflow with automatic checkpointing"
  - "Implement retry-with-backoff for tool calls that may fail transiently"
  - "Design a human-in-the-loop escalation step that pauses the workflow pending approval"
  - "Handle the INPUT_REQUIRED state for long-running research tasks"
prerequisites_chapters:
  - "03-tool-design-for-workers-runtime"
duration_min: 55
level: Intermediate-Advanced
vendor_tag: cloudflare
positions:
  - id: durable-execution-beats-retry-middleware
    engagement: defends
  - id: human-in-the-loop-as-workflow-step
    engagement: defends
chapter_primary_query: "How do Cloudflare Workflows make AI agents durable and resumable in 2026?"
first_60_words_answer: "Cloudflare Workflows v2 execute multi-step agent tasks as durable, checkpointed sequences. Each step is persisted before execution — if the step fails, the Workflow retries from that step, not from the start. A five-step case-handling agent that hits a transient API error at step four resumes from step four after the retry delay, with all prior step outputs intact. Up to 50,000 concurrent Workflow instances per account."
faq:
  - question: "What are Cloudflare Workflows and how do they work with agents?"
    answer: "Cloudflare Workflows v2 are a durable, serverless execution engine for multi-step logic. Each `step.do()` call is an atomic, checkpointed unit — its output is persisted before execution and the Workflow resumes from the last successful step on failure. For AI agents, Workflows replace ad-hoc retry middleware with a platform-level guarantee: a multi-tool agent chain is resumable by default. ([Cloudflare Workflows](https://developers.cloudflare.com/workflows/))"
  - question: "What is the difference between a Cloudflare Workflow and a Durable Object?"
    answer: "A Durable Object provides per-instance state and handles real-time connections (WebSockets, HTTP). A Workflow executes a deterministic sequence of steps to completion. In a production agent architecture, the Durable Object is the 'always-on' session manager, and a Workflow is spawned when the agent needs to execute a long-running, multi-step task that must survive failures. They are complementary — the DO can spawn Workflows and receive their results. ([Cloudflare Workflows](https://developers.cloudflare.com/workflows/))"
  - question: "How do you implement human-in-the-loop with Cloudflare Workflows?"
    answer: "Use `step.waitForEvent()` to pause the Workflow pending an external event. The Workflow enters a waiting state (no compute consumed), and a separate Worker or webhook handler calls `workflow.sendEvent({ type: 'approval', approved: true })` when the human acts. The Workflow resumes from the waiting step with the event payload. Waiting duration can be up to 30 days. ([Workflow events](https://developers.cloudflare.com/workflows/build/events-and-callbacks/))"
  - question: "What happens to a Cloudflare Workflow if my Worker restarts?"
    answer: "Nothing — the Workflow continues. Workflows are independent of the Worker that spawned them. They run on Cloudflare's infrastructure, not in your Worker's V8 isolate. If your Worker redeploys mid-Workflow, the Workflow resumes its current step from the last checkpoint using the new Worker code. Steps that completed before the redeploy are not re-executed. ([Cloudflare Workflows](https://developers.cloudflare.com/workflows/))"
howto_schema:
  name: "Convert a multi-step agent task into a durable Cloudflare Workflow"
  steps:
    - name: "Define a Workflow class extending WorkflowEntrypoint"
      text: "Create a class that extends `WorkflowEntrypoint<Env, Params>` and implement the `run(event, step)` method. Each logical stage of the agent task becomes a `step.do('step-name', async () => { ... })` call. The step name is used for checkpointing and must be unique within the Workflow."
    - name: "Add retry configuration to transient steps"
      text: "Pass a retry config object as the second argument to `step.do()`: `{ retries: { limit: 3, delay: '10 seconds', backoff: 'exponential' } }`. The Workflow retries the step up to 3 times with 10s → 20s → 40s delays before marking it failed and halting."
    - name: "Add a human-approval step with step.waitForEvent"
      text: "Insert `const approval = await step.waitForEvent('human-approval', { timeout: '24 hours' })` at the escalation point. The Workflow pauses. When an external system calls `workflow.sendEvent({ type: 'human-approval', payload: { approved: true } })`, the Workflow resumes with `approval.payload`."
    - name: "Register the Workflow binding in wrangler.toml"
      text: "Add `[[workflows]]` with `name = 'case-handler'`, `binding = 'CASE_WORKFLOW'`, and `class_name = 'CaseHandlerWorkflow'` to wrangler.toml. In your Agent, spawn an instance with `const instance = await env.CASE_WORKFLOW.create({ params: { caseId } })`."
    - name: "Retrieve Workflow status and output from the agent"
      text: "Call `const status = await env.CASE_WORKFLOW.get(instanceId)` to check whether the Workflow is running, waiting, completed, or errored. Surface `status.output` to the user when the Workflow completes. Store the `instanceId` in the DO state so the agent can check status across sessions."
inline_assets:
  - type: diagram
    path: ./img/workflow-step-checkpointing.svg
    alt: "Workflow step checkpointing diagram showing a five-step sequence where steps 1-3 complete successfully, step 4 fails, triggers retry with backoff, eventually succeeds, and step 5 completes — with checkpoint markers after each step"
  - type: diagram
    path: ./img/hitl-workflow-pause-resume.svg
    alt: "Human-in-the-loop Workflow diagram showing Workflow entering waitForEvent state at escalation step, operator receiving notification, approving via external webhook, and Workflow resuming from the waiting step"
last_updated: 2026-06-14
sources:
  - https://developers.cloudflare.com/workflows/
  - https://developers.cloudflare.com/workflows/build/events-and-callbacks/
  - https://developers.cloudflare.com/workflows/build/retry-and-concurrency/
  - https://developers.cloudflare.com/workflows/reference/limits/
  - https://blog.cloudflare.com/cloudflare-workflows-open-beta/
tags:
  - cloudflare
  - workflows
  - durable-execution
  - agents
  - human-in-the-loop
  - retry
  - checkpointing
  - 2026
quiz:
  - question: "What is the key property of a step.do() call in a Cloudflare Workflow?"
    options:
      - "It runs the step asynchronously in a separate Worker thread for parallelism"
      - "It automatically caches the step output in Workers KV for reuse across runs"
      - "It checkpoints its output so failures resume from that step, not from step one"
      - "It validates all arguments against a Zod schema before executing the step body"
    correct_idx: 2
    explanation: "step.do() checkpoints its output before execution. If the step fails, the Workflow retries from that specific step — steps that completed before the failure are not re-executed. Workers threads, KV caching, and Zod validation are not properties of step.do()."
    section_anchor: workflow-concepts-steps-instances-and-the-run-method
  - question: "How does a Cloudflare Workflow pause for human approval without consuming compute?"
    options:
      - "The Workflow polls a Queue for an approval message every 60 seconds automatically"
      - "The Worker runs a setInterval loop checking a D1 approval flag on each wake"
      - "The Workflow calls step.waitForEvent() which serializes state to storage until signalled"
      - "A Durable Object alarm wakes the Workflow DO instance when the approval event arrives"
    correct_idx: 2
    explanation: "step.waitForEvent() pauses the Workflow with zero compute consumption — the instance is serialized to durable storage. An external system sends an event via workflow.sendEvent() when the human acts, waking the Workflow from exactly the waiting step. Wait time can be up to 30 days."
    section_anchor: the-human-in-the-loop-pattern
  - question: "An agent Workflow step calls an external API with unpredictable recovery time. Which retry backoff is most appropriate?"
    options:
      - "constant — applies a fixed delay since the API's recovery time is well-known"
      - "exponential — progressively backs off to avoid flooding a recovering external service"
      - "linear — adds a fixed delay increment per retry to balance speed and service load"
      - "none — retry logic should be implemented in application code outside the Workflow"
    correct_idx: 1
    explanation: "exponential backoff (10s → 20s → 40s) is correct for APIs with unknown recovery times — it avoids hammering a recovering service while still retrying promptly on fast recoveries. constant is for predictable recovery windows; linear is a middle ground; no-retry leaves the agent vulnerable to any transient failure."
    section_anchor: retry-configuration-reference
  - question: "After a simulated failure at step 2 of a 5-step Workflow, which steps execute on the automatic retry?"
    options:
      - "All five steps restart from step 1 since the Workflow re-runs fully on any failure"
      - "Steps 2 and 3 rerun together since they share the same checkpoint boundary group"
      - "Only step 2 retries; step 1's checkpoint is reused and steps 3-5 run after"
      - "Steps 2 through 5 rerun since intermediate checkpoints expire when a step fails"
    correct_idx: 2
    explanation: "Cloudflare Workflows checkpoint step outputs durably. On failure at step 2, only step 2 is retried — step 1's output is read from checkpoint, not recomputed. LLM costs for step 1 are not duplicated. Steps 3-5 execute normally once step 2 succeeds."
    section_anchor: simulating-and-verifying-step-resumability
---

# Durable Workflows: Cloudflare Agents That Survive Failures (2026)

Cloudflare Workflows v2 execute multi-step agent tasks as durable, checkpointed sequences. Each step is persisted before execution — if the step fails, the Workflow retries from that step, not from the start. A five-step case-handling agent that hits a transient API error at step four resumes from step four after the retry delay, with all prior step outputs intact. Up to 50,000 concurrent Workflow instances per account.

This chapter converts the Chapter 3 case agent's tool sequence into a Cloudflare Workflow with checkpointing, retry-with-backoff, and a human-in-the-loop escalation step. You'll also implement the `INPUT_REQUIRED` pattern for long-running tasks that pause pending external input.

---

## Why stateless retry isn't enough for agents

The standard approach to reliability in serverless functions is retry-on-failure: if the function errors, re-invoke it from the start. This works for idempotent operations — an HTTP GET that reads a database row can safely retry a hundred times with the same result.

For AI agents, retry-from-start is a correctness hazard:

1. **Step 1**: Classify the case (LLM call, 500ms, costs $0.002)
2. **Step 2**: Look up the customer's billing history (D1 query)
3. **Step 3**: Draft a response (LLM call, 1500ms, costs $0.01)
4. **Step 4**: Post to the CRM (external API, fails with a 503)
5. **Step 5**: Send a confirmation email

If step 4 fails and you retry the entire sequence, you re-run steps 1–3. You pay for the LLM calls again. You re-classify a case that was already correctly classified. You draft a response that's already in your Durable Object. And if any of those intermediate steps have side effects (like a CRM read that's rate-limited), you might trigger rate limits on your retry.

Cloudflare Workflows solve this by making step outputs durable. Once step 3 completes and its output is checkpointed, a failure at step 4 retries *only step 4* — steps 1–3 are not re-executed. Their outputs are read from the checkpoint, not recomputed.

---

## Workflow concepts: steps, instances, and the run method

A Cloudflare Workflow is a class that extends `WorkflowEntrypoint`. You implement a single `run(event, step)` method containing all the steps. The `step` object is the execution context — all side-effectful operations go through `step.do()`.

```typescript
import { WorkflowEntrypoint, type WorkflowStep, type WorkflowEvent } from "cloudflare:workers";

interface CaseParams {
  caseId: string;
  userMessage: string;
  sessionId: string;
}

export class CaseHandlerWorkflow extends WorkflowEntrypoint<Env, CaseParams> {
  async run(event: WorkflowEvent<CaseParams>, step: WorkflowStep) {
    // Steps execute sequentially and are checkpointed between each one
    const classification = await step.do("classify-case", async () => {
      // ...
    });

    const context = await step.do("retrieve-context", async () => {
      // ...
    });

    const draft = await step.do("draft-response", async () => {
      // ...
    });

    return { classification, draft };
  }
}
```

A **Workflow instance** is one execution of `run()` with specific parameters. Instances are created via:

```typescript
const instance = await env.CASE_WORKFLOW.create({
  params: { caseId: "CASE-001", userMessage: text, sessionId },
});
const instanceId = instance.id;
```

An instance runs exactly once to completion (or failure after all retries are exhausted). The instance ID is a stable reference you can use to check status, retrieve output, and send events to waiting steps.

---

## Building the durable case-handler Workflow

Here's the full Workflow for the Chapter 3 case agent, converted to a durable execution:

```typescript
import {
  WorkflowEntrypoint,
  type WorkflowStep,
  type WorkflowEvent,
} from "cloudflare:workers";

interface CaseParams {
  caseId: string;
  userMessage: string;
  sessionId: string;
}

interface CaseOutput {
  classification: string;
  contextSummary: string;
  draft: string;
  status: "completed" | "escalated" | "awaiting_approval";
  escalationDisposition?: "approved" | "rejected";
}

export class CaseHandlerWorkflow extends WorkflowEntrypoint<Env, CaseParams> {
  async run(
    event: WorkflowEvent<CaseParams>,
    step: WorkflowStep
  ): Promise<CaseOutput> {
    const { caseId, userMessage, sessionId } = event.payload;

    // Step 1: Classify the case
    // No retry needed — Workers AI calls are fast and the result is deterministic enough
    const classification = await step.do("classify-case", async () => {
      const result = await this.env.AI.run("@cf/meta/llama-3.1-8b-instruct", {
        messages: [
          {
            role: "system",
            content:
              "Classify the support message as one of: billing, technical, feature_request, or other. " +
              "Reply with only the category name.",
          },
          { role: "user", content: userMessage },
        ],
      });
      return (result as { response: string }).response.trim().toLowerCase();
    });

    // Step 2: Retrieve context from D1 (external dependency — add retry)
    const caseContext = await step.do(
      "retrieve-case-context",
      {
        retries: { limit: 3, delay: "5 seconds", backoff: "exponential" },
      },
      async () => {
        const row = await this.env.CASE_DB.prepare(
          "SELECT * FROM cases WHERE id = ?1"
        )
          .bind(caseId)
          .first<{ id: string; summary: string; status: string }>();

        if (!row) throw new Error(`Case ${caseId} not found`);
        return row;
      }
    );

    // Step 3: Draft a response (LLM call — add retry for transient API errors)
    const draft = await step.do(
      "draft-response",
      {
        retries: { limit: 2, delay: "10 seconds", backoff: "linear" },
      },
      async () => {
        const result = await this.env.AI.run("@cf/meta/llama-3.1-8b-instruct", {
          messages: [
            {
              role: "system",
              content: `You are a support agent. Draft a response for this ${classification} case.
Case: ${caseContext.summary}
User message: ${userMessage}
Be empathetic, specific, and under 200 words.`,
            },
          ],
        });
        return (result as { response: string }).response;
      }
    );

    // Step 4: Check if escalation is needed
    const needsEscalation = await step.do("check-escalation", async () => {
      const urgencyKeywords = ["urgent", "lawsuit", "cancel", "refund", "fraud"];
      return urgencyKeywords.some((kw) =>
        userMessage.toLowerCase().includes(kw)
      );
    });

    if (needsEscalation) {
      // Step 5a: Dispatch to escalation queue
      await step.do(
        "dispatch-escalation",
        {
          retries: { limit: 3, delay: "10 seconds", backoff: "exponential" },
        },
        async () => {
          await this.env.ESCALATION_QUEUE.send({
            caseId,
            reason: `Urgency keywords detected in: "${userMessage.slice(0, 100)}"`,
            agentSessionId: sessionId,
            timestamp: new Date().toISOString(),
          });
        }
      );

      // Step 5b: Wait for human approval (pauses Workflow — no compute consumed)
      const approvalEvent = await step.waitForEvent<{ approved: boolean; notes?: string }>(
        "human-approval",
        { timeout: "24 hours" }
      );

      if (!approvalEvent.payload.approved) {
        return {
          classification,
          contextSummary: caseContext.summary,
          draft,
          status: "escalated",
          escalationDisposition: "rejected",
        };
      }

      return {
        classification,
        contextSummary: caseContext.summary,
        draft,
        status: "escalated",
        escalationDisposition: "approved",
      };
    }

    // Step 5b (non-escalation): Update case status
    await step.do(
      "update-case-status",
      { retries: { limit: 3, delay: "5 seconds", backoff: "exponential" } },
      async () => {
        await this.env.CASE_DB.prepare(
          "UPDATE cases SET status = 'resolved' WHERE id = ?1"
        )
          .bind(caseId)
          .run();
      }
    );

    return {
      classification,
      contextSummary: caseContext.summary,
      draft,
      status: "completed",
    };
  }
}
```

---

## Spawning and monitoring Workflows from the agent

The Durable Object agent spawns the Workflow and stores the instance ID in DO state so it can check status across multiple user messages:

```typescript
export class CaseAgent extends Agent<Env> {
  async onMessage(connection: Connection, message: WSMessage) {
    const text = typeof message === "string" ? message : message.toString();

    // Check for a running Workflow to resume
    const runningInstanceId = await this.env.storage.get<string>(
      "activeWorkflowId"
    );
    if (runningInstanceId) {
      const status = await this.env.CASE_WORKFLOW.get(runningInstanceId);

      if (status.status.name === "waitingOnEvent") {
        // User is responding to the escalation approval prompt
        const approved = text.toLowerCase().includes("approve");
        await status.sendEvent({
          type: "human-approval",
          payload: { approved, notes: text },
        });
        connection.send(
          `Human approval ${approved ? "granted" : "rejected"}. Resuming workflow.`
        );
        return;
      }

      if (status.status.name === "complete") {
        const output = status.output as CaseOutput;
        await this.env.storage.delete("activeWorkflowId");
        connection.send(
          `Previous case completed (${output.status}).\n\nDraft: ${output.draft}`
        );
        return;
      }

      connection.send(
        `A case is currently being processed (status: ${status.status.name}). ` +
        `I'll update you when it's done.`
      );
      return;
    }

    // Extract caseId from the message (simplified — use LLM in production)
    const caseMatch = text.match(/CASE-\d+/);
    if (!caseMatch) {
      connection.send("Please provide a case ID (e.g., CASE-001) to start.");
      return;
    }

    const caseId = caseMatch[0];
    const instance = await this.env.CASE_WORKFLOW.create({
      params: { caseId, userMessage: text, sessionId: this.ctx.id.toString() },
    });

    await this.env.storage.put("activeWorkflowId", instance.id);

    connection.send(
      `Processing ${caseId}. Workflow started (ID: ${instance.id}). ` +
      `I'll respond when the draft is ready — or notify you if escalation approval is needed.`
    );
  }
}
```

---

## Simulating and verifying step resumability

To verify the Workflow actually resumes from the failed step (not from the start), inject a simulated failure:

```typescript
// In retrieve-case-context, add a failure trigger for testing
const caseContext = await step.do(
  "retrieve-case-context",
  {
    retries: { limit: 3, delay: "5 seconds", backoff: "exponential" },
  },
  async () => {
    // Simulate failure on first attempt
    const attemptCount = await this.env.CASE_DB.prepare(
      "SELECT COUNT(*) as n FROM workflow_attempts WHERE instance_id = ?1"
    ).bind(instanceId).first<{ n: number }>();

    if ((attemptCount?.n ?? 0) === 0) {
      await this.env.CASE_DB.prepare(
        "INSERT INTO workflow_attempts VALUES (?1, datetime('now'))"
      ).bind(instanceId).run();
      throw new Error("Simulated transient failure");
    }

    return await this.env.CASE_DB.prepare("SELECT * FROM cases WHERE id = ?1")
      .bind(caseId)
      .first();
  }
);
```

Deploy and check the Workflows dashboard at `dash.cloudflare.com → Workers → Workflows → case-handler`. You'll see:
- `classify-case`: completed on first attempt
- `retrieve-case-context`: failed → retried → completed
- `draft-response`: completed (not re-executed)
- The step counter in the dashboard shows the exact retry count and timestamps

This verifies the core promise: step 3 was not re-run when step 2 failed. Your LLM costs were not duplicated.

---

## The human-in-the-loop pattern

The `step.waitForEvent()` call is what makes human-in-the-loop a first-class Workflow primitive rather than a polling hack. While the Workflow is waiting:

- No compute is consumed (you don't pay for a running Worker)
- The Workflow instance is serialized to durable storage
- It can wait up to 30 days
- The instance ID is stable — external systems can send events at any time

To resume the waiting Workflow from an external approval system (a Slack bot, an email link, a dashboard button):

```typescript
// External webhook handler (a separate Worker or route)
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { instanceId, approved, notes } = await request.json<{
      instanceId: string;
      approved: boolean;
      notes?: string;
    }>();

    const workflow = await env.CASE_WORKFLOW.get(instanceId);
    await workflow.sendEvent({
      type: "human-approval",
      payload: { approved, notes },
    });

    return Response.json({ status: "event_sent" });
  },
};
```

The event payload is available in the Workflow as the return value of `step.waitForEvent()`. The Workflow reads `approvalEvent.payload.approved` to decide whether to proceed or terminate.

---

## Retry configuration reference

| Parameter | Type | Description |
|---|---|---|
| `retries.limit` | number | Maximum retry attempts (0 = no retry, default 0) |
| `retries.delay` | string or number | Initial delay between retries, e.g. `"10 seconds"`, `"1 minute"`, `30000` (ms) |
| `retries.backoff` | `"constant"` / `"linear"` / `"exponential"` | How the delay grows between retries |

With `backoff: "exponential"` and `delay: "10 seconds"`:
- Retry 1: 10 seconds after failure
- Retry 2: 20 seconds after first retry
- Retry 3: 40 seconds after second retry

Use `"constant"` for dependencies with known recovery times (e.g., a partner API that recovers in exactly 30 seconds). Use `"exponential"` for unknown transient failures where you want to back off progressively without hammering a recovering service.

---

## The contrarian take: fire-and-forget is the wrong default

Most serverless agent tutorials show you `Promise.all([tool1(), tool2(), tool3()])` — parallel tool execution with no durability. This is fine for demo agents handling requests that complete in under 10 seconds. For production agents handling real user tasks, it's the wrong default.

Production support cases take minutes to process. CRM updates hit rate limits. LLM APIs return 429s. Human approvals take hours. "Fire-and-forget" for multi-step tasks means the user's request is silently dropped every time any downstream system blips.

Cloudflare Workflows makes durability the default with essentially zero extra code. The step wrapper is 3 lines. The retry config is 4 lines. The `waitForEvent` call is 1 line. For the cost of a dozen lines of code, your agent's task execution becomes a production-grade workflow that survives failures, supports human oversight, and provides an audit trail in the Workflows dashboard.

---

## Chapter summary

- Cloudflare Workflows v2 execute multi-step logic as durable, checkpointed sequences. Each `step.do()` output is persisted — failures retry from the failed step, not from the start.
- Add `retries` config to `step.do()` for steps with transient failure risk (external APIs, LLM calls, database writes). Use `backoff: "exponential"` as the default.
- `step.waitForEvent()` pauses the Workflow indefinitely (up to 30 days) pending an external event. This is the correct pattern for human-in-the-loop escalation — no polling, no compute while waiting.
- Spawn Workflows from your Durable Object agent and store the instance ID in DO state to track status across user sessions.
- In the next chapter, you'll add AI Gateway in front of all LLM calls to enable production-grade logging, semantic caching, and fallback model routing.
