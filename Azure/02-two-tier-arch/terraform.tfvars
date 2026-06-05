environment    = "dev"
location       = "East US"
project_name   = "myvms"
vm_count       = 2
admin_username = "azureuser"
admin_password = "Test@Pass123456!" # Change this!

tags = {
  Environment = "Development"
  Project     = "VM-Project"
  ManagedBy   = "Terraform"
  Owner       = "YourName"
}