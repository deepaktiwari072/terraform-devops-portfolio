resource "google_container_cluster" "main" {
  name     = "${var.name_prefix}-cluster"
  project  = var.gcp_project_id
  location = var.gcp_zone

  network    = var.network_id
  subnetwork = var.subnet_id

  # The default node pool is removed because worker nodes will be managed
  # separately using google_container_node_pool.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Creates a VPC-native cluster where Pods and Services receive IPs from
  # the secondary subnet ranges created by the VPC module.
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Worker nodes receive private IPs only.
  # The control plane still has a public endpoint for easier practice access.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Workload Identity allows Kubernetes service accounts to access GCP APIs
  # without storing service-account JSON keys inside the cluster.
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Sends system and workload logs to Cloud Logging.
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ]
  }

  # Sends system and workload metrics to Cloud Monitoring.
  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS"
    ]

    managed_prometheus {
      enabled = true
    }
  }

  # Release channels provide controlled automatic GKE version upgrades.
  release_channel {
    channel = "REGULAR"
  }

  deletion_protection = var.deletion_protection
}