---
course_slug: picking-a-frontier-model-2026-q2
chapter_num: 5
chapter_slug: gpt-5-5-cyber-governance
title: "Governance and specialized cyber access — TAC, Project Glasswing, and Bedrock controls"
hero_image: "/courses/picking-a-frontier-model-2026-q2/assets/ch05-hero.svg"
status: awaiting-g0
author: "Koenig AI Instructor"
agent_drafted_by: 6c31c5e6-2664-42f9-a81b-470134878a10
vendor_tag: koenig-ai-academy
content_type: course-chapter
date: 2026-06-12
last_updated: 2026-06-15
description: "How OpenAI's Trusted Access for Cyber program and Anthropic's Project Glasswing create distinct governance paths for security teams — covering eligibility, endpoint controls, and agent/tool approval layers."
duration_min: 50
chapter_primary_query: "How do security teams govern access to GPT-5.5-Cyber and Claude Mythos through TAC and Glasswing programs?"
first_60_words_answer: "Specialized cyber access programs — OpenAI's Trusted Access for Cyber (TAC) and Anthropic's Project Glasswing — represent a structural shift in how frontier AI capability is delivered to security practitioners. Rather than treating all API customers as equivalent, both vendors now gate their highest-risk cyber capabilities behind eligibility programs that verify team identity, constrain permitted workflows, and impose logging and human-review obligations."
prerequisites_chapters: [1]
learning_objectives:
  - "Define the Trusted Access for Cyber program and explain how it changes the operating model for security teams using GPT-5.5-Cyber and Codex"
  - "Compare OpenAI's TAC path with Anthropic's Project Glasswing and Cyber Verification Program as two distinct governance models for gated cyber capability release"
  - "Separate three deployment questions that are frequently conflated: model access eligibility, endpoint governance, and agent/tool approval controls"
  - "Evaluate whether OpenAI-direct, OpenAI Enterprise, OpenAI models on Amazon Bedrock, or Anthropic Glasswing-style access better fits a security team's audit and control needs"
  - "Write a governance case study for a cyber-capable coding workflow naming permitted workflows, blocked workflows, audit fields, and escalation paths"
key_concepts:
  - Trusted Access for Cyber
  - GPT-5.5-Cyber limited preview
  - Codex Security plugin
  - Project Glasswing
  - Mythos Preview
  - Cyber Verification Program
  - endpoint governance
  - OpenAI models on Amazon Bedrock
  - IAM and regional controls
  - auditability
  - approved-use scoping
  - misuse monitoring
hands_on_exercise: "Write a one-page trusted-access cyber governance case study for one of four defensive scenarios, covering eligibility, permitted and blocked workflows, endpoint controls, tool approvals, logging fields, and escalation paths"
references:
  - "[^1]: OpenAI. 'Trusted Access for Cyber.' https://openai.com/index/trusted-access-for-cyber/"
  - "[^2]: OpenAI. 'GPT-5.5 with Trusted Access for Cyber.' https://openai.com/index/gpt-5-5-with-trusted-access-for-cyber/"
  - "[^3]: OpenAI. 'GPT-5.5 System Card.' https://deploymentsafety.openai.com/gpt-5-5/gpt-5-5.pdf"
  - "[^4]: Anthropic. 'Project Glasswing.' https://www.anthropic.com/glasswing"
  - "[^5]: Anthropic. 'Glasswing Initial Update.' https://www.anthropic.com/research/glasswing-initial-update"
  - "[^6]: AISI. 'Our evaluation of OpenAI's GPT-5.5 cyber capabilities.' https://www.aisi.gov.uk/blog/our-evaluation-of-openais-gpt-5-5-cyber-capabilities"
  - "[^7]: Amazon Web Services. 'OpenAI models on Amazon Bedrock.' https://aws.amazon.com/bedrock/openai/"
  - "[^8]: Amazon Web Services. 'OpenAI model cards — Amazon Bedrock.' https://docs.aws.amazon.com/bedrock/latest/userguide/model-cards-openai.html"
  - "[^9]: CNBC. 'OpenAI rolls out new GPT-5.5 Cyber to vetted cybersecurity teams.' https://www.cnbc.com/2026/05/07/openai-rolls-out-new-gpt-5point5-cyber-to-vetted-cybersecurity-teams.html"
