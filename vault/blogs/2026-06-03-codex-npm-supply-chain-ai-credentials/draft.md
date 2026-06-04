---
title: "Your AI Dev Credentials Are the New API Key — And You Are Not Protecting Them"
description: "The codexui-android npm package stole OpenAI Codex tokens from 29,000+ developers. Here's what was taken, how the attack worked, and what every AI tooling user needs to do right now."
slug: 2026-06-03-codex-npm-supply-chain-ai-credentials
date: 2026-06-04
last_updated: 2026-06-04
author: blog-author
ticket: KOEA-7312
vendor_tag: openai
content_type: article
status: g3-passed
reading_time_min: 8
tags: [supply-chain-attack, openai, codex, npm, security, developer-security, ai-credentials, token-theft, credential-hygiene]
primary_query: "OpenAI Codex token theft supply chain attack what to do"
first_60_words_answer: "A malicious npm package called codexui-android stole OpenAI Codex authentication tokens — access token, refresh token, ID token, and account ID — from the ~/.codex/auth.json file of 29,000+ weekly users. The refresh token does not expire, giving attackers persistent silent impersonation. If you installed codexui-android or used either of two related Android apps, revoke your Codex tokens immediately via OpenAI account management."
contrarian_angle: "The security community will frame this as a supply chain attack on npm. It is also a credential hygiene failure: AI developer tools are creating new classes of long-lived, high-value credential files, and the ecosystem has not caught up with how to protect them."
positions:
  - id: stance:ai-credential-files-underprotected
    engagement: defends
  - id: stance:supply-chain-due-diligence-npm
    engagement: implies
original_data: false
sources:
  - https://thehackernews.com/2026/06/openai-codex-authentication-tokens.html
  - https://www.csoonline.com/article/4179815/attack-targeting-openai-codex-users-exposes-ai-software-supply-chain-risks.html
  - https://hackread.com/codex-ui-tool-secretly-stole-openai-refresh-tokens
  - https://techcrunch.com/2026/06/02/openai-launches-new-codex-tools-for-white-collar-work/
  - https://thehackernews.com/2026/05/trapdoor-supply-chain-attack-spreads.html
  - https://www.csoonline.com/article/4177019/trapdoor-malware-campaign-puts-developer-workstations-in-ciso-spotlight.html
  - https://www.csoonline.com/article/4179866/infected-red-hat-npm-packages-expose-developer-credentials.html
  - https://www.csoonline.com/article/4168493/your-ctem-program-is-probably-ignoring-mcp-heres-how-to-fix-it.html
  - https://arstechnica.com/information-technology/2026/05/millions-of-ai-agents-imperiled-by-critical-vulnerability-in-open-source-package/
  - https://mondoo.com/blog/npm-supply-chain-security-package-manager-defenses-2026
  - https://www.stepsecurity.io/blog/mini-shai-hulud-is-back-a-self-spreading-supply-chain-attack-hits-the-npm-ecosystem
whats_new:
  - "Aikido Security disclosed on June 1, 2026 that codexui-android (29,000+ weekly npm downloads) exfiltrates Codex credentials to attacker-controlled server [1]."
  - "Two Android apps by publisher 'BrutalStrike' deliver the same payload: 50K+ and 10K+ installs respectively [1]."
  - "Refresh tokens stolen in the attack do not expire — silent impersonation persists until tokens are manually revoked [1]."
learning_objectives:
  - "Identify which credential files AI developer tools create and why they require the same protection as API keys."
  - "Revoke compromised Codex tokens and audit your environment for other AI tooling credential files at risk."
  - "Apply supply chain hygiene practices to AI tooling dependencies: verify publishers, pin versions, audit new packages before install."
