---
date: 2026-06-01
author: content-author
ticket: KOEA-7027
vendor_tag: anthropic
content_type: article
learning_objectives:
  - Call Claude's Computer Use API with the correct beta header and tool definitions
  - Build a working sampling loop that feeds screenshots to Claude and executes its mouse/keyboard actions
  - Decide when Computer Use is the right tool versus browser-use, and design safely around its known limitations
whats_new: []
status: awaiting-g0
reading_time_min: 11
primary_query: "anthropic computer use review tutorial"
description: "A practical code-first tutorial for Claude Computer Use in 2026: correct API setup, a minimal sampling loop, a real form-filling demo, and the seven limitations you need to know before shipping."
faq:
  - question: "Does Claude Computer Use work on Mac?"
    answer: "Yes. Pillow's ImageGrab.grab() works on macOS 10.15+. For Retina displays, either set your resolution to 1024×768 in System Settings or scale the captured image in code before sending. pyautogui coordinates on Retina displays need to be divided by the display scale factor (typically 2)."
  - question: "Which Claude model should I use for Computer Use?"
    answer: "For most tasks, claude-sonnet-4-6 is the best cost/quality balance. claude-opus-4-7 performs better on complex multi-app or multi-window workflows but costs 3–5× more per turn. Start with Sonnet and upgrade if accuracy isn't meeting your bar."
  - question: "Can I use Claude Computer Use on Amazon Bedrock or Google Vertex AI?"
    answer: "Yes. Computer Use is available on both platforms. Pass betas=[\"computer-use-2025-11-24\"] as an extra header in your Bedrock/Vertex client call — the tool schema and beta header are the same as the direct Anthropic API."
  - question: "How do I stop Claude from taking unintended actions?"
    answer: "Add a system prompt that constrains scope: specify which applications it can open, which domains it may visit, and what actions are explicitly off-limits. Always run in an isolated VM or Docker container — never on your development machine with credentials loaded."
  - question: "Is there an official Claude Computer Use demo I can run immediately?"
    answer: "Yes. Anthropic's quickstarts repo (github.com/anthropics/anthropic-quickstarts) ships a Docker container with a pre-wired browser environment, VNC viewer, and the full sampling loop. It runs with a single docker run command once you export your API key."
sources:
  - https://docs.anthropic.com/en/docs/build-with-claude/computer-use
  - https://github.com/anthropics/anthropic-quickstarts/blob/main/computer-use-demo/README.md
  - https://www.digitalapplied.com/blog/anthropic-computer-use-api-guide
  - https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool
hero_image:
  url: /img/blogs/2026-06-01-how-to-use-claude-computer-use/hero.png
  alt: "Diagram of the Claude Computer Use sampling loop: user task → Claude API → tool_use action → pyautogui execution → screenshot → back to Claude"
---

# How to Use Claude Computer Use in 2026: A Practical Tutorial

Claude Computer Use lets your code control a real desktop — mouse, keyboard, and screenshots — through the Anthropic API. To use it: install the `anthropic` Python SDK, pass `computer_20251124` in your tools list with `betas=["computer-use-2025-11-24"]`, build a sampling loop that feeds screenshots to Claude, then execute the actions it returns with pyautogui. Any GUI task becomes automatable — no browser selectors, no screen-scraping scripts, no paid screenshot APIs.

This tutorial takes you from a blank terminal to a working form-filling agent in under 30 minutes.

<Callout type="info">
**"Tools we actually use" series.** This post is part of the [[2026-05-31-agent-control-surface|agent control surface mini-series]] alongside KOEA-7029 (browser-use deep-dive) and KOEA-7030 (Claude bash tool patterns).
</Callout>

---

## Computer Use vs browser-use: pick the right tool first

Before writing a line of code, decide whether Computer Use is actually what you need.

**Reach for Computer Use when:**
- The target is a native desktop app — Electron, Figma, Slack desktop, a legacy Java GUI
- There's no DOM and no API, so Playwright can't touch it
- You need pixel-level precision for drag interactions, canvas tools, or custom-rendered UIs

