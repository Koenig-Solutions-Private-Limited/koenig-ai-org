---
course_slug: gemini-enterprise-agents
slug: gemini-enterprise-agents
title: "How to build production Gemini Enterprise agents with routing, lifecycle, and governance in 8 chapters"
status: g0-passed
course_track: career
last_delta: 2026-05-28
last_delta_reason: "R2 G0 fixes: make routing and lifecycle the spine of the course; separate Gemini Enterprise app, Agent Platform, Vertex AI Agent Engine, ADK, and A2A responsibilities."
author: course-author
level: Builder
vendor_tag: google
tags:
  - course/gemini-enterprise-agents
  - vendor/google
  - agents
  - routing
  - lifecycle
target_audience: "GCP architects, enterprise AI engineers, platform engineers, and DevOps leads who need to design, deploy, and defend production Gemini-based agent systems across routing, state, security, observability, and operating lifecycle."
prerequisites:
  - "Python 3.10+ and comfort reading async code"
  - "A Google Cloud project with billing enabled"
  - "Familiarity with one LLM API or agent SDK"
  - "Basic understanding of IAM, service accounts, VPC networking, and GCP project structure"
  - "Comfort reading API docs and architecture diagrams"
learning_outcomes:
  - "Map Gemini Enterprise app, Agent Platform, Vertex AI Agent Engine, ADK, and A2A to the correct production responsibilities without mixing their boundaries"
  - "Build and deploy an ADK agent to Vertex AI Agent Engine with a clear invocation, session, deploy, update, and rollback lifecycle"
  - "Implement three routing patterns: deterministic workflow routing, LLM-mediated sub-agent routing, and A2A task-based routing between independently deployed agents"
  - "Secure agent-to-agent and agent-to-tool calls with identity, policy gates, least privilege, and audit-ready traces"
  - "Operate a production agent system with preview-model lifecycle controls, tracing, evaluation gates, cost budgets, and incident runbooks"
total_duration_min: 415
chapter_count: 8
capstone_project_min: 75
sources:
  - https://blog.google/innovation-and-ai/infrastructure-and-cloud/google-cloud/gemini-enterprise-agent-platform/
  - https://docs.cloud.google.com/gemini/enterprise/docs
  - https://cloud.google.com/gemini-enterprise/agents
  - https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview
  - https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy
  - https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/sessions/overview
  - https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/manage/tracing
  - https://google.github.io/adk-docs/get-started/about/
  - https://google.github.io/adk-docs/agents/multi-agents/
  - https://google.github.io/adk-docs/agents/workflow-agents/sequential-agents/
  - https://google.github.io/adk-docs/callbacks/types-of-callbacks/
  - https://google-a2a.github.io/A2A/specification/
  - https://a2aproject.github.io/A2A/latest/topics/life-of-a-task/
---

# Course outline

## Why this matters for your career

Engineers who can design, secure, and operate production Gemini Enterprise Agent systems — routing, lifecycle, governance, and cost — are positioned for cloud AI architect and senior platform engineering roles. This course builds that system from scratch, making every production decision traceable to code, cost, and audit evidence.

## Why this course

Google's agent story now spans multiple surfaces that sound similar but solve different problems. Gemini Enterprise is the workforce-facing agentic platform. Agent Platform is Google's developer platform for building, scaling, governing, and optimizing autonomous agents on Google Cloud. Vertex AI Agent Engine is the managed runtime where deployable agent applications run. ADK is the code-first framework for agent logic. A2A is the cross-agent protocol layer for task-based interoperability.

Most courses blur those layers. That causes bad production designs: UI agents treated as runtimes, in-process ADK handoffs treated as inter-service routing, A2A task state ignored, and preview model IDs copied into production without a rollback plan.

This course takes the opposite route. Learners build a production-grade enterprise intake system and make every lifecycle boundary visible: local agent run, managed deployment, session state, sub-agent routing, A2A task state, security policy, trace span, evaluation gate, model migration, and rollback.

