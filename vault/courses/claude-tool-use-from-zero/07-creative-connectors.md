---
chapter_num: 7
course_slug: claude-tool-use-from-zero
title: "Creative Connectors"
date: 2026-04-30
author: Koenig Editorial Team
agent_drafted_by: 1f8e653d-1e0b-430e-84f2-a159e8410b86
ticket: KOE-10
vendor_tag: anthropic
content_type: article
learning_objectives:
  - "Install and verify the Blender MCP connector"
  - "Execute Python inside a live Blender session via Claude tool-use"
  - "Coordinate multi-tool Adobe for creativity pipelines (Library search, Photoshop edit, export)"
  - "Design resilient tool-use systems with provider-agnostic fallbacks"
prerequisites_chapters:
  - 1
  - 2
  - 3
  - 4
  - 5
  - 6
duration_min: 50
whats_new:
  - "Added full walkthroughs for Blender (Python API) and Adobe for creativity connectors"
  - "Added resilience sidebar following the April 2026 Claude outage"
  - "Updated structure to V3-1b standards"
status: published
published_at: 2026-04-30
approved_by: vardaan97@gmail.com
approval_id: 68fb92c5-9413-4857-82d3-ca7bf669edf0
reading_time_min: 10
sources:
  - https://www.anthropic.com/news/claude-for-creative-work
  - https://modelcontextprotocol.io/
  - https://raw.githubusercontent.com/blender/blender/main/doc/python_api/rst/info_overview.rst
  - https://news.ycombinator.com/item?id=47956895
  - https://status.claude.com/incidents/2gf1jpyty350
  - https://news.ycombinator.com/item?id=47952722
quiz:
  - question: "Why did Anthropic target creative tools as early MCP connectors instead of enterprise CRM systems?"
    options:
      - "Creative tools have significantly larger user bases than enterprise CRM across all market segments"
      - "Creative syntax like bpy and ExtendScript is hard for humans but easy for LLMs, making the benefit immediate"
      - "Enterprise CRM vendors declined to provide API documentation for the MCP connector launch"
      - "Creative connectors require fewer authentication steps and no enterprise compliance review process"
    correct_idx: 1
    explanation: "The chapter identifies three reasons: creative syntax has a high barrier for humans but is easy for LLMs, creating immediate 'aha!' moments; a bug in a 3D script is a creative glitch, not a business incident — lower risk for early production testing; cross-app bridging positions Claude as the creative studio OS. User base size and authentication complexity are not the cited reasons."
    section_anchor: why-anthropic-chose-creative-apps-first
  - question: "Which architecture principle applies to all nine initial creative connectors launched in April 2026?"
    options:
      - "Cloud-first storage: all creative assets are uploaded to Anthropic's CDN before processing"
      - "Local-first architecture: creative assets stay on the user's machine while Claude sends structured commands"
      - "Batch-only execution: all tool commands are queued and processed in an offline scheduled job"
      - "Container-based isolation: each connector runs inside a Docker sandbox with no host filesystem access"
    correct_idx: 1
    explanation: "The chapter states the connectors 'run as local MCP servers, meaning your creative assets stay on your machine while Claude only sends and receives structured commands.' Cloud-first storage, batch-only execution, and container-based isolation are not described for these connectors — local-first is the defining architecture."
    section_anchor: key-facts
  - question: "What does the Blender MCP connector expose to Claude?"
    options:
      - "A simplified wrapper with pre-defined 3D shape commands for common modeling operations"
      - "Blender's native Python API (bpy) for executing code directly against the live scene state"
      - "A static catalog of pre-rendered scene templates that Claude selects and applies by name"
      - "A REST API that proxies Blender render requests to Anthropic's cloud servers for processing"
    correct_idx: 1
    explanation: "The Blender connector exposes the native bpy Python API, allowing Claude to execute real bpy patterns against the live Blender scene. It is not a simplified wrapper, a static template catalog, or a cloud proxy — it runs locally and gives Claude access to the same Python API a human Blender developer would use."
    section_anchor: walkthrough-controlling-blender-via-mcp
