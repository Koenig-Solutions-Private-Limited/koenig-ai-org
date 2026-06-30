---
date: 2026-06-01
title: "Use Claude Computer Use in 2026: API Route, Cowork, and the Tool Loop Most Tutorials Skip"
slug: "2026-06-01-how-to-use-claude-computer-use"
description: "A hands-on tutorial covering both the Claude Computer Use API tool loop and Cowork, with a working Python example, sandbox requirements, and the three prompt injection vectors that make unsandboxed computer use dangerous."
author: blog-author
ticket: KOEA-7027
vendor_tag: anthropic
content_type: article
status: g3-passed
seo_description: "Learn how Claude Computer Use works via the API tool loop or Cowork, with a Python sandbox example and the top prompt injection risks to avoid in 2026."
reading_time_min: 6
primary_query: "how to use claude computer use"
contrarian_angle: "Claude never executes actions itself — your code does. The API is a tool loop, not an agent, and conflating the two is why most computer use implementations end up insecure or brittle."
first_60_words_answer: "Claude Computer Use lets Claude control a desktop by taking screenshots, moving the mouse, and typing — but there are two separate routes: the API beta (for builders shipping automation products) and Cowork/Claude Code (for delegating tasks on your own machine). The right choice depends on who owns the execution environment, not on what you want Claude to do."
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: defends
  - id: audit-trail-as-enterprise-gate
    engagement: defends
sources:
  - https://www.anthropic.com/news/3-5-models-and-computer-use
  - https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool
  - https://www.digitalapplied.com/blog/anthropic-computer-use-api-guide
  - https://blog.laozhang.ai/en/posts/claude-computer-use
  - https://siliconangle.com/2026/03/23/anthropics-claude-gets-computer-use-capabilities-preview
  - https://www.hiddenlayer.com/research/indirect-prompt-injection-of-claude-computer-use
  - https://www.kunalganglani.com/blog/claude-computer-use-security-risks
  - https://www.promptarmor.com/resources/claude-cowork-exfiltrates-files
  - https://www.truefoundry.com/blog/claude-cowork-security-risks
whats_new:
  - Claude Computer Use now has two separate execution contracts — API route for builders, Cowork for delegation — and conflating them produces either over-engineered or insecure systems
learning_objectives:
  - Distinguish the API tool loop from Cowork/Claude Code and pick the right route for your use case
  - Implement a working Claude computer use API call with proper sandbox isolation
  - Identify the three concrete prompt injection vectors that make unsandboxed computer use dangerous
faq:
  - question: "How do I enable Claude computer use in the API?"
    answer: "Pass the beta header `anthropic-beta: computer-use-2025-11-24` in your API request alongside a supported model (Opus 4.8, Opus 4.7, Opus 4.6, Sonnet 4.6, or Opus 4.5). Include a `computer` tool in your tools array. Claude will respond with tool_use blocks describing screenshot, mouse, or keyboard actions — your code executes them and returns tool_result. Retrieved 2026-06-01 from platform.claude.com/docs."
  - question: "Is Claude computer use safe to use?"
    answer: "Only with strict isolation. Anthropic explicitly recommends running computer use inside a Docker container or VM with restricted network access. The core risk is prompt injection: a malicious website or document can instruct Claude to take destructive actions like exfiltrating data. HiddenLayer demonstrated in 2026 that indirect injection can trigger `rm -rf /` on an unsandboxed machine. Retrieved 2026-06-01."
  - question: "What is the difference between Claude computer use API and Cowork?"
    answer: "The API route puts your code in control of the execution loop — Claude outputs action instructions and your application executes them inside a sandbox you control. Cowork is Anthropic's managed product where Claude interacts with your actual desktop without a custom loop. API = builder flexibility with full responsibility for security; Cowork = fast delegation with less control. Retrieved 2026-06-01 from blog.laozhang.ai."
  - question: "What models support Claude computer use in 2026?"
    answer: "As of mid-2026, the `computer-use-2025-11-24` beta header supports Claude Opus 4.8, Opus 4.7, Opus 4.6, Sonnet 4.6, and Opus 4.5. A second header `computer-use-2025-01-24` covers Sonnet 4.5, Haiku 4.5, and deprecated models. The beta adds 466–499 system-prompt tokens plus 735 tool-definition tokens per request before counting screenshot images. Retrieved 2026-06-01 from platform.claude.com/docs."
