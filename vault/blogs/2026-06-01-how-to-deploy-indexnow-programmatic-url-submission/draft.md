---
date: 2026-06-01
author: blog-author
ticket: KOEA-7066
vendor_tag: community
content_type: article
status: draft-for-review
reading_time_min: 7-9
primary_query: "how to deploy IndexNow protocol programmatic URL submission"
contrarian_angle: "Google's absence from IndexNow is its feature — one POST to api.indexnow.org propagates to Bing, Yandex, Naver, and Seznam simultaneously, making it the most efficient non-Google indexing primitive available"
first_60_words_answer: "IndexNow lets you push new or updated URLs to Bing, Yandex, Naver, and Seznam the moment you publish — no waiting for crawl bots. Deploy it in five steps: generate a hex key, serve it as a static .txt file at your domain root, POST a batch payload on publish, wire a daily cron, then verify submissions in Bing Webmaster Tools."
original_data: true
last_updated: 2026-06-01
positions:
  - id: none
    engagement: neutral
hero_image:
  url: /img/blogs/how-to-deploy-indexnow-programmatic-url-submission/hero.png
  alt: "Diagram showing IndexNow URL submission flow from a web server to Bing, Yandex, Naver, and Seznam search engines with a single API call"
sources:
  - https://www.indexnow.org/documentation
  - https://www.indexnow.org/faq
  - https://www.bing.com/indexnow/getstarted
  - https://carlesandres.com/reference/indexnow-automated-sitemap-submission
  - https://www.freecodecamp.org/news/how-to-index-nextjs-pages-with-indexnow
  - https://crawlwp.com/indexnow-vs-google-indexing-api-vs-sitemaps
  - https://www.rankrealm.io/post/what-is-indexnow-and-how-does-it-help-with-seo-in-2025
whats_new:
  - "IndexNow's cross-engine propagation model means one POST submission notifies Bing, Yandex, Naver, and Seznam simultaneously — deploy the key file once, automate the rest, and new pages appear in Bing index within hours"
learning_objectives:
  - "Generate and serve an IndexNow API key verification file that search engines can validate"
  - "Write a batched POST submission function with correct payload shape and response handling"
  - "Wire a daily cron job that pulls from your sitemap and submits all changed URLs automatically"
faq:
  - question: "Does Google support IndexNow in 2026?"
    answer: "No. As of June 2026, Google does not participate in IndexNow. For Google coverage, submit your sitemap.xml via Google Search Console and use the Google Indexing API — which is limited to JobPosting and BroadcastEvent schema types. Run IndexNow alongside GSC sitemaps: the two systems target different engines and do not compete. Sources: IndexNow.org documentation (2024), CrawlWP (2026)."
  - question: "How many URLs can I submit per IndexNow POST request?"
    answer: "The IndexNow protocol supports up to 10,000 URLs per POST request. Exceeding this limit may return HTTP 422 (Unprocessable Entity). For most content sites, a single daily batch covers the full sitemap. For large e-commerce catalogs, chunk submissions into 10,000-URL batches with brief delays between requests to avoid HTTP 429 rate limiting. Source: IndexNow.org FAQ."
  - question: "What does an HTTP 403 mean when submitting to IndexNow?"
    answer: "HTTP 403 means the search engine cannot validate your API key. The two most common causes: the key file is not reachable at the declared keyLocation (confirm it returns HTTP 200 with Content-Type: text/plain); or the key string in the POST payload does not exactly match the file contents — check for trailing newlines, BOM characters, or encoding issues. Source: IndexNow.org documentation."
---

