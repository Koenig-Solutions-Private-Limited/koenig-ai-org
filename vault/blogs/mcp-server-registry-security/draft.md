---
date: 2026-05-13
author: vardaan-koenig
agent_drafted_by: blog-author
ticket: KOEA-1339
vendor_tag: anthropic
content_type: article
status: awaiting-g0
title: "Treat the MCP server registry like npm in 2016, not an app store"
slug: 2026-05-13-mcp-server-registry-security
description: "The MCP server registry is not safe by default because one-click bundles, community directories, and remote authorization flows still move faster than signing, provenance, and review standards."
tags:
  - mcp
  - security
  - supply-chain
  - anthropic
  - registry
reading_time_min: 15
primary_query: "is the mcp server registry safe"
contrarian_angle: "The main MCP registry failure is not prompt injection alone. It is packaging trust: install flows became one-click before provenance, signing, and review became legible."
sources:
  - https://www.anthropic.com/engineering/desktop-extensions
  - https://modelcontextprotocol.io/specification/2025-03-26
  - https://modelcontextprotocol.io/specification/2025-03-26/basic/authorization
  - https://github.com/modelcontextprotocol/specification
  - https://github.com/anthropics/claude-ai-mcp
  - https://github.com/anthropics/claude-ai-mcp/issues
  - https://github.com/anthropics/claude-ai-mcp/issues/217
  - https://github.com/anthropics/claude-ai-mcp/issues/250
  - https://www.anthropic.com/engineering/claude-code-sandboxing
  - https://claude.com/blog/claude-security-public-beta
  - https://www.anthropic.com/news/anthropic-amazon-compute
  - https://github.com/anthropics/claude-plugins-community
  - https://github.com/cnych/claude-mcp
hero_image: auto:flux
references:
  - n: 1
    title: "Claude Desktop Extensions: One-click MCP server installation - Anthropic"
    url: https://www.anthropic.com/engineering/desktop-extensions
    retrieved: 2026-05-12
  - n: 2
    title: "Model Context Protocol Specification 2025-03-26 - modelcontextprotocol.io"
    url: https://modelcontextprotocol.io/specification/2025-03-26
    retrieved: 2026-05-13
  - n: 3
    title: "Authorization - MCP Specification 2025-03-26 - modelcontextprotocol.io"
    url: https://modelcontextprotocol.io/specification/2025-03-26/basic/authorization
    retrieved: 2026-05-13
  - n: 4
    title: "Model Context Protocol specification repository - GitHub"
    url: https://github.com/modelcontextprotocol/specification
    retrieved: 2026-05-13
  - n: 5
    title: "anthropics/claude-ai-mcp - GitHub"
    url: https://github.com/anthropics/claude-ai-mcp
    retrieved: 2026-05-12
  - n: 6
    title: "anthropics/claude-ai-mcp issues - GitHub"
    url: https://github.com/anthropics/claude-ai-mcp/issues
    retrieved: 2026-05-13
  - n: 7
    title: "Issue #217: claude.ai skips OAuth discovery after 401 - GitHub"
    url: https://github.com/anthropics/claude-ai-mcp/issues/217
    retrieved: 2026-05-13
  - n: 8
    title: "Issue #250: OAuth callback rejects HTTP 307 redirects - GitHub"
    url: https://github.com/anthropics/claude-ai-mcp/issues/250
    retrieved: 2026-05-13
  - n: 9
    title: "Making Claude Code more secure and autonomous with sandboxing - Anthropic"
    url: https://www.anthropic.com/engineering/claude-code-sandboxing
    retrieved: 2026-05-12
  - n: 10
    title: "Claude Security is now in public beta - Claude"
    url: https://claude.com/blog/claude-security-public-beta
    retrieved: 2026-05-12
  - n: 11
    title: "Anthropic and Amazon expand collaboration for up to 5 gigawatts of compute - Anthropic"
    url: https://www.anthropic.com/news/anthropic-amazon-compute
    retrieved: 2026-05-12
  - n: 12
    title: "anthropics/claude-plugins-community - GitHub"
    url: https://github.com/anthropics/claude-plugins-community
    retrieved: 2026-05-13
  - n: 13
    title: "cnych/claude-mcp community MCP server list"
    url: https://github.com/cnych/claude-mcp
    retrieved: 2026-05-12
whats_new:
  - "MCP registry risk comes from packaging trust, not just model behavior: one-click installs now move faster than provenance, signing, and review."
learning_objectives:
  - "Differentiate the three MCP distribution channels and explain why each creates a different trust boundary."
  - "Audit an MCP bundle or server before install using manifest inspection, version pinning, and sandbox isolation."
  - "Explain why Claude Security is a reviewer, not a registry trust badge, and apply that distinction when evaluating third-party MCP servers."
