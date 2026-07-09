---
date: 2026-07-08
author: koenig-ai-academy
ticket: KOEA-9613
vendor_tag: microsoft
content_type: explainer
title: "Guide to Pass AZ-104: Microsoft Certified Azure Administrator Exam"
slug: guide-to-pass-az-104-microsoft-certified-azure-administrator-exam
tags:
  - azure
  - az-104
  - microsoft-certification
  - cloud-computing
learning_objectives:
  - Map the five AZ-104 exam domain areas and their weighting
  - Understand what skills are measured in each domain before you study
  - Build an exam-prep sequence that targets the highest-weighted domains first
whats_new:
  - AZ-104 domain map table showing all five skill areas with topic coverage and current weights
description: "A complete guide to passing AZ-104 Microsoft Certified Azure Administrator — exam domain map with weights, an 8-week study sequence, common failure points, and exam logistics from the official skills outline."
seo_description: "Pass AZ-104 with the updated 5-domain map (April 2026), an 8-week sequence ordered by weight, common failure points, and key CLI commands."
faq:
  - question: "What are the five exam domains for AZ-104 and which carries the most weight?"
    answer: "The five AZ-104 domains are: Manage Azure Identities and Governance (20–25%), Implement and Manage Storage (15–20%), Deploy and Manage Azure Compute Resources (20–25%), Implement and Manage Virtual Networking (15–20%), and Monitor and Maintain Azure Resources (10–15%). Identity and compute are tied for the highest weight at 20–25%, as confirmed by the official Microsoft study guide [2]. Always verify current weights before booking — Microsoft updates exam content periodically."
  - question: "What hands-on experience do I need before taking AZ-104?"
    answer: "Microsoft recommends at least 6 months of Azure hands-on experience before taking AZ-104. This means practical work with Azure Virtual Machines [4], virtual networking including VNets and NSGs, storage accounts with different redundancy options [5], and Microsoft Entra ID (formerly Azure Active Directory). You should be comfortable with the Azure Portal, Azure CLI, and PowerShell. If you are new to Azure, start with AZ-900 Azure Fundamentals first and verify the current recommended experience on the official AZ-104 exam overview page [1]."
  - question: "What is the passing score for AZ-104 and how many questions does it have?"
    answer: "AZ-104 requires a passing score of 700 out of 1000 points, as confirmed by the Microsoft credentials page [1]. The exam typically includes 40–60 questions (Microsoft varies the count per session) across multiple-choice, multiple-select, drag-and-drop, and case study formats. Duration is 100 minutes. Case studies appear at the end of the exam and cannot be revisited once exited. Questions are drawn from all five exam domain areas with weighting proportional to the percentages in the official study guide [2]."
positions:
  - id: audit-trail-as-enterprise-gate
    engagement: defends
  - id: cli-first-workflows-for-production-teams
    engagement: defends
first_60_words_answer: "The AZ-104 is Microsoft's benchmark certification for Azure Administrators — the engineers who manage subscriptions, configure virtual machines, handle networking, and keep Azure environments running. It tests breadth over depth: you need to know five distinct skill domains rather than one technology in detail. This guide covers the exam domain map, the skills that matter most by weight, and a study sequence that gets you to passing faster."
last_updated: 2026-07-09
hero_image:
  url: /img/blogs/guide-to-pass-az-104-microsoft-certified-azure-administrator-exam/hero.png
  alt: "AZ-104 exam domain map showing five skill areas with percentage weights from identities and governance to compute, networking, storage, and monitoring"
status: g0-passed
reading_time_min: 7
sources:
  - "https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/"
  - "https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104"
  - "https://learn.microsoft.com/en-us/azure/role-based-access-control/overview"
  - "https://learn.microsoft.com/en-us/azure/virtual-machines/overview"
  - "https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy"
  - "https://learn.microsoft.com/en-us/azure/networking/fundamentals/networking-overview"
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
  - n: 4
    title: "Microsoft — Azure Virtual Machines Overview"
    url: "https://learn.microsoft.com/en-us/azure/virtual-machines/overview"
    retrieved: 2026-07-09
  - n: 5
    title: "Microsoft — Azure Storage Redundancy"
    url: "https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy"
    retrieved: 2026-07-09
  - n: 6
    title: "Microsoft — Azure Networking Fundamentals"
    url: "https://learn.microsoft.com/en-us/azure/networking/fundamentals/networking-overview"
    retrieved: 2026-07-09
---

# Guide to Pass AZ-104: Microsoft Certified Azure Administrator Exam

The AZ-104 is Microsoft's benchmark certification for Azure Administrators — the engineers who manage subscriptions, configure virtual machines, handle networking, and keep Azure environments running. It tests breadth over depth: you need to know five distinct skill domains rather than one technology in detail.

This guide covers the exam domain map, the skills that matter most by weight, and a study sequence that gets you to passing faster.

## Who Should Take AZ-104?

AZ-104 suits engineers who:
- Manage Azure resources day-to-day (VMs, storage, networking, access)
- Have 6+ months of Azure hands-on experience
- Want to formalise their Azure skills with a widely recognised credential
- Are pursuing Azure Solutions Architect Expert (AZ-305 requires AZ-104 first)

It is not a beginner exam. If you are new to Azure, start with AZ-900 (Azure Fundamentals) first.

## AZ-104 Exam Domain Map

