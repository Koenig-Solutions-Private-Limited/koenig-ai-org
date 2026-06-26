---
chapter_num: 1
title: "Map the Platform Before You Build"
course_slug: gemini-enterprise-agents
chapter_slug: ch01-map-the-platform
prerequisites_chapters: []
duration_min: 40
reading_time_min: 40
status: outline-draft
author: "Koenig AI Academy"
content_type: course-chapter
vendor_tag: google
learning_objectives:
  - "Distinguish Gemini Enterprise app, Agent Platform, Vertex AI Agent Engine, ADK, and A2A by responsibility"
  - "Draw the build-time, run-time, route-time, and operate-time boundaries in a Gemini agent system"
  - "Identify where enterprise data access, agent discovery, task routing, and audit logs belong"
  - "Explain why a production agent platform is more than a model endpoint plus tools"
key_concepts:
  - "Gemini Enterprise app"
  - "Agent Platform"
  - "Vertex AI Agent Engine"
  - "ADK (Agent Development Kit)"
  - "A2A (Agent-to-Agent protocol)"
  - "MCP (Model Context Protocol)"
  - "lifecycle boundary"
  - "build-time vs run-time vs route-time vs operate-time"
  - "workforce agent vs developer-built agent"
sources:
  - https://blog.google/innovation-and-ai/infrastructure-and-cloud/google-cloud/gemini-enterprise-agent-platform/
  - https://docs.cloud.google.com/gemini/enterprise/docs
  - https://cloud.google.com/gemini-enterprise/agents
  - https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview
  - https://google.github.io/adk-docs/get-started/about/
  - https://google-a2a.github.io/A2A/specification/
hands_on_exercise: "Draw a component map for an enterprise intake assistant that triages HR, finance, and legal requests. Label which layer owns user entry, agent logic, session state, cross-agent routing, external tool calls, and audit evidence."
---

# Map the Platform Before You Build

Most engineering teams start with the model and add infrastructure when things break. On Google Cloud, that path leads to re-architecting before you reach production. The Gemini enterprise agent stack has five distinct components, each with a different job. Getting them straight on day one — which layer runs the agent, which layer routes tasks, which protocol crosses team boundaries — is the difference between a platform that grows with you and one you outgrow before launch.

## The Five-Component Map

The platform comprises five components (plus MCP) that together cover user access, agent logic, managed execution, cross-agent coordination, and tool connectivity. Each owns a different slice of your system.

**Gemini Enterprise app** is the workforce-facing surface. Employees interact here — it is the chat, workflow, and task interface that knowledge workers touch daily. The app abstracts everything below it; someone filing an expense report does not need to know what runs the agent. This is distinct from Agent Platform, which is the developer control plane.

**Agent Platform** (Gemini Enterprise Agent Platform) is the developer platform on Google Cloud: the control plane where you build, scale, govern, and optimize agents. Announced at Google Cloud Next '26, it "brings the model building and tuning services of Vertex AI together with new features for agent integration, security, DevOps and more." It is the management layer that sits above the runtime — not the runtime itself.

**Vertex AI Agent Engine** is the managed runtime. This is where deployable agent apps actually execute. Agent Engine handles session persistence, traces, cold starts, and managed execution at scale. When your ADK agent is deployed, it lives in Agent Engine, not in Agent Platform. Fully managed service: you supply the agent code, Agent Engine supplies the infrastructure.

**ADK (Agent Development Kit)** is the open-source, code-first framework — Python, TypeScript, Go, and Java — for writing agent logic. ADK defines how an agent selects tools, manages conversation turns, and delegates to sub-agents. It is the only layer in this stack you write yourself. Enterprise-grade, multi-language, designed for production deployment via Agent Engine.

**A2A (Agent-to-Agent protocol)** is the cross-agent protocol layer. Where ADK sub-agents run inside a single process and share state directly, A2A spans process boundaries: it lets agents built by different teams, deployed on different services, exchange tasks and artifacts through a standard HTTP interface. A2A adds task lifecycle (submitted → working → input-required → completed) that in-process calls cannot provide.

**MCP (Model Context Protocol)** is the tool-connectivity layer. Where A2A routes work between agents, MCP connects agents to external tools and data sources. Any MCP-compatible server exposes its capabilities to any MCP-compatible client.

Key distinction: Agent Platform is the developer control plane (dashboards, config, governance, lifecycle management). Vertex AI Agent Engine is the execution runtime (live sessions, session state, traces). These are NOT interchangeable — session state lives in Agent Engine at run-time, not in Agent Platform.

