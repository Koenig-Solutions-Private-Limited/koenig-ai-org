---
term: "Guardrails"
definition: "Rules, checks, permissions, and recovery paths that constrain an AI system so it stays within acceptable behavior and operational boundaries."
seo_description: "Guardrails: rules, checks, permissions, and recovery paths that keep an AI system inside acceptable behavior and operational boundaries."
category: "Agentic AI concepts"
related_terms: [rbac, privilege, human-in-the-loop, audit-trail, sandboxing]
---

Guardrails are not a single feature. They include prompt instructions, input validation, output validation, tool permissions, policy classifiers, approval gates, rate limits, sandboxing, and monitoring.

The strongest guardrails are enforced outside the model. A model can be asked not to delete production data, but the safer design is to avoid giving it that permission unless an explicit approval gate has been satisfied.
