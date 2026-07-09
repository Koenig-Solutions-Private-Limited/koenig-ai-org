---
chapter_num: 8
course_slug: claude-tool-use-from-zero
title: "Legal and Regulatory Connectors in MCP"
slug: 08-legal-connectors
status: g4-approved
last_updated: "2026-06-10"
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
description: "The definitive guide to integrating Claude with the legal technology stack. Master 20+ enterprise connectors, 12 practice-area plugins, and compliance-first tool design for secure, agentic legal workflows."
first_60_words_answer: "Legal MCP connectors let Claude query legal systems of record—contract repositories, document management systems, e-discovery platforms, and research databases—without requiring bulk data export. The governance constraint is that connectors preserve matter boundaries, user permissions, source provenance, and auditability. Connecting Claude to legal data does not make the data less sensitive."
positions:
  - stance_id: mcp-as-interoperability-moat
    mode: defends
  - stance_id: audit-trail-as-enterprise-gate
    mode: defends
sources:
  - url: "https://www.lawnext.com/2026/05/anthropic-goes-all-in-on-legal-releasing-more-than-20-connectors-and-12-practice-area-plugins-for-claude.html"
    title: "Anthropic Goes All-In on Legal — LawNext"
  - url: "https://techcrunch.com/2026/05/12/the-ai-legal-services-industry-is-heating-up-anthropic-is-getting-in-on-the-action/"
    title: "The AI Legal Services Industry Is Heating Up — TechCrunch"
  - url: "https://claude.com/blog/claude-for-the-legal-industry"
    title: "Claude for the legal industry — Claude Blog"
  - url: "https://github.com/anthropics/claude-for-legal/blob/main/CONNECTORS.md"
    title: "anthropics/claude-for-legal CONNECTORS.md — GitHub"
  - url: "https://www.lawnext.com/2026/05/two-legal-research-providers-launch-mcp-integrations-with-claude-thomson-reuters-and-free-law-project-connect-their-data-to-ai.html"
    title: "Two Legal Research Providers Launch MCP Integrations with Claude — LawNext"
  - url: "https://csrc.nist.gov/pubs/sp/800/122/final"
    title: "Guide to Protecting the Confidentiality of PII — NIST SP 800-122"
  - url: "https://www.everlaw.com/blog/ai-and-advanced-analytics/anthropic-mcp-integration/"
    title: "Anthropic MCP integration — Everlaw"
  - url: "https://github.com/modelcontextprotocol/typescript-sdk"
    title: "TypeScript SDK — GitHub"
key_concepts:
  - legal MCP connector inventory
  - practice-area plugins
  - deterministic redaction
  - matter-scoped authorization
  - audit-safe tool design
hands_on_exercise: "Build a mock legal document redaction tool that strips SSNs before returning text to Claude and logs only redaction metadata."
faq:
  - question: "What does MCP query-in-place mean for legal data?"
    answer: "Query-in-place means Claude retrieves context from legal systems of record—contract repositories, e-discovery platforms, document management systems—without requiring bulk export of the underlying files. The connector issues targeted queries and returns only relevant content to the model, so sensitive matter data stays within the firm's governed infrastructure [3]."
  - question: "Why is deterministic redaction required rather than asking the LLM to handle PII?"
    answer: "Deterministic controls—regexes, checksums, or dedicated PII-detection services—apply consistent, auditable transformations before sensitive material reaches the model. Asking an LLM to 'ignore' PII after seeing it is a probabilistic approach prone to silent failure. NIST SP 800-122 frames PII confidentiality as a lifecycle risk-control problem, not a prompt-instruction problem [6]."
  - question: "What is the difference between a legal MCP connector and a practice-area plugin?"
    answer: "A connector is the technical bridge to a specific platform—such as Everlaw for e-discovery or iManage for document management—providing permission-scoped, auditable access to data. A practice-area plugin is the domain-specific workflow package: the Setup Interview, prompts, guardrails, and escalation logic a legal team runs on top of one or more connectors to produce consistent, repeatable legal work [3][4]."
