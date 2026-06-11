output "vpc_network_name" {
  description = "VPC network name from the VPC module."
  value       = module.vpc.network_name
}

output "gke_subnet_name" {
  description = "GKE subnet name from the VPC module."
  value       = module.vpc.subnet_name
}

output "pods_range_name" {
  description = "Secondary range name for GKE Pods."
  value       = module.vpc.pods_range_name
}

output "services_range_name" {
  description = "Secondary range name for Kubernetes Services."
  value       = module.vpc.services_range_name
}

output "artifact_registry_url" {
  description = "Artifact Registry Docker URL used by GitHub Actions."
  value       = module.artifact_registry.repository_url
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster."
  value       = module.gke.cluster_name
}

output "gke_cluster_location" {
  description = "Region where the GKE cluster is created."
  value       = module.gke.cluster_location
}

output "gke_node_pool_name" {
  description = "Name of the GKE worker node pool."
  value       = module.gke_node_pool.node_pool_name
}

output "github_actions_service_account" {
  description = "Service account email that GitHub Actions will impersonate."
  value       = module.github_wif.terraform_service_account_email
}

output "github_actions_workload_identity_provider" {
  description = "Workload Identity Provider resource name used by GitHub Actions."
  value       = module.github_wif.workload_identity_provider
}