output "cloud_sql_private_ip" {
  value = google_sql_database_instance.mysql.private_ip_address
}

output "database_name" {
  value = google_sql_database.app.name
}
