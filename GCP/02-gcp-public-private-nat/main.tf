locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
data "google_compute_image" "centos" {
  family  = "centos-stream-9"
  project = "centos-cloud"
}

# Network, Subnetwork , Compute

resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "public" {
  ip_cidr_range = var.public_subnet_cidr
  name          = "${local.name_prefix}-public-subnet"
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork" "private" {
  ip_cidr_range = var.private_subnet_cidr
  name          = "${local.name_prefix}-private-subnet"
  network       = google_compute_network.main.id

}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${local.name_prefix}-allow-ssh"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-01", "app-01"]

}

resource "google_compute_firewall" "allow_http" {
  name    = "${local.name_prefix}-allow-http"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags   = ["web-01", "app-01"]
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_firewall" "allow_internal" {
  name    = "${local.name_prefix}-allow-internal"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    var.public_subnet_cidr,
    var.private_subnet_cidr
  ]
  target_tags = [ "web-01", "app-01" ]

}

resource "google_compute_firewall" "web-https" {
  name = "${local.name_prefix}-web-https"
  network = google_compute_network.main.id
  allow {
    ports = [ "443" ]
    protocol = "tcp"
  }
  target_tags = [ "web-01", "app-01" ]
  source_ranges = [ "0.0.0.0/0" ]
  
}

resource "google_compute_router" "main" {
  name    = "${local.name_prefix}-router"
  network = google_compute_network.main.id
  region  = var.gcp_region

}

resource "google_compute_router_nat" "main" {
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.main.name
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "AUTO_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_instance" "web-01" {
  machine_type = "e2-micro"
  name         = "${local.name_prefix}-web-01"
  tags         = ["web-01"]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos.id
      size  = 20
      type  = "pd-balanced"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      # Public IP
    }
  }
metadata_startup_script = <<-EOF
  #!/bin/bash
  dnf install -y nginx
  systemctl enable nginx
  systemctl start nginx

  firewall-cmd --permanent --add-service=http || true
  firewall-cmd --permanent --add-service=https || true
  firewall-cmd --reload || true

  echo "<h1>Public Web VM</h1>" > /usr/share/nginx/html/index.html
EOF
}

resource "google_compute_instance" "app-01" {
  machine_type = "e2-micro"
  name         = "${local.name_prefix}-app-01"
  zone         = var.gcp_zone
  tags         = ["app-01"]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos.id
      size  = 20
      type  = "pd-balanced"
    }

  }
  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }
  metadata_startup_script = <<-EOF
  #!/bin/bash
  dnf install -y nginx
  systemctl enable nginx
  systemctl start nginx

  firewall-cmd --permanent --add-service=http || true
  firewall-cmd --permanent --add-service=https || true
  firewall-cmd --reload || true

  echo "<h1>Private app VM</h1>" > /usr/share/nginx/html/index.html
EOF
}
