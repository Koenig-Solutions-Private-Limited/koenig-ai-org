---
chapter_num: 8
title: "Legal and Regulatory Connectors in MCP"
slug: 08-legal-connectors
status: g0-blocked
tags:
  - mcp
  - legal
  - connectors
  - compliance
learning_objectives:
  - "Explain the regulatory requirements for handling legal documents via MCP"
  - "Implement document redaction and audit trails using MCP tools"
  - "Configure secure interfaces for industry-standard legal technology platforms"
  - "Deploy practice-area plugins for specialized legal workflows in Claude Cowork"
prerequisites_chapters:
  - "Chapter 7: Creative Connectors"
duration_min: 60
description: "Master the integration of Claude with specialized legal technology using MCP, covering 20+ enterprise connectors and 12 practice-area plugins for compliant, secure legal workflows."
faq:
  - q: "Can Claude access confidential case data without moving it to the cloud?"
    a: "Yes, by using local MCP servers that query systems of record like iManage or Relativity."
  - q: "What is the difference between an MCP connector and a practice-area plugin?"
    a: "Connectors provide the technical bridge to data sources (e.g., DocuSign), while plugins provide domain-specific prompts, guardrails, and playbooks (e.g., IP Legal)."
  - q: "Does Anthropic offer programmatic access to legal plugins?"
    a: "A subset of plugins (Commercial, Corporate, Litigation, Product) are available as cookbooks for deployment via the Claude API as Managed Agents."
---

# Chapter 8: Legal and Regulatory Connectors in MCP

Legal technology ("LegalTech") represents one of the most high-stakes environments for the Model Context Protocol (MCP). In May 2026, Anthropic released over 20 specialized MCP connectors and 12 practice-area plugins for **Claude Cowork**, enabling legal professionals to interact with documents, communications, and records tied to specific matters [1][3].

## Why Legal Connectors Matter

Legal work runs on a specific technology stack: contract lifecycle systems, research platforms, document management, and e-discovery. MCP connectors bring this data into Claude without requiring bulk exports or custom integrations, ensuring that work stays within governed environments [3].

Tools handling legal documents must be explicit about their data bounds. For example, a redaction tool can be implemented within an MCP server to ensure sensitive information is stripped before it reaches the LLM [4].

## Connector Inventory

Anthropic's May 2026 expansion includes connectors that link Claude to industry-standard software while respecting existing security and access policies [3].

- **Contract & CLM**: Ironclad, DocuSign, Definely, Airwallex.
- **E-discovery & Litigation**: Relativity, Everlaw, Consilio.
- **Document Management**: iManage, NetDocuments, Box, Datasite.
- **Legal Research**: Thomson Reuters CoCounsel (bidirectional), Midpage, Trellis, Legal Data Hunter.
- **IP & Specialized**: Harvey, Solve Intelligence.
- **Public Service**: Courtroom5, BoardWise, Free Law Project, Descrybe.

The Thomson Reuters integration allows Claude to call CoCounsel Legal as a tool, grounding outputs in Westlaw primary law and Practical Law guidance [3].

## Practice-Area Plugins

Anthropic's 12 legal plugins bundle pre-configured prompts and "setup interviews" that learn a team's specific playbooks, escalation chains, and risk calibration [1][3].

### The 12 Specialized Domains
- **Commercial Legal**: Reviews vendor agreements and NDAs against playbooks and routes escalations.
- **Corporate Legal**: Handles M&A diligence, disclosure schedules, and closing checklists.
- **Employment Legal**: Covers hires, terminations, and leave deadlines; drafts policies.
- **Privacy Legal**: Reviews DPAs and PIAs; prepares DSAR responses.
- **Product Legal**: Runs launch reviews and checks marketing claims.
- **Regulatory Legal**: Monitors regulatory developments and compares rules against policy libraries.
- **AI Governance Legal**: Triages AI use cases and runs impact assessments.
- **IP Legal**: Conducts trademark clearance and drafts cease-and-desist letters.
- **Litigation Legal**: Manages matter intake, legal holds, and privilege logs.
- **Law Student**: Provides Socratic drilling and IRAC grading.
- **Legal Clinic**: Manages client intake and case memos.
- **Legal Builder Hub**: Repository for community-built legal skills.

