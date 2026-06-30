---
chapter_num: 1
course_slug: terraform-for-ml-engineers
title: "Writing and Applying Your First HCL Configuration with Terraform 1.15"
status: g3-passed
duration_min: 12
vendor_tag: HashiCorp Terraform
learning_objectives:
  - "Author a valid HCL configuration with terraform, provider, and resource blocks"
  - "Run the init → plan → apply → destroy cycle and interpret each command's output"
  - "Explain the difference between a version constraint and the lock file's pinned version"
  - "Commit the right files to Git: .terraform.lock.hcl yes, .terraform/ no"
sources:
  - url: "https://developer.hashicorp.com/terraform/language/syntax/configuration"
    title: "Terraform Configuration Syntax"
  - url: "https://developer.hashicorp.com/terraform/language/providers/requirements"
    title: "Terraform Provider Requirements"
  - url: "https://developer.hashicorp.com/terraform/language/files/dependency-lock"
    title: "Terraform Dependency Lock File (.terraform.lock.hcl)"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/plan"
    title: "terraform plan CLI Reference"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/destroy"
    title: "terraform destroy CLI Reference"
  - url: "https://developer.hashicorp.com/terraform/language/expressions/version-constraints"
    title: "Terraform Version Constraints"
owns:
  - "HCL configuration syntax and file layout"
  - "provider block authoring and version constraints"
  - "terraform init / plan / apply / destroy core cycle"
  - ".terraform.lock.hcl purpose and version pinning"
  - "reading and interpreting terraform plan output"
  - "verifying resource removal in cloud console and local state after destroy"
defers_to:
  - "remote backends and state locking → ch2"
  - "module authoring → ch3"
  - "CI/CD pipeline wiring → ch4"
  - "drift detection and remediation → ch5"
quiz_topics:
  - "HCL syntax rules: blocks, arguments, expressions"
  - "purpose of the required_providers block and version constraints"
  - "how to interpret +/~/- symbols in terraform plan output"
  - "why .terraform.lock.hcl must be committed to version control"
  - "what terraform destroy verifies before removing a resource"
notebooklm_source_focus:
  - "Terraform 1.15 HCL language documentation"
  - "HashiCorp provider versioning and lock file spec"
  - "terraform init / plan / apply / destroy CLI reference"
word_budget: { min: 800, max: 1200 }
positions: []
quiz:
  - question: "Which two syntax constructs form the complete basis of HCL?"
    options:
      - "Arguments that assign values and blocks that group nested configuration"
      - "Variables that hold inputs and data sources that query external APIs"
      - "Resource blocks that define infrastructure and provider blocks that authenticate"
      - "Input blocks that declare parameters and output blocks that expose values"
    correct_idx: 0
    explanation: "HCL has exactly two primitives: arguments assign a value to a name (region = \"us-central1\"), and blocks group related configuration under a typed container (resource \"google_storage_bucket\" \"training_data\" { ... }). Every other Terraform construct is built on these two."
    section_anchor: two-primitives-arguments-and-blocks
  - question: "What is the correct role of the version constraint ~> 6.0 in a required_providers block?"
    options:
      - "It pins the provider to exactly version 6.0 and rejects all other versions"
      - "It defines an acceptable range — any 6.x minor version but not 7.0"
      - "It forces terraform init to install the newest available version regardless of locks"
      - "It marks the provider as optional; Terraform may skip it if unavailable"
    correct_idx: 1
    explanation: "The pessimistic constraint operator ~> 6.0 allows any version in the 6.x series (6.0, 6.1, 6.14, etc.) while blocking the next major version (7.0). The exact version actually installed is recorded in .terraform.lock.hcl — not in required_providers."
    section_anchor: provider-block-and-version-constraints
  - question: "In terraform plan output, what does the -/+ symbol indicate?"
    options:
      - "The resource will be updated in-place with no interruption to existing workloads"
      - "The resource will be destroyed and then rebuilt as an entirely new object"
      - "The resource will be created in the cloud provider for the very first time"
      - "The resource will be permanently deleted without any replacement being created"
    correct_idx: 1
    explanation: "-/+ means Terraform must destroy the existing resource and create a replacement. This happens when an immutable argument is changed — for example, a GCS bucket name. For ML workloads, a -/+ on a training instance means in-flight jobs are killed, making careful plan review essential."
    section_anchor: reading-terraform-plan-output
  - question: "Why must .terraform.lock.hcl be committed to version control?"
    options:
      - "Terraform refuses to run plan or apply when the lock file is absent from Git"
      - "It holds cloud provider credentials that Terraform needs to authenticate to the cloud"
      - "A fresh clone without the lock file may select a newer provider version silently"
      - "It replaces the .terraform/ directory and eliminates large binaries from the repository"
    correct_idx: 2
    explanation: "The version constraint ~> 6.0 defines a range, not a single version. On a fresh clone without the lock file, terraform init queries the registry and may select 6.15 instead of the 6.14.1 your team tested. Committing the lock file guarantees every engineer — and every CI run — installs the identical provider binary."
    section_anchor: locking-versions-with-terraform-lock-hcl
  - question: "After terraform destroy reports 'Destroy complete! Resources: 1 destroyed', which two checks confirm that removal is complete?"
    options:
      - "Open the Terraform Registry and verify the Google provider version is still available"
      - "Inspect terraform.tfstate for an empty resources array and verify bucket absence in the GCS console"
      - "Run terraform validate to verify the remaining configuration file is still syntactically valid"
      - "Check .terraform.lock.hcl to confirm the provider hash entry was not removed by the command"
    correct_idx: 1
    explanation: "terraform destroy reports success based on cloud API responses, but you should always do a two-point post-destroy check: open terraform.tfstate and confirm the resources array is empty ([]), then open the GCS console and confirm the bucket does not appear under your project. Both checks appear explicitly in the Hands-On Exercise success criteria."
    section_anchor: hands-on-exercise
