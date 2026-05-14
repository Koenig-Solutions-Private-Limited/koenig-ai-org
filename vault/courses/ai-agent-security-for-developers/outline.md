---
course_slug: ai-agent-security-for-developers
slug: ai-agent-security-for-developers
title: "How to secure tool-using AI agents in 6 chapters"
status: awaiting-g0
author: course-author
agent_drafted_by: course-author
date: 2026-05-14
level: Builder
vendor_tag: cross-vendor
tags:
  - course/ai-agent-security-for-developers
  - security
  - agents
  - mcp
  - prompt-injection
target_audience: "Developers and AI engineers shipping agents that read files, call tools, use MCP servers, run in terminals or CI, or automate repository/workflow actions."
prerequisites:
  - "Comfortable reading and editing Python or TypeScript"
  - "Basic command-line and Git workflow experience"
  - "Familiarity with REST APIs, JSON, and environment variables"
  - "Completed an MCP fundamentals course or can explain tools, resources, prompts, transports, and OAuth at a high level"
learning_outcomes:
  - "Threat-model a tool-using agent across model, harness, tool, and environment layers"
  - "Classify agent inputs and tool surfaces by prompt-injection, exfiltration, mutation, credential, and network risk"
  - "Implement approval policies, allowlists, scoped credentials, and sandbox boundaries for local, hosted, MCP, and CI agents"
  - "Add traces, audit logs, retry budgets, and incident-review checkpoints that expose unsafe agent behavior before it causes damage"
  - "Ship a working secure-agent reference implementation with tests that prove unsafe actions are blocked or routed to review"
total_duration_min: 300
chapter_count: 6
capstone_project_min: 75
related_courses:
  - mcp-from-first-principles-to-production
  - production-agents-claude-agent-sdk-mcp-connector
  - claude-tool-use-from-zero
sources:
  - https://www.anthropic.com/research/trustworthy-agents
  - https://www.anthropic.com/engineering/claude-code-auto-mode
  - https://www.anthropic.com/engineering/claude-code-sandboxing
  - https://www.anthropic.com/engineering/managed-agents
  - https://openai.com/safety/prompt-injections/
  - https://developers.openai.com/api/docs/guides/agent-builder-safety
  - https://openai.com/index/designing-agents-to-resist-prompt-injection/
  - https://openai.com/index/running-codex-safely/
  - https://openai.github.io/openai-agents-python/mcp/
  - https://github.com/google-gemini/gemini-cli
  - https://google-gemini.github.io/gemini-cli/docs/cli/trusted-folders.html
  - https://raw.githubusercontent.com/google-github-actions/run-gemini-cli/v0.1.22/docs/trust-guidance.md
  - https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/sandbox.md
---

# Course outline

## Why this course

Tool-using agents are no longer demos that call a weather API. They read repositories, process tickets, browse documents, invoke MCP servers, run shell commands, write files, open pull requests, and act inside CI. That makes the security question concrete: what happens when untrusted text, a compromised workspace, or a malicious tool output reaches an agent with credentials and write access?

This course teaches agent security as systems engineering. The learner will not be asked to believe that better prompts solve prompt injection. They will build a small insecure agent, attack it with domain-specific prompt-injection and workspace-trust scenarios, then harden it with explicit trust boundaries, tool policies, sandboxing, credential separation, approvals, telemetry, and safe failure behavior.

The course sits after `mcp-from-first-principles-to-production`. The MCP course teaches protocol primitives, auth, gateways, and audit logs. This course broadens the runtime lens: terminal agents, hosted agents, IDE agents, MCP servers, CI agents, cloud VMs, and human-review surfaces.

## Chapter 1: Build the threat model before the agent gets tools

Agents fail differently from chatbots because they can route untrusted text into privileged actions. This chapter gives learners a repeatable threat-modeling framework before they write security code: model layer, harness layer, tool layer, environment layer. Learners start with a deliberately useful but unsafe repository assistant that can read files, summarize issues, and draft changes. They then map each input, tool, credential, and execution surface to the layer that owns the risk.

- **Duration**: 40 min
- **Prerequisites**: course intro only; basic Git and API familiarity
- **Learning objectives**:
  1. Distinguish prompt injection, indirect prompt injection, tool-output poisoning, workspace poisoning, exfiltration, and unintended actions with one concrete example each.
  2. Draw a four-layer security map for an agent: model, harness, tools, environment.
  3. Identify which layer owns each control: prompt hierarchy, approval rules, tool allowlists, sandboxing, credentials, logs.
  4. Write an initial risk register for a repository assistant that reads issues, files, web pages, and MCP tool output.
