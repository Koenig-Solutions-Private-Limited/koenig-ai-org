---
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8552
course: multi-agent-orchestration-a2a
chapter_num: 6
chapter_title: "Orchestration Patterns — Chains, Hubs, and Meshes"
slug: multi-agent-orchestration-a2a-chapter-06
description: "Every multi-agent workflow collapses into one of three topologies — linear chain, hub-and-spoke, or mesh — each with a distinct failure mode that only appears at scale. This chapter shows you how to identify the Orchestrator Bottleneck before it kills hub throughput, implement A2A-native Peer-to-Peer Delegation using contextId to preserve workflow lineage, and design a Dynamic Mesh where agents self-discover and join only when needed."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 50
reading_time_min: 13
last_updated: 2026-06-15
chapter_primary_query: "how to choose between chain hub-and-spoke and mesh orchestration patterns in A2A multi-agent systems"
first_60_words_answer: "Every multi-agent workflow maps to one of three topologies: Linear Chains sequence agents in order; Hub-and-Spoke routes all tasks through a central orchestrator; Fully Connected Meshes let every agent delegate directly to any other. Hub-and-Spoke is the most common entry pattern and also the most dangerous at scale — the central orchestrator becomes a bottleneck, a single point of failure, and a coordination tax on every step."
prerequisites_chapters: [4, 5]
learning_objectives:
  - Compare Linear Chain, Hub-and-Spoke, and Fully Connected Mesh architectures on throughput, failure modes, and coordination complexity
  - Identify the Orchestrator Bottleneck in Hub-and-Spoke systems and apply three concrete mitigation strategies before it becomes a production incident
  - Implement a Peer-to-Peer Delegation pattern where A2A agents collaborate without routing through a central orchestrator, using contextId to preserve lineage
  - Design a Dynamic Mesh where agents discover peers at runtime and join or leave the workflow based on task requirements
positions:
  - id: mcp-as-interoperability-moat
    engagement: neutral
tags: [A2A, multi-agent, orchestration, hub-and-spoke, peer-to-peer, dynamic-mesh, topology, linear-chain, orchestrator-bottleneck]
status: g3-passed
sources:
  - https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/ # retrieved 2026-05-12
  - https://a2a-protocol.org/latest/specification/ # retrieved 2026-05-12
  - https://github.com/a2aproject/A2A # retrieved 2026-05-12
  - https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade # retrieved 2026-05-12
  - https://github.com/a2aproject/A2A/releases/tag/v1.0.0 # retrieved 2026-05-12
  - https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform # retrieved 2026-05-12
  - https://a2a-protocol.org/latest/partners/ # retrieved 2026-05-12
faq:
  - question: "When should I use a Linear Chain over a Hub-and-Spoke?"
    answer: "Use a Linear Chain when the workflow is strictly sequential — every step depends entirely on the previous step's output, parallelism provides no benefit, and each agent only needs to know one downstream address. A chain's single advantage over hub-and-spoke is zero orchestrator overhead after the first dispatch. Hub-and-Spoke is the better default whenever you need conditional routing, parallel dispatch to multiple specialists, or the ability to recover and re-route a single failed step without restarting the chain. ([A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/))"
  - question: "What is the Orchestrator Bottleneck and what are its three mitigation strategies?"
    answer: "The Orchestrator Bottleneck occurs when a central hub agent is the required routing point for every task in the workflow. As concurrent workflows increase, the orchestrator's task queue grows faster than its throughput. Three mitigations: (1) Direct P2P handoffs — authorize specialist agents to hand off to each other for known sequential sub-task pairs, eliminating round-trips through the hub; (2) Async dispatch — fire tasks in parallel with non-blocking A2A sends and collect results via push notifications rather than waiting for sequential completions; (3) Domain sub-orchestrators — promote domain-specialist agents to handle routing within their own domains, distributing the coordination tax. ([Gemini Enterprise Agent Platform, Google Cloud](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform))"
  - question: "How does A2A enable Peer-to-Peer Delegation without a central orchestrator?"
    answer: "A2A's task delegation primitives are symmetric — any A2A client can call SendMessage on any A2A server endpoint, regardless of who originated the workflow. The spec-defined contextId field propagates the original workflow session ID through every peer-to-peer handoff, so the originating Manager receives the final completion notification without having brokered the intermediate step. Before delegating, the Researcher validates the Writer's capability by fetching the Writer's Agent Card and confirming the required skill ID is listed — the same AgentCard-based capability check used for all A2A task dispatch. ([A2A GitHub repository](https://github.com/a2aproject/A2A))"
---

# Orchestration Patterns — Chains, Hubs, and Meshes

> **Chapter 6 of 10 · 50 min (prose ~13 min + 25 min hands-on exercise)**

Every multi-agent workflow maps to one of three topologies: Linear Chains sequence agents in order; Hub-and-Spoke routes all tasks through a central orchestrator; Fully Connected Meshes let every agent delegate directly to any other. Hub-and-Spoke is the most common entry pattern and also the most dangerous at scale — the central orchestrator becomes a bottleneck, a single point of failure, and a coordination tax on every step.

