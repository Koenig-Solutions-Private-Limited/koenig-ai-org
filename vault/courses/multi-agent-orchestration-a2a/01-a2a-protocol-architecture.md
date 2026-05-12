---
chapter_num: 1
title: "The A2A Protocol Architecture"
learning_objectives:
  - "Explain the core philosophy of A2A versus traditional RPC/REST"
  - "Identify the primary components: AgentCard, AgentSkill, and EventBus"
  - "Draw a high-level architecture diagram comparing monolithic vs agent-to-agent communication"
prerequisites_chapters: []
duration_min: 60
status: draft
---

# Chapter 1: The A2A Protocol Architecture

The A2A (Agent-to-Agent) protocol is an open standard designed to solve the "agent silo" problem. In 2026, we are moving past monolithic, vendor-locked agent runtimes toward a federated landscape. When agents can discover, communicate, and collaborate across these boundaries, their effective capability set expands exponentially.

## Architecting for Federation: Monolithic vs A2A 

To visualize this, consider a simple system.

### Monolithic Approach (The Hard-Wired Web)
In a monolith, every agent needs to know exactly how to talk to every other agent. As you add agents, the number of point-to-point connections grows at O(n^2).

![Architecture: Monolithic Agent Connections (Point-to-Point)](https://placeholder.diagram.io/monolith)

### A2A Approach (The Federated Bus)
A2A introduces an **EventBus** or **Broker** layer. Agents attach to the bus and publish their `AgentCard`—a manifest of their skills. They interact via standardized message envelopes.

![Architecture: Federated A2A Model (Hub-and-Spoke)](https://placeholder.diagram.io/a2a-bus)

## Primary Components of A2A

1. **AgentCard**: The "business card" of an agent. It lists identity, security tokens, and available `AgentSkills`.
2. **AgentSkill**: A standardized definition of a tool, including input/output schemas (JSON Schema) and semantic descriptions.
3. **EventBus**: The transport substrate that routes messages between agents based on capability requests rather than raw URLs.

---

## RunPromptCell: Comparing Architectures

```python
# Conceptual comparison: REST vs A2A

# Traditional REST approach (monolithic approach)
# Need to know the specific endpoint, auth method, and schema for every service
def call_service_rest(service_url, action, params):
    # Fragile: tightly coupled to the specific provider's API
    # Must know the target agent's internal implementation details
    import requests
    return requests.post(f"{service_url}/{action}", json=params)

# A2A approach (federated approach)
# Agent interacts via an A2A Broker using semantic routing
def call_service_a2a(broker, target_capability, payload):
    # Flexible: uses the capability name regardless of target agent
    # The broker resolves the target agent based on the requested capability
    return broker.request(target_capability, payload)
```

## KnowledgeCheck 1

1. What is the primary problem A2A solves?
   a) Faster token generation
   b) Agent siloization and vendor lock-in
   c) Lower GPU memory usage

2. True or False: A2A requires that agents share the same internal codebase.

3. (FREE FORM) In your own words, why does the number of connections in a monolithic system create a bottleneck?

## Callout: Hot
The A2A protocol is NOT a replacement for language models; it is the transport layer for their reasoning processes.

## Hands-on Exercise: Map Your System
1. List three agent services you are currently running (or plan to run).
2. Identify one "hard-coded" connector between them (or one you expect to build).
3. Sketch how this connector would look if you expressed it as an "AgentSkill" advertisement. Define the inputs (e.g., `query: string`) and output (e.g., `results: list[dict]`).

## What's Next?
In Chapter 2, we dive into how to model your agents using **AgentCards** and **AgentSkills**.
