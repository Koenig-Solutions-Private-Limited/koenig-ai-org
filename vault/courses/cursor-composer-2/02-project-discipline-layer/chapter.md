---
course_slug: cursor-composer-2
chapter_num: 2
title: ".cursorrules + AGENTS.md — The Project-Discipline Layer"
status: awaiting-g0
author: course-author
ticket: KOEA-2385
chapter_primary_query: "How do I make .cursorrules and AGENTS.md actually enforce rules in Cursor sessions?"
first_60_words_answer: "Make .cursorrules enforce rules by writing verifiable constraints — specific numbers and counter-examples the model can check mechanically. Make AGENTS.md enforce team norms by adding an escalation matrix with explicit stopping conditions. Then validate with a three-step cite-the-rule, compliance-check, and violation-probe protocol before trusting either file in production workflows."
learning_objectives:
  - "Engineer .cursorrules rules that are specific enough to be verifiable, not just stylistic"
  - "Design AGENTS.md as a team-AI interaction manifest with a formal escalation matrix"
  - "Run a compliance test protocol to validate agent adherence and diagnose rule failures"
  - "Iterate rule sets based on observed AI behavior rather than guessing at rule phrasing"
prerequisites_chapters: [1]
duration_min: 45
last_updated: 2026-06-10
read_time_min: 18
tags:
  - cursorrules
  - agents-md
  - project-discipline
  - cursor-composer-2
positions: []  # chapter is tool-specific tutorial; stance engagement deferred to course overview
faq:
  - question: "Why does Cursor sometimes ignore .cursorrules?"
    answer: "Three root causes account for most ignores: the file isn't in the context window (verify it's in the project root and restart the session), the rule is phrased too vaguely for the model to operationalize, or the rule conflicts with a strong prior from the model's training data. The compliance test protocol in section 2.4 isolates which cause applies. See [Rules for AI](https://cursor.com/docs/context/rules-for-ai) for context-loading details."
  - question: "What's the difference between .cursorrules and AGENTS.md?"
    answer: ".cursorrules governs code-writing behavior — language versions, forbidden patterns, test requirements. AGENTS.md governs project identity and session coordination — what the system is, who the active agents are, what triggers escalation. Both are needed; they serve different surfaces of the same instruction contract. The [Background Agents docs](https://cursor.com/docs/background-agents) explain how AGENTS.md is consumed by autonomous sessions."
  - question: "Can I use the same .cursorrules file across multiple projects?"
    answer: "You can use it as a template, but stack-specific constraints (language version, test runner, ORM) must be updated per project. Generic rules like 'max function length: 40 lines' travel well; 'use Drizzle query builder' does not. Treat it like a Dockerfile — start from a base, override what differs. The [Composer 2 changelog](https://cursor.com/changelog/composer-2) lists which rule surface types are read per session context."
inline_assets:
  - type: diagram
    path: ./img/rules-adherence-loop.svg
    alt: "Feedback loop for iterating .cursorrules: write rule → test compliance → diagnose failure → tighten rule wording → retest"
sources:
  - https://cursor.com/docs/context/rules-for-ai
  - https://np.reddit.com/r/ClaudeAI/comments/1rozbzb/are_agents_actually_useful_for_complex_tasks/
  - https://www.reddit.com/r/cursor/comments/1t9gzd1/tips_for_using_composer_2_new_to_cursor/
  - https://news.ycombinator.com/item?id=46955895
  - https://cursor.com/docs/background-agents
  - https://cursor.com/changelog/composer-2
---

# .cursorrules + AGENTS.md — Master the Project-Discipline Layer

[[cursor-composer-2/01-foundations|Chapter 1]] gave you the templates. This chapter gives you the engineering discipline to make them actually work.

A [[cursorrules|`.cursorrules`]] file that isn't followed is just documentation. An `AGENTS.md` that doesn't encode team constraints is a formality. The gap between "I have these files" and "my AI sessions consistently produce compliant code" is a validation and iteration practice — and that practice is what this chapter teaches.

---

## 2.1 Why Rule Files Fail in Practice

The most common failure mode is not a missing file. It is vague rules that look plausible but give the model nothing to enforce.

Here is the pattern in action:

| Vague | Verifiable |
|---|---|
| "Write clean code" | "Max function length: 40 lines. Extract if longer." |
| "Use TypeScript properly" | "All functions must have explicit return types. No `any` — use `unknown` with explicit narrowing." |
| "Handle errors gracefully" | "All async functions must either return a typed error via `Result<T, E>` or throw with an `Error` instance. No swallowed rejections." |
| "Follow project conventions" | "File naming: kebab-case for utilities, PascalCase for React components. Component filename must match its default export: `UserCard.tsx` exports `UserCard`." |

