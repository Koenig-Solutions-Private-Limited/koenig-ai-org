# Chapter 1: Composer 2 Models & IDE-First Workflow (2026)

Cursor Composer 2 is not just a model upgrade — it is a shift in how cost-sensitive engineering teams structure their AI-assisted workflows. Built on Kimi K2.5 with large-scale reinforcement learning, priced at $0.50/M input and $2.50/M output tokens, Composer 2 changes the economics of iterative agent loops inside your IDE. This chapter explains what Composer 2 actually is, how to read its benchmarks honestly, when to route tasks to it versus a frontier model, and how to configure the two project files — .cursorrules and AGENTS.md — that determine whether the model helps or drifts.

## 1.1 What Cursor Composer 2 Is (and Isn't)

When Cursor announced Composer 2 in May 2026, the marketing framing positioned it against Claude Opus 4.6. The community reaction was more nuanced.

### Model lineage

Cursor trained Composer 2 in two phases, as documented in their technical report and arXiv paper (arxiv.org/abs/2603.24477):

1. Continued pretraining on a large corpus of code and developer context.
2. Large-scale reinforcement learning optimized for agentic coding tasks, including multi-file edits, test generation, and tool-use in IDE environments.

Community analysis on HackerNews and r/LocalLLaMA identified the Kimi K2.5 base model as the starting point (confirmed indirectly by architecture analysis and training methodology similarities). Cursor did not prominently disclose the base model at launch, which triggered a transparency debate that is worth understanding — not for drama, but because model lineage affects what you can expect from the model's strengths, failure modes, and future availability.
Why lineage matters in practice: Models inherit characteristics from their base. If Kimi K2.5 has particular strengths in long-context reasoning and particular gaps in certain language ecosystems, those tendencies carry forward even after fine-tuning. When your team evaluates Composer 2 for a specific stack, run your own evals; don't assume vendor benchmarks cover your exact workload.

### Pricing

At $0.50/M input, Composer 2 is substantially more cost-efficient than frontier models like Opus 4.7 — check anthropic.com/pricing for current rates to compare directly. For teams running 50+ agent turns per day across large codebases, this is not a marginal difference. The community's actual reaction was not "this beats everything" — it was "this changes how often I'm willing to iterate."

## 1.2 Benchmark Literacy: Reading Numbers Without Being Misled

Cursor's technical report claims Composer 2 achieves 61.3 on CursorBench. VentureBeat reported it "beats Claude Opus 4.6 but still trails GPT-5.4." What does that mean for your team?

Almost nothing, taken at face value. Here is a two-layer reading framework the community has converged on:

### Layer 1: Directional signal

Benchmarks do tell you something. A model scoring 61.3 versus 45 on the same eval likely handles the evaluated task type better in the tested conditions. CursorBench is designed to test IDE-specific agentic tasks — file reads, multi-step edits, test runs — which is at least more relevant than generic coding competitions. Use benchmark rankings to form a prior, not a verdict.

### Layer 2: Local task evals as decision authority

Your codebase is not CursorBench. It has:
- Specific language versions and framework idioms
- Tribal knowledge encoded in existing code that no benchmark captures
- Test harnesses with particular failure modes
- Reviewer standards that are not in any eval rubric

The pattern experienced users have converged on: run Composer 2 on 10–20 representative tasks from your actual backlog before committing it as your primary model. Measure: correctness rate, number of follow-up prompts needed, test-pass rate on first attempt, and token spend per task completion.
Warning: "benchmaxxed" risk. Some benchmark improvements are achieved through prompt engineering on benchmark task formats rather than general capability gains. If a model's benchmark score rose sharply without a proportionally large training compute increase, it may be overfit to the eval distribution. Treat it like a suspiciously high A/B test — run your own experiment.

## 1.3 The Routing Rubric: When to Use Composer 2 vs. a Frontier Model

The strongest practical lesson from community usage threads is that advanced teams do not pick one model and stick with it. They route by task class.

Here is the rubric that emerges from synthesizing real usage reports:

### Use Composer 2 for:

