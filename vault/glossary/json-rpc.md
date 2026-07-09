---
term: "JSON-RPC"
definition: "A stateless, lightweight remote procedure call protocol that encodes method calls, parameters, and responses in JSON—the wire format underlying the Model Context Protocol (MCP) and many other AI infrastructure components."
seo_description: "JSON-RPC: the lightweight RPC protocol that powers MCP's message structure, defining how requests, responses, and notifications flow between hosts and tool servers."
category: "protocol"
related_terms: [mcp, stdio-transport, http-sse, tool-use, agent-harness]
related_courses: [mcp-from-first-principles-to-production]
---

**JSON-RPC 2.0** defines how two processes exchange structured requests and responses using JSON objects. Each request specifies a `method` name (the function to call), `params` (arguments), and an `id` (so the response can be matched back to the request). Responses carry either a `result` on success or an `error` object with a code and message. Notifications—one-way messages that expect no response—omit the `id` field. The entire protocol fits in a page of specification; its simplicity is why it is widely implemented across languages and environments.

The [[mcp]] specification uses JSON-RPC 2.0 as its message envelope. When a host application asks an MCP server what tools it has, it sends a `tools/list` JSON-RPC request. When an agent invokes a tool, the host sends a `tools/call` request with the tool name and arguments in `params`. The server returns the tool result as a JSON-RPC response. Because the protocol is stateless and JSON-encoded, it works over any transport: [[stdio-transport]] delivers it as newline-delimited messages between processes; [[http-sse]] delivers it over HTTP+SSE streams; WebSockets can carry it for bidirectional real-time use cases.

A common misconception is that JSON-RPC is only relevant to backend engineers writing MCP servers. Understanding it matters for prompt engineering and debugging too: when a [[tool-use]] call produces unexpected behavior, inspecting the raw JSON-RPC exchange between host and server reveals whether the problem is in the tool schema, the argument serialization, or the server's response format. Another misconception is that JSON-RPC adds significant overhead compared to REST APIs. The protocol payload is minimal, and the elimination of HTTP method semantics and URL routing makes it faster to parse on both sides. See [[mcp-from-first-principles-to-production]] for complete annotated examples of JSON-RPC exchanges in a working MCP implementation.

## Related Terms

- [[glossary/agent-harness|Agent harness]] — the host process that sends JSON-RPC requests to MCP servers and processes their responses in the tool loop
- [[glossary/tool-use|Tool use]] — the model capability that JSON-RPC tools/call messages implement at the transport layer
- [[glossary/stdio-transport|Stdio Transport]] — the local IPC variant that frames JSON-RPC messages as newline-delimited objects over stdin/stdout
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on walkthrough of building and securing MCP servers
