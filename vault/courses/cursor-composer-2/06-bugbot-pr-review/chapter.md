---
course_slug: cursor-composer-2
chapter_num: 6
title: "Bugbot: AI-Powered PR Review"
description: "Learn how Cursor Bugbot automatically reviews pull requests for logic errors, null dereferences, and security smells — and how its Autofix feature closes the review loop on agent-generated code from your /multitask and Background Agent runs."
chapter_primary_query: "How does Cursor Bugbot work and how do I set it up to automatically review pull requests?"
first_60_words_answer: "Bugbot is Cursor's automated PR reviewer, a GitHub App that scans every pull request automatically for high-confidence bugs and posts inline code review comments within seconds. It focuses exclusively on logic errors, null dereferences, off-by-ones, and security smells; style and formatting stay with your linters. Bugbot runs on Cursor's cloud infrastructure, so it reviews both human-written and agent-generated PRs equally."
learning_objectives:
  - "Enable Bugbot on a repository by installing the GitHub App and configuring settings in the Cursor dashboard"
  - "Describe the bug categories Bugbot flags versus the categories it deliberately ignores"
  - "Interpret Bugbot's inline review comments and decide whether to fix, dismiss, or escalate each finding"
  - "Connect Bugbot's review loop to a /multitask parallel-agent workflow from Chapter 5"
faq:
  - question: "What is Cursor Bugbot and what does it review?"
    answer: "Bugbot is Cursor's automated PR reviewer — a GitHub integration that posts inline code-review comments for logic errors, null dereferences, off-by-ones, and security smells. It ignores style and formatting. Bugbot uses a combination of frontier and in-house models, designed for high-confidence defect detection with a low false-positive rate (source: cursor.com/bugbot, retrieved 2026-06-11)."
  - question: "How do I enable Bugbot on my repository?"
    answer: "Open your Cursor dashboard, go to the Bugbot tab, connect your GitHub organisation (org admin access required), and select repositories to monitor. Once the GitHub App is installed, Bugbot reviews every new PR automatically on open and push. You can alternatively configure it to run only when a reviewer comments `cursor review` or `bugbot run` on the PR (source: cursor.com/docs/bugbot, retrieved 2026-06-11)."
  - question: "Does Bugbot replace human code review?"
    answer: "No. Bugbot reviews the diff, not the full codebase, so it cannot evaluate architectural decisions or cross-file logic. Its default verdict is neutral — it advises rather than blocks merges. Security-critical changes still require human review. Think of Bugbot as first-pass triage for high-confidence mechanical bugs (source: stevekinney.com/courses/self-testing-ai-agents/tuning-bugbot-for-your-codebase, retrieved 2026-06-11)."
  - question: "What does Bugbot Autofix do?"
    answer: "Autofix spins up isolated Cloud Agent VMs to fix the bugs Bugbot identifies, then commits the changes back to the PR branch. Over 35% of Autofix changes get merged by developers. It requires on-demand usage pricing and storage enabled (not Legacy Privacy Mode), and consumes Cloud Agent credits at your plan rate (source: cursor.com/docs/bugbot, retrieved 2026-06-11; workos.com/blog/cursor-bugbot-autoreview-claude-code-prs, retrieved 2026-06-11)."
sources:
  - https://cursor.com/bugbot
  - https://cursor.com/changelog
  - https://cursor.com/docs/bugbot
  - https://workos.com/blog/cursor-bugbot-autoreview-claude-code-prs
  - https://stevekinney.com/courses/self-testing-ai-agents/tuning-bugbot-for-your-codebase
  - https://www.devtoolsacademy.com/blog/state-of-ai-code-review-tools-2025
tags:
  - cursor
  - bugbot
  - pr-review
  - automated-review
  - code-review
  - cursor-composer-2
duration_min: 30
read_time_min: 8
last_updated: 2026-06-11
status: g3-passed
author: content-author
ticket: KOEA-7816
whats_new: "Chapter covers Cursor Bugbot — automated PR reviewer that integrates with GitHub to post inline code-review comments. Covers setup via the Cursor dashboard, BUGBOT.md configuration, Autofix, the /multitask closing-the-loop workflow, and usage-based pricing (updated May 2026)."
prerequisites_chapters: [1, 2, 3, 4, 5]
positions: []
---

