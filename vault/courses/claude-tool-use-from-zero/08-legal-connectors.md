---
chapter_num: 8
course_slug: claude-tool-use-from-zero
title: "Legal and Regulatory Connectors in MCP"
slug: 08-legal-connectors
status: awaiting-g0
author: vardaan-koenig
agent_drafted_by: course-author
date: 2026-05-28
tags:
  - mcp
  - legal
  - connectors
  - compliance
learning_objectives:
  - "Analyze the regulatory requirements and data confidentiality standards for handling legal documents via MCP"
  - "Implement deterministic document redaction and audit trails using the Model Context Protocol"
  - "Configure secure tool interfaces for industry-standard LegalTech platforms like Relativity, Everlaw, and Thomson Reuters"
  - "Deploy practice-area plugins with tailored 'setup interviews' for specialized legal workflows"
prerequisites_chapters:
  - "Chapter 7: Creative Connectors"
duration_min: 60
key_concepts:
  - legal MCP connector inventory
  - practice-area plugins
  - deterministic redaction
  - matter-scoped authorization
  - audit-safe tool design
hands_on_exercise: "Build a mock legal document redaction tool that strips SSNs before returning text to Claude and logs only redaction metadata."
sources:
  - https://www.lawnext.com/2026/05/anthropic-goes-all-in-on-legal-releasing-more-than-20-connectors-and-12-practice-area-plugins-for-claude.html
  - https://claude.com/blog/claude-for-the-legal-industry
  - https://github.com/anthropics/claude-for-legal/blob/main/README.md
  - https://github.com/anthropics/claude-for-legal/blob/main/CONNECTORS.md
  - https://www.thomsonreuters.com/en/press-releases/2026/may/thomson-reuters-and-anthropic-expand-partnership-to-connect-claude-with-cocounsel-legal
  - https://csrc.nist.gov/pubs/sp/800/122/final
description: "A compliance-first guide to legal MCP connectors: what the May 2026 connector launch enables, what governance constraints remain, and how to design redaction, matter scoping, and audit trails."
---

# Chapter 8: Legal and Regulatory Connectors in MCP

Legal MCP connectors let Claude work against legal systems of record: contract repositories, document management systems, e-discovery projects, research databases, deal rooms, and public-law datasets. The constraint is that the connector does not make the legal system less sensitive. The connector still has to preserve matter boundaries, user permissions, source provenance, review obligations, and auditability.

On May 12, 2026, Anthropic announced 20+ MCP connectors for legal software and 12 practice-area plugins for Claude, including connectors across contract lifecycle, document management, e-discovery, research, data-room, expert-network, and access-to-justice workflows [1][2][3][4]. This chapter is about the design rule behind that launch: legal connectors should make governed retrieval and workflow execution easier without turning Claude into the system of record.

> **Prerequisites**: Chapter 7, where you learned how connector schemas shape creative workflows. You should also understand MCP tools, resources, authentication, and structured logging from Chapters 2, 5, and 6.
>
> **Time**: 60 minutes
>
> **Learning objectives**: by the end of this chapter, you can verify a legal connector inventory against primary sources, explain the difference between a legal connector and a practice-area plugin, design a matter-scoped e-discovery search tool, and implement a deterministic redaction control before sensitive text is returned from a tool.

## Key facts

1. Anthropic's May 12, 2026 legal launch introduced 20+ MCP connectors and 12 legal practice-area plugins; LawNext and Anthropic describe the same release as spanning contract systems, DMS, e-discovery, research, public-service, and expert-network categories [1][2].
2. The official `anthropics/claude-for-legal` repository lists practice-area plugin directories for commercial, corporate, employment, privacy, product, regulatory, AI governance, IP, litigation, law-student, legal-clinic, and legal-builder-hub workflows [3].
3. The repository's connector map distinguishes connector infrastructure from plugin workflow packages: connectors wire Claude to data sources, while plugins package skills, agents, hooks, and practice profiles [4].
4. Thomson Reuters separately announced an MCP integration connecting Claude to CoCounsel Legal, with Westlaw, Practical Law, and KeyCite named as the professional content backbone for that partnership [5].
5. NIST SP 800-122 frames PII confidentiality as a lifecycle problem involving collection, use, retention, sharing, and disposal; this chapter applies that risk-control framing to legal MCP tool responses [6].

## Why Legal Connectors Matter: The Stakes of "Data Bound"

