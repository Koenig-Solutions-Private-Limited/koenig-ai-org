---
term: "Confidentiality"
definition: "The ethical, legal, and technical obligation to protect sensitive information from unauthorized access, disclosure, or use—applied in AI systems through encryption, access controls, data minimization, and audit logging."
seo_description: "Confidentiality in AI: how encryption, access controls, and data minimization protect sensitive information in LLM-powered applications."
category: "security"
related_terms: [privilege, data-residency, rbac, sandboxing, audit-trail, api-key]
related_courses: [gemini-enterprise-agents, mcp-from-first-principles-to-production]
---

**Confidentiality** is the commitment that information shared with a system stays protected—seen only by those authorized to see it and never exposed through logs, caches, training pipelines, or third-party integrations. In regulated industries it is a legal obligation; in consumer products it is a baseline user expectation.

In AI systems, confidentiality is harder to maintain than in traditional software because model inference often involves third-party API calls that send user data to a vendor's infrastructure, context windows that can inadvertently leak session data if not scoped correctly, prompt logging that captures PII in plaintext, and fine-tuning pipelines that may memorize private inputs. The common misconception is that confidentiality is simply encryption at rest. Encryption protects stored data, but most confidentiality gaps in AI systems appear at inference time—when a message is dispatched to the model provider, when a tool call includes a secret value in its arguments, or when [[structured-logging]] captures full prompt content without redaction.

Legal frameworks sharpen the requirement in regulated sectors. Healthcare applications must comply with HIPAA; financial services applications must meet GLBA or FCA requirements; legal AI tools must actively maintain [[privilege]]. Cloud architecture choices—dedicated inference endpoints, [[data-residency]] constraints, single-tenant deployments—directly affect which confidentiality obligations a system can demonstrate to auditors. [[rbac]] restricts which agents and users can access which data, while [[audit-trail]] records who accessed what and when, creating the evidence needed for compliance review.

A practical first step is to treat every prompt and tool-call payload as potentially sensitive by default: redact known PII patterns before logging, apply field-level encryption for stored context, and require explicit data classification before enabling fine-tuning on user conversations. See [[gemini-enterprise-agents]] for how enterprise agent platforms enforce confidentiality through VPC isolation and audit-grade logging at scale.

## Related Terms

- [[glossary/privilege|Attorney-Client Privilege]] — the confidentiality protection that restricts access to certain communications
- [[glossary/data-residency|Data Residency]] — the legal and policy requirement that data stays within a specified geographic boundary
- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/sandboxing|Sandboxing]] — the isolation mechanism that prevents agent code execution from affecting the host system
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