**Stick with browser-use when:**
- The target is a public web page you can reach with a headless browser context
- You need reliable form filling with instant feedback from validation errors
- Cost matters: browser-use is dramatically cheaper because it sends structured DOM context instead of a full screenshot image every turn

The cost difference is material. A single 1024×768 PNG screenshot is approximately 765 input tokens. A 20-step Computer Use task burns 15,000–20,000 tokens on screenshots alone before counting Claude's completions. For web automation, the [[production-agents-claude-agent-sdk-mcp-connector|Production Agents with Claude Agent SDK course]] covers browser-use as the default automation layer. Computer Use is the escape hatch when browser automation falls short.

---

## Prerequisites

- Python 3.10+
- An Anthropic API key with Computer Use access (all paid tiers — see [console.anthropic.com](https://console.anthropic.com))
- A display environment where you'll execute actions: a Docker container, a VM, or your local machine
- `pip install anthropic pyautogui pillow`

<Callout type="warning">
**Run in an isolated environment.** Claude can click, type, and execute whatever is on screen. Never point Computer Use at your production machine with credentials loaded. A Docker container or dedicated VM is the minimum safe setup — Anthropic's own reference implementation enforces this.
</Callout>

---

## Step 1: Install and verify

```bash
pip install anthropic pyautogui pillow
export ANTHROPIC_API_KEY="sk-ant-..."
```

Quick sanity check — if this returns a list of models, your key is wired up correctly:

```python
import anthropic
client = anthropic.Anthropic()
print([m.id for m in client.models.list()])
```

[Anthropic's get-started guide](https://docs.anthropic.com/en/docs/get-started) covers key generation and account setup if you're starting from scratch.

---

## Step 2: Define your tools

Computer Use needs three tool definitions and one beta header. [Per the Anthropic Computer Use docs](https://docs.anthropic.com/en/docs/build-with-claude/computer-use), all three tools can be passed together in a single request:

```python
import anthropic
import base64, io, time
from PIL import ImageGrab

client = anthropic.Anthropic()

TOOLS = [
    {
        "type": "computer_20251124",   # current version — Nov 2024+
        "name": "computer",
        "display_width_px": 1024,
        "display_height_px": 768,
        "display_number": 1,
    },
    {
        "type": "text_editor_20250728",
        "name": "str_replace_based_edit_tool",
    },
    {
        "type": "bash_20250124",
        "name": "bash",
    },
]

BETA   = ["computer-use-2025-11-24"]
MODEL  = "claude-sonnet-4-6"
```

Three things to get exactly right:

**`display_width_px` and `display_height_px` must match what you actually send.** Claude uses these to calculate click coordinates. If they don't match the screenshot resolution, every click lands in the wrong place. [Anthropic recommends 1024×768](https://github.com/anthropics/anthropic-quickstarts/blob/main/computer-use-demo/README.md) — it's the resolution with the best accuracy-to-cost ratio. Scale your screenshots to this before encoding.

**`computer_20251124` is the current tool type.** The older `computer_20241022` still works but doesn't support enhanced actions like `scroll`, `right_click`, `double_click`, or `hold_key`. Use the 2025 version.

**The beta header is required for the computer tool.** Omit `betas=["computer-use-2025-11-24"]` and the API returns a 400 error. The text editor and bash tools don't need a beta header if you use them without the computer tool.

<KnowledgeCheck
  question="Which beta header is required to use Claude Computer Use in 2026?"
  answers={["computer-use-2025-11-24", "computer-use-2024-10-22", "computer-use-2026-01-01", "No beta header is needed"]}
  correct={0}
/>

---

## Step 3: Capture screenshots

Claude needs a screenshot at the start of each turn to decide what to do next. You don't need a paid screenshot API — capture directly with Pillow:

```python
def capture_screenshot() -> dict:
    """Capture the screen, scale to 1024×768, and return as a base64 image block."""
    img = ImageGrab.grab()
    img = img.resize((1024, 768))

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    data = base64.standard_b64encode(buf.getvalue()).decode("utf-8")

    return {
        "type": "image",
        "source": {"type": "base64", "media_type": "image/png", "data": data},
    }
```

One cost detail worth knowing: [Anthropic's docs state](https://docs.anthropic.com/en/docs/build-with-claude/computer-use) that sending images above XGA/WXGA resolution triggers internal resizing, which both lowers model accuracy and increases latency. Resize to 1024×768 in your code — don't rely on the API to do it. This is also where [[2026-05-31-claude-prompt-caching-roi-2026|prompt caching]] won't help you: screenshots change every turn, so they can't be cached.

---

## Step 4: Execute Claude's actions

When Claude requests a tool use, it returns an `action` string in the tool input. Map it to pyautogui:

```python
import pyautogui

def execute_action(action: dict) -> str:
    """Execute one computer action returned by Claude."""
    atype = action.get("action")

    if atype == "screenshot":
        return "screenshot_requested"   # caller handles this

    elif atype == "left_click":
        x, y = action["coordinate"]
        pyautogui.click(x, y)
        return f"Clicked ({x}, {y})"

    elif atype == "double_click":
        x, y = action["coordinate"]
        pyautogui.doubleClick(x, y)
        return f"Double-clicked ({x}, {y})"

    elif atype == "right_click":
        x, y = action["coordinate"]
        pyautogui.rightClick(x, y)
        return f"Right-clicked ({x}, {y})"

    elif atype == "type":
        pyautogui.write(action["text"], interval=0.05)
        return f"Typed: {action['text']}"

    elif atype == "key":
        # Claude passes e.g. "ctrl+s", "Return", "Tab"
        pyautogui.hotkey(*action["text"].split("+"))
        return f"Key pressed: {action['text']}"

    elif atype == "scroll":
        x, y = action["coordinate"]
        direction = action.get("direction", "down")
        amount = action.get("amount", 3)
        pyautogui.scroll(amount if direction == "up" else -amount, x=x, y=y)
        return f"Scrolled {direction} at ({x}, {y})"

    elif atype == "mouse_move":
        x, y = action["coordinate"]
        pyautogui.moveTo(x, y)
        return f"Moved to ({x}, {y})"

    return f"Unhandled action: {atype}"
```

This covers the eight actions you'll hit in 95% of tasks. The full list — including `left_click_drag`, `hold_key`, `triple_click`, `left_mouse_down`, and `left_mouse_up` — is documented in the [Anthropic Computer Use reference](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool).

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You have access to the computer tool. Take a screenshot and tell me what application is currently in focus."
  expectedOutput="A tool_use block with action: 'screenshot', followed by Claude's text description of the focused application."
/>

---

## Step 5: Build the sampling loop

The sampling loop is the entire pattern. Send a task, receive tool use, execute the action, take a fresh screenshot, feed it back, repeat until Claude stops:

```python
def run_computer_task(task: str, max_iterations: int = 20) -> str:
    """Run a Computer Use task to completion or the iteration limit."""
    messages = [{"role": "user", "content": task}]

    for _ in range(max_iterations):
        response = client.beta.messages.create(
            model=MODEL,
            max_tokens=4096,
            tools=TOOLS,
            messages=messages,
            betas=BETA,
        )

        # Append Claude's response to maintain conversation history
        messages.append({"role": "assistant", "content": response.content})

        # If Claude stopped without a tool call, it's done
        if response.stop_reason != "tool_use":
            for block in response.content:
                if hasattr(block, "text"):
                    return block.text
            return "Task complete."

        # Process each tool_use block in this response
        tool_results = []
        for block in response.content:
            if block.type != "tool_use":
                continue

            action = block.input
            atype  = action.get("action")

            if atype == "screenshot":
                # Claude is asking for a current view of the screen
                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": [capture_screenshot()],
                })
            else:
                # Execute the action, then send back result + fresh screenshot
                result_text = execute_action(action)
                time.sleep(0.5)   # let the UI settle before capturing

                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": [
                        {"type": "text", "text": result_text},
                        capture_screenshot(),   # Claude uses this to verify the action landed
                    ],
                })

        messages.append({"role": "user", "content": tool_results})

    return "Reached max iterations without completing the task."
```

The most important line is the fresh screenshot after every non-screenshot action. Claude uses that image to confirm the click or keypress had the intended effect. Without it, Claude is flying blind — it'll often repeat the same action or get stuck. [Anthropic's reference implementation](https://github.com/anthropics/anthropic-quickstarts/blob/main/computer-use-demo/README.md) follows the same pattern.

---

## Demo: a real task from end to end

Open a browser to any login page, then run:

```python
if __name__ == "__main__":
    result = run_computer_task(
        "Go to the login form visible on screen. "
        "Fill in the username field with 'demo@example.com' and the password field with 'test1234'. "
        "Click Sign In. Tell me what happens on screen after you click."
    )
    print(result)
```

What Claude does, turn by turn:

| Turn | Action | What Claude sees |
|---|---|---|
| 1 | `screenshot` | Initial page state |
| 2 | `left_click` (username field) | Cursor in field, screenshot confirms |
| 3 | `type` "demo@example.com" | Email typed, field populated |
| 4 | `key` "Tab" | Focus moved to password field |
| 5 | `type` "test1234" | Password entered |
| 6 | `left_click` (Sign In button) | Form submitted |
| 7 | `screenshot` | Outcome — logged in or error shown |
| 8 | Text response | Summary of what happened |

Total wall-clock time on a local machine: 8–15 seconds. Total input tokens: ~10,000 (mostly screenshots). This is why Computer Use is right for native GUI tasks but [[production-agents-claude-agent-sdk-mcp-connector|browser-use]] is the better call for public web pages.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Using the computer tool, open the terminal application and run the command 'echo hello world'. Report the output you see."
  expectedOutput="A sequence of tool_use blocks: screenshot to see the desktop, left_click or key action to open terminal, type the command, key Return, screenshot to read output, then a text summary."
/>

---

## Known limitations

Computer Use is beta. Know these before shipping:

**1. Coordinate drift.** Claude's coordinate estimates can be off by 5–20 pixels, especially on high-DPI displays. Always scale to exactly 1024×768. If clicks miss, log the coordinates Claude returns and compare them to what you see — the pattern usually reveals a scale mismatch. [Source: Anthropic docs](https://docs.anthropic.com/en/docs/build-with-claude/computer-use)

**2. Screenshot token cost scales with task length.** Each 1024×768 PNG is ~765 tokens. A 20-turn task: ~15,000 tokens in images alone. For reference: 20 turns of browser-use with DOM context runs under 5,000 tokens total. Budget accordingly.

**3. Single-session only.** Anthropic's reference implementation explicitly notes the agent loop "can only be used by one session at a time" and must be restarted between sessions. Build a queue for multi-user access; don't share an instance.

**4. No state memory across context windows.** If a task fills the context window mid-way, starting fresh is usually better than compaction — Claude rediscovers state from a new screenshot more reliably than from a compressed history. Design tasks to complete within a single context.

**5. CAPTCHA resistance is limited.** Computer Use generates real mouse events, but modern systems (hCaptcha, Cloudflare Turnstile, Google reCAPTCHA v3) detect automation patterns. Don't use it to bypass access controls. Expect occasional CAPTCHA failures on aggressively protected sites.

**6. Latency per turn is 2–5 seconds.** Each round trip includes screenshot capture + encode, API call + streaming, response parse, and action execution with a brief settle delay. Plan for 60–120 seconds on a 20-step workflow.

**7. Claude won't always stop.** Without a clear done condition, Claude may continue taking actions after the task is complete. Always include an explicit success condition in your task prompt: "Once you see the confirmation message, stop and report what it says."

<KnowledgeCheck
  question="Why must you resize screenshots to exactly 1024×768 before sending them to the Computer Use API?"
  answers={[
    "So Claude's coordinate calculations match the actual screen layout",
    "Because the API rejects larger images with a 400 error",
    "To reduce latency only — accuracy is unaffected",
    "Because pyautogui only works at this resolution"
  ]}
  correct={0}
/>

---

## What to build next

Computer Use handles pixel-level GUI tasks that no other tool can reach. For everything else, use the right layer:

- **Web automation on public pages** → [[production-agents-claude-agent-sdk-mcp-connector|browser-use in the Production Agents course]] — cheaper, faster, more reliable
- **File system operations and shell commands** → bash tool, covered in the [[claude-tool-use-from-zero|Claude Tool Use from Zero course]]
- **Connecting Claude to external services** → [[mcp-from-first-principles-to-production|MCP from First Principles to Production]]
- **Visual design automation** → [[2026-04-30-claude-design-visual-workflows|Claude for design workflows]]

The [[2026-05-31-agent-control-surface|agent control surface post]] has a decision tree for choosing between Computer Use, browser-use, bash, and MCP connectors for a given task type.

---

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Use Claude Computer Use in 2026",
  "description": "A step-by-step guide to setting up Claude's Computer Use API for desktop automation: mouse clicks, keyboard input, and screenshot-driven agent loops.",
  "totalTime": "PT30M",
  "tool": [
    { "@type": "HowToTool", "name": "Python 3.10+" },
    { "@type": "HowToTool", "name": "anthropic Python SDK" },
    { "@type": "HowToTool", "name": "pyautogui" },
    { "@type": "HowToTool", "name": "Pillow (PIL)" },
    { "@type": "HowToTool", "name": "Anthropic API key" }
  ],
  "step": [
    {
      "@type": "HowToStep",
      "position": 1,
      "name": "Install the SDK and set your API key",
      "text": "Run pip install anthropic pyautogui pillow and set the ANTHROPIC_API_KEY environment variable."
    },
    {
      "@type": "HowToStep",
      "position": 2,
      "name": "Define the computer_20251124 tool",
      "text": "Add computer_20251124 to your tools list with display_width_px: 1024 and display_height_px: 768. Optionally include text_editor_20250728 and bash_20250124 for file editing and shell access."
    },
    {
      "@type": "HowToStep",
      "position": 3,
      "name": "Add the required beta header",
      "text": "Pass betas=[\"computer-use-2025-11-24\"] in every API call that includes the computer tool. The request returns a 400 error without it."
    },
    {
      "@type": "HowToStep",
      "position": 4,
      "name": "Capture and encode screenshots",
      "text": "Use Pillow's ImageGrab to capture the screen, resize to 1024x768, and base64-encode the PNG. Send this as an image block in the API request."
    },
    {
      "@type": "HowToStep",
      "position": 5,
      "name": "Build the sampling loop",
      "text": "Send the task message, receive tool_use blocks, execute each action with pyautogui, take a fresh screenshot after each action, include it in the tool_result, and repeat until stop_reason is not tool_use."
    }
  ]
}
</script>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Does Claude Computer Use work on Mac?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes. Pillow's ImageGrab.grab() works on macOS 10.15+. For Retina displays, set your display resolution to 1024x768 in System Settings or scale the captured image in code before sending. pyautogui coordinates on Retina need to be divided by the display scale factor (typically 2)."
      }
    },
    {
      "@type": "Question",
      "name": "Which Claude model should I use for Computer Use?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "For most tasks, claude-sonnet-4-6 is the best cost/quality balance. claude-opus-4-7 performs better on complex multi-app workflows but costs 3–5x more per turn. Start with Sonnet."
      }
    },
    {
      "@type": "Question",
      "name": "Can I use Claude Computer Use on Amazon Bedrock or Google Vertex AI?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes. Computer Use is available on both Bedrock and Vertex AI with the same tool schema. Pass betas=[\"computer-use-2025-11-24\"] as an extra header in your Bedrock or Vertex client call."
      }
    },
    {
      "@type": "Question",
      "name": "How do I stop Claude from taking unintended actions?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Add a system prompt that constrains scope: specify which applications it can open, which domains it may visit, and what actions are off-limits. Always run in an isolated VM or Docker container."
      }
    },
    {
      "@type": "Question",
      "name": "Is there an official Claude Computer Use demo I can run immediately?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes. Anthropic's quickstarts repo on GitHub ships a Docker container with a browser environment, VNC viewer, and sampling loop pre-wired. It runs with a single docker run command after you export ANTHROPIC_API_KEY."
      }
    }
  ]
}
</script>