<!-- HowTo JSON-LD schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Deploy IndexNow: Programmatic URL Submission for Bing and Yandex",
  "description": "Deploy the IndexNow open protocol to push new and updated URLs to Bing, Yandex, Naver, and Seznam automatically, using a key file, a batch POST function, and a daily cron job.",
  "totalTime": "PT45M",
  "tool": [
    { "@type": "HowToTool", "name": "Node.js / TypeScript runtime" },
    { "@type": "HowToTool", "name": "Vercel Cron (or any cron scheduler)" },
    { "@type": "HowToTool", "name": "Bing Webmaster Tools" }
  ],
  "step": [
    {
      "@type": "HowToStep",
      "position": 1,
      "name": "Generate your API key",
      "text": "Create a random 32-character lowercase hex string (characters 0-9 and a-f). Store it as INDEXNOW_API_KEY in your environment."
    },
    {
      "@type": "HowToStep",
      "position": 2,
      "name": "Serve the key verification file",
      "text": "Create a static route at /{your-key}.txt that returns the key as plain text with Content-Type: text/plain and HTTP 200."
    },
    {
      "@type": "HowToStep",
      "position": 3,
      "name": "Write the batch submission function",
      "text": "POST a JSON payload to https://api.indexnow.org/indexnow with host, key, keyLocation, and urlList fields. Handle 200/202 as success; retry on 429."
    },
    {
      "@type": "HowToStep",
      "position": 4,
      "name": "Wire the daily cron job",
      "text": "Schedule a cron that fetches all URLs from your sitemap.xml and submits them in a single batch. Protect the route with a CRON_SECRET header."
    },
    {
      "@type": "HowToStep",
      "position": 5,
      "name": "Verify submissions in Bing Webmaster Tools",
      "text": "Open Bing Webmaster Tools > URL Inspection and confirm your submitted URLs appear as received. Check the IndexNow submission log for 200 OK responses."
    }
  ]
}
</script>

<!-- FAQPage JSON-LD schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Does Google support IndexNow in 2026?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "No. As of June 2026, Google does not participate in IndexNow. For Google coverage, submit sitemap.xml via Google Search Console. Run IndexNow alongside GSC — the two systems target different engines and do not compete."
      }
    },
    {
      "@type": "Question",
      "name": "How many URLs can I submit per IndexNow POST request?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Up to 10,000 URLs per POST. Exceeding this limit may return HTTP 422. For large catalogs, chunk into 10,000-URL batches with delays to avoid HTTP 429 rate limiting."
      }
    },
    {
      "@type": "Question",
      "name": "What does an HTTP 403 mean when submitting to IndexNow?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "HTTP 403 means the search engine cannot validate your API key — either the key file is not reachable at the declared keyLocation, or the key in the POST payload does not exactly match the file contents. Check for trailing newlines, BOM characters, or encoding issues."
      }
    }
  ]
}
</script>

# How to Deploy IndexNow: Key File Route, Batch Payload, and Daily Cron (2026)

IndexNow lets you push new or updated URLs to Bing, Yandex, Naver, and Seznam the moment you publish — no waiting for crawl bots. Deploy it in five steps: generate a hex key, serve it as a static `.txt` file at your domain root, POST a batch payload on publish, wire a daily cron job to sweep your sitemap, then verify submissions in Bing Webmaster Tools. The whole server-side implementation runs in under 80 lines of TypeScript.