slides: courses/picking-a-frontier-model-2026-q2/ch05-slides.pptx
faq:
  - question: "What is the Trusted Access for Cyber program and who qualifies?"
    answer: "OpenAI's Trusted Access for Cyber (TAC) is a gated deployment program that extends GPT-5.5-Cyber capabilities to vetted defensive security teams. Qualifying teams must demonstrate existing defensive expertise through organizational attestation and use-case description. Individual developers and general-purpose consultancies without demonstrated critical-infrastructure work do not qualify. See [OpenAI TAC](https://openai.com/index/trusted-access-for-cyber/)."
  - question: "Does deploying GPT-5.5 via Amazon Bedrock bypass TAC eligibility requirements?"
    answer: "No. Bedrock adds AWS-native endpoint controls — IAM role-based access, VPC private routing, CloudTrail audit logging, and regional data residency — but TAC eligibility is enforced at the OpenAI application layer regardless of which endpoint path delivers the API call. An unverified team calling GPT-5.5 through Bedrock receives the standard output policy, not the TAC-relaxed policy. See [AWS Bedrock OpenAI](https://aws.amazon.com/bedrock/openai/)."
  - question: "How does OpenAI's TAC differ from Anthropic's Project Glasswing for compliance teams?"
    answer: "TAC is a commercial deployment program with a fixed, published permitted-use taxonomy documented in the GPT-5.5 system card — straightforward for third-party auditors to cite. Project Glasswing's Cyber Verification Program is announced but not yet open for general applications as of Q2 2026; access is currently limited to approximately 50 invited organizational partners. Neither verification is cross-recognized. See [Anthropic Glasswing](https://www.anthropic.com/glasswing)."
# positions: STANCES.md reviewed; no directly engaged stances identified for this governance-focused chapter
positions: []
tags:
  - course/picking-a-frontier-model-2026-q2
  - governance
  - security
  - trusted-access
  - cyber
  - codex
  - glasswing
---

# Governance and specialized cyber access — TAC, Project Glasswing, and Bedrock controls

> **Prerequisites**: [Chapter 1](/learn/picking-a-frontier-model-2026-q2/01-dimensions-that-matter) required. The three deployment questions this chapter separates (model access, endpoint governance, agent/tool controls) build directly on the evaluation-dimensions framework from Chapter 1.
>
> **Time**: 50 minutes
>
> **Learning objectives**: By the end of this chapter, you can describe the Trusted Access for Cyber program, contrast it with Anthropic's Glasswing path, choose the right deployment architecture for an audit-grade security workflow, and produce a governance case study that would survive a compliance review.

Specialized cyber access programs — OpenAI's Trusted Access for Cyber (TAC) and Anthropic's Project Glasswing — represent a structural shift in how frontier AI capability is delivered to security practitioners. Rather than treating all API customers as equivalent, both vendors now gate their highest-risk cyber capabilities behind eligibility programs that verify team identity, constrain permitted workflows, and impose logging and human-review obligations. As of Q2 2026, GPT-5.5-Cyber is in limited preview to vetted security teams through the TAC program, with Codex included under expanded cyber-permissive access for verified critical-infrastructure defenders. [^1][^2] Anthropic's Project Glasswing serves a parallel function on the Claude side, with the Cyber Verification Program announced as forthcoming and Claude Mythos Preview access currently limited to approximately 50 invited organizational partners. [^4] The practical question for a security engineering team in 2026 is not simply "which model has the best cyber-capability benchmark score?" but rather "which access path, endpoint architecture, and governance structure can we operate, audit, and defend?"

## Key facts

1. **GPT-5.5-Cyber limited preview launched May 7, 2026**, rolling out to vetted cybersecurity teams through the Trusted Access for Cyber program. The Codex coding agent surface was subsequently included in the TAC program with fewer output restrictions for verified critical-infrastructure defenders. [^2][^9]
2. **The UK's AI Safety Institute (AISI) evaluated GPT-5.5's cyber capabilities** before the TAC program launched. The evaluation established the empirical basis for OpenAI's access controls by identifying the uplift risk the model poses for real exploit development. [^6]
3. **OpenAI models — including GPT-5.5 — are available on Amazon Bedrock** as of Q2 2026. Bedrock delivery changes endpoint governance (AWS IAM, VPC, CloudTrail) and regional data residency but does not bypass the upstream eligibility requirements that TAC places on the model access tier. [^7][^8]
4. **Anthropic's Project Glasswing** is the organizational home for Anthropic's cybersecurity capability research and the Cyber Verification Program. The Glasswing initial update documents the scope of Claude Mythos Preview access and the review obligations placed on participating teams. [^4][^5]
5. **"Fewer restrictions" in the TAC context is a precise technical term**, not a casual claim. The GPT-5.5 system card describes specific use-case categories that shift from blocked to monitored-with-approval for TAC-verified teams — vulnerability triage, patch authoring for CVEs, malware reverse-engineering support, and red-team validation. Exploit weaponization remains blocked. [^3]
6. **Three questions that get conflated**: (a) *model access eligibility* — which teams qualify for TAC or Glasswing verification; (b) *endpoint governance* — whether you call OpenAI-direct, OpenAI Enterprise, or Bedrock, and what controls each adds; (c) *agent and tool controls* — which Codex tools or Claude tool-use surfaces are permitted in scope, what logging is required, and who reviews flagged outputs. These three layers are independent; getting one right does not substitute for the others.
7. **The AISI evaluation found that GPT-5.5 provides meaningful uplift to attackers with some existing security knowledge.** [^6] This finding is *consistent with* TAC's eligibility focus on demonstrated defensive expertise rather than organizational affiliation alone — a risk-calibrated interpretation, though the direct causal link is this author's inference rather than a documented AISI finding.