# Bugbot: AI-Powered PR Review

Bugbot is Cursor's automated PR reviewer, a GitHub App that scans every pull request automatically for high-confidence bugs and posts inline code review comments within seconds. It focuses exclusively on logic errors, null dereferences, off-by-ones, and security smells; style and formatting stay with your linters. Bugbot runs on Cursor's cloud infrastructure, so it reviews both human-written and agent-generated PRs equally.

In the context of this course, Bugbot closes the review loop opened in [[cursor-composer-2/05-multitask-parallel-agents]]: after a `/multitask` run produces N branch PRs, Bugbot reviews each one automatically before you merge — catching the mechanical bugs that slipped through your agent's test suite. The same applies to [[cursor-composer-2/04-background-agents]] work; every PR your cloud agents open gets a Bugbot scan on push.

---

## 6.1 Enabling Bugbot

Setup takes about five minutes [4]:

1. **Cursor dashboard → Bugbot tab.** Click **Connect GitHub Organisation** (org admin access required). GitLab is also supported — GitLab.com and self-hosted GitLab [3].
2. **Select repositories.** Toggle the repos you want Bugbot to monitor.
3. **Choose trigger mode.** Default is automatic on every PR open and push. Set to manual-only if you prefer opt-in: Bugbot then runs only when someone comments `cursor review` or `bugbot run` on the PR [3].
4. **Optional: `.cursor/BUGBOT.md`.** Drop a rules file in the repo root to give Bugbot project-specific context (Section 6.3).

Once installed, Bugbot posts review comments directly in the GitHub PR interface — no Cursor editor open required. You can also require the `Cursor Bugbot` check via branch protection to enforce review completion before merge [3].

<Callout type="info">
**Pre-push review (Cursor 3.7+):** Run `/review` or `/review-bugbot` from within Cursor before pushing to get Bugbot findings locally before the PR opens. The integration recognises previously reviewed diffs and skips redundant analysis — only new changes are re-reviewed (source: cursor.com/changelog, retrieved 2026-06-11). For CI and CLI-based workflows, see [[cursor-composer-2/03-cursor-cli-headless]].
</Callout>

---

## 6.2 What Bugbot Reviews — and What It Ignores

Bugbot targets defects that escape static analysis [1][6]:

| Bugbot **flags** | Bugbot **ignores** |
|---|---|
| Logic errors and incorrect conditionals | Code style and formatting |
| Null / undefined dereferences | Naming conventions |
| Off-by-one errors | Import ordering |
| Security smells (SQL injection, unsafe `eval`) | Whitespace and indentation |
| Missing error handling on API calls | Documentation and comment style |

As of the June 10, 2026 changelog update, average review time is approximately 90 seconds — down from ~5 minutes — and bug detection improved to 0.62 bugs found per review, powered by Composer 2.5 [2]. Bugbot's default verdict is **neutral**: findings are advisory and do not block merges unless you configure branch protection to require a passing check [3].

---

## 6.3 Configuring Bugbot with BUGBOT.md

Create `.cursor/BUGBOT.md` at the repository root to give Bugbot project-specific review rules. As of April 2026, the file uses uppercase capitalisation (`BUGBOT.md`, not `bugbot.md`) [5]:

<RunPromptCell
  title="Starter BUGBOT.md for a Next.js app"
  prompt={`# Bugbot Review Rules

## Project context
Next.js 15 e-commerce app. Stripe handles all payment processing.

## High-scrutiny areas
- Stripe webhook handlers: always verify signature before processing payload
- Database access: parameterised queries only, no string concatenation
- API routes: validate session before reading any user data

## Known safe patterns (do not flag)
- console.log in /scripts/* (build tooling, not production code)
- process.env access in next.config.js

## Out of scope
- Tailwind class ordering
- JSDoc comment presence`}
  expectedOutput={`Bugbot applies these rules to all PRs in this repository. High-scrutiny entries increase model attention on payment and auth code. Safe-pattern entries suppress known false positives from build tooling.`}
/>

Rules are hierarchical: Team Rules → project `BUGBOT.md` → User Rules. Nest `BUGBOT.md` files in subdirectories for more targeted enforcement — useful in monorepos where each package has different standards [4].

---

