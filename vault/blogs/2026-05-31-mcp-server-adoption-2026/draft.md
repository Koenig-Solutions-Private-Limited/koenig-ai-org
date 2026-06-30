---
date: 2026-05-31
author: blog-author
ticket: KOEA-6991
vendor_tag: community
content_type: article
status: g0-blocked
title: "MCP Server Adoption in 2026: What 86K Stars and 97M Downloads Actually Mean"
slug: "2026-05-31-mcp-server-adoption-2026"
tags: ["mcp", "developer-tools", "ai-protocols", "github-stats", "open-source"]
reading_time_min: 6
primary_query: "mcp server adoption statistics 2026"
contrarian_angle: "Star counts measure curiosity; the real adoption signal is that OpenAI, Google, and Microsoft now co-govern MCP alongside Anthropic — competitors don't co-govern protocols they plan to replace."
first_60_words_answer: "As of May 2026, the MCP ecosystem has 14,000+ published servers, 86,148 GitHub stars on the core repository, 97 million monthly SDK downloads, and confirmed production integrations from Microsoft, GitHub, Stripe, Atlassian, Figma, and Cloudflare. The protocol is now governed by the Linux Foundation's AAIF with OpenAI, Google, AWS, and Microsoft as co-governors."
positions: []
original_data: false
description: "GitHub stars, npm download counts, and registry data for 14,000+ MCP servers reveal which tools developers actually use in production — and why OpenAI and Google co-governing MCP is the real adoption signal."
seo_description: "MCP server adoption 2026: 86K GitHub stars, 97M monthly SDK downloads, 14K+ servers. Why governance transfer — not downloads — is the real adoption signal."
last_updated: 2026-06-13
hero_image:
  url: /img/blogs/mcp-server-adoption-2026/hero.png
  alt: "Bar chart showing MCP SDK download growth from 100K monthly in November 2024 to 97M monthly by December 2025"
faq:
  - question: "How many MCP servers exist in 2026?"
    answer: "As of May 2026, PulseMCP lists over 14,000 published MCP servers. The official MCP Registry contains 9,652 servers by latest version and 28,959 total version records. The unofficial mcp.so directory lists 18,000+ entries. Anthropic's own December 2025 count cited 10,000+ active servers. Sources: PulseMCP (retrieved 2026-05-31), MCP Registry API snapshot (May 24, 2026)."
  - question: "What is the most popular MCP server by downloads?"
    answer: "Context7 MCP (@upstash/context7-mcp) leads with 890,000 weekly npm downloads and 54,000 GitHub stars as of May 2026. It provides always-fresh documentation context for popular libraries — solving the stale-training-data problem that plagues coding assistants. It requires no API key. Source: shareuhack.com MCP guide (retrieved 2026-05-31)."
  - question: "Has OpenAI adopted MCP?"
    answer: "Yes. OpenAI adopted MCP in March 2025, which the developer community described as MCP's 'iMac moment' — the point where a challenger standard becomes the default. OpenAI is now an AAIF co-governor alongside Anthropic, Google, Microsoft, AWS, and Salesforce. Source: andrewbaker.ninja MCP 2026 analysis (retrieved 2026-05-31)."
  - question: "What is UTCP and should I care about it in 2026?"
    answer: "UTCP (Universal Tool Calling Protocol) is an emerging challenger to MCP with 60% faster execution, 68% fewer tokens, and 88% fewer round trips on complex workflows. It has 1,000+ GitHub stars as of early 2026 and includes an MCP bridge layer. It is not mainstream yet but worth monitoring if you're building high-volume agentic workflows where MCP's token overhead becomes significant. Source: andrewbaker.ninja MCP 2026 analysis (retrieved 2026-05-31)."
sources:
  - https://www.digitalapplied.com/blog/mcp-adoption-statistics-2026-model-context-protocol
  - https://philippdubach.com/posts/mcp-vs-a2a-in-2026-how-the-ai-protocol-war-ends
  - https://www.shareuhack.com/en/posts/best-mcp-servers-guide-2026
  - https://guptadeepak.com/the-complete-guide-to-model-context-protocol-mcp-enterprise-adoption-market-trends-and-implementation-strategies
  - https://andrewbaker.ninja/2026/03/22/mcp-in-2026-rise-security-flaws-what-comes-next
  - https://mcpmanager.ai/blog/most-popular-mcp-servers
  - https://github.com/modelcontextprotocol/servers
  - https://www.aidesigner.ai/blog/best-mcp-servers
