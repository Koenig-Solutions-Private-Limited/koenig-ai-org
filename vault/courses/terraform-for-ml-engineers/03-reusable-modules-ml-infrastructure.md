---
chapter_num: 3
course_slug: terraform-for-ml-engineers
title: "Building Reusable Modules for ML Infrastructure Components"
status: g3-passed
last_updated: 2026-06-12
duration_min: 12
vendor_tag: HashiCorp Terraform
learning_objectives:
  - "Describe the standard four-file module layout and why each file exists"
  - "Author input variables with type constraints, validation rules, and defaults"
  - "Use local values to eliminate repetition inside a module"
  - "Declare module outputs and consume them in a root configuration"
  - "Call a module with environment-specific .tfvars files"
  - "Explain what terraform validate catches that terraform plan requires credentials to reach"
sources:
  - url: "https://developer.hashicorp.com/terraform/language/modules/develop"
    title: "Module Development — Terraform Language"
  - url: "https://developer.hashicorp.com/terraform/language/modules/develop/structure"
    title: "Standard Module Structure — Terraform Language"
  - url: "https://developer.hashicorp.com/terraform/language/values/variables"
    title: "Input Variables — Terraform Language"
  - url: "https://developer.hashicorp.com/terraform/language/values/locals"
    title: "Local Values — Terraform Language"
  - url: "https://developer.hashicorp.com/terraform/language/values/outputs"
    title: "Output Values — Terraform Language"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/validate"
    title: "Command: validate — Terraform CLI"
  - url: "https://developer.hashicorp.com/terraform/language/modules/syntax"
    title: "Module Blocks — Terraform Language"
  - url: "https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html"
    title: "Best Practices for Code Base Structure and Organization — AWS Prescriptive Guidance"
  - url: "https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules"
    title: "Best Practices for Reusable Terraform Modules — Google Cloud Documentation"
owns:
  - "module file layout: variables.tf, locals.tf, outputs.tf, main.tf"
  - "authoring input variables with type constraints and defaults"
  - "using local values to reduce repetition inside a module"
  - "declaring and consuming module outputs"
  - "calling a module from root configuration with environment-specific .tfvars"
  - "keeping IAM, tagging, and logging policy inside the module boundary"
  - "terraform validate for pre-plan type checking"
defers_to:
  - "remote backend configuration → ch2"
  - "CI pipeline plan/apply gating → ch4"
  - "drift detection and terraform import → ch5"
  - "provider version pinning in root config → ch1"
quiz_topics:
  - "required vs optional input variables: when to use each"
  - "what local values are and why they differ from input variables"
  - "how module outputs flow to the calling root configuration"
  - ".tfvars file precedence and override order"
  - "what terraform validate catches that terraform plan does not"
