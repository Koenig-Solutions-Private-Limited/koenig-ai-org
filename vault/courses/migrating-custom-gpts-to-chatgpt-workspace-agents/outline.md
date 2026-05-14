---
course_slug: migrating-custom-gpts-to-chatgpt-workspace-agents
title: "Migrating Custom GPTs to ChatGPT Workspace Agents: A Builder's Guide"
status: awaiting-g0
author: course-author
level: Builder
target_audience: "Developers familiar with Custom GPTs and OpenAI platform APIs"
prerequisites:
  - "Proficiency with Custom GPTs (Actions/Knowledge)"
  - "Basic Python or TypeScript experience"
  - "Familiarity with OpenAI API"
learning_outcomes:
  - "Map GPT Actions to structured Tool definitions"
  - "Implement secure authentication for Workspace Agents"
  - "Deploy agents into a production Workspace environment"
  - "Configure observability and structured logging"
total_duration_min: 240  # 4 hours
chapter_count: 5
---

# Course outline

## Chapter 1: The Agentic Shift: From GPTs to Workspace Agents
- **Duration**: 45 min

**Learning objectives:**
- Contrast the monolithic architecture of Custom GPTs with the composable nature of Workspace Agents.
- Identify the key technical benefits of migrating to Workspace Agents for production environments.
- Verify environment setup and prerequisites for building Workspace Agents.

## Chapter 2: Mapping Capabilities: GPT Actions to Tool Definitions
- **Duration**: 50 min

**Learning objectives:**
- Map an existing OpenAPI Action spec to a Workspace Agent tool definition.
- Identify incompatible GPT Action patterns and apply the correct Workspace Agent alternative.
- Validate a tool schema using the ChatGPT Workspace developer console.

## Chapter 3: Securing the Handshake: Data & Authentication Migration
- **Duration**: 50 min

**Learning objectives:**
- Migrate API authentication configurations (OAuth/API Key) from Custom GPTs to Workspace-compliant standards.
- Configure secure environment variables and secrets management for agent backend services.
- Test the end-to-end authentication handshake between ChatGPT and your custom backend.

## Chapter 4: Bridging the Gap: Observability & Agent Behavior
- **Duration**: 45 min

**Learning objectives:**
- Implement structured logging to trace agent decision paths and tool execution results.
- Configure monitoring dashboards to track agent latency, error rates, and token usage.
- Optimize agent system prompts based on observability data to reduce hallucinations and tool-call failures.

## Chapter 5: Shipping to Production: Deploying & Managing Agents
- **Duration**: 50 min

**Learning objectives:**
- Deploy a validated agent to a production ChatGPT Workspace environment.
- Establish a CI/CD pipeline for automated testing and deployment of agent tool updates.
- Manage agent permissions and access controls within a team workspace.

## Capstone project
Migrate a functional Custom GPT (with custom actions and knowledge files) into a Workspace Agent that operates reliably within a team workspace with full observability and secure authentication.
