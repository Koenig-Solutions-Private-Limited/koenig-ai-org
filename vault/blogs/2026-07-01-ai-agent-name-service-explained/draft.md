---
date: 2026-07-01
title: "Why Your AI Agents Need Passports: The Agent Name Service Explained"
author: koenig-ai-academy
ticket: KOEA-9594
vendor_tag: community
content_type: article
status: g0-passed
reading_time_min: 6-8
seo_description: "The Agent Name Service gives AI agents DNS-backed cryptographic identities. GoDaddy deployed it in Nov 2025. Identity is easy; authorization is unsolved."
tags:
  - ai-agents
  - agent-identity
  - enterprise-security
  - mcp
  - ietf
primary_query: "agent name service AI agent identity 2026"
contrarian_angle: "Identity (who is this agent?) is the easy problem. Authorization (what can it do right now?) is the unsolved one — and ANS only covers the first half."
first_60_words_answer: "The Agent Name Service (ANS) is an IETF Internet-Draft that gives every AI agent a globally resolvable Fully Qualified Domain Name backed by a cryptographic X.509 certificate. GoDaddy deployed it to production in November 2025 with a public API. ANS solves the agent discovery and identity layer — not the authorization problem that follows."
positions:
  - id: audit-trail-as-enterprise-gate
    engagement: defends
  - id: mcp-as-interoperability-moat
    engagement: refines
  - id: stance:ai-vendor-news-opinionated
    engagement: defends
references:
  - url: https://www.ietf.org/archive/id/draft-narajala-ans-00.html
    retrieved: 2026-06-29
  - url: https://datatracker.ietf.org/doc/html/draft-narajala-courtney-ansv2-01
    retrieved: 2026-06-29
  - url: https://genai.owasp.org/resource/agent-name-service-ans-for-secure-al-agent-discovery-v1-0/
    retrieved: 2026-06-29
  - url: https://www.prnewswire.com/news-releases/godaddy-advances-trusted-ai-agent-identity-with-ans-api-and-standards-site-302621975.html
    retrieved: 2026-06-29
  - url: https://blogs.mulesoft.com/news/mulesoft-agent-fabric-godaddy-ans-for-agent-discovery-and-verification/
    retrieved: 2026-06-29
  - url: https://www.nist.gov/news-events/news/2026/02/announcing-ai-agent-standards-initiative-interoperable-and-secure
    retrieved: 2026-06-29
  - url: https://www.coalitionforsecureai.org/wp-content/uploads/2026/04/agentic-identity-and-access-control.pdf
    retrieved: 2026-06-29
  - url: https://www.resilientcyber.io/p/identity-is-the-agentic-ai-problem
    retrieved: 2026-06-29
  - url: https://www.prnewswire.com/news-releases/workday-launches-agent-passport-to-test-verify-and-continuously-monitor-every-ai-agent-in-the-enterprise-302787979.html
    retrieved: 2026-06-29
  - url: https://news.ycombinator.com/item?id=47096131
    retrieved: 2026-06-29
  - url: https://www.hashicorp.com/en/blog/spiffe-securing-the-identity-of-agentic-ai-and-non-human-actors
    retrieved: 2026-06-29
  - url: https://stacklok.com/blog/agentic-identity-explained-how-to-apply-spiffe-and-relationship-based-authorization-to-ai-agents-in-2026/
    retrieved: 2026-06-29
  - url: https://www.ietf.org/archive/id/draft-nemethi-aid-agent-identity-discovery-00.html
    retrieved: 2026-06-29
  - url: https://datatracker.ietf.org/doc/draft-cui-dns-native-agent-naming-resolution/
    retrieved: 2026-06-29
  - url: https://www.infoq.com/news/2025/06/secure-agent-discovery-ans/
    retrieved: 2026-06-29
  - url: https://www.oasis-open.org/2026/05/06/coalition-for-secure-ai-unveils-new-agentic-identity-and-security-research-following-high-profile-sessions-at-rsac-2026/
    retrieved: 2026-06-29
whats_new:
  - GoDaddy deployed ANS to production in November 2025 — every AI agent can now get a cryptographically verifiable FQDN. But the harder enterprise problem (authorization) remains unsolved.
