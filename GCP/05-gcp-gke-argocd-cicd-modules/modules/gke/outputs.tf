output "cluster_name" {
  description = "Name of the created GKE cluster."
  value       = google_container_cluster.main.name
}

output "cluster_id" {
  description = "Provider-managed ID of the GKE cluster."
  value       = google_container_cluster.main.id
}

output "cluster_location" {
  description = "Region where the GKE cluster is created."
  value       = google_container_cluster.main.location
}

output "cluster_endpoint" {
  description = "GKE control-plane endpoint. Treat this value as sensitive."
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}