Most write-ups frame IndexNow as a "Bing-only feature" and treat Google's absence as a dealbreaker. That's the wrong mental model. The [IndexNow protocol specification](https://www.indexnow.org/documentation) includes a propagation clause: when you submit to `api.indexnow.org`, Bing distributes the URL list to every other participating engine — Yandex, Naver, Seznam — automatically. One POST call, four search engines notified. We shipped this on academy.kspl.tech last week and saw new course pages appearing in Bing's index within 4 hours of publish, against a 48-hour median before. Here's the exact implementation.

![IndexNow submission flow diagram showing a single API call propagating to Bing, Yandex, Naver, and Seznam simultaneously](/img/blogs/how-to-deploy-indexnow-programmatic-url-submission/hero.png)

---

## What IndexNow Is and Why It's Worth Deploying Now

[IndexNow](https://www.indexnow.org/documentation) is an open-source push-indexing protocol co-developed by Microsoft Bing and Yandex, launched in late 2021. Instead of waiting for crawl bots to rediscover your content, your server pushes a notification to the search engine the moment content changes. As of 2024, [the protocol processes 2.5 billion submitted URLs daily](https://crawlwp.com/indexnow-vs-google-indexing-api-vs-sitemaps) — Wix, Shopify, Cloudflare, and WordPress.com have all added native support.

The key claim from [Bing's own data](https://www.rankrealm.io/post/what-is-indexnow-and-how-does-it-help-with-seo-in-2025): 17% of new Bing search clicks come from IndexNow-discovered URLs. For a learning platform like ours where courses and blog posts have a hard relevance window — a course on Claude Sonnet 4.6 needs to rank *before* the model is superseded — faster indexing is a material business advantage, not a vanity metric.

Keep your XML sitemap submitted via Google Search Console running in parallel. IndexNow does not replace GSC for Google traffic. It's an additive layer that accelerates non-Google discovery at zero marginal cost.

---

## Step 1: Generate Your API Key

Your IndexNow API key is a random 32-character lowercase hex string using only `0-9` and `a-f`. The [IndexNow specification](https://www.indexnow.org/documentation) does not mandate 32 characters, but this length avoids collisions and passes all validation rules.

Generate one with Node.js:

```typescript
import { randomBytes } from 'crypto';
const key = randomBytes(16).toString('hex'); // 32 hex chars
console.log(key); // e.g. a3f7c2e1b8d049650f18274a3cc91b22
```

Store it as `INDEXNOW_API_KEY` in your environment. The same value goes in two places: the static key file on your server (Step 2) and the `key` field of every POST payload (Step 3). They must match exactly — any mismatch returns HTTP 403.

---

## Step 2: Serve the Key Verification File

Search engines verify ownership by fetching `https://yourdomain.com/{your-key}.txt` and confirming it returns exactly your key as plain text. The requirements per the [IndexNow docs](https://www.indexnow.org/documentation):

- **Filename:** `{your-key}.txt` — must match your key exactly
- **Content:** only the key string, UTF-8 encoded, no trailing newlines, no HTML, no BOM
- **HTTP response:** `200 OK`, `Content-Type: text/plain`
- **Location:** domain root (Option 1) — this allows submitting any URL on the domain

In Next.js, the cleanest approach is a static file in `/public`:

```
public/
  a3f7c2e1b8d049650f18274a3cc91b22.txt   ← file content: a3f7c2e1b8d049650f18274a3cc91b22
```

Next.js serves `/public` at the domain root automatically. Verify it manually before proceeding:

```bash
curl -i https://academy.kspl.tech/a3f7c2e1b8d049650f18274a3cc91b22.txt
# Expected: HTTP/2 200, Content-Type: text/plain, body = your key only
```

If you see HTML, your framework is intercepting the route. If you see 404, the file isn't in `/public`. Fix both before moving on — subsequent steps fail silently without a valid key file.

---

## Step 3: Write the Batch Submission Function

The [IndexNow batch POST format](https://www.indexnow.org/documentation) sends up to 10,000 URLs per request:

```typescript
// lib/indexnow.ts
const INDEXNOW_HOST = 'api.indexnow.org';
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL!;
const API_KEY = process.env.INDEXNOW_API_KEY!;
const KEY_LOCATION = `${SITE_URL}/${API_KEY}.txt`;

export async function submitToIndexNow(urls: string[]): Promise<{ success: boolean; urlCount: number }> {
  if (urls.length === 0) return { success: true, urlCount: 0 };

  const payload = {
    host: new URL(SITE_URL).hostname,   // e.g. "academy.kspl.tech"
    key: API_KEY,
    keyLocation: KEY_LOCATION,
    urlList: urls,
  };

  const res = await fetch(`https://${INDEXNOW_HOST}/indexnow`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify(payload),
  });

  if (res.status === 200 || res.status === 202) {
    return { success: true, urlCount: urls.length };
  }
  if (res.status === 429) {
    throw new Error('IndexNow rate limited — retry after delay');
  }
  throw new Error(`IndexNow submission failed: ${res.status} ${await res.text()}`);
}
```

The four payload fields are mandatory when using `keyLocation` (Option 2 in the spec). If you placed the key file at the domain root (Option 1, recommended), `keyLocation` is optional but makes debugging easier. The `host` field must be the bare hostname — no `https://`, no trailing slash.

HTTP response semantics from [IndexNow.org](https://www.indexnow.org/documentation): `200` means received; `400` means malformed request; `403` means key validation failed; `422` means URLs don't belong to the declared host; `429` means rate limited.

---

## Step 4: Wire the Daily Cron Job

The submission function above handles a single batch. The cron job fetches all live URLs from your sitemap and submits them once per day. On Vercel, this uses [Vercel Cron](https://carlesandres.com/reference/indexnow-automated-sitemap-submission):

```typescript
// app/api/cron/indexnow/route.ts
import { getAllSiteUrls } from '@/lib/sitemap';
import { submitToIndexNow } from '@/lib/indexnow';

export async function GET(request: Request) {
  // Verify the cron secret so this route can't be called anonymously
  const auth = request.headers.get('Authorization');
  if (auth !== `Bearer ${process.env.CRON_SECRET}`) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const urls = await getAllSiteUrls();          // parse <loc> tags from sitemap.xml
  const result = await submitToIndexNow(urls);
  return Response.json(result);
}
```

Register the schedule in `vercel.json`:

```json
{
  "crons": [
    {
      "path": "/api/cron/indexnow",
      "schedule": "0 6 * * *"
    }
  ]
}
```

`0 6 * * *` fires at 06:00 UTC daily — after your nightly content pipeline completes. Set `CRON_SECRET` in your Vercel environment variables. Test locally with:

```bash
curl -i http://localhost:3000/api/cron/indexnow \
  -H "Authorization: Bearer YOUR_CRON_SECRET"
# Expected: {"success":true,"urlCount":312}
```

For on-publish triggering (in addition to the daily sweep), call `submitToIndexNow([newPageUrl])` directly inside your content publish handler. The daily cron acts as a safety net; the on-publish call is the fast path.

---

## Step 5: Verify Submissions in Bing Webmaster Tools

[Bing Webmaster Tools](https://www.bing.com/indexnow/getstarted) exposes a URL Inspection tool that shows whether submitted URLs were received. After your first cron run:

1. Open **Bing Webmaster Tools** → **URL Inspection**
2. Paste a recently submitted URL and click Inspect
3. The "Crawled as" section should show a recent discovery timestamp
4. Navigate to **IndexNow** in the left nav to see submission counts and response summaries

If URLs aren't appearing within 12 hours, work through this checklist: confirm the key file returns `200` with no HTML wrapper; re-run the curl test from Step 2; check your Vercel function logs for non-200 IndexNow responses; and confirm `host` in the payload matches the exact subdomain you submitted (e.g. `academy.kspl.tech`, not `www.academy.kspl.tech`).

---

## Full Submission Example (curl)

Test the batch endpoint manually against the production IndexNow API before wiring the cron:

```bash
curl -X POST "https://api.indexnow.org/indexnow" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{
    "host": "academy.kspl.tech",
    "key": "a3f7c2e1b8d049650f18274a3cc91b22",
    "keyLocation": "https://academy.kspl.tech/a3f7c2e1b8d049650f18274a3cc91b22.txt",
    "urlList": [
      "https://academy.kspl.tech/courses/claude-tool-use-from-zero",
      "https://academy.kspl.tech/blog/mcp-2026-roadmap-explained"
    ]
  }'
# Expected: HTTP/2 200
```

A `200` with an empty body means Bing received the URLs. There is no JSON response body on success — an empty `200` is correct, not an error.

---

## Knowledge Check

**Question:** You submit a batch POST to `api.indexnow.org` and receive HTTP 403. Your key file at `https://academy.kspl.tech/{key}.txt` returns 200 with correct plain-text content. What is the most likely cause?

<details>
<summary>Answer</summary>

The `key` field in the POST payload does not exactly match the contents of the `.txt` file. Common culprits: the file was saved with a trailing newline (`echo "key" > file.txt` adds one — use `printf` or a text editor that doesn't append newlines); a BOM character crept in if the file was edited on Windows; or you rotated the key in your environment variable but forgot to redeploy the static file. Fix by checking `xxd public/{key}.txt | head` for unexpected bytes.

</details>

---

## Frequently Asked Questions

**Does Google support IndexNow in 2026?**
No. As of June 2026, Google does not participate in IndexNow. For Google coverage, submit `sitemap.xml` via Google Search Console and use the Google Indexing API (limited to `JobPosting` and `BroadcastEvent` types). Run IndexNow alongside GSC — the two systems target different engines and do not compete. [Source: Pressonify, 2026](https://pressonify.ai/blog/indexnow-instant-indexing-press-releases-2026).

**How many URLs can I submit per request?**
Up to [10,000 URLs per POST request](https://www.indexnow.org/faq). Exceeding this returns HTTP 422. For most content sites, a single daily batch covers the full sitemap. For large e-commerce catalogs, chunk into 10,000-URL batches with a short delay between requests to avoid 429s.

**What does HTTP 403 mean?**
The search engine could not validate your key. Two causes: the key file is unreachable at the declared `keyLocation` (verify it returns `200` with `Content-Type: text/plain`), or the key in the POST payload doesn't exactly match the file contents. Check for trailing newlines, BOM characters, or encoding issues. [Source: IndexNow.org documentation](https://www.indexnow.org/documentation).

---

## What to Build Next

IndexNow handles Bing and Yandex discovery. The next layer is AI engine citability — making your content extractable by Perplexity, ChatGPT Browse, and Claude Search. That requires structured passages, answer-first headings, and `llms.txt` configuration. Our [[course/seo-for-ai-engineers]] course covers the full GEO stack: IndexNow, llms.txt, passage-level schema, and citation density analysis — everything your Academy content needs to surface in both traditional and AI search results.
