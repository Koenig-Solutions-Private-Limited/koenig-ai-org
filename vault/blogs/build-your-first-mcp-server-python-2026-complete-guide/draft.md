---
date: 2026-07-06
title: "Build Your First MCP Server in Python (2026 Complete Guide)"
slug: build-your-first-mcp-server-python-2026-complete-guide
author: blog-author
ticket: KOEA-10201
vendor_tag: anthropic
content_type: article
status: g2-passed
reading_time_min: 6
tags:
  - mcp
  - python
  - fastmcp
  - tutorial
description: "Build your first Python MCP server with FastMCP, Claude Desktop configuration, version pinning, and the security checks that keep a toy demo from breaking in production."
seo_description: "Build a Python MCP server with FastMCP in 20 lines. Covers Claude Desktop config, version pinning for the July 2026 SDK v2 break, and minimum security rules."
primary_query: "MCP server tutorial getting started model context protocol"
contrarian_angle: "Most MCP tutorials will silently break your code on July 27, 2026 — one version-pin line prevents it"
first_60_words_answer: "To build your first MCP server in Python, install Python 3.10+, run `uv add 'mcp[cli]'`, and write a 10-line server using `from mcp.server.fastmcp import FastMCP` with the `@mcp.tool()` decorator. Run it with `uv run server.py` for stdio transport. Your tools are then callable from Claude Desktop or Cursor — no manual schema writing needed."
sources:
  - https://modelcontextprotocol.io/quickstart/server
  - https://github.com/modelcontextprotocol/python-sdk
  - https://www.digitalocean.com/community/tutorials/mcp-server-python
  - https://workos.com/blog/everything-your-team-needs-to-know-about-mcp-in-2026
  - https://stackoverflow.blog/2026/01/21/is-that-allowed-authentication-and-authorization-in-model-context-protocol
  - https://medium.com/@virtualik/building-mcp-servers-with-fastmcp-7-mistakes-worth-avoiding-07f81f693250
  - https://www.firecrawl.dev/blog/fastmcp-tutorial-building-mcp-servers-python
  - https://www.practical-devsecops.com/mcp-security-vulnerabilities
  - https://modelcontextprotocol.io/docs/getting-started/intro
  - https://developers.openai.com/api/docs/guides/tools-connectors-mcp
  - https://northflank.com/blog/how-to-build-and-deploy-a-model-context-protocol-mcp-server
positions:
  - id: mcp-as-interoperability-moat
    engagement: defends
  - id: mcp-as-agent-peer-protocol
    engagement: defends
  - id: prompt-injection-defense-at-boundary
    engagement: refines
  - id: stance:ai-vendor-news-opinionated
    engagement: defends
whats_new:
  - "Pin mcp>=1.27,<2 now — SDK v2 ships July 27 with breaking changes most tutorials won't warn you about"
learning_objectives:
  - "Stand up a Python MCP server with FastMCP in under 20 lines"
  - "Connect the server to Claude Desktop and Cursor using the correct config format"
  - "Apply the three minimum security rules before connecting any server to external data"
