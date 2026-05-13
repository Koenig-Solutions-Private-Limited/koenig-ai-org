---
chapter_num: 3
title: "State and Persistent Memory"
learning_objectives:
  - "Understand the distinction between ephemeral session state and persistent memory"
  - "Implement connection and thread management for long-lived agent interactions"
  - "Configure a storage layer (SQLite) for state persistence across process restarts"
prerequisites_chapters: [1, 2]
duration_min: 60
---

# Chapter 3: State and Persistent Memory

In Chapters 1 and 2, we built stateless agents. When the script exits, the agent's memory vanishes. In production, this is unacceptable: users expect their agent to remember the context of their conversation across different sessions.

This chapter teaches you how to move from ephemeral agents to stateful, persistent systems.

## The Architecture of Persistent State

The OpenAI Agents SDK provides a `Thread` model to manage history. A thread manages a specific sequence of interactions between the user and the agent.

To persist an agent, we must store the `Thread` content (history) outside the agent's memory process, typically in an external database.

### Core concepts:
- **`Thread`**: A container for a sequence of messages.
- **`Checkpointer`**: An interface for saving and loading the state of a thread.
- **Persistence Store**: The underlying storage (SQLite, Redis, or Postgres).

> **WARNING: The Stateless Hazard**
> Developing without a state persistence layer leads to "Agent Amnesia," where the agent restarts its personality or loses vital user context every time the service restarts. Always design for checkpointing from the start.

---

### RunPromptCell: Persistent Storage with SQLite

We can attach a persistent store to the agent. Below is an example using a SQLite backend.

```python
from openai import Agent
from openai.agents.persistence import SQLiteStore

# Setup the persistent store
store = SQLiteStore(path="agent_state.db")

# Initialize an agent with persistent storage
agent = Agent(
    model="gpt-4o",
    instructions="You are a personal project assistant.",
    persistence_store=store
)

# Interaction 1
agent.run("My project is called AgentMastery.")
print("Saved state to SQLite.")

# If we were to restart the script here, the next run would remember:
# Interaction 2
response = agent.run("What is my project called?")
print(f"Agent remembers: {response.content}")
```

**Expected Output:**
Saved state to SQLite.
Agent remembers: Your project is called AgentMastery.

---

## Knowledge Check 3

**Q1: Why do we use a `Checkpointer` interface for agent state?**
(A) To speed up the LLM's response time
(B) To abstract away the specific database implementation (SQL, Redis, etc.)
(C) To increase the number of tokens the LLM can process
(D) To automatically delete sensitive user information

**Q2: Describe the "Stateless Hazard" in your own words.**
[Free-form response - describe why statelessness is problematic for production agent applications]

---

## Hands-on Exercise: Implementing Persistence

Your goal is to build a stateful agent that doesn't forget.

1. Create `persistence_agent.py`.
2. Configure it with a `SQLiteStore`.
3. Build a "Daily Reminder Agent" that stores the user's name and goal.
4. Run the script. Verify that the agent can retrieve the name in a subsequent execution (simulate this by running it twice in the same process, ensuring it writes to the DB).
5. Success criteria: The agent correctly recalls user information after the initial interaction sequence.

---

## What's Next?

With state managed, our agents are beginning to resemble production software. However, we've kept our logic linear. In Chapter 4, we will learn how to enable complex decision-making through **Planning and Reasoning**.

[Proceed to Chapter 4: Planning and Reasoning]
