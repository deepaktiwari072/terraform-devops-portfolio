# Project 02: AWS 3-Tier VPC Architecture With Terraform

This project creates a production-style AWS 3-tier architecture foundation using Terraform.

It includes public subnets, private subnets, Internet Gateway, NAT Gateway, EC2 instances, and an RDS MySQL database.

## Architecture

```text
Internet
   |
Internet Gateway
   |
Public Route Table
   |
Public Subnets
   |
Bastion EC2
   |
Private Subnets
   |
App EC2
   |
RDS MySQL Database
```

## Resources Created

- VPC
- 2 public subnets
- 2 private subnets
- Internet Gateway
- Elastic IP for NAT Gateway
- NAT Gateway
- Public route table
- Private route table
- Route table associations
- Bastion EC2 instance
- Private app EC2 instance
- Security groups
- RDS subnet group
- RDS MySQL database

## Architecture Purpose

This project follows a basic 3-tier architecture pattern.

| Tier | Resource | Subnet Type |
| --- | --- | --- |
| Web Tier | Bastion host / public entry | Public subnet |
| App Tier | App EC2 instance | Private subnet |
| Database Tier | RDS MySQL | Private subnet |

## Traffic Flow

Public subnet resources access the internet through:

```text
Public Subnet -> Public Route Table -> Internet Gateway
```

Private subnet resources access the internet through:

```text
Private Subnet -> Private Route Table -> NAT Gateway -> Internet Gateway
```

Database access is restricted to the app security group only.

## Prerequisites

Before running this project, make sure you have:

- AWS account
- Terraform installed
- AWS CLI installed and configured
- Existing AWS EC2 key pair
- IAM permissions for VPC, EC2, NAT Gateway, and RDS

Check AWS authentication:

```bash
aws sts get-caller-identity
```

Check Terraform:

```bash
terraform version
```

## Variables

Example variables:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format"
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}
```

## Secrets Handling

Do not hardcode real passwords in `variables.tf`.

Recommended for local testing:

```bash
export TF_VAR_db_password="YourStrongPassword123!"
```

Or use a local `terraform.tfvars` file that is ignored by Git:

```hcl
db_username = "adminuser"
db_password = "YourStrongPassword123!"
```

Make sure `.gitignore` includes:

```gitignore
*.tfvars
!*.tfvars.example
*.tfstate
*.tfstate.*
```

## Example terraform.tfvars

Create a local `terraform.tfvars` file:

```hcl
aws_region  = "us-west-2"
vpc_cidr    = "10.0.0.0/16"
my_ip_cidr  = "YOUR_PUBLIC_IP/32"
key_name    = "your-key-pair-name"
db_username = "adminuser"
db_password = "YourStrongPassword123!"
```

Do not commit this file.

## Terraform Commands

Initialize Terraform:

```bash
terraform init
```

Format files:

```bash
terraform fmt
```

Validate configuration:

```bash
terraform validate
```

Preview changes:

```bash
terraform plan
```

Apply infrastructure:

```bash
terraform apply
```

Destroy infrastructure:

```bash
terraform destroy
```

## Testing

SSH into the bastion host:

```bash
ssh -i /path/to/key.pem ec2-user@BASTION_PUBLIC_IP
```

SSH from bastion to private app server:

```bash
ssh -i /path/to/key.pem ec2-user@APP_PRIVATE_IP
```

Better option: use SSH agent forwarding from your local machine:

```bash
ssh-add /path/to/key.pem
ssh -A ec2-user@BASTION_PUBLIC_IP
ssh ec2-user@APP_PRIVATE_IP
```

Test internet access from private app EC2:

```bash
curl https://www.google.com
```

Test Nginx on app EC2:

```bash
sudo systemctl status nginx
```

Test database connection from app EC2:

```bash
mysql -h RDS_ENDPOINT -u DB_USERNAME -p
```

## Outputs

Recommended outputs:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
```

## Issues And Troubleshooting

### Invalid Availability Zone

Error:

```text
Value (us-west-2) for parameter availabilityZone is invalid
```

Reason:

`us-west-2` is a region, not an Availability Zone.

Fix:

```hcl
availability_zone = "us-west-2a"
```

Valid examples:

```text
us-west-2a
us-west-2b
us-west-2c
us-west-2d
```

### count.index Error

Error:

```text
Reference to "count" in non-counted context
```

Reason:

`count.index` was used without defining `count`.

Fix:

```hcl
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
}
```

### RDS Password Showing In Plan

If password appears in Terraform output, make sure the variable is marked sensitive:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

Sensitive values may still exist in `terraform.tfstate`, so never commit state files.

### Variables Not Allowed In terraform.tfvars

Error:

```text
Variables may not be used here
```

Reason:

String values were not inside quotes.

Wrong:

```hcl
db_password = MyPassword123
```

Correct:

```hcl
db_password = "MyPassword123"
```

### SSH To Private EC2 Fails

Possible reasons:

- App EC2 is in a private subnet
- Security group does not allow SSH from bastion security group
- Key pair is missing
- Private key is not available through agent forwarding

Fix app security group:

```hcl
ingress {
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  security_groups = [aws_security_group.bastion_sg.id]
}
```

Use SSH agent forwarding:

```bash
ssh-add /path/to/key.pem
ssh -A ec2-user@BASTION_PUBLIC_IP
ssh ec2-user@APP_PRIVATE_IP
```

### Private EC2 Cannot Access Internet

Possible reasons:

- NAT Gateway missing
- NAT Gateway is not in a public subnet
- Private route table is missing route to NAT Gateway
- Public subnet route table is missing route to Internet Gateway

Private route should be:

```hcl
route {
  cidr_block     = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}
```

Public route should be:

```hcl
route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}
```

### RDS Connection Fails

Possible reasons:

- RDS security group does not allow MySQL from app security group
- Wrong RDS endpoint
- Wrong username or password
- MySQL client is not installed on app EC2

Fix DB security group:

```hcl
ingress {
  from_port       = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_groups = [aws_security_group.app_sg.id]
}
```

Install MySQL client:

```bash
sudo dnf install -y mariadb105
```

Connect:

```bash
mysql -h RDS_ENDPOINT -u DB_USERNAME -p
```

## Cost Warning

This project can create AWS charges.

Resources that may cost money:

- NAT Gateway
- Elastic IP
- RDS database
- EC2 instances
- Data transfer

Destroy the infrastructure after testing:

```bash
terraform destroy
```

## Learning Outcomes

After completing this project, you should understand:

- Public vs private subnets
- Internet Gateway
- NAT Gateway
- Route table associations
- Bastion host pattern
- Private EC2 deployment
- RDS subnet group
- Security group to security group access
- Terraform sensitive variables
- Multi-AZ VPC design
