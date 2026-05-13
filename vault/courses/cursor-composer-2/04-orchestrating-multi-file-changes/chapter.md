---
chapter_num: 4
title: "Orchestrating Multi-File Changes"
learning_objectives:
  - "Coordinate changes across database, service, and API layers"
  - "Maintain architectural integrity in large-scale refactors"
  - "Utilize Composer for project-wide structural updates"
  - "Manage atomicity in AI-assisted multi-file operations"
prerequisites_chapters: [1, 2, 3]
duration_min: 60
---

# Chapter 4: Orchestrating Multi-File Changes

Up until now, we’ve focused on generating code for new components. Now, we confront the "AI-Engineering Reality": most production features are not greenfield. They are modifications that ripple through your existing architecture.

In this chapter, we learn to use Cursor Composer 2 for complex, multi-layer orchestration.

## The Rippling Effect: Stack-Awareness

When you change a data model, you break the database layer (if using ORMs), the service layer (which transforms the models), and the API layer (which serializes them).

A naive agent breaks one layer at a time. A professional AI engineer orchestrates the cascade.

### Strategy: Layer-by-Layer Synchronization
1. **Model First**: Define the interface or entity changes.
2. **Persistence/DB**: Apply changes to schemas.
3. **Logic Cascade**: Propagate to services and APIs.

## Callout: The Fallacy of Simultaneity
<div class="callout callout-warn">
### Warning: The "Simultaneous Change" Anti-Pattern
Tempting as it is to prompt "Refresh all layers for this new user field," doing so in a single prompt often confuses the agent if the context is large. You are more likely to succeed by asking for sequential, layer-specific updates, trusting Cursor to track the changes in the edit buffer.
</div>

## Generating Coordinated Changes

To orchestrate effectively, maintain an open Composer session with *all* relevant layers (Model, Service, API) present in the context window.

### RunPromptCell: Coordinated Model Refactor
1. **Context**: Load `@UserEntity.ts`, `@UserService.ts`, and `@UserController.ts`.
2. **Prompt**: "Add an optional `phoneNumber` field to `UserEntity`. Propagation: 1. Update the entity. 2. Update service logic to include validation. 3. Reflect in API controller."

*Expected Output:* Cursor should sequentially propose edits to all three files, maintaining consistent data handling patterns across layers.

## KnowledgeCheck 1

1. Why is sequential layer propagation better than asking the agent to update all layers at once?
2. What role does the maintainance of "atomicity" play in large-scale orchestration?

## Hands-on Exercise: The Architectural Refactor

Time-box: 60 minutes.

**Goal**: Execute a cross-layer change (e.g., adding a pagination parameter to an API which ripples down to the service).

1. **Setup**: Identify an API endpoint that interacts with a service.
2. **Orchestration**: Use Composer to apply the parameter change downwards through the stack.
3. **Verification**: Compile and check if the interface contracts in the service/DB layers have been met.

**Success Criteria**: All layers are updated, types are consistent (no lint errors), and the change is verified by a smoke test.

## What's Next?
In Chapter 5, we shift to **Automated Refactoring & Modernization**. Once we know how to orchestrate *features*, we turn that power to *cleanup* and *modernizing* legacy code.
