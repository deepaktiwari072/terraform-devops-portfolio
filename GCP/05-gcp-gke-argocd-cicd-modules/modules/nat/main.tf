resource "google_compute_router" "main" {
    name = "${var.name_prefix}-cloud-router"
    network = var.network_id
    description = "Cloud router used by GKE cloud NAT gateway"
    region = var.gcp_region
    
}
resource "google_compute_router_nat" "main" {
    name = "${var.name_prefix}-nat-gateway"
    router = google_compute_router.main.name
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    region = var.gcp_region
    nat_ip_allocate_option = "AUTO_ONLY"

    subnetwork {
      name = var.subnet_id
         # NATs the primary node range and both secondary Pod/Service ranges.
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

    }
    