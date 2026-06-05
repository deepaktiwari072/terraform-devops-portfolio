# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnets for each tier
resource "azurerm_subnet" "subnets" {
  for_each = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    app = {
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = []
    }
    db = {
      address_prefixes = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
  }
  
  name                 = "subnet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

# Network Security Group with Rules
    
resource "azurerm_network_security_group" "name" {
    location = "value"
    name = "value"
    resource_group_name = "value"
    
    
}