variable "gcp_project_id" {
  description = "GCP project ID used to configure Workload Identity Federation for GKE."
  type        = string
}

variable "name_prefix" {
  description = "Common naming prefix created from project name and environment."
  type        = string
}

variable "gcp_region" {
  description = "GCP region where the regional GKE cluster will be created."
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network where the GKE cluster will be created."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet used by GKE worker nodes."
  type        = string
}

variable "pods_range_name" {
  description = "Name of the subnet secondary IP range assigned to Kubernetes Pods."
  type        = string
}

variable "services_range_name" {
  description = "Name of the subnet secondary IP range assigned to Kubernetes Services."
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "Private CIDR range used by the GKE control plane. It must not overlap with existing network ranges."
  type        = string
  default     = "172.16.0.0/28"
}

variable "deletion_protection" {
  description = "Protects the GKE cluster from accidental deletion. Use true for production and false for temporary practice."
  type        = bool
  default     = false
}
variable "gcp_zone" {
  description = "GCP zone where the practice GKE cluster will be created."
  type        = string
}