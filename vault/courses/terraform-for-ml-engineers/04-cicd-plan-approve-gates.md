---
chapter_num: 4
course_slug: terraform-for-ml-engineers
title: "Integrating Terraform into a CI/CD Review Workflow with Plan-Then-Approve Gates"
status: awaiting-g0
duration_min: 10
vendor_tag: "HashiCorp Terraform / GitHub Actions"
learning_objectives:
  - "Configure a GitHub Actions pipeline that runs terraform fmt -check, validate, and plan on every pull request"
  - "Post terraform plan output as a PR comment artifact visible to all repository collaborators"
  - "Place the manual approval gate on the apply job so reviewers see the full diff before approving"
  - "Inject cloud credentials and sensitive variables using TF_VAR_ environment variables sourced from GitHub secrets"
  - "Diagnose and fix Error: No value for required variable failures in CI pipelines"
sources:
  - url: "https://developer.hashicorp.com/terraform/cli/commands/fmt"
    title: "terraform fmt CLI Reference — HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/validate"
    title: "terraform validate CLI Reference — HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/plan"
    title: "terraform plan CLI Reference — HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/language/values/variables"
    title: "Input Variables — Terraform Language Reference"
  - url: "https://developer.hashicorp.com/terraform/language/manage-sensitive-data"
    title: "Manage Sensitive Data in Terraform — HashiCorp Developer"
  - url: "https://github.com/hashicorp/setup-terraform"
    title: "hashicorp/setup-terraform GitHub Action"
  - url: "https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment"
    title: "Managing environments for deployment — GitHub Docs"
  - url: "https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions"
    title: "Using secrets in GitHub Actions — GitHub Docs"
owns:
  - "GitHub Actions (or equivalent) pipeline for terraform fmt -check / validate / plan on PR"
  - "posting terraform plan output as a PR comment artifact"
  - "manual approval gate placement between plan and apply stages"
  - "storing cloud credentials and API keys as CI secrets"
  - "confirming sensitive variables never appear in plan output"
  - "diagnosing and fixing missing-required-variable failures in CI"
defers_to:
  - "remote state backend setup → ch2"
  - "module authoring → ch3"
  - "HCL syntax and provider pinning → ch1"
  - "drift reconciliation and terraform import → ch5"
quiz_topics:
  - "what terraform fmt -check does and when it fails"
  - "why plan output is posted as a PR comment rather than just CI logs"
  - "how to pass a secret Terraform variable in GitHub Actions without leaking it"
  - "placement of the manual approval gate: before plan, after plan, or after apply"
  - "how to diagnose 'Error: No value for required variable' in a CI run"
notebooklm_source_focus:
  - "GitHub Actions workflow syntax for Terraform"
  - "Terraform GitHub Actions official action documentation"
  - "HashiCorp best practices for secrets in CI/CD"
  - "terraform fmt / validate CLI reference"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "terraform fmt -check -recursive exits non-zero when:"
    options:
      - "Any .tf file in the directory tree deviates from canonical Terraform format"
      - "The Terraform binary version is newer than the provider version constraints allow"
      - "Any module source URL is unreachable from the CI runner network connection"
      - "The required_providers block is absent from the root module configuration"
    correct_idx: 0
    explanation: "terraform fmt -check validates formatting only — it never modifies files and makes no network calls. It exits non-zero and prints the names of any files that deviate from canonical format."
    section_anchor: the-four-stage-validation-funnel
  - question: "Plan output is posted as a PR comment rather than left in CI logs primarily because:"
    options:
      - "CI logs expire after ninety days, making them unavailable for future compliance audits"
      - "PR comments are visible to all repository collaborators while CI logs require pipeline access"
      - "The GitHub Actions log viewer cannot display HCL syntax with correct color highlighting"
      - "Plan output files routinely exceed GitHub's maximum CI artifact retention size limit"
    correct_idx: 1
    explanation: "CI logs require pipeline read access to view. A PR comment is visible to every collaborator with repository read permission — the right audience for an infra change review."
    section_anchor: posting-plan-output-as-a-pr-comment
  - question: "In the plan-then-approve pattern, the manual approval gate should be placed on:"
    options:
      - "The fmt-check job, so malformed files are blocked before any team review begins"
      - "The validate job, before any credentials or provider network calls are required"
      - "The apply job, after plan runs and posts its diff as a PR comment"
      - "The plan job with deployment: false to gate the diff before it is posted"
    correct_idx: 2
    explanation: "The gate must be on the apply job. Reviewers need to see the plan diff before approving. Placing the gate before plan means approving without information; placing it after apply is too late to prevent mistakes."
    section_anchor: placing-the-approval-gate-correctly
  - question: "Which method correctly passes a sensitive Terraform variable in GitHub Actions without leaking it?"
    options:
      - "Write the secret value directly to a .tfvars file inside the workflow run"
      - "Pass the secret using a -var flag argument on the terraform plan command line"
      - "Set a TF_VAR_name environment variable sourced from an encrypted GitHub secret"
      - "Declare default as an empty string and override the value via a step output"
    correct_idx: 2
    explanation: "TF_VAR_ environment variables sourced from GitHub secrets are masked in runner logs automatically and never appear in process argument lists. The -var flag approach is risky because the value is visible in the process command line."
    section_anchor: storing-secrets-safely-in-ci
  - question: "Error: No value for required variable during a CI plan most commonly means:"
    options:
      - "The variable is marked sensitive = true and is restricted from reading in CI runtime"
      - "A required input variable has no default and no matching TF_VAR_ env var in the workflow"
      - "The GitHub Actions runner cannot reach the Terraform provider authentication endpoint from the CI network"
      - "The .tfvars file references a remote backend that was not initialised in this run"
    correct_idx: 1
    explanation: "Terraform emits this error when an input variable declared without a default receives no value from any source. In CI the cause is almost always a missing or misspelled TF_VAR_ env var or the referenced GitHub secret not existing in the repository."
    section_anchor: diagnosing-missing-variable-failures-in-ci
