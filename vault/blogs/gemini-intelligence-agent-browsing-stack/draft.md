---
date: 2026-05-14
title: "Gemini Intelligence vs. the Agent Browsing Stack: A Pre-I/O Scorecard"
slug: "2026-05-14-gemini-intelligence-agent-browsing-stack"
description: "Project Mariner is dead. Gemini Intelligence is live. Google I/O is in 5 days. Here's how Google's agent browsing play compares to browser-use, OpenAI Operator, and Anthropic Computer Use — with pricing math."
author: blog-author
ticket: KOEA-2152
vendor_tag: google
content_type: article
tags:
  - gemini
  - agent-browsing
  - browser-use
  - openai-operator
  - google-io-2026
  - project-mariner
  - computer-use
status: g0-blocked
reading_time_min: 8
primary_query: "gemini intelligence browser agent vs openai operator browser-use 2026"
contrarian_angle: "Project Mariner didn't fail — it was absorbed on purpose; Google's actual developer bet is Gemini 2.5 Computer Use API at $1.25/M input, the most underpriced flagship agent model in the stack"
faq:
  - q: "What replaced Project Mariner?"
    a: "Project Mariner was shut down May 4, 2026. Its technology moved into Gemini Agent, AI Mode, and Chrome Auto Browse rather than remaining a standalone browser-agent experiment."
  - q: "How does Gemini Intelligence compare to OpenAI Operator?"
    a: "GPT-5.5 Pro scores 90.1 on BenchLM agentic benchmarks — the highest published model score cited in this stack. Gemini Intelligence's consumer layer has no published equivalent benchmark. Gemini leads on ecosystem integration (Android/Chrome/Workspace); Operator product reliability is not benchmarked here."
  - q: "Is Gemini 2.5 Computer Use free?"
    a: "No. The Gemini 2.5 Computer Use Preview model is paid-only — $1.25/M input tokens for prompts under 200k tokens. There is no free tier."
sources:
  - https://blog.google/products-and-platforms/platforms/android/gemini-intelligence/
  - https://blog.google/products-and-platforms/products/chrome/bringing-chrome-ai-to-android/
  - https://www.theverge.com/tech/925559/google-project-mariner-shut-down
  - https://aimultiple.com/open-source-web-agents
  - https://ai.google.dev/gemini-api/docs/pricing
  - https://ai.google.dev/gemini-api/docs/computer-use
  - https://9to5google.com/2026/05/12/the-android-show-2026/
  - https://9to5google.com/2026/05/06/gemini-agent-planner-upgrade/
  - https://devtk.ai/en/blog/ai-api-pricing-comparison-2026/
  - https://benchlm.ai/llm-agent-benchmarks
  - https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/computer-use-tool
  - https://io.google/2026/
  - https://blog.google/innovation-and-ai/technology/developers-tools/io-2026-save-the-date/
whats_new:
  - "Project Mariner shut down May 4; Gemini Intelligence launched May 12 — Google's agent browsing is now an OS feature, not a lab experiment, and the $1.25/M Gemini 2.5 Computer Use API quietly undercuts every competitor"
learning_objectives:
  - "Understand how Gemini Intelligence (Chrome Auto Browse, Gemini Agent, AI Mode) replaced Project Mariner's standalone agent model"
  - "Compare the four-player agent browsing stack — Google, OpenAI Operator, browser-use, Anthropic Computer Use — on benchmarks, pricing, and developer access"
  - "Know which Gemini API model and tier to target for building browser-control agents in 2026"
  - "Apply a practitioner decision framework to choose the right agent browsing approach for your use case"
---

# Gemini Intelligence vs. the Agent Browsing Stack: A Pre-I/O Scorecard

Google's standalone browser agent, Project Mariner, was [shut down on May 4, 2026](https://www.theverge.com/tech/925559/google-project-mariner-shut-down). Eight days later, at The Android Show, Google announced Gemini Intelligence — a unified AI suite for premium Android that includes Chrome Auto Browse, cross-app orchestration, and Workspace integration. With [Google I/O 2026 confirmed for May 19](https://blog.google/innovation-and-ai/technology/developers-tools/io-2026-save-the-date/) ([io.google/2026/](https://io.google/2026/)), here is where the four main agent browsing players stand as of today: Google's Gemini stack, OpenAI Operator, open-source browser-use, and Anthropic Computer Use.