- Short-to-medium iteration loops — feature additions, bug fixes, refactor passes in code you own and understand
- High-frequency experiments — parallel attempts ("try three approaches, I'll pick the best"), throwaway prototypes
- Routine generation tasks — CRUD endpoints, test cases, migration scripts for known schemas
- IDE-integrated edits — diff-reviewed changes where you are inspecting every hunk before accepting

### Escalate to a frontier reasoning model (Opus 4.7, GPT-5.4) for:

- Unfamiliar architecture — debugging a third-party library internals you've never seen
- Brittle refactors — changing a core abstraction that 40 files depend on and where failure mode is subtle
- Security-sensitive reasoning — auth flows, crypto implementations, permission model design
- Complex debugging across module boundaries — when the bug requires understanding state transitions across 5+ subsystems

The key signal for escalation: when you cannot predict what the right answer looks like, and a wrong answer might not be obviously wrong. In those cases, the extra cost of a frontier model buys you reasoning quality that reduces silent failure risk.
Hot tip: Build this routing rubric into your .cursorrules file as an explicit instruction. When Cursor is in Composer 2 mode and the model encounters something matching your escalation criteria, having a rule that says "flag this for human review before proceeding" can prevent expensive mistakes that look like successes until they hit production.

## 1.4 Auto Routing vs. Manual Model Pinning

Cursor's Auto model selection routes between available models based on task context. For new users, it is convenient. For production AI engineering workflows, it introduces unpredictable cost and quality variance.

When to trust Auto:
- Exploratory sessions where you haven't scoped the task
- Short one-off questions where cost doesn't matter
- When you don't yet have a routing rubric and want to observe which model Cursor selects

When to pin manually:
- Any session running more than 10–15 turns (cost governance)
- Parallel agent loops where you need consistent behavior for comparison
- Regulated environments where model selection must be auditable
- When onboarding a new team member and you want reproducible demos

To pin Composer 2 in Cursor: open the Composer panel, click the model dropdown in the top-right corner of the chat input area, and select cursor-composer-2 (or equivalent name per your version). Verify it sticks between sessions via Settings → AI → Default Model.

## 1.5 Setting Up the IDE Environment

Before configuring AI behavior, the physical IDE setup matters. Cursor inherits from VS Code; if you have existing VS Code settings, they carry over. Here is what to configure specifically for AI-assisted engineering:

### Workspace layout

- Open the root of the repository, not a subdirectory. Composer uses the workspace root to discover .cursorrules and to scope context-window crawls.
- Enable the file tree panel — Composer needs to be able to read the file structure to make sensible multi-file edits.
- Turn on inline diff mode: Settings → Editor → Diff: Inline Mode. This makes AI-generated changes visibly separated from your code, reducing accidental acceptance.

### Context window hygiene

Cursor's context window is not unlimited. Pasting large files, opening many tabs, and running long sessions all erode context quality. Three habits that help:

1. Use @file references explicitly rather than relying on open tabs being in context.
2. Close files you aren't actively editing. Cursor includes open buffers in context; 20 open tabs is 20 files of noise.
3. Start a new Composer session per task. Sessions accumulate context pollution. A new session per discrete task is cheaper and more reliable than one mega-session.

## 1.6 Configuring .cursorrules

.cursorrules is Cursor's project-level AI instruction file. It lives in the repository root and is loaded at the start of every Composer session. Think of it as a system prompt for your project.

A weak .cursorrules file looks like this:

These instructions are too vague to produce reliable behavior. A strong .cursorrules file is specific, constraint-based, and structured around what the model must not do as much as what it should do.

### Template: production-ready .cursorrules

This template is specific enough to produce consistent behavior. Adjust stack details for your project; preserve the constraint structure.
Info: .cursorrules is gitignored by default in some project templates. Make sure it is committed. Your entire team should share the same AI behavioral contract — having it in version control ensures this.

## 1.7 Setting Up AGENTS.md

AGENTS.md serves a different purpose than .cursorrules. Where .cursorrules governs code-writing behavior, AGENTS.md provides project context to any agent session: what the project is, how it is structured, who the active agents are, and how escalation is handled.

