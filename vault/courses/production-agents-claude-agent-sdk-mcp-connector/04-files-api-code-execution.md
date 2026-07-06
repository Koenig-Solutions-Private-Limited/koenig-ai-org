---
course_slug: production-agents-claude-agent-sdk-mcp-connector
chapter_num: 4
chapter_slug: files-api-code-execution
title: "Files API + code execution: the complete agent IO surface"
description: "Use the Anthropic Files API and code execution tool to upload documents once, reference file IDs, process data, and download generated outputs."
tags: [files-api, code-execution, agent-io]
faq:
  - q: "Does the Files API reduce token costs?"
    a: "No. It reduces retransmission and latency, but referenced file content is still billed as input tokens."
  - q: "Can I download uploaded files?"
    a: "No. Anthropic documents downloads for files created by code execution or skills, not files you uploaded yourself."
  - q: "Which beta header does the Files API use?"
    a: "Use the files-api-2025-04-14 beta header on Files API requests."
status: g3-passed
last_updated: 2026-06-14
author: vardaan-koenig
agent_drafted_by: course-author
date: 2026-04-30
duration_min: 45
prerequisites_chapters: [1]
learning_objectives:
  - "Upload a PDF and a dataset to the Files API and reference both in a Messages call"
  - "Use the code execution tool to process an uploaded CSV and download the output chart"
  - "Apply the correct content block type (document, image, container_upload) for each file type"
  - "Explain the billing model: what is free, what is charged as tokens, and what is charged as runtime"
key_concepts:
  [files-api, file-id, content-blocks, code-execution, container-upload, billing-model, zdr-ineligibility]
hands_on_exercise: "Upload a PDF once, run three analytical queries against it in three separate Messages calls, and download an auto-generated summary chart"
sources:
  - https://platform.claude.com/docs/en/build-with-claude/files
  - https://claude.com/blog/agent-capabilities-api
  - https://platform.claude.com/docs/en/managed-agents/overview
  - https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool
  - https://platform.claude.com/docs/en/api/files-list
  - https://platform.claude.com/docs/en/build-with-claude/api-and-data-retention
  - https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/code-execution-tool
---

# Files API + code execution: the complete agent IO surface

The Anthropic Files API lets you upload a file once (up to 500 MB), receive a persistent `file_id`, and reference it across multiple Messages calls without retransmitting bytes. The savings are bandwidth and latency — you still pay full input tokens each time a `file_id` appears in a Messages request [1]. This chapter covers the complete IO surface: Files API for document persistence, code execution for computation, and downloading generated artifacts.

## Key facts

1. Beta header `files-api-2025-04-14` required on every request [1].
2. Max file size: 500 MB; workspace storage: 500 GB per org [1].
3. Storage operations (upload, download, list, delete) are **free**; file content is billed as input tokens on each Messages reference [1].
4. Code execution billed as container runtime (5-min minimum) plus normal token costs; verify current rate [7].
5. Files API: not eligible for ZDR; not available on Bedrock or Vertex AI; any workspace API key can delete any file [1].
6. You can only **download** files created by code execution or skills — not files you uploaded [1].

## Content block types by file format

Each file type maps to a specific content block — using the wrong one returns a 400 error:

| File type | MIME type | Content block | Use case |
|---|---|---|---|
| PDF | `application/pdf` | `document` | Document analysis, citations |
| Plain text | `text/plain` | `document` | Logs, markdown, config files |
| JPEG, PNG, GIF, WebP | `image/*` | `image` | Visual analysis, screenshots |
| CSV, datasets, binaries | varies | `container_upload` | Code execution, data analysis |

For `.docx`, `.xlsx`, `.md`: convert to plain text or PDF first.

```takeaways
- PDFs and plain text use the `document` content block type; images use `image`; files passed to code execution use `container_upload` — using the wrong type returns a 400 error.
- The Files API beta header `files-api-2025-04-14` is required on every request.
- Maximum file size is 500 MB per file; total workspace storage is 500 GB per organization.
```

## Uploading files

Install the Anthropic SDK (not the Agent SDK):

```python
pip install anthropic
```

Upload a PDF and an image:

```python
from anthropic import Anthropic

client = Anthropic()

# Upload a PDF
with open("quarterly_report.pdf", "rb") as f:
    pdf_file = client.beta.files.upload(
        file=("quarterly_report.pdf", f, "application/pdf"),
    )
print(f"PDF file_id: {pdf_file.id}")
# → file_011CNha8iCJcU1wXNR6q4V8w

# Upload a PNG chart
with open("chart.png", "rb") as f:
    image_file = client.beta.files.upload(
        file=("chart.png", f, "image/png"),
    )
print(f"Image file_id: {image_file.id}")
```

