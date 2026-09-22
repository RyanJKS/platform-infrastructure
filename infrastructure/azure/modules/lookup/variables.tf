variable "user_mails" {
  type    = list(string)
  default = []
}

variable "group_names" {
  type    = list(string)
  default = []
}

variable "service_principal_names" {
  type    = list(string)
  default = []
}

variable "ignore_missing" {
  type = object({
    azuread_users = bool,
    azuread_groups : bool,
    azuread_service_principals : bool,
  })
  default = {
    azuread_users              = true,
    azuread_groups             = true,
    azuread_service_principals = true,
  }
}

