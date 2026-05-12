---
term: "Ephemeral Storage"
definition: "Ephemeral storage is temporary storage that is not intended to persist beyond the lifetime of the compute instance or container session."
seo_description: "Ephemeral storage explained: temporary data for agent tasks."
category: "infrastructure"
related_terms: [agent-memory, memory-agent]
related_courses: [mcp-from-first-principles-to-production]
---

Many agent tasks (like compiling code or running ephemeral tests) need file-system access, but that data is irrelevant after the task completes. Ephemeral storage provides high-performance, temporary scratch space. It is intentionally cleared after the task finishes to keep the environment clean and prevent cross-task data leakage.