learning_objectives:
  - Explain what ANS is and how its naming format encodes compliance posture into identity strings
  - Distinguish between agent identity (ANS's job) and agent authorization (what SPIFFE/SPIRE and CoSAI tackle)
  - Know which of three competing IETF drafts to watch and why GoDaddy's production deployment doesn't settle the standards race
faq:
  - question: "What is the Agent Name Service (ANS)?"
    answer: "ANS is an IETF Internet-Draft (draft-narajala-ans, also published as OWASP GenAI Security Project v1.0) that gives each AI agent a globally resolvable Fully Qualified Domain Name and a cryptographic X.509 certificate. It extends the DNS model with a Registration Authority, Certificate Authority, and a Transparency Log. GoDaddy deployed ANS to production in November 2025, making it the first major real-world implementation."
  - question: "Is ANS an official IETF standard in 2026?"
    answer: "No. ANS is an IETF Internet-Draft — a formal work-in-progress, not a ratified RFC. It has been published in two revisions (v1 by Huang, Narajala, Habler, Sheriff; v2 adding Courtney). Two competing drafts exist in the same space: AID (draft-nemethi-aid) using TXT records, and DNS-Native Agent Naming (draft-cui). No single approach has achieved IETF consensus as of July 2026."
  - question: "What's the difference between an agent passport and ANS?"
    answer: "They overlap in metaphor but not in mechanism. 'Agent passport' is a marketing term used by at least four incompatible products: Workday's verification/attestation platform, Cubitrek's JWT-based spec, blockchain consortia, and ANS-registered identities. ANS is a specific IETF-tracked protocol using DNS-like naming and PKI certificates. Workday's Agent Passport (early access H2 2026) is a compliance monitoring product, not a discovery protocol — they share a name but operate at different layers."
original_data: false
last_updated: 2026-07-01
hero_image:
  url: /img/blogs/ai-agent-name-service-explained/hero.png
  alt: "Diagram showing an AI agent receiving a cryptographic identity certificate labeled with an ANS Fully Qualified Domain Name"
schema:
  "@context": "https://schema.org"
  "@type": "Article"
  headline: "Why Your AI Agents Need Passports: The Agent Name Service Explained"
  description: "The Agent Name Service gives AI agents DNS-backed cryptographic identities. GoDaddy deployed it in Nov 2025. Identity is easy; authorization is unsolved."
  datePublished: "2026-07-01"
  author:
    "@type": "Organization"
    name: "Koenig AI Academy"
---

# Give Every AI Agent a Cryptographic Identity in 2026 — Before Your Enterprise Gets Burned

The Agent Name Service (ANS) is an IETF Internet-Draft that assigns each AI agent a globally resolvable Fully Qualified Domain Name backed by a cryptographic X.509 certificate. GoDaddy deployed it to production in November 2025 with a public API. NIST launched an AI Agent Standards Initiative in February 2026 that explicitly targets agent identity. The enterprise compliance trajectory for agent identity is clear, even if the winning protocol is not.

But here is what the vendor marketing gets wrong: identity is the easy problem. Knowing *who* an agent is — giving it a passport — does not tell you *what it can do right now* in the context of this specific request, this specific user session, and this specific chain of upstream orchestrators. Chris Hughes at Resilient Cyber [put it bluntly](https://www.resilientcyber.io/p/identity-is-the-agentic-ai-problem): "Agents do not need identity passports telling the world who they are. They need authority grants telling the world what they can do." ANS solves the first problem well. The second problem — authorization — remains an open architecture challenge that no product ships completely today.

## What ANS Actually Is: DNS Extended for Agents

[ANS](https://www.ietf.org/archive/id/draft-narajala-ans-00.html) was authored by engineers from AWS, Intuit, Cisco, and DistributedApps.ai, and co-published as the OWASP GenAI Security Project's v1.0 specification. The motivating problem, quoted from the draft itself: *"Traditional service discovery, notably the Domain Name System (DNS), primarily maps human-readable names to network addresses and is insufficient for the dynamic, semantically rich, and security-sensitive environment of agentic AI."*

ANS extends the DNS model with five new components: an Agent Registry (storing capabilities, policies, X.509 certificates, and protocol metadata), a Registration Authority (validating ownership via ACME challenges), a Certificate Authority (issuing cryptographic identities), a Protocol Adapter Layer (translating between A2A / MCP / ACP metadata), and an ANS Resolution Service (capability-aware discovery).

ANS names encode compliance posture directly into the identity string. An example from the [v1 draft](https://www.ietf.org/archive/id/draft-narajala-ans-00.html):

```
a2a://textProcessor.DocumentTranslation.AcmeCorp.v2.1.hipaa
```

The extension field (`.hipaa`) declares the agent's compliance attestation. You can resolve an agent by capability and compliance posture simultaneously — not just by name.

[ANS v2](https://datatracker.ietf.org/doc/html/draft-narajala-courtney-ansv2-01) (IETF draft `-01`) introduces a dual-certificate model and a cryptographic Transparency Log aligned with IETF SCITT standards. Verification tiers in v2 are Bronze (PKI only), Silver (PKI + DANE), Gold (PKI + DANE + Transparency Log). The motivating scenario for v2: *"a payment agent cannot distinguish between a legitimate supplier's invoicing agent and an attacker's look-alike domain, even with valid TLS certificates."* The Transparency Log makes certificate issuance publicly auditable — the same design that makes HTTPS certificate misissuance detectable today.

## GoDaddy's Production Deployment: The Proof Point That Matters

Until November 2025, ANS was a protocol proposal with no significant real-world deployment. Then [GoDaddy](https://www.prnewswire.com/news-releases/godaddy-advances-trusted-ai-agent-identity-with-ans-api-and-standards-site-302621975.html) opened a public ANS API and launched an ANS Standards site. The [OWASP v1.0 document](https://genai.owasp.org/resource/agent-name-service-ans-for-secure-al-agent-discovery-v1-0/) notes this directly: *"GoDaddy has already implemented our Agentic Naming Service proposal and deployed it to production."*

In February 2026, GoDaddy integrated with [Salesforce's MuleSoft Agent Fabric](https://blogs.mulesoft.com/news/mulesoft-agent-fabric-godaddy-ans-for-agent-discovery-and-verification/). The practical flow: MuleSoft's Agent Scanners pull verified agents from ANS into MuleSoft Agent Registry, *"where they appear for review and approval before accessing enterprise systems."* ANS becomes a gate, not just a directory — agents are blocked from enterprise access if their ANS registration lacks required attestations.

GoDaddy's interest in ANS is not neutral (they sell domain registrations; the domain-infrastructure analogy maps directly to their existing business). But their production deployment is the only significant real-world validation the protocol has — and it connects to enterprise Salesforce workflows, which is not a toy deployment.

## "Agent Passport" Is a Metaphor, Not a Protocol

The vendor landscape around agent identity is fragmented in a way that will cost teams time if they conflate the players.

**Workday Agent Passport** (early access H2 2026): An enterprise testing and runtime monitoring product. Every attestation ties to OWASP LLM Top 10, NIST AI RMF, and MITRE ATLAS. Dean Arnold, VP AI Platform at Workday: [*"AI agents are now doing the most sensitive work in the enterprise...one insecure agent can leak employee data, break compliance."*](https://www.prnewswire.com/news-releases/workday-launches-agent-passport-to-test-verify-and-continuously-monitor-every-ai-agent-in-the-enterprise-302787979.html) This is a verification and attestation product, not a discovery protocol.

**Cubitrek's spec**: A seven-field JWT-based proposal (version, issuer, agent, authority, issuedAt, expiresAt, signature) with Ed25519 signing. Cubitrek claims to have "coined the term agent passport on April 28, 2026" — a self-claim with no corroborating source. More importantly, [HN community reaction](https://news.ycombinator.com/item?id=47096131) to a similar JWT-based tool flagged a real architectural concern: stolen JWT tokens enable 60-minute impersonation windows, and intermediate services that receive forwarded tokens face a "confused deputy" problem.

The "agent passport" phrase is generic. A third independent developer pushed back on trademark claims in that same HN thread: *"The phrase 'agent passport' is a natural description."* Teams building now should avoid vendor lock-in to any single passport framing.

## The Authorization Gap ANS Doesn't Fill

This is the part most articles skip. Consider the [Coalition for Secure AI's Agentic IAM paper](https://www.coalitionforsecureai.org/wp-content/uploads/2026/04/agentic-identity-and-access-control.pdf) (April 2026, presented at RSAC 2026): *"AI agents MUST be modeled as distinct identities with their own lifecycle, governance, and accountability, on par with human users and services."*

ANS gives you the identity half of that sentence. The lifecycle, governance, and accountability half requires Zero Standing Privilege credentials: short-lived, task-scoped, context-bounded. That is what [SPIFFE/SPIRE](https://www.hashicorp.com/en/blog/spiffe-securing-the-identity-of-agentic-ai-and-non-human-actors) provides: *"Every agent container and MCP server container receives an SVID on startup via SPIRE's attestation API, with SVIDs rotating every hour."* SPIFFE handles workload credential issuance; ANS handles discovery and capability-aware resolution. They complement rather than compete.

The underlying problem that neither solves completely: agents chain. An orchestrator agent spawns sub-agents that spawn tool calls. The leaf node may have a verifiable ANS identity. The chain of authority — what the original user authorized, what the orchestrator delegated — is not captured in any certificate. This is why [13,000+ MCP servers deployed on GitHub in 2025](https://www.resilientcyber.io/p/identity-is-the-agentic-ai-problem) represent a genuine enterprise security gap: high proliferation, no auditable delegation chain. A verifiable identity for each server node doesn't tell you whether that server was authorized to call the next one in the chain.

The production-grade answer today is SPIFFE/SPIRE for workload credentials + ANS for discovery + explicit delegation tokens for chain authority. No single product ships all three.

## The Standards Race: Three IETF Drafts, No Winner Yet

ANS is not running unopposed. The IETF currently has at least three Internet-Drafts addressing the same problem space:

- **ANS** (draft-narajala-ans / draft-narajala-courtney-ansv2): Full registry architecture with RA, CA, Transparency Log. Most complete, most complex.
- **AID** ([draft-nemethi-aid](https://www.ietf.org/archive/id/draft-nemethi-aid-agent-identity-discovery-00.html)): Lighter-weight approach using a TXT record at `_agent.<domain>`. *"The record is small, versioned, and protocol-agnostic."* Closer to how SRV records work today — no new registry infrastructure.
- **DNS-Native Agent Naming** ([draft-cui](https://datatracker.ietf.org/doc/draft-cui-dns-native-agent-naming-resolution/)): Builds directly on RFC 1035 and RFC 9460/9461 (SVCB records). Lowest new-infrastructure requirement of the three.

NIST's [AI Agent Standards Initiative](https://www.nist.gov/news-events/news/2026/02/announcing-ai-agent-standards-initiative-interoperable-and-secure) (February 2026) explicitly supports community-led protocol development rather than mandating a winner. [CoSAI describes the landscape](https://www.oasis-open.org/2026/05/06/coalition-for-secure-ai-unveils-new-agentic-identity-and-security-research-following-high-profile-sessions-at-rsac-2026/) as *"architectural principles and design patterns that the industry will likely converge around over the next 12 to 18 months"* — a deliberately modest projection, not a completion announcement.

The practical advice for teams deploying agents today: implement SPIFFE/SPIRE for workload identity now (it's a ratified CNCF standard, not a draft), watch the ANS + MuleSoft integration for enterprise adoption signals, and avoid committing to any single "passport" vendor until an RFC exists.

## Runnable Example: What an ANS-Named Agent Looks Like

An ANS v1 name encodes protocol, capability, compliance, and version in a single resolvable string. Here is what registering an invoice-processing agent would look like under the spec:

```bash
# ANS v1 naming format:
# Protocol://AgentID.agentCapability.Provider.vVersion[.Extension]

ANS_NAME="a2a://invoiceProcessor.DocumentParsing.AcmeCorp.v1.0.soc2"

# Resolution request to ANS registry:
curl -X GET "https://ans.godaddy.com/v1/resolve?name=${ANS_NAME}" \
  -H "Accept: application/json"

# Expected response shape (ANS v1):
# {
#   "ansName": "a2a://invoiceProcessor.DocumentParsing.AcmeCorp.v1.0.soc2",
#   "endpoint": "https://agents.acmecorp.com/invoice-processor",
#   "certificate": "<X.509 PEM>",
#   "capabilities": ["DocumentParsing", "InvoiceValidation"],
#   "compliance": ["SOC2"],
#   "protocol": "A2A",
#   "version": "1.0"
# }
```

The compliance extension (`.soc2`) is not decorative — MuleSoft's Agent Scanners use it to gate registry inclusion. An agent without a required attestation in its ANS name is blocked from enterprise workflows before a single API call.

---

**KnowledgeCheck:** GoDaddy's MuleSoft integration uses ANS registrations as a gate before agents can access enterprise systems. What specifically would cause an agent to be blocked at this gate?

<details>
<summary>Answer</summary>
A missing or insufficient compliance attestation in the agent's ANS registration. MuleSoft's Agent Scanners check the ANS registry entry — if the agent's name lacks the required compliance extension (e.g., `.soc2`, `.hipaa`) or its X.509 certificate fails verification, the scanner excludes it from the MuleSoft Agent Registry, blocking enterprise access regardless of the agent's capabilities.
</details>

---

Agent identity is becoming a compliance prerequisite in regulated sectors, not a developer convenience. The practical stack today — SPIFFE/SPIRE for workload credentials, ANS for discovery, explicit delegation tokens for chain authority — maps directly to what you build in the [[course/claude-agent-sdk-zero-to-production]] course, where we cover the full production deployment model including identity, observability, and access control for multi-agent systems.