```typescript
import Anthropic, { toFile } from "@anthropic-ai/sdk";
import fs from "fs";

const anthropic = new Anthropic();

// Upload a PDF
const pdfFile = await anthropic.beta.files.upload({
  file: await toFile(
    fs.createReadStream("quarterly_report.pdf"),
    undefined,
    { type: "application/pdf" }
  ),
});
console.log(`PDF file_id: ${pdfFile.id}`);
```

The returned `file_id` is permanent until you delete it. Store it in your database alongside the document metadata.

## Referencing files in Messages calls

Once uploaded, reference the `file_id` using the appropriate content block type. You don't need the file's bytes — just the ID:

```python
# Three queries against the same PDF — only one upload needed
questions = [
    "What were the total revenues in Q1?",
    "List the top 3 risk factors mentioned in this report.",
    "What is management's outlook for Q2?",
]

for question in questions:
    response = client.beta.messages.create(
        model="claude-sonnet-4-5",
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": question},
                {
                    "type": "document",
                    "source": {
                        "type": "file",
                        "file_id": pdf_file.id,
                    },
                    "citations": {"enabled": True},  # request inline citations
                },
            ],
        }],
        betas=["files-api-2025-04-14"],
    )
    print(f"\n{question}")
    print(response.content[0].text)
```

For images, use the `image` content block type:

```python
response = client.beta.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=512,
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "Describe what this chart shows."},
            {
                "type": "image",
                "source": {
                    "type": "file",
                    "file_id": image_file.id,
                },
            },
        ],
    }],
    betas=["files-api-2025-04-14"],
)
```

<Callout type="warn">
Using an image `file_id` in a `document` block (or vice versa) returns a `400 invalid_request_error`. The content block type must match the file's MIME type. If you see this error, check that you're using `"type": "document"` for PDFs and text, and `"type": "image"` for image files.
</Callout>

## The billing reality

Storage operations are free. Every Messages call that references a `file_id` bills the file content as input tokens — 100 queries against the same PDF cost 100× the document's token price. Code execution adds container runtime cost on top. Use extended prompt caching (1-hour TTL) when querying the same document many times in one session to drop repeated calls to ~10% of full input price. For session-level cost controls and PreToolUse circuit breakers, see [[course/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability|Chapter 5]].

> **Sonnet 5 migration note:** The Sonnet 5 tokenizer produces approximately 30% more tokens for the same file content compared to Sonnet 4.x. If you migrate these examples to `claude-sonnet-5`, re-measure the per-file token count and rebaseline any cost estimates, `max_tokens` budgets, and prompt caching thresholds before deploying to production.

```takeaways
- File storage operations (upload, download, list, metadata, delete) are free; file content is billed as input tokens every time a `file_id` is referenced in a Messages request.
- The "upload once" pitch saves bandwidth and latency but not token cost — 100 queries against the same file cost 100× the document's token price.
- Enable 1-hour extended prompt caching when running many queries against the same document in one session to reduce per-call costs to approximately 10% of full input price.
- **Sonnet 5 caveat**: tokenizer produces ~30% more tokens per equivalent document — rebaseline cost estimates when migrating from 4.x.
```

## Code execution with the Files API

Unlike [[course/production-agents-claude-agent-sdk-mcp-connector/03-mcp-connector-multi-server|MCP tool servers in Chapter 3]] — which connect to external services — code execution runs within Anthropic's infrastructure. Pass files via `container_upload` blocks, run code, and download output files:

```python
# Upload a dataset for code execution
with open("sales_data.csv", "rb") as f:
    dataset = client.beta.files.upload(
        file=("sales_data.csv", f, "text/plain"),
    )

# Run code execution with the uploaded file
response = client.beta.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=4096,
    tools=[{"type": "code_execution_20250825", "name": "code_execution"}],
    messages=[{
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": "Load the CSV, compute monthly totals, and create a bar chart saved as monthly_totals.png",
            },
            {
                "type": "container_upload",
                "source": {
                    "type": "file",
                    "file_id": dataset.id,
                },
            },
        ],
    }],
    betas=["files-api-2025-04-14", "code-execution-2025-08-25"],
)

# Extract the output file_id from the response
for block in response.content:
    if hasattr(block, "type") and block.type == "tool_result":
        for content in block.content:
            if hasattr(content, "file_id"):
                output_file_id = content.file_id
                print(f"Output chart file_id: {output_file_id}")
```

Now download the generated chart:

```python
# Download the generated chart
chart_content = client.beta.files.download(output_file_id)
chart_content.write_to_file("monthly_totals.png")
print("Chart downloaded to monthly_totals.png")
```

<RunPromptCell
  model="claude-sonnet-4-5"
  prompt="I have a CSV with columns: month, product, revenue. Using the code execution tool, compute the top 3 products by total revenue and create a horizontal bar chart. Return the file_id of the saved PNG."
  expectedOutput="Claude writes Python code using pandas and matplotlib. The code reads the CSV from the container, computes `.groupby('product')['revenue'].sum().nlargest(3)`, generates a horizontal bar chart with `plt.barh()`, saves it as `top_products.png`. The tool_result block includes a `file_id` for the output PNG that can be passed to `client.beta.files.download()`."