The left column sounds reasonable. It fails because "clean" and "properly" have no definition the model can test against. The right column gives the model a binary check: "Is this function over 40 lines?" Rules that can be verified mechanically are also rules the model can self-check during generation.

> **Info:** `.cursorrules` does not execute rules — there is no linter parsing the file. The model reads it as natural language instructions. Wording matters more than syntax. A rule with specific numbers and a counter-example outperforms a rule with adjectives every time. [3]

---

## 2.2 Constructing Rules That Work

Build `.cursorrules` in four layers. Each layer serves a different function in the instruction contract.

### Layer 1: Stack declaration

State language, runtime, framework, and tool versions as facts, not preferences.

```
## Stack
# Updated: 2026-06-10
- Language: TypeScript 5.4 (strict mode, noUncheckedIndexedAccess: true)
- Runtime: Node 22 LTS
- Framework: Next.js 15 App Router — no Pages Router
- Test runner: Vitest 2.x — not Jest
- Package manager: pnpm 9.x
```

Version numbers prevent the model from defaulting to whatever patterns dominated its training data. "TypeScript" without a version will produce 4.x-era idioms unless you specify otherwise. The Composer 2 changelog documents which rule surface types are applied per session context mode. [1][6]

### Layer 2: Structural constraints

Define file organization, naming, and module boundaries as explicit rules.

```
## Structure
- Component files: PascalCase. Filename must match default export. UserCard.tsx exports UserCard.
  Invalid: user-card.tsx, userCard.tsx.
- Utility files: kebab-case under /lib — e.g. format-date.ts
- Props interfaces: named <ComponentName>Props. Example: UserCardProps.
- No barrel files (index.ts re-exports) under /lib or /server — import directly.
- Server-only modules: suffix with .server.ts — never import into client components.
```

### Layer 3: Forbidden patterns

List what must never appear. Prohibitions outperform recommendations for consistent enforcement.

```
## Forbidden
- No raw SQL strings — Drizzle query builder only.
- No console.log in production paths — use lib/logger.ts only.
- No window access without typeof window !== 'undefined' guard.
- No React.FC type annotation — use explicit prop types with return ReactElement.
- No any type — use unknown with explicit narrowing.
```

Each rule is on its own line. A model skimming a list stops at the first plausible match; standalone lines are harder to miss.

### Layer 4: AI behavior directives

Instructions that govern how the model should operate, not just what it should produce.

```
## AI behavior
- Before editing any file, state your understanding of the current behavior and the intended change.
- If a change affects more than 3 files, list all affected files before making edits.
- If you encounter a decision point where multiple approaches are valid, stop and ask.
- Do not "fix" code you weren't asked to change — flag it with a comment instead.
- If a task requires a dependency install, stop and state the dependency + reason before proceeding.
```

> **Hot tip:** Add `# Updated: <date>` at the top of your `.cursorrules` file. Date changes create visible diffs in PRs, making rule changes explicit and reviewable — instead of silently shifting AI behavior on your team.

---

## 2.3 AGENTS.md as a Team-AI Interaction Manifest

Chapter 1 introduced `AGENTS.md` as project context for a single developer. The more precise framing for teams is: **a contract between your team and every AI agent that touches the codebase** — whether that is Cursor Composer in a live session or a Background Agent running autonomously.

The upgrade from a minimal `AGENTS.md` to a team-grade manifest is the **escalation matrix** — an explicit set of stopping conditions the agent must honor.

### Designing an escalation matrix

Community experience with production agentic workflows confirms that agents without explicit escalation conditions tend to proceed through uncertainty rather than stop [2]. They guess. The escalation matrix makes stopping conditions unambiguous.

```markdown
## Escalation matrix

| Condition | Required action |
|---|---|
| Change touches /server/auth or /lib/crypto | Stop. Flag for human security review before commit. |
| DB migration detected (new file in /drizzle/migrations) | Run `pnpm drizzle-kit check`. Confirm no destructive ops before continuing. |
| Change affects >5 files | Produce a plan listing all affected files. Get approval. Then execute. |
| Test suite fails after a change | Stop. Do not continue to next step. Report the failure. |
| A new dependency install is required | Stop. State the dependency and why. Wait for human confirmation. |
```

Two principles when writing escalation conditions:

1. **State the condition, not the judgment.** "Change touches /server/auth" is mechanical. "Change looks security-sensitive" requires the model to make a call it is not equipped to make reliably.

2. **Specify the action, not just the signal.** "Flag for security review" is more useful than "be careful here."

### Encoding team norms

`AGENTS.md` is also the right place for workflow conventions that would otherwise live only in tribal knowledge:

