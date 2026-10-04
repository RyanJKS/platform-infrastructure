locals {
  # Replace with the real DEV-HUB subscription ID before running.
  sub_to_sa = {
    "DEV-JKS" = {
      subscription_id = "91c6f5e9-f6ab-400c-b5e7-265fd48053d3"
      regions         = ["uks"]
    }
  }

  region_short_to_long_map = {
    uks  = "uksouth"
    eus2 = "eastus2"
  }

  current_sub     = "DEV-JKS"
  subscription_id = local.sub_to_sa[local.current_sub].subscription_id
  container_name  = "tfstate"

  configs = local.sub_to_sa[local.current_sub]

  rg_to_sa = {
    for region_short in local.configs.regions :
    upper("${local.current_sub}-TFSTATE-${region_short}-RG") => {
      sa_name = lower("${replace(local.current_sub, "-", "")}tfstate${region_short}sa"),
      region  = local.region_short_to_long_map[region_short]
    }
  }

  tags = {
    Environment = "dev"
    Purpose     = "terraform-state"
  }
}

resource "azurerm_resource_group" "tfstate" {
  for_each = local.rg_to_sa
  name     = each.key
  location = each.value.region
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  for_each                 = local.rg_to_sa
  name                     = each.value.sa_name
  resource_group_name      = azurerm_resource_group.tfstate[each.key].name
  location                 = azurerm_resource_group.tfstate[each.key].location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  for_each              = local.rg_to_sa
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.tfstate[each.key].id
  container_access_type = "private"
}

data "azurerm_client_config" "this" {}

resource "azurerm_role_assignment" "sa_owner" {
  for_each             = local.rg_to_sa
  scope                = azurerm_resource_group.tfstate[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.this.object_id
}
