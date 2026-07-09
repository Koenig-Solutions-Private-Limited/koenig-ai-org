---
course_slug: gemini-enterprise-agents
chapter_num: 1
type: voiceover-script
source_chapter: vault/courses/gemini-enterprise-agents/01-what-gemini-enterprise-agent-platform-is-and-isnt.md
audio_file: vault/courses/gemini-enterprise-agents/01-what-gemini-enterprise-agent-platform-is-and-isnt-audio.mp3
duration_sec: 0
word_count: 2569
speaker: notebooklm-dual-narrator
script_version: R2
script_rewritten_at: 2026-06-13
audio_status: pending-regen
---

# Voiceover Script: Chapter 1 — Map the Platform Before You Build

[HOST] Most engineering teams I talk to make the same mistake when they first touch Google's Gemini enterprise agent stack. They start with the model. They get it working locally, they add some tools, things look great — and then six weeks later they're doing a full re-architecture because the pieces don't fit together the way they assumed. Today we're going to prevent that.

[GUEST] Right, and I think the reason that happens is that the Gemini enterprise stack isn't one thing — it's five distinct components, each with a completely different job. And if you don't know which is which before you start building, you end up building on the wrong layer.

[HOST] Exactly. So let's do what the chapter title says: map the platform before we build. There are five components you need to be able to name and differentiate. Let's go through them one by one.

[GUEST] Alright, first one.

[HOST] First: Gemini Enterprise app. This is the workforce-facing surface. It's the thing employees actually touch — the chat interface, the workflow interface, the place where a knowledge worker files an expense report or routes a legal question. The app abstracts everything below it completely. The person using it doesn't know or care what's running underneath.

[GUEST] So this is pure user interface territory.

[HOST] Entirely. No code, no configuration from the end user's perspective. Now second component: Agent Platform. This is the developer platform on Google Cloud — the control plane. When a practitioner says "the GEAP console," they mean Agent Platform. It's where you build, scale, govern, and optimize agents. The dashboards, the configuration, the governance tooling — all of that lives here.

[GUEST] And I want to flag something because this trips people up constantly: Agent Platform is not where your agents run. It's the control plane *above* the runtime.

[HOST] That distinction is so important and we're going to come back to it. Because the third component — Vertex AI Agent Engine — that is where your agents actually execute. Engine is the managed runtime. It handles session persistence, execution traces, cold starts, scaling — all the infrastructure concerns. When you deploy an ADK agent, it lives in Agent Engine. Not in Agent Platform. Agent Platform manages it; Agent Engine runs it.

[GUEST] So Agent Platform is the dashboard and configuration layer, Agent Engine is the execution environment. Different jobs, different moments in your workflow.

[HOST] Exactly. Now fourth component: ADK — the Agent Development Kit. This is the open-source, code-first framework. Python, TypeScript, Go, Java. ADK is where you write agent logic. You define how your agent selects tools, manages conversation turns, delegates to sub-agents. And critically — ADK is the only layer in this entire stack that you write yourself. Everything else is managed infrastructure.

[GUEST] That's an interesting way to frame it. One layer you write, everything else is managed service.

[HOST] That's the core architectural pattern. And the fifth component is A2A — the Agent-to-Agent protocol. This is the cross-agent protocol layer. Where ADK sub-agents run inside a single process and share state directly, A2A spans process boundaries. It lets agents built by completely different teams, deployed on completely different services, exchange tasks and artifacts through a standard HTTP interface.

[GUEST] We're going to spend a lot of time on A2A in a few minutes because I think it's the one that surprises people the most. But before we get there — there's actually a sixth component you mentioned in the chapter.

[HOST] Right — MCP, the Model Context Protocol. MCP is the tool-connectivity layer. Think of it this way: A2A routes work *between agents*, while MCP connects agents to external tools and data sources. Any MCP-compatible server exposes its capabilities to any MCP-compatible client, regardless of who built either. So A2A is agent-to-agent coordination; MCP is agent-to-tool connectivity. Different protocols, different problems.

[GUEST] Okay so let's do a quick sanity check here. We've got Gemini Enterprise app as the workforce surface, Agent Platform as the developer control plane, Vertex AI Agent Engine as the managed runtime, ADK as the code framework, A2A as the cross-agent protocol, and MCP as the tool-connectivity layer. Six components total.

[HOST] And the way I like to think about it is that each one owns a completely different slice of your system. User access, developer control plane, managed runtime, agent logic, cross-agent coordination, tool connectivity. Those are six different problems that require six different solutions.

[GUEST] Now here's what I think is the most clarifying lens for understanding when you reach for which of these: lifecycle boundaries. The chapter breaks this into four time horizons.

