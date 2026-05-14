---
term: "API Key"
definition: "A secret token used by software to authenticate requests to an API, usually identifying the calling project, account, or service."
seo_description: "API key: a secret token used by software to authenticate API requests from a project, account, or service."
category: "Infrastructure"
related_terms: [rbac, privilege, rate-limiting, audit-trail, confidentiality]
---

An API key is the simplest credential many AI applications use to call model, database, or orchestration services. The service checks the key on each request, applies the associated permissions and rate limits, and records activity for billing or audit purposes.

API keys should be stored in secret managers or encrypted environment stores, never in source code or prompt text. Production systems usually rotate keys, scope them to the smallest practical permission set, and separate human operator credentials from agent runtime credentials.
