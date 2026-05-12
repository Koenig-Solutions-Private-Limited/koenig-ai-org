---
term: "JSON-RPC"
definition: "JSON-RPC is a stateless, lightweight remote procedure call (RPC) protocol that uses JSON for data exchange."
seo_description: "JSON-RPC explained: the wire format for MCP."
category: "protocol"
related_terms: [mcp, stdio-transport]
related_courses: [mcp-from-first-principles-to-production]
---

JSON-RPC 2.0 is the foundational wire format for the Model Context Protocol. It defines how requests (method calls), responses (results or errors), and notifications (messages without responses) are structured. Its simplicity (newline-delimited for stdio) makes it easy for both host applications and server implementations to parse without complex dependencies.
