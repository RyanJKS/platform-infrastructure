# Changelog

Record notable changes here. Group release entries under Added, Changed, Fixed, and Removed as needed.

## Unreleased

### Changed

- Centralise Azure VNet address allocations in `_envcommon/network-addresses.hcl`,
  keyed by subscription, region, and spoke, with direct lookups from VNet units.
- Configure Azure catalog discovery for local modules, with readable catalog
  metadata and filtering that excludes deployment units.
- Configure the Azure development AKS unit with one `Standard_D4as_v5` node,
  autoscaling disabled, and the Free management tier.
- Reserve separate Azure hub placeholders under `DEV-HUB/dev/eus2` and
  `PROD-HUB/prod/eus2`, separate from workload subscriptions.

- Group cloud configuration under `infrastructure/<cloud>/`, with account and
  subscription folders beneath `live/` alongside shared configuration and local
  module placeholders. Update Azure workflow paths and state keys accordingly.

### Added

- Centralise Azure remote module refs in `_envcommon/module-versions.hcl` with
  plain per-module locals exposed by direct includes in consuming units.
- Add Azure subscription division labels (`JKS` and `HUB`), exposed through the
  root configuration as a local and inherited input.
- Add the local base Entra groups module with READER, WRITER, and ADMIN groups,
  nested membership, role-keyed object ID outputs, and mocked Terraform tests.
- Reserve `infrastructure/azure/live/PROD-JKS/` for production workloads with a
  README placeholder.

- Azure provisioning and deprovisioning workflows with validated unit selection,
  OIDC, saved plans, required apply reviewers, and shared per-unit concurrency.

- AWS and Azure `spoke-atlas` layouts with sibling platform and application
  folders, inherited settings, and hub folders with README TODOs and proposed platform units.

- Separate AWS and Azure Terragrunt catalog roots and a pinned Terragrunt version.
- Deployment guidance for account/subscription, environment, region, solution,
  and unit boundaries, isolated state, and future GCP support.
- HCL and strict TechDocs checks in CI.

- Initial repository scaffold with Python entry point, CI, and development conventions.