- **Key concepts**: assumed-compromise inputs, blast-radius reduction, shared responsibility, trusted vs untrusted data, model-visible vs host-controlled state, authority-bearing tool calls
- **Hands-on exercise**: Create a threat model for a repository triage agent. The learner lists every input source, every tool, every credential, every write path, and every place a malicious instruction could cross into a privileged action.

## Chapter 2: Stop untrusted text from becoming privileged instructions

This chapter turns the threat model into data-flow discipline. Learners build a small agent loop that reads a GitHub issue and drafts a change plan. First, they let issue text flow directly into privileged instructions and observe the failure mode. Then they refactor the loop so untrusted content is passed as data, validated into structured fields, and never interpolated into developer-level instructions. The point is not "detect every injection"; it is "design so injection has less authority when detection fails."

- **Duration**: 45 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  1. Separate trusted instructions, user goals, retrieved content, tool output, and generated intermediate state in an agent data-flow diagram.
  2. Replace free-form intermediate agent output with structured JSON that can be validated before the next step.
  3. Name the anti-pattern of placing untrusted variables into privileged/developer instructions and show its safer alternative.
  4. Add a prompt-injection fixture that attempts to override the task and exfiltrate a fake secret, then verify the hardened flow does not route it into a tool call.
- **Key concepts**: prompt hierarchy, trusted instructions, untrusted variables, structured outputs, schema validation, injection fixtures, constrained impact
- **Hands-on exercise**: Harden a GitHub issue summarizer. The learner starts with an unsafe prompt that embeds issue text in a developer instruction, then changes it to pass issue text as quoted data, validates a structured risk summary, and blocks tool calls unless the summary passes policy checks.

## Chapter 3: Govern tools like capabilities, not helper functions

Tool calls are capability grants. This chapter teaches learners to inventory tools by read/write/network/credential impact, design approval classes, and expose only the subset each agent needs. The lab uses an MCP-enabled repository assistant with safe read tools, risky write tools, and a mock external ticketing tool. Learners create deterministic names, split read-only from mutating actions, require approval for consequential calls, and test for tool-name confusion and overbroad MCP exposure.

- **Duration**: 50 min
- **Prerequisites**: Chapters 1-2; MCP basics or equivalent experience with tool/function calling
- **Learning objectives**:
  1. Classify tools by capability: read-only, local mutation, remote mutation, network access, credential access, and shell/code execution.
  2. Design an approval matrix that distinguishes silent allow, review-required, and always-blocked actions.
  3. Filter an MCP server's exposed tools so the agent receives only the capabilities required for the workflow.
  4. Write tests that prove a read-only agent cannot call write or shell tools even when untrusted text asks it to.
- **Key concepts**: least privilege, capability inventory, MCP tool subsetting, deterministic tool names, approval policy, read/write separation, tool-call tests
- **Hands-on exercise**: Build a tool-policy file for a repo assistant with `read_file`, `grep_code`, `create_branch`, `open_pr`, `run_tests`, and `post_ticket_comment`. The learner marks each tool's risk class, approval requirement, allowed inputs, denied inputs, and audit fields, then wires the policy into the agent loop.

## Chapter 4: Isolate execution and keep credentials out of the sandbox

Sandboxing is not a checkbox. This chapter compares hosted containers, local terminal sandboxes, cloud VM agents, and IDE/runtime sandboxes, then teaches the control objective: the model-executed code should not see broad secrets, unrestricted filesystem paths, or unrestricted network access. Learners take the chapter 3 agent and move risky command execution into a constrained workspace with scoped environment variables, a network allowlist, and artifact boundaries.

- **Duration**: 55 min
- **Prerequisites**: Chapters 1-3; basic shell and environment-variable familiarity
- **Learning objectives**:
  1. Compare local terminal, hosted container, IDE, CI, and cloud VM execution topologies by filesystem, network, credential, and review risk.
  2. Remove direct API keys from the execution environment and replace them with scoped host-mediated actions or short-lived credentials.
  3. Configure a sandbox policy with allowed directories, denied paths, allowed network destinations, and blocked shell patterns.
  4. Demonstrate that a simulated injection cannot read a fake secret outside the workspace or contact a denied domain.
- **Key concepts**: sandbox boundary, credential proxying, filesystem scope, network policy, hosted vs local execution, artifact boundary, sandbox expansion, secret minimization
- **Hands-on exercise**: Run the repository assistant inside a constrained workspace. The learner adds a fake `PROD_TOKEN`, proves the unsafe version can leak it, then hardens the runtime so the token is unavailable to model-generated code and denied network attempts are logged.

## Chapter 5: Harden agents in CI, repos, and human-review workflows