Legal work runs on a highly specialized technology stack: contract lifecycle management (CLM) systems, e-discovery platforms, document management systems (DMS), and primary law research databases. Historically, bringing LLM intelligence to this data required bulk exports—moving sensitive files out of their governed environments and into the cloud for processing.

MCP changes this paradigm. Anthropic describes legal connectors as bringing the documents, communications, and records tied to specific matters into Claude without requiring legal teams to rebuild their system of record around the model [2].

### The Principle of Deterministic Tooling
In legal contexts, some tool behaviors should be deterministic. If a lawyer asks Claude to "Redact this document," they are not looking for a creative interpretation of what should be hidden. They need a repeatable control that can be tested, logged, and reviewed. Depending on the deployment, that control might run inside the MCP server, inside a vendor platform before the MCP response is assembled, or in another governed service boundary.

When designing legal tools, we prioritize **deterministic logic over probabilistic reasoning**. For example, a redaction tool should use verified PII-detection libraries or regex patterns on the server side, returning only the cleaned text to the model.

<Callout type="warn">
**Deterministic vs. Probabilistic**: Redaction in a legal context should rely on deterministic controls such as regexes, checksums, review workflows, or dedicated PII-detection services before sensitive material is returned to the model. NIST frames PII confidentiality as a lifecycle risk-control problem, so prompt-only instructions like "ignore any PII" are not enough for high-stakes legal workflows [6].
</Callout>

## The May 2026 Connector Inventory

The expansion of the MCP ecosystem in May 2026 targeted virtually every segment of the legal market. Understanding this inventory is crucial for knowing what "off-the-shelf" connectors you can leverage versus what you need to build from scratch. The safe source of truth for this chapter is Anthropic's May 12 legal launch and the official `anthropics/claude-for-legal` repository, with partner documentation used only to explain how a named connector behaves in practice [2][3][4].

The list below names 23 legal-specific connectors or legal connector partners supported by LawNext, Anthropic, the official GitHub repository, or the Thomson Reuters launch: Definely, DocuSign / DocuSign CLM, Ironclad, Box, Datasite, iManage, NetDocuments, Lawve AI, Lloyd by The L Suite, TopCounsel by The L Suite, Consilio / Aurora Legal AI, Everlaw, Relativity / RelativityOne, Thomson Reuters CoCounsel Legal, Legal Data Hunter, Midpage, Trellis, Harvey, Solve Intelligence, BoardWise, Courtroom5, Descrybe, and Free Law Project / CourtListener [1][2][3][4][5].

### 1. Contract Lifecycle and Drafting
These connectors manage the lifecycle of an agreement, from initial drafting and negotiation to signature and post-execution auditing.
- **Definely** gives Claude deterministic access to contract structure: definitions, cross-references, dependency maps, and structural diffs [3].
- **DocuSign / DocuSign CLM** connects Claude to agreement data and workflow status across drafting, signature, and post-signature management [3].
- **Ironclad** lets Claude query contract repositories and workflows while scoping results to the user's existing permissions, according to Anthropic's launch description [2].

### 2. Deal Rooms and Transaction Documents
M&A and financing work often happens in controlled data rooms where the audit trail matters as much as retrieval speed.
- **Box** connects Claude to governed content so legal teams can search files, query documents, update content, and extract metadata while enforcing Box access policies [3].
- **Datasite** connects Claude to a virtual data room for folder setup, buyer Q&A tracking, document search, and readiness audits [3].

### 3. Document Management Systems
The document management system is the source of truth for matter files, precedent banks, emails, and institutional knowledge.
- **iManage** gives Claude permission-bound, auditable access to governed matter content without a bulk export [3].
- **NetDocuments** lets Claude search and retrieve repository documents and draft from approved precedents while preserving repository permissions and governance [3].

### 4. Expert Networks and Legal Skills
These connectors do not replace the legal system of record. They connect Claude to specialized expertise, skills, and outside-counsel selection data.
- **Lawve AI** offers a curated library of legal AI skills written by practicing lawyers, in-house counsel, and legal technologists [3][4].
- **Lloyd by The L Suite** connects qualifying L Suite members to the Braintrust member platform inside Claude [3].
- **TopCounsel by The L Suite** helps in-house counsel find outside counsel for a specific matter using The L Suite's proprietary recommendation data [3][4].

