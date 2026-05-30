variable "public_subnet_cidr" {
  type        = string
  description = "public subnet cidr"
  default     = "192.168.1.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "private subnet cidr"
  default     = "192.168.2.0/24"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "my first project"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "gcp_zone" {
  type        = string
  description = "defining region here"
  default     = "asia-south1-a"
}

variable "gcp_project_id" {
type = string
description = "Project ID of GCP"

}

variable "gcp_region" {
  type = string
  description = "Zone for vpc"
  default = "us-central-1"
}

variable "gcp_project_name" {
  type = string

}

