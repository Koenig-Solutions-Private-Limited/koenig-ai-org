---
date: 2026-06-30
author: blog-author
ticket: KOEA-9763
vendor_tag: anthropic
content_type: article
status: draft-for-review
reading_time_min: 6-7
primary_query: "claude azure foundry hosted on azure vs hosted on anthropic capability tradeoffs"
contrarian_angle: "Every launch recap treated 'Claude on Azure' as one product — it's two, with a hard API-enforced capability split most architects haven't seen yet"
first_60_words_answer: "Claude (Opus 4.8 and Haiku 4.5) went GA on Microsoft Azure Foundry on June 29, 2026, in two hosting modes with meaningfully different capability sets. Hosted on Azure blocks web search, code execution, the MCP connector, structured outputs, and the Files API — returning 400 errors by design. Hosted on Anthropic delivers full API parity at the cost of Azure data residency. The choice is architectural, not cosmetic."
seo_description: "Claude on Azure Foundry offers two hosting modes with different capabilities. Hosted on Azure blocks web search, MCP connector, and code execution. Here's the full split."
positions:
  - id: stance:ai-vendor-news-opinionated
    engagement: defends
  - id: mcp-as-interoperability-moat
    engagement: refines
  - id: audit-trail-as-enterprise-gate
    engagement: neutral
faq:
  - question: "What features are unavailable in Claude Hosted on Azure mode?"
    answer: "Hosted on Azure blocks nine capabilities: web search, web fetch, code execution, tool search, structured outputs, the MCP connector, Agent Skills, programmatic tool calling, and the Files API. Calling any of these returns a 400 Bad Request error by design. Source: Anthropic Foundry docs, retrieved 2026-06-30."
  - question: "Which Claude models are available on Azure Foundry Hosted on Azure?"
    answer: "At GA (June 29, 2026), only Claude Opus 4.8 and Claude Haiku 4.5 run on Hosted on Azure infrastructure. The full nine-model roster — including Claude Fable 5 and all Sonnet variants — requires Hosted on Anthropic. This is a hard constraint in Anthropic's official model table."
  - question: "Can I use Azure Enterprise Agreement (EA) commitments with Claude on Foundry?"
    answer: "Yes. Eligible customers with Microsoft Enterprise Agreements can apply existing Azure MACC commitments to offset Claude Foundry spend across both hosting modes. Billing runs through Azure Marketplace in Claude Consumption Units (CCUs), invoiced monthly. Verify current rates on the Azure Foundry pricing page before scoping costs."
  - question: "Is the MCP connector available on Azure Foundry Hosted on Azure?"
    answer: "No. The MCP connector is explicitly blocked on Hosted on Azure and returns a 400 error. Any pipeline routing tool calls through MCP servers must use Hosted on Anthropic through Foundry, or run MCP calls through a client-side intermediary outside the Foundry endpoint."
original_data: false
last_updated: 2026-07-01
hero_image:
  url: /img/blogs/claude-azure-foundry-hosted-mode-tradeoffs/hero.png
  alt: "Side-by-side comparison diagram of Claude Hosted on Azure versus Hosted on Anthropic capability sets in Microsoft Foundry, showing which API features are available in each mode"
sources:
  - https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry
  - https://claude.com/blog/claude-in-microsoft-foundry
  - https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude
  - https://platform.claude.com/docs/en/docs/about-claude/models/overview
  - https://www.anthropic.com/news/claude-in-microsoft-foundry
  - https://blogs.nvidia.com/blog/anthropic-nvidia-gb300-blackwell-ultra-microsoft-azure/
  - https://platform.claude.com/docs/en/api/claude-on-vertex-ai
whats_new:
  - "Hosted on Azure blocks 9 capabilities — web search, MCP, code execution, structured outputs — while Hosted on Anthropic delivers full API parity. Here's the exact split."
learning_objectives:
  - "Identify which Claude API features are blocked by Hosted on Azure mode and why they return 400 errors"
  - "Choose the correct hosting mode based on your pipeline's tool requirements and compliance constraints"
---

# Claude on Azure Foundry in 2026: What You Actually Lose in Hosted-on-Azure Mode (And When It Matters)

Claude (Opus 4.8 and Haiku 4.5) went GA on Microsoft Azure Foundry on June 29, 2026, in two hosting modes with meaningfully different capability sets. Hosted on Azure blocks web search, code execution, the MCP connector, structured outputs, and the Files API — returning `400 Bad Request` by design. Hosted on Anthropic delivers full API parity at the cost of Azure data residency. The choice is architectural, not cosmetic.

