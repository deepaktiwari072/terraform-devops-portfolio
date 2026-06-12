terraform {
  backend "gcs" {
    bucket = "gcp-terraform-dev"
    prefix = "gke-argocd-cicd/practice"

  }
}
