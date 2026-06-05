# compute-app.tf
# WHY: App tier runs business logic and communicates with database

# ============================================
# INTERNAL LOAD BALANCER (No public IP!)
# ============================================
resource "azurerm_lb" "app_lb" {
  name                = "${var.project_name}-${var.environment}-app-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  
  # INTERNAL load balancer - no public frontend
  frontend_ip_configuration {
    name                          = "InternalIP"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

# Backend pool for app VMs
resource "azurerm_lb_backend_address_pool" "app_backend_pool" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "app-backend-pool"
}

# Health probe for app tier
resource "azurerm_lb_probe" "app_health_probe" {
  loadbalancer_id     = azurerm_lb.app_lb.id
  name                = "app-health-probe"
  port                = 8080
  protocol            = "Tcp"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load balancing rule for app tier
resource "azurerm_lb_rule" "app_rule" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "app-rule"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "InternalIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend_pool.id]
  probe_id                       = azurerm_lb_probe.app_health_probe.id
}

# ============================================
# APP TIER VIRTUAL MACHINES
# ============================================

# Network Interface for each app VM (Private subnet)
resource "azurerm_network_interface" "app_nics" {
  count               = var.app_vm_count
  name                = "${var.project_name}-${var.environment}-app-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect app NICs to internal load balancer
resource "azurerm_network_interface_backend_address_pool_association" "app_lb_assoc" {
  count                   = var.app_vm_count
  network_interface_id    = azurerm_network_interface.app_nics[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_backend_pool.id
}

# Connect app VMs to Application Security Group
resource "azurerm_network_interface_application_security_group_association" "app_asg_assoc" {
  count                         = var.app_vm_count
  network_interface_id          = azurerm_network_interface.app_nics[count.index].id
  application_security_group_id = azurerm_application_security_group.app_asg.id
}

# App Virtual Machines (Private - no public IP)
resource "azurerm_linux_virtual_machine" "app_vms" {
  count                           = var.app_vm_count
  name                            = "${var.project_name}-${var.environment}-app-vm-${count.index + 1}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.vm_sizes[var.environment]
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  
  network_interface_ids = [azurerm_network_interface.app_nics[count.index].id]

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

  # Sample app that returns instance info
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Install Node.js for sample app
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    # Create simple API server
    cat > /opt/app.js << 'EOL'
    const http = require('http');
    const os = require('os');
    
    const server = http.createServer((req, res) => {
      res.writeHead(200, {'Content-Type': 'application/json'});
      res.end(JSON.stringify({
        message: 'Hello from App Server ${count.index + 1}',
        environment: '${var.environment}',
        hostname: os.hostname(),
        timestamp: new Date().toISOString()
      }));
    });
    
    server.listen(8080, () => {
      console.log('App server running on port 8080');
    });
    EOL
    
    # Run the app
    node /opt/app.js &
  EOF
  )

  tags = var.tags
}