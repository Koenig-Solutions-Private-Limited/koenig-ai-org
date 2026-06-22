---
schema: agentcompanies/v1
kind: skill
slug: g4-routing
name: G4 — Human Approval Routing
description: CEO routes G3-passed COURSE work to Vardaan via Paperclip UI queue, Resend email, and optional Slack webhook. Blogs NEVER hit G4 — auto-publish on G3 PASS. G4 is courses-only (policy locked 2026-05-01).
version: 0.1.0
license: MIT
sources: []
---

# G4 — Human Approval Routing

Used by `ceo`. Triggered ONLY for COURSE content that passes G3 with `high_stakes: true`. **Blogs never enter G4** — they auto-publish on G3 PASS regardless of high_stakes flag. The CEO is the final approver for all blog content.

G4 fires only on:
- **New full course launches** (multi-chapter; brand reputation stakes)
- **Strategic course modules** where Vardaan flags `high_stakes: true` at ticket creation
- Single-chapter rewrites and routine course updates do NOT trigger G4

Policy reference: `vault/decisions/2026-05-01-blog-skip-g4.md`

If a blog ticket arrives at this skill, **return immediately with a routing error** — the upstream g3-alignment skill misclassified the content type. The fix is in g3-alignment, not here.

## Procedure

1. **Build a one-screen approval brief** — title, what's changing, where to preview (mobile-safe URL), link to vault file or PR, list of gates already passed (G0/G_code/G2/G3 with timestamps), budget consumed, time-to-approve estimate (≤30 sec for blogs, ≤2 min for courses), reason this is `high_stakes`.

2. **Build a mobile-safe preview URL (V3-6 LOCKED)**:
   - Trigger Vercel preview deploy: `vercel deploy --prebuilt --token $VERCEL_TOKEN` (NOT `--prod`)
   - Capture the deploy URL (format `https://academy-pr-<n>-koenig-ai-academy.vercel.app/blog/<slug>`)
   - This URL works on mobile + auto-expires after 7 days
   - **Never use `localhost:3010` or `localhost:3100` — breaks on mobile**

3. **Route notifications using the helper** (Paperclip UI + Resend + optional Slack):

   ```bash
   bash scripts/g4-notify.sh \
     --issue "$ISSUE_ID" \
     --approval-id "$APPROVAL_ID" \
     --title "$TITLE" \
     --preview-url "$PREVIEW_URL" \
     --vault-path "$VAULT_PATH" \
     --gates "$GATES" \
     --validate-resend \
     --allow-chat-unavailable
   ```

   The helper is notification-only and must not publish, mutate approval state, or print secret values.

   **Email** (via Resend):
   ```
   Subject: G4 · Approve "<title>"? (high_stakes; 1 of <queue size> in queue)

   Body:
   • What: <Blog post|Course|Course chapter> (<word count> words) — <one-line summary>
   • Why high_stakes: <reason flagged at ticket creation>
   • Preview (mobile-safe): https://academy-pr-<n>-koenig-ai-academy.vercel.app/blog/<slug>
   • Vault: vault/<path>/draft.md
   • Gates passed: G0 ✓ <HH:MM> · G_code N/A · G2 ✓ <HH:MM> · G3 ✓ <HH:MM>
   • Budget: $<spent> spent ($<estimated> estimated)
   • Time to review: ~30 sec

   [✅ Approve & Publish]   [❌ Reject with comment]   [📝 Open in Paperclip]
   ```

   **Paperclip UI queue** — task surfaces in `/g4-queue` with the same content; one-click approve buttons (https://paperclip.kspl.tech/g4-queue when V3-9 Cloudflare Tunnel lands; ngrok in interim)

   **Slack webhook** (optional) — send same brief when `SLACK_WEBHOOK_URL` is configured.

   **Teams webhook** — future/unused in this runtime. Do not treat Teams as an active route.

4. **Write sanitized status comment** — after each routing attempt, comment per-channel status back to the driving issue and the target G4 issue. Include route availability (`resendEmail`, `slack`, `teams`) without recipient addresses, webhook URLs, bearer tokens, approval links, or message body.

5. **Wait for approval** — first channel to respond wins. Other channels auto-cancel after first response.

6. **On APPROVE**:
   - Trigger publish action (course → Convex agentApi `submit-for-approval` then publish; blog → same; code → merge PR)
   - PATCH `metadata.publish_state="g4-approved"` (status stays `done`; publish-action cron detects this and deploys). (**Do NOT set status to "published" — invalid enum; returns 400.**)
   - Append to today's EOD digest

7. **On REJECT**:
   - Capture Vardaan's reject comment (required field)
   - Route back to the appropriate chief based on the reject reason
   - Set status to `in_progress` + `metadata.publish_state="rejected"` (**"awaiting-revision" is not a valid enum value**)

## Inputs

- A G3-passed COURSE ticket WITH `high_stakes: true` in description metadata. (Blogs are forbidden inputs — they auto-publish without G4. Routine course updates are forbidden inputs — only `high_stakes: true` courses route here.)
- Vardaan's email + optional Slack webhook
- Resend API key
- Vercel preview deploy URL (mobile-safe; auto-expires 7 days)

## Outputs

- 1 email sent
- 1 Paperclip queue entry
- (optional) 1 Slack webhook message
- Approval state captured + downstream action triggered

## Never do

- Never auto-approve. Ever. G4 is the human gate — that is the whole point.
- Never lose the reject comment — it's the corrective signal
- Never publish from `g4-notify.sh`; publishing remains a separate approved action
- Never publish after a reject (even a stale approve from a different channel)
- Never include sensitive secrets/PII in the email

## Escalation

- No response in 24h → resend reminder + ping
- Same ticket rejected twice → flag for next weekly retro; possibly the brief is wrong

## Budget

Per-task cap $0.25.
