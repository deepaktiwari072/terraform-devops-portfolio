locals {
  prefix_name = "${var.gcp_project_name}-${var.environment}"
}

data "google_compute_image" "centos" {
  family  = "centos-stream-9"
  project = "centos-cloud"

}