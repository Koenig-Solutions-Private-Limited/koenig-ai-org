---
chapter_num: 2
course_slug: terraform-for-ml-engineers
title: "Managing Shared Remote State with Locking for Multi-Engineer ML Teams"
status: g0-passed
duration_min: 13
vendor_tag: HashiCorp Terraform
learning_objectives:
  - "Configure an S3 backend with native locking and a GCS backend for shared ML infrastructure state"
  - "Migrate existing local state to a remote backend safely using terraform init -migrate-state"
  - "Explain what happens when two engineers apply simultaneously and how locking prevents state corruption"
  - "Choose between CLI workspaces and directory-per-environment isolation for ML dev/staging/prod"
  - "Detect state drift with terraform plan -refresh-only and decide whether to accept or reject it"
sources:
  - url: "https://developer.hashicorp.com/terraform/language/backend/s3"
    title: "Backend Type: s3 — Terraform HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/language/backend/gcs"
    title: "Backend Type: gcs — Terraform HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/init"
    title: "Command: init — Terraform HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/workspaces"
    title: "Managing Workspaces — Terraform HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/refresh"
    title: "Command: refresh — Terraform HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/language/state/locking"
    title: "State: Locking — Terraform HashiCorp Developer"
  - url: "https://gruntwork.io/blog/how-to-manage-terraform-state"
    title: "How to Manage Terraform State — Gruntwork Blog"
  - url: "https://spacelift.io/blog/terraform-state-lock"
    title: "Terraform State Lock: How It Works & Best Practices — Spacelift"
  - url: "https://spacelift.io/blog/terraform-workspaces"
    title: "What are Terraform Workspaces? Overview with Examples — Spacelift"
owns:
  - "remote backend configuration: S3 + DynamoDB and GCS with locking"
  - "state migration using terraform init -migrate-state"
  - "state locking mechanism and simulating concurrent apply conflicts"
  - "workspace vs directory-per-environment isolation patterns"
  - "terraform refresh to detect and recover from stale state"
  - "diagnosing plan failures caused by state drift"
defers_to:
  - "HCL syntax and provider pinning → ch1"
  - "module variable patterns → ch3"
  - "CI pipeline secrets management → ch4"
  - "lifecycle preconditions and import-based remediation → ch5"
quiz_topics:
  - "S3 + DynamoDB vs GCS locking: what each component does"
  - "what happens when two engineers apply simultaneously without locking"
  - "workspace vs directory-per-env trade-offs for ML dev/staging/prod"
  - "step-by-step terraform init -migrate-state walkthrough"
  - "when to use terraform refresh vs terraform plan to detect drift"
