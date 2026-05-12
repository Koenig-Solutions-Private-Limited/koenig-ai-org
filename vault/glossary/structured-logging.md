---
term: "Structured Logging"
definition: "Structured logging is a practice where logs are emitted in a consistent, machine-readable format (typically JSON) containing key-value pairs rather than unstructured plain text."
seo_description: "Structured logging explained: machine-readable logs for agent debugging."
category: "observability"
related_terms: [observability, telemetry, audit-trail]
related_courses: [gemini-enterprise-agents]
---

In complex agent loops involving multiple tools, standard logs become useless. Structured logging allows teams to query logs based on specific fields (e.g., `agent_id`, `tool_name`, `error_code`), making it possible to reconstruct the exact path an agent took through a multi-step task when debugging a failure in production.
