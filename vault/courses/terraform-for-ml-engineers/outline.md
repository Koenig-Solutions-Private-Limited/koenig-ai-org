---
course_slug: terraform-for-ml-engineers
title: "Terraform for MLOps Engineers: Provisioning and Managing ML Infrastructure as Code"
status: awaiting-g3
course_track: career
toc_locked: true
video_overview: true
koenig_recommendation: "Terraform Certified Associate with Azure (https://www.koenig-solutions.com/hashicorp-terraform-on-microsoft-azure-training)"
author: course-architect
level: Advanced
vendor_tag: HashiCorp Terraform
target_audience: "Senior ML/MLOps engineers who manage cloud infrastructure and want to enforce reproducibility, auditability, and safe change management on GPU clusters, model-serving endpoints, and data pipeline resources using Terraform 1.15."
prerequisites:
  - "Hands-on experience with at least one major cloud provider (AWS, GCP, or Azure)"
  - "Familiarity with ML training and inference infrastructure concepts (GPU instances, storage buckets, managed notebooks)"
  - "Basic command-line proficiency (Git, shell)"
learning_outcomes:
  - "Write and apply HCL configurations using the terraform init/plan/apply/destroy cycle"
  - "Configure remote state backends with locking for safe multi-engineer collaboration"
  - "Author reusable Terraform modules for repeatable ML infrastructure components"
  - "Wire Terraform into a CI/CD pipeline with plan-then-approve gating on pull requests"
  - "Detect, evaluate, and remediate infrastructure drift in a live ML environment"
total_duration_min: 60
chapter_count: 5
sources: []
---

## Chapter 1 — Writing and Applying Your First HCL Configuration with Terraform 1.15

**Duration:** ~12 minutes
**Learning objectives:**
- Configure a Terraform 1.15 working directory with a versioned provider block and run terraform init, plan, and apply to provision a cloud storage bucket
- Interpret a terraform plan output to identify which resources will be created, changed, or destroyed before any apply
- Pin provider versions using a .terraform.lock.hcl file and explain why version pinning prevents silent breaking changes in a shared codebase
- Run terraform destroy and verify the resource is removed from both the cloud console and local state

**Key concepts:** HCL blocks and arguments · required_providers versioning · .terraform.lock.hcl · reading plan symbols (+/~/−) · state verification after destroy

**Hands-on exercise:** Write a `main.tf` that provisions a cloud storage bucket with a versioned provider, run the full init → plan → apply cycle, inspect the plan diff, then run destroy and confirm the resource is gone from both the console and state file.

---

## Chapter 2 — Managing Shared Remote State with Locking for Multi-Engineer ML Teams

**Duration:** ~13 minutes
**Learning objectives:**
- Configure a remote backend (S3 + DynamoDB or GCS with locking) in a Terraform project and verify that local state is migrated correctly using terraform init -migrate-state
- Demonstrate state locking by simulating a concurrent apply and confirming the lock prevents a conflicting write
- Isolate dev and prod ML environments into separate state files using workspace or directory-per-environment patterns
- Recover a plan failure caused by stale state by running terraform refresh and diagnosing the drift in the output

**Key concepts:** S3 + DynamoDB backend · GCS locking · state migration · workspace vs directory-per-env · terraform refresh · concurrent write protection

**Hands-on exercise:** Migrate a local-state project to a remote S3 backend with DynamoDB locking, simulate a concurrent apply to trigger the lock error, then create dev and prod workspaces with separate state isolation.

---

## Chapter 3 — Building Reusable Modules for ML Infrastructure Components

**Duration:** ~12 minutes
**Learning objectives:**
- Author a Terraform module with input variables, local values, and outputs that provisions a parameterized ML compute resource (e.g., GPU instance group or managed notebook environment)
- Call the module from a root configuration with environment-specific .tfvars files for dev, staging, and prod without duplicating resource blocks
- Expose only variable inputs that legitimately differ across environments and keep IAM, tagging, and logging policy inside the module
- Validate the module using terraform validate and confirm it rejects an invalid variable type before plan is run

**Key concepts:** Module file layout (variables.tf / locals.tf / outputs.tf / main.tf) · input variable type constraints · local values · module outputs · .tfvars override order · terraform validate

**Hands-on exercise:** Build a `gpu-training-cluster` module with parameterized instance type and replica count, call it from a root config with `dev.tfvars` and `prod.tfvars`, then intentionally pass a wrong type and verify terraform validate catches it before plan.

---

## Chapter 4 — Integrating Terraform into a CI/CD Review Workflow with Plan-Then-Approve Gates

**Duration:** ~10 minutes
**Learning objectives:**
- Configure a CI pipeline (GitHub Actions or equivalent) that runs terraform fmt -check, terraform validate, and terraform plan on every pull request and posts the plan output as a PR comment
- Add a manual approval gate between plan and apply so no resource is mutated without explicit sign-off
- Store sensitive Terraform variables (cloud credentials, API keys) as CI secrets and confirm they are never printed in plan output
- Diagnose a pipeline failure caused by a missing required variable and fix it by supplying the value through the CI environment rather than hard-coding it

**Key concepts:** GitHub Actions terraform workflow · PR plan comments · manual approval gate · CI secrets vs hard-coded vars · terraform fmt -check · missing-variable diagnostics

**Hands-on exercise:** Create a GitHub Actions workflow that runs fmt/validate/plan on PR and posts the plan as a comment; add an environment-level approval gate; pass a cloud credential as a repository secret and confirm it is masked in plan output.

---

## Chapter 5 — Detecting and Remediating Infrastructure Drift in a Live ML Environment

**Duration:** ~13 minutes
**Learning objectives:**
- Run terraform plan against a live environment where a resource was manually changed in the cloud console and identify the exact drift in the plan diff
- Evaluate the drift and make a deliberate decision: reconcile by applying the Terraform definition back, or import the console change into state using terraform import
- Use terraform state list and terraform state show to inspect individual resource attributes and confirm state reflects reality after reconciliation
- Write a lifecycle precondition on a critical ML resource (e.g., GPU instance type) that causes terraform plan to fail if the configuration drifts below a required specification

**Key concepts:** Drift detection via plan diff · reconcile vs import decision framework · terraform import workflow · terraform state list/show · lifecycle precondition block

**Hands-on exercise:** Manually resize a training instance in the cloud console, run terraform plan to surface the drift, choose the import path, run terraform import, inspect state with terraform state show, then add a lifecycle precondition that rejects under-spec instance types.

---

## Capstone

**Project:** Provision a complete ML training pipeline infrastructure — storage bucket, GPU training cluster (module-driven), and model-serving endpoint — using a remote-state-backed Terraform project wired into a GitHub Actions CI pipeline with plan-then-approve gating. Introduce deliberate drift in one resource, detect it, and document the reconciliation decision with evidence from terraform plan and terraform state show.

**Deliverable:** A pull request containing the Terraform configuration, CI workflow YAML, a `modules/gpu-training-cluster/` module, and a `DRIFT-REPORT.md` documenting the drift incident and resolution.
