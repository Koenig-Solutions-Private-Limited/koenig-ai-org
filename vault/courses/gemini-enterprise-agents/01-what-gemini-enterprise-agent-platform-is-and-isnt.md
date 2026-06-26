---
chapter_num: 1
title: "Map the Platform Before You Build"
course_slug: gemini-enterprise-agents
prerequisites_chapters: []
duration_min: 40
reading_time_min: 40
status: draft-for-review
author: "Koenig AI Academy"
content_type: course-chapter
vendor_tag: google
learning_objectives:
  - "Distinguish Gemini Enterprise app, Agent Platform, Vertex AI Agent Engine, ADK, and A2A by responsibility"
  - "Draw the build-time, run-time, route-time, and operate-time boundaries in a Gemini agent system"
  - "Identify where enterprise data access, agent discovery, task routing, and audit logs belong"
  - "Explain why a production agent platform is more than a model endpoint plus tools"
sources:
  - https://blog.google/innovation-and-ai/infrastructure-and-cloud/google-cloud/gemini-enterprise-agent-platform/
  - https://docs.cloud.google.com/gemini/enterprise/docs
  - https://cloud.google.com/gemini-enterprise/agents
  - https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview
  - https://google.github.io/adk-docs/get-started/about/
  - https://a2a-protocol.org/latest/specification/
owns:
  - "Gemini Enterprise app — the workforce-facing agentic surface"
  - "Agent Platform — the developer platform (build, scale, govern, optimize)"
  - "Vertex AI Agent Engine — the managed runtime where deployable agent apps run"
  - "ADK — the code-first framework (Python/TypeScript) for agent logic"
  - "A2A — the cross-agent protocol layer for task-based interoperability"
  - "MCP — tool connectivity protocol"
  - "lifecycle boundaries: build-time, run-time, route-time, operate-time"
  - "workforce agent vs developer-built agent distinction"
defers_to:
  - "ADK hands-on code → ch2"
  - "routing patterns and SequentialAgent → ch3"
  - "A2A task lifecycle and task states → ch4"
  - "security and IAM → ch5"
quiz_topics:
  - "Which layer is the workforce-facing app vs the developer platform?"
  - "Where does managed session state live (Agent Platform vs Vertex AI Agent Engine)?"
  - "What does A2A add that in-process ADK sub-agents cannot provide?"
  - "Name the four lifecycle boundary types and which system operates at each"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which component is the workforce-facing surface where employees interact with agents?"
    options:
      - "Agent Platform — the developer control plane on Google Cloud"
      - "Vertex AI Agent Engine — the managed runtime for deployed agents"
      - "Gemini Enterprise app — the agentic surface for knowledge workers"
      - "ADK — the code-first framework for agent logic"
    correct_idx: 2
    explanation: "Gemini Enterprise app is the interface employees use for daily tasks. Agent Platform is the developer platform (build, scale, govern, optimize). Workforce agents are consumed through the app; developer-built agents are shipped through Agent Platform."
    section_anchor: the-five-components
  - question: "A deployed agent needs to resume a user's conversation after a timeout. Which component manages session state?"
    options:
      - "ADK — it persists session state inside the agent process"
      - "Agent Platform — it stores state in the developer control plane"
      - "Vertex AI Agent Engine — it provides managed session persistence at runtime"
      - "Gemini Enterprise app — it holds session state at the workforce layer"
    correct_idx: 2
    explanation: "Vertex AI Agent Engine is the run-time layer: it deploys agent apps and manages session state. Agent Platform is the control plane (config, governance), not the execution runtime. ADK defines session APIs but does not itself persist state outside of local runs."
    section_anchor: four-lifecycle-boundaries
  - question: "An HR agent and a Finance agent are owned by separate teams with separate codebases. Which mechanism lets them exchange tasks at runtime?"
    options:
      - "In-process ADK sub-agents — one Python process delegates to another"
      - "MCP — the tool-connectivity layer that links agents to external services"
      - "A2A — the cross-agent protocol routes tasks across deployment boundaries"
      - "Agent Platform registry — agents discover each other through a shared catalogue"
    correct_idx: 2
    explanation: "A2A exists for cross-team, cross-boundary agent coordination. In-process ADK sub-agents run in the same process and cannot span independent deployments. MCP connects agents to external tools, not to other agents."
    section_anchor: a2a-what-in-process-calls-cannot-do
  - question: "Which lifecycle boundary is active when Vertex AI Agent Engine executes a live session?"
    options:
      - "Build-time — agent logic is being written and tools configured"
      - "Route-time — ADK and A2A dispatch tasks between independently deployed agents"
      - "Operate-time — observability, evaluation, and cost tracking are in progress"
      - "Run-time — Agent Engine manages the active execution and session state"
    correct_idx: 3
    explanation: "Run-time is when Agent Engine operates: deploying agent apps, managing sessions, and tracing execution. Build-time involves ADK and Agent Platform tooling. Route-time covers in-process ADK delegation and A2A cross-process routing. Operate-time covers observability and evaluation in Agent Platform."
    section_anchor: four-lifecycle-boundaries
