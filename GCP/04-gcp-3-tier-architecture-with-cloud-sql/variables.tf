variable "gcp_project_id" {
  description = "project ID for GCP"
  type        = string
}

variable "gcp_project_name" {
  description = "project Name of GCP"
  type        = string
}

variable "environment" {
  description = "env for GCP"
  type        = string
  default     = "development"
}

variable "gcp_region" {
  description = "region for GCP"
  type        = string
  default     = "us-central-1a"
}

variable "gcp_zone" {
  description = "zone for GCP"
  type        = string
  default     = "us-central-1"
}

variable "public_subnet_cidr" {
  description = "CIDR for public"
  type        = string
  default     = "192.168.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnet"
  type        = string
  default     = "192.168.2.0/24"
}

variable "db_name" {
  description = "DB name"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "db user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for DB"
  type        = string
  sensitive   = true
}

variable "machine_type" {
    description = "define machine type"
    type = string
    default = "e2-small"
}