## Designing Compliance-First Tool Definitions

Tools handling legal documents must behave deterministically. A "redact" tool, for instance, should strip PII locally within the MCP server boundary.

### <RunPromptCell> Example: Redaction Tool Definition
> [!note] Illustrative API — verify against Anthropic docs when published

```json
{
    "name": "redact_document_pii",
    "description": "Redacts SSNs and Names from a local document before LLM egress.",
    "inputSchema": {
        "type": "object",
        "properties": {
            "document_path": {"type": "string", "description": "Absolute path to local doc"},
            "pii_types": {"type": "array", "items": {"type": "string"}}
        },
        "required": ["document_path"]
    }
}
```
**Expected Output**: A valid MCP tool registration schema for local redaction.
</RunPromptCell>

[KnowledgeCheck]
1. How do MCP connectors help maintain data governance in legal workflows?
2. [Free-form] Why is the "setup interview" important for practice-area plugins?

[Callout type="warning"]
**Never log raw PII.** Audit trails should store *meta-context* (e.g., "User A accessed File B") rather than the sensitive contents of the file itself.
[/Callout]

## Implementation Walkthrough: E-Discovery Search

In a litigation context, an MCP connector for a platform like **Everlaw** or **Relativity** allows a legal team to search across case data using natural language queries while enforcing existing access policies [3].

### <RunPromptCell> Example: E-Discovery Search
> [!note] Illustrative API — verify against Anthropic docs when published

```json
{
    "name": "search_everlaw_matter",
    "description": "Searches for relevant documents within a specific Everlaw matter.",
    "inputSchema": {
        "type": "object",
        "properties": {
            "matter_id": {"type": "string"},
            "query": {"type": "string", "description": "Natural language query"}
        },
        "required": ["matter_id", "query"]
    }
}
```
**Expected Output**: JSON-RPC tool registration for an e-discovery search tool.
</RunPromptCell>

## Hands-on exercise

Build a document redaction tool:
1. Define a tool schema in `json` that takes a document path and a list of PII types (e.g., SSN, name).
2. Implement a mock redaction service that redacts PII using regex.
3. Verify the redaction by inspecting the file output before and after.
4. **Success Criteria**: The tool must be defined as `read-only` for the original file, outputting the redacted version to a separate secure path.

## See also

- [[courses/claude-tool-use-from-zero/02-beyond-function-calling-understanding-mcp]]
- [[courses/claude-tool-use-from-zero/05-observability-and-logging-in-mcp]]
- [[courses/claude-tool-use-from-zero/06-security-and-authentication]]
- [[blogs/anthropic-legal-mcp-vs-openai-fde-enterprise-wedge]]

## References

1. Ambrogi, Robert. "Anthropic Goes All-In on Legal, Releasing More Than 20 Connectors and 12 Practice-Area Plugins for Claude." *LawNext*. 2026-05-12. [Link](https://www.lawnext.com/2026/05/anthropic-goes-all-in-on-legal-releasing-more-than-20-connectors-and-12-practice-area-plugins-for-claude.html) (retrieved 2026-05-13)
2. Anthropic. "The AI legal services industry is heating up." *TechCrunch*. 2026-05-12. [Link](https://techcrunch.com/2026/05/12/the-ai-legal-services-industry-is-heating-up-anthropic-is-getting-in-on-the-action/) (retrieved 2026-05-13)
3. Anthropic. "Claude for the legal industry." *Claude Blog*. 2026-05-12. [Link](https://claude.com/blog/claude-for-the-legal-industry) (retrieved 2026-05-14)
4. Anthropic. "Claude Security is now in public beta." *Claude Blog*. 2026-04-30. [Link](https://claude.com/blog/claude-security-public-beta) (retrieved 2026-05-14)

## What's next
In the next module, we will apply these patterns to capstone projects, enabling you to build fully-featured, production-grade agentic connectors.
