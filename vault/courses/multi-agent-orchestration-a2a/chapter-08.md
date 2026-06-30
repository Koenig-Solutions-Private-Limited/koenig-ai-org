---
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8560
course: multi-agent-orchestration-a2a
chapter_num: 8
title: "Secure Communication — Auth, DPoP, and Trust Models"
slug: multi-agent-orchestration-a2a-chapter-08
description: "Encrypted channels are table stakes. This chapter layers application-level token binding with DPoP, delegated trust chains via OAuth 2.0 Token Exchange, network-layer agent sandboxing, and zero-trust sanitization of every incoming A2A message — so Agent B can verify not just who Agent A is, but what the user actually authorized."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 55
reading_time_min: 15
last_updated: 2026-06-15
chapter_primary_query: "how to secure A2A agent-to-agent communication with DPoP tokens, delegated trust chains, and prompt injection defenses"
first_60_words_answer: "Layer three independent guarantees to secure A2A communication: TLS or mTLS for transport identity, DPoP for application-layer token binding (a stolen token is worthless without the matching private key), and OAuth 2.0 Token Exchange for delegated trust chain verification — Agent B cryptographically confirms the user authorized Agent A's delegation. Treat every incoming task payload as untrusted regardless of caller identity."
prerequisites_chapters: [2]
learning_objectives:
  - Implement DPoP-bound OAuth tokens as an application-layer hardening pattern on top of A2A's security declaration model, correctly framing DPoP as an OAuth 2.0 extension rather than an A2A-native feature
  - Design a delegated trust chain using OAuth 2.0 Token Exchange so Agent B can cryptographically verify the user authorized Agent A's specific delegation
  - Describe the A2A spec's security surface (AgentCard securitySchemes, header-only credentials, Agent Card access controls) versus implementation hardening patterns
  - Implement a security middleware layer that validates identity, scope, replay protection, and prompt injection before handing an inbound A2A task to the agent's LLM core
tags: [A2A, security, DPoP, OAuth, mTLS, delegated-trust, prompt-injection, zero-trust, agent-sandboxing, token-exchange]
status: g3-passed
positions: [audit-trail-as-enterprise-gate]
sources:
  - url: "https://tyk.io/learning-center/a2a-protocol-architecture-and-technical-specification"
    title: "Tyk: A2A Protocol Architecture and Technical Specification"
    retrieved: "2026-06-15"
  - url: "https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security"
    title: "Red Hat Developer: How to Enhance A2A Security"
    retrieved: "2026-06-15"
  - url: "https://datatracker.ietf.org/doc/html/rfc9449"
    title: "RFC 9449: OAuth 2.0 Demonstrating Proof of Possession (DPoP)"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/dpop-rfc-9449-explained"
    title: "WorkOS: DPoP (RFC 9449) Explained"
    retrieved: "2026-06-15"
  - url: "https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf"
    title: "OpenID Foundation: Identity Management for Agentic AI"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/ai-agent-credentials"
    title: "WorkOS: Securing Agentic Apps — AI Agent Credentials"
    retrieved: "2026-06-15"
  - url: "https://www.diagrid.io/blog/making-agent-to-agent-a2a-communication-secure-and-reliable-with-dapr"
    title: "Diagrid: Making A2A Communication Secure with Dapr"
    retrieved: "2026-06-15"
  - url: "https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/"
    title: "Microsoft Open Source: Introducing the Agent Governance Toolkit"
    retrieved: "2026-06-15"
  - url: "https://cloudsecurityalliance.org/blog/2026/02/02/the-agentic-trust-framework-zero-trust-governance-for-ai-agents"
    title: "Cloud Security Alliance: The Agentic Trust Framework"
    retrieved: "2026-06-15"