Most launch coverage treated the two modes as a billing footnote. They're not. One mode hard-blocks nine API capabilities. The other doesn't. If your pipeline relies on web search, programmatic tool calling, or MCP — and you've provisioned Hosted on Azure — you won't get a degraded response. You'll get a `400` and a confusing afternoon.

## The Capability Split: Full Table

The following table is derived directly from [Anthropic's Foundry documentation](https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry) (retrieved 2026-06-30). Anthropic is explicit: *"The following features are available for deployments hosted on Anthropic but are not supported for deployments hosted on Azure: Structured outputs, Server-side tools (web search, web fetch, code execution, and tool search), MCP connector, Agent Skills, Programmatic tool calling, Files API."*

| Capability | Hosted on Azure | Hosted on Anthropic |
|---|---|---|
| Web search (`web_search_20260318`) | ❌ 400 error | ✅ |
| Web fetch | ❌ 400 error | ✅ |
| Code execution | ❌ 400 error | ✅ |
| Tool search | ❌ 400 error | ✅ |
| Structured outputs | ❌ 400 error | ✅ |
| MCP connector | ❌ 400 error | ✅ |
| Agent Skills | ❌ 400 error | ✅ |
| Programmatic tool calling | ❌ 400 error | ✅ |
| Files API | ❌ 400 error | ✅ |
| US Data Zone (inference stays in US) | ✅ Opus 4.8 only | ❌ |
| Azure Entra ID / RBAC auth | ✅ | ✅ |
| Azure MACC billing offset | ✅ | ✅ |
| Extended thinking | ✅ | ✅ |
| Prompt caching | ✅ | ✅ |
| Client-provided tool use | ✅ | ✅ |
| Vision / 1M-token context | ✅ | ✅ |

The model roster is also constrained. At GA, **only Opus 4.8 and Haiku 4.5** run on Hosted on Azure infrastructure. Claude Fable 5, all Sonnet variants, and every other Opus version require Hosted on Anthropic. This is documented in Anthropic's [model overview](https://platform.claude.com/docs/en/docs/about-claude/models/overview) (retrieved 2026-06-30), not in the launch blog.

## What "Hosted on Azure" Actually Means

The distinction isn't where the model "lives" — Anthropic operates inference in both modes. The difference is **where inference hardware runs**.

- **Hosted on Azure:** Anthropic's inference service runs on NVIDIA GB300 NVL72 Blackwell Ultra GPUs provisioned on Azure. Prompts and completions stay within Azure; only usage metadata and safety-flagged content egress to Anthropic. [NVIDIA confirmed the hardware configuration](https://blogs.nvidia.com/blog/anthropic-nvidia-gb300-blackwell-ultra-microsoft-azure/) at the GA announcement (retrieved 2026-06-30).
- **Hosted on Anthropic:** Standard Anthropic inference on Anthropic's own infrastructure, accessed through the Foundry endpoint with Azure billing and IAM.

Both modes share the same API surface (`https://{resource}.services.ai.azure.com/anthropic/v1/messages`) and billing pathway (Azure Marketplace, Claude Consumption Units, monthly invoice). The capability gap exists because server-side tools — web search, code execution — run in Anthropic's own sandboxed environment and cannot be replicated on Azure-hosted infrastructure at GA.

One operational catch: Foundry omits Anthropic's standard `anthropic-ratelimit-*` response headers entirely. Teams using SDK-level retry logic that reads those headers must switch to [Azure Monitor](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude) for quota tracking (retrieved 2026-06-30).

## When Hosted on Azure Is the Right Call

For regulated enterprise environments, Hosted on Azure offers four concrete procurement levers unavailable through Hosted on Anthropic:

**EA billing offset (MACC).** Eligible customers with Microsoft Enterprise Agreements can apply existing Azure commitments to offset Claude Foundry spend. If your organization carries $5M in MACC credits, Claude usage draws against that balance — no separate Anthropic invoice.

**Entra ID native authentication.** RBAC-gated access via existing Entra ID groups. Deprovisioning follows existing IAM workflows. No separate API key rotation infrastructure.

**US Data Zone inference residency.** The US Data Zone Standard deployment type (Opus 4.8 only) keeps inference within the United States — the only current Foundry option for hard US data residency requirements. Note: an EU data residency equivalent is not documented at GA; teams with EU residency requirements should treat global routing as the current Foundry default.

**Single-vendor governance posture.** For teams under Azure-primary vendor policies, Hosted on Azure consolidates Claude into Azure Policy, Defender for Cloud, and unified audit logs via Azure Monitor.

A provisioning note: the [Anthropic GA blog](https://claude.com/blog/claude-in-microsoft-foundry) lists launch regions as East US and West Europe. But [Microsoft Learn](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/how-to/use-foundry-models-claude) specifies Foundry resources must be created in **East US2** (not East US) for Global Standard deployments. Expansion to Southeast Asia, Australia East, and UK South is projected for mid-July 2026.

## When Hosted on Anthropic Is the Right Call

Any pipeline touching server-side tools must use Hosted on Anthropic:

- **Web-grounded agents:** Research or fact-checking pipelines using `web_search_20260318` with the new `response_inclusion` parameter.
- **Code execution:** Sandboxed Python/JS evaluation, data analysis workflows.
- **MCP-connected agents:** Any pipeline routing through MCP servers. MCP is blocked on Hosted on Azure — teams migrating MCP-based pipelines must account for this.
- **Claude Agent SDK workflows:** Programmatic tool calling and Agent Skills — both required for full Agent SDK capability — are absent in Azure mode.
- **Files API:** Persistent file references for document-processing pipelines.
- **Full model roster:** Fable 5 and all Sonnet variants.

One silent failure pattern worth flagging: as of Claude Code v2.1.196, the CLI detects Hosted on Azure deployments and strips unsupported features silently. Migrating an existing Agent SDK pipeline to Foundry won't produce an error at the CLI level — it will produce a silently degraded agent.

For context, **web search IS available on Google Cloud Vertex AI** for Claude deployments — [confirmed in Anthropic's Vertex docs](https://platform.claude.com/docs/en/api/claude-on-vertex-ai) (retrieved 2026-06-30). Teams evaluating Azure Foundry as a Vertex substitute for search-enabled agents will find a larger capability gap in Hosted on Azure than they'd expect from the launch coverage.

## SDK Example: Selecting Hosted on Anthropic Through Foundry

```python
import anthropic

# Hosted on Anthropic through Foundry — full feature set including web search
client = anthropic.AnthropicFoundry(
    base_url="https://{resource}.services.ai.azure.com",
    api_key="{your-key}",
    deployment="claude-opus-4-8-hosted-on-anthropic",  # note deployment name
)

response = client.messages.create(
    model="claude-opus-4-8-20261012",
    max_tokens=1024,
    tools=[{"type": "web_search_20260318", "name": "web_search"}],
    messages=[{"role": "user", "content": "What are the Azure Foundry launch regions for Claude?"}],
)
# Returns results with web search grounding.
# Switching deployment= to a Hosted-on-Azure deployment name
# returns: 400 Bad Request — tool type not supported in this mode.
```

## Routing Table: Choosing a Mode

| Team type | Low compliance need | High compliance need |
|---|---|---|
| **Agentic / tool-heavy workflows** | Hosted on Anthropic | Hosted on Anthropic (accept Anthropic data terms) |
| **Chat / summarization / structured RAG only** | Either; Hosted on Azure for unified billing | Hosted on Azure (data residency + MACC) |

Practical rule: **if your pipeline calls any server-side tool, Hosted on Azure is the wrong mode**. The compliance benefits of Azure data residency don't apply, because the server-side tools that you need run on Anthropic infrastructure regardless. Hosted on Anthropic through Foundry still gives you Azure billing and RBAC — you just give up data residency and MACC offsets.

Do not make purchase decisions based on cost figures in this post. Foundry billing is denominated in Claude Consumption Units (CCUs) and rates change. Check the [Azure Foundry pricing page](https://azure.microsoft.com/en-us/pricing/details/azure-ai-foundry/) directly before scoping workloads.

Anthropic has stated a goal of feature parity between modes. No timeline has been given. The gap is intentional during the GA ramp, not an oversight, per the [official Foundry docs](https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry) (retrieved 2026-06-30).

---

**Knowledge Check:** An enterprise team has existing Azure MACC credits and a hard US data residency requirement. They also need to build a Claude-powered research agent that runs web searches. Which Foundry hosting mode should they choose, and what constraint forces that decision?

*Answer: They must use **Hosted on Anthropic** — web search is blocked on Hosted on Azure and returns a 400 error. They give up MACC billing offset and US data residency as a result. The compliance benefits of Azure mode are incompatible with web-search-dependent pipelines at GA.*

---

If you want to build agent pipelines that work across deployment targets — including Foundry Hosted on Anthropic, direct API, and Bedrock — the [[course/claude-agent-sdk-zero-to-production]] course covers SDK initialization, tool registration, endpoint configuration, and deployment-target switching in depth.
