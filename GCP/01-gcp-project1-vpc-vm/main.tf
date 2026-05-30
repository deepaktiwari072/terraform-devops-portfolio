
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "public" {
  ip_cidr_range = "10.0.0.0/24"
  name          = "${local.name_prefix}-public-subnet"
  network       = google_compute_network.main.id
  region        = var.gcp_region

}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${local.name_prefix}-allow-ssh"
  network = google_compute_network.main.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${local.name_prefix}-allow-http"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]

}

resource "google_compute_instance" "web" {
  machine_type = "e2-micro"
  name         = "${local.name_prefix}-web"
  tags = [ "ssh", "web" ]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos.self_link
      size  = 20
      type  = "pd-balanced"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public.id

    access_config {
      # Creates an ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOF
  #!/bin/bash
  dnf update -y
  dnf install -y nginx
  systemctl enable nginx
  systemctl start nginx

  cat > /usr/share/nginx/html/index.html <<HTML
  <html>
    <head>
      <title>GCP Terraform VM</title>
    </head>
    <body>
      <h1>Hello from Terraform on GCP CentOS</h1>
      <p>This VM was created using Terraform.</p>
    </body>
  </html>
  HTML
EOF
}

    