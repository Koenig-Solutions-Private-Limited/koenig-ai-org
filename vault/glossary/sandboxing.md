---
term: "Sandboxing"
definition: "Running code, tools, or agent actions inside a constrained environment to limit filesystem, network, credential, or system access."
seo_description: "Sandboxing: running code, tools, or agent actions inside constrained environments to limit access and reduce operational risk."
category: "Infrastructure"
related_terms: [guardrails, privilege, rbac, confidentiality, audit-trail]
---

Sandboxing reduces the blast radius of mistakes or malicious inputs. A coding agent, browser agent, or data-processing tool may be allowed to operate only in a temporary directory, a container, or a restricted network environment.

Sandbox boundaries should match the risk of the task. Reading public docs may need little isolation; running untrusted code or editing production systems requires stronger limits, logging, and approval gates.
