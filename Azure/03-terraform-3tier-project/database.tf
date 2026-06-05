# database.tf
# WHY: Managed database service - Azure handles backups, patching, high availability

# SQL Server instance
resource "azurerm_mssql_server" "sql_server" {
  name                         = "${var.project_name}-${var.environment}-sql"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_admin_login
  administrator_login_password = var.db_admin_password
  
  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "app_db" {
  name           = "appdb"
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  
  # Different SKU based on environment
  sku_name       = var.environment == "prod" ? "S0" : "Basic"
  max_size_gb    = var.environment == "prod" ? 10 : 2
  
  tags = var.tags
}

# Firewall rule to allow Azure services (including App Service)
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
  # WHY: 0.0.0.0 tells Azure "allow all Azure services"
  # NOT the same as allowing all internet traffic!
}

# Virtual Network rule for direct access from app subnet
resource "azurerm_mssql_virtual_network_rule" "app_subnet_rule" {
  name      = "app-subnet-rule"
  server_id = azurerm_mssql_server.sql_server.id
  subnet_id = azurerm_subnet.db_subnet.id
  # WHY: Allows app VMs to connect without going through firewall
}