faq:
  - question: "Am I affected by the codexui-android attack?"
    answer: "If you installed the npm package codexui-android, or either of the Android apps published by 'BrutalStrike' (OpenClaw Codex Claude AI Agent or Codex), your ~/.codex/auth.json file was exfiltrated. Revoke your OpenAI Codex tokens immediately via OpenAI account management, even if you are uncertain whether you installed these packages."
  - question: "What exactly was stolen?"
    answer: "The attack exfiltrated four fields from ~/.codex/auth.json: access_token, refresh_token, id_token, and account_id. The refresh token is the most dangerous — it does not expire and allows an attacker to silently impersonate you indefinitely, generating new access tokens without your knowledge [1]."
  - question: "How do I revoke my Codex tokens?"
    answer: "Log into platform.openai.com, navigate to account management, and revoke active sessions and tokens for Codex. Then re-authenticate from a clean device. Treat the revocation as you would a compromised password: do it immediately, do not wait to investigate first."
  - question: "Does this affect Claude Code, GitHub Copilot CLI, or other AI coding tools?"
    answer: "This specific attack targeted ~/.codex/auth.json. However, Claude Code, Copilot CLI, Gemini CLI, and similar tools create their own credential files in home directory paths. The attack pattern — malicious packages or apps targeting AI tool auth files — is directly applicable to all of them. Audit where each tool stores credentials and protect those files accordingly."
  - question: "How did the package stay live for ~2 months before disclosure?"
    answer: "The domain anyclaw[.]store was registered April 12, 2026 — two days after the first npm upload — and the exfiltration code appeared in version 0.1.82, not the initial release. The package presented a clean GitHub repository and plausible-looking development history, which slowed detection. Aikido Security disclosed publicly on June 1, 2026 [1]."
references:
  - n: 1
    title: "OpenAI Codex Authentication Tokens Stolen via Malicious npm Package"
    url: https://thehackernews.com/2026/06/openai-codex-authentication-tokens.html
    date: 2026-06-01
    retrieved: 2026-06-04
---

# Your AI Dev Credentials Are the New API Key — And You Are Not Protecting Them

On June 1, 2026, Aikido Security disclosed that a malicious npm package called `codexui-android` had been silently stealing OpenAI Codex authentication tokens from developers for approximately two months. The package had 29,000+ weekly downloads. It sent the contents of `~/.codex/auth.json` — access token, refresh token, ID token, and account ID — to an attacker-controlled server impersonating Sentry [1].

The refresh token does not expire. Every developer who installed that package gave an unknown attacker permanent silent access to their OpenAI Codex account until they manually revoke it.

```takeaways
- codexui-android (29K+ weekly downloads) exfiltrated ~/.codex/auth.json to sentry.anyclaw[.]store [1].
- Refresh tokens stolen in the attack do not expire — impersonation persists until manually revoked [1].
- Two Android apps by publisher "BrutalStrike" delivered the same payload (50K+ and 10K+ installs) [1].
- Immediate action: revoke Codex tokens at platform.openai.com now. Do not wait to investigate first.
```

## What Was Stolen and Why It Matters

The credential file targeted — `~/.codex/auth.json` — is created automatically when a developer authenticates with the Codex CLI. Most developers are unaware it exists. It contains four fields [1]:

| Field | Risk |
|---|---|
| `access_token` | Short-lived API access; expires |
| `refresh_token` | **Does not expire**; generates new access tokens silently |
| `id_token` | Identity proof for OpenAI services |
| `account_id` | Unique identifier; links to billing and usage |

The refresh token is the critical failure. In standard OAuth flows, refresh tokens are the long-lived credential that allows a client to request new access tokens without re-authenticating. Holding a valid refresh token is equivalent to holding a password that never changes.

An attacker with your refresh token can:
- Generate new access tokens indefinitely
- Access Codex and associated OpenAI services
- Incur API usage billed to your account
- Access any data or integrations your Codex session can reach

This is not a temporary exposure. If you installed `codexui-android` and have not revoked your tokens, you are still compromised right now.

## How the Attack Worked

The attack followed a deliberate multi-stage pattern designed to evade detection [1]:

**Stage 1 — Establish legitimacy.** The first npm upload (version 0.1.72) happened on April 10, 2026 with no malicious code. The package presented a clean GitHub repository with plausible development history.