quiz:
  - question: "What problem does MCP's query-in-place model solve for legal workflows?"
    options:
      - "It eliminates the need for matter-scoped authorization by granting Claude shared read permissions"
      - "It allows Claude to query legal systems without bulk-exporting sensitive matter files from governed infrastructure"
      - "It provides automatic PII redaction before any sensitive legal content reaches the model context"
      - "It transfers legal document storage to Anthropic's servers for lower-latency inference performance"
    correct_idx: 1
    explanation: "Query-in-place means Claude retrieves targeted context from e-discovery platforms, contract repositories, and document management systems without bulk-exporting underlying files. Sensitive matter data stays within the firm's governed infrastructure. The connector does not eliminate authorization requirements, provide automatic redaction, or move documents to Anthropic."
    section_anchor: why-legal-connectors-matter-the-stakes-of-data-bound
  - question: "Why is deterministic redaction required rather than instructing the LLM to ignore PII in legal documents?"
    options:
      - "LLMs lack the context window capacity to process unredacted legal documents of typical enterprise length"
      - "Deterministic controls apply consistent, auditable transformations before sensitive data reaches the model"
      - "The MCP protocol specification explicitly prohibits passing PII in tool response payload fields"
      - "Anthropic's API charges a higher inference rate for requests that contain personal identifiers"
    correct_idx: 1
    explanation: "Deterministic controls — regex patterns, checksum verification, PII-detection services — apply consistent, auditable transformations every time. Asking an LLM to 'ignore' PII is a probabilistic approach prone to silent failure. NIST SP 800-122 frames PII confidentiality as a lifecycle risk-control problem, not a prompt-instruction problem."
    section_anchor: designing-compliance-first-tool-definitions
  - question: "What distinguishes a legal MCP connector from a practice-area plugin?"
    options:
      - "A connector packages domain workflow skills and prompts; a plugin is the technical platform bridge"
      - "A connector bridges Claude to a specific legal platform; a plugin packages domain workflow skills and agents"
      - "Connectors are available only on free tiers; plugins require enterprise licensing agreements to access"
      - "Connectors deliver prompts and guardrails; plugins deliver only low-level raw API bindings"
    correct_idx: 1
    explanation: "The claude-for-legal repository distinguishes connector infrastructure (the technical bridge to platforms like Everlaw or iManage) from plugin workflow packages (the Setup Interview, prompts, guardrails, and escalation logic for a practice area). Plugins sit on top of connectors. Licensing tier and scope of prompts are not the distinguishing criterion."
    section_anchor: key-facts
---

# Chapter 8: Legal and Regulatory Connectors in MCP

Legal MCP connectors let Claude work against legal systems of record: contract repositories, document management systems, e-discovery projects, research databases, deal rooms, and public-law datasets. The constraint is that the connector does not make the legal system less sensitive. The connector still has to preserve matter boundaries, user permissions, source provenance, review obligations, and auditability.

On May 12, 2026, Anthropic announced 20+ MCP connectors for legal software and 12 practice-area plugins for Claude, including connectors across contract lifecycle, document management, e-discovery, research, data-room, expert-network, and access-to-justice workflows [1][2][3][4]. This chapter is about the design rule behind that launch: legal connectors should make governed retrieval and workflow execution easier without turning Claude into the system of record.

## Key facts

1. Anthropic's May 12, 2026 legal launch introduced 20+ MCP connectors and 12 legal practice-area plugins; LawNext and Anthropic describe the same release as spanning contract systems, DMS, e-discovery, research, public-service, and expert-network categories [1][3].
2. The `anthropics/claude-for-legal` repository packages practice-area plugin directories for commercial, corporate, employment, privacy, product, regulatory, AI governance, IP, litigation, law-student, legal-clinic, and legal-builder-hub workflows [4].
3. The repository's connector map distinguishes connector infrastructure from plugin workflow packages: connectors wire Claude to data sources, while plugins package skills, agents, hooks, and practice profiles [4].
4. Thomson Reuters separately announced an MCP integration connecting Claude to CoCounsel Legal, with Westlaw, Practical Law, and KeyCite named as the professional content backbone for that partnership [5].
5. NIST SP 800-122 frames PII confidentiality as a lifecycle problem involving collection, use, retention, sharing, and disposal; this chapter applies that risk-control framing to legal MCP tool responses [6].

## Why Legal Connectors Matter: The Stakes of "Data Bound"

Legal work runs on a highly specialized technology stack: contract lifecycle management (CLM) systems, e-discovery platforms, document management systems (DMS), and primary law research databases. Historically, bringing LLM intelligence to this data required bulk exports—moving sensitive files out of their governed environments and into the cloud for processing.

