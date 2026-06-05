# Linux VM outputs
output "linux_vm_public_ips" {
  description = "Public IP addresses of Linux VMs"
  value       = azurerm_public_ip.vm_ips[*].ip_address
}

output "linux_website_urls" {
  description = "URLs to access Linux VMs"
  value = {
    for idx, ip in azurerm_public_ip.vm_ips[*].ip_address :
    "Linux-VM-${idx + 1}" => "http://${ip}"
  }
}

# Windows VM outputs
output "windows_vm_public_ip" {
  description = "Public IP address of Windows VM"
  value       = azurerm_public_ip.win_ip.ip_address
}

output "windows_website_url" {
  description = "URL to access Windows VM IIS"
  value       = "http://${azurerm_public_ip.win_ip.ip_address}"
}

output "windows_rdp_command" {
  description = "RDP connection command"
  value       = "mstsc.exe /v:${azurerm_public_ip.win_ip.ip_address}"
}

# Combined summary
output "deployment_summary" {
  value = <<-EOT
    ========================================
    DEPLOYMENT SUMMARY
    ========================================
    Environment: ${var.environment}
    Location: ${var.location}
    
    Linux VMs: ${var.vm_count}
      - Sizes: ${var.vm_sizes[var.environment]}
      - Public IPs: ${join(", ", azurerm_public_ip.vm_ips[*].ip_address)}
    
    Windows VM: 1
      - Size: ${var.vm_sizes[var.environment]}
      - Public IP: ${azurerm_public_ip.win_ip.ip_address}
      - RDP: mstsc.exe /v:${azurerm_public_ip.win_ip.ip_address}
    ========================================
  EOT
}