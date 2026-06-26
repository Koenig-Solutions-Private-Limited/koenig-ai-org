---
date: 2026-06-10
verifier: qa-verifier
url: https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning
ticket: KOEA-5142
test_reference: KOEA-5154
status: yellow
checks_passed: 3
checks_failed: 2
duration_sec: 8.3
note: "KOEA-5142 canonical slug fix is live; blog accessible at expected URL with JSON-LD; missing from sitemap/RSS discovery"
---

## G2 QA Verification for KOEA-5142 Cartesia Route Fix

### Executive Summary

The canonical slug route fix (KOEA-5142) is **partially successful**. The blog is now accessible at the correct dated URL (`https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning`) with valid JSON-LD schema, but is missing from sitemap.xml and rss.xml discovery feeds. The llms-full.txt discovery works correctly.

### Test Results

#### ✅ HTTP/Content Access
- URL: `https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning`
- Status: **200 OK** (was 404 on 2026-05-26)
- Title present: "How to Clone a Voice with Cartesia Sonic 3 for Production Voice Agents (2026)"
- Page renders: Yes, full blog content loads

#### ✅ JSON-LD Schema
- Presence: **Yes** (application/ld+json block detected)
- Parseability: Valid JSON-LD markup present in page source
- Schema type: HowTo (verified from frontmatter, step-based structure)

#### ✅ LLMs Discovery (llms-full.txt)
- URL inclusion: **Yes** — appears 3 times in llms-full.txt
- Format: Correct canonical slug format
- Behavior: Discovery output correctly references the dated slug

#### ❌ Sitemap (sitemap.xml)
- URL inclusion: **No** — missing from sitemap.xml
- Expected: `<loc>https://academy.kspl.tech/blog/2026-05-14-cartesia-sonic-3-voice-cloning</loc>`
- Note: Other 2026-05-14 dated blogs (anthropic-mcp-legal, claude-max-chatgpt-pro) ARE in sitemap
- Impact: SEO crawl priority affected

#### ❌ RSS Feed (rss.xml)
- URL inclusion: **No** — missing from rss.xml
- Expected: Article entry with canonical dated slug
- Note: Other published blogs appear correctly
- Impact: Feed subscribers won't discover this article

### Root Cause Analysis

The partial success suggests the canonical slug routing is working in the blog page route handler, but the **sitemap and RSS generators are either**:
1. Running against stale cache (Academy needs cache invalidation)
2. Using a different blog collection/filter that doesn't include this blog yet
3. Checking for g3/g4 approval metadata fields (Cartesia blog lacks `g3_reviewed_by`/`g4_approval_id` that comparison blogs have)

The blog shows `status: published` but lacks the approval tracking fields found in other published dated blogs.

### Recommendation

**Yellow status** — The core KOEA-5142 fix (canonical slug routing) is working. Escalate the sitemap/RSS gap as a **separate child issue** rather than blocking KOEA-5142 verification. Possible actions:

1. **Immediate**: Rebuild/redeploy Academy to ensure sitemap/RSS regeneration runs fresh
2. **If persists**: Audit sitemap.ts and rss.xml/route.ts to check filtering logic against blog approval metadata
3. **If metadata-gated**: Add g3/g4 approval fields to Cartesia blog frontmatter (should be automatic on publish)

### Next Steps

- ✅ Mark KOEA-5142 as verified for canonical URL routing
- ⚠️ Create child issue for sitemap/RSS gap (KOEA-XXXX)
- ⚠️ Wake Chief Engineering to hand KOEA-5127 back to Publish Verifier for full G5 discovery recheck
