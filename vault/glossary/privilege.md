---
term: "Attorney-Client Privilege"
definition: "A legal protection that keeps communications between a lawyer and their client confidential and shielded from compelled disclosure in legal proceedings. In AI legal tools, maintaining this protection requires specific technical and contractual controls."
seo_description: "Attorney-client privilege and AI: the technical requirements legal teams must enforce when using LLMs on privileged communications."
category: "security"
related_terms: [confidentiality, data-residency, rbac, audit-trail, sandboxing]
related_courses: [gemini-enterprise-agents, mcp-from-first-principles-to-production]
---

**Attorney-client privilege** is one of the oldest and most tightly protected doctrines in law. It gives clients the right to communicate candidly with their attorneys without fear that those communications will be used against them in court. The privilege applies to legal advice—not business advice—and can be permanently lost ("waived") if the communication is disclosed to an unauthorized third party, whether intentionally or by accident.

When law firms and legal-tech companies deploy AI on privileged content, the waiver risk is real and non-theoretical. Sending privileged documents to a cloud AI provider whose terms of service allow prompt logging, training data use, or employee review can constitute disclosure to an unauthorized third party. The legal analysis depends on jurisdiction and specific contracts, but many firms take a conservative approach: privileged content may only touch AI infrastructure that offers zero-retention agreements, dedicated single-tenant deployments, and explicit contractual commitments that no human at the provider can access the data. [[confidentiality]] controls—field-level encryption, [[rbac]], and [[audit-trail]]—must be demonstrable to bar counsel and opposing parties.

A common misconception is that marking a document "attorney-client privileged" creates the legal protection. What creates the protection is the relationship, the content, and—critically for AI use—the maintenance of confidentiality throughout the document's lifecycle. An [[audit-trail]] that records every system that touched a privileged document is the evidence that courts and bar associations look for when evaluating whether privilege was maintained. This is distinct from [[data-residency]], which governs jurisdiction; privilege governs disclosure regardless of geography.

In practice, legal teams using AI for contract review, discovery, or research should insist on zero-retention model agreements, opt-out of any training data pipelines, disable shared [[structured-logging]] for privileged content paths, and conduct an annual review of vendor access logs. See [[gemini-enterprise-agents]] for how enterprise AI deployments can be architected to satisfy privilege-preservation requirements.

## Related Terms

- [[glossary/confidentiality|Confidentiality]] — the information-security property that data is accessible only to authorised parties
- [[glossary/data-residency|Data Residency]] — the legal and policy requirement that data stays within a specified geographic boundary
- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/audit-trail|Audit Trail]] — the immutable chronological record of every action taken, enabling forensic review
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