---

# How to use Claude’s creative connectors for Blender and Adobe for creativity

The creative connectors are a suite of nine integrations launched by Anthropic on April 28, 2026, that enable the Model Context Protocol (MCP) to control professional creative software directly via Claude. This launch marks a strategic shift for MCP: instead of targeting enterprise SaaS (like Salesforce or Jira) first, Claude has moved into the "creative beachhead" — tools like Blender, Adobe for creativity, and Ableton.

## Key facts

1.  **Nine initial connectors**: The launch includes Blender, Adobe for creativity, Ableton Live, Affinity by Canva, Autodesk Fusion, SketchUp, Resolume Arena, Resolume Wire, and Splice.
2.  **Live scene execution**: Unlike static file parsing, connectors like Blender allow Claude to execute code (via `bpy`) against the live scene state.
3.  **Local-first architecture**: The connectors run as local MCP servers, meaning your creative assets stay on your machine while Claude only sends and receives structured commands.
4.  **Free and Paid Tiers**: While many features (like Adobe Express) are available on free plans, advanced API access for tools like Photoshop typically requires a paid subscription.

## Why Anthropic chose creative apps first

Most AI providers chase enterprise CRM and ERP integrations. Anthropic’s pivot to creative tools is non-obvious but brilliant for three reasons:

1.  **High Syntax Barrier**: Writing `bpy` (Blender Python) or ExtendScript (Adobe) is notoriously difficult for humans but easy for LLMs. This creates an immediate "aha!" moment that checking a Jira ticket doesn’t.
2.  **Low Risk, High Visibility**: A bug in a generative 3D script is a creative glitch; a bug in a Salesforce integration is a business catastrophe. Creative tools provide a safe sandbox to stress-test MCP in production.
3.  **Synthesizing the Pipeline**: Creative work is rarely done in one app. By winning the "bridge" between Blender and Photoshop, Anthropic positions Claude as the OS for the creative studio, not just another chat box.

```takeaways
- Creative tools have a high syntax barrier (bpy, ExtendScript) that makes LLM assistance immediately valuable while keeping failure risk low.
- A bug in a generative 3D script is a creative glitch; a bug in a CRM integration is a business incident — creative apps are safer early production targets for MCP.
- Positioning Claude as a cross-app bridge is a distribution strategy: the model becomes the interface to the entire creative studio stack, not a single chat feature.
```

This signals that Anthropic view MCP as a **distribution play**. By becoming the default way humans interact with complex, fragmented software suites, they bypass the need for every software vendor to build their own AI UI. For a primer on the protocol itself, see [[course/mcp-from-first-principles-to-production/01-why-mcp-exists]].

---

## Walkthrough: Controlling Blender via MCP


The Blender connector is the most technically transparent of Anthropic's nine creative integrations. Unlike connectors that wrap proprietary APIs, the [Blender MCP server](https://www.anthropic.com/news/claude-for-creative-work) exposes Blender's native Python API (`bpy`) directly to Claude. That means every technique Claude uses here is a real `bpy` pattern you can learn, copy, and extend.

```takeaways
- The Blender MCP server exposes the native `bpy` Python API, so Claude's tool calls are real Blender patterns that execute against the live scene, not a simplified wrapper.
- Claude never touches your filesystem directly — it sends a tool call with Python code, and the local MCP server executes it inside Blender's interpreter.
- Because the connector runs locally, creative assets stay on your machine while only structured commands and results cross the MCP boundary.
```

### How the connection works

Before touching any code, it helps to have a mental model of the data flow.