```takeaways
- MCP's query-in-place model lets Claude retrieve targeted context from legal systems without bulk-exporting sensitive matter files out of governed infrastructure.
- The connector does not reduce the sensitivity of the data — matter boundaries, user permissions, source provenance, and audit obligations all remain in force.
- Legal connectors must preserve the system of record's access controls rather than bypassing them at the protocol layer.
```

MCP changes this paradigm. By defining tools that act as "pipes" to existing systems, Claude can query these systems in real-time without ever requiring the bulk migration of the underlying data. This "query-in-place" model is the foundation of modern Legal AI [3].

### The Principle of Deterministic Tooling
In legal contexts, tools must behave deterministically. If a lawyer asks Claude to "Redact this document," they aren't looking for a "best effort" or a "creative interpretation" of what should be hidden. They require a tool that follows a strict, auditable protocol locally within the MCP server boundary before any text ever egresses to the LLM. 

When designing legal tools, we prioritize **deterministic logic over probabilistic reasoning**. For example, a redaction tool should use verified PII-detection libraries or regex patterns on the server side, returning only the cleaned text to the model.

<Callout type="warn">
**Deterministic vs. Probabilistic**: Redaction in a legal context should rely on deterministic methods (regex, checksums, or dedicated PII-detection models) running on the MCP server, rather than asking the LLM to "ignore" PII in the prompt. Asking an LLM to redact data is prone to failure; stripping it before the model sees it is the only compliant path [6].
</Callout>

## The May 2026 Connector Inventory

The expansion of the MCP ecosystem in May 2026 targeted virtually every segment of the legal market. Understanding this inventory is crucial for knowing what "off-the-shelf" connectors you can leverage versus what you need to build from scratch. The safe source of truth for this chapter is Anthropic's May 12 legal launch announcement [1][3], with partner documentation used only to explain how a named connector behaves in practice.

### 1. Contract Lifecycle and Drafting
These connectors manage the lifecycle of an agreement, from initial drafting and negotiation to signature and post-execution auditing.
- **Definely** gives Claude deterministic access to contract structure: definitions, cross-references, dependency maps, and structural diffs [3].
- **DocuSign / DocuSign CLM** connects Claude to agreement data and workflow status across drafting, signature, and post-signature management [3].
- **Ironclad** lets Claude query contract repositories and workflows while scoping results to the user's existing permissions, according to Anthropic's legal launch [3].

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
- **Everlaw** lets Claude search, organize, and retrieve documents from Everlaw projects using metadata, keywords, and document types, with direct review links back to the source system [3][7].
- **Relativity / RelativityOne** connects Claude to legal data intelligence workflows such as matter setup, workspace schema, access governance, and usage analysis [3].

### 6. Legal Research, Case Law, and Fiduciary-Grade Workflows
Legal research connectors are only useful if they return provenance. A connector that returns a confident answer without citation-ready source metadata is not production-ready for this domain.
- **Thomson Reuters CoCounsel Legal** connects Claude to a fiduciary-grade legal AI system grounded in Westlaw primary law, Practical Law guidance, KeyCite, and customer documents [3][5].
- **Legal Data Hunter**, **Midpage**, and **Trellis** connect Claude to legal corpora, case-law databases, and trial-court datasets with source links for verification [3].
- **Harvey** and **Solve Intelligence** expose specialized legal AI capabilities: Harvey for firm legal intelligence and Solve Intelligence for patent, prior-art, and claim-analysis workflows [3].
- **BoardWise**, **Courtroom5**, **Descrybe**, and **Free Law Project / CourtListener** support public-service and access-to-justice use cases, including board matters, pro se litigation guidance, primary-law search, and public court records [3][5].

<Callout type="info">
**Connector selection rationale**: This chapter counts only legal-specific connectors named in Anthropic's public launch announcement [1][3]. Thomson Reuters, Datasite, and Relativity appear in that announcement; note that the `anthropics/claude-for-legal` CONNECTORS.md repository lists them in a "Wanted" (not-yet-shipped) section—inventory here follows the public announcement, not the repo's shipped connectors. Generic productivity connectors such as Slack, Google Drive, Linear, Asana, and Jira are not counted as legal-specific connectors. Airwallex is excluded because it is a finance platform [1][3].
</Callout>

## Practice-Area Plugins: Intelligence vs. Infrastructure

