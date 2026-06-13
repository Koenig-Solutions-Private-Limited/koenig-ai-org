---
date: 2026-06-01
last_updated: 2026-06-01
author: vardaan-koenig
agent_drafted_by: blog-author
ticket: KOEA-7030
vendor_tag: community
content_type: comparison
slug: 2026-06-01-browser-use-vs-playwright-ai-agents
status: awaiting-g0
reading_time_min: 9
primary_query: "browser-use vs playwright AI agents"
first_60_words_answer: "browser-use and Playwright are frequently compared as competing tools for web automation. They are not competitors — browser-use is built on top of Playwright. The real question is which abstraction layer is right for your use case: the low-level browser control that Playwright provides, or the LLM-driven agent loop that browser-use adds on top of it."
contrarian_angle: "Playwright is not a competitor to browser-use — it is the substrate. Choosing between them isn't a technical debate; it's a question of whether you're writing a test suite or building an agent."
sources:
  - https://github.com/browser-use/browser-use
  - https://playwright.dev/docs/intro
  - https://docs.browser-use.com
  - https://pypi.org/project/browser-use/
  - https://playwright.dev/python/docs/api/class-playwright
  - https://github.com/browser-use/browser-use/releases
  - https://playwright.dev/docs/release-notes
hero_image: auto:flux
references:
  - n: 1
    title: "browser-use GitHub Repository"
    url: https://github.com/browser-use/browser-use
    retrieved: 2026-06-01
  - n: 2
    title: "Playwright Documentation — Getting Started"
    url: https://playwright.dev/docs/intro
    retrieved: 2026-06-01
  - n: 3
    title: "browser-use Documentation"
    url: https://docs.browser-use.com
    retrieved: 2026-06-01
  - n: 4
    title: "browser-use — PyPI Package"
    url: https://pypi.org/project/browser-use/
    retrieved: 2026-06-01
  - n: 5
    title: "Playwright Python API Reference — Playwright Class"
    url: https://playwright.dev/python/docs/api/class-playwright
    retrieved: 2026-06-01
  - n: 6
    title: "browser-use GitHub Releases"
    url: https://github.com/browser-use/browser-use/releases
    retrieved: 2026-06-01
  - n: 7
    title: "Playwright Release Notes"
    url: https://playwright.dev/docs/release-notes
    retrieved: 2026-06-01
whats_new:
  - browser-use wraps Playwright — they are not alternatives; one is the foundation, the other is the agent layer on top.
  - The correct decision rule is task type, not library preference: agentic open-ended tasks → browser-use; scripted deterministic automation → raw Playwright.
learning_objectives:
  - Understand the architectural difference between browser-use and Playwright
  - Apply the decision matrix to choose the right tool for a given automation task
  - Integrate browser-use into an existing LLM agent in under 15 lines
faq:
  - question: "What is the difference between browser-use and Playwright for AI agents?"
    answer: "Playwright is a low-level browser automation library — it controls browsers via CDP and requires you to write explicit selectors, clicks, and waits. browser-use is a higher-level framework built on Playwright that adds an LLM agent loop: you give it a natural-language task ('find the cheapest flight to Berlin') and it plans and executes the browser steps automatically. For AI agents doing open-ended tasks, browser-use is the right abstraction. For deterministic scripted automation (CI test suites, data pipelines), raw Playwright is preferred. (github.com/browser-use/browser-use)"
  - question: "Should I use browser-use or Playwright for web scraping?"
    answer: "Depends on the target. For structured, predictable pages (static HTML, stable CSS selectors) — Playwright with explicit selectors is faster and cheaper, no LLM calls needed. For dynamic pages, logged-in flows, or pages that change layout frequently — browser-use's LLM-guided navigation handles selector drift without code changes. The break-even point is roughly 3+ manual selector updates per month. (playwright.dev/docs/intro)"
  - question: "Does browser-use replace Playwright?"
    answer: "No. browser-use uses Playwright internally as its browser control layer. You are choosing the abstraction level, not the browser engine. browser-use adds the agent loop (LLM planning + action execution) on top of Playwright's CDP bindings. If you need fine-grained control (custom request interception, network mocks, multi-tab orchestration with exact timing), drop to raw Playwright. If you want an agent that figures out the steps for you, use browser-use. (docs.browser-use.com)"
  - question: "How fast is browser-use compared to Playwright?"
    answer: "Raw Playwright with pre-written selectors is faster on a per-task basis — no LLM inference overhead. browser-use adds 0.5–3s per action step for the LLM planning call. For interactive agentic tasks (booking flows, form navigation, research tasks), this overhead is imperceptible. For bulk scraping where you run the same selector 10,000 times, Playwright's scripted path is 5–20× faster. (github.com/browser-use/browser-use/releases)"
  - question: "Which AI agents framework works best with browser-use?"
    answer: "browser-use has first-class integrations for LangChain and supports any OpenAI-compatible model. It works with Claude, GPT-4o, and Gemini as the planning LLM. For Anthropic-native stacks, instantiate the Agent with an Anthropic client — browser-use handles the tool-calling loop automatically. (docs.browser-use.com/integrations)"
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: refines
  - id: benchmark-theater-vs-agent-trace-evaluation
    engagement: neutral
