output "network_name" {
  description = "Name of the created VPC network."
  value       = google_compute_network.main.name

}

output "network_id" {
  description = "ID/self-link of the created VPC network."
  value       = google_compute_network.main.id
}

output "subnet_name" {
  description = "Name of the GKE subnet."
  value       = google_compute_subnetwork.gke.name

}

output "subnet_id" {
  description = "ID/self-link of the GKE subnet."
  value       = google_compute_subnetwork.gke.id

}

output "pods_range_name" {
  description = "Name of the secondary IP range used for GKE Pods."
  value       = "pods-range"
}

output "services_range_name" {
  description = "Name of the secondary IP range used for Kubernetes Services."
  value       = "services-range"
}