### 5. E-Discovery and Review
E-discovery involves searching through large matter datasets: emails, chats, PDFs, spreadsheets, transcripts, and review coding. Connector design here must preserve the matter boundary.
- **Consilio / Aurora Legal AI** makes live matter data and litigation-support workflows available through Claude while scoping output to what the user is entitled to see [3].
- **Everlaw** lets Claude search, organize, and retrieve documents from Everlaw projects using metadata, keywords, and document types, with direct review links back to the source system [2].
- **Relativity / RelativityOne** connects Claude to legal data intelligence workflows such as matter setup, workspace schema, access governance, and usage analysis [3].

### 6. Legal Research, Case Law, and Fiduciary-Grade Workflows
Legal research connectors are only useful if they return provenance. A connector that returns a confident answer without citation-ready source metadata is not production-ready for this domain.
- **Thomson Reuters CoCounsel Legal** connects Claude to a legal AI system backed by Westlaw, Practical Law, and KeyCite content, according to Thomson Reuters' MCP partnership announcement [2][5].
- **Legal Data Hunter**, **Midpage**, and **Trellis** connect Claude to legal corpora, case-law databases, and trial-court datasets that still require citation verification by the legal team [1][2].
- **Harvey** and **Solve Intelligence** expose specialized legal AI capabilities: Harvey for firm legal intelligence and Solve Intelligence for patent, prior-art, and claim-analysis workflows [3].
- **BoardWise**, **Courtroom5**, **Descrybe**, and **Free Law Project / CourtListener** support public-service and access-to-justice use cases, including board matters, pro se litigation guidance, primary-law search, and public court records [1][2][3].

<Callout type="info">
**Connector selection rationale**: This chapter counts only legal-specific connectors named in Anthropic's legal launch, the official `anthropics/claude-for-legal` repository, or legal partner announcements. Generic productivity connectors such as Slack, Google Drive, Linear, Asana, and Jira appear in the broader plugin repository, but they are not counted in the 23-connector legal inventory above. Airwallex is excluded because it is a finance platform, not part of the legal connector inventory [2][4].
</Callout>

## Practice-Area Plugins: Intelligence vs. Infrastructure

There is a critical distinction in the Anthropic ecosystem between an **MCP Connector** and a **Practice-Area Plugin**:
- **Connector**: The technical bridge to a specific platform, data source, or external capability, such as iManage, Everlaw, Ironclad, TopCounsel, or CoCounsel Legal.
- **Plugin**: The domain-specific workflow package: prompts, slash commands, skills, guardrails, and what Anthropic calls "Setup Interviews" [3][4].

### The "Setup Interview" Pattern
Anthropic's 12 legal plugins start with a **Setup Interview**. This is a meta-tool interaction where the plugin asks the legal team about their specific playbooks, risk calibration (e.g., "Are we aggressive or conservative on limitation of liability?"), escalation chains, and house style [3]. This interview calibrates the agent's behavior for all subsequent tasks in that matter.

### The 12 Specialized Domains
1. **Commercial Legal**: Vendor agreements, NDAs, SaaS subscriptions, renewals, escalation routing, and stakeholder summaries.
2. **Corporate Legal**: M&A diligence, disclosure schedules, closing checklists, written consents, entity compliance, and post-close integration.
3. **Employment Legal**: Hiring review, termination review, worker classification, leave tracking, investigations, and policy drafting.
4. **Privacy Legal**: DPA review, DSAR response, privacy impact assessment, privacy triage, and policy drift monitoring.
5. **Product Legal**: Product launch review, marketing claims checks, feature risk assessment, and "is this a problem?" triage.
6. **Regulatory Legal**: Regulatory feed monitoring, change triage, business-impact summaries, and policy update workflows.
7. **AI Governance Legal**: AI use-case triage, AI impact assessments, vendor AI review, and regulation-to-policy gap analysis.
8. **IP Legal**: Patent, trademark, open-source, licensing, and IP clause review workflows.
9. **Litigation Legal**: Claim charts, litigation timelines, legal holds, deposition preparation, and matter workspace workflows.
10. **Law Student**: Socratic practice, IRAC-style memo scaffolding, research planning, and exam-style feedback.
11. **Legal Clinic**: Client intake, research roadmaps, plain-language client letters, deadline tracking, and supervisor review queues.
12. **Legal Builder Hub**: Discovery, installation, freshness checks, and update workflows for community-built legal skills.

