---
chapter_num: 1
title: "Foundations — Cursor AI Environment & Rules"
learning_objectives:
  - "Configure .cursorrules for project-specific behavioral anchors"
  - "Establish project context using the context window correctly"
  - "Initialize AGENTS.md to define team-AI conventions"
  - "Set up a standard AI-engineering workspace"
prerequisites_chapters: []
duration_min: 45
---

# Chapter 1: Foundations — Cursor AI Environment & Rules

Welcome to Cursor Composer 2. If you are reading this, you likely already use Cursor for day-to-day coding. But there is a massive delta between "chatting with an AI to write a function" and "orchestrating an AI agent to build complex features across your entire codebase."

In this chapter, we will bridge that gap. We won't just write code; we will configure the environment to make Cursor your most disciplined teammate.

## The AI-Engineering Mindset

Mediocre AI usage treats the LLM like a helpful junior intern: you prompt, they output, you copy-paste.

Professional AI engineering treats the LLM like a highly skilled software engineer. This engineer needs:
1. **Context:** What are we building?
2. **Rules:** How do we write code here?
3. **Roles:** Who does what?

Without this framework, the AI wanders, repeats common patterns from general training sets (which might conflict with your specific architecture), and eventually produces "hallucinated" code structures that break your build.

## Configuring `.cursorrules`

The `.cursorrules` file is the project's behavioral anchor. It informs the AI about the specific stack, architectural patterns, and code-style nuances of your codebase.

### Example: A Robust `.cursorrules` Structure

```text
# Project Standards

- Language: TypeScript with strict mode (tsconfig enabled).
- Framework: Next.js 15 (App Router).
- CSS: Tailwind CSS with shadcn/ui components.
- State Management: React Query for server state, Zustand for global UI state.

# Architectural Patterns

- Always favor composition over inheritance.
- Prefer functional components over class components.
- Do not add dependencies without express approval in the PR.
- Use path aliases (@/components/*).

# Formatting

- Use Prettier with the provided .prettierrc.
- Ensure all exported components have JSDoc.
```

### KnowledgeCheck 1

1. Why is a `.cursorrules` file superior to adding style instructions to every individual prompt?
2. What are the potential risks of an empty or missing `.cursorrules` file in a codebase?

## Initializing `AGENTS.md`

`AGENTS.md` is our manifest for agentic behavior. It tells the agent "how to be an expert on this project."

While `.cursorrules` governs *how* the code is written, `AGENTS.md` governs *how the interaction flows*.

Create `AGENTS.md` in your project root:

```markdown
# AGENTS.md

## Developer Persona
You are a senior full-stack engineer. You favor simple, maintainable solutions over clever hacks.

## Interaction Patterns
- Before implementing features, suggest the architectural approach.
- If you find a bug in the code you are reading, point it out immediately.
- Use the project's existing testing utilities for any new component.
```

## RunPromptCell: Validating Rules

Run this experiment in your Cursor environment:

1. Create a file `src/test_agent.ts` with only a comment: `// Placeholder`
2. Open Cursor Composer (Cmd+I).
3. Type: "Create a simple React component that fetches data from an API and displays it, using current project standards."

*Expected output:* The agent should respect your path aliases, import styles, and state management rules defined in your `.cursorrules`.

## Hands-on Exercise: Workspace Setup

Time-box: 30 minutes.

**Goal**: Configure a dummy repository with the foundational files drafted above.

1. **Initialize**: Create a new directory and `git init`.
2. **Rules**: Create `.cursorrules` in the root. Fill it with at least 3 project-specific rules.
3. **Persona**: Create `AGENTS.md`.
4. **Verification**: Generate a dummy component and verify (inspect the imports and structure) that it adheres to your rules.

**Success Criteria**: The component matches your project import pattern (e.g., using `@/`) and follows your specified state architecture exactly.

## What's Next?
In Chapter 2, we will go deep into the Composer interface itself. Now that the agent knows *who it is* and *how it should code*, we will learn to drive it proficiently through the IDE's UI.