faq:
  - question: "Why is my MCP server not showing up in Claude Desktop?"
    answer: "Three common causes: (1) you used a relative path instead of an absolute path in `claude_desktop_config.json` — the config silently ignores relative paths; (2) you edited the config but only reloaded Claude Desktop instead of doing a full quit-and-relaunch; (3) the config key is `mcpServers` not `servers` — a typo here causes silent failure. Check the official local-server quickstart before debugging further: https://modelcontextprotocol.io/quickstart/server"
  - question: "Is FastMCP official or a third-party library?"
    answer: "There are two different packages sharing the FastMCP name in 2026. The official one ships inside the `mcp` package from the Model Context Protocol Python SDK repo — import it with `from mcp.server.fastmcp import FastMCP` as shown in https://github.com/modelcontextprotocol/python-sdk. A separate third-party `fastmcp` package adds its own production framework surface; Firecrawl's tutorial covers that ecosystem at https://www.firecrawl.dev/blog/fastmcp-tutorial-building-mcp-servers-python."
  - question: "Can I use MCP with OpenAI models, not just Claude?"
    answer: "Yes. MCP is a provider-neutral open protocol: the official intro says MCP connects AI applications such as Claude or ChatGPT to external systems, and names broad ecosystem support across clients and servers: https://modelcontextprotocol.io/docs/getting-started/intro. OpenAI also documents MCP connectors and remote MCP servers in its API docs at https://developers.openai.com/api/docs/guides/tools-connectors-mcp."
  - question: "What happens to my server code when MCP SDK v2 ships on July 27, 2026?"
    answer: "If you follow this guide's version pin (`mcp>=1.27,<2`), nothing breaks — pip will keep you on the last v1 stable release. If you omit the upper bound and auto-upgrade, v2 introduces breaking API changes documented by the official SDK repo and migration guide: https://github.com/modelcontextprotocol/python-sdk and https://py.sdk.modelcontextprotocol.io/v2/migration/. The safest path is to pin now, then upgrade deliberately."
original_data: false
last_updated: 2026-07-09
hero_image:
  url: /img/blogs/build-your-first-mcp-server-python-2026-complete-guide/hero.png
  alt: "Diagram showing the MCP architecture: a host application connecting to a local Python MCP server via stdio, with tool calls flowing from the LLM through the client to the server"
parent_issue: KOEA-10201
research_source: vault/research/anthropic/build-your-first-mcp-server-python-2026-complete-guide.md
---

# Build Your First MCP Server in Python (2026 Complete Guide)

