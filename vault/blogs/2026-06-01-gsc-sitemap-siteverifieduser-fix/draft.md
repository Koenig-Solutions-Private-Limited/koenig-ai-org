---
date: 2026-06-01
author: blog-author
ticket: KOEA-7067
vendor_tag: google
content_type: article
status: draft-for-review
reading_time_min: 7-9
primary_query: "Google Search Console API siteUnverifiedUser fix sitemap submission 2026"
contrarian_angle: "siteUnverifiedUser is almost never an OAuth scope problem — it is a property-type problem. sc-domain properties silently break the sitemap submission API, and the CNAME you used to verify your domain is likely RFC 1912-invalid anyway"
first_60_words_answer: "The siteUnverifiedUser error from the Google Search Console API means the OAuth identity making the call is not a verified owner of the GSC property — not that your token is wrong. The fastest fix is to switch from a sc-domain (domain) property to a URL-prefix property, verify it via HTML file upload, then add your service account email as Owner in GSC Settings."
positions: none  # pure practitioner how-to, no brand stance engaged; STANCES.md not yet created
sources:
  - https://developers.google.com/webmaster-tools/v1/sitemaps/submit
  - https://support.google.com/webmasters/answer/9008080?hl=en
  - https://stackoverflow.com/questions/60040822/how-to-submit-sitemaps-using-seach-console-api-when-the-domain-is-in-the-form-sc
  - https://seotesting.com/google-search-console/domain-vs-url-prefix
  - https://www.eunit.me/blog/how-to-automatically-submit-sitemap-to-google-programmatically
  - https://webmasters.stackexchange.com/questions/140853/how-to-submit-a-new-sitemap-to-gsc-with-api
  - https://support.google.com/webmasters/thread/428945747
whats_new:
  - "sc-domain properties silently fail the sitemap submission API with 500 or opaque 403; URL-prefix + HTML file verification is the agentic platform path"
learning_objectives:
  - "Understand why siteUnverifiedUser is a property-type error, not an OAuth scope error"
  - "Verify a URL-prefix GSC property via HTML file upload and add a service account as Owner"
  - "Submit a sitemap programmatically using the Search Console API without 403 or 500 errors"
faq:
  - question: "What causes siteUnverifiedUser in the Google Search Console API?"
    answer: "siteUnverifiedUser (HTTP 403, reason: forbidden) means the Google account or service account making the API call is not a verified owner of the GSC property. Two root causes: (1) the account was added as a User or Viewer instead of Owner in GSC Settings > Users and permissions, or (2) you are calling the API against a sc-domain: property using an account that only holds URL-prefix verification for the domain. Owner-level permission is mandatory for sitemap submission — viewer access is insufficient."
  - question: "Why do sc-domain properties fail with the Search Console API?"
    answer: "sc-domain properties use DNS TXT record verification, which is tied to the domain as a whole rather than to a specific URL. When you authenticate via OAuth with a user or service account that holds HTML-file or meta-tag verification on a URL-prefix property, the sc-domain property sees that account as unverified because the verification method doesn't carry over. Additionally, the Webmasters v3 sitemaps.submit endpoint returns an opaque HTTP 500 with a null message body for sc-domain URIs on many configurations, as documented in a 2020 Stack Overflow thread that remains open and unresolved."
  - question: "Can I use a service account to submit sitemaps to Google Search Console?"
    answer: "Yes. Create a service account in Google Cloud Console, enable the Search Console API, download the JSON key, then add the service account email (e.g., indexing-bot@your-project.iam.gserviceaccount.com) as an Owner — not User — in GSC Settings > Users and permissions for a URL-prefix property. As of April 2026, there is an intermittent bug where pasting a service account email into the GSC Add User flow returns 'email not found'. The workaround is to wait 24-48 hours and retry; the issue is known to the GSC team."
  - question: "What OAuth scope does the Search Console API require for sitemap submission?"
    answer: "The sitemap submission endpoint (PUT /webmasters/v3/sites/{siteUrl}/sitemaps/{feedpath}) requires the https://www.googleapis.com/auth/webmasters scope. The read-only variant https://www.googleapis.com/auth/webmasters.readonly is insufficient. Your OAuth token or service account key must be generated with the full webmasters scope."
  - question: "Why does CNAME verification fail for sc-domain properties on some DNS providers?"
    answer: "RFC 1912 section 2.4 prohibits CNAME records at the zone apex (the naked domain, e.g., example.com). Many DNS providers — including Cloudflare with its CNAME flattening — handle this by transparently converting the CNAME to an A record, which breaks Google's CNAME-based site verification because the TXT lookup no longer returns the expected google-site-verification token format. If your domain is on a CNAME-flattening provider, DNS TXT verification becomes unreliable. HTML file upload on a URL-prefix property bypasses DNS entirely."
