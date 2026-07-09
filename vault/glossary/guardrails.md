---
term: "Guardrails"
definition: "Rules, checks, permissions, and recovery paths that constrain an AI system so it stays within acceptable behavior and operational boundaries."
seo_description: "Guardrails: rules, checks, permissions, and recovery paths that keep an AI system inside acceptable behavior and operational boundaries."
category: "Agentic AI concepts"
related_terms: [rbac, privilege, human-in-the-loop, audit-trail, sandboxing]
related_courses: [gemini-enterprise-agents]
---

Guardrails are not a single feature. They include prompt instructions, input validation, output validation, tool permissions, policy classifiers, approval gates, [[rate-limiting|rate limits]], [[sandboxing]], and monitoring.

The strongest guardrails are enforced outside the model. A model can be asked not to delete production data, but the safer design is to avoid giving it that permission unless an explicit approval gate has been satisfied.

**Defense in depth** is the correct mental model. No single layer is sufficient. Model-level instructions (system prompt prohibitions, [[constitutional-ai]] training) are the first layer but the weakest: they can be circumvented by adversarial prompts, prompt injection from untrusted content, or model drift across versions. Tooling-level permissions ([[rbac]] on what tools and resources the agent can access) are harder to circumvent because they are enforced by the harness, not the model. Infrastructure-level constraints — [[sandboxing]], network egress restrictions, read-only file system mounts — are the strongest because they are enforced by the operating environment regardless of what the model requests.

**Input guardrails** classify or transform user input before it reaches the model. A content classifier can reject jailbreak attempts, flag personally identifiable information, or route sensitive queries to a restricted model variant. Input guardrails run synchronously in the request path and should be fast; expensive validation belongs in a pre-check layer, not inline.

**Output guardrails** validate model output before it is acted upon or shown. In agentic workflows this includes checking that generated tool calls target allowed endpoints, that structured output conforms to the expected schema, and that sensitive information is not surfaced in a response that will reach an unpermitted audience. Output guardrails catch errors that slipped through input guardrails.

**Approval gates** ([[human-in-the-loop]] checkpoints) interrupt the [[agent-loop]] before high-stakes, irreversible, or novel actions. Deleting records, sending communications to external parties, or making purchases are canonical examples. The [[agent-budget]] pattern extends this: an agent that is approaching its cost or action limit pauses and requests authorization to continue.

**The usability tradeoff.** Guardrails that are too tight produce a system that refuses legitimate requests, adding friction without safety benefit. Calibrate guardrail thresholds using [[evals]] on known-good and known-bad inputs. Track refusal rates alongside safety metrics. See [[gemini-enterprise-agents]] for a worked example of layered guardrails in an enterprise agent deployment.

## Related Terms

- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/privilege|Attorney-Client Privilege]] — the confidentiality protection that restricts access to certain communications
- [[glossary/human-in-the-loop|Human-in-the-Loop]] — the checkpoint pattern where a human approves before irreversible agent actions
- [[glossary/audit-trail|Audit Trail]] — the immutable chronological record of every action taken, enabling forensic review
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
