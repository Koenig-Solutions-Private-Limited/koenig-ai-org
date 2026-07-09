---
date: 2026-07-08
author: content-author
ticket: KOEA-9613
vendor_tag: microsoft
content_type: explainer
learning_objectives:
  - Map the six AZ-104 exam domain areas and their weighting
  - Understand what skills are measured in each domain before you study
  - Build an exam-prep sequence that targets the highest-weighted domains first
whats_new:
  - AZ-104 domain map table showing all six skill areas with topic coverage and current weights
status: awaiting-g0
reading_time_min: 7
seo_description: "A complete guide to passing AZ-104 Microsoft Azure Administrator — exam domain map, skill weights, study sequence, and practice tips from the official skills outline."
sources:
  - "https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/"
  - "https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104"
  - "https://learn.microsoft.com/en-us/azure/role-based-access-control/overview"
references:
  - n: 1
    title: "Microsoft — AZ-104 Exam Overview"
    url: "https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/"
    retrieved: 2026-07-08
  - n: 2
    title: "Microsoft — AZ-104 Study Guide"
    url: "https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104"
    retrieved: 2026-07-08
  - n: 3
    title: "Microsoft — Azure RBAC Overview"
    url: "https://learn.microsoft.com/en-us/azure/role-based-access-control/overview"
    retrieved: 2026-07-08
---

# Guide to Pass AZ-104: Microsoft Certified Azure Administrator Exam

The AZ-104 is Microsoft's benchmark certification for Azure Administrators — the engineers who manage subscriptions, configure virtual machines, handle networking, and keep Azure environments running. It tests breadth over depth: you need to know six distinct skill domains rather than one technology in detail.

This guide covers the exam domain map, the skills that matter most by weight, and a study sequence that gets you to passing faster.

## Who Should Take AZ-104?

AZ-104 suits engineers who:
- Manage Azure resources day-to-day (VMs, storage, networking, access)
- Have 6+ months of Azure hands-on experience
- Want to formalise their Azure skills with a widely recognised credential
- Are pursuing Azure Solutions Architect Expert (AZ-305 requires AZ-104 first)

It is not a beginner exam. If you are new to Azure, start with AZ-900 (Azure Fundamentals) first.

## AZ-104 Exam Domain Map

The exam measures six skill areas. The table below shows each domain, its current weight, and the core topics you must know.

| Domain | Weight | Core Topics |
|---|---|---|
| **Manage Azure Identities and Governance** | 15–20% | Microsoft Entra ID (Azure AD), users, groups, RBAC roles, subscriptions, management groups, policies, resource locks, cost management |
| **Implement and Manage Storage** | 15–20% | Storage accounts, blob/file/queue/table, redundancy options (LRS/ZRS/GRS), access keys vs SAS tokens, Azure Files, Azure File Sync, import/export |
| **Deploy and Manage Azure Compute Resources** | 20–25% | VMs (size, availability sets, scale sets), Azure App Service, Azure Container Instances, ARM templates, Bicep, VM extensions, OS disk encryption |
| **Implement and Manage Virtual Networking** | 15–20% | VNets, subnets, NSGs, ASGs, peering, VPN Gateway, ExpressRoute basics, Azure DNS, load balancers, Application Gateway, Azure Bastion |
| **Monitor and Maintain Azure Resources** | 10–15% | Azure Monitor, Log Analytics, alerts, diagnostic settings, Azure Backup, Recovery Services vault, Azure Site Recovery, Update Manager |
| **Manage and Configure Resources Using Azure Tools** | 5–10% | Azure Portal, CLI, PowerShell, Cloud Shell, Resource Graph, Resource Manager APIs |

*Table 1 — AZ-104 exam domain map. Weights are approximate and sourced from the official Microsoft skills outline [1][2]. Domains update periodically — always verify against the live study guide before your exam date.*

**Highest-weight domain: Deploy and Manage Azure Compute Resources (20–25%).** VMs and their management are the backbone of the exam. Know VM creation, resizing, availability options, and Bicep/ARM deployment cold.

## Study Sequence That Works

Study in weight order, not alphabetical order.

**Phase 1 — Compute (weeks 1–2)**
Spin up VMs, resize them, create a scale set, deploy via ARM template or Bicep, attach a data disk, enable encryption. Hands-on is mandatory. The portal hides complexity; use the CLI for everything.

**Phase 2 — Networking (weeks 3–4)**
Create a VNet with multiple subnets. Attach NSGs. Peer two VNets. Configure a basic VPN Gateway. Set up an Azure load balancer across two VMs. DNS zone creation. This domain has the most "gotcha" questions about traffic flow and NSG evaluation order.

**Phase 3 — Identity and Governance (week 5)**
Work through RBAC role assignments, custom roles, and policy definitions. Understand management group hierarchy and how policy inherits down. Cost Management and budgets appear occasionally.

**Phase 4 — Storage (week 6)**
Create storage accounts with different redundancy levels. Practice SAS token generation, lifecycle policies, and setting up Azure File Sync. Blob access tier changes (hot/cool/archive).

**Phase 5 — Monitor and Maintain (week 7)**
Configure Azure Backup for a VM. Set up Log Analytics with a workspace. Create an alert rule on CPU percentage. Practice Recovery Services vault and creating a backup policy.

**Phase 6 — Practice Tests (week 8)**
Take three full 60-question practice exams under timed conditions. Any domain below 70% gets a targeted review week before the real exam.

## What the Exam Actually Looks Like

- **Questions**: ~40–60 questions (Microsoft varies the count)
- **Format**: multiple choice, multiple select, drag-and-drop, case studies
- **Duration**: 120 minutes
- **Passing score**: 700 out of 1000
- **Language**: English and 10+ other languages

Case studies appear at the end and cannot be revisited once you leave them. Read each scenario twice before answering.

## Common Failure Points

1. **Confusing NSG and ASG rules.** NSG rules are stateful and apply at subnet or NIC level. ASGs let you group VMs by role for cleaner NSG rules. Know which controls traffic.

2. **Missing the difference between LRS, ZRS, and GRS.** ZRS replicates across availability zones in one region. GRS replicates to a secondary region. LRS keeps three copies in one datacenter.

3. **Underestimating policy and governance questions.** Policy compliance evaluation, built-in definitions, and remediation tasks appear more than candidates expect.

4. **Not practising the CLI.** The exam includes CLI and PowerShell command questions. Know `az vm create`, `az network vnet create`, and `az group lock create` at minimum.

<Callout type="info">
Microsoft updates AZ-104 exam content roughly every 12–18 months. The weights above reflect the study guide as of mid-2026. Always download the current skills outline PDF from the Microsoft credentials page before booking your exam.
</Callout>

## After AZ-104

AZ-104 is the required prerequisite for:
- **AZ-305 Azure Solutions Architect Expert** — the most sought-after Azure credential
- **AZ-500 Azure Security Engineer Associate** — security posture, identity, and threat protection
- **AZ-700 Azure Network Engineer Associate** — advanced networking (not formally required but assumes AZ-104 knowledge)

Pass AZ-104, then choose the track that matches your next career target: architecture (AZ-305), security (AZ-500), or networking (AZ-700).

## Learn More

- [Secure Coding With Claude](/learn/secure-coding-with-claude) — Claude-assisted code review and security pattern guidance applicable to Azure IaC and policy-as-code.
- [Claude Tool Use From Zero](/learn/claude-tool-use-from-zero) — Build agents that interact with Azure APIs using function calling.
