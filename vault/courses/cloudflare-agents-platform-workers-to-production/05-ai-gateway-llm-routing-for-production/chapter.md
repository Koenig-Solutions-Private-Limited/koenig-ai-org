---
chapter_num: 5
course_slug: cloudflare-agents-platform-workers-to-production
title: "AI Gateway: LLM Routing for Production Cloudflare Agents (2026)"
status: draft
author: course-author
ticket: KOEA-6699
learning_objectives:
  - "Route all LLM calls through AI Gateway for unified logging and cost tracking"
  - "Configure per-model rate limits and caching policies to cut repeat-query costs"
  - "Implement fallback routing: primary model to fallback model on failure"
  - "Read AI Gateway analytics to identify top cost drivers and optimize them"
prerequisites_chapters:
  - "01-what-the-agents-platform-actually-is"
duration_min: 45
level: Intermediate-Advanced
positions:
  - id: ai-gateway-beats-third-party-observability
    engagement: defends
  - id: semantic-caching-for-agent-cost-control
    engagement: defends
chapter_primary_query: "How does Cloudflare AI Gateway work for production LLM routing in 2026?"
first_60_words_answer: "Cloudflare AI Gateway is a reverse proxy that sits between your Workers agent and any LLM provider. Route your Workers AI and OpenAI calls through a single gateway URL to get unified token logging, semantic caching (matching similar queries — not just exact ones), per-model rate limits, and automatic fallback routing. AI Gateway has processed 241 billion tokens and adds less than 1ms of overhead on the hot path."
faq:
  - question: "What is Cloudflare AI Gateway?"
    answer: "Cloudflare AI Gateway is a managed reverse proxy for LLM API calls. You replace your model provider's base URL with a gateway URL (e.g., `https://gateway.ai.cloudflare.com/v1/{account}/{gateway}/openai`) and gain unified logging, semantic caching, rate limiting, and model fallback — without changing your client library. It's free for up to 100,000 requests per day and available to all Cloudflare accounts. ([AI Gateway docs](https://developers.cloudflare.com/ai-gateway/))"
  - question: "How does AI Gateway semantic caching work?"
    answer: "Semantic caching uses a vector embedding of the incoming prompt to find cached responses from semantically similar previous queries — not just exact text matches. If a user asks 'What is your refund policy?' and another user asked 'Can I get a refund?' within the cache TTL, the second query may hit the cache and return the prior response without calling the LLM. Cache hit rates of 20–40% are typical for support agents with repetitive query patterns."
  - question: "How do you add AI Gateway to an existing Workers agent without changing model logic?"
    answer: "Replace the base URL in your AI client initialization. For Workers AI: use the `gateway` option in `env.AI.run()` with a `gatewayId` parameter. For OpenAI SDK: set `baseURL` to `https://gateway.ai.cloudflare.com/v1/{account}/{gateway}/openai`. Your model calls, streaming logic, and response parsing stay the same — only the network path changes."
  - question: "Can AI Gateway route to multiple model providers?"
    answer: "Yes. A single AI Gateway instance can proxy calls to Workers AI, OpenAI, Anthropic, Hugging Face, Azure OpenAI, and other providers. You configure per-provider routes within one gateway. This lets you implement a fallback chain: call Sonnet 4.5 via Anthropic first, fall back to GPT-4o via OpenAI if Anthropic returns a 5xx, and fall back to Workers AI Llama as a last resort — all through one gateway configuration."