faq:
  - question: "Is the MCP server registry safe by default?"
    answer: "No. The MCP server registry is fragmented across one-click Desktop Extension bundles, community directories, GitHub-hosted integration surfaces, and ordinary package registries, and those install surfaces do not share one uniform signing, provenance, or review standard."
  - question: "What is the biggest MCP registry risk right now?"
    answer: "The biggest risk is packaging trust. Teams focus on prompt injection, but the more basic failure is that users can install bundled local code or remote connectors before they can independently verify who built the artifact, what it contains, and whether anyone reviewed it."
  - question: "Does Claude Security make third-party MCP servers safe to install?"
    answer: "No. Claude Security can help review server code for vulnerabilities, but Anthropic does not describe it as a registry admission control system, a bundle signing service, or a provenance guarantee for every third-party MCP server artifact."
---

# Treat the MCP server registry like npm in 2016, not an app store

The MCP server registry is a fragmented set of distribution channels, community-maintained GitHub lists, one-click bundles, GitHub-hosted integrations, and package registries, that move untrusted code and untrusted tool output into Claude workflows without a uniform signing or provenance standard. If you are asking whether it is safe by default, the short answer is no: the install experience is now smoother than the trust model behind it, especially for Desktop Extensions and community-listed servers.[1][2][5][13]

1. Claude Desktop Extensions package a server, its dependencies, and a manifest into an `.mcpb` bundle that a user can install with a drag-and-drop flow, which means the distance between curiosity and local code execution is now very short.[1]
2. The current protocol docs tell implementors to treat tools as arbitrary code execution and untrusted surfaces, and the authorization spec exists, but that still leaves users navigating inconsistent real-world auth behavior and uneven host implementations.[2][3][7][8]
3. The public MCP ecosystem is not one store. It spans Anthropic product surfaces, community-maintained GitHub lists such as `cnych/claude-mcp`, GitHub issue trackers, and ordinary npm or PyPI packaging conventions.[5][6][13]
4. Anthropic has shipped useful compensating controls, including Claude Code sandboxing and Claude Security, but neither control is the same thing as registry-wide provenance, artifact signing, or reproducible verification.[9][10]

Most people frame MCP security as a prompt injection story. That is only half right. The larger failure is packaging trust. Once a server looks legitimate, with stars, a clean README, and a one-click installer, the important boundary has already been crossed. The injection may come later. This is the MCP-specific slice of our earlier [[vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026|AI Coding Agent Supply Chain Threat Atlas]]: the same supply chain logic, compressed into a faster install loop and wrapped in agent tooling.

## Understand the MCP registry as three install channels, not one marketplace

The first mistake is talking about "the" MCP registry as if it were a single reviewed store. It is not. The current landscape is at least three channels with different trust assumptions.

First, Claude Desktop now supports one-click MCP bundles. Anthropic's Desktop Extensions post explains that an `.mcpb` file is a packaged archive containing the server, its dependencies, and a `manifest.json`; the point is to remove manual JSON editing and dependency setup from the install flow.[1] That is good for adoption. It also means users can move from curiosity to local code execution in a single click.

Second, the community-list layer sits outside Anthropic's official product boundary. A public GitHub list such as `cnych/claude-mcp` can help discovery, but it is still repository evidence rather than a registry admission system, bundle signer, or independent provenance service.[13] Even if a list is useful, a list is not a signing service.

Third, there is the GitHub-hosted MCP integration surface. The `anthropics/claude-ai-mcp` repository describes itself as the communication hub for MCP integration in Claude and directs users to the issue tracker for bugs and feature requests.[5] That issue list matters because remote-server trust is not just about malicious code. It is also about brittle transport, inconsistent auth handling, and users approving flows they do not fully understand.[6][7][8]

That fragmentation is the core security fact. You are not installing from one audited pipe. You are hopping between package ecosystems, community mirrors, bundled local processes, and remote auth flows. [[vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026|The Atlas]] matters here because it gives the broader frame: MCP registry risk is not a weird corner case. It is a supply chain problem expressed through agent tooling.

## Rank the ten risks before you install anything

The attached synthesis for KOEA-1339 mapped ten registry-specific risks. Read them as a ranked list of trust failures, not as theoretical edge cases.

