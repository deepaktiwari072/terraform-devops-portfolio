# GCP GKE GitOps Platform With Terraform Modules

This project builds the infrastructure foundation for a production-style GitOps platform on Google Cloud.

Terraform provisions a private-node GKE cluster, networking, Cloud NAT, Artifact Registry, monitoring and logging integrations, and keyless GitHub Actions authentication through Workload Identity Federation.

The project is structured as reusable Terraform child modules called by a root module.

## Current Status

Completed:

- Modular Terraform project structure
- Required GCP API enablement using `for_each`
- Custom VPC and VPC-native GKE subnet
- Secondary IP ranges for Kubernetes Pods and Services
- Cloud Router and Cloud NAT
- Artifact Registry Docker repository
- Zonal GKE cluster for lower-cost daily practice
- Separately managed GKE node pool
- Private GKE worker nodes
- GKE Workload Identity Federation
- Cloud Logging, Cloud Monitoring, and Managed Prometheus integration
- GitHub Actions Workload Identity Federation
- Keyless GitHub Actions authentication to GCP
- Manual GitHub Actions workflow for Terraform plan, apply, and destroy

Remaining:

- Configure a remote GCS Terraform backend for GitHub Actions
- Install Argo CD into GKE
- Create Kubernetes application manifests
- Build and push an application image from GitHub Actions
- Update GitOps manifests from CI
- Configure Argo CD to synchronize manifests into GKE
- Add application-level dashboards, uptime checks, and alerts

## Architecture

```text
GitHub Repository
   |
   | GitHub Actions OIDC token
   v
Workload Identity Federation
   |
   | Impersonates without a JSON key
   v
Terraform Deployer Service Account
   |
   v
Terraform Modules
   |
   |-- Required GCP APIs
   |-- Custom VPC
   |-- GKE subnet
   |-- Pod and Service secondary ranges
   |-- Cloud Router and Cloud NAT
   |-- Artifact Registry
   |-- Private-node GKE cluster
   |-- GKE node pool
   |-- Cloud Logging and Monitoring
   |
   v
GKE Platform

Future application delivery:

GitHub Actions CI
   |
   | Build and push immutable image
   v
Artifact Registry
   |
   | Update GitOps manifest
   v
Git Repository
   |
   | Watched by Argo CD
   v
GKE Application Deployment
```

## Why This Design

The project separates infrastructure concerns into reusable modules:

```text
Root module = orchestrator
Child module = specialist
```

The root module decides which modules to call, passes environment-specific values, and connects module outputs to other module inputs.

Each child module owns one infrastructure responsibility, such as networking or GKE.

## Project Structure

```text
05-gcp-gke-argocd-cicd-modules/
├── main.tf
├── outputs.tf
├── provider.tf
├── variables.tf
├── versions.tf
├── terraform.tfvars.example
└── modules/
    ├── apis/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── artifact_registry/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── github_wif/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── gke/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── gke_node_pool/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── nat/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── vpc/
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

The GitHub Actions workflow is stored at:

```text
.github/workflows/gke-platform-terraform.yml
```

## Module Descriptions

### APIs Module

Enables the Google APIs required by the platform:

- Kubernetes Engine API
- Artifact Registry API
- IAM API
- Cloud Resource Manager API
- Cloud Logging API
- Cloud Monitoring API

The module demonstrates `for_each`, `toset()`, and `each.value`:

```hcl
resource "google_project_service" "apis" {
  for_each = toset(var.required_apis)

  service            = each.value
  disable_on_destroy = false
}
```

`toset()` converts the API list into a unique set. Terraform creates one resource for each API. During each loop, `each.value` contains the current API name.

### VPC Module

Creates a custom-mode VPC and a regional subnet for GKE.

GCP VPCs do not have a CIDR block at the VPC level. CIDR ranges are assigned to regional subnets.

The GKE subnet contains:

```text
Primary range   -> GKE worker nodes
Pod range       -> Kubernetes Pods
Service range   -> Kubernetes Services
```

This enables a VPC-native GKE cluster.

### NAT Module

Creates:

- Cloud Router
- Cloud NAT
- NAT error logging

GKE worker nodes have private IP addresses only. Cloud NAT provides outbound access so nodes and workloads can reach GitHub, package repositories, and external services without public node IPs.

### Artifact Registry Module

Creates a Docker Artifact Registry repository for application container images.

Immutable tags are enabled:

```hcl
immutable_tags = true
```

The future CI workflow should use unique Git commit SHA tags instead of repeatedly overwriting `latest`.

Example:

```text
us-central1-docker.pkg.dev/PROJECT_ID/REPOSITORY/app:COMMIT_SHA
```

### GKE Module

Creates a zonal GKE cluster configured with:

- VPC-native networking
- Private worker nodes
- Public control-plane endpoint for practice access
- Workload Identity Federation for GKE
- Cloud Logging integration
- Cloud Monitoring integration
- Managed Prometheus
- Regular release channel
- Separately managed node pool

The cluster is zonal to reduce cost and make daily creation and destruction faster.

For production high availability, a regional cluster would normally be considered.

### GKE Node Pool Module

Creates the worker node pool separately from the cluster.

This separation allows node pools to be upgraded, resized, replaced, or configured independently.

The node pool includes:

- Autoscaling settings
- Automatic repair
- Automatic upgrades
- Node labels
- GKE metadata mode
- Disabled legacy metadata endpoints

For daily practice, the node pool uses one `e2-medium` node.

### GitHub WIF Module

Creates keyless authentication between GitHub Actions and GCP:

- Terraform deployer service account
- Workload Identity Pool
- GitHub OIDC provider
- Repository and branch attribute restriction
- IAM roles for the Terraform deployer
- Service account impersonation binding

Authentication flow:

```text
GitHub Actions requests OIDC token
   |