The operating rule is simple: a connector fetches or acts; a plugin decides how a legal team wants a repeatable workflow to run. In production, you usually need both. A Litigation Legal plugin may know how to draft a privilege log, but the Everlaw or Relativity connector is what gives it permission-scoped access to matter documents.

## Designing Compliance-First Tool Definitions

When you are tasked with building a custom MCP connector for a legal team, your tool definitions must prioritize data boundary enforcement. 

### Implementation: The Redaction Tool
A common requirement in legal workflows is to reduce unnecessary exposure of PII (Personally Identifiable Information). One implementation pattern is to run a deterministic redaction step before the MCP tool returns text to Claude. That step can live in your MCP server when you control the connector, or in a vendor-side governed workflow when the platform already provides the control. The important design property is not the word "local"; it is that sensitive fields are minimized or transformed before the model receives them, and that the transformation is auditable [6].

<RunPromptCell
  model="claude-sonnet-4-6"
  system="You are an expert MCP server designer reviewing tool definitions for legal compliance."
  prompt="Draft a JSON schema for a hypothetical `redact_document_pii` tool. The tool must accept an absolute document path and a list of PII types (SSN, Name, Phone). Label this as a HYPOTHETICAL TEACHING SCHEMA to avoid confusion with official vendor APIs."
  expectedOutput="A valid MCP tool definition where `document_path` is the primary input and `pii_types` is an enum-constrained array. The description should state that this teaching example performs redaction before returning text to Claude, without implying that every legal connector must use the same deployment boundary."
/>

## Implementation Walkthrough: E-Discovery Search

E-discovery is the process by which parties in a legal case must provide relevant documents to each other. It often involves searching across terabytes of data. Using MCP, we can create a search tool that queries an e-discovery platform like **Everlaw** or **Relativity**.

<RunPromptCell
  model="claude-sonnet-4-6"
  system="You are an expert MCP server designer."
  prompt="Design a hypothetical teaching schema for an e-discovery search tool called `search_discovery_vault`. It should take a `matter_id` and a `query`. Justify the use of `matter_id` as a required field from a security perspective."
  expectedOutput="A tool definition that enforces `matter_id` as a required parameter. The justification should explain that requiring a Matter ID prevents cross-tenant or cross-case data leakage by scoping the search at the protocol level."
/>

### Deployment Choice Does Not Remove Governance
Anthropic's legal launch says the legal templates can be installed in Claude Cowork or Claude Code, and that a subset is available as Claude Platform cookbooks for programmatic deployment [2][3]. Treat deployment mode as an operations choice, not a substitute for governance. The same questions still apply: which connectors are enabled, which user identity is used, what tool calls require confirmation, what data is returned, and where the audit trail lives.

<KnowledgeCheck
  question="What is the primary architectural benefit of using an MCP connector for an e-discovery platform instead of uploading files directly to Claude?"
  options={[
    "It allows Claude to bypass the token limit by reading files in chunks.",
    "It ensures that only relevant snippets are sent to the LLM, maintaining the bulk of the data within the governed system of record.",
    "It is the only way to get Claude to understand legal terminology.",
    "It allows the model to permanently delete files in the source system."
  ]}
  correctIdx={1}
  explanation="MCP connectors act as a secure bridge, querying the system of record and returning only the necessary context. This minimizes data egress and ensures that sensitive files remain within the firm's governed infrastructure."
/>

<KnowledgeCheck
  question="Why is the 'Setup Interview' a critical part of a legal practice-area plugin?"
  options={[
    "It serves as a password to unlock the agent's full capabilities.",
    "It allows the agent to calibrate its risk profile, playbooks, and 'house style' to the specific needs of the legal team.",
    "It is used to verify the user's license to practice law.",
    "It is a mandatory requirement from the Bar Association."
  ]}
  correctIdx={1}
  explanation="Setup interviews provide the meta-context necessary for an agent to align with a specific team's procedural nuances and risk tolerance. Without this, the agent would provide generic advice that might conflict with the firm's internal playbooks."
/>

<KnowledgeCheck
  question="Imagine you are building a 'Regulatory Monitoring' tool for a global bank. Based on what you've learned about MCP and legal connectors, what is the best way to handle PII?"
  options={[
    "Ask Claude in the system prompt to ignore any PII it sees in the regulatory files.",
    "Implement a deterministic redaction layer before returning regulated text to the LLM, using an MCP-server control or an equivalent governed service boundary.",
    "Assume regulatory files never contain PII.",
    "Only use the tool in a sandbox environment where PII doesn't matter."
  ]}
  correctIdx={1}
  explanation="Deterministic redaction or minimization is a stronger risk control than relying on an LLM to follow 'redaction instructions' after it has already seen sensitive data. The exact boundary depends on the connector architecture and the team's governance requirements."