quiz:
  - question: "DPoP (RFC 9449) is best described as:"
    options:
      - "An A2A-native feature mandated by the v1.0 spec for all compliant agent deployments"
      - "An OAuth 2.0 extension that sender-constrains bearer tokens to the holder's private key"
      - "A TLS extension that replaces mutual certificate exchange with lightweight per-request JWT proofs"
      - "A JSON Web Token profile in the A2A specification used for signing AgentCard payloads at publication"
    correct_idx: 1
    explanation: "DPoP is defined in RFC 9449 as an OAuth 2.0 extension — not part of the A2A protocol. The A2A spec's enterprise guidance endorses it alongside mTLS-bound tokens as a higher-assurance alternative to plain bearer tokens, but mandates neither. A2A's security is at the declaration layer (securitySchemes); DPoP is a hardening choice layered on top."
    section_anchor: dpop-sender-constraining-bearer-tokens

  - question: "The scope attenuation invariant in delegated agent authorization means:"
    options:
      - "Agent B must request the union of its own and Agent A's scopes to ensure full task coverage"
      - "Agent B's effective scope is the intersection of its role and Agent A's delegation — permissions only narrow"
      - "The authorization server grants Agent B all user-level scopes to prevent permission gaps in the chain"
      - "Scope constraints apply only at token-request time; once issued, tokens carry the full delegating agent's authority"
    correct_idx: 1
    explanation: "Scope attenuation requires that each delegation hop can only shrink, not grow, the permission set. Agent B's effective authority is intersection(B's own role, A's delegated scope). This prevents a compromised or over-requesting sub-agent from escalating to permissions its role was never individually authorized to hold."
    section_anchor: delegated-trust-proving-the-user-authorized-the-chain

  - question: "Prompt injection is structurally worse in A2A multi-agent systems than in single-agent systems because:"
    options:
      - "Each additional agent adds untrusted message boundaries, multiplying injection opportunities beyond what classifiers can reliably scan"
      - "The A2A spec omits injection defenses entirely, so no standard detection tooling exists for inter-agent message payloads"
      - "Peer-agent messages carry implicit trust, so one successful injection propagates through every downstream agent that handles the output"
      - "A2A's JSON-RPC framing lacks content-type headers, so injection-detection middleware has no standard field to inspect in payloads"
    correct_idx: 2
    explanation: "Receiving agents tend to treat peer-agent messages as more trusted than user input — the exact inverse of what security requires. An injected instruction in one agent's output can silently propagate if downstream agents don't validate task content as untrusted input at every hop. The structural amplification is why zero-trust per-message validation is required."
    section_anchor: prompt-injection-via-a2a-messages

  - question: "What does the A2A spec define in the AgentCard securitySchemes field?"
    options:
      - "The exact OAuth token endpoint URL and required DPoP key algorithm all callers must implement"
      - "The authentication scheme families the agent accepts (OAuth2, mTLS, OIDC, API key) in OpenAPI format"
      - "A mandatory JWKS discovery endpoint for callers to verify the AgentCard's cryptographic signature before trusting it"
      - "The minimum TLS version and cipher suite required for all transport-layer connections to the agent"
    correct_idx: 1
    explanation: "The A2A spec reuses the OpenAPI Security Scheme format verbatim. It declares which scheme families the agent accepts and which scopes are required per skill — but says nothing about how to obtain tokens, which OAuth flow to use, or what key algorithm callers must provide. Those implementation choices are left entirely to deploying organizations."
    section_anchor: what-the-a2a-spec-actually-defines

  - question: "Network-layer agent sandboxing is categorically stronger than prompt-layer access policy because:"
    options:
      - "Network rules appear in auditable infrastructure logs while prompt-layer policies live only inside volatile LLM context"
      - "Network-blocked resources are unreachable regardless of what the LLM reasons, imagines, or is prompted to attempt"
      - "Prompt-layer policies add latency to every LLM inference call while network packet filtering imposes near-zero overhead"
      - "The A2A v1.0 specification explicitly mandates network-layer enclave isolation for all agents in production by default"
    correct_idx: 1
    explanation: "An LLM can potentially reason around or be prompted to override a system-prompt access restriction. A resource that is genuinely unreachable at the network layer — because no route exists — cannot be accessed regardless of the LLM's reasoning or injected instructions. Network-layer containment is enforced outside the agent's own control plane."
    section_anchor: agent-sandboxing-and-trust-tiers
faq:
  - question: "What exactly does DPoP prevent that plain bearer tokens don't?"
    answer: "A plain bearer token is reusable by any party that intercepts it — equivalent to a door key that works in any lock. A DPoP-bound token contains a cnf.jkt claim: a SHA-256 fingerprint of the caller's JWK public key. The resource server verifies that the caller can sign a fresh proof JWT with the matching private key on every request. Without the private key (which only the legitimate agent holds and never transmits), the stolen token is rejected every time. ([RFC 9449: OAuth 2.0 DPoP](https://datatracker.ietf.org/doc/html/rfc9449))"
  - question: "How does OAuth 2.0 Token Exchange prove user authorization across an agent chain?"
    answer: "RFC 8693 Token Exchange lets Agent A obtain a new token T2 by presenting its existing token T1 at the authorization server's token endpoint. T2 is narrowly scoped to Agent B's specific skill and carries an act claim identifying Agent A as delegating party. When Agent B receives T2, it can verify the full chain — the sub claim names the original user, the act claim names Agent A, and the scope is bounded to exactly what Agent A was authorized to delegate. Neither Agent B's nor Agent A's permissions can exceed what T2's scope allows. ([OpenID Foundation: Identity Management for Agentic AI](https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf))"
  - question: "Does the A2A spec require Agent Cards to be cryptographically signed?"
    answer: "No. As of A2A v1.0, the spec supports card signing (added in v0.3+) but does not mandate it. An unsigned AgentCard served from a compromised DNS or CDN record can be spoofed to redirect callers to a malicious endpoint with a fabricated capability set. Production deployments should either sign cards with a verifiable key or serve them exclusively from mTLS-authenticated endpoints. ([Red Hat Developer: How to Enhance A2A Security](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security))"
