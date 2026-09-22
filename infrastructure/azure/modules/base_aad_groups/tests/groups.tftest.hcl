mock_provider "azuread" {}

override_resource {
  target = azuread_group.admin
  values = { object_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }
}

override_resource {
  target = azuread_group.writer
  values = { object_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" }
}

override_resource {
  target = azuread_group.reader
  values = { object_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
}

variables {
  group_prefix = " atlas "
  region       = "eus2"
  environment  = "dev"
  owners       = ["11111111-1111-1111-1111-111111111111"]
  members = {
    ADMIN  = ["22222222-2222-2222-2222-222222222222"]
    WRITER = ["33333333-3333-3333-3333-333333333333"]
    READER = ["44444444-4444-4444-4444-444444444444"]
  }
}

run "nested_membership" {
  command = apply

  assert {
    condition = output.display_names == {
      ADMIN = "ATLAS-EUS2-DEV-ADMIN", WRITER = "ATLAS-EUS2-DEV-WRITER", READER = "ATLAS-EUS2-DEV-READER"
    }
    error_message = "Names must normalize the supplied labels and append each role."
  }

  assert {
    condition = output.object_ids == {
      ADMIN = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", WRITER = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", READER = "cccccccc-cccc-cccc-cccc-cccccccccccc"
    }
    error_message = "Consumers must receive object IDs keyed by role."
  }

  assert {
    condition = (
      azuread_group.admin.members == var.members["ADMIN"] &&
      azuread_group.writer.members == setunion(var.members["WRITER"], toset([output.object_ids["ADMIN"]])) &&
      azuread_group.reader.members == setunion(var.members["READER"], toset([output.object_ids["WRITER"]]))
    )
    error_message = "ADMIN must nest inside WRITER, and WRITER inside READER, preserving direct members without reverse membership."
  }

  assert {
    condition = alltrue([
      for group in [azuread_group.admin, azuread_group.writer, azuread_group.reader] :
      group.owners == var.owners && group.security_enabled && !group.mail_enabled && group.prevent_duplicate_names
    ])
    error_message = "All groups must be security groups with shared owners and duplicate-name protection."
  }
}

run "no_direct_members" {
  command = apply
  variables {
    members = {}
    owners  = []
  }

  assert {
    condition = (
      length(azuread_group.admin.members) == 0 &&
      azuread_group.writer.members == toset([output.object_ids["ADMIN"]]) &&
      azuread_group.reader.members == toset([output.object_ids["WRITER"]])
    )
    error_message = "Empty inputs must preserve the nested groups without adding other members."
  }
}

run "reject_unknown_role" {
  command = plan
  variables {
    members = { WRITRE = [] }
  }
  expect_failures = [var.members]
}

run "reject_invalid_member" {
  command = plan
  variables {
    members = { ADMIN = ["person@example.com"] }
  }
  expect_failures = [var.members]
}

run "reject_null_members" {
  command = plan
  variables {
    members = { ADMIN = null }
  }
  expect_failures = [var.members]
}

run "reject_invalid_owner" {
  command = plan
  variables {
    owners = ["person@example.com"]
  }
  expect_failures = [var.owners]
}

run "reject_blank_environment" {
  command = plan
  variables {
    environment = " "
  }
  expect_failures = [var.environment]
}
