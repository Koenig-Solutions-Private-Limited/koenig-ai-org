---
ticket: KOEA-6993
planner: planner
date: 2026-06-10
estimated_complexity: medium
estimated_token_cost: $0.28
base_branch: master
basebranch_verified: true
---

# Plan: gate Content Reviewer wake on master vault freshness

## Goal

Prevent Content Reviewer re-review wakes from firing when a blog revision child issue is marked done but the canonical `vault/blogs/<slug>/draft.md` on `origin/master` does not yet include the revision. Success means stale or unverifiable blog-fix completion leaves the parent blocked with a clear unblock action, while ordinary child-completion wakes and legitimate fresh re-review wakes still work.

## Context

- Files to read first: `server/src/routes/issues.ts:2512-2709`, `server/src/services/issues.ts:2556-2621`, `server/src/__tests__/issue-dependency-wakeups-routes.test.ts:178-266`, `server/src/__tests__/issues-service.test.ts:1912-1977`, `packages/adapter-utils/src/server-utils.ts:531-748`, `server/src/services/heartbeat.ts:1724-1738`.
- Relevant prior work: KOEA-6947 showed the failure mode on a blog draft (`vault/blogs/2026-05-31-local-model-benchmarks-lie-agent-trace-evaluation/draft.md`); KOEA-1980 established the same `origin/master` artifact-guard pattern for publish-action metadata advancement.
- Constraints: this is a Paperclip core server change, not a Learnova portal change. It must stay company-scoped through issue lookups, avoid hardcoded one-off ticket ids, and avoid polling. Base branch verified with `git ls-remote --heads origin master`.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Add a narrow artifact-freshness guard inside the existing child-completion wake boundary. When a direct child becomes terminal and `getWakeableParentAfterChildCompletion()` says the parent is wakeable, the route should evaluate a content-review gate only for blog revision/re-review cases with a resolvable vault artifact. The gate passes if the canonical `origin/master:<draft_path>` frontmatter has `last_updated >= completed child createdAt` or if the child-provided commit SHA is an ancestor of `origin/master`. If the gate fails or required metadata is missing for a blog review/revision pair, do not enqueue `issue_children_completed`; instead update the parent to `blocked` with metadata/comment naming the stale or missing canonical path and the unblock action.

**Rejected**: Add a separate Content Reviewer workflow runner because the bad wake is emitted by the generic issue update route and a second runner would race it. Rejected: make every child-completion wake check git because most parent/child trees have no vault artifact and broad git probes would add latency/noise. Rejected: rely on Content Reviewer instructions to self-check freshness because the wake has already consumed a reviewer heartbeat by then.

## Steps (Executor follows in order)

1. Extend `server/src/services/issues.ts` child-completion data so `getWakeableParentAfterChildCompletion()` returns enough gated context: parent title/status/metadata, parent assignee agent name or role, each direct child's `createdAt`/metadata, and the completed child id passed from the route.
2. Add a small server helper near the issue route or issue service, scoped to blog re-review/revision cases, that resolves `draft_path` from child metadata first, then parent metadata, then `metadata.slug -> vault/blogs/<slug>/draft.md`; resolve commit SHA from child metadata keys such as `commit_sha`, `commitSha`, or `master_commit_sha`.
3. Implement the freshness check with one fetch/read cycle: `git fetch origin master` best-effort with timeout, parse `origin/master:<draft_path>` frontmatter for `last_updated`, and separately allow `git merge-base --is-ancestor <commit_sha> origin/master` to pass when a commit SHA is provided.
4. In `server/src/routes/issues.ts:2672-2701`, call the helper before `addWakeup()` for `issue_children_completed`; when blocked, skip the wake and patch the parent to `blocked` with merged metadata (`unblock_owner`, `unblock_action`, `artifact_freshness_status`, `completed_child_issue_id`, `draft_path`) plus a concise comment.
5. Add route/service tests covering: fresh `last_updated` passes and wakes, stale `last_updated` blocks and does not wake, commit SHA on `origin/master` passes, missing metadata on a blog review/revision pair blocks, and non-blog child-completion behavior remains unchanged.
6. Run `pnpm vitest run server/src/__tests__/issue-dependency-wakeups-routes.test.ts server/src/__tests__/issues-service.test.ts` plus the smallest new helper test file if Executor splits the git/frontmatter helper out.

## Verification (QA Verifier checks these)

- [ ] Completing a blog-fix child whose canonical `origin/master` draft has `last_updated` newer than or equal to the child `createdAt` still queues one `issue_children_completed` wake for the parent assignee.
- [ ] Completing a blog-fix child whose canonical draft is missing, stale, or lacks both usable `last_updated` and a commit SHA leaves the parent `blocked` with an unblock comment and queues no Content Reviewer wake.
- [ ] Completing an unrelated non-blog child tree still wakes the parent exactly as the current route-level test expects.
- [ ] The gate performs a single bounded git/frontmatter check during the status update path and does not introduce polling or Learnova app changes.

## Risk

- The gate could suppress a legitimate reviewer wake if artifact metadata is incomplete. Mitigate by applying fail-closed behavior only to blog review/revision-shaped issues and making the blocker comment tell the author/owner exactly which `draft_path`, `last_updated`, or commit SHA is needed to resume.

## Out of scope

- Changing Learnova rendering, publish-action dispatch, Content Reviewer rubric text, or historical KOEA-6947 content state.

Pre-flight: status=active assignee=planner sibling_count=0 chain_depth=2 basebranch_verified=true acceptance_criteria_source=issue-description
