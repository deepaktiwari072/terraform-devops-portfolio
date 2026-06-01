resource "google_compute_network" "main" {
  name                    = "${local.prefix_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  ip_cidr_range = var.public_subnet_cidr
  name          = "${local.prefix_name}-public-subnet"
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork" "private" {
  ip_cidr_range = var.private_subnet_cidr
  name          = "${local.prefix_name}-private-subnet"
  network       = google_compute_network.main.id

}

resource "google_compute_firewall" "allow-iap-ssh" {
  name    = "${local.prefix_name}-allow-iap-ssh"
  network = google_compute_network.main.id

  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  target_tags   = ["ssh"]
  source_ranges = ["35.235.240.0/20"]

}

resource "google_compute_firewall" "allow-http" {
  name    = "${local.prefix_name}-allow-http"
  network = google_compute_network.main.id

  allow {
    ports    = ["80"]
    protocol = "tcp"
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags   = ["web"]

}

resource "google_compute_firewall" "allow-db" {
  name    = "${local.prefix_name}-allow-db"
  network = google_compute_network.main.id

  allow {
    ports    = ["3306"]
    protocol = "tcp"
  }

  source_ranges = ["192.168.2.0/24"]
  source_tags   = ["db"]

}

resource "google_compute_firewall" "allow-internal" {
  name    = "${local.prefix_name}-allow-internal"
  network = google_compute_network.main.id

  allow {
    ports    = ["0-65535"]
    protocol = "tcp"
  }

  allow {
    protocol = "icmp"
  }
  source_ranges = [var.private_subnet_cidr,
  var.public_subnet_cidr]
}

resource "google_compute_router" "main-router" {
  name    = "${local.prefix_name}-main-router"
  network = google_compute_network.main.id
  region  = var.gcp_region

}

resource "google_compute_router_nat" "main-nat" {
  name                               = "${local.prefix_name}-main-nat"
  router                             = google_compute_router.main-router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

}

resource "google_compute_instance" "web" {
  machine_type              = var.machine_type
  name                      = "${local.prefix_name}-web"
  zone                      = var.gcp_zone
  allow_stopping_for_update = true
  tags                      = ["ssh", "web"]
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
      # Public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx

    firewall-cmd --permanent --add-service=http || true
    firewall-cmd --reload || true

    echo "<h1>GCP 3-Tier Web Tier</h1>" > /usr/share/nginx/html/index.html
  EOF
}

resource "google_compute_instance" "app" {
  machine_type = var.machine_type
  name         = "${local.prefix_name}-app"
  zone         = var.gcp_zone
  tags         = ["web", "ssh"]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos.self_link
      size  = 20
      type  = "pd-balanced"
    }

  }
  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }
  depends_on = [google_compute_router_nat.main-nat]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    dnf install -y nginx mysql
    systemctl enable nginx
    systemctl start nginx

    firewall-cmd --permanent --add-service=http || true
    firewall-cmd --reload || true

    echo "<h1>GCP 3-Tier App Tier</h1>" > /usr/share/nginx/html/index.html
  EOF
}

############################################################################################
## Making DB configuration from here ##
resource "google_compute_global_address" "private_service_range" {
  name          = "${local.prefix_name}-private-service-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id

}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.main.id
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
  service                 = "servicenetworking.googleapis.com"

}



resource "google_sql_database_instance" "mysql" {
  database_version = "MYSQL_8_0"
  name             = "${local.prefix_name}-mysql"
  region           = var.gcp_region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_HDD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }
    backup_configuration {
      enabled = false
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_service_connection]

}

resource "google_sql_database" "app" {
  instance = google_sql_database_instance.mysql.name
  name     = var.db_name

}
resource "google_sql_user" "app" {
  instance = google_sql_database_instance.mysql.name
  name     = var.db_user
  password = var.db_password

}
