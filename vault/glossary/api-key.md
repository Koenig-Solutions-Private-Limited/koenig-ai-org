---
term: "API Key"
definition: "A secret token used by software to authenticate requests to an API, usually identifying the calling project, account, or service."
seo_description: "API key: a secret token used by software to authenticate API requests from a project, account, or service."
category: "Infrastructure"
related_terms: [rbac, privilege, rate-limiting, audit-trail, confidentiality]
related_courses: [gemini-enterprise-agents]
---

An API key is an opaque bearer token — typically a long random string — that a client sends with every request to prove it is allowed to use an API. There is no expiry built into the format itself; keys remain valid until the issuing service rotates or revokes them. This makes them simple to use and dangerous to lose.

When a service receives a request, it looks up the key, resolves the associated account, checks the permission scope, applies any [[rate-limiting]] bucket, and logs the request for billing and [[audit-trail]] purposes. The key is simultaneously an authentication credential, an authorization scope selector, and a cost-attribution tag — three concerns bundled into one string.

**Why exposure is serious.** Unlike a password, an API key carries no second factor. Anyone who obtains the key can call the API as if they are the legitimate owner until the key is rotated. Exposure paths include committed source code, logged request headers, leaked environment files, and screenshots of terminal sessions. The blast radius depends on the scope the key carries: a read-only analytics key is far less dangerous than a key with write or admin [[privilege]].

**Best practices.** Store keys in a dedicated secret manager (AWS Secrets Manager, HashiCorp Vault, or equivalent) rather than in plaintext environment files or source code. Inject them at runtime via environment variables. Define a rotation policy — weekly or monthly depending on sensitivity. Scope each key to the minimum permission set it needs; this limits damage if the key leaks and makes [[rbac]] enforcement meaningful. Maintain [[confidentiality]] by never including keys in logs, error messages, or prompts sent to a model.

**Per-agent isolation.** In multi-agent systems, sharing one API key across all agents makes [[audit-trail]] analysis impossible: you cannot tell which agent made which call or exceeded which budget. Issue a separate key per agent role, label them, and set per-key rate limits to contain cost spikes.

**API keys vs. OAuth tokens.** OAuth access tokens expire after minutes or hours and are scoped to a user session. API keys are long-lived and service-scoped. Neither is universally better; the right choice depends on whether the caller is a human session or a machine service. For machine-to-machine calls in production agent systems, API keys with strict rotation are the standard pattern. See [[gemini-enterprise-agents]] for how enterprise agent platforms handle credential injection at scale.

## Related Terms

- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/privilege|Attorney-Client Privilege]] — the confidentiality protection that restricts access to certain communications
- [[glossary/rate-limiting|Rate Limiting]] — the policy of capping request throughput to protect service reliability
- [[glossary/audit-trail|Audit Trail]] — the immutable chronological record of every action taken, enabling forensic review
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
