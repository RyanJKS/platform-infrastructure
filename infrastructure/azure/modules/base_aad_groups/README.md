<!-- Frontmatter
name: Base Microsoft Entra groups
description: Create nested READER, WRITER, and ADMIN security groups with role-keyed object IDs.
tags: [azure, identity, module]
-->

# Base Microsoft Entra groups

Creates three security groups named `<GROUP_PREFIX>-<REGION>-<ENVIRONMENT>-<ROLE>`.
ADMIN is a member of WRITER, and WRITER is a member of READER.

Required inputs are `group_prefix`, `region`, and `environment`. Optional `owners`
contains owner object IDs for all three groups. Optional `members` contains direct
member object IDs keyed by `READER`, `WRITER`, or `ADMIN`.

Use `object_ids` for the full map, or `object_ids["WRITER"]` for one group.
`display_names` returns the generated names with the same keys.

The caller configures AzureAD authentication and remote state. Groups do not
grant permissions until assigned roles. See the [usage guide](../../../../docs/azure-groups.md)
for examples, membership behavior, and validation commands.
