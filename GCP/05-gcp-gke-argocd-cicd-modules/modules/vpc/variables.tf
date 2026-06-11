variable "name_prefix" {
  description = "Common name prefix passed from root module, usually project name plus environment."
  type        = string
}

variable "gcp_region" {
  description = "GCP region where the subnet will be created."
  type        = string
}

variable "network_name" {
  description = "Name suffix for the VPC network."
  type        = string
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR range used by GKE nodes."
  type        = string
}

variable "pods_cidr" {
  description = "Secondary CIDR range used by GKE Pods."
  type        = string
}

variable "services_cidr" {
  description = "Secondary CIDR range used by Kubernetes Services."
  type        = string
}