```markdown
## Team conventions

- Branch naming: feat/<ticket-id>-<short-description>, fix/<ticket-id>-description
- PR size: target ≤400 line changes. If larger, explain in the PR description why a split creates more overhead.
- Code review: ≥1 approval from a team member who didn't write the change.
- Deployment: main → staging auto-deploys. main → prod requires manual workflow trigger.
- Secrets: environment variables only. Never hardcode in any file, including test fixtures.
```

When a Background Agent runs an autonomous task, this context lets it produce branches and PRs that fit your team's conventions without being re-briefed each session. [5]

> **Warning:** `AGENTS.md` is not `.cursorrules`. Do not put code-quality constraints in `AGENTS.md` — they will compete with `.cursorrules` rules if they ever diverge, and the model will receive conflicting instructions. Keep the separation clean: `.cursorrules` = how to write code; `AGENTS.md` = what the project is and how the team operates.

---

## KnowledgeCheck 3: File Separation

**Question (MCQ):** Which of the following rules belongs in `.cursorrules` rather than `AGENTS.md`?

- A) Branch naming: `feat/<ticket-id>-<short-description>`
- B) Max function length: 40 lines. Extract if longer.
- C) Production deployment requires a manual workflow trigger.
- D) PR size target: ≤400 line changes.

*Correct answer: B — it is a code-writing constraint the model enforces during generation. A, C, and D are team operation norms (workflow, branching, deployment) that belong in `AGENTS.md` so both human teammates and autonomous agents understand the project's process expectations.*

---

## 2.4 Validating Agent Adherence

Having the files is not enough. Validate that the model is reading and following them before you commit to this setup for your team. Use this three-step protocol:

### Step 1: Cite-the-rule test

Open a new Composer session pinned to Composer 2. Send:

```
Before writing any code, list all .cursorrules constraints that apply to 
creating a new React component that displays a user's avatar and name.
```

**Expected:** The model lists specific rules from your file — component naming, PascalCase, co-located test requirement, explicit return types, etc. If it returns generic TypeScript advice or lists nothing, the file is not in context. Restart the session from the project root.

### Step 2: Compliance check

Ask the model to generate the component. Verify the output mechanically:

- Is the file named with PascalCase and matching the export name?
- Does the props interface follow the `<ComponentName>Props` convention?
- Is there a co-located test file?
- Are any forbidden patterns present?

### Step 3: Violation probe

Ask for something that should be refused or flagged:

```
Create a new utility function in /lib/data.ts that queries the users table 
using a raw SQL string.
```

**Expected:** The model flags the violation ("This would require a raw SQL string, which violates the .cursorrules constraint") and offers a Drizzle alternative. If it produces the raw SQL without flagging it, the forbidden pattern rule needs stronger wording — move it to a standalone line and add the word "Never" before the pattern.

### Diagnosing a rule that isn't followed

Three root causes, in order of frequency:

| Cause | Diagnosis | Fix |
|---|---|---|
| File not in context | Step 1 returns generic advice | Restart session from project root |
| Rule too vague | Model generates code that sort-of follows the rule but not precisely | Add a counter-example and measurable threshold |
| Strong training prior overrides | Model follows the rule sometimes but not consistently for a specific pattern (e.g. `console.log`) | Make the prohibition a standalone line starting with "Never use X" — not buried in a list |

> **Info:** The HackerNews "Prompt Contracts" discussion (2026-05-28) observed that persistent instruction files behave more like soft constraints than hard rules — the model weighs them against its own priors. The fix is not to write longer rules; it is to write rules that give the model nothing to weigh against. A specific, binary rule ("file must be PascalCase") leaves no room for interpretation. [4]

---

## RunPromptCell: Naming Convention Compliance Test

> **Try this in Cursor Composer now.** Open a new session (Cmd/Ctrl+Shift+L) pinned to Composer 2. First, confirm your `.cursorrules` contains:
>
> ```
> ## Naming conventions
> - React component files: PascalCase. The filename must match the default export name.
>   Valid: UserCard.tsx (exports UserCard).
>   Invalid: user-card.tsx, userCard.tsx — kebab-case and camelCase filenames are not permitted.
> - Props interfaces: named <ComponentName>Props. Example: UserCardProps.
>   Invalid: Props, IProps, ComponentProps.
> ```
>
> Then send this prompt to Composer:

```
Create a new React component that displays a product name and price.
Accept productName (string) and price (number) as props.
Place it at components/product-display.tsx.
```

**What to observe:**

- Does the model flag `product-display.tsx` as a naming convention violation before or while generating?
- Does it rename the file to `ProductDisplay.tsx` in its output?
- Is the props interface named `ProductDisplayProps`?
- Does the default export match the filename?

