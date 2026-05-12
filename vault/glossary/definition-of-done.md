---
term: "Definition of Done"
definition: "A precise, checkable description of the conditions that must be satisfied for an agent to consider a task complete and safe to hand off, preventing premature or incomplete deliveries."
seo_description: "Definition of done: precise, checkable completion criteria for an AI agent's task, preventing premature handoff in automated pipelines."
category: "Agentic AI concepts"
related_terms: [agent-soul, agent-lane, handoff, agent-evaluation, definition-of-done]
---

The definition of done (DoD) is the agent's exit criteria. Without explicit DoD, agents may declare tasks complete prematurely or continue refining indefinitely. A good DoD is specific, verifiable, and scoped to the agent's lane: "The blog post draft is done when it has 800–1200 words, includes at least three cited sources, passes the internal SEO checklist, and has been saved to the vault with correct frontmatter."

DoD items should be machine-checkable wherever possible. A code agent's DoD might include: all tests pass, no linting errors, and diff is under 500 lines. Automated checking prevents the agent from self-reporting completion without actually satisfying the criteria.

DoD also defines what is NOT included—explicitly ruling out scope creep. A content author's DoD says nothing about publishing or SEO optimization; those belong to later stages. By making both the positive criteria and the scope boundary explicit, the DoD reduces ambiguity and supports reliable automated evaluation.