## Build-Time vs Run-Time vs Route-Time vs Operate-Time Boundaries

The components do not all act at the same moment. Framing the platform through four time horizons reveals which layer you reach for when:

| Boundary | When it is active | Primary layer | What lives here |
|---|---|---|---|
| Build-time | Writing and testing agent logic | ADK, Agent Platform tooling | Tool definitions, agent instructions, test scaffolds, deployment packages |
| Run-time | Executing a live agent session | Vertex AI Agent Engine | Session state, traces, cold start management, live model calls |
| Route-time | Dispatching tasks between agents | ADK (in-process) + A2A (cross-process) | Sub-agent delegation, task state, artifact passing, cross-team routing |
| Operate-time | Monitoring, evaluating, updating | Agent Platform observability + cost | Audit logs, eval results, cost budgets, model lifecycle, rollback |

Build-time is where you spend most early weeks: writing tools in ADK, configuring models, running local tests. Run-time is invisible when it works — Agent Engine manages sessions and traces. Route-time is where most production complexity lives: deciding whether in-process ADK sub-agents or cross-process A2A routing is right for a given workflow. Operate-time is continuous: audit logs, model lifecycle changes, cost spikes, and eval regressions all surface here.

## Where Enterprise Capabilities Live

For enterprise deployments, knowing which layer owns critical capabilities prevents architectural mistakes:

**Enterprise data access**: Retrieved through ADK tools or Gemini Enterprise connectors. Permission boundaries are enforced at the tool layer — each specialist agent accesses only its authorized data source.

**Agent discovery**: Agent Cards (A2A) publish agent capabilities so other agents can find and invoke them. Discovery is a route-time concern. Discovery does NOT equal authorization.

**Task routing**:
- In-process (single runtime): ADK sub-agents / workflow agents (SequentialAgent, ParallelAgent, LoopAgent)
- Cross-process (cross-team/deployment): A2A task-based routing with full task lifecycle

**Audit logs**: Operate-time. Execution traces in Vertex AI Agent Engine. Policy audit logs in Agent Platform and GCP IAM. Every privileged action should produce a trace span.

## Component Map: Enterprise Intake Assistant

An enterprise intake assistant that triages HR, finance, and legal requests illustrates how all five components interact:

User entry → Gemini Enterprise app (workforce surface)
Agent deployment → Agent Platform (developer control plane) → Vertex AI Agent Engine (runtime)
Agent logic → ADK coordinator + specialist sub-agents (in-process at route-time)
Cross-boundary routing → A2A (compliance review agent, independently deployed)
Tool access → MCP (HR handbook, expense policy, legal runbook)
Audit evidence → Agent Engine traces + Agent Platform observability + GCP IAM audit logs

Layer ownership in this system:
- User entry: Gemini Enterprise app
- Agent logic: ADK (coordinator + specialist agents)
- Session state: Vertex AI Agent Engine (run-time)
- Cross-agent routing: A2A (coordinator to compliance agent)
- External tool calls: MCP (data sources per specialist)
- Audit evidence: Agent Engine traces + Agent Platform + GCP IAM audit logs

## Hands-On Exercise

Draw the component map for an enterprise intake assistant that triages HR, finance, and legal requests.

Step 1: Identify the five components and where each one sits in the architecture
Step 2: Draw the user entry path — which component is the front door?
Step 3: Label which layer owns agent logic vs. session state vs. routing
Step 4: Add cross-agent routing — is it in-process ADK or cross-process A2A?
Step 5: Mark where audit evidence accumulates (traces, IAM logs, eval results)

Your completed map should answer: "If this system breaks in production, which layer do I look at first for each type of failure?"

## Chapter Summary and Key Takeaways

- Five components, each distinct: Gemini Enterprise app (workforce UI), Agent Platform (developer control plane), Vertex AI Agent Engine (managed runtime), ADK (agent logic framework), A2A (cross-agent protocol), MCP (tool connectivity)
- Lifecycle boundaries clarify where to build, what runs live, how to route, and how to operate — build-time / run-time / route-time / operate-time
- Agent Platform is not Agent Engine: Agent Platform is governance and management; Agent Engine is execution and session state. When production breaks, check Engine traces first
- Discovery does not equal authorization: A2A Agent Cards let agents find each other; IAM policies control whether they can call each other
- Audit evidence lives in layers: execution traces in Engine, policy logs in Agent Platform and GCP IAM, eval results in Agent Platform observability

Next: In Chapter 2, you will build a real ADK agent, run it locally in the developer UI, and deploy it to Vertex AI Agent Engine — making the run-time boundary visible with your own code.
