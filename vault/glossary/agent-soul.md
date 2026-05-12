---
term: "Agent SOUL"
definition: "A structured markdown document that defines an agent's identity, role lane, definition-of-done, escalation triggers, reporting format, and behavioral constraints—serving as its immutable core identity loaded into every system prompt."
seo_description: "Agent SOUL: a structured identity document defining an agent's role, constraints, escalation triggers, and reporting format loaded into every session."
category: "Agentic AI concepts"
related_terms: [agent-lane, definition-of-done, escalation, system-prompt, agent-scaffolding, human-in-the-loop]
---

The SOUL (a Paperclip convention) is the constitutional document for an individual agent. It answers: who am I, what do I do, what do I never do, when do I escalate, and what does a completed task look like? By loading the SOUL into the system prompt at the start of every session, the scaffold ensures the agent's identity and constraints are always in scope regardless of how complex the task context becomes.

A well-written SOUL is narrow enough to prevent scope creep but broad enough to handle legitimate variation within the role. A content author SOUL might say: "I write first drafts of blog posts and course chapters based on a brief. I do not publish, edit final copy, or communicate directly with customers. I escalate if the brief is ambiguous or if I cannot find sufficient authoritative sources." This clarity prevents the agent from drifting into reviewer or publisher behavior.

SOULs should be version-controlled alongside the company configuration. Changes to a SOUL are deployment changes: they alter the agent's behavior across all future tasks and should go through review (ideally by the CEO agent and a human) before being promoted to production.
