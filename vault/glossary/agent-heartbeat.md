---
term: "Agent Heartbeat"
definition: "A periodic signal emitted by a running agent to its watchdog or orchestrator to indicate it is alive and making progress, enabling detection of stuck, crashed, or infinitely looping agents."
seo_description: "Agent heartbeat: a periodic liveness signal from an agent to its watchdog, enabling detection of stuck or crashed autonomous agents."
category: "Agentic AI concepts"
related_terms: [agent-budget, agent-loop, agent-orchestration, autonomous-agent, watchdog]
---

Heartbeats are a standard pattern in distributed systems for detecting failures, applied here to AI agents. The agent emits a heartbeat—a lightweight status update (agent ID, task ID, current step, tokens consumed so far)—at the end of each loop iteration or on a fixed timer. The watchdog expects heartbeats at regular intervals; a missed heartbeat triggers an alert and optionally a kill signal.

Heartbeat design should include progress information, not just liveness. An agent that is running but not making progress (e.g., retrying the same failed tool call in a tight loop) is just as problematic as a crashed agent. Including a "step count" or "cost delta" in the heartbeat allows the watchdog to detect no-progress loops.

In Paperclip's watchdog implementation (`watchdog/watchdog.mjs`), agents emit heartbeats via task status updates. The watchdog monitors task update timestamps and triggers a circuit breaker if a task has been in a non-terminal state for longer than its configured maximum duration.

## Related Terms

- [[glossary/agent-budget|Agent Budget]] — the resource and spend limits enforced to prevent runaway agent consumption
- [[glossary/agent-loop|Agent Loop]] — the iterative perceive-act-observe cycle the harness executes
- [[glossary/agent-orchestration|Agent Orchestration]] — the coordination layer that routes and schedules work across multiple agents
- [[glossary/autonomous-agent|Autonomous Agent]] — an agent that completes tasks independently without step-by-step human approval
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