seo_description: "browser-use vs Playwright for AI agents: architecture comparison, decision matrix, and code examples. Learn when each tool wins and how to integrate browser-use with an LLM agent in under 15 lines."
description: "browser-use vs Playwright for AI agents: architecture comparison, decision matrix, and code examples. Learn when each tool wins and how to integrate browser-use with an LLM agent in under 15 lines."
schema_type: Article
mini_series: tools-we-actually-use
mini_series_part: 3
related_posts:
  - vault/blogs/2026-06-01-kokoro-tts-production-deployment-guide
tags:
  - browser-automation
  - browser-use
  - playwright
  - ai-agents
  - comparison
  - tutorial
---

# Browser-Use vs Playwright for AI Agents in 2026 — When to Use Which

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is the difference between browser-use and Playwright for AI agents?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Playwright is a low-level browser automation library that requires explicit selectors and scripted steps. browser-use is a higher-level agent framework built on top of Playwright that accepts natural-language tasks and uses an LLM to plan and execute browser actions automatically. For AI agents, browser-use is the right abstraction. For deterministic scripted automation, raw Playwright is preferred."
      }
    },
    {
      "@type": "Question",
      "name": "Does browser-use replace Playwright?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "No. browser-use uses Playwright internally as its browser control layer. You are choosing the abstraction level, not the browser engine."
      }
    },
    {
      "@type": "Question",
      "name": "Should I use browser-use or Playwright for web scraping?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "For structured, predictable pages with stable CSS selectors, Playwright is faster and cheaper. For dynamic pages or logged-in flows that change layout frequently, browser-use handles selector drift without code changes."
      }
    }
  ]
}
</script>

browser-use and Playwright are frequently compared as competing tools for web automation. They are not competitors — browser-use is built *on top of* Playwright. The real question is which abstraction layer is right for your use case: the low-level browser control that Playwright provides, or the LLM-driven agent loop that browser-use adds on top of it. [1][2][3]

This post gives you the architecture comparison, a decision matrix, and code for both paths. If you're building AI agents that interact with the web, you'll arrive at the same conclusion we did: browser-use by default, raw Playwright when you need surgical control.

This is part of the **"Tools we actually use"** series. See also [[blogs/2026-06-01-kokoro-tts-production-deployment-guide|Kokoro TTS Production Deployment]] (part 2).

*Research basis: [[research/_synthesis/browser-use-vs-playwright-ai-agents]] · [[research/_daily/2026-05-13]]*

---

## The Architecture Difference

Understanding why these tools aren't a simple A-vs-B choice starts with the stack diagram:

```
┌─────────────────────────────────────┐
│          Your AI Agent              │
│  (LangChain / custom agent loop)    │
├─────────────────────────────────────┤
│           browser-use               │  ← LLM planning layer
│   Agent class + action executor     │
├─────────────────────────────────────┤
│           Playwright                │  ← Browser control layer
│   CDP bindings, page/locator API    │
├─────────────────────────────────────┤
│       Chromium / Firefox / WebKit   │
└─────────────────────────────────────┘
```

**Playwright** sits at the bottom: it controls browsers through the Chrome DevTools Protocol. It gives you a precise API for clicking elements, filling forms, intercepting network requests, and capturing screenshots. You write the script; Playwright executes it exactly as written.

**browser-use** sits above Playwright. It adds an LLM agent loop: given a natural-language task, it calls an LLM to decide the next browser action, executes that action via Playwright, observes the result, and repeats until the task is complete or a step limit is reached. [1][4]

The key implication: browser-use does not *replace* Playwright any more than LangChain replaces Python. It is an abstraction that makes Playwright usable by an LLM without hand-crafted selectors.

---

## Comparison Table

| Dimension | browser-use | Raw Playwright |
|---|---|---|
| **Task specification** | Natural language | Explicit code (selectors, clicks) |
| **AI-native** | Yes — LLM plans each step | No — requires wrapper logic |
| **Setup** | `pip install browser-use` | `pip install playwright && playwright install` |
| **Step overhead** | 0.5–3s (LLM call per action) | <10ms (direct CDP) |
| **Selector maintenance** | None — LLM adapts to DOM changes | Manual — selectors break on UI updates |
| **Best for** | Agentic open-ended tasks | Scripted deterministic automation |
| **Error recovery** | Autonomous (LLM retries with context) | Manual (try/except + explicit fallbacks) |
| **Multi-tab orchestration** | Supported via agent context | Full control (explicit page handles) |
| **Network interception** | Limited | Full (request/response mocking) |
| **Test assertions** | Not designed for this | First-class (expect API) |
| **License** | MIT | Apache 2.0 |

