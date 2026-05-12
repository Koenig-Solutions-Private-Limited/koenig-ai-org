---
chapter_num: 3
title: "Hello-A2A: Hosting an A2A Endpoint"
learning_objectives:
  - "Configure a basic agent to serve an A2A endpoint"
  - "Bridge Claude Code agent with an OpenAI Agent SDK agent"
  - "Verify connectivity through a handshake exchange"
prerequisites_chapters: ["01-a2a-protocol-architecture", "02-designing-agent-roles-and-capabilities"]
duration_min: 90
status: draft
---

# Chapter 3: Hello-A2A: Hosting an A2A Endpoint

Now that we know how to define capabilities, let's ship some code. In this chapter, we move from architecture and manifests to running a live, cross-platform A2A endpoint. Our goal is to connect two different agent runtimes: Claude Code (as the Orchestrator) and an OpenAI-SDK-based Agent (as the Specialist).

## The A2A Bridge Configuration

An A2A endpoint acts as a lightweight wrapper around your existing agent server. It listens for A2A bus events and translates them into calls that your agent's native SDK can process, while also exposing a manifest endpoint for capability discovery.

## RunPromptCell: Minimal A2A FastAPI Wrapper

```python
# A simplified example of the A2A Bridge middleware in Python
from fastapi import FastAPI, Request
import json

app = FastAPI()

@app.post("/a2a/bus")
async def handle_a2a_message(request: Request):
    message = await request.json()
    # 1. Authenticate message signature
    # 2. Route payload to native agent SDK
    # 3. Return response in standard A2A envelope
    return {"a2a_status": "processed", "data": "native_agent_result"}

@app.get("/.well-known/agent-card")
def get_card():
    # Returns the AgentCard manifest
    return {"agent_id": "specialist-v1", "capabilities": [...]}
```

## Bridging Claude Code and OpenAI Agents

The magic of the A2A protocol is that the communication is agnostic. Once the bridge is defined in the `AgentCard` schema, the orchestrator doesn't care if the specialist is running LangChain, AutoGen, or a custom SDK; it just sees an `AgentSkill` compliant with the agreed-upon interface.

## KnowledgeCheck 1

1. Where should an agent host its public manifest for capability discovery?
   a) A private database column
   b) A `.well-known/agent-card` endpoint
   c) Hard-coded in the orchestrator's config

2. Why do we need a middleware layer for A2A?

## Callout: Warning
Always implement message signature verification *before* passing traffic into your Agent SDK. An improperly secured bridge is an open door for arbitrary prompt injection from any agent on the network.

## Hands-on Exercise: The Hello-Handshake
1. Deploy two local instances of simple HTTP endpoints using the A2A bridge template above.
2. Manually trigger a "discovery" POST request from server A to server B's `/.well-known/agent-card` endpoint.
3. Validate that the handshake JSON matches the expected schema.

## What's Next?
Now that agents can *talk*, we need to ensure they can *negotiate*. In Chapter 4, we move to **Capability Discovery and Formal Negotiation**.