There is a critical distinction in the Anthropic ecosystem between an **MCP Connector** and a **Practice-Area Plugin**:
- **Connector**: The technical bridge to a specific platform, data source, or external capability, such as iManage, Everlaw, Ironclad, TopCounsel, or CoCounsel Legal.
- **Plugin**: The domain-specific workflow package: prompts, slash commands, skills, guardrails, and what Anthropic calls "Setup Interviews" [3][4].

```takeaways
- A connector is the permission-scoped technical bridge to a specific platform; a plugin is the reusable workflow package that runs on top of one or more connectors.
- In production you typically need both: the plugin knows how to perform the legal task, but the connector provides the permission-scoped access to the matter data.
- The Setup Interview pattern calibrates a plugin's risk profile, playbooks, and house style before any task begins, making subsequent agent behavior consistent with firm procedure.
```

### The "Setup Interview" Pattern
Anthropic's 12 legal plugins start with a **Setup Interview**. This is a meta-tool interaction where the plugin asks the legal team about their specific playbooks, risk calibration (e.g., "Are we aggressive or conservative on limitation of liability?"), escalation chains, and house style [3]. This interview calibrates the agent's behavior for all subsequent tasks in that matter.

### The 12 Specialized Domains
1. **Commercial Legal**: Specialized in vendor agreements, NDAs, and Master Service Agreements.
2. **Corporate Legal**: Handles the heavy lifting of M&A diligence, disclosure schedules, and closing checklists.
3. **Employment Legal**: Manages the complexities of HR law, termination policies, and leave deadlines.
4. **Privacy Legal**: Specifically designed for DPA (Data Processing Agreement) reviews and GDPR/CCPA compliance.
5. **Product Legal**: Clears marketing claims and runs product launch reviews for compliance with consumer protection laws.
6. **Regulatory Legal**: Monitors the "Federal Register" and local equivalents to flag policy changes affecting the business.
7. **AI Governance Legal**: A new category for 2026, triaging AI use cases and conducting mandatory impact assessments.
8. **IP Legal**: Trademark clearance, patent landscape analysis, and cease-and-desist drafting.
9. **Litigation Legal**: Privilege logs, legal hold management, and matter intake.
10. **Law Student**: Socratic drilling and IRAC (Issue, Rule, Application, Conclusion) grading.
11. **Legal Clinic**: Pro-bono intake and case memo generation for non-profit entities.
12. **Legal Builder Hub**: Finds and installs community-built legal skills with security, license, and freshness checks.

The operating rule is simple: a connector fetches or acts; a plugin decides how a legal team wants a repeatable workflow to run. In production, you usually need both. A Litigation Legal plugin may know how to draft a privilege log, but the Everlaw or Relativity connector is what gives it permission-scoped access to matter documents.

## Designing Compliance-First Tool Definitions

When you are tasked with building a custom MCP connector for a legal team, your tool definitions must prioritize data boundary enforcement. 

```takeaways
- Deterministic redaction (regex, checksums, dedicated PII-detection models) must run on the MCP server before text reaches the model — asking the LLM to "ignore" PII is a probabilistic control that fails silently.
- NIST SP 800-122 frames PII confidentiality as a lifecycle risk problem involving collection, use, retention, sharing, and disposal — not a prompt-instruction problem.
- A narrow redaction tool should name the matter boundary, the supported redaction types, and the audit behavior explicitly rather than accepting arbitrary text with vague instructions.
```

### Implementation: The Redaction Tool
A core requirement in legal workflows is to ensure PII (Personally Identifiable Information) never leaves the local environment. A redaction tool should be a "local-first" tool—logic that runs on the MCP server and strips data *before* it is returned to Claude.

<RunPromptCell
  model="claude-sonnet-4-6"
  system="You are an expert MCP server designer reviewing tool definitions for legal compliance."
  prompt="Draft a JSON schema for a hypothetical `redact_document_pii` tool. The tool must accept an absolute document path and a list of PII types (SSN, Name, Phone). Label this as a HYPOTHETICAL TEACHING SCHEMA to avoid confusion with official vendor APIs."
  expectedOutput="A valid MCP tool definition where `document_path` is the primary input and `pii_types` is an enum-constrained array. The description must emphasize that processing happens locally on the server."
/>

### Runnable Example: A Local Legal Redaction MCP Server

The schema above is useful for design review, but legal connectors become real only when the boundary is enforced in code. The official TypeScript SDK exposes `McpServer` for registering tools and `StdioServerTransport` for local MCP servers, which makes it a good fit for a small teaching connector that you can run from a terminal [8]. The example below is intentionally narrow: it redacts U.S. Social Security Number patterns from text that belongs to a matter, returns only cleaned text to the client, and records an audit event without storing the raw identifier.

