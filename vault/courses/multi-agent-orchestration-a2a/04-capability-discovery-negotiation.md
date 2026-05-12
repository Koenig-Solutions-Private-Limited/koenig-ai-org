---
chapter_num: 4
title: "Capability Discovery and Negotiation"
learning_objectives:
  - "Implement the protocol for A2A handshakes"
  - "Learn how an orchestrator queries a specialist's manifests dynamically"
  - "Understand the negotiation phase: proposing and accepting a skill interaction"
prerequisites_chapters: ["01-a2a-protocol-architecture", "03-hello-a2a-hosting-endpoint"]
duration_min: 75
status: draft
---

# Chapter 4: Capability Discovery and Negotiation

In Chapter 3, we successfully connected two agents. But connection alone is insufficient for a *dynamic* multi-agent system. An orchestrator must not only know *who* a specialist is, but *what* it can do. This chapter covers the discovery and negotiation protocols.

## Discovery: The Handshake

When an orchestrator connects to a new specialist endpoint, it does not immediately send tasks. It initiates a **Handshake/Discovery sequence**.

1. **Ping:** Basic connectivity check.
2. **Metadata Fetch:** Pulls the `AgentCard`.
3. **Skill Indexing:** The orchestrator indexes available `AgentSkills` into its local memory/vector store.

## Negotiation: Proposing and Confirming

Not every agent can handle every payload. The negotiation phase allows agents to formalize specific parameter requirements.

### Standard Negotiation Pattern

```python
# A simple negotiation exchange
def negotiate_skill_use(specialist_endpoint, skill_id, params):
    # Propose usage
    proposal = {"action": "propose", "skill": skill_id, "params": params}
    response = requests.post(specialist_endpoint, json=proposal)
    
    if response.json()["status"] == "confirmed":
        return execute_skill(specialist_endpoint, skill_id, params)
    else:
        # Fallback or error handling
        return "Negotiation failed"
```

## KnowledgeCheck 1

1. Why is a metadata fetch (discovery) necessary before execution?
   a) To lower network latency
   b) To verify agent capabilities dynamically
   c) To encrypt the connection

2. What is the role of the negotiation phase in an A2A interaction?

## Callout: Warning
Never assume an `AgentSkill` definition is static. Always re-fetch manifests if a previous connection attempt fails; agents may update their capabilities dynamically.

## Hands-on Exercise: Implement Discovery
1. Write a script that visits a `/discover` endpoint, downloads the `AgentCard`, and parses the available skills into a dictionary.
2. Simulate a failed negotiation (e.g., provide a parameter that violates the input schema) and ensure your agent handles the error gracefully.

## What's Next?
Now that agents can discover and negotiate, we need to master how to route work across them. Chapter 5: **Routing Patterns: Triage vs. Federation**.
