---
chapter_num: 3
title: "Context-Aware Code Generation"
learning_objectives:
  - "Implement multi-file code generation strategies"
  - "Ensure architectural consistency during feature addition"
  - "Manage project-level dependencies and modules"
  - "Avoid hallucination through effective contextual grounding"
prerequisites_chapters: [1, 2]
duration_min: 60
---

# Chapter 3: Context-Aware Code Generation

In Chapter 2, we mastered the UI. In this chapter, we apply that proficiency to what matters most: **shipping features**. We will explore how to leverage Cursor's deep semantic awareness to generate coherent, multi-file code that respects your existing architectural reality.

## The Semantic Context Engine

When you prompt Composer to "create a new feature," it isn't just looking at the files you added to the context window. It is querying a semantic index of your entire codebase to understand relationships—imports, class structures, and function usage patterns.

### Grounding Principles
- **Explicit vs. Implicit**: The agent performs best when provided with an "anchor" (a local base class, related interface, or existing API implementation).
- **Module Scoping**: Don't force the AI to span the entire project if you are working on a scoped module. Use `@` to target folders containing only the relevant subsystem.

## RunPromptCell: The Anchor-Based Generation Pattern

1. **Setup**: Have an existing `OrderService` module.
2. **Action**: Open Composer (`Cmd+I`).
3. **Prompt**: "Using the patterns established in `@order_service.ts`, implement a `PaymentGateway` that returns an object of type `PaymentResponse` (define this in `types.ts`)."

*Expected Output:* The agent should read `@order_service.ts` to mirror the error handling and service structure, then locate `types.ts` to correctly define the interface, ensuring cross-file consistency without manual guidance.

## Handling Multi-File Complexity

The most challenging task for an AI engineer is generating updates that cross module boundaries without introducing breakage.

<div class="callout callout-warn">
### Warning: The "Ghost Dependency" Trap
When generating code across folders, AI agents can sometimes reference non-existent modules if the context window is too broad. Always specify the import path explicitly in your prompt if the module is deep in the tree or recently created.
</div>

### KnowledgeCheck 1

1. Why should you use an "anchor file" when asking an AI to generate a new module?
2. What are the signs that your context window is over-burdened resulting in degraded code quality?

## Hands-on Exercise: Feature Scoping

Time-box: 45 minutes.

**Goal**: Implement a new business-logic component grounding it on existing code.

1. **Target**: Identify an existing logic layer (Service or Component).
2. **Context**: Open Composer, add only the target file and the root `types` directory.
3. **Generation**: Implement a new related feature (e.g., if you have `UserAuthentication`, implement `UserSessionTracking`).
4. **Verification**: Confirm that imports match project standards and no redundant logic was generated.

**Success Criteria**: The component is generated without manual import fixing, follows project-specific error handling found in the anchor file, and compiles successfully.

## What's Next?
In Chapter 4, we will move to **Orchestrating Multi-File Changes**. Now that you can generate individual modules, we will learn how to make the agent coordinate changes across the *entire* stack (Database, Service, and API layers) in a single workflow.
