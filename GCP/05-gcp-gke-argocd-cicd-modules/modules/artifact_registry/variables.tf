variable "gcp_project_id" {
  description = "GCP project ID where the Artifact Registry repository will be created."
  type        = string
}

variable "gcp_region" {
  description = "GCP region where the Artifactory Regisrty Repository will be created"
  type        = string
}

variable "repository_id" {
  description = "Unique repository identifier used in Artifact Registry URLs."
  type        = string
}
variable "description" {
  description = "Human-readable description of the Artifact Registry URLS."
}

variable "lables" {
  description = "Labels applied to the Artifact Registry repository for ownership, environment, and cost tracking."
  type        = map(string)
  default     = {}
}