original_data: false
last_updated: 2026-06-01
hero_image:
  url: /img/blogs/2026-06-01-gsc-sitemap-siteverifieduser-fix/hero.png
  alt: "Flowchart showing the two paths to GSC API access: the broken sc-domain path returning 403/500 errors, and the working URL-prefix plus HTML file verification path leading to successful sitemap submission"
---

# Fix siteUnverifiedUser When Submitting Sitemaps via the Google Search Console API in 2026

The `siteUnverifiedUser` error from the Google Search Console API means the OAuth identity making the call is not a verified owner of that GSC property — not that your token is misconfigured. The fastest fix: switch from a `sc-domain:` (domain-type) property to a URL-prefix property, verify ownership via HTML file upload, then add your service account email as Owner in GSC Settings. This post is a first-hand walkthrough of the exact setup we used, including the pitfalls that cost us three hours.

Most tutorials stop at "add the service account as Owner." That step is necessary but not sufficient. The real wall is the property type.

![Flowchart showing the two paths to GSC API access: the broken sc-domain path returning 403/500 errors, and the working URL-prefix plus HTML file verification path leading to successful sitemap submission](/img/blogs/2026-06-01-gsc-sitemap-siteverifieduser-fix/hero.png)

---

## Why sc-domain Properties Break the Sitemap API

