---
title: "How Anthropic's Claude Mythos Preview Is Finding Critical Vulnerabilities in Power Grids, Hospitals, and Water Systems"
slug: 2026-06-02-project-glasswing-claude-mythos-critical-infra
date: 2026-06-02
last_updated: 2026-06-03
tags: [anthropic, security, vulnerability-scanning, critical-infrastructure, ai-safety, claude-mythos]
status: awaiting-g0
g0_pass: false
description: "Anthropic's Project Glasswing expansion brings Claude Mythos Preview to power grids, hospital networks, and water systems — how AI-assisted scanning found over 10,000 critical vulnerabilities defenders had missed."
first_60_words_answer: "Over 10,000 high or critical-severity security flaws. Found not by red teams or months-long pen-test engagements — but by an AI model working through codebases at a scale no human team could sustain. That's the headline number from Anthropic's June 2 expansion of Project Glasswing, and it's the kind of figure that makes you stop and recalibrate what AI-assisted security actually means in 2026."
positions:
  - ai-security-defender-advantage
faq:
  - q: "What is Project Glasswing?"
    a: "Project Glasswing is Anthropic's initiative to provide Claude Mythos Preview — a restricted-access, security-focused AI model — to operators of critical infrastructure including power grids, hospital networks, and water treatment facilities. Launched in April 2026, the program expanded in June to approximately 200 partner organizations across 15+ countries and 5 sectors, with the goal of AI-assisted vulnerability scanning in systems that affect more than 100 million people. ([Source: Anthropic](https://www.anthropic.com/news/expanding-project-glasswing), retrieved 2026-06-03)"
  - q: "What vulnerabilities has Claude Mythos Preview found in critical infrastructure?"
    a: "As of June 2026, Claude Mythos Preview has identified over 10,000 high or critical-severity security vulnerabilities across Glasswing's initial partner organizations — infrastructure operators running power grid management, hospital networks, water treatment systems, and communications backbones. These are findings that pattern-matching static analysis tools had missed, uncovered through deep semantic analysis of legacy C/C++ codebases and modern infrastructure software. ([Source: Anthropic](https://www.anthropic.com/news/expanding-project-glasswing), retrieved 2026-06-03)"
  - q: "How does Claude Mythos Preview differ from Claude Security?"
    a: "Claude Mythos Preview is a restricted-access, higher-capability security model available only to vetted Glasswing partners, while Claude Security is publicly available to all Anthropic API customers. Claude Security uses Claude Opus 4.8 and supports codebase scanning and patch suggestions; Claude Mythos Preview adds penetration testing support, threat detection automation, and legacy codebase migration capabilities tuned for security research depth rather than broad accessibility. ([Source: Anthropic](https://www.anthropic.com/news/expanding-project-glasswing), retrieved 2026-06-03)"
---

# How Anthropic's Claude Mythos Preview Is Finding Critical Vulnerabilities in Power Grids, Hospitals, and Water Systems

