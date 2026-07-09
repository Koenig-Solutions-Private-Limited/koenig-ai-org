---
term: "Research Agent"
definition: "An AI agent that autonomously searches the web, reads documents, synthesizes findings, and produces cited reports by iteratively formulating queries and evaluating retrieved information against a research goal."
seo_description: "Research agent: an AI agent that autonomously searches, reads, and synthesizes information into cited research reports."
category: "Agentic AI concepts"
related_terms: [autonomous-agent, rag, grounding, agent-loop, tool-use, planning-agent]
---

Research agents combine web search, document retrieval, and synthesis in a loop. A common pattern is: decompose the research question into sub-queries, retrieve and read sources in parallel, score sources for relevance and credibility, then synthesize a draft with inline citations. The agent iterates until coverage of the question reaches a confidence threshold.

Quality controls include source diversity (avoiding echo-chamber retrieval), recency filtering, and factual cross-validation across multiple sources. Research agents are particularly prone to hallucination when sources conflict, so strong implementations explicitly represent uncertainty and surface disagreements rather than smoothing them over.

Production research agents in 2026 typically use a fast, cheap model (e.g., Grok 4.1 Fast or Gemini 2.5 Flash) for initial retrieval and a stronger model (Sonnet 4.6 or Opus 4.7) for synthesis and fact-checking. This mix balances cost and quality effectively.

## Related Terms

- [[glossary/autonomous-agent|Autonomous Agent]] — an agent that completes tasks independently without step-by-step human approval
- [[glossary/rag|Retrieval-Augmented Generation (RAG)]] — the pattern of retrieving relevant documents and injecting them into the prompt
- [[glossary/grounding|Grounding]] — the technique of anchoring model responses in verified external facts or retrieved documents
- [[glossary/agent-loop|Agent Loop]] — the iterative perceive-act-observe cycle the harness executes
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
