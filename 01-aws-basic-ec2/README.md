# Terraform Project 01: AWS Basic EC2 Web Server

This project creates a basic AWS web server infrastructure using Terraform.

## Architecture

This Terraform configuration creates:

- VPC
- Public subnet
- Internet Gateway
- Route table
- Route table association
- Security group
- EC2 instance
- SSH key pair attachment
- Nginx web server using user data

## Architecture Flow

```text
Internet
   |
Internet Gateway
   |
Route Table
   |
Public Subnet
   |
EC2 Instance
   |
Security Group
Resources Created
Resource	Purpose
aws_vpc	Creates a custom VPC
aws_subnet	Creates a public subnet inside the VPC
aws_internet_gateway	Allows internet access for the VPC
aws_route_table	Defines route to the internet
aws_route_table_association	Associates public subnet with route table
aws_security_group	Allows SSH and HTTP traffic
aws_instance	Launches EC2 web server
aws_ami data source	Fetches latest Amazon Linux 2023 AMI
Prerequisites
Before running this project, make sure you have:

AWS account
AWS CLI installed and configured
Terraform installed
Existing AWS EC2 key pair
IAM permissions to create VPC, EC2, subnet, route table, internet gateway, and security group
Check AWS authentication:

aws sts get-caller-identity
Check Terraform version:

terraform version
Provider
This project uses AWS provider.

Example:

provider "aws" {
  region = "us-west-2"
}
Variables
Example variables used in this project:

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Instance type for EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}
Security Group Rules
Inbound rules:

Port	Protocol	Source	Purpose
22	TCP	Your public IP /32	SSH access
80	TCP	0.0.0.0/0	HTTP access
Outbound rules:

Port	Protocol	Destination	Purpose
All	All	0.0.0.0/0	Allow internet access from EC2
User Data
The EC2 instance installs and starts Nginx automatically using user data.

#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl enable nginx
systemctl start nginx
Terraform Commands
Initialize Terraform:

terraform init
Format Terraform files:

terraform fmt
Validate configuration:

terraform validate
Preview infrastructure changes:

terraform plan
Create infrastructure:

terraform apply
Destroy infrastructure:

terraform destroy
Testing
After terraform apply, get the EC2 public IP from output.

Open in browser:

http://EC2_PUBLIC_IP
SSH into EC2:

ssh -i /path/to/key.pem ec2-user@EC2_PUBLIC_IP
If permission error occurs:

chmod 400 /path/to/key.pem
Issues And Troubleshooting
1. Invalid Availability Zone Error
Error:

Value (us-west-2) for parameter availabilityZone is invalid
Reason:

us-west-2 is a region, not an Availability Zone.

Fix:

availability_zone = "us-west-2a"
Valid examples:

us-west-2a
us-west-2b
us-west-2c
us-west-2d
2. Invalid AMI ID Error
Error:

InvalidAMIID.NotFound
Reason:

AMI IDs are region-specific. An AMI from another region will not work in us-west-2.

Fix:

Use a Terraform data source instead of hardcoding AMI ID.

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
Then use:

ami = data.aws_ami.amazon_linux_2023.id
3. Instance Type Not Free Tier Eligible
Error:

The specified instance type is not eligible for Free Tier
Reason:

Free Tier eligible instance types depend on AWS account creation date and region.

Fix:

Check eligible instance types:

aws ec2 describe-instance-types \
  --region us-west-2 \
  --filters "Name=free-tier-eligible,Values=true" \
  --query "InstanceTypes[*].InstanceType" \
  --output table
Then update:

instance_type = "t3.micro"
4. Route Table Route Error
Error:

Inappropriate value for attribute "route"
Reason:

Wrong route syntax was used.

Wrong:

route = {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
Correct:

route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
5. SSH Not Working
Possible reasons:

Key pair not attached to EC2
Wrong .pem file used
Security group does not allow port 22
Your public IP changed
.pem file permissions are too open
Fix:

Add key pair:

key_name = var.key_name
Allow SSH from your IP:

cidr_blocks = ["YOUR_PUBLIC_IP/32"]
Fix PEM permissions:

chmod 400 /path/to/key.pem
SSH command:

ssh -i /path/to/key.pem ec2-user@EC2_PUBLIC_IP
6. Website Not Opening
Possible reasons:

Port 80 not allowed in security group
Nginx not installed
User data did not run correctly
EC2 does not have public IP
Subnet is not public
Fix security group:

ingress {
  description = "Allow HTTP"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
Check Nginx on EC2:

sudo systemctl status nginx
Start Nginx manually if required:

sudo systemctl start nginx
7. Terraform State Lock Message
Message:

Releasing state lock. This may take a few moments...
Reason:

Terraform locks state while applying changes to prevent multiple updates at the same time.

Fix:

Usually no action is needed. Wait for Terraform to release the lock.

If lock remains stuck, investigate carefully before using force unlock:

terraform force-unlock LOCK_ID
Use force unlock only when you are sure no Terraform operation is running.

Important Learning Points
VPC is the private network boundary.
Subnet is created inside a VPC.
Internet Gateway allows internet access.
Route table decides traffic direction.
Public subnet needs route to Internet Gateway.
Security group controls EC2 traffic.
EC2 needs public IP for internet access.
AMI IDs are region-specific.
Key pair is required for SSH access.
User data helps automate server setup.
Cleanup
To avoid unnecessary AWS charges, destroy the resources after testing:

terraform destroy
Confirm resources are deleted from AWS Console after destroy completes.