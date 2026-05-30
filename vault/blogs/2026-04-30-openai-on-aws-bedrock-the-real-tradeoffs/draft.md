---
date: 2026-04-30
last_updated: 2026-05-30
author: blog-author
ticket: KOE-23
vendor_tag: openai
content_type: article
status: published
reading_time_min: 6
primary_query: "OpenAI on AWS Bedrock auth IAM tradeoffs"
contrarian_angle: "Bedrock is not an OpenAI API drop-in — IAM/SigV4 replaces bearer tokens and your existing openai client will not work at all"
sources:
  - https://openai.com/index/openai-on-aws/
  - https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html
  - https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModel.html
  - https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html
  - https://aws.amazon.com/about-aws/whats-new/2026/04/bedrock-iam-cost-allocation/
hero_image: auto:flux
references:
  - n: 1
    title: "OpenAI on AWS — OpenAI Announcement"
    url: https://openai.com/index/openai-on-aws/
    retrieved: 2026-04-30
  - n: 2
    title: "What Is Amazon Bedrock — AWS Documentation"
    url: https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html
    retrieved: 2026-04-30
  - n: 3
    title: "InvokeModel API Reference — AWS Bedrock Runtime"
    url: https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModel.html
    retrieved: 2026-04-30
  - n: 4
    title: "Identity and Access Management for Amazon Bedrock — AWS IAM Guide"
    url: https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html
    retrieved: 2026-04-30
  - n: 5
    title: "Cost Allocation by IAM User and Role in Amazon Bedrock — AWS What's New"
    url: https://aws.amazon.com/about-aws/whats-new/2026/04/bedrock-iam-cost-allocation/
    retrieved: 2026-04-30
whats_new:
  - OpenAI GPT models now run on AWS Bedrock under IAM auth — not API keys — with data that never leaves your AWS region
learning_objectives:
  - Understand how Bedrock's IAM/SigV4 auth differs from OpenAI's native bearer-token model in practice
  - Know when migrating to Bedrock-hosted OpenAI models pays off and when it adds complexity without benefit
faq:
  - question: "Is OpenAI available on AWS Bedrock, and does it cost more than the direct API?"
    answer: "Yes — OpenAI GPT models, Codex, and Managed Agents are listed in the Bedrock foundation model catalog as of April 2026. Per-token rates are comparable to the native API, but you add AWS infrastructure overhead: IAM role setup, boto3 SDK integration, and CloudWatch observability dashboards. Teams already on AWS absorb this cost easily; teams without AWS infrastructure face substantial migration overhead."
  - question: "What are the real cost tradeoffs of OpenAI on AWS Bedrock vs the direct API?"
    answer: "Bedrock costs run through AWS billing with IAM-principal-tagged cost allocation — useful for multi-team FinOps. You lose the OpenAI usage dashboard's real-time rate-limit visibility and per-org spend forecasting. For regulated industries that already pay AWS enterprise commit rates, Bedrock can reduce net AI spend. For everyone else, the native API is cheaper to operate end-to-end."
  - question: "When should you choose Bedrock over the direct OpenAI API?"
    answer: "Choose Bedrock when your workloads already run on IAM roles, data residency rules prohibit sending prompts to non-AWS endpoints (HIPAA, FedRAMP, financial services SOC 2), or you need Bedrock Guardrails applied uniformly across Claude, Titan, and OpenAI models. Stay on the native API when you have no existing AWS infrastructure, need the OpenAI usage dashboard, or want to avoid AWS lock-in."
  - question: "How does Bedrock's IAM and SigV4 auth differ from OpenAI's native bearer-token model?"
    answer: "Bedrock requires AWS SigV4 request signing via IAM roles instead of a simple bearer token — adding infrastructure complexity but gaining enterprise access controls, audit logging, and VPC network isolation that OpenAI's direct API does not provide."
