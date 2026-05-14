---
date: 2026-05-13
author: blog-author
ticket: KOEA-1424
vendor_tag: anthropic
content_type: article
status: draft-for-review
title: "Treat the Anthropic MCP server registry like an unsigned package manager"
slug: "mcp-server-registry-security"
description: "Anthropic has added real review to some plugin paths, but the wider MCP install ecosystem still behaves like an unsigned package manager: easy local code execution, uneven provenance, and too much trust placed in bundles, repos, and copied install commands."
reading_time_min: 13
primary_query: "is the Anthropic MCP server registry safe"
contrarian_angle: "The biggest risk is not prompt injection inside Claude. It is distribution: most MCP installs still lack package-manager-grade signing, attestation, and policy controls."
sources:
  - https://www.anthropic.com/engineering/desktop-extensions
  - https://www.anthropic.com/engineering/claude-code-sandboxing
  - https://claude.com/blog/claude-security-public-beta
  - https://www.anthropic.com/news/anthropic-amazon-compute
  - https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices
  - https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
  - https://github.com/anthropics/claude-ai-mcp
  - https://github.com/anthropics/claude-plugins-community
  - https://github.com/anthropics/dxt
  - https://github.com/cnych/claude-mcp
whats_new:
  - Anthropic now reviews marketplace plugins, but the riskiest MCP installs still arrive through one-click bundles, GitHub repos, and package managers without a universal trust layer.
learning_objectives:
  - Distinguish between Anthropic-reviewed plugin distribution and the wider MCP install paths that still behave like unsigned package feeds.
  - Apply a practical 10-risk audit before installing an MCP server in Claude Desktop, Claude Code, or a team runtime.
references:
  - n: 1
    title: "Claude Desktop Extensions: One-click MCP server installation for Claude Desktop — Anthropic"
    url: https://www.anthropic.com/engineering/desktop-extensions
    retrieved: 2026-05-13
  - n: 2
    title: "Making Claude Code more secure and autonomous with sandboxing — Anthropic"
    url: https://www.anthropic.com/engineering/claude-code-sandboxing
    retrieved: 2026-05-13
  - n: 3
    title: "Claude Security is now in public beta — Claude"
    url: https://claude.com/blog/claude-security-public-beta
    retrieved: 2026-05-13
  - n: 4
    title: "Anthropic and Amazon expand collaboration for up to 5 gigawatts of AI compute — Anthropic"
    url: https://www.anthropic.com/news/anthropic-amazon-compute
    retrieved: 2026-05-13
  - n: 5
    title: "Security Best Practices — Model Context Protocol"
    url: https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices
    retrieved: 2026-05-13
  - n: 6
    title: "Authorization — Model Context Protocol specification"
    url: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
    retrieved: 2026-05-13
  - n: 7
    title: "Claude.ai MCP Integration — anthropics/claude-ai-mcp"
    url: https://github.com/anthropics/claude-ai-mcp
    retrieved: 2026-05-13
  - n: 8
    title: "Claude Plugins — Community — anthropics/claude-plugins-community"
    url: https://github.com/anthropics/claude-plugins-community
    retrieved: 2026-05-13
  - n: 9
    title: "MCP Bundles (MCPB) / DXT toolchain — anthropics/dxt"
    url: https://github.com/anthropics/dxt
    retrieved: 2026-05-13
  - n: 10
    title: "Claude MCP Community Website source — cnych/claude-mcp"
    url: https://github.com/cnych/claude-mcp
    retrieved: 2026-05-13
---

# Treat the Anthropic MCP server registry like an unsigned package manager

