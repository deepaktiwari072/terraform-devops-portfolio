# outputs.tf
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.blog_rg.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.blog_storage.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.blog_storage.id
}

output "deployment_summary" {
  description = "Summary of deployment"
  value       = "Deployed ${var.environment} environment in ${var.location}"
}