---
term: "HTTP SSE (Server-Sent Events)"
definition: "HTTP SSE is a standard for pushing real-time updates from a server to a client over a long-lived HTTP connection."
seo_description: "HTTP SSE explained: real-time streaming for remote MCP servers."
category: "protocol"
related_terms: [mcp, stdio-transport]
related_courses: [mcp-from-first-principles-to-production]
---

While stdio is ideal for local servers, remote MCP servers require a network transport. HTTP+SSE (Streamable HTTP) allows the server to stream updates (e.g., tool results) to the client over an open HTTP connection. It is unidirectional (server-to-client), and it enables MCP servers to be deployed behind standard load balancers or gateways.
