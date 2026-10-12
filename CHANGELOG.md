# Changelog

Record notable changes here. Group release entries under Added, Changed, Fixed, and Removed as needed.

## Unreleased

### Added

- Add `just clean` to delete `.terragrunt-cache` directories beneath `infrastructure/`.

### Fixed

- Create sandbox AGIC control-plane subnet and kubelet permissions in
  `cluster_identity_rbacs` before AKS, instead of waiting for downstream RBAC.
- Order sandbox Application Gateway creation after the gateway subnet NSG apply
  so the required v2 management-port rules exist before Azure validates the gateway.
- Fix sandbox AGIC planning by correcting dependency paths and group output
  lookups, adding the registry dependency and matching planning mocks, and
  removing the gateway's dependency on the cluster-federated AGIC identity.
- Align AGIC bootstrap inputs with the modules: use a flat frontend port map,
  `add_public_ip`, and `null` for unconfigured cluster KMS.
- Point the sandbox AGIC RBAC group dependency to `../cluster_ad_groups` instead
  of duplicating the AKS cluster dependency path.
- Omit sandbox container registry network rules with `null` so the default Basic
  SKU passes the module's Premium-feature precondition.
- Correct sandbox container registry dependency paths to sibling platform units
  and the Log Analytics solution settings output reference.
- Point sandbox platform RBAC's AKS dependency to `aks-app-routing/cluster`.

- Document excluding Argo CD manifest units from the first UKS infrastructure
  plan because Kubernetes schema discovery requires a live API and installed CRDs.

- Align the Azure VNet address map with the `domain_name` lookup key (`atlas`).

- Use the Azure root's `domain_name` in platform units instead of the undefined
  `spoke_prefix` local.
- Allow Azure units without an ancestor `solution.hcl` to use the root's
  default `solution_name = null` instead of failing the parent-file lookup.

### Changed

- Allocate `10.2.0.0/16` to the development UKS Intro VNet and move its AKS and
  application integration subnets into that address space.

- Centralise development UKS dependency mocks in Azure `_mocks/outputs.hcl`,
  exposed through the cloud root. Restrict mocks to validation and planning,
  preserve real state outputs, and use domain-specific solution settings.

- Rename domain folders from `spoke-atlas/` to `atlas/` and settings from
  `spoke.hcl` to `domain.hcl` across AWS and Azure. Update inherited inputs,
  address allocation labels, workflow defaults, and the UKS Argo CD source path.
  Existing deployments require reviewed state and GitOps path migrations.

- Centralise Azure VNet address allocations in `_envcommon/network-addresses.hcl`,
  keyed by subscription, environment, region, and domain, with direct lookups from VNet units.
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

- Add a standalone local Terraform bootstrap under `scripts/azure-tfstate-bootstrap/`
  for a DEV-HUB resource group, HNS-enabled ADLS Gen2 storage account, and private
  state container, with editable locals and a local backend.

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