**If the model creates `product-display.tsx` without flagging it:** Your naming rule needs the counter-example to be more explicit. The rule above includes `Invalid: product-display.tsx — kebab-case filenames are not permitted for component files`. If that line is missing, add it and rerun.

**Expected compliant output:** File named `ProductDisplay.tsx`, props interface named `ProductDisplayProps`, default export `ProductDisplay`, optional but expected: co-located `ProductDisplay.test.tsx` if your rules require it.

---

## KnowledgeCheck 1: Rule Specificity

**Question (MCQ):** Which of the following `.cursorrules` entries is verifiable — meaning both the model and a human reviewer can check compliance mechanically?

- A) "Write clean, readable functions."
- B) "Use TypeScript best practices throughout."
- C) "Max function length: 40 lines. Extract if longer."
- D) "Prefer composition over inheritance where possible."

*Correct answer: C — it specifies a measurable threshold (40 lines) that can be checked without judgment. A, B, and D all require interpretation of what "clean," "best practices," and "where possible" mean.*

---

## KnowledgeCheck 2: Compliance Testing

**Question (free-form):** You run the Step 1 cite-the-rule test and the model returns generic TypeScript advice instead of citing your specific `.cursorrules` constraints. What are the two most likely causes, and what action do you take for each?

*Model answer: (1) The file is not in the session context — the session may have been started outside the project root, or the file was added after the session began. Fix: restart the Composer session from the project root and rerun the cite-the-rule test. (2) The rules are too vague for the model to distinguish them from general TypeScript advice. Fix: review each rule for specificity, add concrete examples and measurable thresholds, and retest.*

---

## Hands-On Exercise: Naming Convention Enforcement

**Objective:** Configure a naming convention rule in `.cursorrules`, generate a compliant component, then verify the model correctly identifies a deliberate violation.

**Time-box:** 30 minutes.

**Steps:**

1. **Add a naming convention section** to your `.cursorrules` file using the template from the RunPromptCell above. Include both the valid and invalid examples. Commit it.

2. **Run the compliance test.** Start a new Composer session from the project root. Run the product display component prompt. Confirm the model produces `ProductDisplay.tsx` with a `ProductDisplayProps` interface and a `ProductDisplay` default export.

3. **Run the violation probe.** Send this prompt:

   ```
   Create a React component at components/user-profile.tsx that displays 
   a user's full name. Name the props interface just "Props".
   ```

   The model should identify two violations: the filename (`user-profile.tsx` should be `UserProfile.tsx`) and the props interface name (`Props` should be `UserProfileProps`). It may still generate the code — what matters is that it explicitly calls out both violations.

4. **Iterate if needed.** If the model missed one or both violations, apply the diagnosis from section 2.4 and tighten the rule wording. Rerun the violation probe until both violations are flagged.

**Success criteria:**

- Compliance test produces a correctly named component on the first attempt.
- Violation probe results in explicit identification of both naming violations.
- `.cursorrules` is committed with your naming convention section including at least one counter-example for each rule.
- `AGENTS.md` is committed with an escalation matrix containing at least three conditions specific to your project's actual risk boundaries.

---

## What's Next

Chapter 2 gave you the engineering discipline behind project rules: how to write them with the specificity that produces reliable adherence, how to validate that adherence, and how to diagnose failures when rules aren't followed.

[[cursor-composer-2/03-context-aware-code-generation|Chapter 3: Context-Aware Code Generation]] builds directly on this foundation. With your project rules producing consistent outputs, the next challenge is keeping Cursor's context window focused on the right files as your project grows. You will learn `@file` and `@symbol` reference strategies, context window hygiene at the task level, and how to structure multi-file generation prompts so Composer maintains architectural consistency across a growing codebase.

---

## References

1. Cursor. "Rules for AI." cursor.com/docs/context/rules-for-ai. Retrieved 2026-06-10.
2. Reddit r/ClaudeAI. "Are agents actually useful for complex tasks?" np.reddit.com/r/ClaudeAI/comments/1rozbzb/. Retrieved 2026-05-14.
3. Reddit r/cursor. "Tips for using Composer 2 — new to Cursor." reddit.com/r/cursor/comments/1t9gzd1/. Retrieved 2026-05-14.
4. HackerNews. "Prompt Contracts — persistent instruction surfaces for AI." news.ycombinator.com/item?id=46955895. Retrieved 2026-05-28.
5. Cursor. "Background Agents." cursor.com/docs/background-agents. Retrieved 2026-06-10.
6. Cursor. "Composer 2 Changelog." cursor.com/changelog/composer-2. Retrieved 2026-05-14.