| Risk | Severity | Why it matters now |
| --- | --- | --- |
| Unvetted Desktop Extension installs | Critical | A one-click `.mcpb` bundle can package code, dependencies, and manifest-declared behavior into a local install flow.[1] |
| Prompt injection through tool responses | High | MCP servers return text that the model then treats as context, and the spec tells implementors to treat tools as arbitrary code execution and untrusted surfaces.[2][4] |
| Dependency confusion in npm or PyPI packages | High | Many servers still ship as ordinary packages, so standard package-repo attacks still apply. |
| HTTP and SSE transport interception or auth failure | High | The auth spec now exists, but live implementations still show brittle discovery, redirect, and token handling.[3][7][8] |
| Capability negotiation spoofing | Medium-High | What a server advertises at handshake time is not the same as what it may later do in practice.[2][4] |
| Claude Code stdio sandbox escape | High | Anthropic's own sandboxing work exists because agent autonomy without isolation is risky.[9] |
| Community plugin or skill injection | Medium | Community surfaces widen distribution faster than human review scales.[12] |
| Star farming and social proof manipulation | Medium | GitHub stars, README placement, and community-list inclusion are easy to over-trust, especially in a young ecosystem.[13] |
| Namespace squatting and lookalike servers | Medium | MCP naming conventions make typos and near-matches cheap attack paths. |
| Transitive cloud dependency concentration | Medium | Remote MCP hosting inherits the blast radius of the cloud providers underneath it.[11] |

The common thread is simple: MCP collapses discovery, install, execution, and model context into one product motion. Traditional software ecosystems at least forced those steps apart. MCP makes them feel like one button.

## Assume every `.mcpb` bundle is a code execution event

Desktop Extensions are the sharpest edge because they turn server installation into something that feels like adding a browser extension. Anthropic's own post makes the benefit explicit: no terminal, no config files, no dependency conflicts; package the server and dependencies, then drag the resulting `.mcpb` file into Claude Desktop.[1] That convenience is real. So is the trust leap.

An MCP bundle is not just metadata. It is a packaged runtime definition. The manifest declares the server type, entry point, command, arguments, user configuration, and supported runtimes. If you would not run an unknown binary from a random GitHub release, you should not install an unknown MCP bundle just because the install surface looks polished.

Anthropic does note security features such as separate-process execution, permission visibility, and limited permissions in the Desktop Extensions post.[1] That helps, but it is not the same as provenance. Sandboxing contains some classes of damage after execution. It does not answer the earlier question: who built this bundle, what exactly is inside it, and did anyone independent verify it before you installed it?

That distinction matters because Anthropic's sandboxing write-up for Claude Code is fundamentally about constraining an already-running agent. The post introduces filesystem isolation, network isolation, and an OS-level sandbox runtime because prompt injection and approval fatigue are real problems in agentic workflows.[9] A sandbox is a compensating control. It is not a registry guarantee.

So the right mental model is not "extension install." It is "local process execution with a nicer wrapper." If you start from that premise, your behavior changes. You inspect the manifest. You check the command. You inspect the dependency chain. You isolate the runtime. You assume that a bundle with a clean icon can still be hostile.

## Treat remote MCP authentication as unfinished infrastructure, not solved plumbing

The protocol story is more mature than it was a year ago. The MCP specification now includes explicit authorization material, including OAuth 2.1-oriented guidance, metadata discovery, and fallback rules for restricted servers.[3] That is a real improvement. If you need the protocol mechanics before evaluating a live connector, start with [[course/mcp-from-first-principles-to-production]].

But a written spec and a safe install surface are different things. The live issue queue in `anthropics/claude-ai-mcp` reads like a reminder that remote MCP is still rough at the edges. Issue #217 reports claude.ai skipping OAuth discovery entirely after a `401` response and silently giving up rather than following the advertised auth path.[7] Issue #250 reports that claude.ai rejected HTTP `307` redirects during OAuth callback handling and expected `302` or `303` instead.[8] The broader issues list also shows connector failures around token refresh, auth broker behavior, and post-OAuth connection handling.[6]

Why does that matter for security? Because broken auth flows create exactly the kind of user behavior attackers want. Users stop distinguishing between a legitimate auth prompt, a degraded connector, and a hostile workaround. They copy tokens into the wrong place. They disable checks. They approve reconnects they would not otherwise approve. "It's just flaky" is one of the oldest social-engineering enablers in software.

The deeper point is that remote MCP inherits web auth complexity at the same moment local MCP inherits package-execution risk. The ecosystem is asking users to reason about both at once.

## Do not confuse community review with registry-grade verification

This is where the story gets more interesting than the usual "open ecosystems are risky" take. Anthropic's community plugin marketplace is not completely ungoverned. The `anthropics/claude-plugins-community` repository says it is a read-only mirror of the community plugin marketplace, synced nightly from Anthropic's internal review pipeline, and that every listed plugin has passed automated security scanning and been approved for distribution.[12]