[HOST] This is my favorite part of the chapter honestly, because it makes the five-component map concrete in a way that the component list alone doesn't. So let's walk through the four boundaries. Build-time: this is when you're writing and testing agent logic. ADK is your primary tool, plus Agent Platform tooling for configuration. This is where you spend most of your early weeks as a practitioner — writing tools as Python functions, configuring models, running local tests.

[GUEST] And build-time is the only boundary where you're actively writing code.

[HOST] Right. Everything else is about what happens once you've written it. Run-time is the second boundary — this is when a live agent session is executing. Vertex AI Agent Engine is the primary layer here. Engine manages your active sessions, handles state persistence, runs your traces. When it's working well, run-time is invisible. You're focused on your ADK logic; Engine handles the infrastructure underneath.

[GUEST] Third boundary — route-time. This one I think is where most production complexity actually lives.

[HOST] Absolutely. Route-time is when tasks are being dispatched between agents. And here you have a choice: if you're in a single deployment with a single team, you use ADK sub-agents. That's in-process delegation — one Python process calls another, state is shared directly, no network hop. Fast, simple. But if your agents span team boundaries, separate codebases, separate deployments — that's where A2A comes in. A2A routing at route-time.

[GUEST] And the fourth boundary?

[HOST] Operate-time. This is continuous — it never stops. Observability, evaluation, cost tracking, model lifecycle updates, audit logs. All of that surfaces in Agent Platform's dashboards. When something goes wrong in production, you look in Agent Engine traces first to see what happened in the runtime, and then in Agent Platform observability dashboards to understand the governance and performance picture.

[GUEST] So the lifecycle table is really a decision framework. Which layer am I in, what time boundary am I at, therefore which component do I reach for?

[HOST] Exactly. And the single most dangerous confusion in the whole stack is conflating Agent Platform with Vertex AI Agent Engine. They're not interchangeable. Agent Platform is the developer control plane — dashboards, config, governance. Agent Engine is the execution runtime. Session state lives in Agent Engine at run-time. When a deployed agent fails to resume a conversation after a timeout, you go to Agent Engine traces first, not Agent Platform.

[GUEST] Alright, let's go deeper on A2A, because I think this is where the architecture gets interesting. You mentioned that in-process ADK sub-agents exist — when does A2A become necessary?

[HOST] So in-process sub-agents are simple and they're fast. One Python process delegates to another, state passes directly. If you have a single team shipping a single application, in-process is the right choice. No network overhead, no protocol to implement.

[GUEST] But production enterprise environments almost never look like that.

[HOST] Almost never. Think about a real enterprise scenario: you have an HR agent built by the People team. You have a Finance agent built by the Finance team. Those two agents will probably never share a codebase. They might be deployed in different cloud regions. They have different deployment lifecycles. In-process calls cannot cross those boundaries — full stop.

[GUEST] So A2A is the solution.

[HOST] A2A defines a standard HTTP task lifecycle. A calling agent posts a task to an A2A endpoint. The receiving agent processes it asynchronously. The result — including any artifacts — flows back through the same protocol. And here's what this unlocks: neither team needs to know how the other's agent is implemented. They only need to know the A2A interface contract. The People team doesn't need to understand the Finance team's deployment. The Finance team doesn't need to understand the People team's data model.

[GUEST] So deployment becomes decoupled from coordination.

[HOST] Exactly. And at scale — when you have a multi-team, multi-department agent network — A2A is what makes coordination possible without creating a dependency nightmare. It makes agents first-class participants in enterprise workflows without requiring a shared runtime or shared codebase.

[GUEST] There's also a distinction in the chapter I want to make sure we highlight: workforce agents versus developer-built agents. Because those are genuinely different things.

[HOST] They are, and product marketing often blurs them. Workforce agents are delivered through Gemini Enterprise app. A knowledge worker uses them without writing code, without knowing what's running underneath. These are configured — often by Power Users or IT admins — through the app's interface.

[GUEST] Developer-built agents are the other path.

[HOST] Developer-built agents are created in ADK, deployed on Vertex AI Agent Engine, managed through Agent Platform. They can surface inside Gemini Enterprise app as well — but they originate in code, not in configuration. The developer controls the tool set, the routing logic, the deployment configuration.

[GUEST] And the reason this distinction matters operationally is ownership. Who monitors, who debugs, who pays the bill — that answer is completely different depending on which type of agent you're dealing with.

[HOST] That's right. Workforce agents are consumed; developer-built agents are shipped. Mixing up those responsibilities is a real source of production incidents on multi-team platforms. Someone gets paged at two in the morning and they have no idea who owns the thing that's failing.

[GUEST] Now, before we get to the hands-on exercise — the chapter has a capability map that I think is worth walking through, because it directly informs what you're about to draw in the exercise.

