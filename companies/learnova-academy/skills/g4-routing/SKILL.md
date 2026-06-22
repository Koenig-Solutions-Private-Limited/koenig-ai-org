---
schema: agentcompanies/v1
kind: skill
slug: g4-routing
name: G4 — Human Approval Routing
description: CEO routes G3-passed COURSE work to Vardaan via three channels (Resend email + Slack webhook + Paperclip UI queue). Blogs NEVER hit G4 — auto-publish on G3 PASS. G4 is courses-only (policy locked 2026-05-01).
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

3. **Route to channels in parallel** (Paperclip UI + Resend email + Slack):

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

   **Canonical helper command** (runs Resend + Slack and returns sanitized channel statuses):
   ```bash
   bash scripts/g4-notify.sh \
     --issue <KOEA-id> \
     --approval-id <paperclip-approval-id> \
     --title "<title>" \
     --preview-url "<mobile-preview-url>" \
     --vault-path "<vault/path.md>" \
     --gates "G0,G_code,G2,G3"
   ```

   - `RESEND_API_KEY` is required for CEO delivery.
   - `SLACK_WEBHOOK_URL` is optional. If missing, CEO must obtain Chief Engineering/operator sign-off before using:
   ```bash
   bash scripts/g4-notify.sh ... --allow-chat-unavailable
   ```
   - Teams is future/unused in this repo. Do not implement Teams routing in this skill.

3. **Wait for approval** — first channel to respond wins. Other channels auto-cancel after first response.

4. **On APPROVE**:
   - Trigger publish action (course → Convex agentApi `submit-for-approval` then publish; blog → same; code → merge PR)
   - PATCH `metadata.publish_state="g4-approved"` (status stays `done`; publish-action cron detects this and deploys). (**Do NOT set status to "published" — invalid enum; returns 400.**)
   - Append to today's EOD digest

5. **On REJECT**:
   - Capture Vardaan's reject comment (required field)
   - Route back to the appropriate chief based on the reject reason
   - Set status to `in_progress` + `metadata.publish_state="rejected"` (**"awaiting-revision" is not a valid enum value**)

## Inputs

- A G3-passed COURSE ticket WITH `high_stakes: true` in description metadata. (Blogs are forbidden inputs — they auto-publish without G4. Routine course updates are forbidden inputs — only `high_stakes: true` courses route here.)
- Resend API key + optional Slack webhook URL
- Resend API key
- Vercel preview deploy URL (mobile-safe; auto-expires 7 days)

## Outputs

- 1 email sent
- 1 Paperclip queue entry
- 1 Slack message when webhook is configured, otherwise explicit `intentionally_unavailable` chat status after sign-off
- Approval state captured + downstream action triggered

## Never do

- Never auto-approve. Ever. G4 is the human gate — that is the whole point.
- Never lose the reject comment — it's the corrective signal
- Never publish before all 3 channels are dispatched (ensures redundancy)
- Never publish after a reject (even a stale approve from a different channel)
- Never include sensitive secrets/PII in the email

## Escalation

- No response in 24h → resend reminder + ping
- Same ticket rejected twice → flag for next weekly retro; possibly the brief is wrong

## Budget

Per-task cap $0.25.