Read that as a self-attestation about one plugin surface, not as proof that the broader MCP ecosystem has solved provenance. The same repo does not publish a bundle signing standard, a reproducible-build policy, or a verification workflow that would let a user independently confirm that a third-party MCP artifact matches what was reviewed. That is why the synthesis still treats community plugin and skill surfaces as risk vectors. A review pipeline can exist and still leave a verification gap.

The gap is even clearer once you compare surfaces. The Desktop Extensions post describes packaging and install mechanics, but it does not describe a mandatory signing regime or public provenance standard for every `.mcpb` a user may encounter.[1] Community-maintained GitHub lists sit outside Anthropic's internal review pipeline and should be treated as discovery aids, not trust guarantees.[13] And the GitHub MCP integration surface shows that remote transport behavior is still changing in public.[6][7][8]

That is the contrarian angle worth keeping. The problem is not that Anthropic has done nothing. The problem is that the trust guarantees are inconsistent across surfaces while the user experience makes those surfaces feel interchangeable. A community plugin mirror with nightly sync and automated scanning is one thing. A community directory ranking servers by social proof is another. A self-contained local bundle is something else again. Users should not have to reverse-engineer which trust model they are in after they have already clicked install.

This is also where [[vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026|the Supply Chain Threat Atlas]] helps. The Atlas argues that AI tooling keeps collapsing abstraction layers. MCP does the same thing socially: it makes a reviewed marketplace, a GitHub repo, and a random bundle feel like adjacent options in the same product family.

## Use Claude Security as a reviewer, not as a trust badge for the registry

Anthropic's public beta launch for Claude Security is serious work. The product scans codebases for vulnerabilities, produces contextual findings, and generates proposed fixes. Anthropic positions it as defensive AI for code review and vulnerability triage, not as a toy scanner.[10] If you maintain an MCP server, that is relevant. You can use Claude Security to audit the server code you plan to ship.

What it is not, at least today, is a registry-level enforcement mechanism. The launch post describes scheduled scans, targeted scans, export workflows, and partner integrations. It does not describe automatic registry admission control for MCP servers, a mandatory scan before listing, or a public attestation attached to every bundle.[10]

That distinction matters because security products often get mistaken for ecosystem guarantees. They are not the same. A good scanner helps a diligent maintainer ship safer code. It does not prove that the artifact a user downloaded from a third-party directory matches the code that was scanned. It does not tell you whether the bundle was rebuilt with a malicious dependency later. It does not replace signing, checksums, reproducible builds, or a public review trail.

So developers should absolutely use Claude Security on MCP codebases. Anthropic already has the product surface to make that useful. But users should not infer from that existence that the registry problem is already solved. The current state is better summarized this way: Anthropic has built a strong reviewer, while the MCP ecosystem still lacks a uniform notary.

## Audit the bundle before install, and isolate the runtime after install

The best defense available right now is not magical. It is boring operational hygiene applied earlier than most people are used to.

Before you install a Desktop Extension, inspect the manifest inside the bundle. Anthropic's format makes that possible because the package is just an archive with a manifest and runtime configuration.[1]

> [!run-prompt-cell] Run this: inspect an MCP bundle before you install it
> ```bash
> unzip -p suspicious-server.mcpb manifest.json | jq '{
>   name,
>   version,
>   author,
>   runtime: .server.type,
>   command: .server.mcp_config.command,
>   args: .server.mcp_config.args,
>   user_config: (.user_config // {})
> }'
> ```
>
> Expected output:
> ```json
> {
>   "name": "filesystem-helper",
>   "version": "0.3.1",
>   "author": { "name": "Example Dev" },
>   "runtime": "node",
>   "command": "node",
>   "args": ["${__dirname}/server/index.js"],
>   "user_config": {
>     "root_dir": {
>       "type": "string",
>       "description": "Directory the server can read"
>     }
>   }
> }
> ```

That one command already catches a surprising amount: unexpected executables, odd entry points, broad user-configuration prompts, and runtime assumptions that do not match the README. It also forces a pause before install, which is valuable on its own.

From there, the defensive checklist is straightforward:

1. Inspect the manifest and install command before first run. If the command surprises you, stop.
2. Prefer pinned package versions and explicit hashes for any npm or PyPI dependencies referenced by the server.
3. Run new servers in a disposable profile, container, or VM first. Anthropic's own sandboxing work is an existence proof that isolation materially reduces risk.[9]
4. Limit filesystem and network access to the minimum the server needs. A model does not need your whole home directory just because a plugin says it is "more helpful" with broad access.
5. Treat tool output as untrusted input. Even a benign server can be compromised later, and even a correct tool can return adversarial content. If your team needs the habits behind that rule, [[course/secure-coding-with-claude]] is the right follow-on.

