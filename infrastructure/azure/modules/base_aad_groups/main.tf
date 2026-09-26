locals {
  name_prefix = upper(join("-", [trimspace(var.group_prefix), trimspace(var.region), trimspace(var.environment)]))
}

resource "azuread_group" "admin" {
  display_name            = "${local.name_prefix}-ADMIN"
  description             = "Administrators for ${local.name_prefix}."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  owners                  = var.owners
  members                 = lookup(var.members, "ADMIN", toset([]))
}

resource "azuread_group" "writer" {
  display_name            = "${local.name_prefix}-WRITER"
  description             = "Writers for ${local.name_prefix}, including the ADMIN group."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  owners                  = var.owners
  members                 = setunion(lookup(var.members, "WRITER", toset([])), toset([azuread_group.admin.object_id]))
}

resource "azuread_group" "reader" {
  display_name            = "${local.name_prefix}-READER"
  description             = "Readers for ${local.name_prefix}, including the WRITER group."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  owners                  = var.owners
  members                 = setunion(lookup(var.members, "READER", toset([])), toset([azuread_group.writer.object_id]))
}
