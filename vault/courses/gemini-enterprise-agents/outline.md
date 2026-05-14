---
course_slug: gemini-enterprise-agents
title: "Build Production AI Agents with Gemini Enterprise Agent Platform"
status: awaiting-g0
author: course-author
level: Builder
vendor_tag: google
target_audience: "GCP architects, enterprise AI/ML engineers, DevOps leads evaluating agent infrastructure, and platform engineers building internal AI tooling at mid-to-large enterprises who must defend production agent deployments to a CISO."
prerequisites:
  - "Python 3.10+ and familiarity with async/await"
  - "A Google Cloud project with billing enabled"
  - "Familiarity with at least one LLM API (Gemini, OpenAI, or Anthropic)"
  - "Basic understanding of IAM, VPC networking, and GCP project structure"
  - "Comfort reading architecture diagrams and API reference docs"
learning_outcomes:
  - "Design and deploy multimodal agents using Gemini 3.1 Pro and Flash TTS with expressive audio control"
  - "Architect multi-agent orchestration patterns (supervisor/worker, sequential pipeline, A2A) using Agent Registry"
  - "Configure Agent Gateway, Agent Identity, and Model Armor for a CISO-defensible deployment"
  - "Implement production observability (traces, logs, metrics, topology) and automated evaluation pipelines"
  - "Operate a production agent system with SLA targets, cost controls (Flash-Lite), and incident response runbooks"
  - "Deploy agents in hardened Agent Sandboxes for secure 'computer use' and code execution"
total_duration_min: 345
chapter_count: 8
capstone_project_min: 60
---

# Build Production AI Agents with Gemini Enterprise Agent Platform

## Why this course

Google's Gemini Enterprise Agent Platform (GEAP), GA since 23 April 2026, is the first cloud-native agent runtime with DevSecOps baked in. With the release of **Gemini 3.1 Pro** and **Flash TTS**, the platform has moved beyond text-based reasoning to native multimodal agency. Gemini 3.1 Pro's 77.1% score on ARC-AGI-2 marks a shift from "managing tasks" to "delegating outcomes."

Most agent tutorials end at "hello world with a tool." This course starts where they stop. It is for the engineer who must defend a production agent deployment to a CISO — not just ship a demo. Every chapter produces something you can show your security team, your SRE on-call, or your finance department.

By the end of Chapter 8 you will have a fully deployed multi-agent system behind Agent Gateway, featuring expressive voice interaction, hardened code execution, and the governance to operate it at scale.

## Course outline

### Chapter 1: The production agent landscape — why GEAP exists
- **Duration**: 35 min
- **Prerequisites**: None (course intro)
- **Learning objectives**:
  - Explain the 2026 transition from Vertex AI to GEAP: why standalone AI services are legacy
  - Map Gemini 3.1 Pro's reasoning leap (ARC-AGI-2) to the necessity of enterprise guardrails
  - Map GEAP's four pillars (Build / Scale / Govern / Optimize) to enterprise requirements
  - Identify the trade-offs of the "Google-native" stack vs. multi-cloud agent SDKs
- **Key concepts**: Agent Runtime, Memory Bank, Agent Gateway, Agent Identity, Agent Registry, Model Armor, Gemini 3.1 Pro reasoning leap, Vertex AI consolidation
- **Hands-on**: Draw the GEAP component map for an enterprise HR-onboarding agent. Annotate which pillar owns each component and where Gemini 3.1 Pro sits.

---

### Chapter 2: Single-agent setup — build, tool, and persist
- **Duration**: 50 min
- **Prerequisites**: Chapter 1, GCP project with billing, `gcloud` CLI
- **Learning objectives**:
  - Install `google-cloud-aiplatform[agent_engines,adk]` and initialize the SDK
  - Define Python functions as tools with proper type hints for ADK auto-introspection
  - Distinguish in-session state (Sessions) from long-term memory (Memory Bank)
  - Deploy to Agent Runtime and compare **Gemini 3.1 Pro** vs. **Flash-Lite** for cost/latency tradeoffs
- **Key concepts**: `AdkApp`, Sessions vs Memory Bank, Agent Runtime, Gemini 3.1 Pro vs. Flash-Lite pricing, cold-start behavior
- **Hands-on**: Build a "Policy Q&A" agent — a tool for mock policy retrieval, a Session for state, and a Memory Bank profile for user context. Verify via `curl`.

---

### Chapter 3: RAG and grounding — agents that know your enterprise data
- **Duration**: 45 min
- **Prerequisites**: Chapter 2
- **Learning objectives**:
  - Configure RAG Engine with a 1M+ token corpus using Gemini 3.1 Pro's long-context capabilities
  - Distinguish grounding options: Google Search, Maps, RAG, and Web Grounding for Enterprise
  - Set up Vector Search 2.0 as the backing store
  - Measure retrieval quality vs. synthesis accuracy at various context depths (200K, 500K, 1M)
- **Key concepts**: RAG Engine, chunking strategies, Vector Search 2.0, 1M token context behavior, synthesis effective limits
- **Hands-on**: Ingest 20 internal policy documents. Compare 3.1 Pro reasoning quality with and without grounding at 500K token depth.

---

### Chapter 4: Multi-agent orchestration — from solo to ensemble
- **Duration**: 55 min
- **Prerequisites**: Chapter 3
- **Learning objectives**:
  - Implement orchestration patterns: supervisor/worker, sequential pipeline, and Agent2Agent (A2A)
  - Register agents in Agent Registry and discover them by capability annotations
  - Wire agent handoffs with `transfer_to_agent` and debug via Agent Observability traces
  - Use Gemini 3.1 Pro's high-determinism reasoning to reduce orchestration "looping"