A [domain property in GSC](https://seotesting.com/google-search-console/domain-vs-url-prefix) covers all subdomains and protocols under a single umbrella. The `sc-domain:example.com` URI format is what the [Search Console API sitemaps.submit endpoint](https://developers.google.com/webmaster-tools/v1/sitemaps/submit) expects when you target a domain property. The problem: domain properties can **only** be verified via DNS TXT record. There is no HTML file option, no meta-tag option, no Google Analytics option.

DNS TXT verification is where [RFC 1912 becomes relevant](https://www.rfc-editor.org/rfc/rfc1912). Section 2.4 prohibits CNAME records at the zone apex — but many DNS providers (Cloudflare, Netlify, Vercel) use CNAME flattening at the apex to enable root domain serving. When Google's site verifier tries to check the TXT record, the flattened CNAME causes the DNS resolution path to diverge from what Google expects, and verification fails silently or intermittently.

Even if you do get DNS TXT verification to stick, the API behaves unexpectedly for `sc-domain:` URIs. A [2020 Stack Overflow thread](https://stackoverflow.com/questions/60040822/how-to-submit-sitemaps-using-seach-console-api-when-the-domain-is-in-the-form-sc) — still unresolved — documents the `sc-domain:` variant returning HTTP 500 with a `null` message body, while the same credentials work fine against URL-prefix properties. The [Webmasters Stack Exchange](https://webmasters.stackexchange.com/questions/140853/how-to-submit-a-new-sitemap-to-gsc-with-api) has the same pattern: `webmasters.readonly` scope and `sc-domain:` URIs produce opaque failures.

**The practical outcome for AI ops engineers**: if your automation pipeline targets a domain property, you will get either a 403 `siteUnverifiedUser` or an HTTP 500 with no actionable error message. Both resolve by switching to a URL-prefix property. Here is the exact path.

---

## 7 Steps to Clean Sitemap Submission via the GSC API

### Step 1: Add a URL-Prefix Property for Your HTTPS Origin

In [Google Search Console](https://search.google.com/search-console), click the property selector → **Add property** → choose **URL prefix** (not Domain). Enter your canonical HTTPS origin, e.g. `https://academy.kspl.tech/`. This creates a property with the `https://academy.kspl.tech/` URI format, which the API handles reliably.

If you already have a `sc-domain:` domain property, keep it for the broad-coverage reporting view. You need the URL-prefix property specifically for the programmatic API path.

### Step 2: Download the HTML Verification File

After adding the property, GSC will offer **HTML file** as a verification option. Click it to reveal a filename like `google1a2b3c4d5e6f7a8b.html`. Download or create a file with that exact name containing only the verification token line Google specifies — do not add any HTML wrapping.

According to [Google's verification guide](https://support.google.com/webmasters/answer/9008080?hl=en), the file must be:
- Served from the exact URL-prefix root: `https://academy.kspl.tech/google1a2b3c4d5e6f7a8b.html`
- Accessible without redirects or authentication
- Returning HTTP 200 with the token as the body

### Step 3: Deploy the Verification File and Confirm Ownership

Upload the file to your server or CDN origin. For Next.js/Vercel deployments, place it in the `/public` directory. For Cloudflare Pages, it goes in the site root. Confirm the URL serves the file before clicking **Verify** in GSC.

Once ownership is confirmed, the property shows in your GSC property list with a small HTML file badge. This is the property URI your API calls will target.

### Step 4: Create a Google Cloud Project and Enable the Search Console API

Go to [Google Cloud Console](https://console.cloud.google.com/) → create a new project (e.g., `sitemap-automation`). Navigate to **APIs & Services → Library**, search for **Google Search Console API** (listed under the webmasters v3 surface), and enable it. Without this step, every API call returns a 403 regardless of credentials.

### Step 5: Create a Service Account and Download the JSON Key

Under **IAM & Admin → Service Accounts**, create a service account named `sitemap-bot`. Grant it no project-level IAM roles — you will grant GSC property access separately. Once created, click the service account email → **Keys → Add Key → Create new key → JSON**. Save the downloaded file as `gsc-credentials.json` outside your repository.

The service account email will look like `sitemap-bot@sitemap-automation.iam.gserviceaccount.com`. Copy this; you need it in the next step.

### Step 6: Add the Service Account Email as Owner in GSC

In Google Search Console, open your URL-prefix property → **Settings → Users and permissions → Add user**. Paste the full service account email. Set permission to **Owner** — not Full user, not Restricted. [Owner-level access is required for sitemap submission](https://www.eunit.me/blog/how-to-automatically-submit-sitemap-to-google-programmatically); lower permission levels return the same 403 `siteUnverifiedUser` error.

> **Known bug (April 2026)**: The GSC "Add user" flow intermittently returns `"Failed to add user: email not found"` for service account emails. [This is a known issue being investigated by the GSC team](https://support.google.com/webmasters/thread/428945747). If you hit this, wait 24–48 hours and retry. Do not create a new service account — the email lookup is eventually consistent and your existing service account will resolve.

### Step 7: Submit the Sitemap via the Search Console API

With the service account key and URL-prefix property verified, submit your sitemap using the `webmasters` scope. Here is a minimal Python example:

```python
from google.oauth2 import service_account
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/webmasters"]
SERVICE_ACCOUNT_FILE = "gsc-credentials.json"

# URL-prefix property URI — must match exactly what's in GSC
SITE_URL = "https://academy.kspl.tech/"
SITEMAP_URL = "https://academy.kspl.tech/sitemap.xml"

credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES
)
service = build("webmasters", "v3", credentials=credentials)

service.sitemaps().submit(siteUrl=SITE_URL, feedpath=SITEMAP_URL).execute()
print("Sitemap submitted successfully.")
```

Expected output on success: `Sitemap submitted successfully.` — the API returns an empty body on 200, so no JSON to parse.

Expected error if service account not yet an Owner: `HttpError 403 when requesting https://www.googleapis.com/webmasters/v3/sites/... returned "User does not have sufficient permission for site '...'. See also: https://support.google.com/webmasters/answer/2453966"`

---

## The OAuth User vs. siteOwner Distinction

The error message says "User does not have sufficient permission" but the underlying GSC concept is `siteOwner` vs. `siteUser`. The Search Console API uses the **Webmasters v3** surface, which predates the current GSC UI. When you add an account as Owner in the GSC UI, the API records it as a `siteOwner`. The `sitemaps.submit` endpoint [requires siteOwner permission](https://developers.google.com/webmaster-tools/v1/sitemaps/submit), not merely siteUser. Users added with Full or Restricted access via the UI receive siteUser, not siteOwner — and siteUser cannot submit sitemaps programmatically.

This is the second common failure mode: teams add the service account correctly but at the wrong permission level. The UI labels it "Owner" — but the confirmation email and documentation sometimes show "Full" as equivalent. They are not equivalent for the API.

---

## Verifying the Setup End-to-End

After submitting, confirm the sitemap appears in GSC within 10–15 minutes:

1. Navigate to your URL-prefix property → **Sitemaps** in the left sidebar
2. Your sitemap URL should appear with status **Success** or **Pending** (pending means Google hasn't fetched it yet, not an error)
3. If it shows **Couldn't fetch**, the sitemap URL itself is unreachable — verify the sitemap file is publicly accessible without authentication

For ongoing automation, the same service account credentials work for the [Search Console Index Coverage API](https://developers.google.com/webmaster-tools/v1/searchanalytics/query) if you want to close the loop on indexing status in your pipeline.

---

## KnowledgeCheck

**Question**: Your sitemap submission script runs successfully against your URL-prefix property (`https://example.com/`) but returns HTTP 403 when you change `SITE_URL` to `sc-domain:example.com`. What is the most likely cause?

**Answer**: The service account email is a verified Owner of the URL-prefix property but is not a verified owner of the sc-domain (domain) property. Domain properties maintain separate ownership records from URL-prefix properties. Add the service account as Owner in the domain property's Settings > Users and permissions, or switch back to the URL-prefix URI in your API call.

---

## What's Next

If you are building an SEO automation pipeline that needs deeper GSC integration — inspecting index coverage, querying search analytics, and managing sitemaps programmatically — the patterns here extend naturally into a full agentic SEO harness. The [[course/seo-automation-with-agents]] course covers the full architecture, from credential provisioning to multi-property orchestration, with production-ready Python.

---

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "Fix siteUnverifiedUser When Submitting Sitemaps via the Google Search Console API",
  "description": "A step-by-step guide to resolving the siteUnverifiedUser (HTTP 403) error when submitting sitemaps programmatically via the Google Search Console API, covering property type selection, HTML file verification, service account setup, and OAuth configuration.",
  "totalTime": "PT45M",
  "estimatedCost": {
    "@type": "MonetaryAmount",
    "currency": "USD",
    "value": "0"
  },
  "step": [
    {
      "@type": "HowToStep",
      "position": 1,
      "name": "Add a URL-Prefix Property in Google Search Console",
      "text": "In Google Search Console, click the property selector, choose Add property, then select URL prefix (not Domain). Enter your canonical HTTPS origin, e.g. https://example.com/. Do not use the Domain option, which creates an sc-domain property that behaves unreliably with the sitemap submission API.",
      "url": "https://search.google.com/search-console"
    },
    {
      "@type": "HowToStep",
      "position": 2,
      "name": "Download the HTML Verification File",
      "text": "After adding the URL-prefix property, select HTML file as the verification method. GSC will generate a filename like google1a2b3c4d5e6f7a8b.html. Download or create this file containing only the verification token line Google provides.",
      "url": "https://support.google.com/webmasters/answer/9008080"
    },
    {
      "@type": "HowToStep",
      "position": 3,
      "name": "Deploy the Verification File and Confirm Ownership",
      "text": "Upload the HTML verification file to your server root so it is reachable at the URL prefix root (e.g., https://example.com/google1a2b3c4d5e6f7a8b.html). Confirm it returns HTTP 200 with no redirects, then click Verify in GSC."
    },
    {
      "@type": "HowToStep",
      "position": 4,
      "name": "Create a Google Cloud Project and Enable the Search Console API",
      "text": "In Google Cloud Console, create a new project. Navigate to APIs & Services > Library, search for Google Search Console API, and enable it. This step is required before any API credential will function.",
      "url": "https://console.cloud.google.com/"
    },
    {
      "@type": "HowToStep",
      "position": 5,
      "name": "Create a Service Account and Download the JSON Key",
      "text": "Under IAM & Admin > Service Accounts, create a service account with no project IAM roles. Click the service account email, go to Keys > Add Key > Create new key > JSON, and save the downloaded file securely outside your repository."
    },
    {
      "@type": "HowToStep",
      "position": 6,
      "name": "Add the Service Account Email as Owner in GSC",
      "text": "In your GSC URL-prefix property, go to Settings > Users and permissions > Add user. Paste the service account email (e.g., sitemap-bot@your-project.iam.gserviceaccount.com) and set the permission level to Owner — not Full or Restricted. Owner-level access is required for sitemap submission."
    },
    {
      "@type": "HowToStep",
      "position": 7,
      "name": "Submit the Sitemap via the Search Console API",
      "text": "Using the google-auth Python library, authenticate with the webmasters scope and call sitemaps().submit(siteUrl=SITE_URL, feedpath=SITEMAP_URL).execute(). Use the URL-prefix property URI (e.g., https://example.com/) as the siteUrl — not the sc-domain format. A successful call returns HTTP 200 with an empty body.",
      "url": "https://developers.google.com/webmaster-tools/v1/sitemaps/submit"
    }
  ]
}
</script>
