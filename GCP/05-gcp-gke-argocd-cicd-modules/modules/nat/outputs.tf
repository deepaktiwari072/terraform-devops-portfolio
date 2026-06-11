output "router_name" {
    description = "Name of the cloud router used by Cloud NAT"
    value = google_compute_router.main.name
  
}

output "nat_name" {
    description = "Name of the Cloud NAT gateway"
    value = google_compute_router_nat.main.name
  
}