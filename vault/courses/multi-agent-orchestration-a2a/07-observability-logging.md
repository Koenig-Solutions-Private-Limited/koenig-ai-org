---
chapter_num: 7
title: "Observability and Logging in A2A Networks"
learning_objectives:
  - "Configure distributed tracing for cross-agent workflows using OpenTelemetry"
  - "Implement structured logging that captures context across agent boundaries"
  - "Build an observability dashboard view of agent interaction health"
prerequisites_chapters: ["06-handling-asynchrony-state"]
duration_min: 90
status: draft
---

# Chapter 7: Observability and Logging in A2A Networks

When an agent in Japan calls an agent in the US, what happens when it fails? Without cross-boundary observability, your multi-agent system is a black box. This chapter teaches you how to shine a light into that box.

## The Challenge of Distributed Tracing
In standard web apps, you trace a request from client to DB. In A2A, a single "request" might fork and join across 5 agents, each running its own runtime.

### OpenTelemetry for Agents
We use **OpenTelemetry** with globally unique `trace_id`s that persist in the message header of every A2A envelope. Any agent *must* propagate this `trace_id` to its downstream calls.

## RunPromptCell: Tracing Middleware Pattern

```python
# Instrumenting an A2A message with OTel context
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def instrumented_a2a_call(capability, target_agent, payload):
    with tracer.start_as_current_span("a2a_outbound_call") as span:
        # Inject trace context into the envelope
        span.set_attribute("target_agent", target_agent)
        envelope = {
            "payload": payload,
            "trace_id": span.get_span_context().trace_id
        }
        return broker.send(target_agent, envelope)
```

## KnowledgeCheck 1

1. Why standard web tracing fails in A2A systems?
   a) Network latency
   b) Disjoint agent runtimes without shared context
   c) Lack of JSON support

2. True or False: You should only log the payload received at your agent boundary, not the propagated trace ID.

## Callout: Warning
If you *don't* pass the `trace_id` forward to the next agent, you effectively "break the chain," making debugging impossible. Propagate headers strictly!

## Hands-on Exercise: Implement Trace Propagation
1. Update your bridge middleware from Chapter 3 to extract a `trace_id` from the incoming request headers.
2. Ensure that any downstream interaction performed by the agent includes this `trace_id` in its outbound messages.

## What's Next?
We have built, routed, secured, and observed. Now, we prepare for the inevitable. Chapter 8: **Failure Modes and Reliability**.