Is the Anthropic MCP server registry safe? Not by default. The safe answer in May 2026 is to treat every MCP server install as untrusted code until you verify how it is distributed, what runtime it executes, what scopes it gets, and whether it stays inside a sandbox. Anthropic has added more review around some plugin distribution paths, but the broader MCP ecosystem still makes it very easy to install local code through bundles, GitHub repos, and package managers before package-manager-grade trust controls exist at the protocol level ([Anthropic Desktop Extensions](https://www.anthropic.com/engineering/desktop-extensions), [MCP security best practices](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices), [Claude Plugins — Community](https://github.com/anthropics/claude-plugins-community)).

What most people miss is where the real bottleneck sits. The loud conversation is about prompt injection inside Claude. The quieter, more important problem is distribution. Anthropic can keep improving model behavior, but if your team installs an MCP bundle that ships a malicious dependency, or copies an `npx` command from a community directory, you are back in the same trust model that made npm and PyPI supply-chain incidents so expensive. The protocol is only half the story. The install path is the other half. That is the registry-specific extension of the broader argument in [[blog/ai-coding-agent-supply-chain-threat-atlas-2026]]: agents are dangerous less because they "think" and more because they compress retrieval, execution, and privilege into one uninterrupted flow.

## Treat the ecosystem as three trust zones, not one registry

There is no single "Anthropic MCP registry" with one security model. There are at least three trust zones that matter in practice.

First, there is Anthropic's reviewed plugin path. The `anthropics/claude-plugins-community` repository says the public repo is a read-only mirror of a community plugin marketplace and that listed plugins are synced from an internal review pipeline after automated security scanning and approval for distribution ([Claude Plugins — Community](https://github.com/anthropics/claude-plugins-community)). That is better than many people assume. It means some of the ecosystem already has more process than "random GitHub README plus hope."

Second, there is the Desktop Extensions path. Anthropic's Desktop Extensions post makes installation intentionally frictionless: an `.mcpb` bundle is a zip archive containing the MCP server, its dependencies, and a `manifest.json`, and Claude Desktop is designed to make installation feel like a one-click action ([Anthropic Desktop Extensions](https://www.anthropic.com/engineering/desktop-extensions), [MCP Bundles toolchain](https://github.com/anthropics/dxt)). That convenience is the point of the product. It also means the old security friction of manual config editing, environment setup, and dependency inspection is disappearing.

Third, there is the wider community directory path. The `cnych/claude-mcp` repository describes claudemcp.com as a community hub with a server directory and a submission flow that can auto-generate pull requests for new entries ([claudemcp.com source repo](https://github.com/cnych/claude-mcp)). That is useful for discovery. It is not the same thing as a cryptographically signed, centrally enforced trust program.

This is the first correction security-minded teams should make: stop talking about "the registry" as if it were one thing. Anthropic-reviewed plugins, one-click bundles, community directories, direct GitHub installs, and `npm` or `uvx` install flows are different risk classes. If your policy says "MCP is allowed," but does not distinguish among those channels, your policy is too coarse to matter.

## Assume one-click installs can run local code

The MCP documentation is not vague about the failure mode here. The official security best-practices page includes a local server compromise example that literally shows `npx malicious-package` exfiltrating `~/.ssh/id_rsa`, and a privilege-escalation example that chains dangerous shell behavior into an install flow ([MCP security best practices](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices)). That is not alarmist writing. It is the protocol documentation telling you that local MCP servers should be treated as code execution, not as harmless metadata.

Anthropic's own Desktop Extensions materials reinforce the point from a packaging angle. A bundle can contain a Node server, a Python server, or a classic executable, plus the dependencies required to run it ([Anthropic Desktop Extensions](https://www.anthropic.com/engineering/desktop-extensions), [MCP Bundles toolchain](https://github.com/anthropics/dxt)). In other words, the ecosystem has already normalized a format whose whole job is to make local code execution feel as ordinary as installing a browser extension.

That is why Anthropic's sandboxing work matters so much. The Claude Code sandboxing post explains that real isolation needs both filesystem and network boundaries, and says sandboxing reduced permission prompts by 84% in Anthropic's internal usage ([Claude Code sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)). The important read is not "great, fewer prompts." It is "Anthropic had to build stricter boundaries because prompt approval alone was not a strong enough defense." If you install a third-party MCP server without equivalent boundaries, you are choosing the pre-sandbox trust model.

There is also a subtle but important asymmetry between Anthropic's reviewed plugin mirror and the rest of the install ecosystem. The plugin mirror now says marketplace entries have passed automated security scanning and approval for distribution ([Claude Plugins — Community](https://github.com/anthropics/claude-plugins-community)). Good. But Desktop Extensions, direct GitHub installs, and community-directory copy-paste flows still do not inherit one universal trust layer by default. The risk is not that Anthropic reviews nothing. The risk is that most teams will behave as if one reviewed surface somehow secures all the other surfaces.

## Score these 10 registry risks before you install anything

Here is the practical threat model. Not every item below has a formal CVE yet. Several are attack classes that the MCP docs or Anthropic docs already describe directly. That is exactly why they deserve attention now.

| Risk | Why it matters | What to verify before install |
|---|---|---|
| 1. Unvetted bundle install | `.mcpb` packages make local code execution look routine | Inspect runtime type, dependency tree, and network destinations |
| 2. Prompt injection through tool results | Tool output can carry instructions the model treats as context | Separate untrusted content from privileged tools; review server output handling |
| 3. Dependency confusion in npm/PyPI packages | Many MCP installs still resolve through generic package managers | Pin exact versions and check package provenance |
| 4. Auth and transport gaps on remote servers | Remote MCP still depends on correct OAuth and metadata handling | Require protected-resource metadata, scopes, and TLS-only endpoints |
| 5. Capability spoofing | A server can advertise a benign surface and behave differently later | Re-check tool list changes and lock allowed tools |
| 6. stdio child-process abuse | Local servers run as processes with meaningful local access | Force sandboxing and deny ambient shell/network privileges |
| 7. Off-marketplace plugin injection | Review exists for marketplace plugins, not for every repo install | Prefer reviewed channels over README-based installs |
| 8. Social-proof manipulation | Stars and directory ranking are cheap to fake | Prefer code provenance and maintenance history over popularity |
| 9. Namespace squatting | Lookalike package and repo names are easy to miss | Verify exact repo owner, package name, and release history |
| 10. Transitive cloud-provider trust | Hosted MCP servers inherit the blast radius of their hosting stack | Review where the server runs and what cloud credentials it touches |

A few of these deserve extra emphasis.

Prompt injection is still the obvious attacker move, but the right frame is wider than "the model saw a bad sentence." The MCP docs explicitly call out session hijacking, confused-deputy risks, overscoped auth, and local server compromise as implementation concerns, not abstract theory ([MCP security best practices](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices), [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)). If your server can read untrusted resources and also act with broad write scopes, prompt injection becomes a trust-boundary failure, not just an LLM failure.

The authorization story is especially important for remote servers. The spec requires protected-resource metadata discovery, `WWW-Authenticate` scope challenges, and resource-bound access patterns so clients know which scopes are needed for which target ([MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)). That gives teams a real design pattern: if a registry entry cannot explain its scopes, audience binding, and authorization metadata, it has not earned production trust.

The cloud-provider risk sounds abstract until you tie it back to Anthropic's deployment footprint. Anthropic's April 2026 AWS announcement says the company is committing to huge compute expansion and deeper AWS integration, including a coming Claude Platform on AWS experience ([Anthropic and Amazon compute expansion](https://www.anthropic.com/news/anthropic-amazon-compute)). That does not mean AWS-hosted MCP is unsafe. It means infrastructure concentration is part of the trust chain now. Hosted MCP tools are not just "a remote server." They are remote servers sitting inside specific cloud, identity, and governance assumptions.

## Audit an MCP server with policy, not social proof

A security review for an MCP server should look a lot more like a package review than a product demo. I would ask five questions before approving any install.

1. What code actually runs, and in which runtime?
2. What outbound network destinations does it need on day one?
3. What scopes does it request, and can those scopes be narrowed?
4. Is this install path covered by a reviewed marketplace, or did it arrive through a repo, a bundle, or a package manager?
5. If the server is compromised, what can it read, modify, or exfiltrate from the operator's machine or connected services?

That checklist is boring on purpose. The bad alternative is to trust stars, screenshots, or "official-looking" install pages. The claudemcp.com source repo makes clear that the directory is a community hub and submission surface ([claudemcp.com source repo](https://github.com/cnych/claude-mcp)). The `claude-ai-mcp` repository is a communications hub for MCP integration issues, not a blanket statement that every listed or community-discovered server is safe to install ([Claude.ai MCP Integration](https://github.com/anthropics/claude-ai-mcp)). Neither surface should be read as a substitute for runtime review.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You are reviewing an MCP server before installation. Given this manifest and install path, produce a risk report with: runtime, local-code-execution risk, required secrets, outbound domains, requested scopes, persistence/update path, and a final verdict of allow / sandbox-only / reject. Manifest: {\"server\": {\"type\": \"node\", \"entry_point\": \"server/index.js\", \"mcp_config\": {\"command\": \"node\", \"args\": [\"${__dirname}/server/index.js\"], \"env\": {\"GITHUB_TOKEN\": \"${user_config.github_token}\"}}}, \"tools\": [\"repo.read\", \"repo.write\", \"issues.list\"], \"user_config\": {\"github_token\": {\"type\": \"string\", \"sensitive\": true}}}. Install path: downloaded from a community directory, not Anthropic's reviewed plugin marketplace."
  expectedOutput="A short security review that flags Node local execution, a sensitive GitHub token, write-capable tool scope, off-marketplace distribution risk, and recommends sandbox-only or reject unless the token and tool scopes are narrowed."
/>

The reason to encode review this way is that Anthropic's own security products are moving in the same direction. Claude Security, now in public beta, is positioned as an agentic security reviewer that finds vulnerabilities and generates patches, but it is not wired directly into every MCP install path or community directory by default ([Claude Security public beta](https://claude.com/blog/claude-security-public-beta)). That is useful context for buyers: the defense capability exists, but the registry plumbing has not caught up yet.

## Ask for package-manager-grade trust, not smarter models

The most useful long-term demand is not "make Claude better at spotting prompt injection." Anthropic should do that, and clearly is doing some of it. The bigger ask is to make MCP distribution feel more like a hardened software supply chain.

That means signed bundles, provenance attestations, visible review states, scope manifests that are enforced instead of merely declared, and install policies that enterprises can apply across reviewed plugins, bundles, and remote servers. It also means pushing more of the MCP documentation's security guidance into defaults. The protocol docs already describe scope minimization, SSRF defenses, session binding, and local-compromise risks in plain language ([MCP security best practices](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices), [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)). The gap is not awareness. The gap is making those controls unavoidable in real installs.

That is the real difference between an interesting ecosystem and a production-safe one. Anthropic's reviewed plugin mirror is a step in the right direction. So is sandboxing. So is Claude Security. But none of those remove the core problem that distribution still outruns trust. Until every major MCP install path offers package-manager-grade provenance and enforceable least privilege, the right security posture is skepticism first, convenience second.

<KnowledgeCheck
  question="What is the most important security distinction when evaluating an MCP server registry entry?"
  options={[
    "Whether the server has a polished landing page and many stars",
    "Whether the model using it is smart enough to resist prompt injection on its own",
    "Whether the install path is reviewed and enforceable, or just a convenient way to run local code with broad scopes",
    "Whether the server uses Python instead of Node"
  ]}
  correctIdx={2}
  explanation="The main risk is distribution plus privilege. A reviewed marketplace, narrow scopes, and sandboxed execution matter more than social proof or runtime language alone."
/>

This post is the narrower follow-up to [[blog/ai-coding-agent-supply-chain-threat-atlas-2026]]. If you want the implementation path after the threat model, start with [[course/mcp-from-first-principles-to-production]]. Then use [[course/production-agents-claude-agent-sdk-mcp-connector]] to design the sandboxing, connector scoping, and runtime boundaries that keep an MCP install from turning into a local breach.

## References

1. Anthropic, "Claude Desktop Extensions: One-click MCP server installation for Claude Desktop" — https://www.anthropic.com/engineering/desktop-extensions · retrieved 2026-05-13
2. Anthropic, "Making Claude Code more secure and autonomous with sandboxing" — https://www.anthropic.com/engineering/claude-code-sandboxing · retrieved 2026-05-13
3. Claude, "Claude Security is now in public beta" — https://claude.com/blog/claude-security-public-beta · retrieved 2026-05-13
4. Anthropic, "Anthropic and Amazon expand collaboration for up to 5 gigawatts of AI compute" — https://www.anthropic.com/news/anthropic-amazon-compute · retrieved 2026-05-13
5. Model Context Protocol, "Security Best Practices" — https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices · retrieved 2026-05-13
6. Model Context Protocol, "Authorization" — https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization · retrieved 2026-05-13
7. GitHub, "anthropics/claude-ai-mcp" — https://github.com/anthropics/claude-ai-mcp · retrieved 2026-05-13
8. GitHub, "anthropics/claude-plugins-community" — https://github.com/anthropics/claude-plugins-community · retrieved 2026-05-13
9. GitHub, "anthropics/dxt" — https://github.com/anthropics/dxt · retrieved 2026-05-13
10. GitHub, "cnych/claude-mcp" — https://github.com/cnych/claude-mcp · retrieved 2026-05-13