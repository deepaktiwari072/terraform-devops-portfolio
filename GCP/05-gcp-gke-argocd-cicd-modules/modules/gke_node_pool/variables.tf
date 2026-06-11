variable "gcp_project_id" {
  description = "GCP project ID where the GKE node pool will be created."
  type        = string
}

variable "name_prefix" {
  description = "Common prefix used for naming the node pool."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster that will own this node pool."
  type        = string
}

variable "cluster_location" {
  description = "Region where the GKE cluster and node pool are located."
  type        = string
}

variable "machine_type" {
  description = "Compute Engine machine type used by GKE worker nodes."
  type        = string
  default     = "e2-standard-2"
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone maintained by autoscaling."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes per zone allowed by autoscaling."
  type        = number
  default     = 2
}

variable "disk_size_gb" {
  description = "Boot disk size in GB for each GKE worker node."
  type        = number
  default     = 30
}

variable "labels" {
  description = "Labels applied to GKE worker nodes for environment identification and cost tracking."
  type        = map(string)
  default     = {}
}