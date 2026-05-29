---
ticket: KOEA-6717
agent: Executor
author: operator (Claude Code, V7 SEO/GEO Phase 2)
date: 2026-05-29
estimated_minutes: 30
---

# KOEA-6717 plan — GA4 wiring + daily pull routine

## Goal

Provision a GA4 property for academy.kspl.tech, wire the gtag into `app/layout.tsx`, and add a daily pull routine to Search Visibility Optimizer that writes traffic data to `vault/marketing/ga4/<date>.md`.

## Procedure

### Phase A — provision GA4 property (USER ACTION REQUIRED, 10 min)

Executor: post a comment with these exact lines and exit blocked with `unblock_owner=operator`.

```
@operator GA4 setup steps (browser-only, cannot script):

1. Go to https://analytics.google.com → click ⚙ Admin
2. Click + Create Property
   - Name: Koenig AI Academy
   - Timezone: Asia/Kolkata
   - Currency: INR
3. Click Next → choose "Web" platform
4. Stream URL: https://academy.kspl.tech
5. Stream name: academy
6. Click "Create stream"
7. Copy the Measurement ID (G-XXXXXXXXXX)
8. Paste it as a reply comment on this ticket
```

### Phase B — add gtag to learnova-academy `app/layout.tsx` (10 min)

Once operator provides G-XXXXXXXXXX:

```bash
# 1. Add to Vercel env vars (operator pastes via Vercel CLI or dashboard):
#    NEXT_PUBLIC_GA4_ID=G-XXXXXXXXXX
# 2. Edit learnova-academy/src/app/layout.tsx — add gtag script in <head>
#    Respect [stance:contrarian-no-fake-ratings] — anonymous-by-default; no PII; no cookie banner needed for measurement-only purposes
```

Patch to apply:
```tsx
// In <head>:
{process.env.NEXT_PUBLIC_GA4_ID && (
  <>
    <Script src={`https://www.googletagmanager.com/gtag/js?id=${process.env.NEXT_PUBLIC_GA4_ID}`} strategy="afterInteractive" />
    <Script id="ga4-init" strategy="afterInteractive">{`
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '${process.env.NEXT_PUBLIC_GA4_ID}', {
        anonymize_ip: true,
        allow_google_signals: false,
        allow_ad_personalization_signals: false
      });
    `}</Script>
  </>
)}
```

### Phase C — daily pull routine on Search Visibility Optimizer (10 min)

Add a new routine `ga4-daily-pull` to Search Visibility Optimizer (agent UUID `b17b6992-a180-4835-b22d-8dff1e86d615`).

```sql
INSERT INTO routines (company_id, title, description, assignee_agent_id, status, concurrency_policy, catch_up_policy)
VALUES (
  '2a77f89b-33f0-4133-a20c-77ddaac5e744',
  'ga4-daily-pull',
  'Pull yesterdays page-view + bounce + top-pages data via GA4 Data API and write to vault/marketing/ga4/<YYYY-MM-DD>.md. Uses same OAuth service account as GSC.',
  'b17b6992-a180-4835-b22d-8dff1e86d615',
  'active',
  'skip_if_active',
  'skip_missed'
);

INSERT INTO routine_triggers (company_id, routine_id, kind, enabled, cron_expression, timezone, next_run_at)
SELECT '2a77f89b-33f0-4133-a20c-77ddaac5e744', id, 'schedule', true, '30 8 * * *', 'UTC', '2026-05-30 08:30:00+00'
FROM routines WHERE title='ga4-daily-pull';
```

## Acceptance

- [ ] G-XXXXXXXXXX provisioned + pasted by operator
- [ ] NEXT_PUBLIC_GA4_ID env var set in Vercel
- [ ] gtag rendered in layout.tsx (verify view-source on academy.kspl.tech)
- [ ] First GA4 hit visible in GA4 realtime dashboard within 5 min of deploy
- [ ] `ga4-daily-pull` routine active in DB
- [ ] First daily-pull writes `vault/marketing/ga4/<tomorrow's date>.md`

## Exit invariant

Executor exits `blocked` with unblock_owner=operator and unblock_action="paste G-XXXXXXXXXX measurement ID in reply comment". Resume when operator confirms.
