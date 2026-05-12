---
chapter_num: 2
title: "Designing Agent Roles and Capabilities"
learning_objectives:
  - "Define the structure and purpose of an AgentCard"
  - "Construct a formal AgentSkill definition including schema and semantic metadata"
  - "Understand the relationship between agent roles (Orchestrator vs. Specialist) and capability exposure"
prerequisites_chapters: ["01-a2a-protocol-architecture"]
duration_min: 60
status: draft
---

# Chapter 2: Designing Agent Roles and Capabilities

In this chapter, we transition from the theory of the A2A EventBus to the practical mechanics of how agents *describe* themselves to the network. If Chapter 1 was about the "connector," this chapter is about the "contract."

## The AgentCard: Identity and Manifest

An **AgentCard** is the fundamental identity unit in A2A. It is not just an endpoint; it is a JSON-LD compliant manifest. When an agent joins an A2A cluster, it broadcasts its Card.

### Anatomy of an AgentCard

- `agent_id`: A unique, verifiable identifier (often a URN).
- `endpoints`: A list of reachable protocol transports (e.g., HTTPS, WSS).
- `skills`: A reference list of capabilities (AgentSkills) this agent offers.
- `metadata`: Security scoping, owner identity, and operational constraints (e.g., rate limits).

## AgentSkills: Standardizing Tooling

An **AgentSkill** defines *what* an agent can do using standard JSON Schema for inputs and outputs. This allows for cross-vendor interoperability.

## RunPromptCell: Defining a Weather Specialist Skill

```python
# Definition of a weather forecasting skill
weather_skill = {
    "name": "get_weather",
    "description": "Provides current temperature and conditions for a city.",
    "input_schema": {
        "type": "object",
        "properties": {
            "city": {"type": "string", "description": "City name"},
            "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
        },
        "required": ["city"]
    },
    "output_schema": {
        "type": "object",
        "properties": {
            "temperature": {"type": "number"},
            "condition": {"type": "string"}
        }
    }
}
```

## KnowledgeCheck 1

1. Which element of A2A functions as the "business card" for an agent?
   a) EventBus
   b) AgentSkill
   c) AgentCard

2. Why do we encode AgentSkills using standardized JSON Schema?

## Designing Roles: Orchestrators vs. Specialists

One common anti-pattern is building agents that try to do everything. A healthy A2A ecosystem relies on functional modularity:
- **Orchestrator Agents:** Responsible for high-level planning, state tracking, and breaking tasks into sub-tasks. They rarely hold deep domain tools (e.g., specialized RAG logic).
- **Specialist Agents:** Hold deep, highly controlled access to specific resources (e.g., a SQL-Database-Agent with strict query constraints).

## Callout: Warning
Never expose internal database schemas directly as an `AgentSkill`. Always provide an abstraction layer via the skill to maintain security and avoid brittle coupled interfaces.

## Hands-on Exercise: Construct Your Skill Manifest
1. Choose one tool from the system you mapped in Chapter 1.
2. Draft a complete `AgentSkill` JSON object for that tool, including `input_schema` and `output_schema`.
3. Create a draft `AgentCard` snippet for an agent that would expose this skill.

## What's Next?
In Chapter 3, we address the most critical piece of production systems: **Securing Agent-to-Agent Communication**.