- **Key concepts**: sub-agent networks, `AgentRegistry`, `transfer_to_agent`, A2A protocol, orchestration anti-patterns, determinism budgets
- **Hands-on**: Build a three-agent invoice processing pipeline. Register all three in Agent Registry and process test invoices through the ensemble.

---

### Chapter 5: Enterprise security — CISO-defensible deployments
- **Duration**: 50 min
- **Prerequisites**: Chapter 4
- **Learning objectives**:
  - Configure Agent Identity (SPIFFE) per agent—no shared service accounts
  - Set up Agent Gateway for traffic enforcement, tool-call interception, and Model Armor inspection
  - Implement user-delegated OAuth 2.0 via Agent Identity Auth Manager
  - Use **SynthID watermarking** for audit-logging and verifying model-generated audio/video
- **Key concepts**: Agent Identity, Agent Gateway, Model Armor, Agent Identity Auth Manager, SynthID, VPC-SC, CMEK
- **Hands-on**: Secure the invoice pipeline—assign Identities, configure Gateway to block unauthorized tool calls, and enable Model Armor for tool responses.

---

### Chapter 6: Production observability and evaluation
- **Duration**: 50 min
- **Prerequisites**: Chapter 5
- **Learning objectives**:
  - Configure Cloud Observability using OpenTelemetry for agent-specific traces
  - Read traces to identify bottlenecks and calculate token cost per interaction
  - Set up automated evaluation with Agent Simulation and Online Monitors (autoraters)
  - Use Agent Optimizer to cluster failures and suggest prompt refinements based on 3.1 Pro behavior
- **Key concepts**: Cloud Trace, Cloud Logging, OpenTelemetry, Agent Simulation, Online Monitors, Agent Optimizer
- **Hands-on**: Inject a failure into the pipeline. Use the trace to find it. Run an offline evaluation on 30 queries and configure a quality alert.

---

### Chapter 7: Multimodal Agents — Voice, Video, and Computer Use
- **Duration**: 40 min
- **Prerequisites**: Chapter 6
- **Learning objectives**:
  - Implement **Gemini 3.1 Flash TTS** with expressive audio tags (`[whisper]`, `[excited]`)
  - Build agents that reason over images and real-time video streams
  - Configure **Agent Sandbox** for secure code execution and "computer use" browser tasks
  - Apply SynthID watermarking to all agent-generated multimodal outputs
- **Key concepts**: Flash TTS, expressive audio tags, multimodal reasoning, Agent Sandbox, Computer Use, SynthID
- **Hands-on**: Build a "Voice Concierge" that uses Flash TTS to welcome users with different vocal styles and identifies a product shown to a webcam.

---

### Chapter 8: Operating at scale — SLAs, cost, and incident response
- **Duration**: 20 min
- **Prerequisites**: Chapter 7
- **Learning objectives**:
  - Define SLA targets and map them to GEAP's pricing model (Pro vs. Flash-Lite)
  - Implement cost controls: Provisioned Throughput vs. On-demand, and context caching
  - Write an incident response runbook for tool-timeouts and Memory Bank corruption
  - Plan rollbacks using Agent Registry versioning and traffic shifting
- **Key concepts**: SLA definition, Provisioned Throughput, context caching, Agent Registry versioning, traffic shifting, incident response runbooks
- **Hands-on**: Write a production runbook for the multimodal invoice pipeline. Test a rollback procedure via Agent Registry.

---

## Capstone project

**Deploy a production-grade multimodal multi-agent system for enterprise processing.**

Deliverable:
- ADK codebase with Supervisor, RAG (1M context), Voice (Flash TTS), and Compliance agents
- All agents registered in Agent Registry with Agent Identities and secured by Agent Gateway
- Multimodal capability: processes images/video and responds with expressive voice
- Cloud Observability enabled with quality alerts and an evaluation report (>80% accuracy)
- Production runbook with SLA, cost projection (Pro/Flash-Lite mix), and CISO checklist

Time: 60 min

---

## Why this beats alternatives

Most GEAP content stops at "deploy your first agent." This is the first course to integrate **Gemini 3.1 Pro**'s reasoning, **Flash TTS**'s expressive voice, and **Agent Gateway**'s enterprise security. We don't just teach you to code; we teach you to defend your deployment to a CISO.

---

## Sources

1. [Google Cloud Blog: Introducing Gemini Enterprise Agent Platform](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform)
2. [Gemini 3.1 Flash TTS: Expressive AI Speech](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-1-flash-tts/)
3. [Gemini 3.1 Pro: A Smarter Model](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-1-pro/)
4. [Gemini 3.1 Flash-Lite GA](https://cloud.google.com/blog/products/ai-machine-learning/gemini-3-1-flash-lite-is-now-generally-available)
5. [GEAP Official Documentation](https://docs.cloud.google.com/gemini-enterprise-agent-platform/agents/overview)
6. [Agent Development Kit (ADK) Quickstart](https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/runtime/quickstart-adk)
7. [RAG Engine Overview](https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/rag-engine/rag-overview)
8. [Agent Gateway & Identity](https://docs.cloud.google.com/gemini-enterprise-agent-platform/govern/gateways/agent-gateway-overview)
9. [Agent Observability & Evaluation](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/observability/overview)
10. [ARC-AGI-2 Reasoning Benchmark](https://arcprize.org/blog/gemini-3-1-pro-results)
