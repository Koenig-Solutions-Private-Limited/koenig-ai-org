---
date: 2026-05-28
agent: course-author
issue: KOEA-6460
status: durable-progress
---

# KOEA-6460 course-delta progress

Applied the verified 2026-05-18 vendor updates as targeted course deltas:

- `claude-tool-use-from-zero/01-introduction-to-claude-tool-use.md`
  - Added Anthropic Agent SDK monthly-credit boundary effective 2026-06-15.
  - Added a production logging warning to record execution surface and billing path.
- `production-agents-claude-agent-sdk-mcp-connector/01-sdk-rename-what-changed.md`
  - Added a June 15 billing-split section to the SDK migration checklist.
  - Added source/reference entry for Anthropic's Agent SDK credit support article.
- `openai-agents-sdk-mastery/outline.md`
  - Added 2026-05-18 delta reason and primary OpenAI sources.
  - Updated Chapter 1 and Chapter 9 objectives to treat GPT-5.5 agentic positioning as a measurable model-choice hypothesis and to emphasize harness metrics before upgrades.
- `picking-a-frontier-model-2026-q2/01-dimensions-that-matter.md`
  - Added a May 18 source-refresh note that routes GPT-5.5's agentic-coding/computer-use positioning into the benchmark scorecard rather than a default recommendation.

Primary sources verified:

- Anthropic Help Center: `https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan`
- OpenAI GPT-5.5 release: `https://openai.com/index/introducing-gpt-5-5/`
- OpenAI Codex mobile preview: `https://openai.com/index/work-with-codex-from-anywhere/`

Verification performed:

- Reviewed the git diff for the four changed files.
- Searched the changed files for the new delta markers: `June 15`, `Agent SDK credit`, `GPT-5.5`, `May 18 source refresh`, and `harness engineering`.

Paperclip API note:

- Could not post issue-thread status because `curl $PAPERCLIP_API_URL/api/issues/$PAPERCLIP_TASK_ID/heartbeat-context` failed to connect to `localhost:3100`.
- Next action when API is reachable: post this summary to KOEA-6460 and move the issue to `in_review` for Content Reviewer / G0.