The goal is not zero risk. It is moving MCP installs back toward ordinary software scrutiny. Right now too many teams review prompts more carefully than they review the software that the prompt is about to call.

## Map MCP registry risk back to the supply chain atlas, then push for stronger defaults

The final frame is the broad one. [[vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026|AI Coding Agent Supply Chain Threat Atlas]] argued that the dangerous part of agent tooling is not one model making one bad choice. It is the chain: package source, dependency tree, tool invocation path, network boundary, credential surface, and human approval loop. MCP registry risk is that argument with fewer abstractions and a faster click path.

That is why the ten risks in the synthesis are so useful. They cover every layer that matters: local bundle execution, tool-response injection, dependency confusion, auth brittleness, handshake spoofing, sandbox escape, community-surface injection, fake social proof, namespace squatting, and cloud concentration risk. None of those require science fiction. They require only an ecosystem that optimizes install velocity before it standardizes trust.

There is a policy implication here too. Anthropic should not have to solve every community directory, but the company can make the safest path the default path. The ecosystem needs at least four things next: published signing requirements for distributable bundles, clearer provenance metadata, reproducible build guidance, and a visible distinction between "listed," "scanned," and "reviewed." The plugin marketplace hints at what a stronger submission pipeline can look like, but the harder step is extending that clarity to MCP's most popular install surfaces.[12]

There is also a product-design lesson here. Install friction was treated as the main adoption bottleneck, so the ecosystem removed terminal setup first. Trust friction was left for later. That is backwards for tools that can read files, call APIs, and shape what an LLM sees next. The safer sequence would have been provenance first, then one-click convenience.

Until then, the practical answer to "is the MCP server registry safe?" stays the same: it is only as safe as your pre-install review, your isolation model, and your willingness to treat agent tooling like software supply chain infrastructure instead of app-store furniture.

## KnowledgeCheck

Question: Which control reduces MCP registry risk the most today?

A. Choosing the server with the most GitHub stars  
B. Assuming Claude Security means every listed server was reviewed  
C. Inspecting the bundle manifest, pinning dependencies, and isolating first run  
D. Waiting for the model to refuse malicious tool output on its own

Answer: C

If you want the defensive workflow behind that answer, start with [[course/secure-coding-with-claude]]. Then use [[course/mcp-from-first-principles-to-production]] to understand the protocol surface you are hardening.

## References

[1] Claude Desktop Extensions: One-click MCP server installation - Anthropic — https://www.anthropic.com/engineering/desktop-extensions · retrieved 2026-05-12
[2] Model Context Protocol Specification 2025-03-26 - modelcontextprotocol.io — https://modelcontextprotocol.io/specification/2025-03-26 · retrieved 2026-05-13
[3] Authorization - MCP Specification 2025-03-26 - modelcontextprotocol.io — https://modelcontextprotocol.io/specification/2025-03-26/basic/authorization · retrieved 2026-05-13
[4] Model Context Protocol specification repository - GitHub — https://github.com/modelcontextprotocol/specification · retrieved 2026-05-13
[5] anthropics/claude-ai-mcp - GitHub — https://github.com/anthropics/claude-ai-mcp · retrieved 2026-05-12
[6] anthropics/claude-ai-mcp issues - GitHub — https://github.com/anthropics/claude-ai-mcp/issues · retrieved 2026-05-13
[7] Issue #217: claude.ai skips OAuth discovery after 401 - GitHub — https://github.com/anthropics/claude-ai-mcp/issues/217 · retrieved 2026-05-13
[8] Issue #250: OAuth callback rejects HTTP 307 redirects - GitHub — https://github.com/anthropics/claude-ai-mcp/issues/250 · retrieved 2026-05-13
[9] Making Claude Code more secure and autonomous with sandboxing - Anthropic — https://www.anthropic.com/engineering/claude-code-sandboxing · retrieved 2026-05-12
[10] Claude Security is now in public beta - Claude — https://claude.com/blog/claude-security-public-beta · retrieved 2026-05-12
[11] Anthropic and Amazon expand collaboration for up to 5 gigawatts of compute - Anthropic — https://www.anthropic.com/news/anthropic-amazon-compute · retrieved 2026-05-12
[12] anthropics/claude-plugins-community - GitHub — https://github.com/anthropics/claude-plugins-community · retrieved 2026-05-13
[13] cnych/claude-mcp community MCP server list — https://github.com/cnych/claude-mcp · retrieved 2026-05-12
