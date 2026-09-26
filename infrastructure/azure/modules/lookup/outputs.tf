output "this" {
  value = data.azurerm_client_config.current
}

output "users" {
  value = data.azuread_users.users
}

output "groups" {
  value = data.azuread_groups.groups
}

output "service_principals" {
  value = data.azuread_service_principals.service_principals
}

