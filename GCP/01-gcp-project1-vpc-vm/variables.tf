
variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "asia-south-1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-south1-a"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "gcp-foundation"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
variable "gcp_project_id" {
  description = "project id for GCP"
  type        = string
}
variable "gcp_project_name" {
  description = "project name for gcp"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "allowing my IP for SSH"
  type        = string
  default     = "0.0.0.0/0"
}