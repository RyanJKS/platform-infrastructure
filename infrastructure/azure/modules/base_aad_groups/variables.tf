variable "group_prefix" {
  description = "Application or platform prefix for group names, for example ATLAS."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.group_prefix)) > 0
    error_message = "group_prefix must not be blank."
  }
}

variable "region" {
  description = "Region label used in group names, for example EUS2. Groups themselves are tenant-wide."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.region)) > 0
    error_message = "region must not be blank."
  }
}

variable "environment" {
  description = "Environment label used in group names, for example DEV."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be blank."
  }
}

variable "owners" {
  description = "Object IDs of owners assigned to all three groups. Owners are not automatically members."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for id in var.owners : can(regex("(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))])
    error_message = "owners must contain Microsoft Entra object IDs in UUID format."
  }
}

variable "members" {
  description = "Direct member object IDs keyed by READER, WRITER, or ADMIN. Omitted roles have no additional direct members."
  type        = map(set(string))
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for role in keys(var.members) : contains(["READER", "WRITER", "ADMIN"], role)])
    error_message = "members keys must be READER, WRITER, or ADMIN."
  }

  validation {
    condition = alltrue([
      for ids in values(var.members) : ids == null ? false : alltrue([
        for id in ids : can(regex("(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))
      ])
    ])
    error_message = "Each members value must be a non-null set of Microsoft Entra object IDs in UUID format."
  }
}
