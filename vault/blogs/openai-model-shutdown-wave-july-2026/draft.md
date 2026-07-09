---
date: 2026-07-07
title: "Migrate OpenAI Model IDs Before the July 2026 Shutdown Wave"
slug: openai-model-shutdown-wave-july-2026
author: blog-author
ticket: KOEA-10295
vendor_tag: openai
content_type: article
status: awaiting-g0
reading_time_min: 6
tags:
  - openai
  - model-deprecations
  - migration
  - production-ai
description: "Audit OpenAI model IDs before the July and October 2026 shutdown waves, including hidden fallbacks, fine-tuned bases, and computer-use replacements."
primary_query: "openai model shutdown July 2026 migration guide"
contrarian_angle: "The July wave is not the hardest outage risk; October's legacy-family shutdown exposes hidden fallbacks, fine-tunes, and stale routing configs."
first_60_words_answer: "OpenAI's July 23, 2026 model shutdown removes dated preview snapshots for computer use, Codex, search, audio, realtime, TTS, and deep research. The immediate migration is mostly snapshot replacement. The larger outage risk is October 23, 2026, when `gpt-3.5-turbo`, `gpt-4`, `gpt-4-turbo`, `o1`, `o3-mini`, `o4-mini`, `gpt-image-1`, and related fine-tuned models shut down."
positions:
  - id: stance:ai-vendor-news-opinionated
    engagement: defends
  - id: stance:harness-over-model
    engagement: defends
  - id: benchmark-theater-vs-agent-trace-evaluation
    engagement: neutral
faq:
  - question: "Which OpenAI models shut down on July 23, 2026?"
    answer: "OpenAI's July 23, 2026 wave shuts down dated preview snapshots across computer use, search, TTS, realtime, audio, Codex, chat-latest, and deep-research families. The official deprecations page lists `computer-use-preview-2025-03-11`, `gpt-5-codex`, `gpt-5.1-codex*`, `gpt-audio-mini-2025-10-06`, `gpt-realtime-mini-2025-10-06`, and deep-research snapshots. Source: https://developers.openai.com/api/docs/deprecations"
  - question: "Is computer-use-preview removed with no replacement?"
    answer: "No. The dated `computer-use-preview-2025-03-11` snapshot is shutting down, but the functional replacement is `gpt-5.4-mini` or `gpt-5.4` through the Responses API. OpenAI's GPT-5.4 mini model page lists computer use as supported, so frame this as a model migration, not a capability removal. Source: https://developers.openai.com/api/docs/models/gpt-5.4-mini"
  - question: "What is the biggest October 23, 2026 OpenAI migration risk?"
    answer: "The biggest October 23 risk is not the obvious `gpt-4` call in application code. It is the hidden fallback: old routing rules, exception handlers, eval scripts, fine-tuned model IDs, and cost-saving paths that silently fall back to `gpt-3.5-turbo`, `o3-mini`, `o4-mini`, or old `ft-*` bases. These will fail unless audited before the cutoff. Source: https://developers.openai.com/api/docs/deprecations"
original_data: false
last_updated: 2026-07-09
hero_image:
  url: /img/blogs/openai-model-shutdown-wave-july-2026/hero.png
  alt: "OpenAI model migration calendar showing July 23 and October 23 2026 shutdown waves with replacement model routes"
whats_new:
  - "OpenAI's July 23 shutdown is the warning shot; October 23 is where hidden fallbacks and fine-tuned legacy models break production."
learning_objectives:
  - "Map the July 23 and October 23 OpenAI shutdown waves to practical replacement model IDs."
  - "Audit production repos for hidden legacy fallbacks and fine-tuned base-model dependencies."
  - "Migrate computer-use workloads without repeating the incorrect no-replacement framing."
sources:
  - https://developers.openai.com/api/docs/deprecations
  - https://developers.openai.com/api/docs/models/gpt-5.4-mini
  - https://community.openai.com/t/deprecation-notice-upcoming-model-shutdowns-in-2026/1379553
  - https://community.openai.com/t/is-computer-use-preview-retiring-with-no-replacement/1368785
  - https://community.openai.com/t/assistants-api-beta-deprecation-august-26-2026-sunset/1354666
  - https://aiweekly.co/alerts/openai-deprecates-three-image-apis-by-december-2026
---

# Migrate OpenAI Model IDs Before the July 2026 Shutdown Wave

OpenAI's July 23, 2026 model shutdown removes preview snapshots for computer use, Codex, search, audio, realtime, TTS, and deep research. The immediate migration is mostly snapshot replacement. The larger outage risk is October 23, 2026, when `gpt-3.5-turbo`, `gpt-4`, `gpt-4-turbo`, `o1`, `o3-mini`, `o4-mini`, `gpt-image-1`, and related fine-tuned models shut down.[1]