By the end, a learner can not only build a Gemini-based agent system, but explain which component owns each routing decision and which system records each lifecycle transition.

> [!WARNING] Current As Of May 28, 2026
> This outline reflects Google's public Gemini Enterprise, Agent Platform, Vertex AI Agent Engine, ADK, and A2A documentation available on 2026-05-28. Production chapters must treat preview model IDs, preview Agent Engine features, and A2A version details as lifecycle-sensitive. Learners should verify launch stage, deprecation notes, quota, and fallback routing before deploying any copied configuration.

## Chapter 1: Map the platform before you build

- **Duration**: 40 min
- **Prerequisites**: None, course intro only
- **Learning objectives**:
  1. Distinguish Gemini Enterprise app, Agent Platform, Vertex AI Agent Engine, ADK, and A2A by responsibility
  2. Draw the build-time, run-time, route-time, and operate-time boundaries in a Gemini agent system
  3. Identify where enterprise data access, agent discovery, task routing, and audit logs belong
  4. Explain why a production agent platform is more than a model endpoint plus tools
- **Key concepts**: Gemini Enterprise app, Agent Platform, Vertex AI Agent Engine, ADK, A2A, MCP, lifecycle boundary, runtime boundary, workforce agent vs developer-built agent
- **Hands-on exercise**: Draw a component map for an enterprise intake assistant that triages HR, finance, and legal requests. Label which layer owns user entry, agent logic, session state, cross-agent routing, external tool calls, and audit evidence.

This chapter fixes the largest conceptual risk: treating every Google agent product as interchangeable. Learners leave with a reference map they will reuse for every later routing and lifecycle decision.

---

## Chapter 2: Build one ADK agent and deploy it with a real lifecycle

- **Duration**: 55 min
- **Prerequisites**: Chapter 1, GCP project with billing, `gcloud` CLI, Python 3.10+
- **Learning objectives**:
  1. Create a minimal ADK agent with a typed domain tool and a testable instruction
  2. Run the agent locally and inspect events, state changes, and tool calls in the ADK developer UI
  3. Deploy the same agent to Vertex AI Agent Engine and invoke it through the remote client path
  4. Describe the deployment lifecycle: package, create, query, update, delete, and rollback
  5. Distinguish ephemeral local state from managed session state in Vertex AI Agent Engine Sessions
- **Key concepts**: ADK `Agent`, tools, local run, `AdkApp`, Vertex AI Agent Engine, deployment package, remote agent, `query`, `streamQuery`, session, event history
- **Hands-on exercise**: Build a "Policy Intake" agent that classifies employee policy questions and calls a mock policy lookup tool. Run it locally, deploy it to Agent Engine, create a session, invoke it twice, and record which lifecycle events were local-only versus managed by Agent Engine.

The course earns the word "production" here by making deployment and session lifecycle visible before any multi-agent routing is introduced.

---

## Chapter 3: Route inside one runtime with deterministic and LLM-mediated patterns

- **Duration**: 55 min
- **Prerequisites**: Chapter 2
- **Learning objectives**:
  1. Implement deterministic routing with ADK workflow agents such as `SequentialAgent`, `ParallelAgent`, and `LoopAgent`
  2. Implement LLM-mediated routing where a coordinator chooses a specialist sub-agent based on request content
  3. Pass data between sub-agents through shared invocation context and explicit session state rather than hidden prompt coupling
  4. Add loop limits, route budgets, and fail-loud behavior for routing errors
  5. Read ADK events to prove which sub-agent ran and why
- **Key concepts**: workflow agents, coordinator agent, sub-agent, invocation context, session state, route budget, loop guard, deterministic route, generative route
- **Hands-on exercise**: Extend the Policy Intake agent into a three-agent internal-helpdesk router: HR policy, expense policy, and IT access. Implement a deterministic pre-screening step, then an LLM-mediated specialist selection step. Verify that three sample requests route to the expected specialist and that unknown requests fail with a clear escalation message.

