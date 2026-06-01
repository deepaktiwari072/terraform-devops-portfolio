# Project 03: GCP Foundation With Terraform

This project creates a beginner-friendly Google Cloud foundation using Terraform.

It is the GCP equivalent of a basic AWS foundation project: networking, firewall rules, IAM service accounts, required APIs, Cloud NAT, and a secure Cloud Storage bucket for future Terraform remote state.

## Architecture

```text
GCP Project
   |
Enabled APIs
   |
Custom VPC
   |
Regional Subnets
   |-- Public workload subnet
   |-- Private workload subnet
           |
           Cloud Router
           |
           Cloud NAT
           |
           Internet egress

Cloud Storage Bucket
   |
Future Terraform remote state
```

## Resources Created

- Required Google Cloud APIs
- Custom VPC
- Public workload subnet
- Private workload subnet with Private Google Access
- Cloud Router
- Cloud NAT for private subnet internet egress
- Internal firewall rule
- IAP SSH firewall rule
- HTTP/HTTPS firewall rule for future web workloads
- Application service account
- IAM bindings for logging and monitoring
- Cloud Storage bucket for Terraform state

## AWS To GCP Mapping

| AWS Concept | GCP Concept |
| --- | --- |
| AWS account or environment boundary | GCP project |
| IAM role for workload | Service account |
| S3 remote state bucket | Cloud Storage remote state bucket |
| VPC | VPC network |
| Subnet | Regional subnet |
| Security group style access | VPC firewall rule with tags |
| NAT Gateway | Cloud NAT with Cloud Router |
| EC2 public/private subnets | Workloads with or without external IPs |

## Important GCP Difference

GCP does not use public and private subnets exactly like AWS.

In AWS, a subnet becomes public when its route table points to an Internet Gateway.

In GCP, subnet privacy is usually controlled by whether a VM has an external IP address and which firewall rules apply. This project still names the subnets `public` and `private` for learning clarity:

- `public-subnet`: intended for workloads that may receive external IPs.
- `private-subnet`: intended for workloads without external IPs, using Cloud NAT for outbound internet access.

## Prerequisites

Before running this project, make sure you have:

- GCP account
- Existing GCP project with billing enabled
- Terraform installed
- Google Cloud CLI installed
- IAM permissions to manage Compute Engine, IAM, Service Usage, and Cloud Storage

Check Terraform:

```bash
terraform version
```

Check Google Cloud authentication:

```bash
gcloud auth list
gcloud config get-value project
```

Authenticate Terraform with Application Default Credentials:

```bash
gcloud auth application-default login
```

Set your active project:

```bash
gcloud config set project YOUR_GCP_PROJECT_ID
```

## Required Bootstrap Note

Terraform can enable most APIs in this project, but the Service Usage API may need to be enabled before Terraform can manage APIs:

```bash
gcloud services enable serviceusage.googleapis.com
```

If the project is brand new, you may also need:

```bash
gcloud services enable cloudresourcemanager.googleapis.com
```

## Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace:

- `gcp_project_id` with your real GCP project ID
- `gcp_region` if you want a different region
- `state_bucket_name` only if the generated default bucket name is already taken

Example:

```hcl
gcp_project_id = "my-practice-project-123"
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"

project_name = "terraform-gcp-foundation"
environment  = "dev"
```

Do not commit `terraform.tfvars`.

## Terraform Commands

Initialize Terraform:

```bash
terraform init
```

Format the code:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Preview changes:

```bash
terraform plan
```

Create the foundation:

```bash
terraform apply
```

Destroy the foundation when finished:

```bash
terraform destroy
```

## Remote State Migration

This project creates a Cloud Storage bucket for future Terraform remote state.

The first apply uses local state because the bucket does not exist yet. After apply succeeds:

1. Copy `backend.tf.example` to `backend.tf`.
2. Replace the bucket name with the `terraform_state_bucket_name` output.
3. Run:

```bash
terraform init -migrate-state
```

After that, Terraform state will live in Cloud Storage.

## What To Understand Before Moving On

- `provider.tf` connects Terraform to GCP.
- `versions.tf` pins Terraform and provider requirements.
- `variables.tf` defines configurable inputs.
- `main.tf` declares GCP resources.
- `outputs.tf` prints useful values after apply.
- `terraform.tfvars` supplies your local values and should not be committed.
- `backend.tf.example` shows how to move from local state to GCS remote state.

## Next Upgrade

The next GCP project can use this foundation to deploy a Compute Engine VM with Nginx in the public subnet and a private VM that reaches the internet through Cloud NAT.