---

## The Three Topologies

The topology you choose determines where coordination complexity lives and which failure mode will hit you first. None is universally correct.

**Linear Chain**: Agent A passes output directly to Agent B, which passes to Agent C. Dependencies are strictly sequential — each agent starts only when its predecessor finishes. Coordination overhead is minimal: there is no central dispatcher, and each agent only needs to know one downstream address. The cost is inflexibility: a failure at any step halts the full chain, and adding a new agent mid-chain requires modifying two existing agents. Parallelism is structurally impossible.

**Hub-and-Spoke**: A central orchestrator (the hub) receives the top-level goal, decomposes it into sub-tasks, and dispatches each to a specialist (the spokes). All inter-agent communication routes through the hub. The hub holds global state, can re-route failed tasks, and provides a single point for monitoring. This topology maps to how humans think about delegation — one coordinator, many workers — which is why most teams default to it. The failure mode is the Orchestrator Bottleneck, covered next.

**Fully Connected Mesh**: Every agent can delegate directly to every other. No central coordinator exists. Coordination logic distributes across agents. A Researcher can hand off to a Writer; the Writer can invoke a Fact-Checker without looping back through a Manager. A **Dynamic Mesh** is the practical production variant: agents discover and join the workflow based on task requirements and leave when they are no longer needed, rather than maintaining full static connectivity.

| Topology | Throughput ceiling | Failure blast radius | Coordination knowledge |
|---|---|---|---|
| Linear Chain | Sequential only | Full chain halts | Agent N knows only agent N+1 |
| Hub-and-Spoke | Orchestrator queue depth | Hub is single point of failure | All routes known by hub only |
| Fully Connected Mesh | Per-agent × N agents | Single agent only | Every agent knows every other |

<KnowledgeCheck
  question="Which topology eliminates the orchestrator as a single point of failure?"
  answers={[
    "Hub-and-Spoke, because the hub maintains global workflow state and can re-route any failed spoke",
    "Linear Chain, because agents only communicate with their immediate successor and there is no central hub to fail",
    "Fully Connected Mesh, because orchestration logic distributes across agents rather than concentrating in one coordinator",
    "None — all A2A topologies require a designated orchestrator role defined in the A2A specification"
  ]}
  correct={2}
/>

---

## The Orchestrator Bottleneck

Hub-and-Spoke works until it doesn't. The failure arrives quietly: the hub's task queue grows faster than its dispatch throughput. Latency on every workflow step climbs as tasks wait for the orchestrator's attention. Add one high-cost specialist — an agent whose tasks take ten seconds to complete — and the hub serializes every workflow behind it, including workflows that have nothing to do with that specialist.

Three concrete mitigations address the bottleneck without abandoning hub-and-spoke. First, authorize direct P2P handoffs for known sequential sub-task pairs: if Researcher always hands off to Writer, route that specific transition peer-to-peer and eliminate one hub round-trip per workflow. Second, switch to async task dispatch: fire all parallel sub-tasks with non-blocking `SendMessage` calls (the A2A v1.0.0 operation name; the Python SDK exposes this as `send_task()`) and collect results via push notification endpoints — an A2A-spec mechanism — rather than blocking the hub waiting for sequential completions. Third, introduce domain sub-orchestrators: promote a domain-specialist agent to coordinate its own subdomain, distributing the routing tax across domain boundaries. The [Gemini Enterprise Agent Platform](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform) demonstrates this pattern at scale, distributing orchestration across domain-specific coordinators rather than a single hub.

<Callout type="warning">
  Add async push notification handling to your hub before adding your third spoke — retrofitting it later requires updating every specialist's response path. The Orchestrator Bottleneck is a throughput problem first and a reliability problem second; teams typically discover it after the fourth specialist, not the second, when concurrent workflow load finally exceeds hub queue depth. ([A2A Specification v1.0.0, push notification model](https://a2a-protocol.org/latest/specification/) · [A2A v1.0.0 Release Notes](https://github.com/a2aproject/A2A/releases/tag/v1.0.0))
</Callout>

---

## Peer-to-Peer Delegation

A2A's delegation primitives are symmetric by spec design: any A2A client can call `SendMessage` on any A2A server endpoint. The [A2A specification](https://a2a-protocol.org/latest/specification/) does not restrict delegation to originate from a designated orchestrator role. This symmetry makes P2P delegation a first-class pattern rather than a workaround.

In P2P delegation, the Researcher completes its sub-task and issues a `SendMessage` to the Writer's A2A endpoint directly, attaching the research artifact as context. The Manager never loses visibility — the A2A spec's `contextId` field propagates the original workflow session ID through the handoff, so the Manager receives the Writer's completion notification without having brokered the intermediate step.

