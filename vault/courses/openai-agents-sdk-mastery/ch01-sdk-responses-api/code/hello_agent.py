"""
Chapter 1: Hello World agent using the OpenAI Agents SDK (Python)

Requirements:
    pip install openai-agents python-dotenv

Usage:
    export OPENAI_API_KEY="sk-..."
    python hello_agent.py

    # Or with a .env file:
    echo "OPENAI_API_KEY=sk-..." > .env
    python hello_agent.py
"""

import asyncio
import os

# Load .env if present (optional, requires python-dotenv)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from agents import Agent, Runner, function_tool


# ── Basic Hello World ────────────────────────────────────────────────────────

basic_agent = Agent(
    name="Academy Guide",
    instructions=(
        "You are a concise technical guide for the Koenig AI Academy. "
        "Answer questions about AI agents clearly and in plain language. "
        "Keep answers to 2-3 sentences unless more detail is requested."
    ),
    model="gpt-4.1",
)


async def run_basic_example():
    """Single-turn hello world — no tools, just a plain conversation."""
    print("── Basic Hello World ──────────────────────────────────")
    result = await Runner.run(
        basic_agent,
        "In one sentence: what problem does the OpenAI Agents SDK solve?",
    )
    print(result.final_output)
    print()


# ── Tool-Calling Agent ───────────────────────────────────────────────────────

@function_tool
def get_sdk_version() -> str:
    """Returns the currently installed openai-agents package version."""
    import importlib.metadata
    try:
        return importlib.metadata.version("openai-agents")
    except importlib.metadata.PackageNotFoundError:
        return "openai-agents package not found — is it installed?"


@function_tool
def get_python_version() -> str:
    """Returns the current Python interpreter version."""
    import sys
    return f"Python {sys.version}"


tool_agent = Agent(
    name="System Assistant",
    instructions=(
        "You are a helpful system assistant. "
        "When asked about SDK or Python versions, always use the provided tools "
        "to retrieve the real values rather than guessing."
    ),
    model="gpt-4.1",
    tools=[get_sdk_version, get_python_version],
)


async def run_tool_example():
    """Demonstrates the agent loop: model → tool call → result → final answer."""
    print("── Tool-Calling Agent ─────────────────────────────────")
    result = await Runner.run(
        tool_agent,
        "What version of the Agents SDK am I running, and what Python version is this?",
        max_turns=5,  # safety guard — never omit in production
    )
    print(result.final_output)
    print()


# ── Multi-Turn Conversation ──────────────────────────────────────────────────

async def run_multi_turn_example():
    """Shows how to maintain conversation history across multiple Runner.run() calls."""
    print("── Multi-Turn Conversation ────────────────────────────")

    conversation_agent = Agent(
        name="Responses API Expert",
        instructions=(
            "You are an expert on the OpenAI Responses API. "
            "Answer questions concisely and build on previous answers."
        ),
        model="gpt-4.1",
    )

    # Turn 1
    result = await Runner.run(
        conversation_agent,
        "What is the Responses API?",
    )
    print(f"Turn 1: {result.final_output}\n")

    # Turn 2 — pass result.to_input_list() to continue the conversation
    result = await Runner.run(
        conversation_agent,
        result.to_input_list() + [{"role": "user", "content": "How does it differ from Chat Completions?"}],
    )
    print(f"Turn 2: {result.final_output}\n")


# ── Entry Point ──────────────────────────────────────────────────────────────

async def main():
    if not os.environ.get("OPENAI_API_KEY"):
        raise EnvironmentError(
            "OPENAI_API_KEY is not set. "
            "Export it or add it to a .env file in this directory."
        )

    await run_basic_example()
    await run_tool_example()
    await run_multi_turn_example()


if __name__ == "__main__":
    asyncio.run(main())
