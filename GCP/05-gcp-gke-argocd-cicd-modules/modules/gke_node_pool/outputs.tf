output "node_pool_name" {
  description = "Name of the GKE worker node pool."
  value       = google_container_node_pool.main.name
}

output "node_pool_id" {
  description = "Provider-managed ID of the GKE worker node pool."
  value       = google_container_node_pool.main.id
}