## 6.4 Reading Bugbot Output

Bugbot posts inline comments on specific diff lines. Each comment describes what it found and why it matters. The practical workflow [5]:

1. **Read the finding.** Not every finding is correct — treat each as a hypothesis.
2. **If right,** hand it to an agent: *"Bugbot flagged this handler for trusting the request body. Fix it."* The agent makes the change and pushes; Bugbot re-reviews the new diff.
3. **If wrong,** resolve the PR thread and update `.cursor/BUGBOT.md` to suppress future recurrence.
4. **If ambiguous,** fix it anyway — Bugbot findings are often symptoms of real issues even when the exact diagnosis is off.

<KnowledgeCheck
  questions={[
    {
      type: "mcq",
      question: "Which of the following will Bugbot flag by default?",
      options: [
        "Single vs double quotes used inconsistently across the file",
        "A null check missing before dereferencing a user object",
        "An import statement sorted in the wrong alphabetical order",
        "A Tailwind CSS class ordered incorrectly in a template"
      ],
      correct: 1,
      explanation: "Bugbot targets high-confidence defects like null dereferences. Style issues (quote style, import order, Tailwind class order) are explicitly out of scope and handled by your linter."
    }
  ]}
/>

---

## 6.5 Autofix: Closing the Loop

When a Bugbot finding is clear-cut, **Autofix** resolves it without you writing a line of code [3][4]:

- Autofix spins up an isolated Cloud Agent VM, applies the fix, and commits it to the PR branch.
- Choose the mode: **Create New Branch** (recommended — keeps fix separate for easy review) or **Commit to Existing Branch** (max 3 attempts per PR to prevent loops) [3].
- Over 35% of Autofix changes get merged by developers [4].

Autofix requires **on-demand usage pricing** and **storage enabled** in your account settings (accounts in Legacy Privacy Mode cannot use it). It consumes Cloud Agent credits at your plan rate [3].

<KnowledgeCheck
  questions={[
    {
      type: "mcq",
      question: "Bugbot Autofix requires which two account settings to be active?",
      options: [
        "On-demand usage pricing and storage enabled (not Legacy Privacy Mode)",
        "Seat-based billing and background agent credits both turned on",
        "GitHub Enterprise Server plus an advanced rules subscription enabled",
        "MCP server access plus on-demand usage pricing turned on"
      ],
      correct: 0,
      explanation: "The Cursor docs specify Autofix requires on-demand usage pricing and storage enabled (not in Legacy Privacy Mode). It then bills against Cloud Agent credits at your plan rate."
    }
  ]}
/>

---

## 6.6 Bugbot + /multitask: Closing the Review Loop

Chapter 5's `/multitask` command produces a fleet of PR branches — one per subagent chunk. Bugbot's value compounds in this pattern: each PR gets reviewed in parallel within ~90 seconds of opening [2], so by the time you sit down to merge, structured findings already wait in every PR thread.

Practical sequence:

1. Run `/multitask` → N branch PRs open on GitHub.
2. Bugbot reviews each PR automatically (~90 seconds per PR) [2].
3. Review Bugbot findings across all PRs; use Autofix for mechanical fixes.
4. Human review focuses on architecture and cross-PR interactions — not the mechanical bugs Bugbot already caught.

A well-tuned `.cursor/BUGBOT.md` pays off most here: agent-generated code is particularly prone to subtle bugs, and project context makes Bugbot's findings more precise [6].

---

## 6.7 Limitations

Bugbot reviews the **diff, not the full codebase**. This means it:

- Cannot evaluate cross-file architectural decisions
- Misses bugs that only surface when two changed files interact at runtime
- Cannot substitute for a security audit on high-stakes changes (auth, payments, access control)
- Works best on focused, well-described PRs — sprawling multi-domain diffs reduce precision

Bugbot's neutral verdict is intentional: it advises, you decide. For security-critical PRs, treat Bugbot as a first-pass filter and follow with a dedicated human security review.

---

## 6.8 Pricing

Bugbot pricing moved to **usage-based billing** in May 2026 [3]. The legacy seat-based plan remains available for existing subscribers [3]. A **14-day free trial** is available on all plans [1]. Check `cursor.com/pricing` for current on-demand rates — pricing has been actively revised throughout early 2026.