This chapter narrows "routing" to in-process or same-runtime orchestration. Learners do not use A2A yet, because A2A has a different lifecycle model and should not be collapsed into ADK sub-agent calls.

---

## Chapter 4: Route across agents with A2A task lifecycle

- **Duration**: 60 min
- **Prerequisites**: Chapter 3
- **Learning objectives**:
  1. Explain the A2A model: Agent Card discovery, client agent, remote agent, Message, Part, Task, Artifact
  2. Implement an A2A-style route from the helpdesk coordinator to an independently deployed compliance review agent
  3. Track task lifecycle states, including submitted, working, input-required, auth-required, completed, canceled, rejected, and failed where supported by the current A2A version
  4. Decide when an agent should return a direct response versus a long-running task with artifacts
  5. Handle human input and secondary authorization without losing task history
- **Key concepts**: A2A, Agent Card, task lifecycle, message, part, artifact, streaming status update, push notification, human-in-the-loop, auth-required, idempotency key
- **Hands-on exercise**: Publish an Agent Card for a compliance review agent, then have the helpdesk coordinator submit a review task for a risky HR answer. Simulate `input-required` for missing policy scope, continue the task with additional input, and finish with an artifact containing the approved response and audit notes.

This is the G0-critical routing/lifecycle chapter. It teaches that cross-agent work is not just "call another agent"; it is a stateful task with ownership, interruptions, outputs, and terminal states.

---

## Chapter 5: Ground routed agents in enterprise data safely

- **Duration**: 45 min
- **Prerequisites**: Chapter 4
- **Learning objectives**:
  1. Choose between Gemini Enterprise connectors, RAG on Vertex AI, and custom tools for enterprise knowledge access
  2. Add retrieval to each specialist without giving the coordinator broad data access
  3. Preserve permission boundaries across routed calls so sub-agents only see data they are authorized to use
  4. Evaluate retrieval quality separately from final synthesis quality
- **Key concepts**: enterprise connectors, permissions-aware search, RAG, data-source boundary, least-privilege retrieval, grounded answer, retrieval evaluation
- **Hands-on exercise**: Add three mock enterprise data sources: HR handbook, expense policy, and access-control runbook. Configure each specialist to retrieve only from its allowed source. Prove with tests that the HR agent cannot answer expense-policy questions by directly reading the expense source.

Routing without data boundaries is an anti-pattern. This chapter teaches learners to route both requests and permissions, not just prompts.

---

## Chapter 6: Secure agent-to-agent and agent-to-tool traffic

- **Duration**: 55 min
- **Prerequisites**: Chapter 5, basic IAM knowledge
- **Learning objectives**:
  1. Assign distinct identities to coordinator, specialist, and compliance agents
  2. Enforce caller-to-agent and agent-to-tool authorization with least-privilege policy
  3. Apply gateway-style controls for rate limits, tool interception, and content safety where the deployed surface supports them
  4. Log every privileged tool call with actor, agent identity, route, tool name, data classification, and result status
  5. Explain why discovery does not equal authorization
- **Key concepts**: agent identity, service account, IAM, gateway, policy gate, tool-call interception, audit log, data classification, least privilege
- **Hands-on exercise**: Secure the helpdesk system so the coordinator can route to specialists, specialists can call only their own policy tools, and only the compliance agent can approve high-risk responses. Attempt one forbidden route and one forbidden tool call, then capture the expected denial logs.

This chapter converts the routing graph into a security graph. The learner must be able to defend who can call whom and why.

---

## Chapter 7: Observe, evaluate, and gate lifecycle transitions

