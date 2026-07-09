---
term: "HTTP SSE (Server-Sent Events)"
definition: "An HTTP protocol extension that allows a server to push a continuous stream of events to a client over a single long-lived connection—used by remote MCP servers to stream tool results and progress updates back to the host application."
seo_description: "HTTP SSE in MCP: how server-sent events enable real-time streaming from remote AI tool servers to host applications over standard HTTP connections."
category: "protocol"
related_terms: [mcp, stdio-transport, json-rpc, http-sse, agent-loop, latency]
related_courses: [mcp-from-first-principles-to-production]
---

**HTTP Server-Sent Events** (SSE) is a W3C standard that turns a normal HTTP connection into a one-way event stream from server to client. After the client makes an HTTP request, the server keeps the connection open and pushes newline-delimited event objects as data becomes available, rather than sending a single response and closing. Browsers and HTTP libraries handle the connection lifecycle—automatic reconnection, event IDs for resumption—which makes SSE simpler to implement than WebSockets for use cases where only the server needs to push data.

In the [[mcp]] ecosystem, HTTP+SSE (officially called "Streamable HTTP" in the MCP specification) is the preferred transport for remote servers that need to operate over a network. The client posts a JSON-RPC request to the server's endpoint; the server responds with an SSE stream that delivers the result—and any intermediate progress notifications—as events. This pattern handles long-running tool calls well: instead of the client waiting on a blocking HTTP response that might time out, it receives incremental updates as the server works. Load balancers and CDNs handle SSE connections transparently, which means remote MCP servers can be deployed behind standard infrastructure without custom network configuration.

The comparison with [[stdio-transport]] clarifies where each fits. Stdio is simpler and more secure for local servers—communication stays within the same machine, there is no network exposure, and the host manages the child process lifetime. HTTP+SSE is required when the server must be remote: a shared enterprise tool hub, a cloud-hosted database connector, or a third-party service. A common misconception is that SSE is a legacy choice superseded by WebSockets. SSE is intentionally unidirectional, which makes it easier to reason about, more compatible with existing HTTP infrastructure, and sufficient for MCP's message pattern where requests flow client-to-server and responses flow server-to-client. See [[mcp-from-first-principles-to-production]] for complete examples of both transports and when to choose each.

## Related Terms

- [[glossary/mcp|Model Context Protocol (MCP)]] — the protocol layer that standardises how agents discover and call tools
- [[glossary/stdio-transport|Stdio Transport]] — the stdin/stdout pipe transport used by MCP when host and server run in the same process
- [[glossary/json-rpc|JSON-RPC]] — related concept that intersects with this term in agent workflows
- [[glossary/http-sse|HTTP SSE (Server-Sent Events)]] — the long-lived HTTP streaming transport used by MCP for server-to-client event push
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
