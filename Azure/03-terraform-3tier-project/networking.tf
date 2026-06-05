# networking.tf
# WHY: Networks isolate traffic. Each tier has its own subnet for security.

# VIRTUAL NETWORK - The overall container for all networking

resource "azurerm_virtual_network" "vnet" {
    address_space = [ "192.68.0.0/16" ]
    location = var.location
    name = "${var.project_name}-${var.environment}-vnet"
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags
    
}
# ============================================
# WEB SUBNET - Public-facing tier
# ============================================
resource "azurerm_subnet" "web_subnet" {
    name = "web-subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = [ "192.168.1.0/24" ]
}

# ============================================
# APP SUBNET - Private application tier
# ============================================

resource "azurerm_subnet" "app_subnet" {
    address_prefixes = [ "192.168.2.0/24" ]
    name = "app_subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    
}

resource "azurerm_subnet" "db_subnet" {
    address_prefixes = [ "192.168.3.0/24" ]
    name = "db_subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name

    # WHY: SQL Database needs special delegation to be created in this subnet
  delegation {
    name = "sql-delegation"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_nat_gateway" "nat_gateway" {
    location = var.location
    name = "nat_gateway"
    resource_group_name = azurerm_resource_group.rg.name
    
}

resource "azurerm_public_ip" "nat_ip" {
    allocation_method = "Static"
    sku = "Standard"
    location = var.location
    name = "${var.project_name}-${var.environment}-nat_ip"
    resource_group_name = azurerm_resource_group.rg.name
    
}

# Connecting NAT gateway to public IP
resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
    nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
    public_ip_address_id = azurerm_public_ip.nat_ip.id
    
}

# COnnecting NAT gateway to private subnet

resource "azurerm_subnet_nat_gateway_association" "nat_subnet_assoc" {
    nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
    subnet_id = azurerm_subnet.app_subnet.id
    
}

# ============================================
# WHY NAT GATEWAY?
# ============================================
# App tier needs to:
# 1. Download software updates
# 2. Pull Docker images  
# 3. Call external APIs
#
# But app tier should NEVER be directly accessible from internet
# NAT Gateway provides ONE-WAY internet access (outbound only)
# VMs can reach out, but nothing can reach in

