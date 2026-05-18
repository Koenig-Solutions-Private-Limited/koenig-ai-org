---
title: Choose Claude Skills for workflows and MCP for live systems
date: 2026-05-13
author: blog-author
ticket: KOEA-1254
slug: claude-skills-vs-mcp
vendor: anthropic
vendor_tag: anthropic
content_type: article
status: draft-for-review
tags:
  - anthropic
  - claude-code
  - mcp
  - agent-skills
  - developer-tools
reading_time_min: 12
primary_query: "claude skills vs mcp when to use which"
contrarian_angle: "Skills and MCP are not competing extension mechanisms. Skills encode repeatable judgment; MCP exposes live systems. The highest-leverage architecture is usually hybrid."
sources:
  - https://www.anthropic.com/news/skills
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
  - https://www.anthropic.com/news/model-context-protocol
  - https://modelcontextprotocol.io/docs
  - https://modelcontextprotocol.io/quickstart
  - https://www.anthropic.com/engineering/code-execution-with-mcp
  - https://github.com/anthropics/skills
  - https://agentskills.io
whats_new:
  - "Use Skills to encode repeatable workflow judgment, use MCP to reach live systems, and combine them when the workflow repeats but the data changes."
learning_objectives:
  - "Decide whether a task belongs in a Claude Skill, an MCP server, or a hybrid design."
  - "Explain why progressive disclosure makes Skills cheaper for procedural knowledge while MCP remains the right boundary for live integrations."
references:
  - n: 1
    title: Introducing Agent Skills
    url: https://www.anthropic.com/news/skills
    retrieved: 2026-05-13
  - n: 2
    title: Agent Skills overview
    url: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
    retrieved: 2026-05-13
  - n: 3
    title: Equipping agents for the real world with Agent Skills
    url: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
    retrieved: 2026-05-13
  - n: 4
    title: Introducing the Model Context Protocol
    url: https://www.anthropic.com/news/model-context-protocol
    retrieved: 2026-05-13
  - n: 5
    title: What is the Model Context Protocol?
    url: https://modelcontextprotocol.io/docs
    retrieved: 2026-05-13
  - n: 6
    title: Build an MCP server
    url: https://modelcontextprotocol.io/quickstart
    retrieved: 2026-05-13
  - n: 7
    title: Code execution with MCP: building more efficient AI agents
    url: https://www.anthropic.com/engineering/code-execution-with-mcp
    retrieved: 2026-05-13
  - n: 8
    title: anthropics/skills GitHub repository
    url: https://github.com/anthropics/skills
    retrieved: 2026-05-13
  - n: 9
    title: Agent Skills overview
    url: https://agentskills.io
    retrieved: 2026-05-13
---

# Choose Claude Skills for workflows and MCP for live systems

