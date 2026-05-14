# Watchdog Bot Operations Note

## slide-fake-done-auditor contract

- Candidate selection:
  - Audit `done` `[SLIDES]` issues where `metadata.fake_done_audited != true`.
  - Recovery-check `blocked`/`reverted` `[SLIDES]` issues only when `metadata.fake_done_audited == true`.
- Artifact discovery order:
  - `/paperclip/tmp/koea1551/koenig-ai-org/vault/courses/<slug>`
  - `/paperclip/instances/default/workspaces/koenig-ai-org-*/vault/courses/<slug>`
  - `/paperclip/instances/default/workspaces/learnovaBeast-*/learnova-academy/public/courses/<slug>`
  - Match `${chNN}-slides*.pptx` with file size `>1000` bytes.
- Recovery path:
  - Never mutate source issue status/metadata directly.
  - Never use `PATCH /api/issues/<source>` or direct DB mutation for source ticket repair.
  - Open/update a single idempotent recovery issue:
    - `[Recovery] Restore <identifier> after slide artifact found`
    - `[Recovery] Verify missing slide artifact for <identifier>`
  - Assign to source assignee if resolvable, else Chief Engineering.
- Idempotency:
  - Reuse active recovery issues (`todo`, `in_progress`, `in_review`, `blocked`) by deterministic title.
  - Append new artifact evidence as comments instead of opening duplicates.