This file is especially important in multi-agent Cursor workflows, where a Background Agent (Cursor's long-running task execution mode) needs to understand the project without a live human in the loop.

### Template: minimal AGENTS.md

## RunPromptCell: Validating Your .cursorrules Setup
Try this in Cursor Composer now. Open a new Composer session (Cmd/Ctrl+Shift+L), paste the following prompt, and evaluate the response against your .cursorrules constraints:

Expected output pattern:
- The model should cite specific rules from your .cursorrules (explicit return types, no any, Vitest test requirement).
- It should note if any rule is relevant even if not violated.
- The generated function should have an explicit TypeScript return type, no any, and a co-located test file.

What to watch for:
- If the model ignores .cursorrules entirely, the file may not be in the context window. Check that it is in the project root and restart the session.
- If the model writes console.log in the test or uses any, your rules need stronger wording (add "Never use any" as a standalone line, not buried in a list).

## RunPromptCell: Model Routing Self-Test
Use this prompt to calibrate your routing rubric. Paste it into Composer with Composer 2 selected, then run the same prompt with your preferred frontier model. Compare the responses.

What to observe:
- Does Composer 2 give a concrete, prioritized hypothesis list, or does it give generic "check your connections" advice?
- Does the frontier model provide meaningfully different hypotheses, or is the output similar?
- Use this as your personal calibration data for "deep debugging across module boundaries" — if the outputs are comparable, Composer 2 is sufficient for this class of problem in your context.

## KnowledgeCheck 1: Model & Economics

Question 1 (MCQ): Cursor Composer 2 is fine-tuned on top of which base model?
- A) GPT-4o
- B) Claude Sonnet 4.6
- C) Kimi K2.5
- D) DeepSeek Coder V3

*Correct answer: C — Kimi K2.5, as identified through community analysis and corroborated by architectural comparison.*

Question 2 (MCQ): A developer runs 200M input tokens per month through Composer 2 at standard pricing. What is the monthly input token cost?
- A) $10
- B) $50
- C) $100
- D) $500

*Correct answer: C — 200M × $0.50/M = $100.*

Question 3 (free-form): A teammate argues "Composer 2 scores higher on CursorBench so we should always use it." Write a 2-sentence response explaining why this isn't sufficient justification for an exclusive model choice.

*Model answer: CursorBench is designed around Cursor's own evaluation conditions and may not reflect your team's actual codebase characteristics or task distribution. Benchmark scores are a useful prior, but routing decisions should be validated against your own representative tasks before committing to a single-model strategy.*

## KnowledgeCheck 2: Configuration & Workflow

Question 1 (MCQ): Which of the following belongs in .cursorrules rather than AGENTS.md?
- A) Project purpose and architecture overview
- B) Active agent list and escalation rules
- C) Forbidden patterns like "no raw SQL strings"
- D) Production branch naming conventions for agents

*Correct answer: C — .cursorrules governs code-writing constraints; AGENTS.md governs project context and multi-agent coordination.*

Question 2 (MCQ): When should you pin Composer 2 manually rather than using Auto model selection?
- A) Only during onboarding demos
- B) Any session running more than 10–15 turns, for cost governance and reproducibility
- C) Only when the task involves security-sensitive code
- D) Auto selection is always preferable for production work

*Correct answer: B.*

Question 3 (free-form): You are starting a new project and need to write a .cursorrules file. List three specific constraints you would include — not generic style advice, but constraints specific enough that an AI model could verifiably comply or fail.

*Example answers: "Use Vitest not Jest for all tests," "No any type — use unknown with narrowing," "All DB queries via Drizzle query builder, no raw SQL strings." Accept any three concrete, verifiable rules.*

## 1.8 Common Pitfalls and Anti-Patterns

### Anti-pattern: Vague .cursorrules

"Write clean, readable code" is not enforceable. The model cannot operationalize "clean." State the standard: "Max function length: 40 lines. Extract if longer." This is verifiable.

### Anti-pattern: One mega-session per day

