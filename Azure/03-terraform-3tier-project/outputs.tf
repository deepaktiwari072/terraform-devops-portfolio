# outputs.tf
# WHY: Shows you the important information after deployment

output "load_balancer_public_ip" {
  description = "Public IP address of the web load balancer"
  value       = azurerm_public_ip.web_lb_ip.ip_address
}

output "web_app_url" {
  description = "URL to access your web application"
  value       = "http://${azurerm_public_ip.web_lb_ip.ip_address}"
}

output "internal_lb_ip" {
  description = "Internal IP of the app load balancer (for web tier to call)"
  value       = azurerm_lb.app_lb.frontend_ip_configuration[0].private_ip_address
}

output "sql_server_fqdn" {
  description = "SQL Server address for connection strings"
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Database name for connection strings"
  value       = azurerm_mssql_database.app_db.name
}

output "nat_gateway_public_ip" {
  description = "Public IP used by app tier for outbound internet"
  value       = azurerm_public_ip.nat_ip.ip_address
}

output "web_vm_private_ips" {
  description = "Private IPs of web tier VMs"
  value       = azurerm_network_interface.web_nics[*].private_ip_address
}

output "app_vm_private_ips" {
  description = "Private IPs of app tier VMs"
  value       = azurerm_network_interface.app_nics[*].private_ip_address
}
