# state.tf - Remote State Configuration (Production)

terraform {
  backend "azurerm" {
    #  # Storage account details (create this first!)
    resource_group_name  = "development"
    storage_account_name = "terraformdevdeepak" # Must be globally unique
    container_name       = "tfstate"
    key                  = "2tierinfra/terraform.tfstate"

    #Optional: Use SAS token or Managed Identity for auth
  }
}

