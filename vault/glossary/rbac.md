---
term: "RBAC (Role-Based Access Control)"
definition: "RBAC is a security model that restricts system access based on the roles assigned to individual users or agents within an organization, rather than assigning permissions directly to users."
seo_description: "RBAC explained: role-based security for AI agents."
category: "security"
related_terms: [ai-gateway, audit-trail, agent-harness]
related_courses: [gemini-enterprise-agents]
---

RBAC replaces the complexity of per-identity permission lists with a two-step indirection: identities are assigned to roles, and roles are granted permissions. A "ReadOnly Analyst" role might allow querying a database and reading documents but block any write or delete tool. An "Admin" role adds destructive capabilities. When a new agent is provisioned, you assign it a role — not a bespoke permission set — which keeps governance manageable at scale.

**RBAC vs. ABAC.** Attribute-Based Access Control (ABAC) makes access decisions on dynamic attributes — user department, document classification, time of day. RBAC is simpler and easier to audit; ABAC is more expressive. Most enterprise agent deployments start with RBAC and layer ABAC only where fine-grained context-sensitivity is genuinely required, because ABAC policies are significantly harder to reason about in an [[audit-trail]].

**Least privilege and agents.** The least-privilege principle — grant only the minimum permissions needed to complete a task — is especially critical for autonomous agents. Unlike a human who self-censors, an agent will call any tool its role permits. If a summarization agent has been granted file-delete permissions it never actually needs, a prompt injection or reasoning error can silently destroy data. Every role definition should be challenged with: "what is the worst action an agent in this role could take, and is that acceptable?"

**RBAC in [[mcp]] tool permissions.** In an MCP-based architecture, tool availability is the primary enforcement point. An agent authenticates to the MCP gateway, which checks its role and returns only the subset of tools that role allows. The agent's [[context-window]] never contains tool definitions it cannot use, which also reduces prompt noise and lowers the chance of the model attempting unauthorized operations.

**[[sandboxing]] and [[privilege]] escalation.** RBAC defines what is permitted; [[sandboxing]] enforces the boundary at the execution layer. Together they form defense in depth. RBAC alone does not prevent an agent from exploiting a vulnerability in a permitted tool — the sandbox limits blast radius if that happens.

**Role sprawl — the common misconception.** RBAC is often treated as a one-time setup. In practice, roles accumulate over time as exceptions are added for individual agents. Regular role audits — checking that every permission in every role is still actively required — are as important as the initial design. Stale over-permissive roles are a leading cause of [[confidentiality]] breaches in agentic systems.

See [[gemini-enterprise-agents]] for how enterprise agent platforms implement role-based tool gating in production deployments.

## Related Terms

- [[glossary/ai-gateway|AI Gateway]] — the proxy layer that centralises auth, rate-limiting, logging, and model routing
- [[glossary/audit-trail|Audit Trail]] — the immutable chronological record of every action taken, enabling forensic review
- [[glossary/agent-harness|Agent harness]] — the software framework that runs the agent loop with tools and stopping criteria
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
