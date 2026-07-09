---
term: "Sandboxing"
definition: "Running code, tools, or agent actions inside a constrained environment to limit filesystem, network, credential, or system access."
seo_description: "Sandboxing: running code, tools, or agent actions inside constrained environments to limit access and reduce operational risk."
category: "Infrastructure"
related_terms: [guardrails, privilege, rbac, confidentiality, audit-trail]
---

Sandboxing limits what an agent or tool can do even when it runs correctly. Instead of trusting that a model will only perform safe operations, a sandbox enforces hard boundaries at the system level: the agent simply cannot access filesystems, network endpoints, credentials, or processes outside its designated scope — regardless of what instructions it receives.

**What a sandbox enforces.** A well-designed sandbox controls filesystem isolation (the process can only read and write a specific directory), network isolation (outbound calls are blocked or routed through an allowlist), process isolation (the agent cannot fork new processes or inspect the host), credential scope (no environment variables containing secrets unless explicitly injected), and resource limits (CPU time, memory, wall-clock duration). Each of these dimensions has independent risk.

**Implementation layers.** Sandboxing can be applied at multiple levels. OS containers (Docker) provide filesystem and network namespacing but share the host kernel. VM-level isolation (Firecracker, gVisor) provides stronger kernel-level separation and is the standard for untrusted code execution. Language-level sandboxes (Deno's permission flags, browser Worker threads) restrict specific runtime capabilities without a full VM. Managed cloud sandboxes (E2B, Modal, AWS Lambda with VPC isolation) handle the infrastructure concern so product teams focus on code rather than container hardening.

**Why prompt-based restrictions are insufficient.** A common misconception is that telling a model "only operate on these files" in the [[system-prompt]] is an adequate safety control. It is not. Prompt injection attacks — where malicious content in a retrieved document or tool response overrides earlier instructions — can cause the model to ignore restrictions. Model error and unexpected reasoning paths can also violate intent without any adversarial input. Sandbox enforcement is orthogonal to prompt engineering: it holds regardless of what the model outputs.

**Relationship to privilege and RBAC.** [[Privilege]] describes which capabilities an agent is entitled to hold. [[Rbac]] assigns those capabilities based on agent role or identity. The sandbox enforces the capability ceiling at runtime. Together, they implement the principle of least privilege: an agent that only needs to read one directory receives a sandbox that only exposes that directory, even if it has broader RBAC entitlements.

**Audit trail inside the sandbox.** All actions taken within a sandbox should be emitted to a structured [[audit-trail]]. This includes file reads, writes, subprocess calls, and outbound network requests. The audit trail is the primary forensic tool when reviewing whether an agent performed unexpected actions. See [[gemini-enterprise-agents]] for enterprise sandbox deployment patterns and [[guardrails]] for the complementary policy layer.

## Related Terms

- [[glossary/guardrails|Guardrails]] — the input/output filters that prevent harmful, off-policy, or malformed agent responses
- [[glossary/privilege|Attorney-Client Privilege]] — the confidentiality protection that restricts access to certain communications
- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/confidentiality|Confidentiality]] — the information-security property that data is accessible only to authorised parties
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