notebooklm_source_focus:
  - "Terraform remote backend documentation (S3, GCS)"
  - "DynamoDB state locking design"
  - "terraform workspaces vs directory isolation patterns"
  - "terraform refresh CLI reference"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "On GCS, what enables Terraform state locking?"
    options:
      - "A separate Cloud Spanner table configured in the backend block"
      - "Object versioning enabled on the GCS storage bucket"
      - "Automatic .tflock files created by GCS with no extra service"
      - "A google_kms_key_ring resource declared in the backend block"
    correct_idx: 2
    explanation: "GCS backends create .tflock files automatically alongside each state file. Unlike the (now-deprecated) DynamoDB approach for S3, no external service or extra flag is required — locking is on by default."
    section_anchor: remote-backend-configuration-s3-and-gcs
  - question: "What does terraform init -reconfigure do to existing state?"
    options:
      - "It copies existing state to the new backend, prompting for confirmation"
      - "It silently discards the old state and starts the new backend fresh"
      - "It creates a .terraform backup of existing state before migrating"
      - "It compares old and new backend configs and merges them if compatible"
    correct_idx: 1
    explanation: "-reconfigure ignores the old state file. Your live infrastructure is unchanged but Terraform loses track of it — the next plan shows everything as new creates. Use -migrate-state when changing backends on an existing workspace."
    section_anchor: migrating-existing-state-to-a-remote-backend
  - question: "When two engineers run terraform apply simultaneously against the same remote state, what happens to the second apply?"
    options:
      - "Both applies run in parallel and Terraform merges the two state files"
      - "The second apply pauses automatically until the first apply completes"
      - "The second apply fails immediately with a state file not found error"
      - "The second apply fails with a lock error showing the first engineer's metadata"
    correct_idx: 3
    explanation: "The first apply acquires a lock. The second cannot acquire the same lock and exits immediately with an error containing the holding engineer's username, operation type, and lock UUID. There is no automatic queue or retry."
    section_anchor: how-state-locking-works-in-practice
  - question: "Which is the strongest reason to use directory-per-environment instead of CLI workspaces for ML prod/staging/dev?"
    options:
      - "Workspaces store all environment state in one file; directories use one per environment"
      - "Workspaces cannot run terraform plan, which requires the directory layout"
      - "All workspaces share the same backend credentials, so IAM roles cannot be isolated"
      - "The terraform.workspace variable is unavailable in workspaces, limiting environment config"
    correct_idx: 2
    explanation: "CLI workspaces share one backend configuration and one IAM role. Selecting a workspace named dev does not prevent writes to prod if both share credentials. Directory-per-environment gives each environment its own backend config and IAM policy."
    section_anchor: workspace-vs-directory-per-environment-isolation
  - question: "You suspect someone scaled your ML training cluster from the AWS console. Which command is the correct first step?"
    options:
      - "terraform refresh — reads live infrastructure and auto-approves all state changes"
      - "terraform plan -refresh-only — reads live infra and shows drift without state changes"
      - "terraform state pull — downloads state and diffs it against the latest plan"
      - "terraform apply — detects and corrects any drift in a single combined step"
    correct_idx: 1
    explanation: "terraform plan -refresh-only is a non-destructive drift probe. It reports what would change in state to match live infra but makes no changes. The standalone terraform refresh command is deprecated and auto-approves state changes without confirmation."
    section_anchor: detecting-and-recovering-from-state-drift
---

## Why Local State Breaks Multi-Engineer ML Teams

When three engineers share a local `terraform.tfstate` committed to git, concurrent applies are a silent data race. Priya commits a lifecycle-policy change to the model-artifact S3 bucket; Karan applies a cluster scale-out five minutes later from a stale local copy. Karan's apply completes last and overwrites Priya's write — the lifecycle change is gone, and stale model artifacts start accumulating. No error, no warning.

Local state has two structural problems: no locking and no single source of truth. A remote backend solves both. The state file lives in a shared object store (S3 or GCS), and every write operation acquires a lock before touching it.

## Remote Backend Configuration: S3 and GCS

