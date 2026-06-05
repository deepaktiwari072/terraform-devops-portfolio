# state.tf - Remote State Configuration (Production)

#terraform {
 # backend "azurerm" {
  #  # Storage account details (create this first!)
   # resource_group_name  = "terraform-state-rg"
    #storage_account_name = "tfstate123456789"  # Must be globally unique
    #container_name       = "tfstate"
    #key                  = "blog-project/terraform.tfstate"
    
    # Optional: Use SAS token or Managed Identity for auth
    # sas_token = var.sas_token
  #}
#}