faq:
  - question: "What is the difference between the version constraint and the lock file?"
    answer: "The version constraint in required_providers (e.g., ~> 6.0) defines an acceptable range of provider versions. The lock file (.terraform.lock.hcl) records the exact version (e.g., 6.14.1) and cryptographic hashes of the binary that terraform init actually installed. The constraint is a policy; the lock file is the enforceable pin. Committing the lock file means every engineer and every CI run installs the identical provider binary, regardless of what newer patch releases have since appeared in the registry."
  - question: "Why does terraform plan show -/+ for a bucket name change?"
    answer: "GCS bucket names are globally unique and immutable once provisioned — there is no cloud API that renames a bucket in place. When you change the name argument in your .tf file, Terraform calculates that the only path to the desired state is to destroy the existing bucket and create a new one. That destroy-and-replace action appears as -/+ (replace) in plan output. For buckets holding training data, this means all objects are deleted unless force_destroy = true is set and you have moved the data elsewhere first."
  - question: "Which files should be committed to Git and which should be gitignored?"
    answer: "Commit all .tf configuration files and .terraform.lock.hcl. Add .terraform/ to .gitignore — provider binaries can exceed 100 MB and are rebuilt by terraform init from the lock file. Also gitignore terraform.tfstate and terraform.tfstate.backup: state files contain resource IDs and may expose secrets; store them in a remote GCS backend instead (covered in ch2). Some older .gitignore templates mistakenly exclude *.lock.hcl — verify yours explicitly includes .terraform.lock.hcl."
---

## Two Primitives: Arguments and Blocks

HCL has exactly two syntax constructs. Once you recognize them, every Terraform configuration becomes predictable.

An **argument** assigns a value to a name:

```hcl
region = "us-central1"
```

A **block** is a named container for related configuration:

```hcl
resource "google_storage_bucket" "training_data" {
  name          = "my-ml-project-training-data-2026"
  location      = "US"
  force_destroy = true
}
```

Every top-level construct in Terraform — `resource`, `provider`, `terraform`, `variable` — is a specific block type. The `resource` block requires exactly two labels: the resource type (`google_storage_bucket`) and a local name (`training_data`). The local name exists only inside Terraform; it never appears in your cloud provider's API. To reference this resource elsewhere in the configuration, write `google_storage_bucket.training_data.name` — resource type, then local name, then the attribute.

