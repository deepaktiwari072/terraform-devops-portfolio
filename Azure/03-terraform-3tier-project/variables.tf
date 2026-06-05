# variables.tf
# WHY: Variables make this code reusable across dev/staging/prod
# Change just the .tfvars file, not the code!

variable "environment" {
    description = "Environment name (dev/staging/prod)"
    type = string
    default = "dev"
}

variable "location" {
    description = "Azure region"
    type = string
    default = "East US"
}

variable "project_name" {
    description = "Project name for resource naming"
    type = string
    default = "3tier"
}

variable "vm_sizes" {
    description = "VM sizes for each env"
    type = map(string)
    default = {
      "dev" = "Standard_B1s"
      staging = "Standard_B2s"
      prod = "Standard_D2s_v3"
    }
}
variable "web_vm_count" {
    description = "Number of web tier VMs"
     # WHY: Multiple VMs = High Availability (if one fails, others work)
    type = number
    default = 2
}

variable "app_vm_count" {
    description = "Number of app tier VMs"
    type = number
    default = 2
}

variable "admin_username" {
    description = "username fo VM"
    type = string
    default = "azureuser"
}

variable "admin_password" {
    description = "password for VM,s"
    type = string
    default = "null"
    sensitive = true
     # WHY: Azure requires complex passwords for security
     validation {
       condition = var.admin_password != null ? length(var.admin_password) >= 12 : true
       error_message = "Password must be at least 12 characters with uppercase, lowercase, number, and special character."
     }
}

variable "db_admin_login" {
    description = "database admin login"
    type = string
    default = "dbadmin"
    sensitive = true
}

variable "db_admin_password" {
    description = "database admin password"
    type = string
    sensitive = true
    default = "null"

    validation {
      condition = var.db_admin_password != null ? length(var.db_admin_password) >= 8 : true
      error_message = "Database password must be at least 8 characters."
    }
}

variable "tags" {
    description = "resource tags for organization"
    type = map(string)
    default = {
      "ManagedBy" = "Terraform"
      project = "3-tier-infra"
    }
}