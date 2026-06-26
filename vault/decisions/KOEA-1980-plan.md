---
ticket: KOEA-1990
parent_ticket: KOEA-1980
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
chain_alert_approval: 39b4e0e3-1e5a-4459-824f-c5db2488d7b6
---

# Plan: publish-action origin/master hard stop

## Goal

Prevent `scripts/publish-action.sh` from advancing any issue to `dispatching` or `published` unless the exact vault artifact being published is present on `origin/master`. Success means Phase 0 fails closed on non-canonical branches, dirty/unpushed state, failed pushes, missing artifact metadata, or local-vs-`origin/master` blob mismatch, while preserving the existing learnovaBeast repository_dispatch flow.

## Context

- Files to read first: `scripts/publish-action.sh:768-830`, `scripts/publish-action.sh:833-897`, `scripts/publish-action.sh:900-998`, `scripts/tests/publish-action-guard-logging.sh:19-131`
- Relevant prior work: KOEA-1969 / KOEA-1973 / current branch `koea-1987/publish-action-silent-exit-hardening` added terminal logging, authenticated curl helpers, parse guards, and dispatch ledger behavior. KOEA-1976 found local commit `a2974855` existed only on `koea-1615/publish-action-guard-logging`; KOEA-1748 was later cherry-picked to `origin/master` at `0a1f2b9b`.
- Constraints: fix is script-only in `koenig-ai-org`; no Paperclip schema/API change and no extra board approval beyond the existing plan-review/code-review/QA gates. Do not mutate learnovaBeast. Do not bypass the existing publish-verifier/G5 flow. Base branch verified with `git ls-remote --heads origin master`.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Add a fail-closed canonical sync gate around Phase 0, then verify each candidate artifact against `origin/master` immediately before Phase 1 dispatch and again before Phase 2 marks it `published`. Executor should introduce helpers in `scripts/publish-action.sh` that require the runtime branch to be `master`, fetch `origin/master`, commit/push vault changes only to `origin/master`, confirm the tracked worktree is clean after Phase 0, resolve the issue artifact from `metadata.draft_path` or `metadata.slug`, and compare the local artifact blob with `origin/master:<path>`. Any failure logs a specific guard reason and skips metadata advancement for that issue.

**Rejected**: Only change `git push origin "$CURRENT_BRANCH"` to `git push origin master` because the script could still continue after non-fast-forward failures or from a dirty feature branch. Rejected: rely on learnovaBeast/G5 to catch 404s because Phase 1/2 metadata has already advanced by then. Rejected: rewrite the publisher in another language because KOEA-1969 already hardened the shell script and this ticket is a narrow safety gate.

## Steps (Executor follows in order)

1. Update `scripts/publish-action.sh` near Phase 0 to define `PUBLISH_CANONICAL_REMOTE="${PUBLISH_CANONICAL_REMOTE:-origin}"`, `PUBLISH_CANONICAL_BRANCH="${PUBLISH_CANONICAL_BRANCH:-master}"`, and a helper that logs and returns false unless `git branch --show-current` equals the canonical branch.
2. Change Phase 0 so a commit push failure, branch mismatch, failed `git fetch origin master`, local `HEAD` not matching `origin/master` after push/no-op, or non-clean tracked worktree sets a fail-closed `PHASE0_SYNC_OK=0` and prevents Phase 1 and Phase 2 from mutating issue metadata.
3. Extend Phase 1 issue extraction to retain existing metadata needed to resolve artifacts; do not default slug to issue id. If `metadata.slug`/`metadata.draft_path` cannot resolve to an existing `vault/blogs/<slug>/draft.md`, `vault/courses/...` path, or explicit draft path, log `origin-master-guard: BLOCK issue=<id> reason=missing-artifact-path` and skip dispatch.
4. Add an `artifact_on_origin_master_matches` helper that fetches the canonical ref and compares the local artifact blob SHA to `origin/master:<artifact_path>`; call it before repository_dispatch, before setting `publish_state=dispatching`, and before setting `publish_state=published`.
5. Preserve issue metadata when patching publish-state transitions by merging with the current metadata payload or by sending only fields through an API path proven to merge; this prevents `slug`/`draft_path` loss during `dispatching` and `published` updates.
6. Extend `scripts/tests/publish-action-guard-logging.sh` or add one sibling fixture to simulate branch mismatch, push failure, missing slug/path, and blob mismatch; assert no GitHub dispatch, no Paperclip `publish_state=dispatching|published` PATCH, sanitized guard logs, and terminal completion/failure logging.
7. Run `bash scripts/tests/publish-action-guard-logging.sh` and `bash -n scripts/publish-action.sh scripts/tests/publish-action-guard-logging.sh`.

## Verification (QA Verifier checks these)

- [ ] Running on any branch other than `master` logs a canonical-branch guard block and does not call repository_dispatch or patch `publish_state`.
- [ ] A Phase 0 non-fast-forward push failure blocks Phase 1 and Phase 2 metadata advancement for all publish candidates.
- [ ] A candidate with missing `metadata.slug`/`metadata.draft_path` is skipped with a clear guard log and is not default-dispatched using the issue id as slug.
- [ ] A candidate whose local artifact differs from `origin/master:<artifact_path>` is not dispatched and cannot be marked `published` after a successful GH Actions run.
- [ ] A valid candidate on clean `master` with a matching artifact on `origin/master` still dispatches to learnovaBeast and later triggers publish-verifier after a successful run.

## Risk

- Strict branch/clean-worktree gating can pause publishing if launchd is pointed at a feature branch or if unrelated tracked files are dirty; mitigate with explicit log messages naming the branch/status blocker and keep untracked files out of the clean check unless Executor confirms launchd can tolerate a stricter policy.

## Out of scope

- Repairing the already-published KOEA-1748 live route, changing learnovaBeast GitHub Actions, replacing launchd, or redesigning Paperclip issue metadata semantics outside the publish-action script.

Pre-flight: status=active assignee=planner sibling-chain-alert-approved=39b4e0e3-1e5a-4459-824f-c5db2488d7b6 basebranch_verified=true acceptance_criteria_source=issue-description