**Stage 2 — Register attacker infrastructure.** The domain `anyclaw[.]store` was registered on April 12, 2026 — two days after the npm upload. The subdomain `sentry.anyclaw[.]store` impersonates the legitimate Sentry error monitoring service, a tool common in developer environments. An HTTP request to a Sentry-looking endpoint from a developer tool raises no alarms.

**Stage 3 — Inject the payload.** Exfiltration code appeared in version 0.1.82. The package reads `~/.codex/auth.json` and sends its contents to the attacker's server on installation or execution.

**Stage 4 — Expand the surface.** The same payload was distributed through two Android apps published under the name "BrutalStrike":
- **OpenClaw Codex Claude AI Agent** (package: `gptos.intelligence.assistant`): 50,000+ installs
- **Codex** (package: `codex.app`): 10,000+ installs

The Android apps ran the exfiltration within a PRoot sandbox, suggesting the attacker understood the mobile execution environment [1].

The gap between first upload (April 10) and public disclosure (June 1) is approximately 52 days. During that window, every install of versions 0.1.82+ sent credentials to the attacker.

```takeaways
- The malicious payload was introduced in v0.1.82, not the initial release — a deliberate evasion pattern [1].
- The attacker's domain was registered after the npm package, then used as fake Sentry infrastructure [1].
- The Android distribution extended the attack surface beyond npm to mobile app stores [1].
```

## If You Installed This Package: What to Do Now

Do not investigate first. Revoke first.

