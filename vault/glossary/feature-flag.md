---
term: "Feature Flag"
definition: "A software configuration technique that enables or disables specific functionality at runtime without deploying new code, allowing teams to control capability rollout, run A/B experiments, and perform instant rollbacks."
seo_description: "Feature flags in AI systems: how runtime configuration controls enable safe rollouts of new agent capabilities, models, and MCP tools without redeployment."
category: "infrastructure"
related_terms: [ai-gateway, observability, agent-evaluation, rate-limiting, agent-budget]
related_courses: [production-agents-claude-agent-sdk-mcp-connector, mcp-from-first-principles-to-production]
---

A **feature flag** (also called a feature toggle or feature switch) separates the act of deploying code from the act of enabling it. A new tool, model, or agent behavior ships to production in a disabled state. The flag is flipped to enable it for a defined audience—1% of users, a specific tenant, or a specific agent role—while [[observability]] metrics are monitored for regressions. If something goes wrong, disabling the flag rolls back the behavior without touching code or redeploying infrastructure.

For AI systems this pattern is especially valuable because the feedback loop for model and agent behavior is longer than for traditional features. Switching to a new LLM, enabling a new [[mcp]] tool, or deploying a changed system prompt all carry behavioral risk that is hard to catch completely in pre-production testing. Feature flags let teams make these changes incrementally: route 5% of traffic to the new model, measure task completion rate and error rate via [[structured-logging]], and ramp to 100% only after the behavior confirms expectations. If the new behavior is actually worse—or triggers [[rate-limiting]] at scale—the flag makes the rollback instant.

A common misconception is that feature flags add operational complexity without enough payoff for small teams. In practice, even two-person teams benefit from the ability to separate deploy from release and to conduct controlled experiments on model behavior. Another misconception is that flags are only for user-facing features: they are equally useful for internal agent capabilities, MCP server versions, and [[prompt-caching]] policies. The [[ai-gateway]] is often the right place to implement flag evaluation for model routing decisions, while application-level flags handle tool and prompt choices. See [[production-agents-claude-agent-sdk-mcp-connector]] for how feature flags integrate into production agent deployment patterns.

## Related Terms

- [[glossary/ai-gateway|AI Gateway]] — the proxy layer that centralises auth, rate-limiting, logging, and model routing
- [[glossary/observability|Observability]] — the practice of capturing traces, logs, and metrics to understand agent runtime behaviour
- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[glossary/rate-limiting|Rate Limiting]] — the policy of capping request throughput to protect service reliability
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