notebooklm_source_focus:
  - "Terraform module creation documentation"
  - "input variables, local values, and output values reference"
  - "terraform validate CLI reference"
  - "HashiCorp module design best practices"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "A `variable` block declared without a `default` argument is:"
    options:
      - "Optional — Terraform silently substitutes `null` if no value is supplied"
      - "Required — Terraform errors or prompts when no value is provided"
      - "Deprecated in Terraform 1.x — use a `locals` block instead"
      - "Optional — the provider fills it from its own internal defaults"
    correct_idx: 1
    explanation: "Without a default, Terraform has no fallback. It must receive a value from the caller, a TF_VAR_* environment variable, or a -var flag. In non-interactive CI it fails with 'no value for required variable' rather than prompting."
    section_anchor: "authoring-input-variables"
  - question: "What is the key distinction between a local value and an input variable?"
    options:
      - "Local values accept type constraints; input variables do not support them"
      - "Local values are caller-overridable; input variables are computed at apply"
      - "Input variables allow caller overrides; local values are module-internal and read-only"
      - "Local values only hold string expressions; input variables support all types"
    correct_idx: 2
    explanation: "A local value (local.name_prefix) is an internal shorthand the caller cannot change. An input variable (var.environment) exists specifically so the caller can supply a per-instantiation value."
    section_anchor: "local-values-the-internal-dry-layer"
  - question: "After calling a module labeled `training`, how does the root configuration read its `sagemaker_role_arn` output?"
    options:
      - "`output.training.sagemaker_role_arn`"
      - "`var.training.sagemaker_role_arn`"
      - "`module.training.sagemaker_role_arn`"
      - "`local.training.sagemaker_role_arn`"
    correct_idx: 2
    explanation: "Module outputs are accessed via module.<LABEL>.<OUTPUT_NAME>. This reference also registers an implicit dependency so downstream resources wait for the module to finish creating the referenced object."
    section_anchor: "declaring-and-consuming-module-outputs"
  - question: "Which variable-loading mechanism carries the highest precedence in Terraform?"
    options:
      - "A `terraform.tfvars` file auto-loaded from the working directory"
      - "A `TF_VAR_*` environment variable set in the shell before running"
      - "An explicit `-var-file=<path>` CLI flag on the command line"
      - "An inline `-var 'name=value'` flag passed on the command line"
    correct_idx: 3
    explanation: "Precedence from lowest to highest: variable default → TF_VAR_* env → terraform.tfvars → *.auto.tfvars → -var-file flags (in CLI order) → -var flags (in CLI order). The -var flag always wins."
    section_anchor: "calling-the-module-with-environment-specific-tfvars"
  - question: "Why is `terraform validate` safe to run in an offline environment after `terraform init`?"
    options:
      - "It checks syntax and types without contacting any cloud provider API"
      - "It reads a cached copy of your cloud account's live resource state"
      - "It uses local provider schema to simulate a complete resource plan"
      - "It bypasses provider schema and checks only raw HCL file syntax"
    correct_idx: 0
    explanation: "terraform validate checks syntax correctness, attribute names, and type constraints against the provider schema downloaded during init — no API calls, no state reads. This makes it safe as a pre-save or pre-commit hook with zero cloud credentials required."
    section_anchor: "terraform-validate-pre-plan-type-checking"
---

## The Case for Modules

Your fare-prediction ML pipeline runs in three environments — dev, staging, and prod. Without a module, you maintain three near-identical copies of a SageMaker training configuration, roughly 200 HCL lines each. After every AWS API change, someone updates one copy and forgets the others. A module collapses those 600 lines into three short `module` blocks and three `.tfvars` files, each holding only what differs by environment.

A Terraform module is any directory containing `.tf` files. The directory where you run `terraform apply` is the *root module*; every other directory you call from it is a *child module*. Child modules expose a clean contract — inputs in, outputs out — so the root never needs to know how the resources inside are implemented.

## The Four-File Module Layout