positions:
  - stance: cost-inexpensive
    body: "Bedrock-hosted OpenAI models carry hidden infrastructure overhead — IAM role management, SigV4 signing, CloudWatch dashboard setup. For teams without existing AWS investment, the native OpenAI API is meaningfully cheaper to operate and maintain."
  - stance: open-closed-prefer-oss
    body: "Bedrock deepens AWS lock-in; teams that prefer multi-cloud or open-source-first strategies should default to the native OpenAI API or evaluate open-weight alternatives before committing to Bedrock's proprietary auth and observability stack."
---

# OpenAI on AWS Bedrock: IAM Auth Is the Real Engineering Work (2026)

**OpenAI on AWS Bedrock replaces API-key auth with IAM/SigV4 — your existing `openai` Python client will not work against a Bedrock endpoint.** The core tradeoff: Bedrock gives you AWS data residency, IAM audit logging, and Bedrock Guardrails; it costs you the OpenAI usage dashboard and adds real infrastructure complexity. For teams already running AWS workloads, this is a net win. For everyone else, it is overhead with no payoff.[^1]

The announcement says "AWS customers can deploy OpenAI capabilities natively." The engineering reality is that you are swapping one auth model for a fundamentally different one — SigV4-signed requests, IAM role policies, and a new observability surface. Most teams find out the hard way when their first `openai.ChatCompletion.create()` call returns a 403 from a Bedrock endpoint.

## Key facts

- OpenAI models (including `gpt-oss-20b`), Codex, and Managed Agents are now listed in the Bedrock foundation model catalog.[^2]
- Bedrock uses AWS IAM/SigV4 authentication — **no OpenAI API keys accepted**.
- Data stays in your chosen AWS region; requests do not transit OpenAI's infrastructure.
- Bedrock Guardrails (content filtering, PII redaction, topic blocks) can be applied to OpenAI models just like any other Bedrock model.
- Cost is attributed via AWS billing — not the OpenAI usage dashboard.
- IAM cost allocation by principal (user or role) is now available in Cost Explorer and CUR 2.0.[^5]

## The auth flip: from bearer token to SigV4

OpenAI's native API is a bearer-token model: set `OPENAI_API_KEY`, attach it as an `Authorization` header, done. Bedrock is built on AWS Signature Version 4 — every request is cryptographically signed with temporary IAM credentials. Here is what that difference looks like:

**Native OpenAI SDK:**

```python
import openai

client = openai.OpenAI(api_key="sk-...")
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Summarize this contract."}]
)
```

**Same call routed through Bedrock (boto3):**

```python
import boto3, json

bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")
# No API key — credentials come from the ambient IAM identity:
# EC2 instance profile, Lambda execution role, or sts:AssumeRole.
response = bedrock.invoke_model(
    modelId="openai.gpt-oss-20b",
    contentType="application/json",
    accept="application/json",
    body=json.dumps({
        "messages": [{"role": "user", "content": "Summarize this contract."}]
    })
)
result = json.loads(response["body"].read())
```

The boto3 call requires an IAM identity with `bedrock:InvokeModel` on the target model ARN.[^3] That identity is typically an IAM role assumed by your workload — an EC2 instance profile, a Lambda execution role, or a role acquired via `sts:AssumeRole`.[^4] Temporary credentials rotate automatically; there is no secret to rotate by hand. This is strictly more secure than a long-lived API key — but the operational surface is larger. You now manage IAM policies, trust relationships, and permission boundaries instead of a secret store entry.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I've just moved OpenAI API calls to AWS Bedrock using boto3 and IAM roles. List the three most common IAM policy mistakes teams make when first granting bedrock:InvokeModel access, and explain how to fix each one."
  expectedOutput="A numbered list of three IAM pitfalls with concrete fixes — for example: using resource wildcards instead of scoping to specific model ARNs, attaching policies directly to IAM users rather than roles, and forgetting to grant sts:AssumeRole on the execution role so the calling service can actually obtain credentials."
/>

## Observability: CloudWatch, not the OpenAI dashboard

When you use OpenAI's native API, usage data flows to your OpenAI dashboard — token counts, latency percentiles, error rates, rate-limit proximity. Via Bedrock that pipeline is severed. **Your observability surface is now CloudWatch and AWS Cost Explorer.**