[HOST] Right. So there are four enterprise capabilities the chapter maps to specific components. First: enterprise data access. That lives in ADK tools plus Gemini Enterprise connectors. Permissions are enforced at the tool layer. Each specialist agent only accesses its authorized data source.

[GUEST] Second: agent discovery.

[HOST] Agent discovery lives in A2A Agent Cards. An Agent Card is A2A's discovery document — a machine-readable JSON file that advertises a remote agent's capabilities, skills, and endpoint address. Before routing a task, the calling agent reads the target's Agent Card.

[GUEST] And an important caveat here — discovery is not authorization.

[HOST] Critically important. Reading an Agent Card grants no access. That gate is enforced by the tool-layer permissions and GCP IAM policies attached to the receiving agent's deployment. You can discover an agent exists; you can't necessarily talk to it.

[GUEST] Third capability: task routing.

[HOST] Task routing is ADK sub-agents for in-process scenarios — same deployment, shared state. A2A HTTP task lifecycle for cross-process scenarios — separate teams, separate deployments. The choice is driven by deployment boundaries.

[GUEST] And fourth: audit logs.

[HOST] Audit logs live in two places for a reason. Vertex AI Agent Engine execution traces tell you what happened inside a session — which tools fired, what inputs and outputs were. Agent Platform and GCP IAM policy logs tell you who was permitted to do it. Missing either half leaves a compliance gap. Enterprise compliance reviews require both: the evidence of what happened and the evidence of who authorized it.

[GUEST] Alright — hands-on exercise. This is the practical test of whether you can actually map all of this.

[HOST] The exercise in the chapter asks you to draw the component map for an enterprise intake assistant that triages HR, finance, and legal requests. Three specialist agents, one intake routing agent. And you need to label six specific things.

[GUEST] Walk us through them.

[HOST] Number one: user entry. Where does the employee submit the request? That's Gemini Enterprise app — the workforce-facing surface. Number two: agent logic. Which framework processes the intent? That's ADK — it's where the intake agent's routing logic and the specialist agents' logic are written. Number three: session state. Where is conversation context persisted between turns? That's Vertex AI Agent Engine at run-time — it provides managed session persistence.

[GUEST] Number four?

[HOST] Number four: cross-agent routing. How does the intake agent hand off to the HR, Finance, or Legal specialist agent? And here is where the exercise forces you to make the key architectural choice: are these agents on the same team with the same codebase? Then in-process ADK delegation. Are they owned by different teams with separate codebases and separate deployments? Then A2A routing. The answer changes the architecture entirely.

[GUEST] Number five and six?

[HOST] Number five: external tool calls. How do agents connect to the HRIS system, the ERP, the case management platform? That's MCP — tool connectivity. Each specialist agent connects to its authorized data source through MCP-compatible tooling. And number six: audit evidence. Where is the record of every agent action stored? Agent Engine execution traces for what happened, plus Agent Platform and GCP IAM policy logs for who authorized it. Both required.

[GUEST] The success criteria in the chapter say you need all six elements labeled with the correct component, and specifically that the cross-agent routing label distinguishes between in-process ADK delegation and A2A routing.

[HOST] That distinction is the whole point. If you can draw that exercise correctly, you've internalized the five-component map in a way that actually transfers to production decisions.

[GUEST] So let's summarize what we've covered. Five components: Gemini Enterprise app is the workforce interface, Agent Platform is the developer control plane, Vertex AI Agent Engine is the managed runtime, ADK is the code framework you write, A2A is the cross-agent protocol for multi-team coordination, and MCP handles tool connectivity.

[HOST] Four lifecycle boundaries: build-time is ADK and Agent Platform tooling, run-time is Agent Engine managing live sessions, route-time is in-process ADK or cross-process A2A, and operate-time is Agent Platform observability and evaluation — and it's continuous.

[GUEST] The agent-to-agent distinction: in-process ADK sub-agents for single-team deployments, A2A for agents that cross team, codebase, or deployment boundaries.

[HOST] Workforce agents versus developer-built agents: different entry points, different ownership, different incident response chains. And audit logs live in two places — execution traces in Agent Engine, policy logs in Agent Platform and GCP IAM — and you need both for enterprise compliance.

[GUEST] What's next in the course?

[HOST] Chapter two gets hands-on. You'll install ADK, define a Python function as a tool, wire it into an agent, and add session persistence that survives process restarts. By the end of chapter two you'll have a working agent that remembers your last session — even after the process shuts down and restarts. That's where the platform starts to click.

[GUEST] Looking forward to it.

[HOST] Do the exercise. Draw the component map for the intake assistant before you move on. It's six labeled elements — that's the checkpoint that tells you whether the map is actually in your head or just in the notes.
