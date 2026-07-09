---
term: "Stdio Transport"
definition: "Stdio transport is an inter-process communication (IPC) method where two processes communicate by writing to each other's standard input and output streams."
seo_description: "Stdio transport explained: IPC for local MCP servers."
category: "protocol"
related_terms: [mcp, json-rpc]
related_courses: [mcp-from-first-principles-to-production]
---

In the [[mcp]] protocol, the host application (e.g., Claude Desktop, an agent harness) launches the MCP server as a child process. From that point forward, every message in both directions is a JSON-RPC 2.0 object written to the child's stdin or read from its stdout. The host writes a request; the server writes a response. Stderr is reserved for diagnostic messages and is never parsed as protocol traffic.

**Security by construction.** Because stdio transport carries no network socket, there is no port to bind, no TLS certificate to manage, and no authentication handshake required. Only the process that spawned the server can communicate with it. This makes stdio transport the right default for any MCP server that runs locally alongside the host — a filesystem reader, a code executor, a local database client. An attacker with no local process access cannot reach the server at all.

**Lifecycle management.** The child server process is owned by the host. When the host exits or crashes, the OS cleans up the child automatically. There is no orphaned daemon to worry about. Conversely, if the server crashes, the host receives EOF on its read handle and can detect the failure immediately rather than waiting for a timeout.

**Message framing.** Raw stdio has no built-in message boundaries. The [[mcp]] spec addresses this with a simple framing convention: each JSON-RPC message is followed by a newline delimiter. Implementations must buffer incoming bytes until a complete newline-terminated JSON object is received before attempting to parse it. Fragmentation across OS write boundaries is normal and must be handled correctly.

**Stdio vs. HTTP/SSE transport.** The alternative transport for [[mcp]] is HTTP with Server-Sent Events, which exposes the server over a network socket. HTTP/SSE transport is required when the server is remote (running on a different machine or in a container), when multiple host processes need to share a single server instance, or when the server must push unsolicited notifications to the host. HTTP/SSE requires authentication (typically bearer tokens) and TLS. Stdio requires neither.

**Choosing between them.** Use stdio for local developer tools, personal automation, and any tool where isolation is a security requirement. Use HTTP/SSE for shared enterprise MCP servers, cloud deployments, and cases where the server lifecycle must outlive any single client session.

See [[mcp-from-first-principles-to-production]] for a complete walkthrough of both transports with working server implementations.

## Related Terms

- [[glossary/mcp|Model Context Protocol (MCP)]] — the protocol layer that standardises how agents discover and call tools
- [[glossary/json-rpc|JSON-RPC]] — related concept that intersects with this term in agent workflows
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