**AWS S3 backend.** Terraform 1.x recommends S3 native locking via `use_lockfile = true`, which creates `.tflock` files in the same bucket using S3 conditional writes — no DynamoDB table required. The older DynamoDB locking approach is [deprecated and scheduled for removal](https://developer.hashicorp.com/terraform/language/backend/s3) in a future minor version.

```hcl
terraform {
  backend "s3" {
    bucket       = "ml-infra-tfstate-prod"
    key          = "training-cluster/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

`encrypt = true` enables AES-256 server-side encryption. Per [Gruntwork's state management guide](https://gruntwork.io/blog/how-to-manage-terraform-state), S3 object durability is 99.999999999% — state file loss is not a realistic concern; corruption from concurrent writes is, which is exactly what locking prevents.

One critical constraint: **backend blocks cannot reference Terraform variables.** Writing `bucket = var.state_bucket_name` causes a parse error at `init` time because backend configuration is evaluated before variable processing. Use literal strings, or supply values via `terraform init -backend-config="bucket=ml-infra-tfstate-prod"` (partial configuration).

**GCS backend.** GCS makes locking even simpler — it is enabled automatically:

```hcl
terraform {
  backend "gcs" {
    bucket = "ml-infra-tfstate-prod"
    prefix = "terraform/training-cluster"
  }
}
```

GCS creates `.tflock` files alongside each state file with no additional configuration. No external service is required. Enable object versioning on the bucket for state recovery. Per the [GCS backend docs](https://developer.hashicorp.com/terraform/language/backend/gcs), workspace states are stored at `<prefix>/<workspace_name>.tfstate`.

<KnowledgeCheck
  question="On GCS, what enables Terraform state locking?"
  options={["A separate Cloud Spanner table configured in the backend block", "Object versioning enabled on the GCS storage bucket", "Automatic .tflock files created by GCS with no extra service", "A google_kms_key_ring resource declared in the backend block"]}
  correctIdx={2}
  explanation="GCS backends create .tflock files automatically alongside each state file. No external service or extra flag is required — locking is on by default."
/>

## Migrating Existing State to a Remote Backend

Adding a `backend` block to an existing config requires a one-time migration. The `terraform init -migrate-state` command reads state from the current backend (local file or previous remote) and writes it to the new destination. Terraform prompts for confirmation before copying.

```bash
# 1. Add the backend block to main.tf

# 2. Migrate
terraform init -migrate-state
# Prompt: "Do you want to copy existing state?" → yes

# 3. Verify state landed in S3
aws s3 ls s3://ml-infra-tfstate-prod/training-cluster/terraform.tfstate
```

The counterpart flag is `-reconfigure`, which silently discards the old state and configures the backend as if starting fresh. Never use `-reconfigure` on an existing workspace. Your infrastructure is still live but Terraform no longer knows about it; the next `terraform plan` shows everything as new creates. Per the [init command reference](https://developer.hashicorp.com/terraform/cli/commands/init), `-migrate-state` is the safe path; `-reconfigure` is for genuinely blank-slate setups only.

One bootstrapping trap: the S3 bucket must exist *before* `init -migrate-state` can use it as a backend. Don't declare the bucket resource in the same config that uses it as a backend — create it with a separate bootstrap config that uses local state, then add the backend block to the main config.

## How State Locking Works in Practice

When Karan runs `terraform apply`, Terraform acquires a lock on the state file before writing a single byte. If Priya attempts a concurrent apply, she sees:

```
Error: Error acquiring the state lock

Lock Info:
  ID:        0071b31e-4d15-17dd-78b2-d24f117a2c35
  Operation: OperationTypeApply
  Who:       karan@ml-team (terraform 1.15.0 on linux_amd64)
  Created:   2026-06-11T07:42:10.123Z
```

Locking is automatic for all write operations — plan, apply, destroy. Priya's only action is to wait; when Karan's apply completes, the lock releases. Per the [state locking docs](https://developer.hashicorp.com/terraform/language/state/locking), the six metadata fields (ID, Operation, Who, Version, Created, Path) give enough context to determine whether a lock is stale. `terraform force-unlock <LOCK_ID>` manually releases a stuck lock — use it only after confirming the holding process has genuinely terminated (check CI logs, confirm with the team). Running force-unlock while the original apply is still in progress corrupts state.

<Callout type="warning">
Force-unlock is not a shortcut for impatience. Verify the holding process is dead using the `Who` and `Created` fields before releasing. A live apply that loses its lock mid-write produces partial state.
</Callout>

## Workspace vs. Directory-per-Environment Isolation

CLI workspaces create named state isolation units within a single Terraform directory. The team creates dev, staging, and prod workspaces with `terraform workspace new <name>` and switches between them with `terraform workspace select`. Inside HCL, `terraform.workspace` returns the active name, enabling environment-specific sizing:

```hcl
instance_type = terraform.workspace == "prod" ? "p4d.24xlarge" : "g4dn.xlarge"
```

The hard limit: **all workspaces in a directory share the same backend configuration and the same IAM credentials.** Selecting `workspace dev` does not prevent an accidental apply from reaching production infrastructure if both workspaces share an IAM role with prod write access. Per the [Managing Workspaces docs](https://developer.hashicorp.com/terraform/cli/workspaces) and [Gruntwork's analysis](https://gruntwork.io/blog/how-to-manage-terraform-state), this makes CLI workspaces unsuitable for credential-isolated environments.

The directory-per-environment pattern solves this. Each environment gets its own root module directory (`envs/dev/`, `envs/staging/`, `envs/prod/`) with an independent `backend {}` block pointing to a separate IAM role. A misconfigured `dev/` config is bounded to dev; it cannot reach prod. The trade-off is moderate code duplication — shared child modules address that (covered in [[03-reusable-modules-ml-infrastructure.md]]).

Use workspaces for short-lived feature branches and ephemeral test environments. Use directories for long-lived, credential-isolated ML environments.

<KnowledgeCheck
  question="Which is the strongest reason to use directory-per-environment instead of CLI workspaces for ML prod/staging/dev?"
  options={["Workspaces store all environment state in one file; directories use one per environment", "Workspaces cannot run terraform plan, which requires the directory layout", "All workspaces share the same backend credentials, so IAM roles cannot be isolated", "The terraform.workspace variable is unavailable in workspaces, limiting environment config"]}
  correctIdx={2}
  explanation="CLI workspaces share one backend and one IAM role. Selecting a workspace named dev does not prevent writes to prod if both share credentials. Directory-per-environment gives each environment its own backend config and IAM policy."
/>

## Detecting and Recovering from State Drift

State drift occurs when infrastructure changes outside Terraform — an engineer scales a training cluster from the AWS console, a lifecycle policy expires a model artifact bucket, or an autoscaler adjusts instance counts. The state file reflects the last `apply`; live infrastructure has moved.

The modern drift-detection workflow replaces the deprecated `terraform refresh` command:

```bash
# Safe probe: reads live infra, shows drift, changes nothing
terraform plan -refresh-only

# Example output showing a manual GPU count change:
# ~ aws_autoscaling_group.training_cluster
#     desired_capacity: 2 -> 5  (detected: manual console change)
```

`plan -refresh-only` is non-destructive and safe to run at any cadence. The standalone `terraform refresh` command is deprecated: it auto-approves state updates without a confirmation prompt. Per the [refresh command docs](https://developer.hashicorp.com/terraform/cli/commands/refresh), the replacement is `terraform apply -refresh-only`, which prompts before writing updated state.

After reviewing drift, choose one of two paths. Accept the drift (the change was intentional): run `terraform apply -refresh-only` to update the state file to match live reality. Reject the drift (the change was wrong): run `terraform apply` to re-enforce the configuration, overwriting the manual change. Handling unmanaged resources and import-based remediation is covered in [[05-drift-detection-remediation.md]].

---

**Hands-on exercise: migrate local state and simulate a lock conflict**

1. Create an S3 bucket with object versioning using a separate bootstrap config with local state.
2. Add an S3 backend block (`use_lockfile = true`) to your main ML config.
3. Run `terraform init -migrate-state` and confirm the state file appears in S3.
4. In two terminal sessions, run `terraform apply` simultaneously against the remote backend. Observe the lock error in the second session — note the `Who` and `ID` fields.
5. After the first apply completes, run `terraform plan -refresh-only` to confirm no drift.

**Success criteria:** S3 contains `terraform.tfstate`; a `.tflock` file is visible in S3 during the active apply; the second session shows a lock error with a valid `Who` and `Lock ID`; `plan -refresh-only` reports no changes.

Next: learn how to extract reusable infrastructure patterns into parameterized child modules — [[03-reusable-modules-ml-infrastructure.md]].