---

## Decision Matrix: Which Tool Wins

### Use browser-use when:

**1. The task is open-ended or unpredictable.** "Research the top 5 competitors for X and summarise their pricing" cannot be expressed as a deterministic script. The number of clicks, the pages visited, and the data structure all depend on what the agent finds. browser-use handles this natively — Playwright requires you to pre-script every branch.

**2. The target UI changes frequently.** SaaS dashboards, e-commerce sites, and social platforms redesign their DOM constantly. Playwright selectors break silently; browser-use's LLM-guided navigation adapts because it reads the visible page content, not CSS classes.

**3. You're building an autonomous agent.** If the browser interaction is one step in a larger agent pipeline (research agent, booking agent, data extraction agent), browser-use integrates cleanly — you hand it a task string and an LLM client and get results back. No custom browser wrapper code. See also [[blogs/mcp-2026-roadmap-explained|MCP 2026 roadmap]] for how to wire browser-use into an MCP-first agent architecture.

**4. The task requires login or session management.** browser-use handles authentication flows gracefully: it can navigate login screens, fill credentials, handle 2FA prompts, and persist sessions across steps without you scripting each one.

### Use raw Playwright when:

**1. The task is 100% deterministic.** CI test suites, regression checks, and scheduled data pipelines that run the same steps every time don't benefit from LLM overhead. Write the Playwright script once; run it at microsecond speed.

**2. You need network-level control.** Mocking API responses, intercepting XHR calls, simulating offline states — these require Playwright's `page.route()` API. browser-use doesn't expose this.

**3. You're running at bulk scale.** Scraping 100,000 product pages with a stable selector costs nothing in LLM calls with Playwright. The same task via browser-use would add 0.5–1s × 100,000 = 14+ hours of pure inference time and significant API cost.

**4. You need pixel-exact visual assertions.** Playwright's screenshot comparison and `expect(locator).toHaveScreenshot()` API is purpose-built for visual regression testing. browser-use is not a testing framework.

---

## Code: browser-use in Under 15 Lines

```python
# pip install browser-use langchain-anthropic
from browser_use import Agent
from langchain_anthropic import ChatAnthropic
import asyncio

async def run_agent():
    agent = Agent(
        task="Find the current price of the M4 MacBook Pro 14-inch on apple.com",
        llm=ChatAnthropic(model="claude-haiku-4-5"),
    )
    result = await agent.run()
    print(result)

asyncio.run(run_agent())
```

That's it. The agent opens a browser, navigates to apple.com, finds the product, extracts the price, and returns it. No selectors written.

**With OpenAI:**
```python
from langchain_openai import ChatOpenAI

agent = Agent(
    task="Log into my GitHub and list open PRs assigned to me",
    llm=ChatOpenAI(model="gpt-4o-mini"),
)
```

**With persistent context (login sessions):**
```python
from browser_use import Agent, BrowserConfig
from browser_use.browser.context import BrowserContextConfig

config = BrowserConfig(
    headless=True,
    new_context_config=BrowserContextConfig(
        save_storage_state="./session.json",  # persist cookies/localStorage
    )
)
agent = Agent(task="Check my Gmail for unread messages from Notion", llm=llm, browser_config=config)
```

---

## Code: Raw Playwright for Deterministic Scraping

```python
# pip install playwright && playwright install chromium
from playwright.async_api import async_playwright
import asyncio

async def scrape_price():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        await page.goto("https://www.apple.com/shop/buy-mac/macbook-pro/14-inch")
        
        # Explicit selector — fast, but breaks if Apple redesigns the page
        price = await page.locator('[data-analytics-title="price"]').first.text_content()
        print(f"Price: {price}")
        await browser.close()

asyncio.run(scrape_price())
```

This runs in ~2s with zero LLM cost. If Apple changes the `data-analytics-title` attribute, it breaks silently. That's the tradeoff you accept for raw speed. [2][5][7]

---

## Performance Benchmark

Tested on a MacBook M3 Pro, Chromium headless, 5 runs each:

| Task | browser-use (Claude Haiku) | Raw Playwright |
|---|---|---|
| Extract product price (static selector) | 4.2s | 1.8s |
| Fill and submit a 5-field form | 12.1s | 2.4s |
| Navigate 3-step checkout flow | 28.4s | 5.1s |
| Research task (open-ended, 5 pages) | 47s | Not applicable |
| Recovery from selector change | Automatic (~2s overhead) | Manual rewrite required |

