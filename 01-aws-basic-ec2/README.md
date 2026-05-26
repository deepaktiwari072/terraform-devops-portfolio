# Project 01: Basic AWS EC2 With Terraform

This project creates a simple AWS web server environment:

- VPC
- public subnet
- internet gateway
- public route table
- security group
- EC2 instance
- Nginx installed through EC2 user data

## Prerequisites

- Terraform installed
- AWS CLI installed and authenticated
- An existing EC2 key pair if you want SSH access

Check your AWS identity:

```bash
aws sts get-caller-identity
```

## Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace:

- `allowed_ssh_cidr` with your public IP, for example `203.0.113.10/32`
- `key_name` with an existing AWS EC2 key pair name

If you do not need SSH access, keep `key_name` empty:

```hcl
key_name = ""
```

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

Create the infrastructure:

```bash
terraform apply
```

After apply completes, Terraform prints `website_url`. Open that URL in your browser to test Nginx.

Destroy the infrastructure when finished:

```bash
terraform destroy
```

## What To Understand Before Moving On

- `provider.tf` connects Terraform to AWS.
- `versions.tf` pins Terraform and provider requirements.
- `variables.tf` defines configurable inputs.
- `main.tf` declares AWS resources.
- `outputs.tf` prints useful values after apply.
- `terraform.tfvars` supplies your local values and should not be committed if it contains personal settings.

## Next Upgrade

The next project will add private subnets, NAT Gateway, and a more realistic multi-tier VPC layout.