---

## The Four-Stage Validation Funnel

Every PR touching Terraform configuration should pass four sequential checks before a human reviewer opens the diff. Think of them as a funnel: each stage is faster and cheaper than the next, and each catches a different failure class.

[`terraform fmt -check -recursive`](https://developer.hashicorp.com/terraform/cli/commands/fmt) reads every `.tf` file in the directory tree and exits non-zero if any file deviates from canonical Terraform style. It makes zero network calls, completes in under a second, and never modifies files — it only reports. If the check fails, the PR is blocked; the engineer fixes locally by running `terraform fmt -recursive`, then pushes again.

`terraform validate` parses the configuration and verifies type constraints, attribute names, and module structure. No provider API calls, no backend access, no credentials required — safe to run on every fork and external PR. It exits non-zero with a machine-readable JSON report when it finds a problem.

`terraform init -input=false` initialises providers and the backend, the first step that may need credentials to reach the remote state backend. (Remote state backend setup is covered in [[02-remote-state-locking-ml-teams]].)

`terraform plan -no-color -input=false` contacts the provider APIs and produces the actual resource diff. This is the most expensive step; the three earlier stages catch the majority of issues before you pay for it.

The `-input=false` flag is **required on every CI plan and apply**. Without it, Terraform blocks on stdin waiting for missing variable values. On a non-interactive CI runner there is no stdin, so the job hangs until the runner timeout kills it.

<KnowledgeCheck question="Which of the four pipeline stages makes no network calls AND requires no credentials?" options={["terraform fmt -check", "terraform validate", "terraform init", "terraform plan"]} correctIdx={1} explanation="terraform validate checks syntax and type constraints using only local configuration files — no provider API calls, no backend access, and no credentials needed. terraform fmt -check is also credential-free, but validate is the formal syntax and type checker."/>

## Posting Plan Output as a PR Comment

CI logs require pipeline read access to view. A PR comment is visible to every collaborator with repository read permission. That asymmetry is the reason the canonical pattern posts plan output as a PR comment: **reviewers must see exactly what will change before deciding whether to approve the merge**.

The [`hashicorp/setup-terraform`](https://github.com/hashicorp/setup-terraform) action installs a shim — enabled by default via `terraform_wrapper: true` — that captures `stdout`, `stderr`, and `exitcode` as step outputs. Your comment-posting step accesses `${{ steps.plan.outputs.stdout }}` and embeds the full diff inside a collapsible `<details>` block, giving reviewers a clean summary table at the top and the full diff on demand.

One constraint to plan around: GitHub PR comments are capped at 65,535 characters. Large ML infrastructure — GPU clusters, dozens of S3 buckets, dozens of IAM policies — routinely exceeds this limit. The safe fallback is to write full output to `$GITHUB_STEP_SUMMARY` and post only a resource-count summary (`Plan: 3 to add, 1 to change, 0 to destroy`) as the PR comment body.

<Callout type="warning">Never use `terraform plan -out=planfile` in CI and treat the file as safe to log. The binary plan file stores sensitive variable values in cleartext. Committing or logging a `.tfplan` file exposes credentials. If you need a saved plan for a two-step apply, store it as an encrypted CI artifact with restricted access.</Callout>

## Placing the Approval Gate Correctly

A GitHub Actions environment with *required reviewers* pauses any job that references it until at least one of up to six authorised reviewers clicks **Approve and deploy**. Configure the gate by creating a `production` environment under **Settings → Environments → New environment**, adding required reviewers, and setting `environment: production` on the apply job. According to the [GitHub Docs](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment), only one of the configured reviewers must approve for the job to proceed.

The gate belongs on the **apply job only**. Three wrong placements are common:

- **Before plan:** Reviewers see nothing yet. They are approving a blank cheque.
- **After apply:** The change already happened. The gate is now a post-mortem notification.
- **On the plan job:** Any job that references an environment with required reviewers will pause for approval — including a plan job. Setting `environment: { name: production, deployment: false }` suppresses creation of a deployment record but does *not* bypass required reviewers; the plan job still waits for approval. To let the plan stage run unblocked, reference a separate environment without required reviewers, or inject credentials as repository-level secrets.

The canonical job dependency graph: the plan job runs on every PR, reads credentials from repository-level secrets or a gate-free environment, and posts the diff as a comment. The apply job declares `needs: plan`, runs only on push to `main`, and pauses for reviewer approval before executing.

<KnowledgeCheck question="What does `deployment: false` on a GitHub Actions environment job actually suppress?" options={["The required-reviewer approval gate — the job runs without pausing for review", "Creation of a deployment record in GitHub's deployments history", "All environment protection rules including wait timers and branch policies", "Access to environment secrets — use repository-level secrets instead"]} correctIdx={1} explanation="deployment: false suppresses creation of a GitHub deployment record (which would otherwise appear in the Deployments tab and trigger deployment notifications), but does NOT bypass required-reviewer gates. If the environment has required reviewers configured, the job still pauses for approval. To run a plan job without gating, use a separate environment without required reviewers or inject credentials as repository-level secrets."/>

## Storing Secrets Safely in CI

Cloud credentials and Terraform input variables such as database passwords or ML platform API keys must never appear in `.tf` files, `.tfvars` files, or workflow YAML values committed to the repository.

The correct injection path uses two layers. First, [GitHub secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions) store encrypted values at rest; any attempt to `echo` a secret in a workflow step is automatically masked as `***` in the runner output. Second, `TF_VAR_<name>` environment variables map those secrets to [Terraform input variables](https://developer.hashicorp.com/terraform/language/values/variables) without a `.tfvars` file. The mapping `TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}` sets `var.db_password` in your HCL. The name after `TF_VAR_` is **case-sensitive** and must match the `variable` block declaration exactly.

Pair this with `sensitive = true` on the HCL variable declaration and Terraform replaces the value with `(sensitive value)` in all plan and apply CLI output — confirming the secret never surfaces in the PR comment or CI logs.

Important caveat: [`sensitive = true`](https://developer.hashicorp.com/terraform/language/manage-sensitive-data) suppresses CLI output only. The actual value is still persisted in the state file. Running `terraform output -raw var_name` prints the plaintext value, bypassing redaction. For credentials that must never touch state at all, Terraform 1.10+ offers `ephemeral = true`. State encryption and access control are covered in [[02-remote-state-locking-ml-teams]].

## Diagnosing Missing-Variable Failures in CI

```
Error: No value for required variable
 The root module input variable "db_password" is not set, and has no default value.
```

This error means a Terraform input variable declared without a `default` received no value from any source. In CI it almost always traces to a missing or misspelled secret. Follow this diagnostic path:

1. Find the variable name in `variables.tf` — e.g., `variable "db_password"`.
2. Locate the corresponding `TF_VAR_db_password` entry in the workflow `env:` block.
3. Confirm the referenced secret (e.g., `secrets.DB_PASSWORD`) exists under **Settings → Secrets and variables → Actions**.
4. Check case: `TF_VAR_db_Password` ≠ `TF_VAR_db_password`. The name after `TF_VAR_` is case-sensitive.

A second variant appears on forks: forked repositories do not inherit parent repository secrets. PRs from external contributors will always fail for any required secret variable. Address this with fork-aware workflow conditions (`if: github.event.pull_request.head.repo.full_name == github.repository`) or by declaring safe defaults only for non-sensitive configuration variables.

---

## Hands-On Exercise: Wire a Plan-Then-Approve Pipeline

**Goal:** Create a two-job GitHub Actions workflow for a single S3 bucket with a plan-then-approve gate wired end-to-end.

**Steps:**

1. Create `.github/workflows/terraform.yml`. The `plan` job runs on `pull_request` to `main` with no `environment` attribute — credentials are injected directly from repository-level secrets so the job never pauses for approval. The `apply` job runs on `push` to `main`, declares `needs: plan`, and sets `environment: production`.
2. Create a GitHub environment named `production` under **Settings → Environments** and add yourself as a required reviewer.
3. Add a Terraform variable `bucket_suffix` (type `string`, no default) to `variables.tf`. Store a value as a GitHub Actions secret named `BUCKET_SUFFIX`. Wire `TF_VAR_bucket_suffix: ${{ secrets.BUCKET_SUFFIX }}` in both job `env:` blocks.
4. Open a PR with a trivial change. Confirm the plan job posts a PR comment showing the resource diff with no secret values visible.
5. Merge the PR. Confirm the apply job enters a paused state requiring your approval, then approve and verify the bucket is created.

**Success criteria:**
- The PR comment displays `Plan: 1 to add, 0 to change, 0 to destroy` with `(sensitive value)` replacing any secret variable.
- The apply job pauses at the approval gate and does not execute `terraform apply` until you click **Approve and deploy**.
- The Terraform state shows the bucket after apply completes, with no secret value visible in the PR comment thread.

Next: [[05-drift-detection-remediation]].
