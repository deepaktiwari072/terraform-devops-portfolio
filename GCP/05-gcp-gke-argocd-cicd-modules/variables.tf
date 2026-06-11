variable "gcp_project_id" {
  description = "GCP project ID where all resources for the GKE CI/CD platform will be created."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for regional resources such as subnet and Artifact Registry."
  type        = string
  default     = "us-central1"
}

variable "project_name" {
  description = "Project name used as a prefix for resource naming."
  type        = string
  default     = "gke-argocd-cicd"
}

variable "environment" {
  description = "Environment name such as dev, staging, or prod."
  type        = string
  default     = "dev"
}

variable "network_name" {
  description = "Name suffix for the VPC network."
  type        = string
  default     = "vpc"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR range used by GKE nodes."
  type        = string
  default     = "10.70.0.0/24"
}

variable "pods_cidr" {
  description = "Secondary CIDR range used by GKE Pods in a VPC-native cluster."
  type        = string
  default     = "10.71.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR range used by Kubernetes Services in a VPC-native cluster."
  type        = string
  default     = "10.72.0.0/20"
}

variable "required_apis" {
  description = "GCP APIs required for GKE, Artifact Registry, IAM, Monitoring, and Logging."
  type        = list(string)

  default = [
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
}

variable "artifact_registry_repository_id" {
  description = "Artifact Registry repository ID used to store application Docker images."
  type        = string
  default     = "gke-argocd-cicd-dev-repo"
}

variable "master_ipv4_cidr_block" {
  description = "Private CIDR range reserved for communication with the GKE control plane."
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_deletion_protection" {
  description = "Protects GKE cluster from accidental deletion. Keep false for temporary practice."
  type        = bool
  default     = false
}

variable "node_machine_type" {
  description = "Compute Engine machine type used by GKE worker nodes."
  type        = string
  default     = "e2-medium"
}

variable "node_min_count" {
  description = "Minimum number of GKE worker nodes per zone."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of GKE worker nodes per zone."
  type        = number
  default     = 1
}

variable "node_disk_size_gb" {
  description = "Boot disk size for each GKE worker node."
  type        = number
  default     = 30
}
variable "gcp_zone" {
  description = "GCP zone used for zonal GKE cluster during daily practice."
  type        = string
  default     = "us-central1-a"
}

variable "git_owner" {
  description = "GitHub username or organization that owns the repository."
  type        = string
}

variable "git_repo" {
  description = "GitHub repository name allowed to deploy this infrastructure."
  type        = string
}

variable "git_branch" {
  description = "GitHub branch allowed to authenticate to GCP."
  type        = string
  default     = "main"
}

variable "terraform_deployer_roles" {
  description = "IAM roles assigned to the GitHub Actions Terraform deployer service account."
  type        = list(string)

  default = [
    "roles/compute.admin",
    "roles/container.admin",
    "roles/artifactregistry.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
    "roles/monitoring.admin",
    "roles/logging.admin"
  ]
}
