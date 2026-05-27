variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
variable "vpc_cidr" {
  description = "CIDR block for vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availibility_zone" {
  description = "AZ for subnet placement"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}



variable "key_name" {
  description = "Defining pem key here so EC2 can take it pem key"
  default = "dev-web-server-key"
}

variable "db_username" {
  description = "RDS master username"
  default = []
}

variable "db_password" {
  description = "RDS master password "
  default = []
  sensitive = true
}