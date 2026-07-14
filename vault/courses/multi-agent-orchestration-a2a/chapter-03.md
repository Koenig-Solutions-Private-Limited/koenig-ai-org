---
course: multi-agent-orchestration-a2a
chapter_num: 3
chapter_title: "The Internet of Agents — AGNTCY & Global Discovery (2026)"
author: course-author
ticket: KOEA-6946
date: 2026-05-31
status: g3-passed
level: Advanced
duration_min: 50
reading_time_min: 12
prerequisites_chapters:
  - 1
  - 2
learning_objectives:
  - Explain the AGNTCY Internet of Agents vision and the role of global agent registries in enabling cross-vendor collaboration
  - Implement a Capability Discovery query against a mock AGNTCY-style registry using OASF schema conventions
  - Design a globally unique Agent Identity (AID) and explain the trust implications of centralized versus decentralized identity
  - Describe the Registry-less Discovery fallback pattern using p2p gossip and explain when each discovery mode should be preferred
positions:
  - id: mcp-as-interoperability-moat
    engagement: defends
  - id: audit-trail-as-enterprise-gate
    engagement: defends
slug: multi-agent-orchestration-a2a-ch03
description: "Learn how AGNTCY's Internet of Agents infrastructure enables cross-vendor agent discovery, global registry queries, OASF capability indexing, and p2p gossip fallback for resilient multi-agent systems."
tags: [AGNTCY, A2A, agent-discovery, OASF, multi-agent, Internet-of-Agents]
chapter_primary_query: "how to discover agents using AGNTCY and A2A protocol"
first_60_words_answer: "AGNTCY is the Linux Foundation-hosted open infrastructure for the Internet of Agents. To discover agents, you publish an OASF-compliant schema to an Agent Directory Service and query it by capability — not by hard-coded endpoint. Every A2A-compliant agent also exposes a /.well-known/agent-card.json that any client can probe. Together, these two mechanisms make cross-vendor agent discovery deterministic rather than manual."
faq:
  - question: "What is AGNTCY and why does it matter for multi-agent systems?"
    answer: "AGNTCY is a Linux Foundation open-source initiative that provides the infrastructure layer — discovery, identity, messaging, and observability — that lets AI agents from different vendors and frameworks find and collaborate with each other without bilateral integration agreements. ([AGNTCY.org](https://agntcy.org/))"
  - question: "How does A2A agent discovery work in practice?"
    answer: "Every A2A-compliant agent publishes an AgentCard at /.well-known/agent-card.json describing its capabilities, skills, and auth requirements. Clients can probe this endpoint directly (well-known URI discovery), query a curated registry that indexes many AgentCards (registry discovery), or use a hardcoded endpoint (direct config) for tightly coupled systems. ([A2A agent discovery spec](https://a2a-protocol.org/latest/topics/agent-discovery/))"
  - question: "What is OASF and how does it relate to agent discovery?"
    answer: "The Open Agentic Schema Framework (OASF) is an extensible data model from AGNTCY that formalizes how agents describe their capabilities, identity, and supported protocols. OASF records can be indexed by the Agent Directory Service and queried by fuzzy capability string, enabling agents to find each other by what they can do rather than where they live. ([OASF docs](https://docs.agntcy.org/oasf/open-agentic-schema-framework/))"
  - question: "What happens if the central registry goes down?"
    answer: "Production A2A networks should fall back to p2p gossip discovery using protocols like Hyperspace's GossipSub or libp2p DHT. Agents that have previously established connections share AgentCard updates peer-to-peer, so the network degrades gracefully rather than failing completely if a central directory is unavailable. ([Hyperspace Protocol](https://protocol.hyper.space/))"
inline_assets:
  - type: diagram
    path: ./img/ch03-discovery-modes.png
    alt: "Three A2A agent discovery modes: well-known URI probe (agent exposes /.well-known/agent-card.json), curated registry query (central service indexes many AgentCards, client queries by capability), and direct config (hardcoded endpoint in client application). All three modes return the same AgentCard document."
last_updated: 2026-06-15
sources:
  - https://agntcy.org/
  - https://docs.agntcy.org/
  - https://docs.agntcy.org/oasf/open-agentic-schema-framework/
  - https://github.com/agntcy/oasf
  - https://a2a-protocol.org/latest/topics/agent-discovery/
  - https://a2a-protocol.org/latest/specification/
  - https://www.linuxfoundation.org/press/linux-foundation-welcomes-the-agntcy-project-to-standardize-open-multi-agent-system-infrastructure-and-break-down-ai-agent-silos
  - https://protocol.hyper.space/
