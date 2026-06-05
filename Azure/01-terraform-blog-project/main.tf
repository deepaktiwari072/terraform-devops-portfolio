resource "azurerm_resource_group" "blog_rg" {
    location = var.location
    name = "${var.project_name}-${var.environment}"
    tags = var.tags
    
}

resource "azurerm_storage_account" "blog_storage" {
    account_replication_type = "LRS"
    account_tier = "Standard"
    location = var.location
    name = "${var.project_name}-${var.environment}"
    resource_group_name = azurerm_resource_group.blog_rg.name
    
}

resource "azurerm_storage_container" "images" {
    name = "bolg-images"
    storage_account_name = azurerm_storage_account.blog_storage.name
    container_access_type = "private"
    
}