This is not a vendor API and not legal advice. It is a runnable MCP server pattern for the control-plane behavior you want around legal data.

Create a fresh folder:

```bash
mkdir legal-redaction-mcp
cd legal-redaction-mcp
npm init -y
npm install @modelcontextprotocol/sdk zod
npm install -D typescript tsx @types/node
```

Then edit `package.json` so Node treats the file as an ES module and gives you a start command:

```json
{
  "type": "module",
  "scripts": {
    "start": "tsx server.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "latest",
    "zod": "latest"
  },
  "devDependencies": {
    "@types/node": "latest",
    "tsx": "latest",
    "typescript": "latest"
  }
}
```

Now create `server.ts`:

```ts
import { createHash } from "node:crypto";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const ssnPattern = /\b\d{3}-\d{2}-\d{4}\b/g;

type AuditEvent = {
  matterId: string;
  redactionType: "SSN";
  count: number;
  fingerprints: string[];
  occurredAt: string;
};

const auditLog: AuditEvent[] = [];

function fingerprint(value: string) {
  return createHash("sha256").update(value).digest("hex").slice(0, 16);
}

function redactSsn(text: string) {
  const matches = Array.from(text.matchAll(ssnPattern), (match) => match[0]);
  return {
    redactedText: text.replace(ssnPattern, "[REDACTED_SSN]"),
    matches
  };
}

const server = new McpServer({
  name: "legal-redaction-teaching-server",
  version: "0.1.0"
});

server.tool(
  "redact_legal_text",
  "Redact SSN patterns locally before text is returned to Claude. This teaching tool never logs raw SSNs.",
  {
    matter_id: z
      .string()
      .regex(/^MAT-\d{4}$/)
      .describe("Matter identifier used to keep the audit trail scoped, for example MAT-2042."),
    text: z
      .string()
      .min(1)
      .describe("Legal text to redact locally inside the MCP server process.")
  },
  async ({ matter_id, text }) => {
    const result = redactSsn(text);
    auditLog.push({
      matterId: matter_id,
      redactionType: "SSN",
      count: result.matches.length,
      fingerprints: result.matches.map(fingerprint),
      occurredAt: new Date().toISOString()
    });

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              matter_id,
              redacted_text: result.redactedText,
              redaction_count: result.matches.length,
              audit_event: auditLog.at(-1)
            },
            null,
            2
          )
        }
      ]
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

You can connect this server to any MCP-compatible client that supports stdio servers. For example, a local client configuration can point to `npm start` in this folder. Once connected, ask the client to call:

```json
{
  "matter_id": "MAT-2042",
  "text": "Witness Jane Doe listed 123-45-6789 in the intake packet."
}
```

The expected tool result is:

```json
{
  "matter_id": "MAT-2042",
  "redacted_text": "Witness Jane Doe listed [REDACTED_SSN] in the intake packet.",
  "redaction_count": 1,
  "audit_event": {
    "matterId": "MAT-2042",
    "redactionType": "SSN",
    "count": 1,
    "fingerprints": ["01a54629efb95228"],
    "occurredAt": "2026-05-28T00:00:00.000Z"
  }
}
```

Your exact fingerprint and timestamp will differ, but two facts must stay invariant: the returned text must not contain the original SSN, and the audit record must describe what happened without logging the raw value. This follows the PII minimization logic in NIST SP 800-122: reduce collection, exposure, and retention of sensitive identifiers wherever possible [6].

<Callout type="warn">
Do not expand this teaching server into a broad `redact_anything` tool. Production legal connectors should name the matter boundary, supported redaction types, confirmation requirements, and audit behavior explicitly. A tool that accepts arbitrary text and vague instructions pushes compliance back onto the model.
</Callout>

## Implementation Walkthrough: E-Discovery Search

E-discovery is the process by which parties in a legal case must provide relevant documents to each other. It often involves searching across terabytes of data. Using MCP, we can create a search tool that queries an e-discovery platform like **Everlaw** or **Relativity**.

<RunPromptCell
  model="claude-sonnet-4-6"
  system="You are an expert MCP server designer."
  prompt="Design a hypothetical teaching schema for an e-discovery search tool called `search_discovery_vault`. It should take a `matter_id` and a `query`. Justify the use of `matter_id` as a required field from a security perspective."
  expectedOutput="A tool definition that enforces `matter_id` as a required parameter. The justification should explain that requiring a Matter ID prevents cross-tenant or cross-case data leakage by scoping the search at the protocol level."
/>

### Managed Agents for Legal
For teams that prefer not to maintain their own MCP server infrastructure, Anthropic says a subset of the legal plugins can also be deployed as **Managed Agents** through Claude Platform cookbooks [3]. Treat this as a deployment option, not a substitute for governance. The same questions still apply: which connectors are enabled, which user identity is used, what tool calls require confirmation, and where the audit trail lives.

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
    "Implement a deterministic redaction layer locally on the MCP server that strips PII before returning text to the LLM.",
    "Assume regulatory files never contain PII.",
    "Only use the tool in a sandbox environment where PII doesn't matter."
  ]}
  correctIdx={1}
  explanation="Deterministic, local-first redaction is the only compliant path for high-stakes legal and financial data. Relying on an LLM to follow 'redaction instructions' is a probabilistic approach that is prone to failure and leakage."
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
- [[05-observability-and-logging-in-mcp|Chapter 5: Observability and Logging in MCP]]
- [[06-security-and-authentication|Chapter 6: Security and Authentication]]
- [[blogs/anthropic-legal-mcp-vs-openai-fde-enterprise-wedge/draft|Anthropic Legal MCP vs OpenAI FDE: The Enterprise Wedge]]

## References
1. Ambrogi, Robert. "Anthropic Goes All-In on Legal, Releasing More Than 20 Connectors and 12 Practice-Area Plugins for Claude." *LawNext*. 2026-05-12. [Anthropic Goes All-In on Legal — LawNext](https://www.lawnext.com/2026/05/anthropic-goes-all-in-on-legal-releasing-more-than-20-connectors-and-12-practice-area-plugins-for-claude.html) (retrieved 2026-05-13).
2. Ropek, Lucas. "The AI legal services industry is heating up. Anthropic is getting in on the action." *TechCrunch*. 2026-05-12. [The AI Legal Services Industry Is Heating Up — TechCrunch](https://techcrunch.com/2026/05/12/the-ai-legal-services-industry-is-heating-up-anthropic-is-getting-in-on-the-action/) (retrieved 2026-05-14).
3. Anthropic. "Claude for the legal industry." *Claude Blog*. 2026-05-12. [Claude for the legal industry — Claude Blog](https://claude.com/blog/claude-for-the-legal-industry) (retrieved 2026-05-14).
4. Anthropic. "`anthropics/claude-for-legal` — CONNECTORS.md." *GitHub*. 2026-05. [anthropics/claude-for-legal CONNECTORS.md — GitHub](https://github.com/anthropics/claude-for-legal/blob/main/CONNECTORS.md) (retrieved 2026-05-14).
5. Ambrogi, Robert. "Two Legal Research Providers Launch MCP Integrations with Claude." *LawNext*. 2026-05-12. [Two Legal Research Providers Launch MCP Integrations with Claude — LawNext](https://www.lawnext.com/2026/05/two-legal-research-providers-launch-mcp-integrations-with-claude-thomson-reuters-and-free-law-project-connect-their-data-to-ai.html) (retrieved 2026-05-14).
6. McCallister, Erika; Grance, Tim; Scarfone, Karen. "Guide to Protecting the Confidentiality of Personally Identifiable Information (PII)." *NIST Special Publication 800-122*. 2010. [Guide to Protecting the Confidentiality of PII — NIST SP 800-122](https://csrc.nist.gov/pubs/sp/800/122/final) (retrieved 2026-05-14).
7. Everlaw. "Anthropic MCP integration." *Everlaw*. 2026-05. [Anthropic MCP integration — Everlaw](https://www.everlaw.com/blog/ai-and-advanced-analytics/anthropic-mcp-integration/) (retrieved 2026-05-14).
8. Model Context Protocol. "TypeScript SDK." *GitHub*. [TypeScript SDK — GitHub](https://github.com/modelcontextprotocol/typescript-sdk) (retrieved 2026-05-28).

## What's next
Congratulations on completing the Builder track! In the final **Capstone Project**, you will apply everything you've learned to build a production-ready MCP "Agentic Connector" that bridges a secure corporate system to Claude, complete with full observability and a documented compliance trail.
