locals {
  # Replace with the real DEV-HUB subscription ID before running.
  subscription_id      = "00000000-0000-0000-0000-000000000000"
  location             = "eastus2"
  resource_group_name  = "rg-devhub-tfstate-eus2"
  storage_account_name = "stdevhubtfstateeus2"
  container_name       = "tfstate"

  tags = {
    Environment = "dev"
    Purpose     = "terraform-state"
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
