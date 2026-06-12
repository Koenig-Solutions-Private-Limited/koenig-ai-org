---
chapter_num: 5
course_slug: terraform-for-ml-engineers
title: "Detecting and Remediating Infrastructure Drift in a Live ML Environment"
status: g0-passed
duration_min: 13
vendor_tag: HashiCorp Terraform
learning_objectives:
  - "Run terraform plan to surface manual changes made outside of Terraform"
  - "Read drift diffs and decide whether to re-apply or import the change"
  - "Use terraform import to bring an unmanaged cloud resource under state control"
  - "Query terraform state list and terraform state show to audit resource attributes"
  - "Write a lifecycle precondition block that enforces minimum GPU instance specifications"
sources:
  - url: "https://developer.hashicorp.com/terraform/tutorials/state/resource-drift"
    title: "Manage resource drift | Terraform | HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/plan"
    title: "terraform plan command reference | Terraform | HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/import"
    title: "terraform import command reference | Terraform | HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/state/resource-addressing"
    title: "Resource address reference | Terraform | HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/state/list"
    title: "terraform state list command reference | Terraform | HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/cli/commands/state/show"
    title: "terraform state show command reference | Terraform | HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle"
    title: "lifecycle meta-argument reference | Terraform | HashiCorp Developer"
  - url: "https://developer.hashicorp.com/terraform/tutorials/state/refresh"
    title: "Use refresh-only mode to sync Terraform state | Terraform | HashiCorp Developer"
  - url: "https://www.firefly.ai/blog/chaos-under-control-addressing-cloud-infrastructure-drift"
    title: "Chaos Under Control: Addressing Cloud Infrastructure Drift | Firefly"
owns:
  - "running terraform plan against a live environment to surface manual changes"
  - "reading drift diffs: which attributes changed, by whom, and what Terraform intends"
  - "reconcile decision: re-apply Terraform definition vs import console change"
  - "terraform import workflow for bringing unmanaged resources under state control"
  - "terraform state list and terraform state show for inspecting individual resource attributes"
  - "lifecycle precondition block to enforce minimum resource specifications (e.g., GPU instance type)"
defers_to:
  - "CI/CD pipeline gating → ch4"
  - "module variable design → ch3"
  - "remote state backend and locking → ch2"
quiz_topics:
  - "how terraform plan reveals that a resource was manually changed in the cloud console"
  - "when to use terraform import vs re-applying the Terraform definition to reconcile drift"
  - "what terraform state list returns and how to use it to find a specific resource"
  - "syntax and semantics of a lifecycle precondition block"
  - "how a failed lifecycle precondition surfaces in terraform plan output"
notebooklm_source_focus:
  - "Terraform drift detection and reconciliation patterns"
  - "terraform import CLI reference and workflow"
  - "terraform state subcommands: list, show, mv, rm"
  - "lifecycle meta-arguments: precondition and postcondition"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "You run terraform plan and see the header 'Note: Objects have changed outside of Terraform'. What does the ~ symbol beside an attribute mean?"
    options:
      - "The attribute was added by Terraform and now matches the config"
      - "The attribute was modified externally and differs from what state recorded"
      - "The attribute will be destroyed and recreated on the next apply"
      - "The attribute is marked sensitive and its value is redacted in output"
    correct_idx: 1
    explanation: "The ~ symbol means the attribute was changed outside of Terraform. The left side shows what the state file recorded; the right shows what the cloud provider currently reports. A + means added, - means removed, and -/+ means replace (destroy and recreate)."
    section_anchor: "reading-drift-in-terraform-plan-output"
  - question: "An on-call engineer upgraded a SageMaker endpoint configuration via the AWS Console to fix a production issue. The fix was intentional and must persist. Which reconcile action is correct?"
    options:
      - "Run terraform apply immediately to revert the manual change back to the declared Terraform configuration"
      - "Run terraform import to add the resource to state, then re-run plan until drift clears"
      - "Update the .tf config to match the console change, then run terraform apply -refresh-only to sync state"
      - "Delete the resource from state with terraform state rm and let the next apply recreate it"
    correct_idx: 2
    explanation: "When a manual change is intentional and must persist, update the Terraform configuration to match the current cloud state, then run terraform apply -refresh-only to sync the state file without touching the resource. A plain terraform apply would revert the change. terraform import is for resources not yet tracked in state at all."
    section_anchor: "making-the-reconcile-decision"
  - question: "A cloud alert fires for instance i-0ab123cd456ef7890. You need to find its Terraform resource address. Which command is correct?"
    options:
      - "terraform state show i-0ab123cd456ef7890"
      - "terraform state list -id=i-0ab123cd456ef7890"
      - "terraform plan -target=i-0ab123cd456ef7890"
      - "terraform import aws_instance.unknown i-0ab123cd456ef7890"
    correct_idx: 1
    explanation: "terraform state list -id=CLOUD_ID filters the state by the cloud provider's resource ID and returns the matching Terraform resource address (e.g., module.training_cluster.aws_instance.gpu_trainer[2]). Once you have the address, pass it to terraform state show to inspect all stored attributes."
    section_anchor: "inspecting-state-with-terraform-state-list-and-terraform-state-show"
  - question: "A lifecycle precondition has condition = contains([\"p3.2xlarge\", \"p3.8xlarge\"], var.instance_type) and a developer sets instance_type = \"t3.large\". When does Terraform halt the operation?"
    options:
      - "After the instance is created, during the postcondition phase"
      - "During terraform apply, after the resource is provisioned but found non-compliant"
      - "During terraform plan, before any resource changes are proposed"
      - "Only when terraform validate is run as a separate pre-flight step"
    correct_idx: 2
    explanation: "A precondition is evaluated during the plan phase, before Terraform proposes or makes any changes to the resource. If the condition is false, Terraform prints Error: Resource precondition failed with your error_message and stops the entire plan. No apply is possible until the condition is satisfied."
    section_anchor: "blocking-unauthorized-instance-types-with-lifecycle-preconditions"