Over 10,000 high or critical-severity security flaws. Found not by red teams or months-long pen-test engagements — but by an AI model working through codebases at a scale no human team could sustain. That's the headline number from Anthropic's June 2 expansion of [Project Glasswing](https://www.anthropic.com/news/expanding-project-glasswing), and it's the kind of figure that makes you stop and recalibrate what AI-assisted security actually means in 2026.

## What Is Project Glasswing?

Project Glasswing launched in April 2026 as Anthropic's collaborative initiative to bring advanced AI security tooling to critical infrastructure operators and essential software maintainers — organizations whose code underpins systems that billions of people depend on.

The premise is simple but the stakes are enormous: the codebases running power grids, hospital networks, water treatment facilities, and communications backbones are often legacy systems with decades of accumulated technical debt, sparse documentation, and security postures that predate modern threat models. Conventional security tooling — static analysis, manual code review, periodic pen tests — can't keep pace with the attack surface.

Glasswing's approach: give partners access to **Claude Mythos Preview**, Anthropic's most capable security-focused model variant, and let it do what frontier AI does best at scale.

## Claude Mythos Preview: What It Actually Does

Claude Mythos Preview is not a SAST scanner wrapped in a chat interface. Its capability set is meaningfully broader:

- **Codebase vulnerability scanning** — deep semantic analysis across large codebases, identifying vulnerability classes that pattern-matching tools routinely miss
- **Patch writing and pre-release checks** — not just flagging issues but suggesting (and in some cases drafting) fixes, integrated into pre-release workflows
- **Penetration testing support and threat detection automation** — assisting red and blue teams with structured attack simulation and alert triage
- **Legacy codebase migration** — helping rebuild C/C++ and other memory-unsafe systems in memory-safe languages like Rust, addressing entire categories of memory corruption vulnerabilities at the source

This is a qualitatively different tool from the publicly available **[[claude-security-beta-devsecops|Claude Security]]** (which uses Claude Opus 4.8 and is available to all customers for codebase scanning and patch suggestions). Mythos Preview is a restricted-access, higher-capability model tuned specifically for security research depth.

## Three Sectors, One Shared Problem

The June 2 expansion adds approximately 150 new partner organizations across five newly covered sectors — power, water, healthcare, communications, and hardware — bringing the total to roughly 200 organizations across 15+ countries. But power, hospitals, and water deserve specific attention because they represent the hardest-to-patch, highest-consequence codebases in the portfolio.

**Power infrastructure** operators are running code that controls grid management, load balancing, and SCADA systems. Much of it is C-based, decades old, and deeply entangled with proprietary hardware. A single exploitable vulnerability in a grid management system could cascade into regional blackouts. Claude Mythos Preview's ability to reason about memory safety issues and control-flow vulnerabilities in legacy C/C++ codebases is directly applicable here.

**Hospital networks** face a different threat model: ransomware actors actively target healthcare systems because downtime is life-threatening and organizations are more likely to pay. The attack surface includes everything from scheduling and EHR systems to medical device firmware. Glasswing's pre-release vulnerability checking capability matters most in this context — catching issues before a new software version ships to production is far cheaper than containing a post-exploitation incident.

**Water treatment systems** are perhaps the most underappreciated risk in critical infrastructure security. The 2021 Oldsmar, Florida attack — where an attacker briefly increased sodium hydroxide levels in a water treatment plant via remote access — demonstrated how catastrophic a successful intrusion could be. These systems often run industrial control software with minimal patching cycles. Mythos Preview's penetration testing support capabilities give operators a way to continuously probe their attack surface without requiring specialized ICS security expertise.

Anthropic estimates that a major attack on most of its Glasswing partner systems could affect more than 100 million people, with significant national and global security implications. That scale is what justifies the restricted access model.

## The Defender Advantage Thesis

The strongest case for Project Glasswing is simply economic: attackers have asymmetric advantage by default. A nation-state actor or sophisticated criminal group needs to find one exploitable vulnerability. Defenders need to find — and patch — all of them.

AI-assisted vulnerability scanning changes that equation. If Claude Mythos Preview can scan a million-line codebase in hours rather than weeks, and surface critical issues with enough context for a developer to act on them immediately, defenders are no longer playing a losing game of whack-a-mole. The 10,000+ vulnerabilities already found by initial Glasswing partners represent bugs that, left undiscovered, would have remained exploitable.

The hybrid model the security community is converging on — pairing LLMs with established tooling like Semgrep and CodeQL — amplifies this advantage further. As one practitioner [noted in the HN discussion](https://news.ycombinator.com/item?id=47092277), "giving LLM security agents access to good tools makes them significantly better especially when it comes to false positives." The model doesn't replace the toolchain; it orchestrates it.

## The Attack-Surface Counterargument

It would be intellectually dishonest to stop at the defender-advantage framing.

**The false positive problem is real.** The same HN discussion that validated the hybrid approach also surfaced legitimate skepticism about the severity of claimed findings. Pattern-based security tools have always struggled with false positive rates, and the concern is that wrapping them in an LLM layer doesn't fully solve this — it may just make the false positives harder to distinguish from true positives because the reasoning sounds more authoritative.

**Capability proliferation is a genuine risk.** Claude Mythos Preview is currently restricted to vetted partners under Anthropic's oversight. But Anthropic has stated its goal is to eventually "expand Mythos-level capabilities to general access with robust safeguards." What those safeguards look like at scale, and whether they're sufficient to prevent offensive use, is not yet answered. The same capability that finds vulnerabilities in critical infrastructure can be used to find vulnerabilities *in* critical infrastructure — a trajectory explored further in [[2026-05-14-sub-hour-zero-days-aisi-mythos-autonomous-cyber-developers|the sub-hour zero-day research from AISI]].

**Deployment complexity is underestimated.** As one practitioner noted in the HN thread, code changes constantly, rescanning with thinking models is expensive, and integration into existing security workflows ("missing workflows") is harder in practice than in a research context. Organizations that adopt Glasswing tooling without the operational maturity to act on its output may end up with a long queue of unresolved findings rather than a genuinely improved security posture.

These aren't reasons to reject AI-assisted vulnerability research. They're reasons to implement it with eyes open.

## What Security Teams Should Do Now

Whether or not your organization qualifies for Glasswing access, this expansion has practical implications:

1. **Apply for Glasswing if you're in scope.** If you operate or maintain software used by critical infrastructure, Anthropic is actively expanding the partner base. The application bar is lower than it was in April.

2. **Don't wait for Mythos-level access.** Claude Security (public, Opus 4.8-based) is available today for codebase scanning and patch suggestions. Use it to build familiarity with AI-assisted security workflows before the more capable tooling becomes broadly available.

3. **Build the hybrid pipeline.** The practitioner consensus is clear: LLMs paired with Semgrep, CodeQL, or similar tools outperform either in isolation. If you're piloting AI security tooling, structure the workflow so the model is augmenting rule-based analysis, not replacing it. For a comprehensive treatment of securing the AI agents themselves in these pipelines, see [[ai-agent-security-for-developers]].

4. **Invest in triage capacity.** The biggest bottleneck in AI-assisted security is rarely finding vulnerabilities — it's having the engineering bandwidth to act on findings. A tool that discovers 10,000 issues is only as valuable as your ability to prioritize and patch them.

5. **Watch the false-positive rate in your context.** Benchmark AI scanner output against a subset of manually verified findings before letting it drive prioritization. The base rate for true critical vulnerabilities varies dramatically by codebase type, and miscalibrated trust in AI outputs can misallocate scarce security engineering time.

## What This Signals

Project Glasswing's expansion is one of the clearest signals yet that AI-assisted security is transitioning from research novelty to operational infrastructure. The 10,000+ vulnerability figure is a proof point that changes the conversation from "can AI help with security?" to "how do we deploy it responsibly at scale?"

The answer isn't to move fast and hope the safeguards hold. It's to move deliberately — building the operational muscle to absorb AI-generated findings, investing in the hybrid toolchains that minimize false positives, and maintaining honest assessment of the dual-use risk that comes with any powerful vulnerability-discovery capability.

Defenders have a genuine advantage here. The question is whether they'll build the processes to use it.

---

*Sources: [Anthropic — Expanding Project Glasswing](https://www.anthropic.com/news/expanding-project-glasswing) (June 2, 2026); [Hacker News discussion](https://news.ycombinator.com/item?id=47092277)*
