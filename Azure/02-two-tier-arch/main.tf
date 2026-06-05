# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-${var.environment}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.project_name}-${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ============================================
# LINUX VMs with Public IPs (FIXED CASE)
# ============================================

# Create multiple public IPs for Linux VMs
resource "azurerm_public_ip" "vm_ips" {
  count               = var.vm_count
  name                = "${var.project_name}-${var.environment}-pip-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"   # FIXED: Capital S
  sku                 = "Standard" # FIXED: Capital S
  tags                = var.tags
}

# Create network interfaces for Linux VMs
resource "azurerm_network_interface" "vm_nics" {
  count               = var.vm_count
  name                = "${var.project_name}-${var.environment}-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ips[count.index].id
  }
  tags = var.tags
}

# Create Linux VMs
resource "azurerm_linux_virtual_machine" "vms" {
  count                           = var.vm_count
  name                            = "${var.project_name}-${var.environment}-vm-${count.index + 1}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.vm_sizes[var.environment]
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.vm_nics[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Linux VM ${count.index + 1} - Environment: ${var.environment}</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  tags = var.tags
}

# ============================================
# WINDOWS VM (NEW - Fixed with proper NICs)
# ============================================

# Public IP for Windows VM (FIXED CASE)
resource "azurerm_public_ip" "win_ip" {
  name                = "${var.project_name}-${var.environment}-win-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"   # FIXED: Capital S
  sku                 = "Standard" # FIXED: Capital S
  tags                = var.tags
}

# Network Interface for Windows VM (CREATED - was missing)
resource "azurerm_network_interface" "win_nics" {
  name                = "${var.project_name}-${var.environment}-win-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.win_ip.id
  }
  tags = var.tags
}

# Windows Virtual Machine (FIXED)
resource "azurerm_windows_virtual_machine" "windowsvm" {
  name                = "${var.project_name}-${var.environment}-windowsvm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_sizes[var.environment]

  # Fixed: Correct field order
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.win_nics.id] # FIXED: Now exists!

  # Windows specific settings
  patch_mode = "AutomaticByOS"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${var.project_name}-${var.environment}-osdisk"
  }

  # Windows Server 2022 image
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  # Optional: Install IIS via PowerShell
  custom_data = base64encode(<<-EOF
    <powershell>
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    Set-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value "<h1>Windows VM - ${var.environment}</h1><h2>Deployed by Terraform</h2>"
    </powershell>
  EOF
  )

  tags = var.tags
}