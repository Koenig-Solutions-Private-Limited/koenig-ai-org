---
date: 2026-05-14
title: "Gemini Intelligence vs. the Agent Browsing Stack: A Pre-I/O Scorecard"
slug: "2026-05-14-gemini-intelligence-agent-browsing-stack"
description: "Project Mariner is dead. Gemini Intelligence is live. Google I/O is in 5 days. Here's how Google's agent browsing play compares to browser-use, OpenAI Operator, and Anthropic Computer Use — with pricing math."
author: blog-author
ticket: KOEA-2021
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
status: published
reading_time_min: 6
primary_query: "gemini intelligence browser agent vs openai operator browser-use 2026"
seo_description: "Gemini Intelligence vs browser-use, OpenAI Operator, and Anthropic Computer Use: pre-I/O scorecard with pricing math and what replaced Project Mariner."
contrarian_angle: "Project Mariner didn't fail — it was absorbed on purpose; Google's actual developer bet is Gemini 2.5 Computer Use API at $1.25/M input, the most underpriced flagship agent model in the stack"
faq:
  - q: "What replaced Project Mariner?"
    a: "Project Mariner was shut down May 4, 2026. Its technology moved into three products: Gemini Agent (AI Pro/Ultra), AI Mode (enhanced search), and Chrome Auto Browse (desktop now, mobile late June 2026)."
  - q: "How does Gemini Intelligence compare to OpenAI Operator?"
    a: "OpenAI Operator (GPT-5.5 backbone) scores 90.1 on BenchLM agentic benchmarks versus no published score for Gemini Intelligence's consumer layer. Gemini leads on ecosystem integration (Android/Chrome/Workspace); Operator leads on standalone task reliability."
  - q: "Is Gemini 2.5 Computer Use free?"
    a: "No. The Gemini 2.5 Computer Use Preview model is paid-only — $1.25/M input tokens for prompts under 200k tokens. There is no free tier."
sources:
  - https://blog.google/products-and-platforms/platforms/android/gemini-intelligence/
  - https://www.cnbc.com/2026/05/12/google-races-put-gemini-at-center-of-android-before-apples-ai-reboot.html
  - https://9to5google.com/2026/05/06/gemini-agent-planner-upgrade/
  - https://www.theverge.com/tech/925559/google-project-mariner-shut-down
  - https://aimultiple.com/open-source-web-agents
  - https://ai.google.dev/gemini-api/docs/pricing
  - https://9to5google.com/2026/05/12/the-android-show-2026/
  - https://builtin.com/articles/google-gemini
  - https://devtk.ai/en/blog/ai-api-pricing-comparison-2026/
  - https://www.tomsguide.com/ai/google-just-unlocked-agent-mode-for-gemini-3-1-here-are-7-things-it-can-now-do-for-you
whats_new:
  - "Project Mariner shut down May 4; Gemini Intelligence launched May 12 — Google's agent browsing is now an OS feature, not a lab experiment, and the $1.25/M Gemini 2.5 Computer Use API quietly undercuts every competitor"
learning_objectives:
  - "Understand how Gemini Intelligence (Chrome Auto Browse, Gemini Agent, AI Mode) replaced Project Mariner's standalone agent model"
  - "Compare the four-player agent browsing stack — Google, OpenAI Operator, browser-use, Anthropic Computer Use — on benchmarks, pricing, and developer access"
  - "Know which Gemini API model and tier to target for building browser-control agents in 2026"
---

# Gemini Intelligence vs. the Agent Browsing Stack: A Pre-I/O Scorecard

Google's standalone browser agent, Project Mariner, was [shut down on May 4, 2026](https://www.theverge.com/tech/925559/google-project-mariner-shut-down). Eight days later, at The Android Show, Google announced Gemini Intelligence — a unified AI suite for premium Android that includes Chrome Auto Browse, cross-app orchestration, and Workspace integration. With Google I/O scheduled for May 19, here is where the four main agent browsing players stand as of today: Google's Gemini stack, OpenAI Operator, open-source browser-use, and Anthropic Computer Use.

The non-obvious read: Project Mariner wasn't killed — it was absorbed. The technology moved into three production surfaces (Gemini Agent, AI Mode, Chrome Auto Browse) precisely because a $249.99/month standalone lab experiment was never going to scale. Meanwhile, the quietly launched [Gemini 2.5 Computer Use Preview API](https://ai.google.dev/gemini-api/docs/pricing) at **$1.25/M input tokens** is the most underpriced flagship agent model in the stack — cheaper than [GPT-5.5](/blog/gpt-5-5-vs-claude-opus-4-7-agentic-coding) ($5.00/M) and Claude Opus 4.6 ($5.00/M).

