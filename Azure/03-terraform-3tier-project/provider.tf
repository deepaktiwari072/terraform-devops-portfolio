terraform {
  required_providers {
    azurerm  = {
        source = "hashicorp/azurerm"
        version = "~>3.0"
    }
    random = {
        source = "hashicorp/random"
        version = "~>3.0"
    }
  }
}

provider "azurerm" {
    features {
        # WHY: During learning/cleanup, we want to delete everything
        # In production, set this to 'true' to prevent accidental deletion
        resource_group {
          prevent_deletion_if_contains_resources = false
        }
    }
    
}