---
date: 2026-06-01
author: blog-author
ticket: KOEA-7067
vendor_tag: community
content_type: article
status: draft-for-review
reading_time_min: 7-9
primary_query: "GSC sitemap submission programmatic agentic siteUnverifiedUser fix"
contrarian_angle: "siteUnverifiedUser has nothing to do with OAuth scopes — it is a GSC property permissions error. You can have a valid token, the correct scope, and the API enabled and still hit it. The fix is one line in the GSC UI: add your service account email as Owner, not User."
first_60_words_answer: "Google Search Console's siteUnverifiedUser error blocks programmatic sitemap submissions when the authenticated service account is not a verified owner of the GSC property. Fix it in two places: verify your property as URL-prefix (not sc-domain) using HTML file upload — sc-domain fails if your host is a CNAME node due to RFC 1912 — then add your service account email as Owner in GSC Settings › Users & Permissions."
original_data: true
last_updated: 2026-06-01
positions:
  - id: none
    engagement: neutral
hero_image:
  url: /img/blogs/gsc-sitemap-submission-agentic-siteunverifieduser/hero.png
  alt: "Diagram showing GSC siteUnverifiedUser error flow and the fix: URL-prefix property with HTML file verification plus service account Owner permission"
sources:
  - https://developers.google.com/webmaster-tools/v1/sitemaps/submit
  - https://support.google.com/webmasters/answer/9008080
  - https://developers.google.com/identity/protocols/oauth2/scopes
  - https://developers.google.com/identity/protocols/oauth2/service-account
  - https://www.ietf.org/rfc/rfc1912.txt
  - https://oxfordmosaic.web.ox.ac.uk/documentation/verify-ownership-google-search-console
  - https://www.eunit.me/blog/how-to-automatically-submit-sitemap-to-google-programmatically
whats_new:
  - "siteUnverifiedUser is a GSC property permissions error, not an OAuth scope error — sc-domain verification fails on CNAME-hosted subdomains because RFC 1912 §2.4 prohibits other records coexisting with a CNAME node; URL-prefix + HTML file verification is the reliable path"
learning_objectives:
  - "Understand why sc-domain verification fails when your hostname is a CNAME record and how URL-prefix avoids the conflict"
  - "Serve a GSC HTML verification file from a Next.js dynamic route so it survives deployments"
  - "Add a service account as a verified Owner in GSC and call the Sitemaps API without hitting siteUnverifiedUser"
faq:
  - question: "What is the siteUnverifiedUser error in Google Search Console API?"
    answer: "HTTP 403 with reason siteUnverifiedUser means the authenticated user or service account is not a verified owner of the GSC property it is trying to access. It is not an OAuth scope problem — having the webmasters scope is necessary but not sufficient. The account must also appear as an Owner in GSC Settings › Users & Permissions on the specific property. Source: Google Search Console API documentation."
  - question: "Why does sc-domain verification fail on Vercel or Cloudflare-hosted subdomains?"
    answer: "sc-domain properties require DNS-level verification (TXT record or CNAME token). RFC 1912 §2.4 states a CNAME record cannot coexist with any other DNS record at the same node. If your subdomain (e.g. academy.kspl.tech) is already defined as a CNAME pointing to Vercel or Cloudflare, most DNS providers will reject adding a TXT record at the same FQDN. Use a URL-prefix property with HTML file verification instead — it avoids DNS entirely. Source: IETF RFC 1912, GSC verification docs."
  - question: "Can I add a service account as a User instead of Owner in GSC?"
    answer: "No — not for API sitemap submission. The Search Console API's Sitemaps.submit endpoint requires the webmasters scope, and Google enforces that the authenticated identity must have siteOwner-level permissions on the property. Accounts added as Users (Full or Restricted) receive siteUnverifiedUser errors on write operations. Add the service account email as Owner in GSC Settings › Users & Permissions, then verify ownership from the GSC UI by clicking 'Verify' on the service account entry. Source: GSC API documentation, first-hand testing."