The thing most teams will miss: July 23 is not the worst migration. It is the rehearsal. The July list is noisy because it includes recent-sounding model IDs such as `gpt-5.1-codex` and `gpt-5.2-codex`, but October is where hidden fallbacks break production. If your retry path still says "fall back to `gpt-3.5-turbo`," your primary model can be healthy while your incident handler returns 404s.[1][3]

![Migration calendar for OpenAI July and October 2026 model shutdowns](/img/blogs/openai-model-shutdown-wave-july-2026/hero.png)

## Treat July 23 as a Snapshot Cleanup, Not a Full Platform Rewrite

The July 23 wave shuts down dated snapshots, not every capability in those families. OpenAI's deprecations page lists `computer-use-preview-2025-03-11`, search and TTS preview snapshots, `gpt-audio-mini-2025-10-06`, `gpt-realtime-mini-2025-10-06`, multiple `gpt-5.x-codex` IDs, and deep-research snapshots including `o3-deep-research-2025-06-26` and `o4-mini-deep-research-2025-06-26`.[1]

That means the first audit is mechanical: find exact model strings, map each to the listed substitute, and run regression tests on prompts where model behavior matters. Do not rely on model age as a proxy for safety. The community reaction called the list unusually large, and one developer pointed out that `gpt-4-1106-preview` appears again even though it had already been listed in an earlier wave.[3] The operational lesson is simple: the deprecations page, not release recency, is the source of truth.

For most teams, July's riskiest categories are realtime/audio and Codex-like coding agents. Audio migrations need latency and voice-quality checks. Coding-agent migrations need trace-level evals: run the same repository tasks before and after the model change, then compare patch quality, tool-call count, latency, and cost. If your team does not already have this vocabulary, start with [[glossary/agent-evaluation]] before treating the replacement model as equivalent.

## Replace Computer-Use Preview with GPT-5.4 Mini, Not a No-Replacement Panic

The accurate computer-use migration is: `computer-use-preview-2025-03-11` goes away, but computer-use capability does not. The synthesis and OpenAI model docs point to `gpt-5.4-mini` as the functional replacement, and the GPT-5.4 mini model page lists computer use as supported under Responses API tools.[2]

This distinction matters because developers have been reading the deprecation table as circular: the snapshot is deprecated, the alias appears in the transition path, and the long-term substitute is easy to miss. The community thread asking whether computer use was retiring with no replacement captures that confusion.[4] The safer migration rule is: stop depending on the dated preview snapshot, move screen-control workflows to `gpt-5.4-mini` or `gpt-5.4`, keep the Responses API computer-use tool declaration, and re-run your browser or desktop task harness. Computer-use agents are sensitive to screenshot cadence, tool-call budget, coordinate precision, and recovery behavior after bad clicks.

## Audit October 23 for Hidden Legacy Fallbacks and Fine-Tunes

The October 23 wave is the larger production risk because it removes the model families many teams still treat as durable defaults. OpenAI lists shutdowns for `gpt-3.5-turbo-0125` via the `gpt-3.5-turbo` alias, `gpt-4-0613` via `gpt-4`, `gpt-4-turbo-2024-04-09`, `gpt-4.1-nano-2025-04-14`, `gpt-4o-2024-05-13`, `gpt-image-1`, `o1`, `o1-pro`, `o3-mini`, `o4-mini`, and fine-tuned models based on `gpt-3.5-turbo`, `gpt-4`, `gpt-4.1-nano`, `babbage-002`, `davinci-002`, and `o4-mini`.[1]

The dangerous files are rarely named `openai-models.ts`. They are eval fixtures, LangChain defaults, notebooks, queue workers, incident fallbacks, retry middleware, old fine-tune manifests, and cost-optimized "cheap model" branches. Search for exact strings and family aliases, then partials such as `gpt-3.5`, `gpt-4-turbo`, `o1`, `o3-mini`, `o4-mini`, `ft-`, `babbage`, and `davinci`.

A concrete failure mode: your primary completion route targets `gpt-4.1`, which is still live, but your fallback handler on connection timeout was written two years ago to retry on `gpt-3.5-turbo`. On October 24, the primary succeeds, the fallback returns `model_not_found`, and your error-rate SLO trips because the handler now hard-errors instead of recovering. The fix is not to route around the exception — it is to promote the fallback to a current model ID before the shutdown date.

Fine-tunes need a separate plan. A fine-tuned model tied to a retiring base does not magically become a fine-tuned replacement on the new base. Budget time for re-training, eval comparison, and rollout behind a flag. The key distinction in [[glossary/fine-tuning]] is that you are migrating learned behavior, not just swapping an inference endpoint.