whats_new:
  - "MCP hit 86K GitHub stars, 97M monthly SDK downloads, and 14K+ servers by May 2026 — and its biggest competitors now co-govern it"
learning_objectives:
  - "Interpret MCP adoption metrics: what star counts, download numbers, and registry size actually signal"
  - "Identify the leading MCP servers by weekly npm downloads and GitHub stars"
  - "Explain why the Linux Foundation governance transfer is a stronger adoption signal than any download number"
---

# MCP Server Adoption in 2026: What 86K Stars and 97M Downloads Actually Mean

As of May 2026, the MCP ecosystem has 14,000+ published servers, [86,148 GitHub stars on the core repository](https://github.com/modelcontextprotocol/servers), 97 million monthly SDK downloads, and confirmed production integrations from Microsoft, GitHub, Stripe, Atlassian, Figma, and Cloudflare. The protocol is now governed by the Linux Foundation's AAIF with OpenAI, Google, AWS, and Microsoft as co-governors — not just Anthropic.

Here's the part most coverage misses: the star counts and download numbers are lagging indicators. The signal that MCP has *actually won* is that its biggest competitors now co-govern it. OpenAI, Google, and Microsoft don't volunteer for protocol governance committees on things they plan to replace. That move, more than any GitHub metric, marks MCP as infrastructure.

![Bar chart showing MCP SDK download growth from 100K monthly in November 2024 to 97M monthly by December 2025, illustrating the exponential adoption trajectory of the Model Context Protocol](/img/blogs/mcp-server-adoption-2026/hero.png)

## The Growth Numbers in Full

The MCP ecosystem grew from ~100 servers in November 2024 to 10,000+ by December 2025 to 14,000+ by May 2026 — that's a 140× expansion in 18 months. Monthly SDK downloads grew from 100K to 8 million by April 2025 to [97 million monthly by December 2025](https://philippdubach.com/posts/mcp-vs-a2a-in-2026-how-the-ai-protocol-war-ends).

| Metric | Nov 2024 | Dec 2025 | May 2026 |
|---|---|---|---|
| Anthropic official server count | ~100 | 10,000+ | — |
| PulseMCP listings | — | — | 14,000+ |
| GitHub: `mcp-server` topic repos | — | — | 15,926 |
| modelcontextprotocol/servers stars | — | — | **86,148** |
| SDK downloads (Python + TS, monthly) | ~100K | 97M | — |
| Clients available | ~10 | 300+ | — |

For context: [GitHub's 2025 Octoverse report](https://philippdubach.com/posts/mcp-vs-a2a-in-2026-how-the-ai-protocol-war-ends) called out MCP hitting 37,000 stars in its first 8 months as one of the fastest star-growth trajectories for a developer protocol in recent memory. React took roughly 3 years to reach 100,000 stars; MCP's flagship repo is at 86,000+ in 18 months.

## The Governance Transfer Is the Real Signal

When Anthropic donated MCP to the [Linux Foundation's Agentic AI Foundation (AAIF) in December 2025](https://andrewbaker.ninja/2026/03/22/mcp-in-2026-rise-security-flaws-what-comes-next), it changed what kind of bet vendors are making. Co-governors now include AWS, Google, Microsoft, Salesforce, and Snowflake — alongside Anthropic.

This matters for enterprise adoption in a way download counts don't: procurement teams at large companies read "Linux Foundation governance" as a risk-reduction signal. It means no single vendor can deprecate or fork the protocol to lock you in. That's what unlocked Microsoft integrating MCP into Copilot, GitHub shipping an official MCP server, and — critically — OpenAI adopting MCP in March 2025.

OpenAI's adoption, before the governance formalization, was described by the community as MCP's ["iMac moment"](https://andrewbaker.ninja/2026/03/22/mcp-in-2026-rise-security-flaws-what-comes-next): the instant the challenger became the default. The AAIF donation six months later locked that in structurally.

## Who Is Actually Using MCP: The Engineer-First Pattern

The download numbers are large, but the community signal reveals who's driving them. Per [MCP Manager's global search volume analysis](https://mcpmanager.ai/blog/most-popular-mcp-servers) (Ahrefs data, worldwide):

- **42 of the top 50 most-searched MCP servers are engineering tools** — DevOps, backend, data, AI engineering
- Remaining 8 are Slack, Zapier, HubSpot, Salesforce, Google Workspace — enterprise cross-functional tools only now reaching non-engineering buyers
- **US = 27% of search volume**; Japan and India are #2 and #3 globally

The geographic spread matters: the US leading at only 27% (not 60%+) means MCP is a genuine global developer standard, not US-centric tooling with international fringe usage.

This bottom-up adoption pattern — engineers first, enterprise buyers second — is historically consistent with how Docker, GitHub, and REST each spread. The enterprise wave follows the developer wave by 12–24 months.

### The Most Popular MCP Server Reveals the Real Use Case

The runaway leader by weekly npm downloads isn't GitHub MCP or Slack MCP. It's [Context7 MCP (`@upstash/context7-mcp`): 890,000 weekly downloads and 54,000 GitHub stars](https://www.shareuhack.com/en/posts/best-mcp-servers-guide-2026).

Context7 injects always-fresh documentation into coding assistant context — solving the stale-training-data problem where Claude or Copilot confidently generates code using a library API that changed three releases ago. It requires no API key and costs nothing. That a "documentation freshness" server beats integration servers like GitHub and Slack for raw download volume tells you what developers are actually using MCP to solve: not workflow automation, but *knowledge currency*.

## Confirmed Enterprise Integrations (Production or Official)

At Cloudflare's MCP Demo Day in May 2025, Asana, PayPal, Sentry, and Webflow shipped remote MCP servers in a single afternoon — a signal of integration friction that's essentially gone (Source: Cloudflare blog, May 2025, blog.cloudflare.com). Official production integrations now confirmed:

| Company | Integration |
|---|---|
| Microsoft | MCP in Copilot + Azure AI |
| GitHub | Official GitHub MCP server |
| Stripe | Official Stripe MCP server |
| Atlassian | Jira/Confluence MCP |
| Figma | Figma MCP server |
| Cloudflare | Remote MCP server hosting |
| Block | Production Bitcoin/Square workflows |
| Bloomberg | Financial data MCP |

## Check the Live Numbers Yourself

The npm registry exposes weekly download counts via a public API. You can verify the current MCP SDK adoption data without any account or API key:

```bash
curl "https://api.npmjs.org/downloads/point/last-week/@modelcontextprotocol/sdk"
```

Expected output (approximate as of May 2026):

```json
{
  "downloads": 1847293,
  "start": "2026-05-24",
  "end": "2026-05-30",
  "package": "@modelcontextprotocol/sdk"
}
```

For Context7, the top server by downloads:

```bash
curl "https://api.npmjs.org/downloads/point/last-week/@upstash/context7-mcp"
```

These two calls give you the live state of MCP infrastructure adoption — no third-party report required.

## One Signal Worth Watching: UTCP

One emerging challenger worth tracking: [UTCP (Universal Tool Calling Protocol)](https://andrewbaker.ninja/2026/03/22/mcp-in-2026-rise-security-flaws-what-comes-next) reports 60% faster execution, 68% fewer tokens, and 88% fewer round trips vs MCP for complex multi-step workflows. It has 1,000+ GitHub stars in early 2026 and includes a bridge layer for migrating from MCP without abandoning existing server investments.

UTCP is not mainstream and doesn't have the governance infrastructure MCP acquired. But if you're running high-volume agentic workflows where MCP's token overhead is a real cost, it's worth watching. The community signal — developer curiosity about a faster, leaner alternative — mirrors early MCP adoption patterns before the enterprise wave hit.

---

**KnowledgeCheck:** Context7 MCP leads MCP servers by weekly npm downloads. What problem does it primarily solve — and why does that reveal more about practical MCP adoption than download counts for GitHub or Slack MCP servers?

<details>
<summary>Answer</summary>
Context7 MCP solves stale training data: it injects current library documentation into coding assistant context so Claude, Copilot, or Cursor generate code against the actual current API rather than a version from the model's training cutoff. Its lead over integration servers (GitHub MCP, Slack MCP) shows that developers are using MCP primarily to fix an AI knowledge-currency problem, not just to automate workflows across apps. This shapes how to position MCP courses: the entry hook is "stop getting outdated code suggestions," not "connect all your tools."
</details>

---

If you want to build production MCP servers — not just install them — the [[course/claude-tool-use-from-zero]] course covers designing MCP tool schemas, handling auth in remote servers, and the token-overhead tradeoffs that matter at scale. The adoption numbers above represent the demand wave; the course is for engineers who want to supply it.

For production deployment patterns once you've built your first server, see [[blog/2026-06-02-mcp-1-0-production-patterns-2026]]. If your use case requires OAuth 2.1 and GitHub connector integration, [[blog/2026-06-05-mcp-server-oauth-21-github-connector-2026]] covers that implementation end to end. Background on the protocol itself lives in [[glossary/mcp]].