---

<!-- HowTo JSON-LD schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Fix GSC siteUnverifiedUser and Submit Sitemaps Programmatically",
  "description": "Fix the Google Search Console siteUnverifiedUser 403 error for agentic platforms: choose the right property type, verify via HTML file, create a service account, and submit sitemaps with the Search Console API.",
  "totalTime": "PT90M",
  "tool": [
    { "@type": "HowToTool", "name": "Google Search Console" },
    { "@type": "HowToTool", "name": "Google Cloud Console" },
    { "@type": "HowToTool", "name": "Node.js / TypeScript" }
  ],
  "step": [
    {
      "@type": "HowToStep",
      "position": 1,
      "name": "Understand why sc-domain fails on CNAME-hosted subdomains",
      "text": "RFC 1912 §2.4 prohibits any other DNS record coexisting with a CNAME node. If your subdomain is a CNAME, DNS TXT verification for sc-domain is blocked. Use URL-prefix instead."
    },
    {
      "@type": "HowToStep",
      "position": 2,
      "name": "Create a URL-prefix property in GSC",
      "text": "In Google Search Console, add a new property using URL-prefix format (https://academy.kspl.tech/). Choose HTML file upload as the verification method and download the token file."
    },
    {
      "@type": "HowToStep",
      "position": 3,
      "name": "Serve the HTML verification file from a dynamic route",
      "text": "Create a Next.js route handler at app/[gscToken]/route.ts that serves the verification file content so it survives deployments without committing secrets to the repo."
    },
    {
      "@type": "HowToStep",
      "position": 4,
      "name": "Complete verification and confirm siteOwner status",
      "text": "Click Verify in GSC. Confirm the property shows your Google account as a siteOwner in Settings › Users & Permissions before proceeding to API setup."
    },
    {
      "@type": "HowToStep",
      "position": 5,
      "name": "Enable the Search Console API and create a service account",
      "text": "In Google Cloud Console, enable the Google Search Console API, create a service account, and download the JSON key. Copy the service account email address."
    },
    {
      "@type": "HowToStep",
      "position": 6,
      "name": "Add the service account as Owner in GSC",
      "text": "In GSC Settings › Users & Permissions, add the service account email and set the permission level to Owner. Do not use User — API write calls require Owner level."
    },
    {
      "@type": "HowToStep",
      "position": 7,
      "name": "Submit sitemaps programmatically with the Search Console API",
      "text": "Use the service account JSON key to obtain a Bearer token scoped to https://www.googleapis.com/auth/webmasters, then call PUT /webmasters/v3/sites/{siteUrl}/sitemaps/{feedpath}."
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
      "name": "What is the siteUnverifiedUser error in Google Search Console API?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "HTTP 403 siteUnverifiedUser means the authenticated service account is not a verified owner of the GSC property. Having the webmasters OAuth scope is necessary but not sufficient — the account must also be added as Owner in GSC Settings › Users & Permissions."
      }
    },
    {
      "@type": "Question",
      "name": "Why does sc-domain verification fail on Vercel or Cloudflare-hosted subdomains?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "RFC 1912 §2.4 prohibits any other DNS record coexisting with a CNAME. If your subdomain is a CNAME record, DNS providers reject adding the TXT token sc-domain requires. Fix: use a URL-prefix property with HTML file verification — it avoids DNS entirely."
      }
    },
    {
      "@type": "Question",
      "name": "Can I add a service account as User instead of Owner in GSC for API access?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "No. The Sitemaps.submit API endpoint requires siteOwner-level permissions. Accounts added as Users (Full or Restricted) return siteUnverifiedUser on write operations. Add the service account email as Owner in GSC Settings › Users & Permissions."
      }
    }
  ]
}
</script>

# GSC Sitemap Submission for Agentic Platforms: Fixing siteUnverifiedUser (2026)