[Standard Module Structure — Terraform Language](https://developer.hashicorp.com/terraform/language/modules/develop/structure) prescribes four files for the minimal complete module:

```
modules/fare-pred-training/
├── main.tf        # resource definitions
├── variables.tf   # all input variable declarations
├── locals.tf      # shared name prefixes and tag maps
└── outputs.tf     # everything the caller can read
```

Add `iam.tf` as a fifth file when IAM resources exceed 150 lines — a threshold from [AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html) that keeps privilege-boundary resources in one reviewable file, separate from compute.

Do not add a `providers.tf` or `backend.tf` inside a shared module. Provider and backend configuration belongs in the root module only — provider pinning syntax is covered in [[01-hcl-configuration-core-workflow]] and backend setup in [[02-remote-state-locking-ml-teams]]; placing either inside a child module forces a specific region, credential profile, or state location onto every caller. A `versions.tf` that declares only `required_providers` version constraints is the sole acceptable provider-related file in a shared module.

## Authoring Input Variables

Every knob the caller needs to turn is a `variable` block in `variables.tf`. The `type` argument is not optional in a shared module — it lets `terraform validate` catch type mismatches before a plan touches your cloud account.

```hcl
variable "environment" {
  type        = string
  description = "Deployment tier: dev | staging | prod."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  type    = string
  default = "ml.m5.xlarge"
}
```

A variable without `default` is **required** — Terraform errors rather than guessing. A variable with `default` is **optional**. Use required variables for values that differ meaningfully across environments (`environment`, `training_image_uri`). Use optional variables for values safe to share most of the time: `instance_type = "ml.m5.xlarge"` serves dev and staging; prod overrides it via `.tfvars`. The `validation` block runs at plan time and surfaces a targeted error message instead of a cryptic downstream provider error, per [Input Variables — Terraform Language](https://developer.hashicorp.com/terraform/language/values/variables).

<KnowledgeCheck question="A `variable` block declared without a `default` argument is:" options={["Optional — Terraform silently substitutes null if no value is supplied","Required — Terraform errors or prompts when no value is provided","Deprecated in Terraform 1.x — use a locals block instead","Optional — the provider fills it from its own internal defaults"]} correctIdx={1} explanation="Without a default, Terraform must receive a value from the caller, a TF_VAR_* environment variable, or a -var flag. In non-interactive CI it fails with 'no value for required variable' rather than prompting."/>

## Local Values — The Internal DRY Layer

Local values are the module's internal shorthand — defined once, referenced many times, and never overridable by the caller.

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    { Project = var.project_name, Environment = var.environment, ManagedBy = "terraform" },
    var.tags
  )
}
```

`local.name_prefix` stamps every resource name consistently — SageMaker job, IAM role, CloudWatch log group — without repeating the concatenation. `local.common_tags` builds the full tag map once; every resource calls `tags = local.common_tags`.

The distinction from input variables is fundamental: if a value should vary across instantiations, use a `variable`. If a value is always derived from other expressions inside the module, use a `local`. The most common mistake is hard-coding an environment-specific value in `locals.tf` and then being unable to override it without touching the module source. Per [Local Values — Terraform Language](https://developer.hashicorp.com/terraform/language/values/locals), locals can reference resource attributes, data sources, and functions — not just variables.

## Declaring and Consuming Module Outputs

Outputs expose module internals to the caller via `output` blocks in `outputs.tf`:

```hcl
output "sagemaker_role_arn" {
  description = "ARN of the IAM role used by SageMaker training jobs."
  value       = aws_iam_role.sagemaker.arn
}

output "training_job_name_prefix" {
  description = "Consistent name prefix applied to all training jobs in this module."
  value       = local.name_prefix
}
```

The calling root reads outputs as `module.training.sagemaker_role_arn`. This reference also registers an implicit dependency — Terraform knows that a CloudWatch log group using the ARN must wait for the IAM role to exist. [Best Practices for Reusable Terraform Modules — Google Cloud](https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules) states explicitly: every resource in a shared module should have at least one output so callers can declare dependencies without resorting to `depends_on` hacks.

<Callout type="warning">
Never add `provider` or `backend` blocks inside a shared module. Doing so binds every caller to one specific region, credential profile, or state location and silently breaks reuse. Shared modules declare only `required_providers` version constraints — never a full provider configuration.
</Callout>

<KnowledgeCheck question="After calling a module labeled `training`, how does the root configuration read its `sagemaker_role_arn` output?" options={["output.training.sagemaker_role_arn","var.training.sagemaker_role_arn","module.training.sagemaker_role_arn","local.training.sagemaker_role_arn"]} correctIdx={2} explanation="Module outputs are accessed via module.<LABEL>.<OUTPUT_NAME>. This reference also registers an implicit dependency so downstream resources wait for the module to finish creating the referenced object."/>

## Calling the Module with Environment-Specific `.tfvars`

The root `main.tf` calls the module with a `source` pointing to its directory:

```hcl
module "training" {
  source = "./modules/fare-pred-training"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.training_instance_type
  training_image_uri = var.training_image_uri
  s3_data_bucket     = var.s3_data_bucket
}
```

Per-environment values live in separate `.tfvars` files and are applied with `-var-file`:

```hcl
# envs/dev/terraform.tfvars
instance_type      = "ml.m5.xlarge"
training_image_uri = "123456789.dkr.ecr.ap-south-1.amazonaws.com/fare-pred-train:dev-latest"