---

```takeaways
- Trusted Access for Cyber gates GPT-5.5-Cyber behind team identity verification and approved workflow scope — not just an API key upgrade.
- Three questions are often conflated: model access eligibility, endpoint governance (direct/Enterprise/Bedrock), and agent/tool approval controls. Answering one does not answer the others.
- AISI's pre-launch cyber evaluation shaped the TAC eligibility model: risk scales with the attacker's existing knowledge, so gating requires demonstrated defensive expertise, not just organizational affiliation.
```

## Why governance is the seventh evaluation dimension

The first four chapters of this course focused on measurement: how reliable is the model's tool-use, how does long-context retrieval degrade, what does production cost actually look like. Those are the dimensions that determine whether a model works on your workload. This chapter addresses a different question — whether you can operate it within the risk and compliance constraints of a security organization.

Governance is not a post-selection consideration. For security teams, it is a primary constraint that eliminates access paths before any technical benchmark is run. A model that scores 94% on tool-use determinism but is unavailable under your organization's cloud provider agreement is not in your shortlist. A model capability that is technically superior but blocked under TAC's approved-use scope for your specific workflow is similarly off the table.

The outline for this course lists governance as the seventh of seven evaluation dimensions in Chapter 1 (alongside latency p95, tool-use determinism, context fidelity at depth, structured-output reliability, cost-per-task, and multimodal fidelity). The reason it is last is not that it matters least — it is that it is the filter you apply *after* confirming the model is technically capable. If a model fails on determinism or long-context retrieval, governance is irrelevant. If it passes, governance determines which of the viable paths is actually available to you.

For security teams specifically, governance is often the dimension with the longest lead time. Model access eligibility verification — TAC or Glasswing — can take weeks from application to approval. Endpoint procurement through an Enterprise agreement or Bedrock organizational setup takes time to negotiate and configure. Tool approval controls require internal security review before they can be deployed in a regulated environment. A team that defers governance assessment until after it has validated a model's technical performance will find itself with a technically viable model it cannot legally or operationally deploy. Starting governance evaluation in parallel with technical benchmarking is not overcaution; it is schedule management.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I'm a senior engineer on a defensive security team at a critical-infrastructure operator. We want to use an AI model to help with vulnerability triage on internally-discovered CVEs. We are not trying to build attack tools — only to accelerate our own patching. What governance questions should we be asking before we pick a model and access path? Give me a structured list."
  expectedOutput="A well-structured model will distinguish model access eligibility questions (does my team qualify for TAC or Glasswing?), endpoint questions (should we use OpenAI-direct, Enterprise, or Bedrock, and what does each add?), and agent/tool control questions (which tools can be in scope, what logging is required?). Notice whether the model conflates eligibility with endpoint selection — most do."
/>

## The Trusted Access for Cyber program