GCP WIF provider validates repository and branch
   |
GitHub identity impersonates Terraform deployer service account
   |
GitHub Actions receives short-lived GCP credentials
```

No long-lived service account JSON key is stored in GitHub.

## Module Data Flow

Modules are connected through outputs and inputs.

Example:

```text
VPC module creates subnet
   |
VPC module outputs subnet_id
   |
Root module passes module.vpc.subnet_id
   |
NAT and GKE modules receive subnet_id
```

Terraform automatically understands dependencies when one module references another module's output.

Explicit `depends_on` is useful when a dependency exists but there is no direct input/output reference, such as enabling an API before creating a service.

## Daily Practice Configuration

The current configuration is optimized for repeated practice:

- Zonal GKE cluster
- One worker node
- `e2-medium` node machine type
- Deletion protection disabled
- Manually triggered GitHub Actions
- Manual plan, apply, and destroy choices

Recommended daily flow:

```text
Morning:
GitHub Actions -> plan
GitHub Actions -> apply

Practice:
Deploy and troubleshoot workloads

Evening:
GitHub Actions -> destroy
```

Do not leave GKE nodes, load balancers, or other billable resources running when they are not needed.

## Prerequisites

- GCP project with billing enabled
- Terraform installed for initial bootstrap
- Google Cloud CLI installed
- GitHub repository
- Owner-level or sufficient bootstrap permissions in GCP
- Existing GCS bucket for remote Terraform state before using GitHub Actions apply

Authenticate locally:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_GCP_PROJECT_ID
```

## Local Configuration

Create a local variable file from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Do not commit `terraform.tfvars`, state files, credentials, or `.terraform/`.

Example local values:

```hcl
gcp_project_id = "your-gcp-project-id"
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"

project_name = "gke-argocd-cicd"
environment  = "practice"

github_owner  = "your-github-user"
github_repo   = "terraform-devops-portfolio"
github_branch = "master"
```

## One-Time WIF Bootstrap

GitHub Actions cannot authenticate until the WIF trust relationship exists. Therefore, WIF must be bootstrapped once using local Terraform credentials.

Plan only the API and WIF modules:

```bash
terraform plan \
  -var-file="terraform.tfvars" \
  -target=module.apis \
  -target=module.github_wif
```

Apply:

```bash
terraform apply \
  -var-file="terraform.tfvars" \
  -target=module.apis \
  -target=module.github_wif
```

Using `-target` is acceptable here only for the deliberate one-time bootstrap. Normal Terraform operations should avoid targeted apply.

Get WIF outputs:

```bash
terraform output -raw github_actions_service_account
terraform output -raw github_actions_workload_identity_provider
```

## GitHub Repository Variables

Configure these at:

```text
Repository -> Settings -> Secrets and variables -> Actions -> Variables
```

| Variable | Description |
| --- | --- |
| `GCP_PROJECT_ID` | GCP project ID |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full WIF provider resource name from Terraform output |
| `GCP_TERRAFORM_SERVICE_ACCOUNT` | Terraform deployer service account email |
| `GIT_OWNER` | GitHub username or organization |
| `GIT_REPO` | Repository name |
| `GIT_BRANCH` | Branch allowed by the WIF condition |

GitHub reserves the `GITHUB_` prefix, so repository variables use `GIT_OWNER`, `GIT_REPO`, and `GIT_BRANCH`.

The workflow maps them to Terraform variables:

```yaml
TF_VAR_github_owner: ${{ vars.GIT_OWNER }}
TF_VAR_github_repo: ${{ vars.GIT_REPO }}
TF_VAR_github_branch: ${{ vars.GIT_BRANCH }}
```

Terraform automatically loads environment variables beginning with `TF_VAR_`.

## GitHub Actions Terraform Workflow

The workflow is manually triggered and accepts:

```text
plan
apply
destroy
```

Workflow stages:

```text
Checkout repository
Authenticate to GCP using WIF
Install Terraform
Check formatting
Initialize Terraform
Validate configuration
Plan, apply, or destroy
```

Required workflow permissions:

```yaml
permissions:
  contents: read
  id-token: write
```

`id-token: write` allows GitHub Actions to request an OIDC token for WIF authentication.

## Critical: Remote State For GitHub Actions

GitHub-hosted runners are temporary. Local Terraform state stored on one runner disappears after the workflow completes.