# envs/prod/terraform.tfvars
instance_type      = "ml.p3.2xlarge"
training_image_uri = "123456789.dkr.ecr.ap-south-1.amazonaws.com/fare-pred-train:v1.4.2"
```

```bash
terraform apply -var-file=envs/prod/terraform.tfvars
```

Variable loading precedence from lowest to highest: variable `default` → `TF_VAR_*` environment variables → `terraform.tfvars` (auto-loaded) → `*.auto.tfvars` (lexicographic order) → `-var-file` flags (CLI order) → `-var` flags (CLI order, highest). An explicit `-var-file=envs/prod/terraform.tfvars` overrides any `terraform.tfvars` present in the working directory. The `-var` flag overrides everything.

## Keeping IAM, Tagging, and Logging Inside the Module Boundary

IAM roles, tagging, and logging configuration belong inside the module, not in the root. Co-locating them with the resources they govern means a reviewer auditing `modules/fare-pred-training/iam.tf` sees the complete privilege boundary in one file. Letting IAM leak into the root creates scattered ad-hoc policies disconnected from the compute they control and makes security audits much harder.

When IAM resources inside the module exceed 150 lines, break them into a dedicated `iam.tf` inside the module directory. The module still owns them — the separate file is purely a readability split, not a boundary change.

## Terraform Validate — Pre-Plan Type Checking

Run `terraform validate` inside the module directory after every edit:

```bash
cd modules/fare-pred-training
terraform init -backend=false
terraform validate
# Success: The configuration is valid.
```

`terraform validate` checks syntax correctness, attribute names, and type constraints against the provider schema that was downloaded during `init` — no cloud API calls, no state reads. It catches a misspelled `assume_role_polciy` attribute or a `list(string)` value passed to a `string` variable in under a second. What it does **not** catch: whether the instance type exists in your target region, whether the IAM role has the right permissions, or whether the ECR image URI resolves — those require a live `terraform plan` with valid credentials. CI/CD gating on plan output is covered in [[04-cicd-plan-approve-gates]]. Run `validate` as a fast pre-save check; run `plan` as the gate before merge.

---

## Hands-On Exercise

**Task:** Extract a minimal SageMaker training module and call it from a root configuration with separate dev and prod `.tfvars` files.

1. Create `modules/fare-pred-training/` with `variables.tf`, `locals.tf`, `main.tf`, `outputs.tf`, and `iam.tf`.
2. In `variables.tf`, declare `project_name` (required, `string`), `environment` (required, `string` with `validation` restricting to `dev`/`staging`/`prod`), `instance_type` (optional, default `"ml.m5.xlarge"`), and `training_image_uri` (required, `string`).
3. In `locals.tf`, define `name_prefix = "${var.project_name}-${var.environment}"` and a `common_tags` map merging standard keys with `var.tags`.
4. In `outputs.tf`, export `sagemaker_role_arn` (referencing the IAM role in `iam.tf`) and `training_job_name_prefix` (from `local.name_prefix`).
5. Run `terraform init -backend=false && terraform validate` inside the module directory — confirm exit code 0.
6. Create `envs/dev/terraform.tfvars` with `instance_type = "ml.m5.xlarge"` and `envs/prod/terraform.tfvars` with `instance_type = "ml.p3.2xlarge"`.
7. In the root `main.tf`, call the module and reference `module.training.sagemaker_role_arn` in a `aws_cloudwatch_log_group` resource.

**Success criteria:**
- `terraform validate` exits 0 with "The configuration is valid."
- Setting `environment = "qa"` in a `.tfvars` file triggers the validation error message, not a generic provider error.
- `terraform plan -var-file=envs/prod/terraform.tfvars` shows `ml.p3.2xlarge` as the instance type.
- Removing `training_image_uri` from the `.tfvars` file causes Terraform to error with "no value for required variable."

---

Next: [[04-cicd-plan-approve-gates]] — wiring `terraform validate` and `plan` into a GitHub Actions pipeline with manual approval gates before every apply.