---

# Map the Platform Before You Build

Most engineering teams start with the model and add infrastructure when things break. On Google Cloud, that path leads to re-architecting before you reach production. The Gemini enterprise agent stack has five distinct components, each with a different job. Getting them straight on day one — which layer runs the agent, which layer routes tasks, which protocol crosses team boundaries — is the difference between a platform that grows with you and one you outgrow before launch.

## The five components

The platform comprises five components that together cover user access, agent logic, managed execution, cross-agent coordination, and tool connectivity. Each owns a different slice of your system.

**Gemini Enterprise app** is the workforce-facing surface. Employees interact here — it is the chat, workflow, and task interface that knowledge workers touch daily. The app abstracts everything below it; someone filing an expense report does not need to know what runs the agent.

**Agent Platform** is the developer platform on Google Cloud: the control plane where you build, scale, govern, and optimize agents. When a practitioner says "the GEAP console," they mean Agent Platform. It is the management layer that sits above the runtime, not the runtime itself. The [Gemini Enterprise Agent Platform announcement](https://blog.google/innovation-and-ai/infrastructure-and-cloud/google-cloud/gemini-enterprise-agent-platform/) describes it as the single surface consolidating Google Cloud's enterprise AI capabilities.

**Vertex AI Agent Engine** is the managed runtime. This is where deployable agent apps actually execute. Engine handles session persistence, traces, cold starts, and managed execution at scale. When your ADK agent is deployed, it lives in Agent Engine, not in Agent Platform. The [Agent Engine overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) describes it as a fully managed service — you supply the agent code, Agent Engine supplies the infrastructure.

**ADK (Agent Development Kit)** is the open-source, code-first framework — Python and TypeScript — for writing agent logic. ADK defines how an agent selects tools, manages conversation turns, and delegates to sub-agents. It is the only layer in this stack you write yourself. [ADK documentation](https://google.github.io/adk-docs/get-started/about/) covers installation and the session-and-tool primitives this course builds on.

**A2A (Agent-to-Agent protocol)** is the cross-agent protocol layer. Where ADK sub-agents run inside a single process and share state directly, A2A spans process boundaries: it lets agents built by different teams, deployed on different services, exchange tasks and artifacts through a standard HTTP interface.

**MCP (Model Context Protocol)** is the tool-connectivity layer. Where A2A routes work between agents, MCP connects agents to external tools and data sources — any MCP-compatible server exposes its capabilities to any MCP-compatible client, regardless of who built either.

<KnowledgeCheck question="Which component is the workforce-facing surface where employees interact with agents?" options={["Agent Platform — the developer control plane on Google Cloud", "Vertex AI Agent Engine — the managed runtime for deployed agents", "Gemini Enterprise app — the agentic surface for knowledge workers", "ADK — the code-first framework for agent logic"]} correctIdx={2} explanation="Gemini Enterprise app is the interface employees use for daily tasks. Agent Platform is the developer platform (build, scale, govern, optimize). Workforce agents are consumed through the app; developer-built agents are shipped through Agent Platform." />

```takeaways
- Gemini Enterprise app, Agent Platform, Vertex AI Agent Engine, ADK, A2A, and MCP each own a distinct slice: user access, developer control plane, managed runtime, agent logic, cross-agent coordination, and tool connectivity respectively.
- Agent Platform is the developer control plane (config, governance, optimization); Vertex AI Agent Engine is the execution runtime where deployed agent apps actually run — the two are not interchangeable.
- MCP connects agents to external tools and data sources; A2A routes tasks between independently deployed agents across process or team boundaries.
```

## Four lifecycle boundaries

The components do not all act at the same moment. Framing the platform through four time horizons reveals which layer you reach for when:

| Boundary | When it is active | Primary layer |
|---|---|---|
| **Build-time** | Writing and testing agent logic | ADK, Agent Platform tooling |
| **Run-time** | Executing a live agent session | Vertex AI Agent Engine |
| **Route-time** | Dispatching tasks between agents | ADK (in-process) + A2A (cross-process) |
| **Operate-time** | Monitoring, evaluating, updating | Agent Platform (observability, evaluation, cost) |

Build-time is where you spend most early weeks: writing tools in ADK, configuring models, running local tests. Run-time is invisible when it works — Agent Engine manages sessions and traces while you focus on logic. Route-time is where most production complexity lives: deciding whether in-process ADK sub-agents or cross-process A2A routing is right for a given workflow. Operate-time is continuous: audit logs, model lifecycle changes, cost spikes, and eval regressions all surface here.

<Callout type="info">
A common mistake is conflating Agent Platform with Vertex AI Agent Engine. Agent Platform is the developer control plane — dashboards, config, governance. Agent Engine is the execution runtime. Session state lives in Agent Engine at run-time, not in Agent Platform. When something fails in production, you look in Agent Engine traces first, then in Agent Platform observability dashboards.
</Callout>

<KnowledgeCheck question="A deployed agent needs to resume a user's conversation after a timeout. Which component manages session state?" options={["ADK — it persists session state inside the agent process", "Agent Platform — it stores state in the developer control plane", "Vertex AI Agent Engine — it provides managed session persistence at runtime", "Gemini Enterprise app — it holds session state at the workforce layer"]} correctIdx={2} explanation="Vertex AI Agent Engine is the run-time layer: it deploys agent apps and manages session state. Agent Platform is the control plane (config, governance), not the execution runtime. ADK defines session APIs but does not itself persist state outside of local runs." />

```takeaways
- The platform operates at four time horizons: build-time (ADK + Agent Platform tooling), run-time (Vertex AI Agent Engine manages sessions and traces), route-time (in-process ADK or cross-process A2A), and operate-time (Agent Platform observability, evaluation, and cost tracking).
- Session state lives in Vertex AI Agent Engine at run-time, not in Agent Platform; when a production agent fails to resume a conversation, check Agent Engine traces first, then Agent Platform dashboards.
- Route-time is where most production complexity concentrates: in-process ADK sub-agents suit single-team deployments; A2A routing is required when agents span separate codebases or deployment boundaries.
```

## A2A — what in-process calls cannot do

In-process ADK sub-agents are simple and fast: one Python process calls another, passing state directly. For a single team shipping a single application, this is the right choice.

A2A exists for the case where that assumption breaks. An HR agent built by the People team and a Finance agent built by the Finance team may never share a codebase, a deployment boundary, or a cloud region. In-process calls cannot cross these boundaries.

A2A defines a standard HTTP task lifecycle: a calling agent posts a task to an A2A endpoint, the receiving agent processes it asynchronously, and the result — including any artifacts — flows back through the same protocol. This decouples deployment from coordination. Neither team needs to know how the other's agent is implemented, only the A2A interface contract. The [A2A specification](https://a2a-protocol.org/latest/specification/) defines the full task-state machine and wire format; the implementation details belong to [[gemini-enterprise-agents/04-comparing-to-claude-agent-sdk-and-cloudflare-agents]].

The practical effect: A2A makes agents first-class participants in enterprise workflows without requiring a shared runtime or shared codebase. For multi-team, multi-department agent networks, it is the protocol that makes coordination at scale possible.

## Workforce agent vs developer-built agent

The five-component map clarifies a distinction that product marketing often blurs.

**Workforce agents** are delivered through Gemini Enterprise app. A knowledge worker uses them without writing code or knowing what runs beneath. These agents are configured — often by Power Users or IT admins — through the app's interface.

**Developer-built agents** are created in ADK, deployed on Vertex AI Agent Engine, and managed through Agent Platform. They can surface inside Gemini Enterprise app as well, but they originate in code. The developer controls the tool set, the routing logic, and the deployment configuration.

The boundary matters for ownership, budgeting, and incident response. Workforce agents are consumed; developer-built agents are shipped. Mixing up responsibility — who monitors, who debugs, who pays the bill — is a common source of production incidents on multi-team platforms.

```takeaways
- Workforce agents are configured through Gemini Enterprise app and consumed by knowledge workers without code; developer-built agents are authored in ADK, deployed on Vertex AI Agent Engine, and managed through Agent Platform.
- The ownership boundary is operational: who monitors, who debugs, and who bears the cost differs depending on whether the agent is a workforce agent or a developer-built agent.
- A developer-built agent can surface inside Gemini Enterprise app, but the team that wrote it owns its tool set, routing logic, and deployment configuration.
```

## Hands-on exercise

**Component map for an HR / finance / legal intake assistant**

On paper or in a diagramming tool, draw the component map for an enterprise intake assistant that triages HR, finance, and legal requests. Label which layer owns each of the following:

1. **User entry** — where the employee submits the request
2. **Agent logic** — which framework processes the intent
3. **Session state** — where conversation context is persisted between turns
4. **Cross-agent routing** — how the intake agent hands off to the HR, Finance, or Legal specialist agent
5. **External tool calls** — how agents connect to HRIS, ERP, or case management systems
6. **Audit evidence** — where the record of every agent action is stored

**Success criteria:** All six elements labelled with the correct component from the five-component map. The cross-agent routing label distinguishes between in-process ADK delegation (single team, single deployment) and A2A routing (multi-team or cross-service boundary).

---

Next up: hands-on ADK code — build a working agent from scratch, add tools, and wire in session state that survives process restarts.

See [[gemini-enterprise-agents/02-hello-world-agent-tool-state-persistence]].