---

# Secure Communication — Auth, DPoP, and Trust Models

> **Chapter 8 of 10 · 55 min (prose ~15 min + 25 min hands-on)**

---

## Encrypted Channels Are Table Stakes

Layer three independent guarantees to secure A2A communication: TLS or mTLS for transport identity, DPoP for application-layer token binding (a stolen token is worthless without the matching private key), and OAuth 2.0 Token Exchange for delegated trust chain verification — Agent B cryptographically confirms the user authorized Agent A's delegation. Treat every incoming task payload as untrusted regardless of caller identity. TLS alone achieves only the first layer: it does nothing about stolen tokens, hallucinated authorizations, or prompt injection delivered through the task payload. This chapter builds all three.

---

## What the A2A Spec Actually Defines

The A2A spec's security model is a **declaration layer only**. Three things are spec-grounded (the AgentCard format itself was covered in [[chapter-02.md]]):

1. **AgentCard `securitySchemes`:** Every agent card publishes which authentication scheme families it accepts — OAuth2, API key, mTLS, or OIDC — using the OpenAPI Security Scheme format verbatim. The [Tyk A2A architecture guide](https://tyk.io/learning-center/a2a-protocol-architecture-and-technical-specification) quotes the spec pattern directly: agents bind each skill to required scopes in a `security` block.
2. **Credentials in HTTP headers only.** Authorization material goes in the `Authorization` header on each A2A call — never embedded in JSON-RPC params, where it would appear in structured message traces.
3. **Agent Card endpoints must be access-controlled.** Per the [Red Hat A2A security analysis](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security): *"The specification establishes that the Agent Card endpoint must be protected by appropriate access controls such as authentication, mTLS, network restrictions."* An unprotected card leaks your entire capability and routing surface.

What the spec leaves to implementers: how tokens are obtained, whether cards are signed, how the delegation chain from user to Agent A to Agent B is structured, and all prompt injection defenses.

<KnowledgeCheck question="Where does the A2A spec require credentials to be placed?" options={["Embedded in JSON-RPC method params alongside the task identifiers and skill IDs", "In the HTTP Authorization header attached to every outbound A2A call", "Inside the AgentCard securitySchemes block as a static credential or pre-shared API key", "In a DPoP proof JWT included in the well-known AgentCard endpoint response body"]} correctIdx={1} explanation="The spec requires credentials in HTTP Authorization headers, keeping them out of structured JSON-RPC logs and payload traces. Authorization material in the JSON-RPC params is non-compliant with the spec's security guidance." />

---

## OAuth Scopes and Least-Privilege Declarations

The spec endorses four scheme families, each at a different assurance level:

| Scheme | What it proves | When to use |
|--------|---------------|-------------|
| OAuth 2.0 | Application-level scoped authorization | Default for most agent networks |
| OIDC | Cryptographic identity of the calling agent | When caller identity matters beyond authorization |
| API key | Simple machine-to-machine auth | Low-stakes internal, scope-less calls only |
| mTLS | Transport-layer bidirectional identity via X.509 | Enterprise or high-assurance baseline |

Each skill in the AgentCard maps to specific OAuth scopes. Calling agents request only the scopes they need for the skills they invoke — the direct analog of least-privilege at the capability level. Scope names like `agent:delegate` or `flights:write` are implementation conventions; the A2A spec defines no scope vocabulary.

<Callout type="warning">
AgentCard signing is supported in A2A v0.3+ but is **not mandated** by v1.0. An unsigned card served from a compromised CDN or spoofed DNS record can redirect callers to a malicious endpoint with a fabricated capability advertisement. In production: sign your cards or serve them exclusively from mTLS-authenticated endpoints.
</Callout>

---

## DPoP: Sender-Constraining Bearer Tokens

A plain OAuth bearer token is reusable by anyone who intercepts it. [DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) fixes this at the application layer without a full PKI. The agent holds a P-256 key pair and attaches a short-lived proof JWT on every request:

```http
POST /a2a/ HTTP/1.1
Authorization: DPoP <access-token>
DPoP: <proof-JWT signed with private key>
```

The proof JWT binds the request to the exact HTTP method (`htm`) and URI (`htu`), plus a fresh `jti` for replay prevention. The access token carries a `cnf.jkt` claim — the JWK SHA-256 thumbprint of the agent's public key. A stolen token presented without the matching DPoP proof returns `401 Unauthorized` every time.

**Classification:** DPoP is an OAuth 2.0 hardening extension layered on A2A — not an A2A-native feature. The A2A spec's enterprise guidance endorses it as the application-layer alternative to full mTLS-bound tokens, but mandates neither.

<KnowledgeCheck question="Why does a DPoP-bound token become useless if intercepted and reused by a different party?" options={["Presenting the token requires a fresh proof JWT signed by the private key only the legitimate caller holds", "The authorization server records each token's jti and invalidates the token after the first successful validation", "DPoP tokens embed a 30-second expiry that elapses before a network attacker can redeploy them to another service", "DPoP tokens are end-to-end encrypted and cannot be decoded without the recipient agent's private decryption key"]} correctIdx={0} explanation="The cnf.jkt claim in a DPoP-bound token is a fingerprint of the caller's JWK public key. Every resource server verifies that the DPoP proof header is signed with the key matching that fingerprint. Without the private key — which only the legitimate agent generated and holds — no valid proof can be produced and the token is rejected." />

---

## Delegated Trust: Proving the User Authorized the Chain

mTLS tells Agent B *who* Agent A is. It does not tell Agent B *what the user authorized Agent A to delegate*. This distinction is the chapter's hardest concept and the least addressed by the A2A spec. Orchestration patterns that generate these delegation chains were covered in [[chapter-06.md]] — this chapter addresses how to verify them cryptographically.

The current best pattern is **OAuth 2.0 Token Exchange** (RFC 8693). The [OpenID Foundation's Identity Management for Agentic AI](https://openid.net/wp-content/uploads/2025/10/Identity-Management-for-Agentic-AI.pdf) describes it for agent chains:

1. User authenticates → authorization server issues token T1 (broad scope)
2. Agent A exchanges T1 for T2, scoped narrowly to Agent B's specific skill, with an `act` claim identifying Agent A as the delegating party
3. Agent B validates T2 — the `sub` claim traces to the original user, `act` traces to Agent A, and `scope` is bounded to this delegation

The **scope attenuation invariant** governs every hop: Agent B's effective permissions are `intersection(B's own role, A's delegated scope)`. As [WorkOS articulates](https://workos.com/blog/ai-agent-credentials): permissions can only narrow through the chain, never widen. An authorization server should reject any sub-agent token request that attempts scope expansion.

Multi-hop chains (A→B→C→D) accumulate one token exchange round-trip per hop. This is a known scalability gap — no standard efficiently handles recursive delegation at depth as of 2026.

---

## Agent Sandboxing and Trust Tiers

Network-layer isolation is categorically stronger than prompt-layer access policy. An agent that cannot reach a resource at the network layer cannot be prompted, tricked, or hallucinated into reaching it. The [Cloud Security Alliance Agentic Trust Framework](https://cloudsecurityalliance.org/blog/2026/02/02/the-agentic-trust-framework-zero-trust-governance-for-ai-agents) describes enclave-based containment: agents assigned to an enclave have zero network visibility of resources outside it — enforced at the routing layer, where the agent has no influence.

The ATF also defines progressive trust tiers for autonomous agents:

| Tier | Autonomy | Gate to promote |
|------|---------|----------------|
| Intern | All actions require human approval | None — default for new agents |
| Junior | Act + notify post-action | Dwell time + performance thresholds |
| Senior | Autonomous within domain | DPoP/mTLS compliance + audit log integrity |
| Principal | Full agency | Governance sign-off |

For inbound A2A tasks: **authentication tells you who sent the message, not whether the content is safe to execute.** Always treat incoming task `message.parts` as untrusted input, regardless of how well-authenticated the calling agent is.

---

## Prompt Injection via A2A Messages

Microsoft's [Agent Governance Toolkit](https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/) (April 2026) frames the core problem: *"Trust is dynamic, not static. A binary trusted and untrusted model doesn't capture reality."* The implication for prompt injection is direct — receiving agents that default to implicit trust in peer-agent messages create exactly the attack surface that multi-agent injection exploits. A successful injection into one upstream agent propagates through every downstream agent that treats the poisoned output as authoritative.

Four attack classes to defend against:

| Attack | Mechanism |
|--------|-----------|
| Control-flow hijacking | Injected metadata redirects which agent handles the next step |
| Confused deputy | Compromised Agent B exploits Agent A's elevated delegated scope |
| Context contamination | Malicious artifact content poisons downstream agents' LLM context |
| Capability bleed | Shared memory or context stores enable cross-task scope leakage |

Defense-in-depth layers (none eliminates the risk alone):
1. **Structural validation first** — schema, type, and size-bound checks before any NLP processing
2. **NLP pattern scanning** — flag instruction-override signatures and role-switch commands
3. **External content tagging** — wrap all incoming task content in `<EXTERNAL_CONTENT>` tags with a system-prompt directive marking tagged content as untrusted regardless of message origin
4. **Intent diffing** — compare original task intent against what downstream agents are being asked to do; semantic drift signals injection

Prompt injection in A2A systems remains an unsolved problem as of 2026. These patterns are defense-in-depth layers, not elimination strategies.

---

## The Secure Inbound Task Middleware

The validation chain below must complete before any inbound A2A task reaches your agent's LLM core. Steps 1–5 are the hard security floor; steps 6–8 are defense-in-depth.

```python
async def validate_inbound_task(request: A2ARequest, task: Task) -> Task:
    # 1. mTLS: terminated at the service mesh/load balancer before application code runs.
    #    If not using mTLS, add client-cert validation here.

    # 2. Auth header extraction
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise AuthenticationError("Missing or malformed Authorization header")
    token = auth.split(" ", 1)[1]

    # 3. DPoP proof validation (if this endpoint requires DPoP)
    dpop = request.headers.get("DPoP")
    if dpop:
        validate_dpop_proof(
            dpop, token,
            method=request.method,
            uri=request.uri,        # htm + htu must match exactly
        )
        # Checks: ES256 signature, iat freshness (<120s),
        # jti uniqueness in Redis store (300s TTL), cnf.jkt binding

    # 4. JWT validation + claims
    claims = verify_jwt(token, audience=THIS_AGENT_AUDIENCE)

    # 5. Scope enforcement for the requested skill
    required = SKILL_SCOPE_MAP[task.skill_id]
    if required not in claims.get("scope", "").split():
        raise AuthorizationError(f"Token missing scope: {required}")

    # 6. Replay protection on task ID
    if not task_nonce_store.add_if_absent(task.id, ttl=300):
        raise ReplayError("Duplicate task ID within replay window")

    # 7. Prompt injection sanitization + untrusted content tagging
    for part in task.message.parts:
        if part.type == "text":
            sanitize_for_injection(part.text)   # raises on injection patterns
            part.text = f"<EXTERNAL_CONTENT>\n{part.text}\n</EXTERNAL_CONTENT>"

    # 8. Scope attenuation for On-Behalf-Of delegated tokens
    if "act" in claims:
        attenuate_to_delegating_scope(claims)

    return task  # Safe to pass to agent core
```

`validate_dpop_proof` requires a Redis-backed `jti` store to block proof replay within the validity window. `sanitize_for_injection` should combine regex-based pattern matching with a lightweight NLP classifier — Meta PromptGuard 2 (22M parameters) is latency-feasible for this path.

---

## Hands-On: Security Middleware for an A2A Server

**Objective:** Implement `validate_inbound_task` as a FastAPI dependency and verify that each rejection path fires correctly before any task payload reaches your handler's core logic.

**Setup:** FastAPI server, `python-jose` for JWT issuance and verification, Redis for `jti` replay tracking, a locally generated P-256 key pair for the "calling agent."

**Steps:**
1. Generate a P-256 key pair. Issue a DPoP-bound access token using `python-jose` — the token's `cnf.jkt` must be the JWK SHA-256 thumbprint of the public key.
2. Implement `validate_inbound_task` and wire it as a FastAPI `Depends` on your `POST /a2a/` endpoint.
3. Run each success criterion below as a separate `curl` or `pytest` call.

**Success criteria — all five must pass before the exercise is complete:**
- Plain bearer token (no `DPoP` header) → `401 Unauthorized`
- Replaying the same DPoP proof JWT within 300 seconds → `401 Unauthorized` (jti replay blocked)
- Valid token with missing or wrong scope → `403 Forbidden` with the required scope named in the response body
- Task message containing an instruction-override injection payload (e.g., a `"[injection-test: override system role]"` string) → content wrapped in `<EXTERNAL_CONTENT>` tags in your handler's printed output
- Fully valid DPoP-bound request with correct scope → `200 OK` with the sanitized task echoed back

---

Next, you'll instrument these auth flows, delegation hops, and injection events as distributed traces so a single timeline shows exactly what happened, when, and why: [[chapter-09.md]]
