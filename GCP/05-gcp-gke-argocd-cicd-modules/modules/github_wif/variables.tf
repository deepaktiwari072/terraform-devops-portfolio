variable "gcp_project_id" {
  description = "GCP project ID where Workload Identity Federation resources are created."
  type        = string
}

variable "name_prefix" {
  description = "Common naming prefix used for WIF pool, provider, and service account."
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or username that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name allowed to authenticate to GCP."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to authenticate to GCP, for example main."
  type        = string
  default     = "main"
}

variable "terraform_roles" {
  description = "IAM roles granted to the Terraform deploy service account."
  type        = list(string)
}
variable "service_account_id" {
  description = "Short service account ID. Must be between 6 and 30 characters."
  type        = string
  default     = "github-tf-deployer"

  validation {
    condition     = can(regex("^[a-z](?:[-a-z0-9]{4,28}[a-z0-9])$", var.service_account_id))
    error_message = "service_account_id must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "workload_identity_pool_id" {
  description = "Short Workload Identity Pool ID. Must not exceed 32 characters."
  type        = string
  default     = "github-actions-pool"

  validation {
    condition     = length(var.workload_identity_pool_id) <= 32
    error_message = "workload_identity_pool_id must not exceed 32 characters."
  }
}

variable "workload_identity_provider_id" {
  description = "Short Workload Identity Provider ID. Must not exceed 32 characters."
  type        = string
  default     = "github-provider"

  validation {
    condition     = length(var.workload_identity_provider_id) <= 32
    error_message = "workload_identity_provider_id must not exceed 32 characters."
  }
}