- **Duration**: 55 min
- **Prerequisites**: Chapter 6
- **Learning objectives**:
  1. Enable Cloud Trace or OpenTelemetry-compatible tracing for Agent Engine deployments
  2. Read spans for model calls, tool calls, route decisions, A2A task transitions, and final artifacts
  3. Add ADK callbacks for lifecycle-aware logging, validation, and guardrails
  4. Build an evaluation suite that separately tests routing accuracy, retrieval grounding, policy compliance, and final answer quality
  5. Define release gates that block deployment when routing regressions or lifecycle regressions appear
- **Key concepts**: trace, span, Cloud Trace, OpenTelemetry, ADK callbacks, route accuracy, eval dataset, online monitor, release gate, regression budget
- **Hands-on exercise**: Inject three failures: misrouted HR request, missing compliance approval, and empty retrieval result. Use traces and callback logs to find each failure, then add an evaluation case that would catch it before release.

Production agents fail in traces before they fail in dashboards. This chapter teaches learners to observe the lifecycle, not just the final answer.

---

## Chapter 8: Operate models, costs, incidents, and rollbacks

- **Duration**: 50 min
- **Prerequisites**: Chapter 7
- **Learning objectives**:
  1. Choose models by route: coordinator reasoning, specialist extraction, compliance review, and summarization
  2. Apply preview-model lifecycle controls: launch-stage check, deprecation watch, quota check, fallback route, and per-model monitoring
  3. Estimate cost per resolved task instead of cost per model call
  4. Write incident runbooks for routing loops, stuck A2A tasks, auth-required dead ends, retrieval leakage, and model retirement
  5. Execute a rollback using versioned deployment and traffic-shift procedure
- **Key concepts**: model routing, Gemini Pro, Gemini Flash, preview endpoint, deprecation, fallback model, cost per resolved task, route loop, stuck task, rollback, traffic shifting
- **Hands-on exercise**: Create an operating runbook for the helpdesk system. Include model selection per route, spend budget, loop detector, stuck-task policy, preview-model migration checklist, and rollback procedure. Run one rollback drill by switching the coordinator to the previous known-good deployment.

This final chapter keeps the course honest: a learner has not built a production agent until they can survive model churn, budget pressure, stuck tasks, and route loops.

---

## Capstone project

**Deploy a governed Gemini enterprise helpdesk agent system with explicit routing and lifecycle evidence.**

### Deliverable

A working repository and runbook containing:

- ADK codebase for a coordinator agent plus HR, expense, IT, and compliance specialist agents
- Local run instructions and Vertex AI Agent Engine deployment instructions
- Three routing implementations: deterministic workflow route, LLM-mediated specialist route, and A2A task-based compliance route
- A2A Agent Card for the compliance agent and a task lifecycle demo covering submitted, working, input-required, completed, and failed or rejected
- Managed session usage showing conversation history and route state across multiple turns
- Permission-scoped data access so each specialist can retrieve only from its allowed source
- Identity and policy configuration documenting which agent can invoke which sub-agent and which tool
- Tracing and evaluation report covering route accuracy, groundedness, policy compliance, and cost per resolved task
- Production runbook covering stuck task handling, route loop containment, preview-model migration, incident response, rollback, and audit evidence

### Verification criteria

- The coordinator routes 10 test requests with at least 90% expected specialist accuracy
- A risky HR response creates an A2A compliance task and records each lifecycle transition
- A missing policy scope causes `input-required` rather than hallucinated approval
- Unauthorized cross-domain retrieval is denied and logged
- Traces show the full route path from user request to specialist call to compliance artifact
- Evaluation results identify at least one intentionally injected routing failure
- Rollback drill restores the previous coordinator deployment and passes the smoke test

### Estimated time

75 min for learners who completed all eight chapters.

---

## Why this beats alternatives

Most Gemini agent material teaches either a workforce product tour or a single-agent code sample. This course teaches the production architecture between those extremes. Learners build the system, but more importantly they can prove the system's route decisions, lifecycle transitions, permission boundaries, trace evidence, model choices, and rollback procedure.

That is the difference between an agent demo and an agent system an enterprise can operate.
