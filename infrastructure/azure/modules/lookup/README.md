<!-- Frontmatter
name: Azure identity lookup
description: Look up Microsoft Entra users, groups, service principals, and the current Azure client.
tags: [azure, identity, module]
-->

# Azure identity lookup

Looks up existing identities without creating them. The caller configures
AzureRM and AzureAD authentication and remote state.

| Input | Default | Purpose |
| --- | --- | --- |
| `user_mails` | `[]` | User email addresses to look up. Blank entries are excluded. |
| `group_names` | `[]` | Group display names to look up. |
| `service_principal_names` | `[]` | Service principal display names to look up. |
| `ignore_missing` | All three flags `true` | Object containing `azuread_users`, `azuread_groups`, and `azuread_service_principals` flags. |

Outputs `users`, `groups`, and `service_principals` expose the corresponding
AzureAD data source results. Output `this` exposes the current AzureRM client
configuration. Missing identities are ignored by default; disable the relevant
`ignore_missing` flag when every requested identity must exist.
