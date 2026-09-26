terraform {
  required_version = ">=1.3.4"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.0.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.12.0"
    }
  }
}
