resource "google_artifact_registry_repository" "main" {
  format        = "DOCKER"
  repository_id = var.repository_id
  project       = var.gcp_project_id
  location      = var.gcp_region
  description   = var.description

  labels = var.lables

  # Immutable tags prevent an existing image tag from being overwritten.
  # CI pipelines should use unique tags such as the Git commit SHA.
  docker_config {
    immutable_tags = true
  }
}