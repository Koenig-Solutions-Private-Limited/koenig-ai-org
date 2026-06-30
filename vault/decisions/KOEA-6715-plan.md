---
ticket: KOEA-6715
agent: Executor
author: operator (Claude Code, V7 SEO/GEO Phase 2)
date: 2026-05-29
estimated_minutes: 40
---

# KOEA-6715 plan — Lighthouse CI gate on Vercel deploys

## Goal

Add `.github/workflows/lighthouse.yml` running on each Vercel deploy preview for blog/course pages. Block publish if LCP > 2.5s OR INP > 200ms OR CLS > 0.1. Integrate with Publish Verifier (L0-L4 → L5 = Lighthouse).

## Procedure

### Phase A — author lighthouse.yml workflow (15 min)

```yaml
# .github/workflows/lighthouse.yml — in learnovaBeast repo
name: Lighthouse CI
on:
  deployment_status:
jobs:
  lighthouse:
    if: github.event.deployment_status.state == 'success'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lighthouse Audit
        uses: treosh/lighthouse-ci-action@v12
        with:
          urls: |
            ${{ github.event.deployment_status.target_url }}
            ${{ github.event.deployment_status.target_url }}/learn/gemini-enterprise-agents
            ${{ github.event.deployment_status.target_url }}/blog
          configPath: ./.lighthouserc.json
          uploadArtifacts: true
          temporaryPublicStorage: true
```

### Phase B — author .lighthouserc.json budget (5 min)

```json
{
  "ci": {
    "collect": { "numberOfRuns": 3, "settings": { "preset": "desktop" } },
    "assert": {
      "assertions": {
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "interaction-to-next-paint": ["warn", { "maxNumericValue": 200 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "categories:performance": ["warn", { "minScore": 0.85 }],
        "categories:seo": ["error", { "minScore": 0.95 }],
        "categories:accessibility": ["warn", { "minScore": 0.9 }]
      }
    }
  }
}
```

### Phase C — Publish Verifier integration (15 min)

Read Publish Verifier AGENTS.md L0-L4 matrix; add L5:
- **L5 Lighthouse gate** — before dispatching publish for a blog/course, check the most recent Lighthouse CI run on the preview URL. If LCP > 2.5s OR CLS > 0.1, BLOCK with comment naming failing metric + threshold + actual value.

### Phase D — secrets + verify (5 min)

```bash
# 1. Add LHCI_GITHUB_APP_TOKEN if needed (optional — temporary storage works without)
# 2. Push branch + open PR + verify workflow fires on next Vercel deploy
gh secret list --repo Koenig-Solutions-Private-Limited/learnovaBeast | grep LHCI
```

## Acceptance

- [ ] `.github/workflows/lighthouse.yml` + `.lighthouserc.json` committed
- [ ] Workflow fires on next Vercel deploy preview
- [ ] At least 1 metric assertion (LCP) is enforceable
- [ ] Publish Verifier AGENTS.md updated with L5 check
- [ ] Deliberate slow-image draft fails the gate (smoke test)

## Exit invariant

Executor exits `done` when all 4 phases land. If Phase D secret-setup requires operator, exits `blocked` with unblock_owner=operator + specific secret name.
