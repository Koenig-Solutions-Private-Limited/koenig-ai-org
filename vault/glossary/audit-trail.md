---
term: "Audit Trail"
definition: "A chronological, tamper-evident record of all activities, tool calls, decisions, and data accesses performed within an AI system—essential for accountability, compliance, incident response, and debugging agent behavior."
seo_description: "Audit trail in AI: why every tool call an agent makes must be logged, and how to build tamper-evident records that satisfy compliance and incident review."
category: "security"
related_terms: [ai-gateway, rbac, structured-logging, observability, confidentiality, sandboxing, telemetry]
related_courses: [mcp-from-first-principles-to-production, gemini-enterprise-agents]
---

An **audit trail** answers the question "what exactly happened, and who authorized it?" In traditional software, audit trails track user actions on data. In agentic systems, the problem is more complex: an agent may call dozens of tools across multiple services within a single task, make decisions that aren't visible in final outputs, and operate on behalf of users who never saw the intermediate steps. Without a comprehensive audit trail, it is impossible to determine why an agent took a damaging action, whether a user's data was accessed appropriately, or where a compliance failure occurred.

A complete AI audit trail captures more than just tool names. For each [[tool-use]] invocation it should record: timestamp, agent identity, user context, tool name, full argument payload, raw tool result, and whether a human approved the action. For model calls it should record: prompt length, system prompt version, response, and latency. This data feeds [[observability]] dashboards for performance debugging and provides the forensic evidence needed for incident response. When an agent deletes a repository, modifies production data, or sends a message in a user's name, the audit trail must be sufficient for a post-incident review to reconstruct the exact decision path.

A common misconception is that [[structured-logging]] alone constitutes an audit trail. Logs are a raw material; an audit trail is logs with integrity guarantees—records that cannot be selectively deleted or altered without detection. Production implementations often write audit records to append-only storage (object storage with object lock, write-once databases) and include cryptographic signatures to detect tampering. [[rbac]] and [[confidentiality]] controls also depend on a functioning audit trail: RBAC decisions are only meaningful if there is a record proving those decisions were enforced. See [[mcp-from-first-principles-to-production]] for how to wire audit logging into MCP server middleware so every tool call generates a compliant record.

## Related Terms

- [[glossary/ai-gateway|AI Gateway]] — the proxy layer that centralises auth, rate-limiting, logging, and model routing
- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/structured-logging|Structured Logging]] — machine-parseable log output with consistent fields for reliable querying and alerting
- [[glossary/observability|Observability]] — the practice of capturing traces, logs, and metrics to understand agent runtime behaviour
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
