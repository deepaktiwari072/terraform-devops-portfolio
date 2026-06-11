output "repository_id" {
  description = "Identifier of the created Artifact Registry repository."
  value       = google_artifact_registry_repository.main.repository_id
}

output "repository_name" {
  description = "Provider-managed full name of the Artifact Registry repository."
  value       = google_artifact_registry_repository.main.name
}

output "repository_url" {
  description = "Docker repository URL used to tag and push container images."
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.main.repository_id}"
}