Google Search Console's `siteUnverifiedUser` error blocks programmatic sitemap submissions when the authenticated service account is not a verified owner of the GSC property. Fix it in two places: verify your property as URL-prefix — not sc-domain — using HTML file upload (sc-domain fails if your host is a CNAME node due to RFC 1912), then add your service account email as **Owner** in GSC Settings › Users & Permissions. The whole setup takes 90 minutes end-to-end.

Here's the thing most tutorials skip: `siteUnverifiedUser` is not an OAuth scope error. You can have a valid Bearer token, the `webmasters` scope enabled, and the Search Console API toggled on in your GCP project, and you will still hit `HTTP 403` with `"reason": "siteUnverifiedUser"` if the authenticated identity is not registered as a *verified owner* in GSC. We learned this the slow way on academy.kspl.tech. This walkthrough documents the path that works.

![GSC siteUnverifiedUser error fix diagram: URL-prefix verification path vs blocked sc-domain CNAME path](/img/blogs/gsc-sitemap-submission-agentic-siteunverifieduser/hero.png)

---

## The Root Cause: Two Separate Failure Modes

GSC sitemap submission fails in two distinct ways, and they require different fixes.

**Failure mode 1 — sc-domain blocked at DNS:** When you try to create a `sc-domain:academy.kspl.tech` property, GSC offers you TXT or CNAME verification. If `academy.kspl.tech` is a CNAME record in your DNS zone (pointing to Vercel, Cloudflare, or any other host), [RFC 1912 §2.4](https://www.ietf.org/rfc/rfc1912.txt) prohibits any other record — including TXT — from existing at the same node. Most DNS providers enforce this. The verification token never appears in DNS and GSC keeps spinning. The fix is not to fight the RFC; it's to use a different property type entirely.

**Failure mode 2 — siteUnverifiedUser despite valid OAuth:** Even after switching to a URL-prefix property and verifying it manually, programmatic API calls from a service account fail with `siteUnverifiedUser`. The OAuth layer is fine; the GSC property permissions layer rejects it. GSC has its own access control that runs orthogonally to GCP IAM.

Both failures have simple fixes. The 7 steps below walk them end-to-end.

---

## Step 1: Understand Why sc-domain Fails on CNAME-Hosted Subdomains

Google Search Console offers two property types:

| Type | Format | Covers | Verification methods |
|---|---|---|---|
| Domain | `sc-domain:example.com` | All subdomains, all protocols | DNS TXT or CNAME only |
| URL-prefix | `https://academy.kspl.tech/` | Exact URL prefix | HTML file, HTML tag, Analytics, TMS, DNS TXT |

Domain properties sound better — one property covering all of your subdomains. The catch: they require DNS-level verification, which requires writing a TXT or CNAME record at the subdomain node.

[RFC 1912 §2.4](https://www.ietf.org/rfc/rfc1912.txt) is explicit:

> "A CNAME record is not allowed to coexist with any other data."

If `academy.kspl.tech` is already defined as a CNAME (e.g., `academy.kspl.tech CNAME cname.vercel-dns.com`), adding a TXT record at the same FQDN violates the RFC. Most DNS providers will silently drop the record or return an error. Google's DNS verification check then fails to find the token and GSC never verifies the property.

**The fix:** Use URL-prefix. HTML file verification proves ownership without touching DNS.

---

## Step 2: Create a URL-Prefix Property in GSC

1. Open [Google Search Console](https://search.google.com/search-console) and click **Add property**
2. In the dialog, select **URL prefix** (not Domain)
3. Enter your full URL with protocol and trailing slash: `https://academy.kspl.tech/`
4. Click **Continue**
5. Under **Verification method**, select **HTML file**
6. Download the verification file — it will be named `google[alphanumeric-hash].html`
7. Note the filename and its required content (a single line like `google-site-verification: [token]`)

Do not close this dialog yet — you need to serve the file before GSC can verify.

---

## Step 3: Serve the HTML Verification File from a Dynamic Route

The naive approach — committing the `.html` file into `/public` — works but leaks the verification token into your repository. A cleaner pattern uses an environment variable and a route handler:

```typescript
// app/[gscToken]/route.ts
import { NextRequest, NextResponse } from 'next/server';

const GSC_VERIFICATION_FILENAME = process.env.GSC_VERIFICATION_FILENAME!;
// e.g. "google1a2b3c4d5e6f7890.html"
const GSC_VERIFICATION_CONTENT = process.env.GSC_VERIFICATION_CONTENT!;
// e.g. "google-site-verification: 1a2b3c4d5e6f7890abcdef1234567890"

export async function GET(
  request: NextRequest,
  { params }: { params: { gscToken: string } }
) {
  if (params.gscToken !== GSC_VERIFICATION_FILENAME) {
    return new NextResponse('Not found', { status: 404 });
  }

  return new NextResponse(GSC_VERIFICATION_CONTENT, {
    headers: { 'Content-Type': 'text/html' },
  });
}
```

Set both env vars in your deployment. Verify the route is live before proceeding:

```bash
curl -i https://academy.kspl.tech/google1a2b3c4d5e6f7890.html
# Expected: HTTP/2 200, body = "google-site-verification: ..."
```

---

## Step 4: Complete Verification and Confirm siteOwner Status

Return to the GSC dialog and click **Verify**. On success, the UI confirms "Ownership verified."

Before moving on, navigate to **Settings › Users & Permissions** on the newly verified property. Confirm that your Google account appears with the label **Owner** (not just User). This "Owner" status is what allows you to add other owners later in Step 6. If you see only "User," the verification is incomplete — revisit the HTML file and retry.

---

## Step 5: Enable the Search Console API and Create a Service Account

In [Google Cloud Console](https://console.cloud.google.com):

1. Select or create a GCP project tied to your organization
2. Navigate to **APIs & Services › Library**, search for "Google Search Console API," and click **Enable**
3. Go to **IAM & Admin › Service Accounts** and click **Create Service Account**
4. Give it a descriptive name: `academy-gsc-submitter@your-project.iam.gserviceaccount.com`
5. Skip the optional IAM role and user access steps for now
6. In the service account detail page, go to the **Keys** tab
7. Click **Add Key › Create new key**, select **JSON**, and click **Create**
8. A JSON credentials file downloads automatically — store it outside your repository (e.g., in your secrets manager or as a base64-encoded environment variable)
9. Copy the `client_email` field from the JSON file — you need it for Step 6

---

## Step 6: Add the Service Account as Owner in GSC

This is the step that fixes `siteUnverifiedUser`.

1. Open your verified URL-prefix property in GSC
2. Go to **Settings › Users & Permissions**
3. Click **Add user**
4. Paste the service account's `client_email` (e.g., `academy-gsc-submitter@your-project.iam.gserviceaccount.com`)
5. Set the permission level to **Owner** — **not** Full user, not Restricted user
6. Click **Add**

After adding the service account, it will appear with `Unverified` status. That is expected. Service accounts cannot perform the interactive verification steps that human accounts do — but they inherit the property's verification from the human owner who added them. GSC API calls from this service account will now succeed.

---

## Step 7: Submit Sitemaps Programmatically

With the service account credentials in place, call the [Sitemaps.submit endpoint](https://developers.google.com/webmaster-tools/v1/sitemaps/submit):

```typescript
// lib/gsc-sitemap.ts
import { google } from 'googleapis';

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL!;
// Must match exactly how the property is registered: "https://academy.kspl.tech/"

export async function submitSitemapToGSC(sitemapPath = '/sitemap.xml') {
  const auth = new google.auth.GoogleAuth({
    // Pass key as env var: base64-decode the JSON key file
    credentials: JSON.parse(
      Buffer.from(process.env.GSC_SERVICE_ACCOUNT_KEY_B64!, 'base64').toString()
    ),
    scopes: ['https://www.googleapis.com/auth/webmasters'],
  });

  const searchconsole = google.searchconsole({ version: 'v1', auth });
  const sitemapUrl = `${SITE_URL}${sitemapPath}`;

  await searchconsole.sitemaps.submit({
    siteUrl: SITE_URL,           // "https://academy.kspl.tech/"
    feedpath: sitemapUrl,        // "https://academy.kspl.tech/sitemap.xml"
  });

  return { submitted: sitemapUrl };
}
```

Or with a raw `curl` if you have a short-lived Bearer token:

```bash
ACCESS_TOKEN=$(gcloud auth print-access-token)
SITE_URL="https%3A%2F%2Facademy.kspl.tech%2F"
SITEMAP_URL="https%3A%2F%2Facademy.kspl.tech%2Fsitemap.xml"

curl -X PUT \
  "https://www.googleapis.com/webmasters/v3/sites/${SITE_URL}/sitemaps/${SITEMAP_URL}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Length: 0"
# Expected: HTTP/2 200, empty body
```

A `200` response with an empty body is correct — the API returns no JSON on success. Confirm receipt in GSC under **Sitemaps** in the left nav.

---

## Common Error Reference

| HTTP code | Reason | Fix |
|---|---|---|
| `403` | `siteUnverifiedUser` | Service account not added as Owner in GSC Settings › Users & Permissions |
| `403` | `forbidden` | Correct service account, wrong property URL — check that `siteUrl` matches exactly (including trailing slash, exact subdomain) |
| `400` | `invalidArgument` | `siteUrl` or `feedpath` is not URL-encoded; encode both parameters |
| `404` | property not found | Property not yet verified; complete Step 4 first |

---

## Knowledge Check

**Question:** Your service account has the `webmasters` OAuth scope and the Search Console API is enabled in GCP. GSC returns `HTTP 403 siteUnverifiedUser` when you call `sitemaps.submit`. You checked GSC and the service account appears in Settings › Users & Permissions. What is the most likely remaining issue?

<details>
<summary>Answer</summary>

The service account was added as a **User** (Full or Restricted), not as an **Owner**. GSC's Sitemaps.submit write endpoint requires siteOwner-level permissions — User-level access is read-only for API purposes. Edit the service account's permission level to Owner in GSC Settings › Users & Permissions. A secondary possibility: the `siteUrl` parameter in the API call doesn't exactly match the property's registered URL format — check for trailing slash, protocol, and subdomain alignment.

</details>

---

## Frequently Asked Questions

**What is the siteUnverifiedUser error?**
HTTP 403 `siteUnverifiedUser` from the GSC API means the authenticated identity is not a verified owner of the property. OAuth scope and GCP API enablement are not sufficient — the service account must appear as an Owner in GSC's own per-property access control. [Source: Google Search Console API docs](https://developers.google.com/webmaster-tools/v1/sitemaps/submit).

**Why does sc-domain verification fail on Vercel or Cloudflare subdomains?**
[RFC 1912 §2.4](https://www.ietf.org/rfc/rfc1912.txt) prohibits any DNS record coexisting with a CNAME at the same node. If your subdomain is defined as a CNAME, you can't add the TXT token sc-domain requires. Use URL-prefix + HTML file verification — it requires no DNS changes.

**Can a service account be added as User instead of Owner?**
No, not for API write operations. Sitemaps.submit requires siteOwner-level permissions. Accounts added as Users (Full or Restricted) receive `siteUnverifiedUser` on sitemap submission. Set the permission to Owner.

---

## What to Build Next

Now that GSC sitemap submission is automated, the next layer is ensuring your sitemap stays accurate as content publishes. Pair this GSC integration with IndexNow (covered in [[2026-06-01-how-to-deploy-indexnow-programmatic-url-submission]]) for a dual-submission pipeline: IndexNow notifies Bing, Yandex, Naver, and Seznam in real time; the GSC sitemap submission keeps Google's crawl queue current. Both run as Vercel cron jobs and share the same sitemap parsing utility. Our [[course/seo-for-ai-engineers]] course covers the full pipeline including llms.txt, passage-level schema, and AI crawler access controls.