original_data: false
last_updated: 2026-06-13
hero_image:
  url: /img/blogs/2026-06-01-how-to-use-claude-computer-use/hero.png
  alt: "Claude Computer Use architecture diagram showing the tool loop between Claude API, your application code, and a sandboxed virtual machine"
tags:
  - anthropic
  - computer-use
  - claude-api
  - automation
  - agents
  - security
---

# Use Claude Computer Use in 2026: API Route, Cowork, and the Tool Loop Most Tutorials Skip

Claude Computer Use lets Claude control a desktop by taking screenshots, moving the mouse, and typing — but there are two separate routes with completely different contracts: the API beta for builders shipping automation products, and Cowork/Claude Code for delegating tasks on your own machine. Pick the wrong one and you'll either over-engineer a delegation task or ship a security liability into production.

Most tutorials treat computer use as a monolithic "Claude controls your computer" feature. That framing is wrong — and it's why most implementations end up either brittle or dangerously insecure. The architectural truth is that Claude never executes actions itself. Claude outputs instructions. Your code executes them. That distinction changes everything about how you should build, sandbox, and audit a computer use system.

## Two Execution Contracts, Not One

Anthropic launched computer use as an [API public beta in October 2024](https://www.anthropic.com/news/3-5-models-and-computer-use) with Claude 3.5 Sonnet. On March 23, 2026, the capability landed in a separate product surface — Claude Cowork and Claude Code — as a [research preview for Pro and Max subscribers](https://siliconangle.com/2026/03/23/anthropics-claude-gets-computer-use-capabilities-preview).

These two surfaces have fundamentally different ownership models:

| | API Route | Cowork / Claude Code |
|---|---|---|
| Who owns the loop | You (your application code) | Anthropic's managed product |
| Who owns the sandbox | You | Anthropic |
| Permission model | Programmatic, per-request | Session-based, user-approved |
| Best for | Automation products, internal tooling | Personal delegation on your own machine |
| Audit trail | Whatever your code logs | Cowork sessions (not covered by Compliance API as of mid-2026) |

If you're shipping an automation feature into a product, use the API route. If you want Claude to do repetitive work on your own desktop, use Cowork. Don't mix them.

![Claude Computer Use architecture: the API tool loop vs Cowork session model](/img/blogs/2026-06-01-how-to-use-claude-computer-use/hero.png)

## How the API Tool Loop Actually Works

The [computer use API](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool) is a standard [[glossary/tool-use]] loop, not an autonomous agent. Here's the cycle:

1. Your code captures a screenshot of the desktop state.
2. You send the screenshot plus a task to Claude with the `computer` tool enabled.
3. Claude responds with a `tool_use` block describing the next action: `mouse_move`, `left_click`, `type`, `screenshot`, etc.
4. **Your code** executes that action inside a VM or container you control.
5. Your code sends back a `tool_result` with the new screenshot.
6. Claude determines the next action. Repeat until the task is complete.

Claude never touches your machine directly. It produces structured instructions; your application decides whether and how to execute them. This is the architectural fact that most tutorials elide — and it's where your safety controls actually live.

As of mid-2026, [`computer-use-2025-11-24`](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool) supports Claude Opus 4.8, Opus 4.7, Opus 4.6, Sonnet 4.6, and Opus 4.5; a second header `computer-use-2025-01-24` covers Sonnet 4.5, Haiku 4.5, and deprecated models.

## Minimal Working Implementation

```python
import anthropic
import base64
from screenshot_utils import capture_desktop_screenshot  # your sandbox screenshot tool

client = anthropic.Anthropic()

def run_computer_use_task(task: str) -> None:
    screenshot_b64 = base64.b64encode(capture_desktop_screenshot()).decode()
    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {"type": "base64", "media_type": "image/png", "data": screenshot_b64},
                },
                {"type": "text", "text": task},
            ],
        }
    ]

    while True:
        response = client.beta.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=4096,
            tools=[{"type": "computer_20251124", "name": "computer", "display_width_px": 1280, "display_height_px": 800}],
            messages=messages,
            betas=["computer-use-2025-11-24"],
        )

        if response.stop_reason == "end_turn":
            break

        tool_calls = [b for b in response.content if b.type == "tool_use"]
        if not tool_calls:
            break

        tool_results = []
        for tool_call in tool_calls:
            result_screenshot = execute_action(tool_call.input)  # YOUR sandbox executor
            tool_results.append({
                "type": "tool_result",
                "tool_use_id": tool_call.id,
                "content": [{"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": base64.b64encode(result_screenshot).decode()}}],
            })

        messages.append({"role": "assistant", "content": response.content})
        messages.append({"role": "user", "content": tool_results})

run_computer_use_task("Open the terminal and list files in the home directory.")
```

**Expected output**: Claude issues a sequence of `tool_use` blocks — `key: super` to open a launcher, `type: terminal`, `key: Return`, `type: ls`, `key: Return` — your executor fires each action inside the sandbox VM, and Claude reads back the resulting screenshot to confirm completion.

Note the token overhead: the `computer-use-2025-11-24` beta adds [466–499 system-prompt tokens plus 735 tool-definition tokens](https://blog.laozhang.ai/en/posts/claude-computer-use) before counting screenshot images. A session with 10 screenshot exchanges at 1280×800 pixels can easily hit 50K tokens. Budget accordingly.

## The Prompt Injection Risk You Can't Ignore

Prompt injection is [OWASP's #1 LLM vulnerability in 2026](https://www.kunalganglani.com/blog/claude-computer-use-security-risks), and computer use makes it catastrophically more dangerous than in chatbot contexts.

The attack is straightforward: a malicious website or document embeds hidden text — invisible to humans, visible to Claude's vision model — that contains instructions. When Claude reads the page as part of a task, it may execute the injected instructions. [HiddenLayer demonstrated](https://www.hiddenlayer.com/research/indirect-prompt-injection-of-claude-computer-use) that this can trigger `rm -rf /` on an unsandboxed machine. In June 2026, [PromptArmor](https://www.promptarmor.com/resources/claude-cowork-exfiltrates-files) showed a complete enterprise attack chain where a Word document with invisible injection text caused Cowork to locate and exfiltrate financial documents to an attacker-controlled account.

Anthropic's own guidance for production use:

- **Run inside a container or VM.** Never point computer use at your dev machine or production host.
- **Restrict network access.** Whitelist only the domains the task requires. An agent that can't reach arbitrary URLs can't exfiltrate data.
- **No credentials in the sandbox.** No browser password managers, no SSH keys, no API tokens.
- **Log every action.** Screenshot every state transition. A complete [[glossary/audit-trail]] is the only way to answer compliance questions after the fact.

The [audit trail requirement](https://www.truefoundry.com/blog/claude-cowork-security-risks) is particularly sharp for enterprise teams: as of mid-2026, Cowork sessions are explicitly excluded from Anthropic's Compliance API and Audit Logs. If your security or compliance team asks "what did Claude do on that machine at 14:32?", the API route with your own logging is the only path to an answer.

## When Cowork Is the Right Call

If you're an individual contributor delegating repetitive research, data entry, or file organization on your own machine, Cowork is the faster answer. Open Claude Desktop, switch to Cowork, describe the task, review the plan, and leave the desktop app running. Claude always asks permission before accessing a new application and can be interrupted at any point.

The tradeoff is control: you get speed and simplicity, but you're working within Anthropic's managed session model rather than a sandbox you own. For personal productivity tasks where you're present to supervise, that's a reasonable deal. For unattended automation, it's not.

## KnowledgeCheck

**Which of the following is true about the Claude Computer Use API?**

A) Claude directly executes mouse and keyboard actions on the host machine  
B) Your application code executes actions; Claude only outputs instructions in tool_use blocks  
C) The computer use beta requires a separate Anthropic subscription beyond API access  
D) Prompt injection is only a risk when browsing untrusted websites, not when processing local documents

**Correct answer: B.** Claude outputs `tool_use` blocks; your code decides whether and how to execute them inside your sandbox. This is the load-bearing architectural fact for building safe computer use systems. Prompt injection (ruling out D) is equally dangerous from local documents — the PromptArmor June 2026 demo used a Word file, not a website.

---

If you want to go deeper on building production-grade agentic systems with Claude — including tool loops, sandboxing patterns, and multi-agent orchestration — the [[course/claude-tool-use-from-zero]] course covers the full stack from first API call to deployed agent pipeline.