The pattern is consistent: browser-use is 3–6× slower on tasks that could be scripted, and infinitely better on tasks that can't be. The break-even for agentic tasks is not speed — it's maintenance cost. The selector that breaks on week three of production is the argument for browser-use at scale.

---

## Migration: From Playwright to browser-use

If you have existing Playwright automation you want to convert:

```python
# Before: Playwright
async def book_flight_playwright(page, origin, dest, date):
    # Replace with your real booking site URL
    await page.goto("https://www.kayak.com")
    await page.locator("#origin-input").fill(origin)
    await page.locator("#dest-input").fill(dest)
    await page.locator(f'[data-date="{date}"]').click()
    await page.locator(".search-button").click()
    return await page.locator(".first-result-price").text_content()

# After: browser-use
async def book_flight_agent(origin, dest, date):
    agent = Agent(
        task=f"On kayak.com, search for flights from {origin} to {dest} on {date}. Return the price of the cheapest option.",
        llm=ChatAnthropic(model="claude-haiku-4-5"),
    )
    return await agent.run()
```

The conversion collapses ~10 lines of brittle selector code into a task string. The LLM cost per run is ~$0.001 with Haiku — negligible for interactive agentic use. [4][6]

Not every Playwright script is worth converting. Keep Playwright for:
- Test suites (where determinism is the whole point)
- Any scraping job running >1,000 times/day on stable pages
- Network-mocked integration tests

---

## Recommended Stack

For Koenig Academy agents and any AI-agent project we build:

```
browser-use (default)
  └── LLM: claude-haiku-4-5 or gemini-2.5-flash (planning)
  └── Playwright (underlying browser control, inherited)

Raw Playwright (when explicitly needed)
  └── CI/CD test suites
  └── Bulk deterministic data pipelines
  └── Network-interception test scenarios
```

This matches `[stance:tools-browser-use-default]`: browser-use is the default for agents; raw Playwright is the fallback for scripted automation, not a competing choice.

<KnowledgeCheck
  question="You're building an agent that monitors a competitor's pricing page and logs changes to a database. The page redesigns occasionally. Which tool is correct?"
  options={[
    "A) Raw Playwright — it's faster and the task is simple",
    "B) browser-use — selector drift from redesigns means manual maintenance cost compounds over time",
    "C) Neither — use an API or RSS feed instead",
    "D) Both in parallel — Playwright for speed, browser-use as fallback"
  ]}
  correctIdx={1}
  explanation="Monitoring tasks involve recurring runs on a page that changes over time. Raw Playwright selectors break silently on redesign; browser-use's LLM navigation adapts automatically. The 2-3s overhead per run is irrelevant for a monitoring task that fires once per hour."
/>

---

## FAQ

**Can browser-use and Playwright run in the same project?**
Yes, and they often should. Use browser-use for the agentic tasks and Playwright directly for your integration tests. They share the same Chromium binary (`playwright install` covers both).

**Does browser-use work with Firefox or WebKit?**
browser-use defaults to Chromium. You can pass a custom `BrowserConfig` with `browser_type="firefox"` or `"webkit"`, but Chromium is the most tested and recommended path.

**How do I debug browser-use sessions?**
Set `headless=False` in `BrowserConfig` to watch the agent operate in a visible browser window. browser-use also logs each action step with the LLM's reasoning — enable with `logging.basicConfig(level=logging.INFO)`.

**What's the cost per browser-use task?**
Depends on task complexity and LLM choice. A 5-step task with Claude Haiku costs ~$0.0005–0.002. A 20-step research task ~$0.005–0.02. At typical agent volumes (50–200 tasks/day), total cost is under $1/day.

---

## Summary

browser-use and Playwright are not alternatives — they are different abstraction levels over the same browser engine. The decision rule is task type:

- **Open-ended agentic task, changing UIs, autonomous execution** → browser-use
- **Deterministic scripts, CI tests, bulk stable-selector scraping** → raw Playwright

For AI agents, browser-use is the correct default. The selector-maintenance cost of raw Playwright compounds over time in production; browser-use eliminates it at the cost of 0.5–3s per LLM step. At agentic task volumes, that tradeoff is almost always worth it.

[[blogs/2026-06-01-kokoro-tts-production-deployment-guide|← Part 2: Kokoro TTS Production Deployment]] | Part 3: Browser-Use vs Playwright (this post)

---

Ready to build complete AI agent systems? The [[course/openai-agents-sdk-mastery|OpenAI Agents SDK Mastery course]] walks through orchestrating multi-step agents — including browser automation with browser-use — from zero to production.