---

## Why Drift Happens in ML Infrastructure

Infrastructure drift is the gap between what Terraform believes exists — the state file — and what actually runs in your cloud account. In ML environments, it is endemic: according to a [Firefly 2024 vendor survey](https://www.firefly.ai/blog/chaos-under-control-addressing-cloud-infrastructure-drift), 90% of large-scale IaC deployments experience drift, and roughly half of those incidents go unnoticed without active detection tooling.

The trigger is almost always urgency. A training job OOMs at 2 AM. A data scientist logs into the AWS Console and resizes the GPU node from `p3.2xlarge` to `p3.8xlarge` to meet a deadline. The job finishes; the console tab closes. Terraform's state file still records `p3.2xlarge`. The gap is invisible until the next `terraform plan` run — which, without a scheduled CI pipeline, might be days away and hundreds of dollars in unexpected GPU spend later.

## Reading Drift in terraform plan Output

`terraform plan` is your primary drift detector. Every time it runs, Terraform refreshes resource attributes from the cloud provider and compares them against the state file. When it finds a discrepancy, it prints a dedicated header before the change summary:

```
Note: Objects have changed outside of Terraform since the last "terraform apply"
```

Below that header, drifted resources appear with the `~` modifier, showing the state-file value on the left and the current cloud value on the right:

```
~ resource "aws_instance" "gpu_trainer" {
      id            = "i-0ab123cd456ef7890"
    ~ instance_type = "p3.2xlarge" -> "p3.8xlarge"
  }
```

The left side is what Terraform recorded; the right side is what the cloud provider reports now. The plan body that follows describes what Terraform *intends* to do — which, by default, is to revert the drift back to the configuration. Read both sections before acting; the header tells you what happened, the plan body tells you what will happen next.

<KnowledgeCheck question="You run terraform plan and see 'Note: Objects have changed outside of Terraform'. Which symbol marks an attribute that was modified externally?" options={["+ (added by Terraform)", "~ (modified externally)", "- (deleted from config)", "-/+ (destroy and recreate)"]} correctIdx={1} explanation="The ~ symbol indicates an attribute was changed outside Terraform. The left side is what the state file recorded; the right shows what the cloud currently has. A + means added, - means removed, and -/+ means Terraform will destroy and recreate the resource."/>

## Making the Reconcile Decision

When drift is detected, you face a binary choice.

**Re-apply the Terraform definition.** Leave the configuration as-is and run `terraform apply`. Terraform reverts the cloud resource to match the configuration. Use this path when the manual change was a mistake, an unauthorized shortcut, or a temporary hotfix that is no longer needed.

**Accept the manual change.** Update the `.tf` file to match what is currently running in the cloud, then run `terraform apply -refresh-only` to sync the state file without touching the resource. Use this path when the change was intentional and must persist.

For the GPU-resize scenario above, if retraining is complete and `p3.8xlarge` is no longer needed, re-apply is the right call — run `terraform apply` and the three instances resize back to `p3.2xlarge`. If the model genuinely requires more GPU memory going forward, update the config to `p3.8xlarge`, sync state with `apply -refresh-only`, and open a PR to record the decision.

<Callout type="warning">Never use the old `terraform refresh` subcommand. It silently overwrites the state file with no review or approval gate and is [deprecated in favor of plan -refresh-only](https://developer.hashicorp.com/terraform/tutorials/state/refresh). The `-refresh-only` mode shows you exactly what would change in state and requires an explicit `apply` confirmation before writing anything.</Callout>

## Bringing Unmanaged Resources Under State Control

Sometimes drift is not a changed attribute but an absent entry: a resource exists in the cloud but Terraform has never tracked it. This is common when teams prototype in the console and later want to codify what they built. [`terraform import`](https://developer.hashicorp.com/terraform/cli/commands/import) resolves this by reading the existing cloud resource and recording it in the state file at a specified address.

The workflow has three required steps — skip any one and the import either fails or produces a plan that immediately destroys what you just imported.

**Step 1 — Write the matching resource block first.** `terraform import` does not generate configuration; you must author it.

```hcl
resource "aws_sagemaker_endpoint" "inference" {
  name                 = "bert-sentiment-prod"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.bert.name
}
```

**Step 2 — Import by cloud ID.**

```bash
terraform import aws_sagemaker_endpoint.inference bert-sentiment-prod
```

**Step 3 — Verify zero drift.** Run `terraform plan`. If the configuration matches the real resource, the output reads "No changes." If attributes differ, Terraform proposes modifications — adjust the config until the plan is clean.

Since Terraform 1.5, the declarative `import` block lets you declare imports inside `.tf` files and preview them through the normal plan-apply cycle, making it safer for CI/CD pipelines than the imperative CLI command.

<KnowledgeCheck question="You run terraform import aws_sagemaker_endpoint.inference bert-sentiment-prod without first writing the resource block. What happens on the next terraform plan?" options={["The plan succeeds with No changes", "Terraform proposes to destroy the just-imported resource", "Terraform generates a matching config file automatically", "The state file is left unchanged because the import failed"]} correctIdx={1} explanation="terraform import adds the resource to state but writes no configuration. Without a matching resource block, Terraform treats the state entry as an orphan and proposes to destroy it on the next apply. Always author the resource block before importing."/>

## Inspecting State with terraform state list and terraform state show

`terraform state list` returns every resource address currently tracked in the state file. Use it to audit what Terraform owns without triggering a plan or modifying anything. Pass the `-id` flag to look up a resource by its cloud provider ID — essential when a monitoring alert fires on an instance ID and you need to find its Terraform address quickly:

```bash
$ terraform state list -id=i-0ab123cd456ef7890
module.training_cluster.aws_instance.gpu_trainer[2]
```

Once you have the address, `terraform state show` dumps all stored attributes in human-readable HCL format:

```bash
$ terraform state show 'module.training_cluster.aws_instance.gpu_trainer[2]'
# resource "aws_instance" "gpu_trainer" {
#     id            = "i-0ab123cd456ef7890"
#     instance_type = "p3.2xlarge"
#     ...
# }
```

Both commands are strictly read-only — they never modify state or cloud resources. For machine-readable output, use `terraform show -json`. The `-id` lookup pattern is especially useful during incident response when you know a resource's cloud ID from an alert but not the module path or index it lives under in the configuration.

## Blocking Unauthorized Instance Types with lifecycle Preconditions

Detection after the fact is useful; prevention is better. A `lifecycle` block's `precondition` sub-block runs during `terraform plan`, before any resource changes are proposed. If the `condition` expression evaluates to `false`, Terraform emits `Error: Resource precondition failed` and halts the entire plan — no apply is possible until the condition is satisfied:

```hcl
resource "aws_instance" "gpu_trainer" {
  ami           = data.aws_ami.deep_learning.id
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition = contains(
        ["p3.2xlarge", "p3.8xlarge", "p3.16xlarge", "p4d.24xlarge"],
        var.instance_type
      )
      error_message = "ML training requires a GPU instance. Got '${var.instance_type}'; must be one of: p3.2xlarge, p3.8xlarge, p3.16xlarge, p4d.24xlarge."
    }
  }
}
```

With this guard in place, any attempt to apply with a CPU instance type — from a misconfigured `.tfvars` file or a mistaken variable override — fails at plan time with a clear error before any cloud resource changes. The manual console workaround that caused drift in the first place still requires a human to log in, but the next `terraform plan` run will catch it immediately.

## Hands-On Exercise

**Scenario:** Your travel-ranking model's training cluster experienced a weekend drift event. Three `p3.2xlarge` GPU nodes were manually resized to `p3.8xlarge` in the AWS Console to unblock a failing retraining job. The job has since completed.

**Task:** Work through the full drift lifecycle in a sandbox account.

1. Run `terraform plan` and locate the "Objects have changed" header. Identify which instances drifted and record their `instance_type` change.
2. Use `terraform state list -id=<instance-id>` to find the Terraform resource address for one of the drifted instances.
3. Run `terraform state show` on that address and confirm the stored `instance_type` still reads `p3.2xlarge`.
4. Retraining is done and `p3.8xlarge` is no longer needed. Run `terraform apply` and verify all three instances revert to `p3.2xlarge`.
5. Add a `lifecycle precondition` to `aws_instance.gpu_trainer` that only permits `p3.2xlarge` and `p3.8xlarge`. Attempt `terraform plan -var instance_type=t3.large` and confirm the plan halts with `Error: Resource precondition failed`.

**Success criteria:** `terraform plan` shows "No changes" after re-apply; `terraform plan -var instance_type=t3.large` prints your precondition error message and stops before evaluating any resource block.

---

This is the final chapter of *Terraform for ML Engineers* — you now have the complete toolkit: write and apply HCL configurations (ch1), manage shared remote state with locking (ch2), build reusable modules (ch3), gate changes through CI/CD review pipelines (ch4), and detect and remediate infrastructure drift in production (ch5).
