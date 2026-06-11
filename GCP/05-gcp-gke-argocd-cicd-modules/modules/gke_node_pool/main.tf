resource "google_container_node_pool" "main" {
  cluster  = var.cluster_name
  name     = "${var.name_prefix}-primary-node-pool"
  location = var.cluster_location
  # For regional clusters, node_count represents the number of nodes per zone.
  initial_node_count = var.min_node_count
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-balanced"
    labels       = var.labels
    # Prevents workloads from accessing the legacy Compute Engine metadata API.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Gives nodes permission to interact with Google Cloud APIs.
    # Workloads should still use Workload Identity for least-privilege access.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

}