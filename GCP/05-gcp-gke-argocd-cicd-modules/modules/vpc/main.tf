resource "google_compute_network" "main" {
  name                    = "${var.name_prefix}-${var.network_name}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Custom VPC for GKE, Argo CD, and CI/CD workloads."

}

resource "google_compute_subnetwork" "gke" {
  name          = "${var.name_prefix}-gke-subnet"
  network       = google_compute_network.main.id
  region        = var.gcp_region
  ip_cidr_range = var.subnet_cidr
  description   = "Primary subnet for GKE worker nodes."
  /*
GKE VPC-native cluster uses secondary IP ranges.
Pods get IPs from pods_cidr.
Services get IPs from services_cidr.
Nodes get IPs from subnet_cidr.
*/

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "service-range"
    ip_cidr_range = var.services_cidr
  }

}
