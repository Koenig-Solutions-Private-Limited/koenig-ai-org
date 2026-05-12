---
chapter_num: 2
title: "The Agent SDK Tool-Calling Model"
learning_objectives:
  - "Understand how the Agent SDK injects tools into the model's context"
  - "Define type-safe tools using Python functions + type hints"
  - "Handle tool execution results and errors gracefully"
prerequisites_chapters: [1]
duration_min: 60
---

# Chapter 2: The Agent SDK Tool-Calling Model

In Chapter 1, we established that Agents differ from Chatbots by their ability to drive the interaction. The "engine" that powers this is Tool Calling. Without tools, an agent is just a very smart chatterbox; with tools, it becomes an interface for your software systems.

In this chapter, we will master the mechanics of the Agent SDK tool-calling model.

## The Tool-Calling Anatomy

When an agent needs external information or action, it doesn't "guess"—it requests a tool execution. The OpenAI Agents SDK maps this into a strictly structured flow:

1. **Schema Generation:** The SDK inspects your Python functions (via type hints and docstrings) and generates a JSON Schema representation.
2. **The Decision:** The model emits a `tool_use` event, requesting specific parameters.
3. **Execution:** The SDK pauses, runs the local function, and gathers the result.
4. **Resolution:** The result is injected back into the conversation history, allowing the agent to formulate the final answer.

> **HOT: Why Type Hints Matter**
> The model is only as safe as your type hints. If you define a tool without an explicit schema or type, the model will hallucinate argument formats, leading to runtime crashes.

---

### RunPromptCell: Creating Your First Bound Tool

The SDK makes binding functions trivial. Simply decorate your function and add it to the agent instance.

```python
from openai import Agent
from typing import Annotated

# Define a tool with type-checked parameters
def get_weather(location: Annotated[str, "The city and state, e.g. San Francisco, CA"]):
    """Gets the current weather for a specific location."""
    # Mock database lookup
    return f"The weather in {location} is 72°F and sunny."

agent = Agent(
    model="gpt-4o",
    instructions="You are a helpful assistant.",
    tools=[get_weather]
)

# Run an interaction that requires the tool
response = agent.run("What's the weather like in New York?")
print(response.content)
```

**Expected Output:**
The weather in New York is 72°F and sunny.

---

## Knowledge Check 2

**Q1: What process ensures the LLM understands how to call your function properly?**
(A) It scans the entire source code file
(B) It relies on docstrings automatically
(C) It maps Python functions to JSON Schema via type hints
(D) It makes a random guess based on function names

**Q2: If a tool execution fails, what should the agent's behavior be?**
[Free-form response - describe how a robust agent should handle a failed tool call, e.g., error reporting, notifying the user, or retrying]

---

## Hands-on Exercise: Building a Utility Agent

Your goal is to build an agent capable of performing basic mathematical operations and simple data lookups.

1. Create `utility_agent.py`.
2. Define a `multiply(a: int, b: int)` tool.
3. Define a `lookup_user_id(username: str)` tool that returns `1234` for a hardcoded lookup.
4. Run the agent with the prompt: "Multiply 42 by 7, then look up the user 'hermes'."
5. Verify success: Check if the agent correctly called *both* tools.

---

## What's Next?

Now that we can give our agents tools, what happens if the conversation lasts for days? In Chapter 3, we address the challenge of stateful memory and persistence—ensuring your agent remembers the user across long, disconnected sessions.

[Proceed to Chapter 3: State and Persistent Memory]