---

# The Internet of Agents — AGNTCY & Global Discovery (2026)

> **Chapter 3 of 10 · 50 min (prose ~12 min + 30 min hands-on exercise)**

---

AGNTCY is the Linux Foundation-hosted open infrastructure for the Internet of Agents. To discover agents, you publish an OASF-compliant schema to an Agent Directory Service and query it by capability — not by hard-coded endpoint. Every A2A-compliant agent also exposes a `/.well-known/agent-card.json` that any client can probe. Together, these two mechanisms make cross-vendor agent discovery deterministic rather than manual.

This chapter builds the discovery layer on top of the wire protocol you learned in [[multi-agent-orchestration-a2a/chapter-02|Chapter 2]]. By the end, you'll be able to register an agent in a local registry, query that registry by fuzzy capability string, and implement the p2p gossip fallback that keeps your network alive when the registry goes down. (New to A2A? Start with [[multi-agent-orchestration-a2a/chapter-01|Chapter 1]] for the protocol foundations.)

---

## Why Discovery Is the Hardest Problem in Multi-Agent Systems

You've solved the wire format (Chapter 2). Your agents can send `sendMessage` payloads, negotiate capabilities, and track task state. The next question immediately surfaces: **how does Agent A find Agent B in the first place?**

In traditional microservice architectures, this is solved by a service mesh — Kubernetes DNS, Consul, Eureka. You deploy services with known names, you configure clients to hit those names, done. The topology is static and centrally managed.

Agents break this assumption in three ways:

1. **Dynamic capability emergence.** Agents acquire new skills over time (through tool updates, fine-tuning, or new MCP server connections). A static registry entry becomes stale within hours.
2. **Cross-organizational boundaries.** Your orchestrator needs to hire a specialist that belongs to a different company's infrastructure. There is no shared Kubernetes cluster, no shared Consul, no shared anything.
3. **Intent-based matching.** You don't want to query "give me the agent named `sentiment-analyst-v3`." You want to query "give me an agent that can analyze earnings call transcripts and output JSON sentiment scores." The registry must understand capability semantics, not just string names.

These three constraints rule out every traditional service-discovery approach. What the agent ecosystem needs — and what AGNTCY is building — is a *protocol-level* discovery infrastructure where any agent can advertise capabilities in a standardized schema and any client can find the right agent by semantic query.

---

## AGNTCY — The Internet of Agents Infrastructure