**Step 1 — Revoke tokens immediately.**
Log into [platform.openai.com](https://platform.openai.com), navigate to account management, and revoke active sessions and tokens. This invalidates the refresh token and ends the attacker's persistent access.

**Step 2 — Delete the credential file.**
```bash
rm ~/.codex/auth.json
```

**Step 3 — Re-authenticate from a clean device.**
Do not re-authenticate on the same machine until you have audited what else is installed. The exfiltration code ran at install time; verify the `codexui-android` package is removed.

**Step 4 — Audit your npm history.**
```bash
npm ls --global | grep codex
cat ~/.npm/_logs/*.log | grep codexui
```

**Step 5 — Review account activity.**
Check platform.openai.com for API usage patterns inconsistent with your own activity. Unusual usage spikes since mid-April 2026 may indicate the attacker was using your credentials.

**Step 6 — Report to OpenAI security.**
If you confirm exposure, report via OpenAI's security disclosure channel. This helps them track the scope of account compromise.

## The Broader Problem: AI Tooling Creates Unprotected Credential Files

The Codex attack is a preview of a wider threat pattern. Every AI developer tool that authenticates via OAuth or API key writes a credential file to your home directory. Most developers treat these as transparent plumbing — they exist, they work, and they are never thought about again.

Here is what that looks like across the tools many developers now have installed:

| Tool | Credential file location | Token longevity |
|---|---|---|
| OpenAI Codex CLI | `~/.codex/auth.json` | Refresh token: indefinite |
| Claude Code | `~/.claude/` (config/auth) | Session token; varies |
| GitHub Copilot CLI | `~/.config/gh/hosts.yml` | GitHub OAuth token |
| Gemini CLI | `~/.gemini/` | Google OAuth token |
| AWS Bedrock CLI | `~/.aws/credentials` | IAM keys; long-lived by default |

None of these files have the cultural protection that `.env` files have acquired over the past decade. Developers are trained to `.gitignore` and never commit `.env`. They are not trained to think about `~/.codex/auth.json`.

The attacker who built `codexui-android` understood this gap. Their payload targeted a specific path that:
1. Every Codex CLI user has
2. Almost no one monitors
3. Contains long-lived credentials
4. Is readable by any process running as that user

This is exactly the pattern that made API key theft via environment variable leaks so effective in the 2019–2022 period, before `.env` hygiene became normalized. We are at the same stage with AI tool credential files in 2026.

```takeaways
- AI developer tools create credential files in home directory paths that developers rarely audit or protect [1].
- The same attack pattern is directly applicable to Claude Code, Copilot CLI, Gemini CLI, and any OAuth-authenticated AI tool.
- The cultural hygiene gap for AI tool credential files in 2026 mirrors the .env gap from 2019.
```

## What Good Credential Hygiene Looks Like for AI Tooling

**Treat auth files as secrets, not config.**
Add AI tool credential paths to your `.gitignore` globally:
```bash
# ~/.gitignore_global
.codex/
.claude/
.gemini/
.config/gh/
```

Run `git config --global core.excludesfile ~/.gitignore_global` if you have not already.

**Restrict file permissions.**
```bash
chmod 600 ~/.codex/auth.json
chmod 700 ~/.codex/
```

Only your user account should be able to read the file. This does not protect against processes running as your user, but it eliminates world-readable exposure.

**Audit installed npm packages before running them.**
For any package touching AI tooling credentials, read the source before installing. `npx` makes this easy to skip; do not skip it for packages in the AI tooling namespace:
```bash
npm pack <package-name> --dry-run
# or inspect the unpacked tarball
```

**Enable npm audit as a CI gate.**
If you maintain a repo that depends on AI tooling packages, add `npm audit` as a step. It will not catch zero-day malicious packages, but it catches known-vulnerable dependency chains.

**Use short-lived tokens where the tool supports it.**
OpenAI's platform allows API key rotation. Prefer short-lived API keys scoped to specific use cases over long-lived OAuth sessions for automated workflows. Reserve OAuth flows for interactive CLI use.

**Monitor for unexpected API usage.**
Set up usage alerts in platform.openai.com. An unexpected spike in API calls — especially outside your working hours or from unusual IPs — is the signal you need to catch a compromised token before it causes significant damage.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Audit the home directory credential files for common AI developer tools. For each tool found, report: (1) the credential file path, (2) its current permissions, (3) whether it appears in the user's global gitignore. Tools to check: Codex CLI (~/.codex/), Claude Code (~/.claude/), GitHub Copilot (~/.config/gh/hosts.yml), Gemini CLI (~/.gemini/). Output a table with status: PROTECTED / AT_RISK / NOT_FOUND."
  expectedOutput="A table showing each tool's credential file, its permissions, gitignore status, and an overall risk classification"
/>

<KnowledgeCheck
  question="Why is the refresh_token more dangerous than the access_token in the Codex attack?"
  answers={["The refresh_token is larger and contains more user data", "The refresh_token does not expire and can be used to silently generate new access tokens indefinitely", "The refresh_token grants administrator access to OpenAI systems", "The access_token is encrypted but the refresh_token is not"]}
  correct={1}
/>

## What This Signals for AI Developer Security

The `codexui-android` attack is not sophisticated in its execution — it is a credential-harvesting script targeting a predictable file path. What makes it notable is the target selection: the attacker correctly identified that AI developer tooling credential files are high-value, poorly protected, and systematically ignored by the security posture most developers have built around their environments.

This is the first publicly disclosed attack targeting an AI CLI tool's credential file at scale. It will not be the last.

The security community's response to API key leaks in the early cloud era was to normalize `.env` files, build pre-commit hooks for secret scanning, and make credential-in-code a CI failure. That took approximately three years after the first major incidents.

The AI developer tooling ecosystem is at day one of that cycle. The `~/.codex/auth.json` file today is what a hardcoded AWS key in a GitHub repo was in 2018. The tooling to detect and prevent these leaks does not yet exist at scale. The cultural norms are not yet established.

That window is exactly when attackers operate. Build the hygiene now, before the norm exists, and you will not be in the window when the next attacker targets `~/.claude/auth.json` or `~/.gemini/credentials`.

## The Broader Wave: Codex Is One Target Among Many

The `codexui-android` disclosure landed the same week as three other confirmed supply-chain campaigns converging on developer machines. These are not isolated incidents — they represent a coordinated shift in attacker strategy.

**TrapDoor (May 2026)** distributed 34+ malicious packages across npm, PyPI, and Crates.io targeting crypto, DeFi, and AI developers. What makes it distinct: attackers injected `.cursorrules` and `CLAUDE.md` files designed to poison AI coding assistants. A developer working in a compromised repository would have their AI assistant — Cursor, Claude Code — silently instructed to conduct "security scans" that exfiltrate secrets to attacker infrastructure. ["TrapDoor targets developers in crypto, DeFi, Solana, and AI communities. The malicious packages are designed to steal developer secrets, crypto wallets, SSH keys, cloud credentials, browser data, and environment variables."](https://thehackernews.com/2026/05/trapdoor-supply-chain-attack-spreads.html) — Socket (The Hacker News, 2026-05-27)

**Shai-Hulud / Mini Shai-Hulud** is a self-propagating npm worm from the TeamPCP threat actor, now on its seventh confirmed wave since March 2026. It has hit Trivy, LiteLLM, Bitwarden CLI, TanStack, and the Nx Console VS Code extension. The Nx Console attack specifically targeted `~/.claude/settings.json` — the Claude Code config file, not Codex. The worm spreads by compromising npm publish tokens and re-releasing packages under legitimate namespaces, making it structurally self-amplifying. Immediate remediation requires rotating all CI secrets: GitHub tokens, npm tokens, NX_CLOUD_ACCESS_TOKEN, and cloud provider credentials. ([StepSecurity](https://www.stepsecurity.io/blog/mini-shai-hulud-is-back-a-self-spreading-supply-chain-attack-hits-the-npm-ecosystem), 2026-06-04)

**Red Hat npm supply chain (June 2, 2026)**: Wiz researchers documented attackers compromising GitHub Actions workflows to forge valid SLSA Build Level 3 provenance attestations for malicious releases in the `@redhat-cloud-services` namespace. The attack vector: the compromised workflow requested GitHub OIDC identity tokens and published packages with legitimate-looking provenance metadata. Valid SLSA attestation is no longer a trust signal when the build pipeline itself is the attack surface. ([CSO Online](https://www.csoonline.com/article/4179866/infected-red-hat-npm-packages-expose-developer-credentials.html), 2026-06-02)

**BadHost / CVE-2026-48710 (May 2026)**: A single-character HTTP Host header injection bypasses path-based authorization in Starlette, the routing core of FastAPI — and by extension vLLM, LiteLLM, most OpenAI-shim proxies, and the majority of MCP servers. This network-level attack converges on the same credential stores that supply-chain attacks target via malicious packages. Patch your Starlette version and audit any MCP server accepting external HTTP traffic. ([Ars Technica](https://arstechnica.com/information-technology/2026/05/millions-of-ai-agents-imperiled-by-critical-vulnerability-in-open-source-package/), 2026-05-29)

The common thread: ["A single compromised workstation can quietly become an entry point into CI/CD pipelines and build infrastructure. That's not credential theft. That's an initial access operation."](https://www.csoonline.com/article/4177019/trapdoor-malware-campaign-puts-developer-workstations-in-ciso-spotlight.html) — Sakshi Grover, IDC Asia Pacific (CSO Online, 2026-05-27). Developer machines running AI tooling are now the highest-value initial access target in the modern software supply chain, and the campaigns are converging simultaneously.

---

If you want to build secure AI agent systems from the ground up — not just patch the last breach — the **[AI Agent Security for Developers](https://academy.kspl.tech/courses/ai-agent-security-for-developers)** course covers exactly this. Chapter 4 covers credential isolation patterns so your agents never hold long-lived plaintext tokens. Chapter 5 covers CI/CD hardening so a compromised package publisher cannot forge valid provenance for your pipeline.

See also: [[ai-coding-agent-supply-chain-threat-atlas-2026]] for the broader threat landscape across AI developer tooling.

See also: [[mcp-server-registry-security]] for supply chain risks specific to MCP server dependencies.