OpenAI launched the [Trusted Access for Cyber program](https://openai.com/index/trusted-access-for-cyber/) as a structured mechanism for extending GPT-5.5's cybersecurity capabilities to vetted defensive teams while managing the risk that the same capabilities pose in an attacker's hands. [^1] The program has three components that operate independently:

**Eligibility verification.** Teams applying for TAC must demonstrate existing defensive security expertise through organizational attestation, team-level vetting, and use-case description. The program is not available to individual developers, general-purpose security consultancies without demonstrated critical-infrastructure contracts, or research teams without institutional backing. Approval is not automatic on organizational affiliation — the AISI evaluation's finding that uplift scales with attacker existing knowledge is consistent with the requirement for demonstrated *defensive* expertise, though whether that finding directly shaped the eligibility design is not documented in the AISI publication. [^6]

**Approved-use scoping.** TAC approval comes with an explicit scope of permitted workflows. As of Q2 2026, the documented permitted categories include: vulnerability triage on internally-discovered or CVE-published vulnerabilities; patch authoring assistance for known CVEs affecting the team's own systems; malware reverse-engineering support for defensive analysis; and red-team validation where the target system is owned or contracted by the team. Exploit weaponization — producing working exploit code targeting external systems the team does not own — remains blocked regardless of TAC status. The GPT-5.5 system card documents these boundaries. [^3]

**Misuse monitoring.** TAC-tier access includes additional output-layer monitoring. OpenAI does not publish the exact technical implementation, but the program's terms require teams to report outputs they believe fall outside the permitted scope and to cooperate with audit requests. This is a behavioral obligation, not just an API configuration.

The AISI's pre-launch evaluation found that GPT-5.5 provides meaningful uplift to operators who already have existing security knowledge — junior security researchers with some CTF background and experienced red-teamers both showed acceleration. [^6] *Consistent with* that finding is a risk-calibrated interpretation of TAC's eligibility design: a team with no prior vulnerability research experience is less positioned to translate the model's vulnerability synthesis into actionable exploit steps, while a team with demonstrated security knowledge is precisely the population where misuse risk — and therefore monitoring obligations — creates the most value. Whether the AISI finding directly shaped OpenAI's eligibility criteria is not documented in the AISI publication; the causal link is this author's inference. What the AISI evaluation establishes independently is the empirical basis for why uplift-risk correlates with existing attacker knowledge — which is the premise any eligibility gate of this kind would need to be defensible.

<Callout type="info">
**TAC is not a capability upgrade.** The GPT-5.5-Cyber model is the same model; what changes is the output policy layer applied to requests from verified teams. Outputs that would be blocked or truncated for a standard API customer in specific cyber-adjacent categories are instead routed to a monitored approval path or allowed with logging for TAC-verified teams. The capability ceiling is identical; the policy envelope differs.
</Callout>

---

```takeaways
- TAC has three independent components: team eligibility verification, approved-use workflow scoping, and ongoing misuse monitoring obligations.
- The permitted use-case list is explicit in the GPT-5.5 system card: vulnerability triage, patch authoring on your own systems, malware reverse-engineering (defensive), red-team validation of systems you own.
- Exploit weaponization for external systems remains blocked for all access tiers, including TAC.
```

## GPT-5.5-Cyber in Codex: what expands and what stays restricted

When OpenAI included Codex under the Trusted Access for Cyber umbrella, it created a specific workflow path: a TAC-verified team can use Codex's agentic coding surface against security-adjacent tasks with the relaxed output policy applied to their verified-team API calls. [^2] This is meaningful because Codex's tool-use surface — file access, code execution, web fetch — is exactly the surface that security automation requires. A vulnerability-triage workflow that reads a CVE description, pulls the affected package source, analyzes the diff, and drafts a patch requires multi-step tool use that a chat-completion endpoint alone cannot provide.

What the Codex TAC expansion does not change: the tool approval architecture. Codex's tool-use controls — which tools are in scope for a given deployment, what sandboxing is applied, how outputs are logged — are a separate layer from the TAC eligibility status. A TAC-verified organization that deploys Codex with file-system write access and no output logging has satisfied the model-access eligibility requirement while creating an uncontrolled endpoint governance situation. These are different risks.

The configuration that most security teams should target for a Codex-based vulnerability-triage workflow looks like this:

```yaml
# codex-security-workflow.yaml — reference governance config
access_tier: trusted_access_for_cyber
model: gpt-5.5-cyber
approved_use_scope:
  - vulnerability_triage
  - patch_authoring
  - malware_reverse_engineering_defensive

tool_allowlist:
  - file_read           # read source files, CVE descriptions, advisories
  - code_execution      # run analysis scripts in sandboxed container
  - web_fetch           # pull NVD entries, vendor advisories (allow-listed domains)
  # file_write: EXCLUDED — patches are reviewed by human before commit
  # shell: EXCLUDED — full shell access not required for triage workflow

sandbox:
  network: restricted    # only allow-listed domains
  filesystem: read_only  # no writes from agent; human commits patch
  execution_timeout: 60s

logging:
  output_capture: full
  flagged_output_review: human_within_4h
  retention: 90_days     # match SOC retention policy

escalation:
  misuse_signal: page_security_lead_immediately
  borderline_output: flag_and_hold_pending_human_review
```

This is a governance-first configuration, not a capability-first one. The tool-allowlist excludes `file_write` and `shell` deliberately — not because the model cannot use them, but because an audit-grade workflow requires human review before any patch lands in source control. The sandbox network restriction to allow-listed domains prevents the agent from fetching arbitrary external content during analysis. These controls exist in addition to the TAC eligibility layer, not as a substitute for it.

<KnowledgeCheck
  question="A team with TAC verification deploys Codex with full shell access and no output logging to accelerate vulnerability triage. Which governance layer have they addressed and which have they left uncontrolled?"
  options={[
    "Model access eligibility is addressed; endpoint governance and agent/tool controls are uncontrolled",
    "Endpoint governance is addressed; model access eligibility and tool controls are uncontrolled",
    "Agent/tool controls are addressed; model access eligibility is the remaining gap",
    "All three layers are addressed — TAC verification covers the full governance stack"
  ]}
  correctIdx={0}
  explanation="TAC verification addresses model access eligibility — the team qualifies for the relaxed output policy. Full shell access with no logging is an agent/tool control failure. Endpoint governance (OpenAI-direct vs. Enterprise vs. Bedrock) is a separate question the example doesn't address. TAC eligibility does not imply endpoint controls or tool-scope controls."
/>

## Anthropic's Project Glasswing and the Cyber Verification Program

Anthropic's parallel structure is [Project Glasswing](https://www.anthropic.com/glasswing) — the organizational unit responsible for Anthropic's work on cybersecurity capability research and the access controls that govern Claude Mythos Preview. [^4] Where OpenAI's TAC is framed primarily as a deployment program (how verified teams access GPT-5.5-Cyber), Glasswing is framed as a research-and-governance program: it simultaneously researches Claude's offensive cyber capabilities, develops defenses and mitigations, and governs which external teams get access to the Mythos Preview under what conditions.

Anthropic has announced a forthcoming Cyber Verification Program as part of Glasswing; as of Q2 2026, access is limited to approximately 50 invited organizational partners — including Cloudflare, Microsoft, and Oracle. [^4][^5] There is no open application process for the CVP. Glasswing-participating teams are expected to share findings about model behavior and misuse signals back to Anthropic, making the relationship bidirectional in a way that TAC's commercial terms do not obviously require.

The Mythos Preview, which drew significant federal attention in April 2026, is the specific Claude model surface available under Glasswing verification. The [AISI evaluation of GPT-5.5's cyber capabilities](https://www.aisi.gov.uk/blog/our-evaluation-of-openais-gpt-5-5-cyber-capabilities) implicitly places Mythos and GPT-5.5-Cyber at comparable capability levels — both provide meaningful uplift to operators with existing security knowledge. [^6] The governance structures that gate access to each model are the differentiator, not the raw capability ceiling.

One operational difference that matters for compliance teams: based on Anthropic's announced model for the forthcoming CVP, the program does not publish a fixed permitted-use taxonomy in the same way the GPT-5.5 system card does. [^3] The Glasswing initial update describes an approach where use-case scope would be documented per approved team rather than drawn from a published list. This model creates more flexibility for novel or research-adjacent workflows — a team analyzing an emerging threat actor's toolchain may not fit any pre-defined category cleanly, and Glasswing's described approach accommodates scope discussion. The cost is that scope boundaries are less legible to auditors who are not party to the individual verification agreement. For organizations that need to demonstrate compliance to a third-party auditor — a SOC 2 Type II audit, a FedRAMP authorization, or an internal governance board — a fixed, published permitted-use list from the GPT-5.5 system card is easier to reference than a bespoke agreement. Neither approach is objectively superior; the choice depends on whether your compliance environment rewards specificity or flexibility.

Glasswing also operates with an explicit assumption that the capability landscape will evolve. The initial update notes that permitted-use categories and monitoring requirements will be updated as Anthropic's internal research on Mythos's offensive capability ceiling develops. [^5] This means the governance agreement a team signs today is not static — Anthropic may tighten or loosen restrictions as the empirical picture changes. TAC terms are similarly subject to update, but the system card model creates a version-referenced baseline that auditors and regulators can pin to.

<Callout type="warn">
**Glasswing verification is not transferable to TAC, and vice versa.** A team with TAC approval can use GPT-5.5-Cyber and Codex under OpenAI's approved-use scope. They do not automatically qualify for Glasswing/Mythos access, and their TAC approval does not substitute for Anthropic's separate verification process — which as of Q2 2026 has no open application pathway (current access = ~50 invited partners). The governance frameworks are independently maintained by competing organizations and are not cross-recognized.
</Callout>

---

```takeaways
- Project Glasswing is Anthropic's research-and-governance unit for cyber capabilities — it governs Mythos Preview access through the Cyber Verification Program, and participating teams have reciprocal research-sharing obligations.
- Mythos Preview and GPT-5.5-Cyber sit at comparable capability levels per AISI's evaluation — the governance model, not raw capability, is the differentiator.
- TAC verification and Glasswing verification are not cross-recognized; teams wanting both access paths must apply to each separately.
```

## Side-by-side: TAC vs. Glasswing

| Dimension | OpenAI TAC (GPT-5.5-Cyber) | Anthropic Glasswing (Mythos Preview) |
|---|---|---|
| Program framing | Commercial deployment program | Research-and-governance unit |
| Eligibility | Organizational attestation + team vetting | Research-collaborative relationship with Anthropic |
| Permitted scope | Explicit list in system card [^3] | Documented per approved use case at verification |
| Reciprocal obligations | Misuse reporting + audit cooperation | Research finding sharing + misuse reporting |
| Codex/agent surface | Yes — Codex included in TAC [^2] | Claude tool-use under approved scope |
| Bedrock availability | Yes — GPT-5.5 on Bedrock [^7] | Anthropic direct / Bedrock Anthropic models |
| AISI evaluation | Published [^6] | Referenced but Mythos-specific publication pending |
| Cross-recognition | Not cross-recognized | Not cross-recognized |

The structural difference that matters most for a security team choosing between the two: TAC is a deployment-tier program where eligibility is confirmed once and the commercial relationship then operates within documented permitted-use boundaries. Glasswing is a research-collaborative program where the relationship is expected to evolve as Claude's capabilities and Anthropic's understanding of the risk surface develop. Teams with stable, well-defined triage workflows that fit the TAC permitted-use list will likely find the TAC path more operationally predictable. Teams with novel research-adjacent workflows — new malware families, emerging vulnerability classes, experimental defensive tooling — may find the Glasswing relationship more appropriate because it creates a channel for scope discussion rather than requiring the workflow to fit a fixed list.

<KnowledgeCheck
  question="A defensive security team wants to use an AI model to reverse-engineer a novel ransomware variant not yet covered by existing CVEs. Which access path is structurally better suited to this workflow and why?"
  options={[
    "TAC, because the permitted-use list explicitly includes malware reverse-engineering",
    "Glasswing, because novel research workflows benefit from the reciprocal scope-discussion channel rather than a fixed permitted-use list",
    "Either path equally — both are approved for any defensive security workflow",
    "Neither path — novel malware reverse-engineering requires AISI pre-approval before any model can be used"
  ]}
  correctIdx={1}
  explanation="TAC's permitted-use list does include malware reverse-engineering for defensive analysis, but it is a fixed list applied to known workflow categories. A novel ransomware variant may generate outputs that push against the policy boundary in ways that fit the defensive intent but not the documented category. Glasswing's research-collaborative structure creates a channel to discuss boundary cases and update scope — better suited for evolving, novel research. Option C is wrong: neither program approves arbitrary defensive workflows. Option D is fabricated — AISI conducts pre-launch capability evaluations of frontier models, not per-use-case approvals for individual teams."
/>

## Deployment paths: OpenAI-direct, Enterprise, and Amazon Bedrock

TAC eligibility addresses model access. Endpoint governance — which API surface you call and what platform-level controls wrap it — is a separate decision with material implications for compliance, data residency, and audit. As of Q2 2026, TAC-verified organizations calling GPT-5.5-Cyber have three primary endpoint paths:

**OpenAI-direct (API platform).** The standard API path. Controls include: API key management, usage limits, and OpenAI's platform-level logging. Data residency is OpenAI's infrastructure. Compliance certifications (SOC 2 Type II, ISO 27001) apply to the platform broadly. Audit trail is OpenAI's usage logs plus any application-layer logging you implement. This is the fastest path to get a TAC-verified workflow running but offers the least organizational control over the data path.

**OpenAI Enterprise.** Enterprise agreements add: dedicated infrastructure, negotiated data processing terms, admin-level usage controls, and direct account management for compliance discussions. Enterprise contracts can specify data retention, deletion, and usage-for-training opt-outs. For security teams in regulated industries (HIPAA, FedRAMP-adjacent), Enterprise is often the minimum viable path — not because the model differs, but because the contractual and infrastructure controls satisfy requirements that the standard API platform cannot.

**OpenAI models on Amazon Bedrock.** AWS made GPT-5.5 available on Bedrock as of Q2 2026. [^7][^8] Bedrock delivery adds:

```hcl
# Example: IAM policy restricting GPT-5.5 Bedrock invocations
# to a specific security-team role in a specific region
resource "aws_iam_policy" "gpt55_cyber_invoke" {
  name        = "gpt55-cyber-invoke-tac-team"
  description = "Restrict GPT-5.5 Bedrock invocations to TAC security team role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "arn:aws:bedrock:us-east-1::foundation-model/openai.gpt-5-5-cyber"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/team" = "security-tac-verified"
          }
        }
      }
    ]
  })
}
```

AWS-side controls that Bedrock adds on top of OpenAI's platform controls:
- **IAM role-based access**: only specific IAM principals can invoke the GPT-5.5 Bedrock endpoint — enforce at the AWS control plane, not just the application layer
- **VPC endpoints**: keep traffic off the public internet entirely, required for many FedRAMP and DoD IL2/IL4 environments
- **CloudTrail logging**: every Bedrock InvokeModel call is logged in CloudTrail, giving you AWS-native audit trails that integrate with your existing SIEM
- **Regional data residency**: GPT-5.5 on Bedrock can be constrained to specific AWS regions, satisfying data-residency requirements that OpenAI-direct cannot

The trade-off: Bedrock adds latency (a hop through AWS infrastructure), requires AWS-specific IAM configuration overhead, and may not have the same model-version rollout cadence as OpenAI-direct. For security teams already deep in the AWS ecosystem with existing CloudTrail/SIEM infrastructure, the Bedrock path is typically worth the overhead. For teams outside AWS, it adds friction without adding proportionate benefit.

<Callout type="hot">
**Bedrock delivery does not bypass TAC eligibility.** A team that is not TAC-verified calling GPT-5.5-Cyber through Bedrock still runs the standard GPT-5.5 output policy — not the TAC-relaxed policy. AWS-side controls (IAM, VPC, CloudTrail) are endpoint governance, not model access eligibility. The TAC verification happens at the OpenAI application layer and applies regardless of which deployment path delivers the API call. This is the most common misconception teams make when evaluating Bedrock as a compliance shortcut.
</Callout>

---

```takeaways
- Three endpoint paths for TAC-verified GPT-5.5-Cyber: OpenAI-direct (fastest, least platform control), Enterprise (contractual controls for regulated industries), Bedrock (AWS IAM/VPC/CloudTrail/region for AWS-native compliance stacks).
- Bedrock adds endpoint governance — IAM access control, CloudTrail audit, regional residency — but does not substitute for TAC eligibility at the OpenAI application layer.
- For FedRAMP-adjacent or DoD environments, Bedrock + VPC endpoints is frequently the minimum viable path; Enterprise contracts are an additional layer, not an alternative.
```

## Writing your governance case study

The hands-on exercise for this chapter asks you to produce a governance case study for one of four scenarios. Before you write it, here is the schema that distinguishes a defensible case study from a policy-shaped prose paragraph:

```markdown
# Governance Case Study: [Scenario Name]

## Scenario
One paragraph: what the team is trying to accomplish, what the target system is, and
what the risk surface is if the AI workflow produces a harmful output.

## Eligibility signals
- Team credential: [e.g., CISA-verified critical-infrastructure defender]
- Organizational backing: [e.g., Fortune 500 financial institution with SOC 2 Type II]
- Existing expertise signal: [e.g., 5-member red-team with CVE credits, lead holds OSCP]
- Use-case category: [which TAC or Glasswing permitted category this maps to]

## Access path
- Model: [GPT-5.5-Cyber via TAC | Claude Mythos via Glasswing]
- Endpoint: [OpenAI-direct | Enterprise | Bedrock | Anthropic-direct]
- Rationale: [one sentence on why this endpoint path for this compliance context]

## Permitted workflows
- [Specific task type 1, with scope constraint]
- [Specific task type 2, with scope constraint]

## Blocked workflows
- [Task that is excluded from scope and why]
- [Task that is excluded even though it looks adjacent]

## Tool controls
- Allowed tools: [list]
- Excluded tools: [list + rationale]
- Sandbox: [network restriction, filesystem access level, execution timeout]

## Logging and retention
- Output capture: [full | summary | flagged-only]
- Flagged output review: [human, within X hours]
- Retention: [X days, matched to SOC/compliance requirement]

## Escalation
- Borderline output: [hold + human review within X hours]
- Clear misuse signal: [page security lead immediately + suspend session]
- Program reporting: [report to OpenAI TAC / Anthropic Glasswing within X hours]
```

Three things to notice about this template:

1. **Permitted and blocked workflows are listed together.** Security teams that only document what they are allowed to do, without documenting what they are explicitly blocking, create policy gaps that misuse hides in. A governance case study that says "allowed: vulnerability triage" but does not say "blocked: exploit code targeting external systems the team does not own" has not provided meaningful scope control.

2. **Tool controls are independent of model access.** A case study that specifies the TAC access tier but leaves tool controls blank has answered the eligibility question and left the deployment question open. Both must be present.

3. **Escalation paths have time SLAs.** "Human review" is not an escalation path — it is a category. "Flag and hold pending human review within 4 hours, with page to security lead if hold exceeds threshold" is an escalation path. The distinction matters when an auditor reviews the policy.

## Hands-on exercise

**Write a governance case study** for one of the following four scenarios:

1. **Critical-infrastructure vulnerability triage**: A power utility's internal security team wants to use an AI coding assistant to accelerate CVE triage on their SCADA control software. They are CISA-registered critical-infrastructure defenders.

2. **Open-source supply-chain patch review**: A financial institution's AppSec team needs to analyze suspicious commits in open-source dependencies before pulling updates. They suspect an active supply-chain insertion campaign.

3. **Malware reverse-engineering support**: A threat intelligence team is analyzing a novel ransomware variant targeting healthcare infrastructure. No CVE exists yet; they are doing primary analysis.

4. **Internal red-team validation**: A large technology company's red team wants to use an AI model to accelerate coverage of their own production API surface during a scheduled red-team engagement.

**Using the schema above, fill in all sections:**
- Eligibility signals (include at least 3 concrete signals, not generic placeholders)
- Access path with rationale (choose between TAC/Glasswing and endpoint type — justify the choice)
- Permitted workflows (at least 2 specific tasks with scope constraints)
- Blocked workflows (at least 2 — one obvious, one adjacent-but-excluded)
- Tool controls (complete tool allowlist and exclusion rationale)
- Logging and retention (specific SLAs)
- Escalation (time-bounded paths for borderline and clear-misuse signals)

**Success criteria:**
- All sections are filled in with specific, concrete entries — no placeholders
- Permitted and blocked workflows are listed together, not in isolation
- Tool controls are independent of the model access tier specification
- Escalation paths include time SLAs
- The case study distinguishes between model access eligibility (TAC or Glasswing), endpoint governance (which deployment path), and agent/tool controls — at minimum as separate sections, ideally cross-referenced

**Estimated time**: 30–45 minutes. This deliverable is also the core of the capstone project governance section — saving it in your course notes means you can import it directly into the model-selection memo.

---

```takeaways
- A governance case study is not complete without both permitted and blocked workflows — gaps are where misuse hides.
- Tool controls must be specified independently of model access tier — TAC eligibility does not imply tool scope or sandbox controls.
- Escalation paths require time SLAs; "human review" without a time bound is not a functioning escalation path.
```

The next chapter applies the full set of evaluation dimensions — determinism, long-context behavior, cost-per-task, and governance — to the capstone project: a defensible model-selection memo for your specific production use case. See [[courses/picking-a-frontier-model-2026-q2/capstone-model-selection-memo]].

---

## References

[^1]: OpenAI. "Trusted Access for Cyber." https://openai.com/index/trusted-access-for-cyber/

[^2]: OpenAI. "GPT-5.5 with Trusted Access for Cyber." https://openai.com/index/gpt-5-5-with-trusted-access-for-cyber/ — May 7, 2026 announcement of GPT-5.5-Cyber limited preview and Codex inclusion under TAC.

[^3]: OpenAI. "GPT-5.5 System Card." https://deploymentsafety.openai.com/gpt-5-5/gpt-5-5.pdf — documents the specific use-case categories that shift from blocked to monitored-with-approval for TAC-verified teams.

[^4]: Anthropic. "Project Glasswing." https://www.anthropic.com/glasswing — Anthropic's cybersecurity capability research and governance unit; home of the Cyber Verification Program governing Mythos Preview access.

[^5]: Anthropic. "Glasswing Initial Update." https://www.anthropic.com/research/glasswing-initial-update — documents scope of Mythos Preview access and review obligations for participating teams.

[^6]: AISI. "Our evaluation of OpenAI's GPT-5.5 cyber capabilities." https://www.aisi.gov.uk/blog/our-evaluation-of-openais-gpt-5-5-cyber-capabilities — UK AI Safety Institute pre-launch evaluation establishing the empirical basis for TAC eligibility design; finding that uplift scales with attacker existing knowledge.

[^7]: Amazon Web Services. "OpenAI models on Amazon Bedrock." https://aws.amazon.com/bedrock/openai/ — GPT-5.5 delivery via Bedrock with AWS-native IAM, VPC, CloudTrail, and regional controls.

[^8]: Amazon Web Services. "OpenAI model cards — Amazon Bedrock." https://docs.aws.amazon.com/bedrock/latest/userguide/model-cards-openai.html — model card documentation for OpenAI models on Bedrock.

[^9]: CNBC. "OpenAI rolls out new GPT-5.5 Cyber to vetted cybersecurity teams." https://www.cnbc.com/2026/05/07/openai-rolls-out-new-gpt-5point5-cyber-to-vetted-cybersecurity-teams.html — third-party coverage of the May 7, 2026 TAC launch.

---

*Related chapters in this course: [[courses/picking-a-frontier-model-2026-q2/01-dimensions-that-matter]] | [[courses/picking-a-frontier-model-2026-q2/02-tool-use-determinism-benchmark]] | [[courses/picking-a-frontier-model-2026-q2/04-cost-per-task]]*

*Related blogs: [[blogs/sub-hour-zero-days-aisi-mythos-autonomous-cyber-developers]] | [[blogs/gpt-5-5-in-codex]]*
