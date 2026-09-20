# Changelog

Record notable changes here. Group release entries under Added, Changed, Fixed, and Removed as needed.

## Unreleased

### Changed

- Reserve separate Azure hub placeholders under `DEV-HUB/dev/eus2` and
  `PROD-HUB/prod/eus2`, separate from workload subscriptions.

- Group cloud configuration under `infrastructure/<cloud>/`, with account and
  subscription folders beneath `live/` alongside shared configuration and local
  module placeholders. Update Azure workflow paths and state keys accordingly.

### Added

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