The non-obvious read: Project Mariner wasn't killed — it was absorbed. The technology moved into three production surfaces (Gemini Agent, AI Mode, Chrome Auto Browse) because a standalone lab experiment was never going to scale like a browser and OS feature. Meanwhile, the quietly launched [Gemini 2.5 Computer Use Preview API](https://ai.google.dev/gemini-api/docs/pricing) at **$1.25/M input tokens** is the most underpriced flagship agent model in the stack — cheaper than GPT-5.5 API pricing ($5.00/M) and Claude Opus 4.6 ($5.00/M).

## Project Mariner Is Dead — Here's Where It Went

Project Mariner launched in December 2024 as a DeepMind experiment: a browser agent that processed screenshots in real time to click buttons, fill forms, and navigate sites. The shutdown page is blunt: *"Thank you for using Project Mariner. It was shut down on May 4th, 2026 and its technology voyaged to other Google products."*

Google's public shutdown language offers no technical rationale — it says only that Mariner's technology "voyaged to other Google products." My inference from the cited evidence is narrower: Google's move from a standalone Labs-style browser agent into Chrome and Android reduces the friction Mariner had as a separate Ultra-only product. The public benchmark data here proves that browser-use's hybrid DOM/vision framework has a strong WebVoyager score; it does not prove that Mariner failed because of architecture, and Google has made no public statement linking the shutdown to that cause.