[AGNTCY](https://agntcy.org/) launched in March 2025, founded by Outshift by Cisco, LangChain, and Galileo. By mid-2026, it operates under Linux Foundation governance with Cisco, Dell Technologies, Google Cloud, Oracle, and Red Hat as formative members — the same governance model that gave us Kubernetes and OpenTelemetry. ([Linux Foundation press release](https://www.linuxfoundation.org/press/linux-foundation-welcomes-the-agntcy-project-to-standardize-open-multi-agent-system-infrastructure-and-break-down-ai-agent-silos))

The AGNTCY vision has four capabilities that map exactly to the lifecycle gaps that make multi-agent systems hard to build:

| Capability | What it solves | AGNTCY component |
|---|---|---|
| **Discover** | Finding the right agent for a task across org boundaries | Agent Directory Service + OASF |
| **Compose** | Wiring agents into workflows without bilateral integration | SLIM messaging protocol |
| **Deploy** | Running multi-agent systems securely at cloud scale | Cloud-native deployment specs |
| **Evaluate** | Tracking agent performance and optimizing effectiveness | Observability & telemetry layer |

This chapter focuses almost entirely on **Discover** — the first capability. Compose is covered in Chapter 6; Deploy and Evaluate in Chapters 7 and 9.

AGNTCY is not a product. It is an **infrastructure layer** that frameworks run on top of. LangGraph can use AGNTCY for discovery while orchestrating agents internally. A Paperclip agent and a Vertex AI agent can find each other through AGNTCY without sharing a framework at all. This is the same relationship DNS has to HTTP: the naming layer is independent of what the applications do after they connect.

---

## OASF — The Schema That Powers Discovery

Every agent in an AGNTCY-compatible network publishes an **OASF record** — an Open Agentic Schema Framework document that describes who the agent is and what it can do. ([docs.agntcy.org/oasf](https://docs.agntcy.org/oasf/open-agentic-schema-framework/))

OASF is an OCSF-inspired extensible data model (Open Cybersecurity Schema Framework — not Open Container Initiative). The top-level fields describe the agent's identity and protocol support; the taxonomy of skills uses a dotted-namespace notation that enables semantic search:

```json
{
  "oasf_version": "1.0",
  "uid": "did:agntcy:abc123-sentiment-analyst",
  "name": "SentimentAnalyst",
  "description": "Analyzes financial text — earnings calls, news, filings — and returns structured JSON sentiment scores with per-entity attribution.",
  "version": "2.1.4",
  "endpoints": [
    {
      "type": "a2a",
      "url": "https://agents.acme.io/sentiment-analyst",
      "agent_card_url": "https://agents.acme.io/sentiment-analyst/.well-known/agent-card.json"
    }
  ],
  "skills": [
    {
      "id": "nlp.sentiment.financial",
      "name": "Financial Sentiment Analysis",
      "description": "Returns sentiment polarity and confidence per named entity from earnings transcripts, press releases, and SEC filings.",
      "input_modes": ["text/plain", "application/pdf"],
      "output_modes": ["application/json"],
      "examples": [
        "Analyze the Q3 2025 Apple earnings call transcript",
        "Rate sentiment for all named entities in this press release"
      ]
    },
    {
      "id": "nlp.ner.financial",
      "name": "Financial Named Entity Recognition",
      "description": "Extracts company, person, and financial instrument entities from financial text.",
      "input_modes": ["text/plain"],
      "output_modes": ["application/json"]
    }
  ],
  "extensions": ["a2a/push-notifications", "a2a/streaming"],
  "auth": {
    "schemes": ["oauth2", "dpop"]
  }
}
```

The `skills` array is the key to semantic discovery. The dotted notation (`nlp.sentiment.financial`) is hierarchical — an orchestrator querying for agents with any `nlp.sentiment.*` skill will match this agent even without knowing the exact skill ID. This is capability indexing: the registry stores the taxonomy tree and supports prefix-match and fuzzy queries.

<Callout type="info">
OASF records extend A2A's AgentCard format without replacing it. The AgentCard (at `/.well-known/agent-card.json`) is the A2A wire-level identity document. The OASF record wraps and extends it with richer metadata — cost-per-task, performance SLAs, domain classification, and observability endpoints — that the registry indexes for discovery. When an agent publishes to the AGNTCY directory, it submits its OASF record; the directory extracts and caches the AgentCard URL so A2A clients can probe it directly.
</Callout>

---

## Agent Identity (AID) — Global Uniqueness and Trust Implications

Every agent in an Internet of Agents network needs a globally unique identifier that:

1. **Proves ownership** — the identifier holder controls the private key
2. **Doesn't depend on a registry** — the identity must be verifiable even if the directory is unreachable
3. **Survives relocations** — when an agent moves from `cloud.acme.io` to `on-prem.acme.io`, its identity doesn't change

The emerging pattern, visible in both AGNTCY and Hyperspace Protocol, is **DID-style identifiers**: `did:agntcy:<unique-id>`. DID (Decentralized Identifier) URNs bind identity to a cryptographic key pair, not to a domain name or a registry record.

The trust chain for an AID works like this:

```
Agent generates secp256k1 keypair
        ↓
Public key → hashed to produce AID   (did:agntcy:abc123...)
        ↓
Private key → signs OASF records and A2A message envelopes
        ↓
Any verifier can validate signature without contacting the registry
```

This is why the contrarian angle for this chapter matters so much: **the identity must not be owned by the registry**. The GPT Store model — where OpenAI assigns plugin IDs and revokes them at will — is fundamentally incompatible with an interoperable Internet of Agents. If Acme Corp's orchestrator integrates with your agent, Acme Corp's workflow should not break if you decide to move registries. Your AID is yours; registries are just *indexes* of it.

**Trust implications for production systems:**

- An agent you discover via a registry is only as trustworthy as the registry's vetting process. Use the AID + signature to verify claims independently of the registry.
- Registries can be gamed: a malicious agent can publish a plausible OASF record with false capability claims. Before delegating sensitive tasks, always run the A2A capability negotiation handshake (Chapter 2) to confirm the agent can actually *demonstrate* the skills it claims.
- Enterprise deployments typically run **private registries** that accept only AIDs from known organizational namespaces (`did:agntcy:acme:*`). Public discovery layers on top of private identity — the organization controls which agents appear in public search results.

<KnowledgeCheck
  question="An agent's AID (Agent Identity) is based on a cryptographic key pair rather than a domain name. Which property does this provide?"
  answers={[
    "The agent's identity becomes tied to the hosting provider's infrastructure",
    "The registry gains exclusive authority to revoke agent identities",
    "The agent's identity can be verified without contacting the registry, and survives domain migrations",
    "AIDs prevent agents from being indexed in multiple registries simultaneously"
  ]}
  correct={2}
/>

---

## The Three A2A Discovery Mechanisms

The A2A specification defines three discovery modes. They are not mutually exclusive — a production system typically implements all three in order of preference. ([a2a-protocol.org/latest/topics/agent-discovery](https://a2a-protocol.org/latest/topics/agent-discovery/))

### Mode 1: Well-Known URI Probe

The simplest discovery mechanism. Every A2A server MUST expose its AgentCard at:

```
https://{domain}/.well-known/agent-card.json
```

This follows [RFC 8615](https://www.rfc-editor.org/rfc/rfc8615) conventions. Any client that knows the domain can retrieve the AgentCard without prior agreement:

```python
import httpx

async def probe_agent(domain: str) -> dict:
    url = f"https://{domain}/.well-known/agent-card.json"
    async with httpx.AsyncClient() as client:
        response = await client.get(url, timeout=5.0)
        response.raise_for_status()
        return response.json()

# Usage
card = await probe_agent("agents.acme.io")
print(card["name"])         # SentimentAnalyst
print(card["skills"])       # [...skill list...]
```

**When to use:** Public agents where you know the domain. Dev environments where you're testing a specific agent.

**Limitation:** You must already know the domain. This is not discovery from capability — it is discovery from location. The "I know you exist" problem is not solved.

### Mode 2: Curated Registry Query

A registry service indexes many AgentCards and exposes a query API. The A2A spec does not standardize the registry API (as of v1.0.0), but AGNTCY's Agent Directory Service and the emerging community conventions converge on a pattern:

```python
import httpx

async def discover_by_capability(
    registry_url: str,
    skill_prefix: str,
    min_output_modes: list[str] | None = None,
) -> list[dict]:
    """Query an AGNTCY-style registry for agents by capability prefix."""
    params = {
        "skill": skill_prefix,          # prefix match: "nlp.sentiment.*"
        "output_modes": min_output_modes or [],
    }
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{registry_url}/v1/agents/search",
            params=params,
            timeout=10.0,
        )
        response.raise_for_status()
        return response.json()["agents"]

# An orchestrator looking for a financial sentiment specialist
candidates = await discover_by_capability(
    registry_url="https://registry.agntcy.org",
    skill_prefix="nlp.sentiment.financial",
    min_output_modes=["application/json"],
)

for agent in candidates:
    print(f"{agent['name']} → {agent['endpoints'][0]['agent_card_url']}")
```

**When to use:** Cross-organizational discovery where you don't know what agents exist. Marketplace scenarios where you want to compare multiple candidates before hiring.

**Limitation:** Requires a running registry. The registry's index of capabilities must be kept current — stale OASF records return outdated capability information.

### Mode 3: Direct Configuration

The agent's endpoint is hardcoded in a config file, environment variable, or secrets manager. No runtime discovery occurs.

```yaml
# agents.yaml
specialists:
  sentiment_analyst:
    agent_card_url: https://agents.acme.io/sentiment/.well-known/agent-card.json
    auth: oauth2
```

**When to use:** Tightly coupled production systems with known, stable partners. CI environments where discovery must be deterministic. Fallback when both Mode 1 and Mode 2 fail.

**Limitation:** Breaks the Intent Gap closure — you're back to hard-coding endpoints rather than discovering by capability.

---

## Building a Local AGNTCY-Style Registry

You don't need to run the full AGNTCY stack to experiment with registry-based discovery. The following is a minimal FastAPI implementation that accepts OASF-style registrations and supports prefix-match capability queries:

```python
# registry.py — local AGNTCY-style agent registry
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json, re

app = FastAPI(title="Local Agent Registry")

# In-memory store: aid → oasf_record
_registry: dict[str, dict] = {}

class OASFRecord(BaseModel):
    uid: str                   # AID: did:agntcy:<hash>
    name: str
    description: str
    version: str
    endpoints: list[dict]
    skills: list[dict]         # [{id, name, description, input_modes, output_modes}]
    auth: dict = {}

@app.post("/v1/agents/register", status_code=201)
async def register_agent(record: OASFRecord):
    _registry[record.uid] = record.model_dump()
    return {"registered": record.uid, "total_agents": len(_registry)}

@app.get("/v1/agents/search")
async def search_agents(skill: str = "", output_modes: list[str] = []):
    """Prefix-match agents by skill taxonomy path."""
    pattern = re.compile(
        r"^" + re.escape(skill).replace(r"\*", r".*") + r"$"
    )
    results = []
    for record in _registry.values():
        for s in record["skills"]:
            if pattern.match(s["id"]):
                # filter by output_modes if specified
                if output_modes and not any(
                    m in s.get("output_modes", []) for m in output_modes
                ):
                    continue
                results.append(record)
                break
    return {"agents": results, "count": len(results)}

@app.get("/v1/agents/{uid}")
async def get_agent(uid: str):
    if uid not in _registry:
        raise HTTPException(status_code=404, detail="Agent not found")
    return _registry[uid]
```

Run it:

```bash
pip install fastapi uvicorn httpx pydantic
uvicorn registry:app --port 8001 --reload
```

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You are an A2A orchestrator agent. Generate a complete OASF record (as a JSON object) for a \"Financial News Researcher\" agent with the following properties:\n- uid: did:agntcy:finresearch-001\n- Endpoint: http://localhost:8002 with A2A agent-card URL\n- Two skills: news.fetch.financial (fetches financial news from RSS/web) and news.summarize.earnings (summarizes earnings call transcripts)\n- Input modes: text/plain for both skills\n- Output modes: application/json for news.fetch.financial; text/markdown for news.summarize.earnings\n- Auth: api_key scheme\n\nOutput only valid JSON."
  expectedOutput='{"uid":"did:agntcy:finresearch-001","name":"FinancialNewsResearcher","description":"Fetches and summarizes financial news from RSS feeds and earnings call transcripts.","version":"1.0.0","endpoints":[{"type":"a2a","url":"http://localhost:8002","agent_card_url":"http://localhost:8002/.well-known/agent-card.json"}],"skills":[{"id":"news.fetch.financial","name":"Financial News Fetch","description":"Fetches financial news from RSS feeds and financial news APIs.","input_modes":["text/plain"],"output_modes":["application/json"]},{"id":"news.summarize.earnings","name":"Earnings Call Summarizer","description":"Summarizes earnings call transcripts into structured key-point narratives.","input_modes":["text/plain"],"output_modes":["text/markdown"]}],"auth":{"schemes":["api_key"]}}'
/>

---

## Capability Indexing — How Fuzzy Search Works

The dotted taxonomy notation in OASF (`nlp.sentiment.financial`) is not arbitrary. It encodes a hierarchical capability tree that registries can index efficiently:

```
nlp
├── sentiment
│   ├── financial        ← "does it affect stock prices?"
│   ├── social-media     ← "Twitter/Reddit tone analysis"
│   └── customer         ← "product review analysis"
├── summarization
│   ├── abstractive
│   └── extractive
└── ner
    └── financial

news
├── fetch
│   └── financial
└── summarize
    └── earnings
```

A query for `nlp.*` returns every agent that has any NLP skill. A query for `nlp.sentiment.*` returns sentiment agents across all domains. A query for `nlp.sentiment.financial` returns only the agents that specifically handle financial text. This prefix-match hierarchy is how an orchestrator can be intentionally broad ("find me *any* NLP agent") or intentionally narrow ("find me an agent that specifically handles financial sentiment in JSON output format").

**Scoring and ranking:** Production registries layer fuzzy scoring on top of prefix matching. The AGNTCY Agent Directory Service weights candidates by:
- Skill specificity match (exact match > prefix match)
- Output mode compatibility
- Self-reported performance metadata (latency_p50_ms, success_rate)
- Recency of last OASF update

The orchestrator receives a ranked list of candidates, not a single "best" answer. The agent that's cheapest might not be the most accurate. The final selection — whether to pick by cost, by declared success rate, or by brand trust — belongs to the orchestrator's policy layer, not the registry.

<KnowledgeCheck
  question="An orchestrator queries a registry with skill='nlp.sentiment.*'. Which of the following agents will be returned? (Select all that apply)"
  answers={[
    "An agent with skill id 'nlp.sentiment.financial'",
    "An agent with skill id 'nlp.summarization.abstractive'",
    "An agent with skill id 'nlp.sentiment.social-media'",
    "An agent with skill id 'news.fetch.financial'"
  ]}
  correct={[0, 2]}
  multi={true}
  freeform="Explain in one sentence why skill prefix matching is more useful for orchestrators than exact-match queries."
/>

---

## Registry-less Discovery — The P2P Gossip Fallback

Central registries have a single-point-of-failure problem. For enterprise-grade systems, a 5-minute registry outage should not prevent agents from finding each other at all. The fallback is **p2p gossip discovery**.

The pattern (implemented by Hyperspace Protocol using GossipSub, and by the Pilot Protocol using libp2p DHT) works as follows:

1. **Bootstrap contact list.** Each agent starts with a small list of known peer agents (2-5 bootstrap peers) from direct configuration.
2. **Heartbeat broadcast.** Every 60 seconds, each agent broadcasts a signed OASF summary (uid + skill IDs + endpoint hash) to its connected peers.
3. **Forwarding with TTL.** Peers forward the broadcast to their own connected peers with `TTL - 1`. A TTL of 3 reaches an agent's third-degree network within 3 heartbeat intervals (~3 minutes).
4. **Local cache.** Each agent maintains a local capability cache keyed by AID. Before querying a registry, agents check their local cache for recently-seen matching UIDs.
5. **Fallback trigger.** When the central registry returns an error or times out, the orchestrator degrades to querying the local cache.

```python
# gossip_client.py — minimal p2p capability cache
import time, json, hashlib

class GossipCache:
    def __init__(self, ttl_seconds: int = 300):
        self._cache: dict[str, dict] = {}  # aid → {record, seen_at}
        self._ttl = ttl_seconds

    def update(self, oasf_summary: dict):
        uid = oasf_summary["uid"]
        self._cache[uid] = {
            "record": oasf_summary,
            "seen_at": time.time(),
        }

    def search_by_skill(self, skill_prefix: str) -> list[dict]:
        now = time.time()
        results = []
        for uid, entry in self._cache.items():
            if now - entry["seen_at"] > self._ttl:
                continue  # stale entry
            for skill_id in entry["record"].get("skill_ids", []):
                if skill_id.startswith(skill_prefix.replace("*", "")):
                    results.append(entry["record"])
                    break
        return results

    def evict_stale(self):
        now = time.time()
        self._cache = {
            uid: entry
            for uid, entry in self._cache.items()
            if now - entry["seen_at"] <= self._ttl
        }
```

The complete discovery flow for a production orchestrator looks like:

```python
async def find_agent(
    skill: str,
    registry: RegistryClient,
    gossip: GossipCache,
) -> dict | None:
    # 1. Try registry first (authoritative, fresh data)
    try:
        candidates = await registry.search(skill=skill, timeout=5.0)
        if candidates:
            return candidates[0]  # pick highest-ranked
    except (httpx.TimeoutException, httpx.HTTPStatusError):
        pass  # registry unavailable, fall through

    # 2. Fall back to local gossip cache
    cached = gossip.search_by_skill(skill)
    if cached:
        return cached[0]

    # 3. Fall back to direct config
    return FALLBACK_CONFIG.get(skill)
```

<Callout type="warning">
P2P gossip discovery is eventually consistent. An agent that just registered will not appear in peer caches until the next broadcast cycle (up to 3 minutes). For time-sensitive task delegation in production systems, always try the central registry first and use gossip only as a fallback. Never treat gossip cache results as authoritative — the agent's endpoint or capability set may have changed since the last broadcast. Always validate against the agent's live AgentCard before delegating high-stakes tasks.
</Callout>

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You are an A2A orchestrator. You have just queried a local AGNTCY registry and received the following two candidate agents for the skill 'nlp.sentiment.financial':\n\nAgent A: {\"name\": \"SentimentAnalystPro\", \"uid\": \"did:agntcy:sap-v2\", \"declared_latency_p50_ms\": 800, \"declared_success_rate\": 0.97, \"cost_per_task_usd\": 0.04}\nAgent B: {\"name\": \"QuickSentiment\", \"uid\": \"did:agntcy:qs-v1\", \"declared_latency_p50_ms\": 200, \"declared_success_rate\": 0.88, \"cost_per_task_usd\": 0.01}\n\nYou need to analyze quarterly earnings sentiment across 50 transcripts (high accuracy required). Which agent should you hire and why? Write a 3-sentence justification that references the specific metrics and explains the tradeoff."
  expectedOutput="SentimentAnalystPro (Agent A) is the better choice for high-accuracy batch analysis. Its 0.97 success rate is significantly higher than QuickSentiment's 0.88, which translates to roughly 5 fewer failures per 50 transcripts — important when earnings sentiment errors could influence financial decisions. The 4× cost difference ($2.00 vs. $0.50 total) is acceptable given the accuracy requirement and the higher operational cost of re-running failed tasks."
/>

---

## Centralized vs. Decentralized: The Architectural Choice

The outline's contrarian angle for this chapter is correct and deserves a direct treatment: **centralized registries like the GPT Store are architecturally anti-A2A**.

Here's why. The GPT Store model (and similar plugin marketplaces from other providers) has these properties:

- **Platform-controlled identity**: The platform assigns and can revoke agent IDs.
- **Platform-controlled discovery**: Only agents the platform approves appear in search results.
- **Platform-controlled relationships**: The integration between your orchestrator and a plugin runs through the platform's infrastructure, not directly between you and the plugin.

This is not discovery — it's a **walled garden**. If OpenAI decides to remove a plugin, every orchestrator that relied on it breaks. If Anthropic's plugin store goes down, discovery fails globally. The platform owns the relationship between agents.

An Internet of Agents built on A2A + AGNTCY has the opposite properties:

- **Self-sovereign identity** (DID-style AIDs): You generate your identity; no platform can revoke it.
- **Open directory**: Any agent can publish to AGNTCY; the directory indexes capability, not platform membership.
- **Direct relationships**: After discovery, your orchestrator communicates directly with the specialist over A2A. No intermediary proxy required.

The business implication is significant: building on A2A + AGNTCY means your agent-to-agent integrations survive registry failures, platform policy changes, and organizational boundaries. Building on a proprietary plugin marketplace means you're renting your network topology from a vendor.

This is the same battle that open vs. proprietary email won in the 1990s. SMTP doesn't care which email provider you use. A2A + AGNTCY doesn't care which agent framework you use. That's the point.

---

## Hands-On Exercise: Register, Discover, Hire

**Time estimate:** 30 minutes

**Prerequisites:** Python 3.10+, pip

### Setup

Start the local registry from earlier in this chapter:

```bash
pip install fastapi uvicorn httpx pydantic
uvicorn registry:app --port 8001 --reload
```

### Step 1 — Register two agents

Copy the OASF records below and register each one using the registry's POST endpoint.

**Agent 1 — Financial News Researcher:**
```bash
curl -X POST http://localhost:8001/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "did:agntcy:finresearch-001",
    "name": "FinancialNewsResearcher",
    "description": "Fetches and summarizes financial news.",
    "version": "1.0.0",
    "endpoints": [{"type": "a2a", "url": "http://localhost:8002",
                   "agent_card_url": "http://localhost:8002/.well-known/agent-card.json"}],
    "skills": [
      {"id": "news.fetch.financial", "name": "Financial News Fetch",
       "input_modes": ["text/plain"], "output_modes": ["application/json"]},
      {"id": "news.summarize.earnings", "name": "Earnings Summarizer",
       "input_modes": ["text/plain"], "output_modes": ["text/markdown"]}
    ],
    "auth": {"schemes": ["api_key"]}
  }'
```

**Agent 2 — Sentiment Analyst:**
```bash
curl -X POST http://localhost:8001/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "did:agntcy:sentiment-001",
    "name": "SentimentAnalyst",
    "description": "Analyzes financial text sentiment.",
    "version": "2.1.0",
    "endpoints": [{"type": "a2a", "url": "http://localhost:8003",
                   "agent_card_url": "http://localhost:8003/.well-known/agent-card.json"}],
    "skills": [
      {"id": "nlp.sentiment.financial", "name": "Financial Sentiment Analysis",
       "input_modes": ["text/plain", "application/pdf"], "output_modes": ["application/json"]},
      {"id": "nlp.ner.financial", "name": "Financial NER",
       "input_modes": ["text/plain"], "output_modes": ["application/json"]}
    ],
    "auth": {"schemes": ["oauth2", "dpop"]}
  }'
```

### Step 2 — Discovery queries

Run the following capability queries and record the results:

```bash
# Query 1: Find all NLP agents (broad prefix)
curl "http://localhost:8001/v1/agents/search?skill=nlp.*"

# Query 2: Find financial sentiment agents with JSON output
curl "http://localhost:8001/v1/agents/search?skill=nlp.sentiment.financial&output_modes=application/json"

# Query 3: Find news agents (should return Agent 1 only)
curl "http://localhost:8001/v1/agents/search?skill=news.*"

# Query 4: Find agents that do NOT exist
curl "http://localhost:8001/v1/agents/search?skill=code.generation.*"
```

**Expected results:**
- Query 1 → 1 agent (SentimentAnalyst)
- Query 2 → 1 agent (SentimentAnalyst)
- Query 3 → 1 agent (FinancialNewsResearcher)
- Query 4 → 0 agents

### Step 3 — Orchestrator hire flow

Write a Python function that:
1. Queries the local registry for an agent with skill `nlp.sentiment.financial`
2. Extracts the first result's `agent_card_url`
3. Probes that URL to retrieve the live AgentCard (use `http://localhost:8003/.well-known/agent-card.json` — it won't exist yet, so handle the `ConnectionRefused` gracefully)
4. Prints: "Would hire: {name} at {endpoint}" if the AgentCard probe succeeds, or "Would hire from registry cache: {name}" if the probe fails

**Success criteria:**
- `curl "http://localhost:8001/v1/agents/search?skill=nlp.sentiment.*"` returns exactly 1 agent
- `curl "http://localhost:8001/v1/agents/search?skill=code.*"` returns 0 agents
- Your Python function prints a "Would hire" line (from registry or cache) without crashing on the missing AgentCard endpoint

This is the core loop of every A2A orchestrator: **discover → probe → hire**. Chapter 4 builds on this by defining what a specialist agent does after it's hired.

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| AGNTCY | Linux Foundation initiative providing open infrastructure (discovery, identity, messaging, observability) for cross-vendor agent collaboration |
| OASF | Open Agentic Schema Framework — extensible JSON data model for describing agent capabilities, identity, and endpoints |
| AID | Agent Identity — a DID-style globally unique identifier bound to a cryptographic key pair, independent of any registry |
| Agent Directory Service | AGNTCY's distributed registry for agent announcement and discovery, synchronizable across nodes |
| Capability Indexing | Registry feature that indexes OASF skill taxonomies (dotted notation) for prefix-match and fuzzy search |
| Well-Known URI | RFC 8615-compliant endpoint (`/.well-known/agent-card.json`) where every A2A agent publishes its AgentCard |
| Gossip Discovery | P2P fallback discovery where agents exchange signed OASF summaries via broadcast (GossipSub/DHT), bypassing the central registry |
| Skill Taxonomy | Hierarchical dotted-namespace skill identifiers (e.g., `nlp.sentiment.financial`) enabling broad-to-narrow capability queries |

---

## What's Next

[[multi-agent-orchestration-a2a/chapter-04|Chapter 4: Modeling Roles and Capabilities — The Specialized Agent]] answers the question you haven't asked yet: once an orchestrator *finds* a specialist via discovery, how does the specialist enforce its own boundaries? You'll implement Recursive Task Decomposition, design a Capability Advertisement with cost-per-task, and build a specialist that rejects out-of-scope tasks rather than silently hallucinating an answer. The "No" is load-bearing.

---

*Sources: [AGNTCY — Internet of Agents](https://agntcy.org/) · [AGNTCY Documentation](https://docs.agntcy.org/) · [Open Agentic Schema Framework](https://docs.agntcy.org/oasf/open-agentic-schema-framework/) · [OASF GitHub](https://github.com/agntcy/oasf) · [A2A Agent Discovery](https://a2a-protocol.org/latest/topics/agent-discovery/) · [A2A Specification v1.0.0](https://a2a-protocol.org/latest/specification/) · [Linux Foundation AGNTCY Announcement](https://www.linuxfoundation.org/press/linux-foundation-welcomes-the-agntcy-project-to-standardize-open-multi-agent-system-infrastructure-and-break-down-ai-agent-silos) · [Hyperspace Gossip Protocol](https://protocol.hyper.space/)*