howto_schema:
  name: "Add Cloudflare AI Gateway to a Workers agent for production LLM routing"
  steps:
    - name: "Create an AI Gateway in the Cloudflare dashboard"
      text: "Navigate to AI → AI Gateway in the Cloudflare dashboard and click 'Create Gateway'. Give it a name (e.g., 'case-agent-gateway') and note the gateway ID. The gateway URL follows the pattern `https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/`."
    - name: "Route Workers AI calls through the gateway"
      text: "In your agent's AI calls, add a `gateway` option to `env.AI.run()`: `env.AI.run(model, params, { gateway: { id: 'case-agent-gateway', skipCache: false } })`. This routes the call through the gateway, enabling logging and caching without any other code changes."
    - name: "Enable semantic caching for repetitive queries"
      text: "In the AI Gateway dashboard, open Settings → Cache and enable 'Semantic caching'. Set a cache TTL (e.g., 3600 seconds for support FAQ responses). Set `cacheKey.custom` to the prompt content if you want consistent cache keys across different user sessions."
    - name: "Configure a fallback model for resilience"
      text: "In the gateway configuration, add a second provider under Fallbacks. Set the primary provider to Workers AI (Llama 3.1 8B) and the fallback to OpenAI (GPT-4o Mini). When Workers AI returns a 5xx, the gateway automatically retries the request against GPT-4o Mini and returns the result to your agent."
    - name: "Read the cost analytics dashboard"
      text: "Navigate to AI Gateway → your gateway → Analytics. Filter by model and date range to see token counts, estimated costs, cache hit rates, and error rates per model. Identify your top-cost model calls and evaluate whether semantic caching or a cheaper fallback model can reduce spend."
inline_assets:
  - type: diagram
    path: ./img/ai-gateway-routing-flow.svg
    alt: "AI Gateway routing flow diagram showing Worker making LLM request to gateway URL, gateway checking semantic cache (hit returns cached response; miss forwards to model provider), fallback routing on 5xx errors, and response returned to Worker with logging"
  - type: diagram
    path: ./img/semantic-cache-vs-exact-cache.svg
    alt: "Semantic cache diagram showing two queries with different wording but similar meaning — 'What is your refund policy?' and 'How do I get my money back?' — both hitting the same cache entry via vector similarity, versus an exact-match cache that would miss the second query"
last_updated: 2026-06-14
sources:
  - https://developers.cloudflare.com/ai-gateway/
  - https://developers.cloudflare.com/ai-gateway/configuration/caching/
  - https://developers.cloudflare.com/ai-gateway/configuration/rate-limiting/
  - https://developers.cloudflare.com/ai-gateway/providers/workersai/
  - https://developers.cloudflare.com/ai-gateway/providers/openai/
  - https://developers.cloudflare.com/ai-gateway/configuration/fallbacks/
tags:
  - cloudflare
  - ai-gateway
  - llm-routing
  - semantic-caching
  - rate-limiting
  - cost-control
  - observability
  - 2026
---

# AI Gateway: LLM Routing for Production Cloudflare Agents (2026)

Cloudflare AI Gateway is a reverse proxy that sits between your Workers agent and any LLM provider. Route your Workers AI and OpenAI calls through a single gateway URL to get unified token logging, semantic caching (matching similar queries — not just exact ones), per-model rate limits, and automatic fallback routing. AI Gateway has processed 241 billion tokens and adds less than 1ms of overhead on the hot path.

This chapter wires AI Gateway into the Chapter 4 case agent: routing all LLM calls through the gateway, enabling semantic caching, configuring a fallback model, and using the analytics dashboard to identify cost reduction opportunities.

---

## The production LLM routing problem

Every production AI agent has the same set of problems with raw LLM API calls:

- **No visibility**: you don't know how many tokens you're spending per user, per case type, or per model until the monthly bill arrives.
- **No cost controls**: a runaway agent or a malicious prompt that induces verbose responses can rack up costs with no circuit breaker.
- **No caching**: a support agent that answers "What is your refund policy?" a hundred times a day calls the LLM a hundred times, paying full token cost each time.
- **No fallback**: if your primary model provider has an outage, your agent goes down entirely.

The typical answer is to build a middleware layer: log all LLM calls to a database, add a Redis cache, implement a rate limiter, wire up a secondary model client for failover. That's 500–1000 lines of infrastructure code that isn't your agent's business logic.

AI Gateway replaces all of it with a URL change.

---

## Architecture: how AI Gateway fits into a Workers agent

Without AI Gateway, your agent calls the model provider directly:

```
Worker → Workers AI (or OpenAI API) → response
```

With AI Gateway, the path becomes:

```
Worker → AI Gateway → Workers AI (or OpenAI API) → response
         ↓
    (check semantic cache)
         ↓ miss
    (check rate limit)
         ↓ within limit
    (log request metadata)
         ↓
    (forward to provider)
         ↓ 5xx error
    (retry with fallback provider)
```

The Worker code doesn't change in structure. You change the URL or add a gateway option to your existing AI call. Everything else happens transparently in the gateway.

---

## Step 1: Create the gateway

In the Cloudflare dashboard, navigate to **AI → AI Gateway → Create Gateway**. Name it `case-agent-gateway`. Note your account ID (available in the dashboard URL or via `wrangler whoami`).

Your gateway URL pattern is:
```
https://gateway.ai.cloudflare.com/v1/{account_id}/case-agent-gateway/{provider}
```

The gateway supports multiple provider path suffixes:
- `.../workers-ai/` — Workers AI models
- `.../openai/` — OpenAI API compatible
- `.../anthropic/` — Anthropic API
- `.../huggingface/` — Hugging Face Inference API

---

## Step 2: Route Workers AI calls through the gateway

The Cloudflare Workers AI binding accepts an optional `gateway` parameter that routes calls through your gateway:

```typescript
// Before: direct Workers AI call
const response = await this.env.AI.run("@cf/meta/llama-3.1-8b-instruct", {
  messages: [{ role: "user", content: userMessage }],
});

// After: routed through AI Gateway
const response = await this.env.AI.run(
  "@cf/meta/llama-3.1-8b-instruct",
  {
    messages: [{ role: "user", content: userMessage }],
  },
  {
    gateway: {
      id: "case-agent-gateway",
      skipCache: false,          // false = check semantic cache first
      cacheTtl: 3600,            // cache responses for 1 hour
      metadata: {
        sessionId: this.ctx.id.toString(),
        caseId: caseId,          // surfaced in gateway analytics per-request
      },
    },
  }
);
```

The `metadata` object attaches arbitrary key-value pairs to each logged request. This is how you correlate gateway logs to your application context — filter the analytics dashboard by `caseId` to see the token cost for a specific case.

---

## Step 3: Route external OpenAI calls through the gateway

If you use the OpenAI SDK for external model calls, change only the `baseURL`:

```typescript
import OpenAI from "openai";

// Before
const openai = new OpenAI({ apiKey: this.env.OPENAI_API_KEY });

// After
const openai = new OpenAI({
  apiKey: this.env.OPENAI_API_KEY,
  baseURL: `https://gateway.ai.cloudflare.com/v1/${this.env.CF_ACCOUNT_ID}/case-agent-gateway/openai`,
  defaultHeaders: {
    "cf-aig-metadata": JSON.stringify({
      sessionId: this.ctx.id.toString(),
    }),
  },
});
```

All existing calls — `openai.chat.completions.create()`, streaming, function calling — work unchanged. The gateway URL change is the only modification.

---

## Step 4: Configure semantic caching

In the AI Gateway dashboard, navigate to **Settings → Cache**:

1. Enable **Semantic caching**
2. Set **Cache TTL** to `3600` seconds (1 hour) for support FAQ responses, or `86400` (24 hours) for stable knowledge base content
3. Set **Similarity threshold** to `0.85` (match queries that are 85%+ semantically similar)
4. Optionally set **Cache scope** to `gateway` (shared across all sessions) or `session` (per-user cache)

For a support agent, a global cache scope makes sense: if ten users ask "How do I cancel my subscription?" within an hour, only the first call hits the LLM. The other nine return the cached response instantly at zero token cost.

**When to skip the cache**: use `skipCache: true` for:
- Queries about real-time state (`"What is the current status of my order?"`)
- Personalized responses that depend on user-specific data the LLM sees in the system prompt
- Tool-calling rounds (the LLM's tool-call decisions are context-dependent and should not be cached)

In the Chapter 4 Workflow, the classification step is a good candidate for caching (`skipCache: false`). The draft-response step should skip the cache because the draft references the specific case context.

---

## Step 5: Configure rate limits

In the AI Gateway dashboard, navigate to **Settings → Rate Limits**:

```
Per-gateway limit: 1000 requests/minute
Per-model limit (Workers AI Llama):  500 requests/minute
Per-model limit (OpenAI GPT-4):       50 requests/minute
```

Rate limits protect against:
- A single agent session consuming the entire budget
- A prompt injection attack that induces the agent to call the LLM in a tight loop
- Cost spikes from a misconfigured Workflow that retries LLM calls too aggressively

When a rate limit is exceeded, the gateway returns a `429 Too Many Requests`. Your agent should handle this gracefully — surface a "high demand, please try again in a moment" message to the user rather than propagating the raw API error.

---

## Step 6: Configure fallback routing

In the AI Gateway dashboard, navigate to **Settings → Fallbacks**:

1. **Primary**: Workers AI (`@cf/meta/llama-3.1-8b-instruct`)
2. **Fallback 1**: OpenAI (`gpt-4o-mini`) — triggers on Workers AI 5xx
3. **Fallback 2**: Anthropic (`claude-haiku-4-5-20251001`) — triggers on OpenAI 5xx

The fallback chain activates automatically. Your Worker code doesn't change — it calls the gateway URL and receives a response, regardless of which provider actually served it. The gateway logs which provider handled each request, so you can see fallback activation rates in the analytics dashboard.

---

## Step 7: Reading the analytics dashboard

Navigate to **AI Gateway → case-agent-gateway → Analytics** and set the date range to the last 7 days.

Key metrics to review:

**Token cost by model**: sort by token count. If Workers AI is handling 90% of calls but a handful of GPT-4 calls consume 60% of token spend, evaluate whether those GPT-4 calls could use a smaller model.

**Cache hit rate**: if semantic caching is enabled and hit rate is below 15%, either your queries are too diverse for caching, the TTL is too short, or the similarity threshold is too high. Try lowering the threshold to `0.80`.

**Error rate by provider**: if Workers AI has a 2% error rate but OpenAI shows 0%, your fallback routing is masking a reliability gap. Check whether the Workers AI model you're using is available in your target PoPs.

**Latency percentiles**: the P99 latency tells you what your slowest users experience. AI Gateway adds less than 1ms to median latency. A high P99 points to LLM provider latency, not the gateway.

---

## The contrarian take: Cloudflare beats third-party observability for Workers agents

Developers reach for LangSmith, Helicone, or Braintrust for LLM observability. These tools are excellent for agent frameworks that run on arbitrary infrastructure. But if you're on Cloudflare Workers, AI Gateway gives you token counts, latency percentiles, provider error rates, semantic caching, and rate limiting for free — no third-party account, no API key to manage, no data leaving your Cloudflare account.

The important caveat: AI Gateway doesn't give you *trace-level* agent observability — it logs LLM calls, not the reasoning steps, tool call results, or Workflow step outputs that context them. For that, you still need the Workers Analytics Engine or an external tool (chapter 7 covers this). But for pure LLM cost and reliability monitoring, AI Gateway eliminates the need for a third-party service for teams already on Cloudflare.

---

## Chapter summary

- AI Gateway routes all LLM calls from your Workers agent through a single proxy, adding logging, semantic caching, rate limiting, and fallback routing with a URL change.
- Add a `gateway` option to `env.AI.run()` for Workers AI calls. Change `baseURL` on the OpenAI SDK client for external provider calls.
- Semantic caching matches queries by meaning (not exact text) — hit rates of 20–40% are typical for support agents with repetitive query patterns.
- Use `metadata` on each gateway call to attach session and case IDs — these surface in the analytics dashboard for per-request attribution.
- Rate limits protect against cost runaway from injection attacks and misconfigured retry loops.
- In the next chapter, you'll expose the agent's tools as an MCP server endpoint so external clients (Claude Desktop, other agents) can call them directly.