/>

<KnowledgeCheck
  question="Free-form: In two or three sentences, explain the difference between a legal MCP connector and a legal practice-area plugin. Use Everlaw or Relativity as your connector example, and Litigation Legal as your plugin example."
  expectedAnswer="A strong answer says the connector is the permission-scoped bridge to the e-discovery system or matter data, while the plugin is the reusable workflow package that knows how to perform litigation tasks such as intake, legal holds, privilege logs, or deposition prep. It should also mention that the plugin should not bypass connector permissions or attorney review."
/>

## Hands-on Exercise: Build a Document Redactor MCP Tool

In this final exercise of the Builder track, you will scaffold the definition and logic for a tool that protects sensitive legal data.

### 1. Define the Schema
Create a file named `redact_tool_spec.json`. Use the `inputSchema` format to define a tool that takes a `text_input` and a `redaction_level` (e.g., "STRICT", "BASIC").

### 2. Implement Mock Logic
Write a simple Python script using the MCP SDK that:
- Receives the `text_input` from the model.
- Uses a regex to find and replace any string matching an SSN pattern (`XXX-XX-XXXX`) with `[REDACTED]`.
- Returns the cleaned text to the model.

### 3. Verify Success
Execute the tool using a mock input containing an SSN. 
**Success Criteria**:
- The tool must return the redacted text, not the original.
- The tool must log the *fact* that a redaction occurred (for the audit trail) without logging the *original* SSN (for compliance).

## See also
- [[02-beyond-function-calling-understanding-mcp|Chapter 2: Beyond Function Calling — Understanding MCP]]
- [[03-building-your-first-mcp-server|Chapter 3: Building Your First MCP Server]]
- [[05-observability-and-logging-in-mcp|Chapter 5: Observability and Logging in MCP]]
- [[06-security-and-authentication|Chapter 6: Security and Authentication]]
- [[09-smb-connectors|Chapter 9: SMB Connectors]]
- [[blogs/anthropic-legal-mcp-vs-openai-fde-enterprise-wedge/draft|Anthropic Legal MCP vs OpenAI FDE: The Enterprise Wedge]]

## References
[1] Ambrogi, Robert. "Anthropic Goes All-In on Legal, Releasing More Than 20 Connectors and 12 Practice-Area Plugins for Claude." *LawNext*. 2026-05-12 — https://www.lawnext.com/2026/05/anthropic-goes-all-in-on-legal-releasing-more-than-20-connectors-and-12-practice-area-plugins-for-claude.html · retrieved 2026-05-28
[2] Anthropic. "Claude for the legal industry." *Claude Blog*. 2026-05-12 — https://claude.com/blog/claude-for-the-legal-industry · retrieved 2026-05-28
[3] Anthropic. "`anthropics/claude-for-legal` — README.md." *GitHub*. 2026-05 — https://github.com/anthropics/claude-for-legal/blob/main/README.md · retrieved 2026-05-28
[4] Anthropic. "`anthropics/claude-for-legal` — CONNECTORS.md." *GitHub*. 2026-05 — https://github.com/anthropics/claude-for-legal/blob/main/CONNECTORS.md · retrieved 2026-05-28
[5] Thomson Reuters. "Thomson Reuters and Anthropic Expand Partnership to Connect Claude with CoCounsel Legal." 2026-05-12 — https://www.thomsonreuters.com/en/press-releases/2026/may/thomson-reuters-and-anthropic-expand-partnership-to-connect-claude-with-cocounsel-legal · retrieved 2026-05-28
[6] McCallister, Erika; Grance, Tim; Scarfone, Karen. "Guide to Protecting the Confidentiality of Personally Identifiable Information (PII)." *NIST Special Publication 800-122*. 2010 — https://csrc.nist.gov/pubs/sp/800/122/final · retrieved 2026-05-28

## What's next
Congratulations on completing the Builder track! In the final **Capstone Project**, you will apply everything you've learned to build a production-ready MCP "Agentic Connector" that bridges a secure corporate system to Claude, complete with full observability and a documented compliance trail.
