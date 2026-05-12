---
term: "Stdio Transport"
definition: "Stdio transport is an inter-process communication (IPC) method where two processes communicate by writing to each other's standard input and output streams."
seo_description: "Stdio transport explained: IPC for local MCP servers."
category: "protocol"
related_terms: [mcp, json-rpc]
related_courses: [mcp-from-first-principles-to-production]
---

Stdio transport is the preferred communication method for local MCP servers. It is inherently secure, as communication happens entirely within the local machine (no network exposure), and it simplifies process management (the server is just a child process of the host). When the host application exits, the child process is automatically terminated.