If you are deciding between Claude Skills and MCP, the short answer is simple: use Skills when you need Claude to follow a repeatable way of working, and use MCP when Claude needs access to a live tool, API, database, or application. Skills package instructions, scripts, and references into a reusable folder that loads on demand, while MCP defines a client-server protocol for connecting an assistant to external systems ([Anthropic Skills announcement](https://www.anthropic.com/news/skills), retrieved 2026-05-13; [Anthropic MCP announcement](https://www.anthropic.com/news/model-context-protocol), retrieved 2026-05-13).

Most teams frame this as a product comparison, which is the wrong mental model. Skills and MCP do different jobs. Skills tell the agent how your team wants work done. MCP gives the agent access to things it cannot know from static instructions alone. Once you see that split, the “which one should I choose?” question becomes a boundary-design question: are you encoding judgment, or are you exposing a system?

The research synthesis for this topic also points in the same direction: Claude Skills work best as procedural memory with progressive disclosure, while MCP works best as the integration layer for external data and actions. The useful architecture in 2026 is not Skills versus MCP. It is Skills over MCP when the workflow repeats but the inputs keep changing.

## Use Skills when the agent needs judgment, conventions, and reusable workflow memory

Claude Skills are filesystem-based folders centered on a `SKILL.md` file. Anthropic describes them as specialized folders containing instructions, scripts, and resources that Claude can load dynamically for specific tasks ([Introducing Agent Skills](https://www.anthropic.com/news/skills), retrieved 2026-05-13). The API docs make the same point in more operational terms: Skills are reusable, filesystem-based resources that provide domain-specific expertise, workflows, and best practices, and they load through progressive disclosure instead of taking over the whole context window up front ([Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview), retrieved 2026-05-13).

That architecture matters because it changes what a Skill is good at. A Skill is not another connector. It is a compact way to teach the model your preferred process.

Anthropic’s docs break progressive disclosure into stages. Claude first reads only metadata such as `name` and `description`, then loads the full `SKILL.md` only when relevant, and only later executes scripts or opens extra resources if the task requires them ([Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview), retrieved 2026-05-13). The engineering write-up describes the same pattern as discovery, loading, and deep-dive access to bundled resources ([Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills), retrieved 2026-05-13).

That makes Skills the right choice when:

- the workflow is stable and repeated often
- the agent mostly needs judgment, templates, and sequencing rather than live data
- you want repo-local or team-local conventions to be reusable
- you need scripts and references that support the workflow without shipping everything into prompt context

Claude Code is the clearest example. The docs explicitly distinguish Claude Code from the API and claude.ai: Claude Code supports custom Skills that live locally or at the project level in `.claude/skills/`, which is exactly the right shape for things like PR review rules, release checklists, editorial workflows, migration playbooks, or security triage conventions ([Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview), retrieved 2026-05-13).

If your problem statement sounds like “we want Claude to always handle this class of work the way our team does,” start with a Skill.

> [!run-prompt-cell] Run this: create a minimal Claude Code skill for repo-specific PR reviews
> ```bash
> mkdir -p .claude/skills/pr-review
> cat > .claude/skills/pr-review/SKILL.md <<'EOF'
> ---
> name: pr-review
> description: Review pull requests for security regressions, missing tests, and rollout risk. Use when the user asks for code review or pre-merge feedback.
> ---
>
> # PR Review
> 
> ## Instructions
> - Read the diff before commenting.
> - Flag security, data-loss, and auth issues first.
> - Prefer minimal, concrete fixes.
> - End with PASS, CHANGES, or BLOCK.
> 
> ## Examples
> - “Review this auth middleware diff.”
> EOF
> ```
>
> Expected output:
> ```text
> A new skill folder exists at .claude/skills/pr-review/SKILL.md
> ```

That example is intentionally boring. Boring is the point. Skills shine when you are encoding repeatable process, not when you are building another network boundary.

## Use MCP when the agent must read from or act on live systems

MCP solves a different problem. Anthropic introduced the Model Context Protocol as an open standard for connecting AI assistants to the systems where data lives ([Introducing the Model Context Protocol](https://www.anthropic.com/news/model-context-protocol), retrieved 2026-05-13). The official MCP docs describe it as a protocol for clients, servers, and apps, and the quickstart shows the typical shape: you build a server, expose tools, and wire that server into a client such as Claude for Desktop via config ([What is MCP?](https://modelcontextprotocol.io/docs), retrieved 2026-05-13; [Build an MCP server](https://modelcontextprotocol.io/quickstart), retrieved 2026-05-13).

That means MCP is the right choice when the assistant needs facts or actions that cannot be frozen into a markdown folder:

- reading live documents from Drive or Notion
- querying a database or ticket system
- calling an internal service with current state
- creating, updating, or deleting records in another system
- exposing organization-specific tools to more than one agent surface

This is why “Skills vs MCP” is such a misleading query. A Skill can teach Claude how your team triages incidents. It cannot, by itself, fetch the current incident roster from PagerDuty. MCP can expose PagerDuty data and actions. It cannot, by itself, teach Claude which escalation path your org expects or what “good” triage notes look like.

The quickstart also reveals the practical cost of MCP: you now own an integration surface. Even the simplest server involves runtime, transport, logging discipline, configuration, and tool schemas ([Build an MCP server](https://modelcontextprotocol.io/quickstart), retrieved 2026-05-13). That overhead is worth it when the assistant must operate on live systems. It is wasted motion when you only need reusable instructions.

A good rule is this: if the capability requires a fresh network round trip or a live application boundary, it is probably MCP.

## Combine Skills and MCP when the workflow repeats but the data changes

The highest-leverage design is usually hybrid because real production work contains both stable procedure and changing state.

Anthropic’s own engineering post on code execution with MCP makes this explicit. The point of MCP is not merely tool calling; it is giving agents access to external systems in a more scalable way. The post argues that direct tool calls do not scale cleanly because tool definitions and intermediate results both consume context, and it gives a concrete example of reducing a task from 150,000 tokens to 2,000 tokens by letting the agent explore and call tools in code instead of pushing every detail through the model context ([Code execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp), retrieved 2026-05-13).

That official article also says something more interesting: agents can save successful logic as reusable “Skills” while MCP supplies tool access ([Code execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp), retrieved 2026-05-13). In other words, Anthropic’s own materials already imply the architecture most developers eventually land on.

The decision matrix below is the practical version.

| Scenario | Better default | Why |
| --- | --- | --- |
| Repo-specific review checklist, release playbook, writing style guide | Skill | Stable procedure, low integration overhead |
| Querying GitHub issues, CRM records, or production metrics | MCP | Needs live state and authenticated actions |
| Running a recurring workflow against live systems, such as support triage or security review | Hybrid | Skill encodes process; MCP supplies current data and tools |
| Sharing a durable protocol-based integration across multiple agent clients | MCP | Portability matters more than repo-local workflow memory |
| Teaching Claude how your org wants outputs formatted after data retrieval | Skill + MCP | MCP fetches data, Skill shapes behavior |

Three concrete decision scenarios make the split even clearer.

1. Pure Skills: Your team wants Claude Code to review every migration diff for rollback risk, missing backfills, and unsafe locks. No live system calls are required. A project Skill is enough.

2. Pure MCP: You want Claude to open a support ticket, look up the customer’s current subscription, and post the result back into Slack. That requires authenticated access to live systems. Build or adopt MCP servers.

3. Hybrid: You want a support-quality workflow that always checks entitlement, summarizes prior incidents, follows your escalation policy, and drafts a response in your house style. MCP fetches the customer record and ticket history. A Skill tells Claude exactly how to reason through the case and format the answer.

That third case is where most teams end up. It is also the fastest way to stop overbuilding MCP servers for things that should just be instructions.

## Avoid three mistakes that make the choice look harder than it is

The first mistake is using MCP as a glorified knowledge base. If the information is static enough to live in markdown, templates, scripts, or reference files, a Skill is usually cheaper, simpler, and easier to audit than a server.

The second mistake is using Skills as if they were connectors. Anthropic’s documentation is clear that Skills can include scripts and resources, but that does not turn them into a universal replacement for authenticated live integrations ([Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview), retrieved 2026-05-13). The moment the workflow depends on current external state, Skills alone become fragile.

The third mistake is treating “local” as “small” and “protocol” as “advanced.” That framing pushes teams into MCP too early. The more accurate split is operational: Skills are lighter because they package how to work, while MCP is heavier because it packages access to something outside the model’s sandbox.

Anthropic’s public `anthropics/skills` repository reinforces that point. The repository is full of example and production-oriented Skills for document handling and specialized workflows, which is exactly what you would expect from a system meant to encode reusable expertise rather than live system access ([anthropics/skills repository](https://github.com/anthropics/skills), retrieved 2026-05-13). The open Agent Skills standard at agentskills.io pushes the same story: a Skill is a folder with `SKILL.md`, optional scripts, references, and assets, built for specialized knowledge and repeatable workflows ([Agent Skills overview](https://agentskills.io), retrieved 2026-05-13).

That is also the right moment to think about packaging. If you find yourself stretching a repo-local Skill into something that really wants to be shared as a reusable integration surface, that is when you graduate from local Skill logic toward an MCP server or a more formal packaged extension. In Paperclip environments, that is also the point where a packaging helper like [[paperclip-create-plugin]] becomes relevant.

> [!run-prompt-cell] Run this: wire a minimal MCP server into Claude Desktop
> ```json
> {
>   "mcpServers": {
>     "weather": {
>       "command": "uv",
>       "args": [
>         "--directory",
>         "/ABSOLUTE/PATH/TO/weather",
>         "run",
>         "weather.py"
>       ]
>     }
>   }
> }
> ```
>
> Expected output:
> ```text
> Claude Desktop can discover a server named "weather" and expose its tools after restart.
> ```

That config snippet is from the official MCP quickstart. It is a useful reminder that MCP brings real setup with it: executable path, runtime, server process, and client configuration ([Build an MCP server](https://modelcontextprotocol.io/quickstart), retrieved 2026-05-13). If your use case does not need that machinery, do not volunteer to own it.

## Choose the boundary first, then choose the mechanism

The cleanest way to decide is to ask two questions in order.

First: is the missing capability procedural or connective?

If the missing capability is procedural, the agent needs a better way of working. That points to a Skill.

If the missing capability is connective, the agent needs access to something outside itself. That points to MCP.

Second: will the workflow repeat while the underlying data changes?

If yes, you almost certainly want both. Put the repeatable reasoning, formatting rules, edge cases, and escalation heuristics in a Skill. Put the live reads and writes in MCP. That gives you the cheapest possible context footprint for instructions and the strongest possible boundary for external systems.

This is also why the contrarian answer matters for developers choosing in 2026. The real risk is not choosing the “wrong product.” It is collapsing two different concerns into one mechanism. Teams that shove process into MCP overbuild infrastructure. Teams that shove live integration into Skills create brittle pseudo-connectors. The durable architecture separates memory from access.

## KnowledgeCheck

Question: Your team wants Claude to fetch the latest Jira ticket, read the customer’s current plan from an internal billing API, then write the reply in your company’s support style with your escalation policy. Which design fits best?

A. Skill only  
B. MCP only  
C. Hybrid: Skill for workflow and MCP for live systems  
D. Neither

Answer: C. The live systems belong behind MCP, while the repeatable support workflow, escalation logic, and writing conventions belong in a Skill.

If that is the architecture you are trying to build, the next useful step is [[mcp-from-first-principles-to-production]]. The course-level skill is not memorizing protocol jargon. It is learning where to draw the boundary between workflow memory and live integration so your agent stack stays cheap, auditable, and adaptable.

## References

1. [Anthropic, “Introducing Agent Skills”](https://www.anthropic.com/news/skills) — retrieved 2026-05-13
2. [Claude API docs, “Agent Skills overview”](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) — retrieved 2026-05-13
3. [Anthropic Engineering, “Equipping agents for the real world with Agent Skills”](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — retrieved 2026-05-13
4. [Anthropic, “Introducing the Model Context Protocol”](https://www.anthropic.com/news/model-context-protocol) — retrieved 2026-05-13
5. [Model Context Protocol docs, “What is MCP?”](https://modelcontextprotocol.io/docs) — retrieved 2026-05-13
6. [Model Context Protocol quickstart, “Build an MCP server”](https://modelcontextprotocol.io/quickstart) — retrieved 2026-05-13
7. [Anthropic Engineering, “Code execution with MCP: building more efficient AI agents”](https://www.anthropic.com/engineering/code-execution-with-mcp) — retrieved 2026-05-13
8. [GitHub, `anthropics/skills`](https://github.com/anthropics/skills) — retrieved 2026-05-13
9. [AgentSkills.io overview](https://agentskills.io) — retrieved 2026-05-13