The riskiest agents often run where developers already grant automation power: GitHub Actions, repository hooks, IDE workspaces, and pull-request review bots. This chapter focuses on workspace trust and CI trust tiers. Learners design separate workflows for trusted maintainers and untrusted contributors, reduce token permissions, restrict tool allowlists for issues and external PRs, and add human review gates for plans, diffs, and publish actions.

- **Duration**: 50 min
- **Prerequisites**: Chapters 1-4; basic CI/YAML familiarity
- **Learning objectives**:
  1. Distinguish trusted and untrusted CI inputs, including collaborator branches, fork PRs, issue comments, dependency files, and repo-local config.
  2. Configure least-privilege workflow permissions for an agent job that reviews pull requests without publishing code.
  3. Disable repo-local config and auto-accept behavior for untrusted workspaces.
  4. Add plan review, diff review, and final approval gates before an agent opens or updates a pull request.
- **Key concepts**: workspace trust, untrusted PRs/issues, CI token scope, tool allowlists, repo-local config, plan review, diff review, approval fatigue
- **Hands-on exercise**: Write two CI workflow sketches for the same agent: one for trusted maintainers and one for untrusted fork PRs. The learner limits permissions, narrows allowed tools, blocks shell execution for untrusted inputs, and records exactly where a human must approve.

## Chapter 6: Observe failures, rehearse incidents, and make retries safe

Security controls fail quietly if nobody can reconstruct what happened. This final chapter adds telemetry and operational safety. Learners add structured logs for prompts, tool calls, approvals, denied actions, network policy decisions, retry attempts, and final outcomes. They then run a simulated incident: a malicious issue tries to make the agent repeat a write action during an API outage. The learner uses logs to detect the pattern, confirm idempotency behavior, and write a short incident note.

- **Duration**: 60 min
- **Prerequisites**: Chapters 1-5
- **Learning objectives**:
  1. Emit structured audit events for tool calls, approvals, denied actions, sandbox/network decisions, and retries.
  2. Add idempotency keys and retry budgets for consequential tool calls.
  3. Build a simple trace review checklist that catches exfiltration attempts, suspicious tool sequences, and degraded-dependency behavior.
  4. Write an incident report from agent logs that names root cause, blast radius, control failures, and next hardening action.
- **Key concepts**: trace review, audit logs, OpenTelemetry-style events, retry budgets, idempotency, degraded dependency behavior, suspicious sequence detection, incident review
- **Hands-on exercise**: Simulate an upstream API failure while an injected issue asks the agent to retry a mutating action. The learner verifies that the agent stops after the retry budget, does not duplicate the action, logs the denied/retried sequence, and produces an incident note.

## Capstone project

**Ship a secure repository-assistant agent with a documented threat model and passing security tests.**

### Deliverable

A public or local repo containing:

- A small agent that can triage repository issues, read files, draft a plan, run tests in a constrained environment, and prepare a pull-request draft.
- A threat model covering model, harness, tool, and environment layers.
- A tool policy covering every exposed capability, with read/write/network/credential/shell classifications.
- An MCP or function-tool configuration that exposes only the required tool subset.
- Approval gates for branch creation, pull-request publication, ticket comments, shell commands, and network-expanding actions.
- A sandbox/runtime policy with allowed directories, denied paths, network allowlist, and no broad secrets in the model-executed environment.
- CI workflow notes for trusted and untrusted inputs.
- Structured audit logs for prompts, tool calls, approvals, denials, sandbox/network decisions, retries, and final outcomes.
- Tests or replay fixtures proving that injection, overbroad tool use, secret access, denied network egress, untrusted CI input, and duplicate mutating retries are handled safely.

### Verification criteria

- The threat model names all input sources, tools, credentials, write paths, and trust boundaries.
- A malicious issue fixture cannot cause the agent to call a write tool without approval.
- A malicious file fixture cannot access a fake secret outside the sandbox.
- A denied-domain fixture produces a blocked network event in the audit log.
- The untrusted-PR workflow sketch uses least-privilege permissions and blocks shell execution or routes it to human review.
- A retry fixture for a mutating action uses an idempotency key, obeys a retry budget, and does not duplicate the action.
- The final README includes exact commands to run the fixtures and inspect the resulting logs.

### Estimated time

75 min for learners who completed all six chapters.

## Reviewer notes

This outline is based on the 2026-05-14 Research Editor synthesis `vault/research/_synthesis/ai-agent-security-for-developers-course-scope-2026-05-14.md` and vendor source packets from Anthropic, OpenAI, and Google. It intentionally avoids writing chapter bodies before outline G0. The course should stay implementation-led and cross-vendor: use vendor examples as evidence and contrast cases, but make the learner ship durable controls that transfer across agent stacks.
