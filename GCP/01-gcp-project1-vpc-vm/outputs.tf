output "vpc_name" {
  value = google_compute_network.main.name
}

output "subnet_name" {
  value = google_compute_subnetwork.public.name
}

output "vm_name" {
  value = google_compute_instance.web.name
}

output "vm_public_ip" {
  value = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "website_url" {
  value = "http://${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}"
}