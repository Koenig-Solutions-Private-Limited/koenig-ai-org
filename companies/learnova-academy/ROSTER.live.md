# Live agent roster (generated — do not hand-edit)

Regenerate: `./scripts/roster-snapshot.sh`. Verify: `./scripts/roster-snapshot.sh --check`.
The DB is the runtime source of truth; this file makes it reviewable in git.

| Agent | Status | Adapter | Model | Reports to | Heartbeat |
|---|---|---|---|---|---|
| Blog Author | running | codex_local | gpt-5.5 | Chief Content | */15 * * * * |
| CEO | idle | codex_local | gpt-5.5 | - | enabled |
| Chief Content | idle | codex_local | gpt-5.5 | CEO | enabled |
| Chief Engineering | idle | codex_local | gpt-5.5 | CEO | enabled |
| Chief Learning | idle | codex_local | gpt-5.5 | CEO | - |
| Chief Marketing/SEO | idle | claude_local | claude-fable-5 | CEO | enabled |
| Chief Research | idle | codex_local | gpt-5.5 | CEO | enabled |
| Code Reviewer | idle | codex_local | gpt-5.5 | Chief Engineering | enabled |
| Content Author | running | claude_local | claude-sonnet-4-6 | Chief Content | */15 * * * * |
| Content Reviewer | running | claude_local | claude-sonnet-4-6 | Chief Content | enabled |
| Course Architect | idle | codex_local | gpt-5.5 | Chief Content | */15 * * * * |
| Distribution Writer | running | codex_local | gpt-5.4 | CEO | enabled |
| Editor in Chief | idle | codex_local | gpt-5.5 | CEO | */30 * * * * |
| Engineering Triage Officer | idle | claude_local | claude-sonnet-4-6 | Chief Engineering | enabled |
| Executor | running | claude_local | claude-sonnet-4-6 | Chief Engineering | enabled |
| Growth Lead | running | claude_local | claude-sonnet-4-6 | CEO | enabled |
| Meeting Attendee | idle | claude_local | claude-sonnet-4-6 | CEO | - |
| Meeting Follower | idle | claude_local | claude-haiku-4-5 | CEO | - |
| Planner | idle | codex_local | gpt-5.5 | Chief Engineering | enabled |
| Publish Verifier | idle | claude_local | claude-sonnet-4-6 | CEO | enabled |
| QA Verifier | idle | codex_local | gpt-5.5 | Chief Engineering | */30 * * * * |
| Research Editor | idle | opencode_local | openai/gpt-5.2 | Chief Research | */15 * * * * |
| Researcher · Anthropic | idle | codex_local | gpt-5.4-mini | Chief Research | */15 * * * * |
| Researcher · Community | idle | codex_local | gpt-5.4-mini | Chief Research | */15 * * * * |
| Researcher · Google | idle | codex_local | gpt-5.4-mini | Chief Research | */15 * * * * |
| Researcher · OpenAI | idle | codex_local | gpt-5.4-mini | Chief Research | */15 * * * * |
| Search Visibility Optimizer | idle | claude_local | claude-sonnet-4-6 | Chief Marketing/SEO | enabled |
| Slide + Audio Producer | idle | codex_local | gpt-5.4 | Chief Content | enabled |
| Triage Agent | paused | claude_local | claude-sonnet-4-6 | CEO | */30 * * * * |
| Vault Historian | idle | codex_local | gpt-5.4 | CEO | 30 * * * * |
| Voice Producer | paused | opencode_local | openrouter/deepseek/deepseek-v4-flash | Chief Content | - |
| Watchdog Bot | idle | claude_local | claude-haiku-4-5-20251001 | CEO | */30 * * * * |
| chapter-author-1 | running | claude_local | claude-sonnet-4-6 | Chief Learning | - |
| chapter-author-2 | running | claude_local | claude-sonnet-4-6 | Chief Learning | - |
| chapter-author-3 | running | claude_local | claude-sonnet-4-6 | Chief Learning | - |
| domain-researcher | idle | claude_local | claude-sonnet-4-6 | Chief Learning | - |
