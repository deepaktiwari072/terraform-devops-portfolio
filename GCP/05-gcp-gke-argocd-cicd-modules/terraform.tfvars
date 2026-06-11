gcp_project_id = "project-b18ced1d-cbfc-41b5-ba1"
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"

project_name = "gke-argocd-cicd"
environment  = "practice"

subnet_cidr   = "10.70.0.0/24"
pods_cidr     = "10.71.0.0/16"
services_cidr = "10.72.0.0/20"

node_machine_type = "e2-medium"
node_min_count    = 1
node_max_count    = 1
node_disk_size_gb = 30

gke_deletion_protection = false

github_owner  = "YOUR_GITHUB_USERNAME"
github_repo   = "YOUR_REPOSITORY_NAME"
github_branch = "main"