<RunPromptCell
  model="gpt-5.5"
  prompt="Write a shell audit for a repository that must migrate before OpenAI's July 23 and October 23 2026 shutdowns. It should search code, config, notebooks, and CI for deprecated OpenAI model IDs including computer-use-preview-2025-03-11, gpt-3.5-turbo, gpt-4, gpt-4-turbo, o1, o3-mini, o4-mini, gpt-image-1, and ft-* models. Return commands plus what a clean result means."
  expectedOutput="A repo-wide ripgrep audit that searches source, config, notebooks, CI, and env templates for exact deprecated IDs and aliases; a clean result means no direct references, but routing dashboards and hosted fine-tune registries still need manual review."
/>

## Put the Whole H2 2026 Deprecation Calendar on One Runbook

July and October are not isolated dates. The synthesis tracks a dense second-half calendar: August 10 for `gpt-5.2-chat-latest` and `gpt-5.3-chat-latest`, August 26 for Assistants API sunset, September 28 for older instruct and base models, December 1 for image-model consolidation, and December 11 for original `gpt-5` and `o3` snapshots.[1][5][6]

The Assistants API deserves special attention because it is not a model swap. OpenAI's community announcement says the beta sunsets on August 26, 2026; the migration path changes object boundaries from Assistants, Threads, and Runs toward Responses and Conversations.[5] If your app uses server-managed threads as the state container, decide what state remains server-side, what moves into your database, and how much historical context each response receives. The practical migration pattern is covered in [[course/openai-agents-sdk-mastery/ch01-sdk-responses-api]].

Image generation has a similar trap. The research synthesis cites a December 1 consolidation from `gpt-image-1-mini`, `gpt-image-1.5`, and `chatgpt-image-latest` toward `gpt-image-2`.[6] If your product stores expected dimensions or prompt templates tuned to old outputs, schedule a visual regression pass.

## Ship a Model-Lifecycle Harness Before the Next Shutdown

The durable fix is not a spreadsheet of replacement names. It is a model-lifecycle harness: model IDs in config, owner-assigned deprecation checks, eval suites for every production route, and release gates that compare behavior before and after a model change. Keep aliases and dated snapshots separate, flag every fine-tuned base model, and make OpenAI's deprecations page part of release ops. A quarterly review cadence is the minimum; monthly is better for organizations with fine-tuned models, since retraining on a new base typically needs six to eight weeks of eval time before a production rollout is safe.

A practical harness has three layers. First, a central `models.config.ts` where every model ID is declared and versioned — no inline string literals in service code. Second, a weekly CI script that checks each declared ID against OpenAI's deprecations feed and opens a ticket automatically when a match appears. Third, a labeled eval suite that runs representative prompts per production route and records quality scores before and after any model change, so reviewers have evidence rather than opinion when approving a swap. Model IDs treated as infrastructure config get the same review rigor as a database schema migration. That discipline eliminates the silent-breakage scenario where a fallback routes to a sunset model for weeks before an on-call engineer notices the error spike.

<KnowledgeCheck
  question="Why is October 23, 2026 the bigger production risk than July 23 for many OpenAI users?"
  options={[
    "Because July only affects ChatGPT users.",
    "Because October removes legacy families and fine-tuned bases that often live in hidden fallbacks, routing configs, eval scripts, and retry paths.",
    "Because computer use has no replacement after July 23.",
    "Because OpenAI is shutting down the Responses API in October."
  ]}
  correctIdx={1}
  explanation="July mainly removes dated preview snapshots. October removes long-lived defaults such as gpt-3.5-turbo, gpt-4, o1, o3-mini, o4-mini, gpt-image-1, and related fine-tuned bases, so stale fallback routes become outage paths."
/>

The practical takeaway: update July IDs, but spend most engineering time on the October audit. That is where assumptions about stable OpenAI families, cheap fallbacks, and reusable fine-tunes become production risk. For migration habits covering Responses API, tool calling, evals, and release gates, continue with [[course/openai-agents-sdk-mastery]].

## Sources

[1] OpenAI API deprecations: https://developers.openai.com/api/docs/deprecations

[2] OpenAI GPT-5.4 mini model docs: https://developers.openai.com/api/docs/models/gpt-5.4-mini

[3] OpenAI Developer Community deprecation notice thread: https://community.openai.com/t/deprecation-notice-upcoming-model-shutdowns-in-2026/1379553

[4] OpenAI Developer Community computer-use-preview replacement thread: https://community.openai.com/t/is-computer-use-preview-retiring-with-no-replacement/1368785

[5] OpenAI Developer Community Assistants API sunset thread: https://community.openai.com/t/assistants-api-beta-deprecation-august-26-2026-sunset/1354666

[6] AI Weekly image API deprecation alert: https://aiweekly.co/alerts/openai-deprecates-three-image-apis-by-december-2026