What you gain: Bedrock now supports cost allocation by IAM principal in Cost Explorer and CUR 2.0.[^5] Tag inference costs to a team, project, or application with IAM principal tagging — something the OpenAI API only approximates through per-key attribution. For FinOps teams running multi-team AI platforms, this is a real advantage that the native API cannot match.

What you lose: the OpenAI usage dashboard's per-model latency breakdowns, organization-level spend forecasting, and real-time rate-limit visibility do not exist out of the box in CloudWatch. You build those dashboards yourself via CloudWatch Logs Insights or CUR 2.0 exports to Athena. Budget accordingly — this is a non-trivial observability engineering task for a first migration.

See [[research/openai/2026-04-29]] for the original research note that flagged this announcement as a hot signal.

## When Bedrock-hosted OpenAI models make sense

**Migrate to Bedrock when:**

- Your workloads already run on IAM roles and SigV4. Adding another bearer-token secret is the actual overhead.
- Data residency is non-negotiable — regulated industries (HIPAA, FedRAMP, financial services SOC 2) often prohibit sending data to non-AWS API endpoints. Bedrock keeps all inference inside your VPC.
- You want cross-model Guardrails applied uniformly. Bedrock Guardrails (content filtering, PII redaction, denied topics) apply the same policy to Claude, Titan, and now OpenAI models through one configuration. You cannot attach a Bedrock Guardrail to a native OpenAI API call.

**Stay on the native OpenAI API when:**

- You have no existing AWS infrastructure. Acquiring IAM credentials, configuring boto3, and debugging SigV4 errors purely to access a model you can already reach with one env var is negative ROI.
- You need OpenAI's usage dashboard for real-time rate-limit visibility or organization-level token accounting. That data is not available through Bedrock.
- You are building a multi-cloud application where AWS lock-in is itself a risk. Bedrock deepens AWS dependency; the native API keeps your options open.

This decision mirrors the pattern in [[course/claude-tool-use-from-zero]] where the same tradeoff applies to Claude: Bedrock-hosted Claude vs direct Anthropic API. The auth and observability shape is identical — the IAM patterns transfer directly.

<KnowledgeCheck
  question="Why does your existing openai Python client fail when pointed at an AWS Bedrock endpoint?"
  options={[
    "Bedrock uses a different JSON schema for chat messages",
    "Bedrock requires IAM/SigV4-signed requests, not OpenAI bearer-token headers",
    "OpenAI models are only available in Bedrock via the Converse API, not InvokeModel",
    "Bedrock throttles requests from non-AWS IP addresses"
  ]}
  correctIdx={1}
  explanation="Bedrock authenticates all requests using AWS SigV4, which signs the request with IAM credentials. The openai SDK sends an Authorization: Bearer <key> header that Bedrock does not recognise. You must use boto3 (or another AWS SDK) to generate valid SigV4-signed requests."
/>

## What to do next

If you are evaluating this migration, start by auditing which OpenAI API calls already run inside an existing AWS workload — Lambda functions, ECS tasks, SageMaker pipelines. Those are the natural first candidates because the IAM identity is already there. Verify credential acquisition works before writing inference code: `aws sts get-caller-identity` should return the expected role ARN from your workload environment.

For teams new to both Bedrock and multi-model IAM patterns, [[course/claude-tool-use-from-zero]] walks through the foundational patterns — including how to structure IAM policies for model inference, when Bedrock's cross-model Guardrails justify the migration cost, and how to instrument CloudWatch dashboards for LLM observability. The same AWS patterns that govern Claude on Bedrock now govern OpenAI models too.

## Further Reading

[^1]: OpenAI, "OpenAI on AWS," https://openai.com/index/openai-on-aws/
[^2]: Amazon Bedrock, "What is Amazon Bedrock — Supported models," https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html
[^3]: AWS Bedrock API Reference, "InvokeModel," https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModel.html
[^4]: AWS IAM User Guide, "Identity and access management for Amazon Bedrock," https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html
[^5]: AWS, "Cost allocation by IAM user and role in Amazon Bedrock," https://aws.amazon.com/about-aws/whats-new/2026/04/bedrock-iam-cost-allocation/
