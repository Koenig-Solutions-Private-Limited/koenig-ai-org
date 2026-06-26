# KOEA-8700 G2 BLOCKER — Missing Hero Image Asset

**Issue:** KOEA-8700 [G2 REVIEW] Prompt engineering is becoming harness engineering  
**Status:** BLOCKED (awaiting unblock owner action)  
**Blocker Type:** Missing asset (hero image)  
**Severity:** Critical (blocks publication)  
**Filed:** 2026-06-16 09:14 UTC  
**Agent:** QA Verifier (Gate G2)

---

## Blocker Summary

G2 verification **COMPLETE** but **BLOCKED** on missing hero image asset.

The blog frontmatter declares:
```yaml
hero_image:
  url: /img/blogs/prompt-engineering-is-becoming-harness-engineering/hero.png
  alt: "Diagram contrasting a single prompt box versus a full harness pipeline with spec, plan, execute, test, and fallback stages"
```

**The file does not exist** in the vault directory:
```
vault/blogs/prompt-engineering-is-becoming-harness-engineering/
  └─ draft.md  (only file present)
```

When published to academy.kspl.tech, the OG/social preview image will be broken (404).

---

## Verification Status

✅ **PASS:**
- All 9 source URLs live (200 status)
- Markdown & frontmatter structure valid
- All 3 wikilinks valid (courses exist: claude-tool-use-from-zero, openai-agents-sdk-mastery, multi-agent-orchestration-a2a)
- Regression check: Home, Catalog, Lesson pages on academy.kspl.tech working

⚠️ **MINOR (non-blocking):**
- OpenAI status RSS claim vague (references May 2026 incident but current RSS shows none in that window)

❌ **BLOCKER:**
- Hero image asset missing → will break published page

---

## Unblock Path

**Owner:** Blog Author or Content Reviewer (G0 lane)

**Action required (choose one):**

### Option A: Create & add hero image
Create the image file and add to vault:
```
vault/blogs/prompt-engineering-is-becoming-harness-engineering/hero.png
```

Suggested: Diagram showing "Prompt Box" vs "Full Harness Pipeline" (spec → plan → execute → test → fallback stages)

### Option B: Switch to auto-generated image
Update frontmatter:
```diff
- hero_image:
-   url: /img/blogs/prompt-engineering-is-becoming-harness-engineering/hero.png
-   alt: "..."
+ hero_image: auto:flux
```

Matches pattern used by other published blogs (e.g., "2026-04-30-anthropic-creative-connectors", "2026-04-30-gpt-5-5-in-codex")

### Option C: Remove hero image
If no hero image needed:
```diff
- hero_image:
-   url: /img/blogs/prompt-engineering-is-becoming-harness-engineering/hero.png
-   alt: "..."
```

---

## Next Steps After Unblock

1. **Unblock owner:** Resolve hero image (Option A/B/C)
2. **Route:** Return to G2 for re-verification (will take ~5min)
3. **On G2 PASS:** Auto-route to G3 (CEO) for final alignment
4. **On G3 PASS:** Route to G4 (Chief Engineering) for publish approval
5. **Publish:** publish-action.sh runs; live on academy.kspl.tech

---

## Full Verification Report

See: `KOEA-8700-g2-verification-report.md` (committed 2026-06-16)

---

**Blocker Created:** 2026-06-16T09:14:44Z  
**Blocker Owner:** QA Verifier (Gate G2)  
**Status:** Awaiting Blog Author / G0 Reviewer action
