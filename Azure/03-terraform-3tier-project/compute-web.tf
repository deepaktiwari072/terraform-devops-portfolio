# compute-web.tf
# WHY: Web tier handles incoming HTTP traffic and routes to app tier

# ============================================
# PUBLIC IP FOR LOAD BALANCER
# ============================================
resource "azurerm_public_ip" "web_lb_ip" {
    allocation_method = "Static"
    location = azurerm_resource_group.rg.location
    name = "${var.project_name}-${var.environment}-web_lb_ip"
    resource_group_name = azurerm_resource_group.rg.name
    sku = "Standard"
    tags = var.tags
    
}

# ============================================
# PUBLIC LOAD BALANCER (Azure's ALB)
# ============================================

resource "azurerm_lb" "web_lb" {
    location = azurerm_resource_group.rg.location
    name = "${var.project_name}-${var.environment}-web_lb"
    resource_group_name = azurerm_resource_group.rg.name
    sku = "Standard"
    frontend_ip_configuration {
      name = "PublicIPAddress"
      public_ip_address_id = azurerm_public_ip.web_lb_ip.id
    }
    tags = var.tags
}
# ============================================
# LOAD BALANCER BACKEND POOL
# ============================================
resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
    loadbalancer_id = azurerm_lb.web_lb.id
    name = "web-backend-pool"
    
}
# ============================================
# HEALTH PROBE
# ============================================
resource "azurerm_lb_probe" "web_health_probe" {
    loadbalancer_id = azurerm_lb.web_lb.id
    name = "web-health-probe"
    port = 80
    protocol = "Http"
    request_path = "/"
    interval_in_seconds = 15
    number_of_probes = 2
    # WHY: Load balancer checks / every 15 seconds
  # After 2 failures (30 seconds), stops sending traffic to that VM
}

# ============================================
# LOAD BALANCING RULE
# ============================================

resource "azurerm_lb_rule" "http_rule" {
    backend_port = 80
    frontend_ip_configuration_name = "PublicIPAddress"
    frontend_port = 80
    loadbalancer_id = azurerm_resource_group.rg.id
    name = "http-rule"
    protocol = "Tcp"
    backend_address_pool_ids = [ azurerm_lb_backend_address_pool.web_backend_pool.id ]
    probe_id = azurerm_lb_probe.web_health_probe.id    
}

# ============================================
# WEB TIER VIRTUAL MACHINES
# ============================================

# Network Interface for each web VM
resource "azurerm_network_interface" "web_nics" {
  count               = var.web_vm_count
  name                = "${var.project_name}-${var.environment}-web-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"  # Azure assigns IP
  }
}

# Connect web NICs to load balancer backend pool
resource "azurerm_network_interface_backend_address_pool_association" "web_lb_assoc" {
  count                   = var.web_vm_count
  network_interface_id    = azurerm_network_interface.web_nics[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_backend_pool.id
}

# Connect web VMs to Application Security Group
resource "azurerm_network_interface_application_security_group_association" "web_asg_assoc" {
  count                         = var.web_vm_count
  network_interface_id          = azurerm_network_interface.web_nics[count.index].id
  application_security_group_id = azurerm_application_security_group.web_asg.id
}
resource "azurerm_linux_virtual_machine" "web_vms" {
  count                           = var.web_vm_count
  name                            = "${var.project_name}-${var.environment}-web-vm-${count.index + 1}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.vm_sizes[var.environment]
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  
  network_interface_ids = [azurerm_network_interface.web_nics[count.index].id]

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
 # Install NGINX web server on startup
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Web Server ${count.index + 1} - Environment: ${var.environment}</h1>" > /var/www/html/index.html
    echo "<p>Hostname: $(hostname)</p>" >> /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  tags = var.tags
}