```python
# Researcher: complete work, then delegate to Writer — no Manager round-trip
async def complete_and_delegate(task: A2ATask, research_artifact: dict):
    writer_card = await a2a_client.fetch_agent_card(WRITER_URL)
    # Spec-grounded: capability check via Agent Card before delegation (see Ch 4)
    assert "content-synthesis" in [s["id"] for s in writer_card["skills"]]

    handoff = await a2a_client.send_task(
        agent_url=WRITER_URL,
        message=A2AMessage(
            parts=[DataPart(data=research_artifact)],
            contextId=task.contextId,         # A2A spec field; propagates lineage
            metadata={"upstream_task": task.id}  # convention, not A2A-mandatory
        )
    )
    await a2a_client.complete_task(task.id, artifact={"delegated_to": handoff.id})
```

Note the separation: `contextId` is a spec-defined field that any A2A-compliant implementation must support. The `metadata.upstream_task` key is a production convention — useful for downstream tracing but not part of the wire protocol.

<KnowledgeCheck
  question="What A2A spec field preserves workflow session lineage when the Researcher delegates directly to the Writer without returning through the Manager?"
  answers={[
    "The task id, which both agents must set to the same value to signal membership in the same workflow session",
    "The contextId field, which the spec defines to propagate the originating session ID through every delegation hop",
    "The Agent Card provider field, which links all agents from the same organization into a shared lineage namespace",
    "There is no built-in A2A field for this — lineage across P2P handoffs requires a custom header from the original orchestrator"
  ]}
  correct={1}
/>

---

## The Dynamic Mesh

A Dynamic Mesh removes the pre-wired topology entirely. Instead of a static graph of known agents, each agent queries a registry — an AGNTCY-style global index or a local agent pool — for a peer satisfying a required capability, fetches that peer's Agent Card at runtime, validates the skill match, and delegates. Agents leave the workflow when their tasks complete rather than idling in a static configuration. The [Google A2A announcement](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) describes this as the long-term model for the Internet of Agents: agents that are sovereign, discoverable, and composable without pre-registration in any specific workflow.

The trade-off is observability. When any agent can reach any other, tracing actual delegation sequences requires propagating `contextId` and trace IDs through every hop — covered in Chapter 9. Architecture convention, not A2A spec, governs how teams enforce this: common practice is to require trace-ID headers at the MCP gateway layer so they are added regardless of individual agent implementation.

---

## Hands-On Exercise: Hub-and-Spoke to Peer-to-Peer Refactor

**Time estimate:** 25 minutes

Build a 3-agent Hub-and-Spoke system, then refactor it so the Researcher hands off directly to the Writer without a Manager round-trip.

**Step 1 — Hub-and-Spoke baseline.**

```python
# Manager: dispatch Researcher, collect result, dispatch Writer
async def manager_workflow(goal: str) -> dict:
    research_task = await a2a_client.send_task(
        agent_url=RESEARCHER_URL,
        message=A2AMessage(parts=[TextPart(text=goal)])
    )
    research = await a2a_client.await_task(research_task.id)

    write_task = await a2a_client.send_task(
        agent_url=WRITER_URL,
        message=A2AMessage(parts=[DataPart(data=research.artifact)])
    )
    return (await a2a_client.await_task(write_task.id)).artifact
```

**Step 2 — Refactor: Researcher delegates to Writer directly.**

```python
# Researcher: run work, then delegate — Manager is not in the handoff path
async def handle_task(task: A2ATask) -> None:
    result = await run_research(task.message.parts[0].text)
    await a2a_client.send_task(
        agent_url=WRITER_URL,
        message=A2AMessage(
            parts=[DataPart(data=result)],
            contextId=task.contextId,
            metadata={"upstream_task": task.id}
        )
    )
    await a2a_client.complete_task(task.id, artifact={"delegated": True})
```

**Step 3 — Manager: switch to awaiting the Writer's completion, not the Researcher's artifact.**

Update `manager_workflow` to dispatch only the Researcher and then listen for the Writer's push notification. The Manager fires one dispatch; the Researcher fires the second.

**Success criteria:**
- Manager calls `send_task` exactly once (to Researcher). It does not call `send_task` to Writer — the Researcher does.
- The Writer's final artifact reaches the Manager via push notification, not via a Manager-initiated `tasks/get` after the Researcher completes.
- The `contextId` on the Writer's task matches the `contextId` on the Researcher's original task — proving lineage continuity through the P2P handoff.
- Replacing the Researcher with a stub that calls Writer directly delivers the correct artifact to the Manager without any Manager code changes.

---

## What's Next

You now have working topologies from hub-and-spoke to peer-to-peer delegation. The next challenge is what happens when agents or the network fail mid-workflow: checkpointing, distributed state management, and the A2A patterns for resuming work after a partial failure.

[[multi-agent-orchestration-a2a/chapter-07|Chapter 7: Resilience, State, and Asynchrony]] implements checkpointing for long-running workflows and shows how the Two-Phase Commit problem surfaces in agentic negotiations.

---

*Sources: [A2A Announcement, Google Developers Blog](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/) · [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [A2A v1.0.0 Release Notes](https://github.com/a2aproject/A2A/releases/tag/v1.0.0) · [Gemini Enterprise Agent Platform, Google Cloud](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform)*