## Project Mariner Is Dead — Here's Where It Went

Project Mariner launched in December 2024 as a DeepMind experiment: a browser agent that processed screenshots in real time to click buttons, fill forms, and navigate sites, available only to Google AI Ultra subscribers at $249.99/month. At its peak it handled 10 parallel tasks. The shutdown page is blunt: *"Thank you for using Project Mariner. It was shut down on May 4th, 2026 and its technology voyaged to other Google products."*

The tell-tale was a Wired report from March: Google had begun [reassigning Mariner staffers](https://www.theverge.com/tech/925559/google-project-mariner-shut-down) months before the shutdown (retrieved 2026-05-14). The internal diagnosis appears to be that screenshot-based browser agents — the architecture both Mariner and Anthropic Computer Use use — lose to approaches that combine DOM parsing with vision, or that run below the browser surface entirely.

What absorbed Mariner's tech:
- **Gemini Agent** — the "24/7 digital partner" for AI Pro/Ultra subscribers, now with Workspace integration (Gmail, Calendar, Drive) and a "require human review" toggle
- **AI Mode** — Gemini's enhanced search layer, now with live web-action capability built in
- **Chrome Auto Browse** — task completion embedded directly in the Chrome browser; desktop-available today, [coming to Android in late June 2026](https://9to5google.com/2026/05/12/the-android-show-2026/) (retrieved 2026-05-14)

## What Gemini Intelligence Actually Is

Gemini Intelligence, [announced May 12 at The Android Show](https://blog.google/products-and-platforms/platforms/android/gemini-intelligence/), is Google's umbrella brand for its best AI features on premium Android hardware — not a new model, and not a standalone product. It is an OS-level capability suite: Chrome Auto Browse for web tasks, cross-app orchestration ("build a barbecue menu, add ingredients to Instacart, return for checkout approval"), and Personal Intelligence pulling from Gmail and Calendar to autofill forms and answer context-aware questions.

The consumer positioning is deliberate: Android VP Sameer Samat told CNBC that ["the human is always in the loop"](https://www.cnbc.com/2026/05/12/google-races-put-gemini-at-center-of-android-before-apples-ai-reboot.html) before transactions complete (retrieved 2026-05-14). It rolls out to Samsung Galaxy and Google Pixel devices starting summer 2026, with watches, cars, glasses, and laptops to follow. Chrome Auto Browse — powered by Gemini 3 — can [schedule appointments, fill online forms, manage subscriptions, and add shopping items to a cart](https://builtin.com/articles/google-gemini) (retrieved 2026-05-14).

**The access gate:** Chrome Auto Browse requires Google AI Pro ($19.99/month) at minimum. The full Gemini Agent Mode — with Workspace integration and multi-step purchasing flows — requires Ultra ($249.99/month), the same tier that previously funded Project Mariner.

## The Four-Player Comparison

| | Google Gemini | OpenAI Operator | browser-use | Anthropic Computer Use |
|---|---|---|---|---|
| **Architecture** | DOM + OS-level Chrome/Android integration | GPT-5.5 browser agent | Playwright + LLM (hybrid DOM/vision) | Screenshot + keyboard/mouse (API primitive) |
| **Benchmark** | Not published (consumer UI) | 90.1 BenchLM agentic score | 89.1% WebVoyager | 72.5% OSWorld-Verified |
| **API access** | Gemini 2.5 Computer Use Preview ($1.25/M) | GPT-5.5 ($5.00/M) | Open source (self-host free) | Claude API ($5.00/M Opus 4.6) |
| **Best for** | Consumer Android/Chrome tasks | Production-ready discrete web tasks | Developer infrastructure, any LLM | Desktop-level OS automation in sandboxes |
| **Ecosystem** | Gmail, Calendar, Drive, Android, Chrome | ChatGPT, Plugin ecosystem | Any LLM via LangChain | Claude agents, Docker sandboxes |
| **Availability** | Consumer: Pro/Ultra tiers; API: paid | ChatGPT Pro/Enterprise | MIT, self-hosted | Beta API |

**browser-use** (MIT, Python, ~88k GitHub stars as of May 2026) achieves [89.1% on WebVoyager](https://aimultiple.com/open-source-web-agents) — the highest accuracy of any open-source framework (retrieved 2026-05-14). It is infrastructure, not a product: LLM-agnostic, proxy-ready, CAPTCHA-capable. It enables any developer to wire any model to any browser, which Gemini Intelligence's walled garden cannot match. The tradeoff: no persistent memory across sessions, no consumer UI, and no Workspace integration.

**OpenAI Operator** leads on raw agentic benchmark performance and is the most production-mature option for standalone web tasks, but its $5.00/M API pricing is 4× the Gemini 2.5 Computer Use Preview rate for comparable agent workloads. Gemini Intelligence occupies Chrome/Android while active — it is not a background process.

For a direct model benchmark breakdown across GPT-5.5 and Claude [Opus 4.7](/blog/2026-04-30-opus-4-7-long-running-coding-benchmark), see [[gpt-5-5-vs-claude-opus-4-7-agentic-coding/draft]].

**Anthropic Computer Use** operates at the OS level (full desktop via Docker sandboxes), which makes it more capable than browser-only agents for complex desktop automation — but it is a developer building block, not a finished product, and its 72.5% OSWorld-Verified score trails Operator's BenchLM.

## The Pricing Math That Changes the Developer Equation

The [Gemini API pricing page](https://ai.google.dev/gemini-api/docs/pricing) (retrieved 2026-05-14) lists the Gemini 2.5 Computer Use Preview model — `gemini-2.5-computer-use-preview-10-2025` — at:

- Input: **$1.25/M tokens** (≤200k context)
- Output: **$10.00/M tokens**
- Context: unlisted (based on 2.5 Pro architecture)

Competitive context from [DevTK's May 2026 pricing comparison](https://devtk.ai/en/blog/ai-api-pricing-comparison-2026/) (retrieved 2026-05-14): GPT-5.5 at $5.00/$30 per 1M, Claude Opus 4.6 at $5.00/$25 per 1M. Gemini 3.1 Pro at $2.00/$12.00 is already the most price-competitive flagship; the Computer Use Preview at $1.25 input is a further 37.5% discount over Gemini 3.1 Pro for browser-agent use cases.

**The developer use case:** If you are building a browser control agent and want a hosted inference backend rather than self-hosting browser-use, Gemini 2.5 Computer Use Preview is the cheapest path to a production-grade model. The catch: it is paid-only (no free tier) and the model is still in preview.

```bash
# Minimal Gemini 2.5 Computer Use Preview — list visible interactive elements on a page screenshot
curl -s https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-computer-use-preview-10-2025:generateContent \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -d '{
    "contents": [{
      "parts": [
        {"text": "List all clickable interactive elements visible in this screenshot and their approximate screen coordinates."},
        {"inline_data": {"mime_type": "image/png", "data": "'$(base64 -w0 screenshot.png)'"}}
      ]
    }],
    "generationConfig": {"temperature": 0}
  }' | jq '.candidates[0].content.parts[0].text'

# Expected output (example):
# "1. Search bar — top-center (~960, 80)\n2. 'Sign In' button — top-right (~1820, 45)\n3. Navigation menu items: Home, Products, Pricing (~200-600, 130)"
```

Note: `screenshot.png` must be a Base64-encoded PNG of the browser viewport. For production use, pair with Playwright to capture and feed screenshots in a loop.

---

> **KnowledgeCheck:** Which Google plan is the minimum requirement for using Chrome Auto Browse to complete web tasks (booking, form filling) on Android when it launches in late June 2026?
>
> A) Free  
> B) Google AI Plus ($7.99/month)  
> C) Google AI Pro ($19.99/month)  
> D) Google AI Ultra ($249.99/month)
>
> **Answer: C** — Chrome Auto Browse's agentic capabilities require Google AI Pro at minimum. Ultra adds the full Gemini Agent Mode with Workspace integration and purchasing flows.

## What to Watch at Google I/O (May 19, 2026)

This comparison is a pre-I/O snapshot. Google I/O 2026 is five days away. Based on pre-event signals, expect announcements on: a next-generation Gemini agentic model (potentially a direct OpenClaw competitor), further Workspace agent integrations, and possibly a production-ready replacement for the Gemini 2.5 Computer Use Preview. Any new model release could shift the pricing and benchmark comparison above materially. A post-I/O update section will be added if warranted.

The current read: Google holds the largest consumer distribution advantage — Android's massive device footprint and Chrome's dominant browser presence — but trails on raw agent benchmark performance and developer openness. browser-use wins on flexibility. OpenAI Operator wins on production maturity. Gemini wins on reach — and, quietly, on API pricing for the Computer Use workload.

---

Ready to evaluate which model tier fits your agent stack before committing to an API? The [[picking-a-frontier-model-2026-q2/outline]] course covers the benchmark dimensions that matter for agentic workloads — including Computer Use tiers — with hands-on exercises. For building multi-agent systems that coordinate browser tasks in parallel, see [[multi-agent-orchestration-a2a/outline]].