```
You (natural language)
        │
        ▼
   Claude (reasoning + code generation)
        │   tool_call: execute_python({ code: "..." })
        ▼
   Blender MCP Server (local process, port 9001 by default)
        │   subprocess call via bpy
        ▼
   Blender Python Interpreter
        │   modifies scene graph
        ▼
   Result dict  ──►  back up the chain to Claude  ──►  back to you
```

The MCP server runs locally alongside Blender. Claude never touches your filesystem directly — it sends a `tool_call` with Python code, the server executes it inside Blender's interpreter, and returns the result. This means Claude is working against the **live scene state**, not a static file.

<Callout type="info">
**MCP primer**: The Model Context Protocol is an open standard. The protocol specification itself and its official SDKs are primarily licensed under **Apache License 2.0**, with older contributions retaining the **MIT license** [[source](https://github.com/modelcontextprotocol/typescript-sdk/blob/main/LICENSE)]. It lets AI models call tools with structured inputs and typed outputs. The Blender server implements the MCP tool interface so Claude treats Blender exactly like any other tool in a multi-tool flow. Full spec at [modelcontextprotocol.io](https://modelcontextprotocol.io/).
</Callout>

### Step 1 — Install the Blender MCP connector


1. Open Claude.ai → **Settings → Connectors → Browse**
2. Search for **Blender** and click **Enable**.
3. The connector guide will prompt you to install the companion server package:
   ```bash
   pip install blender-mcp-server
   ```
4. Start Blender (4.x), then start the MCP server from your terminal:
   ```bash
   blender-mcp-server --port 9001
   ```
   You should see: `Blender MCP server running on ws://localhost:9001`.
5. Back in Claude.ai, click **Test connection**. A green checkmark confirms Claude can reach the server.

<Callout type="warning">
**Blender version**: The connector requires Blender 4.0 or later. Blender 3.x uses a different Python version (`3.10`) that is incompatible with `blender-mcp-server`. Run `blender --version` to check.
</Callout>

### Step 2 — Your first tool-use call: query the scene

The safest first call is read-only: ask Claude to describe what's currently in the scene.

<RunPromptCell
  model="claude-sonnet-4-6"
  tools={["blender"]}
  prompt="Using the Blender connector, tell me how many objects are in the current scene and list their names and types."
  expectedOutput="I'll check the current Blender scene for you.\n\n[tool_call: blender.execute_python]\n```python\nimport bpy\nobjects = [(obj.name, obj.type) for obj in bpy.context.scene.objects]\nprint(f\"Object count: {len(objects)}\")\nfor name, typ in objects:\n    print(f\"  {name}: {typ}\")\n```\n\nResult:\nObject count: 3\n  Camera: CAMERA\n  Light: LIGHT\n  Cube: MESH\n\nThe scene contains 3 objects: a default Camera, a Point Light, and the default startup Cube (a MESH type)."
/>

Notice the pattern: Claude wrote `bpy` Python, the MCP server ran it inside Blender, and the stdout came back as the tool result.

<KnowledgeCheck
  questions={[
    {
      question: "When Claude calls the Blender MCP tool, where does the Python code actually execute?",
      answers: [
        "In Claude's cloud infrastructure",
        "In a sandboxed Docker container on your machine",
        "Inside Blender's Python interpreter, against the live scene",
        "In a local Python virtualenv separate from Blender"
      ],
      correct: 2,
      explanation: "The MCP server is a bridge: it receives the code string from Claude and passes it to Blender's embedded Python interpreter via `bpy`."
    }
  ]}
/>

### Step 3 — Generate a procedural wave scene

Now for the main event. Give Claude a creative brief and let it author the full script.

<RunPromptCell
  model="claude-sonnet-4-6"
  tools={["blender"]}
  prompt="I want to create a generative wave pattern in Blender: a 10×10 grid of cubes where each cube's Z-scale is determined by a sine wave based on its distance from the centre. Clear the scene first (keep the camera and light), then build the grid. Name the collection 'WaveGrid'."
  expectedOutput="I'll build that for you. First I'll clear any existing mesh objects, then generate the wave grid.\n\n[tool_call: blender.execute_python]\n```python\nimport bpy\nimport math\n\n# Clear existing meshes (keep camera and light)\nbpy.ops.object.select_all(action='DESELECT')\nfor obj in bpy.context.scene.objects:\n    if obj.type == 'MESH':\n        obj.select_set(True)\nbpy.ops.object.delete()\n\n# Create collection\nwave_coll = bpy.data.collections.new(\"WaveGrid\")\nbpy.context.scene.collection.children.link(wave_coll)\n\nGRID = 10\nSPACING = 1.5\nMAX_HEIGHT = 2.0\n\nfor row in range(GRID):\n    for col in range(GRID):\n        x = (col - GRID / 2) * SPACING\n        y = (row - GRID / 2) * SPACING\n        dist = math.sqrt(x**2 + y**2)\n        z_scale = 0.2 + (MAX_HEIGHT * (0.5 + 0.5 * math.sin(dist - 0)))\n\n        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, 0))\n        obj = bpy.context.active_object\n        obj.name = f\"WaveCube_{row}_{col}\"\n        obj.scale.z = z_scale\n        wave_coll.objects.link(obj)\n        bpy.context.scene.collection.objects.unlink(obj)\n\nprint(f\"WaveGrid built: {GRID*GRID} cubes in collection 'WaveGrid'\")\n```\n\nResult: WaveGrid built: 100 cubes in collection 'WaveGrid'\n\nYour wave scene is ready. You should see a 10×10 grid with cubes rising and falling in concentric rings from the centre."
/>

---

## Walkthrough: Multi-tool pipelines with Adobe for creativity

Adobe for creativity is the broadest integration in Anthropic's creative connector lineup: a broad collection of tools across photo editing, video production, vector illustration, web design, and stock media [[source](https://www.anthropic.com/news/claude-for-creative-work)]. Unlike the Blender connector, the Adobe for creativity connector wraps a collection of heterogeneous application APIs under one MCP interface.

### What requires a paid plan

| Flow | Minimum plan |
|---|---|
| Adobe for creativity Libraries asset management (read/write) | Adobe for creativity Individual (paid) |
| Photoshop, Lightroom, Illustrator Smart APIs | Adobe for creativity Individual (paid) |
| Adobe Express design generation + export | **Free** (Adobe Express free tier) |
| Adobe Firefly image generation via API | Free trial credits |

### Multi-tool flow: locate → edit → export

Each step here is a separate tool call; Claude sequences them automatically based on context.

<RunPromptCell
  model="claude-sonnet-4-6"
  tools={["adobe_creative_cloud"]}
  prompt="Find 'hero-banner.png' in my Adobe for creativity Libraries, apply a 2px Gaussian Blur in Photoshop (use a Smart Object), and export it as a web-optimised JPEG."
  expectedOutput="[tool_call: adobe_creative_cloud.search_library_assets]\n{ \"name\": \"hero-banner.png\" }\n\n[tool_call: adobe_creative_cloud.open_in_photoshop]\n{ \"asset_id\": \"asset_123\" }\n\n[tool_call: adobe_creative_cloud.photoshop_action]\n{ \"action\": \"convert_to_smart_object\" }\n\n[tool_call: adobe_creative_cloud.photoshop_action]\n{ \"action\": \"apply_smart_filter\", \"filter\": \"Gaussian Blur\", \"params\": { \"radius\": 2 } }\n\n[tool_call: adobe_creative_cloud.export_asset]\n{ \"format\": \"jpeg\", \"quality\": 80 }\n\nDone. Your blurred banner has been exported."
/>

<KnowledgeCheck
  questions={[
    {
      question: "Why convert to a Smart Object before applying a filter?",
      answers: [
        "It's required by the API",
        "It's non-destructive, allowing later adjustments",
        "It makes the export faster",
        "It reduces memory usage"
      ],
      correct: 1,
      explanation: "Smart Objects preserve the original pixel data, making the filter a re-editable effect."
    },
    {
      question: "Which Adobe app allows design generation and export on the free tier?",
      answers: ["Photoshop", "Lightroom", "Adobe Express", "Premiere Pro"],
      correct: 2,
      explanation: "Adobe Express offers a permanent free tier that includes design generation and export via the MCP connector."
    }
  ]}
/>

---


## Exploring the other creative connectors

While Blender and Adobe for creativity are the flagship integrations, Anthropic launched a total of nine connectors targeting different creative domains.

### Ableton Live: Automating the manual

The Ableton connector focuses on **documentation and session management**. It allows Claude to read session metadata (track names, clips, device chains) and automate manual tasks like renaming 100+ stems or generating "track notes" from the actual MIDI/Audio data.

*   **Pattern**: Read session → Analyze MIDI → Generate documentation/labels.
*   **Key benefit**: Eliminates the "janitorial" work of professional music production.

### Affinity by Canva: Automating production

The Affinity connector brings Model Context Protocol to professional design apps like Affinity Designer, Photo, and Publisher. Unlike the general Adobe for creativity connector, the Affinity integration focuses on **deep layer manipulation and batch processing**.

*   **Pattern**: Select layers → Apply batch adjustment → Export to Canva.
*   **Key benefit**: Automates the "final 10%" of production work, such as renaming hundreds of layers or adjusting export settings across a multi-page document.

### Autodesk Fusion & SketchUp: CAD for agents

For industrial designers and architects, the Fusion and SketchUp connectors provide a bridge to 3D modelling. Like Blender, these connectors often surface a Python-like command interface, allowing Claude to build complex geometric structures from mathematical descriptions.

### Resolume & Splice: Performance and Samples

*   **Resolume**: Enables live visual performance automation. Claude can trigger clips or adjust effects based on a real-time event log (e.g., "Change the visual intensity when the BPM exceeds 140").
*   **Splice**: Allows Claude to search your local and cloud sample libraries. "Find me all 120bpm techno kicks with a high transient" becomes a tool call instead of a 10-minute manual scroll.

---

## Which connector should you use?

```takeaways
- Integration depth ranges from high (Blender's full Python API, Autodesk's command API) to medium (Adobe's multi-app pipeline, Ableton's metadata layer) — match the connector to the task complexity.
- Ableton and Splice focus on session management and asset discovery rather than direct audio generation, making them useful for documentation and search workflows.
- Resolume connectors target live performance automation, not post-production — clip and effect triggering is the primary use case.
```

| Domain | Tool | Integration Depth | Best for... |
|---|---|---|---|
| **3D / VFX** | Blender | High (Python API) | Generative scenes, proceduralism |
| **Design** | Adobe for creativity | Medium (Multi-app) | Pipelines, batch editing, library management |
| **Design** | Affinity by Canva | Medium (Layer API) | Vector/raster design, precision illustration |
| **CAD** | Autodesk Fusion | High (Command API) | Precision modelling, engineering |
| **Architecture** | SketchUp | Medium (Command API) | Architectural modelling, space planning |
| **Audio** | Ableton Live | Medium (Metadata) | Stem management, documentation |
| **Samples** | Splice | Medium (Search) | Asset discovery |
| **Live Visual** | Resolume Arena | Medium (Clip API) | Live VJ performance, clip triggering |
| **Live Visual** | Resolume Wire | Medium (Patch API) | Generative real-time visuals, effect patching |

---

## Sidebar: Design for resilience from day one

Building for resilience requires understanding the [[course/picking-a-frontier-model-2026-q2/01-dimensions-that-matter]] that ensure your pipeline stays live during provider volatility.

<Callout type="warning">
**Two incidents in the same week.** On April 30 (UTC), 2026, Claude.ai experienced a full availability outage [[source](https://status.claude.com/incidents/2gf1jpyty350)]. The same week, a billing routing bug in Claude Code (the "HERMES.md incident") highlighted the risks of single-provider dependency [[source](https://news.ycombinator.com/item?id=47952722)].

**Lesson**: Claude is an excellent first-choice model, but no single provider has 100% uptime. If your tool-use pipeline depends entirely on one provider, one outage takes your whole workflow offline.
</Callout>

### The failover pattern

Route your tool-use calls through a provider-agnostic fallback chain. The Vercel AI SDK has no built-in `fallbackModels` option — fallback must be implemented explicitly, either at the gateway layer (OpenRouter's route configuration) or in your own code:

```typescript
import { createAnthropic } from "@ai-sdk/anthropic";
import { createOpenAI } from "@ai-sdk/openai";
import { generateText } from "ai";
import type { Tool } from "ai";

const providers = [
  createAnthropic()("claude-sonnet-4-6"),
  createOpenAI()("gpt-4o"),
];

async function resilientToolCall(
  tools: Record<string, Tool>,
  prompt: string,
) {
  for (let i = 0; i < providers.length; i++) {
    try {
      return await generateText({ model: providers[i], tools, prompt });
    } catch (err) {
      if (i === providers.length - 1) throw err;
      console.warn(`Provider ${i} failed, trying fallback:`, err);
    }
  }
}
```

When Claude is unavailable, the loop retries on the next provider. Your tool definitions work unchanged across providers because they are MCP-standard. For server hardening tips, see [[course/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability]].

<KnowledgeCheck
  questions={[
    {
      question: "What is the primary benefit of using a gateway like OpenRouter for creative MCP pipelines?",
      answers: [
        "It makes tool calls faster",
        "It provides automatic failover to secondary providers if Claude is down",
        "It eliminates the need for an Adobe subscription",
        "It converts Python to JavaScript automatically"
      ],
      correct: 1,
      explanation: "Gateways allow you to define fallback models so your production pipeline stays live even during single-provider outages."
    }
  ]}
/>

---

## Hands-on exercise

**Goal**: Build a product-launch kit using the Adobe for creativity connector.

1. Find the three most recently added assets in your Adobe for creativity Libraries.
2. For each image, export a half-size JPEG at 75% quality.
3. Save all exports to a new library named `"Launch Kit — [today's date]"`.
4. Return a summary table of the file size reductions.

---

## Ship your creative pipeline: Identify, connect, and automate

The creative connectors represent more than just new features; they are a blueprint for agentic tool-use. 

Instead of just observing your scene state, use Claude to **actively generate, animate, and export** assets. By using consistent naming conventions (like `'WaveCube_'`) across your tool calls, you build **cumulative context** that allows Claude to target specific objects and layers precisely. Finally, remember to **prioritize resilience** by routing your MCP pipelines through gateways like OpenRouter to maintain uptime during provider outages.

By mastering these nine connectors, you move from simple prompt engineering to architecting a fully automated, cross-platform digital production pipeline.

---

## References

[1] Anthropic — Claude for Creative Work — https://www.anthropic.com/news/claude-for-creative-work · retrieved 2026-04-30
[2] Model Context Protocol Spec — https://modelcontextprotocol.io/ · retrieved 2026-04-30
[3] Blender Python API Overview — https://raw.githubusercontent.com/blender/blender/main/doc/python_api/rst/info_overview.rst · retrieved 2026-04-30
[4] Hacker News — Claude.ai and API unavailable [fixed] (outage discussion) — https://news.ycombinator.com/item?id=47956895 · retrieved 2026-04-30
[5] Claude Status — April 2026 outage — https://status.claude.com/incidents/2gf1jpyty350 · retrieved 2026-04-30
[6] Hacker News — Claude Code HERMES.md billing bug — https://news.ycombinator.com/item?id=47952722 · retrieved 2026-04-30