The exam measures five skill areas. The table below shows each domain, its current weight, and the core topics you must know.

| Domain | Weight | Core Topics |
|---|---|---|
| **Manage Azure Identities and Governance** | 20–25% | Microsoft Entra ID (Azure AD), users, groups, RBAC roles [3], subscriptions, management groups, policies, resource locks, cost management |
| **Implement and Manage Storage** | 15–20% | Storage accounts, blob/file/queue/table, redundancy options (LRS/ZRS/GRS) [5], access keys vs SAS tokens, Azure Files, Azure File Sync, import/export |
| **Deploy and Manage Azure Compute Resources** | 20–25% | VMs (size, availability sets, scale sets) [4], Azure App Service, Azure Container Instances, ARM templates, Bicep, VM extensions, OS disk encryption |
| **Implement and Manage Virtual Networking** | 15–20% | VNets, subnets, NSGs, ASGs, peering, VPN Gateway, ExpressRoute basics, Azure DNS, load balancers, Application Gateway, Azure Bastion [6] |
| **Monitor and Maintain Azure Resources** | 10–15% | Azure Monitor, Log Analytics, alerts, diagnostic settings, Azure Backup, Recovery Services vault, Azure Site Recovery, Update Manager |

*Table 1 — AZ-104 exam domain map. Weights are approximate and sourced from the official Microsoft skills outline [1][2]. Domains update periodically — always verify against the live study guide before your exam date.*

**Highest-weight domains: Manage Azure Identities and Governance and Deploy and Manage Azure Compute Resources (both 20–25%).** Treat identity and compute as co-equal anchors: one tests how access and governance shape every Azure environment, the other tests whether you can deploy and operate the resources those policies protect. Know RBAC, policy inheritance, VM creation, resizing, availability options, and Bicep/ARM deployment cold.

<KnowledgeCheck
  question="Which AZ-104 exam domain carries the highest weight and what should you study first?"
  options={[
    "Manage Azure Identities and Governance (20–25%) — study RBAC and policies first",
    "Deploy and Manage Azure Compute Resources (20–25%) — study VMs, scale sets, and Bicep/ARM first",
    "Implement and Manage Virtual Networking (15–20%) — study VNets and NSGs first",
    "Monitor and Maintain Azure Resources (10–15%) — study Azure Backup first"
  ]}
  correctIndex={1}
  explanation="Manage Azure Identities and Governance and Deploy and Manage Azure Compute Resources are tied at the highest weight: 20–25% each. A practical study sequence can start with compute because VMs, scale sets, and Bicep/ARM deployments are easy to rehearse hands-on, but identity and governance deserve equal review time."
/>

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

Use Microsoft Learn as the spine for each phase, not as the only preparation source. The official study guide links directly to self-paced learning paths, documentation, the practice assessment, and Exam Readiness Zone videos [1][2]. A good rule: read the Learn module, perform the task in a real Azure subscription, then repeat it from CLI or PowerShell without copying the instructions. The exam rewards recall under time pressure, so passive reading has a low ceiling.

## What the Exam Actually Looks Like

- **Questions**: ~40–60 questions (Microsoft varies the count)
- **Format**: multiple choice, multiple select, drag-and-drop, case studies
- **Duration**: 100 minutes
- **Passing score**: 700 out of 1000
- **Language**: English and 10+ other languages

Case studies appear at the end and cannot be revisited once you leave them. Treat them like a separate mini-exam: scan the requirements, identify the subscription, region, identity, and network constraints, then answer only from the facts in the scenario. Do not burn time trying to perfect earlier multiple-choice questions if you still have a case study ahead; Microsoft says interactive components may appear as part of the assessment [1], and those items are where time pressure feels sharpest.

## Common Failure Points

1. **Confusing NSG and ASG rules.** NSG rules are stateful and apply at subnet or NIC level. ASGs let you group VMs by role for cleaner NSG rules. Know which controls traffic.

2. **Missing the difference between LRS, ZRS, and GRS.** ZRS replicates across availability zones in one region. GRS replicates to a secondary region. LRS keeps three copies in one datacenter. [5]

3. **Underestimating policy and governance questions.** Policy compliance evaluation, built-in definitions, and remediation tasks appear more than candidates expect.

4. **Not practising the CLI.** The exam includes CLI and PowerShell command questions. Know `az vm create`, `az network vnet create`, and `az group lock create` at minimum.

<KnowledgeCheck
  question="What is the passing score threshold for AZ-104, and what should you do if you score below 70% in a domain during practice tests?"
  options={[
    "Passing score is 700/1000; below 70% domain score means reschedule the entire exam",
    "Passing score is 700/1000; below 70% in any domain gets a targeted review week before the real exam",
    "Passing score is 800/1000; any domain below 80% requires a course retake",
    "Passing score is 650/1000; practice test scores don't predict real exam performance"
  ]}
  correctIndex={1}
  explanation="AZ-104 requires 700 out of 1000 points to pass. In the recommended study sequence, after completing three full timed practice exams, any domain scoring below 70% should receive a dedicated review week before the real exam. This targeted remediation is more efficient than generically reviewing all domains again."
/>

<Callout type="info">
Microsoft updates AZ-104 exam content roughly every 12–18 months. The weights above reflect the study guide as of mid-2026. Always download the current skills outline PDF from the Microsoft credentials page [1] before booking your exam.
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