What absorbed Mariner's tech:
- **Gemini Agent** — the upgraded agent surface that can take actions on the web and with connected apps, according to strings reported by [9to5Google](https://9to5google.com/2026/05/06/gemini-agent-planner-upgrade/) (retrieved 2026-05-14)
- **AI Mode** — Gemini's enhanced search layer, now with live web-action capability built in
- **Chrome Auto Browse** — task completion embedded directly in the Chrome browser; desktop-available today, [coming to Android in late June 2026](https://9to5google.com/2026/05/12/the-android-show-2026/) (retrieved 2026-05-14)

## What Gemini Intelligence Actually Is

Gemini Intelligence, [announced May 12 at The Android Show](https://blog.google/products-and-platforms/platforms/android/gemini-intelligence/), is Google's umbrella brand for its best AI features on premium Android hardware — not a new model, and not a standalone product. It is an OS-level capability suite: Chrome Auto Browse for web tasks, cross-app orchestration ("build a barbecue menu, add ingredients to Instacart, return for checkout approval"), and Personal Intelligence pulling from Gmail and Calendar to autofill forms and answer context-aware questions.

The consumer positioning is deliberate: Google's [official Gemini Intelligence announcement](https://blog.google/products-and-platforms/platforms/android/gemini-intelligence/) explicitly frames the system around keeping the user "in control" before transactions complete (retrieved 2026-05-14). It rolls out to Samsung Galaxy and Google Pixel devices starting summer 2026, with watches, cars, glasses, and laptops to follow. Per that same announcement, Chrome Auto Browse can [complete tasks including scheduling appointments, filling out forms, managing subscriptions, and purchasing — returning for your approval before any transaction finalises](https://blog.google/products-and-platforms/platforms/android/gemini-intelligence/) (retrieved 2026-05-14).

**The access gate:** Per Google's [Chrome on Android announcement](https://blog.google/products-and-platforms/products/chrome/bringing-chrome-ai-to-android/), Chrome Auto Browse requires Google AI Pro at minimum (retrieved 2026-05-14). This draft does not claim a separate Ultra-only gate for Gemini Agent Mode because the adjacent Google source does not support that claim.

## The Four-Player Comparison

| | Google Gemini | OpenAI Operator | browser-use | Anthropic Computer Use |
|---|---|---|---|---|
| **Architecture** | DOM + OS-level Chrome/Android integration | Managed browser-agent product; model score published separately | Playwright + LLM (hybrid DOM/vision) | Screenshot + keyboard/mouse (API primitive) |
| **Benchmark** | Not published (consumer UI) | GPT-5.5 Pro model: [90.1 on BenchLM](https://benchlm.ai/llm-agent-benchmarks) (no published Operator product score) | 89.1% WebVoyager | Not publicly benchmarked |
| **API access** | Gemini 2.5 Computer Use Preview ($1.25/M) | GPT-5.5 ($5.00/M) | Open source (self-host free) | Claude API ($5.00/M Opus 4.6) |
| **Best for** | Consumer Android/Chrome tasks | Production-ready discrete web tasks | Developer infrastructure, any LLM | Desktop-level OS automation in sandboxes |
| **Ecosystem** | Gmail, Calendar, Drive, Android, Chrome | OpenAI model ecosystem; Operator product behavior not evaluated here | Any LLM via LangChain | Claude API plus reference implementation |
| **Availability** | Consumer: Pro gate for Chrome Auto Browse; API: paid | API pricing/benchmark evidence only | MIT, self-hosted | Beta API |

**The architecture dimension matters because it predicts where agents break.** The four players split across three approaches:

1. **DOM + OS integration** (Gemini Intelligence's Chrome surface): faster on well-structured pages and cheaper than screenshot loops, but weaker when the useful state is hidden in canvas-rendered or obfuscated UIs.

2. **Screenshot + vision** (Anthropic Computer Use, legacy Mariner): sees the browser as a pixel grid, identical to a human's view. Anthropic's official Computer Use docs describe screenshot capture plus mouse and keyboard control for desktop automation, with beta headers required for current models ([Anthropic docs](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/computer-use-tool), retrieved 2026-05-14). The Gemini 2.5 Computer Use Preview model also operates in this mode: it receives screenshot images and returns structured UI actions.

3. **Hybrid DOM + vision** (browser-use, managed browser agents): reads the DOM for structural context and uses a vision model to verify state and handle dynamic rendering — currently the most practical architecture across diverse page types. browser-use's [89.1% WebVoyager accuracy](https://aimultiple.com/open-source-web-agents) is the cleanest public benchmark signal for this framework pattern.

Gemini Intelligence's Chrome surface (DOM-integrated) and Gemini 2.5 Computer Use Preview (screenshot-based) are **not interchangeable layers of the same stack** — they are different products targeting different use cases.

**browser-use** (MIT, Python) achieves [89.1% on WebVoyager](https://aimultiple.com/open-source-web-agents) — the highest accuracy of any open-source framework in AI Multiple's May 2026 roundup (retrieved 2026-05-14). It is infrastructure, not a product: LLM-agnostic, proxy-ready, CAPTCHA-capable. It enables any developer to wire any model to any browser, which Gemini Intelligence's walled garden cannot match. The tradeoff: no persistent memory across sessions, no consumer UI, and no Workspace integration.

[GPT-5.5 Pro scores 90.1 on BenchLM's agentic benchmark](https://benchlm.ai/llm-agent-benchmarks) — the highest published model score in this comparison set (retrieved 2026-05-14). That is a model benchmark, not an end-to-end Operator product benchmark. Treat Operator as a product surface and GPT-5.5 pricing as API economics; do not collapse them into one number.

For a direct model benchmark breakdown across frontier agent workloads, see [[course/picking-a-frontier-model-2026-q2]].

**Anthropic Computer Use** is a developer primitive, not a finished consumer product. Anthropic's docs describe a reference implementation that includes a web interface, Docker container, example tool implementation, and an agent loop; that supports the narrow claim that practical deployments are expected to run in isolated environments, not the broader claim that Anthropic provides a managed desktop product ([Anthropic docs](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/computer-use-tool), retrieved 2026-05-14).

## The Pricing Math That Changes the Developer Equation

The [Gemini API pricing page](https://ai.google.dev/gemini-api/docs/pricing) (retrieved 2026-05-14) lists the Gemini 2.5 Computer Use Preview model — `gemini-2.5-computer-use-preview-10-2025` — at:

- Input: **$1.25/M tokens** (≤200k context)
- Output: **$10.00/M tokens**
- Context window and other limits: see the [Computer Use docs](https://ai.google.dev/gemini-api/docs/computer-use) (paid tier only)

Competitive context from [DevTK's May 2026 pricing comparison](https://devtk.ai/en/blog/ai-api-pricing-comparison-2026/) (retrieved 2026-05-14): GPT-5.5 at $5.00/$30 per 1M, Claude Opus 4.6 at $5.00/$25 per 1M. Gemini 3.1 Pro at $2.00/$12.00 is already the most price-competitive flagship; the Computer Use Preview at $1.25 input is a further 37.5% discount over Gemini 3.1 Pro for browser-agent use cases.

**The developer use case:** If you are building a browser control agent and want a hosted inference backend rather than self-hosting browser-use, Gemini 2.5 Computer Use Preview is the cheapest path to a production-grade model. The catch: it is paid-only (no free tier) and the model is still in preview.

The model accepts screenshot images and returns structured UI actions. A real Computer Use agent loops: take screenshot -> call the model with the `computer_use` tool -> execute the returned action -> send back the new screenshot. Google's official quickstart for `gemini-2.5-computer-use-preview-10-2025` is at [ai.google.dev/gemini-api/docs/computer-use](https://ai.google.dev/gemini-api/docs/computer-use) and requires both a screenshot part and a `computer_use` tool declaration.

<RunPromptCell>

```python
from google import genai
from google.genai import types
from google.genai.types import Content, Part

client = genai.Client()

with open("screenshot.png", "rb") as f:
    screenshot = f.read()

response = client.models.generate_content(
    model="gemini-2.5-computer-use-preview-10-2025",
    contents=[
        Content(
            role="user",
            parts=[
                Part(text="Open the pricing page and find the Computer Use input price."),
                Part.from_bytes(data=screenshot, mime_type="image/png"),
            ],
        )
    ],
    config=types.GenerateContentConfig(
        tools=[
            types.Tool(
                computer_use=types.ComputerUse(
                    environment=types.Environment.ENVIRONMENT_BROWSER
                )
            )
        ]
    ),
)

print(response.candidates[0].content.parts[0].function_call)
```

Expected shape: a `function_call` such as `navigate`, `click_at`, `type_text_at`, or `scroll_document`; your client executes that action, captures a fresh screenshot, and sends it back as the next turn.

</RunPromptCell>

## How to Pick Your Agent Browsing Stack

The four players serve meaningfully different use cases. Here is how to route a decision:

**If you are a consumer user on Android or Pixel:** Gemini Intelligence is the natural choice. It is integrated into your device, Google account, and Chrome — no API key required. The June 2026 Android rollout for Chrome Auto Browse makes this the lowest-friction consumer agent for routine tasks such as form filling, subscriptions, and simple purchases. The limitation: it requires Pro at minimum and still needs user supervision for consequential actions.

**If your shortlist includes Operator:** keep product evaluation separate from model pricing. This draft only uses BenchLM for the model benchmark and DevTK for API pricing; it does not claim current Operator access tiers or product behavior. GPT-5.5 pricing applies only to model-backed agent systems you build yourself.

**If you are a developer who wants LLM flexibility and low vendor lock-in:** browser-use is the correct starting point. It is MIT-licensed, Python, Playwright-backed, and compatible with Gemini, Claude, GPT-5.5, or local models. Its 89.1% WebVoyager score comes with no framework fee beyond your LLM provider. The downside is operational overhead: you run the browser infrastructure, handle anti-bot friction, and build your own memory layer. See [[course/multi-agent-orchestration-a2a]] if you are assessing how to coordinate browser tasks across multiple agents.

**If you need to automate desktop applications, not just browser tasks:** Anthropic Computer Use is the OS-level option in this group: screenshot capture plus mouse and keyboard control, exposed as an API beta. That matters when the target is a native app or a legacy enterprise interface. The trade-off is isolation: Anthropic's reference implementation uses a Docker container, and the safety burden sits with the developer.

**If you are building an agent API layer and API cost is the primary constraint:** Gemini 2.5 Computer Use Preview at $1.25/M input is the lowest-cost hosted model for screenshot-driven browser control in this comparison. At production scale, the 4× pricing gap over GPT-5.5 compounds quickly. The model is still in preview, so factor in the possibility of API changes before Google I/O announcements.

**The hybrid pattern that many teams land on:** Use browser-use for the browser automation layer (open source, composable, benchmarked) and drop in whichever model inference backend best fits the task — Gemini 2.5 Computer Use Preview for cost-sensitive flows, GPT-5.5 Pro for tasks where peak benchmark accuracy matters, Claude for long-context reasoning over page content.

---

> **KnowledgeCheck:** Which Google plan is the minimum requirement for using Chrome Auto Browse to complete web tasks (booking, form filling) on Android when it launches in late June 2026?
>
> A) Free  
> B) Google AI Plus  
> C) Google AI Pro  
> D) Google AI Ultra
>
> **Answer: C** — Per [Google's Chrome on Android announcement](https://blog.google/products-and-platforms/products/chrome/bringing-chrome-ai-to-android/) (retrieved 2026-05-14), Chrome Auto Browse agentic capabilities require Google AI Pro at minimum.

The current read: Google holds the consumer distribution advantage through Android and Chrome, but trails on published benchmark evidence and developer openness. browser-use wins on flexibility. OpenAI Operator wins on managed-product maturity. Gemini wins on reach and API pricing.

Ready to evaluate which model tier fits your agent stack before committing to an API? The [[course/picking-a-frontier-model-2026-q2]] course covers the benchmark dimensions that matter for agentic workloads, including Computer Use tiers, with hands-on exercises. For building multi-agent systems that coordinate browser tasks in parallel, see [[course/multi-agent-orchestration-a2a]]. If Gemini's enterprise integration is your primary interest — Workspace agents, cross-app orchestration, Android deployment — [[course/gemini-enterprise-agents]] covers the full production stack.
