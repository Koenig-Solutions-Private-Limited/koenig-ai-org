---
chapter_num: 1
title: "Anatomy of an Agent"
learning_objectives:
  - "Define the paradigm shift from Chatbot to Agentic systems"
  - "Understand the Agent SDK's core architecture (the runtime loop)"
  - "Set up the local development environment and run a first agent"
prerequisites_chapters: []
duration_min: 60
---

# Chapter 1: Anatomy of an Agent

In this chapter, we depart from the traditional request-response model of LLMs and enter the world of **Agentic Systems**. An agent isn't just an endpoint that returns a prediction; it is a system designed to interact with its environment, maintain state, and execute work autonomously toward a goal.

## The Paradigm Shift: From Chatbots to Agents

Traditional LLM applications follow a "Chatbot" pattern:
User Input → Prompt → Model → Response.

This is a stateless, passive interaction. The LLM does not *do*—it merely *answers*. 

An **Agentic system** flips this. The Agent is the driver of the interaction. It has:
1. **Goal/Instructions:** Defines *what* to do.
2. **Tools:** Defines *how* it interacts with the world (web search, math, file I/O).
3. **Reasoning Loop:** The core cycle: Observe → Think → Act → Observe.

### The Agent SDK Runtime Loop

The OpenAI Agents SDK handles the boilerplate of this "Observe-Think-Act" cycle. At its heart, it provides a persistent loop that:
1. Receives input.
2. Interleaves model execution with tool calls.
3. Maintains context (history).

> **HOT: The "Response" vs "Chat Completion" distinction**
> While we have all used `openai.chat.completions.create`, this is too low-level for complex agents. It lacks built-in tool management, state persistence, and automatic retries. The Agents SDK abstracts this into a state machine that handles multi-turn interaction reliably.

---

### RunPromptCell: Your First Agent

Let's boot a minimal agent that answers a simple question.

```python
from openai import Agent

# Initialize the agent
agent = Agent(
    model="gpt-4o",
    instructions="You are a helpful assistant."
)

# Run an interaction
response = agent.run("What is the capital of France?")
print(response.content)
```

**Expected Output:**
The capital of France is Paris.

---

## Knowledge Check 1

**Q1: What are the three components of an agentic system pattern?**
(A) Prompt, Completion, and API key
(B) Goal, Tools, and Reasoning Loop
(C) Frontend, Database, and LLM
(D) User, Model, and Tokenizer

**Q2: How does an Agent differ from a standard Chatbot?**
[Free-form response - describe the agent's ability to drive the interaction]

---

## Setting up your Lab

To follow this course, you need a stable Python 3.10+ environment.

1. Create a workspace:
   `mkdir -p ~/projects/agent-mastery && cd ~/projects/agent-mastery`
2. Install dependencies:
   `pip install openai-agents`
3. Verify installation:
   `python -c "import openai; print('Agent SDK is ready')"`

### Hands-on Exercise: The "Echo" Agent

Your goal for this chapter is to build an agent that does NOT just answer, but echoes back specific instructions about "Agentic Mastery" whenever asked a question.

1. Create `echo_agent.py`.
2. Configure it with instructions: "You are the Agentic Mastery assistant. Every response must include the quote: 'Agents are the future of software.'"
3. Run it against the user prompt: "Hello!"
4. Verify success: Does the output include the required quote?

---

## What's Next?

In Chapter 2, we stop talking about agents and start giving them tools to perform real-world tasks like searching the web and interacting with local files.

[Proceed to Chapter 2: The Agent SDK Tool-Calling Model]
