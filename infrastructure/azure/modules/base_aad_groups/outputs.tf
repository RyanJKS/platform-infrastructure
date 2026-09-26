output "object_ids" {
  description = "Group object IDs keyed by READER, WRITER, and ADMIN."
  value = {
    READER = azuread_group.reader.object_id
    WRITER = azuread_group.writer.object_id
    ADMIN  = azuread_group.admin.object_id
  }
}

output "display_names" {
  description = "Generated group display names keyed by READER, WRITER, and ADMIN."
  value = {
    READER = azuread_group.reader.display_name
    WRITER = azuread_group.writer.display_name
    ADMIN  = azuread_group.admin.display_name
  }
}
