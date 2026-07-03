---
ticket: KOEA-9955
planner: planner
date: 2026-07-02
estimated_complexity: medium
estimated_token_cost: "$0.45"
base_branch: academy/redesign-v1
basebranch_verified: true
executor_workspace: /paperclip/instances/default/workspaces/learnovaBeast-KOEA-9955
executor_branch: koea-9955/openai-model-deprecation-audit
---

# Plan: Audit Academy runtime for OpenAI July 23 deprecated model IDs

## Goal
Determine whether the organic Koenig AI Academy runtime, course rendering path, tutor surface, examples, or vault-fed course/blog corpus contain OpenAI API model IDs scheduled for the July 23, 2026 Wave 1 shutdown. Success is an audit verdict with exact commands, paths, and hit classification; code changes are only dispatched if an Engineering-owned runtime reference is found.

## Context
- Files to read first: `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-9955/CLAUDE.md:1-76`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-9955/learnova-academy/CLAUDE.md:1-88`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-9955/learnova-academy/README.md:1-127`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-9955/learnova-academy/src/app/api/tutor/route.ts:1-204`
- Relevant prior work: current branch head `c7f36da1` mirrors `origin/academy/redesign-v1`; prior commit `618b9e0f` changed Nova tutor model compatibility.
- Constraints: use `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-9955` only; respect `.claude/agent-lock`; do not use `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`; keep scope to OpenAI Wave 1 July 23, 2026 shutdown IDs, not Wave 2 October 23 cleanup.
- Lock handoff: Planner's read-only planning lock has been released for execution. Executor may proceed when `.claude/agent-lock` says `owner: executor` and `phase: execution-audit-ready`; stop only if the lock names a different active owner or an incompatible phase.
- Fact source to verify at audit time: official OpenAI API deprecations page, `https://developers.openai.com/api/docs/deprecations`, specifically the 2026-04-22 legacy snapshot table.
- Planning note: the ticket explicitly asks searches to include `gpt-4o-audio-preview-2024-12-17`; current official OpenAI docs place that exact model in a prior May 7, 2026 shutdown section, not the July 23 table. Executor must still search it as a required reconciliation term and call out the date mismatch if the official page remains unchanged.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Evidence-first grep audit with hit classification. Executor should first verify the official OpenAI July 23 list, then run exact-ID and family searches across the Academy app plus vault content that feeds Academy, excluding dependency/build artifacts. Each hit is classified as Engineering-owned runtime/config, course/content/example, generated artifact, or unrelated portal. This produces a defensible verdict without changing runtime code prematurely.

**Rejected**: Immediate model-string replacement sweep - unsafe because most likely hits may be course prose, examples, screenshots, or non-Academy content; Full monorepo refactor - too broad for the ticket and risks touching student/TC/admin/sales surfaces outside organic Academy.

## Steps (Executor follows in order)
1. Confirm workspace, branch, and lock handoff with `cd /paperclip/instances/default/workspaces/learnovaBeast-KOEA-9955 && git status --short && git branch --show-current && nl -ba .claude/agent-lock`; proceed only on branch `koea-9955/openai-model-deprecation-audit` with `.claude/agent-lock` showing `owner: executor` and `phase: execution-audit-ready`, and stop if the lock names any other active owner.
2. Re-verify the Wave 1 July 23, 2026 shutdown scope from the official OpenAI deprecations page, then use this exact July 23 audit set unless the official page changed: `computer-use-preview-2025-03-11`, `gpt-4o-mini-search-preview-2025-03-11`, `gpt-4o-mini-tts-2025-03-20`, `gpt-4o-search-preview-2025-03-11`, `gpt-5-chat-latest`, `gpt-5-codex`, `gpt-5.1-chat-latest`, `gpt-5.1-codex`, `gpt-5.1-codex-max`, `gpt-5.1-codex-mini`, `gpt-audio-mini-2025-10-06`, `gpt-realtime-mini-2025-10-06`, `o3-deep-research-2025-06-26`, `o4-mini-deep-research-2025-06-26`, `gpt-5.2-codex`. Also search ticket-required reconciliation terms `gpt-4o-audio-preview-2024-12-17`, `gpt-4o-mini-audio-preview`, and `gpt-4o-mini-realtime-preview`, but label them by their official shutdown date.
3. Run exact recursive searches from the workspace root, excluding `node_modules`, `.next`, `dist`, `build`, lockfiles, and binary media; include `learnova-academy/src`, `learnova-academy/scripts`, `learnova-academy/public` text files, `learnova-academy/README.md`, `learnova-academy/package.json`, and `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/{courses,blogs}` because Academy reads vault content at build time.
4. Run broader family searches for `computer-use-preview`, `gpt-4o-audio-preview`, `gpt-4o-mini.*(audio|realtime|search|tts)`, `gpt-5`, `gpt-5.1`, `gpt-5.2`, `o3.*deep-research`, and `o4.*deep-research`; inspect nearby lines for prompt/config/runtime use rather than counting raw matches.
5. Inspect the high-risk Academy surfaces directly even if grep is empty: `learnova-academy/src/app/api/tutor/route.ts`, `learnova-academy/src/components/_shared/tutor.tsx`, `learnova-academy/src/components/_shared/content.tsx`, `learnova-academy/src/lib/courses.ts`, `learnova-academy/src/lib/fixtures.ts`, `learnova-academy/src/lib/vault.ts`, `learnova-academy/scripts/sync-vault.mjs`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx`, `learnova-academy/src/app/(site)/learn/[slug]/[chapterSlug]/page.tsx`, `learnova-academy/src/app/llms-full.txt/route.ts`, and `learnova-academy/src/app/api/asset/route.ts`.
6. Comment the audit verdict on KOEA-9955 with commands run, exact hits, and classification. If no Engineering-owned references exist, hand remaining course/content cleanup back to Chief Content; if runtime/code references exist, create or request the proper Executor implementation chain with G_code and G2 review gates before changing production code.

## Verification (QA Verifier checks these)
- [ ] The KOEA-9955 verdict includes the official OpenAI deprecations URL and the exact July 23, 2026 ID list used.
- [ ] The verdict includes the exact `rg` commands or equivalent command transcript and covers both `learnova-academy` code/runtime surfaces and Academy-fed vault content.
- [ ] Every hit is classified as runtime/config, course/content/example, generated artifact, unrelated portal, or false positive, with file paths and line references.
- [ ] If code/runtime hits exist, a follow-up implementation issue with G_code and G2 gates exists; if none exist, the comment explicitly hands content-only work back to Chief Content.

## Risk
- Broad model-family searches can produce noisy matches in generated screenshots, lockfiles, or course prose; mitigate by excluding generated/dependency artifacts for the primary audit and separately classifying any remaining non-runtime hits.

## Out of scope
- Replacing model IDs, editing prompts, changing tutor providers, auditing Career Compass, or handling OpenAI Wave 2 October 23 deprecations.

Preflight: status_checked=true; sibling_check_passed=true; acceptance_scope_checked=true; basebranch_verified=true.
