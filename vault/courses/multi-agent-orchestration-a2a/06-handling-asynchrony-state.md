---
chapter_num: 6
title: "Handling Asynchrony and State Management"
learning_objectives:
  - "Implement state persistence for long-running agent workflows"
  - "Design asynchronous message handling using callback IDs and correlation tokens"
  - "Manage workflow state consistency across disjoint agent nodes"
prerequisites_chapters: ["05-routing-patterns"]
duration_min: 90
status: draft
---

# Chapter 6: Handling Asynchrony and State Management

In real-world multi-agent systems, "instant" responses are the exception, not the rule. Agents often need to wait for external API results, human feedback, or long-running computations. Mastering **asynchronous flow** and **distributed state** is mandatory for system reliability.

## The A2A Asynchrony Model

A2A uses non-blocking communication patterns by default. When an Orchestrator sends a task to a Specialist, it does not wait for a direct return. It receives a `task_id` and then periodically polls an A2A result channel—or receives a webhook callback when the specialist is done.

### Correlation Tokens
To match responses to requests in an asynchronous mesh, every message MUST carry a `correlation_token`. This acts as a distributed "primary key" for that transaction.

## RunPromptCell: Async Task Pattern

```python
# A2A Async call pattern
def call_async_specialist(specialist_url, task_data):
    # Send request and receive a ticket
    ticket = requests.post(f"{specialist_url}/tasks", json=task_data).json()
    task_id = ticket["task_id"]
    
    # Poll for completion (or wait for webhook)
    while True:
        status = requests.get(f"{specialist_url}/tasks/{task_id}").json()
        if status["completed"]:
            return status["result"]
        time.sleep(2) # Backoff logic in production!
```

## KnowledgeCheck 1

1. What is the role of a `correlation_token` in an asynchronous multi-agent system?
   a) To authorize the agent to access resources
   b) To map asynchronous responses back to their original requests
   c) To encrypt the message payload

2. Why is polling often inferior to webhook callbacks?

## Callout: Warning
Always implement a **timeout** mechanism on your async tasks. An agent system that allows infinite pending states will eventually cascade into a resource-exhaustion failure (a "distributed hang").

## Hands-on Exercise: Implement Async State Tracker
1. Create a simple `StateStore` (can be an in-memory dict for this exercise) that keeps track of the `status` and `result` of tasks managed by your orchestrator.
2. Implement a polling loop that queries the specialist agent for a status update on a long-running task until it returns `completed`.

## What's Next?
Next, we tackle the "black box" of agent-to-agent networks. Chapter 7: **Observability and Logging**.
