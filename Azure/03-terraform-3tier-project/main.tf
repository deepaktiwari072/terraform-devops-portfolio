resource "azurerm_resource_group" "rg" {
    location = var.location
    name = "${var.project_name}-${var.environment}-rg"
    tags = var.tags
    
}