Before using GitHub Actions for `apply` or `destroy`, configure a remote GCS backend:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "gke-argocd-cicd/practice"
  }
}
```

Without remote state:

- GitHub Actions cannot reliably identify previously created resources
- Later plans may attempt to recreate resources
- Destroy operations may not find infrastructure

The Terraform deployer service account must have access to the state bucket.

## Validation Commands

Run locally:

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars"
```

After GKE creation:

```bash
gcloud container clusters get-credentials CLUSTER_NAME \
  --zone us-central1-a \
  --project YOUR_GCP_PROJECT_ID

kubectl get nodes
kubectl get pods -A
```

## Troubleshooting Lessons

### Child Module Variables Are Independent

Root variables are not automatically available inside child modules. The root module must explicitly pass them:

```hcl
module "vpc" {
  source = "./modules/vpc"

  gcp_region = var.gcp_region
}
```

### Module Source Paths

Module paths are relative to the root module:

```hcl
source = "./modules/vpc"
```

Run Terraform from the root project folder, not from inside a child module.

### Module Cycles

A module cannot consume its own output as an input.

Wrong:

```hcl
pods_range_name = module.gke.pods_range_name
```

Correct:

```hcl
pods_range_name = module.vpc.pods_range_name
```

### GCP Resource Naming

GCP resource names commonly allow lowercase letters, numbers, and hyphens, but not underscores.

Terraform local names can use underscores:

```hcl
resource "google_compute_firewall" "allow_iap_ssh" {
  name = "allow-iap-ssh"
}
```

Different GCP resources also have different length limits. Short IDs are used for the WIF pool, provider, and service account.

### `for_each`, `toset()`, And `each.value`

For a set of API strings:

```hcl
for_each = toset(var.required_apis)
service  = each.value
```

`each.value` is the current API string. `each.service` does not exist.

### WIF Attribute Condition Rejected

If GitHub authentication returns:

```text
The given credential is rejected by the attribute condition
```

Check that the configured repository and branch exactly match the workflow:

```text
attribute.repository == "OWNER/REPOSITORY"
attribute.ref        == "refs/heads/BRANCH"
```

Inspect the live provider:

```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-actions-pool \
  --location=global \
  --project=YOUR_GCP_PROJECT_ID \
  --format="value(attributeCondition)"
```

### GitHub Actions Workflow Syntax

Use:

```yaml
uses: actions/checkout@v4
run: terraform validate
```

`uses:` runs an existing GitHub Action. `run:` executes a shell command.

GitHub repository variables use:

```yaml
${{ vars.VARIABLE_NAME }}
```

Terraform variables use:

```hcl
var.variable_name
```

### Terraform Format Exit Code 3

When `terraform fmt -check -recursive` exits with code `3`, files require formatting.

Fix locally:

```bash
terraform fmt -recursive
git add .
git commit -m "Format Terraform configuration"
git push
```

## Security Practices Demonstrated

- No service account JSON keys in GitHub
- Short-lived credentials through WIF
- Repository and branch restrictions on GitHub authentication
- Private GKE worker nodes
- Cloud NAT for controlled outbound access
- Workload Identity Federation for GKE workloads
- Disabled legacy metadata endpoints
- Immutable Artifact Registry tags
- Separate GKE node pool management
- Manually triggered infrastructure apply and destroy

## Production Improvements

The current project balances production concepts with low-cost daily practice. Before using it for a real production environment, consider:

- Regional GKE cluster for high availability
- Multiple node pools across zones
- Dedicated least-privilege service accounts
- Bucket-level IAM instead of project-wide Storage Admin
- Private GKE control-plane endpoint
- VPN, bastion, or secure administration network
- Cloud Armor and external HTTPS Load Balancer
- Organization policies
- Customer-managed encryption keys
- Policy validation using Checkov, tfsec, or OPA
- Pull-request plan workflow and protected approval environment
- Saved Terraform plan artifact applied after approval
- Application-level SLOs, alerts, and dashboards

## Interview Summary

> I created a modular Terraform platform for GKE on GCP. The root module orchestrates reusable modules for API enablement, VPC networking, Cloud NAT, Artifact Registry, GKE, a separately managed node pool, and GitHub Workload Identity Federation. The GKE cluster uses VPC-native networking, private nodes, Workload Identity, Cloud Logging, Cloud Monitoring, and Managed Prometheus. GitHub Actions authenticates to GCP keylessly through OIDC and WIF, then performs manually approved Terraform plan, apply, and destroy operations. The next phase is to install Argo CD and implement a GitOps application delivery pipeline where CI builds immutable container images and Argo CD manages deployment to GKE.

## Next Phase

1. Configure and verify remote GCS state.
2. Apply the platform through GitHub Actions.
3. Install Argo CD.
4. Create a sample application and Dockerfile.
5. Push images to Artifact Registry using GitHub Actions.
6. Create GitOps Kubernetes manifests.
7. Configure an Argo CD Application.
8. Add application monitoring, dashboards, and alert policies.