/>

## File lifecycle management

Files persist until you explicitly delete them. For production agents, you need a retention policy:

```python
import datetime

def cleanup_old_files(client: Anthropic, max_age_days: int = 30):
    """Delete files older than max_age_days."""
    files = client.beta.files.list()
    cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=max_age_days)
    
    deleted = 0
    for file in files.data:
        created = datetime.datetime.fromisoformat(file.created_at)
        if created < cutoff:
            client.beta.files.delete(file.id)
            deleted += 1
    
    return deleted
```

<Callout type="info">
The Files API rate limit is approximately 100 requests per minute during the beta period. If you're bulk-uploading documents at ingestion time, add a delay between uploads or batch them during off-peak windows. Contact sales@anthropic.com for higher limits.
</Callout>

```takeaways
- Files persist until explicitly deleted; build a retention policy from day one to avoid hitting the 500 GB per-organization storage limit.
- A `cleanup_old_files()` function that checks `created_at` and deletes stale entries is the minimum viable retention policy for production agents.
- The Files API rate limit during beta is approximately 100 requests per minute; batch bulk uploads during off-peak windows if you need to ingest many documents at once.
```

## Extended prompt caching with Files API

Add `cache_control: {type: "ephemeral"}` to a document block to cache it. First call pays full token cost; subsequent calls within the TTL window pay ~10% of full input price:

```python
response = client.beta.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "What are the payment terms?"},
            {
                "type": "document",
                "source": {"type": "file", "file_id": pdf_file.id},
                "cache_control": {"type": "ephemeral"},  # cache this document
            },
        ],
    }],
    betas=["files-api-2025-04-14", "prompt-caching-2024-07-31"],
)
```

Cache is keyed on exact content — re-uploading a changed file resets it.

## Hands-on exercise

**Upload a PDF once and run three analytical queries; bonus: download a generated chart.**

1. Upload any PDF; store `file_id`
2. Query 1: "What is the main topic? Summarize in 3 sentences."
3. Query 2: "List all named organizations mentioned."
4. Query 3: "What are the 5 most important statistics?" with `citations: {enabled: true}`
5. **Bonus**: Pass Q2 org list as CSV to code execution; download output PNG

**Verify**: Same `file_id` in all 3 calls; Q3 includes inline citations. **Est. time**: 20 min (30 with bonus)

<KnowledgeCheck
  question="A developer uploads a 2 MB PDF to the Files API and then uses the same file_id in 50 separate Messages API calls over one month. Which costs does she pay?"
  options={[
    "Zero for the upload; input tokens for each of the 50 Messages calls",
    "Zero for everything — Files API uploads and reads are free",
    "A one-time upload fee + zero for the 50 calls",
    "Input tokens once for the upload; zero for subsequent calls (cached)"
  ]}
  correctIdx={0}
  explanation="File operations (upload, download, list, delete) are free. However, each of the 50 Messages API calls that reference the file_id charges the PDF's content as input tokens — same as if she'd sent the bytes inline. The savings are bandwidth (no 2 MB per request) and latency. To reduce the per-call token cost, enable extended prompt caching so calls 2–50 pay cache read rates instead of full input rates."
/>

<KnowledgeCheck
  question="You want to download a PNG chart that Claude generated during a code execution call. Describe the correct sequence of API calls, including the beta headers needed."
  options={["self-check"]}
  correctIdx={0}
  explanation="Self-check: (1) Make a Messages API call with the code_execution tool enabled and the beta headers `files-api-2025-04-14` and `code-execution-2025-08-25`. (2) In the response, find the tool_result block that contains a `file_id` for the generated output. (3) Call `GET /v1/files/{file_id}/content` with the header `anthropic-beta: files-api-2025-04-14` to download the PNG bytes. Note: you can only download files that were CREATED by code execution or skills — not files you uploaded yourself."
/>

## What's next

[[course/production-agents-claude-agent-sdk-mcp-connector/05-production-deploy-observability|Chapter 5]] covers production hardening: hooks, cost circuit breakers, and the deployment checklist.

## References

[1] Files API — https://platform.claude.com/docs/en/build-with-claude/files · retrieved 2026-04-30
[2] Agent Capabilities API announcement — https://claude.com/blog/agent-capabilities-api · retrieved 2026-04-30
[3] Claude Managed Agents Tools — https://platform.claude.com/docs/en/managed-agents/tools · retrieved 2026-04-30
[4] Code Execution Tool — https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool · retrieved 2026-04-30
[5] Files API Reference — https://platform.claude.com/docs/en/api/files-list · retrieved 2026-05-14
[6] Anthropic API and data retention — https://platform.claude.com/docs/en/build-with-claude/api-and-data-retention · retrieved 2026-05-14
[7] Current code execution tool reference — https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/code-execution-tool · retrieved 2026-05-27
