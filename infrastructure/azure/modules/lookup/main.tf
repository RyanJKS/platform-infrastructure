locals {
  # Filter out empty or blank strings from user_mails
  filtered_user_mails = [
    for email in var.user_mails : email
    if email != null && trim(email, " ") != ""
  ]

}

data "azurerm_client_config" "current" {}

data "azuread_users" "users" {
  mails          = local.filtered_user_mails
  ignore_missing = var.ignore_missing.azuread_users
}

data "azuread_groups" "groups" {
  display_names  = var.group_names
  ignore_missing = var.ignore_missing.azuread_groups
}

data "azuread_service_principals" "service_principals" {
  display_names  = var.service_principal_names
  ignore_missing = var.ignore_missing.azuread_service_principals
}
