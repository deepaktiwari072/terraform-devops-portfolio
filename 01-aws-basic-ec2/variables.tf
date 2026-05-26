variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "Deployment aws region"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC cidr for development VPC"
}

variable "aws_subnet_tag" {
  type    = string
  default = "public_subnet"
}

variable "instance_type" {
  description = "Instance type for EC2 instance (web-server)"
  type        = string
  default     = "t2.micro"
}

variable "az" {
  description = "Availibility zone for web server"
  type        = string
  default     = "us-west-2a"
}