Identifiers must start with a letter or underscore and can contain letters, digits, underscores, and hyphens. Files use the `.tf` extension, and Terraform reads all `.tf` files in the working directory as a single, unified configuration. According to the [Terraform Configuration Syntax](https://developer.hashicorp.com/terraform/language/syntax/configuration) docs, both `#` and `//` are valid single-line comment delimiters, but `terraform fmt` converts `//` to `#` — use `#` from the start.

<KnowledgeCheck question="A teammate writes 'location = US' without quotes in their .tf file. What kind of syntax construct is this, and what is wrong with it?" options={["It is a block — blocks require curly braces, not equals signs", "It is an argument — string values must be quoted, so it should be location = \"US\"", "It is a label — labels are optional in HCL and can be unquoted", "It is an expression — expressions evaluate to booleans, not strings"]} correctIdx={1} explanation="'location = US' is an argument — a name-value assignment. String literals in HCL must be enclosed in double quotes. 'US' without quotes would be parsed as a reference to a variable named US, which does not exist, causing a plan error."/>

## Provider Block and Version Constraints

The `terraform` block sits at the top of your configuration and declares two things: the minimum Terraform core version your code requires, and every external provider it depends on.

```hcl
terraform {
  required_version = "~> 1.15"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = "travel-ml-prod-314159"
  region  = "asia-south1"
}
```

The `source` field uses a three-part registry address: `hostname/namespace/type`. The hostname defaults to `registry.terraform.io`, so `hashicorp/google` expands to `registry.terraform.io/hashicorp/google`. The Google Cloud provider has accumulated over 600 million cumulative downloads, reflecting its weight in ML and data-engineering stacks.

The `~>` operator is the pessimistic constraint and the most common choice for root modules. `~> 6.0` allows any `6.x` minor version but blocks `7.0`. `~> 6.0.1` is stricter: it permits `6.0.2` and `6.0.3` but rejects `6.1.0`. Pick `~> 6.0` when you want minor-version security patches automatically; pick `~> 6.0.1` when you need patch-level stability for a sensitive production pipeline. Six constraint operators are available (`=`, `!=`, `>`, `>=`, `<`, `<=`, `~>`); for reusable modules shared across teams, `>= 6.0, < 7.0` provides explicit upper and lower bounds without pessimistic shorthand. Source: [Terraform Version Constraints](https://developer.hashicorp.com/terraform/language/expressions/version-constraints).

<KnowledgeCheck question="A module author writes version = \">= 6.0\" in required_providers. An engineer consuming the module has ~> 6.0.1 in their root config. Which version wins?" options={["The module's >= 6.0 wins — module requirements always override root", "The root config's ~> 6.0.1 wins — root requirements always override modules", "Terraform intersects both constraints and selects a version satisfying both", "Terraform errors because two version constraints for the same provider conflict"]} correctIdx={2} explanation="Terraform intersects all version constraints for a provider across the entire configuration (root + modules) and selects a version that satisfies all of them simultaneously. ~> 6.0.1 (allows 6.0.x) combined with >= 6.0 would accept any 6.0.x patch version."/>

## The Core Workflow: init → plan → apply → destroy

Terraform's four-command cycle is deliberate. Each step is safe to re-run and progressively more consequential.

**`terraform init`** downloads provider binaries into `.terraform/` and writes `.terraform.lock.hcl`. It is idempotent — running it again never deletes your configuration or state. Re-run it after any change to `required_providers` or after cloning the repository.

**`terraform plan`** reads current state, compares it to your configuration, and proposes change actions. No cloud resources are created or modified. Treat it as a mandatory draft review: always run `terraform plan -out=tfplan` before apply, save the output, and verify it before committing.

**`terraform apply`** presents the plan one final time and prompts for confirmation. After you type `yes`, Terraform creates, updates, or destroys resources and writes the result to `terraform.tfstate`. The state file maps every resource block to its real cloud object — never edit it by hand.

**`terraform destroy`** is a convenience alias for `terraform apply -destroy`. It runs the same apply engine in destroy-planning mode. Always preview with `terraform plan -destroy` first to confirm exactly which resources will be removed.

<Callout type="warning">
The `-auto-approve` flag skips the interactive confirmation prompt on `apply` and `destroy`. Only use it in locked CI environments where no out-of-band infrastructure changes are possible. Using `-auto-approve` locally against a production GCS bucket holding 50 GB of training data is a fast path to an unrecoverable data loss event.
</Callout>

After `terraform destroy` completes, verify removal in two places: the cloud console (the bucket should be absent from the GCS browser) and `terraform.tfstate` (the `"resources"` array should be empty). If state still lists the resource but the console confirms deletion, you have encountered drift — covered in [[05-drift-detection-remediation]].

## Reading Terraform Plan Output

Four symbols appear in plan output, and misreading them is the most common source of production surprises:

| Symbol | Meaning | What actually happens |
|--------|---------|----------------------|
| `+` | Create | New resource provisioned |
| `-` | Destroy | Existing resource deleted |
| `~` | Update in-place | Attributes changed, same cloud object |
| `-/+` | Replace | Destroy old, create new (replacement) |

`-/+` demands the closest scrutiny. It appears when an argument that cannot be changed in place is modified — for example, changing a GCS bucket's `name`. Because GCS bucket names are globally unique and immutable once created, Terraform must delete the old bucket and create a new one. For an ML team storing training events, that means data loss unless the bucket was emptied first. For a Vertex AI training instance, `-/+` means any in-flight training jobs are terminated.

A plan ending with `Plan: 0 to add, 0 to change, 0 to destroy` is Terraform's confirmation that your running infrastructure exactly matches your configuration — the "clean slate" signal. According to the [terraform plan CLI Reference](https://developer.hashicorp.com/terraform/cli/commands/plan), plan performs a three-step read-compare-propose: it reads current remote object state, compares it to your configuration, and proposes the minimal set of changes needed to converge them.

## Locking Versions with .terraform.lock.hcl

After `terraform init`, examine the generated lock file:

```hcl
provider "registry.terraform.io/hashicorp/google" {
  version     = "6.14.1"
  constraints = "~> 6.0"
  hashes = [
    "h1:ABC123xyz...",
    "zh:DEF456uvw...",
  ]
}
```

`version` records the exact provider binary installed — `6.14.1` — selected within the `~> 6.0` range. `constraints` echoes the range from `required_providers` (informational only; Terraform enforces `version`). The `h1:` hash checksums the package contents and is the current preferred scheme; `zh:` is a legacy archive checksum retained for compatibility with older tooling.

**Commit `.terraform.lock.hcl` to Git. Add `.terraform/` to `.gitignore`.** Provider binaries reach 100 MB or more and are rebuilt by `terraform init` from the lock file. Without the lock file on a fresh clone, `init` queries the Terraform Registry and may silently select a newer patch release, diverging from what your team tested. Standard Terraform `.gitignore` templates correctly exclude `.terraform/`, but some older templates also exclude `*.lock.hcl` by mistake — verify yours. Source: [Terraform Dependency Lock File (.terraform.lock.hcl)](https://developer.hashicorp.com/terraform/language/files/dependency-lock).

---

## Hands-On Exercise

**Goal:** Provision a GCS training-data bucket and walk the complete init → plan → apply → destroy lifecycle.

1. Create `main.tf` with the configuration from the worked example in this chapter (substitute your GCP project ID).
2. Run `terraform init`. Confirm `.terraform.lock.hcl` was created and lists `hashicorp/google` with an exact version.
3. Run `terraform plan`. Verify exactly one `+` resource in the output and note the planned bucket name.
4. Run `terraform apply`. At the prompt, type `yes`. Confirm "Apply complete! Resources: 1 added, 0 changed, 0 destroyed."
5. Open the GCS console — the bucket must be visible with the name from step 3.
6. Run `terraform plan -destroy`. Read the `-` symbol on the bucket entry and confirm no other resources appear.
7. Run `terraform destroy`. Type `yes`. Confirm "Destroy complete! Resources: 1 destroyed."
8. Inspect `terraform.tfstate` in a text editor — the `"resources"` array must be empty (`[]`). Cross-check in the GCS console: the bucket must be absent.

**Success criteria:** Plan output shows `1 to add, 0 to change, 0 to destroy` before apply; apply completes with `1 added`; `terraform.tfstate` lists zero resources after destroy; GCS console shows no bucket under your project.

Your first configuration is running end-to-end — next, learn how to share state safely across a multi-engineer ML team. [[02-remote-state-locking-ml-teams]]
