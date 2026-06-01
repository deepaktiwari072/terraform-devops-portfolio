variable "gcp_zone" {
  description = "Zone for gcs servics"
  type        = string
  default     = "us-central-1a"
}

variable "gcp_region" {
  description = "region for machine engine"
  type        = string
  default     = "us-central-1"

}

variable "machine_type" {
  description = "machine type of VM"
  type        = string
  default     = "e2-small"
}

variable "gcp_project_id" {
  description = "project ID for GCP services"
  type        = string
}

variable "gcp_project_name" {
  description = "Project name of GCP"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR for private IP"
  type        = string
  default     = "192.168.2.0"
}

variable "public_subnet_cidr" {
  description = "CIDR for public IP"
  type        = string
  default     = "192.168.1.0"
}

variable "environment" {
  description = "env for gcp"
  type        = string
  default     = "development"
}

variable "bucket_name" {
  type = string

}