---
chapter_num: 5
title: "Routing Patterns: Triage to Federation"
learning_objectives:
  - "Differentiate between Triage (Centrally Routed), Hierarchical (Chain of Thought), and Federated (Mesh) patterns"
  - "Implement a Triage agent that intelligently routes tasks to optimal specialists"
  - "Understand the trade-offs of federation: latency vs. autonomy"
prerequisites_chapters: ["01-a2a-protocol-architecture", "04-capability-discovery-negotiation"]
duration_min: 90
status: draft
---

# Chapter 5: Routing Patterns: Triage to Federation

In this chapter, we explore the *topology* of agent interaction. How do you construct an organization of specialized agents? Routing is the difference between a brittle, manual-coded script and a robust, scalable agent system.

## Designing the Router: Three Core Patterns

### 1. Triage (The "Dispatcher" Model)
A central Orchestrator agent acts as a dispatcher. It receives the user’s request, analyzes it, and determines which specialist has the matching skill manifest.
- **Strength:** Simple to debug, clear ownership.
- **Weakness:** Single point of failure; orchestrator bottleneck.

### 2. Hierarchical (The "Manager-Worker" Model)
A chain of agents. One agent interprets the request, another researches, another synthesizes.
- **Strength:** Maps well to complex, multi-stage workflows (e.g., research → drafting → review).
- **Weakness:** Latency increases cumulatively with chain depth.

### 3. Federated (The "Mesh" Model)
Specialists can talk to each other directly without returning to the Orchestrator. 
- **Strength:** Maximum flexibility/innovation; emergent collaboration.
- **Weakness:** High complexity; difficult observability and auditability.

## RunPromptCell: Simple Triage Logic

```python
# A simple Triage router
def triage_orchestrator(task_prompt, specialist_registry):
    # Determine the required capability
    intent = analyze_intent(task_prompt) # Orchestrator's internal LLM logic
    
    # Route based on registered capabilities
    for agent in specialist_registry:
        if intent in agent.capabilities:
            return agent.route(task_prompt)
            
    # Fallback to general handling
    return default_agent.route(task_prompt)
```

## KnowledgeCheck 1

1. Which topological pattern is best suited for complex, multi-stage workflows but suffers from cumulative latency?
   a) Triage
   b) Hierarchical
   c) Federated

2. List one major trade-off of the Federated (Mesh) pattern.

## Callout: Hot
The **Triage** pattern is usually the correct starting point for production systems. Reserve Federation for mature ecosystems where individual specialists have high autonomy and reliable manifests.

## Hands-on Exercise: Build a Triage Agent
1. Create a `TriageOrchestrator` agent capable of routing requests between a `CalculatorSpecialist` and a `SearchSpecialist` using their manifest definitions.
2. Ensure that it gracefully handles tasks requiring *both* skills by routing sequentially.

## What's Next?
So far, our agents are stateless. That rarely works in production. In Chapter 6, we address **Handling Asynchrony and State Management**.
