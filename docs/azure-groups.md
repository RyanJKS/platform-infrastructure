# Base Microsoft Entra groups

The repository-local module at `infrastructure/azure/modules/base_aad_groups`
creates three Microsoft Entra security groups: `READER`, `WRITER`, and `ADMIN`.
It adds the ADMIN group as a member of WRITER, and WRITER as a member of READER.
The nesting is one-way: membership in READER does not grant WRITER or ADMIN membership.

Names follow `<GROUP_PREFIX>-<REGION>-<ENVIRONMENT>-<ROLE>`, converted to uppercase
after trimming surrounding whitespace from each input. For example,
`atlas`, `eus2`, and `dev` produce `ATLAS-EUS2-DEV-WRITER`. Region is a naming label;
Entra groups are tenant-wide resources, not regional Azure resources.

## Inputs and outputs

| Input | Type | Default | Purpose |
| --- | --- | --- | --- |
| `group_prefix` | `string` | Required | Application or platform name. |
| `region` | `string` | Required | Region label, such as `eus2`. |
| `environment` | `string` | Required | Environment label, such as `dev`. |
| `owners` | `set(string)` | `[]` | Owner object IDs assigned to all three groups. |
| `members` | `map(set(string))` | `{}` | Additional direct member object IDs keyed by `READER`, `WRITER`, or `ADMIN`. |

Use Microsoft Entra object IDs, not email addresses, application/client IDs, or
Azure resource IDs. Role keys are case-sensitive. Omit a role to add no direct
members to it; the built-in group nesting still applies. Owners manage the
groups but are not automatically members. Add an owner's object ID to `members`
as well if that identity needs membership.

The `object_ids` output returns all three IDs as a map. Select one with
`module.base_aad_groups.object_ids["WRITER"]`. `display_names` returns the generated
names with the same keys.

## Terraform example

From a Terraform configuration in `infrastructure/azure/modules/`, use:

```hcl
module "base_aad_groups" {
  source = "./base_aad_groups"

  group_prefix = "atlas"
  region       = "eus2"
  environment  = "dev"
  owners       = ["11111111-1111-1111-1111-111111111111"]
  members = {
    ADMIN  = ["22222222-2222-2222-2222-222222222222"]
    WRITER = ["33333333-3333-3333-3333-333333333333"]
  }
}

output "group_object_ids" {
  value = module.base_aad_groups.object_ids
}

output "writer_object_id" {
  value = module.base_aad_groups.object_ids["WRITER"]
}
```

Replace the example object IDs with identities from your tenant. The module
requires Terraform >= 1.3 and AzureAD provider 3.x. The caller supplies provider
authentication and remote state. The deployment identity needs Microsoft Graph
permissions to create security groups and manage their owners and memberships;
Azure subscription Contributor alone does not provide those directory permissions.

For a Terragrunt unit, point `terraform.source` at this local module and pass the
same inputs. Another unit can read a selected ID using
`dependency.base_aad_groups.outputs.object_ids["WRITER"]`, with a dependency block
pointing at the deployed groups unit.

Group names do not assign Azure or Kubernetes permissions. Create the relevant
role assignments separately, and verify that each consuming service supports
nested groups. Applications that check only direct membership will not see the
same effective membership. Do not manage these groups' memberships with separate
`azuread_group_member` resources: this module manages the full member sets inline.

## Validation

From `infrastructure/azure/modules/base_aad_groups`, run:

```sh
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

The tests require Terraform >= 1.7 and use a mocked AzureAD provider. They check
names, nesting direction, direct memberships, outputs, and invalid inputs without
creating tenant resources. They do not verify live directory permissions or a
consuming service's treatment of nested groups.
