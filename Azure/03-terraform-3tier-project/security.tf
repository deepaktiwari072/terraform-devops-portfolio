# security.tf
# WHY: NSGs are like firewalls controlling traffic between tiers
# Each tier has different security rules

# ============================================
# WEB TIER NSG - Controls traffic to web VMs
# ============================================
resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.project_name}-${var.environment}-web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # WHY: Security rules are processed by priority (lower number = higher priority)
  
  security_rule {
    name                       = "Allow-HTTP-Internet"
    priority                   = 100  # High priority - processed first
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"      # Any source port
    destination_port_range     = "80"     # HTTP port
    source_address_prefix      = "*"      # ANY IP address (the internet!)
    destination_address_prefix = "*"
    description                = "Allow web traffic from anywhere"
  }

  security_rule {
    name                       = "Allow-HTTPS-Internet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"    # HTTPS port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow secure web traffic from anywhere"
  }

  security_rule {
    name                       = "Allow-LoadBalancer-Probes"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"  # Azure's special tag
    destination_address_prefix = "*"
    description                = "Allow Azure Load Balancer health checks"
    # CRITICAL: Without this, Load Balancer thinks VMs are dead!
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000  # Low priority - catch-all rule
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all other inbound traffic"
  }
}

# ============================================
# APP TIER NSG - Strict control to app VMs
# ============================================
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.project_name}-${var.environment}-app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-From-Web-Tier"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"   # Common app server port (Java/Node.js/Python)
    source_address_prefixes    = [azurerm_subnet.web_subnet.address_prefixes[0]]  # ONLY web subnet
    destination_address_prefix = "*"
    description                = "Only allow traffic from web tier VMs"
    # WHY: App tier should ONLY receive requests from web tier
    # No direct internet access to app servers!
  }

  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"     # SSH port
    source_address_prefix      = "10.0.4.0/24"  # Bastion subnet (future)
    destination_address_prefix = "*"
    description                = "Allow admins to SSH via bastion host"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all other inbound traffic"
  }
}

# ============================================
# DB TIER NSG - Maximum security for database
# ============================================
resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.project_name}-${var.environment}-db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-SQL-From-App-Tier"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"   # SQL Server port
    source_address_prefixes    = [azurerm_subnet.app_subnet.address_prefixes[0]]  # ONLY app subnet
    destination_address_prefix = "*"
    description                = "Only allow database connections from app tier"
    # WHY: Database should ONLY be accessible by application tier
    # Web tier talks to app tier, which talks to DB
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all other inbound traffic"
  }
}

# ============================================
# ASSOCIATE NSGs WITH SUBNETS
# ============================================
# WHY: NSGs don't work until attached to a subnet or NIC

resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# ============================================
# APPLICATION SECURITY GROUPS (Advanced grouping)
# ============================================
# WHY: ASGs let you group VMs logically without using IP addresses
# If you add/remove VMs, rules still work!

resource "azurerm_application_security_group" "web_asg" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_application_security_group" "app_asg" {
  name                = "${var.project_name}-${var.environment}-app-asg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}