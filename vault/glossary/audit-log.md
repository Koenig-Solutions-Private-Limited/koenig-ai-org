---
term: "Audit Log"
definition: "An audit log is a structured, append-only record of discrete actions taken by agents or connectors — capturing what changed, when, by which tool, and in what format — so that any handoff can be inspected, replayed, or rolled back."
seo_description: "Audit log explained: structured record of agent and connector actions for traceability and rollback in multi-tool workflows."
category: "observability"
related_terms: [audit-trail, observability, handoff, idempotency, structured-logging]
related_courses: [mcp-from-first-principles-to-production, claude-mcp-mastery]
---

An audit log is the implementation artifact that makes an [[glossary/audit-trail]] concrete. Where an audit trail is the security concept — "there must be a record" — an audit log is the file, stream, or database table where that record actually lives. Each entry answers four questions: *what* action was performed, *by whom* (which agent or connector), *on what* (which asset, file, or resource), and *with what result* (success, failure, or partial change).

In cross-tool connector workflows, audit logs matter because format translation silently discards metadata. When an asset moves from Blender through SketchUp to Autodesk Fusion, an audit log captures what each connector exported, what fields Claude changed, which format carried the asset forward, and who verified the output before the next step began. Without this record, debugging a material-definition defect three steps downstream requires reconstructing the full export chain from memory.

A well-structured audit log entry for a connector handoff includes: the source file path and hash, the connector action (export, transform, import), the target file path and hash, the timestamp, and a diff summary of what changed. Storing hashes allows exact file comparison even if timestamps drift. See [[courses/mcp-from-first-principles-to-production/05-gateways-audit-logs]] for gateway-level audit log patterns that complement connector-level records.

Audit logs differ from general application logs in two ways: they are append-only (no entry is ever modified or deleted) and they record business-meaningful events rather than debug output. A debug log says "export function called with args X." An audit log says "Blender scene `hero_mesh_v3.blend` exported to `hero_mesh_v3.obj` by claude-blender-connector at 14:22:07 UTC; 4 materials stripped (no OBJ shader graph support); verified by operator."