Running 60+ turns in a single Composer session degrades output quality as the context window fills with earlier conversation turns. Start a new session per discrete task. The few seconds it takes to restart are worth it.

### Anti-pattern: Auto routing in production-critical sessions

Auto routing optimizes for Cursor's metrics, not yours. For any session where you need predictable behavior — demos, code that will be reviewed by a senior engineer, security-sensitive work — pin the model explicitly.

### Anti-pattern: No AGENTS.md in multi-agent workflows

If you use Cursor Background Agents or run any kind of parallel agent session, AGENTS.md is the document that tells an agent what the project is and what it must not do autonomously. Skipping it means the agent has no project context beyond whatever you include in each individual prompt.

### Anti-pattern: Treating benchmark superiority as task-specific superiority

Composer 2 outperforms some frontier models on CursorBench. That does not mean it outperforms them on your specific hard debugging task. Always calibrate on your workload.

## Hands-On Exercise: Project Foundation Setup

Objective: Configure a real project repository for AI-first development with Composer 2.

Time-box: 30 minutes.

Steps:

1. Create or open a project repository. If you don't have one, use any small existing side project or initialize a new TypeScript project with pnpm create next-app.

2. Write .cursorrules following the template in section 1.6. Customize at minimum: stack versions, 3+ specific forbidden patterns, test tool, and 2+ AI behavior instructions. Commit it.

3. Write AGENTS.md following the template in section 1.7. Fill in your project's real purpose, directory structure, and at least 2 escalation rules that reflect actual risk boundaries in your codebase. Commit it.

4. Validate with the RunPromptCell from section 1.5. Open a new Composer session pinned to Composer 2, run the formatDate.ts validation prompt, and check that the model's output complies with your specific rules.

5. Run the routing self-test from section 1.5. Compare Composer 2 vs. one frontier model on the 503 debugging prompt. Note which produced better hypotheses and why.

Success criteria:
- .cursorrules is committed to the repository root with at least 5 verifiable constraints.
- AGENTS.md is committed with at minimum: project purpose, directory map, and 2 escalation rules.
- Composer 2 session correctly references at least 2 of your specific .cursorrules constraints when given a coding task.
- You have personal calibration data from the routing self-test: a subjective note on whether Composer 2 or the frontier model gave a better response to the debugging prompt.

## What's Next

Chapter 1 established the foundation: you understand what Composer 2 is (and why the benchmark story is incomplete), you have a routing rubric, and your project repository is configured with .cursorrules and AGENTS.md.

Chapter 2: Mastering the Cursor Composer Interface builds directly on this. You will learn how to manage context windows efficiently as your project grows, how to use @file and @symbol references to stay precise in large codebases, and how to structure multi-turn Composer sessions that don't degrade as the conversation gets longer. The techniques in Chapter 2 only work well when you have the project foundation from Chapter 1 in place — so make sure the hands-on exercise is done before continuing.

## References

1. Cursor. "Composer 2 is now available in Cursor." cursor.com/blog/composer-2. Retrieved 2026-05-14.
2. Cursor. "Cursor Composer 2 Technical Report." cursor.com/blog/composer-2-technical-report/. Retrieved 2026-05-14.
3. Cursor. "Composer 2 Changelog." cursor.com/changelog/composer-2. Retrieved 2026-05-14.
4. arXiv. "Composer 2 CursorBench evaluation." arxiv.org/abs/2603.24477. Retrieved 2026-05-14.
5. HackerNews. "Cursor Composer 2 is just Kimi K2.5 with RL." news.ycombinator.com/item?id=47452404. Retrieved 2026-05-14.
6. Reddit r/cursor. "Composer 2 is now available in Cursor." reddit.com/r/cursor/comments/1ry5rgw. Retrieved 2026-05-14.
7. Reddit r/cursor. "Has anyone actually tested Composer 2 vs Claude?" reddit.com/r/cursor/comments/1ryb2jt. Retrieved 2026-05-14.
8. Render. "AI Coding Agents Benchmark." render.com/blog/ai-coding-agents-benchmark/. Retrieved 2026-05-14.