To build your first MCP server in Python, you need Python 3.10+, the `mcp[cli]` package installed via `uv add "mcp[cli]"`, and a 10-line script using `from mcp.server.fastmcp import FastMCP` with the `@mcp.tool()` decorator. The SDK reads your type hints and docstrings to auto-generate the JSON schema Claude sees — no manual schema writing. Run with `uv run server.py` and your tools are callable from Claude Desktop or Cursor immediately via stdio transport. [source: modelcontextprotocol.io/quickstart/server](https://modelcontextprotocol.io/quickstart/server)

Most tutorials stop there. Here's what they don't tell you: the MCP Python SDK v2 is targeting a **breaking release on July 27, 2026**, and any code written today without an upper-bound version pin will silently break when pip auto-upgrades. One line in your `pyproject.toml` prevents this — and it's the difference between a toy demo and a server you can actually maintain.

![Diagram showing the MCP architecture: a host application connecting to a local Python MCP server via stdio, with tool calls flowing from the LLM through the client to the server](/img/blogs/build-your-first-mcp-server-python-2026-complete-guide/hero.png)

---

## What an MCP Server Actually Does (and Why It's Not Just Another Plugin System)

The [official MCP quickstart](https://modelcontextprotocol.io/quickstart/server) defines three server primitives:

| Primitive | Who invokes it | Side effects? | FastMCP decorator |
|-----------|---------------|---------------|-------------------|
| **Tool** | LLM (with user approval) | Yes — executes actions | `@mcp.tool()` |
| **Resource** | Application layer | No — read-only data | `@mcp.resource("scheme://{param}")` |
| **Prompt** | User via host UI | No — reusable templates | `@mcp.prompt()` |

For a first server, focus on **Tools** — they're what make Claude actually do things. Resources and Prompts are natural extensions once the core pattern is clear.

What makes MCP worth the investment is the n+m effect: build one MCP server for your internal API and it becomes callable from Claude Desktop, Cursor, and any other future MCP client without code changes. [WorkOS's 2026 MCP guide](https://workos.com/blog/everything-your-team-needs-to-know-about-mcp-in-2026) frames it well: MCP collapses the n×m integration problem that has plagued AI tool wiring since 2023.

---

## Set Up Your MCP Server in 5 Steps

### Step 1: Install the SDK

The official MCP toolchain uses `uv` as its package manager. If you don't have it:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Then scaffold and install:

```bash
uv init my-mcp-server
cd my-mcp-server
uv add "mcp[cli]"
```

The `[cli]` extra installs the MCP Inspector — a browser-based debugger you'll want for testing tools before connecting to Claude.

### Step 2: Pin the version (do this now)

Open `pyproject.toml` and add the constraint:

```toml
[project]
dependencies = [
  "mcp>=1.27,<2"
]
```

The current stable is v1.28.1 (released June 26, 2026). [The SDK repo](https://github.com/modelcontextprotocol/python-sdk) explicitly targets SDK v2 stable for **July 27, 2026** alongside the MCP spec revision — and v2 introduces breaking API changes. [DigitalOcean's MCP tutorial](https://www.digitalocean.com/community/tutorials/mcp-server-python) (updated June 12, 2026) states: *"Pin mcp>=1.27,<2 until the stable 2.x release ships."* Lock it now.

### Step 3: Write the server

Create `server.py`:

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers and return the result."""
    return a + b

@mcp.resource("greeting://{name}")
def greeting(name: str) -> str:
    """Return a greeting for the given name."""
    return f"Hello, {name}!"

if __name__ == "__main__":
    mcp.run(transport="stdio")
```

The SDK reads the type hints and docstring to build the JSON schema. The docstring becomes the tool description Claude sees when deciding whether to invoke your tool — write it clearly.

**Critical stdio rule**: Never use `print()` in a stdio server. Print writes to stdout, which corrupts the JSON-RPC framing the protocol uses. Log to stderr instead:

```python
import sys
# ❌ Breaks the server
print("Processing request")

# ✅ Correct
print("Processing request", file=sys.stderr)
```

### Step 4: Test with the Inspector

Before connecting to Claude, verify your tools work:

```bash
uv run mcp dev server.py
```

This opens a browser-based debugger where you can invoke tools directly and see their schemas. Catch errors here, not inside Claude Desktop.

### Step 5: Run it

```bash
uv run server.py
```

The server starts and waits for a client connection over stdio.

---

## Connect to Claude Desktop (macOS/Windows) or Cursor

For Claude Desktop, edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%AppData%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "my-server": {
      "command": "uv",
      "args": ["--directory", "/ABSOLUTE/PATH/TO/my-mcp-server", "run", "server.py"]
    }
  }
}
```

For Cursor, edit `~/.cursor/mcp.json` with the same `mcpServers` key structure.

**Three rules that cause most silent failures:**

1. Always use **absolute paths** — relative paths fail silently.
2. The config key is `mcpServers`, not `servers` — a typo here causes silent failure.
3. **Full quit-and-relaunch** Claude Desktop after any config change. Reload is not enough.

Note: Claude Desktop is not available on Linux as of July 2026. Linux users should build their own MCP client or use a framework that supports stdio servers directly.

---

## Three Security Rules Before You Go Live

Two real incidents in the past six months make security non-optional for any MCP tutorial:

- **January 2026**: Anthropic's own `mcp-server-git` reference server exposed path traversal and argument injection flaws. [Medium, 2026](https://medium.com/@virtualik/building-mcp-servers-with-fastmcp-7-mistakes-worth-avoiding-07f81f693250)
- **CVE-2025-6514**: A CVSS 9.6 command injection in `mcp-remote` via OAuth handling.

The [Practical DevSecOps MCP security guide](https://www.practical-devsecops.com/mcp-security-vulnerabilities) identifies prompt injection and tool poisoning as the two primary vectors: *"Both attack vectors can lead to data loss, privilege abuse, or full system compromise."*

**Minimum safe practices for any MCP server:**

1. **Never eval user input** — not even in a "local-only" server that later gets deployed remotely.
2. **Least privilege on tool surfaces** — only expose tools the host application actually needs.
3. **Log every tool invocation to stderr** — `logging.info("Tool %s called with %s", name, args)`. Auditability is the enterprise gate.

For remote servers using Streamable HTTP transport (`mcp.run(transport="streamable-http")`): OAuth 2.1 with PKCE is required by the spec. The [Stack Overflow blog's 2026 MCP auth guide](https://stackoverflow.blog/2026/01/21/is-that-allowed-authentication-and-authorization-in-model-context-protocol) clarifies that stdio transport uses environment credentials instead — pass API keys via the `env` block in your MCP config, not hardcoded in the server file.

---

## Knowledge Check

**Question:** Which practice is safest before connecting an MCP server to real data?

A. Expose every internal API as a tool.

B. Keep tools minimal, log invocations, and pass secrets through host config.

C. Use `print()` for debugging stdout.

<details>
<summary>Answer</summary>

B. MCP tools are action surfaces, so least privilege and audit logs matter. For stdio servers, stdout is reserved for JSON-RPC; logs go to stderr and secrets belong in config, not code.

</details>

---

## Knowledge Check

**Question:** You've built a stdio MCP server and it connects in the MCP Inspector, but it doesn't appear in Claude Desktop after you restart the app. You checked the config path and it's correct. What are the two most likely causes?

<details>
<summary>Answer</summary>

1. You used a relative path in the `command` or `args` field — stdio MCP configs require absolute paths. A relative path fails silently.
2. You "reloaded" Claude Desktop (Command+R or menu refresh) instead of fully quitting and relaunching it. Claude Desktop only re-reads `claude_desktop_config.json` on full app startup.

</details>

---

## FAQ

**Why is my MCP server not showing up in Claude Desktop?**

Three common causes: (1) relative path instead of absolute path in `claude_desktop_config.json` — the config silently ignores relative paths; (2) reload instead of full quit-and-relaunch; (3) the config key is `mcpServers` not `servers`. Check all three before debugging further.

**Is FastMCP the official SDK or a third-party library?**

Both, confusingly. The official FastMCP ships inside the `mcp` package from Anthropic's Python SDK — import with `from mcp.server.fastmcp import FastMCP`. A separate third-party `fastmcp` package on PyPI (v3.0, January 2026) adds OpenTelemetry and granular auth. [Firecrawl's FastMCP guide](https://www.firecrawl.dev/blog/fastmcp-tutorial-building-mcp-servers-python) covers the third-party version. For a first server, use the official SDK package.

**Can I use my MCP server with OpenAI models, not just Claude?**

Yes — MCP is a provider-neutral open protocol. The official MCP intro describes MCP as an open-source standard for connecting AI applications, including Claude and ChatGPT, to external systems; OpenAI also documents remote MCP servers in its API docs. Any compliant MCP client can call your server. [source: modelcontextprotocol.io/docs/getting-started/intro](https://modelcontextprotocol.io/docs/getting-started/intro), [source: developers.openai.com/api/docs/guides/tools-connectors-mcp](https://developers.openai.com/api/docs/guides/tools-connectors-mcp)

**What happens to my server when SDK v2 ships July 27, 2026?**

If you pinned `mcp>=1.27,<2` per Step 2, nothing breaks. If you omitted the upper bound, pip will auto-upgrade and your imports will likely fail. Upgrade deliberately after reading the official migration guide at `py.sdk.modelcontextprotocol.io/v2/migration/`.

---

## Go Deeper with the Full MCP Course

This guide covers the minimum to get a local server running. Production MCP work involves transport selection for multi-client deployments, gateway auth, audit logs, and rollback paths for irreversible tool actions.

The Koenig AI Academy's **[MCP From First Principles to Production](https://academy.kspl.tech)** course covers [[courses/mcp-from-first-principles-to-production/01-why-mcp-exists|why MCP exists at the protocol level]], JSON-RPC over stdio, OAuth/DPoP authentication for Streamable HTTP, and [[courses/mcp-from-first-principles-to-production/05-gateways-audit-logs|gateway patterns with full audit trails]]. If you're building MCP connectors for creative tools (Blender, Adobe Creative Cloud, Ableton), the [[courses/claude-mcp-mastery/outline|Claude MCP Mastery course]] walks through production connector workflows with permissions and rollback planning.
